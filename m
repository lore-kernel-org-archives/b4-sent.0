From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Thu, 27 Aug 2026 08:40:11 +0000
Subject: [PATCH v4 2/4] pwm: meson: add the PWM count driver data
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260827-s6-s7-pwm-v4-2-d28a2015177d@amlogic.com>
References: <20260827-s6-s7-pwm-v4-0-d28a2015177d@amlogic.com>
In-Reply-To: <20260827-s6-s7-pwm-v4-0-d28a2015177d@amlogic.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787820043; l=4621;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=XWBLCai/fzPSLXT+rV6gvMmqDHi7OFZogDsuyVzW6gk=;
 b=Rh9OjEOD7SNxnECzTQEmrJSTchFP5bhVfta+X6y2sVbP3EbhfJ6CZfSi1WkgC2qIsCwNZv0rq
 Z1YyvX/Xj/fCH3vrsAFgdZ5vcf9hEZiU/0sVB4IXqNQ7PoIEkRdXils
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add .npwm fill the  existing entries, use it in probe, and switch the loop
in meson_pwm_init_clocks_meson8b() and meson_pwm_init_channels_s4() to
chip->npwm. No functional change.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 drivers/pwm/pwm-meson.c | 20 ++++++++++++++++----
 1 file changed, 16 insertions(+), 4 deletions(-)

diff --git a/drivers/pwm/pwm-meson.c b/drivers/pwm/pwm-meson.c
index 8c6bf3d49753..22cefc6d5dd0 100644
--- a/drivers/pwm/pwm-meson.c
+++ b/drivers/pwm/pwm-meson.c
@@ -113,6 +113,7 @@ struct meson_pwm_data {
 	int (*channels_init)(struct pwm_chip *chip);
 	bool has_constant;
 	bool has_polarity;
+	u8 npwm;
 };
 
 struct meson_pwm {
@@ -382,7 +383,7 @@ static int meson_pwm_init_clocks_meson8b(struct pwm_chip *chip,
 	char name[255];
 	int err;
 
-	for (i = 0; i < MESON_NUM_PWMS; i++) {
+	for (i = 0; i < chip->npwm; i++) {
 		struct meson_pwm_channel *channel = &meson->channels[i];
 		struct clk_parent_data div_parent = {}, gate_parent = {};
 		struct clk_init_data init = {};
@@ -510,7 +511,7 @@ static int meson_pwm_init_channels_s4(struct pwm_chip *chip)
 	struct meson_pwm *meson = to_meson_pwm(chip);
 	int i, ret;
 
-	for (i = 0; i < MESON_NUM_PWMS; i++) {
+	for (i = 0; i < chip->npwm; i++) {
 		meson->channels[i].clk = of_clk_get(np, i);
 		if (IS_ERR(meson->channels[i].clk))
 			return dev_err_probe(dev,
@@ -530,6 +531,7 @@ static int meson_pwm_init_channels_s4(struct pwm_chip *chip)
 static const struct meson_pwm_data pwm_meson8b_data = {
 	.parent_names = { "xtal", NULL, "fclk_div4", "fclk_div3" },
 	.channels_init = meson_pwm_init_channels_meson8b_legacy,
+	.npwm = 2,
 };
 
 /*
@@ -539,6 +541,7 @@ static const struct meson_pwm_data pwm_meson8b_data = {
 static const struct meson_pwm_data pwm_gxbb_ao_data = {
 	.parent_names = { "xtal", "clk81", NULL, NULL },
 	.channels_init = meson_pwm_init_channels_meson8b_legacy,
+	.npwm = 2,
 };
 
 static const struct meson_pwm_data pwm_axg_ee_data = {
@@ -546,6 +549,7 @@ static const struct meson_pwm_data pwm_axg_ee_data = {
 	.channels_init = meson_pwm_init_channels_meson8b_legacy,
 	.has_constant = true,
 	.has_polarity = true,
+	.npwm = 2,
 };
 
 static const struct meson_pwm_data pwm_axg_ao_data = {
@@ -553,6 +557,7 @@ static const struct meson_pwm_data pwm_axg_ao_data = {
 	.channels_init = meson_pwm_init_channels_meson8b_legacy,
 	.has_constant = true,
 	.has_polarity = true,
+	.npwm = 2,
 };
 
 static const struct meson_pwm_data pwm_g12a_ee_data = {
@@ -560,6 +565,7 @@ static const struct meson_pwm_data pwm_g12a_ee_data = {
 	.channels_init = meson_pwm_init_channels_meson8b_legacy,
 	.has_constant = true,
 	.has_polarity = true,
+	.npwm = 2,
 };
 
 static const struct meson_pwm_data pwm_g12a_ao_ab_data = {
@@ -567,6 +573,7 @@ static const struct meson_pwm_data pwm_g12a_ao_ab_data = {
 	.channels_init = meson_pwm_init_channels_meson8b_legacy,
 	.has_constant = true,
 	.has_polarity = true,
+	.npwm = 2,
 };
 
 static const struct meson_pwm_data pwm_g12a_ao_cd_data = {
@@ -574,22 +581,26 @@ static const struct meson_pwm_data pwm_g12a_ao_cd_data = {
 	.channels_init = meson_pwm_init_channels_meson8b_legacy,
 	.has_constant = true,
 	.has_polarity = true,
+	.npwm = 2,
 };
 
 static const struct meson_pwm_data pwm_meson8_v2_data = {
 	.channels_init = meson_pwm_init_channels_meson8b_v2,
+	.npwm = 2,
 };
 
 static const struct meson_pwm_data pwm_meson_axg_v2_data = {
 	.channels_init = meson_pwm_init_channels_meson8b_v2,
 	.has_constant = true,
 	.has_polarity = true,
+	.npwm = 2,
 };
 
 static const struct meson_pwm_data pwm_s4_data = {
 	.channels_init = meson_pwm_init_channels_s4,
 	.has_constant = true,
 	.has_polarity = true,
+	.npwm = 2,
 };
 
 static const struct of_device_id meson_pwm_matches[] = {
@@ -650,9 +661,10 @@ static int meson_pwm_probe(struct platform_device *pdev)
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
@@ -664,7 +676,7 @@ static int meson_pwm_probe(struct platform_device *pdev)
 	spin_lock_init(&meson->lock);
 	chip->ops = &meson_pwm_ops;
 
-	meson->data = of_device_get_match_data(&pdev->dev);
+	meson->data = pdata;
 
 	err = meson->data->channels_init(chip);
 	if (err < 0)

-- 
2.52.0

