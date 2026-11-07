From: =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
Date: Sat, 07 Nov 2026 05:28:41 -0600
Subject: [PATCH 2/2] staging: octeon: prevent buffer overflow in
 cvm_oct_xmit_pow()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261107-octeon-tx-fixes-v1-2-db03f73a6e6f@gmail.com>
References: <20261107-octeon-tx-fixes-v1-0-db03f73a6e6f@gmail.com>
In-Reply-To: <20261107-octeon-tx-fixes-v1-0-db03f73a6e6f@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794050920; l=3088;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=A73cNrYJxl0LgvL86wV5fevUF4EgHv5VLNNXVCqJff4=;
 b=8Ohcw2vIma8Mg7JGcXtgSkTTw2bGrzFslZyZUPh1Dc32Izwc+uKQjFsCQN1LmFjihMSUd16kl
 wujqUh13KwFCFCp66N2MIoiHiPKMfemd5eYFM3ldJnuLKrYeMR53jXc
X-Developer-Key: i=aleszlucero@gmail.com; a=ed25519;
 pk=zRzEBMID7l1FXqr2CjfnlIn++3m3N05FuNYb5zPA3cw=
X-Endpoint-Received: by B4 Relay for aleszlucero@gmail.com/20261104 with auth_id=1410
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

cvm_oct_xmit_pow() copies packet data into an allocated FPA packet pool
buffer without checking if skb->len plus the header offset fits within
CVMX_FPA_PACKET_POOL_SIZE, which can cause a buffer overflow. Drop
oversized packets before allocating hardware buffers.

Additionally, fixed-size memcpys into work->packet_data read directly
from skb->data without checking skb->len, risking out-of-bounds reads
on short packets. Bound these copies using min_t().

Signed-off-by: Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>
---
 drivers/staging/octeon/ethernet-tx.c | 24 +++++++++++++++++-------
 1 file changed, 17 insertions(+), 7 deletions(-)

diff --git a/drivers/staging/octeon/ethernet-tx.c b/drivers/staging/octeon/ethernet-tx.c
index 13a205648f8b..0a350faec591 100644
--- a/drivers/staging/octeon/ethernet-tx.c
+++ b/drivers/staging/octeon/ethernet-tx.c
@@ -507,10 +507,18 @@ netdev_tx_t cvm_oct_xmit_pow(struct sk_buff *skb, struct net_device *dev)
 	struct octeon_ethernet *priv = netdev_priv(dev);
 	u8 *packet_buffer;
 	u8 *copy_location;
+	size_t header_skip = sizeof(u64) +
+			     ((CVMX_HELPER_FIRST_MBUFF_SKIP + 7) & 0xfff8) + 6;
+	struct cvmx_wqe *work;
 
-	/* Get a work queue entry */
-	struct cvmx_wqe *work = cvmx_fpa_alloc(CVMX_FPA_WQE_POOL);
+	if (unlikely(header_skip + skb->len > CVMX_FPA_PACKET_POOL_SIZE)) {
+		dev->stats.tx_dropped++;
+		dev_kfree_skb_any(skb);
+		return NETDEV_TX_OK;
+	}
 
+	/* Get a work queue entry */
+	work = cvmx_fpa_alloc(CVMX_FPA_WQE_POOL);
 	if (unlikely(!work)) {
 		printk_ratelimited("%s: Failed to allocate a work queue entry\n",
 				   dev->name);
@@ -538,8 +546,7 @@ netdev_tx_t cvm_oct_xmit_pow(struct sk_buff *skb, struct net_device *dev)
 	 * calculation may add a little extra, but that doesn't
 	 * hurt.
 	 */
-	copy_location = packet_buffer + sizeof(u64);
-	copy_location += ((CVMX_HELPER_FIRST_MBUFF_SKIP + 7) & 0xfff8) + 6;
+	copy_location = packet_buffer + header_skip;
 
 	/*
 	 * We have to copy the packet since whoever processes this
@@ -586,8 +593,10 @@ netdev_tx_t cvm_oct_xmit_pow(struct sk_buff *skb, struct net_device *dev)
 		 * ethernet header to align the same way hardware
 		 * does.
 		 */
-		memcpy(work->packet_data, skb->data + 10,
-		       sizeof(work->packet_data));
+		if (skb->len > 10)
+			memcpy(work->packet_data, skb->data + 10,
+			       min_t(size_t, sizeof(work->packet_data),
+				     skb->len - 10));
 	} else {
 		work->word2.snoip.is_rarp = skb->protocol == htons(ETH_P_RARP);
 		work->word2.snoip.is_arp = skb->protocol == htons(ETH_P_ARP);
@@ -596,7 +605,8 @@ netdev_tx_t cvm_oct_xmit_pow(struct sk_buff *skb, struct net_device *dev)
 		work->word2.snoip.is_mcast =
 		    (skb->pkt_type == PACKET_MULTICAST);
 		work->word2.snoip.not_IP = 1;	/* IP was done up above */
-		memcpy(work->packet_data, skb->data, sizeof(work->packet_data));
+		memcpy(work->packet_data, skb->data,
+		       min_t(size_t, sizeof(work->packet_data), skb->len));
 	}
 
 	/* Submit the packet to the POW */

-- 
2.56.0

