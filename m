From: Cunhao Lu <1579567540@qq.com>
Date: Sun, 08 Nov 2026 19:33:28 +0800
Subject: [PATCH net v8 01/10] can: rockchip_canfd: prevent TX stall on echo
 skb failure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-rockchip-canfd-restart-close-v8-1-3e7a23fd9eae@qq.com>
References: <20261108-rockchip-canfd-restart-close-v8-0-3e7a23fd9eae@qq.com>
In-Reply-To: <20261108-rockchip-canfd-restart-close-v8-0-3e7a23fd9eae@qq.com>
To: Marc Kleine-Budde <mkl@pengutronix.de>, kernel@pengutronix.de, 
 Vincent Mailhol <mailhol@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Oliver Hartkopp <socketcan@hartkopp.net>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Wolfgang Grandegger <wg@grandegger.com>
Cc: Cunhao Lu <1579567540@qq.com>, linux-can@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 linux-doc@vger.kernel.org, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794137678; l=2976;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=yFeGM8b4hExYb+05VKnGUsT2mfVsfGSbgmFllNqgntM=;
 b=DL4bwb9oHxwLG4Vnt4QK64megKO+phFOIcM3PHByH0wMm6SZ8aMC3ZV/sNfoLpnoG2N4cL5Jo
 AzNm1RBFiJlBgup+YfCnPrqXzA3oStpSvkhkVBgCIin7yhOATEZyc4f
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

rkcanfd_start_xmit() advances tx_head and requests transmission even when
can_put_echo_skb() fails. Completion matches self-received frames against
the echo ring, so an entry without an echo skb cannot be completed and
can leave the TX queue stopped.

Install the echo skb before writing the hardware TX buffer. If echo
preparation fails or returns success without installing an echo skb,
drop the frame without writing TX data or commands, advancing tx_head
or adding BQL bytes.

Pass an extra reference to can_put_echo_skb() and retain the original skb
as the frame-data source until submission finishes. This keeps the data
alive even if echo cleanup removes the installed clone. Release the
retained reference on both success and failure.

Backports require can_put_echo_skb() to consume the passed reference on
every return path, including -EINVAL, or equivalent ownership handling.

Fixes: b6661d73290c ("can: rockchip_canfd: add TX PATH")
Cc: stable@vger.kernel.org
Signed-off-by: Cunhao Lu <1579567540@qq.com>

---
Changes in v8:
- Retain the original skb as the frame-data source and release it after
  submission or failure.
- Reject successful echo preparation if no echo skb was installed.
---
 drivers/net/can/rockchip/rockchip_canfd-tx.c | 21 +++++++++++++++++----
 1 file changed, 17 insertions(+), 4 deletions(-)

diff --git a/drivers/net/can/rockchip/rockchip_canfd-tx.c b/drivers/net/can/rockchip/rockchip_canfd-tx.c
index 12200dcfd3389..420e59b41059c 100644
--- a/drivers/net/can/rockchip/rockchip_canfd-tx.c
+++ b/drivers/net/can/rockchip/rockchip_canfd-tx.c
@@ -117,16 +117,21 @@ netdev_tx_t rkcanfd_start_xmit(struct sk_buff *skb, struct net_device *ndev)
 	tx_head = rkcanfd_get_tx_head(priv);
 	reg_cmd = RKCANFD_REG_CMD_TX_REQ(tx_head);
 
+	/* Retain the original skb as the frame-data source even if the
+	 * echo skb is removed before submission finishes.
+	 */
+	frame_len = can_skb_get_frame_len(skb);
+	err = can_put_echo_skb(skb_get(skb), ndev, tx_head, frame_len);
+	if (unlikely(err || !priv->can.echo_skb[tx_head]))
+		goto out_drop;
+
 	rkcanfd_write(priv, RKCANFD_REG_FD_TXFRAMEINFO, reg_frameinfo);
 	rkcanfd_write(priv, RKCANFD_REG_FD_TXID, reg_id);
 	for (i = 0; i < cfd->len; i += 4)
 		rkcanfd_write(priv, RKCANFD_REG_FD_TXDATA0 + i,
 			      *(u32 *)(cfd->data + i));
 
-	frame_len = can_skb_get_frame_len(skb);
-	err = can_put_echo_skb(skb, ndev, tx_head, frame_len);
-	if (!err)
-		netdev_sent_queue(priv->ndev, frame_len);
+	netdev_sent_queue(priv->ndev, frame_len);
 
 	WRITE_ONCE(priv->tx_head, priv->tx_head + 1);
 
@@ -137,6 +142,14 @@ netdev_tx_t rkcanfd_start_xmit(struct sk_buff *skb, struct net_device *ndev)
 				  RKCANFD_TX_STOP_THRESHOLD,
 				  RKCANFD_TX_START_THRESHOLD);
 
+	dev_consume_skb_any(skb);
+
+	return NETDEV_TX_OK;
+
+out_drop:
+	ndev->stats.tx_dropped++;
+	dev_kfree_skb_any(skb);
+
 	return NETDEV_TX_OK;
 }
 

-- 
2.34.1

