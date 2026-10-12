From: Bishwa Bhusan Saha <contact@bishwasaha.com>
Date: Tue, 13 Oct 2026 01:45:26 +0530
Subject: [PATCH 4/5] HID: UNCTRL: keep a single battery when a mouse has
 multiple connections
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-b4-unctrl-m1-battery-v1-4-4a50203b7177@bishwasaha.com>
References: <20261013-b4-unctrl-m1-battery-v1-0-4a50203b7177@bishwasaha.com>
In-Reply-To: <20261013-b4-unctrl-m1-battery-v1-0-4a50203b7177@bishwasaha.com>
To: Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Bishwa Bhusan Saha <contact@bishwasaha.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791836132; l=6862;
 i=contact@bishwasaha.com; s=20261012; h=from:subject:message-id;
 bh=4neSlyECLUYXKx9wFRn1EZyvTGTNq9xezXjW9ydiins=;
 b=6tE4RuvClkrqNlfmmIMf5Kusxa236y8Bku47zeIPzc/EqUdDshRsk827bu5e76c1Iuu5M5sLx
 9kpN+A7mqQkDV+wj/xRxzDBQCSP0gvQhqNgVA2Z7VPXczK7Ws+XilgQ
X-Developer-Key: i=contact@bishwasaha.com; a=ed25519;
 pk=bW8B6BzX1VU4IIcYagrb5nNRxBho+rTXaQZ8fLx8CoU=
X-Endpoint-Received: by B4 Relay for contact@bishwasaha.com/20261012 with auth_id=1168
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The UNCTRL RAGE mouse can be connected over its 2.4 GHz dongle and
its wired connection at the same time. Both are visible as separate
devices on lsusb. Without this patch two separate batteries would be
detected in case of a single mouse connected over 2 interfaces. This
patch solves it by registering the power supply only on the connection
that can answer queries and taking it away when that connection goes
away.

Signed-off-by: Bishwa Bhusan Saha <contact@bishwasaha.com>
Assisted-by: GLM:glm-5.3
---
 drivers/hid/hid-unctrl-m1.c | 103 ++++++++++++++++++++++++++++++++++++++------
 1 file changed, 91 insertions(+), 12 deletions(-)

diff --git a/drivers/hid/hid-unctrl-m1.c b/drivers/hid/hid-unctrl-m1.c
index 1e73cad1e..ff15384c0 100644
--- a/drivers/hid/hid-unctrl-m1.c
+++ b/drivers/hid/hid-unctrl-m1.c
@@ -16,9 +16,12 @@
  * answers over the interrupt out endpoint, where the queries go.
  */
 
+#include <linux/cleanup.h>
 #include <linux/device.h>
 #include <linux/hid.h>
+#include <linux/list.h>
 #include <linux/module.h>
+#include <linux/mutex.h>
 #include <linux/power_supply.h>
 #include <linux/slab.h>
 #include <linux/usb.h>
@@ -45,19 +48,27 @@ static const u8 unctrl_battery_query[33] = {
 };
 
 struct unctrl_dev {
+	struct list_head list;
 	struct hid_device *hdev;
 
 	struct power_supply_desc battery_desc;
 	struct power_supply *battery;
 
+	/* raw_event runs in the completion path, so this is a spinlock. */
+	spinlock_t lock;
+
 	struct delayed_work battery_work;
 
 	u8 battery_capacity;
 	u8 mode;
 	bool online;
 	bool wired;
+	bool vendor;
 };
 
