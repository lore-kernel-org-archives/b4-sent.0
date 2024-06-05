From: Kelvin Zhang <kelvin.zhang@amlogic.com>
Date: Wed, 05 Jun 2024 10:44:55 +0800
Subject: [PATCH v7 1/2] pwm: meson: Add support for Amlogic S4 PWM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240605-s4-pwm-v7-1-e822b271d7b0@amlogic.com>
References: <20240605-s4-pwm-v7-0-e822b271d7b0@amlogic.com>
In-Reply-To: <20240605-s4-pwm-v7-0-e822b271d7b0@amlogic.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717555496; l=2138;
 i=kelvin.zhang@amlogic.com; s=20240329; h=from:subject:message-id;
 bh=PY1LLIlUoEaOvFEAiK0IUMl1TtUUL9kMLCoeJzffQ8s=;
 b=O3AHvuK3WmFNKLuTbYCYnQMWZjsI0xJhfK2Quo47JUGzgeNTjg8IqB5it1K0WOKPzh02VbzRs
 hyqZvrUF/TKCkHYHVAOnh1FYFmY/jadIYbIsTEeNXUFvQV8HZfz/wUi
X-Developer-Key: i=kelvin.zhang@amlogic.com; a=ed25519;
 pk=pgnle7HTNvnNTcOoGejvtTC7BJT30HUNXfMHRRXSylI=
X-Endpoint-Received: by B4 Relay for kelvin.zhang@amlogic.com/20240329 with auth_id=148
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Junyi Zhao <junyi.zhao@amlogic.com>

Add support for Amlogic S4 PWM.

Signed-off-by: Junyi Zhao <junyi.zhao@amlogic.com>
Signed-off-by: Kelvin Zhang <kelvin.zhang@amlogic.com>
---
 drivers/pwm/pwm-meson.c | 36 ++++++++++++++++++++++++++++++++++++
 1 file changed, 36 insertions(+)

diff --git a/drivers/pwm/pwm-meson.c b/drivers/pwm/pwm-meson.c
index b2f97dfb01bb..4f01847525b2 100644
--- a/drivers/pwm/pwm-meson.c
+++ b/drivers/pwm/pwm-meson.c
@@ -460,6 +460,34 @@ static int meson_pwm_init_channels_meson8b_v2(struct pwm_chip *chip)
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
+		if (IS_ERR(meson->channels[i].clk)) {
+			ret = PTR_ERR(meson->channels[i].clk);
+			dev_err_probe(dev, ret, "Failed to get clk\n");
+			return ret;
+		}
+		devm_add_action_or_reset(dev, meson_pwm_s4_put_clk,
+					 meson->channels[i].clk);
+	}
+
+	return 0;
+}
+
 static const struct meson_pwm_data pwm_meson8b_data = {
 	.parent_names = { "xtal", NULL, "fclk_div4", "fclk_div3" },
 	.channels_init = meson_pwm_init_channels_meson8b_legacy,
@@ -498,6 +526,10 @@ static const struct meson_pwm_data pwm_meson8_v2_data = {
 	.channels_init = meson_pwm_init_channels_meson8b_v2,
 };
 
+static const struct meson_pwm_data pwm_s4_data = {
+	.channels_init = meson_pwm_init_channels_s4,
+};
+
 static const struct of_device_id meson_pwm_matches[] = {
 	{
 		.compatible = "amlogic,meson8-pwm-v2",
@@ -536,6 +568,10 @@ static const struct of_device_id meson_pwm_matches[] = {
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

