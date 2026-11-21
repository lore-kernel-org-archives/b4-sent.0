From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Date: Sat, 21 Nov 2026 10:30:22 +0100
Subject: [PATCH 3/3] power: supply: smb347: Set the USB input current limit
 from APSD
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-upstream-smb347-apsd-v1-3-ca46b92bfd44@tsv-stahl-riesa.de>
References: <20261121-upstream-smb347-apsd-v1-0-ca46b92bfd44@tsv-stahl-riesa.de>
In-Reply-To: <20261121-upstream-smb347-apsd-v1-0-ca46b92bfd44@tsv-stahl-riesa.de>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Heidelberg <david@ixit.cz>, 
 Dmitry Osipenko <digetx@gmail.com>
Cc: Svyatoslav Ryhel <clamor95@gmail.com>, 
 Bruce Robertson <brucer42@gmail.com>, 
 =?utf-8?q?Martin_J=C3=BCcker?= <martin.juecker@gmail.com>, 
 Mithil Bavishi <bavishimithil@gmail.com>, linux-pm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Patrick Fischer <admin@tsv-stahl-riesa.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795253429; l=15427;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=RELoFozcAv6c9VU1zOArm6B+aQ4krKLrECThTH0LyRU=;
 b=9AI6Xg4PIzgnmdnJY9A9zzqC0u65gWHGfOP0Wbq8Q19MFt09MfXQzOM+fMzfm3obGhlX3yKyn
 Ws4wUXR6rmDDtTp5Ggz05nCt5hunQzbpOFTVHKcY+dbFKIZICYRGBj4
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver programs the USB input current limit only once at probe,
from "summit,usb-current-limit-microamp". Without that property the
limit stays at the value from the chip's non-volatile memory. On the
Nexus 7 (2012) this is 900 mA, so the original 2 A charger charges the
battery no faster than a PC port: about 540 mA into the battery with
the display on, against about 505 mA at a laptop port. With the limit
set to 1800 mA in the device tree, the charger gives about 790 mA, but
then the same 1800 mA also applies to PC ports. Once, directly after
boot at a laptop port, input current limiting (AICL) then ended at
the lowest step (STAT_E 0xc0) and the battery got about 120 mA.

The charger detects the port type itself (automatic power source
detection, APSD) and reports it in STAT_D. The Android kernel for the
Nexus 7 uses it: 900 mA for a standard downstream port, 1800 mA for a
charging downstream port, a dedicated charger or an unknown charger.
It turns AICL off while it changes the limit and on again afterwards.

Use the APSD result to set the limit and report it as
POWER_SUPPLY_PROP_USB_TYPE:

  SDP, other, unknown  500 mA (USB 2.0)
  CDP                  1500 mA (BC 1.2)
  DCP                  "summit,usb-current-limit-microamp", or 1500 mA

All values are capped by "summit,usb-current-limit-microamp" if it is
set. A delayed work reads STAT_D 500 ms after the USB input became valid
and polls for up to 2 s until APSD is done. The same delay applies at
probe: directly after probe the charger NAKs the write to
CFG_VARIOUS_FUNCTION, 500 ms later it accepts it. If APSD does not
finish, the limit for an unknown port is used. When the input goes away,
the work sets that limit as well, so that a new connection never starts
with the higher limit of the previous charger. The work runs after every
USB input interrupt, even if the input state looks unchanged: on the
Nexus 7, a quick move from a laptop port to the charger gave two
interrupts, but the driver saw the input as connected both times and
kept the limit for the laptop port. Nothing changes while the charger
supplies VBUS in host mode.

The detection relies on the interrupt for input changes, so it is only
used if the interrupt is available. The STAT_D and AICL bit layout is
only known for the SMB347, so SMB345 and SMB358 are left as they are.
APSD is turned on at probe, as in the Android driver.

On the Nexus 7 (2012) the original charger is detected as DCP and now
gives about 1160 mA into the battery at 37-39 % charge with the display
off, against 600 mA before (31-33 %), and about 970 mA at 74-82 % with
the display on, against 560 mA before (84-86 %). 1800 mA in the device
tree gave no further gain. A laptop port detected as CDP gives about
640 mA instead of 505 mA.

