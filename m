From: David Heidelberg <david@ixit.cz>
Date: Sun, 08 Nov 2026 12:17:25 +0000
Subject: [PATCH v3 2/2] media: imx258: Reuse existing CCS defines
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-imx355-ccsify-v3-2-366ce7ae1bef@ixit.cz>
References: <20261108-imx355-ccsify-v3-0-366ce7ae1bef@ixit.cz>
In-Reply-To: <20261108-imx355-ccsify-v3-0-366ce7ae1bef@ixit.cz>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: Jai Luthra <jai.luthra@ideasonboard.com>, linux-media@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=20747; i=david@ixit.cz;
 h=from:subject:message-id; bh=uIR21wrEB4MN4gmhs1AEt4JnqKyYA1wf3dfn1f2BCkE=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq8GhXVyRCiVPeEX3MZnSrqFIzM1mUhJBTPWqHZ
 1C8z5rwpgGJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCavBoVwAKCRBgAj/E00kg
 cnqXEACweR52yE51xGqUswCftkBhbEhPRF20E/Q1dWM94UBy/Y3nUZX6rj3w84U0V/k1aMbvtDu
 SxXkghU9qReSq5emp4zp48mbUkx4/9s4JKQ54n4HzRtwowYnoW3Mq5CUb0pAXTRZC401PnLl49Y
 fqWi/BPutHQD614Mu8B6VAV9P9GKkCLlJUTi4s9XtyFhDWlnUqRIgJjOi84oED1t3T4vlRl+HRT
 YS7ZDg3Mv7pnKOSiAEjlTJMWlrPPmWJYE1njQKiio9QKEOu5RtWxKZ8AzrxoqSy45A68n0d3eCz
 tPRhDngbGMtGTGzm9um1gG47MAU3o+ULbvQ7+VX3+gRi7hpvzl6iY03I8xF+dsCLfxH66UeUtUU
 4KKgIlzzPrfFvsgeLpUtK9y+s6uHg+xmjyekL3puVBU97ice2qfi0q6qqN7vnX1LsLxiVDKcSsh
 e8taE3QLilYd4tZ8iBnEgUqFrfCRIDHtMu98DCWL5IHMwxkrPvejZI7q5ey2HxxGoMtWxYEdwFg
 8u0uZFG4FXnoiaWbVWIfz8rcoCK8OBUYEqF6qb5M8FYiUWXEk5CaLPEZJ8AxehDRTJGOv/5GqBG
 92ad2qNAjw+75V3X+1nyrljcSrIWdqxELilVeNqCc/NWak4LA43HqOJnBU5nGiTqneTyVPxGrWN
 tMnTP3l6e9qgJxw==
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
 drivers/media/i2c/imx258.c | 218 +++++++++++++++++++--------------------------
 1 file changed, 90 insertions(+), 128 deletions(-)

diff --git a/drivers/media/i2c/imx258.c b/drivers/media/i2c/imx258.c
index 065c33380f60c..231ab0037579a 100644
--- a/drivers/media/i2c/imx258.c
+++ b/drivers/media/i2c/imx258.c
@@ -10,128 +10,89 @@
 #include <linux/regulator/consumer.h>
 #include <linux/unaligned.h>
 
 #include <media/v4l2-cci.h>
 #include <media/v4l2-ctrls.h>
 #include <media/v4l2-device.h>
 #include <media/v4l2-fwnode.h>
 
-#define IMX258_REG_MODE_SELECT		CCI_REG8(0x0100)
-#define IMX258_MODE_STANDBY		0x00
-#define IMX258_MODE_STREAMING		0x01
-
-#define IMX258_REG_RESET		CCI_REG8(0x0103)
+#include "ccs/ccs-regs.h"
 
 /* Chip ID */
-#define IMX258_REG_CHIP_ID		CCI_REG16(0x0016)
 #define IMX258_CHIP_ID			0x0258
 
 /* V_TIMING internal */
 #define IMX258_VTS_30FPS		0x0c50
 #define IMX258_VTS_30FPS_2K		0x0638
 #define IMX258_VTS_30FPS_VGA		0x034c
 #define IMX258_VTS_MAX			65525
 
 /* HBLANK control - read only */
 #define IMX258_PPL_DEFAULT		5352
 
 /* Exposure control */
-#define IMX258_REG_EXPOSURE		CCI_REG16(0x0202)
 #define IMX258_EXPOSURE_OFFSET		10
 #define IMX258_EXPOSURE_MIN		4
 #define IMX258_EXPOSURE_STEP		1
 #define IMX258_EXPOSURE_DEFAULT		0x640
 #define IMX258_EXPOSURE_MAX		(IMX258_VTS_MAX - IMX258_EXPOSURE_OFFSET)
 
 /* Analog gain control */
