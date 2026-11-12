From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Date: Thu, 12 Nov 2026 17:27:57 +0000
Subject: [PATCH v3 3/4] can: kvaser_usb: hydra: do not read the command
 length before it is received
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-kvaser-usb-validate-v3-3-61587f639508@gmail.com>
References: <20261112-kvaser-usb-validate-v3-0-61587f639508@gmail.com>
In-Reply-To: <20261112-kvaser-usb-validate-v3-0-61587f639508@gmail.com>
To: mkl@pengutronix.de, mailhol@kernel.org, joasantonio108@gmail.com
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794504474; l=5600;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=ldTeBoZ4+jKNL/lgU1zjcXXFBzkpZLGiDFqOc5o2sd8=;
 b=tjmqatAi7KoDMsGfT5wYv8qtwO3VXSMIW1OgNLCISJQYHPBes7/187rbjUv6PT2v+LDI3ZIB5
 VSbCXDvLC50BzmnXI7MHPYnRQuRAzC0Qc6VUAavl4CATHBTEXlDQdVJ
X-Developer-Key: i=joasantonio108@gmail.com; a=ed25519;
 pk=ZxAznJT/FcPPdzLrDDFJQm4LLjjHVGBBqDSG3TXS23w=
X-Endpoint-Received: by B4 Relay for joasantonio108@gmail.com/20261031 with auth_id=1371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

kvaser_usb_hydra_cmd_size() reads the 16 bit length of an extended
command from bytes 4 and 5 of the command.  The two command parsers call
it without checking that those bytes have been received:

  - kvaser_usb_hydra_wait_cmd() only requires pos < actual_len.  If the
    transfer fills the whole KVASER_USB_RX_BUFFER_SIZE buffer and the
    last command starts in its last five bytes, the length is read from
    beyond the end of the kzalloc()ed buffer.

  - kvaser_usb_hydra_read_bulk_callback() has the same problem at the
    end of the receive buffer.  In addition, an extended command that is
    split so that fewer than six bytes arrive in the first transfer is
    parsed with a length taken from stale buffer content.  That either
    fails the length check or stores the fragment in usb_rx_leftover,
    where the next callback computes the length again before the rest of
    the header has been copied in, and without checking it against
    sizeof(struct kvaser_cmd).

Every command is at least sizeof(struct kvaser_cmd) long and
kvaser_usb_hydra_wait_cmd() does not handle partial commands, so require
that many bytes there before looking at the command.

In kvaser_usb_hydra_read_bulk_callback(), buffer the fragment when the
length field is not complete, and complete the length field in
usb_rx_leftover before using it.  Apply the minimum length check to the
buffered command too.  Drop the buffered fragment when that check or
the existing check against the size of usb_rx_leftover fails; the
latter kept the fragment, so that the same error was hit again on the
following transfers.

Found by the Sashiko AI review of the previous version of this series.

Fixes: aec5fb2268b7 ("can: kvaser_usb: Add support for Kvaser USB hydra family")
Cc: stable@vger.kernel.org
Signed-off-by: Joas Antonio dos Santos <joasantonio108@gmail.com>
---
 drivers/net/can/usb/kvaser_usb/kvaser_usb_hydra.c | 50 +++++++++++++++++++----
 1 file changed, 43 insertions(+), 7 deletions(-)

