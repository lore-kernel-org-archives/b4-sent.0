From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Mon, 21 Oct 2024 00:13:31 +0200
Subject: [PATCH v2 11/13] media: i2c: imx214: Add analogue/digital gain
 control
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241021-imx214-v2-11-fbd23e99541e@apitzsch.eu>
References: <20241021-imx214-v2-0-fbd23e99541e@apitzsch.eu>
In-Reply-To: <20241021-imx214-v2-0-fbd23e99541e@apitzsch.eu>
To: Ricardo Ribalda <ribalda@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>, 
 Ricardo Ribalda <ribalda@chromium.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729462449; l=4360;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=rXL1g7Oe8YzuPPhYACw/Jy36nnaFTf5MQS8SSUXbNRE=;
 b=WXzI6ca0GpCmGXV5kfd81sVpwBwcxO20nmSYMpCVzCYDlSMqSE99G519iO0kdYJTqvNoBcrlz
 +3B7Ev4qk4rBGIiATX+S+xa2f/eZgvQvJONCJhC8YpRWxdoSt2aI+Mi
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The imx214 sensor supports analogue gain up to 8x and digital gain up to
16x. Implement the corresponding controls in the driver. Default gain
values are not modified by this patch.

Acked-by: Ricardo Ribalda <ribalda@chromium.org>
Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 drivers/media/i2c/imx214.c | 53 +++++++++++++++++++++++++++++++++-------------
 1 file changed, 38 insertions(+), 15 deletions(-)

diff --git a/drivers/media/i2c/imx214.c b/drivers/media/i2c/imx214.c
index f2d21c2e8cf84ed25403c98e280073f32e50e758..ad1f88057ac47ae0d494d7a10520fabf969315ed 100644
--- a/drivers/media/i2c/imx214.c
+++ b/drivers/media/i2c/imx214.c
@@ -53,12 +53,20 @@
 /* Analog gain control */
 #define IMX214_REG_ANALOG_GAIN		CCI_REG16(0x0204)
 #define IMX214_REG_SHORT_ANALOG_GAIN	CCI_REG16(0x0216)
+#define IMX214_ANA_GAIN_MIN		0
+#define IMX214_ANA_GAIN_MAX		448
+#define IMX214_ANA_GAIN_STEP		1
+#define IMX214_ANA_GAIN_DEFAULT		0x0
 
 /* Digital gain control */
 #define IMX214_REG_DIG_GAIN_GREENR	CCI_REG16(0x020e)
 #define IMX214_REG_DIG_GAIN_RED		CCI_REG16(0x0210)
 #define IMX214_REG_DIG_GAIN_BLUE	CCI_REG16(0x0212)
 #define IMX214_REG_DIG_GAIN_GREENB	CCI_REG16(0x0214)
+#define IMX214_DGTL_GAIN_MIN		0x0100
+#define IMX214_DGTL_GAIN_MAX		0x0fff
+#define IMX214_DGTL_GAIN_DEFAULT	0x0100
+#define IMX214_DGTL_GAIN_STEP		1
 
 #define IMX214_REG_ORIENTATION		CCI_REG8(0x0101)
 
