From: Rohan G Thomas <rohan.g.thomas@altera.com>
Date: Tue, 28 Oct 2025 11:18:44 +0800
Subject: [PATCH net v4 2/3] net: stmmac: Consider Tx VLAN offload tag
 length for maxSDU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251028-qbv-fixes-v4-2-26481c7634e3@altera.com>
References: <20251028-qbv-fixes-v4-0-26481c7634e3@altera.com>
In-Reply-To: <20251028-qbv-fixes-v4-0-26481c7634e3@altera.com>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Jose Abreu <Jose.Abreu@synopsys.com>, 
 Rohan G Thomas <rohan.g.thomas@intel.com>, 
 Boon Khai Ng <boon.khai.ng@altera.com>
Cc: netdev@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Rohan G Thomas <rohan.g.thomas@altera.com>, 
 Matthew Gerlach <matthew.gerlach@altera.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761621544; l=2209;
 i=rohan.g.thomas@altera.com; s=20250815; h=from:subject:message-id;
 bh=CO26pwlKR66OKT0ufmF/QwQbSxoYj3sToTSLa+5EzgI=;
 b=Gx526F+k/ZNMujmfc2ZDc8kjxctS/U7dvX8WX5u1qa+DoeQOX4uMPftUDysPHK0eIcXFcqg6f
 z96MVfr+AWPA9DUEipfGr9/X2Y0tjgBGEbyththa8HqFWE+xwgXnZb4
X-Developer-Key: i=rohan.g.thomas@altera.com; a=ed25519;
 pk=5yZXkXswhfUILKAQwoIn7m6uSblwgV5oppxqde4g4TY=
X-Endpoint-Received: by B4 Relay for rohan.g.thomas@altera.com/20250815 with auth_id=494
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Queue maxSDU requirement of 802.1 Qbv standard requires mac to drop
packets that exceeds maxSDU length and maxSDU doesn't include
preamble, destination and source address, or FCS but includes
ethernet type and VLAN header.

On hardware with Tx VLAN offload enabled, VLAN header length is not
included in the skb->len, when Tx VLAN offload is requested. This
leads to incorrect length checks and allows transmission of
oversized packets. Add the VLAN_HLEN to the skb->len before checking
the Qbv maxSDU if Tx VLAN offload is requested for the packet.

Fixes: c5c3e1bfc9e0 ("net: stmmac: Offload queueMaxSDU from tc-taprio")
Signed-off-by: Rohan G Thomas <rohan.g.thomas@altera.com>
Reviewed-by: Matthew Gerlach <matthew.gerlach@altera.com>
---
 drivers/net/ethernet/stmicro/stmmac/stmmac_main.c | 14 ++++++++++----
 1 file changed, 10 insertions(+), 4 deletions(-)

diff --git a/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c b/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
index 0e2dc0a464d5516b8aabe2f9afc60c6e37f0209e..042c823bbced88070fa26003c6b513257c0f2bb6 100644
--- a/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
+++ b/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
@@ -4518,6 +4518,7 @@ static netdev_tx_t stmmac_xmit(struct sk_buff *skb, struct net_device *dev)
 	bool has_vlan, set_ic;
 	int entry, first_tx;
 	dma_addr_t des;
+	u32 sdu_len;
 
 	tx_q = &priv->dma_conf.tx_queue[queue];
 	txq_stats = &priv->xstats.txq_stats[queue];
@@ -4536,10 +4537,15 @@ static netdev_tx_t stmmac_xmit(struct sk_buff *skb, struct net_device *dev)
 	}
 
 	if (priv->est && priv->est->enable &&
-	    priv->est->max_sdu[queue] &&
-	    skb->len > priv->est->max_sdu[queue]){
-		priv->xstats.max_sdu_txq_drop[queue]++;
-		goto max_sdu_err;
+	    priv->est->max_sdu[queue]) {
+		sdu_len = skb->len;
+		/* Add VLAN tag length if VLAN tag insertion offload is requested */
+		if (priv->dma_cap.vlins && skb_vlan_tag_present(skb))
+			sdu_len += VLAN_HLEN;
+		if (sdu_len > priv->est->max_sdu[queue]) {
+			priv->xstats.max_sdu_txq_drop[queue]++;
+			goto max_sdu_err;
+		}
 	}
 
 	if (unlikely(stmmac_tx_avail(priv, queue) < nfrags + 1)) {

-- 
2.43.7

