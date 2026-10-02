From: Maurizio Casciano <mauriziocasciano7@gmail.com>
Date: Fri, 02 Oct 2026 10:57:40 +0200
Subject: [PATCH v10 02/15] media: ov8858: support 19.2 MHz clock and manual
 white balance
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261002-submission-media-yogabook-v10-b4-final-v10-2-817ec765b257@gmail.com>
References: <20261002-submission-media-yogabook-v10-b4-final-v10-0-817ec765b257@gmail.com>
In-Reply-To: <20261002-submission-media-yogabook-v10-b4-final-v10-0-817ec765b257@gmail.com>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Jacopo Mondi <jacopo.mondi@ideasonboard.com>, 
 Nicholas Roth <nicholas@rothemail.net>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Bingbu Cao <bingbu.cao@amd.com>, 
 Dan Scally <dan.scally@ideasonboard.com>, Hans de Goede <hansg@kernel.org>, 
 Andy Shevchenko <andy@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Andy Shevchenko <andriy.shevchenko@intel.com>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-staging@lists.linux.dev
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790931470; l=12194;
 i=mauriziocasciano7@gmail.com; s=yogabook-kernel-20261002;
 h=from:subject:message-id; bh=6vHYJPHXLzbRSO1QCoIDH7aDNQCDOSyMrnoNjVDD5yU=;
 b=xxBrTXLRvW6guNyhhn+F0DVXXkggQbH4PwpVcQbXd1ahzD1tEW/mmTjC4DfCWZ/7raykWM0Z6
 YXRM2pLLMLOB7lheOO7rjaLrpIi63jaEwfbnLEKHniGBYdzQqVLAbcu
X-Developer-Key: i=mauriziocasciano7@gmail.com; a=ed25519;
 pk=ODC2oSPBqt7ukC3AEDZNS7LIE21D8ke8TEHoNlxniNM=
X-Endpoint-Received: by B4 Relay for mauriziocasciano7@gmail.com/yogabook-kernel-20261002 with auth_id=1099
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Support both 19.2 MHz and 24 MHz input clocks. Move the PLL and
global-timing registers out of the common mode tables and select register
settings for the detected revision, lane count, input clock and 360 MHz
link frequency when starting the stream. Use the actual input-clock rate
when calculating the reset delay.

Add standard red and blue balance controls for the sensor's manual white
balance registers. V4L2 defines red and blue balance relative to green but
does not define a standard green-balance control, so keep green at unity.
Accumulate errors while programming all three channels.

The manual white-balance register definitions and programming follow
Intel's GPL-2.0 OV5670 driver, so retain its 2017 Intel copyright notice.

Signed-off-by: Maurizio Casciano <mauriziocasciano7@gmail.com>
Assisted-by: LLM sparse
---
 drivers/media/i2c/ov8858.c | 183 ++++++++++++++++++++++++++++++++++++---------
 1 file changed, 147 insertions(+), 36 deletions(-)

diff --git a/drivers/media/i2c/ov8858.c b/drivers/media/i2c/ov8858.c
index 2a0e2b08b9aa..64532237e8b5 100644
--- a/drivers/media/i2c/ov8858.c
+++ b/drivers/media/i2c/ov8858.c
@@ -3,10 +3,9 @@
  * Copyright (C) 2023 Jacopo Mondi <jacopo.mondi@ideasonboard.com>
  * Copyright (C) 2022 Nicholas Roth <nicholas@rothemail.net>
  * Copyright (C) 2017 Fuzhou Rockchip Electronics Co., Ltd.
+ * Copyright (c) 2017 Intel Corporation.
  */
 
-#include <linux/unaligned.h>
-
 #include <linux/clk.h>
 #include <linux/delay.h>
 #include <linux/device.h>
@@ -18,6 +17,8 @@
 #include <linux/property.h>
 #include <linux/regulator/consumer.h>
 #include <linux/slab.h>
+#include <linux/unaligned.h>
+#include <linux/units.h>
 
 #include <media/media-entity.h>
 #include <media/v4l2-async.h>
