From: Cunhao Lu <1579567540@qq.com>
Date: Thu, 22 Oct 2026 00:11:05 +0800
Subject: [PATCH 08/27] pinctrl: rockchip: Add RK3572 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-add-board-ok3572-c-v1-8-0b0fd85a31ee@qq.com>
References: <20261022-add-board-ok3572-c-v1-0-0b0fd85a31ee@qq.com>
In-Reply-To: <20261022-add-board-ok3572-c-v1-0-0b0fd85a31ee@qq.com>
To: Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Elaine Zhang <zhangqing@rock-chips.com>, Lee Jones <lee@kernel.org>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>, 
 Richard Cochran <richardcochran@gmail.com>, Ulf Hansson <ulfh@kernel.org>, 
 Andi Shyti <andi.shyti@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Jisheng Zhang <jszhang@kernel.org>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 David Wu <david.wu@rock-chips.com>, "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, 
 Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Vinod Koul <vkoul@kernel.org>, Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Jaehoon Chung <jh80.chung@samsung.com>, 
 Shawn Lin <shawn.lin@rock-chips.com>
Cc: Cunhao Lu <1579567540@qq.com>, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 mfd@lists.linux.dev, linux-gpio@vger.kernel.org, netdev@vger.kernel.org, 
 linux-pm@vger.kernel.org, linux-i2c@vger.kernel.org, 
 linux-serial@vger.kernel.org, linux-mmc@vger.kernel.org, 
 linux-stm32@st-md-mailman.stormreply.com, linux-phy@lists.infradead.org, 
 linux-usb@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792599138; l=10910;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=llpd4hSoeAxFlyw37M/TwbFtigFBA0OxKUA2lzfGh7w=;
 b=bdUGoMBhDQqFxE/R6weMwkERu0HSLXV2BlCdCZB+1QyUn+h7uK0dV+sx9N6XrRy+f+4zWFlrV
 +VSV6vGWdWYCqMwAcyCZLuglSPQRVbIUhiDEd2Is/HtwYPla1uP06Mj
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Support RK3572 pinmux, bias, drive-strength, and Schmitt controls.
Enable input buffers during mux changes for the RGMII receive clocks.

Signed-off-by: Cunhao Lu <1579567540@qq.com>
---
 drivers/pinctrl/pinctrl-rockchip.c | 230 ++++++++++++++++++++++++++++++++++++-
 drivers/pinctrl/pinctrl-rockchip.h |   1 +
 2 files changed, 230 insertions(+), 1 deletion(-)

diff --git a/drivers/pinctrl/pinctrl-rockchip.c b/drivers/pinctrl/pinctrl-rockchip.c
index ba47b6f323cc..6d9a6510b343 100644
--- a/drivers/pinctrl/pinctrl-rockchip.c
+++ b/drivers/pinctrl/pinctrl-rockchip.c
@@ -1363,6 +1363,10 @@ static int rockchip_get_mux(struct rockchip_pin_bank *bank, int pin)
 	if (bank->recalced_mask & BIT(pin))
 		rockchip_get_recalced_mux(bank, pin, &reg, &bit, &mask);
 
+	if (ctrl->type == RK3572 && bank->bank_num == 0 &&
+	    pin >= RK_PB4 && pin <= RK_PB7)
+		reg += 0x2000;
+
 	if (ctrl->type == RK3576) {
 		if ((bank->bank_num == 0) && (pin >= RK_PB4) && (pin <= RK_PB7))
 			reg += 0x1ff4; /* GPIO0_IOC_GPIO0B_IOMUX_SEL_H */
@@ -1421,6 +1425,24 @@ static int rockchip_verify_mux(struct rockchip_pin_bank *bank,
 	return 0;
 }
 
+static int rk3572_enable_input(struct rockchip_pin_bank *bank, int pin)
+{
+	static const u32 offsets[] = { 0x300, 0x10310, 0x12320, 0x14330, 0x14340 };
+	struct rockchip_pinctrl *info = bank->drvdata;
+	u32 reg, bit = pin % 8;
+
+	if (bank->bank_num >= ARRAY_SIZE(offsets))
+		return -EINVAL;
+
+	reg = offsets[bank->bank_num] + pin / 8 * 4;
+	if (bank->bank_num == 0 && pin >= RK_PB4)
+		reg += 0x2000;
+	else if (bank->bank_num == 4 && pin >= RK_PC0)
+		reg -= 0x10000;
+
+	return regmap_write(info->regmap_base, reg, BIT(bit + 16) | BIT(bit));
+}
+
 /*
  * Set a new mux function for a pin.
  *
@@ -1498,6 +1520,10 @@ static int rockchip_set_mux(struct rockchip_pin_bank *bank, int pin, int mux)
 	if (bank->recalced_mask & BIT(pin))
 		rockchip_get_recalced_mux(bank, pin, &reg, &bit, &mask);
 
+	if (ctrl->type == RK3572 && bank->bank_num == 0 &&
+	    pin >= RK_PB4 && pin <= RK_PB7)
+		reg += 0x2000;
+
 	if (ctrl->type == RK3576) {
 		if ((bank->bank_num == 0) && (pin >= RK_PB4) && (pin <= RK_PB7))
 			reg += 0x1ff4; /* GPIO0_IOC_GPIO0B_IOMUX_SEL_H */
@@ -1568,8 +1594,13 @@ static int rockchip_set_mux(struct rockchip_pin_bank *bank, int pin, int mux)
 	rmask = data | (data >> 16);
 	data |= (mux & mask) << bit;
 	ret = regmap_update_bits(regmap, reg, rmask, data);
+	if (ret)
+		return ret;
 
-	return ret;
+	if (ctrl->type == RK3572)
+		return rk3572_enable_input(bank, pin);
+
+	return 0;
 }
 
 #define PX30_PULL_PMU_OFFSET		0x10
