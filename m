From: Bishwa Bhusan Saha <contact@bishwasaha.com>
Date: Tue, 13 Oct 2026 02:44:00 +0530
Subject: [PATCH v2 5/5] HID: UNCTRL: only report to userspace on battery
 changes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-b4-unctrl-m1-battery-v2-5-bd6752021753@bishwasaha.com>
References: <20261013-b4-unctrl-m1-battery-v2-0-bd6752021753@bishwasaha.com>
In-Reply-To: <20261013-b4-unctrl-m1-battery-v2-0-bd6752021753@bishwasaha.com>
To: Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Bishwa Bhusan Saha <contact@bishwasaha.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791839640; l=1613;
 i=contact@bishwasaha.com; s=20261012; h=from:subject:message-id;
 bh=KdqmriOtFavceiEYR5a85IDrZtx1u4sC3/DG/YTiFJ0=;
 b=yP3y4kypAkgi3nBghxXa8QO28nISgCfqrC5G61vi8namA1rGRyA2UWBTkNl1y0qS6O6n0xpqX
 F47X4ZTE85lCtbJm5VQEWnJ6DEhAl8uqYIYOFC/EdKxo9k/PdYHxnp2
X-Developer-Key: i=contact@bishwasaha.com; a=ed25519;
 pk=bW8B6BzX1VU4IIcYagrb5nNRxBho+rTXaQZ8fLx8CoU=
X-Endpoint-Received: by B4 Relay for contact@bishwasaha.com/20261012 with auth_id=1168
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch calls power_supply_changed() only when the reported
capacity or mode actually changes.

Signed-off-by: Bishwa Bhusan Saha <contact@bishwasaha.com>
Assisted-by: GLM:glm-5.3
---
 drivers/hid/hid-unctrl-m1.c | 11 ++++++++++-
 1 file changed, 10 insertions(+), 1 deletion(-)

diff --git a/drivers/hid/hid-unctrl-m1.c b/drivers/hid/hid-unctrl-m1.c
index 624ac1365..c44d1cd5b 100644
--- a/drivers/hid/hid-unctrl-m1.c
+++ b/drivers/hid/hid-unctrl-m1.c
@@ -331,6 +331,8 @@ static int unctrl_raw_event(struct hid_device *hdev, struct hid_report *report,
 {
 	struct unctrl_dev *dev = hid_get_drvdata(hdev);
 	struct power_supply *battery = NULL;
+	bool changed;
+	u8 old_capacity, old_mode;
 
 	if (!dev || size < 8)
 		return 0;
@@ -345,16 +347,23 @@ static int unctrl_raw_event(struct hid_device *hdev, struct hid_report *report,
 
 	scoped_guard(spinlock_irqsave, &dev->lock) {
 		/* the receiver reports 0% while the mouse is switched off */
+		old_capacity = dev->battery_capacity;
+		old_mode = dev->mode;
+
 		dev->battery_capacity = min_t(u8, data[4], 100);
 		dev->mode = data[5];
 		dev->online = dev->battery_capacity != 0;
+
+		changed = dev->battery_capacity != old_capacity ||
+			  dev->mode != old_mode;
+
 		battery = dev->battery;
 		/*
 		 * Only schedules a work, so safe from the completion path that
 		 * raw_event runs in. Under the lock so that the unregistering side
 		 * is either done or still blocked when we touch the pointer.
 		 */
-		if (battery)
+		if (battery && changed)
 			power_supply_changed(battery);
 	}
 

-- 
2.56.0

