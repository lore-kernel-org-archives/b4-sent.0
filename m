From: Herman van Hazendonk <github.com@herrie.org>
Date: Fri, 05 Jun 2026 11:18:13 +0200
Subject: [PATCH v2 2/2] power: supply: max8903: add DC and USB input
 current-limit GPIO controls
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260605-submit-power-max8903-dc-limit-v2-2-0c5396e98f14@herrie.org>
References: <20260605-submit-power-max8903-dc-limit-v2-0-0c5396e98f14@herrie.org>
In-Reply-To: <20260605-submit-power-max8903-dc-limit-v2-0-0c5396e98f14@herrie.org>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780651091; l=22790;
 i=github.com@herrie.org; s=20240417; h=from:subject:message-id;
 bh=1OtbQaVpa+0OPsaIlA+iXEvHV7q8kYPoNmQaFjwLI7I=;
 b=jEfufUPDN91dQ2E1v8jPlw5sLD8JJeJJbDcwC0fcxpEQIH8xg//f55ZhNqKfg+PXpW614Ywxk
 CosJ5ukGsCHBi4p50XCEwyP57/wehqgBlZLsTZl+P83O/VWNZ2mDS5d
X-Developer-Key: i=github.com@herrie.org; a=ed25519;
 pk=YYxdq8fb5O9vhkW3n2dCH044FPZZO5718v/du7fRhFw=
X-Endpoint-Received: by B4 Relay for github.com@herrie.org/20240417 with auth_id=809
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add two optional current-limit knobs surfaced through
POWER_SUPPLY_PROP_INPUT_CURRENT_LIMIT, selected by which input source
is currently online:

  - DC (DOK / TA-IN): a "dc-current-limit-gpios" array drives the
    GPIOs of an external resistor mux connected to the MAX8903 IDC pin
    (DC Current-Limit Set Input, pin 11). The IDC pin programs the
    step-down DC input current limit from 0.5 A to 2 A via R_IDC when
    the DCM mode pin is logic-high. The DT property
    "dc-current-limit-mapping" describes the (current_ua, gpio_value)
    pairs the board can program; the driver picks the largest entry
    whose limit is <= the requested limit. A 0 uA entry, used to
    stop drawing DC current, is selectable by issuing a 0 uA request
    (the selection uses a -1 "not found" sentinel rather than
    tracking best_limit > 0, so the all-zero entry can win).

  - USB (UOK / USB-IN): a single "usb-current-limit-gpio" drives the
    MAX8903 IUSB pin (USB Current-Limit Set Input, pin 7). The IUSB
    pin is silicon-fixed per the MAX8903 datasheet Pin Description:
    logic-low selects 100 mA, logic-high selects 500 mA. The two
    values are encoded as MAX8903_USB_CURRENT_LIMIT_{LOW,HIGH}_UA
    #defines with the datasheet quote in a header comment. The
    requested limit picks HIGH if it can absorb 500 mA, else LOW,
    else returns -EINVAL rather than silently programming a higher
    current that would violate the system power budget. Mirroring
    the DC-priority policy in the get path: when ta_in is asserted
    the part draws from DC regardless of USB state, so the set path
    only routes to USB when DC is not online.

The dispatch in max8903_set_property() to the DC vs USB path needs to
match the active source flag set by the corresponding *_ok GPIO IRQ
handler; both update sites take a new struct mutex source_lock so the
check and the resulting hardware write cannot be torn by a concurrent
IRQ flipping the source-online flag mid-decision. The DOK/UOK IRQ
handlers hold source_lock across the full read-modify-evaluate block
(line sampling, ta_in/usb_in update, dcm/cen GPIO writes, psy type
update) so the cen enable calculation reads a stable other-source
flag rather than racing with the peer IRQ. The IRQs are requested
with IRQF_ONESHOT (threaded), so a sleepable lock is the right
primitive in both contexts. max8903_get_property() also takes
source_lock briefly to snapshot the source flags and current-limit
values so userspace never observes a torn pair of
(source-online flag, current-limit ua).

