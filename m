From: Jaret Varn <jav26122@gmail.com>
Date: Mon, 02 Nov 2026 09:59:20 -0500
Subject: [PATCH] HID: steelseries: Add support for Arctis Pro Wireless
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261102-hid-arctis-pro-wireless-v1-1-109500e36f5b@gmail.com>
X-B4-Tracking: v=1; b=H4sIAEel6GoC/x3MQQqDQAxG4atI1gacmSK0VxEXQ+ZvDRSVRFQQ7
 96hy2/x3kUOUzi9mosMu7ouc0VoG5Ipzx+wlmqKXexDFxNPWjibbOq82sKHGr5w5yce0qeQkwi
 o1qvhref/PIz3/QM7mcF0aQAAAA==
X-Change-ID: 20261023-hid-arctis-pro-wireless-9e4c631a3cce
To: Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sriman Achanta <srimanachanta@gmail.com>, 
 =?utf-8?q?Erik_H=C3=A5kansson?= <erikhakan@gmail.com>, 
 Martin Oberleiter <martin.oberleiter@netixx.it>, 
 Jaret Varn <jav26122@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793631561; l=8406;
 i=jav26122@gmail.com; s=20261023; h=from:subject:message-id;
 bh=P8hw5Np1I1fi36O38WKLtuWMlqRxVnApPqW0aD40h3U=;
 b=9xfBRSpU6RpfbJYb9vQcHniAfpd1vRG2opmRGWad04JcNtBzJlrKFlieIq8yYRIwTtYoIAGWO
 u//mtApWnQZDFzpZ5L5jxJe+QlOOzc1kHi1l3XvU+MTiTvXSo0mXbre
X-Developer-Key: i=jav26122@gmail.com; a=ed25519;
 pk=WqYyslVFlvCd2E/8Og9Rh5VHXXB8A5a1ZhHaqIDzgFE=
X-Endpoint-Received: by B4 Relay for jav26122@gmail.com/20261023 with auth_id=1300
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Arctis Pro Wireless base station (USB ID 1038:1290) answers status
queries on HID interface 0, but the driver does not know the device, so
the headset battery is not reported to userspace.

Sending 0x41 0xaa returns the connection state in the first byte: 0x04
when the headset is connected and 0x02 when it is switched off. Sending
0x40 0xaa returns the battery level on a 0-4 scale. The replies do not
echo the request. The second byte was 0x02 in every connection reply
and 0x00 in every battery reply, including while swapping the headset
battery and the spare battery in the base station, so use it to tell
the two replies apart.

The base station keeps reporting the last battery level after the
headset is switched off, and reports 0 if it powered up with the
headset off, so only update the level while the headset is connected.
No unsolicited reports were seen on either HID interface, so rely on
the existing periodic status polling.

The base station drops a query that arrives while it is still
answering the previous one: sending the two queries back to back left
most polls unanswered, and the base station then stopped answering at
all until it was reset. Wait 100 ms between them. The connection reply
arrives within 3 ms, and a 50 ms gap was already reliable in testing.

Add USB ID 1038:1290 to the driver's device tables.

Signed-off-by: Jaret Varn <jav26122@gmail.com>
---
Tested on an Arctis Pro Wireless in a QEMU VM with the base station
passed through: connection state, battery level and wireless_status
are reported, and switching the headset off and on is picked up within
one poll. Battery levels 4/4 and 3/4 were reported as 100% and 75%,
matching the base station's own display. The base station's volume
knob and spare battery charging indicator kept working while the
driver polled. Builds cleanly with CONFIG_HID_STEELSERIES=y, =m and
=n, and sparse reports nothing. Suspend and resume were not tested.

The code and changelog were drafted with an AI coding assistant
(Claude), modelled on the Arctis 7 (2018) support. The protocol bytes
come from HeadsetControl's documentation of this model and were
checked on my headset through hidraw. I reviewed and tested the patch.

This touches the same lines as patches still on the list: the Rival 3
Wireless series [1] (Kconfig help text and hid-ids.h), and the two
Arctis 7 (2018) request-spacing fixes [2][3]. I'm happy to rebase on
whichever lands first. If the wait-for-reply approach in [3] is
preferred over a fixed delay, I can switch this device to it as well.

