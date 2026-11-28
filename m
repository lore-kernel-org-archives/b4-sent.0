From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 28 Nov 2026 19:00:38 +0000
Subject: [PATCH net] net: stmmac: Drop TX buffers too long for normal
 descriptors
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-stmmac-ndesc-tx-len-v1-1-69f737224dc0@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMwQrCMBAFf6Xs2QU3B7X+inhIN6+6YqNkoxRK/
 92oxxmYWchRDE7HbqGCt7k9cgPZdKTXmC9gS40pbMNOJOzZ6zRF5ZzgynXmOzJj7HtNEImHgVr
 5LBht/l1PlFHp/Jf+Gm7Q+v3Run4AgfLLEnwAAAA=
X-Change-ID: 20261127-stmmac-ndesc-tx-len-ef99cde11a8b
To: Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Chen-Yu Tsai <wens@kernel.org>
Cc: netdev@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795892437; l=3104;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=UKsD2T2AGKzpC1WaupMUb300yebHh9UxQbyihv5XzcA=;
 b=6CotknO2Uph/1v38egcb3CMfNMft+oF9JiuwTddyu+L6OEZsBanvDXRX7duiPGFb92TCJ68BP
 C+T6P+VYkEFDIk2MHgC2bC0qPoPiHpwECs94HSYuEysoB5jkBbiOu7E
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Sashiko found in [1] that stmmac_xmit() does not check buffer sizes for
normal descriptors, whose size field has 11 bits. As Chen-Yu Tsai noted
in [2], only enhanced descriptors take the jumbo path that splits
buffers, since commit 29896a674c8e ("stmmac: fix chained mode"). A
longer buffer gets its size cut in chain mode, and in ring mode its
rest goes to buffer 2 at DES3, which is 0.

Such skbs come from MTUs above one buffer, and from act_mirred and BPF
redirect, which do not check the MTU. Drop them and count them in
tx_dropped.

Link: https://lore.kernel.org/r/179542841718.3135.3290374626862889297@kernel.org [1]
Link: https://lore.kernel.org/r/CAGb2v66oxp7G92psuF-pQsha5doh47j2gSMiTY7PAB2dYfozUw@mail.gmail.com [2]
Fixes: 48febf7e6476 ("stmmac: allow mtu bigger than 1500 in case of normal desc (V4)")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Tested on an H616 (chain mode) with skbs of 1600 to 9000 bytes from
tc mirred at MTU 1500. Without this patch, TX stops at a 2048-byte
linear skb until the TX watchdog resets it. With it, every skb with a
buffer of 2048 bytes or more is dropped and counted, and TX stays up.
Ring mode is untested. AF_XDP zero-copy TX has the same gap and is not
covered.

Developed with Claude (Anthropic), which wrote the code and the commit
message. I reviewed every change.
---
 drivers/net/ethernet/stmicro/stmmac/stmmac_main.c | 25 +++++++++++++++++++++++
 1 file changed, 25 insertions(+)

diff --git a/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c b/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
index a685ce4638f6..f21f7fc1beb7 100644
--- a/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
+++ b/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
@@ -2033,6 +2033,25 @@ static void stmmac_set_tx_dma_last_segment(struct stmmac_tx_queue *tx_q,
 	tx_q->tx_skbuff_dma[entry].last_segment = true;
 }
 
+/* Normal descriptors have an 11-bit buffer size */
+static bool stmmac_ndesc_tx_too_long(struct stmmac_priv *priv,
+				     struct sk_buff *skb)
+{
+	unsigned int i;
+
+	if (priv->hw->desc != &ndesc_ops)
+		return false;
+
+	if (skb_headlen(skb) >= BUF_SIZE_2KiB)
+		return true;
+
+	for (i = 0; i < skb_shinfo(skb)->nr_frags; i++)
+		if (skb_frag_size(&skb_shinfo(skb)->frags[i]) >= BUF_SIZE_2KiB)
+			return true;
+
+	return false;
+}
+
 /**
  * __init_dma_tx_desc_rings - init the TX descriptor ring (per queue)
  * @priv: driver private structure
@@ -4889,6 +4908,12 @@ static netdev_tx_t stmmac_xmit(struct sk_buff *skb, struct net_device *dev)
 		}
 	}
 
+	if (unlikely(stmmac_ndesc_tx_too_long(priv, skb))) {
+		dev_kfree_skb(skb);
+		priv->xstats.tx_dropped++;
+		return NETDEV_TX_OK;
+	}
+
 	if (unlikely(stmmac_tx_avail(priv, queue) < nfrags + 1)) {
 		if (!netif_tx_queue_stopped(netdev_get_tx_queue(dev, queue))) {
 			netif_tx_stop_queue(netdev_get_tx_queue(priv->dev,

---
base-commit: 28a371228d4eb4857cc31eeb1a0d7d01e9c3ea2f
change-id: 20261127-stmmac-ndesc-tx-len-ef99cde11a8b

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

