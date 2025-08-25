From: Rohan G Thomas <rohan.g.thomas@altera.com>
Date: Mon, 25 Aug 2025 12:36:54 +0800
Subject: [PATCH net v3 3/3] net: stmmac: Set CIC bit only for TX queues
 with COE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250825-xgmac-minor-fixes-v3-3-c225fe4444c0@altera.com>
References: <20250825-xgmac-minor-fixes-v3-0-c225fe4444c0@altera.com>
In-Reply-To: <20250825-xgmac-minor-fixes-v3-0-c225fe4444c0@altera.com>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Jose Abreu <Jose.Abreu@synopsys.com>, 
 Romain Gantois <romain.gantois@bootlin.com>, 
 Serge Semin <fancer.lancer@gmail.com>, 
 Ong Boon Leong <boon.leong.ong@intel.com>
Cc: netdev@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Rohan G Thomas <rohan.g.thomas@altera.com>, 
 Matthew Gerlach <matthew.gerlach@altera.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756096627; l=2589;
 i=rohan.g.thomas@altera.com; s=20250815; h=from:subject:message-id;
 bh=ufHiTveJv2qBm24xiMB0gFsw0pu0zMd7hgFCJ9lPQkI=;
 b=J9xTvnesrv2sisMNAGCxcdrQoTHV2SLh3+3iW7faARF6ra+9ADLML6lJxH36GguS6UndD/PB5
 eTShfFdRmoiBgCrCLRf6pVPz270nXnPUja344HDqgLcK5teGx39zsAD
X-Developer-Key: i=rohan.g.thomas@altera.com; a=ed25519;
 pk=5yZXkXswhfUILKAQwoIn7m6uSblwgV5oppxqde4g4TY=
X-Endpoint-Received: by B4 Relay for rohan.g.thomas@altera.com/20250815 with auth_id=494
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, in the AF_XDP transmit paths, the CIC bit of
TX Desc3 is set for all packets. Setting this bit for
packets transmitting through queues that don't support
checksum offloading causes the TX DMA to get stuck after
transmitting some packets. This patch ensures the CIC bit
of TX Desc3 is set only if the TX queue supports checksum
offloading.

Fixes: 132c32ee5bc0 ("net: stmmac: Add TX via XDP zero-copy socket")
Signed-off-by: Rohan G Thomas <rohan.g.thomas@altera.com>
Reviewed-by: Matthew Gerlach <matthew.gerlach@altera.com>
---
 drivers/net/ethernet/stmicro/stmmac/stmmac_main.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c b/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
index fa3d26c285025d01c72cef51add534fc722552b8..143e68639548f390e97b5a8dd09f3f4af12cec43 100644
--- a/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
+++ b/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
@@ -2585,6 +2585,7 @@ static bool stmmac_xdp_xmit_zc(struct stmmac_priv *priv, u32 queue, u32 budget)
 	struct netdev_queue *nq = netdev_get_tx_queue(priv->dev, queue);
 	struct stmmac_tx_queue *tx_q = &priv->dma_conf.tx_queue[queue];
 	struct stmmac_txq_stats *txq_stats = &priv->xstats.txq_stats[queue];
+	bool csum = !priv->plat->tx_queues_cfg[queue].coe_unsupported;
 	struct xsk_buff_pool *pool = tx_q->xsk_pool;
 	unsigned int entry = tx_q->cur_tx;
 	struct dma_desc *tx_desc = NULL;
@@ -2672,7 +2673,7 @@ static bool stmmac_xdp_xmit_zc(struct stmmac_priv *priv, u32 queue, u32 budget)
 		}
 
 		stmmac_prepare_tx_desc(priv, tx_desc, 1, xdp_desc.len,
-				       true, priv->mode, true, true,
+				       csum, priv->mode, true, true,
 				       xdp_desc.len);
 
 		stmmac_enable_dma_transmission(priv, priv->ioaddr, queue);
@@ -4987,6 +4988,7 @@ static int stmmac_xdp_xmit_xdpf(struct stmmac_priv *priv, int queue,
 {
 	struct stmmac_txq_stats *txq_stats = &priv->xstats.txq_stats[queue];
 	struct stmmac_tx_queue *tx_q = &priv->dma_conf.tx_queue[queue];
+	bool csum = !priv->plat->tx_queues_cfg[queue].coe_unsupported;
 	unsigned int entry = tx_q->cur_tx;
 	struct dma_desc *tx_desc;
 	dma_addr_t dma_addr;
@@ -5038,7 +5040,7 @@ static int stmmac_xdp_xmit_xdpf(struct stmmac_priv *priv, int queue,
 	stmmac_set_desc_addr(priv, tx_desc, dma_addr);
 
 	stmmac_prepare_tx_desc(priv, tx_desc, 1, xdpf->len,
-			       true, priv->mode, true, true,
+			       csum, priv->mode, true, true,
 			       xdpf->len);
 
 	tx_q->tx_count_frames++;

-- 
2.25.1

