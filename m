From: =?utf-8?q?St=C3=A9phane_Grosjean?= <s.grosjean@peak-system.fr>
Date: Tue, 03 Nov 2026 13:30:24 +0100
Subject: [PATCH v8 08/14] can: peak_usb: validate the data length of
 PCAN-USB Pro CAN records
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261103-canfd_check_channel_idx-v8-8-4e8b2c0a8806@peak-system.fr>
References: <20261103-canfd_check_channel_idx-v8-0-4e8b2c0a8806@peak-system.fr>
In-Reply-To: <20261103-canfd_check_channel_idx-v8-0-4e8b2c0a8806@peak-system.fr>
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol@kernel.org>, 
 Wolfgang Grandegger <wg@grandegger.com>, 
 =?utf-8?q?St=C3=A9phane_Grosjean?= <s.grosjean@peak-system.fr>, 
 Dan Carpenter <error27@gmail.com>, Lukas Magel <lukas.magel@posteo.net>
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Tristan Madani <tristmd@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793709024; l=2800;
 i=s.grosjean@peak-system.fr; s=20261020; h=from:subject:message-id;
 bh=JjxyM/KiPAiDjN4DrO2PnFVJnmhDFwF8g0hNc4FqXlk=;
 b=ivRYKaMOPmQwqAAtQHWRHPLhGbMrmKdtwVcnYf3ZFoL0B5wp1ioReaP30a2BNbFHA13vGFPjP
 BaE83uCrYi5Dxyn1upU8xgaYfoyPqVsaMX/jPFhOMDzp5fAkRMA/iqz
X-Developer-Key: i=s.grosjean@peak-system.fr; a=ed25519;
 pk=bP7QV2zvvAKAfConZlUOGKGEcXL64SNUpVUm++Ai+/c=
X-Endpoint-Received: by B4 Relay for s.grosjean@peak-system.fr/20261020 with auth_id=1250
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The PCAN-USB Pro decoder takes the data length of a received CAN frame
from the 4-bit DLC field of the record, i.e. 0 to 15, and copies that
many bytes from the record into can_frame->data. This length is checked
neither against CAN_MAX_DLEN nor against the size of the record, which
depends on its type: RXMSG8, RXMSG4 and RXMSG0/RXRTR records carry 8, 4
and 0 data bytes. pcan_usb_pro_decode_buf() only checks that the record
fits in the URB, according to its type.

A faulty or malicious device can therefore make the driver:
- copy bytes located beyond the record into the frame, i.e. stale bytes
  of the RX buffer or, when the record ends the 1024-byte buffer, bytes
  beyond it, and deliver them to the CAN sockets;
- write up to 7 bytes past can_frame->data[] with a DLC of 9 to 15;
- deliver an RTR frame whose len is greater than CAN_MAX_DLEN.

Convert the DLC with can_cc_dlc2len() and reject a data frame whose
length exceeds the number of data bytes of its record type, as the
other malformed records are.

Found by Sashiko AI review.

Fixes: d8a199355f8f ("can: usb: PEAK-System Technik PCAN-USB Pro specific part")
Cc: stable@vger.kernel.org
Assisted-by: LLM
Signed-off-by: Stéphane Grosjean <s.grosjean@peak-system.fr>
---
 drivers/net/can/usb/peak_usb/pcan_usb_pro.c | 9 ++++++++-
 1 file changed, 8 insertions(+), 1 deletion(-)

diff --git a/drivers/net/can/usb/peak_usb/pcan_usb_pro.c b/drivers/net/can/usb/peak_usb/pcan_usb_pro.c
index 9e2f48683a9d..38307d452a5a 100644
--- a/drivers/net/can/usb/peak_usb/pcan_usb_pro.c
+++ b/drivers/net/can/usb/peak_usb/pcan_usb_pro.c
@@ -534,6 +534,7 @@ static int pcan_usb_pro_handle_canmsg(struct pcan_usb_pro_interface *usb_if,
 				      struct pcan_usb_pro_rxmsg *rx)
 {
 	const unsigned int ctrl_idx = (rx->len >> 4) & 0x0f;
+	const u8 len = can_cc_dlc2len(rx->len & 0x0f);
 	struct peak_usb_device *dev;
 	struct net_device *netdev;
 	struct can_frame *can_frame;
@@ -543,6 +544,12 @@ static int pcan_usb_pro_handle_canmsg(struct pcan_usb_pro_interface *usb_if,
 	if (ctrl_idx >= ARRAY_SIZE(usb_if->dev))
 		return -EINVAL;
 
+	/* the number of data bytes depends on the record type */
+	if (!(rx->flags & PCAN_USBPRO_RTR) &&
+	    len > pcan_usb_pro_sizeof_rec[rx->data_type] -
+		  offsetof(struct pcan_usb_pro_rxmsg, data))
+		return -EINVAL;
+
 	dev = READ_ONCE(usb_if->dev[ctrl_idx]);
 
 	/* reject records for a channel that is not (or no longer) set up */
@@ -556,7 +563,7 @@ static int pcan_usb_pro_handle_canmsg(struct pcan_usb_pro_interface *usb_if,
 		return -ENOMEM;
 
 	can_frame->can_id = le32_to_cpu(rx->id);
-	can_frame->len = rx->len & 0x0f;
+	can_frame->len = len;
 
 	if (rx->flags & PCAN_USBPRO_EXT)
 		can_frame->can_id |= CAN_EFF_FLAG;

-- 
2.53.0

