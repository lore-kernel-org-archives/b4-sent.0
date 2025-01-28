From: David Dgien <dgienda125@gmail.com>
Date: Mon, 27 Jan 2025 23:16:18 -0500
Subject: [PATCH] macb: Fix tx completion check
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250127-fix-macb-send-v1-1-d9b6067dda86@gmail.com>
X-B4-Tracking: v=1; b=H4sIABFamGcC/x2MQQqAIBAAvyJ7bmEzsugr0cF0qz1koRCB+Pek4
 8DMZEgchRNMKkPkR5JcoULbKHCHDTuj+MqgSffUaoObvHhat2Li4LEzRMNIW+95hNrckavw/+a
 llA9/D1swXwAAAA==
X-Change-ID: 20250126-fix-macb-send-3600780f5de8
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 BAREBOX <barebox@lists.infradead.org>
Cc: Billy Gomez <william.james.gomez@gmail.com>, 
 David Dgien <dgienda125@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1738037790; l=1127;
 i=dgienda125@gmail.com; s=20250126; h=from:subject:message-id;
 bh=TOYs8c3poqqRPzuaB7uHXHWJwieavBQK6hgSIzXrSE4=;
 b=7et2K7QnCEirSrH4zAp0Y+iIl+0BZZQgR8FCgwc5FRF/kpMN0DPUJd5CQunY3sEB9bfgBHA78
 KS8p1A8GdECC7oHunRP1N83lJcRyyTbx/nWAVZArXauyMK9kwfDQOQ1
X-Developer-Key: i=dgienda125@gmail.com; a=ed25519;
 pk=zPhfl/eH2iShpaIksvU8MCg11Il6Dx2oW7WYAzpKbo0=
X-Endpoint-Received: by B4 Relay for dgienda125@gmail.com/20250126 with auth_id=332
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Check the send completion bit for the current packet in the descriptor
ring, instead of just the first entry in the ring.

This fixes issues when sending multiple small packets in quick
succession, such as with netconsole.

Reported-by: Billy Gomez <william.james.gomez@gmail.com>
Signed-off-by: David Dgien <dgienda125@gmail.com>
Fixes: aa2095304a ("macb: fix tx ring size")
---
 drivers/net/macb.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/net/macb.c b/drivers/net/macb.c
index 28c2fc860e37853a91488a675af3716d9f3843df..205e3169f17b2b762ba51640248a2ea96db5c582 100644
--- a/drivers/net/macb.c
+++ b/drivers/net/macb.c
@@ -132,7 +132,7 @@ static int macb_send(struct eth_device *edev, void *packet,
 	start = get_time_ns();
 	ret = -ETIMEDOUT;
 	do {
-		ctrl = readl(&macb->tx_ring[0].ctrl);
+		ctrl = readl(&macb->tx_ring[tx_head].ctrl);
 		if (ctrl & MACB_BIT(TX_USED)) {
 			ret = 0;
 			break;

---
base-commit: 1a3be5bdf6329e4e691f1d39461f5157767c7e72
change-id: 20250126-fix-macb-send-3600780f5de8

Best regards,
-- 
David Dgien <dgienda125@gmail.com>

