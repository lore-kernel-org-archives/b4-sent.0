From: =?utf-8?q?Nikolaj_Klitlund_B=C3=B8rty?= <nbn@sj.dk>
Date: Sat, 05 Sep 2026 14:05:12 +0200
Subject: [PATCH] Bluetooth: btusb: Add device ID for Realtek RTL8761BUE
 (StarTech AV53C1)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260905-startech-av53c1-v1-1-3385f9bb220c@sj.dk>
X-B4-Tracking: v=1; b=H4sIAHcFnGoC/x3MQQqAIBBA0avIrBPUsqirRAubxppNhYoE0t2Tl
 m/xf4FIgSnCJAoEyhz5Oit0IwAPd+4keasGo0yvRmVlTC4kwkO6bFvUUq8d2dYbq3GAWt2BPD/
 /cV7e9wNlCZg3YQAAAA==
X-Change-ID: 20260905-startech-av53c1-1b4e53f251c7
To: Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: linux-bluetooth@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, =?utf-8?q?Nikolaj_Klitlund_B=C3=B8rty?= <nbn@sj.dk>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788609911; l=2680;
 i=nbn@sj.dk; s=20260905; h=from:subject:message-id;
 bh=qikB7+kXC0YvR5kdQ4345D7/gSWOZ6njl78gr4Q01Mc=;
 b=KvlU26Ro04cGwNSf5bWuo5LvGwBncPF0PXfBHwsjW6ROazoTYySahibtxhOFiV3/0PuoK3dqP
 L/xMQdFIWkzDD18eU1CaGm6EAv6HszIS9+xbLfUElaHsJBhPP7Vrk57
X-Developer-Key: i=nbn@sj.dk; a=ed25519;
 pk=gSabhnk9EeLlA58h6ZHttMKWKQwb5LGja3BORiZv9gQ=
X-Endpoint-Received: by B4 Relay for nbn@sj.dk/20260905 with auth_id=1005
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the USB ID 0x14b0:0x047a for the StarTech AV53C1-USB-BLUETOOTH
adapter, a Realtek RTL8761BUE based Bluetooth 5.3 dongle.

Without this entry btusb treats the device as a generic Bluetooth
adapter and never loads the Realtek firmware, leaving the controller on
its ROM firmware. In that state it advertises and scans actively, but
never reports advertisements during passive scanning. LE connections
initiated by the kernel wait for a passive-scan report before issuing
LE Create Connection, so connecting and pairing from BlueZ time out
without any error from the controller.

The same product is also sold with the ID 0x2c0a:0x8761, which is
already supported.

lsusb -v output for the device:

Bus 001 Device 010: ID 14b0:047a StarTech.com Ltd. Bluetooth Radio
Device Descriptor:
  bcdUSB               1.10
  bDeviceClass          224 Wireless
  bDeviceSubClass         1 Radio Frequency
  bDeviceProtocol         1 Bluetooth
  idVendor           0x14b0 StarTech.com Ltd.
  idProduct          0x047a
  bcdDevice            2.00
  iManufacturer           1 Realtek
  iProduct                2 Bluetooth Radio
  iSerial                 3 00E04C239987
  bNumInterfaces          2
    Interface Descriptor:
      bInterfaceClass       224 Wireless
      bInterfaceSubClass      1 Radio Frequency
      bInterfaceProtocol      1 Bluetooth

Cc: stable@vger.kernel.org
Signed-off-by: Nikolaj Klitlund Børty <nbn@sj.dk>
---
Tested on Home Assistant OS 18.2 (kernel 6.18.39): without this entry the
adapter enumerates and scans, but btusb never loads rtl_bt/rtl8761bu_fw.bin,
and LE connections from BlueZ never complete because the controller reports
no advertisements during passive scanning. Details in the commit message.
---
 drivers/bluetooth/btusb.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/bluetooth/btusb.c b/drivers/bluetooth/btusb.c
index d70a3e7a13f5d18c75bc1c9fbc1ac5706e832f61..c3c581a5adbb09f7118a3932cdda210d68d2336d 100644
--- a/drivers/bluetooth/btusb.c
+++ b/drivers/bluetooth/btusb.c
@@ -860,6 +860,8 @@ static const struct usb_device_id quirks_table[] = {
 						     BTUSB_WIDEBAND_SPEECH },
 	{ USB_DEVICE(0x37ad, 0x0600), .driver_info = BTUSB_REALTEK |
 						     BTUSB_WIDEBAND_SPEECH },
+	{ USB_DEVICE(0x14b0, 0x047a), .driver_info = BTUSB_REALTEK |
+						     BTUSB_WIDEBAND_SPEECH },
 
 	/* Additional Realtek 8761CU Bluetooth devices */
 	{ USB_DEVICE(0x0b05, 0x1bef), .driver_info = BTUSB_REALTEK |

---
base-commit: 4d7d9486c04d917265f64c55bd23b2cc4fe7749c
change-id: 20260905-startech-av53c1-1b4e53f251c7

Best regards,
-- 
Nikolaj Klitlund Børty <nbn@sj.dk>

