From: Amit Sunil Dhamne <amitsd@google.com>
Date: Thu, 02 Apr 2026 07:15:29 +0000
Subject: [PATCH] power: supply: max77759_charger: fix voltage scale (mV ->
 uV)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260402-fix-psy-max77759-usb-next-v1-1-427f5af566c3@google.com>
X-B4-Tracking: v=1; b=H4sIAJAXzmkC/x2MQQ5AMBAAvyJ7tkk1KL4iDsViD0q6SEX8XeM4y
 cw8IOSZBJrkAU8XC28uQpYmMCzWzYQ8RgatdKlypXHigLvcuNpgjClqPKVHR+HArLD5VJVWVQN
 B7HdPUf7fbfe+H7R8EV1rAAAA
X-Change-ID: 20260402-fix-psy-max77759-usb-next-15a4f86a08ce
To: Amit Sunil Dhamne <amitsd@google.com>, 
 Sebastian Reichel <sre@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 =?utf-8?q?Andr=C3=A9_Draszik?= <andre.draszik@linaro.org>
Cc: linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 linux-usb@vger.kernel.org, Badhri Jagan Sridharan <badhri@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775114153; l=7748;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=59/AjsdipPHEtmFIyA3h6KhCPPrrp72LTkD5FeZMk/k=;
 b=/cA759Ui37lFsiIJWmlVx2MCaJTghbsbPALCnqg5ZDIL2DNiM8O/pyvhr+gyXCG/Xp4fsMAjZ
 UHXBmKbWx0UDXG4jIzLEBlTLOfiuX4O3QWvUQVTt7ch7Qbe1TZkuYEE
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

CONSTANT_CHARGE_VOLTAGE_MAX property incorrectly uses mV instead of uV.
Add fix to use uV as per the power-supply subsystem convention.

Also, add a note indicating all the properties use non negative values.
A negative value indicates failure with the appropriate error value. In
that case, it should not be taken as a measurement value or status.

Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
---
This patch is a follow-up to the series [1]. [1] has been accepted in
the USB subsystem tree (usb-next). However, since Sebastian has additional
feedback [2], I am sending this patch to address it. Please note that this
patch is based out of usb-next branch on usb tree. This patch should be
applied on top of 70d7dd27f6dc ("power: supply: max77759: add charger driver").

[1] https://lore.kernel.org/all/20260325-max77759-charger-v9-0-4486dd297adc@google.com/
[2] https://lore.kernel.org/all/ac2jYUA2F5oQsA2g@venus/#t
---
Output of power supply selftest:
root@google-gs:/data/power_supply# ./test_power_supply_properties.sh
TAP version 13
1..66
 # Testing device max77759-charger
ok 1 max77759-charger.exists
ok 2 max77759-charger.uevent.NAME
ok 3 max77759-charger.sysfs.type
ok 4 max77759-charger.uevent.TYPE
ok 5 max77759-charger.sysfs.usb_type # SKIP
 # Reported: '1' ()
ok 6 max77759-charger.sysfs.online
 # Reported: '1' ()
ok 7 max77759-charger.sysfs.present
 # Reported: 'Charging'
ok 8 max77759-charger.sysfs.status
ok 9 max77759-charger.sysfs.capacity # SKIP
ok 10 max77759-charger.sysfs.capacity_level # SKIP
ok 11 max77759-charger.sysfs.model_name # SKIP
ok 12 max77759-charger.sysfs.manufacturer # SKIP
ok 13 max77759-charger.sysfs.serial_number # SKIP
ok 14 max77759-charger.sysfs.technology # SKIP
ok 15 max77759-charger.sysfs.cycle_count # SKIP
ok 16 max77759-charger.sysfs.scope # SKIP
 # Reported: '3000000' uA (3000 mA)
