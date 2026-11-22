From: EMCP333 <emcp@enser.io>
Date: Sun, 22 Nov 2026 05:13:31 +0000
Subject: [PATCH] power: supply: qcom_smbx: Make the float voltage
 adjustable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-b4-smbx-ccv-v1-1-0ecc4217b58c@enser.io>
X-B4-Tracking: v=1; b=H4sIAPp5AmsC/yXMwQ7CIBAE0F9p9uyqECLWX2k8wLJYTETDKmnS9
 N8FPb7JzKwgXBILXIYVCtck6Zkb1G4Aml2+MabQDPqoT0ppjd6gPPyCRBWjtTZEcw5+HKEtXoV
 jWn5v0/Vv+fg707tf9IZ3wuiLyzT3qPNQ7d5gIQ3b9gVBNQZRjwAAAA==
X-Change-ID: 20261122-b4-smbx-ccv-f777df48db99
To: Sebastian Reichel <sre@kernel.org>
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Robin Snyders <robin@snyders.xyz>, linux-pm@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 EMCP333 <emcp@enser.io>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795324411; l=5793;
 i=emcp@enser.io; s=ultron; h=from:subject:message-id;
 bh=c81KUHplwWRmxuVs0d0MhXnbVsifOIAU8afoDoBp8fU=;
 b=Ll0mm0xiLTjcmUVG66bC1fcaaIlZ0tYWOeV2SJwrJnvIrAnPltOkPU4a5tL/lJPGGBByyewf8
 GEsQUpAyUvcDD8RViA1zHeMCRlafQHvHKGePNniq3S7YnIr+RdESGeB
X-Developer-Key: i=emcp@enser.io; a=ed25519;
 pk=5sG48Lul+Vn7OzXu3VZrCWk5uvEFPYMXYnAV0TZR/tY=
X-Endpoint-Received: by B4 Relay for emcp@enser.io/ultron with auth_id=1598
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Charging a lithium battery to a lower voltage is the usual way to make
it last longer, and on PMI8998 and PM660 the float voltage is the
register that sets that voltage. The driver programs it once at probe
from the battery data, and userspace cannot change it.

Expose it as POWER_SUPPLY_PROP_CONSTANT_CHARGE_VOLTAGE, writable, and
the value probe left as CONSTANT_CHARGE_VOLTAGE_MAX. A write is clamped
to the range between the lowest setting and that maximum, then rounded
down to a 7.5 mV step, so userspace can charge the battery less than
the battery data allows but never more. Without battery data, the
maximum is whatever the boot firmware set.