diff --git a/drivers/net/can/usb/kvaser_usb/kvaser_usb_hydra.c b/drivers/net/can/usb/kvaser_usb/kvaser_usb_hydra.c
index 9adb4eb36e39..6b68e0714ae3 100644
--- a/drivers/net/can/usb/kvaser_usb/kvaser_usb_hydra.c
+++ b/drivers/net/can/usb/kvaser_usb/kvaser_usb_hydra.c
@@ -675,6 +675,12 @@ static int kvaser_usb_hydra_wait_cmd(const struct kvaser_usb *dev, u8 cmd_no,
 			size_t cmd_len;
 
 			tmp_cmd = buf + pos;
+			if (actual_len - pos < sizeof(struct kvaser_cmd)) {
+				dev_err_ratelimited(&dev->intf->dev,
+						    "Format error\n");
+				break;
+			}
+
 			cmd_len = kvaser_usb_hydra_cmd_size(tmp_cmd);
 			if (cmd_len < sizeof(struct kvaser_cmd) ||
 			    pos + cmd_len > actual_len) {
@@ -2117,6 +2123,8 @@ static void kvaser_usb_hydra_read_bulk_callback(struct kvaser_usb *dev,
 							&dev->card_data.hydra;
 	int usb_rx_leftover_len;
 	spinlock_t *usb_rx_leftover_lock = &card_data->usb_rx_leftover_lock;
+	/* Number of bytes needed to tell the length of any command */
+	const int len_end = offsetofend(struct kvaser_cmd_ext, len);
 
 	spin_lock_irqsave(usb_rx_leftover_lock, irq_flags);
 	usb_rx_leftover_len = card_data->usb_rx_leftover_len;
@@ -2125,20 +2133,43 @@ static void kvaser_usb_hydra_read_bulk_callback(struct kvaser_usb *dev,
 
 		cmd = (struct kvaser_cmd *)card_data->usb_rx_leftover;
 
+		if (usb_rx_leftover_len < len_end) {
+			/* Get the rest of the length field first */
+			remaining_bytes = min(len,
+					      len_end - usb_rx_leftover_len);
+			memcpy(card_data->usb_rx_leftover + usb_rx_leftover_len,
+			       buf, remaining_bytes);
+			pos += remaining_bytes;
+			usb_rx_leftover_len += remaining_bytes;
+			card_data->usb_rx_leftover_len = usb_rx_leftover_len;
+			if (usb_rx_leftover_len < len_end) {
+				spin_unlock_irqrestore(usb_rx_leftover_lock,
+						       irq_flags);
+				return;
+			}
+		}
+
 		cmd_len = kvaser_usb_hydra_cmd_size(cmd);
+		if (cmd_len < sizeof(struct kvaser_cmd)) {
+			dev_err(&dev->intf->dev, "Format error\n");
+			card_data->usb_rx_leftover_len = 0;
+			spin_unlock_irqrestore(usb_rx_leftover_lock, irq_flags);
+			return;
+		}
 
-		remaining_bytes = min_t(unsigned int, len,
+		remaining_bytes = min_t(unsigned int, len - pos,
 					cmd_len - usb_rx_leftover_len);
 		/* Make sure we do not overflow usb_rx_leftover */
 		if (remaining_bytes + usb_rx_leftover_len >
 						KVASER_USB_HYDRA_MAX_CMD_LEN) {
 			dev_err(&dev->intf->dev, "Format error\n");
+			card_data->usb_rx_leftover_len = 0;
 			spin_unlock_irqrestore(usb_rx_leftover_lock, irq_flags);
 			return;
 		}
 
-		memcpy(card_data->usb_rx_leftover + usb_rx_leftover_len, buf,
-		       remaining_bytes);
+		memcpy(card_data->usb_rx_leftover + usb_rx_leftover_len,
+		       buf + pos, remaining_bytes);
 		pos += remaining_bytes;
 
 		if (remaining_bytes + usb_rx_leftover_len == cmd_len) {
@@ -2155,11 +2186,16 @@ static void kvaser_usb_hydra_read_bulk_callback(struct kvaser_usb *dev,
 	while (pos < len) {
 		cmd = buf + pos;
 
-		cmd_len = kvaser_usb_hydra_cmd_size(cmd);
+		if (len - pos < len_end) {
+			/* The length is not known yet, buffer what we got */
+			cmd_len = sizeof(struct kvaser_cmd);
+		} else {
+			cmd_len = kvaser_usb_hydra_cmd_size(cmd);
 
-		if (cmd_len < sizeof(struct kvaser_cmd)) {
-			dev_err(&dev->intf->dev, "Format error\n");
-			return;
+			if (cmd_len < sizeof(struct kvaser_cmd)) {
+				dev_err(&dev->intf->dev, "Format error\n");
+				return;
+			}
 		}
 
 		if (pos + cmd_len > len) {

-- 
2.43.0

