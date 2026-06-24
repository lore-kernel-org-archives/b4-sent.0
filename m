From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Tue, 23 Jun 2026 23:19:02 -0500
Subject: [PATCH v2 1/2] libnvdimm/labels: Prevent integer overflow in
 __nd_label_validate()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260623-b4-disp-1f2c537a-v2-1-59af73f1f090@proton.me>
References: <20260623-b4-disp-1f2c537a-v2-0-59af73f1f090@proton.me>
In-Reply-To: <20260623-b4-disp-1f2c537a-v2-0-59af73f1f090@proton.me>
To: Ira Weiny <iweiny@kernel.org>, Vishal Verma <vishal.l.verma@intel.com>, 
 Dan Williams <djbw@kernel.org>, Dave Jiang <dave.jiang@intel.com>
Cc: David Laight <david.laight.linux@gmail.com>, 
 Alison Schofield <alison.schofield@intel.com>, nvdimm@lists.linux.dev, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782274741; l=1939;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=q0i06gR6biCNC+Je6Bjwu/WLkEUdu04uI3r3m216Cng=;
 b=C/kxooCTdWphtHwNI9K7/yru0NxiZdlww6pyZnaogrNihvEOhr7SUdrhJA1dqGhg0bnZ3KOKt
 Pg/NmSnM/EhB97Ou3aMJhacigf3RV3rGVOySbFzIOD8F8HvOCA+U2bd
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The on-media namespace index field nslot is a u32 read from the DIMM
label storage area.  __nd_label_validate() bounds it against the config
area size, but sizeof_namespace_label() returns unsigned, so the product
nslot * label_size is evaluated in 32-bit and wraps modulo 2^32 before
the comparison.  A crafted nslot passes the bound and is then used as the
loop trip count in nd_label_data_init(), whose memset() walks off the end
of the config_size buffer: an out-of-bounds write.

The field is not trusted -- it comes from the medium, or from userspace
via ND_CMD_SET_CONFIG_DATA.  Evaluate the product in 64-bit so the bound
check is exact; conforming labels are unaffected.

The check was safe when introduced by commit 4a826c83db4e ("libnvdimm:
namespace indices: read and validate") -- it multiplied by sizeof(struct
nd_namespace_label), a size_t, so the product was 64-bit.  Commit
564e871aa66f ("libnvdimm, label: add v1.2 nvdimm label definitions")
narrowed it to 32 bits when the label size became a runtime value read
via sizeof_namespace_label().

Fixes: 564e871aa66f ("libnvdimm, label: add v1.2 nvdimm label definitions")
Cc: stable@vger.kernel.org
Reviewed-by: Alison Schofield <alison.schofield@intel.com>
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 drivers/nvdimm/label.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/nvdimm/label.c b/drivers/nvdimm/label.c
index 4218e3ac4a2a..ec12ce72cfe2 100644
--- a/drivers/nvdimm/label.c
+++ b/drivers/nvdimm/label.c
@@ -202,7 +202,7 @@ static int __nd_label_validate(struct nvdimm_drvdata *ndd)
 		}
 
 		nslot = __le32_to_cpu(nsindex[i]->nslot);
-		if (nslot * sizeof_namespace_label(ndd)
+		if ((u64)nslot * sizeof_namespace_label(ndd)
 				+ 2 * sizeof_namespace_index(ndd)
 				> ndd->nsarea.config_size) {
 			dev_dbg(dev, "nsindex%d nslot: %u invalid, config_size: %#x\n",

-- 
2.43.0

