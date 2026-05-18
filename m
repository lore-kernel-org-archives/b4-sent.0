From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Mon, 18 May 2026 08:26:20 +0000
Subject: [PATCH] pinctrl: meson: amlogic-a4: fix gpio output glitch
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260518-fix-set-value-glitch-v1-1-d350732dc934@amlogic.com>
X-B4-Tracking: v=1; b=H4sIACvNCmoC/x2MQQqAIBAAvxJ7biG1pPpKdBDdaiEstCIQ/550H
 JiZBJECU4SxShDo4ciHLyDqCuxm/ErIrjDIRuqmEz0u/GKkCx+z34TrzpfdcGmVdUprK4cOSno
 GKt6/neacP6WFXLJmAAAA
X-Change-ID: 20260518-fix-set-value-glitch-f43cd366c295
To: Linus Walleij <linusw@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-gpio@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779092781; l=2464;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=HQut5DoHHLHMAAEMHfB1ndnbzPoAfeLWYAz1btYy/v4=;
 b=iSGDTNSp99CxN/n337nlmpKipA9olU98cB3IT8K22NnaIVpfwhI4C4MCEB0dIVlmR3IlTXd9Y
 FhrDNoLUCdxC0Nekxu1rUksY4RIWqW9zWwDlGWEmyCvbAmOWryO6CqJ
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the system transitions from bootloader to kernel, the GPIO is
expected to keep driving high.

However, the Linux kernel first configures the pin direction and then
sets the output value. This may cause a brief low-level glitch on the
GPIO line, which can be problematic for regulator control.

By configuring the output value before switching the pin direction to
output, the glitch can be avoided.

This commit fixes the issue by swapping the configuration order.

Fixes: 6e9be3abb78c ("pinctrl: Add driver support for Amlogic SoCs")
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
fix one issue when set gpio line high.
---
 drivers/pinctrl/meson/pinctrl-amlogic-a4.c | 15 +++++++--------
 1 file changed, 7 insertions(+), 8 deletions(-)

diff --git a/drivers/pinctrl/meson/pinctrl-amlogic-a4.c b/drivers/pinctrl/meson/pinctrl-amlogic-a4.c
index 35d27626a336..1bd58fbbd26a 100644
--- a/drivers/pinctrl/meson/pinctrl-amlogic-a4.c
+++ b/drivers/pinctrl/meson/pinctrl-amlogic-a4.c
@@ -548,11 +548,11 @@ static int aml_pinconf_set_output_drive(struct aml_pinctrl *info,
 {
 	int ret;
 
-	ret = aml_pinconf_set_output(info, pin, true);
+	ret = aml_pinconf_set_drive(info, pin, high);
 	if (ret)
 		return ret;
 
-	return aml_pinconf_set_drive(info, pin, high);
+	return aml_pinconf_set_output(info, pin, true);
 }
 
 static int aml_pinconf_set(struct pinctrl_dev *pcdev, unsigned int pin,
@@ -921,15 +921,14 @@ static int aml_gpio_direction_output(struct gpio_chip *chip, unsigned int gpio,
 	unsigned int bit, reg;
 	int ret;
 
-	aml_gpio_calc_reg_and_bit(bank, AML_REG_DIR, gpio, &reg, &bit);
-	ret = regmap_update_bits(bank->reg_gpio, reg, BIT(bit), 0);
+	aml_gpio_calc_reg_and_bit(bank, AML_REG_OUT, gpio, &reg, &bit);
+	ret = regmap_update_bits(bank->reg_gpio, reg, BIT(bit),
+				 value ? BIT(bit) : 0);
 	if (ret < 0)
 		return ret;
 
-	aml_gpio_calc_reg_and_bit(bank, AML_REG_OUT, gpio, &reg, &bit);
-
-	return regmap_update_bits(bank->reg_gpio, reg, BIT(bit),
-				  value ? BIT(bit) : 0);
+	aml_gpio_calc_reg_and_bit(bank, AML_REG_DIR, gpio, &reg, &bit);
+	return regmap_update_bits(bank->reg_gpio, reg, BIT(bit), 0);
 }
 
 static int aml_gpio_set(struct gpio_chip *chip, unsigned int gpio, int value)

---
base-commit: 73d4991a6949eedb51e442d4e81415017d85975b
change-id: 20260518-fix-set-value-glitch-f43cd366c295

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

