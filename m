From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sat, 13 Jun 2026 20:07:20 -0500
Subject: [PATCH] Input: touchwin - reset the packet index on every complete
 packet
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260613-b4-disp-69921bfd-v1-1-82c036899959@proton.me>
X-B4-Tracking: v=1; b=H4sIAMf+LWoC/x3MPQqAMAxA4atIZgP9s6JXEQdrUs2i0oIIxbtbH
 L/hvQKZk3CGsSmQ+JYs51Gh2wbWfTk2RqFqMMp45bXF4JAkX+iHwegQCVWnlbdEiws91OxKHOX
 5l9P8vh90H9uaYgAAAA==
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-input@vger.kernel.org, Rick Koch <n1gp@hotmail.com>, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781399239; l=3554;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=0xJe696QjnZ2WzWwmJYPtlGz8d7L6oa0Pm0tSupjsa8=;
 b=DwvXmr0m0s2O2ewItgGBjfV7+FW0FarE4EcYbadYvnw5OSTm66d0MWo0KkGzcuguM3gGTz9tV
 o3z5CRV5+KEAPLbH8OC6XaNMwGy0YBONKwsebqSO1mEZ+vHKOfFZgEu
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tw_interrupt() accumulates each non-zero serial byte into a fixed
three-byte buffer with a running index that is only reset once a full
packet has been received *and* the device's two Y bytes agree:

	tw->data[tw->idx++] = data;
	if (tw->idx == TW_LENGTH && tw->data[1] == tw->data[2]) {
		...
		tw->idx = 0;
	}

The reset is gated on tw->data[1] == tw->data[2], a value the device
controls.  A malicious, malfunctioning or counterfeit Touchwindow
peripheral can stream non-zero bytes whose 2nd and 3rd bytes differ: the
index reaches TW_LENGTH without the equality holding, is never reset, and
keeps growing, so tw->data[tw->idx++] walks off the end of the three-byte
array and the rest of the heap-allocated struct tw, one attacker-chosen
byte at a time -- an unbounded, device-driven heap out-of-bounds write.

Reset the index on every completed packet and report an event only when
the two Y bytes match, like the other serio touchscreen drivers do.

Fixes: 11ea3173d5f2 ("Input: add driver for Touchwin serial touchscreens")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
Reachable on every serial byte once the device is bound as SERIO_TOUCHWIN
(inputattach --touchwin): serport_ldisc_receive -> serio_interrupt ->
tw_interrupt, with no length validation on the path.  The peripheral need
only avoid zero bytes (any data != 0) and send a 2nd byte different from
the 3rd to defeat the reset.

struct tw is a 64-byte kmalloc-64 object; the unbounded store crosses the
allocation once the running index reaches 40.

Verified with a faithful in-kernel KASAN litmus (the verbatim struct tw
and the tw_interrupt accumulation), CONFIG_KASAN=y on x86_64:

  Arm A, 64 non-zero bytes with byte[1] != byte[2]:
    BUG: KASAN: slab-out-of-bounds in ... Write of size 1
    located 0 bytes to the right of the allocated 64-byte region
    ... cache kmalloc-64 of size 64
  Arm B, with this patch (index reset every packet): clean
  Arm C, benign device (byte[1] == byte[2]): clean

  AddressSanitizer (x86_64 and i386): heap-buffer-overflow WRITE, both ABIs.

Reproducer and full logs available on request.
---
 drivers/input/touchscreen/touchwin.c | 15 +++++++++------
 1 file changed, 9 insertions(+), 6 deletions(-)

diff --git a/drivers/input/touchscreen/touchwin.c b/drivers/input/touchscreen/touchwin.c
index 099fd88e65d8..3ed33378dfcd 100644
--- a/drivers/input/touchscreen/touchwin.c
+++ b/drivers/input/touchscreen/touchwin.c
@@ -63,12 +63,15 @@ static irqreturn_t tw_interrupt(struct serio *serio,
 	if (data) {		/* touch */
 		tw->touched = 1;
 		tw->data[tw->idx++] = data;
-		/* verify length and that the two Y's are the same */
-		if (tw->idx == TW_LENGTH && tw->data[1] == tw->data[2]) {
-			input_report_abs(dev, ABS_X, tw->data[0]);
-			input_report_abs(dev, ABS_Y, tw->data[1]);
-			input_report_key(dev, BTN_TOUCH, 1);
-			input_sync(dev);
+		/* a full packet ends the accumulation, valid or not */
+		if (tw->idx == TW_LENGTH) {
+			/* report only if the two Y's are the same */
+			if (tw->data[1] == tw->data[2]) {
+				input_report_abs(dev, ABS_X, tw->data[0]);
+				input_report_abs(dev, ABS_Y, tw->data[1]);
+				input_report_key(dev, BTN_TOUCH, 1);
+				input_sync(dev);
+			}
 			tw->idx = 0;
 		}
 	} else if (tw->touched) {	/* untouch */

---
base-commit: 8e65320d91cdc3b241d4b94855c88459b91abf66
change-id: 20260613-b4-disp-69921bfd-051063dda4b7

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

