From: Richard Nunley <richard.w.nunley@gmail.com>
Date: Sun, 09 Aug 2026 15:30:50 -0500
Subject: [PATCH] Bluetooth: btusb: Add Realtek RTL8821CE device 13d3:3558
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260809-master-v1-1-c62bc61debdd@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXM2wpAQBSF4VfRvjY1iPAqcjHGwlYOzUZK3t3g8
 qt/rYsEjiFUBhc5HCy8zB5RGJAdzNxDcetNsY4znetCTUY2OGVgm7xIYLskJR+vDh2f31FV/5a
 9GWG3d033/QBDa/m7agAAAA==
X-Change-ID: 20260809-master-aecb893ecf35
To: Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: linux-bluetooth@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Richard Nunley <richard.w.nunley@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786307454; l=1415;
 i=richard.w.nunley@gmail.com; s=20260809; h=from:subject:message-id;
 bh=wLOaL/YgYl4wu8uYH7L47uT9+N/zEs5F96wJ8v2JHdQ=;
 b=t+NFz1yRiPyBNzMMOkM4oSU1aPF+IkaaUpaC+ZLrI0sI1dIhD97/qyhmj0oDpKbazt9tBk9Li
 tKlTwTRfY0PDaYQUJeMHo43LIE5/vHkljyNnNMG4Aqu1X0CShp2tKEr
X-Developer-Key: i=richard.w.nunley@gmail.com; a=ed25519;
 pk=r+PiBAjnHd6R1vmsv4bP95gslouemyN27nQXIWcK3YQ=
X-Endpoint-Received: by B4 Relay for richard.w.nunley@gmail.com/20260809 with auth_id=930
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The IMC Networks Bluetooth controller with USB ID 13d3:3558 uses an
RTL8821CE. Without BTUSB_REALTEK, btusb uses generic initialization and
does not load the controller firmware. BLE connections then fail before
pairing with HCI error 0x3e.

Add the device ID to the RTL8821CE table. This enables loading
rtl_bt/rtl8821c_fw.bin and rtl_bt/rtl8821c_config.bin, after which a
BLE HID keyboard pairs successfully.

Signed-off-by: Richard Nunley <richard.w.nunley@gmail.com>
---
Tested on a CachyOS 7.1.6 kernel with BlueZ 5.87 and a Corsair K65
Plus BLE keyboard.
---
 drivers/bluetooth/btusb.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/bluetooth/btusb.c b/drivers/bluetooth/btusb.c
index be82bbbc1..2bae85b00 100644
--- a/drivers/bluetooth/btusb.c
+++ b/drivers/bluetooth/btusb.c
@@ -509,6 +509,8 @@ static const struct usb_device_id quirks_table[] = {
 						     BTUSB_WIDEBAND_SPEECH },
 	{ USB_DEVICE(0x13d3, 0x3533), .driver_info = BTUSB_REALTEK |
 						     BTUSB_WIDEBAND_SPEECH },
+	{ USB_DEVICE(0x13d3, 0x3558), .driver_info = BTUSB_REALTEK |
+						     BTUSB_WIDEBAND_SPEECH },
 
 	/* Realtek 8822CE Bluetooth devices */
 	{ USB_DEVICE(0x0bda, 0xb00c), .driver_info = BTUSB_REALTEK |

---
base-commit: 43a556b2fd43f2df6dded59c2e26560a27874c24
change-id: 20260809-master-aecb893ecf35

Best regards,
--  
Richard Nunley <richard.w.nunley@gmail.com>