[1] https://lore.kernel.org/r/20261030-rival3-battery-v1-1-6b1feeaf1f52@netixx.it
[2] https://lore.kernel.org/r/20261024-feature-arctis7-v1-1-583951aa6583@gmail.com
[3] https://lore.kernel.org/r/20261029-arctis7-battery-v1-1-599a4554af30@netixx.it
---
 drivers/hid/Kconfig                  |  4 +--
 drivers/hid/hid-ids.h                |  1 +
 drivers/hid/hid-quirks.c             |  1 +
 drivers/hid/hid-steelseries-arctis.c | 55 ++++++++++++++++++++++++++++++++++++
 4 files changed, 59 insertions(+), 2 deletions(-)

diff --git a/drivers/hid/Kconfig b/drivers/hid/Kconfig
index 2481bc01c435b1305aa6666a6f94471635a8f6a0..16d95f948fe8f70ada1c89836b472aef9a40d139 100644
--- a/drivers/hid/Kconfig
+++ b/drivers/hid/Kconfig
@@ -1216,8 +1216,8 @@ config HID_STEELSERIES
 	depends on USB_HID
 	help
 	Support for Steelseries SRW-S1 steering wheel, and the Steelseries
-	Arctis 1 Wireless for XBox, Arctis 7 (2018), Arctis 9, and Arctis
-	Nova headsets.
+	Arctis 1 Wireless for XBox, Arctis 7 (2018), Arctis 9, Arctis Pro
+	Wireless, and Arctis Nova headsets.
 
 config HID_SUNPLUS
 	tristate "Sunplus wireless desktop"
diff --git a/drivers/hid/hid-ids.h b/drivers/hid/hid-ids.h
index 91319aa6516dae89a6d1ace1b2ff089254fb93ae..ae09333566893c5934a09f7a58c0b5b924ad7c6c 100644
--- a/drivers/hid/hid-ids.h
+++ b/drivers/hid/hid-ids.h
@@ -1435,6 +1435,7 @@
 #define USB_DEVICE_ID_STEELSERIES_ARCTIS_NOVA_7_X_GEN2	0x2258
 #define USB_DEVICE_ID_STEELSERIES_ARCTIS_NOVA_7_X_GEN2_2	0x229e
 #define USB_DEVICE_ID_STEELSERIES_ARCTIS_NOVA_7_X_GEN2_3	0x22ad
+#define USB_DEVICE_ID_STEELSERIES_ARCTIS_PRO_WIRELESS	0x1290
 #define USB_DEVICE_ID_STEELSERIES_MSI_KLC   0x1122
 #define USB_DEVICE_ID_STEELSERIES_MSI_ALC   0x1161
 
diff --git a/drivers/hid/hid-quirks.c b/drivers/hid/hid-quirks.c
index 793db001a62b7ba4ef2da67759a75334750be489..1097fd268bb6b2adc1fbaec3ba0f388931e7eefe 100644
--- a/drivers/hid/hid-quirks.c
+++ b/drivers/hid/hid-quirks.c
@@ -772,6 +772,7 @@ static const struct hid_device_id hid_have_special_driver[] = {
 	{ HID_USB_DEVICE(USB_VENDOR_ID_STEELSERIES, USB_DEVICE_ID_STEELSERIES_ARCTIS_NOVA_7_X_GEN2) },
 	{ HID_USB_DEVICE(USB_VENDOR_ID_STEELSERIES, USB_DEVICE_ID_STEELSERIES_ARCTIS_NOVA_7_X_GEN2_2) },
 	{ HID_USB_DEVICE(USB_VENDOR_ID_STEELSERIES, USB_DEVICE_ID_STEELSERIES_ARCTIS_NOVA_7_X_GEN2_3) },
+	{ HID_USB_DEVICE(USB_VENDOR_ID_STEELSERIES, USB_DEVICE_ID_STEELSERIES_ARCTIS_PRO_WIRELESS) },
 #endif
 #if IS_ENABLED(CONFIG_HID_SUNPLUS)
 	{ HID_USB_DEVICE(USB_VENDOR_ID_SUNPLUS, USB_DEVICE_ID_SUNPLUS_WDESKTOP) },
diff --git a/drivers/hid/hid-steelseries-arctis.c b/drivers/hid/hid-steelseries-arctis.c
index df61fa33d4c6876d23c33ec3348d99b169feccb2..aa512342782eccf9062237b2174209dbd4b9b989 100644
--- a/drivers/hid/hid-steelseries-arctis.c
+++ b/drivers/hid/hid-steelseries-arctis.c
@@ -6,6 +6,7 @@
  *  Copyright (c) 2026 Sriman Achanta
  */
 
+#include <linux/delay.h>
 #include <linux/device.h>
 #include <linux/hid.h>
 #include <linux/kref.h>
@@ -128,6 +129,25 @@ static int steelseries_arctis_nova_request_status(struct hid_device *hdev)
 	return steelseries_send_output_report(hdev, data, sizeof(data));
 }
 
