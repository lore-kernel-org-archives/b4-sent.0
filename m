From: Michael Reeves <michael.reeves077@gmail.com>
Date: Fri, 18 Sep 2026 21:06:50 +1000
Subject: [PATCH v2 07/10] HID: apple: Add support for DockChannel HID
 keyboards
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260918-apple-mtp-keyboard-final-v2-7-a5c685e50b60@gmail.com>
References: <20260918-apple-mtp-keyboard-final-v2-0-a5c685e50b60@gmail.com>
In-Reply-To: <20260918-apple-mtp-keyboard-final-v2-0-a5c685e50b60@gmail.com>
To: Sven Peter <sven@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>, Jassi Brar <jassisinghbrar@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Hector Martin <marcan@marcan.st>, 
 Michael Reeves <michael.reeves077@gmail.com>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Jiri Kosina <jikos@kernel.org>, 
 Benjamin Tissoires <bentiss@kernel.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 iommu@lists.linux.dev, linux-input@vger.kernel.org, 
 Yureka Lilian <yureka@cyberchaos.dev>, Julian Braha <julianbraha@gmail.com>, 
 Sasha Finkelstein <k@chaosmail.tech>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789729608; l=7416;
 i=michael.reeves077@gmail.com; s=fedora-20260918; h=from:subject:message-id;
 bh=++PWfyl4aWWCSIvCQ2v5nkAClhD7fiOMmzz+Cj0mwnk=;
 b=Fw2sDFSoNhoXGgsnaijAFlfxBik/XxInhI2m51WKlQCc2fP0pc3WjwUleBBENXiEXQuOKmM8r
 Kyvh3QLTYwcBVpGjEz9Y1+pE/Qz7h/lf4e8l6n3ilHUhYA99HgPa/+b
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=VJ0TvyQ9TvfzYZa908YSE9kpkjFLLD5luv0bERu+boc=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/fedora-20260918 with auth_id=1035
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

DockChannel keyboards are registered as host-bus Apple HID devices
instead of USB or Bluetooth devices.

Match them in hid-apple and use the modern Magic Keyboard function-key
table.

Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
 drivers/hid/hid-apple.c | 117 +++++++++++++++++++++++++++++-------------------
 include/linux/hid.h     |   1 +
 2 files changed, 72 insertions(+), 46 deletions(-)

diff --git a/drivers/hid/hid-apple.c b/drivers/hid/hid-apple.c
index f6134c582..cebe2f901 100644
--- a/drivers/hid/hid-apple.c
+++ b/drivers/hid/hid-apple.c
@@ -395,6 +395,12 @@ static bool apple_is_omoton_kb066(struct hid_device *hdev)
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
@@ -482,53 +488,57 @@ static int hidinput_apple_event(struct hid_device *hid, struct input_dev *input,
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
@@ -768,7 +778,7 @@ static int apple_input_configured(struct hid_device *hdev,
 	struct apple_sc *asc = hid_get_drvdata(hdev);
 
 	if (((asc->quirks & APPLE_HAS_FN) && !asc->fn_found) || apple_is_omoton_kb066(hdev)) {
-		hid_info(hdev, "Fn key not found (Apple Wireless Keyboard clone?), disabling Fn key handling\n");
+		hid_info(hdev, "Disabling function quirk for device without function key\n");
 		asc->quirks &= ~APPLE_HAS_FN;
 	}
 
@@ -1019,6 +1029,17 @@ static void apple_remove(struct hid_device *hdev)
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
@@ -1240,6 +1261,9 @@ static const struct hid_device_id apple_devices[] = {
 		.driver_data = APPLE_HAS_FN | APPLE_ISO_TILDE_QUIRK },
 	{ HID_USB_DEVICE(USB_VENDOR_ID_APPLE, USB_DEVICE_ID_APPLE_TOUCHBAR_BACKLIGHT),
 		.driver_data = APPLE_MAGIC_BACKLIGHT },
+	{ HID_DEVICE(BUS_HOST, HID_GROUP_APPLE_DOCKCHANNEL,
+		     HID_ANY_ID, HID_ANY_ID),
+		.driver_data = APPLE_HAS_FN | APPLE_ISO_TILDE_QUIRK },
 
 	{ }
 };
@@ -1248,6 +1272,7 @@ MODULE_DEVICE_TABLE(hid, apple_devices);
 static struct hid_driver apple_driver = {
 	.name = "apple",
 	.id_table = apple_devices,
+	.match = apple_match,
 	.report_fixup = apple_report_fixup,
 	.probe = apple_probe,
 	.remove = apple_remove,
diff --git a/include/linux/hid.h b/include/linux/hid.h
index 8d17b7416..40be5eabf 100644
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
2.55.0