@@ -3097,6 +3128,151 @@ static int rk3568_calc_drv_reg_and_bit(struct rockchip_pin_bank *bank,
 	return 0;
 }
 
+#define RK3572_DRV_BITS_PER_PIN		4
+#define RK3572_DRV_PINS_PER_REG		4
+#define RK3572_DRV_GPIO0_OFFSET		0x100
+#define RK3572_DRV_GPIO1_OFFSET		0x10120
+#define RK3572_DRV_GPIO2_OFFSET		0x12140
+#define RK3572_DRV_GPIO3_OFFSET		0x14160
+#define RK3572_DRV_GPIO4_OFFSET		0x14180
+
+static int rk3572_calc_drv_reg_and_bit(struct rockchip_pin_bank *bank,
+				       int pin_num, struct regmap **regmap,
+				       int *reg, u8 *bit)
+{
+	struct rockchip_pinctrl *info = bank->drvdata;
+
+	*regmap = info->regmap_base;
+
+	switch (bank->bank_num) {
+	case 0:
+		*reg = RK3572_DRV_GPIO0_OFFSET;
+		if (pin_num >= 12)
+			*reg += 0x2000;
+		break;
+	case 1:
+		*reg = RK3572_DRV_GPIO1_OFFSET;
+		break;
+	case 2:
+		*reg = RK3572_DRV_GPIO2_OFFSET;
+		break;
+	case 3:
+		*reg = RK3572_DRV_GPIO3_OFFSET;
+		break;
+	case 4:
+		*reg = RK3572_DRV_GPIO4_OFFSET;
+		if (pin_num >= 16)
+			*reg -= 0x10000;
+		break;
+	default:
+		dev_err(info->dev, "unsupported bank_num %d\n", bank->bank_num);
+		return -EINVAL;
+	}
+
+	*reg += ((pin_num / RK3572_DRV_PINS_PER_REG) * 4);
+	*bit = pin_num % RK3572_DRV_PINS_PER_REG;
+	*bit *= RK3572_DRV_BITS_PER_PIN;
+
+	return 0;
+}
+
+#define RK3572_PULL_BITS_PER_PIN	2
+#define RK3572_PULL_PINS_PER_REG	8
+#define RK3572_PULL_GPIO0_OFFSET	0x200
+#define RK3572_PULL_GPIO1_OFFSET	0x10210
+#define RK3572_PULL_GPIO2_OFFSET	0x12220
+#define RK3572_PULL_GPIO3_OFFSET	0x14230
+#define RK3572_PULL_GPIO4_OFFSET	0x14240
+
+static int rk3572_calc_pull_reg_and_bit(struct rockchip_pin_bank *bank,
+					int pin_num, struct regmap **regmap,
+					int *reg, u8 *bit)
+{
+	struct rockchip_pinctrl *info = bank->drvdata;
+
+	*regmap = info->regmap_base;
+
+	switch (bank->bank_num) {
+	case 0:
+		*reg = RK3572_PULL_GPIO0_OFFSET;
+		if (pin_num >= 12)
+			*reg += 0x2000;
+		break;
+	case 1:
+		*reg = RK3572_PULL_GPIO1_OFFSET;
+		break;
+	case 2:
+		*reg = RK3572_PULL_GPIO2_OFFSET;
+		break;
+	case 3:
+		*reg = RK3572_PULL_GPIO3_OFFSET;
+		break;
+	case 4:
+		*reg = RK3572_PULL_GPIO4_OFFSET;
+		if (pin_num >= 16)
+			*reg -= 0x10000;
+		break;
+	default:
+		dev_err(info->dev, "unsupported bank_num %d\n", bank->bank_num);
+		return -EINVAL;
+	}
+
+	*reg += ((pin_num / RK3572_PULL_PINS_PER_REG) * 4);
+	*bit = pin_num % RK3572_PULL_PINS_PER_REG;
+	*bit *= RK3572_PULL_BITS_PER_PIN;
+
+	return 0;
+}
+
+#define RK3572_SMT_BITS_PER_PIN		1
+#define RK3572_SMT_PINS_PER_REG		8
+#define RK3572_SMT_GPIO0_OFFSET		0x400
+#define RK3572_SMT_GPIO1_OFFSET		0x10410
+#define RK3572_SMT_GPIO2_OFFSET		0x12420
+#define RK3572_SMT_GPIO3_OFFSET		0x14430
+#define RK3572_SMT_GPIO4_OFFSET		0x14440
+
+static int rk3572_calc_schmitt_reg_and_bit(struct rockchip_pin_bank *bank,
+					   int pin_num,
+					   struct regmap **regmap,
+					   int *reg, u8 *bit)
+{
+	struct rockchip_pinctrl *info = bank->drvdata;
+
+	*regmap = info->regmap_base;
+
+	switch (bank->bank_num) {
+	case 0:
+		*reg = RK3572_SMT_GPIO0_OFFSET;
+		if (pin_num >= 12)
+			*reg += 0x2000;
+		break;
+	case 1:
+		*reg = RK3572_SMT_GPIO1_OFFSET;
+		break;
+	case 2:
+		*reg = RK3572_SMT_GPIO2_OFFSET;
+		break;
+	case 3:
+		*reg = RK3572_SMT_GPIO3_OFFSET;
+		break;
+	case 4:
+		*reg = RK3572_SMT_GPIO4_OFFSET;
+		if (pin_num >= 16)
+			*reg -= 0x10000;
+		break;
+	default:
+		dev_err(info->dev, "unsupported bank_num %d\n", bank->bank_num);
+		return -EINVAL;
+	}
+
+	*reg += ((pin_num / RK3572_SMT_PINS_PER_REG) * 4);
+	*bit = pin_num % RK3572_SMT_PINS_PER_REG;
+	*bit *= RK3572_SMT_BITS_PER_PIN;
+
+	return 0;
+}
+
 #define RK3576_DRV_BITS_PER_PIN		4
 #define RK3576_DRV_PINS_PER_REG		4
 #define RK3576_DRV_GPIO0_AL_OFFSET	0x10
