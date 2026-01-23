From: David Phillips <david@profile.sh>
Date: Fri, 23 Jan 2026 12:56:09 +0900
Subject: [PATCH] HID: elecom: Add support for ELECOM HUGE Plus M-HT1MRBK
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260123-hid-elecom-huge-plus-fix-v1-1-4bed5e52fb3d@profile.sh>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MSwqAMAwFryJZG2jrB/Qq4kLa1AZqlRZFEO9uc
 DlvePNAocxUYKweyHRx4T0J6LoCG5a0ErITBqNMr7RpMLBDimT3DcMp+ohnQc83dm1nvTKDd3o
 BuR+ZZP7T0/y+H604klpqAAAA
X-Change-ID: 20260123-hid-elecom-huge-plus-fix-545cf029fd1a
To: Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 David Phillips <david@profile.sh>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=6118; i=david@profile.sh;
 h=from:subject:message-id; bh=u0LNPm/gfNEblXkqyIokQjDtFoH3XWO7jiKviM9ZIOE=;
 b=owGbwMvMwCV2ny1Y7qdgpz7jabUkhsyij1v0BScuEA39InZk8k6vltkbU1WMXnd2h71N+6FSt
 UTapbipo5SFQYyLQVZMkWWjjufqqwnXdLQrr/2CmcPKBDKEgYtTACay6Qgjw++V5xYEr1ENvDBn
 4Vpn3z1e7H5zjzLGWBzkXnO+9uO6w80M/8OP9lScPh9xxnrv3On5UkUnstYEuU/vv832ZenK1Jn
 79DgA
X-Developer-Key: i=david@profile.sh; a=openpgp;
 fpr=B12C49ABD560D62C2B79D6FADF06531EF911892F
X-Endpoint-Received: by B4 Relay for david@profile.sh/default with auth_id=614
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

New model in the ELECOM HUGE trackball line that has 8 buttons but the
report descriptor specifies only 5. The HUGE Plus supports connecting via
Bluetooth, 2.4GHz wireless USB dongle, and directly via a USB-C cable.
Each connection type reports a different device id, 01AA for cable,
01AB for USB dongle, and 01AC for Bluetooth.

This patch adds these device IDs and applies the fixups similar to the
other ELECOM devices to get all 8 buttons working for all 3 connection
types.

For reference, the usbhid-dump output:
001:013:001:DESCRIPTOR         1769085639.598405
 05 01 09 02 A1 01 85 01 09 01 A1 00 05 09 19 01
 29 05 15 00 25 01 75 01 95 05 81 02 75 03 95 01
 81 01 05 01 09 30 09 31 16 01 80 26 FF 7F 75 10
 95 02 81 06 09 38 15 81 25 7F 75 08 95 01 81 06
 05 0C 0A 38 02 15 81 25 7F 75 08 95 01 81 06 C0
 C0 05 0C 09 01 A1 01 85 02 15 01 26 8C 02 19 01
 2A 8C 02 75 10 95 01 81 00 C0 05 01 09 80 A1 01
 85 03 09 82 09 81 09 83 15 00 25 01 19 01 29 03
 75 01 95 03 81 02 95 05 81 01 C0 06 01 FF 09 00
 A1 01 85 08 09 00 15 00 26 FF 00 75 08 95 07 81
 02 C0 06 02 FF 09 02 A1 01 85 06 09 02 15 00 26
 FF 00 75 08 95 07 B1 02 C0

Signed-off-by: David Phillips <david@profile.sh>
---
 drivers/hid/Kconfig      |  1 +
 drivers/hid/hid-elecom.c | 16 ++++++++++++++++
 drivers/hid/hid-ids.h    |  3 +++
 drivers/hid/hid-quirks.c |  3 +++
 4 files changed, 23 insertions(+)

