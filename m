From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Thu, 21 May 2026 08:26:59 +0000
Subject: [PATCH v3 2/2] pwm: meson: Add support for Amlogic S7
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260521-s6-s7-pwm-v3-2-57b073fbafef@amlogic.com>
References: <20260521-s6-s7-pwm-v3-0-57b073fbafef@amlogic.com>
In-Reply-To: <20260521-s6-s7-pwm-v3-0-57b073fbafef@amlogic.com>
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-pwm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779352023; l=5104;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=ee7S/9E5/xxvFyHNx3kYA681vl0XgvW4Y8eFZhpoo0U=;
 b=TXiAdEYbw/KybAgqyonbV6T/exp3oQ74Da0C919cp5Yin7jK9EMw1J+LofGU2rmIBRHa/Yom2
 qGwM9+P1ScGAT1BFgu9YEEYa3gT6jpNbGBiMxyO/URz5UFU2L/CFeJe
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for Amlogic S7 PWM. Amlogic S7 different from the
previous SoCs, a controller includes one pwm, at the same time,
the controller has only one input clock source.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 drivers/pwm/pwm-meson.c | 41 ++++++++++++++++++++++++++++++++++++++---
 1 file changed, 38 insertions(+), 3 deletions(-)

diff --git a/drivers/pwm/pwm-meson.c b/drivers/pwm/pwm-meson.c
index 8c6bf3d49753..66c41bf036de 100644
--- a/drivers/pwm/pwm-meson.c
+++ b/drivers/pwm/pwm-meson.c
@@ -113,6 +113,7 @@ struct meson_pwm_data {
 	int (*channels_init)(struct pwm_chip *chip);
 	bool has_constant;
 	bool has_polarity;
+	u8 npwm;
 };
 
 struct meson_pwm {
@@ -503,6 +504,18 @@ static void meson_pwm_s4_put_clk(void *data)
 	clk_put(clk);
 }
 
