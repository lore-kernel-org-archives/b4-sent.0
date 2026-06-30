From: Michael Reeves <michael.reeves077@gmail.com>
Date: Tue, 30 Jun 2026 22:54:35 +1000
Subject: [PATCH 07/10] HID: apple: Add support for DockChannel HID
 keyboards
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260630-apple-mtp-keyboard-final-v1-7-506d936a1707@gmail.com>
References: <20260630-apple-mtp-keyboard-final-v1-0-506d936a1707@gmail.com>
In-Reply-To: <20260630-apple-mtp-keyboard-final-v1-0-506d936a1707@gmail.com>
To: Sven Peter <sven@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>, Jassi Brar <jassisinghbrar@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Hector Martin <marcan@marcan.st>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Jiri Kosina <jikos@kernel.org>, 
 Benjamin Tissoires <bentiss@kernel.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 iommu@lists.linux.dev, linux-input@vger.kernel.org, 
 Michael Reeves <michael.reeves077@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782824083; l=8555;
 i=michael.reeves077@gmail.com; s=20260105; h=from:subject:message-id;
 bh=6yE6aPZb9tp6hFgVMnmA6H50KbXFNGStoSs+JCgZxl0=;
 b=OpXm1MgNkoDy8VFQrjkrrXlTcOxcFF3aH5P9H/l26/nx7yJoWCrq7WjkQdz4JA26KJpJSrAy/
 KTzmxv9DIlFDxT18Lf/5y7YBG5sHOZZJjxfnK+o6hr8TGI0oyBy+C4g
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=QIrgWBGCm3LG0YYc6MLCDkwuVXLTGGooVBdWX/KhSiU=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/20260105 with auth_id=591
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

DockChannel keyboards are registered as host-bus Apple HID devices
instead of USB or Bluetooth devices.

Match them in hid-apple, use the modern Magic Keyboard function-key
table, and fix up the oversized report-size descriptor pattern before
parsing.

Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
 drivers/hid/hid-apple.c | 139 ++++++++++++++++++++++++++++++++----------------
 include/linux/hid.h     |   1 +
 2 files changed, 94 insertions(+), 46 deletions(-)

diff --git a/drivers/hid/hid-apple.c b/drivers/hid/hid-apple.c
index bf7dd0fbf249..47c6ec09d5fa 100644
--- a/drivers/hid/hid-apple.c
+++ b/drivers/hid/hid-apple.c
@@ -390,6 +390,12 @@ static bool apple_is_omoton_kb066(struct hid_device *hdev)
 		strcmp(hdev->name, "Bluetooth Keyboard") == 0;
 }
 
