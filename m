From: Igor Velkov <iav@iav.lv>
Date: Sun, 18 Oct 2026 03:57:53 +0000
Subject: [PATCH v2] power: supply: gpio-charger: Report discharging without
 input power
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261018-gpio-charger-offline-v2-1-482795f9e27c@iav.lv>
X-B4-Tracking: v=1; b=H4sIAMBD1GoC/4WNQQ7CIBBFr9LM2jFAwBJX3sN0gXWgkzTQgCGah
 ruLvYDL93/++zsUykwFrsMOmSoXTrGDOg0wLy4GQn52BiXURQphMWycsFc5UMbk/cqRcPZGGq2
 cFOShT7dMnt+H9j51Xri8Uv4cL1X+0j/CKlHiaEctHsZYLdSNXT2vFabW2hew+H1ItQAAAA==
To: Sebastian Reichel <sre@kernel.org>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1919; i=iav@iav.lv;
 h=from:subject:message-id; bh=0JI2YVyIf0wi7lB7au0hHSHWHOT1281rV/OhX2yynHo=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFlXnA8eqtu6MN44cF1weuyG0myFRFnhzbMvu3rFTBD83
 1pb/Fupo5SFQYyLQVZMkWXCIY1bGUuu/vX3MH8AM4eVCWQIAxenAExEZjfD/0rGvRtE1j399Dg2
 sH13ki/7TL6de9kXxRdo+hhFiZzVO8DIsPpx84ayxTcj8hr9gg/feRDOt96ntP398Yl8n5PPTGK
 sZQcA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The status property follows only the charge-status GPIO. Without input
power a charger such as the BQ24133 releases its open-drain STAT pin,
and depending on the board the GPIO then reads as charging.

On Kobol Helios64 the board runs from its battery after a mains loss,
and the charger reports online 0 with status "Charging".

Report "Discharging" whenever the online GPIO is present and inactive.

Fixes: df68c44c720a ("power: supply: gpio-charger: Add support for charger status.")
Assisted-by: LLM
Signed-off-by: Igor Velkov <iav@iav.lv>
---
Changes in v2:
- Report "Discharging" instead of "Not charging" without input power (Sebastian)
- Add Fixes tag (Sebastian)
- Link to v1: https://lore.kernel.org/r/20261008-gpio-charger-offline-v1-1-78740b558402@iav.lv
---
 drivers/power/supply/gpio-charger.c | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/drivers/power/supply/gpio-charger.c b/drivers/power/supply/gpio-charger.c
index 2504190eba82..1dad49acc424 100644
--- a/drivers/power/supply/gpio-charger.c
+++ b/drivers/power/supply/gpio-charger.c
@@ -101,7 +101,10 @@ static int gpio_charger_get_property(struct power_supply *psy,
 		val->intval = gpiod_get_value_cansleep(gpio_charger->gpiod);
 		break;
 	case POWER_SUPPLY_PROP_STATUS:
-		if (gpiod_get_value_cansleep(gpio_charger->charge_status))
+		/* Without input power the battery discharges, whatever the status pin says */
+		if (gpio_charger->gpiod && !gpiod_get_value_cansleep(gpio_charger->gpiod))
+			val->intval = POWER_SUPPLY_STATUS_DISCHARGING;
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