+static int meson_pwm_init_channels_s7(struct pwm_chip *chip)
+{
+	struct device *dev = pwmchip_parent(chip);
+	struct meson_pwm *meson = to_meson_pwm(chip);
+
+	meson->channels[0].clk = devm_clk_get(dev, NULL);
+	if (IS_ERR(meson->channels[0].clk))
+		return dev_err_probe(dev, PTR_ERR(meson->channels[0].clk),
+				     "Failed to get clk\n");
+	return 0;
+}
+
 static int meson_pwm_init_channels_s4(struct pwm_chip *chip)
 {
 	struct device *dev = pwmchip_parent(chip);
@@ -530,6 +543,7 @@ static int meson_pwm_init_channels_s4(struct pwm_chip *chip)
 static const struct meson_pwm_data pwm_meson8b_data = {
 	.parent_names = { "xtal", NULL, "fclk_div4", "fclk_div3" },
 	.channels_init = meson_pwm_init_channels_meson8b_legacy,
+	.npwm = MESON_NUM_PWMS,
 };
 
 /*
@@ -539,6 +553,7 @@ static const struct meson_pwm_data pwm_meson8b_data = {
 static const struct meson_pwm_data pwm_gxbb_ao_data = {
 	.parent_names = { "xtal", "clk81", NULL, NULL },
 	.channels_init = meson_pwm_init_channels_meson8b_legacy,
+	.npwm = MESON_NUM_PWMS,
 };
 
 static const struct meson_pwm_data pwm_axg_ee_data = {
@@ -546,6 +561,7 @@ static const struct meson_pwm_data pwm_axg_ee_data = {
 	.channels_init = meson_pwm_init_channels_meson8b_legacy,
 	.has_constant = true,
 	.has_polarity = true,
+	.npwm = MESON_NUM_PWMS,
 };
 
 static const struct meson_pwm_data pwm_axg_ao_data = {
@@ -553,6 +569,7 @@ static const struct meson_pwm_data pwm_axg_ao_data = {
 	.channels_init = meson_pwm_init_channels_meson8b_legacy,
 	.has_constant = true,
 	.has_polarity = true,
+	.npwm = MESON_NUM_PWMS,
 };
 
 static const struct meson_pwm_data pwm_g12a_ee_data = {
@@ -560,6 +577,7 @@ static const struct meson_pwm_data pwm_g12a_ee_data = {
 	.channels_init = meson_pwm_init_channels_meson8b_legacy,
 	.has_constant = true,
 	.has_polarity = true,
+	.npwm = MESON_NUM_PWMS,
 };
 
 static const struct meson_pwm_data pwm_g12a_ao_ab_data = {
@@ -567,6 +585,7 @@ static const struct meson_pwm_data pwm_g12a_ao_ab_data = {
 	.channels_init = meson_pwm_init_channels_meson8b_legacy,
 	.has_constant = true,
 	.has_polarity = true,
+	.npwm = MESON_NUM_PWMS,
 };
 
 static const struct meson_pwm_data pwm_g12a_ao_cd_data = {
@@ -574,22 +593,33 @@ static const struct meson_pwm_data pwm_g12a_ao_cd_data = {
 	.channels_init = meson_pwm_init_channels_meson8b_legacy,
 	.has_constant = true,
 	.has_polarity = true,
+	.npwm = MESON_NUM_PWMS,
 };
 
 static const struct meson_pwm_data pwm_meson8_v2_data = {
 	.channels_init = meson_pwm_init_channels_meson8b_v2,
+	.npwm = MESON_NUM_PWMS,
 };
 
 static const struct meson_pwm_data pwm_meson_axg_v2_data = {
 	.channels_init = meson_pwm_init_channels_meson8b_v2,
 	.has_constant = true,
 	.has_polarity = true,
+	.npwm = MESON_NUM_PWMS,
 };
 
 static const struct meson_pwm_data pwm_s4_data = {
 	.channels_init = meson_pwm_init_channels_s4,
 	.has_constant = true,
 	.has_polarity = true,
+	.npwm = MESON_NUM_PWMS,
+};
+
+static const struct meson_pwm_data pwm_s7_data = {
+	.channels_init = meson_pwm_init_channels_s7,
+	.has_constant = true,
+	.has_polarity = true,
+	.npwm = 1,
 };
 
 static const struct of_device_id meson_pwm_matches[] = {
@@ -642,7 +672,11 @@ static const struct of_device_id meson_pwm_matches[] = {
 		.compatible = "amlogic,meson-s4-pwm",
 		.data = &pwm_s4_data
 	},
-	{},
+	{
+		.compatible = "amlogic,s7-pwm",
+		.data = &pwm_s7_data
+	},
+	{ }
 };
 MODULE_DEVICE_TABLE(of, meson_pwm_matches);
 
@@ -650,9 +684,10 @@ static int meson_pwm_probe(struct platform_device *pdev)
 {
 	struct pwm_chip *chip;
 	struct meson_pwm *meson;
+	const struct meson_pwm_data *pdata = of_device_get_match_data(&pdev->dev);
 	int err;
 
-	chip = devm_pwmchip_alloc(&pdev->dev, MESON_NUM_PWMS, sizeof(*meson));
+	chip = devm_pwmchip_alloc(&pdev->dev, pdata->npwm, sizeof(*meson));
 	if (IS_ERR(chip))
 		return PTR_ERR(chip);
 	meson = to_meson_pwm(chip);
@@ -664,7 +699,7 @@ static int meson_pwm_probe(struct platform_device *pdev)
 	spin_lock_init(&meson->lock);
 	chip->ops = &meson_pwm_ops;
 
-	meson->data = of_device_get_match_data(&pdev->dev);
+	meson->data = pdata;
 
 	err = meson->data->channels_init(chip);
 	if (err < 0)

-- 
2.52.0

