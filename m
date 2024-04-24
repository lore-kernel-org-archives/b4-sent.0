From: Kelvin Zhang <kelvin.zhang@amlogic.com>
Date: Wed, 24 Apr 2024 18:28:34 +0800
Subject: [PATCH v4 1/2] pwm: meson: Add support for Amlogic S4 PWM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240424-s4-pwm-v4-1-ee22effd40d0@amlogic.com>
References: <20240424-s4-pwm-v4-0-ee22effd40d0@amlogic.com>
In-Reply-To: <20240424-s4-pwm-v4-0-ee22effd40d0@amlogic.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713954523; l=2139;
 i=kelvin.zhang@amlogic.com; s=20240329; h=from:subject:message-id;
 bh=gtMEBe84ZprBZCQ2WIxZzSC+jfy6SdQC7eTQHo6OrP0=;
 b=2QReknnu4j0rhx43sc1H5ezdFAmc2B0Conf7r5ceTUUiA7AhpLj1EGHL8ako++gaojevQyKMp
 /bUmR33rPpQBpTp6b3G0VADO0q5tb3bJ3U47m/++XxFOOnLyRO0dKc6
X-Developer-Key: i=kelvin.zhang@amlogic.com; a=ed25519;
 pk=pgnle7HTNvnNTcOoGejvtTC7BJT30HUNXfMHRRXSylI=
X-Endpoint-Received: by B4 Relay for kelvin.zhang@amlogic.com/20240329 with auth_id=148
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Junyi Zhao <junyi.zhao@amlogic.com>

This patch adds support for Amlogic S4 PWM.

Signed-off-by: Junyi Zhao <junyi.zhao@amlogic.com>
Signed-off-by: Kelvin Zhang <kelvin.zhang@amlogic.com>
---
 drivers/pwm/pwm-meson.c | 37 +++++++++++++++++++++++++++++++++++++
 1 file changed, 37 insertions(+)

diff --git a/drivers/pwm/pwm-meson.c b/drivers/pwm/pwm-meson.c
index ea96c5973488..6abc823745e4 100644
--- a/drivers/pwm/pwm-meson.c
+++ b/drivers/pwm/pwm-meson.c
@@ -462,6 +462,35 @@ static int meson_pwm_init_channels_meson8b_v2(struct pwm_chip *chip)
 	return meson_pwm_init_clocks_meson8b(chip, mux_parent_data);
 }
 
+static int meson_pwm_init_channels_meson_s4(struct pwm_chip *chip)
+{
+	int i, ret;
+	struct device *dev = pwmchip_parent(chip);
+	struct device_node *np = dev->of_node;
+	struct meson_pwm *meson = to_meson_pwm(chip);
+	struct meson_pwm_channel *channel;
+
+	for (i = 0; i < MESON_NUM_PWMS; i++) {
+		channel = &meson->channels[i];
+		channel->clk = of_clk_get(np, i);
+		if (IS_ERR(channel->clk)) {
+			ret = PTR_ERR(channel->clk);
+			dev_err_probe(dev, ret, "Failed to get clk\n");
+			goto err;
+		}
+	}
+
+	return 0;
+
+err:
+	while (--i >= 0) {
+		channel = &meson->channels[i];
+		clk_put(channel->clk);
+	}
+
+	return ret;
+}
+
 static const struct meson_pwm_data pwm_meson8b_data = {
 	.parent_names = { "xtal", NULL, "fclk_div4", "fclk_div3" },
 	.channels_init = meson_pwm_init_channels_meson8b_legacy,
@@ -500,6 +529,10 @@ static const struct meson_pwm_data pwm_meson8_v2_data = {
 	.channels_init = meson_pwm_init_channels_meson8b_v2,
 };
 
+static const struct meson_pwm_data pwm_meson_s4_data = {
+	.channels_init = meson_pwm_init_channels_meson_s4,
+};
+
 static const struct of_device_id meson_pwm_matches[] = {
 	{
 		.compatible = "amlogic,meson8-pwm-v2",
@@ -538,6 +571,10 @@ static const struct of_device_id meson_pwm_matches[] = {
 		.compatible = "amlogic,meson-g12a-ao-pwm-cd",
 		.data = &pwm_g12a_ao_cd_data
 	},
+	{
+		.compatible = "amlogic,meson-s4-pwm",
+		.data = &pwm_meson_s4_data
+	},
 	{},
 };
 MODULE_DEVICE_TABLE(of, meson_pwm_matches);

-- 
2.37.1

