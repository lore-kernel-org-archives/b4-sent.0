From: David Heidelberg <david@ixit.cz>
Date: Tue, 14 Apr 2026 12:12:10 +0200
Subject: [PATCH] media: i2c: imx355: Add support for 24 MHz external clock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260414-imx355-24mhz-v1-1-9ae77bc6e7ec@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAPkS3mkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDE0MT3czcCmNTU10jk9yMKt0ki+TktMQk48SUtCQloJaCotS0zAqwcdG
 xtbUApEEQuF4AAAA=
X-Change-ID: 20260414-imx355-24mhz-b8ccfab3adfb
To: Tianshu Qiu <tian.shu.qiu@intel.com>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Richard Acayan <mailingradian@gmail.com>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=9293; i=david@ixit.cz;
 h=from:subject:message-id; bh=/RS+iqeOynacJviJ8IGq4JSr4HjAOfKq/naOIrw+LNY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp3hRDNkId7Jc499vptwIZyY170CzvJGBr1JmpP
 nVu6QjEJf+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCad4UQwAKCRBgAj/E00kg
 cl7XD/0WQanF2pKV2YxzpCOqq2Da5hmyEB9xPCJmuQOVp8m34GzXs8/gcfDcrESEITGt+h8CgBs
 QLqz2jzYrGVwxnNV5zePiokD9WRj9AclS/WCcC1ZAt/z5YmcTn0UGXTR98NT+/9OY53wntncf7j
 AHlf9OO5S7dvZGsEBXgfZUrvYvGP23hV7pzX8n6sZDv5KCtOrQlUg2AdE1oJ/deJIkDsHnNXvKy
 wt0vIACgFwenhd3OuNUXYysoVWgO0Yth0SewT13ZWxbt2oBxResp97oZRQtTjXoBb3SbiA6PLyf
 ERcMAQYVzsWgy0e9A8tC7ltn0Eii7S3xia5bYfPTrx3wJxU614rjnN4ap5mlcjv+QxlzR3jKsRb
 jXkh4SJj/r+fXNJRtHwxdBQ+kF0IyrtMJh1OOHrFICg9sC09ArXn++9zzAfOal6NLm7spxQ/fPV
 ULP7ClmGT5fWOJH8Bx+r4NtYsSMN/3Kdo2GwWRjwkPoIILDaAnrR2P5oZ/vPc4WINTQxj3Hx6d+
 VNm8gw6lznUSxvMxZjnBH2v9oMsQDGdu80hyXGlkPiROk/jgoErk9A04i5olt6ZjMHMptbC03ro
 2TAnLJsw8sHrmMzDcPNHKfKB78pmjeN3odNetmyPtQzJeXk5PhpMGt6tC5MkDPkdetWaPZTON1r
 sUYcOArr61ksoig==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The IMX355 sensor supports multiple external clock frequencies,
including 19.2 MHz and 24 MHz. The driver currently supports only
fixed 19.2 MHz input clock.

Refactor the clock handling to make the PLL configuration dependent
on the external clock frequency and add support for 24 MHz. Introduce
a table of clock parameter sets and program the corresponding EXTCLK
frequency and PLL multipliers to maintain consistent internal VCO
frequencies across supported inputs.

The PLL settings are adjusted so that:
  - VT VCO remains at 1152 MHz
  - OP VCO remains at 720 MHz

This preserves existing timing characteristics while allowing systems
using a 24 MHz clock to operate correctly.

No functional change for existing 19.2 MHz users.

Assisted-by: Claude:claude-opus-4-6
Signed-off-by: David Heidelberg <david@ixit.cz>
---
Known users: Pixel 3 and 3a.
---
 drivers/media/i2c/imx355.c | 114 +++++++++++++++++++++------------------------
 1 file changed, 54 insertions(+), 60 deletions(-)

diff --git a/drivers/media/i2c/imx355.c b/drivers/media/i2c/imx355.c
index 27a5c212a527f..f9ec13bb27d10 100644
--- a/drivers/media/i2c/imx355.c
+++ b/drivers/media/i2c/imx355.c
@@ -25,6 +25,11 @@
 #define IMX355_REG_CHIP_ID		0x0016
 #define IMX355_CHIP_ID			0x0355
 