diff --git a/drivers/hid/Kconfig b/drivers/hid/Kconfig
index 920a64b66b25..6ff4a3ad34cb 100644
--- a/drivers/hid/Kconfig
+++ b/drivers/hid/Kconfig
@@ -369,6 +369,7 @@ config HID_ELECOM
 	  - EX-G Trackballs (M-XT3DRBK, M-XT3URBK)
 	  - DEFT Trackballs (M-DT1DRBK, M-DT1URBK, M-DT2DRBK, M-DT2URBK)
 	  - HUGE Trackballs (M-HT1DRBK, M-HT1URBK)
+	  - HUGE Plus Trackball (M-HT1MRBK)
 
 config HID_ELO
 	tristate "ELO USB 4000/4500 touchscreen"
diff --git a/drivers/hid/hid-elecom.c b/drivers/hid/hid-elecom.c
index 2003d2dcda7c..37d88ce57f67 100644
--- a/drivers/hid/hid-elecom.c
+++ b/drivers/hid/hid-elecom.c
@@ -5,6 +5,7 @@
  *  - EX-G Trackballs (M-XT3DRBK, M-XT3URBK, M-XT4DRBK)
  *  - DEFT Trackballs (M-DT1DRBK, M-DT1URBK, M-DT2DRBK, M-DT2URBK)
  *  - HUGE Trackballs (M-HT1DRBK, M-HT1URBK)
+ *  - HUGE Plus Trackball (M-HT1MRBK)
  *
  *  Copyright (c) 2010 Richard Nauber <Richard.Nauber@gmail.com>
  *  Copyright (c) 2016 Yuxuan Shui <yshuiv7@gmail.com>
