From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Date: Thu, 17 Sep 2026 09:59:00 +0200
Subject: [PATCH v12 1/6] mfd: khadas-mcu: Add per-variant configuration
 infrastructure and VIM4 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260917-add-mcu-fan-khadas-vim4-v12-1-497cd543a148@aliel.fr>
References: <20260917-add-mcu-fan-khadas-vim4-v12-0-497cd543a148@aliel.fr>
In-Reply-To: <20260917-add-mcu-fan-khadas-vim4-v12-0-497cd543a148@aliel.fr>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1930;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=BJRhwKhcdjrF5epARgcxNmy3jED4cBzG1XxROeciDJk=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQ9bqeVLWEctSXnAY1q9nWdy0Muhnc9WiVtHLglO2nDH43
 Xhtn+2DjlIWBjEuBlkxRZb+uZYn3l0+eubrHvUUmDmsTCBDGLg4BWAiu3gY/vCdeSbLuyCiZ8Np
 LfHQOWtF/jExpDhNedZ9bLPGoZ0rHFsYGb5OU9ds5dmX4JAsJqm2IlTSlfGXw5wN2mZbOTgqpoW
 u5QcA
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some values change per variant, add the structure to manage it.

Add VIM4 specific registers done for a subsequent patch, which will use a
new compatible especially to get the right regmap config.

Add an enum khadas_mcu_type used as value to match.

Also fix a kernel-doc warning for the khadas_mcu struct.

Reviewed-by: Neil Armstrong <neil.armstrong@linaro.org>
Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
 include/linux/mfd/khadas-mcu.h | 19 ++++++++++++++++++-
 1 file changed, 18 insertions(+), 1 deletion(-)

diff --git a/include/linux/mfd/khadas-mcu.h b/include/linux/mfd/khadas-mcu.h
index a99ba2ed0e4e0..acd3291061b40 100644
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
@@ -80,7 +87,7 @@ enum {
 
 /**
  * struct khadas_mcu - Khadas MCU structure
- * @device:		device reference used for logs
+ * @dev:		device reference used for logs
  * @regmap:		register map
  */
 struct khadas_mcu {
@@ -88,4 +95,14 @@ struct khadas_mcu {
 	struct regmap *regmap;
 };
 
+/**
+ * enum khadas_mcu_type - Khadas MCU hardware variant
+ * @KHADAS_MCU_GENERIC: VIM1, VIM2, VIM3, Edge, Edge-V (shared register map)
+ * @KHADAS_MCU_VIM4: VIM4 (extended register map, distinct fan/LED/WDT regs)
+ */
+enum khadas_mcu_type {
+	KHADAS_MCU_GENERIC = 1,
+	KHADAS_MCU_VIM4,
+};
+
 #endif /* MFD_KHADAS_MCU_H */

-- 
2.49.0

