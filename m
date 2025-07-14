From: Rohan G Thomas <rohan.g.thomas@altera.com>
Date: Mon, 14 Jul 2025 15:59:19 +0800
Subject: [PATCH net-next 3/3] net: stmmac: Set CIC bit only for TX queues
 with COE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250714-xgmac-minor-fixes-v1-3-c34092a88a72@altera.com>
References: <20250714-xgmac-minor-fixes-v1-0-c34092a88a72@altera.com>
In-Reply-To: <20250714-xgmac-minor-fixes-v1-0-c34092a88a72@altera.com>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Serge Semin <fancer.lancer@gmail.com>, 
 Romain Gantois <romain.gantois@bootlin.com>
Cc: netdev@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Rohan G Thomas <rohan.g.thomas@altera.com>, 
 Matthew Gerlach <matthew.gerlach@altera.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752480026; l=2519;
 i=rohan.g.thomas@altera.com; s=20250415; h=from:subject:message-id;
 bh=LvG0a5gBZ5g9VJhz1xFTiPD3FiH+GWS8NxcWQcWl6tc=;
 b=fVE9HlJaErdbIModd8D71uXp7Ny7wlJiiE+7BHU4coROJ/HaDD30Ly3V5zU8VBfqhYvYFE9wP
 g7WemhMLVucCOrtR+ZTEuvc3FgAK2dfr1Dr9e90L76eE7gmhl75xTAw
X-Developer-Key: i=rohan.g.thomas@altera.com; a=ed25519;
 pk=TLFM1xzY5sPOABaIaXHDNxCAiDwRegVWoy1tP842z5E=
X-Endpoint-Received: by B4 Relay for rohan.g.thomas@altera.com/20250415 with auth_id=460
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, in the AF_XDP transmit paths, the CIC bit of
TX Desc3 is set for all packets. Setting this bit for
packets transmitting through queues that don't support
checksum offloading causes the TX DMA to get stuck after
transmitting some packets. This patch ensures the CIC bit
of TX Desc3 is set only if the TX queue supports checksum
offloading.

Signed-off-by: Rohan G Thomas <rohan.g.thomas@altera.com>
Reviewed-by: Matthew Gerlach <matthew.gerlach@altera.com>
---
 drivers/net/ethernet/stmicro/stmmac/stmmac_main.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c b/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
index f350a6662880a230a32ad6785c475cce4e950322..d9f7435a44fac695899e0b4ffd0dc7851c4e759f 100644
--- a/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
+++ b/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
@@ -2584,6 +2584,7 @@ static bool stmmac_xdp_xmit_zc(struct stmmac_priv *priv, u32 queue, u32 budget)
 	struct netdev_queue *nq = netdev_get_tx_queue(priv->dev, queue);
 	struct stmmac_tx_queue *tx_q = &priv->dma_conf.tx_queue[queue];
 	struct stmmac_txq_stats *txq_stats = &priv->xstats.txq_stats[queue];
+	bool csum = !priv->plat->tx_queues_cfg[queue].coe_unsupported;
 	struct xsk_buff_pool *pool = tx_q->xsk_pool;
 	unsigned int entry = tx_q->cur_tx;
 	struct dma_desc *tx_desc = NULL;
@@ -2671,7 +2672,7 @@ static bool stmmac_xdp_xmit_zc(struct stmmac_priv *priv, u32 queue, u32 budget)
 		}
 
 		stmmac_prepare_tx_desc(priv, tx_desc, 1, xdp_desc.len,
-				       true, priv->mode, true, true,
+				       csum, priv->mode, true, true,
 				       xdp_desc.len);
 
 		stmmac_enable_dma_transmission(priv, priv->ioaddr, queue);
@@ -4983,6 +4984,7 @@ static int stmmac_xdp_xmit_xdpf(struct stmmac_priv *priv, int queue,
 {
 	struct stmmac_txq_stats *txq_stats = &priv->xstats.txq_stats[queue];
 	struct stmmac_tx_queue *tx_q = &priv->dma_conf.tx_queue[queue];
+	bool csum = !priv->plat->tx_queues_cfg[queue].coe_unsupported;
 	unsigned int entry = tx_q->cur_tx;
 	struct dma_desc *tx_desc;
 	dma_addr_t dma_addr;
@@ -5034,7 +5036,7 @@ static int stmmac_xdp_xmit_xdpf(struct stmmac_priv *priv, int queue,
 	stmmac_set_desc_addr(priv, tx_desc, dma_addr);
 
 	stmmac_prepare_tx_desc(priv, tx_desc, 1, xdpf->len,
-			       true, priv->mode, true, true,
+			       csum, priv->mode, true, true,
 			       xdpf->len);
 
 	tx_q->tx_count_frames++;

-- 
2.25.1

