From: Krzysztof Furman <krisfur@proton.me>
Date: Fri, 09 Oct 2026 15:47:10 +0100
Subject: [PATCH] Input: xpad - add support for Corsair Novablade Pro
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261009-xpad-corsair-novablade-v1-1-e58746bef99f@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQrCMAyA4VcZORtoK6zMVxEPWRs1Iu1IdAzG3
 n2dHr/D/69grMIGl24F5VlMamnwpw7Sk8qDUXIzBBd679yAy0QZU1UjUSx1pvFNmfEcKEQfAw1
 9hBZPyndZfuPr7W/7ji9On+MG27YDCXq0b3oAAAA=
X-Change-ID: 20261009-xpad-corsair-novablade-32a27172a967
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Krzysztof Furman <krisfur@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791557242; l=2357;
 i=krisfur@proton.me; s=20261009; h=from:subject:message-id;
 bh=ajmN4wE5ck5/WbQMqQHqcLzqggS+I8lqcfuBpb4LQN4=;
 b=wzJJIbfQiRN5ky9nCpFii1qs1PySNhBwCcTc84sMUoo2+khwff3rbZTzDbC52zM6Y8jB/LR/s
 Cl0Mscxp8TuDiiuhS482ab8w28WJcxQ1TCOB0A1qd17f/NJb+Y1S5Kj
X-Developer-Key: i=krisfur@proton.me; a=ed25519;
 pk=qWf2loGTQN6F4MMZofmcek16QZYEtENBLRL0vg4m0F0=
X-Endpoint-Received: by B4 Relay for krisfur@proton.me/20261009 with auth_id=1142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add device IDs for the Corsair Novablade Pro leverless fight controller
in both wired (0x2b1f) and 2.4 GHz receiver (0x2b2b) modes, and add
Corsair's vendor ID to the Xbox 360 vendor match list.

Outside of its PS4/PS5 modes the controller uses the Xbox 360 protocol
(vendor-specific class, subclass 93, protocol 1) on interface 0, which
xpad does not currently bind, so no gamepad device is created. The
PS4/PS5 modes present a standard HID gamepad and already work with
hid-generic.

Tested on 7.2.5 with the 2.4 GHz receiver and wired.

Assisted-by: Claude Opus 5.5
Signed-off-by: Krzysztof Furman <krisfur@proton.me>
---
The PS5 mode (0x2b27) presents a plain HID gamepad and needs no xpad
change, so it is not included.
---
 drivers/input/joystick/xpad.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/input/joystick/xpad.c b/drivers/input/joystick/xpad.c
index feb8f368f..51f889389 100644
--- a/drivers/input/joystick/xpad.c
+++ b/drivers/input/joystick/xpad.c
@@ -295,6 +295,8 @@ static const struct xpad_device {
 	{ 0x17ef, 0x6182, "Lenovo Legion Controller for Windows", 0, XTYPE_XBOX360 },
 	{ 0x1949, 0x041a, "Amazon Game Controller", 0, XTYPE_XBOX360 },
 	{ 0x1a86, 0xe310, "Legion Go S", 0, XTYPE_XBOX360 },
+	{ 0x1b1c, 0x2b1f, "Corsair Novablade Pro (Wired)", 0, XTYPE_XBOX360 },
+	{ 0x1b1c, 0x2b2b, "Corsair Novablade Pro (2.4 GHz Receiver)", 0, XTYPE_XBOX360 },
 	{ 0x1bad, 0x0002, "Harmonix Rock Band Guitar", 0, XTYPE_XBOX360 },
 	{ 0x1bad, 0x0003, "Harmonix Rock Band Drumkit", MAP_DPAD_TO_BUTTONS, XTYPE_XBOX360 },
 	{ 0x1bad, 0x0130, "Ion Drum Rocker", MAP_DPAD_TO_BUTTONS, XTYPE_XBOX360 },
@@ -536,6 +538,7 @@ static const struct usb_device_id xpad_table[] = {
 	XPAD_XBOX360_VENDOR(0x17ef),		/* Lenovo */
 	XPAD_XBOX360_VENDOR(0x1949),		/* Amazon controllers */
 	XPAD_XBOX360_VENDOR(0x1a86),		/* Nanjing Qinheng Microelectronics (WCH) */
+	XPAD_XBOX360_VENDOR(0x1b1c),		/* Corsair controllers */
 	XPAD_XBOX360_VENDOR(0x1bad),		/* Harmonix Rock Band guitar and drums */
 	XPAD_XBOX360_VENDOR(0x1ee9),		/* ZOTAC Technology Limited */
 	XPAD_XBOX360_VENDOR(0x20bc),		/* BETOP wireless dongles */

---
base-commit: 1a3ba2dc2b91d50201a9d4721f166e68f4903eb6
change-id: 20261009-xpad-corsair-novablade-32a27172a967

Best regards,
--  
Krzysztof Furman <krisfur@proton.me>

