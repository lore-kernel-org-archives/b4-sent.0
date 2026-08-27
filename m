From: David Heidelberg <david@ixit.cz>
Date: Thu, 27 Aug 2026 11:26:53 +0200
Subject: [PATCH v2] media: imx355: reuse existing CCS defines
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260827-imx355-ccsify-v2-1-3a97bc708315@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNQQ6CMBBFr0JmbU1bLKAr72FYyDiVMRFMWwlIe
 ndbXLt8yfvvr+DJMXk4FSs4mtjzOCTQuwKwvw53EnxLDFrqSjbqKPg5l8YIRM92EY2psDHS1MY
 qSJuXI8vz1ru0P/bv7kEYciQbPfswumU7nFT2/rUnJZSQXYVk65rKgzzzzGGPH2hjjF+O9wQSu
 gAAAA==
X-Change-ID: 20260819-imx355-ccsify-856c850575f1
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=10030; i=david@ixit.cz;
 h=from:subject:message-id; bh=8fjmIEf2Uou5I7hSyXj2MRgsHK14tG7lVR5oqFFpIqQ=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqkALdaU7SCL9MD2CLhpq7GVVTKytztNX37egim
 9gfQ5I8Ra+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCapAC3QAKCRBgAj/E00kg
 civREADP0/akWHg818ryfVEvANU5flZiBcQagxj5ESZ0pvy8+1sEi6Hka/aUUrj0Un6SO/32xcQ
 fyFHIv5g5OrQKCpIy/0q4ro6AclzE9iu7R3TGAACipS4DXcFm8Z6XP5SDikO47kIRDOJe+26ai0
 5iQcKkQsvXj9iJb6mc/mdNDKQekGMnmVQ45x8EYI3rfiZ+H3cjWNbSOFyHkzUXL9B8IGRkm6+kY
 RezZxNT2gxHmHQW8+l44SILcJVLIrl4zAmm0Bl06ysMnTJnZ50n31FaMcg4mldUjkNAZFDOpZdq
 EMst8ev6O/pp+XpgSLlyavKZlqsQyaZGcHrHWM8U2CKqkki8NoooVOU+kIfVacEfsOH3ivybDJm
 C29JH3BmIa+ROq/IijFZkXwiDHiqG7Xa75LygU8smIY1NVK+JomSj7W+dHt88haqtagKhyZbHp7
 cWuNnKCYJS4cGtxKOM+Q9lvzQdBjjl7n6xSMNaKj/1e6oel92AtW7WPuuNEggMdsXWgkac38Inq
 2q9NKWuRGFYC8PU/pBN6vaKrxNVPwPn/k1E8ErZ3vYIjC5QuWIMv9M3JrqV6Cy3k/jtTsz6TEuv
 MHFvMh4xoosKFv+7s34g9WUWfjFVGPnKx2mmbA0UMnt7jiGOHeKSn/j4cvMD3/FR8wi+2m5cdCi
 us5zaHndb613qgw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver may not be MIPI CCS compliant, but does use same address and
often set same values as compliant drivers. Do not redefine registers we
already know and are standard.

No functional changes.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v2:
- Replaced all occurences with CCS ones.
- Link to v1: https://patch.msgid.link/20260819-imx355-ccsify-v1-1-0b6cef77e340@ixit.cz
---
 drivers/media/i2c/imx355.c | 84 ++++++++++++++--------------------------------
 1 file changed, 25 insertions(+), 59 deletions(-)

diff --git a/drivers/media/i2c/imx355.c b/drivers/media/i2c/imx355.c
index 8eb8588cb71bb..2c845b7b3df4f 100644
--- a/drivers/media/i2c/imx355.c
+++ b/drivers/media/i2c/imx355.c
@@ -14,89 +14,55 @@
 #include <linux/unaligned.h>
 
 #include <media/v4l2-cci.h>
 #include <media/v4l2-ctrls.h>
 #include <media/v4l2-device.h>
 #include <media/v4l2-event.h>
 #include <media/v4l2-fwnode.h>
 
-#define IMX355_REG_MODE_SELECT		CCI_REG8(0x0100)
-#define IMX355_MODE_STANDBY		0x00
-#define IMX355_MODE_STREAMING		0x01
+#include "ccs/ccs-regs.h"
 
-/* Chip ID */
-#define IMX355_REG_CHIP_ID		CCI_REG16(0x0016)
 #define IMX355_CHIP_ID			0x0355
 
