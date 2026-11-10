From: Ben Grisdale <bengris32@protonmail.ch>
Date: Tue, 10 Nov 2026 17:41:11 +0000
Subject: [PATCH] mfd: mt6397: Use PMIC specific interrupt count for domain
 creation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-mt6397-irq-num-fix-v1-1-81d17454194e@protonmail.ch>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMyw5AMBCF4VeRWZtEK+ryKmKBDkaiaBGJeHfF8
 jvJ+S9wZJkcFMEFlg52PBsPEQbQDrXpCVl7g4ykEkJEOG0qzlNku6LZJ+z4RKkpzXSdqDwh8Mf
 Fkp+/aFn9dnszUru9JbjvB67Zdkx2AAAA
X-Change-ID: 20261110-mt6397-irq-num-fix-2de78da5695e
To: Lee Jones <lee@kernel.org>, Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Yassine Oudjana <y.oudjana@protonmail.com>
Cc: mfd@lists.linux.dev, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Ben Grisdale <bengris32@protonmail.ch>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794332472; l=3349;
 i=bengris32@protonmail.ch; s=20261018; h=from:subject:message-id;
 bh=bRyoobaVcT/dxO3uclPekPpnlK3tbVg5L4EF4M1asiQ=;
 b=shkTxPb6Mh+r0/BI9HyAkBzh6F25GjW78PFF3C9N6LhR9jcgsCq4mgYvUOTw3+RcFWSfbNwR1
 w7LycfMCPjJD7pXpw/dfoGWMCkxuUppMZaBagYIJkUS7ocpyfmQEFFw
X-Developer-Key: i=bengris32@protonmail.ch; a=ed25519;
 pk=4ewFRC2yNph/tXokHVzIDlgOA9Hxecf1AlBuD4eOnaU=
X-Endpoint-Received: by B4 Relay for bengris32@protonmail.ch/20261018 with auth_id=1233
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mt6397_irq_init() currently creates its IRQ domain with a fixed number
of interrupts (MT6397_IRQ_NR). However, not every PMIC supported by this
driver has the same number of interrupts as the MT6397. The MT6328 has
47 interrupts, so its interrupts above MT6397_IRQ_NR (32) are currently
unusable.

Correct this by passing the PMIC's actual interrupt count to
irq_domain_create_linear() based on the chip ID. Define the missing
interrupt count for MT6328, as the other supported PMICs already have
it defined.

Fixes: 6e31bb8d3a63 ("mfd: mt6397: Add initial support for MT6328")
Signed-off-by: Ben Grisdale <bengris32@protonmail.ch>
---
 drivers/mfd/mt6397-irq.c        | 7 ++++++-
 include/linux/mfd/mt6328/core.h | 1 +
 2 files changed, 7 insertions(+), 1 deletion(-)

diff --git a/drivers/mfd/mt6397-irq.c b/drivers/mfd/mt6397-irq.c
index 5d2e5459f744..783be9f5c9c3 100644
--- a/drivers/mfd/mt6397-irq.c
+++ b/drivers/mfd/mt6397-irq.c
@@ -171,6 +171,7 @@ static int mt6397_irq_pm_notifier(struct notifier_block *notifier,
 
 int mt6397_irq_init(struct mt6397_chip *chip)
 {
+	unsigned int irq_num;
 	int ret;
 
 	mutex_init(&chip->irqlock);
@@ -181,6 +182,7 @@ int mt6397_irq_init(struct mt6397_chip *chip)
 		chip->int_con[1] = MT6323_INT_CON1;
 		chip->int_status[0] = MT6323_INT_STATUS0;
 		chip->int_status[1] = MT6323_INT_STATUS1;
+		irq_num = MT6323_IRQ_STATUS_NR;
 		break;
 	case MT6328_CHIP_ID:
 		chip->int_con[0] = MT6328_INT_CON0;
@@ -189,12 +191,14 @@ int mt6397_irq_init(struct mt6397_chip *chip)
 		chip->int_status[0] = MT6328_INT_STATUS0;
 		chip->int_status[1] = MT6328_INT_STATUS1;
 		chip->int_status[2] = MT6328_INT_STATUS2;
+		irq_num = MT6328_IRQ_STATUS_NR;
 		break;
 	case MT6331_CHIP_ID:
 		chip->int_con[0] = MT6331_INT_CON0;
 		chip->int_con[1] = MT6331_INT_CON1;
 		chip->int_status[0] = MT6331_INT_STATUS_CON0;
 		chip->int_status[1] = MT6331_INT_STATUS_CON1;
+		irq_num = MT6331_IRQ_STATUS_NR;
 		break;
 	case MT6391_CHIP_ID:
 	case MT6397_CHIP_ID:
@@ -202,6 +206,7 @@ int mt6397_irq_init(struct mt6397_chip *chip)
 		chip->int_con[1] = MT6397_INT_CON1;
 		chip->int_status[0] = MT6397_INT_STATUS0;
 		chip->int_status[1] = MT6397_INT_STATUS1;
+		irq_num = MT6397_IRQ_NR;
 		break;
 
 	default:
@@ -216,7 +221,7 @@ int mt6397_irq_init(struct mt6397_chip *chip)
 		regmap_write(chip->regmap, chip->int_con[2], 0x0);
 
 	chip->pm_nb.notifier_call = mt6397_irq_pm_notifier;
-	chip->irq_domain = irq_domain_create_linear(dev_fwnode(chip->dev), MT6397_IRQ_NR,
+	chip->irq_domain = irq_domain_create_linear(dev_fwnode(chip->dev), irq_num,
 						    &mt6397_irq_domain_ops, chip);
 	if (!chip->irq_domain) {
 		dev_err(chip->dev, "could not create irq domain\n");
diff --git a/include/linux/mfd/mt6328/core.h b/include/linux/mfd/mt6328/core.h
index 9a08aed72b9f..18e000cf5d29 100644
--- a/include/linux/mfd/mt6328/core.h
+++ b/include/linux/mfd/mt6328/core.h
@@ -48,6 +48,7 @@ enum mt6328_irq_status_numbers {
 	MT6328_IRQ_STATUS_FG_ZCV,
 	MT6328_IRQ_STATUS_SPKL_D,
 	MT6328_IRQ_STATUS_SPKL_AB,
+	MT6328_IRQ_STATUS_NR,
 };
 
 #endif /* __MFD_MT6323_CORE_H__ */

---
base-commit: 630059a5a632377b9b7b487baccde92b7ae1dd47
change-id: 20261110-mt6397-irq-num-fix-2de78da5695e

Best regards,
--  
Ben Grisdale <bengris32@protonmail.ch>