+/* PLL registers that depend on the external clock frequency */
+#define IMX355_REG_EXTCLK_FREQ		0x0136
+#define IMX355_REG_PLL_VT_MUL		0x0306
+#define IMX355_REG_PLL_OP_MUL		0x030e
+
 /* V_TIMING internal */
 #define IMX355_REG_FLL			0x0340
 #define IMX355_FLL_MAX			0xffff
@@ -63,7 +68,6 @@
 
 /* default link frequency and external clock */
 #define IMX355_LINK_FREQ_DEFAULT	360000000LL
-#define IMX355_EXT_CLK			19200000
 #define IMX355_LINK_FREQ_INDEX		0
 
 /* number of data lanes */
@@ -100,6 +104,33 @@ struct imx355_mode {
 	struct imx355_reg_list reg_list;
 };
 
+struct imx355_clk_params {
+	u32 ext_clk;
+	u16 extclk_freq; /* External clock (MHz) in 8.8 fixed point) */
+	u16 pll_vt_mpy;	/* VT system PLL multiplier */
+	u16 pll_op_mpy;	/* OP system PLL multiplier */
+};
+
+/*
+ * All modes use the same PLL dividers (PREPLLCK_VT_DIV=2, PREPLLCK_OP_DIV=2),
+ * so the multipliers are adjusted to produce the same VCO frequencies:
+ *   VT VCO = 1152 MHz, OP VCO = 720 MHz
+ */
+static const struct imx355_clk_params imx355_clk_params[] = {
+	{
+		.ext_clk = 19200000,
+		.extclk_freq = 0x1333,	/* 19.2 MHz */
+		.pll_vt_mpy = 120,	/* 19.2 / 2 * 120 = 1152 MHz */
+		.pll_op_mpy = 75,	/* 19.2 / 2 * 75  = 720 MHz */
+	},
+	{
+		.ext_clk = 24000000,
+		.extclk_freq = 0x1800,	/* 24.0 MHz */
+		.pll_vt_mpy = 96,	/* 24.0 / 2 * 96  = 1152 MHz */
+		.pll_op_mpy = 60,	/* 24.0 / 2 * 60  = 720 MHz */
+	},
+};
+
 struct imx355_hwcfg {
 	unsigned long link_freq_bitmap;
 };
