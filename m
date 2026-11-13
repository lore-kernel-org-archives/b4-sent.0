From: Lukasz Leczkowski <lukileczo@gmail.com>
Date: Fri, 13 Nov 2026 20:00:32 +0100
Subject: [PATCH] HID: quirks: add ALWAYS_POLL for ASUS ProArt MD301 mouse
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-hid-next-v1-1-864859cc8fb4@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ5AMBCF4avIrDUxRSWuIha0U8aipEWaiLsrl
 l/yv3dBIM8UoM0u8HRy4NUlYJ6Bngc3kWCTDLKQChFLMbMRjuIuKmm1wtrQiA2kfPNkOX5XXf8
 7HONCen/3cN8P+ezjiWwAAAA=
X-Change-ID: 20261113-hid-next-42fc615deb17
To: Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Lukasz Leczkowski <lukileczo@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794596433; l=2708;
 i=lukileczo@gmail.com; s=20261113; h=from:subject:message-id;
 bh=vrTaXFIOa0qeMNOjtZQ1MaWdE3vzSUbRqXS61MDKra8=;
 b=YtJKq1kuIz+V9Y5IJYi9616ZLEmt1o8L5jcyvcPlwa0q6oBdMtK8Y+EtJ0AuLcBPhgtI7JyEb
 tTHHHyzz3U9CNy6VwzAXmIimpkYFgoElJ9KzABTTeZ08aF+s7Un1Mud
X-Developer-Key: i=lukileczo@gmail.com; a=ed25519;
 pk=MiftsQwzsESpOBi4MFSEM/GdQ1AqhJDTUoKXLsZIOBo=
X-Endpoint-Received: by B4 Relay for lukileczo@gmail.com/20261113 with auth_id=1514
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In mouse firmware version 0.00.31 and receiver 0.00.20, the receiver
of the ASUS ProArt MD301 mouse (0b05:1cd3) delays button events
by up to ~500 ms.

The receiver exposes five HID interfaces. Besides the keyboard and mouse
interfaces, interface 4 (vendor usage page 0xffc1) carries a copy of
every button and wheel event as a 64-byte vendor report. As this
interface has no input handlers, usbhid does not poll its interrupt-IN
endpoint unless userspace opens the hidraw node. The firmware appears to
hold back the mouse report on interface 1 until the vendor report has
been read or some timeout expires.

Add HID_QUIRK_ALWAYS_POLL for the receiver so that all of its endpoints
are polled continuously.

The issue was analysed with the help of Claude Code (Claude Opus 5.5),
which captured the raw HID reports, identified the unpolled vendor
interface and drafted this patch.

Tested on 7.3.0 with this patch applied;
clicks are delivered immediately and double-clicks work again.

Signed-off-by: Lukasz Leczkowski <lukileczo@gmail.com>
---
 drivers/hid/hid-ids.h    | 1 +
 drivers/hid/hid-quirks.c | 1 +
 2 files changed, 2 insertions(+)

diff --git a/drivers/hid/hid-ids.h b/drivers/hid/hid-ids.h
index 91319aa65..e638afb1d 100644
--- a/drivers/hid/hid-ids.h
+++ b/drivers/hid/hid-ids.h
@@ -236,6 +236,7 @@
 #define USB_DEVICE_ID_ASUSTEK_FX503VD_KEYBOARD	0x1869
 #define USB_DEVICE_ID_ASUSTEK_XGM_2022	0x1970
 #define USB_DEVICE_ID_ASUSTEK_XGM_2023	0x1a9a
+#define USB_DEVICE_ID_ASUSTEK_MD301_DONGLE	0x1cd3
 
 #define USB_VENDOR_ID_ATEN		0x0557
 #define USB_DEVICE_ID_ATEN_UC100KM	0x2004
diff --git a/drivers/hid/hid-quirks.c b/drivers/hid/hid-quirks.c
index 793db001a..952e1aec1 100644
--- a/drivers/hid/hid-quirks.c
+++ b/drivers/hid/hid-quirks.c
@@ -37,6 +37,7 @@ static const struct hid_device_id hid_quirks[] = {
 	{ HID_USB_DEVICE(USB_VENDOR_ID_ALPS, USB_DEVICE_ID_IBM_GAMEPAD), HID_QUIRK_BADPAD },
 	{ HID_USB_DEVICE(USB_VENDOR_ID_AMI, USB_DEVICE_ID_AMI_VIRT_KEYBOARD_AND_MOUSE), HID_QUIRK_ALWAYS_POLL },
 	{ HID_USB_DEVICE(USB_VENDOR_ID_APPLE, USB_DEVICE_ID_APPLE_ALU_REVB_ANSI), HID_QUIRK_ALWAYS_POLL },
+	{ HID_USB_DEVICE(USB_VENDOR_ID_ASUSTEK, USB_DEVICE_ID_ASUSTEK_MD301_DONGLE), HID_QUIRK_ALWAYS_POLL },
 	{ HID_USB_DEVICE(USB_VENDOR_ID_ATEN, USB_DEVICE_ID_ATEN_2PORTKVM), HID_QUIRK_NOGET },
 	{ HID_USB_DEVICE(USB_VENDOR_ID_ATEN, USB_DEVICE_ID_ATEN_4PORTKVMC), HID_QUIRK_NOGET },
 	{ HID_USB_DEVICE(USB_VENDOR_ID_ATEN, USB_DEVICE_ID_ATEN_4PORTKVM), HID_QUIRK_NOGET },

---
base-commit: 720806515cb6921ab05caaa6f470f7054b56385e
change-id: 20261113-hid-next-42fc615deb17

Best regards,
--  
Lukasz Leczkowski <lukileczo@gmail.com>

