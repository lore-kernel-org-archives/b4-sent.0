From: Martin Oberleiter <martin.oberleiter@netixx.it>
Date: Fri, 30 Oct 2026 07:37:25 +0100
Subject: [PATCH 2/2] HID: steelseries: Add Rival 3 Wireless battery
 reporting
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261030-rival3-battery-v1-2-6b1feeaf1f52@netixx.it>
References: <20261030-rival3-battery-v1-0-6b1feeaf1f52@netixx.it>
In-Reply-To: <20261030-rival3-battery-v1-0-6b1feeaf1f52@netixx.it>
To: Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Martin Oberleiter <martin.oberleiter@netixx.it>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793342246; l=14901;
 i=martin.oberleiter@netixx.it; s=20261029; h=from:subject:message-id;
 bh=PZG7BR4VnnxiEqJSq5UlTMPwal7syUluUFLwp9/veAg=;
 b=fZQLe3a4n5wpsGxZU8Z4JhxrFp2w4v9VLbRUC3iClZU5NjVwv5OWjwsN8TkU7k2TiTyjKClWW
 Lxif2wMQ0nPB2LykkqBUuWMdfKU9CmlnILrtcFAf1NMTRVFM2S5zDnf
X-Developer-Key: i=martin.oberleiter@netixx.it; a=ed25519;
 pk=yZvkAuAsIiJ76LEGGTR3TI7+Xjw7lGN1dK6jcv72XZo=
X-Endpoint-Received: by B4 Relay for martin.oberleiter@netixx.it/20261029 with auth_id=1358
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Rival 3 Wireless mouse in 2.4 GHz mode (receiver 1038:1830) reports
its battery level on request: an output report AA 01 on the vendor
interface (interface 3) is answered through the receiver about 80 ms
later by an input report holding the level in percent in the first
byte and a charging flag in the third, followed by zero padding. While
the mouse is off or asleep, the receiver does not answer. This is the
protocol rivalcfg uses.

Register a power supply on that interface and poll it from a delayed
work: every 10 minutes while the mouse answers, every minute while it
does not, and right after resume. As the reply carries no command echo,
it is only accepted while one is awaited and if it has the expected
shape. If the mouse does not answer within 500 ms, the status becomes
unknown and the last level is kept. Until the first reply, report 100%
with an unknown status, as the Arctis headset support does, to avoid a
spurious low battery warning. The mouse's other interfaces are left
closed until userspace opens them, as with hid-generic.

The status polling in hid-steelseries-arctis is not reused: it is built
around headsets with sync and async interfaces and a connection status,
while the mouse needs a single request with a reply timeout.

Userspace talking to interface 3 through hidraw at the same time (e.g.
rivalcfg) can see the driver's replies, and a reply to its own command
with the same shape would be taken as a battery reply.

Tested on a Rival 3 Wireless with its 2.4 GHz receiver: the battery
shows up with the level the mouse reports, the status becomes unknown
while the mouse is off, and the level is back within a minute of
switching it on. Mouse input is unaffected.

The protocol was verified on the device and the driver and this
changelog were written with the help of an AI coding assistant (Claude
Code).

Signed-off-by: Martin Oberleiter <martin.oberleiter@netixx.it>
---
 drivers/hid/Kconfig           |   4 +-
 drivers/hid/hid-ids.h         |   1 +
 drivers/hid/hid-steelseries.c | 277 +++++++++++++++++++++++++++++++++++++++++-
 3 files changed, 276 insertions(+), 6 deletions(-)

diff --git a/drivers/hid/Kconfig b/drivers/hid/Kconfig
index 4d48da4f5..cd52f7304 100644
--- a/drivers/hid/Kconfig
+++ b/drivers/hid/Kconfig
@@ -1216,9 +1216,9 @@ config HID_STEELSERIES
 	depends on USB_HID
 	select POWER_SUPPLY
 	help
-	Support for Steelseries SRW-S1 steering wheel, and the Steelseries
+	Support for Steelseries SRW-S1 steering wheel, the Steelseries
 	Arctis 1 Wireless for XBox, Arctis 7 (2018), Arctis 9, and Arctis
