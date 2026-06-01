From: Petr Hodina <petr.hodina@protonmail.com>
Date: Mon, 01 Jun 2026 13:52:35 +0200
Subject: [PATCH 1/2] gpio: qcom_pmic_gpio: implement standard pinconf
 parameters
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260601-qcom-gpio-v1-1-e24bcdb35da0@protonmail.com>
References: <20260601-qcom-gpio-v1-0-e24bcdb35da0@protonmail.com>
In-Reply-To: <20260601-qcom-gpio-v1-0-e24bcdb35da0@protonmail.com>
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.denx.de
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Rui Miguel Silva <rui.silva@linaro.org>, phone-devel@vger.kernel.org, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780314756; l=2828;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=hinwgaYrU1XCJQzW4fBDv8E8o7r9z/FdGjiF7nGEfRw=;
 b=/PPQpDX1dQHdFwFVgV8gwnvrNF6UJxzJFFjUNEdpcAtfq5x4n5waDC40fqXeXAZFt6pAuDupg
 LIB7f7ElNb+ALtU1+1l0VT5UJ7EUvEQ5k/14Zx4XZi4nu/heoMt6ztZ
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Set bias-pull-up/down/disable, input-enable and the vendor
qcom,drive-strength properties in pinconf_params.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 drivers/gpio/qcom_pmic_gpio.c | 35 ++++++++++++++++++++++++++++++++---
 1 file changed, 32 insertions(+), 3 deletions(-)

diff --git a/drivers/gpio/qcom_pmic_gpio.c b/drivers/gpio/qcom_pmic_gpio.c
index 4458c55cd3d..71cc76fef2f 100644
--- a/drivers/gpio/qcom_pmic_gpio.c
+++ b/drivers/gpio/qcom_pmic_gpio.c
@@ -56,6 +56,8 @@
 #define REG_DIG_VIN_VIN0       0
 
 #define REG_DIG_PULL_CTL       0x42
+#define REG_DIG_PULL_UP_30K    0x0
+#define REG_DIG_PULL_DN        0x4
 #define REG_DIG_PULL_NO_PU     0x5
 
 #define REG_LV_MV_OUTPUT_CTL	0x44
@@ -365,6 +367,11 @@ U_BOOT_DRIVER(qcom_pmic_gpio) = {
 static const struct pinconf_param qcom_pmic_pinctrl_conf_params[] = {
 	{ "output-high", PIN_CONFIG_OUTPUT_ENABLE, 1 },
 	{ "output-low", PIN_CONFIG_OUTPUT, 0 },
+	{ "input-enable", PIN_CONFIG_INPUT_ENABLE, 1 },
+	{ "bias-disable", PIN_CONFIG_BIAS_DISABLE, 0 },
+	{ "bias-pull-up", PIN_CONFIG_BIAS_PULL_UP, 0 },
+	{ "bias-pull-down", PIN_CONFIG_BIAS_PULL_DOWN, 0 },
+	{ "qcom,drive-strength", PIN_CONFIG_DRIVE_STRENGTH, 0 },
 };
 
 static int qcom_pmic_pinctrl_get_pins_count(struct udevice *dev)
@@ -387,9 +394,31 @@ static const char *qcom_pmic_pinctrl_get_pin_name(struct udevice *dev, unsigned
 static int qcom_pmic_pinctrl_pinconf_set(struct udevice *dev, unsigned int selector,
 					 unsigned int param, unsigned int arg)
 {
-	/* We only support configuring the pin as an output, either low or high */
-	return _qcom_gpio_set_direction(dev, selector, false,
-					param == PIN_CONFIG_OUTPUT_ENABLE);
+	struct qcom_pmic_gpio_data *plat = dev_get_plat(dev);
+	u32 gpio_base = plat->pid + REG_OFFSET(selector);
+
+	switch (param) {
+	case PIN_CONFIG_OUTPUT_ENABLE:
+	case PIN_CONFIG_OUTPUT:
+		return qcom_gpio_set_direction(dev, selector, false,
+					       param == PIN_CONFIG_OUTPUT_ENABLE);
+	case PIN_CONFIG_INPUT_ENABLE:
+		return qcom_gpio_set_direction(dev, selector, true, 0);
+	case PIN_CONFIG_BIAS_PULL_UP:
+		return pmic_reg_write(plat->pmic, gpio_base + REG_DIG_PULL_CTL,
+				      REG_DIG_PULL_UP_30K);
+	case PIN_CONFIG_BIAS_PULL_DOWN:
+		return pmic_reg_write(plat->pmic, gpio_base + REG_DIG_PULL_CTL,
+				      REG_DIG_PULL_DN);
+	case PIN_CONFIG_BIAS_DISABLE:
+		return pmic_reg_write(plat->pmic, gpio_base + REG_DIG_PULL_CTL,
+				      REG_DIG_PULL_NO_PU);
+	case PIN_CONFIG_DRIVE_STRENGTH:
+		return pmic_reg_write(plat->pmic, gpio_base + REG_DIG_OUT_CTL,
+				      REG_DIG_OUT_CTL_CMOS | (arg & 0x3));
+	default:
+		return -EOPNOTSUPP;
+	}
 }
 
 static const char *qcom_pmic_pinctrl_get_function_name(struct udevice *dev, unsigned int selector)

-- 
2.53.0