-#define IMX258_REG_ANALOG_GAIN		CCI_REG16(0x0204)
 #define IMX258_ANA_GAIN_MIN		0
 #define IMX258_ANA_GAIN_MAX		480
 #define IMX258_ANA_GAIN_STEP		1
 #define IMX258_ANA_GAIN_DEFAULT		0x0
 
 /* Digital gain control */
 #define IMX258_REG_GR_DIGITAL_GAIN	CCI_REG16(0x020e)
 #define IMX258_REG_R_DIGITAL_GAIN	CCI_REG16(0x0210)
 #define IMX258_REG_B_DIGITAL_GAIN	CCI_REG16(0x0212)
 #define IMX258_REG_GB_DIGITAL_GAIN	CCI_REG16(0x0214)
 #define IMX258_DGTL_GAIN_MIN		0
 #define IMX258_DGTL_GAIN_MAX		4096	/* Max = 0xFFF */
 #define IMX258_DGTL_GAIN_DEFAULT	1024
 #define IMX258_DGTL_GAIN_STEP		1
 
 /* HDR control */
-#define IMX258_REG_HDR			CCI_REG8(0x0220)
-#define IMX258_HDR_ON			BIT(0)
-#define IMX258_REG_HDR_RATIO		CCI_REG8(0x0222)
 #define IMX258_HDR_RATIO_MIN		0
 #define IMX258_HDR_RATIO_MAX		5
 #define IMX258_HDR_RATIO_STEP		1
 #define IMX258_HDR_RATIO_DEFAULT	0x0
 
-/* Test Pattern Control */
-#define IMX258_REG_TEST_PATTERN		CCI_REG16(0x0600)
-
 #define IMX258_CLK_BLANK_STOP		CCI_REG8(0x4040)
 
-/* Orientation */
-#define REG_MIRROR_FLIP_CONTROL		CCI_REG8(0x0101)
-#define REG_CONFIG_MIRROR_HFLIP		0x01
-#define REG_CONFIG_MIRROR_VFLIP		0x02
-
 /* IMX258 native and active pixel array size. */
 #define IMX258_NATIVE_WIDTH		4224U
 #define IMX258_NATIVE_HEIGHT		3192U
 #define IMX258_PIXEL_ARRAY_LEFT		8U
 #define IMX258_PIXEL_ARRAY_TOP		16U
 #define IMX258_PIXEL_ARRAY_WIDTH	4208U
 #define IMX258_PIXEL_ARRAY_HEIGHT	3120U
 
 /* regs */
-#define IMX258_REG_PLL_MULT_DRIV                  CCI_REG8(0x0310)
 #define IMX258_REG_IVTPXCK_DIV                    CCI_REG8(0x0301)
 #define IMX258_REG_IVTSYCK_DIV                    CCI_REG8(0x0303)
 #define IMX258_REG_PREPLLCK_VT_DIV                CCI_REG8(0x0305)
 #define IMX258_REG_IOPPXCK_DIV                    CCI_REG8(0x0309)
 #define IMX258_REG_IOPSYCK_DIV                    CCI_REG8(0x030b)
 #define IMX258_REG_PREPLLCK_OP_DIV                CCI_REG8(0x030d)
 #define IMX258_REG_PHASE_PIX_OUTEN                CCI_REG8(0x3030)
 #define IMX258_REG_PDPIX_DATA_RATE                CCI_REG8(0x3032)
 #define IMX258_REG_SCALE_MODE                     CCI_REG8(0x0401)
 #define IMX258_REG_SCALE_MODE_EXT                 CCI_REG8(0x3038)
 #define IMX258_REG_AF_WINDOW_MODE                 CCI_REG8(0x7bcd)
-#define IMX258_REG_FRM_LENGTH_CTL                 CCI_REG8(0x0350)
-#define IMX258_REG_CSI_LANE_MODE                  CCI_REG8(0x0114)
 #define IMX258_REG_X_EVN_INC                      CCI_REG8(0x0381)
 #define IMX258_REG_X_ODD_INC                      CCI_REG8(0x0383)
 #define IMX258_REG_Y_EVN_INC                      CCI_REG8(0x0385)
 #define IMX258_REG_Y_ODD_INC                      CCI_REG8(0x0387)
-#define IMX258_REG_BINNING_MODE                   CCI_REG8(0x0900)
-#define IMX258_REG_BINNING_TYPE_V                 CCI_REG8(0x0901)
 #define IMX258_REG_FORCE_FD_SUM                   CCI_REG8(0x300d)
