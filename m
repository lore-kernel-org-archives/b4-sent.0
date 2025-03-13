From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Thu, 13 Mar 2025 14:19:25 +0000
Subject: [PATCH 08/18] pwm: adp5585: add support for adp5589
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250313-dev-adp5589-fw-v1-8-20e80d4bd4ea@analog.com>
References: <20250313-dev-adp5589-fw-v1-0-20e80d4bd4ea@analog.com>
In-Reply-To: <20250313-dev-adp5589-fw-v1-0-20e80d4bd4ea@analog.com>
To: linux-gpio@vger.kernel.org, linux-pwm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-input@vger.kernel.org
Cc: Lee Jones <lee@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Liu Ying <victor.liu@nxp.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741875561; l=5649;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=hDQwADPyhZkCjzlHyCqBfWfElr8WKeXEQSF0RoHBdlI=;
 b=Nd7LWJ9g/k5y/A7ktl2WQVKmHJG9HZizRfvBLYtyVU1Vq30DKIjkapKCXqywu8QUt0oadYIZE
 zUIZ9A3dUICBhSa1IT4Jf3XxYs50+CFBdS37Y7upPCLJP2iI/6yLuH9
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the adp5589 I/O expander. From a PWM point of view it is
pretty similar to adp5585. Main difference is the address
of registers meaningful for configuring the PWM.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/pwm/pwm-adp5585.c | 51 ++++++++++++++++++++++++++++++++---------------
 1 file changed, 35 insertions(+), 16 deletions(-)

diff --git a/drivers/pwm/pwm-adp5585.c b/drivers/pwm/pwm-adp5585.c
index c8821035b7c1412a55a642e6e8a46b66e693a5af..cc8ac8f9e5669b4ffca06d4117a29f030393f48f 100644
--- a/drivers/pwm/pwm-adp5585.c
+++ b/drivers/pwm/pwm-adp5585.c
@@ -32,21 +32,30 @@
 #define ADP5585_PWM_MIN_PERIOD_NS	(2ULL * NSEC_PER_SEC / ADP5585_PWM_OSC_FREQ_HZ)
 #define ADP5585_PWM_MAX_PERIOD_NS	(2ULL * 0xffff * NSEC_PER_SEC / ADP5585_PWM_OSC_FREQ_HZ)
 
