From: Bishwa Bhusan Saha <contact@bishwasaha.com>
Date: Tue, 13 Oct 2026 01:45:25 +0530
Subject: [PATCH 3/5] HID: UNCTRL: add periodic battery reporting using a
 workqueue
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-b4-unctrl-m1-battery-v1-3-4a50203b7177@bishwasaha.com>
References: <20261013-b4-unctrl-m1-battery-v1-0-4a50203b7177@bishwasaha.com>
In-Reply-To: <20261013-b4-unctrl-m1-battery-v1-0-4a50203b7177@bishwasaha.com>
To: Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Bishwa Bhusan Saha <contact@bishwasaha.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791836132; l=2489;
 i=contact@bishwasaha.com; s=20261012; h=from:subject:message-id;
 bh=cZg7tXXlrf9MFCB4wrzOmscX9rpVeRP9MmWnFJhdM4M=;
 b=IPYFwJ5o+MWEnoEXUZuWaerA5M1RpXYfzZuJ31w5xWWJsW9LDjH4l8nriYt3rd67kSMNLq3Rh
 kGNb31vYwu0AB4nEcyLK4ofQ+zbRlbPYyrXwkaE+PvsmGiuaN7ywu3F
X-Developer-Key: i=contact@bishwasaha.com; a=ed25519;
 pk=bW8B6BzX1VU4IIcYagrb5nNRxBho+rTXaQZ8fLx8CoU=
X-Endpoint-Received: by B4 Relay for contact@bishwasaha.com/20261012 with auth_id=1168
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch uses a workqueue to check battery status every 5 seconds.

Signed-off-by: Bishwa Bhusan Saha <contact@bishwasaha.com>
Assisted-by: GLM:glm-5.3
---
 drivers/hid/hid-unctrl-m1.c | 26 +++++++++++++++++++++++++-
 1 file changed, 25 insertions(+), 1 deletion(-)

diff --git a/drivers/hid/hid-unctrl-m1.c b/drivers/hid/hid-unctrl-m1.c
index 59259dee7..1e73cad1e 100644
--- a/drivers/hid/hid-unctrl-m1.c
+++ b/drivers/hid/hid-unctrl-m1.c
@@ -22,11 +22,14 @@
 #include <linux/power_supply.h>
 #include <linux/slab.h>
 #include <linux/usb.h>
+#include <linux/workqueue.h>
 
 #include "hid-ids.h"
 
 #define UNCTRL_VENDOR_IFNUM 2
 
+#define UNCTRL_BATTERY_TIMEOUT_MS 5000
+
 #define UNCTRL_MODE_RECEIVER 0x01
 #define UNCTRL_MODE_WIRED 0x44
 
@@ -47,6 +50,8 @@ struct unctrl_dev {
 	struct power_supply_desc battery_desc;
 	struct power_supply *battery;
 
+	struct delayed_work battery_work;
+
 	u8 battery_capacity;
 	u8 mode;
 	bool online;
@@ -132,6 +137,17 @@ static void unctrl_fetch_battery(struct hid_device *hdev)
 	kfree(write_buf);
 }
 
+static void unctrl_battery_timer_tick(struct work_struct *work)
+{
+	struct unctrl_dev *dev =
+		container_of(work, struct unctrl_dev, battery_work.work);
+
+	unctrl_fetch_battery(dev->hdev);
+
+	schedule_delayed_work(&dev->battery_work,
+			      msecs_to_jiffies(UNCTRL_BATTERY_TIMEOUT_MS));
+}
+
 /* Register the power supply of this connection and start reporting. */
 static int unctrl_battery_register(struct unctrl_dev *dev)
 {
@@ -155,6 +171,8 @@ static int unctrl_battery_register(struct unctrl_dev *dev)
 		 dev->battery_desc.name);
 
 	unctrl_fetch_battery(dev->hdev);
+	schedule_delayed_work(&dev->battery_work,
+			      msecs_to_jiffies(UNCTRL_BATTERY_TIMEOUT_MS));
 
 	return 0;
 }
@@ -200,6 +218,8 @@ static int unctrl_probe(struct hid_device *hdev, const struct hid_device_id *id)
 	}
 
 	dev->hdev = hdev;
+	INIT_DELAYED_WORK(&dev->battery_work, unctrl_battery_timer_tick);
+
 	dev->battery_capacity = 100;
 	dev->mode = UNCTRL_MODE_RECEIVER;
 	dev->wired = hdev->product == USB_DEVICE_ID_UNCTRL_M1_WIRED;
@@ -277,7 +297,11 @@ static void unctrl_remove(struct hid_device *hdev)
 {
 	struct unctrl_dev *dev = hid_get_drvdata(hdev);
 
-	hid_hw_close(hdev);
+	/* Stop polling before the transport goes down. */
+	if (dev) {
+		cancel_delayed_work_sync(&dev->battery_work);
+		hid_hw_close(hdev);
+	}
 
 	hid_hw_stop(hdev);
 

-- 
2.56.0