-	Nova headsets.
+	Nova headsets, and battery reporting for the Rival 3 Wireless mouse.
 
 config HID_SUNPLUS
 	tristate "Sunplus wireless desktop"
diff --git a/drivers/hid/hid-ids.h b/drivers/hid/hid-ids.h
index 91319aa65..ca19f00eb 100644
--- a/drivers/hid/hid-ids.h
+++ b/drivers/hid/hid-ids.h
@@ -1437,6 +1437,7 @@
 #define USB_DEVICE_ID_STEELSERIES_ARCTIS_NOVA_7_X_GEN2_3	0x22ad
 #define USB_DEVICE_ID_STEELSERIES_MSI_KLC   0x1122
 #define USB_DEVICE_ID_STEELSERIES_MSI_ALC   0x1161
+#define USB_DEVICE_ID_STEELSERIES_RIVAL_3_WIRELESS	0x1830
 
 #define USB_VENDOR_ID_SUN		0x0430
 #define USB_DEVICE_ID_RARITAN_KVM_DONGLE	0xcdab
diff --git a/drivers/hid/hid-steelseries.c b/drivers/hid/hid-steelseries.c
index 7292da031..9fa70d21f 100644
--- a/drivers/hid/hid-steelseries.c
+++ b/drivers/hid/hid-steelseries.c
@@ -8,19 +8,25 @@
 /*
  */
 
+#include <linux/completion.h>
 #include <linux/device.h>
 #include <linux/dmi.h>
 #include <linux/hid.h>
 #include <linux/module.h>
+#include <linux/power_supply.h>
 #include <linux/usb.h>
 #include <linux/leds.h>
 #include <linux/led-class-multicolor.h>
 #include <linux/slab.h>
+#include <linux/string.h>
+#include <linux/spinlock.h>
+#include <linux/workqueue.h>
 
 #include "hid-ids.h"
 
 #define STEELSERIES_SRWS1		BIT(0)
 #define STEELSERIES_MSI_RGB		BIT(1)
+#define STEELSERIES_RIVAL3_WIRELESS	BIT(2)
 
 #define STEELSERIES_MSI_RGB_WVALUE 0x0300 /* Feature report, ID 0 */
 #define STEELSERIES_MSI_RGB_REPORT_LEN 524
@@ -42,6 +48,18 @@ struct steelseries_device {
 	struct mutex rgb_lock; /* protects rgb_buf */
 	u8 *rgb_buf;
 #endif
+
+	/* Rival 3 Wireless battery, on the vendor interface only */
+	bool battery_iface;
+	struct power_supply *battery;
+	struct power_supply_desc battery_desc;
+	struct delayed_work battery_work;
+	struct completion battery_reply;
+	spinlock_t battery_lock; /* protects the fields below */
+	bool battery_awaiting_reply;
+	bool battery_online;
+	bool battery_charging;
+	u8 battery_capacity;
 };
 
 #if IS_BUILTIN(CONFIG_LEDS_CLASS) || \
@@ -564,6 +582,206 @@ static int steelseries_msi_rgb_register(struct steelseries_device *sd)
 }
 #endif
 