-#define IMX258_REG_DIG_CROP_X_OFFSET              CCI_REG16(0x0408)
-#define IMX258_REG_DIG_CROP_Y_OFFSET              CCI_REG16(0x040a)
-#define IMX258_REG_DIG_CROP_IMAGE_WIDTH           CCI_REG16(0x040c)
-#define IMX258_REG_DIG_CROP_IMAGE_HEIGHT          CCI_REG16(0x040e)
-#define IMX258_REG_SCALE_M                        CCI_REG16(0x0404)
-#define IMX258_REG_X_OUT_SIZE                     CCI_REG16(0x034c)
-#define IMX258_REG_Y_OUT_SIZE                     CCI_REG16(0x034e)
-#define IMX258_REG_X_ADD_STA                      CCI_REG16(0x0344)
-#define IMX258_REG_Y_ADD_STA                      CCI_REG16(0x0346)
-#define IMX258_REG_X_ADD_END                      CCI_REG16(0x0348)
-#define IMX258_REG_Y_ADD_END                      CCI_REG16(0x034a)
-#define IMX258_REG_EXCK_FREQ                      CCI_REG16(0x0136)
-#define IMX258_REG_CSI_DT_FMT                     CCI_REG16(0x0112)
-#define IMX258_REG_LINE_LENGTH_PCK                CCI_REG16(0x0342)
 #define IMX258_REG_SCALE_M_EXT                    CCI_REG16(0x303a)
-#define IMX258_REG_FRM_LENGTH_LINES               CCI_REG16(0x0340)
 #define IMX258_REG_FINE_INTEG_TIME                CCI_REG8(0x0200)
-#define IMX258_REG_PLL_IVT_MPY                    CCI_REG16(0x0306)
-#define IMX258_REG_PLL_IOP_MPY                    CCI_REG16(0x030e)
+/* Link rate registers: two 16-bit halves, unlike the CCS 32-bit one */
 #define IMX258_REG_REQ_LINK_BIT_RATE_MBPS_H       CCI_REG16(0x0820)
 #define IMX258_REG_REQ_LINK_BIT_RATE_MBPS_L       CCI_REG16(0x0822)
 
 struct imx258_reg_list {
 	u32 num_of_regs;
 	const struct cci_reg_sequence *regs;
 };
 
