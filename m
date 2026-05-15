From: Amit Sunil Dhamne <amitsd@google.com>
Date: Fri, 15 May 2026 05:48:41 +0000
Subject: [PATCH 3/3] power: supply: max17042: add handler for energy_now
 property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260515-batt-status-v1-3-fed6b7d8cea7@google.com>
References: <20260515-batt-status-v1-0-fed6b7d8cea7@google.com>
In-Reply-To: <20260515-batt-status-v1-0-fed6b7d8cea7@google.com>
To: Sebastian Reichel <sre@kernel.org>, 
 Badhri Jagan Sridharan <badhri@google.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Hans de Goede <hansg@kernel.org>, Krzysztof Kozlowski <krzk@kernel.org>, 
 Marek Szyprowski <m.szyprowski@samsung.com>, 
 Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>, 
 Purism Kernel Team <kernel@puri.sm>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Draszik?= <andre.draszik@linaro.org>, 
 Tudor Ambarus <tudor.ambarus@linaro.org>, 
 Peter Griffin <peter.griffin@linaro.org>, RD Babiera <rdbabiera@google.com>, 
 Kyle Tso <kyletso@google.com>, Amit Sunil Dhamne <amitsd@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778824256; l=3946;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=rZ4iAk16d2xmYX+iRg9d3aLsjlCGLdVUfG6+D9Nq6hY=;
 b=mP5j13ZK2htM+zjnJ8ThHRPxXR/MqZXaXDsFwNM3MXuPFJnxgRn6pYa1b9P0EF0FZFZ5S6+mj
 ATw1BO4vO+EDPgUyeEPZXs0dSzHVvnkrmOZf/gtkg+HPU+v6ig8qNHs
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add handler to report power_supply_prop_energy_now so that users can get
current SoC in uWH. Additionally, add helper functions to get avg_vcell
and repcap values in uv and uah units respectively to avoid code
duplication.

Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
---
 drivers/power/supply/max17042_battery.c | 60 ++++++++++++++++++++++++++-------
 1 file changed, 47 insertions(+), 13 deletions(-)

diff --git a/drivers/power/supply/max17042_battery.c b/drivers/power/supply/max17042_battery.c
index 167fb3fb3732..e16eb6985b70 100644
--- a/drivers/power/supply/max17042_battery.c
+++ b/drivers/power/supply/max17042_battery.c
@@ -81,6 +81,7 @@ static enum power_supply_property max17042_battery_props[] = {
 	POWER_SUPPLY_PROP_CHARGE_NOW,
 	POWER_SUPPLY_PROP_CHARGE_COUNTER,
 	POWER_SUPPLY_PROP_CHARGE_TERM_CURRENT,
+	POWER_SUPPLY_PROP_ENERGY_NOW,
 	POWER_SUPPLY_PROP_TEMP,
 	POWER_SUPPLY_PROP_TEMP_ALERT_MIN,
 	POWER_SUPPLY_PROP_TEMP_ALERT_MAX,
@@ -95,6 +96,36 @@ static enum power_supply_property max17042_battery_props[] = {
 	POWER_SUPPLY_PROP_CURRENT_AVG,
 };
 
+static int max17042_get_repcap_uah(struct max17042_chip *chip, u64 *rep_cap)
+{
+	u32 data;
+	int ret;
+
+	ret = regmap_read(chip->regmap, MAX17042_RepCap, &data);
+	if (ret < 0)
+		return ret;
+
+	*rep_cap = data * 5000000ll;
+	*rep_cap *= chip->task_period;
+	do_div(*rep_cap, MAX17042_DEFAULT_TASK_PERIOD);
+	do_div(*rep_cap, chip->pdata->r_sns);
+
+	return 0;
+}
+
+static int max17042_get_avgvcell_uv(struct max17042_chip *chip, u32 *vcell)
+{
+	int ret;
+
+	ret = regmap_read(chip->regmap, MAX17042_AvgVCELL, vcell);
+	if (ret < 0)
+		return ret;
+
+	*vcell = (*vcell * 625) / 8;
+
+	return 0;
+}
+
 static int max17042_get_temperature(struct max17042_chip *chip, int *temp)
 {
 	int ret;
@@ -180,14 +211,12 @@ static int max17042_get_battery_health(struct max17042_chip *chip, int *health)
 	int temp, vavg, vbatt, ret;
 	u32 val;
 
-	ret = regmap_read(chip->regmap, MAX17042_AvgVCELL, &val);
+	ret = max17042_get_avgvcell_uv(chip, &val);
 	if (ret < 0)
 		goto health_error;
 
-	/* bits [0-3] unused */
-	vavg = val * 625 / 8;
 	/* Convert to millivolts */
-	vavg /= 1000;
+	vavg = val / 1000;
 
 	ret = regmap_read(chip->regmap, MAX17042_VCELL, &val);
 	if (ret < 0)
@@ -304,11 +333,10 @@ static int max17042_get_property(struct power_supply *psy,
 		val->intval = data * 625 / 8;
 		break;
 	case POWER_SUPPLY_PROP_VOLTAGE_AVG:
-		ret = regmap_read(map, MAX17042_AvgVCELL, &data);
+		ret = max17042_get_avgvcell_uv(chip, &data);
 		if (ret < 0)
 			return ret;
-
-		val->intval = data * 625 / 8;
+		val->intval = data;
 		break;
 	case POWER_SUPPLY_PROP_VOLTAGE_OCV:
 		ret = regmap_read(map, MAX17042_OCVInternal, &data);
@@ -350,14 +378,9 @@ static int max17042_get_property(struct power_supply *psy,
 		val->intval = data64;
 		break;
 	case POWER_SUPPLY_PROP_CHARGE_NOW:
-		ret = regmap_read(map, MAX17042_RepCap, &data);
+		ret = max17042_get_repcap_uah(chip, &data64);
 		if (ret < 0)
 			return ret;
-
-		data64 = data * 5000000ll;
-		data64 *= chip->task_period;
-		do_div(data64, MAX17042_DEFAULT_TASK_PERIOD);
-		do_div(data64, chip->pdata->r_sns);
 		val->intval = data64;
 		break;
 	case POWER_SUPPLY_PROP_CHARGE_COUNTER:
@@ -370,6 +393,17 @@ static int max17042_get_property(struct power_supply *psy,
 		data64 = div_s64(data64, MAX17042_DEFAULT_TASK_PERIOD);
 		val->intval = div_s64(data64, chip->pdata->r_sns);
 		break;
+	case POWER_SUPPLY_PROP_ENERGY_NOW:
+		ret = max17042_get_repcap_uah(chip, &data64);
+		if (ret < 0)
+			return ret;
+
+		ret = max17042_get_avgvcell_uv(chip, &data);
+		if (ret < 0)
+			return ret;
+
+		val->intval = data64 * data / 1000000;
+		break;
 	case POWER_SUPPLY_PROP_TEMP:
 		ret = max17042_get_temperature(chip, &val->intval);
 		if (ret < 0)

-- 
2.54.0.563.g4f69b47b94-goog

