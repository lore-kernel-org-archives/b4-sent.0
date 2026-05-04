From: Amit Sunil Dhamne <amitsd@google.com>
Date: Mon, 04 May 2026 22:49:54 +0000
Subject: [PATCH] mfd: max77759: style improvements
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260504-fix-mfd-max77759-driver-v1-1-4d4a31a1d214@google.com>
X-B4-Tracking: v=1; b=H4sIAJEi+WkC/x2MSQqAMAwAvyI5G4hFrfoV8VBN1BxcSEEE8e8Wj
 wMz80AUU4nQZQ+YXBr12BMUeQbTGvZFUDkxOHI1VVTirDduM+MWbu991SKbXmJYjBw8kXNTw5D
 q0ySp/7kf3vcDeoHatmkAAAA=
X-Change-ID: 20260504-fix-mfd-max77759-driver-1bda70022c8d
To: =?utf-8?q?Andr=C3=A9_Draszik?= <andre.draszik@linaro.org>, 
 Lee Jones <lee@kernel.org>
Cc: linux-kernel@vger.kernel.org, 
 Badhri Jagan Sridharan <badhri@google.com>, 
 Amit Sunil Dhamne <amitsd@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777935008; l=5271;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=aPyuzQ0035OvtZDjAvztZ+5vXLvUda5StuV95eB4tvM=;
 b=Pts9NkVWU4D2nTVOtS86s5Y8naHRYYW0Gc3yBlJOWUKvTZjMRUEeYTmI+n72RacqhTflU5dYA
 3DP375xiXGXCEQYsRkzFdc9dXpeKFuxvNsGOV+MeZYGS8AD4rR5OOqx
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Improve code style. This includes the following:
- Formatting the max77759_chgr_irqs entries to fit in a single line
  instead of breaking them into multiple lines to improve readability.

- Refactoring comments such that they're full sentences and have
  punctuation marks for a couple of macro definitions to adhere to the
  documentation style.

- Explicitly initializing `MAX77759_CHGR_MODE_OFF`.

Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
---
Context: https://lore.kernel.org/all/20260424082639.GI170138@google.com/
---
 drivers/mfd/max77759.c       | 48 +++++++++++++++-----------------------------
 include/linux/mfd/max77759.h |  6 +++---
 2 files changed, 19 insertions(+), 35 deletions(-)