+/*
+ * Rival 3 Wireless (2.4 GHz receiver): the battery level is read with an
+ * output report AA 01 on the vendor interface. The mouse answers through
+ * the receiver about 80 ms later with an input report whose first byte is
+ * the level in percent and whose third byte is the charging flag. There is
+ * no command echo, so a reply is only accepted while one is awaited. While
+ * the mouse is off or asleep, the receiver does not answer at all.
+ */
+#define STEELSERIES_RIVAL3_WIRELESS_IFACE		3
+#define STEELSERIES_RIVAL3_WIRELESS_REPLY_TIMEOUT_MS	500
+#define STEELSERIES_RIVAL3_WIRELESS_POLL_ONLINE_MS	(10 * 60 * 1000)
+#define STEELSERIES_RIVAL3_WIRELESS_POLL_OFFLINE_MS	(60 * 1000)
+
+static bool steelseries_rival3_is_battery_iface(struct hid_device *hdev)
+{
+	struct usb_interface *intf = steelseries_hid_to_usb_intf(hdev);
+
+	return intf && intf->cur_altsetting->desc.bInterfaceNumber ==
+		STEELSERIES_RIVAL3_WIRELESS_IFACE;
+}
+
+static const enum power_supply_property steelseries_rival3_battery_props[] = {
+	POWER_SUPPLY_PROP_PRESENT,
+	POWER_SUPPLY_PROP_STATUS,
+	POWER_SUPPLY_PROP_SCOPE,
+	POWER_SUPPLY_PROP_CAPACITY,
+	POWER_SUPPLY_PROP_MODEL_NAME,
+	POWER_SUPPLY_PROP_MANUFACTURER,
+};
+
+static int steelseries_rival3_battery_get_property(struct power_supply *psy,
+						   enum power_supply_property psp,
+						   union power_supply_propval *val)
+{
+	struct steelseries_device *sd = power_supply_get_drvdata(psy);
+	unsigned long flags;
+	int ret = 0;
+
+	spin_lock_irqsave(&sd->battery_lock, flags);
+	switch (psp) {
+	case POWER_SUPPLY_PROP_PRESENT:
+		val->intval = 1;
+		break;
+	case POWER_SUPPLY_PROP_STATUS:
+		if (!sd->battery_online)
+			val->intval = POWER_SUPPLY_STATUS_UNKNOWN;
+		else if (sd->battery_charging)
+			val->intval = POWER_SUPPLY_STATUS_CHARGING;
+		else
+			val->intval = POWER_SUPPLY_STATUS_DISCHARGING;
+		break;
+	case POWER_SUPPLY_PROP_SCOPE:
+		val->intval = POWER_SUPPLY_SCOPE_DEVICE;
+		break;
+	case POWER_SUPPLY_PROP_CAPACITY:
+		val->intval = sd->battery_capacity;
+		break;
+	case POWER_SUPPLY_PROP_MODEL_NAME:
+		val->strval = "Rival 3 Wireless";
+		break;
+	case POWER_SUPPLY_PROP_MANUFACTURER:
+		val->strval = "SteelSeries";
+		break;
+	default:
+		ret = -EINVAL;
+		break;
+	}
+	spin_unlock_irqrestore(&sd->battery_lock, flags);
+
+	return ret;
+}
+
+static void steelseries_rival3_battery_work(struct work_struct *work)
+{
+	struct steelseries_device *sd = container_of(work,
+			struct steelseries_device, battery_work.work);
+	static const u8 request[] = { 0x00, 0xaa, 0x01 }; /* report ID 0 */
+	bool was_online, was_charging, online, changed;
+	unsigned long flags, timeout;
+	u8 old_capacity;
+	u8 *buf;
+	int ret;
+
+	spin_lock_irqsave(&sd->battery_lock, flags);
+	was_online = sd->battery_online;
+	was_charging = sd->battery_charging;
+	old_capacity = sd->battery_capacity;
+	spin_unlock_irqrestore(&sd->battery_lock, flags);
+
+	buf = kmemdup(request, sizeof(request), GFP_KERNEL);
+	if (!buf) {
+		ret = -ENOMEM;
+		goto update;
+	}
+
+	spin_lock_irqsave(&sd->battery_lock, flags);
+	reinit_completion(&sd->battery_reply);
+	sd->battery_awaiting_reply = true;
+	spin_unlock_irqrestore(&sd->battery_lock, flags);
+
+	ret = hid_hw_raw_request(sd->hdev, 0x00, buf, sizeof(request),
+				 HID_OUTPUT_REPORT, HID_REQ_SET_REPORT);
+	kfree(buf);
+	if (ret >= 0) {
+		timeout = msecs_to_jiffies(STEELSERIES_RIVAL3_WIRELESS_REPLY_TIMEOUT_MS);
+		ret = wait_for_completion_timeout(&sd->battery_reply, timeout) ? 0 : -ETIMEDOUT;
+	}
+
+update:
+	spin_lock_irqsave(&sd->battery_lock, flags);
+	/* A reply may still have arrived right after the timeout. */
+	if (ret && sd->battery_awaiting_reply) {
+		/* Keep the last level; the mouse is off or asleep. */
+		sd->battery_awaiting_reply = false;
+		sd->battery_online = false;
+	} else {
+		ret = 0;
+	}
+	online = sd->battery_online;
+	changed = online != was_online ||
+		  sd->battery_charging != was_charging ||
+		  sd->battery_capacity != old_capacity;
+	spin_unlock_irqrestore(&sd->battery_lock, flags);
+
+	if (ret)
+		hid_dbg(sd->hdev, "No battery reply: %d\n", ret);
+	if (changed)
+		power_supply_changed(sd->battery);
+
+	schedule_delayed_work(&sd->battery_work, msecs_to_jiffies(online ?
+			STEELSERIES_RIVAL3_WIRELESS_POLL_ONLINE_MS :
+			STEELSERIES_RIVAL3_WIRELESS_POLL_OFFLINE_MS));
+}
+
+static int steelseries_rival3_battery_register(struct steelseries_device *sd)
+{
+	struct power_supply_config battery_cfg = { .drv_data = sd, };
+	struct hid_device *hdev = sd->hdev;
+	struct power_supply *battery;
+
+	spin_lock_init(&sd->battery_lock);
+	init_completion(&sd->battery_reply);
+	INIT_DELAYED_WORK(&sd->battery_work, steelseries_rival3_battery_work);
+	/* Avoid a 0% warning before the first reply; status stays unknown. */
+	sd->battery_capacity = 100;
+
+	sd->battery_desc.type = POWER_SUPPLY_TYPE_BATTERY;
+	sd->battery_desc.properties = steelseries_rival3_battery_props;
+	sd->battery_desc.num_properties = ARRAY_SIZE(steelseries_rival3_battery_props);
+	sd->battery_desc.get_property = steelseries_rival3_battery_get_property;
+	sd->battery_desc.name = devm_kasprintf(&hdev->dev, GFP_KERNEL,
+					       "steelseries_mouse_battery_%s",
+					       hdev->uniq[0] ? hdev->uniq :
+					       dev_name(&hdev->dev));
+	if (!sd->battery_desc.name)
+		return -ENOMEM;
+
+	battery = devm_power_supply_register(&hdev->dev, &sd->battery_desc,
+					     &battery_cfg);
+	if (IS_ERR(battery))
+		return PTR_ERR(battery);
+
+	power_supply_powers(battery, &hdev->dev);
+	sd->battery = battery;
+	sd->battery_iface = true;
+
+	return 0;
+}
+
+static int steelseries_raw_event(struct hid_device *hdev,
+				 struct hid_report *report, u8 *data, int size)
+{
+	struct steelseries_device *sd;
+	unsigned long flags;
+
+	if (hdev->product != USB_DEVICE_ID_STEELSERIES_RIVAL_3_WIRELESS)
+		return 0;
+
+	sd = hid_get_drvdata(hdev);
+	if (!sd || !sd->battery_iface)
+		return 0;
+
+	/* level, 0, charging, then zero padding */
+	if (size < 3 || data[0] > 100 || data[1] ||
+	    memchr_inv(data + 3, 0, size - 3))
+		return 0;
+
+	spin_lock_irqsave(&sd->battery_lock, flags);
+	if (sd->battery_awaiting_reply) {
+		sd->battery_capacity = data[0];
+		sd->battery_charging = data[2];
+		sd->battery_online = true;
+		sd->battery_awaiting_reply = false;
+		complete(&sd->battery_reply);
+	}
+	spin_unlock_irqrestore(&sd->battery_lock, flags);
+
+	return 0;
+}
+
 static int steelseries_probe(struct hid_device *hdev, const struct hid_device_id *id)
 {
 	struct steelseries_device *sd;
@@ -593,17 +811,38 @@ static int steelseries_probe(struct hid_device *hdev, const struct hid_device_id
 		}
 	}
 
