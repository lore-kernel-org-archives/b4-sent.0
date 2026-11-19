From: Joan Maillard <joan.md@proton.me>
Date: Fri, 20 Nov 2026 00:47:19 +0100
Subject: [PATCH] Input: xpad - drop truncated Xbox 360 input reports
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-xpad-truncated-v1-1-74514e0498c3@proton.me>
X-B4-Tracking: v=1; b=H4sIAIaK/2oC/x3MTQqAIBBA4avErBOawJ+6SrQQnWo2JlohSHdPW
 n6L9ypkSkwZ5q5Cooczn6EB+w7cYcNOgn0zjMOoEHESJVovrnQHZy/yAqVE5zUZpQ20KCbauPz
 DZX3fDzx2oDVgAAAA
X-Change-ID: 20261119-xpad-truncated-1551cd7e8678
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-input@vger.kernel.org, Joan Maillard <joan.md@proton.me>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795132053; l=5127;
 i=joan.md@proton.me; s=20261119; h=from:subject:message-id;
 bh=tdp62fZVjV9JdeJU7vPAFFDtdaU/xYLcHfV3h/gbUnc=;
 b=+GQZP3vrDf3u3V7oL+0/froD6+KAzdgmO8XVsch5C+L3EF98jhyJX8Cu7WiscZyBJTBf6m2lo
 l/HhV1rFBW+B75jOBi8RTwYlIA3q/NzjncqiwpA0iE6zPsmF+vROfCc
X-Developer-Key: i=joan.md@proton.me; a=ed25519;
 pk=kywOHDNagSGO48kcqDUiYZklWcOrOiU0lmBEaVM3qWk=
X-Endpoint-Received: by B4 Relay for joan.md@proton.me/20261119 with auth_id=1574
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The GuliKit KingKong3 Max (NS39, firmware V5.9) enumerates as a wired
Xbox 360 controller (045e:028e, manufacturer string "Guli") and
occasionally sends truncated input reports. This leads to intrusive
phantom inputs behaving like fast and repeated keypresses, making the
controller unusable while wired.

A usbmon capture over 150 seconds with no buttons pressed contained 156957
regular 20-byte reports, 3012 transfers that failed with -EOVERFLOW,
362 zero-length packets and 284 truncated packets of 6 to 19 bytes,
mostly 16. Every truncated packet arrived within a burst of -EOVERFLOW
errors, most of them directly after one, so the pad appears to
occasionally send oversized transfers of which only a fragment
gets through. Most of the 16-byte packets are the previous report
with its first four bytes missing. For example:

  20 bytes: 00 14 00 00 00 00 67 01 87 01 47 ff 57 ff 00 00 00 00 00 00
  16 bytes:             00 00 67 01 87 01 47 ff 57 ff 00 00 00 00 00 00

xpad360_process_packet() only checks that byte 0 is 0x00, which such a
packet often passes, so the stick values are parsed as buttons and
triggers. With the stick above at rest, userspace sees D-pad left, Back,
left stick click and LB pressed, with the left trigger at 135. The
truncated packets come in bursts, so the phantom presses repeat at about
50 Hz for a few hundred milliseconds. The same pad shows no phantom
inputs on Windows.

Byte 1 of an Xbox 360 input report holds the report length (0x14). Drop
input reports that are shorter than the 14 bytes the parser reads, or
shorter than the length they declare. This leaves complete reports
untouched and does not affect non-input packets, which are already
ignored.

A bug report was also sent to the manufacturer GuliKit.

The diagnosis (analysis of evtest logs and the usbmon capture), the fix
and a first draft of this changelog were produced with the help of an AI
assistant (Claude Opus 5.5 by Anthropic). I reviewed and tested the change.

Signed-off-by: Joan Maillard <joan.md@proton.me>
---
Tested on Debian's 7.2.12 kernel with the KK3 Max; no phantom inputs
made it through to the game during 4 hours of play. I would be happy to make
a short capture run to compare the debug log and a parallel usbmon
capture, along with the commands used to extract them, upon request.

The check is deliberately lenient: it accepts any input report that is at
least 14 bytes long and as long as it declares, so pads that send shorter
but complete reports keep working. A device-specific quirk was
considered, but would be hard to reliably target: the pad uses Microsoft's
VID/PID, and its manufacturer string changed between firmware versions
(specifically, before writing the patch, an older firmware was in the
controller; it reported "FMD" on V3.8, "Guli" on V5.9).

I also considered doing the check inside xpad360_process_packet(), next to
the existing byte 0 check. That function is shared with the wireless receiver
path, which passes the report embedded at offset 4 of a larger frame, so
it would need a length parameter and would change behavior for wireless pads,
which I cannot test. I therefore kept the check in the wired dispatch path;
happy to move it if that is preferred.

Thank you very much for any attention and time you might spend on this
matter.
---
 drivers/input/joystick/xpad.c | 26 ++++++++++++++++++++++++++
 1 file changed, 26 insertions(+)

diff --git a/drivers/input/joystick/xpad.c b/drivers/input/joystick/xpad.c
index d2eb48d98fead7d89eb3e45613a52176c4fa5fad..0a9e23f6b5fd26950335d39a73c5205c879b9f17 100644
--- a/drivers/input/joystick/xpad.c
+++ b/drivers/input/joystick/xpad.c
@@ -1217,6 +1217,30 @@ static void xpadone_process_packet(struct usb_xpad *xpad, u16 cmd, unsigned char
 		input_sync(dev);
 }
 
+/*
+ * Some third-party pads occasionally send truncated input reports, which
+ * xpad360_process_packet() would parse with stick data in the button
+ * fields. Byte 1 of an Xbox 360 input report holds the report length, so
+ * treat an input report as truncated if it is shorter than the 14 bytes
+ * the parser reads or than the length it declares.
+ */
+static bool xpad360_is_truncated(struct usb_xpad *xpad, u32 len)
+{
+	const unsigned char *data = xpad->idata;
+
+	if (data[0] != 0x00)
+		return false;
+
+	if (len >= 14 && data[1] >= 14 && len >= data[1])
+		return false;
+
+	if (len)
+		dev_dbg(&xpad->intf->dev,
+			"dropping truncated report, %u bytes: %*ph\n",
+			len, (int)len, data);
+	return true;
+}
+
 static void xpad_irq_in(struct urb *urb)
 {
 	struct usb_xpad *xpad = urb->context;
@@ -1244,6 +1268,8 @@ static void xpad_irq_in(struct urb *urb)
 
 	switch (xpad->xtype) {
 	case XTYPE_XBOX360:
+		if (xpad360_is_truncated(xpad, urb->actual_length))
+			break;
 		xpad360_process_packet(xpad, xpad->dev, 0, xpad->idata);
 		break;
 	case XTYPE_XBOX360W:

---
base-commit: 8dac6df92a2e66e2098bbc69061964cfe7e8375b
change-id: 20261119-xpad-truncated-1551cd7e8678

Best regards,
-- 
Joan Maillard <joan.md@proton.me>

