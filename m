From: Kelvin Zhang <kelvin.zhang@amlogic.com>
Date: Thu, 13 Jun 2024 19:46:35 +0800
Subject: [PATCH v8 1/2] pwm: meson: Add support for Amlogic S4 PWM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240613-s4-pwm-v8-1-b5bd0a768282@amlogic.com>
References: <20240613-s4-pwm-v8-0-b5bd0a768282@amlogic.com>
In-Reply-To: <20240613-s4-pwm-v8-0-b5bd0a768282@amlogic.com>
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@pengutronix.de>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pwm@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Kelvin Zhang <kelvin.zhang@amlogic.com>, 
 Junyi Zhao <junyi.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718279231; l=2242;
 i=kelvin.zhang@amlogic.com; s=20240329; h=from:subject:message-id;
 bh=dwmGsdqAEwQLKSoMsQIDCvsk9F7mUyX4lQiaMw6xB40=;
 b=PUnfZ4mzns+rxE0HtGPXEcYGpdRjcKqzUBEqN9+o9pLHDZtrkOzknLMkJy6Pm8l7A8vDYRg7E
 16ZoAfi0aG3C8LnJUQ8nrYtr4L3Zsy/ZbWEA+3a4QtgxKIaDCmvSR7w
X-Developer-Key: i=kelvin.zhang@amlogic.com; a=ed25519;
 pk=pgnle7HTNvnNTcOoGejvtTC7BJT30HUNXfMHRRXSylI=
X-Endpoint-Received: by B4 Relay for kelvin.zhang@amlogic.com/20240329 with auth_id=148
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Junyi Zhao <junyi.zhao@amlogic.com>

Add support for Amlogic S4 PWM.

Signed-off-by: Junyi Zhao <junyi.zhao@amlogic.com>
Signed-off-by: Kelvin Zhang <kelvin.zhang@amlogic.com>
---
 drivers/pwm/pwm-meson.c | 39 +++++++++++++++++++++++++++++++++++++++
 1 file changed, 39 insertions(+)

diff --git a/drivers/pwm/pwm-meson.c b/drivers/pwm/pwm-meson.c
index b2f97dfb01bb..98e6c1533312 100644
--- a/drivers/pwm/pwm-meson.c
+++ b/drivers/pwm/pwm-meson.c
@@ -460,6 +460,37 @@ static int meson_pwm_init_channels_meson8b_v2(struct pwm_chip *chip)
 	return meson_pwm_init_clocks_meson8b(chip, mux_parent_data);
 }
 
+static void meson_pwm_s4_put_clk(void *data)
+{
+	struct clk *clk = data;
+
+	clk_put(clk);
+}
+
+static int meson_pwm_init_channels_s4(struct pwm_chip *chip)
+{
+	struct device *dev = pwmchip_parent(chip);
+	struct device_node *np = dev->of_node;
+	struct meson_pwm *meson = to_meson_pwm(chip);
+	int i, ret;
+
+	for (i = 0; i < MESON_NUM_PWMS; i++) {
+		meson->channels[i].clk = of_clk_get(np, i);
+		if (IS_ERR(meson->channels[i].clk))
+			return dev_err_probe(dev,
+					     PTR_ERR(meson->channels[i].clk),
+					     "Failed to get clk\n");
+
+		ret = devm_add_action_or_reset(dev, meson_pwm_s4_put_clk,
+					       meson->channels[i].clk);
+		if (ret)
+			return dev_err_probe(dev, ret,
+					     "Failed to add clk_put action\n");
+	}
+
+	return 0;
+}
+
 static const struct meson_pwm_data pwm_meson8b_data = {
 	.parent_names = { "xtal", NULL, "fclk_div4", "fclk_div3" },
 	.channels_init = meson_pwm_init_channels_meson8b_legacy,
@@ -498,6 +529,10 @@ static const struct meson_pwm_data pwm_meson8_v2_data = {
 	.channels_init = meson_pwm_init_channels_meson8b_v2,
 };
 
+static const struct meson_pwm_data pwm_s4_data = {
+	.channels_init = meson_pwm_init_channels_s4,
+};
+
 static const struct of_device_id meson_pwm_matches[] = {
 	{
 		.compatible = "amlogic,meson8-pwm-v2",
@@ -536,6 +571,10 @@ static const struct of_device_id meson_pwm_matches[] = {
 		.compatible = "amlogic,meson-g12a-ao-pwm-cd",
 		.data = &pwm_g12a_ao_cd_data
 	},
+	{
+		.compatible = "amlogic,meson-s4-pwm",
+		.data = &pwm_s4_data
+	},
 	{},
 };
 MODULE_DEVICE_TABLE(of, meson_pwm_matches);

-- 
2.37.1

