From: =?utf-8?q?St=C3=A9phane_Grosjean?= <s.grosjean@peak-system.fr>
Date: Tue, 03 Nov 2026 13:30:25 +0100
Subject: [PATCH v8 09/14] can: peak_usb: don't read past the message in
 PCAN-USB Pro decoders
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261103-canfd_check_channel_idx-v8-9-4e8b2c0a8806@peak-system.fr>
References: <20261103-canfd_check_channel_idx-v8-0-4e8b2c0a8806@peak-system.fr>
In-Reply-To: <20261103-canfd_check_channel_idx-v8-0-4e8b2c0a8806@peak-system.fr>
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol@kernel.org>, 
 Wolfgang Grandegger <wg@grandegger.com>, 
 =?utf-8?q?St=C3=A9phane_Grosjean?= <s.grosjean@peak-system.fr>, 
 Dan Carpenter <error27@gmail.com>, Lukas Magel <lukas.magel@posteo.net>
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Tristan Madani <tristmd@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793709024; l=3340;
 i=s.grosjean@peak-system.fr; s=20261020; h=from:subject:message-id;
 bh=h4jVtQ++YLpdaDDefew6U35BUUpoAZ8/yqvbCDBX9dA=;
 b=AxqEku8UFmw5LaP8ZCeST2y+Ts/X24M6YPYFVLU879AAdzifN0kIELT8UcymoQGw59mDZAnuK
 G++yD0ywq1pDzzkluBg7SEYd0PMHWWZ3k9v0rLxRJpypVUrCyUCBDwO
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
  received length at all. A truncated response is then accepted, and
  pcan_usb_pro_get_can_channel_id() returns stale bytes of its own
  request as the channel id. With the current callers, the walk only
  stays within the command buffer because its unused tail is zeroed.

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
index 38307d452a5a..88d21806207b 100644
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

