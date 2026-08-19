From: David Heidelberg <david@ixit.cz>
Date: Wed, 19 Aug 2026 22:17:08 +0200
Subject: [PATCH RFC] media: imx355: reuse existing CCS defines
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260819-imx355-ccsify-v1-1-0b6cef77e340@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDC0NL3czcCmNTU93k5OLMtEpdC1OzZAtTA1Nz0zRDJaCegqLUtMwKsHn
 RSkFuzkqxEMHi0qSs1OQSkElKtbUAVQ+ouHYAAAA=
X-Change-ID: 20260819-imx355-ccsify-856c850575f1
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=7626; i=david@ixit.cz;
 h=from:subject:message-id; bh=Kb/HQ6WuSE/P7jxZPeyXPYdrpcDOJkmCNEEtRhs5294=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqhg9KN3QVeimZ0uMcMRhOYh4MfsiqDL028DpoE
 nxAClKWkmqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaoYPSgAKCRBgAj/E00kg
 csE2D/4u2zwUSD4Qe7dwcH8NnKzU6krcYZuAWLdvByD5g8PFGZelS4OOD4mtFJYQ8/h2ndQQvZo
 DEi25kKeBlOHlQVA67MGESwQ/m2fMItgGMzTN6UsMe3iLLVA/4Rtd++vYa/Y6fVmnlqYABAeM9j
 eYKJBjZwOkhKuRhIUdyPkmduDX9dioLzER9m6IQHzZsnjCkDk9RJjsdlLEewPv1ac0XcsFY20qd
 rblusCaiw39/7fnMqRYdmRGbBbfaCwKRjdQiHidaJZZaEXvCzbmz1oGF5QC8YKmWP1YQh5wdiHW
 iBYBSrHA+V2kcjBeW/zFVFdgpVo3b6CB8ipFi/thRdlQluqXcar4mceKqzgnxY5ms0qYVk6ugCE
 Ihn1meLxZ/vtV/hPpgGFlUtKGuE8xkC3BvEG4yNfawZ4zxthYl7mcpVniD/tWJSI2dfx9Ny3v45
 zSqlx0JfA5stjEJYC16sPtArYJ01vfSSbNsV0Oots7XVJAw5LVW6A3/ryjG+nF9saH2xQk0NRDf
 0KKfZxug8wDGdQveahFDPQAtNGFGxHfT++TrBhBP6zmk0njYN1Sxa1j8vDZtO5m0ZoqtQaTKbq7
 KoIMQHeBZAhhdeUqq1+sQXlxCc9rcMU/bcRNYRZeOyTaY1L0+zX6ZtyYGT+FCm0iX670POj9m98
 7owwr16hhWel7Xg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver may not be MIPU CCS compliant, but does use same address and
often set same values as compliant drivers. Do not define for every Sony
imx* driver registers we already know and are standard.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
I'm sending this as RFC, because we'll need to upstream at least 4 - 6
drivers, which aren't compliant with MIPI CCS. Quirking these drivers in
mipi-ccs would be pointless, thou we could at least simplify and unify
what needs to be separate.

Thanks for the feedback, just did few lines for the idea how the final
changes will look like. Anything ambiguous will be left as is.
---
 drivers/media/i2c/imx355.c | 46 +++++++++++++++-------------------------------
 1 file changed, 15 insertions(+), 31 deletions(-)

diff --git a/drivers/media/i2c/imx355.c b/drivers/media/i2c/imx355.c
index 8eb8588cb71bb..57f7c70d18453 100644
--- a/drivers/media/i2c/imx355.c
+++ b/drivers/media/i2c/imx355.c
@@ -14,50 +14,34 @@
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
 #define IMX355_REG_EXTCLK_FREQ		CCI_REG16(0x0136)
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
 #define IMX355_REG_EXPOSURE		CCI_REG16(0x0202)
 #define IMX355_EXPOSURE_MIN		1
 #define IMX355_EXPOSURE_STEP		1
 #define IMX355_EXPOSURE_DEFAULT		0x0282
 #define IMX355_EXPOSURE_OFFSET		10
 
 /* Analog gain control */
@@ -629,17 +613,17 @@ static int imx355_set_ctrl(struct v4l2_ctrl *ctrl)
 				ctrl->val, NULL);
 		break;
 	case V4L2_CID_EXPOSURE:
 		ret = cci_write(imx355->regmap, IMX355_REG_EXPOSURE,
 				ctrl->val, NULL);
 		break;
 	case V4L2_CID_VBLANK:
 		/* Update FLL that meets expected vertical blanking */
-		ret = cci_write(imx355->regmap, IMX355_REG_FLL,
+		ret = cci_write(imx355->regmap, CCS_R_FRAME_LENGTH_LINES,
 				format->height + ctrl->val, NULL);
 		break;
 	case V4L2_CID_TEST_PATTERN:
 		ret = cci_write(imx355->regmap, IMX355_REG_TEST_PATTERN,
 				ctrl->val, NULL);
 		break;
 	case V4L2_CID_HFLIP:
 	case V4L2_CID_VFLIP:
@@ -823,75 +807,75 @@ static int imx355_start_streaming(struct imx355 *imx355)
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
 	cci_write(imx355->regmap, IMX355_REG_BINNING_MODE,
 		  binning_mode == 0x11 ? 0x00 : 0x01, &ret);
 	cci_write(imx355->regmap, IMX355_REG_BINNING_TYPE, binning_mode, &ret);
 	cci_write(imx355->regmap, IMX355_REG_BINNING_WEIGHTING, 0x00, &ret);
 
 	/* Set PLL registers for the external clock frequency */
 	cci_write(imx355->regmap, IMX355_REG_EXTCLK_FREQ,
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
 
@@ -931,17 +915,17 @@ static int imx355_set_stream(struct v4l2_subdev *sd, int enable)
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