dc-current-limit-mapping gpio_value entries are validated at parse
against the GPIO array width so a malformed DT value is rejected
instead of being silently truncated by gpiod_set_array_value() and
selecting the wrong mux level. ndescs is also bounded to
< BITS_PER_TYPE(u32) to keep BIT(ndescs) well-defined on 32-bit.
The mapping is additionally required to contain a gpio_value=0
entry: devm_gpiod_get_array_optional() asks for GPIOD_OUT_LOW, so
the hardware mux starts at gpio_value 0, and the driver seeds
dc_current_limit_ua from the matching map entry. A DT lacking the
all-zero entry is rejected with -EINVAL because otherwise the
reported INPUT_CURRENT_LIMIT could disagree with the mux state
until a set_property write picks a real value.

Negative INPUT_CURRENT_LIMIT requests are rejected at the
set_property entry: val->intval is signed, the set_*_current_limit()
helpers take a u32, and a negative cast would silently widen to a
huge unsigned value, bypass the upper-bound guard and program the
maximum permitted current.

Signed-off-by: Herman van Hazendonk <github.com@herrie.org>
---
 drivers/power/supply/max8903_charger.c | 415 +++++++++++++++++++++++++++++++--
 1 file changed, 398 insertions(+), 17 deletions(-)

diff --git a/drivers/power/supply/max8903_charger.c b/drivers/power/supply/max8903_charger.c
index 45fbaad6c647..97bd85f87eae 100644
--- a/drivers/power/supply/max8903_charger.c
+++ b/drivers/power/supply/max8903_charger.c
@@ -9,11 +9,29 @@
 #include <linux/gpio/consumer.h>
 #include <linux/interrupt.h>
 #include <linux/module.h>
+#include <linux/mutex.h>
 #include <linux/of.h>
+#include <linux/property.h>
 #include <linux/slab.h>
 #include <linux/power_supply.h>
 #include <linux/platform_device.h>
 
