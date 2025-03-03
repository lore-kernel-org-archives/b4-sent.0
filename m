From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Mon, 03 Mar 2025 15:53:20 +0800
Subject: [PATCH] pinctrl: meson: fix pin input property for a4
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250303-fix-a4-pinctl-v1-1-6579888b4272@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAO9fxWcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDYwNj3bTMCt1EE92CzLzkkhxdkyQjQ9M04zRLEwsLJaCegqJUoAKwedG
 xtbUAl0BJTl8AAAA=
To: Linus Walleij <linus.walleij@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-gpio@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740988400; l=1905;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=8KAlxGwDBrTjecjGM2UBSMoeZW/HVDXc337RfYbdpLs=;
 b=lSCzkCPO4V0PMaYz3RHyLMVvoDIJFa+ttEleYaHx84tqa5hPPEuIuhBgqPVQxEuCkdXP9TslC
 bIGD/OzMizrAHgH73PTjU+OBpqW5wF23nSa2kAG3qyHAmbGpcSMfPcW
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The register of pin input attribute means the opposite.
value of reigster meaning is 1 for input and 0 for output.
So fix it.

Fixes: 6e9be3abb78c ("pinctrl: Add driver support for Amlogic SoCs")
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 drivers/pinctrl/meson/pinctrl-amlogic-a4.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/drivers/pinctrl/meson/pinctrl-amlogic-a4.c b/drivers/pinctrl/meson/pinctrl-amlogic-a4.c
index a5218e8f1e03..35d5540b8eaa 100644
--- a/drivers/pinctrl/meson/pinctrl-amlogic-a4.c
+++ b/drivers/pinctrl/meson/pinctrl-amlogic-a4.c
@@ -775,7 +775,7 @@ static int aml_gpio_get_direction(struct gpio_chip *chip, unsigned int gpio)
 	if (ret)
 		return ret;
 
-	return BIT(bit) & val ? GPIO_LINE_DIRECTION_OUT : GPIO_LINE_DIRECTION_IN;
+	return BIT(bit) & val ? GPIO_LINE_DIRECTION_IN : GPIO_LINE_DIRECTION_OUT;
 }
 
 static int aml_gpio_direction_input(struct gpio_chip *chip, unsigned int gpio)
@@ -785,7 +785,7 @@ static int aml_gpio_direction_input(struct gpio_chip *chip, unsigned int gpio)
 
 	aml_gpio_calc_reg_and_bit(bank, AML_REG_DIR, gpio, &reg, &bit);
 
-	return regmap_update_bits(bank->reg_gpio, reg, BIT(bit), 0);
+	return regmap_update_bits(bank->reg_gpio, reg, BIT(bit), BIT(bit));
 }
 
 static int aml_gpio_direction_output(struct gpio_chip *chip, unsigned int gpio,
@@ -796,7 +796,7 @@ static int aml_gpio_direction_output(struct gpio_chip *chip, unsigned int gpio,
 	int ret;
 
 	aml_gpio_calc_reg_and_bit(bank, AML_REG_DIR, gpio, &reg, &bit);
-	ret = regmap_update_bits(bank->reg_gpio, reg, BIT(bit), BIT(bit));
+	ret = regmap_update_bits(bank->reg_gpio, reg, BIT(bit), 0);
 	if (ret < 0)
 		return ret;
 

---
base-commit: 73e4ffb27bb8a093d557bb2dac1a271474cca99c
change-id: 20250303-fix-a4-pinctl-4b215f3f9488

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