+static LIST_HEAD(unctrl_connections);
+static DEFINE_MUTEX(unctrl_lock);
+
 static enum power_supply_property unctrl_battery_props[] = {
 	POWER_SUPPLY_PROP_STATUS,     POWER_SUPPLY_PROP_PRESENT,
 	POWER_SUPPLY_PROP_CAPACITY,   POWER_SUPPLY_PROP_SCOPE,
@@ -74,9 +85,11 @@ static int unctrl_battery_get_property(struct power_supply *psy,
 	u8 capacity, mode;
 	bool online;
 
-	capacity = dev->battery_capacity;
-	mode = dev->mode;
-	online = dev->online;
+	scoped_guard(spinlock_irqsave, &dev->lock) {
+		capacity = dev->battery_capacity;
+		mode = dev->mode;
+		online = dev->online;
+	}
 
 	switch (psp) {
 	case POWER_SUPPLY_PROP_PRESENT:
@@ -148,13 +161,46 @@ static void unctrl_battery_timer_tick(struct work_struct *work)
 			      msecs_to_jiffies(UNCTRL_BATTERY_TIMEOUT_MS));
 }
 
-/* Register the power supply of this connection and start reporting. */
+static struct unctrl_dev *unctrl_battery_owner(void)
+{
+	struct unctrl_dev *dev;
+
+	list_for_each_entry(dev, &unctrl_connections, list) {
+		if (dev->battery)
+			return dev;
+	}
+
+	return NULL;
+}
+
+/*
+ * Register the power supply on the connection the mouse talks over,
+ * a wired connection takes it away from a receiver. Called with
+ * unctrl_lock held.
+ */
 static int unctrl_battery_register(struct unctrl_dev *dev)
 {
 	struct power_supply_config config = { .drv_data = dev };
+	struct unctrl_dev *owner;
 	struct power_supply *battery;
 	int ret;
 
+	owner = unctrl_battery_owner();
+	if (owner == dev || (owner && (!dev->wired || owner->wired)))
+		return 0;
+
+	if (owner) {
+		struct power_supply *owner_battery;
+
+		cancel_delayed_work_sync(&owner->battery_work);
+		/* so a raw_event cannot touch the supply being unregistered */
+		scoped_guard(spinlock_irqsave, &owner->lock) {
+			owner_battery = owner->battery;
+			owner->battery = NULL;
+		}
+		power_supply_unregister(owner_battery);
+	}
+
 	battery = power_supply_register(&dev->hdev->dev, &dev->battery_desc,
 					&config);
 	if (IS_ERR(battery)) {
@@ -166,7 +212,8 @@ static int unctrl_battery_register(struct unctrl_dev *dev)
 	}
 
 	power_supply_powers(battery, &dev->hdev->dev);
-	dev->battery = battery;
+	scoped_guard(spinlock_irqsave, &dev->lock)
+		dev->battery = battery;
 	hid_info(dev->hdev, "%s:battery registered as %s\n", __func__,
 		 dev->battery_desc.name);
 
@@ -223,6 +270,8 @@ static int unctrl_probe(struct hid_device *hdev, const struct hid_device_id *id)
 	dev->battery_capacity = 100;
 	dev->mode = UNCTRL_MODE_RECEIVER;
 	dev->wired = hdev->product == USB_DEVICE_ID_UNCTRL_M1_WIRED;
+	dev->vendor = vendor;
+	spin_lock_init(&dev->lock);
 
 	dev->battery_desc.name = devm_kasprintf(&hdev->dev, GFP_KERNEL,
 						"unctrl-m1-%04x-battery",
@@ -249,13 +298,20 @@ static int unctrl_probe(struct hid_device *hdev, const struct hid_device_id *id)
 
 	hid_set_drvdata(hdev, dev);
 
+	mutex_lock(&unctrl_lock);
+	list_add_tail(&dev->list, &unctrl_connections);
 	ret = unctrl_battery_register(dev);
+	mutex_unlock(&unctrl_lock);
+
 	if (ret)
 		goto err_del;
 
 	return 0;
 
 err_del:
+	mutex_lock(&unctrl_lock);
+	list_del(&dev->list);
+	mutex_unlock(&unctrl_lock);
 	hid_hw_close(hdev);
 	hid_hw_stop(hdev);
 	hid_set_drvdata(hdev, NULL);
@@ -280,11 +336,13 @@ static int unctrl_raw_event(struct hid_device *hdev, struct hid_report *report,
 	if (data[5] != UNCTRL_MODE_RECEIVER && data[5] != UNCTRL_MODE_WIRED)
 		return 0;
 
-	/* the receiver reports 0% while the mouse is switched off */
-	dev->battery_capacity = min_t(u8, data[4], 100);
-	dev->mode = data[5];
-	dev->online = dev->battery_capacity != 0;
-	battery = dev->battery;
+	scoped_guard(spinlock_irqsave, &dev->lock) {
+		/* the receiver reports 0% while the mouse is switched off */
+		dev->battery_capacity = min_t(u8, data[4], 100);
+		dev->mode = data[5];
+		dev->online = dev->battery_capacity != 0;
+		battery = dev->battery;
+	}
 
 	/* only schedules a work, so this is safe from the completion path */
 	if (battery)
@@ -296,6 +354,7 @@ static int unctrl_raw_event(struct hid_device *hdev, struct hid_report *report,
 static void unctrl_remove(struct hid_device *hdev)
 {
 	struct unctrl_dev *dev = hid_get_drvdata(hdev);
+	struct unctrl_dev *other;
 
 	/* Stop polling before the transport goes down. */
 	if (dev) {
@@ -308,8 +367,28 @@ static void unctrl_remove(struct hid_device *hdev)
 	if (!dev)
 		return;
 
-	if (dev->battery)
-		power_supply_unregister(dev->battery);
+	/*
+	 * Pass the battery to a capable connection without one, so that it
+	 * keeps being reported when the owner disappears.
+	 */
+	mutex_lock(&unctrl_lock);
+	list_del(&dev->list);
+	if (dev->battery) {
+		struct power_supply *battery;
+
+		scoped_guard(spinlock_irqsave, &dev->lock) {
+			battery = dev->battery;
+			dev->battery = NULL;
+		}
+		power_supply_unregister(battery);
+		list_for_each_entry(other, &unctrl_connections, list) {
+			if (!other->vendor || other->battery)
+				continue;
+			unctrl_battery_register(other);
+			break;
+		}
+	}
+	mutex_unlock(&unctrl_lock);
 
 	hid_set_drvdata(hdev, NULL);
 	kfree(dev);

-- 
2.56.0

