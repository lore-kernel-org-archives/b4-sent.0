From: =?utf-8?q?Gr=C3=A9goire_Stein?= <greyxor@protonmail.com>
Date: Tue, 01 Sep 2026 18:22:10 +0200
Subject: [PATCH] HID: logitech-dj: forward Bolt receiver input to the dj
 child device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260901-bolt-scroll-fix-v1-1-58bca7ae487f@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDSwND3aT8nBLd4uSi/Jwc3bTMCl2DNAtDE0OjtERjU0MloK6ColSgMNj
 E6FgIv7g0KSs1uQRkjFJtLQCmfyvgcwAAAA==
X-Change-ID: 20260901-bolt-scroll-fix-0f81412fa351
To: =?utf-8?q?Filipe_La=C3=ADns?= <lains@riseup.net>, 
 Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>, 
 =?utf-8?q?Erik_H=C3=A5kansson?= <erikhakan@gmail.com>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Gr=C3=A9goire_Stein?= <greyxor@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788279746; l=4267;
 i=greyxor@protonmail.com; s=20260901; h=from:subject:message-id;
 bh=itIUMHlbFIHiCL6Z9BZTI0RVz1yrubLT7rZTaR4xcUs=;
 b=BpfwbfVdt1sbrQZafmBXtfHOu38PI1uFluYELm08MOejPV5ZSkRYIMB0jCgzMjYFaXGBFJYll
 UPX8pcGOqNhDOnCQpWfQC+0KkN4xNoCFRyivZn1vgeZNfok8opYhNE9
X-Developer-Key: i=greyxor@protonmail.com; a=ed25519;
 pk=y2UVq46rpGIETwZNhJelO8GDWaI6jfO2G/BCdy5Vu8U=
X-Endpoint-Received: by B4 Relay for greyxor@protonmail.com/20260901 with auth_id=994
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since Bolt receivers got support in hid-logitech-dj, one detent of the
wheel on an MX Master 4 scrolls 2 to 5 times too far.

For Bolt only LOGITECH_DJ_INTERFACE_NUMBER is kept as a dj interface and
everything else is left as a generic-hid device. Interface 1 therefore
registers an input device of its own, and the paired device's reports
are never forwarded to the dj child device, which ends up receiving
nothing at all.

hid-logitech-hidpp still binds to that child and enables hi-res
scrolling through feature 0x2121. The wheel starts emitting several
ticks per detent, but hidpp_event() applies the multiplier on an input
device that never sees a report. The ticks reach userspace over the
receiver's own mouse interface, where hid-input has no resolution
multiplier and scales each one by 120:

  [Logitech USB Receiver Mouse]      REL_WHEEL=2  REL_WHEEL_HI_RES=240
  [Logitech USB Receiver Mouse]      REL_WHEEL=3  REL_WHEEL_HI_RES=360
  [Logitech Wireless Mouse PID:b042] (nothing)

Interface 0 is the keyboard endpoint, interface 1 the mouse endpoint and
interface 2 carries DJ/HID++, which is the same layout as the other
HID++ receivers. Set no_dj_interfaces to 3 and drop the special case, so
interfaces 0 and 1 are claimed by the dj driver and their reports get
forwarded to the child, where the multiplier is applied.

Bolt support was tested with a keyboard, and a keyboard has no wheel
multiplier to get wrong, which is probably why this was missed.

Fixes: 022eb347ff3a ("HID: logitech: add Bolt receiver support for Logitech HID++ devices")
Signed-off-by: Grégoire Stein <greyxor@protonmail.com>
---
Tested on 7.3-rc1 with an MX Master 4 on a Bolt receiver (046d:c548).
Before the patch one detent gives REL_WHEEL 2-5 / REL_WHEEL_HI_RES
240-600 on the receiver's own mouse endpoint, and the dj child device
gets no reports at all. After it everything comes in on the child device
at 120 per detent.

checkpatch says "trailing statements should be on next line" for the
added case, it is written like the eight cases already in that switch.

I only have a mouse here. Erik, could you check that the MX Keys for
Business still works with this applied?
---
 drivers/hid/hid-logitech-dj.c | 22 +++++-----------------
 1 file changed, 5 insertions(+), 17 deletions(-)

diff --git a/drivers/hid/hid-logitech-dj.c b/drivers/hid/hid-logitech-dj.c
index 1d619d2345e1..5a8f63ced627 100644
--- a/drivers/hid/hid-logitech-dj.c
+++ b/drivers/hid/hid-logitech-dj.c
@@ -1907,9 +1907,6 @@ static int logi_dj_probe(struct hid_device *hdev,
 	 * treat these as logitech-dj interfaces then this causes input events
 	 * reported through this extra interface to not be reported correctly.
 	 * To avoid this, we treat these as generic-hid devices.
-	 *
-	 * Bolt receivers only use LOGITECH_DJ_INTERFACE_NUMBER for receiver
-	 * reporting. Treat all other Bolt interfaces as generic-hid devices.
 	 */
 	switch (id->driver_data) {
 	case recvr_type_dj:		no_dj_interfaces = 3; break;
@@ -1920,23 +1917,14 @@ static int logi_dj_probe(struct hid_device *hdev,
 	case recvr_type_27mhz:		no_dj_interfaces = 2; break;
 	case recvr_type_bluetooth:	no_dj_interfaces = 2; break;
 	case recvr_type_dinovo:		no_dj_interfaces = 2; break;
+	case recvr_type_bolt:		no_dj_interfaces = 3; break;
 	}
 	if (hid_is_usb(hdev)) {
 		intf = to_usb_interface(hdev->dev.parent);
-		if (intf) {
-			bool generic_hid_interface;
-
-			if (id->driver_data == recvr_type_bolt)
-				generic_hid_interface =
-					intf->altsetting->desc.bInterfaceNumber !=
-					LOGITECH_DJ_INTERFACE_NUMBER;
-			else
-				generic_hid_interface =
-					intf->altsetting->desc.bInterfaceNumber >= no_dj_interfaces;
-			if (generic_hid_interface) {
-				hdev->quirks |= HID_QUIRK_INPUT_PER_APP;
-				return hid_hw_start(hdev, HID_CONNECT_DEFAULT);
-			}
+		if (intf && intf->altsetting->desc.bInterfaceNumber >=
+							no_dj_interfaces) {
+			hdev->quirks |= HID_QUIRK_INPUT_PER_APP;
+			return hid_hw_start(hdev, HID_CONNECT_DEFAULT);
 		}
 	}
 

---
base-commit: cee9395acd8043be0644b25c34bfa86623f2b935
change-id: 20260901-bolt-scroll-fix-0f81412fa351

Best regards,
--  
Grégoire Stein <greyxor@protonmail.com>

