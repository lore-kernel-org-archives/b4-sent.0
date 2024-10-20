From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Mon, 21 Oct 2024 00:13:27 +0200
Subject: [PATCH v2 07/13] media: i2c: imx214: Check number of lanes from
 device tree
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241021-imx214-v2-7-fbd23e99541e@apitzsch.eu>
References: <20241021-imx214-v2-0-fbd23e99541e@apitzsch.eu>
In-Reply-To: <20241021-imx214-v2-0-fbd23e99541e@apitzsch.eu>
To: Ricardo Ribalda <ribalda@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729462449; l=2978;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=CBPDBnfB8DBiUcxll9P6I0H8kikZ+GlZj0ctfGMDhYE=;
 b=jJZEoSUE6ANmxYOiJY/K5XDWKlD6rnS7nx3pzhUZBzNWr6EKC6V6d4FkfE7d1WKz+VFhvqOo6
 RlkNKt27XWoAbQReJr9vxbMQw7/IXvcB3HfjMfE4yH1Pxh50Bks/w39
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The imx214 camera is capable of either two-lane or four-lane operation.

Currently only the four-lane mode is supported, as proper pixel rates
and link frequences for the two-lane mode are unknown.

Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 drivers/media/i2c/imx214.c | 26 +++++++++++++++++++-------
 1 file changed, 19 insertions(+), 7 deletions(-)

diff --git a/drivers/media/i2c/imx214.c b/drivers/media/i2c/imx214.c
index 0c83149bcc3e3b833a087d26104eb7dfaafdf904..497baad616ad7374a92a3da2b7c1096b1d72a0c7 100644
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
@@ -791,6 +789,13 @@ static int imx214_start_streaming(struct imx214 *imx214)
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
@@ -932,7 +937,7 @@ static int imx214_get_regulators(struct device *dev, struct imx214 *imx214)
 				       imx214->supplies);
 }
 
-static int imx214_parse_fwnode(struct device *dev)
+static int imx214_parse_fwnode(struct device *dev, struct imx214 *imx214)
 {
 	struct fwnode_handle *endpoint;
 	struct v4l2_fwnode_endpoint bus_cfg = {
@@ -951,6 +956,13 @@ static int imx214_parse_fwnode(struct device *dev)
 		goto done;
 	}
 
+	/* Check the number of MIPI CSI2 data lanes */
+	if (bus_cfg.bus.mipi_csi2.num_data_lanes != 4) {
+		dev_err_probe(dev, -EINVAL,
+			      "only 4 data lanes are currently supported\n");
+		goto done;
+	}
+
 	for (i = 0; i < bus_cfg.nr_of_link_frequencies; i++)
 		if (bus_cfg.link_frequencies[i] == IMX214_DEFAULT_LINK_FREQ)
 			break;
@@ -975,14 +987,14 @@ static int imx214_probe(struct i2c_client *client)
 	struct imx214 *imx214;
 	int ret;
 
-	ret = imx214_parse_fwnode(dev);
-	if (ret)
-		return ret;
-
 	imx214 = devm_kzalloc(dev, sizeof(*imx214), GFP_KERNEL);
 	if (!imx214)
 		return -ENOMEM;
 
+	ret = imx214_parse_fwnode(dev, imx214);
+	if (ret)
+		return ret;
+
 	imx214->dev = dev;
 
 	imx214->xclk = devm_clk_get(dev, NULL);

-- 
2.47.0