ok 17 max77759-charger.sysfs.input_current_limit
ok 18 max77759-charger.sysfs.input_voltage_limit # SKIP
ok 19 max77759-charger.sysfs.voltage_now # SKIP
ok 20 max77759-charger.sysfs.voltage_min # SKIP
ok 21 max77759-charger.sysfs.voltage_max # SKIP
ok 22 max77759-charger.sysfs.voltage_min_design # SKIP
ok 23 max77759-charger.sysfs.voltage_max_design # SKIP
ok 24 max77759-charger.sysfs.current_now # SKIP
ok 25 max77759-charger.sysfs.current_max # SKIP
ok 26 max77759-charger.sysfs.charge_now # SKIP
ok 27 max77759-charger.sysfs.charge_full # SKIP
ok 28 max77759-charger.sysfs.charge_full_design # SKIP
ok 29 max77759-charger.sysfs.power_now # SKIP
ok 30 max77759-charger.sysfs.energy_now # SKIP
ok 31 max77759-charger.sysfs.energy_full # SKIP
ok 32 max77759-charger.sysfs.energy_full_design # SKIP
ok 33 max77759-charger.sysfs.energy_full_design # SKIP
 # Testing device tcpm-source-psy-1-0025
ok 34 tcpm-source-psy-1-0025.exists
ok 35 tcpm-source-psy-1-0025.uevent.NAME
ok 36 tcpm-source-psy-1-0025.sysfs.type
ok 37 tcpm-source-psy-1-0025.uevent.TYPE
 # Reported: 'C [PD] PD_PPS PD_SPR_AVS PD_PPS_SPR_AVS' ()
ok 38 tcpm-source-psy-1-0025.sysfs.usb_type
 # Reported: '1' ()
ok 39 tcpm-source-psy-1-0025.sysfs.online
ok 40 tcpm-source-psy-1-0025.sysfs.present # SKIP
ok 41 tcpm-source-psy-1-0025.sysfs.status # SKIP
ok 42 tcpm-source-psy-1-0025.sysfs.capacity # SKIP
ok 43 tcpm-source-psy-1-0025.sysfs.capacity_level # SKIP
ok 44 tcpm-source-psy-1-0025.sysfs.model_name # SKIP
ok 45 tcpm-source-psy-1-0025.sysfs.manufacturer # SKIP
ok 46 tcpm-source-psy-1-0025.sysfs.serial_number # SKIP
ok 47 tcpm-source-psy-1-0025.sysfs.technology # SKIP
ok 48 tcpm-source-psy-1-0025.sysfs.cycle_count # SKIP
ok 49 tcpm-source-psy-1-0025.sysfs.scope # SKIP
ok 50 tcpm-source-psy-1-0025.sysfs.input_current_limit # SKIP
ok 51 tcpm-source-psy-1-0025.sysfs.input_voltage_limit # SKIP
 # Reported: '5000000' uV (5 V)
ok 52 tcpm-source-psy-1-0025.sysfs.voltage_now
 # Reported: '5000000' uV (5 V)
ok 53 tcpm-source-psy-1-0025.sysfs.voltage_min
 # Reported: '5000000' uV (5 V)
ok 54 tcpm-source-psy-1-0025.sysfs.voltage_max
ok 55 tcpm-source-psy-1-0025.sysfs.voltage_min_design # SKIP
ok 56 tcpm-source-psy-1-0025.sysfs.voltage_max_design # SKIP
 # Reported: '3000000' uA (3000 mA)
ok 57 tcpm-source-psy-1-0025.sysfs.current_now
 # Reported: '3000000' uA (3000 mA)
ok 58 tcpm-source-psy-1-0025.sysfs.current_max
ok 59 tcpm-source-psy-1-0025.sysfs.charge_now # SKIP
ok 60 tcpm-source-psy-1-0025.sysfs.charge_full # SKIP
ok 61 tcpm-source-psy-1-0025.sysfs.charge_full_design # SKIP
ok 62 tcpm-source-psy-1-0025.sysfs.power_now # SKIP
ok 63 tcpm-source-psy-1-0025.sysfs.energy_now # SKIP
ok 64 tcpm-source-psy-1-0025.sysfs.energy_full # SKIP
ok 65 tcpm-source-psy-1-0025.sysfs.energy_full_design # SKIP
ok 66 tcpm-source-psy-1-0025.sysfs.energy_full_design # SKIP
 # 47 skipped test(s) detected.  Consider enabling relevant config options to improve coverage.
 # Totals: pass:19 fail:0 xfail:0 xpass:0 skip:47 error:0