@@ -175,147 +136,147 @@ struct imx258_mode {
 };
 
 /*
  * 4208x3120 @ 30 fps needs 1267Mbps/lane, 4 lanes.
  * To avoid further computation of clock settings, adopt the same per
  * lane data rate when using 2 lanes, thus allowing a maximum of 15fps.
  */
 static const struct cci_reg_sequence mipi_1267mbps_19_2mhz_2l[] = {
-	{ IMX258_REG_EXCK_FREQ, 0x1333 },
+	{ CCS_R_EXTCLK_FREQUENCY_MHZ, 0x1333 },
 	{ IMX258_REG_IVTPXCK_DIV, 10 },
 	{ IMX258_REG_IVTSYCK_DIV, 2 },
 	{ IMX258_REG_PREPLLCK_VT_DIV, 3 },
-	{ IMX258_REG_PLL_IVT_MPY, 198 },
+	{ CCS_R_PLL_MULTIPLIER, 198 },
 	{ IMX258_REG_IOPPXCK_DIV, 10 },
 	{ IMX258_REG_IOPSYCK_DIV, 1 },
 	{ IMX258_REG_PREPLLCK_OP_DIV, 2 },
-	{ IMX258_REG_PLL_IOP_MPY, 216 },
-	{ IMX258_REG_PLL_MULT_DRIV, 0 },
+	{ CCS_R_OP_PLL_MULTIPLIER, 216 },
+	{ CCS_R_PLL_MODE, 0 },
 
-	{ IMX258_REG_CSI_LANE_MODE, 1 },
+	{ CCS_R_CSI_LANE_MODE, 1 },
 	{ IMX258_REG_REQ_LINK_BIT_RATE_MBPS_H, 1267 * 2 },
 	{ IMX258_REG_REQ_LINK_BIT_RATE_MBPS_L, 0 },
 };
 
 static const struct cci_reg_sequence mipi_1267mbps_19_2mhz_4l[] = {
-	{ IMX258_REG_EXCK_FREQ, 0x1333 },
+	{ CCS_R_EXTCLK_FREQUENCY_MHZ, 0x1333 },
 	{ IMX258_REG_IVTPXCK_DIV, 5 },
 	{ IMX258_REG_IVTSYCK_DIV, 2 },
 	{ IMX258_REG_PREPLLCK_VT_DIV, 3 },
-	{ IMX258_REG_PLL_IVT_MPY, 198 },
+	{ CCS_R_PLL_MULTIPLIER, 198 },
 	{ IMX258_REG_IOPPXCK_DIV, 10 },
 	{ IMX258_REG_IOPSYCK_DIV, 1 },
 	{ IMX258_REG_PREPLLCK_OP_DIV, 2 },
-	{ IMX258_REG_PLL_IOP_MPY, 216 },
-	{ IMX258_REG_PLL_MULT_DRIV, 0 },
+	{ CCS_R_OP_PLL_MULTIPLIER, 216 },
+	{ CCS_R_PLL_MODE, 0 },
 
-	{ IMX258_REG_CSI_LANE_MODE, 3 },
+	{ CCS_R_CSI_LANE_MODE, 3 },
 	{ IMX258_REG_REQ_LINK_BIT_RATE_MBPS_H, 1267 * 4 },
 	{ IMX258_REG_REQ_LINK_BIT_RATE_MBPS_L, 0 },
 };
 
 static const struct cci_reg_sequence mipi_1272mbps_24mhz_2l[] = {
-	{ IMX258_REG_EXCK_FREQ, 0x1800 },
+	{ CCS_R_EXTCLK_FREQUENCY_MHZ, 0x1800 },
 	{ IMX258_REG_IVTPXCK_DIV, 10 },
 	{ IMX258_REG_IVTSYCK_DIV, 2 },
 	{ IMX258_REG_PREPLLCK_VT_DIV, 4 },
-	{ IMX258_REG_PLL_IVT_MPY, 212 },
+	{ CCS_R_PLL_MULTIPLIER, 212 },
 	{ IMX258_REG_IOPPXCK_DIV, 10 },
 	{ IMX258_REG_IOPSYCK_DIV, 1 },
 	{ IMX258_REG_PREPLLCK_OP_DIV, 2 },
-	{ IMX258_REG_PLL_IOP_MPY, 216 },
-	{ IMX258_REG_PLL_MULT_DRIV, 0 },
+	{ CCS_R_OP_PLL_MULTIPLIER, 216 },
+	{ CCS_R_PLL_MODE, 0 },
 
-	{ IMX258_REG_CSI_LANE_MODE, 1 },
+	{ CCS_R_CSI_LANE_MODE, 1 },
 	{ IMX258_REG_REQ_LINK_BIT_RATE_MBPS_H, 1272 * 2 },
 	{ IMX258_REG_REQ_LINK_BIT_RATE_MBPS_L, 0 },
 };
 
 static const struct cci_reg_sequence mipi_1272mbps_24mhz_4l[] = {
-	{ IMX258_REG_EXCK_FREQ, 0x1800 },
+	{ CCS_R_EXTCLK_FREQUENCY_MHZ, 0x1800 },
 	{ IMX258_REG_IVTPXCK_DIV, 5 },
 	{ IMX258_REG_IVTSYCK_DIV, 2 },
 	{ IMX258_REG_PREPLLCK_VT_DIV, 4 },
-	{ IMX258_REG_PLL_IVT_MPY, 212 },
+	{ CCS_R_PLL_MULTIPLIER, 212 },
 	{ IMX258_REG_IOPPXCK_DIV, 10 },
 	{ IMX258_REG_IOPSYCK_DIV, 1 },
 	{ IMX258_REG_PREPLLCK_OP_DIV, 2 },
-	{ IMX258_REG_PLL_IOP_MPY, 216 },
-	{ IMX258_REG_PLL_MULT_DRIV, 0 },
+	{ CCS_R_OP_PLL_MULTIPLIER, 216 },
+	{ CCS_R_PLL_MODE, 0 },
 
-	{ IMX258_REG_CSI_LANE_MODE, 3 },
+	{ CCS_R_CSI_LANE_MODE, 3 },
 	{ IMX258_REG_REQ_LINK_BIT_RATE_MBPS_H, 1272 * 4 },
 	{ IMX258_REG_REQ_LINK_BIT_RATE_MBPS_L, 0 },
 };
 
 static const struct cci_reg_sequence mipi_640mbps_19_2mhz_2l[] = {
-	{ IMX258_REG_EXCK_FREQ, 0x1333 },
+	{ CCS_R_EXTCLK_FREQUENCY_MHZ, 0x1333 },
 	{ IMX258_REG_IVTPXCK_DIV, 5 },
 	{ IMX258_REG_IVTSYCK_DIV, 2 },
 	{ IMX258_REG_PREPLLCK_VT_DIV, 3 },
-	{ IMX258_REG_PLL_IVT_MPY, 100 },
+	{ CCS_R_PLL_MULTIPLIER, 100 },
 	{ IMX258_REG_IOPPXCK_DIV, 10 },
 	{ IMX258_REG_IOPSYCK_DIV, 1 },
 	{ IMX258_REG_PREPLLCK_OP_DIV, 2 },
-	{ IMX258_REG_PLL_IOP_MPY, 216 },
-	{ IMX258_REG_PLL_MULT_DRIV, 0 },
+	{ CCS_R_OP_PLL_MULTIPLIER, 216 },
+	{ CCS_R_PLL_MODE, 0 },
 
-	{ IMX258_REG_CSI_LANE_MODE, 1 },
+	{ CCS_R_CSI_LANE_MODE, 1 },
 	{ IMX258_REG_REQ_LINK_BIT_RATE_MBPS_H, 640 * 2 },
 	{ IMX258_REG_REQ_LINK_BIT_RATE_MBPS_L, 0 },
 };
 
 static const struct cci_reg_sequence mipi_640mbps_19_2mhz_4l[] = {
-	{ IMX258_REG_EXCK_FREQ, 0x1333 },
+	{ CCS_R_EXTCLK_FREQUENCY_MHZ, 0x1333 },
 	{ IMX258_REG_IVTPXCK_DIV, 5 },
 	{ IMX258_REG_IVTSYCK_DIV, 2 },
 	{ IMX258_REG_PREPLLCK_VT_DIV, 3 },
-	{ IMX258_REG_PLL_IVT_MPY, 100 },
+	{ CCS_R_PLL_MULTIPLIER, 100 },
 	{ IMX258_REG_IOPPXCK_DIV, 10 },
 	{ IMX258_REG_IOPSYCK_DIV, 1 },
 	{ IMX258_REG_PREPLLCK_OP_DIV, 2 },
-	{ IMX258_REG_PLL_IOP_MPY, 216 },
-	{ IMX258_REG_PLL_MULT_DRIV, 0 },
+	{ CCS_R_OP_PLL_MULTIPLIER, 216 },
+	{ CCS_R_PLL_MODE, 0 },
 
-	{ IMX258_REG_CSI_LANE_MODE, 3 },
+	{ CCS_R_CSI_LANE_MODE, 3 },
 	{ IMX258_REG_REQ_LINK_BIT_RATE_MBPS_H, 640 * 4 },
 	{ IMX258_REG_REQ_LINK_BIT_RATE_MBPS_L, 0 },
 };
 
 static const struct cci_reg_sequence mipi_642mbps_24mhz_2l[] = {
-	{ IMX258_REG_EXCK_FREQ, 0x1800 },
+	{ CCS_R_EXTCLK_FREQUENCY_MHZ, 0x1800 },
 	{ IMX258_REG_IVTPXCK_DIV, 5 },
 	{ IMX258_REG_IVTSYCK_DIV, 2 },
 	{ IMX258_REG_PREPLLCK_VT_DIV, 4 },
-	{ IMX258_REG_PLL_IVT_MPY, 107 },
+	{ CCS_R_PLL_MULTIPLIER, 107 },
 	{ IMX258_REG_IOPPXCK_DIV, 10 },
 	{ IMX258_REG_IOPSYCK_DIV, 1 },
 	{ IMX258_REG_PREPLLCK_OP_DIV, 2 },
-	{ IMX258_REG_PLL_IOP_MPY, 216 },
-	{ IMX258_REG_PLL_MULT_DRIV, 0 },
+	{ CCS_R_OP_PLL_MULTIPLIER, 216 },
+	{ CCS_R_PLL_MODE, 0 },
 
-	{ IMX258_REG_CSI_LANE_MODE, 1 },
+	{ CCS_R_CSI_LANE_MODE, 1 },
 	{ IMX258_REG_REQ_LINK_BIT_RATE_MBPS_H, 642 * 2 },
 	{ IMX258_REG_REQ_LINK_BIT_RATE_MBPS_L, 0 },
 };
 
 static const struct cci_reg_sequence mipi_642mbps_24mhz_4l[] = {
-	{ IMX258_REG_EXCK_FREQ, 0x1800 },
+	{ CCS_R_EXTCLK_FREQUENCY_MHZ, 0x1800 },
 	{ IMX258_REG_IVTPXCK_DIV, 5 },
 	{ IMX258_REG_IVTSYCK_DIV, 2 },
 	{ IMX258_REG_PREPLLCK_VT_DIV, 4 },
-	{ IMX258_REG_PLL_IVT_MPY, 107 },
+	{ CCS_R_PLL_MULTIPLIER, 107 },
 	{ IMX258_REG_IOPPXCK_DIV, 10 },
 	{ IMX258_REG_IOPSYCK_DIV, 1 },
 	{ IMX258_REG_PREPLLCK_OP_DIV, 2 },
-	{ IMX258_REG_PLL_IOP_MPY, 216 },
-	{ IMX258_REG_PLL_MULT_DRIV, 0 },
+	{ CCS_R_OP_PLL_MULTIPLIER, 216 },
+	{ CCS_R_PLL_MODE, 0 },
 
-	{ IMX258_REG_CSI_LANE_MODE, 3 },
+	{ CCS_R_CSI_LANE_MODE, 3 },
 	{ IMX258_REG_REQ_LINK_BIT_RATE_MBPS_H, 642 * 4 },
 	{ IMX258_REG_REQ_LINK_BIT_RATE_MBPS_L, 0 },
 };
 
 static const struct cci_reg_sequence mode_common_regs[] = {
 	{ CCI_REG8(0x3051), 0x00 },
 	{ CCI_REG8(0x6B11), 0xCF },
 	{ CCI_REG8(0x7FF0), 0x08 },
@@ -353,34 +314,34 @@ static const struct cci_reg_sequence mode_common_regs[] = {
 	{ CCI_REG8(0x9104), 0x00 },
 	{ CCI_REG8(0x4648), 0x7F },
 	{ CCI_REG8(0x7420), 0x00 },
 	{ CCI_REG8(0x7421), 0x1C },
 	{ CCI_REG8(0x7422), 0x00 },
 	{ CCI_REG8(0x7423), 0xD7 },
 	{ CCI_REG8(0x5F04), 0x00 },
 	{ CCI_REG8(0x5F05), 0xED },
-	{IMX258_REG_CSI_DT_FMT, 0x0a0a},
-	{IMX258_REG_LINE_LENGTH_PCK, 5352},
-	{IMX258_REG_X_ADD_STA, 0},
-	{IMX258_REG_Y_ADD_STA, 0},
-	{IMX258_REG_X_ADD_END, 4207},
-	{IMX258_REG_Y_ADD_END, 3119},
+	{CCS_R_CSI_DATA_FORMAT, 0x0a0a},
+	{CCS_R_LINE_LENGTH_PCK, 5352},
+	{CCS_R_X_ADDR_START, 0},
+	{CCS_R_Y_ADDR_START, 0},
+	{CCS_R_X_ADDR_END, 4207},
+	{CCS_R_Y_ADDR_END, 3119},
 	{IMX258_REG_X_EVN_INC, 1},
 	{IMX258_REG_X_ODD_INC, 1},
 	{IMX258_REG_Y_EVN_INC, 1},
 	{IMX258_REG_Y_ODD_INC, 1},
-	{IMX258_REG_DIG_CROP_X_OFFSET, 0},
-	{IMX258_REG_DIG_CROP_Y_OFFSET, 0},
-	{IMX258_REG_DIG_CROP_IMAGE_WIDTH, 4208},
+	{CCS_R_DIGITAL_CROP_X_OFFSET, 0},
+	{CCS_R_DIGITAL_CROP_Y_OFFSET, 0},
+	{CCS_R_DIGITAL_CROP_IMAGE_WIDTH, 4208},
 	{IMX258_REG_SCALE_MODE_EXT, 0},
 	{IMX258_REG_SCALE_M_EXT, 16},
 	{IMX258_REG_FORCE_FD_SUM, 0},
-	{IMX258_REG_FRM_LENGTH_CTL, 0},
-	{IMX258_REG_ANALOG_GAIN, 0},
+	{CCS_R_FRAME_LENGTH_CTRL, 0},
+	{CCS_R_ANALOG_GAIN_CODE_GLOBAL, 0},
 	{IMX258_REG_GR_DIGITAL_GAIN, 256},
 	{IMX258_REG_R_DIGITAL_GAIN, 256},
 	{IMX258_REG_B_DIGITAL_GAIN, 256},
 	{IMX258_REG_GB_DIGITAL_GAIN, 256},
 	{IMX258_REG_AF_WINDOW_MODE, 0},
 	{ CCI_REG8(0x94DC), 0x20 },
 	{ CCI_REG8(0x94DD), 0x20 },
 	{ CCI_REG8(0x94DE), 0x20 },
@@ -390,47 +351,47 @@ static const struct cci_reg_sequence mode_common_regs[] = {
 	{ CCI_REG8(0x7FB0), 0x00 },
 	{ CCI_REG8(0x9010), 0x3E },
 	{ CCI_REG8(0x9419), 0x50 },
 	{ CCI_REG8(0x941B), 0x50 },
 	{ CCI_REG8(0x9519), 0x50 },
 	{ CCI_REG8(0x951B), 0x50 },
 	{IMX258_REG_PHASE_PIX_OUTEN, 0},
 	{IMX258_REG_PDPIX_DATA_RATE, 0},
-	{IMX258_REG_HDR, 0},
+	{CCS_R_HDR_MODE, 0},
 };
 
 static const struct cci_reg_sequence mode_4208x3120_regs[] = {
-	{IMX258_REG_BINNING_MODE, 0},
-	{IMX258_REG_BINNING_TYPE_V, 0x11},
+	{CCS_R_BINNING_MODE, 0},
+	{CCS_R_BINNING_TYPE, 0x11},
 	{IMX258_REG_SCALE_MODE, 0},
-	{IMX258_REG_SCALE_M, 16},
-	{IMX258_REG_DIG_CROP_IMAGE_HEIGHT, 3120},
-	{IMX258_REG_X_OUT_SIZE, 4208},
-	{IMX258_REG_Y_OUT_SIZE, 3120},
+	{CCS_R_SCALE_M, 16},
+	{CCS_R_DIGITAL_CROP_IMAGE_HEIGHT, 3120},
+	{CCS_R_X_OUTPUT_SIZE, 4208},
+	{CCS_R_Y_OUTPUT_SIZE, 3120},
 };
 
 static const struct cci_reg_sequence mode_2104_1560_regs[] = {
-	{IMX258_REG_BINNING_MODE, 1},
-	{IMX258_REG_BINNING_TYPE_V, 0x12},
+	{CCS_R_BINNING_MODE, 1},
+	{CCS_R_BINNING_TYPE, 0x12},
 	{IMX258_REG_SCALE_MODE, 1},
-	{IMX258_REG_SCALE_M, 32},
-	{IMX258_REG_DIG_CROP_IMAGE_HEIGHT, 1560},
-	{IMX258_REG_X_OUT_SIZE, 2104},
-	{IMX258_REG_Y_OUT_SIZE, 1560},
+	{CCS_R_SCALE_M, 32},
+	{CCS_R_DIGITAL_CROP_IMAGE_HEIGHT, 1560},
+	{CCS_R_X_OUTPUT_SIZE, 2104},
+	{CCS_R_Y_OUTPUT_SIZE, 1560},
 };
 
 static const struct cci_reg_sequence mode_1048_780_regs[] = {
-	{IMX258_REG_BINNING_MODE, 1},
-	{IMX258_REG_BINNING_TYPE_V, 0x14},
+	{CCS_R_BINNING_MODE, 1},
+	{CCS_R_BINNING_TYPE, 0x14},
 	{IMX258_REG_SCALE_MODE, 1},
-	{IMX258_REG_SCALE_M, 64},
-	{IMX258_REG_DIG_CROP_IMAGE_HEIGHT, 780},
-	{IMX258_REG_X_OUT_SIZE, 1048},
-	{IMX258_REG_Y_OUT_SIZE, 780},
+	{CCS_R_SCALE_M, 64},
+	{CCS_R_DIGITAL_CROP_IMAGE_HEIGHT, 780},
+	{CCS_R_X_OUTPUT_SIZE, 1048},
+	{CCS_R_Y_OUTPUT_SIZE, 780},
 };
 
 struct imx258_variant_cfg {
 	const struct cci_reg_sequence *regs;
 	unsigned int num_regs;
 };
 
 static const struct cci_reg_sequence imx258_cfg_regs[] = {
@@ -771,54 +732,54 @@ static int imx258_set_ctrl(struct v4l2_ctrl *ctrl)
 	 * Applying V4L2 control value only happens
 	 * when power is up for streaming
 	 */
 	if (pm_runtime_get_if_in_use(imx258->dev) == 0)
 		return 0;
 
 	switch (ctrl->id) {
 	case V4L2_CID_ANALOGUE_GAIN:
-		ret = cci_write(imx258->regmap, IMX258_REG_ANALOG_GAIN,
+		ret = cci_write(imx258->regmap, CCS_R_ANALOG_GAIN_CODE_GLOBAL,
 				ctrl->val, NULL);
 		break;
 	case V4L2_CID_EXPOSURE:
-		ret = cci_write(imx258->regmap, IMX258_REG_EXPOSURE,
+		ret = cci_write(imx258->regmap, CCS_R_COARSE_INTEGRATION_TIME,
 				ctrl->val, NULL);
 		break;
 	case V4L2_CID_DIGITAL_GAIN:
 		ret = imx258_update_digital_gain(imx258, ctrl->val);
 		break;
 	case V4L2_CID_TEST_PATTERN:
-		ret = cci_write(imx258->regmap, IMX258_REG_TEST_PATTERN,
+		ret = cci_write(imx258->regmap, CCS_R_TEST_PATTERN_MODE,
 				ctrl->val, NULL);
 		break;
 	case V4L2_CID_WIDE_DYNAMIC_RANGE:
 		if (!ctrl->val) {
-			ret = cci_write(imx258->regmap, IMX258_REG_HDR,
+			ret = cci_write(imx258->regmap, CCS_R_HDR_MODE,
 					IMX258_HDR_RATIO_MIN, NULL);
 		} else {
-			ret = cci_write(imx258->regmap, IMX258_REG_HDR,
-					IMX258_HDR_ON, NULL);
+			ret = cci_write(imx258->regmap, CCS_R_HDR_MODE,
+					CCS_HDR_MODE_ENABLED, NULL);
 			if (ret)
 				break;
-			ret = cci_write(imx258->regmap, IMX258_REG_HDR_RATIO,
+			ret = cci_write(imx258->regmap, CCS_R_EXPOSURE_RATIO,
 					BIT(IMX258_HDR_RATIO_MAX), NULL);
 		}
 		break;
 	case V4L2_CID_VBLANK:
-		ret = cci_write(imx258->regmap, IMX258_REG_FRM_LENGTH_LINES,
+		ret = cci_write(imx258->regmap, CCS_R_FRAME_LENGTH_LINES,
 				imx258->cur_mode->height + ctrl->val, NULL);
 		break;
 	case V4L2_CID_VFLIP:
 	case V4L2_CID_HFLIP:
-		ret = cci_write(imx258->regmap, REG_MIRROR_FLIP_CONTROL,
+		ret = cci_write(imx258->regmap, CCS_R_IMAGE_ORIENTATION,
 				(imx258->hflip->val ?
-				 REG_CONFIG_MIRROR_HFLIP : 0) |
+				 CCS_IMAGE_ORIENTATION_HORIZONTAL_MIRROR : 0) |
 				(imx258->vflip->val ?
-				 REG_CONFIG_MIRROR_VFLIP : 0),
+				 CCS_IMAGE_ORIENTATION_VERTICAL_FLIP : 0),
 				NULL);
 		break;
 	default:
 		dev_info(imx258->dev,
 			 "ctrl(id:0x%x,val:0x%x) is not handled\n",
 			 ctrl->id, ctrl->val);
 		ret = -EINVAL;
 		break;
@@ -1028,17 +989,18 @@ static int imx258_get_selection(struct v4l2_subdev *sd,
 
 /* Start streaming */
 static int imx258_start_streaming(struct imx258 *imx258)
 {
 	const struct imx258_reg_list *reg_list;
 	const struct imx258_link_freq_config *link_freq_cfg;
 	int ret, link_freq_index;
 
-	ret = cci_write(imx258->regmap, IMX258_REG_RESET, 0x01, NULL);
+	ret = cci_write(imx258->regmap, CCS_R_SOFTWARE_RESET,
+			CCS_SOFTWARE_RESET_ON, NULL);
 	if (ret) {
 		dev_err(imx258->dev, "%s failed to reset sensor\n", __func__);
 		return ret;
 	}
 
 	/* 12ms is required from poweron to standby */
 	fsleep(12000);
 
@@ -1085,28 +1047,28 @@ static int imx258_start_streaming(struct imx258 *imx258)
 	}
 
 	/* Apply customized values from user */
 	ret =  __v4l2_ctrl_handler_setup(imx258->sd.ctrl_handler);
 	if (ret)
 		return ret;
 
 	/* set stream on register */
-	return cci_write(imx258->regmap, IMX258_REG_MODE_SELECT,
-			 IMX258_MODE_STREAMING, NULL);
+	return cci_write(imx258->regmap, CCS_R_MODE_SELECT,
+			 CCS_MODE_SELECT_STREAMING, NULL);
 }
 
 /* Stop streaming */
 static int imx258_stop_streaming(struct imx258 *imx258)
 {
 	int ret;
 
 	/* set stream off register */
-	ret = cci_write(imx258->regmap, IMX258_REG_MODE_SELECT,
-			IMX258_MODE_STANDBY, NULL);
+	ret = cci_write(imx258->regmap, CCS_R_MODE_SELECT,
+			CCS_MODE_SELECT_SOFTWARE_STANDBY, NULL);
 	if (ret)
 		dev_err(imx258->dev, "%s failed to set stream\n", __func__);
 
 	/*
 	 * Return success even if it was an error, as there is nothing the
 	 * caller can do about it.
 	 */
 	return 0;
@@ -1183,17 +1145,17 @@ static int imx258_set_stream(struct v4l2_subdev *sd, int enable)
 }
 
 /* Verify chip ID */
 static int imx258_identify_module(struct imx258 *imx258)
 {
 	int ret;
 	u64 val;
 
-	ret = cci_read(imx258->regmap, IMX258_REG_CHIP_ID,
+	ret = cci_read(imx258->regmap, CCS_R_SENSOR_MODEL_ID,
 		       &val, NULL);
 	if (ret) {
 		dev_err(imx258->dev, "failed to read chip id %x\n",
 			IMX258_CHIP_ID);
 		return ret;
 	}
 
 	if (val != IMX258_CHIP_ID) {

-- 
2.55.0

