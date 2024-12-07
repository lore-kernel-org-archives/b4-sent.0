From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Sat, 07 Dec 2024 21:47:55 +0100
Subject: [PATCH v3 06/12] media: i2c: imx214: Check number of lanes from
 device tree
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241207-imx214-v3-6-ab60af7ee915@apitzsch.eu>
References: <20241207-imx214-v3-0-ab60af7ee915@apitzsch.eu>
In-Reply-To: <20241207-imx214-v3-0-ab60af7ee915@apitzsch.eu>
To: Ricardo Ribalda <ribalda@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Vincent Knecht <vincent.knecht@mailoo.org>, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733604504; l=2204;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=weqeUMKe5uTQdP5hFWSGU8a0VftNGSL8fbygsOgcwtY=;
 b=qNhFiB/DINxdKCO0xPKRF66ZWxbzd3JCRVetLAw37s2c/XeNWeFjHhFt0wLFSzU9PLhBH+F+V
 u4B+E882FSyDVA+qJO+TpC3jf0pVHHiRrGerMpuhIVpcjSLRHsdgpBX
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The imx214 camera is capable of either two-lane or four-lane operation.

Currently only the four-lane mode is supported, as proper pixel rates
and link frequences for the two-lane mode are unknown.

Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 drivers/media/i2c/imx214.c | 16 ++++++++++++++--
 1 file changed, 14 insertions(+), 2 deletions(-)

diff --git a/drivers/media/i2c/imx214.c b/drivers/media/i2c/imx214.c
index 07926f7257877155548f7bcf0e7ee80037b4ce6c..f1c72db0775eaf4810f762e8798d301c5ad9923c 100644
--- a/drivers/media/i2c/imx214.c
+++ b/drivers/media/i2c/imx214.c
@@ -199,7 +199,6 @@ struct imx214 {
 
 /*From imx214_mode_tbls.h*/
 static const struct cci_reg_sequence mode_4096x2304[] = {
-	{ IMX214_REG_CSI_LANE_MODE, IMX214_CSI_4_LANE_MODE },
 	{ IMX214_REG_HDR_MODE, IMX214_HDR_MODE_OFF },
 	{ IMX214_REG_HDR_RES_REDUCTION, IMX214_HDR_RES_REDU_THROUGH },
 	{ IMX214_REG_EXPOSURE_RATIO, 1 },
@@ -272,7 +271,6 @@ static const struct cci_reg_sequence mode_4096x2304[] = {
 };
 
 static const struct cci_reg_sequence mode_1920x1080[] = {
-	{ IMX214_REG_CSI_LANE_MODE, IMX214_CSI_4_LANE_MODE },
 	{ IMX214_REG_HDR_MODE, IMX214_HDR_MODE_OFF },
 	{ IMX214_REG_HDR_RES_REDUCTION, IMX214_HDR_RES_REDU_THROUGH },
 	{ IMX214_REG_EXPOSURE_RATIO, 1 },
@@ -788,6 +786,13 @@ static int imx214_start_streaming(struct imx214 *imx214)
 		return ret;
 	}
 
+	ret = cci_write(imx214->regmap, IMX214_REG_CSI_LANE_MODE,
+			IMX214_CSI_4_LANE_MODE, NULL);
+	if (ret) {
+		dev_err(imx214->dev, "%s failed to configure lanes\n", __func__);
+		return ret;
+	}
+
 	ret = cci_multi_reg_write(imx214->regmap, imx214->cur_mode->reg_table,
 				  imx214->cur_mode->num_of_regs, NULL);
 	if (ret < 0) {
@@ -948,6 +953,13 @@ static int imx214_parse_fwnode(struct device *dev)
 		goto done;
 	}
 
+	/* Check the number of MIPI CSI2 data lanes */
+	if (bus_cfg.bus.mipi_csi2.num_data_lanes != 4) {
+		ret = dev_err_probe(dev, -EINVAL,
+				    "only 4 data lanes are currently supported\n");
+		goto done;
+	}
+
 	for (i = 0; i < bus_cfg.nr_of_link_frequencies; i++)
 		if (bus_cfg.link_frequencies[i] == IMX214_DEFAULT_LINK_FREQ)
 			break;

-- 
2.47.1