This changes the behaviour of boards that set the property to a value
above 500 mA, today exynos4412-p4note and omap4-samsung-espresso10
with 1800 mA: they keep 1800 mA with a dedicated charger, but draw
500 mA from a PC port.

The STAT_D, AICL and APSD bits and the 20 ms delay before turning AICL
back on come from drivers/power/smb347-charger.c in the
android-tegra3-grouper-3.1-lollipop-release branch of
https://android.googlesource.com/kernel/tegra.

Signed-off-by: Patrick Fischer <admin@tsv-stahl-riesa.de>
---
 drivers/power/supply/smb347-charger.c | 252 +++++++++++++++++++++++++++++++++-
 1 file changed, 250 insertions(+), 2 deletions(-)

diff --git a/drivers/power/supply/smb347-charger.c b/drivers/power/supply/smb347-charger.c
index 03d58b378a25..330c05cfddc3 100644
--- a/drivers/power/supply/smb347-charger.c
+++ b/drivers/power/supply/smb347-charger.c
@@ -8,7 +8,9 @@
  *          Mika Westerberg <mika.westerberg@linux.intel.com>
  */
 
+#include <linux/bitfield.h>
 #include <linux/delay.h>
+#include <linux/devm-helpers.h>
 #include <linux/err.h>
 #include <linux/kernel.h>
 #include <linux/module.h>
@@ -19,6 +21,7 @@
 #include <linux/property.h>
 #include <linux/regmap.h>
 #include <linux/regulator/driver.h>
+#include <linux/workqueue.h>
 
 #include <dt-bindings/power/summit,smb347-charger.h>
 
@@ -44,11 +47,13 @@
 #define CFG_CURRENT_LIMIT_DC_SHIFT		4
 #define CFG_CURRENT_LIMIT_USB_MASK		0x0f
 #define CFG_VARIOUS_FUNCTION			0x02
+#define CFG_VARIOUS_FUNCTION_AICL		BIT(4)
 #define CFG_FLOAT_VOLTAGE			0x03
 #define CFG_FLOAT_VOLTAGE_FLOAT_MASK		0x3f
 #define CFG_FLOAT_VOLTAGE_THRESHOLD_MASK	0xc0
 #define CFG_FLOAT_VOLTAGE_THRESHOLD_SHIFT	6
 #define CFG_CHARGE_CONTROL			0x04
+#define CFG_CHARGE_CONTROL_APSD			BIT(2)
 #define CFG_STAT				0x05
 #define CFG_STAT_DISABLED			BIT(5)
 #define CFG_STAT_ACTIVE_HIGH			BIT(7)
@@ -131,10 +136,29 @@
 #define STAT_C_CHG_TERM				BIT(5)
 #define STAT_C_CHARGER_ERROR			BIT(6)
 #define STAT_D					0x3e
+#define STAT_D_APSD_RESULT_MASK			GENMASK(2, 0)
+#define STAT_D_APSD_RESULT_CDP			1
+#define STAT_D_APSD_RESULT_DCP			2
+#define STAT_D_APSD_RESULT_OTHER		3
+#define STAT_D_APSD_RESULT_SDP			4
+#define STAT_D_APSD_DONE			BIT(3)
 #define STAT_E					0x3f
 
 #define SMB347_MAX_REGISTER			0x3f
 