diff --git a/drivers/mfd/max77759.c b/drivers/mfd/max77759.c
index 9fa6027a92c4..b50433e7b3d3 100644
--- a/drivers/mfd/max77759.c
+++ b/drivers/mfd/max77759.c
@@ -286,38 +286,22 @@ static const struct regmap_irq max77759_topsys_irqs[] = {
 };
 
 static const struct regmap_irq max77759_chgr_irqs[] = {
-	REGMAP_IRQ_REG(MAX77759_CHGR_INT1_AICL, 0,
-		       MAX77759_CHGR_REG_CHG_INT_AICL),
-	REGMAP_IRQ_REG(MAX77759_CHGR_INT1_CHGIN, 0,
-		       MAX77759_CHGR_REG_CHG_INT_CHGIN),
-	REGMAP_IRQ_REG(MAX77759_CHGR_INT1_WCIN, 0,
-		       MAX77759_CHGR_REG_CHG_INT_WCIN),
-	REGMAP_IRQ_REG(MAX77759_CHGR_INT1_CHG, 0,
-		       MAX77759_CHGR_REG_CHG_INT_CHG),
-	REGMAP_IRQ_REG(MAX77759_CHGR_INT1_BAT, 0,
-		       MAX77759_CHGR_REG_CHG_INT_BAT),
-	REGMAP_IRQ_REG(MAX77759_CHGR_INT1_INLIM, 0,
-		       MAX77759_CHGR_REG_CHG_INT_INLIM),
-	REGMAP_IRQ_REG(MAX77759_CHGR_INT1_THM2, 0,
-		       MAX77759_CHGR_REG_CHG_INT_THM2),
-	REGMAP_IRQ_REG(MAX77759_CHGR_INT1_BYP, 0,
-		       MAX77759_CHGR_REG_CHG_INT_BYP),
-	REGMAP_IRQ_REG(MAX77759_CHGR_INT2_INSEL, 1,
-		       MAX77759_CHGR_REG_CHG_INT2_INSEL),
-	REGMAP_IRQ_REG(MAX77759_CHGR_INT2_SYS_UVLO1, 1,
-		       MAX77759_CHGR_REG_CHG_INT2_SYS_UVLO1),
-	REGMAP_IRQ_REG(MAX77759_CHGR_INT2_SYS_UVLO2, 1,
-		       MAX77759_CHGR_REG_CHG_INT2_SYS_UVLO2),
-	REGMAP_IRQ_REG(MAX77759_CHGR_INT2_BAT_OILO, 1,
-		       MAX77759_CHGR_REG_CHG_INT2_BAT_OILO),
-	REGMAP_IRQ_REG(MAX77759_CHGR_INT2_CHG_STA_CC, 1,
-		       MAX77759_CHGR_REG_CHG_INT2_CHG_STA_CC),
-	REGMAP_IRQ_REG(MAX77759_CHGR_INT2_CHG_STA_CV, 1,
-		       MAX77759_CHGR_REG_CHG_INT2_CHG_STA_CV),
-	REGMAP_IRQ_REG(MAX77759_CHGR_INT2_CHG_STA_TO, 1,
-		       MAX77759_CHGR_REG_CHG_INT2_CHG_STA_TO),
-	REGMAP_IRQ_REG(MAX77759_CHGR_INT2_CHG_STA_DONE, 1,
-		       MAX77759_CHGR_REG_CHG_INT2_CHG_STA_DONE),
+	REGMAP_IRQ_REG(MAX77759_CHGR_INT1_AICL, 0, MAX77759_CHGR_REG_CHG_INT_AICL),
+	REGMAP_IRQ_REG(MAX77759_CHGR_INT1_CHGIN, 0, MAX77759_CHGR_REG_CHG_INT_CHGIN),
+	REGMAP_IRQ_REG(MAX77759_CHGR_INT1_WCIN, 0, MAX77759_CHGR_REG_CHG_INT_WCIN),
+	REGMAP_IRQ_REG(MAX77759_CHGR_INT1_CHG, 0, MAX77759_CHGR_REG_CHG_INT_CHG),
+	REGMAP_IRQ_REG(MAX77759_CHGR_INT1_BAT, 0, MAX77759_CHGR_REG_CHG_INT_BAT),
+	REGMAP_IRQ_REG(MAX77759_CHGR_INT1_INLIM, 0, MAX77759_CHGR_REG_CHG_INT_INLIM),
+	REGMAP_IRQ_REG(MAX77759_CHGR_INT1_THM2, 0, MAX77759_CHGR_REG_CHG_INT_THM2),
+	REGMAP_IRQ_REG(MAX77759_CHGR_INT1_BYP, 0, MAX77759_CHGR_REG_CHG_INT_BYP),
+	REGMAP_IRQ_REG(MAX77759_CHGR_INT2_INSEL, 1, MAX77759_CHGR_REG_CHG_INT2_INSEL),
+	REGMAP_IRQ_REG(MAX77759_CHGR_INT2_SYS_UVLO1, 1, MAX77759_CHGR_REG_CHG_INT2_SYS_UVLO1),
+	REGMAP_IRQ_REG(MAX77759_CHGR_INT2_SYS_UVLO2, 1, MAX77759_CHGR_REG_CHG_INT2_SYS_UVLO2),
+	REGMAP_IRQ_REG(MAX77759_CHGR_INT2_BAT_OILO, 1, MAX77759_CHGR_REG_CHG_INT2_BAT_OILO),
+	REGMAP_IRQ_REG(MAX77759_CHGR_INT2_CHG_STA_CC, 1, MAX77759_CHGR_REG_CHG_INT2_CHG_STA_CC),
+	REGMAP_IRQ_REG(MAX77759_CHGR_INT2_CHG_STA_CV, 1, MAX77759_CHGR_REG_CHG_INT2_CHG_STA_CV),
+	REGMAP_IRQ_REG(MAX77759_CHGR_INT2_CHG_STA_TO, 1, MAX77759_CHGR_REG_CHG_INT2_CHG_STA_TO),
+	REGMAP_IRQ_REG(MAX77759_CHGR_INT2_CHG_STA_DONE, 1, MAX77759_CHGR_REG_CHG_INT2_CHG_STA_DONE),
 };
 
 static const struct regmap_irq_chip max77759_pmic_irq_chip = {
diff --git a/include/linux/mfd/max77759.h b/include/linux/mfd/max77759.h
index ec19be952877..7c0b13219d51 100644
--- a/include/linux/mfd/max77759.h
+++ b/include/linux/mfd/max77759.h
@@ -106,9 +106,9 @@
 #define MAX77759_CHGR_REG_CHG_CNFG_10                  0xc3
 #define MAX77759_CHGR_REG_CHG_CNFG_11                  0xc4
 #define MAX77759_CHGR_REG_CHG_CNFG_12                  0xc5
-/* Wireless Charging input channel select */
+/* Setting this enables the Wireless Charging input channel. */
 #define   MAX77759_CHGR_REG_CHG_CNFG_12_WCINSEL        BIT(6)
-/* CHGIN/USB input channel select */
+/* Setting this enables the CHGIN/USB input channel. */
 #define   MAX77759_CHGR_REG_CHG_CNFG_12_CHGINSEL       BIT(5)
 #define MAX77759_CHGR_REG_CHG_CNFG_13                  0xc6
 #define MAX77759_CHGR_REG_CHG_CNFG_14                  0xc7
@@ -204,7 +204,7 @@ enum max77759_chgr_chg_dtls_states {
 };
 
 enum max77759_chgr_mode {
-	MAX77759_CHGR_MODE_OFF,
+	MAX77759_CHGR_MODE_OFF = 0x0,
 	MAX77759_CHGR_MODE_CHG_BUCK_ON = 0x5,
 	MAX77759_CHGR_MODE_OTG_BOOST_ON = 0xA,
 };

---
base-commit: 57b8e2d666a31fa201432d58f5fe3469a0dd83ba
change-id: 20260504-fix-mfd-max77759-driver-1bda70022c8d

Best regards,
-- 
Amit Sunil Dhamne <amitsd@google.com>