+static int steelseries_arctis_pro_wireless_request_status(struct hid_device *hdev)
+{
+	const u8 connection[] = { 0x00, 0x41, 0xaa };
+	const u8 battery[] = { 0x00, 0x40, 0xaa };
+	int ret;
+
+	ret = steelseries_send_output_report(hdev, connection, sizeof(connection));
+	if (ret)
+		return ret;
+
+	/*
+	 * The base station drops a query that arrives while it is still
+	 * answering the previous one, and may then stop answering at all.
+	 */
+	msleep(100);
+
+	return steelseries_send_output_report(hdev, battery, sizeof(battery));
+}
+
 /*
  * Headset battery helpers
  */
@@ -255,6 +275,31 @@ static void steelseries_arctis_nova_7_parse_status(struct steelseries_device *sd
 	}
 }
 
+static void steelseries_arctis_pro_wireless_parse_status(struct steelseries_device *sd,
+							 u8 *data, int size)
+{
+	if (size < 2)
+		return;
+
+	/*
+	 * Replies do not echo the request. The second byte tells them apart:
+	 * 0x02 for the connection status reply, 0x00 for the battery reply.
+	 */
+	switch (data[1]) {
+	case 0x02:
+		/* 0x04 means that the headset is connected to the base station. */
+		sd->headset_connected = data[0] == 0x04;
+		break;
+	case 0x00:
+		/* The base station reports a stale level while disconnected. */
+		if (!sd->headset_connected)
+			break;
+
+		sd->battery_capacity = steelseries_map_capacity(data[0], 0, 4);
+		break;
+	}
+}
+
 /*
  * Device info definitions
  */
@@ -296,6 +341,13 @@ static const struct steelseries_device_info arctis_nova_7_info = {
 	.parse_status = steelseries_arctis_nova_7_parse_status,
 };
 
+static const struct steelseries_device_info arctis_pro_wireless_info = {
+	.sync_interface = 0,
+	.capabilities = SS_CAP_BATTERY,
+	.request_status = steelseries_arctis_pro_wireless_request_status,
+	.parse_status = steelseries_arctis_pro_wireless_parse_status,
+};
+
 /*
  * Headset wireless status and battery infrastructure
  */
@@ -742,6 +794,9 @@ static const struct hid_device_id steelseries_arctis_devices[] = {
 	{ HID_USB_DEVICE(USB_VENDOR_ID_STEELSERIES,
 			 USB_DEVICE_ID_STEELSERIES_ARCTIS_NOVA_7_X_GEN2_3),
 	  .driver_data = (unsigned long)&arctis_nova_info },
+	{ HID_USB_DEVICE(USB_VENDOR_ID_STEELSERIES,
+			 USB_DEVICE_ID_STEELSERIES_ARCTIS_PRO_WIRELESS),
+	  .driver_data = (unsigned long)&arctis_pro_wireless_info },
 	{}
 };
 MODULE_DEVICE_TABLE(hid, steelseries_arctis_devices);

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261023-hid-arctis-pro-wireless-9e4c631a3cce

Best regards,
-- 
Jaret Varn <jav26122@gmail.com>