+/*
+ * USB input current limits (in uA) for the port types reported by APSD.
+ * A dedicated charger gets "summit,usb-current-limit-microamp" if given.
+ */
+#define SMB347_SDP_CURRENT_LIMIT		500000U		/* USB 2.0 */
+#define SMB347_CDP_CURRENT_LIMIT		1500000U	/* BC 1.2 */
+#define SMB347_DCP_CURRENT_LIMIT		1500000U	/* BC 1.2 */
+
+/* APSD takes a few hundred milliseconds after the input became valid. */
+#define SMB347_APSD_DELAY_MS			500
+#define SMB347_APSD_POLL_US			(100 * USEC_PER_MSEC)
+#define SMB347_APSD_TIMEOUT_US			(2 * USEC_PER_SEC)
+
 /**
  * struct smb347_charger - smb347 charger instance
  * @dev: pointer to device
@@ -142,11 +166,14 @@
  * @mains: power_supply instance for AC/DC power
  * @usb: power_supply instance for USB power
  * @usb_rdev: USB VBUS regulator device
+ * @apsd_work: sets the USB input current limit from the detected port type
  * @id: SMB charger ID
  * @mains_online: is AC/DC input connected
  * @usb_online: is USB input connected
  * @irq_unsupported: is interrupt unsupported by SMB hardware
  * @usb_vbus_enabled: is USB VBUS powered by SMB charger
+ * @use_apsd: USB input current limit follows the APSD result
+ * @usb_type: USB port type detected by APSD (%POWER_SUPPLY_USB_TYPE_*)
  * @max_charge_current: maximum current (in uA) the battery can be charged
  * @max_charge_voltage: maximum voltage (in uV) the battery can be charged
  * @pre_charge_current: current (in uA) to use in pre-charging phase
@@ -202,11 +229,14 @@ struct smb347_charger {
 	struct power_supply	*mains;
 	struct power_supply	*usb;
 	struct regulator_dev	*usb_rdev;
+	struct delayed_work	apsd_work;
 	unsigned int		id;
 	bool			mains_online;
 	bool			usb_online;
 	bool			irq_unsupported;
 	bool			usb_vbus_enabled;
+	bool			use_apsd;
+	int			usb_type;
 
 	unsigned int		max_charge_current;
 	unsigned int		max_charge_voltage;
@@ -280,6 +310,14 @@ static const unsigned int ccc_tbl[NUM_CHIP_TYPES][4] = {
 	[SMB358] = {  200000,  450000,  600000,  900000 },
 };
 
+/*
+ * Chips with automatic power source detection (APSD) results in STAT_D and
+ * the AICL enable bit in CFG_VARIOUS_FUNCTION as described above.
+ */
+static const bool apsd_tbl[NUM_CHIP_TYPES] = {
+	[SMB347] = true,
+};
+
 /* Convert register value to current using lookup table */
 static int hw_to_current(const unsigned int *tbl, size_t size, unsigned int val)
 {
@@ -497,6 +535,59 @@ static int smb347_set_current_limits(struct smb347_charger *smb)
 	return 0;
 }
 
+/*
+ * Sets the USB input current limit. Like the vendor driver, turn AICL off
+ * while the limit changes, so that the charger detects the input current
+ * again with the new limit once AICL is turned back on.
+ *
+ * Must be called with the configuration registers writable.
+ */
+static int smb347_set_usb_current_limit(struct smb347_charger *smb,
+					unsigned int limit)
+{
+	unsigned int id = smb->id;
+	unsigned int val;
+	bool aicl;
+	int hw, ret, ret2;
+
+	hw = current_to_hw(icl_tbl[id], ARRAY_SIZE(icl_tbl[id]), limit);
+	if (hw < 0)
+		return hw;
+
+	ret = regmap_read(smb->regmap, CFG_CURRENT_LIMIT, &val);
+	if (ret < 0)
+		return ret;
+
+	if ((val & CFG_CURRENT_LIMIT_USB_MASK) == hw)
+		return 0;
+
+	ret = regmap_read(smb->regmap, CFG_VARIOUS_FUNCTION, &val);
+	if (ret < 0)
+		return ret;
+
+	aicl = val & CFG_VARIOUS_FUNCTION_AICL;
+	if (aicl) {
+		ret = regmap_clear_bits(smb->regmap, CFG_VARIOUS_FUNCTION,
+					CFG_VARIOUS_FUNCTION_AICL);
+		if (ret < 0)
+			return ret;
+	}
+
+	ret = regmap_update_bits(smb->regmap, CFG_CURRENT_LIMIT,
+				 CFG_CURRENT_LIMIT_USB_MASK, hw);
+
+	if (aicl) {
+		/* The vendor driver waits 20 ms before turning AICL back on. */
+		msleep(20);
+		ret2 = regmap_set_bits(smb->regmap, CFG_VARIOUS_FUNCTION,
+				       CFG_VARIOUS_FUNCTION_AICL);
+		if (!ret)
+			ret = ret2;
+	}
+
+	return ret;
+}
+
 static int smb347_set_voltage_limits(struct smb347_charger *smb)
 {
 	int ret;
@@ -794,6 +885,125 @@ static int smb347_hw_init(struct smb347_charger *smb)
 	return ret;
 }
 
