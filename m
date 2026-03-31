From: Amit Sunil Dhamne <amitsd@google.com>
Date: Tue, 31 Mar 2026 23:22:18 +0000
Subject: [PATCH v10 3/6] mfd: max77759: add register bitmasks and modify
 irq configs for charger
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260331-max77759-charger-v10-3-76f59233c369@google.com>
References: <20260331-max77759-charger-v10-0-76f59233c369@google.com>
In-Reply-To: <20260331-max77759-charger-v10-0-76f59233c369@google.com>
To: =?utf-8?q?Andr=C3=A9_Draszik?= <andre.draszik@linaro.org>, 
 Lee Jones <lee@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jagan Sridharan <badhri@google.com>, Mark Brown <broonie@kernel.org>, 
 Matti Vaittinen <mazziesaccount@gmail.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Sebastian Reichel <sre@kernel.org>, Amit Sunil Dhamne <amitsd@google.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Tudor Ambarus <tudor.ambarus@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-usb@vger.kernel.org, linux-pm@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 RD Babiera <rdbabiera@google.com>, Kyle Tso <kyletso@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774999353; l=15748;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=dU/CtUSTH5F/z6+eeAxQad9XYQ8BL+9Uw1n47EgnNos=;
 b=JY0YEmwPX0ppfpvAd0gHosE+8/D7zYH7j78xAzVu3vmpNYKibd2v5zHwlSeE6lqUFqZvdDuQd
 HSRsiOec958A/JyvXqZmBXndXG4BUX5NF11YKxWfOARlqnK04vhaj5L
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add register bitmasks for charger function.
In addition split the charger IRQs further such that each bit represents
an IRQ downstream of charger regmap irq chip. In addition populate the
ack_base to offload irq ack to the regmap irq chip framework.

Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
Reviewed-by: André Draszik <andre.draszik@linaro.org>
---
 drivers/mfd/max77759.c       |  95 ++++++++++++++++++++++---
 include/linux/mfd/max77759.h | 166 +++++++++++++++++++++++++++++++++++--------
 2 files changed, 222 insertions(+), 39 deletions(-)