Tested on a OnePlus 6T (PMI8998) on a 6.18-based kernel, with this
patch and a backport of commit 2a26d260e72a ("power: supply: qcom_smbx:
fix float voltage selector"). constant_charge_voltage_max reads
4395000, and writes read back as below, with the selector read through
regmap debugfs:

  4100000 -> 4095000 (selector 81)
  4500000 -> 4395000 (selector 121, the maximum)
  3000000 -> 3487500 (selector 0, the lowest setting)

The code and this changelog were prepared with the help of an AI coding
assistant. The submitter has reviewed both and takes responsibility for
them.

Signed-off-by: EMCP333 <emcp@enser.io>
---
Also ran on v7.4-rc3 on the same phone, as this exact commit, with the
charge daemon stopped: writing 4100000, 4500000 and 3000000 reads back
4095000, 4395000 and 3487500 (float voltage selectors 0x51, 0x79 and
0x00).
---
 drivers/power/supply/qcom_smbx.c | 47 ++++++++++++++++++++++++++++++++++++++++
 1 file changed, 47 insertions(+)

diff --git a/drivers/power/supply/qcom_smbx.c b/drivers/power/supply/qcom_smbx.c
index 8a2f635a6c..2d30c18671 100644
--- a/drivers/power/supply/qcom_smbx.c
+++ b/drivers/power/supply/qcom_smbx.c
@@ -381,6 +381,7 @@ struct smb_init_register {
  * @base:		Base address for smb registers
  * @regmap:		Register map
  * @batt_info:		Battery data from DT
+ * @float_voltage_max_uv: Highest float voltage userspace may set, in uV
  * @initial_charge_enable: Charging enable state before hardware setup
  * @status_change_work: Worker to handle plug/unplug events
  * @cable_irq:		USB plugin IRQ
@@ -395,6 +396,7 @@ struct smb_chip {
 	unsigned int base;
 	struct regmap *regmap;
 	struct power_supply_battery_info *batt_info;
+	int float_voltage_max_uv;
 	u8 initial_charge_enable;
 
 	struct delayed_work status_change_work;
@@ -417,6 +419,8 @@ static enum power_supply_property smb_properties[] = {
 	POWER_SUPPLY_PROP_HEALTH,
 	POWER_SUPPLY_PROP_ONLINE,
 	POWER_SUPPLY_PROP_USB_TYPE,
+	POWER_SUPPLY_PROP_CONSTANT_CHARGE_VOLTAGE,
+	POWER_SUPPLY_PROP_CONSTANT_CHARGE_VOLTAGE_MAX,
 };
 
 static int smb_get_prop_usb_online(struct smb_chip *chip, int *val)
@@ -653,6 +657,32 @@ static int smb_get_prop_health(struct smb_chip *chip, int *val)
 	return 0;
 }
 
+static int smb_get_float_voltage(struct smb_chip *chip, int *val)
+{
+	unsigned int sel;
+	int rc;
+
+	rc = regmap_read(chip->regmap, chip->base + FLOAT_VOLTAGE_CFG, &sel);
+	if (rc < 0)
+		return rc;
+
+	*val = SMB2_FLOAT_VOLTAGE_MIN_UV +
+	       (sel & FLOAT_VOLTAGE_SETTING_MASK) * SMB2_FLOAT_VOLTAGE_STEP_UV;
+
+	return 0;
+}
+
+static int smb_set_float_voltage(struct smb_chip *chip, int val)
+{
+	unsigned int sel;
+
+	val = clamp(val, SMB2_FLOAT_VOLTAGE_MIN_UV, chip->float_voltage_max_uv);
+	sel = (val - SMB2_FLOAT_VOLTAGE_MIN_UV) / SMB2_FLOAT_VOLTAGE_STEP_UV;
+
+	return regmap_update_bits(chip->regmap, chip->base + FLOAT_VOLTAGE_CFG,
+				  FLOAT_VOLTAGE_SETTING_MASK, sel);
+}
+
 static int smb_get_property(struct power_supply *psy,
 			     enum power_supply_property psp,
 			     union power_supply_propval *val)
@@ -682,6 +712,11 @@ static int smb_get_property(struct power_supply *psy,
 		return smb_get_prop_health(chip, &val->intval);
 	case POWER_SUPPLY_PROP_USB_TYPE:
 		return smb_apsd_get_charger_type(chip, &val->intval);
+	case POWER_SUPPLY_PROP_CONSTANT_CHARGE_VOLTAGE:
+		return smb_get_float_voltage(chip, &val->intval);
+	case POWER_SUPPLY_PROP_CONSTANT_CHARGE_VOLTAGE_MAX:
+		val->intval = chip->float_voltage_max_uv;
+		return 0;
 	default:
 		dev_err(chip->dev, "invalid property: %d\n", psp);
 		return -EINVAL;
@@ -700,6 +735,8 @@ static int smb_set_property(struct power_supply *psy,
 					  USBIN_SUSPEND_BIT, !val->intval);
 	case POWER_SUPPLY_PROP_CURRENT_MAX:
 		return smb_set_current_limit(chip, val->intval);
+	case POWER_SUPPLY_PROP_CONSTANT_CHARGE_VOLTAGE:
+		return smb_set_float_voltage(chip, val->intval);
 	default:
 		dev_err(chip->dev, "No setter for property: %d\n", psp);
 		return -EINVAL;
@@ -712,6 +749,7 @@ static int smb_property_is_writable(struct power_supply *psy,
 	switch (psp) {
 	case POWER_SUPPLY_PROP_STATUS:
 	case POWER_SUPPLY_PROP_CURRENT_MAX:
+	case POWER_SUPPLY_PROP_CONSTANT_CHARGE_VOLTAGE:
 		return 1;
 	default:
 		return 0;
@@ -1064,6 +1102,15 @@ static int smb_probe(struct platform_device *pdev)
 		return dev_err_probe(chip->dev, rc, "Couldn't set vbat max\n");
 
 skip_float_voltage:
+	/*
+	 * Userspace may lower the float voltage to charge the battery less,
+	 * but not raise it above what is set now: the battery's voltage or,
+	 * without battery data, the boot firmware's setting.
+	 */
+	rc = smb_get_float_voltage(chip, &chip->float_voltage_max_uv);
+	if (rc < 0)
+		return dev_err_probe(chip->dev, rc, "Couldn't read vbat max\n");
+
 	rc = smb_init_irq(chip, &irq, "bat-ov", smb_handle_batt_overvoltage);
 	if (rc < 0)
 		return rc;

---
base-commit: 7475ea8b58616b33c04afb976cf0fbaad9dd63fb
change-id: 20261122-b4-smbx-ccv-f777df48db99

Best regards,
--  
EMCP333 <emcp@enser.io>

