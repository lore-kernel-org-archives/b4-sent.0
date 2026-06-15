From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Mon, 15 Jun 2026 13:20:52 -0500
Subject: [PATCH v3 2/2] Input: apple_z2 - bound the device-reported finger
 count
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260615-b4-disp-05943ee1-v3-2-bbfe1b651613@proton.me>
References: <20260615-b4-disp-05943ee1-v3-0-bbfe1b651613@proton.me>
In-Reply-To: <20260615-b4-disp-05943ee1-v3-0-bbfe1b651613@proton.me>
To: Sasha Finkelstein <k@chaosmail.tech>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Neal Gompa <neal@gompa.dev>, asahi@lists.linux.dev, 
 Sven Peter <sven@kernel.org>, linux-input@vger.kernel.org, 
 Janne Grunau <j@jannau.net>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781547650; l=2830;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=DVQu2uvhJW5sxa7z9aTL83zmiULcE9bwvHJa+3o4ZK8=;
 b=AcyRZ+eyXLTDZ7XtLCTaXD0RmLR9HF3B9i/TUyNlGUymo09wMpiy7P0RRMNzX3EZcgYG0tVbT
 HmIzYzNQp4QCQOm83x1PjR/Jg+hSpBXUwYryjezAOHrgMqUWmME5NNd
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

apple_z2_parse_touches() takes the finger count from the touch
controller's report and loops over that many fixed-size finger records
without checking the count against the length of the report:

	nfingers = msg[APPLE_Z2_NUM_FINGERS_OFFSET];
	fingers = (struct apple_z2_finger *)(msg + APPLE_Z2_FINGERS_OFFSET);
	for (i = 0; i < nfingers; i++)
		/* read fingers[i] ... */

msg points into the fixed 4000-byte rx_buf and nfingers is a single
device-supplied byte, so it can be as large as 255.  A malicious,
malfunctioning or counterfeit controller (or an interposer on the SPI
bus) can report a large finger count in a short packet, making the loop
read up to 255 * sizeof(struct apple_z2_finger) bytes starting 24 bytes
into msg -- past the end of the receive buffer.  This is a
controller-driven heap out-of-bounds read, and the finger fields that
are read (position, pressure, touch and tool dimensions) are forwarded
to userspace as input events, leaking adjacent kernel memory.

Drop any packet that claims more fingers than it can hold, warning once
per rate-limit interval, rather than reporting a truncated set of
fingers from an inconsistent report.  A short zero-finger ("all lifted")
report is still passed through so the lifted state reaches userspace.
The 4000-byte receive buffer holds at most 132 finger records, so this
only ever drops counts that could not have been parsed in bounds.

Reported-by: sashiko-bot@kernel.org
Closes: https://lore.kernel.org/all/20260613215358.329921F000E9@smtp.kernel.org/
Fixes: 471a92f8a21a ("Input: apple_z2 - add a driver for Apple Z2 touchscreens")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 drivers/input/touchscreen/apple_z2.c | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/drivers/input/touchscreen/apple_z2.c b/drivers/input/touchscreen/apple_z2.c
index ff9ff97be185..4e2a6967436e 100644
--- a/drivers/input/touchscreen/apple_z2.c
+++ b/drivers/input/touchscreen/apple_z2.c
@@ -93,6 +93,17 @@ static void apple_z2_parse_touches(struct apple_z2 *z2,
 		return;
 	nfingers = msg[APPLE_Z2_NUM_FINGERS_OFFSET];
 	fingers = (struct apple_z2_finger *)(msg + APPLE_Z2_FINGERS_OFFSET);
+	/*
+	 * A malicious or malfunctioning controller can report more fingers
+	 * than the packet actually carries; drop the packet rather than read
+	 * finger records past the end of the receive buffer.
+	 */
+	if (nfingers && msg_len < APPLE_Z2_FINGERS_OFFSET + nfingers * sizeof(*fingers)) {
+		dev_warn_ratelimited(&z2->spidev->dev,
+				     "discarding packet: %d fingers exceed packet length\n",
+				     nfingers);
+		return;
+	}
 	for (i = 0; i < nfingers; i++) {
 		slot = input_mt_get_slot_by_key(z2->input_dev, fingers[i].finger);
 		if (slot < 0) {

-- 
2.43.0