+static int smb347_apsd_usb_type(unsigned int stat_d)
+{
+	switch (FIELD_GET(STAT_D_APSD_RESULT_MASK, stat_d)) {
+	case STAT_D_APSD_RESULT_CDP:
+		return POWER_SUPPLY_USB_TYPE_CDP;
+	case STAT_D_APSD_RESULT_DCP:
+		return POWER_SUPPLY_USB_TYPE_DCP;
+	case STAT_D_APSD_RESULT_SDP:
+		return POWER_SUPPLY_USB_TYPE_SDP;
+	default:
+		/* Includes STAT_D_APSD_RESULT_OTHER (non-BC 1.2 chargers). */
+		return POWER_SUPPLY_USB_TYPE_UNKNOWN;
+	}
+}
+
+static unsigned int smb347_usb_type_current_limit(struct smb347_charger *smb,
+						  int usb_type)
+{
+	unsigned int dcp = smb->usb_hc_current_limit ?: SMB347_DCP_CURRENT_LIMIT;
+
+	switch (usb_type) {
+	case POWER_SUPPLY_USB_TYPE_DCP:
+		return dcp;
+	case POWER_SUPPLY_USB_TYPE_CDP:
+		return min(dcp, SMB347_CDP_CURRENT_LIMIT);
+	default:
+		return min(dcp, SMB347_SDP_CURRENT_LIMIT);
+	}
+}
+
+static void smb347_apsd_work(struct work_struct *work)
+{
+	struct smb347_charger *smb = container_of(to_delayed_work(work),
+						  struct smb347_charger,
+						  apsd_work);
+	int usb_type = POWER_SUPPLY_USB_TYPE_UNKNOWN;
+	unsigned int limit, val;
+	int ret;
+
+	/* VBUS comes from the charger itself in USB host mode. */
+	if (smb->usb_vbus_enabled)
+		return;
+
+	/*
+	 * Without input, set the limit for an unknown port, so that the next
+	 * connection starts with it until APSD has detected the port type.
+	 */
+	if (smb->usb_online) {
+		ret = regmap_read_poll_timeout(smb->regmap, STAT_D, val,
+					       val & STAT_D_APSD_DONE,
+					       SMB347_APSD_POLL_US,
+					       SMB347_APSD_TIMEOUT_US);
+		if (!ret)
+			usb_type = smb347_apsd_usb_type(val);
+		else if (ret == -ETIMEDOUT)
+			dev_dbg(smb->dev, "APSD did not complete\n");
+		else
+			dev_err(smb->dev, "failed to read APSD result: %d\n", ret);
+	}
+
+	limit = smb347_usb_type_current_limit(smb, usb_type);
+
+	ret = smb347_set_writable(smb, true, true);
+	if (ret < 0)
+		goto out;
+
+	ret = smb347_set_usb_current_limit(smb, limit);
+	smb347_set_writable(smb, false, true);
+out:
+	if (ret < 0)
+		dev_err(smb->dev, "failed to set USB input current limit: %d\n",
+			ret);
+
+	WRITE_ONCE(smb->usb_type, usb_type);
+	power_supply_changed(smb->usb);
+}
+
+static void smb347_apsd_schedule(struct smb347_charger *smb)
+{
+	unsigned long delay = 0;
+
+	if (!smb->use_apsd)
+		return;
+
+	if (smb->usb_online)
+		delay = msecs_to_jiffies(SMB347_APSD_DELAY_MS);
+
+	mod_delayed_work(system_dfl_wq, &smb->apsd_work, delay);
+}
+
+static int smb347_apsd_init(struct smb347_charger *smb)
+{
+	int ret;
+
+	smb->use_apsd = apsd_tbl[smb->id] && smb->use_usb &&
+			!smb->irq_unsupported;
+	if (!smb->use_apsd)
+		return 0;
+
+	ret = smb347_set_writable(smb, true, true);
+	if (ret < 0)
+		return ret;
+
+	/* The vendor driver turns APSD on at probe as well. */
+	ret = regmap_set_bits(smb->regmap, CFG_CHARGE_CONTROL,
+			      CFG_CHARGE_CONTROL_APSD);
+	smb347_set_writable(smb, false, true);
+	if (ret < 0)
+		return ret;
+
+	/*
+	 * Directly after probe the charger NAKs the write to
+	 * CFG_VARIOUS_FUNCTION. Wait as after a new connection.
+	 */
+	smb347_apsd_schedule(smb);
+
+	return 0;
+}
+
 static irqreturn_t smb347_interrupt(int irq, void *data)
 {
 	struct smb347_charger *smb = data;
@@ -885,6 +1095,14 @@ static irqreturn_t smb347_interrupt(int irq, void *data)
 			if (smb->use_usb)
 				power_supply_changed(smb->usb);
 		}
