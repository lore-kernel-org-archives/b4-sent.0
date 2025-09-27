From: Levi Zim <rsworktech@outlook.com>
Date: Sat, 27 Sep 2025 10:29:42 +0800
Subject: [PATCH] Bluetooth: btusb: Add one more ID 0x13d3:0x3612 for
 Realtek 8852CE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250927-ble-13d3-3612-v1-1-c62bbb0bc77c@outlook.com>
X-B4-Tracking: v=1; b=H4sIABVM12gC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDSyNz3aScVF1D4xRjXWMzQyNdU+NEIyMTs1QTCzMjJaCegqLUtMwKsHn
 RsbW1AMMgODpfAAAA
X-Change-ID: 20250927-ble-13d3-3612-53a2246e4862
To: Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: linux-bluetooth@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Levi Zim <rsworktech@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2697;
 i=rsworktech@outlook.com; s=ryzen; h=from:subject:message-id;
 bh=0PHaemvygidLVIPnBlULH0clIkTjQK06pLw2gSJsUyg=;
 b=owEBbQKS/ZANAwAKAW87mNQvxsnYAcsmYgBo10wWJwpMWJDI6Gv60GqMSHPYr0X1WYBzIct1+
 lw0sH6qYJiJAjMEAAEKAB0WIQQolnD5HDY18KF0JEVvO5jUL8bJ2AUCaNdMFgAKCRBvO5jUL8bJ
 2OsoD/0WSK8QvBcFB1Z4C7W03UKv7j22OBBm+Vhel+zEYq+fGvYoBZFNLr8M88HMMfSDHkVFD3l
 qFoIoQZ4UDS2kUdj/n0E+DcdOgjhGpxsoMKrMskpL5m71FoZTFGwRxRX8QQmhZr1jgMIMF74rJP
 lN2bV07z+Y/11la2SaPt1iSfmr6w6+CmWJeMbOCYDKkgo4HLVJyJvhUCsWwZyrntY+JvBp6VPFX
 cnLItdUixcYQgD+fn3M5sbrZVOCQmn/QbCz6keOuAQcLHzHw5Z33VM/QVjot7d5g2auSEvJRpQA
 Ug32gZBfp4wIWD0Ja/4OdDt13kZfh+qoZT4RcpbDTMSMDbH1v+V7QFwTiG2w0usB7KZ87cJQOu8
 Zv5ItzoshBPsndHZNiMt+YlA0nHZhQszuL5MqJagt7CK78sVmadlLQ7M7ZLrmd36kfDXqkQHgnP
 r5mEgLgeQH9PN/35Rq/WjoJHgVlMbGTOfNHkUkXBqnRhlLjv4/i+wXpeJrt4WviNZWC/yX71rP2
 9fhSYWHqayVGxHWc8GNBhwPmTr/biFiL0uqsILNCdCMd3UQPXL9HJyIzF5bhabplB8Jt6XuC4s7
 S96EVjihqO59jkkpSyWuTYf6oB0MtVzyaVECtcXZXyzPbedCOxOHmqSENr3UyHuvXxOOKXywAYK
 pOrKoyEUswevf2g==
X-Developer-Key: i=rsworktech@outlook.com; a=openpgp;
 fpr=17AADD6726DDC58B8EE5881757670CCFA42CCF0A
X-Endpoint-Received: by B4 Relay for rsworktech@outlook.com/ryzen with auth_id=536
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Devices with ID 13d3:3612 are found in ASUS TUF Gaming A16 (2025)
and ASUS TX Gaming FA608FM.

The corresponding device info from /sys/kernel/debug/usb/devices is