+struct adp5585_pwm {
+	const struct adp5585_regs *regs;
+	struct regmap *regmap;
+};
+
 static int pwm_adp5585_request(struct pwm_chip *chip, struct pwm_device *pwm)
 {
-	struct regmap *regmap = pwmchip_get_drvdata(chip);
+	struct adp5585_pwm *adp5585_pwm = pwmchip_get_drvdata(chip);
+	const struct adp5585_regs *regs = adp5585_pwm->regs;
+	struct regmap *regmap = adp5585_pwm->regmap;
 
 	/* Configure the R3 pin as PWM output. */
-	return regmap_update_bits(regmap, ADP5585_PIN_CONFIG_C,
+	return regmap_update_bits(regmap, regs->ext_cfg,
 				  ADP5585_R3_EXTEND_CFG_MASK,
 				  ADP5585_R3_EXTEND_CFG_PWM_OUT);
 }
 
 static void pwm_adp5585_free(struct pwm_chip *chip, struct pwm_device *pwm)
 {
-	struct regmap *regmap = pwmchip_get_drvdata(chip);
+	struct adp5585_pwm *adp5585_pwm = pwmchip_get_drvdata(chip);
+	const struct adp5585_regs *regs = adp5585_pwm->regs;
+	struct regmap *regmap = adp5585_pwm->regmap;
 
-	regmap_update_bits(regmap, ADP5585_PIN_CONFIG_C,
+	regmap_update_bits(regmap, regs->ext_cfg,
 			   ADP5585_R3_EXTEND_CFG_MASK,
 			   ADP5585_R3_EXTEND_CFG_GPIO4);
 }
@@ -55,14 +64,16 @@ static int pwm_adp5585_apply(struct pwm_chip *chip,
 			     struct pwm_device *pwm,
 			     const struct pwm_state *state)
 {
-	struct regmap *regmap = pwmchip_get_drvdata(chip);
+	struct adp5585_pwm *adp5585_pwm = pwmchip_get_drvdata(chip);
+	const struct adp5585_regs *regs = adp5585_pwm->regs;
+	struct regmap *regmap = adp5585_pwm->regmap;
 	u64 period, duty_cycle;
 	u32 on, off;
 	__le16 val;
 	int ret;
 
 	if (!state->enabled) {
-		regmap_clear_bits(regmap, ADP5585_PWM_CFG, ADP5585_PWM_EN);
+		regmap_clear_bits(regmap, regs->pwm_cfg, ADP5585_PWM_EN);
 		return 0;
 	}
 
@@ -83,41 +94,43 @@ static int pwm_adp5585_apply(struct pwm_chip *chip,
 	off = div_u64(period, NSEC_PER_SEC / ADP5585_PWM_OSC_FREQ_HZ) - on;
 
 	val = cpu_to_le16(off);
-	ret = regmap_bulk_write(regmap, ADP5585_PWM_OFFT_LOW, &val, 2);
+	ret = regmap_bulk_write(regmap, regs->pwm_offt_low, &val, 2);
 	if (ret)
 		return ret;
 
 	val = cpu_to_le16(on);
-	ret = regmap_bulk_write(regmap, ADP5585_PWM_ONT_LOW, &val, 2);
+	ret = regmap_bulk_write(regmap, regs->pwm_ont_low, &val, 2);
 	if (ret)
 		return ret;
 
 	/* Enable PWM in continuous mode and no external AND'ing. */
-	ret = regmap_update_bits(regmap, ADP5585_PWM_CFG,
+	ret = regmap_update_bits(regmap, regs->pwm_cfg,
 				 ADP5585_PWM_IN_AND | ADP5585_PWM_MODE |
 				 ADP5585_PWM_EN, ADP5585_PWM_EN);
 	if (ret)
 		return ret;
 
-	return regmap_set_bits(regmap, ADP5585_PWM_CFG, ADP5585_PWM_EN);
+	return regmap_set_bits(regmap, regs->pwm_cfg, ADP5585_PWM_EN);
 }
 
 static int pwm_adp5585_get_state(struct pwm_chip *chip,
 				 struct pwm_device *pwm,
 				 struct pwm_state *state)
 {
-	struct regmap *regmap = pwmchip_get_drvdata(chip);
+	struct adp5585_pwm *adp5585_pwm = pwmchip_get_drvdata(chip);
+	const struct adp5585_regs *regs = adp5585_pwm->regs;
+	struct regmap *regmap = adp5585_pwm->regmap;
 	unsigned int on, off;
 	unsigned int val;
 	__le16 on_off;
 	int ret;
 
-	ret = regmap_bulk_read(regmap, ADP5585_PWM_OFFT_LOW, &on_off, 2);
+	ret = regmap_bulk_read(regmap, regs->pwm_offt_low, &on_off, 2);
 	if (ret)
 		return ret;
 	off = le16_to_cpu(on_off);
 
-	ret = regmap_bulk_read(regmap, ADP5585_PWM_ONT_LOW, &on_off, 2);
+	ret = regmap_bulk_read(regmap, regs->pwm_ont_low, &on_off, 2);
 	if (ret)
 		return ret;
 	on = le16_to_cpu(on_off);
@@ -127,7 +140,7 @@ static int pwm_adp5585_get_state(struct pwm_chip *chip,
 
 	state->polarity = PWM_POLARITY_NORMAL;
 
-	regmap_read(regmap, ADP5585_PWM_CFG, &val);
+	regmap_read(regmap, regs->pwm_cfg, &val);
 	state->enabled = !!(val & ADP5585_PWM_EN);
 
 	return 0;
@@ -144,16 +157,21 @@ static int adp5585_pwm_probe(struct platform_device *pdev)
 {
 	struct device *dev = &pdev->dev;
 	struct adp5585_dev *adp5585 = dev_get_drvdata(dev->parent);
+	struct adp5585_pwm *adp5585_pwm;
 	struct pwm_chip *chip;
 	int ret;
 
-	chip = devm_pwmchip_alloc(dev, ADP5585_PWM_CHAN_NUM, 0);
+	chip = devm_pwmchip_alloc(dev, ADP5585_PWM_CHAN_NUM,
+				  sizeof(*adp5585_pwm));
 	if (IS_ERR(chip))
 		return PTR_ERR(chip);
 
+	adp5585_pwm = pwmchip_get_drvdata(chip);
+	adp5585_pwm->regmap = adp5585->regmap;
+	adp5585_pwm->regs = adp5585->info->regs;
+
 	device_set_of_node_from_dev(dev, dev->parent);
 
-	pwmchip_set_drvdata(chip, adp5585->regmap);
 	chip->ops = &adp5585_pwm_ops;
 
 	ret = devm_pwmchip_add(dev, chip);
@@ -165,6 +183,7 @@ static int adp5585_pwm_probe(struct platform_device *pdev)
 
 static const struct platform_device_id adp5585_pwm_id_table[] = {
 	{ "adp5585-pwm" },
+	{ "adp5589-pwm" },
 	{ /* Sentinel */ }
 };
 MODULE_DEVICE_TABLE(platform, adp5585_pwm_id_table);

-- 
2.48.1