---
 drivers/power/supply/max77759_charger.c | 21 +++++++++++++--------
 1 file changed, 13 insertions(+), 8 deletions(-)

diff --git a/drivers/power/supply/max77759_charger.c b/drivers/power/supply/max77759_charger.c
index 9bb414599f16..58594bb78426 100644
--- a/drivers/power/supply/max77759_charger.c
+++ b/drivers/power/supply/max77759_charger.c
@@ -26,7 +26,7 @@
 
 /* Default values for Fast Charge Current & Float Voltage */
 #define CHG_CC_DEFAULT_UA			2266770
-#define CHG_FV_DEFAULT_MV			4300
+#define CHG_FV_DEFAULT_UV			4300000
 
 #define MAX_NUM_RETRIES				3
 #define PSY_WORK_RETRY_DELAY_MS			10
@@ -61,10 +61,10 @@ static const struct linear_range chgcc_limit_ranges[] = {
 	LINEAR_RANGE(200000, 0x3, 0x3C, 66670),
 };
 
-/* Charge Termination Voltage Limits (in mV) */
+/* Charge Termination Voltage Limits (in uV) */
 static const struct linear_range chg_cv_prm_ranges[] = {
-	LINEAR_RANGE(3800, 0x38, 0x39, 100),
-	LINEAR_RANGE(4000, 0x0, 0x32, 10),
+	LINEAR_RANGE(3800000, 0x38, 0x39, 100000),
+	LINEAR_RANGE(4000000, 0x0, 0x32, 10000),
 };
 
 /* USB input current limits (in uA) */
@@ -310,14 +310,14 @@ static int get_float_voltage(struct max77759_charger *chg)
 	return ret ? ret : val;
 }
 
-static int set_float_voltage_limit(struct max77759_charger *chg, u32 fv_mv)
+static int set_float_voltage_limit(struct max77759_charger *chg, u32 fv_uv)
 {
 	u32 regval;
 	bool found;
 
 	linear_range_get_selector_high_array(chg_cv_prm_ranges,
 					     ARRAY_SIZE(chg_cv_prm_ranges),
-					     fv_mv, &regval, &found);
+					     fv_uv, &regval, &found);
 	if (!found)
 		return -EINVAL;
 
@@ -370,6 +370,11 @@ static const enum power_supply_property max77759_charger_props[] = {
 	POWER_SUPPLY_PROP_INPUT_CURRENT_LIMIT,
 };
 
+/*
+ * Note: None of the properties in this driver support usage of negative values.
+ * If you do see one, it's because the function is reporting an error value and
+ * should not be taken as a measurement value or status.
+ */
 static int max77759_charger_get_property(struct power_supply *psy,
 					 enum power_supply_property psp,
 					 union power_supply_propval *pval)
@@ -557,10 +562,10 @@ static int max77759_charger_init(struct max77759_charger *chg)
 		return ret;
 
 	if (power_supply_get_battery_info(chg->psy, &info)) {
-		fv = CHG_FV_DEFAULT_MV;
+		fv = CHG_FV_DEFAULT_UV;
 		fast_chg_curr = CHG_CC_DEFAULT_UA;
 	} else {
-		fv = info->constant_charge_voltage_max_uv / 1000;
+		fv = info->constant_charge_voltage_max_uv;
 		fast_chg_curr = info->constant_charge_current_max_ua;
 	}
 

---
base-commit: 81ebd43cc0d6d106ce7b6ccbf7b5e40ca7f5503d
change-id: 20260402-fix-psy-max77759-usb-next-15a4f86a08ce

Best regards,
-- 
Amit Sunil Dhamne <amitsd@google.com>