@@ -28,8 +29,9 @@
 #include <media/v4l2-mediabus.h>
 #include <media/v4l2-subdev.h>
 
-#define OV8858_LINK_FREQ		360000000U
-#define OV8858_XVCLK_FREQ		24000000
+#define OV8858_LINK_FREQ		(360 * HZ_PER_MHZ)
+#define OV8858_XVCLK_FREQ_24MHZ		(24000 * HZ_PER_KHZ)
+#define OV8858_XVCLK_FREQ_19_2MHZ	(19200 * HZ_PER_KHZ)
 
 #define OV8858_REG_SIZE_SHIFT		16
 #define OV8858_REG_ADDR_MASK		0xffff
@@ -59,6 +61,14 @@
 #define OV8858_LONG_GAIN_STEP		1
 #define OV8858_LONG_GAIN_DEFAULT	0x80
 
+#define OV8858_REG_MWB_RED_GAIN		OV8858_REG_16BIT(0x5032)
+#define OV8858_REG_MWB_GREEN_GAIN	OV8858_REG_16BIT(0x5034)
+#define OV8858_REG_MWB_BLUE_GAIN	OV8858_REG_16BIT(0x5036)
+#define OV8858_MWB_GAIN_MIN		0x400
+#define OV8858_MWB_GAIN_MAX		0xfff
+#define OV8858_MWB_GAIN_STEP		1
+#define OV8858_MWB_GAIN_DEFAULT		0x400
+
 #define OV8858_REG_LONG_DIGIGAIN	OV8858_REG_16BIT(0x350a)
 #define OV8858_LONG_DIGIGAIN_H_MASK	0x3fc0
 #define OV8858_LONG_DIGIGAIN_L_MASK	0x3f