@@ -3441,6 +3617,18 @@ static int rockchip_get_drive_perpin(struct rockchip_pin_bank *bank,
 	if (ret)
 		return ret;
 
+	if (ctrl->type == RK3572) {
+		ret = regmap_read(regmap, reg, &data);
+		if (ret)
+			return ret;
+		data >>= bit;
+		if ((bank->bank_num == 0 && pin_num < 12) ||
+		    (bank->bank_num == 4 && (pin_num == 24 || pin_num == 25)))
+			return ((data & BIT(1)) >> 1) | ((data & BIT(0)) << 1);
+		return ((data & BIT(2)) >> 2) | ((data & BIT(0)) << 2) |
+		       (data & BIT(1));
+	}
+
 	switch (drv_type) {
 	case DRV_TYPE_IO_1V8_3V0_AUTO:
 	case DRV_TYPE_IO_3V3_ONLY:
@@ -3559,6 +3747,22 @@ static int rockchip_set_drive_perpin(struct rockchip_pin_bank *bank,
 		rmask_bits = RK3568_DRV_BITS_PER_PIN;
 		ret = (1 << (strength + 1)) - 1;
 		goto config;
+	} else if (ctrl->type == RK3572) {
+		if (strength < 0 || strength > 7)
+			return -EINVAL;
+		rmask_bits = RK3572_DRV_BITS_PER_PIN;
+		if ((bank->bank_num == 0 && pin_num < 12) ||
+		    (bank->bank_num == 4 && (pin_num == 24 || pin_num == 25))) {
+			/* Only four drive-strength levels are supported. */
+			if (strength > 3)
+				return -EINVAL;
+			ret = ((strength & BIT(1)) >> 1) | ((strength & BIT(0)) << 1);
+		} else {
+			ret = ((strength & BIT(2)) >> 2) |
+			      ((strength & BIT(0)) << 2) |
+			      (strength & BIT(1));
+		}
+		goto config;
 	} else if (ctrl->type == RK3576) {
 		rmask_bits = RK3576_DRV_BITS_PER_PIN;
 		ret = ((strength & BIT(2)) >> 2) | ((strength & BIT(0)) << 2) | (strength & BIT(1));
@@ -3717,6 +3921,7 @@ static int rockchip_get_pull(struct rockchip_pin_bank *bank, int pin_num)
 	case RK3528:
 	case RK3562:
 	case RK3568:
+	case RK3572:
 	case RK3576:
 	case RK3588:
 		pull_type = bank->pull_type[pin_num / 8];
@@ -3786,6 +3991,7 @@ static int rockchip_set_pull(struct rockchip_pin_bank *bank,
 	case RK3528:
 	case RK3562:
 	case RK3568:
+	case RK3572:
 	case RK3576:
 	case RK3588:
 		pull_type = bank->pull_type[pin_num / 8];
@@ -4084,6 +4290,7 @@ static bool rockchip_pinconf_pull_valid(struct rockchip_pin_ctrl *ctrl,
 	case RK3528:
 	case RK3562:
 	case RK3568:
+	case RK3572:
 	case RK3576:
 	case RK3588:
 		return (pull != PIN_CONFIG_BIAS_PULL_PIN_DEFAULT);
@@ -4296,6 +4503,7 @@ static const struct pinconf_ops rockchip_pinconf_ops = {
 
 static const struct of_device_id rockchip_bank_match[] = {
 	{ .compatible = "rockchip,gpio-bank" },
+	{ .compatible = "rockchip,rk3572-gpio-bank" },
 	{ .compatible = "rockchip,rk3188-gpio-bank0" },
 	{},
 };
@@ -5643,6 +5851,24 @@ static struct rockchip_pin_ctrl rk3568_pin_ctrl = {
 					       PULL_TYPE_IO_1V8_ONLY,	\
 					       PULL_TYPE_IO_1V8_ONLY)
 
+static struct rockchip_pin_bank rk3572_pin_banks[] = {
+	RK3576_PIN_BANK(0, "gpio0", 0, 0x8, 0x2010, 0x2018),
+	RK3576_PIN_BANK(1, "gpio1", 0x10020, 0x10028, 0x10030, 0x10038),
+	RK3576_PIN_BANK(2, "gpio2", 0x12040, 0x12048, 0x12050, 0x12058),
+	RK3576_PIN_BANK(3, "gpio3", 0x14060, 0x14068, 0x14070, 0x14078),
+	RK3576_PIN_BANK(4, "gpio4", 0x14080, 0x14088, 0x4090, 0x4098),
+};
+
+static struct rockchip_pin_ctrl rk3572_pin_ctrl __maybe_unused = {
+	.pin_banks		= rk3572_pin_banks,
+	.nr_banks		= ARRAY_SIZE(rk3572_pin_banks),
+	.label			= "RK3572-GPIO",
+	.type			= RK3572,
+	.pull_calc_reg		= rk3572_calc_pull_reg_and_bit,
+	.drv_calc_reg		= rk3572_calc_drv_reg_and_bit,
+	.schmitt_calc_reg	= rk3572_calc_schmitt_reg_and_bit,
+};
+
 static struct rockchip_pin_bank rk3576_pin_banks[] = {
 	RK3576_PIN_BANK(0, "gpio0", 0, 0x8, 0x2004, 0x200C),
 	RK3576_PIN_BANK(1, "gpio1", 0x4020, 0x4028, 0x4030, 0x4038),
@@ -5727,6 +5953,8 @@ static const struct of_device_id rockchip_pinctrl_dt_match[] = {
 		.data = &rk3562_pin_ctrl },
 	{ .compatible = "rockchip,rk3568-pinctrl",
 		.data = &rk3568_pin_ctrl },
+	{ .compatible = "rockchip,rk3572-pinctrl",
+		.data = &rk3572_pin_ctrl },
 	{ .compatible = "rockchip,rk3576-pinctrl",
 		.data = &rk3576_pin_ctrl },
 	{ .compatible = "rockchip,rk3588-pinctrl",
diff --git a/drivers/pinctrl/pinctrl-rockchip.h b/drivers/pinctrl/pinctrl-rockchip.h
index 950097699643..553197f6dc69 100644
--- a/drivers/pinctrl/pinctrl-rockchip.h
+++ b/drivers/pinctrl/pinctrl-rockchip.h
@@ -203,6 +203,7 @@ enum rockchip_pinctrl_type {
 	RK3528,
 	RK3562,
 	RK3568,
+	RK3572,
 	RK3576,
 	RK3588,
 };

-- 
2.34.1