T:  Bus=03 Lev=02 Prnt=03 Port=02 Cnt=02 Dev#=  6 Spd=12   MxCh= 0
D:  Ver= 1.00 Cls=e0(wlcon) Sub=01 Prot=01 MxPS=64 #Cfgs=  1
P:  Vendor=13d3 ProdID=3612 Rev= 0.00
S:  Manufacturer=Realtek
S:  Product=Bluetooth Radio
C:* #Ifs= 2 Cfg#= 1 Atr=e0 MxPwr=500mA
I:* If#= 0 Alt= 0 #EPs= 3 Cls=e0(wlcon) Sub=01 Prot=01 Driver=btusb
E:  Ad=81(I) Atr=03(Int.) MxPS=  16 Ivl=1ms
E:  Ad=02(O) Atr=02(Bulk) MxPS=  64 Ivl=0ms
E:  Ad=82(I) Atr=02(Bulk) MxPS=  64 Ivl=0ms
I:* If#= 1 Alt= 0 #EPs= 2 Cls=e0(wlcon) Sub=01 Prot=01 Driver=btusb
E:  Ad=03(O) Atr=01(Isoc) MxPS=   0 Ivl=1ms
E:  Ad=83(I) Atr=01(Isoc) MxPS=   0 Ivl=1ms
I:  If#= 1 Alt= 1 #EPs= 2 Cls=e0(wlcon) Sub=01 Prot=01 Driver=btusb
E:  Ad=03(O) Atr=01(Isoc) MxPS=   9 Ivl=1ms
E:  Ad=83(I) Atr=01(Isoc) MxPS=   9 Ivl=1ms
I:  If#= 1 Alt= 2 #EPs= 2 Cls=e0(wlcon) Sub=01 Prot=01 Driver=btusb
E:  Ad=03(O) Atr=01(Isoc) MxPS=  17 Ivl=1ms
E:  Ad=83(I) Atr=01(Isoc) MxPS=  17 Ivl=1ms
I:  If#= 1 Alt= 3 #EPs= 2 Cls=e0(wlcon) Sub=01 Prot=01 Driver=btusb
E:  Ad=03(O) Atr=01(Isoc) MxPS=  25 Ivl=1ms
E:  Ad=83(I) Atr=01(Isoc) MxPS=  25 Ivl=1ms
I:  If#= 1 Alt= 4 #EPs= 2 Cls=e0(wlcon) Sub=01 Prot=01 Driver=btusb
E:  Ad=03(O) Atr=01(Isoc) MxPS=  33 Ivl=1ms
E:  Ad=83(I) Atr=01(Isoc) MxPS=  33 Ivl=1ms
I:  If#= 1 Alt= 5 #EPs= 2 Cls=e0(wlcon) Sub=01 Prot=01 Driver=btusb
E:  Ad=03(O) Atr=01(Isoc) MxPS=  49 Ivl=1ms
E:  Ad=83(I) Atr=01(Isoc) MxPS=  49 Ivl=1ms
I:  If#= 1 Alt= 6 #EPs= 2 Cls=e0(wlcon) Sub=01 Prot=01 Driver=btusb
E:  Ad=03(O) Atr=01(Isoc) MxPS=  63 Ivl=1ms
E:  Ad=83(I) Atr=01(Isoc) MxPS=  63 Ivl=1ms

Signed-off-by: Levi Zim <rsworktech@outlook.com>
---
 drivers/bluetooth/btusb.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/bluetooth/btusb.c b/drivers/bluetooth/btusb.c
index 8085fabadde8ff01171783b59226589757bbbbbc..d1e62b3158166a33153a6dfaade03fd3fb7d8231 100644
--- a/drivers/bluetooth/btusb.c
+++ b/drivers/bluetooth/btusb.c
@@ -552,6 +552,8 @@ static const struct usb_device_id quirks_table[] = {
 						     BTUSB_WIDEBAND_SPEECH },
 	{ USB_DEVICE(0x13d3, 0x3592), .driver_info = BTUSB_REALTEK |
 						     BTUSB_WIDEBAND_SPEECH },
+	{ USB_DEVICE(0x13d3, 0x3612), .driver_info = BTUSB_REALTEK |
+						     BTUSB_WIDEBAND_SPEECH },
 	{ USB_DEVICE(0x0489, 0xe122), .driver_info = BTUSB_REALTEK |
 						     BTUSB_WIDEBAND_SPEECH },
 

---
base-commit: 302a1f674c00dd5581ab8e493ef44767c5101aab
change-id: 20250927-ble-13d3-3612-53a2246e4862

Best regards,
-- 
Levi Zim <rsworktech@outlook.com>

