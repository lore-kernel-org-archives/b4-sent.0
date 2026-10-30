From: =?utf-8?q?St=C3=A9phane_Grosjean?= <s.grosjean@peak-system.fr>
Date: Fri, 30 Oct 2026 11:44:56 +0100
Subject: [PATCH v7 07/13] can: peak_usb: fix RX cursor desync for
 self-received RTR frames with SRR
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261030-canfd_check_channel_idx-v7-7-fc4a3faf3acf@peak-system.fr>
References: <20261030-canfd_check_channel_idx-v7-0-fc4a3faf3acf@peak-system.fr>
In-Reply-To: <20261030-canfd_check_channel_idx-v7-0-fc4a3faf3acf@peak-system.fr>
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol@kernel.org>, 
 Wolfgang Grandegger <wg@grandegger.com>, 
 =?utf-8?q?St=C3=A9phane_Grosjean?= <s.grosjean@peak-system.fr>, 
 Dan Carpenter <error27@gmail.com>, Lukas Magel <lukas.magel@posteo.net>
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Tristan Madani <tristmd@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793357103; l=2690;
 i=s.grosjean@peak-system.fr; s=20261020; h=from:subject:message-id;
 bh=7iowm2Ync/QfAvJoNemyRJAkNEBzGpoLl9V/NPwbe3Y=;
 b=faEX5VcF40yIRWHradmC+AYyOzMaoqTGugPuDtU+lON4lkOo54x+lTkIL6N1KFcMm1UrTfEu6
 MQRKmMAlsJoA+UjJ1tdxz5RUGaZMCGF6wc4oFTK7Qg+B5ALp39d80ZP
X-Developer-Key: i=s.grosjean@peak-system.fr; a=ed25519;
 pk=bP7QV2zvvAKAfConZlUOGKGEcXL64SNUpVUm++Ai+/c=
X-Endpoint-Received: by B4 Relay for s.grosjean@peak-system.fr/20261020 with auth_id=1250
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

pcan_usb_encode_msg() appends a one-byte "writer id" whenever
PCAN_USB_TX_SRR is set in can_id_flags, for both RTR and non-RTR
frames: the data block and the SRR writer id byte are two independent,
unconditional steps.

pcan_usb_decode_data() only consumed that extra byte in the non-RTR
branch, inside the same conditional block that reads the CAN data
payload. A self-received RTR frame with the SRR bit set (e.g. a
loopback echo with CAN_CTRLMODE_LOOPBACK) therefore left the RX cursor
one byte short, causing the private id byte to be misparsed as the
next record's status/len byte and the rest of the URB to be misparsed
or rejected.

Move the private id byte skip out of the RTR/non-RTR branch so it is
applied whenever SRR is set, matching the encoder's layout.

Since a frame can now be dropped when this byte is missing, update
rx_bytes together with rx_packets, once the frame has been fully
decoded.

Fixes: 3a7939495ce8 ("can: peak_usb: PCAN-USB: add support of loopback and one-shot mode")
Cc: stable@vger.kernel.org
Assisted-by: LLM
Signed-off-by: Stéphane Grosjean <s.grosjean@peak-system.fr>
---
 drivers/net/can/usb/peak_usb/pcan_usb.c | 22 +++++++++++++---------
 1 file changed, 13 insertions(+), 9 deletions(-)

diff --git a/drivers/net/can/usb/peak_usb/pcan_usb.c b/drivers/net/can/usb/peak_usb/pcan_usb.c
index b9cd6cbeb912..4c93aa060fea 100644
--- a/drivers/net/can/usb/peak_usb/pcan_usb.c
+++ b/drivers/net/can/usb/peak_usb/pcan_usb.c
@@ -655,6 +655,7 @@ static int pcan_usb_decode_data(struct pcan_usb_msg_context *mc, u8 status_len)
 	struct sk_buff *skb;
 	struct can_frame *cf;
 	struct skb_shared_hwtstamps *hwts;
+	u8 rx_bytes = 0;
 	u32 can_id_flags;
 
 	skb = alloc_can_skb(mc->netdev, &cf);
@@ -696,18 +697,21 @@ static int pcan_usb_decode_data(struct pcan_usb_msg_context *mc, u8 status_len)
 
 		memcpy(cf->data, mc->ptr, cf->len);
 		mc->ptr += rec_len;
+		rx_bytes = cf->len;
+	}
 
-		/* Ignore next byte (client private id) if SRR bit is set */
-		if (can_id_flags & PCAN_USB_TX_SRR) {
-			if ((mc->ptr + 1) > mc->end)
-				goto decode_failed;
-			mc->ptr++;
-		}
-
-		/* update statistics */
-		mc->netdev->stats.rx_bytes += cf->len;
+	/* Ignore next byte (client private id) if SRR bit is set.
+	 * Note: this test must be done even when the frame is an RTR frame.
+	 */
+	if (can_id_flags & PCAN_USB_TX_SRR) {
+		if ((mc->ptr + 1) > mc->end)
+			goto decode_failed;
+		mc->ptr++;
 	}
+
+	/* update statistics */
 	mc->netdev->stats.rx_packets++;
+	mc->netdev->stats.rx_bytes += rx_bytes;
 
 	/* convert timestamp into kernel time */
 	hwts = skb_hwtstamps(skb);

-- 
2.53.0

