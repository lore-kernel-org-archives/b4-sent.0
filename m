From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sat, 13 Jun 2026 21:58:55 -0500
Subject: [PATCH] Input: iforce - bound the device-reported force-feedback
 effect index
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260613-b4-disp-4828d263-v1-1-02320e1a89dd@proton.me>
X-B4-Tracking: v=1; b=H4sIAO4YLmoC/x3MQQqAIBBA0avErBvI0Uy6SrQoHWs2FQoRSHdPW
 r7F/wUyJ+EMY1Mg8S1ZzqNCtQ34fTk2RgnVQB3ZziqNq8Eg+ULjyAWyGvvoVrUMnrSxULMrcZT
 nX07z+34R3CGWYgAAAA==
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781405934; l=5020;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=XxpIXCh7ffZCmu2CG+KPf3GOhwCkdR6xHHjQDVV3JFg=;
 b=oJrxY931L5MvoILgDK06XxvKv8KFwMA0IjyZM+N1uCuzhn3i54GLfqPIpZIpfi17F7buM8BBv
 4/4ldZM6M6oCZBF2wmASg3zEV4+6OekNaWnHT12qJm0yjyH4nDg1kZH
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

iforce_process_packet() handles a status report (packet id 0x02) by
taking a force-feedback effect index straight from the device wire and
using it to address the per-effect state array:

	i = data[1] & 0x7f;
	if (data[1] & 0x80) {
		if (!test_and_set_bit(FF_CORE_IS_PLAYED,
				      iforce->core_effects[i].flags))
			...
	} else if (test_and_clear_bit(FF_CORE_IS_PLAYED,
				      iforce->core_effects[i].flags)) {
		...
	}

The index is masked only with 0x7f, so it ranges 0..127, but
core_effects[] holds only IFORCE_EFFECTS_MAX (32) entries.  For an index
of 32..127 the test_and_set_bit()/test_and_clear_bit() is an
out-of-bounds single-bit read-modify-write past the array.  core_effects[]
is the second-to-last member of struct iforce, so the write lands in the
trailing members and beyond the embedding kzalloc()'d iforce_serio /
iforce_usb object.

data[1] is unvalidated device payload on both transports (the USB
interrupt endpoint and serio), and the status path is not gated on force
feedback being present, so a malicious or counterfeit device can set or
clear a bit at an attacker-chosen offset past the object.

Reject an out-of-range index instead of indexing with it.  Bound against
the array dimension IFORCE_EFFECTS_MAX rather than dev->ff->max_effects so
the check guarantees memory safety regardless of how many effects the
device registered.  A legitimate "effect started/stopped" status always
carries an index below IFORCE_EFFECTS_MAX, so well-formed devices are
unaffected; the neighbouring mark_core_as_ready() loop is already bounded
and is left untouched.

Fixes: 1da177e4c3f4 ("Linux-2.6.12-rc2")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
Reachable from a malicious, malfunctioning or counterfeit iforce
force-feedback device on either transport: a USB device matching the
iforce id table (iforce-usb.c forwards the interrupt-IN buffer as
iforce_process_packet(.., data_in[0], data_in + 1, ..)) or an RS232
iforce peripheral bound via inputattach (iforce-serio.c forwards data_in).
data[1] is never validated on the path, and the 0x02 status block runs
regardless of packet length or whether force feedback was created.

struct iforce embeds core_effects[32] as its second-to-last member and is
itself the first member of the kzalloc()'d iforce_serio / iforce_usb
object (~4.8 KB, kmalloc-8k).  A status report with data[1] = 0x80 | idx
sets bit FF_CORE_IS_PLAYED in core_effects[idx].flags; for idx up to 127
that is about 13 KB past the end of the array.

Verified with a faithful in-kernel KASAN litmus (the verbatim struct
iforce / iforce_serio layout and the case-0x02 effect-index block),
Linux 7.1.0-rc5, CONFIG_KASAN=y, kasan.fault=panic, x86_64:

  Arm A, status report effect index 57 (chosen to clear the kmalloc-8k
  bucket; KASAN's kmalloc redzone already trips from index 32):
    BUG: KASAN: slab-out-of-bounds in ... Write of size 8
    located 3440 bytes to the right of the allocated 4840-byte region
    ... cache kmalloc-8k of size 8192
    Kernel panic - not syncing: kasan.fault=panic set
  Arm B, with this patch (index bounded): clean
  Arm C, benign in-range index: clean

  AddressSanitizer (x86_64 and i386): heap-buffer-overflow WRITE, both ABIs.

The "Write of size 8" is the test_and_set_bit() read-modify-write on the
flags long.  Reproducer and full logs available on request.
---
 drivers/input/joystick/iforce/iforce-packets.c | 18 +++++++++++-------
 1 file changed, 11 insertions(+), 7 deletions(-)

diff --git a/drivers/input/joystick/iforce/iforce-packets.c b/drivers/input/joystick/iforce/iforce-packets.c
index fd1cd731d781..ff266568d586 100644
--- a/drivers/input/joystick/iforce/iforce-packets.c
+++ b/drivers/input/joystick/iforce/iforce-packets.c
@@ -186,14 +186,18 @@ void iforce_process_packet(struct iforce *iforce,
 
 		/* Check if an effect was just started or stopped */
 		i = data[1] & 0x7f;
-		if (data[1] & 0x80) {
-			if (!test_and_set_bit(FF_CORE_IS_PLAYED, iforce->core_effects[i].flags)) {
-				/* Report play event */
-				input_report_ff_status(dev, i, FF_STATUS_PLAYING);
+		if (i < IFORCE_EFFECTS_MAX) {
+			unsigned long *flags = iforce->core_effects[i].flags;
+
+			if (data[1] & 0x80) {
+				if (!test_and_set_bit(FF_CORE_IS_PLAYED, flags)) {
+					/* Report play event */
+					input_report_ff_status(dev, i, FF_STATUS_PLAYING);
+				}
+			} else if (test_and_clear_bit(FF_CORE_IS_PLAYED, flags)) {
+				/* Report stop event */
+				input_report_ff_status(dev, i, FF_STATUS_STOPPED);
 			}
-		} else if (test_and_clear_bit(FF_CORE_IS_PLAYED, iforce->core_effects[i].flags)) {
-			/* Report stop event */
-			input_report_ff_status(dev, i, FF_STATUS_STOPPED);
 		}
 
 		for (j = 3; j < len; j += 2)

---
base-commit: 8e65320d91cdc3b241d4b94855c88459b91abf66
change-id: 20260613-b4-disp-4828d263-5f8b1a7c2346

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

