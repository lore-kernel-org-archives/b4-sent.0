From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Date: Tue, 10 Nov 2026 09:03:25 +0000
Subject: [PATCH wpan] ieee802154: atusb: complete each transmitted frame
 only once
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-atusb-tx-once-v1-1-43e2b92f2072@gmail.com>
X-B4-Tracking: v=1; b=H4sIANzd8moC/x3MPQ6AIAxA4auQzjahmjB4FeOAUrQLEMCfxHh3i
 eM3vPdA4SxcYFQPZD6lSAwN1ClYdxs2RnHN0OveEJFGW4+yYL0xhpXROPKD0+QWZmhNyuzl/n8
 TXMkGmN/3AxupegBlAAAA
To: joasantonio108@gmail.com, stefan@datenfreihafen.org, 
 alex.aring@gmail.com, miquel.raynal@bootlin.com
Cc: andrew+netdev@lunn.ch, davem@davemloft.net, edumazet@kernel.org, 
 kuba@kernel.org, pabeni@redhat.com, linux-wpan@vger.kernel.org, 
 netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794301404; l=3532;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=Vqtsi3F3WbF3wGvBDjFI4OLrDf6LJpOQrNpq3siz01Y=;
 b=YLDXtuy52tYz/Ou2wD1yFBUb5xWkkhrAYZYVum7ArT6TZsxMUmWPGBGC9NpSFJwXBfn82Ts/E
 n2Vw5tqBS4XCwRu9XnMgFWckLqbWTmmIWEqWKo12JF0M2afhiv+Iwvm
X-Developer-Key: i=joasantonio108@gmail.com; a=ed25519;
 pk=ZxAznJT/FcPPdzLrDDFJQm4LLjjHVGBBqDSG3TXS23w=
X-Endpoint-Received: by B4 Relay for joasantonio108@gmail.com/20261031 with auth_id=1371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

atusb_xmit() stores the frame being transmitted in atusb->tx_skb and
atusb_tx_done() hands it to ieee802154_xmit_complete() or
ieee802154_xmit_error(), both of which free it.  tx_skb is never
cleared, and atusb_in_good() calls atusb_tx_done() for every one or two
byte bulk-in transfer it receives from the device.

A device that sends a second tx completion report after a transmit
therefore makes the driver free the same skb again, and drop
phy->ongoing_txs once more.  A report sent before the first transmit
calls the completion helpers with a NULL skb, which frees nothing but
still drops phy->ongoing_txs.  The stale pointer is also left behind when
usb_submit_urb() fails in atusb_xmit() and mac802154 frees the skb.

A malicious or malfunctioning USB device can use this for a double
free of an skb once the interface is up and a frame has been sent.

Take the skb out of tx_skb when completing it and ignore completion
reports when no frame is pending.

Found by LLM-assisted source review.

Fixes: 7490b008d123 ("ieee802154: add support for atusb transceiver")
Cc: stable@vger.kernel.org
Signed-off-by: Joas Antonio dos Santos <joasantonio108@gmail.com>
---
This issue was found with the help of an LLM-based code review tool
(Claude).  I checked the code paths by hand against v7.4-rc3 and
reviewed the fix myself.  It is build-tested only (W=1, arm64); I do
not have the hardware to test it at runtime.
---
 drivers/net/ieee802154/atusb.c | 23 +++++++++++++++--------
 1 file changed, 15 insertions(+), 8 deletions(-)

diff --git a/drivers/net/ieee802154/atusb.c b/drivers/net/ieee802154/atusb.c
index 5f7fc4ee7a07..2460eb19b72b 100644
--- a/drivers/net/ieee802154/atusb.c
+++ b/drivers/net/ieee802154/atusb.c
@@ -195,21 +195,26 @@ static void atusb_tx_done(struct atusb *atusb, u8 seq, int reason)
 {
 	struct usb_device *usb_dev = atusb->usb_dev;
 	u8 expect = atusb->tx_ack_seq;
+	struct sk_buff *skb;
 
 	dev_dbg(&usb_dev->dev, "%s (0x%02x/0x%02x)\n", __func__, seq, expect);
+
+	/* The device may report a tx completion when no frame is pending,
+	 * or more than once for the same frame.  Complete each frame only
+	 * once.
+	 */
+	skb = xchg(&atusb->tx_skb, NULL);
+	if (!skb)
+		return;
+
 	if (seq == expect) {
 		/* TODO check for ifs handling in firmware */
 		if (reason == IEEE802154_SUCCESS)
-			ieee802154_xmit_complete(atusb->hw, atusb->tx_skb, false);
+			ieee802154_xmit_complete(atusb->hw, skb, false);
 		else
-			ieee802154_xmit_error(atusb->hw, atusb->tx_skb, reason);
+			ieee802154_xmit_error(atusb->hw, skb, reason);
 	} else {
-		/* TODO I experience this case when atusb has a tx complete
-		 * irq before probing, we should fix the firmware it's an
-		 * unlikely case now that seq == expect is then true, but can
-		 * happen and fail with a tx_skb = NULL;
-		 */
-		ieee802154_xmit_hw_error(atusb->hw, atusb->tx_skb);
+		ieee802154_xmit_hw_error(atusb->hw, skb);
 	}
 }
 
@@ -351,6 +356,8 @@ static int atusb_xmit(struct ieee802154_hw *hw, struct sk_buff *skb)
 			     (unsigned char *)&atusb->tx_dr, skb->data,
 			     skb->len, atusb_xmit_complete, NULL);
 	ret = usb_submit_urb(atusb->tx_urb, GFP_ATOMIC);
+	if (ret)
+		atusb->tx_skb = NULL;
 	dev_dbg(&usb_dev->dev, "%s done (%d)\n", __func__, ret);
 	return ret;
 }

---
base-commit: b3dfbde62cf1981c4638939c159dfd087b7a72e9
change-id: 20261110-atusb-tx-once-6d1f3d01dbee

Best regards,
-- 
Joas Antonio dos Santos <joasantonio108@gmail.com>