@@ -104,6 +114,7 @@ struct ov8858_mode {
 
 struct ov8858 {
 	struct clk		*xvclk;
+	unsigned long		xvclk_rate;
 	struct gpio_desc	*reset_gpio;
 	struct gpio_desc	*pwdn_gpio;
 	struct regulator_bulk_data supplies[ARRAY_SIZE(ov8858_supply_names)];
@@ -115,12 +126,86 @@ struct ov8858 {
 	struct v4l2_ctrl	*exposure;
 	struct v4l2_ctrl	*hblank;
 	struct v4l2_ctrl	*vblank;
+	struct v4l2_ctrl	*red_balance;
+	struct v4l2_ctrl	*blue_balance;
 
 	const struct regval	*global_regs;
+	const struct regval	*xvclk_regs;
 
 	unsigned int		num_lanes;
 };
 
+/* Keep input-clock programming separate from the common sensor setup. */
+static const struct regval ov8858_24mhz_360mhz_r1a_2lane[] = {
+	{0x0302, 0x1e},
+	{0x0303, 0x00},
+	{0x0304, 0x03},
+	{0x030e, 0x00},
+	{0x030f, 0x09},
+	{0x0312, 0x01},
+	{0x031e, 0x0c},
+	{0x4837, 0x16},
+	{REG_NULL, 0x00}
+};
+
+static const struct regval ov8858_24mhz_360mhz_r2a_2lane[] = {
+	{0x0302, 0x1e},
+	{0x0303, 0x00},
+	{0x0304, 0x03},
+	{0x030e, 0x02},
+	{0x030f, 0x04},
+	{0x0312, 0x03},
+	{0x031e, 0x0c},
+	{0x4837, 0x16},
+	{REG_NULL, 0x00}
+};
+
+static const struct regval ov8858_24mhz_360mhz_r2a_4lane[] = {
+	{0x0302, 0x1e},
+	{0x0303, 0x00},
+	{0x0304, 0x03},
+	{0x030e, 0x00},
+	{0x030f, 0x04},
+	{0x0312, 0x01},
+	{0x031e, 0x0c},
+	{0x4837, 0x16},
+	{REG_NULL, 0x00}
+};
+
+/*
+ * Register settings for a 19.2 MHz input and 360 MHz CSI-2 link.
+ *
+ * Besides the corrected sensor/MIPI PLL divisors, keep the final common
+ * black-level settings here. The per-mode tables retain their resolution
+ * dependent black-column anchors and window sizes.
+ */
+static const struct regval ov8858_19_2mhz_360mhz[] = {
+	{0x0300, 0x00},
+	{0x0302, 0x27},
+	{0x0303, 0x00},
+	{0x0304, 0x03},
+	{0x030b, 0x00},
+	{0x030d, 0x27},
+	{0x030e, 0x00},
+	{0x030f, 0x04},
+	{0x0312, 0x01},
+	{0x031e, 0x0c},
+	{0x3f08, 0x08},
+	{0x400a, 0x01},
+	{0x400d, 0x10},
+	{0x4011, 0x20},
+	{0x403e, 0x08},
+	{0x4040, 0x07},
+	{0x4041, 0xc6},
+	{0x4202, 0x00},
+	{0x4500, 0x58},
+	{0x470b, 0x28},
+	{0x4837, 0x15},
+	{0x58f4, 0x32},
+	{0x58f8, 0x3d},
+	{REG_NULL, 0x00}
+};
+
 static inline struct ov8858 *sd_to_ov8858(struct v4l2_subdev *sd)
 {
 	return container_of(sd, struct ov8858, subdev);
@@ -131,13 +216,6 @@ static const struct regval ov8858_global_regs_r1a[] = {
 	{0x0100, 0x00},
 	{0x0100, 0x00},
 	{0x0100, 0x00},
-	{0x0302, 0x1e},
-	{0x0303, 0x00},
-	{0x0304, 0x03},
-	{0x030e, 0x00},
-	{0x030f, 0x09},
-	{0x0312, 0x01},
-	{0x031e, 0x0c},
 	{0x3600, 0x00},
 	{0x3601, 0x00},
 	{0x3602, 0x00},
@@ -370,7 +448,6 @@ static const struct regval ov8858_global_regs_r1a[] = {
 	{0x4600, 0x00},
 	{0x4601, 0xcb},
 	{0x481f, 0x32},
-	{0x4837, 0x16},
 	{0x4850, 0x10},
 	{0x4851, 0x32},
 	{0x4b00, 0x2a},
@@ -405,13 +482,6 @@ static const struct regval ov8858_global_regs_r2a_2lane[] = {
 	 */
 	{0x0103, 0x01}, /* software reset */
 	{0x0100, 0x00}, /* software standby */
-	{0x0302, 0x1e}, /* pll1_multi */
-	{0x0303, 0x00}, /* pll1_divm */
-	{0x0304, 0x03}, /* pll1_div_mipi */
-	{0x030e, 0x02}, /* pll2_rdiv */
-	{0x030f, 0x04}, /* pll2_divsp */
-	{0x0312, 0x03}, /* pll2_pre_div0, pll2_r_divdac */
-	{0x031e, 0x0c}, /* pll1_no_lat */
 	{0x3600, 0x00},
 	{0x3601, 0x00},
 	{0x3602, 0x00},
@@ -648,7 +718,6 @@ static const struct regval ov8858_global_regs_r2a_2lane[] = {
 	{0x4600, 0x00},
 	{0x4601, 0xcb},
 	{0x481f, 0x32}, /* clk prepare min */
-	{0x4837, 0x16}, /* global timing */
 	{0x4850, 0x10}, /* lane 1 = 1, lane 0 = 0 */
 	{0x4851, 0x32}, /* lane 3 = 3, lane 2 = 2 */
 	{0x4b00, 0x2a},
@@ -810,13 +879,6 @@ static const struct regval ov8858_global_regs_r2a_4lane[] = {
 	{0x0103, 0x01}, /* software reset for OVTATool only */
 	{0x0103, 0x01}, /* software reset */
 	{0x0100, 0x00}, /* software standby */
-	{0x0302, 0x1e}, /* pll1_multi */
-	{0x0303, 0x00}, /* pll1_divm */
-	{0x0304, 0x03}, /* pll1_div_mipi */
-	{0x030e, 0x00}, /* pll2_rdiv */
-	{0x030f, 0x04}, /* pll2_divsp */
-	{0x0312, 0x01}, /* pll2_pre_div0, pll2_r_divdac */
-	{0x031e, 0x0c}, /* pll1_no_lat */
 	{0x3600, 0x00},
 	{0x3601, 0x00},
 	{0x3602, 0x00},
@@ -1053,7 +1115,6 @@ static const struct regval ov8858_global_regs_r2a_4lane[] = {
 	{0x4600, 0x00},
 	{0x4601, 0xcb},
 	{0x481f, 0x32}, /* clk prepare min */
-	{0x4837, 0x16}, /* global timing */
 	{0x4850, 0x10}, /* lane 1 = 1, lane 0 = 0 */
 	{0x4851, 0x32}, /* lane 3 = 3, lane 2 = 2 */
 	{0x4b00, 0x2a},
@@ -1345,6 +1406,10 @@ static int ov8858_start_stream(struct ov8858 *ov8858,
 	if (ret)
 		return ret;
 
+	ret = ov8858_write_array(ov8858, ov8858->xvclk_regs);
+	if (ret)
+		return ret;
+
 	/* 200 usec max to let PLL stabilize. */
 	fsleep(200);
 
@@ -1541,6 +1606,23 @@ static int ov8858_set_long_digital_gain(struct ov8858 *ov8858, u32 gain)
 	return ov8858_write(ov8858, OV8858_REG_LONG_DIGIGAIN, long_gain, NULL);
 }
 
+static int ov8858_set_mwb_gains(struct ov8858 *ov8858)
+{
+	int ret = 0;
+
+	ov8858_write(ov8858, OV8858_REG_MWB_RED_GAIN,
+		     ov8858->red_balance->val, &ret);
+	/*
+	 * Green is the unity reference for the red and blue balance controls.
+	 */
+	ov8858_write(ov8858, OV8858_REG_MWB_GREEN_GAIN,
+		     OV8858_MWB_GAIN_DEFAULT, &ret);
+	ov8858_write(ov8858, OV8858_REG_MWB_BLUE_GAIN,
+		     ov8858->blue_balance->val, &ret);
+
+	return ret;
+}
+
 static int ov8858_set_ctrl(struct v4l2_ctrl *ctrl)
 {
 	struct ov8858 *ov8858 = container_of(ctrl->handler,
@@ -1589,6 +1671,10 @@ static int ov8858_set_ctrl(struct v4l2_ctrl *ctrl)
 	case V4L2_CID_DIGITAL_GAIN:
 		ret = ov8858_set_long_digital_gain(ov8858, ctrl->val);
 		break;
+	case V4L2_CID_RED_BALANCE:
+	case V4L2_CID_BLUE_BALANCE:
+		ret = ov8858_set_mwb_gains(ov8858);
+		break;
 	case V4L2_CID_VBLANK:
 		ret = ov8858_write(ov8858, OV8858_REG_VTS,
 				   ctrl->val + format->height, NULL);
@@ -1623,9 +1709,6 @@ static int ov8858_power_on(struct ov8858 *ov8858)
 	unsigned long delay_us;
 	int ret;
 
-	if (clk_get_rate(ov8858->xvclk) != OV8858_XVCLK_FREQ)
-		dev_warn(dev, "xvclk mismatched, modes are based on 24MHz\n");
-
 	ret = clk_prepare_enable(ov8858->xvclk);
 	if (ret < 0) {
 		dev_err(dev, "Failed to enable xvclk\n");
@@ -1644,7 +1727,7 @@ static int ov8858_power_on(struct ov8858 *ov8858)
 	 * transaction, but a double sleep between the release of gpios
 	 * helps with sporadic failures observed at probe time.
 	 */
-	delay_us = DIV_ROUND_UP(8192, OV8858_XVCLK_FREQ / 1000 / 1000);
+	delay_us = DIV_ROUND_UP(8192, ov8858->xvclk_rate / HZ_PER_MHZ);
 
 	gpiod_set_value_cansleep(ov8858->reset_gpio, 0);
 	fsleep(delay_us);
@@ -1710,7 +1793,7 @@ static int ov8858_init_ctrls(struct ov8858 *ov8858)
 	u32 h_blank;
 	int ret;
 
-	ret = v4l2_ctrl_handler_init(handler, 10);
+	ret = v4l2_ctrl_handler_init(handler, 12);
 	if (ret)
 		return ret;
 
@@ -1752,6 +1835,19 @@ static int ov8858_init_ctrls(struct ov8858 *ov8858)
 			  OV8858_LONG_DIGIGAIN_STEP,
 			  OV8858_LONG_DIGIGAIN_DEFAULT);
 
+	ov8858->red_balance =
+		v4l2_ctrl_new_std(handler, &ov8858_ctrl_ops,
+				  V4L2_CID_RED_BALANCE,
+				  OV8858_MWB_GAIN_MIN, OV8858_MWB_GAIN_MAX,
+				  OV8858_MWB_GAIN_STEP,
+				  OV8858_MWB_GAIN_DEFAULT);
+	ov8858->blue_balance =
+		v4l2_ctrl_new_std(handler, &ov8858_ctrl_ops,
+				  V4L2_CID_BLUE_BALANCE,
+				  OV8858_MWB_GAIN_MIN, OV8858_MWB_GAIN_MAX,
+				  OV8858_MWB_GAIN_STEP,
+				  OV8858_MWB_GAIN_DEFAULT);
+
 	v4l2_ctrl_new_std_menu_items(handler, &ov8858_ctrl_ops,
 				     V4L2_CID_TEST_PATTERN,
 				     ARRAY_SIZE(ov8858_test_pattern_menu) - 1,
@@ -1805,15 +1901,20 @@ static int ov8858_check_sensor_id(struct ov8858 *ov8858)
 
 	if (id == OV8858_R2A) {
 		/* R2A supports 2 and 4 lanes modes. */
-		ov8858->global_regs = ov8858->num_lanes == 4
-				    ? ov8858_global_regs_r2a_4lane
-				    : ov8858_global_regs_r2a_2lane;
+		if (ov8858->num_lanes == 4) {
+			ov8858->global_regs = ov8858_global_regs_r2a_4lane;
+			ov8858->xvclk_regs = ov8858_24mhz_360mhz_r2a_4lane;
+		} else {
+			ov8858->global_regs = ov8858_global_regs_r2a_2lane;
+			ov8858->xvclk_regs = ov8858_24mhz_360mhz_r2a_2lane;
+		}
 	} else if (ov8858->num_lanes == 2) {
 		/*
 		 * R1A only supports 2 lanes mode and it's only partially
 		 * supported.
 		 */
 		ov8858->global_regs = ov8858_global_regs_r1a;
+		ov8858->xvclk_regs = ov8858_24mhz_360mhz_r1a_2lane;
 		dev_warn(&client->dev, "R1A may not work well!\n");
 	} else {
 		dev_err(&client->dev,
@@ -1821,6 +1922,9 @@ static int ov8858_check_sensor_id(struct ov8858 *ov8858)
 		return -EINVAL;
 	}
 
+	if (ov8858->xvclk_rate == OV8858_XVCLK_FREQ_19_2MHZ)
+		ov8858->xvclk_regs = ov8858_19_2mhz_360mhz;
+
 	return 0;
 }
 
@@ -1888,6 +1992,13 @@ static int ov8858_probe(struct i2c_client *client)
 		return dev_err_probe(dev, PTR_ERR(ov8858->xvclk),
 				     "Failed to get xvclk\n");
 
+	ov8858->xvclk_rate = clk_get_rate(ov8858->xvclk);
+	if (ov8858->xvclk_rate != OV8858_XVCLK_FREQ_19_2MHZ &&
+	    ov8858->xvclk_rate != OV8858_XVCLK_FREQ_24MHZ)
+		return dev_err_probe(dev, -EINVAL,
+				     "Unsupported xvclk rate %lu Hz\n",
+				     ov8858->xvclk_rate);
+
 	ov8858->reset_gpio = devm_gpiod_get_optional(dev, "reset",
 						     GPIOD_OUT_HIGH);
 	if (IS_ERR(ov8858->reset_gpio))

-- 
2.53.0

