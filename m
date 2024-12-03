From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Tue, 03 Dec 2024 09:04:36 +0100
Subject: [PATCH] power: supply: max1720x: add charge full property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241203-max1720x-charge-full-prop-v1-1-b02776b43f17@liebherr.com>
X-B4-Tracking: v=1; b=H4sIAJO7TmcC/yWOQQ6DIBBFr0JYFwOIAVz1Ho2LEcaWRNSCNibGu
 5fWzSRvfubNP2jGFDDTlhw04SfkME8FxI1Q94LpiSz4wlRyqUQZLMIutOQ7K3Eq8bCNI1vSvDB
 sBLcWRC2coOV+STiE/e9+dBcnfG/lxXotaQ8ZmZtjDGtLFK+NckZxBGGV8to1UFuJxuoGPTcG3
 cD7Wv/UGSfPruZsnVviQ4RqQJ9guz8jhLEqVtqd5xcJ9lfv4AAAAA==
X-Change-ID: 20241202-max1720x-charge-full-prop-e51099a131c1
To: Sebastian Reichel <sre@kernel.org>, 
 Thomas Antoine <t.antoine@uclouvain.be>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dimitri Fedrau <dimitri.fedrau@liebherr.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733213084; l=2122;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=RkkK3ElM3J0WHWfD2Z/jYMO3Bs/oJAsns7dWA0uLXxM=;
 b=R2TCaDXPn2Qv3gJ51ltJ4JB+0wLrzZC7+cyy7KSIYDcb9xrdrCO8K9MA66Ba+k70QHKg3legf
 otvN7CcWBaMB9TBziV61YoV7k08ePRK/0G46kND7GVL/GcTbXfBfpjj
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Charge full holds the calculated full capacity of the cell based on all
inputs from the ModelGauge m5 algorithm including empty compensation. A
new full-capacity value is calculated continuously as application
conditions change.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 drivers/power/supply/max1720x_battery.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/power/supply/max1720x_battery.c b/drivers/power/supply/max1720x_battery.c
index 33105419e2427bb37963bda9948b647c239f8faa..9c7e14d2c7b87b8194511f36ade16e774281333e 100644
--- a/drivers/power/supply/max1720x_battery.c
+++ b/drivers/power/supply/max1720x_battery.c
@@ -29,6 +29,7 @@
 #define MAX172XX_TEMP			0x08	/* Temperature */
 #define MAX172XX_CURRENT		0x0A	/* Actual current */
 #define MAX172XX_AVG_CURRENT		0x0B	/* Average current */
+#define MAX172XX_FULL_CAP		0x10	/* Calculated full capacity */
 #define MAX172XX_TTE			0x11	/* Time to empty */
 #define MAX172XX_AVG_TA			0x16	/* Average temperature */
 #define MAX172XX_CYCLES			0x17
@@ -250,6 +251,7 @@ static const enum power_supply_property max1720x_battery_props[] = {
 	POWER_SUPPLY_PROP_TEMP,
 	POWER_SUPPLY_PROP_CURRENT_NOW,
 	POWER_SUPPLY_PROP_CURRENT_AVG,
+	POWER_SUPPLY_PROP_CHARGE_FULL,
 	POWER_SUPPLY_PROP_MODEL_NAME,
 	POWER_SUPPLY_PROP_MANUFACTURER,
 };
@@ -362,6 +364,10 @@ static int max1720x_battery_get_property(struct power_supply *psy,
 		ret = regmap_read(info->regmap, MAX172XX_AVG_CURRENT, &reg_val);
 		val->intval = max172xx_current_to_voltage(reg_val) / info->rsense;
 		break;
+	case POWER_SUPPLY_PROP_CHARGE_FULL:
+		ret = regmap_read(info->regmap, MAX172XX_FULL_CAP, &reg_val);
+		val->intval = max172xx_capacity_to_ps(reg_val);
+		break;
 	case POWER_SUPPLY_PROP_MODEL_NAME:
 		ret = regmap_read(info->regmap, MAX172XX_DEV_NAME, &reg_val);
 		reg_val = FIELD_GET(MAX172XX_DEV_NAME_TYPE_MASK, reg_val);

---
base-commit: 40384c840ea1944d7c5a392e8975ed088ecf0b37
change-id: 20241202-max1720x-charge-full-prop-e51099a131c1

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

