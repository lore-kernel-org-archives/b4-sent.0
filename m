From: Rohan G Thomas <rohan.g.thomas@altera.com>
Date: Mon, 15 Sep 2025 16:17:19 +0800
Subject: [PATCH net v2 2/2] net: stmmac: Consider Tx VLAN offload tag
 length for maxSDU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250915-qbv-fixes-v2-2-ec90673bb7d4@altera.com>
References: <20250915-qbv-fixes-v2-0-ec90673bb7d4@altera.com>
In-Reply-To: <20250915-qbv-fixes-v2-0-ec90673bb7d4@altera.com>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Jose Abreu <Jose.Abreu@synopsys.com>, 
 Rohan G Thomas <rohan.g.thomas@intel.com>
Cc: netdev@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Rohan G Thomas <rohan.g.thomas@altera.com>, 
 Matthew Gerlach <matthew.gerlach@altera.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757924239; l=2480;
 i=rohan.g.thomas@altera.com; s=20250815; h=from:subject:message-id;
 bh=DoDmPaXfLB/bLZGa1Ixa2bObvDjP8v/PGAMQq76env8=;
 b=wVN5CaLveZl3eMAmOlvIyWdRSXZumm1eMskrSPcGTz7YXY/h4L+qhZTTZMQPOIdDISwNzEbqL
 UIwCGFHliyXBghBeocR0jNjle9uLD5D4HHeaytqLmPo6xajplrlkvQF
X-Developer-Key: i=rohan.g.thomas@altera.com; a=ed25519;
 pk=5yZXkXswhfUILKAQwoIn7m6uSblwgV5oppxqde4g4TY=
X-Endpoint-Received: by B4 Relay for rohan.g.thomas@altera.com/20250815 with auth_id=494
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On hardware with Tx VLAN offload enabled, add the VLAN tag
length to the skb length before checking the Qbv maxSDU.
Add 4 bytes for 802.1Q an add 8 bytes for 802.1AD tagging.

Fixes: c5c3e1bfc9e0 ("net: stmmac: Offload queueMaxSDU from tc-taprio")
Signed-off-by: Rohan G Thomas <rohan.g.thomas@altera.com>
Reviewed-by: Matthew Gerlach <matthew.gerlach@altera.com>
---
 drivers/net/ethernet/stmicro/stmmac/stmmac_main.c | 25 ++++++++++++++++-------
 1 file changed, 18 insertions(+), 7 deletions(-)

diff --git a/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c b/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
index 8c8ca5999bd8ad369eafa0cd8448a15da55be86b..c06c947ef7764bf40291a556984651f4edd7cb74 100644
--- a/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
+++ b/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
@@ -4537,6 +4537,7 @@ static netdev_tx_t stmmac_xmit(struct sk_buff *skb, struct net_device *dev)
 	bool has_vlan, set_ic;
 	int entry, first_tx;
 	dma_addr_t des;
+	u32 sdu_len;
 
 	tx_q = &priv->dma_conf.tx_queue[queue];
 	txq_stats = &priv->xstats.txq_stats[queue];
@@ -4553,13 +4554,6 @@ static netdev_tx_t stmmac_xmit(struct sk_buff *skb, struct net_device *dev)
 			return stmmac_tso_xmit(skb, dev);
 	}
 
-	if (priv->est && priv->est->enable &&
-	    priv->est->max_sdu[queue] &&
-	    skb->len > priv->est->max_sdu[queue]){
-		priv->xstats.max_sdu_txq_drop[queue]++;
-		goto max_sdu_err;
-	}
-
 	if (unlikely(stmmac_tx_avail(priv, queue) < nfrags + 1)) {
 		if (!netif_tx_queue_stopped(netdev_get_tx_queue(dev, queue))) {
 			netif_tx_stop_queue(netdev_get_tx_queue(priv->dev,
@@ -4575,6 +4569,23 @@ static netdev_tx_t stmmac_xmit(struct sk_buff *skb, struct net_device *dev)
 	/* Check if VLAN can be inserted by HW */
 	has_vlan = stmmac_vlan_insert(priv, skb, tx_q);
 
+	sdu_len = skb->len;
+	if (has_vlan) {
+		/* Add VLAN tag length to sdu length in case of txvlan offload */
+		if (priv->dev->features & NETIF_F_HW_VLAN_CTAG_TX)
+			sdu_len += VLAN_HLEN;
+		if (skb->vlan_proto == htons(ETH_P_8021AD) &&
+		    priv->dev->features & NETIF_F_HW_VLAN_STAG_TX)
+			sdu_len += VLAN_HLEN;
+	}
+
+	if (priv->est && priv->est->enable &&
+	    priv->est->max_sdu[queue] &&
+	    sdu_len > priv->est->max_sdu[queue]) {
+		priv->xstats.max_sdu_txq_drop[queue]++;
+		goto max_sdu_err;
+	}
+
 	entry = tx_q->cur_tx;
 	first_entry = entry;
 	WARN_ON(tx_q->tx_skbuff[first_entry]);

-- 
2.26.2

