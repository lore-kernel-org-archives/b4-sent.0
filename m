From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Fri, 20 Dec 2024 14:26:10 +0100
Subject: [PATCH v6 11/13] media: i2c: imx214: Add test pattern control
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241220-imx214-v6-11-d90a185d82e5@apitzsch.eu>
References: <20241220-imx214-v6-0-d90a185d82e5@apitzsch.eu>
In-Reply-To: <20241220-imx214-v6-0-d90a185d82e5@apitzsch.eu>
To: Ricardo Ribalda <ribalda@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Vincent Knecht <vincent.knecht@mailoo.org>, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>, 
 Ricardo Ribalda <ribalda@chromium.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1734701191; l=4254;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=Zo5rfJ2BLIxpU7a6IT7DWhNyt2I+eK8TbFHd0cNNoPQ=;
 b=gtrWEY8Pq3Igv0W7f+5mI0WrEsqcpnKji+kCtbcJVArL9TG5rHnN0F0zcalKkUqvPgBo4MFYt
 wb2fY1HsdQXAzu8+luE+x7F2VSxgoWIjVTiituxr+vmQ7SVIoVt/c+4
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This adds V4L2_CID_TEST_PATTERN control support.

Acked-by: Ricardo Ribalda <ribalda@chromium.org>
Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 drivers/media/i2c/imx214.c | 77 ++++++++++++++++++++++++++++++++++++++++++++--
 1 file changed, 75 insertions(+), 2 deletions(-)

diff --git a/drivers/media/i2c/imx214.c b/drivers/media/i2c/imx214.c
index 6b9584e330ddc17823cbb024e39f9c5fd54442bf..96d05acfeb66480770bb6291027dd023fdccb649 100644
--- a/drivers/media/i2c/imx214.c
+++ b/drivers/media/i2c/imx214.c
@@ -177,6 +177,23 @@
 
 #define IMX214_REG_ATR_FAST_MOVE	CCI_REG8(0x9300)
 
+/* Test Pattern Control */
+#define IMX214_REG_TEST_PATTERN		CCI_REG16(0x0600)
+#define IMX214_TEST_PATTERN_DISABLE	0
+#define IMX214_TEST_PATTERN_SOLID_COLOR	1
+#define IMX214_TEST_PATTERN_COLOR_BARS	2
+#define IMX214_TEST_PATTERN_GREY_COLOR	3
+#define IMX214_TEST_PATTERN_PN9		4
+
+/* Test pattern colour components */
+#define IMX214_REG_TESTP_RED		CCI_REG16(0x0602)
+#define IMX214_REG_TESTP_GREENR		CCI_REG16(0x0604)
+#define IMX214_REG_TESTP_BLUE		CCI_REG16(0x0606)
+#define IMX214_REG_TESTP_GREENB		CCI_REG16(0x0608)
+#define IMX214_TESTP_COLOUR_MIN		0
+#define IMX214_TESTP_COLOUR_MAX		0x03ff
+#define IMX214_TESTP_COLOUR_STEP	1
+
 /* IMX214 native and active pixel array size */
 #define IMX214_NATIVE_WIDTH		4224U
 #define IMX214_NATIVE_HEIGHT		3136U
@@ -209,6 +226,22 @@ static const u32 imx214_mbus_formats[] = {
 	MEDIA_BUS_FMT_SBGGR10_1X10,
 };
 
+static const char * const imx214_test_pattern_menu[] = {
+	"Disabled",
+	"Color Bars",
+	"Solid Color",
+	"Grey Color Bars",
+	"PN9"
+};
+
+static const int imx214_test_pattern_val[] = {
+	IMX214_TEST_PATTERN_DISABLE,
+	IMX214_TEST_PATTERN_COLOR_BARS,
+	IMX214_TEST_PATTERN_SOLID_COLOR,
+	IMX214_TEST_PATTERN_GREY_COLOR,
+	IMX214_TEST_PATTERN_PN9,
+};
+
 struct imx214 {
 	struct device *dev;
 	struct clk *xclk;
@@ -807,6 +840,26 @@ static int imx214_set_ctrl(struct v4l2_ctrl *ctrl)
 		cci_write(imx214->regmap, IMX214_REG_FRM_LENGTH_LINES,
 			  format->height + ctrl->val, &ret);
 		break;
+	case V4L2_CID_TEST_PATTERN:
+		cci_write(imx214->regmap, IMX214_REG_TEST_PATTERN,
+			  imx214_test_pattern_val[ctrl->val], &ret);
+		break;
+	case V4L2_CID_TEST_PATTERN_RED:
+		cci_write(imx214->regmap, IMX214_REG_TESTP_RED,
+			  ctrl->val, &ret);
+		break;
+	case V4L2_CID_TEST_PATTERN_GREENR:
+		cci_write(imx214->regmap, IMX214_REG_TESTP_GREENR,
+			  ctrl->val, &ret);
+		break;
+	case V4L2_CID_TEST_PATTERN_BLUE:
+		cci_write(imx214->regmap, IMX214_REG_TESTP_BLUE,
+			  ctrl->val, &ret);
+		break;
+	case V4L2_CID_TEST_PATTERN_GREENB:
+		cci_write(imx214->regmap, IMX214_REG_TESTP_GREENB,
+			  ctrl->val, &ret);
+		break;
 	default:
 		ret = -EINVAL;
 	}
@@ -834,14 +887,14 @@ static int imx214_ctrls_init(struct imx214 *imx214)
 	struct v4l2_ctrl_handler *ctrl_hdlr;
 	int exposure_max, exposure_def;
 	int hblank;
-	int ret;
+	int i, ret;
 
 	ret = v4l2_fwnode_device_parse(imx214->dev, &props);
 	if (ret < 0)
 		return ret;
 
 	ctrl_hdlr = &imx214->ctrls;
-	ret = v4l2_ctrl_handler_init(&imx214->ctrls, 12);
+	ret = v4l2_ctrl_handler_init(&imx214->ctrls, 13);
 	if (ret)
 		return ret;
 
@@ -910,6 +963,26 @@ static int imx214_ctrls_init(struct imx214 *imx214)
 
 	v4l2_ctrl_cluster(2, &imx214->hflip);
 
+	v4l2_ctrl_new_std_menu_items(ctrl_hdlr, &imx214_ctrl_ops,
+				     V4L2_CID_TEST_PATTERN,
+				     ARRAY_SIZE(imx214_test_pattern_menu) - 1,
+				     0, 0, imx214_test_pattern_menu);
+	for (i = 0; i < 4; i++) {
+		/*
+		 * The assumption is that
+		 * V4L2_CID_TEST_PATTERN_GREENR == V4L2_CID_TEST_PATTERN_RED + 1
+		 * V4L2_CID_TEST_PATTERN_BLUE   == V4L2_CID_TEST_PATTERN_RED + 2
+		 * V4L2_CID_TEST_PATTERN_GREENB == V4L2_CID_TEST_PATTERN_RED + 3
+		 */
+		v4l2_ctrl_new_std(ctrl_hdlr, &imx214_ctrl_ops,
+				  V4L2_CID_TEST_PATTERN_RED + i,
+				  IMX214_TESTP_COLOUR_MIN,
+				  IMX214_TESTP_COLOUR_MAX,
+				  IMX214_TESTP_COLOUR_STEP,
+				  IMX214_TESTP_COLOUR_MAX);
+		/* The "Solid color" pattern is white by default */
+	}
+
 	imx214->unit_size = v4l2_ctrl_new_std_compound(ctrl_hdlr,
 				NULL,
 				V4L2_CID_UNIT_CELL_SIZE,

-- 
2.47.1

