From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sat, 13 Jun 2026 18:57:46 -0500
Subject: [PATCH] Input: apple_z2 - bound the device-reported finger count
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260613-b4-disp-f0148c89-v1-1-868a48b2a187@proton.me>
X-B4-Tracking: v=1; b=H4sIAHnuLWoC/x3MQQqAIBBA0avIrBvQErGuEi0yZ2o2JgoRRHdPW
 r7F/w9UKkIVJvVAoUuqnKnBdAq2Y007ocRm6HXvtDMDBotRakbWxvrNjxh55cjB2zAwtCwXYrn
 /5by87weeWEULYgAAAA==
To: Sasha Finkelstein <k@chaosmail.tech>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Janne Grunau <j@jannau.net>, asahi@lists.linux.dev, 
 linux-input@vger.kernel.org, Neal Gompa <neal@gompa.dev>, 
 Sven Peter <sven@kernel.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781395065; l=3970;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=+piORlsZ9G+rq1w4Tyy0/0zNo6jPC9e+Ct0NYcVnLBs=;
 b=dWGh/OzZS92ftQe4q3LGeswyrD8DhpLSDQdRYBZcLlsyMA5R5Ay0ph0okO81sYCXYDNlfdxgV
 dwrdwpqHMvbBYgdgBei/shLH9p8q5q2omiz5EA/FLXV2M0u8RchxPHz
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

apple_z2_parse_touches() takes the finger count from the touch
controller's report and loops over that many fixed-size finger records
without ever checking the count against the length of the report:

	nfingers = msg[APPLE_Z2_NUM_FINGERS_OFFSET];
	fingers = (struct apple_z2_finger *)(msg + APPLE_Z2_FINGERS_OFFSET);
	for (i = 0; i < nfingers; i++)
		/* read fingers[i] ... */

msg points into the fixed 4000-byte z2->rx_buf and nfingers is a single
device-supplied byte, so it can be as large as 255.  A malicious,
malfunctioning or counterfeit controller (or an interposer on the SPI
bus) can report a large finger count in a short packet, making the loop
read up to 255 * sizeof(struct apple_z2_finger) bytes starting 24 bytes
into msg -- far past the 4000-byte buffer.  This is a controller-driven
heap out-of-bounds read, and the finger fields that are read (position,
pressure, touch and tool dimensions) are forwarded to userspace as input
events, leaking adjacent kernel memory.

Bound the device-reported count to the number of finger records the
report actually carries.

Reported-by: sashiko-bot@kernel.org
Closes: https://lore.kernel.org/all/20260613215358.329921F000E9@smtp.kernel.org/
Fixes: 471a92f8a21a ("Input: apple_z2 - add a driver for Apple Z2 touchscreens")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
Reachable on every touch interrupt once the controller is booted
(apple_z2_irq -> apple_z2_read_packet -> apple_z2_parse_touches).

nfingers is a different device field from the packet length handled by
the in-flight "Input: apple_z2 - bound the device-reported packet length"
patch, so the two are orthogonal: that one bounds the spi_read() length
(rx_buf[1..2]); this one bounds the per-report finger count (msg[16]).

The early-return is tightened from NUM_FINGERS_OFFSET (16) to
FINGERS_OFFSET (24) so the subtraction below cannot underflow; since
msg_len == pkt_len - 5 and pkt_len is rounded to a multiple of four, the
only reachable lengths the tighter guard now drops are 19 and 23, both of
which are too short to hold even the finger-array header.

Verified with a faithful in-kernel KASAN litmus (the verbatim 4000-byte
buffer, the struct apple_z2_finger layout and the parse loop),
CONFIG_KASAN=y on x86_64:

  Arm A, nfingers = 255 in a short packet (msg_len 19):
    BUG: KASAN: slab-out-of-bounds in apple_z2_parse_touches
    Read of size 2 ... 1 bytes to the right of allocated 4000-byte region
    ... cache kmalloc-4k of size 4096
  Arm B, with this patch (count clamped to what the packet holds): clean
  Arm C, benign device (3 fingers): clean

  AddressSanitizer (x86_64 and i386): heap-buffer-overflow READ, both ABIs.

Reproducer and full logs available on request.
---
 drivers/input/touchscreen/apple_z2.c | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/drivers/input/touchscreen/apple_z2.c b/drivers/input/touchscreen/apple_z2.c
index 271ababf0ad5..61f353553e7c 100644
--- a/drivers/input/touchscreen/apple_z2.c
+++ b/drivers/input/touchscreen/apple_z2.c
@@ -88,10 +88,13 @@ static void apple_z2_parse_touches(struct apple_z2 *z2,
 	int slot_valid;
 	struct apple_z2_finger *fingers;
 
-	if (msg_len <= APPLE_Z2_NUM_FINGERS_OFFSET)
+	if (msg_len <= APPLE_Z2_FINGERS_OFFSET)
 		return;
 	nfingers = msg[APPLE_Z2_NUM_FINGERS_OFFSET];
 	fingers = (struct apple_z2_finger *)(msg + APPLE_Z2_FINGERS_OFFSET);
+	/* a malicious controller can claim more fingers than the packet holds */
+	nfingers = min_t(int, nfingers,
+			 (msg_len - APPLE_Z2_FINGERS_OFFSET) / sizeof(*fingers));
 	for (i = 0; i < nfingers; i++) {
 		slot = input_mt_get_slot_by_key(z2->input_dev, fingers[i].finger);
 		if (slot < 0) {

---
base-commit: 8e65320d91cdc3b241d4b94855c88459b91abf66
change-id: 20260613-b4-disp-f0148c89-dfafdfb84b3f

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

