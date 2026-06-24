From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Tue, 23 Jun 2026 23:19:03 -0500
Subject: [PATCH v2 2/2] libnvdimm/labels: reject an implausibly large
 on-media slot count
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260623-b4-disp-1f2c537a-v2-2-59af73f1f090@proton.me>
References: <20260623-b4-disp-1f2c537a-v2-0-59af73f1f090@proton.me>
In-Reply-To: <20260623-b4-disp-1f2c537a-v2-0-59af73f1f090@proton.me>
To: Ira Weiny <iweiny@kernel.org>, Vishal Verma <vishal.l.verma@intel.com>, 
 Dan Williams <djbw@kernel.org>, Dave Jiang <dave.jiang@intel.com>
Cc: David Laight <david.laight.linux@gmail.com>, 
 Alison Schofield <alison.schofield@intel.com>, nvdimm@lists.linux.dev, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782274741; l=2142;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=2tqdVOXGrP3V/0SevNfIQBF49FyQ7PW7p3H8Z9FOK7I=;
 b=8RLtTIfJu3Nxr/7NWZq68j+42eciXwKhk35vyYWjXy/+TOsAxYm1bvIkH4byfD6MDoi+a4CbR
 aAfNWPktGcLDk3wH4Xfwo77kVPkp2S7b/JkUoTTY186EfEdV2ln50zk
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Even with the bound evaluated in 64-bit, nslot is constrained only by
config_size, which nvdimm_init_nsarea() takes verbatim from the dimm's
ND_CMD_GET_CONFIG_SIZE response with no upper sanity check.  A firmware
or emulated device reporting a large config_size would let a
correspondingly large on-media nslot pass validation and drive a large
allocation and memset loop in nd_label_data_init().

Reject an nslot above NSINDEX_NSLOT_MAX (64K).  The largest legitimate
count is config_size / label_size -- about 1K on a real ~128K label area
-- so this cannot affect a conforming device, and it bounds the slot loop
independently of the firmware-reported config_size.

Suggested-by: David Laight <david.laight.linux@gmail.com>
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 drivers/nvdimm/label.c | 4 ++++
 drivers/nvdimm/label.h | 7 +++++++
 2 files changed, 11 insertions(+)

diff --git a/drivers/nvdimm/label.c b/drivers/nvdimm/label.c
index ec12ce72cfe2..ce1e43d67bab 100644
--- a/drivers/nvdimm/label.c
+++ b/drivers/nvdimm/label.c
@@ -202,6 +202,10 @@ static int __nd_label_validate(struct nvdimm_drvdata *ndd)
 		}
 
 		nslot = __le32_to_cpu(nsindex[i]->nslot);
+		if (nslot > NSINDEX_NSLOT_MAX) {
+			dev_dbg(dev, "nsindex%d nslot: %u implausibly large\n", i, nslot);
+			continue;
+		}
 		if ((u64)nslot * sizeof_namespace_label(ndd)
 				+ 2 * sizeof_namespace_index(ndd)
 				> ndd->nsarea.config_size) {
diff --git a/drivers/nvdimm/label.h b/drivers/nvdimm/label.h
index 0650fb4b9821..74d7c1cc7476 100644
--- a/drivers/nvdimm/label.h
+++ b/drivers/nvdimm/label.h
@@ -28,6 +28,13 @@ enum {
 	ND_LABEL_MIN_SIZE = 256 * 4, /* see sizeof_namespace_index() */
 	ND_LABEL_ID_SIZE = 50,
 	ND_NSINDEX_INIT = 0x1,
+	/*
+	 * A sane ceiling on the on-media slot count.  The largest legitimate
+	 * value is config_size / label_size -- about 1K on a real ~128K label
+	 * area.  A count this large cannot describe a real device; it would
+	 * only drive a large allocation in nd_label_data_init(), so reject it.
+	 */
+	NSINDEX_NSLOT_MAX = 64 * 1024,
 };
 
 /**

-- 
2.43.0