-#define IMX355_REG_LANE_SEL		CCI_REG8(0x0114)
-
 /* PLL registers that depend on the external clock frequency */
-#define IMX355_REG_EXTCLK_FREQ		CCI_REG16(0x0136)
 #define IMX355_REG_PLL_OP_PREDIV	CCI_REG8(0x030d)
-#define IMX355_REG_PLL_OP_MUL		CCI_REG16(0x030e)
 #define IMX355_REG_PLL_IVT_PCK_DIV	CCI_REG8(0x0301)
 #define IMX355_REG_PLL_IVT_SYSCK_DIV	CCI_REG8(0x0303)
 #define IMX355_PLL_OP_PREDIV		2
 #define IMX355_PLL_IVT_PCK_DIV		5
 
 /* V_TIMING internal */
-#define IMX355_REG_FLL			CCI_REG16(0x0340)
 #define IMX355_FLL_MAX			0xffff
 #define IMX355_VBLANK_MIN		20
 
-#define IMX355_REG_LLP			CCI_REG16(0x0342)
 #define IMX355_LLP_MAX			0xffff
 
-#define IMX355_REG_X_ADD_START		CCI_REG16(0x0344)
-#define IMX355_REG_Y_ADD_START		CCI_REG16(0x0346)
-#define IMX355_REG_X_ADD_END		CCI_REG16(0x0348)
-#define IMX355_REG_Y_ADD_END		CCI_REG16(0x034a)
-#define IMX355_REG_X_OUT_SIZE		CCI_REG16(0x034c)
-#define IMX355_REG_Y_OUT_SIZE		CCI_REG16(0x034e)
-
 /* Exposure control */
-#define IMX355_REG_EXPOSURE		CCI_REG16(0x0202)
 #define IMX355_EXPOSURE_MIN		1
 #define IMX355_EXPOSURE_STEP		1
 #define IMX355_EXPOSURE_DEFAULT		0x0282
 #define IMX355_EXPOSURE_OFFSET		10
 
 /* Analog gain control */
-#define IMX355_REG_ANALOG_GAIN		CCI_REG16(0x0204)
 #define IMX355_ANA_GAIN_MIN		0
 #define IMX355_ANA_GAIN_MAX		960
 #define IMX355_ANA_GAIN_STEP		1
 #define IMX355_ANA_GAIN_DEFAULT		0
 
 /* Digital gain control */
 #define IMX355_REG_DPGA_USE_GLOBAL_GAIN	CCI_REG8(0x3070)
-#define IMX355_REG_DIG_GAIN_GLOBAL	CCI_REG16(0x020e)
 #define IMX355_DGTL_GAIN_MIN		256
 #define IMX355_DGTL_GAIN_MAX		4095
 #define IMX355_DGTL_GAIN_STEP		1
 #define IMX355_DGTL_GAIN_DEFAULT	256
 
-/* Test Pattern Control */
-#define IMX355_REG_TEST_PATTERN		CCI_REG16(0x0600)
-#define IMX355_TEST_PATTERN_DISABLED		0
-#define IMX355_TEST_PATTERN_SOLID_COLOR		1
-#define IMX355_TEST_PATTERN_COLOR_BARS		2
-#define IMX355_TEST_PATTERN_GRAY_COLOR_BARS	3
-#define IMX355_TEST_PATTERN_PN9			4
-
+/* Link rate register: 16-bit wide, unlike the CCS 32-bit one */
 #define IMX355_REG_REQ_LINK_BIT_RATE	CCI_REG16(0x0820)
 