@@ -125,6 +156,7 @@ struct imx355 {
 	const struct imx355_mode *cur_mode;
 
 	struct imx355_hwcfg *hwcfg;
+	const struct imx355_clk_params *clk_params;
 
 	/*
 	 * Mutex for serialized access:
@@ -144,8 +176,6 @@ static const struct regulator_bulk_data imx355_supplies[] = {
 };
 
 static const struct imx355_reg imx355_global_regs[] = {
-	{ 0x0136, 0x13 },
-	{ 0x0137, 0x33 },
 	{ 0x304e, 0x03 },
 	{ 0x4348, 0x16 },
 	{ 0x4350, 0x19 },
@@ -231,12 +261,8 @@ static const struct imx355_reg mode_3268x2448_regs[] = {
 	{ 0x0301, 0x05 },
 	{ 0x0303, 0x01 },
 	{ 0x0305, 0x02 },
-	{ 0x0306, 0x00 },
-	{ 0x0307, 0x78 },
 	{ 0x030b, 0x01 },
 	{ 0x030d, 0x02 },
-	{ 0x030e, 0x00 },
-	{ 0x030f, 0x4b },
 	{ 0x0310, 0x00 },
 	{ 0x0700, 0x00 },
 	{ 0x0701, 0x10 },
@@ -280,12 +306,8 @@ static const struct imx355_reg mode_3264x2448_regs[] = {
 	{ 0x0301, 0x05 },
 	{ 0x0303, 0x01 },
 	{ 0x0305, 0x02 },
-	{ 0x0306, 0x00 },
-	{ 0x0307, 0x78 },
 	{ 0x030b, 0x01 },
 	{ 0x030d, 0x02 },
-	{ 0x030e, 0x00 },
-	{ 0x030f, 0x4b },
 	{ 0x0310, 0x00 },
 	{ 0x0700, 0x00 },
 	{ 0x0701, 0x10 },
@@ -329,12 +351,8 @@ static const struct imx355_reg mode_3280x2464_regs[] = {
 	{ 0x0301, 0x05 },
 	{ 0x0303, 0x01 },
 	{ 0x0305, 0x02 },
-	{ 0x0306, 0x00 },
-	{ 0x0307, 0x78 },
 	{ 0x030b, 0x01 },
 	{ 0x030d, 0x02 },
-	{ 0x030e, 0x00 },
-	{ 0x030f, 0x4b },
 	{ 0x0310, 0x00 },
 	{ 0x0700, 0x00 },
 	{ 0x0701, 0x10 },
@@ -378,12 +396,8 @@ static const struct imx355_reg mode_1940x1096_regs[] = {
 	{ 0x0301, 0x05 },
 	{ 0x0303, 0x01 },
 	{ 0x0305, 0x02 },
-	{ 0x0306, 0x00 },
-	{ 0x0307, 0x78 },
 	{ 0x030b, 0x01 },
 	{ 0x030d, 0x02 },
-	{ 0x030e, 0x00 },
-	{ 0x030f, 0x4b },
 	{ 0x0310, 0x00 },
 	{ 0x0700, 0x00 },
 	{ 0x0701, 0x10 },
@@ -427,12 +441,8 @@ static const struct imx355_reg mode_1936x1096_regs[] = {
 	{ 0x0301, 0x05 },
 	{ 0x0303, 0x01 },
 	{ 0x0305, 0x02 },
-	{ 0x0306, 0x00 },
-	{ 0x0307, 0x78 },
 	{ 0x030b, 0x01 },
 	{ 0x030d, 0x02 },
-	{ 0x030e, 0x00 },
-	{ 0x030f, 0x4b },
 	{ 0x0310, 0x00 },
 	{ 0x0700, 0x00 },
 	{ 0x0701, 0x10 },
@@ -476,12 +486,8 @@ static const struct imx355_reg mode_1924x1080_regs[] = {
 	{ 0x0301, 0x05 },
 	{ 0x0303, 0x01 },
 	{ 0x0305, 0x02 },
-	{ 0x0306, 0x00 },
-	{ 0x0307, 0x78 },
 	{ 0x030b, 0x01 },
 	{ 0x030d, 0x02 },
-	{ 0x030e, 0x00 },
-	{ 0x030f, 0x4b },
 	{ 0x0310, 0x00 },
 	{ 0x0700, 0x00 },
 	{ 0x0701, 0x10 },
@@ -525,12 +531,8 @@ static const struct imx355_reg mode_1920x1080_regs[] = {
 	{ 0x0301, 0x05 },
 	{ 0x0303, 0x01 },
 	{ 0x0305, 0x02 },
-	{ 0x0306, 0x00 },
-	{ 0x0307, 0x78 },
 	{ 0x030b, 0x01 },
 	{ 0x030d, 0x02 },
-	{ 0x030e, 0x00 },
-	{ 0x030f, 0x4b },
 	{ 0x0310, 0x00 },
 	{ 0x0700, 0x00 },
 	{ 0x0701, 0x10 },
@@ -574,12 +576,8 @@ static const struct imx355_reg mode_1640x1232_regs[] = {
 	{ 0x0301, 0x05 },
 	{ 0x0303, 0x01 },
 	{ 0x0305, 0x02 },
-	{ 0x0306, 0x00 },
-	{ 0x0307, 0x78 },
 	{ 0x030b, 0x01 },
 	{ 0x030d, 0x02 },
-	{ 0x030e, 0x00 },
-	{ 0x030f, 0x4b },
 	{ 0x0310, 0x00 },
 	{ 0x0700, 0x00 },
 	{ 0x0701, 0x10 },
@@ -623,12 +621,8 @@ static const struct imx355_reg mode_1640x922_regs[] = {
 	{ 0x0301, 0x05 },
 	{ 0x0303, 0x01 },
 	{ 0x0305, 0x02 },
-	{ 0x0306, 0x00 },
-	{ 0x0307, 0x78 },
 	{ 0x030b, 0x01 },
 	{ 0x030d, 0x02 },
-	{ 0x030e, 0x00 },
-	{ 0x030f, 0x4b },
 	{ 0x0310, 0x00 },
 	{ 0x0700, 0x00 },
 	{ 0x0701, 0x10 },
@@ -672,12 +666,8 @@ static const struct imx355_reg mode_1300x736_regs[] = {
 	{ 0x0301, 0x05 },
 	{ 0x0303, 0x01 },
 	{ 0x0305, 0x02 },
-	{ 0x0306, 0x00 },
-	{ 0x0307, 0x78 },
 	{ 0x030b, 0x01 },
 	{ 0x030d, 0x02 },
-	{ 0x030e, 0x00 },
-	{ 0x030f, 0x4b },
 	{ 0x0310, 0x00 },
 	{ 0x0700, 0x00 },
 	{ 0x0701, 0x10 },
@@ -721,12 +711,8 @@ static const struct imx355_reg mode_1296x736_regs[] = {
 	{ 0x0301, 0x05 },
 	{ 0x0303, 0x01 },
 	{ 0x0305, 0x02 },
-	{ 0x0306, 0x00 },
-	{ 0x0307, 0x78 },
 	{ 0x030b, 0x01 },
 	{ 0x030d, 0x02 },
-	{ 0x030e, 0x00 },
-	{ 0x030f, 0x4b },
 	{ 0x0310, 0x00 },
 	{ 0x0700, 0x00 },
 	{ 0x0701, 0x10 },
@@ -770,12 +756,8 @@ static const struct imx355_reg mode_1284x720_regs[] = {
 	{ 0x0301, 0x05 },
 	{ 0x0303, 0x01 },
 	{ 0x0305, 0x02 },
-	{ 0x0306, 0x00 },
-	{ 0x0307, 0x78 },
 	{ 0x030b, 0x01 },
 	{ 0x030d, 0x02 },
-	{ 0x030e, 0x00 },
-	{ 0x030f, 0x4b },
 	{ 0x0310, 0x00 },
 	{ 0x0700, 0x00 },
 	{ 0x0701, 0x10 },
@@ -819,12 +801,8 @@ static const struct imx355_reg mode_1280x720_regs[] = {
 	{ 0x0301, 0x05 },
 	{ 0x0303, 0x01 },
 	{ 0x0305, 0x02 },
-	{ 0x0306, 0x00 },
-	{ 0x0307, 0x78 },
 	{ 0x030b, 0x01 },
 	{ 0x030d, 0x02 },
-	{ 0x030e, 0x00 },
-	{ 0x030f, 0x4b },
 	{ 0x0310, 0x00 },
 	{ 0x0700, 0x00 },
 	{ 0x0701, 0x10 },
@@ -868,12 +846,8 @@ static const struct imx355_reg mode_820x616_regs[] = {
 	{ 0x0301, 0x05 },
 	{ 0x0303, 0x01 },
 	{ 0x0305, 0x02 },
-	{ 0x0306, 0x00 },
-	{ 0x0307, 0x78 },
 	{ 0x030b, 0x01 },
 	{ 0x030d, 0x02 },
-	{ 0x030e, 0x00 },
-	{ 0x030f, 0x4b },
 	{ 0x0310, 0x00 },
 	{ 0x0700, 0x02 },
 	{ 0x0701, 0x78 },
@@ -1422,6 +1396,20 @@ static int imx355_start_streaming(struct imx355 *imx355)
 		return ret;
 	}
 
+	/* Set PLL registers for the external clock frequency */
+	ret = imx355_write_reg(imx355, IMX355_REG_EXTCLK_FREQ, 2,
+			       imx355->clk_params->extclk_freq);
+	if (ret)
+		return ret;
+	ret = imx355_write_reg(imx355, IMX355_REG_PLL_VT_MUL, 2,
+			       imx355->clk_params->pll_vt_mpy);
+	if (ret)
+		return ret;
+	ret = imx355_write_reg(imx355, IMX355_REG_PLL_OP_MUL, 2,
+			       imx355->clk_params->pll_op_mpy);
+	if (ret)
+		return ret;
+
 	/* set digital gain control to all color mode */
 	ret = imx355_write_reg(imx355, IMX355_REG_DPGA_USE_GLOBAL_GAIN, 1, 1);
 	if (ret)
@@ -1749,7 +1737,13 @@ static int imx355_probe(struct i2c_client *client)
 				     "failed to get clock\n");
 
 	freq = clk_get_rate(imx355->clk);
-	if (freq != IMX355_EXT_CLK)
+	for (unsigned int i = 0; i < ARRAY_SIZE(imx355_clk_params); i++) {
+		if (freq == imx355_clk_params[i].ext_clk) {
+			imx355->clk_params = &imx355_clk_params[i];
+			break;
+		}
+	}
+	if (!imx355->clk_params)
 		return dev_err_probe(imx355->dev, -EINVAL,
 				     "external clock %lu is not supported\n",
 				     freq);

---
base-commit: 66672af7a095d89f082c5327f3b15bc2f93d558e
change-id: 20260414-imx355-24mhz-b8ccfab3adfb

Best regards,
-- 
David Heidelberg <david@ixit.cz>

