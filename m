From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Mon, 02 Sep 2024 23:54:34 +0200
Subject: [PATCH 07/13] media: i2c: imx214: Use number of lanes from device
 tree
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240902-imx214-v1-7-c96cba989315@apitzsch.eu>
References: <20240902-imx214-v1-0-c96cba989315@apitzsch.eu>
In-Reply-To: <20240902-imx214-v1-0-c96cba989315@apitzsch.eu>
To: Ricardo Ribalda <ribalda@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1725314079; l=3540;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=m5goLAFXtgpfapHH2PqZgsTZuL4USkSmaYIJRA7+tqE=;
 b=yB16JPOVVPecOms6nMVAbj2oyasPNB8xbbuFc5PRcx9HjWiX+d89BaNPgSRpo6+nOquEZt4M/
 acrqCJzVzlkD8KyDtz+5C8rlG1o2y4CoqI5Ch9iYmvzbMD0OWX0V1U8
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The imx214 camera is capable of either two-lane or four-lane operation.

Currently only the four-lane mode is supported, as proper pixel rates
and link frequences for the two-lane mode are unknown.

Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 drivers/media/i2c/imx214.c | 37 ++++++++++++++++++++++++++++++-------
 1 file changed, 30 insertions(+), 7 deletions(-)

diff --git a/drivers/media/i2c/imx214.c b/drivers/media/i2c/imx214.c
index 4507e12dd4cd..3b422cddbdce 100644
--- a/drivers/media/i2c/imx214.c
+++ b/drivers/media/i2c/imx214.c
@@ -195,11 +195,13 @@ struct imx214 {
 	struct regulator_bulk_data	supplies[IMX214_NUM_SUPPLIES];
 
 	struct gpio_desc *enable_gpio;
+
+	/* Two or Four lanes */
+	u8 lanes;
 };
 
 /*From imx214_mode_tbls.h*/
 static const struct cci_reg_sequence mode_4096x2304[] = {
-	{ IMX214_REG_CSI_LANE_MODE, IMX214_CSI_4_LANE_MODE },
 	{ IMX214_REG_HDR_MODE, IMX214_HDR_MODE_OFF },
 	{ IMX214_REG_HDR_RES_REDUCTION, IMX214_HDR_RES_REDU_THROUGH },
 	{ IMX214_REG_EXPOSURE_RATIO, 1 },
@@ -272,7 +274,6 @@ static const struct cci_reg_sequence mode_4096x2304[] = {
 };
 
 static const struct cci_reg_sequence mode_1920x1080[] = {
-	{ IMX214_REG_CSI_LANE_MODE, IMX214_CSI_4_LANE_MODE },
 	{ IMX214_REG_HDR_MODE, IMX214_HDR_MODE_OFF },
 	{ IMX214_REG_HDR_RES_REDUCTION, IMX214_HDR_RES_REDU_THROUGH },
 	{ IMX214_REG_EXPOSURE_RATIO, 1 },
@@ -774,6 +775,13 @@ static int imx214_ctrls_init(struct imx214 *imx214)
 	return 0;
 };
 
+static int imx214_configure_lanes(struct imx214 *imx214)
+{
+	return cci_write(imx214->regmap, IMX214_REG_CSI_LANE_MODE,
+			 imx214->lanes == 2 ? IMX214_CSI_2_LANE_MODE :
+			 IMX214_CSI_4_LANE_MODE, NULL);
+};
+
 static int imx214_start_streaming(struct imx214 *imx214)
 {
 	const struct imx214_mode *mode;
@@ -786,6 +794,13 @@ static int imx214_start_streaming(struct imx214 *imx214)
 		return ret;
 	}
 
+	/* Configure two or four Lane mode */
+	ret = imx214_configure_lanes(imx214);
+	if (ret) {
+		dev_err(imx214->dev, "%s failed to configure lanes\n", __func__);
+		return ret;
+	}
+
 	mode = v4l2_find_nearest_size(imx214_modes,
 				ARRAY_SIZE(imx214_modes), width, height,
 				imx214->fmt.width, imx214->fmt.height);
@@ -930,7 +945,7 @@ static int imx214_get_regulators(struct device *dev, struct imx214 *imx214)
 				       imx214->supplies);
 }
 
-static int imx214_parse_fwnode(struct device *dev)
+static int imx214_parse_fwnode(struct device *dev, struct imx214 *imx214)
 {
 	struct fwnode_handle *endpoint;
 	struct v4l2_fwnode_endpoint bus_cfg = {
@@ -949,6 +964,14 @@ static int imx214_parse_fwnode(struct device *dev)
 		goto done;
 	}
 
+	/* Check the number of MIPI CSI2 data lanes */
+	if (bus_cfg.bus.mipi_csi2.num_data_lanes != 4) {
+		dev_err_probe(dev, -EINVAL,
+			      "only 4 data lanes are currently supported\n");
+		goto done;
+	}
+	imx214->lanes = bus_cfg.bus.mipi_csi2.num_data_lanes;
+
 	for (i = 0; i < bus_cfg.nr_of_link_frequencies; i++)
 		if (bus_cfg.link_frequencies[i] == IMX214_DEFAULT_LINK_FREQ)
 			break;
@@ -973,14 +996,14 @@ static int imx214_probe(struct i2c_client *client)
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
2.46.0