-#define IMX355_REG_BINNING_MODE		CCI_REG8(0x0900)
-#define IMX355_REG_BINNING_TYPE		CCI_REG8(0x0901)
-#define IMX355_REG_BINNING_WEIGHTING	CCI_REG8(0x0902)
-
-/* Flip Control */
-#define IMX355_REG_ORIENTATION		CCI_REG8(0x0101)
-
 #define IMX355_PIXEL_ARRAY_TOP		0
 #define IMX355_PIXEL_ARRAY_LEFT		0
 #define IMX355_PIXEL_ARRAY_WIDTH	3280
 #define IMX355_PIXEL_ARRAY_HEIGHT	2464
 
 struct imx355_reg_list {
 	u32 num_of_regs;
 	const struct cci_reg_sequence *regs;
@@ -616,39 +582,39 @@ static int imx355_set_ctrl(struct v4l2_ctrl *ctrl)
 	 * when power is up for streaming
 	 */
 	if (!pm_runtime_get_if_in_use(imx355->dev))
 		return 0;
 
 	switch (ctrl->id) {
 	case V4L2_CID_ANALOGUE_GAIN:
 		/* Analog gain = 1024/(1024 - ctrl->val) times */
-		ret = cci_write(imx355->regmap, IMX355_REG_ANALOG_GAIN,
+		ret = cci_write(imx355->regmap, CCS_R_ANALOG_GAIN_CODE_GLOBAL,
 				ctrl->val, NULL);
 		break;
 	case V4L2_CID_DIGITAL_GAIN:
-		ret = cci_write(imx355->regmap, IMX355_REG_DIG_GAIN_GLOBAL,
+		ret = cci_write(imx355->regmap, CCS_R_DIGITAL_GAIN_GLOBAL,
 				ctrl->val, NULL);
 		break;
 	case V4L2_CID_EXPOSURE:
-		ret = cci_write(imx355->regmap, IMX355_REG_EXPOSURE,
+		ret = cci_write(imx355->regmap, CCS_R_COARSE_INTEGRATION_TIME,
 				ctrl->val, NULL);
 		break;
 	case V4L2_CID_VBLANK:
 		/* Update FLL that meets expected vertical blanking */
-		ret = cci_write(imx355->regmap, IMX355_REG_FLL,
+		ret = cci_write(imx355->regmap, CCS_R_FRAME_LENGTH_LINES,
 				format->height + ctrl->val, NULL);
 		break;
 	case V4L2_CID_TEST_PATTERN:
-		ret = cci_write(imx355->regmap, IMX355_REG_TEST_PATTERN,
+		ret = cci_write(imx355->regmap, CCS_R_TEST_PATTERN_MODE,
 				ctrl->val, NULL);
 		break;
 	case V4L2_CID_HFLIP:
 	case V4L2_CID_VFLIP:
-		ret = cci_write(imx355->regmap, IMX355_REG_ORIENTATION,
+		ret = cci_write(imx355->regmap, CCS_R_IMAGE_ORIENTATION,
 				imx355->hflip->val | imx355->vflip->val << 1,
 				NULL);
 		break;
 	default:
 		ret = -EINVAL;
 		dev_info(imx355->dev, "ctrl(id:0x%x,val:0x%x) is not handled",
 			 ctrl->id, ctrl->val);
 		break;
@@ -823,75 +789,75 @@ static int imx355_start_streaming(struct imx355 *imx355)
 	crop = v4l2_subdev_state_get_crop(state, 0);
 	mode = v4l2_find_nearest_size(supported_modes,
 				      ARRAY_SIZE(supported_modes),
 				      width, height, fmt->width, fmt->height);
 	cci_multi_reg_write(imx355->regmap, mode->reg_list.regs,
 			    mode->reg_list.num_of_regs, &ret);
 
 	/* Set readout crop and size registers  */
-	cci_write(imx355->regmap, IMX355_REG_X_ADD_START, crop->left,
+	cci_write(imx355->regmap, CCS_R_X_ADDR_START, crop->left,
 		  &ret);
-	cci_write(imx355->regmap, IMX355_REG_Y_ADD_START, crop->top, &ret);
-	cci_write(imx355->regmap, IMX355_REG_X_ADD_END,
+	cci_write(imx355->regmap, CCS_R_Y_ADDR_START, crop->top, &ret);
+	cci_write(imx355->regmap, CCS_R_X_ADDR_END,
 		  crop->width + crop->left - 1, &ret);
-	cci_write(imx355->regmap, IMX355_REG_Y_ADD_END,
+	cci_write(imx355->regmap, CCS_R_Y_ADDR_END,
 		  crop->height + crop->top - 1, &ret);
-	cci_write(imx355->regmap, IMX355_REG_X_OUT_SIZE, fmt->width, &ret);
-	cci_write(imx355->regmap, IMX355_REG_Y_OUT_SIZE, fmt->height, &ret);
+	cci_write(imx355->regmap, CCS_R_X_OUTPUT_SIZE, fmt->width, &ret);
+	cci_write(imx355->regmap, CCS_R_Y_OUTPUT_SIZE, fmt->height, &ret);
 
 	binning_mode = ((crop->width / fmt->width) << 4) |
 			(crop->height / fmt->height);
-	cci_write(imx355->regmap, IMX355_REG_BINNING_MODE,
+	cci_write(imx355->regmap, CCS_R_BINNING_MODE,
 		  binning_mode == 0x11 ? 0x00 : 0x01, &ret);
-	cci_write(imx355->regmap, IMX355_REG_BINNING_TYPE, binning_mode, &ret);
-	cci_write(imx355->regmap, IMX355_REG_BINNING_WEIGHTING, 0x00, &ret);
+	cci_write(imx355->regmap, CCS_R_BINNING_TYPE, binning_mode, &ret);
+	cci_write(imx355->regmap, CCS_R_BINNING_WEIGHTING, 0x00, &ret);
 
 	/* Set PLL registers for the external clock frequency */
-	cci_write(imx355->regmap, IMX355_REG_EXTCLK_FREQ,
+	cci_write(imx355->regmap, CCS_R_EXTCLK_FREQUENCY_MHZ,
 		  imx355->clk_params->extclk_freq, &ret);
-	cci_write(imx355->regmap, IMX355_REG_PLL_OP_MUL,
+	cci_write(imx355->regmap, CCS_R_OP_PLL_MULTIPLIER,
 		  imx355->clk_params->pll_op_mpy[lane_idx], &ret);
 	cci_write(imx355->regmap, IMX355_REG_PLL_OP_PREDIV,
 		  imx355->clk_params->pll_op_prediv[lane_idx], &ret);
 	cci_write(imx355->regmap, IMX355_REG_PLL_IVT_SYSCK_DIV,
 		  lane_idx ? 2 : 1, &ret);
 
 	/* Set MIPI configuration */
-	cci_write(imx355->regmap, IMX355_REG_LANE_SEL,
+	cci_write(imx355->regmap, CCS_R_CSI_LANE_MODE,
 		  imx355->hwcfg->num_lanes - 1, &ret);
 
 	link_bitrate = imx355->link_freq->qmenu_int[imx355->link_freq->val] *
 		       imx355->hwcfg->num_lanes * 2;
 	do_div(link_bitrate, 1000000);
 	cci_write(imx355->regmap, IMX355_REG_REQ_LINK_BIT_RATE, link_bitrate,
 		  &ret);
 
 	/* set digital gain control to all color mode */
 	cci_write(imx355->regmap, IMX355_REG_DPGA_USE_GLOBAL_GAIN, 1, &ret);
 
 	/* set line length */
-	cci_write(imx355->regmap, IMX355_REG_LLP,
+	cci_write(imx355->regmap, CCS_R_LINE_LENGTH_PCK,
 		  imx355->hblank->val + fmt->width, &ret);
 
 	/* Apply customized values from user */
 	if (!ret)
 		ret = __v4l2_ctrl_handler_setup(imx355->sd.ctrl_handler);
 
-	cci_write(imx355->regmap, IMX355_REG_MODE_SELECT, IMX355_MODE_STREAMING,
+	cci_write(imx355->regmap, CCS_R_MODE_SELECT, CCS_MODE_SELECT_STREAMING,
 		  &ret);
 
 	return ret;
 }
 
 /* Stop streaming */
 static int imx355_stop_streaming(struct imx355 *imx355)
 {
-	return cci_write(imx355->regmap, IMX355_REG_MODE_SELECT,
-			 IMX355_MODE_STANDBY, NULL);
+	return cci_write(imx355->regmap, CCS_R_MODE_SELECT,
+			 CCS_MODE_SELECT_SOFTWARE_STANDBY, NULL);
 }
 
 static int imx355_set_stream(struct v4l2_subdev *sd, int enable)
 {
 	struct imx355 *imx355 = to_imx355(sd);
 	struct v4l2_subdev_state *state;
 	int ret = 0;
 
@@ -931,17 +897,17 @@ static int imx355_set_stream(struct v4l2_subdev *sd, int enable)
 }
 
 /* Verify chip ID */
 static int imx355_identify_module(struct imx355 *imx355)
 {
 	int ret;
 	u64 val;
 
-	ret = cci_read(imx355->regmap, IMX355_REG_CHIP_ID, &val, NULL);
+	ret = cci_read(imx355->regmap, CCS_R_SENSOR_MODEL_ID, &val, NULL);
 	if (ret)
 		return ret;
 
 	if (val != IMX355_CHIP_ID) {
 		dev_err(imx355->dev, "chip id mismatch: %x!=%llx",
 			IMX355_CHIP_ID, val);
 		return -EIO;
 	}

---
base-commit: 5453bc3279e9f8578ac3e534d476240e40c879e1
change-id: 20260819-imx355-ccsify-856c850575f1

Best regards,
--  
David Heidelberg <david@ixit.cz>

