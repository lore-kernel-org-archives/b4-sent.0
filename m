From: John Vrachnis <john.al.vra@gmail.com>
Date: Tue, 24 Nov 2026 21:27:27 +0200
Subject: [PATCH] HID: quirks: ignore Sony cameras in USB charging mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-sony-camera-charger-ignore-v1-1-65e457b43241@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/x3MQQrCMBAF0KsMf92BZhpEcxVxEdJpOgsTmYAop
 XcXfAd4B4a66UCiA65vG9YbEoWJUPbcqrKtSASZ5RKCRB69fbnkp3rmsmev6my1dVee5bYsEuO
 2XgUT4eW62eef3x/n+QM1TQSXbAAAAA==
X-Change-ID: 20261124-sony-camera-charger-ignore-02933244fd82
To: Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 John Vrachnis <john.al.vra@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795548451; l=3419;
 i=john.al.vra@gmail.com; s=20261124; h=from:subject:message-id;
 bh=BtH9nhDSGnPZPdnBmfhnyBuwMLusVkripd1HxJKRhfk=;
 b=rN83bbjFc+A+DhXvEnFDgzAwv0Heeh2e3pbBQk2xCKFWFUTfoMxOe3tI9mMMeiIjm0XTjnF/0
 Q+TZ/Y4FAvHC7t8R8DKTY6T/4vE2Tkpl3Dukrb/hhWrA6MXO4rKeI02
X-Developer-Key: i=john.al.vra@gmail.com; a=ed25519;
 pk=dsOoK9BfFDyY0QBd5ot7lbyvsclTm7pCUIO6KCzcalc=
X-Endpoint-Received: by B4 Relay for john.al.vra@gmail.com/20261124 with auth_id=1629
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a Sony camera such as the ILCE-7M3 (A7 III) is switched off and
connected over USB, it enumerates as 054c:0994 "Sony USB Charger" with a
single HID interface. The same ID is used by other models in charging
mode: usb.ids lists it for the ILCE-6000, while each model has its own
IDs for its mass-storage and MTP modes.

Its 19-byte report descriptor declares one 8-bit input with Generic
Desktop usage 0x00 (undefined); the interface does nothing beyond letting
the camera draw charging current.

Sometimes the interface does not answer during probe. usbhid then gives
up after 25 seconds, and the device disconnects:

  usb 1-1: Product: USB Charger
  usb 1-1: Manufacturer: Sony
  usbhid 1-1:1.0: can't add hid device: -110
  usbhid 1-1:1.0: probe with driver usbhid failed with error -110
  usb 1-1: USB disconnect, device number 25

This happened in 2 of 6 connections on an AMD 600-series xHCI
controller. When probing does succeed, a useless "Sony USB Charger"
input device with a single ABS_MISC axis is created instead.

Add the device to hid_ignore_list so usbhid does not bind to it.

Tested on 7.3.4 (Fedora 45) with the equivalent boot parameter
usbhid.quirks=0x054c:0x0994:0x4: 13 connections in charging mode, with
no probe timeout and no input device, and the camera charged its
battery to full.

The problem was found, and this patch and its changelog were drafted,
with the help of an AI assistant (Claude) that analysed the kernel log
and the device's USB and HID descriptors; I reviewed and tested the
change.

Signed-off-by: John Vrachnis <john.al.vra@gmail.com>
---
Side note: the older Sony NEX-5R exposes a similar "USB Charger" HID
interface (054c:05b2, a consumer-control descriptor) in charging mode.
It did not show the probe timeout in 6 connections on the same
controller, so it is not included.
---
 drivers/hid/hid-ids.h    | 1 +
 drivers/hid/hid-quirks.c | 1 +
 2 files changed, 2 insertions(+)

diff --git a/drivers/hid/hid-ids.h b/drivers/hid/hid-ids.h
index c40d818417..854d54003c 100644
--- a/drivers/hid/hid-ids.h
+++ b/drivers/hid/hid-ids.h
@@ -1384,6 +1384,7 @@
 #define USB_DEVICE_ID_SONY_NAVIGATION_CONTROLLER	0x042f
 #define USB_DEVICE_ID_SONY_BUZZ_CONTROLLER		0x0002
 #define USB_DEVICE_ID_SONY_WIRELESS_BUZZ_CONTROLLER	0x1000
+#define USB_DEVICE_ID_SONY_CAMERA_CHARGING	0x0994
 
 #define USB_VENDOR_ID_SONY_RHYTHM	0x12ba
 #define USB_DEVICE_ID_SONY_PS3WIIU_GHLIVE	0x074b
diff --git a/drivers/hid/hid-quirks.c b/drivers/hid/hid-quirks.c
index 39e93b1383..b6db6cd9f1 100644
--- a/drivers/hid/hid-quirks.c
+++ b/drivers/hid/hid-quirks.c
@@ -981,6 +981,7 @@ static const struct hid_device_id hid_ignore_list[] = {
 	{ HID_USB_DEVICE(USB_VENDOR_ID_PHILIPS, USB_DEVICE_ID_PHILIPS_IEEE802154_DONGLE) },
 	{ HID_USB_DEVICE(USB_VENDOR_ID_POWERCOM, USB_DEVICE_ID_POWERCOM_UPS) },
 	{ HID_USB_DEVICE(USB_VENDOR_ID_SAI, USB_DEVICE_ID_CYPRESS_HIDCOM) },
+	{ HID_USB_DEVICE(USB_VENDOR_ID_SONY, USB_DEVICE_ID_SONY_CAMERA_CHARGING) },
 #if IS_ENABLED(CONFIG_MOUSE_SYNAPTICS_USB)
 	{ HID_USB_DEVICE(USB_VENDOR_ID_SYNAPTICS, USB_DEVICE_ID_SYNAPTICS_TP) },
 	{ HID_USB_DEVICE(USB_VENDOR_ID_SYNAPTICS, USB_DEVICE_ID_SYNAPTICS_INT_TP) },

---
base-commit: 4a30b295fc34467e0468a0c8aeef73ecbe876d07
change-id: 20261124-sony-camera-charger-ignore-02933244fd82

Best regards,
-- 
John Vrachnis <john.al.vra@gmail.com>