+static bool apple_is_dockchannel_keyboard(struct hid_device *hdev)
+{
+	return hdev->bus == BUS_HOST &&
+	       hdev->group == HID_GROUP_APPLE_DOCKCHANNEL;
+}
+
 static inline void apple_setup_key_translation(struct input_dev *input,
 		const struct apple_key_translation *table)
 {
@@ -477,53 +483,57 @@ static int hidinput_apple_event(struct hid_device *hid, struct input_dev *input,
 		asc->fn_on = !!value;
 
 	if (real_fnmode) {
-		switch (hid->product) {
-		case USB_DEVICE_ID_APPLE_ALU_WIRELESS_ANSI:
-		case USB_DEVICE_ID_APPLE_ALU_WIRELESS_ISO:
-		case USB_DEVICE_ID_APPLE_ALU_WIRELESS_JIS:
-		case USB_DEVICE_ID_APPLE_ALU_WIRELESS_2009_ANSI:
-		case USB_DEVICE_ID_APPLE_ALU_WIRELESS_2009_ISO:
-		case USB_DEVICE_ID_APPLE_ALU_WIRELESS_2009_JIS:
-		case USB_DEVICE_ID_APPLE_ALU_WIRELESS_2011_ANSI:
-		case USB_DEVICE_ID_APPLE_ALU_WIRELESS_2011_ISO:
-		case USB_DEVICE_ID_APPLE_ALU_WIRELESS_2011_JIS:
-			table = magic_keyboard_alu_fn_keys;
-			break;
-		case USB_DEVICE_ID_APPLE_MAGIC_KEYBOARD_2015:
-		case USB_DEVICE_ID_APPLE_MAGIC_KEYBOARD_NUMPAD_2015:
-			table = magic_keyboard_2015_fn_keys;
-			break;
-		case USB_DEVICE_ID_APPLE_MAGIC_KEYBOARD_2021:
-		case USB_DEVICE_ID_APPLE_MAGIC_KEYBOARD_FINGERPRINT_2021:
-		case USB_DEVICE_ID_APPLE_MAGIC_KEYBOARD_NUMPAD_2021:
-		case USB_DEVICE_ID_APPLE_MAGIC_KEYBOARD_2024:
-		case USB_DEVICE_ID_APPLE_MAGIC_KEYBOARD_FINGERPRINT_2024:
-		case USB_DEVICE_ID_APPLE_MAGIC_KEYBOARD_NUMPAD_2024:
+		if (apple_is_dockchannel_keyboard(hid)) {
 			table = magic_keyboard_2021_and_2024_fn_keys;
-			break;
-		case USB_DEVICE_ID_APPLE_WELLSPRINGT2_J132:
-		case USB_DEVICE_ID_APPLE_WELLSPRINGT2_J213:
-		case USB_DEVICE_ID_APPLE_WELLSPRINGT2_J680:
-		case USB_DEVICE_ID_APPLE_WELLSPRINGT2_J680_ALT:
-			table = macbookpro_no_esc_fn_keys;
-			break;
-		case USB_DEVICE_ID_APPLE_WELLSPRINGT2_J152F:
-		case USB_DEVICE_ID_APPLE_WELLSPRINGT2_J214K:
-		case USB_DEVICE_ID_APPLE_WELLSPRINGT2_J223:
-			table = macbookpro_dedicated_esc_fn_keys;
-			break;
-		case USB_DEVICE_ID_APPLE_WELLSPRINGT2_J140K:
-		case USB_DEVICE_ID_APPLE_WELLSPRINGT2_J230K:
-			table = apple_fn_keys;
-			break;
-		default:
-			if (hid->product >= USB_DEVICE_ID_APPLE_WELLSPRING4_ANSI &&
-			    hid->product <= USB_DEVICE_ID_APPLE_WELLSPRING4A_JIS)
-				table = macbookair_fn_keys;
-			else if (hid->product < 0x21d || hid->product >= 0x300)
-				table = powerbook_fn_keys;
-			else
+		} else {
+			switch (hid->product) {
+			case USB_DEVICE_ID_APPLE_ALU_WIRELESS_ANSI:
+			case USB_DEVICE_ID_APPLE_ALU_WIRELESS_ISO:
+			case USB_DEVICE_ID_APPLE_ALU_WIRELESS_JIS:
+			case USB_DEVICE_ID_APPLE_ALU_WIRELESS_2009_ANSI:
+			case USB_DEVICE_ID_APPLE_ALU_WIRELESS_2009_ISO:
+			case USB_DEVICE_ID_APPLE_ALU_WIRELESS_2009_JIS:
+			case USB_DEVICE_ID_APPLE_ALU_WIRELESS_2011_ANSI:
+			case USB_DEVICE_ID_APPLE_ALU_WIRELESS_2011_ISO:
+			case USB_DEVICE_ID_APPLE_ALU_WIRELESS_2011_JIS:
+				table = magic_keyboard_alu_fn_keys;
+				break;
+			case USB_DEVICE_ID_APPLE_MAGIC_KEYBOARD_2015:
+			case USB_DEVICE_ID_APPLE_MAGIC_KEYBOARD_NUMPAD_2015:
+				table = magic_keyboard_2015_fn_keys;
+				break;
+			case USB_DEVICE_ID_APPLE_MAGIC_KEYBOARD_2021:
+			case USB_DEVICE_ID_APPLE_MAGIC_KEYBOARD_FINGERPRINT_2021:
+			case USB_DEVICE_ID_APPLE_MAGIC_KEYBOARD_NUMPAD_2021:
+			case USB_DEVICE_ID_APPLE_MAGIC_KEYBOARD_2024:
+			case USB_DEVICE_ID_APPLE_MAGIC_KEYBOARD_FINGERPRINT_2024:
+			case USB_DEVICE_ID_APPLE_MAGIC_KEYBOARD_NUMPAD_2024:
+				table = magic_keyboard_2021_and_2024_fn_keys;
+				break;
+			case USB_DEVICE_ID_APPLE_WELLSPRINGT2_J132:
+			case USB_DEVICE_ID_APPLE_WELLSPRINGT2_J213:
+			case USB_DEVICE_ID_APPLE_WELLSPRINGT2_J680:
+			case USB_DEVICE_ID_APPLE_WELLSPRINGT2_J680_ALT:
+				table = macbookpro_no_esc_fn_keys;
+				break;
+			case USB_DEVICE_ID_APPLE_WELLSPRINGT2_J152F:
+			case USB_DEVICE_ID_APPLE_WELLSPRINGT2_J214K:
+			case USB_DEVICE_ID_APPLE_WELLSPRINGT2_J223:
+				table = macbookpro_dedicated_esc_fn_keys;
+				break;
+			case USB_DEVICE_ID_APPLE_WELLSPRINGT2_J140K:
+			case USB_DEVICE_ID_APPLE_WELLSPRINGT2_J230K:
 				table = apple_fn_keys;
+				break;
+			default:
+				if (hid->product >= USB_DEVICE_ID_APPLE_WELLSPRING4_ANSI &&
+				    hid->product <= USB_DEVICE_ID_APPLE_WELLSPRING4A_JIS)
+					table = macbookair_fn_keys;
+				else if (hid->product < 0x21d || hid->product >= 0x300)
+					table = powerbook_fn_keys;
+				else
+					table = apple_fn_keys;
+			}
 		}
 
 		trans = apple_find_translation(table, code);
@@ -659,6 +669,7 @@ static void apple_battery_timer_tick(struct timer_list *t)
 /*
  * MacBook JIS keyboard has wrong logical maximum
  * Magic Keyboard JIS has wrong logical maximum
+ * Internal DockChannel keyboards can advertise oversized report sizes
  */
 static const __u8 *apple_report_fixup(struct hid_device *hdev, __u8 *rdesc,
 		unsigned int *rsize)
@@ -699,6 +710,27 @@ static const __u8 *apple_report_fixup(struct hid_device *hdev, __u8 *rdesc,
 		rdesc[3] = 0x06;
 	}
 
+	if (apple_is_dockchannel_keyboard(hdev) && *rsize >= 5) {
+		int i;
+
+		for (i = 0; i <= *rsize - 5; i++) {
+			if (rdesc[i] == 0x76 && rdesc[i + 1] == 0x00 &&
+			    rdesc[i + 2] == 0x40 && rdesc[i + 3] == 0x95) {
+				u8 count = rdesc[i + 4];
+
+				if (count > 0 && count < 32) {
+					hid_info(hdev,
+						 "fixing up DockChannel report size\n");
+					rdesc[i] = 0x75;
+					rdesc[i + 1] = 0x08;
+					rdesc[i + 2] = 0x96;
+					rdesc[i + 3] = 0x00;
+					rdesc[i + 4] = count * 8;
+				}
+			}
+		}
+	}
+
 	return rdesc;
 }
 
@@ -763,7 +795,7 @@ static int apple_input_configured(struct hid_device *hdev,
 	struct apple_sc *asc = hid_get_drvdata(hdev);
 
 	if (((asc->quirks & APPLE_HAS_FN) && !asc->fn_found) || apple_is_omoton_kb066(hdev)) {
-		hid_info(hdev, "Fn key not found (Apple Wireless Keyboard clone?), disabling Fn key handling\n");
+		hid_info(hdev, "Disabling function quirk for device without function key\n");
 		asc->quirks &= ~APPLE_HAS_FN;
 	}
 
@@ -1003,6 +1035,17 @@ static void apple_remove(struct hid_device *hdev)
 	hid_hw_stop(hdev);
 }
 
+static bool apple_match(struct hid_device *hdev, bool ignore_special_driver)
+{
+	if (ignore_special_driver)
+		return false;
+
+	if (hdev->group == HID_GROUP_APPLE_DOCKCHANNEL)
+		return apple_is_dockchannel_keyboard(hdev);
+
+	return true;
+}
+
 static const struct hid_device_id apple_devices[] = {
 	{ HID_USB_DEVICE(USB_VENDOR_ID_APPLE, USB_DEVICE_ID_APPLE_MIGHTYMOUSE),
 		.driver_data = APPLE_MIGHTYMOUSE | APPLE_INVERT_HWHEEL },
@@ -1224,6 +1267,9 @@ static const struct hid_device_id apple_devices[] = {
 		.driver_data = APPLE_HAS_FN | APPLE_ISO_TILDE_QUIRK },
 	{ HID_USB_DEVICE(USB_VENDOR_ID_APPLE, USB_DEVICE_ID_APPLE_TOUCHBAR_BACKLIGHT),
 		.driver_data = APPLE_MAGIC_BACKLIGHT },
+	{ HID_DEVICE(BUS_HOST, HID_GROUP_APPLE_DOCKCHANNEL,
+		     HID_ANY_ID, HID_ANY_ID),
+		.driver_data = APPLE_HAS_FN | APPLE_ISO_TILDE_QUIRK },
 
 	{ }
 };
@@ -1232,6 +1278,7 @@ MODULE_DEVICE_TABLE(hid, apple_devices);
 static struct hid_driver apple_driver = {
 	.name = "apple",
 	.id_table = apple_devices,
+	.match = apple_match,
 	.report_fixup = apple_report_fixup,
 	.probe = apple_probe,
 	.remove = apple_remove,
diff --git a/include/linux/hid.h b/include/linux/hid.h
index 47dc0bc89fa4..0d40deec6295 100644
--- a/include/linux/hid.h
+++ b/include/linux/hid.h
@@ -441,6 +441,7 @@ struct hid_item {
 #define HID_GROUP_STEAM				0x0103
 #define HID_GROUP_LOGITECH_27MHZ_DEVICE		0x0104
 #define HID_GROUP_VIVALDI			0x0105
+#define HID_GROUP_APPLE_DOCKCHANNEL		0x0106
 
 /*
  * HID protocol status

-- 
2.51.2