@@ -273,13 +281,6 @@ static const struct cci_reg_sequence mode_4096x2304[] = {
 
 	{ IMX214_REG_SHORT_EXPOSURE, 500 },
 
-	{ IMX214_REG_ANALOG_GAIN, 0 },
-	{ IMX214_REG_DIG_GAIN_GREENR, 256 },
-	{ IMX214_REG_DIG_GAIN_RED, 256 },
-	{ IMX214_REG_DIG_GAIN_BLUE, 256 },
-	{ IMX214_REG_DIG_GAIN_GREENB, 256 },
-	{ IMX214_REG_SHORT_ANALOG_GAIN, 0 },
-
 	{ CCI_REG8(0x4170), 0x00 },
 	{ CCI_REG8(0x4171), 0x10 },
 	{ CCI_REG8(0x4176), 0x00 },
@@ -329,13 +330,6 @@ static const struct cci_reg_sequence mode_1920x1080[] = {
 
 	{ IMX214_REG_SHORT_EXPOSURE, 500 },
 
-	{ IMX214_REG_ANALOG_GAIN, 0 },
-	{ IMX214_REG_DIG_GAIN_GREENR, 256 },
-	{ IMX214_REG_DIG_GAIN_RED, 256 },
-	{ IMX214_REG_DIG_GAIN_BLUE, 256 },
-	{ IMX214_REG_DIG_GAIN_GREENB, 256 },
-	{ IMX214_REG_SHORT_ANALOG_GAIN, 0 },
-
 	{ CCI_REG8(0x4170), 0x00 },
 	{ CCI_REG8(0x4171), 0x10 },
 	{ CCI_REG8(0x4176), 0x00 },
@@ -756,6 +750,18 @@ static int imx214_entity_init_state(struct v4l2_subdev *subdev,
 	return 0;
 }
 
+static int imx214_update_digital_gain(struct imx214 *imx214, u32 val)
+{
+	int ret = 0;
+
+	cci_write(imx214->regmap, IMX214_REG_DIG_GAIN_GREENR, val, &ret);
+	cci_write(imx214->regmap, IMX214_REG_DIG_GAIN_RED, val, &ret);
+	cci_write(imx214->regmap, IMX214_REG_DIG_GAIN_BLUE, val, &ret);
+	cci_write(imx214->regmap, IMX214_REG_DIG_GAIN_GREENB, val, &ret);
+
+	return ret;
+}
+
 static int imx214_set_ctrl(struct v4l2_ctrl *ctrl)
 {
 	struct imx214 *imx214 = container_of(ctrl->handler,
@@ -787,6 +793,15 @@ static int imx214_set_ctrl(struct v4l2_ctrl *ctrl)
 		return 0;
 
 	switch (ctrl->id) {
+	case V4L2_CID_ANALOGUE_GAIN:
+		cci_write(imx214->regmap, IMX214_REG_ANALOG_GAIN,
+			  ctrl->val, &ret);
+		cci_write(imx214->regmap, IMX214_REG_SHORT_ANALOG_GAIN,
+			  ctrl->val, &ret);
+		break;
+	case V4L2_CID_DIGITAL_GAIN:
+		ret = imx214_update_digital_gain(imx214, ctrl->val);
+		break;
 	case V4L2_CID_EXPOSURE:
 		cci_write(imx214->regmap, IMX214_REG_EXPOSURE, ctrl->val, &ret);
 		break;
@@ -833,7 +848,7 @@ static int imx214_ctrls_init(struct imx214 *imx214)
 		return ret;
 
 	ctrl_hdlr = &imx214->ctrls;
-	ret = v4l2_ctrl_handler_init(&imx214->ctrls, 10);
+	ret = v4l2_ctrl_handler_init(&imx214->ctrls, 12);
 	if (ret)
 		return ret;
 
@@ -870,6 +885,14 @@ static int imx214_ctrls_init(struct imx214 *imx214)
 					     IMX214_EXPOSURE_STEP,
 					     exposure_def);
 
+	v4l2_ctrl_new_std(ctrl_hdlr, &imx214_ctrl_ops, V4L2_CID_ANALOGUE_GAIN,
+			  IMX214_ANA_GAIN_MIN, IMX214_ANA_GAIN_MAX,
+			  IMX214_ANA_GAIN_STEP, IMX214_ANA_GAIN_DEFAULT);
+
+	v4l2_ctrl_new_std(ctrl_hdlr, &imx214_ctrl_ops, V4L2_CID_DIGITAL_GAIN,
+			  IMX214_DGTL_GAIN_MIN, IMX214_DGTL_GAIN_MAX,
+			  IMX214_DGTL_GAIN_STEP, IMX214_DGTL_GAIN_DEFAULT);
+
 	imx214->hflip = v4l2_ctrl_new_std(ctrl_hdlr, &imx214_ctrl_ops,
 					  V4L2_CID_HFLIP, 0, 1, 1, 0);
 	if (imx214->hflip)

-- 
2.47.0

