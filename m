From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Date: Wed, 05 Aug 2026 10:06:02 +0200
Subject: [PATCH v9 1/6] mfd: khadas-mcu: Add per-variant configuration
 infrastructure and VIM4 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260805-add-mcu-fan-khadas-vim4-v9-1-75df78710b9e@aliel.fr>
References: <20260805-add-mcu-fan-khadas-vim4-v9-0-75df78710b9e@aliel.fr>
In-Reply-To: <20260805-add-mcu-fan-khadas-vim4-v9-0-75df78710b9e@aliel.fr>
To: Neil Armstrong <neil.armstrong@linaro.org>, Lee Jones <lee@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andi Shyti <andi.shyti@kernel.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Beniamino Galvani <b.galvani@gmail.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Liam Girdwood <lgirdwood@gmail.com>, 
 Mark Brown <broonie@kernel.org>
Cc: linux-amlogic@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-i2c@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-pm@vger.kernel.org, 
 mfd@lists.linux.dev, Ronald Claveau <linux-kernel-dev@aliel.fr>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1883;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=l0O0cD0fiAJBO81t4csvMi2nHXVHt2flC0X0yXFYJns=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQ1bR+7TlSTH9bA6391scvfY9sPj+ZvY9kdq+Uhds605FR
 CfOXfm5o5SFQYyLQVZMkaV/ruWJd5ePnvm6Rz0FZg4rE8gQBi5OAZiIz0lGhhlSAYsrLkzS3X6y
 OsCsfU22wO947eligi/VU77/mLKBVYeRYerdpsq1a5xWL/CKXOvgJbxZL96NI6lpkXlcYe2aS4/
 juAA=
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some values change per variant, add the structure to manage it.

Add an enum khadas_mcu_type used as value to match.

Also introduce khadas_mcu_fan_pdata to pass fan register address, a
table named levels to get fan-supported levels on the MCU, and the number
of levels to the fan sub-driver, removing the hardcoded constants.

Reviewed-by: Neil Armstrong <neil.armstrong@linaro.org>
Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
 include/linux/mfd/khadas-mcu.h | 24 ++++++++++++++++++++++++
 1 file changed, 24 insertions(+)

diff --git a/include/linux/mfd/khadas-mcu.h b/include/linux/mfd/khadas-mcu.h
index a99ba2ed0e4e0..e4044c251b97e 100644
--- a/include/linux/mfd/khadas-mcu.h
+++ b/include/linux/mfd/khadas-mcu.h
@@ -70,6 +70,13 @@
 #define KHADAS_MCU_WOL_INIT_START_REG		0x87 /* WO */
 #define KHADAS_MCU_CMD_FAN_STATUS_CTRL_REG	0x88 /* WO */
 
+/* VIM4 specific registers */
+#define KHADAS_MCU_VIM4_REST_CONF_REG		0x2c /* WO - reset EEPROM */
+#define KHADAS_MCU_VIM4_LED_ON_RAM_REG		0x89 /* WO - LED volatile */
+#define KHADAS_MCU_VIM4_FAN_CTRL_REG		0x8a /* WO */
+#define KHADAS_MCU_VIM4_WDT_EN_REG		0x8b /* WO */
+#define KHADAS_MCU_VIM4_SYS_RST_REG		0x91 /* WO */
+
 enum {
 	KHADAS_BOARD_VIM1 = 0x1,
 	KHADAS_BOARD_VIM2,
@@ -88,4 +95,21 @@ struct khadas_mcu {
 	struct regmap *regmap;
 };
 
+/**
+ * struct khadas_mcu_fan_pdata - fan sub-driver configuration
+ * @fan_reg: register address to write the fan level
+ * @levels: table mapping logical cooling-device states to raw fan levels
+ * @nlevels: number of entries in @levels
+ */
+struct khadas_mcu_fan_pdata {
+	unsigned int fan_reg;
+	const unsigned int *levels;
+	unsigned int nlevels;
+};
+
+enum khadas_mcu_type {
+	KHADAS_MCU_GENERIC, /* VIM1/2/3, Edge, Edge-V */
+	KHADAS_MCU_VIM4,
+};
+
 #endif /* MFD_KHADAS_MCU_H */

-- 
2.49.0

