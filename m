From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Sun, 16 Feb 2025 22:18:12 +0100
Subject: [PATCH 1/2] net: tsec: Reorder tsec_recv and tsec_free_pkt
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250216-tsec-v1-1-9a704bedd048@posteo.net>
References: <20250216-tsec-v1-0-9a704bedd048@posteo.net>
In-Reply-To: <20250216-tsec-v1-0-9a704bedd048@posteo.net>
To: Joe Hershberger <joe.hershberger@ni.com>, 
 Ramon Fried <rfried.dev@gmail.com>, Tom Rini <trini@konsulko.com>
Cc: u-boot@lists.denx.de, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739740693; l=1953;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=szYONqyfUAJuQI7dqr75ja6FeiIGRqC49oCs5jo+LwU=;
 b=6QU+sC0Uc9laoridJYZlRujepMcRXpJal0p8g5lHjVSKauWQlacWvqIhH6/D0upy3avzFy/Yc
 PlnblnAjq4GDPszwctnt7BOVbHrPdr/MiVGjSj8uBBmFT/Q0PCqfUac
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is necessary for the following patch. No functional change.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 drivers/net/tsec.c | 36 ++++++++++++++++++------------------
 1 file changed, 18 insertions(+), 18 deletions(-)

diff --git a/drivers/net/tsec.c b/drivers/net/tsec.c
index 6481ee24a6010099cbabb5a213641c63706176a2..b27fc322db55b7b845f8d629348cb34d79de3cc2 100644
--- a/drivers/net/tsec.c
+++ b/drivers/net/tsec.c
@@ -278,6 +278,24 @@ static int tsec_send(struct udevice *dev, void *packet, int length)
 	return result;
 }
 
+static int tsec_free_pkt(struct udevice *dev, uchar *packet, int length)
+{
+	struct tsec_private *priv = (struct tsec_private *)dev_get_priv(dev);
+	u16 status;
+
+	out_be16(&priv->rxbd[priv->rx_idx].length, 0);
+
+	status = RXBD_EMPTY;
+	/* Set the wrap bit if this is the last element in the list */
+	if ((priv->rx_idx + 1) == PKTBUFSRX)
+		status |= RXBD_WRAP;
+	out_be16(&priv->rxbd[priv->rx_idx].status, status);
+
+	priv->rx_idx = (priv->rx_idx + 1) % PKTBUFSRX;
+
+	return 0;
+}
+
 static int tsec_recv(struct udevice *dev, int flags, uchar **packetp)
 {
 	struct tsec_private *priv = (struct tsec_private *)dev_get_priv(dev);
@@ -307,24 +325,6 @@ static int tsec_recv(struct udevice *dev, int flags, uchar **packetp)
 	return ret;
 }
 
-static int tsec_free_pkt(struct udevice *dev, uchar *packet, int length)
-{
-	struct tsec_private *priv = (struct tsec_private *)dev_get_priv(dev);
-	u16 status;
-
-	out_be16(&priv->rxbd[priv->rx_idx].length, 0);
-
-	status = RXBD_EMPTY;
-	/* Set the wrap bit if this is the last element in the list */
-	if ((priv->rx_idx + 1) == PKTBUFSRX)
-		status |= RXBD_WRAP;
-	out_be16(&priv->rxbd[priv->rx_idx].status, status);
-
-	priv->rx_idx = (priv->rx_idx + 1) % PKTBUFSRX;
-
-	return 0;
-}
-
 static void tsec_halt(struct udevice *dev)
 {
 	struct tsec_private *priv;

-- 
2.48.0.rc1.219.gb6b6757d772