+/*
+ * IUSB pin: hardcoded by silicon to 100 mA (low) / 500 mA (high).
+ * MAX8903A/B/C/D/E/F/G/H/I datasheet, "Pin Description" table:
+ *   "USB Current-Limit Set Input. Drive IUSB logic-low to set the
+ *    USB current limit to 100mA. Drive IUSB logic-high to set the
+ *    USB current limit to 500mA."
+ * Not a board parameter - never DT-configurable.
+ */
+#define MAX8903_USB_CURRENT_LIMIT_LOW_UA	100000
+#define MAX8903_USB_CURRENT_LIMIT_HIGH_UA	500000
+
+struct max8903_current_limit_mapping {
+	u32 limit_ua;		/* Current limit in microamps */
+	u32 gpio_value;		/* GPIO bit pattern */
+};
+
 struct max8903_data {
 	struct device *dev;
 	struct power_supply *psy;
@@ -31,6 +49,25 @@ struct max8903_data {
 	struct gpio_desc *flt; /* Fault output */
 	struct gpio_desc *dcm; /* Current-Limit Mode input (1: DC, 2: USB) */
 	struct gpio_desc *usus; /* USB Suspend Input (1: suspended) */
+
+	/* DC current limit control (ISET pins) */
+	struct gpio_descs *dc_current_limit_gpios;
+	struct max8903_current_limit_mapping *dc_current_limit_map;
+	u32 dc_current_limit_map_size;
+	u32 dc_current_limit_ua;	/* Current setting in uA */
+
+	/* USB current limit control (IUSB pin) */
+	struct gpio_desc *usb_current_limit_gpio;
+	u32 usb_current_limit_ua;	/* Current setting in uA */
+
+	/*
+	 * Serialises ta_in / usb_in updates against
+	 * max8903_set_property() which steers the current-limit write to
+	 * the DC or USB path based on which source is currently online.
+	 * The IRQ handlers are requested with IRQF_ONESHOT (threaded), so
+	 * a sleepable mutex is the right primitive in both contexts.
+	 */
+	struct mutex source_lock;
 	bool fault;
 	bool usb_in;
 	bool ta_in;
@@ -40,6 +77,7 @@ static enum power_supply_property max8903_charger_props[] = {
 	POWER_SUPPLY_PROP_STATUS, /* Charger status output */
 	POWER_SUPPLY_PROP_ONLINE, /* External power source */
 	POWER_SUPPLY_PROP_HEALTH, /* Fault or OK */
+	POWER_SUPPLY_PROP_INPUT_CURRENT_LIMIT, /* Input current limit */
 };
 
 static int max8903_get_property(struct power_supply *psy,
@@ -47,6 +85,24 @@ static int max8903_get_property(struct power_supply *psy,
 		union power_supply_propval *val)
 {
 	struct max8903_data *data = power_supply_get_drvdata(psy);
+	bool ta_in, usb_in;
+	u32 dc_limit, usb_limit;
+
+	/*
+	 * Snapshot the source flags and current-limit settings under the
+	 * source_lock that the IRQs (max8903_dcin / max8903_usbin) and
+	 * max8903_set_property() take when updating them, so we never
+	 * observe a torn pair of (source-online flag, current-limit ua).
+	 * The gpiod_get_value() reads further down deliberately stay
+	 * outside the lock — they hit the GPIO controller, not driver
+	 * state, and the IRQs do not touch them under the lock either.
+	 */
+	mutex_lock(&data->source_lock);
+	ta_in = data->ta_in;
+	usb_in = data->usb_in;
+	dc_limit = data->dc_current_limit_ua;
+	usb_limit = data->usb_current_limit_ua;
+	mutex_unlock(&data->source_lock);
 
 	switch (psp) {
 	case POWER_SUPPLY_PROP_STATUS:
@@ -55,21 +111,42 @@ static int max8903_get_property(struct power_supply *psy,
 			if (gpiod_get_value(data->chg))
 				/* CHG asserted */
 				val->intval = POWER_SUPPLY_STATUS_CHARGING;
-			else if (data->usb_in || data->ta_in)
+			else if (usb_in || ta_in)
 				val->intval = POWER_SUPPLY_STATUS_NOT_CHARGING;
 			else
 				val->intval = POWER_SUPPLY_STATUS_DISCHARGING;
 		}
 		break;
 	case POWER_SUPPLY_PROP_ONLINE:
-		val->intval = 0;
-		if (data->usb_in || data->ta_in)
-			val->intval = 1;
+		val->intval = (ta_in || usb_in) ? 1 : 0;
 		break;
 	case POWER_SUPPLY_PROP_HEALTH:
-		val->intval = POWER_SUPPLY_HEALTH_GOOD;
-		if (data->fault)
-			val->intval = POWER_SUPPLY_HEALTH_UNSPEC_FAILURE;
+		/*
+		 * data->fault is a single bool toggled from one IRQ
+		 * handler, so a torn read is not possible; no need to
+		 * extend source_lock coverage here.
+		 */
+		val->intval = data->fault ? POWER_SUPPLY_HEALTH_UNSPEC_FAILURE
+					  : POWER_SUPPLY_HEALTH_GOOD;
+		break;
+	case POWER_SUPPLY_PROP_INPUT_CURRENT_LIMIT:
+		/*
+		 * Hardware prioritises DC over USB - when ta_in is asserted
+		 * the part draws from the DC input regardless of USB state.
+		 * So always report the DC-side limit when DC is online, and
+		 * refuse rather than silently fall back to the USB cap if
+		 * the DC GPIOs are not configured - that would mis-describe
+		 * the active source. Same policy applies in the set path.
+		 */
+		if (ta_in) {
+			if (!data->dc_current_limit_gpios)
+				return -ENODATA;
+			val->intval = dc_limit;
+		} else if (usb_in && data->usb_current_limit_gpio) {
+			val->intval = usb_limit;
+		} else {
+			return -ENODATA;
+		}
 		break;
 	default:
 		return -EINVAL;
@@ -78,6 +155,144 @@ static int max8903_get_property(struct power_supply *psy,
 	return 0;
 }
 
+static int max8903_set_dc_current_limit(struct max8903_data *data, u32 limit_ua)
+{
+	int i, best_idx = -1;
+	/*
+	 * The mapping's gpio_value fits in the lowest ndescs bits of one
+	 * unsigned long (parse_dc_current_limit enforces ndescs < 32 and
+	 * gpio_value < BIT(ndescs)); a single-word bitmap is sufficient
+	 * on both 32- and 64-bit builds. Don't use bitmap_from_arr32() -
+	 * that macro reinterprets its source pointer as unsigned long on
+	 * 64-bit and would read past the on-stack u32.
+	 */
+	DECLARE_BITMAP(values, BITS_PER_TYPE(u32));
+
+	if (!data->dc_current_limit_gpios)
+		return -EOPNOTSUPP;
+
+	/*
+	 * Find the highest supported current <= requested. Use a -1
+	 * "not found" sentinel rather than tracking best_limit > 0 so
+	 * that a 0 uA entry (used to disable charging) can be selected
+	 * by a 0 uA request.
+	 */
+	for (i = 0; i < data->dc_current_limit_map_size; i++) {
+		if (data->dc_current_limit_map[i].limit_ua > limit_ua)
+			continue;
+		if (best_idx < 0 ||
+		    data->dc_current_limit_map[i].limit_ua >
+				data->dc_current_limit_map[best_idx].limit_ua)
+			best_idx = i;
+	}
+
+	if (best_idx < 0)
+		return -EINVAL;
+
+	bitmap_zero(values, BITS_PER_TYPE(u32));
+	values[0] = data->dc_current_limit_map[best_idx].gpio_value;
+	gpiod_set_array_value_cansleep(data->dc_current_limit_gpios->ndescs,
+				       data->dc_current_limit_gpios->desc,
+				       data->dc_current_limit_gpios->info,
+				       values);
+
+	data->dc_current_limit_ua = data->dc_current_limit_map[best_idx].limit_ua;
+	dev_dbg(data->dev, "DC current limit set to %u uA\n",
+		data->dc_current_limit_ua);
+
+	return 0;
+}
+
+static int max8903_set_usb_current_limit(struct max8903_data *data, u32 limit_ua)
+{
+	u32 selected;
+	int gpio_val;
+
+	if (!data->usb_current_limit_gpio)
+		return -EOPNOTSUPP;
+
+	/*
+	 * IUSB is a single-bit input with two silicon-fixed settings;
+	 * pick HIGH (500 mA) iff the caller's cap can absorb it, else
+	 * LOW (100 mA), else refuse rather than program a higher current
+	 * than the request allows.
+	 */
+	if (limit_ua >= MAX8903_USB_CURRENT_LIMIT_HIGH_UA) {
+		selected = MAX8903_USB_CURRENT_LIMIT_HIGH_UA;
+		gpio_val = 1;
+	} else if (limit_ua >= MAX8903_USB_CURRENT_LIMIT_LOW_UA) {
+		selected = MAX8903_USB_CURRENT_LIMIT_LOW_UA;
+		gpio_val = 0;
+	} else {
+		return -EINVAL;
+	}
+
+	gpiod_set_value_cansleep(data->usb_current_limit_gpio, gpio_val);
+	data->usb_current_limit_ua = selected;
+
+	dev_dbg(data->dev, "USB current limit set to %u uA\n",
+		data->usb_current_limit_ua);
+
+	return 0;
+}
+
+static int max8903_set_property(struct power_supply *psy,
+		enum power_supply_property psp,
+		const union power_supply_propval *val)
+{
+	struct max8903_data *data = power_supply_get_drvdata(psy);
+	int ret;
+
+	switch (psp) {
+	case POWER_SUPPLY_PROP_INPUT_CURRENT_LIMIT:
+		/*
+		 * val->intval is signed; the set_*_current_limit() helpers
+		 * take a u32. Reject negatives explicitly so a negative
+		 * request cannot widen into a huge unsigned value, bypass
+		 * the "limit <= cap" bounds check inside the helper, and
+		 * silently program the maximum permitted current.
+		 */
+		if (val->intval < 0)
+			return -EINVAL;
+		/*
+		 * Hold source_lock across the source check and the
+		 * resulting hardware write so the IRQ handler cannot
+		 * flip ta_in/usb_in between them and have us program the
+		 * limit for a source that has just gone offline. Mirror
+		 * the DC-priority policy of the get path: if DC is online
+		 * route to the DC helper (refuse if DC GPIOs aren't
+		 * configured) rather than fall through to USB.
+		 */
+		mutex_lock(&data->source_lock);
+		if (data->ta_in)
+			ret = data->dc_current_limit_gpios ?
+			      max8903_set_dc_current_limit(data, val->intval) :
+			      -ENODEV;
+		else if (data->usb_in && data->usb_current_limit_gpio)
+			ret = max8903_set_usb_current_limit(data, val->intval);
+		else
+			ret = -EINVAL;
+		mutex_unlock(&data->source_lock);
+		return ret;
+	default:
+		return -EINVAL;
+	}
+}
+
+static int max8903_property_is_writeable(struct power_supply *psy,
+		enum power_supply_property psp)
+{
+	struct max8903_data *data = power_supply_get_drvdata(psy);
+
+	switch (psp) {
+	case POWER_SUPPLY_PROP_INPUT_CURRENT_LIMIT:
+		return data->dc_current_limit_gpios ||
+		       data->usb_current_limit_gpio;
+	default:
+		return 0;
+	}
+}
+
 static irqreturn_t max8903_dcin(int irq, void *_data)
 {
 	struct max8903_data *data = _data;
@@ -91,10 +306,21 @@ static irqreturn_t max8903_dcin(int irq, void *_data)
 	 * library as the line should be flagged GPIO_ACTIVE_LOW in the device
 	 * tree.
 	 */
+	/*
+	 * Hold source_lock across the full read-modify-evaluate block:
+	 *   - so a concurrent max8903_set_property() sees a consistent
+	 *     state (lock release would otherwise expose a window where
+	 *     data->ta_in is updated but the cen/dcm writes still pend);
+	 *   - so the cen enable calculation reads a stable data->usb_in
+	 *     rather than racing with max8903_usbin() and writing the
+	 *     wrong enable state.
+	 */
+	mutex_lock(&data->source_lock);
 	ta_in = gpiod_get_value(data->dok);
-
-	if (ta_in == data->ta_in)
+	if (ta_in == data->ta_in) {
+		mutex_unlock(&data->source_lock);
 		return IRQ_HANDLED;
+	}
 
 	data->ta_in = ta_in;
 
@@ -119,9 +345,6 @@ static irqreturn_t max8903_dcin(int irq, void *_data)
 		gpiod_set_value(data->cen, val);
 	}
 
-	dev_dbg(data->dev, "TA(DC-IN) Charger %s.\n", ta_in ?
-			"Connected" : "Disconnected");
-
 	old_type = data->psy_desc.type;
 
 	if (data->ta_in)
@@ -130,6 +353,10 @@ static irqreturn_t max8903_dcin(int irq, void *_data)
 		data->psy_desc.type = POWER_SUPPLY_TYPE_USB;
 	else
 		data->psy_desc.type = POWER_SUPPLY_TYPE_BATTERY;
+	mutex_unlock(&data->source_lock);
+
+	dev_dbg(data->dev, "TA(DC-IN) Charger %s.\n", ta_in ?
+			"Connected" : "Disconnected");
 
 	if (old_type != data->psy_desc.type)
 		power_supply_changed(data->psy);
@@ -150,10 +377,13 @@ static irqreturn_t max8903_usbin(int irq, void *_data)
 	 * library as the line should be flagged GPIO_ACTIVE_LOW in the device
 	 * tree.
 	 */
+	/* See max8903_dcin(): hold the lock across the full update. */
+	mutex_lock(&data->source_lock);
 	usb_in = gpiod_get_value(data->uok);
-
-	if (usb_in == data->usb_in)
+	if (usb_in == data->usb_in) {
+		mutex_unlock(&data->source_lock);
 		return IRQ_HANDLED;
+	}
 
 	data->usb_in = usb_in;
 
@@ -176,9 +406,6 @@ static irqreturn_t max8903_usbin(int irq, void *_data)
 		gpiod_set_value(data->cen, val);
 	}
 
-	dev_dbg(data->dev, "USB Charger %s.\n", usb_in ?
-			"Connected" : "Disconnected");
-
 	old_type = data->psy_desc.type;
 
 	if (data->ta_in)
@@ -187,6 +414,10 @@ static irqreturn_t max8903_usbin(int irq, void *_data)
 		data->psy_desc.type = POWER_SUPPLY_TYPE_USB;
 	else
 		data->psy_desc.type = POWER_SUPPLY_TYPE_BATTERY;
+	mutex_unlock(&data->source_lock);
+
+	dev_dbg(data->dev, "USB Charger %s.\n", usb_in ?
+			"Connected" : "Disconnected");
 
 	if (old_type != data->psy_desc.type)
 		power_supply_changed(data->psy);
@@ -221,6 +452,145 @@ static irqreturn_t max8903_fault(int irq, void *_data)
 	return IRQ_HANDLED;
 }
 
+static int max8903_parse_dc_current_limit(struct platform_device *pdev,
+					  struct max8903_data *data)
+{
+	struct device *dev = &pdev->dev;
+	int ret, i, map_size;
+	u32 *map;
+
+	data->dc_current_limit_gpios = devm_gpiod_get_array_optional(dev,
+					"dc-current-limit", GPIOD_OUT_LOW);
+	if (IS_ERR(data->dc_current_limit_gpios))
+		return dev_err_probe(dev, PTR_ERR(data->dc_current_limit_gpios),
+				     "failed to get DC current limit GPIOs");
+
+	if (!data->dc_current_limit_gpios)
+		return 0;	/* Optional feature not present */
+
+	/*
+	 * gpio_value entries below are bit patterns indexed into the
+	 * dc-current-limit GPIO array. The driver represents them in
+	 * a single unsigned long for gpiod_set_array_value_cansleep(),
+	 * and BIT(ndescs) further down assumes ndescs fits in a u32
+	 * shift; reject pathological DTs at parse time instead of
+	 * relying on undefined-behaviour-free dtschema. The binding
+	 * already caps maxItems at 4 so this is purely defensive.
+	 */
+	if (data->dc_current_limit_gpios->ndescs >= BITS_PER_TYPE(u32)) {
+		dev_err(dev, "dc-current-limit-gpios: %u GPIOs exceeds %u-bit cap\n",
+			data->dc_current_limit_gpios->ndescs,
+			(unsigned int)BITS_PER_TYPE(u32));
+		return -EINVAL;
+	}
+
+	/* Parse mapping: pairs of (current_ua, gpio_value) */
+	map_size = device_property_count_u32(dev, "dc-current-limit-mapping");
+	if (map_size <= 0 || map_size % 2) {
+		dev_err(dev, "invalid dc-current-limit-mapping\n");
+		return -EINVAL;
+	}
+
+	/*
+	 * map[] is a scratch buffer used only inside this function to
+	 * read the property and unpack it into data->dc_current_limit_map.
+	 * Use a plain kmalloc + kfree rather than devm_*: there is no
+	 * reason to keep the raw mirror around for the lifetime of the
+	 * device.
+	 */
+	map = kmalloc_array(map_size, sizeof(*map), GFP_KERNEL);
+	if (!map)
+		return -ENOMEM;
+
+	ret = device_property_read_u32_array(dev, "dc-current-limit-mapping",
+					     map, map_size);
+	if (ret) {
+		dev_err(dev, "failed to read dc-current-limit-mapping\n");
+		kfree(map);
+		return ret;
+	}
+
+	data->dc_current_limit_map_size = map_size / 2;
+	data->dc_current_limit_map = devm_kcalloc(dev,
+					data->dc_current_limit_map_size,
+					sizeof(*data->dc_current_limit_map),
+					GFP_KERNEL);
+	if (!data->dc_current_limit_map) {
+		kfree(map);
+		return -ENOMEM;
+	}
+
+	for (i = 0; i < data->dc_current_limit_map_size; i++) {
+		u32 gpio_value = map[i * 2 + 1];
+
+		/*
+		 * gpio_value is the bitmap programmed across the
+		 * dc-current-limit GPIOs, so it cannot represent more
+		 * bits than the GPIO array width. A larger value would
+		 * be silently truncated by gpiod_set_array_value() and
+		 * select the wrong limit; reject it at parse time so
+		 * the bogus DT is visible to the integrator.
+		 */
+		if (gpio_value >= BIT(data->dc_current_limit_gpios->ndescs)) {
+			dev_err(dev,
+				"dc-current-limit-mapping entry %d: gpio_value 0x%x exceeds %u-GPIO range\n",
+				i, gpio_value,
+				data->dc_current_limit_gpios->ndescs);
+			kfree(map);
+			return -EINVAL;
+		}
+		data->dc_current_limit_map[i].limit_ua = map[i * 2];
+		data->dc_current_limit_map[i].gpio_value = gpio_value;
+	}
+
+	kfree(map);
+
+	/*
+	 * devm_gpiod_get_array_optional() above asked for GPIOD_OUT_LOW,
+	 * so the hardware mux starts at gpio_value 0. Require the DT
+	 * mapping to include a gpio_value=0 entry so the software
+	 * current-limit state has a definite initial value matching the
+	 * hardware. Without this entry we would have to guess and the
+	 * reported INPUT_CURRENT_LIMIT could disagree with what the
+	 * mux is actually wired to until a set_property write picks a
+	 * real value.
+	 */
+	for (i = 0; i < data->dc_current_limit_map_size; i++)
+		if (data->dc_current_limit_map[i].gpio_value == 0)
+			break;
+	if (i == data->dc_current_limit_map_size) {
+		dev_err(dev,
+			"dc-current-limit-mapping must include a gpio_value=0 entry to describe the boot-time mux state\n");
+		return -EINVAL;
+	}
+	data->dc_current_limit_ua = data->dc_current_limit_map[i].limit_ua;
+
+	dev_dbg(dev, "DC current limit control: %d levels available, initial %u uA\n",
+		data->dc_current_limit_map_size, data->dc_current_limit_ua);
+
+	return 0;
+}
+
+static int max8903_parse_usb_current_limit(struct platform_device *pdev,
+					   struct max8903_data *data)
+{
+	struct device *dev = &pdev->dev;
+
+	data->usb_current_limit_gpio = devm_gpiod_get_optional(dev,
+					"usb-current-limit", GPIOD_OUT_LOW);
+	if (IS_ERR(data->usb_current_limit_gpio))
+		return dev_err_probe(dev, PTR_ERR(data->usb_current_limit_gpio),
+				     "failed to get USB current limit GPIO");
+
+	if (!data->usb_current_limit_gpio)
+		return 0;	/* Optional feature not present */
+
+	/* Start at low current (IUSB low = 100 mA) for safety */
+	data->usb_current_limit_ua = MAX8903_USB_CURRENT_LIMIT_LOW_UA;
+
+	return 0;
+}
+
 static int max8903_setup_gpios(struct platform_device *pdev)
 {
 	struct max8903_data *data = platform_get_drvdata(pdev);
@@ -335,17 +705,28 @@ static int max8903_probe(struct platform_device *pdev)
 		return -ENOMEM;
 
 	data->dev = dev;
+	mutex_init(&data->source_lock);
 	platform_set_drvdata(pdev, data);
 
 	ret = max8903_setup_gpios(pdev);
 	if (ret)
 		return ret;
 
+	ret = max8903_parse_dc_current_limit(pdev, data);
+	if (ret)
+		return ret;
+
+	ret = max8903_parse_usb_current_limit(pdev, data);
+	if (ret)
+		return ret;
+
 	data->psy_desc.name = "max8903_charger";
 	data->psy_desc.type = (data->ta_in) ? POWER_SUPPLY_TYPE_MAINS :
 			((data->usb_in) ? POWER_SUPPLY_TYPE_USB :
 			 POWER_SUPPLY_TYPE_BATTERY);
 	data->psy_desc.get_property = max8903_get_property;
+	data->psy_desc.set_property = max8903_set_property;
+	data->psy_desc.property_is_writeable = max8903_property_is_writeable;
 	data->psy_desc.properties = max8903_charger_props;
 	data->psy_desc.num_properties = ARRAY_SIZE(max8903_charger_props);
 

-- 
2.43.0

