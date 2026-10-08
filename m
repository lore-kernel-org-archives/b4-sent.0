From: Igor Velkov <iav@iav.lv>
Date: Thu, 08 Oct 2026 04:27:29 +0300
Subject: [PATCH] power: supply: gpio-charger: Report not charging without
 input power
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261008-gpio-charger-offline-v1-1-78740b558402@iav.lv>
X-B4-Tracking: v=1; b=H4sIAIDxxmoC/x2MQQqAIBAAvxJ7bkElI/pKdIjatYVQWSGC8O9Jx
 2GYeaGQChWYuxeUbimSYgPbd7CfWwyEcjQGZ9xojZkwZEnYlAZSTMyXRMKdvfWD26whhpZmJZb
 n3y5rrR9T+dHQZgAAAA==
To: Sebastian Reichel <sre@kernel.org>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1681; i=iav@iav.lv;
 h=from:subject:message-id; bh=HbkCeasNYbp+Pz+uItepD7+gWxGT00Yxhsd3N6nIWzo=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFnHPjYxH7OtKfXcqbNAuL14ZvG6sl0XL3ya+YX92msbt
 SfiU46IdJSyMIhxMciKKbJMOKRxK2PJ1b/+HuYPYOawMoEMYeDiFICJRGgyMnycq2sZXzX9/4m1
 2g4xcRMlYwyTlawU1DdW+C/74HmCVZyR4e9ZhXbZ69N39D7btbFZNGVj7rxTxy2yt2cq+s75K8l
 3nx8A
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The status property follows only the charge-status GPIO. Without input
power a charger such as the BQ24133 releases its open-drain STAT pin,
and depending on the board the GPIO then reads as charging.

On Kobol Helios64 the board runs from its battery after a mains loss,
and the charger reports online 0 with status "Charging".

Report "Not charging" whenever the online GPIO is present and inactive.

Tested on Helios64: on battery the status now reads "Not charging".

Assisted-by: LLM
Signed-off-by: Igor Velkov <iav@iav.lv>
---
 drivers/power/supply/gpio-charger.c | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/drivers/power/supply/gpio-charger.c b/drivers/power/supply/gpio-charger.c
index 2504190eba82..2fdff5f8b5ad 100644
--- a/drivers/power/supply/gpio-charger.c
+++ b/drivers/power/supply/gpio-charger.c
@@ -101,7 +101,10 @@ static int gpio_charger_get_property(struct power_supply *psy,
 		val->intval = gpiod_get_value_cansleep(gpio_charger->gpiod);
 		break;
 	case POWER_SUPPLY_PROP_STATUS:
-		if (gpiod_get_value_cansleep(gpio_charger->charge_status))
+		/* Without input power the charger cannot charge, whatever its status pin says */
+		if (gpio_charger->gpiod && !gpiod_get_value_cansleep(gpio_charger->gpiod))
+			val->intval = POWER_SUPPLY_STATUS_NOT_CHARGING;
+		else if (gpiod_get_value_cansleep(gpio_charger->charge_status))
 			val->intval = POWER_SUPPLY_STATUS_CHARGING;
 		else
 			val->intval = POWER_SUPPLY_STATUS_NOT_CHARGING;

---
base-commit: a90ee4305c4a5df72c11b31dacfdc76e00fcf78a
change-id: 20261008-gpio-charger-offline-cf51542a10ef

Best regards,
-- 
Igor Velkov <iav@iav.lv>

