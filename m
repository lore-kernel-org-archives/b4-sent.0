From: Martin Oberleiter <martin.oberleiter@netixx.it>
Date: Thu, 29 Oct 2026 22:46:42 +0100
Subject: [PATCH] HID: steelseries: Fix Arctis 7 battery reading 3% on
 overlapping requests
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261029-arctis7-battery-v1-1-599a4554af30@netixx.it>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CMBBG4auQWduEDkajVzEuSvkL4wLNTCEQw
 t2puvwW721kUIHRvdpIMYvJeyzwp4riEMYeTrpi4povvuabCxqz2NW1IWfo6nzDnM5NQhdBpfo
 okiy/4+P5t03tCzF/N7TvB0UfgiBzAAAA
X-Change-ID: 20261029-arctis7-battery-1322f43fedce
To: Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>
Cc: =?utf-8?q?Erik_H=C3=A5kansson?= <erikhakan@gmail.com>, 
 linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Martin Oberleiter <martin.oberleiter@netixx.it>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793310413; l=5120;
 i=martin.oberleiter@netixx.it; s=20261029; h=from:subject:message-id;
 bh=f7Tg+XBPNU6f8wKLfB2LtxfWrgE/PmYwsye7R+ocH1s=;
 b=UbVzVbt/UaEIJtZ7U/Jtf4ITZajrHHkN6aIHudVpGSYVk01gH9cIKRhWzT/bohS0o5lyi5Pvd
 VyxGkMl4MrwDOeNrBQxyhHE0iP8emJY+xwwo6QqyQoa4vNmeG4WDB8H
X-Developer-Key: i=martin.oberleiter@netixx.it; a=ed25519;
 pk=yZvkAuAsIiJ76LEGGTR3TI7+Xjw7lGN1dK6jcv72XZo=
X-Endpoint-Received: by B4 Relay for martin.oberleiter@netixx.it/20261029 with auth_id=1358
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Arctis 7 (2018) status poll sends the connection (0x14) and battery
(0x18) requests back to back. The transmitter answers the connection
request within about a millisecond, but if the battery request arrives
before that answer has gone out, it sends the connection reply relabeled
with the 0x18 command byte. The "connected" status byte (0x03) is then
parsed as a battery level of 3%, followed some 30 ms later by the real
battery reply:

  req 06 14
  req 06 18
  rx  06 18 03 19 01 ...   <- connection reply, relabeled
  rx  06 18 4b 00 c8 ...   <- real battery reply (75%)

On a 1038:12ad transmitter this happened on roughly every third poll, so
the reported capacity flipped between 3% and the real value every few
seconds and the desktop kept raising low battery notifications.

Wait for the connection reply before sending the battery request, and
only send it if that reply says the headset is connected. The driver's
battery request then no longer overlaps its connection request, and it
is not sent once the transmitter has reported the headset as off (the
transmitter answers it with 0 in that state). If no connection reply
arrives within 100 ms, skip the battery request for this poll. Waiting
for the reply rather than sleeping for a fixed time avoids guessing how
long the transmitter takes to answer.

Userspace talking to the transmitter through hidraw at the same time
(e.g. HeadsetControl) can still overlap with the driver's requests;
that is not addressed here.

Tested on a 1038:12ad transmitter: the capacity stays stable while the
headset is on, keeps its last value when it is switched off, and shows
the real value right after it is switched back on.

The issue was diagnosed and the fix and this changelog were written
with the help of an AI coding assistant (Claude Code), from kernel logs
and instrumented builds of the driver on the affected hardware.

Fixes: 7e749a797282 ("HID: steelseries: Add support for Arctis 7 (2018)")
Signed-off-by: Martin Oberleiter <martin.oberleiter@netixx.it>
---
 drivers/hid/hid-steelseries-arctis.c | 32 ++++++++++++++++++++++++++++++++
 1 file changed, 32 insertions(+)

diff --git a/drivers/hid/hid-steelseries-arctis.c b/drivers/hid/hid-steelseries-arctis.c
index df61fa33d..7b83ff8a3 100644
--- a/drivers/hid/hid-steelseries-arctis.c
+++ b/drivers/hid/hid-steelseries-arctis.c
@@ -6,6 +6,7 @@
  *  Copyright (c) 2026 Sriman Achanta
  */
 
+#include <linux/completion.h>
 #include <linux/device.h>
 #include <linux/hid.h>
 #include <linux/kref.h>
@@ -47,6 +48,7 @@ struct steelseries_device {
 	bool battery_charging;
 
 	spinlock_t lock;
+	struct completion connection_reply;
 	bool removed;
 };
 
@@ -101,16 +103,44 @@ static int steelseries_arctis_1_request_status(struct hid_device *hdev)
 	return steelseries_send_output_report(hdev, data, sizeof(data));
 }
 
+#define STEELSERIES_ARCTIS_7_REPLY_TIMEOUT_MS	100
+
 static int steelseries_arctis_7_2018_request_status(struct hid_device *hdev)
 {
+	struct steelseries_device *sd = hid_get_drvdata(hdev);
 	const u8 connection[] = { 0x06, 0x14 };
 	const u8 battery[] = { 0x06, 0x18 };
+	unsigned long flags;
+	bool connected;
 	int ret;
 
+	reinit_completion(&sd->connection_reply);
+
 	ret = steelseries_send_output_report(hdev, connection, sizeof(connection));
 	if (ret)
 		return ret;
 
+	/*
+	 * A request that reaches the transmitter before it has answered the
+	 * previous one is answered with that stale reply relabeled with the
+	 * new command byte, so a "connected" (0x03) reply to 0x14 would read
+	 * as 3% battery. With the headset off, the battery reply is 0. Only
+	 * ask for the battery once the connection reply is in and says the
+	 * headset is connected.
+	 */
+	if (!wait_for_completion_timeout(&sd->connection_reply,
+					 msecs_to_jiffies(STEELSERIES_ARCTIS_7_REPLY_TIMEOUT_MS))) {
+		hid_dbg(hdev, "No connection status reply, skipping battery request\n");
+		return -ETIMEDOUT;
+	}
+
+	spin_lock_irqsave(&sd->lock, flags);
+	connected = sd->headset_connected;
+	spin_unlock_irqrestore(&sd->lock, flags);
+
+	if (!connected)
+		return 0;
+
 	return steelseries_send_output_report(hdev, battery, sizeof(battery));
 }
 
@@ -175,6 +205,7 @@ static void steelseries_arctis_7_2018_parse_status(struct steelseries_device *sd
 	case 0x14:
 		/* 0x03 means that the headset is connected to the transmitter. */
 		sd->headset_connected = data[2] == 0x03;
+		complete(&sd->connection_reply);
 		break;
 	case 0x18:
 		if (!sd->headset_connected)
@@ -518,6 +549,7 @@ static int steelseries_arctis_probe(struct hid_device *hdev,
 		sd->hdev = hdev;
 		sd->info = info;
 		spin_lock_init(&sd->lock);
+		init_completion(&sd->connection_reply);
 		INIT_DELAYED_WORK(&sd->status_work, steelseries_status_timer_work_handler);
 
 		ret = hid_hw_start(hdev, HID_CONNECT_DEFAULT);

---
base-commit: 720806515cb6921ab05caaa6f470f7054b56385e
change-id: 20261029-arctis7-battery-1322f43fedce

Best regards,
--  
Martin Oberleiter <martin.oberleiter@netixx.it>