+	if (sd->quirks & STEELSERIES_RIVAL3_WIRELESS &&
+	    !steelseries_rival3_is_battery_iface(hdev))
+		sd->quirks &= ~STEELSERIES_RIVAL3_WIRELESS;
+
 	ret = hid_parse(hdev);
 	if (ret)
 		return ret;
 
+	if (sd->quirks & STEELSERIES_RIVAL3_WIRELESS) {
+		ret = steelseries_rival3_battery_register(sd);
+		if (ret) {
+			hid_warn(hdev,
+				 "Failed to register battery: %d, continuing without battery reporting\n",
+				 ret);
+			sd->quirks &= ~STEELSERIES_RIVAL3_WIRELESS;
+		}
+	}
+
 	ret = hid_hw_start(hdev, HID_CONNECT_DEFAULT);
 	if (ret)
 		return ret;
 
-	ret = hid_hw_open(hdev);
-	if (ret)
-		goto err_stop;
+	/* Only the Rival 3 Wireless battery interface needs to stay open. */
+	if (hdev->product != USB_DEVICE_ID_STEELSERIES_RIVAL_3_WIRELESS ||
+	    sd->battery_iface) {
+		ret = hid_hw_open(hdev);
+		if (ret)
+			goto err_stop;
+	}
+
+	if (sd->battery_iface)
+		schedule_delayed_work(&sd->battery_work, msecs_to_jiffies(1000));
 
 	if (sd->quirks & STEELSERIES_MSI_RGB) {
 		ret = steelseries_msi_rgb_register(sd);
@@ -624,6 +863,8 @@ static int steelseries_probe(struct hid_device *hdev, const struct hid_device_id
 
 static void steelseries_remove(struct hid_device *hdev)
 {
+	struct steelseries_device *sd;
+
 	if (hdev->product == USB_DEVICE_ID_STEELSERIES_SRWS1) {
 #if IS_BUILTIN(CONFIG_LEDS_CLASS) || \
     (IS_MODULE(CONFIG_LEDS_CLASS) && IS_MODULE(CONFIG_HID_STEELSERIES))
@@ -632,10 +873,32 @@ static void steelseries_remove(struct hid_device *hdev)
 		return;
 	}
 
-	hid_hw_close(hdev);
+	sd = hid_get_drvdata(hdev);
+	if (sd->battery_iface)
+		cancel_delayed_work_sync(&sd->battery_work);
+
+	if (hdev->product != USB_DEVICE_ID_STEELSERIES_RIVAL_3_WIRELESS ||
+	    sd->battery_iface)
+		hid_hw_close(hdev);
 	hid_hw_stop(hdev);
 }
 
+static int steelseries_resume(struct hid_device *hdev)
+{
+	struct steelseries_device *sd;
+
+	if (hdev->product != USB_DEVICE_ID_STEELSERIES_RIVAL_3_WIRELESS)
+		return 0;
+
+	/* Polls during suspend fail, so do not wait for the next one. */
+	sd = hid_get_drvdata(hdev);
+	if (sd && sd->battery_iface)
+		mod_delayed_work(system_wq, &sd->battery_work,
+				 msecs_to_jiffies(1000));
+
+	return 0;
+}
+
 static const __u8 *steelseries_srws1_report_fixup(struct hid_device *hdev,
 		__u8 *rdesc, unsigned int *rsize)
 {
@@ -656,6 +919,9 @@ static const struct hid_device_id steelseries_devices[] = {
 	{ HID_USB_DEVICE(USB_VENDOR_ID_STEELSERIES, USB_DEVICE_ID_STEELSERIES_SRWS1),
 	  .driver_data = STEELSERIES_SRWS1 },
 
+	{ HID_USB_DEVICE(USB_VENDOR_ID_STEELSERIES, USB_DEVICE_ID_STEELSERIES_RIVAL_3_WIRELESS),
+	  .driver_data = STEELSERIES_RIVAL3_WIRELESS },
+
 #if STEELSERIES_HAS_LEDS_MULTICOLOR
 	{ /* MSI Raider A18 KLC */
 	  HID_USB_DEVICE(USB_VENDOR_ID_STEELSERIES, USB_DEVICE_ID_STEELSERIES_MSI_KLC),
@@ -675,6 +941,9 @@ static struct hid_driver steelseries_driver = {
 	.id_table = steelseries_devices,
 	.probe = steelseries_probe,
 	.remove = steelseries_remove,
+	.raw_event = steelseries_raw_event,
+	.resume = pm_ptr(steelseries_resume),
+	.reset_resume = pm_ptr(steelseries_resume),
 	.report_fixup = steelseries_srws1_report_fixup,
 };
 

-- 
2.56.0

