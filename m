From: =?utf-8?q?St=C3=A9phane_Grosjean?= <s.grosjean@peak-system.fr>
Date: Thu, 22 Oct 2026 16:27:56 +0200
Subject: [PATCH v6 11/13] can: peak_usb: don't read past the message in
 PCAN-USB Pro decoders
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261022-canfd_check_channel_idx-v6-11-197704231551@peak-system.fr>
References: <20261022-canfd_check_channel_idx-v6-0-197704231551@peak-system.fr>
In-Reply-To: <20261022-canfd_check_channel_idx-v6-0-197704231551@peak-system.fr>
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol@kernel.org>, 
 Wolfgang Grandegger <wg@grandegger.com>, 
 =?utf-8?q?St=C3=A9phane_Grosjean?= <s.grosjean@peak-system.fr>, 
 Dan Carpenter <error27@gmail.com>, Lukas Magel <lukas.magel@posteo.net>
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792679273; l=3195;
 i=s.grosjean@peak-system.fr; s=20261020; h=from:subject:message-id;
 bh=flMPKg1xIa7U4jARAjBvLBR6Xz2OZahn+0Fz2bTlglc=;
 b=RYpH9P4KoJ7SRI+sjY8/2tof1puaCeu/23xklN9hRabFPT651NEUswmjPgE+L2Xcg7GM3mMxU
 uatOiuoJ2xrAzhKKh3ncjxk+kQBk4MdcuJ9sMSv8VJhZZ1GAW4ICBOv
X-Developer-Key: i=s.grosjean@peak-system.fr; a=ed25519;
 pk=bP7QV2zvvAKAfConZlUOGKGEcXL64SNUpVUm++Ai+/c=
X-Endpoint-Received: by B4 Relay for s.grosjean@peak-system.fr/20261020 with auth_id=1250
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The messages received from a PCAN-USB Pro device start with a record
count, followed by records whose size depends on their type, given by
their first byte. Both pcan_usb_pro_decode_buf() and
pcan_usb_pro_wait_rsp() trust this count:

- pcan_usb_pro_decode_buf() reads the type of the next record before
  checking that this record starts inside the URB. When the device
  claims more records than the URB holds, it reads the byte following
  the URB data, which is beyond the 1024-byte RX buffer when the URB
  fills it;
- pcan_usb_pro_wait_rsp() doesn't check the records against the
  received length at all. Since the count is a 32-bit value, a bogus
  response makes it walk the records past the command buffer.

Stop decoding a message at its end in both functions, and in
pcan_usb_pro_wait_rsp() also reject a record that doesn't fit in the
message.

Found by Sashiko AI review.

Fixes: d8a199355f8f ("can: usb: PEAK-System Technik PCAN-USB Pro specific part")
Assisted-by: LLM
Signed-off-by: Stéphane Grosjean <s.grosjean@peak-system.fr>
---
 drivers/net/can/usb/peak_usb/pcan_usb_pro.c | 18 +++++++++++++++---
 1 file changed, 15 insertions(+), 3 deletions(-)

diff --git a/drivers/net/can/usb/peak_usb/pcan_usb_pro.c b/drivers/net/can/usb/peak_usb/pcan_usb_pro.c
index f94494e01f4a..b869a20438cf 100644
--- a/drivers/net/can/usb/peak_usb/pcan_usb_pro.c
+++ b/drivers/net/can/usb/peak_usb/pcan_usb_pro.c
@@ -244,9 +244,9 @@ static int pcan_usb_pro_wait_rsp(struct peak_usb_device *dev,
 	for (i = 0; !err && i < PCAN_USBPRO_RSP_SUBMIT_MAX; i++) {
 		struct pcan_usb_pro_msg rsp;
 		union pcan_usb_pro_rec *pr;
+		u8 *pc, *rsp_end;
 		u32 r, rec_cnt;
 		u16 rec_len;
-		u8 *pc;
 
 		err = usb_bulk_msg(dev->udev,
 			usb_rcvbulkpipe(dev->udev, PCAN_USBPRO_EP_CMDIN),
@@ -271,13 +271,18 @@ static int pcan_usb_pro_wait_rsp(struct peak_usb_device *dev,
 		pc = pcan_msg_init(&rsp, pum->u.rec_buffer,
 			actual_length);
 
+		rsp_end = pum->u.rec_buffer + actual_length;
 		rec_cnt = le32_to_cpu(*rsp.u.rec_cnt);
 
 		/* loop on records stored into message */
 		for (r = 0; r < rec_cnt; r++) {
+			/* rec_cnt comes from the device: stay in the message */
+			if (pc >= rsp_end)
+				break;
+
 			pr = (union pcan_usb_pro_rec *)pc;
 			rec_len = pcan_usb_pro_sizeof_rec[pr->data_type];
-			if (!rec_len) {
+			if (!rec_len || pc + rec_len > rsp_end) {
 				netdev_err(dev->netdev,
 					   "got unprocessed record in msg\n");
 				pcan_dump_mem("rcvd rsp msg", pum->u.rec_buffer,
@@ -745,8 +750,15 @@ static int pcan_usb_pro_decode_buf(struct peak_usb_device *dev, struct urb *urb)
 	rec_cnt = le16_to_cpu(*usb_msg.u.rec_cnt_rd);
 	for (; rec_cnt > 0; rec_cnt--) {
 		union pcan_usb_pro_rec *pr = (union pcan_usb_pro_rec *)rec_ptr;
-		u16 sizeof_rec = pcan_usb_pro_sizeof_rec[pr->data_type];
+		u16 sizeof_rec;
+
+		/* rec_cnt comes from the device: don't read past the message */
+		if (rec_ptr >= msg_end) {
+			err = -EBADMSG;
+			break;
+		}
 
+		sizeof_rec = pcan_usb_pro_sizeof_rec[pr->data_type];
 		if (!sizeof_rec) {
 			netdev_err(netdev,
 				   "got unsupported rec in usb msg:\n");

-- 
2.53.0

