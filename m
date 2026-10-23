From: Max Bretschneider <max.bretschneider@leica-geosystems.com>
Date: Sat, 24 Oct 2026 00:28:51 +0200
Subject: [PATCH v2 1/4] media: i2c: ov08d10: fix NULL pointer dereference
 in ov08d10_get_hwcfg()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261024-ov08d10-get-selection-v2-1-f8c49972ca18@leica-geosystems.com>
References: <20261024-ov08d10-get-selection-v2-0-f8c49972ca18@leica-geosystems.com>
In-Reply-To: <20261024-ov08d10-get-selection-v2-0-f8c49972ca18@leica-geosystems.com>
To: Jimmy Su <jimmy.su@intel.com>, Matthias Fend <matthias.fend@emfend.at>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, 
 Max Bretschneider <max.bretschneider@leica-geosystems.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792794706; l=1799;
 i=max.bretschneider@leica-geosystems.com; s=20260501;
 h=from:subject:message-id; bh=eLsu5tl24BX1oODaXRTSuCWikGC+/dtd311jxFs+7AE=;
 b=hIO6AMJ8wkZArMvQX4UdhsS4mGWC7tFTaNKFIJofJApLN7LIonU+0mTVcVqJhgr1UK+Q/hQ1o
 u2eYkdGBrGpDi/ultjbXix/+rkLTEsPUvZ1xNvM/EtGXluyg0KN70GC
X-Developer-Key: i=max.bretschneider@leica-geosystems.com; a=ed25519;
 pk=jf4ba33jrWlsOdGemi2InMtJAngoJVZU8Moetp0ixik=
X-Endpoint-Received: by B4 Relay for max.bretschneider@leica-geosystems.com/20260501 with auth_id=1161
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ov08d10_get_hwcfg() logs the number of data lanes using
ov08d10->cur_mode->data_lanes, but cur_mode is only assigned later in
probe(). At the point of the dev_dbg() call it is still NULL, as the
driver data is allocated with devm_kzalloc(). ov08d10->priv_lane, which
cur_mode is set to point into, is only assigned on the following line, so
the value is not reachable here by any route.

The arguments of dev_dbg() are only evaluated when the call site is
enabled, so this dereferences NULL as soon as debugging is turned on for
the driver:

  Unable to handle kernel NULL pointer dereference at virtual address 0000000000000028
  pc : ov08d10_get_hwcfg+0x1b0/0x228 [ov08d10]
  Call trace:
   ov08d10_get_hwcfg+0x1b0/0x228 [ov08d10] (P)
   ov08d10_probe+0xdc/0x658 [ov08d10]
   i2c_device_probe+0x194/0x388

Print the number of data lanes parsed from the endpoint instead, which is
the value the message refers to and which has just been validated.

Fixes: 7be91e02ed57 ("media: i2c: Add ov08d10 camera sensor driver")
Cc: stable@vger.kernel.org
Signed-off-by: Max Bretschneider <max.bretschneider@leica-geosystems.com>
---
 drivers/media/i2c/ov08d10.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/media/i2c/ov08d10.c b/drivers/media/i2c/ov08d10.c
index 0710d2243cc0..4dc68ff89eda 100644
--- a/drivers/media/i2c/ov08d10.c
+++ b/drivers/media/i2c/ov08d10.c
@@ -1432,7 +1432,8 @@ static int ov08d10_get_hwcfg(struct ov08d10 *ov08d10)
 		goto check_hwcfg_error;
 	}
 
-	dev_dbg(dev, "Using %u data lanes\n", ov08d10->cur_mode->data_lanes);
+	dev_dbg(dev, "Using %u data lanes\n",
+		bus_cfg.bus.mipi_csi2.num_data_lanes);
 
 	ov08d10->priv_lane = &lane_cfg_2;
 	ov08d10->modes_size = ov08d10_modes_num(ov08d10);

-- 
2.43.0

