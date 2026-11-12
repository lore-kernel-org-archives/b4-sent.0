From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Date: Thu, 12 Nov 2026 17:27:58 +0000
Subject: [PATCH v3 4/4] can: kvaser_usb: hydra: check the payload of
 extended rx commands
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-kvaser-usb-validate-v3-4-61587f639508@gmail.com>
References: <20261112-kvaser-usb-validate-v3-0-61587f639508@gmail.com>
In-Reply-To: <20261112-kvaser-usb-validate-v3-0-61587f639508@gmail.com>
To: mkl@pengutronix.de, mailhol@kernel.org, joasantonio108@gmail.com
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794504474; l=2808;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=WJCjgUb94163buNtNhHfE+CDpz0+R00yFLhc1KmDJuY=;
 b=7xCW0Jrj0rmfzez6b34gGJhOU73/5bicHQMaYqAVD1b0s2gnqNXuRl5zinNc1UiaSCiLTHftT
 w0ThJMmM1UsCW1lcnqDjvknzQqAAJi2XYpvZik350eaNA+nP0t2bNFK
X-Developer-Key: i=joasantonio108@gmail.com; a=ed25519;
 pk=ZxAznJT/FcPPdzLrDDFJQm4LLjjHVGBBqDSG3TXS23w=
X-Endpoint-Received: by B4 Relay for joasantonio108@gmail.com/20261031 with auth_id=1371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

kvaser_usb_hydra_rx_msg_ext() reads the error frame data or copies up
to 64 bytes of CAN FD payload from an extended command.  Both start at
byte 32 of the command, and the number of payload bytes is derived from
the DLC in kcan_header.  Neither is checked against the length of the
command, which the parsers only guarantee to be at least
sizeof(struct kvaser_cmd), 32 bytes.

A device can therefore send a short CMD_RX_MESSAGE_FD command with a
large DLC and make the driver copy up to 64 bytes that follow the
command into the CAN frame that is passed to user space: stale data of
earlier transfers in the receive buffer or in usb_rx_leftover, or data
beyond the 3072 bytes of the receive buffer if the command is the last
one in a full transfer.

Check that the command contains the error frame data and the payload
before using them, and count the command as an rx error otherwise.

Found by the Sashiko AI review of the previous version of this series.

Fixes: aec5fb2268b7 ("can: kvaser_usb: Add support for Kvaser USB hydra family")
Cc: stable@vger.kernel.org
Signed-off-by: Joas Antonio dos Santos <joasantonio108@gmail.com>
---
 drivers/net/can/usb/kvaser_usb/kvaser_usb_hydra.c | 15 +++++++++++++++
 1 file changed, 15 insertions(+)

diff --git a/drivers/net/can/usb/kvaser_usb/kvaser_usb_hydra.c b/drivers/net/can/usb/kvaser_usb/kvaser_usb_hydra.c
index 6b68e0714ae3..387a522c60fa 100644
--- a/drivers/net/can/usb/kvaser_usb/kvaser_usb_hydra.c
+++ b/drivers/net/can/usb/kvaser_usb/kvaser_usb_hydra.c
@@ -1308,6 +1308,7 @@ static void kvaser_usb_hydra_rx_msg_ext(const struct kvaser_usb *dev,
 	struct sk_buff *skb;
 	struct skb_shared_hwtstamps *shhwtstamps;
 	struct net_device_stats *stats;
+	size_t cmd_len = le16_to_cpu(cmd->len);
 	u32 flags;
 	u8 dlc;
 	u32 kcan_header;
@@ -1327,6 +1328,12 @@ static void kvaser_usb_hydra_rx_msg_ext(const struct kvaser_usb *dev,
 	hwtstamp = kvaser_usb_hydra_ktime_from_cmd(dev->cfg, std_cmd);
 
 	if (flags & KVASER_USB_HYDRA_CF_FLAG_ERROR_FRAME) {
+		if (cmd_len < offsetofend(struct kvaser_cmd_ext,
+					  rx_can.err_frame_data)) {
+			stats->rx_errors++;
+			return;
+		}
+
 		kvaser_usb_hydra_error_frame(priv, &cmd->rx_can.err_frame_data,
 					     hwtstamp);
 		return;
@@ -1370,6 +1377,14 @@ static void kvaser_usb_hydra_rx_msg_ext(const struct kvaser_usb *dev,
 	if (flags & KVASER_USB_HYDRA_CF_FLAG_REMOTE_FRAME) {
 		cf->can_id |= CAN_RTR_FLAG;
 	} else {
+		/* The payload must be part of the received command */
+		if (cmd_len < offsetof(struct kvaser_cmd_ext,
+				       rx_can.kcan_payload) + cf->len) {
+			stats->rx_errors++;
+			kfree_skb(skb);
+			return;
+		}
+
 		memcpy(cf->data, cmd->rx_can.kcan_payload, cf->len);
 
 		stats->rx_bytes += cf->len;

-- 
2.43.0