@@ -123,12 +124,25 @@ static const __u8 *elecom_report_fixup(struct hid_device *hdev, __u8 *rdesc,
 		 */
 		mouse_button_fixup(hdev, rdesc, *rsize, 22, 30, 24, 16, 8);
 		break;
+	case USB_DEVICE_ID_ELECOM_M_HT1MRBK:
+	case USB_DEVICE_ID_ELECOM_M_HT1MRBK_01AB:
+	case USB_DEVICE_ID_ELECOM_M_HT1MRBK_01AC:
+		/*
+		 * Report descriptor format:
+		 * 24: button bit count
+		 * 28: padding bit count
+		 * 22: button report size
+		 * 16: button usage maximum
+		 */
+		mouse_button_fixup(hdev, rdesc, *rsize, 24, 28, 22, 16, 8);
+		break;
 	}
 	return rdesc;
 }
 
 static const struct hid_device_id elecom_devices[] = {
 	{ HID_BLUETOOTH_DEVICE(USB_VENDOR_ID_ELECOM, USB_DEVICE_ID_ELECOM_BM084) },
+	{ HID_BLUETOOTH_DEVICE(USB_VENDOR_ID_ELECOM, USB_DEVICE_ID_ELECOM_M_HT1MRBK_01AC) },
 	{ HID_USB_DEVICE(USB_VENDOR_ID_ELECOM, USB_DEVICE_ID_ELECOM_M_XGL20DLBK) },
 	{ HID_USB_DEVICE(USB_VENDOR_ID_ELECOM, USB_DEVICE_ID_ELECOM_M_XT3URBK_00FB) },
 	{ HID_USB_DEVICE(USB_VENDOR_ID_ELECOM, USB_DEVICE_ID_ELECOM_M_XT3URBK_018F) },
@@ -142,6 +156,8 @@ static const struct hid_device_id elecom_devices[] = {
 	{ HID_USB_DEVICE(USB_VENDOR_ID_ELECOM, USB_DEVICE_ID_ELECOM_M_HT1URBK_019B) },
 	{ HID_USB_DEVICE(USB_VENDOR_ID_ELECOM, USB_DEVICE_ID_ELECOM_M_HT1DRBK_010D) },
 	{ HID_USB_DEVICE(USB_VENDOR_ID_ELECOM, USB_DEVICE_ID_ELECOM_M_HT1DRBK_011C) },
+	{ HID_USB_DEVICE(USB_VENDOR_ID_ELECOM, USB_DEVICE_ID_ELECOM_M_HT1MRBK) },
+	{ HID_USB_DEVICE(USB_VENDOR_ID_ELECOM, USB_DEVICE_ID_ELECOM_M_HT1MRBK_01AB) },
 	{ }
 };
 MODULE_DEVICE_TABLE(hid, elecom_devices);
diff --git a/drivers/hid/hid-ids.h b/drivers/hid/hid-ids.h
index 9c2bf584d9f6..c9b07890a808 100644
--- a/drivers/hid/hid-ids.h
+++ b/drivers/hid/hid-ids.h
@@ -465,6 +465,9 @@
 #define USB_DEVICE_ID_ELECOM_M_HT1URBK_019B	0x019b
 #define USB_DEVICE_ID_ELECOM_M_HT1DRBK_010D	0x010d
 #define USB_DEVICE_ID_ELECOM_M_HT1DRBK_011C	0x011c
+#define USB_DEVICE_ID_ELECOM_M_HT1MRBK	0x01aa
+#define USB_DEVICE_ID_ELECOM_M_HT1MRBK_01AB	0x01ab
+#define USB_DEVICE_ID_ELECOM_M_HT1MRBK_01AC	0x01ac
 
 #define USB_VENDOR_ID_DREAM_CHEEKY	0x1d34
 #define USB_DEVICE_ID_DREAM_CHEEKY_WN	0x0004
diff --git a/drivers/hid/hid-quirks.c b/drivers/hid/hid-quirks.c
index 11438039cdb7..3217e436c052 100644
--- a/drivers/hid/hid-quirks.c
+++ b/drivers/hid/hid-quirks.c
@@ -420,6 +420,7 @@ static const struct hid_device_id hid_have_special_driver[] = {
 #if IS_ENABLED(CONFIG_HID_ELECOM)
 	{ HID_BLUETOOTH_DEVICE(USB_VENDOR_ID_ELECOM, USB_DEVICE_ID_ELECOM_BM084) },
 	{ HID_BLUETOOTH_DEVICE(USB_VENDOR_ID_ELECOM, USB_DEVICE_ID_ELECOM_M_XGL20DLBK) },
+	{ HID_BLUETOOTH_DEVICE(USB_VENDOR_ID_ELECOM, USB_DEVICE_ID_ELECOM_M_HT1MRBK_01AC) },
 	{ HID_USB_DEVICE(USB_VENDOR_ID_ELECOM, USB_DEVICE_ID_ELECOM_M_XT3URBK_00FB) },
 	{ HID_USB_DEVICE(USB_VENDOR_ID_ELECOM, USB_DEVICE_ID_ELECOM_M_XT3URBK_018F) },
 	{ HID_USB_DEVICE(USB_VENDOR_ID_ELECOM, USB_DEVICE_ID_ELECOM_M_XT3DRBK_00FC) },
@@ -432,6 +433,8 @@ static const struct hid_device_id hid_have_special_driver[] = {
 	{ HID_USB_DEVICE(USB_VENDOR_ID_ELECOM, USB_DEVICE_ID_ELECOM_M_HT1URBK_019B) },
 	{ HID_USB_DEVICE(USB_VENDOR_ID_ELECOM, USB_DEVICE_ID_ELECOM_M_HT1DRBK_010D) },
 	{ HID_USB_DEVICE(USB_VENDOR_ID_ELECOM, USB_DEVICE_ID_ELECOM_M_HT1DRBK_011C) },
+	{ HID_USB_DEVICE(USB_VENDOR_ID_ELECOM, USB_DEVICE_ID_ELECOM_M_HT1MRBK) },
+	{ HID_USB_DEVICE(USB_VENDOR_ID_ELECOM, USB_DEVICE_ID_ELECOM_M_HT1MRBK_01AB) },
 #endif
 #if IS_ENABLED(CONFIG_HID_ELO)
 	{ HID_USB_DEVICE(USB_VENDOR_ID_ELO, 0x0009) },

---
base-commit: 79b95d74470dd97d7d0908d5a3c0734a23e51aa4
change-id: 20260123-hid-elecom-huge-plus-fix-545cf029fd1a

Best regards,
-- 
David Phillips <david@profile.sh>