+
+		/*
+		 * The USB input may have been disconnected and connected again
+		 * since the last interrupt, so detect the port type again even
+		 * if the input state looks unchanged.
+		 */
+		if (irqstat_e & IRQSTAT_E_USBIN_UV_IRQ)
+			smb347_apsd_schedule(smb);
 		handled = true;
 	}
 
@@ -1157,6 +1375,10 @@ static int smb347_get_property_locked(struct power_supply *psy,
 		val->intval = ret;
 		break;
 
+	case POWER_SUPPLY_PROP_USB_TYPE:
+		val->intval = READ_ONCE(smb->usb_type);
+		break;
+
 	default:
 		return -EINVAL;
 	}
@@ -1191,6 +1413,15 @@ static enum power_supply_property smb347_properties[] = {
 	POWER_SUPPLY_PROP_CONSTANT_CHARGE_VOLTAGE,
 };
 
+static enum power_supply_property smb347_usb_properties[] = {
+	POWER_SUPPLY_PROP_STATUS,
+	POWER_SUPPLY_PROP_CHARGE_TYPE,
+	POWER_SUPPLY_PROP_ONLINE,
+	POWER_SUPPLY_PROP_CONSTANT_CHARGE_CURRENT,
+	POWER_SUPPLY_PROP_CONSTANT_CHARGE_VOLTAGE,
+	POWER_SUPPLY_PROP_USB_TYPE,
+};
+
 static bool smb347_volatile_reg(struct device *dev, unsigned int reg)
 {
 	switch (reg) {
@@ -1516,9 +1747,13 @@ static const struct power_supply_desc smb347_mains_desc = {
 static const struct power_supply_desc smb347_usb_desc = {
 	.name		= "smb347-usb",
 	.type		= POWER_SUPPLY_TYPE_USB,
+	.usb_types	= BIT(POWER_SUPPLY_USB_TYPE_SDP) |
+			  BIT(POWER_SUPPLY_USB_TYPE_CDP) |
+			  BIT(POWER_SUPPLY_USB_TYPE_DCP) |
+			  BIT(POWER_SUPPLY_USB_TYPE_UNKNOWN),
 	.get_property	= smb347_get_property,
-	.properties	= smb347_properties,
-	.num_properties	= ARRAY_SIZE(smb347_properties),
+	.properties	= smb347_usb_properties,
+	.num_properties	= ARRAY_SIZE(smb347_usb_properties),
 };
 
 static const struct regulator_desc smb347_usb_vbus_regulator_desc = {
@@ -1548,6 +1783,7 @@ static int smb347_probe(struct i2c_client *client)
 		return -ENOMEM;
 	smb->dev = &client->dev;
 	smb->id = id->driver_data;
+	smb->usb_type = POWER_SUPPLY_USB_TYPE_UNKNOWN;
 	i2c_set_clientdata(client, smb);
 
 	smb347_dt_parse_dev_info(smb);
@@ -1582,10 +1818,22 @@ static int smb347_probe(struct i2c_client *client)
 	if (ret < 0)
 		return ret;
 
+	/* Before the IRQ, so that it is cancelled after the IRQ is freed. */
+	ret = devm_delayed_work_autocancel(dev, &smb->apsd_work,
+					   smb347_apsd_work);
+	if (ret)
+		return ret;
+
 	ret = smb347_irq_init(smb, client);
 	if (ret)
 		return ret;
 
+	ret = smb347_apsd_init(smb);
+	if (ret < 0) {
+		smb347_irq_disable(smb);
+		return dev_err_probe(dev, ret, "failed to enable APSD\n");
+	}
+
 	usb_rdev_cfg.dev = dev;
 	usb_rdev_cfg.driver_data = smb;
 	usb_rdev_cfg.regmap = smb->regmap;

-- 
2.56.1