diff --git a/drivers/mfd/max77759.c b/drivers/mfd/max77759.c
index a7efe233ec8c..9fa6027a92c4 100644
--- a/drivers/mfd/max77759.c
+++ b/drivers/mfd/max77759.c
@@ -201,8 +201,24 @@ static const struct regmap_config max77759_regmap_config_charger = {
  *         - SYSUVLO_INT
  *         - FSHIP_NOT_RD
  *     - CHGR_INT: charger
- *       - CHG_INT
- *       - CHG_INT2
+ *       - INT1
+ *         - AICL
+ *         - CHGIN
+ *         - WCIN
+ *         - CHG
+ *         - BAT
+ *         - INLIM
+ *         - THM2
+ *         - BYP
+ *       - INT2
+ *         - INSEL
+ *         - SYS_UVLO1
+ *         - SYS_UVLO2
+ *         - BAT_OILO
+ *         - CHG_STA_CC
+ *         - CHG_STA_CV
+ *         - CHG_STA_TO
+ *         - CHG_STA_DONE
  */
 enum {
 	MAX77759_INT_MAXQ,
@@ -228,8 +244,22 @@ enum {
 };
 
 enum {
-	MAX77759_CHARGER_INT_1,
-	MAX77759_CHARGER_INT_2,
+	MAX77759_CHGR_INT1_AICL,
+	MAX77759_CHGR_INT1_CHGIN,
+	MAX77759_CHGR_INT1_WCIN,
+	MAX77759_CHGR_INT1_CHG,
+	MAX77759_CHGR_INT1_BAT,
+	MAX77759_CHGR_INT1_INLIM,
+	MAX77759_CHGR_INT1_THM2,
+	MAX77759_CHGR_INT1_BYP,
+	MAX77759_CHGR_INT2_INSEL,
+	MAX77759_CHGR_INT2_SYS_UVLO1,
+	MAX77759_CHGR_INT2_SYS_UVLO2,
+	MAX77759_CHGR_INT2_BAT_OILO,
+	MAX77759_CHGR_INT2_CHG_STA_CC,
+	MAX77759_CHGR_INT2_CHG_STA_CV,
+	MAX77759_CHGR_INT2_CHG_STA_TO,
+	MAX77759_CHGR_INT2_CHG_STA_DONE,
 };
 
 static const struct regmap_irq max77759_pmic_irqs[] = {
@@ -256,8 +286,38 @@ static const struct regmap_irq max77759_topsys_irqs[] = {
 };
 
 static const struct regmap_irq max77759_chgr_irqs[] = {
-	REGMAP_IRQ_REG(MAX77759_CHARGER_INT_1, 0, GENMASK(7, 0)),
-	REGMAP_IRQ_REG(MAX77759_CHARGER_INT_2, 1, GENMASK(7, 0)),
+	REGMAP_IRQ_REG(MAX77759_CHGR_INT1_AICL, 0,
+		       MAX77759_CHGR_REG_CHG_INT_AICL),
+	REGMAP_IRQ_REG(MAX77759_CHGR_INT1_CHGIN, 0,
+		       MAX77759_CHGR_REG_CHG_INT_CHGIN),
+	REGMAP_IRQ_REG(MAX77759_CHGR_INT1_WCIN, 0,
+		       MAX77759_CHGR_REG_CHG_INT_WCIN),
+	REGMAP_IRQ_REG(MAX77759_CHGR_INT1_CHG, 0,
+		       MAX77759_CHGR_REG_CHG_INT_CHG),
+	REGMAP_IRQ_REG(MAX77759_CHGR_INT1_BAT, 0,
+		       MAX77759_CHGR_REG_CHG_INT_BAT),
+	REGMAP_IRQ_REG(MAX77759_CHGR_INT1_INLIM, 0,
+		       MAX77759_CHGR_REG_CHG_INT_INLIM),
+	REGMAP_IRQ_REG(MAX77759_CHGR_INT1_THM2, 0,
+		       MAX77759_CHGR_REG_CHG_INT_THM2),
+	REGMAP_IRQ_REG(MAX77759_CHGR_INT1_BYP, 0,
+		       MAX77759_CHGR_REG_CHG_INT_BYP),
+	REGMAP_IRQ_REG(MAX77759_CHGR_INT2_INSEL, 1,
+		       MAX77759_CHGR_REG_CHG_INT2_INSEL),
+	REGMAP_IRQ_REG(MAX77759_CHGR_INT2_SYS_UVLO1, 1,
+		       MAX77759_CHGR_REG_CHG_INT2_SYS_UVLO1),
+	REGMAP_IRQ_REG(MAX77759_CHGR_INT2_SYS_UVLO2, 1,
+		       MAX77759_CHGR_REG_CHG_INT2_SYS_UVLO2),
+	REGMAP_IRQ_REG(MAX77759_CHGR_INT2_BAT_OILO, 1,
+		       MAX77759_CHGR_REG_CHG_INT2_BAT_OILO),
+	REGMAP_IRQ_REG(MAX77759_CHGR_INT2_CHG_STA_CC, 1,
+		       MAX77759_CHGR_REG_CHG_INT2_CHG_STA_CC),
+	REGMAP_IRQ_REG(MAX77759_CHGR_INT2_CHG_STA_CV, 1,
+		       MAX77759_CHGR_REG_CHG_INT2_CHG_STA_CV),
+	REGMAP_IRQ_REG(MAX77759_CHGR_INT2_CHG_STA_TO, 1,
+		       MAX77759_CHGR_REG_CHG_INT2_CHG_STA_TO),
+	REGMAP_IRQ_REG(MAX77759_CHGR_INT2_CHG_STA_DONE, 1,
+		       MAX77759_CHGR_REG_CHG_INT2_CHG_STA_DONE),
 };
 
 static const struct regmap_irq_chip max77759_pmic_irq_chip = {
@@ -297,11 +357,12 @@ static const struct regmap_irq_chip max77759_topsys_irq_chip = {
 	.num_irqs = ARRAY_SIZE(max77759_topsys_irqs),
 };
 
-static const struct regmap_irq_chip max77759_chrg_irq_chip = {
+static const struct regmap_irq_chip max77759_chgr_irq_chip = {
 	.name = "max77759-chgr",
 	.domain_suffix = "CHGR",
 	.status_base = MAX77759_CHGR_REG_CHG_INT,
 	.mask_base = MAX77759_CHGR_REG_CHG_INT_MASK,
+	.ack_base = MAX77759_CHGR_REG_CHG_INT,
 	.num_regs = 2,
 	.irqs = max77759_chgr_irqs,
 	.num_irqs = ARRAY_SIZE(max77759_chgr_irqs),
@@ -325,8 +386,22 @@ static const struct resource max77759_gpio_resources[] = {
 };
 
 static const struct resource max77759_charger_resources[] = {
-	DEFINE_RES_IRQ_NAMED(MAX77759_CHARGER_INT_1, "INT1"),
-	DEFINE_RES_IRQ_NAMED(MAX77759_CHARGER_INT_2, "INT2"),
+	DEFINE_RES_IRQ_NAMED(MAX77759_CHGR_INT1_AICL,         "AICL"),
+	DEFINE_RES_IRQ_NAMED(MAX77759_CHGR_INT1_CHGIN,        "CHGIN"),
+	DEFINE_RES_IRQ_NAMED(MAX77759_CHGR_INT1_WCIN,         "WCIN"),
+	DEFINE_RES_IRQ_NAMED(MAX77759_CHGR_INT1_CHG,          "CHG"),
+	DEFINE_RES_IRQ_NAMED(MAX77759_CHGR_INT1_BAT,          "BAT"),
+	DEFINE_RES_IRQ_NAMED(MAX77759_CHGR_INT1_INLIM,        "INLIM"),
+	DEFINE_RES_IRQ_NAMED(MAX77759_CHGR_INT1_THM2,         "THM2"),
+	DEFINE_RES_IRQ_NAMED(MAX77759_CHGR_INT1_BYP,          "BYP"),
+	DEFINE_RES_IRQ_NAMED(MAX77759_CHGR_INT2_INSEL,        "INSEL"),
+	DEFINE_RES_IRQ_NAMED(MAX77759_CHGR_INT2_SYS_UVLO1,    "SYS_UVLO1"),
+	DEFINE_RES_IRQ_NAMED(MAX77759_CHGR_INT2_SYS_UVLO2,    "SYS_UVLO2"),
+	DEFINE_RES_IRQ_NAMED(MAX77759_CHGR_INT2_BAT_OILO,     "BAT_OILO"),
+	DEFINE_RES_IRQ_NAMED(MAX77759_CHGR_INT2_CHG_STA_CC,   "CHG_STA_CC"),
+	DEFINE_RES_IRQ_NAMED(MAX77759_CHGR_INT2_CHG_STA_CV,   "CHG_STA_CV"),
+	DEFINE_RES_IRQ_NAMED(MAX77759_CHGR_INT2_CHG_STA_TO,   "CHG_STA_TO"),
+	DEFINE_RES_IRQ_NAMED(MAX77759_CHGR_INT2_CHG_STA_DONE, "CHG_STA_DONE"),
 };
 
 static const struct mfd_cell max77759_cells[] = {
@@ -567,7 +642,7 @@ static int max77759_add_chained_charger(struct i2c_client *client,
 					    max77759->regmap_charger,
 					    MAX77759_INT_CHGR,
 					    parent,
-					    &max77759_chrg_irq_chip,
+					    &max77759_chgr_irq_chip,
 					    &irq_chip_data);
 	if (ret)
 		return ret;
diff --git a/include/linux/mfd/max77759.h b/include/linux/mfd/max77759.h
index c6face34e385..ec19be952877 100644
--- a/include/linux/mfd/max77759.h
+++ b/include/linux/mfd/max77759.h
@@ -59,35 +59,65 @@
 #define MAX77759_MAXQ_REG_AP_DATAIN0            0xb1
 #define MAX77759_MAXQ_REG_UIC_SWRST             0xe0
 
-#define MAX77759_CHGR_REG_CHG_INT               0xb0
-#define MAX77759_CHGR_REG_CHG_INT2              0xb1
-#define MAX77759_CHGR_REG_CHG_INT_MASK          0xb2
-#define MAX77759_CHGR_REG_CHG_INT2_MASK         0xb3
-#define MAX77759_CHGR_REG_CHG_INT_OK            0xb4
-#define MAX77759_CHGR_REG_CHG_DETAILS_00        0xb5
-#define MAX77759_CHGR_REG_CHG_DETAILS_01        0xb6
-#define MAX77759_CHGR_REG_CHG_DETAILS_02        0xb7
-#define MAX77759_CHGR_REG_CHG_DETAILS_03        0xb8
-#define MAX77759_CHGR_REG_CHG_CNFG_00           0xb9
-#define MAX77759_CHGR_REG_CHG_CNFG_01           0xba
-#define MAX77759_CHGR_REG_CHG_CNFG_02           0xbb
-#define MAX77759_CHGR_REG_CHG_CNFG_03           0xbc
-#define MAX77759_CHGR_REG_CHG_CNFG_04           0xbd
-#define MAX77759_CHGR_REG_CHG_CNFG_05           0xbe
-#define MAX77759_CHGR_REG_CHG_CNFG_06           0xbf
-#define MAX77759_CHGR_REG_CHG_CNFG_07           0xc0
-#define MAX77759_CHGR_REG_CHG_CNFG_08           0xc1
-#define MAX77759_CHGR_REG_CHG_CNFG_09           0xc2
-#define MAX77759_CHGR_REG_CHG_CNFG_10           0xc3
-#define MAX77759_CHGR_REG_CHG_CNFG_11           0xc4
-#define MAX77759_CHGR_REG_CHG_CNFG_12           0xc5
-#define MAX77759_CHGR_REG_CHG_CNFG_13           0xc6
-#define MAX77759_CHGR_REG_CHG_CNFG_14           0xc7
-#define MAX77759_CHGR_REG_CHG_CNFG_15           0xc8
-#define MAX77759_CHGR_REG_CHG_CNFG_16           0xc9
-#define MAX77759_CHGR_REG_CHG_CNFG_17           0xca
-#define MAX77759_CHGR_REG_CHG_CNFG_18           0xcb
-#define MAX77759_CHGR_REG_CHG_CNFG_19           0xcc
+#define MAX77759_CHGR_REG_CHG_INT                      0xb0
+#define   MAX77759_CHGR_REG_CHG_INT_AICL               BIT(7)
+#define   MAX77759_CHGR_REG_CHG_INT_CHGIN              BIT(6)
+#define   MAX77759_CHGR_REG_CHG_INT_WCIN               BIT(5)
+#define   MAX77759_CHGR_REG_CHG_INT_CHG                BIT(4)
+#define   MAX77759_CHGR_REG_CHG_INT_BAT                BIT(3)
+#define   MAX77759_CHGR_REG_CHG_INT_INLIM              BIT(2)
+#define   MAX77759_CHGR_REG_CHG_INT_THM2               BIT(1)
+#define   MAX77759_CHGR_REG_CHG_INT_BYP                BIT(0)
+#define MAX77759_CHGR_REG_CHG_INT2                     0xb1
+#define   MAX77759_CHGR_REG_CHG_INT2_INSEL             BIT(7)
+#define   MAX77759_CHGR_REG_CHG_INT2_SYS_UVLO1         BIT(6)
+#define   MAX77759_CHGR_REG_CHG_INT2_SYS_UVLO2         BIT(5)
+#define   MAX77759_CHGR_REG_CHG_INT2_BAT_OILO          BIT(4)
+#define   MAX77759_CHGR_REG_CHG_INT2_CHG_STA_CC        BIT(3)
+#define   MAX77759_CHGR_REG_CHG_INT2_CHG_STA_CV        BIT(2)
+#define   MAX77759_CHGR_REG_CHG_INT2_CHG_STA_TO        BIT(1)
+#define   MAX77759_CHGR_REG_CHG_INT2_CHG_STA_DONE      BIT(0)
+#define MAX77759_CHGR_REG_CHG_INT_MASK                 0xb2
+#define MAX77759_CHGR_REG_CHG_INT2_MASK                0xb3
+#define MAX77759_CHGR_REG_CHG_INT_OK                   0xb4
+#define MAX77759_CHGR_REG_CHG_DETAILS_00               0xb5
+#define   MAX77759_CHGR_REG_CHG_DETAILS_00_CHGIN_DTLS  GENMASK(6, 5)
+#define MAX77759_CHGR_REG_CHG_DETAILS_01               0xb6
+#define   MAX77759_CHGR_REG_CHG_DETAILS_01_BAT_DTLS    GENMASK(6, 4)
+#define   MAX77759_CHGR_REG_CHG_DETAILS_01_CHG_DTLS    GENMASK(3, 0)
+#define MAX77759_CHGR_REG_CHG_DETAILS_02               0xb7
+#define   MAX77759_CHGR_REG_CHG_DETAILS_02_CHGIN_STS   BIT(5)
+#define MAX77759_CHGR_REG_CHG_DETAILS_03               0xb8
+#define MAX77759_CHGR_REG_CHG_CNFG_00                  0xb9
+#define   MAX77759_CHGR_REG_CHG_CNFG_00_MODE           GENMASK(3, 0)
+#define MAX77759_CHGR_REG_CHG_CNFG_01                  0xba
+#define MAX77759_CHGR_REG_CHG_CNFG_02                  0xbb
+#define   MAX77759_CHGR_REG_CHG_CNFG_02_CHGCC          GENMASK(5, 0)
+#define MAX77759_CHGR_REG_CHG_CNFG_03                  0xbc
+#define MAX77759_CHGR_REG_CHG_CNFG_04                  0xbd
+#define   MAX77759_CHGR_REG_CHG_CNFG_04_CHG_CV_PRM     GENMASK(5, 0)
+#define MAX77759_CHGR_REG_CHG_CNFG_05                  0xbe
+#define MAX77759_CHGR_REG_CHG_CNFG_06                  0xbf
+#define   MAX77759_CHGR_REG_CHG_CNFG_06_CHGPROT        GENMASK(3, 2)
+#define MAX77759_CHGR_REG_CHG_CNFG_07                  0xc0
+#define MAX77759_CHGR_REG_CHG_CNFG_08                  0xc1
+#define MAX77759_CHGR_REG_CHG_CNFG_09                  0xc2
+#define   MAX77759_CHGR_REG_CHG_CNFG_09_CHGIN_ILIM     GENMASK(6, 0)
+#define MAX77759_CHGR_REG_CHG_CNFG_10                  0xc3
+#define MAX77759_CHGR_REG_CHG_CNFG_11                  0xc4
+#define MAX77759_CHGR_REG_CHG_CNFG_12                  0xc5
+/* Wireless Charging input channel select */
+#define   MAX77759_CHGR_REG_CHG_CNFG_12_WCINSEL        BIT(6)
+/* CHGIN/USB input channel select */
+#define   MAX77759_CHGR_REG_CHG_CNFG_12_CHGINSEL       BIT(5)
+#define MAX77759_CHGR_REG_CHG_CNFG_13                  0xc6
+#define MAX77759_CHGR_REG_CHG_CNFG_14                  0xc7
+#define MAX77759_CHGR_REG_CHG_CNFG_15                  0xc8
+#define MAX77759_CHGR_REG_CHG_CNFG_16                  0xc9
+#define MAX77759_CHGR_REG_CHG_CNFG_17                  0xca
+#define MAX77759_CHGR_REG_CHG_CNFG_18                  0xcb
+#define   MAX77759_CHGR_REG_CHG_CNFG_18_WDTEN          BIT(0)
+#define MAX77759_CHGR_REG_CHG_CNFG_19                  0xcc
 
 /* MaxQ opcodes for max77759_maxq_command() */
 #define MAX77759_MAXQ_OPCODE_MAXLENGTH (MAX77759_MAXQ_REG_AP_DATAOUT32 - \
@@ -101,6 +131,84 @@
 #define MAX77759_MAXQ_OPCODE_USER_SPACE_READ     0x81
 #define MAX77759_MAXQ_OPCODE_USER_SPACE_WRITE    0x82
 
+/**
+ * enum max77759_chgr_chgin_dtls_status - Charger Input Status
+ * @MAX77759_CHGR_CHGIN_DTLS_VBUS_UNDERVOLTAGE:
+ *     Charger input voltage (Vchgin) < Under Voltage Threshold (Vuvlo)
+ * @MAX77759_CHGR_CHGIN_DTLS_VBUS_MARGINAL_VOLTAGE:
+ *     Vchgin > Vuvlo and Vchgin < (Battery Voltage (Vbatt) + system voltage (Vsys))
+ * @MAX77759_CHGR_CHGIN_DTLS_VBUS_OVERVOLTAGE:
+ *     Vchgin > Over Voltage threshold (Vovlo)
+ * @MAX77759_CHGR_CHGIN_DTLS_VBUS_VALID:
+ *     Vchgin > Vuvlo, Vchgin < Vovlo and Vchgin > (Vsys + Vbatt)
+ */
+enum max77759_chgr_chgin_dtls_status {
+	MAX77759_CHGR_CHGIN_DTLS_VBUS_UNDERVOLTAGE,
+	MAX77759_CHGR_CHGIN_DTLS_VBUS_MARGINAL_VOLTAGE,
+	MAX77759_CHGR_CHGIN_DTLS_VBUS_OVERVOLTAGE,
+	MAX77759_CHGR_CHGIN_DTLS_VBUS_VALID,
+};
+
+/**
+ * enum max77759_chgr_bat_dtls_states - Battery Details
+ * @MAX77759_CHGR_BAT_DTLS_NO_BATT_CHG_SUSP:	No battery and the charger suspended
+ * @MAX77759_CHGR_BAT_DTLS_DEAD_BATTERY:	Vbatt < Vtrickle
+ * @MAX77759_CHGR_BAT_DTLS_BAT_CHG_TIMER_FAULT:	Charging suspended due to timer fault
+ * @MAX77759_CHGR_BAT_DTLS_BAT_OKAY:		Battery okay and Vbatt > Min Sys Voltage (Vsysmin)
+ * @MAX77759_CHGR_BAT_DTLS_BAT_UNDERVOLTAGE:	Battery is okay. Vtrickle < Vbatt < Vsysmin
+ * @MAX77759_CHGR_BAT_DTLS_BAT_OVERVOLTAGE:	Battery voltage > Overvoltage threshold
+ * @MAX77759_CHGR_BAT_DTLS_BAT_OVERCURRENT:	Battery current exceeds overcurrent threshold
+ * @MAX77759_CHGR_BAT_DTLS_BAT_ONLY_MODE:	Battery only mode and battery level not available
+ */
+enum max77759_chgr_bat_dtls_states {
+	MAX77759_CHGR_BAT_DTLS_NO_BATT_CHG_SUSP,
+	MAX77759_CHGR_BAT_DTLS_DEAD_BATTERY,
+	MAX77759_CHGR_BAT_DTLS_BAT_CHG_TIMER_FAULT,
+	MAX77759_CHGR_BAT_DTLS_BAT_OKAY,
+	MAX77759_CHGR_BAT_DTLS_BAT_UNDERVOLTAGE,
+	MAX77759_CHGR_BAT_DTLS_BAT_OVERVOLTAGE,
+	MAX77759_CHGR_BAT_DTLS_BAT_OVERCURRENT,
+	MAX77759_CHGR_BAT_DTLS_BAT_ONLY_MODE,
+};
+
+/**
+ * enum max77759_chgr_chg_dtls_states - Charger Details
+ * @MAX77759_CHGR_CHG_DTLS_PREQUAL:		Charger in prequalification mode
+ * @MAX77759_CHGR_CHG_DTLS_CC:			Charger in fast charge const curr mode
+ * @MAX77759_CHGR_CHG_DTLS_CV:			Charger in fast charge const voltage mode
+ * @MAX77759_CHGR_CHG_DTLS_TO:			Charger is in top off mode
+ * @MAX77759_CHGR_CHG_DTLS_DONE:		Charger is done
+ * @MAX77759_CHGR_CHG_DTLS_RSVD_1:		Reserved
+ * @MAX77759_CHGR_CHG_DTLS_TIMER_FAULT:		Charger is in timer fault mode
+ * @MAX77759_CHGR_CHG_DTLS_SUSP_BATT_THM:	Charger is suspended as battery removal detected
+ * @MAX77759_CHGR_CHG_DTLS_OFF:			Charger is off. Input invalid or charger disabled
+ * @MAX77759_CHGR_CHG_DTLS_RSVD_2:		Reserved
+ * @MAX77759_CHGR_CHG_DTLS_RSVD_3:		Reserved
+ * @MAX77759_CHGR_CHG_DTLS_OFF_WDOG_TIMER:	Charger is off as watchdog timer expired
+ * @MAX77759_CHGR_CHG_DTLS_SUSP_JEITA:		Charger is in JEITA control mode
+ */
+enum max77759_chgr_chg_dtls_states {
+	MAX77759_CHGR_CHG_DTLS_PREQUAL,
+	MAX77759_CHGR_CHG_DTLS_CC,
+	MAX77759_CHGR_CHG_DTLS_CV,
+	MAX77759_CHGR_CHG_DTLS_TO,
+	MAX77759_CHGR_CHG_DTLS_DONE,
+	MAX77759_CHGR_CHG_DTLS_RSVD_1,
+	MAX77759_CHGR_CHG_DTLS_TIMER_FAULT,
+	MAX77759_CHGR_CHG_DTLS_SUSP_BATT_THM,
+	MAX77759_CHGR_CHG_DTLS_OFF,
+	MAX77759_CHGR_CHG_DTLS_RSVD_2,
+	MAX77759_CHGR_CHG_DTLS_RSVD_3,
+	MAX77759_CHGR_CHG_DTLS_OFF_WDOG_TIMER,
+	MAX77759_CHGR_CHG_DTLS_SUSP_JEITA,
+};
+
+enum max77759_chgr_mode {
+	MAX77759_CHGR_MODE_OFF,
+	MAX77759_CHGR_MODE_CHG_BUCK_ON = 0x5,
+	MAX77759_CHGR_MODE_OTG_BOOST_ON = 0xA,
+};
+
 /**
  * struct max77759 - core max77759 internal data structure
  *

-- 
2.53.0.1118.gaef5881109-goog

