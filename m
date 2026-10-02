From: Ali Resool Tuama <aliresool567@gmail.com>
Date: Fri, 02 Oct 2026 20:42:12 +0300
Subject: [PATCH v2] USB: quirks: add USB_QUIRK_WINDOWS_CONFIG_REQ_SIZE for
 GameSir G7 SE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261002-master-v2-1-24b05d8792b5@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/2WNwQ7CIBAFf6XZs5hCUxBP/ofpAXDbrpFioDaah
 n+X1qPHSebNWyFhJExwrlaIuFCiMBUQhwrcaKYBGd0Kg6iFrLVQzJs0Y2RKa6ta2zQ1SijyM2J
 P7z107X6cXvaObt7WmzFSmkP87E8L37y/6MIZZ1r2/akVmlvRXgZv6HF0wUOXc/4CMf+HZ64AA
 AA=
X-Change-ID: 20260927-master-799b75b330e6
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Ali Resool Tuama <aliresool567@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790962931; l=2770;
 i=aliresool567@gmail.com; s=20260927; h=from:subject:message-id;
 bh=9ZSSjiM2avTu7kQAcgRfCkpowkxycBnoAQrsblaGhXc=;
 b=k4ZzvnKVBJx+wQg4up7zVG4XrzjB7zf8daV7By0ZeG++iAwrbvWyOA5SianTEDJbYPDJh0VMx
 QroLNjUkNBaDQJCMe30Qo4yDmZJFmklciKHLCtlNWrb+OnaMAhA0Uwj
X-Developer-Key: i=aliresool567@gmail.com; a=ed25519;
 pk=s/zyZoG6z3JyJokqs9ZIcSAb8PgriZ1QW+mgffBV90w=
X-Endpoint-Received: by B4 Relay for aliresool567@gmail.com/20260927 with auth_id=1071
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The GameSir G7 SE wired controller first enumerates as 3537:10a0 and
then re-enumerates in a mode it picks from how the host enumerated it.

When the configuration descriptor is fetched the Linux way, 9 bytes
followed by the full 80, the controller disconnects about 1 ms after
its string descriptors have been read, before SET_CONFIGURATION, and
comes back as 3537:1082, a generic HID gamepad without force feedback.

When the configuration descriptor is fetched in one 255-byte request,
as Windows does, it comes back as 3537:1010 in Xbox One (GIP) mode,
which xpad already supports, including rumble.

Skipping the device qualifier requests (USB_QUIRK_DEVICE_QUALIFIER)
makes no difference; the configuration descriptor request size alone
decides the mode. Add USB_QUIRK_WINDOWS_CONFIG_REQ_SIZE for the 10a0
identity, as is already done for the ShanWan Wireless Gamepad.

Cc: stable@vger.kernel.org
Assisted-by: claude-opus-5-5
Signed-off-by: Ali Resool Tuama <aliresool567@gmail.com>
---
Tested on 7.2.7 (x86_64, xHCI) by setting usbcore.quirks=3537:10a0:r at
runtime. With it, the controller settles as 3537:1010 on every plug-in,
is bound by xpad as "GameSir G7 SE", and rumble works through xpad's
force feedback. Without it, it settles as 3537:1082 every time. The
patch itself is against v7.3-rc5.

usbmon of the 3537:10a0 enumeration without the quirk: GET_DESCRIPTOR
(CONFIGURATION) with wLength 9, then 80, then string descriptors 0, 2,
1 and 3. The port reports a disconnect about 1 ms after the serial
number string, and the SET_CONFIGURATION that follows fails with
-EPROTO. With the quirk, the only difference is a single wLength 255
configuration request, after which the device re-enumerates as
3537:1010.
---
Changes in v2:
- Use my full real name in From: and Signed-off-by:
- Link to v1: https://patch.msgid.link/20260927-master-v1-1-96ff85291b25@gmail.com
---
 drivers/usb/core/quirks.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/usb/core/quirks.c b/drivers/usb/core/quirks.c
index b5b577f..a4bcbe9 100644
--- a/drivers/usb/core/quirks.c
+++ b/drivers/usb/core/quirks.c
@@ -612,6 +612,9 @@ static const struct usb_device_id usb_quirk_list[] = {
 	/* ezcap401 - BOS descriptor fetch hangs at SuperSpeed Plus */
 	{ USB_DEVICE(0x32ed, 0x0401), .driver_info = USB_QUIRK_NO_BOS },
 
+	/* GameSir G7 SE */
+	{ USB_DEVICE(0x3537, 0x10a0), .driver_info = USB_QUIRK_WINDOWS_CONFIG_REQ_SIZE },
+
 	/* DELL USB GEN2 */
 	{ USB_DEVICE(0x413c, 0xb062), .driver_info = USB_QUIRK_NO_LPM | USB_QUIRK_RESET_RESUME },
 

---
base-commit: fd179f8a05be3ccae366b9b96e176b51fbe54aab
change-id: 20260927-master-799b75b330e6

Best regards,
--  
Ali Resool Tuama <aliresool567@gmail.com>

