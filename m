From: Satish Kharat <satishkh@cisco.com>
Date: Thu, 06 Mar 2025 19:15:29 -0500
Subject: [PATCH net-next v3 8/8] enic: get max rq & wq entries supported by
 hw, 16K queues
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250306-enic_cleanup_and_ext_cq-v3-8-92bc165344cf@cisco.com>
References: <20250306-enic_cleanup_and_ext_cq-v3-0-92bc165344cf@cisco.com>
In-Reply-To: <20250306-enic_cleanup_and_ext_cq-v3-0-92bc165344cf@cisco.com>
To: Christian Benvenuti <benve@cisco.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Satish Kharat <satishkh@cisco.com>, Nelson Escobar <neescoba@cisco.com>, 
 John Daley <johndale@cisco.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741306525; l=8011;
 i=satishkh@cisco.com; s=20250226; h=from:subject:message-id;
 bh=x77EXPuH2B5E7HMjpcZQpt6qDulc8/gTpGpVsIUdnxk=;
 b=1vuLMC5V87Q5P4kCNQLnzdFvYAyf+wQ07mvrDeBn2+EH1VldC7jJ7uGBIKMGfRj/TU58JMp1d
 yvLsUetsJetDpj5WWTxOYsU5Awb8QSyoZpbVt9d5yJk7KHCFzssC/fn
X-Developer-Key: i=satishkh@cisco.com; a=ed25519;
 pk=lkxzORFYn5ejiy0kzcsfkpGoXZDcnHMc4n3YK7jJnJo=
X-Endpoint-Received: by B4 Relay for satishkh@cisco.com/20250226 with auth_id=351
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enables reading the max rq and wq entries supported from the hw.
Enables 16k rq and wq entries on hw that supports.

Co-developed-by: Nelson Escobar <neescoba@cisco.com>
Signed-off-by: Nelson Escobar <neescoba@cisco.com>
Co-developed-by: John Daley <johndale@cisco.com>
Signed-off-by: John Daley <johndale@cisco.com>
Signed-off-by: Satish Kharat <satishkh@cisco.com>
---
 drivers/net/ethernet/cisco/enic/enic_ethtool.c | 12 +++++------
 drivers/net/ethernet/cisco/enic/enic_res.c     | 29 ++++++++++++++++----------
 drivers/net/ethernet/cisco/enic/enic_res.h     | 11 ++++++----
 drivers/net/ethernet/cisco/enic/enic_wq.c      |  2 +-
 drivers/net/ethernet/cisco/enic/vnic_enet.h    |  5 +++++
 drivers/net/ethernet/cisco/enic/vnic_rq.h      |  2 +-
 drivers/net/ethernet/cisco/enic/vnic_wq.h      |  2 +-
 7 files changed, 39 insertions(+), 24 deletions(-)

diff --git a/drivers/net/ethernet/cisco/enic/enic_ethtool.c b/drivers/net/ethernet/cisco/enic/enic_ethtool.c
index 18b929fc2879912ad09025996a4f1b9fdb353961..529160926a9633f5e2d60e6842c2fcf07492854b 100644
--- a/drivers/net/ethernet/cisco/enic/enic_ethtool.c
+++ b/drivers/net/ethernet/cisco/enic/enic_ethtool.c
@@ -222,9 +222,9 @@ static void enic_get_ringparam(struct net_device *netdev,
 	struct enic *enic = netdev_priv(netdev);
 	struct vnic_enet_config *c = &enic->config;
 
-	ring->rx_max_pending = ENIC_MAX_RQ_DESCS;
+	ring->rx_max_pending = c->max_rq_ring;
 	ring->rx_pending = c->rq_desc_count;
-	ring->tx_max_pending = ENIC_MAX_WQ_DESCS;
+	ring->tx_max_pending = c->max_wq_ring;
 	ring->tx_pending = c->wq_desc_count;
 }
 
@@ -252,18 +252,18 @@ static int enic_set_ringparam(struct net_device *netdev,
 	}
 	rx_pending = c->rq_desc_count;
 	tx_pending = c->wq_desc_count;
-	if (ring->rx_pending > ENIC_MAX_RQ_DESCS ||
+	if (ring->rx_pending > c->max_rq_ring ||
 	    ring->rx_pending < ENIC_MIN_RQ_DESCS) {
 		netdev_info(netdev, "rx pending (%u) not in range [%u,%u]",
 			    ring->rx_pending, ENIC_MIN_RQ_DESCS,
-			    ENIC_MAX_RQ_DESCS);
+	      c->max_rq_ring);
 		return -EINVAL;
 	}
-	if (ring->tx_pending > ENIC_MAX_WQ_DESCS ||
+	if (ring->tx_pending > c->max_wq_ring ||
 	    ring->tx_pending < ENIC_MIN_WQ_DESCS) {
 		netdev_info(netdev, "tx pending (%u) not in range [%u,%u]",
 			    ring->tx_pending, ENIC_MIN_WQ_DESCS,
-			    ENIC_MAX_WQ_DESCS);
+			c->max_wq_ring);
 		return -EINVAL;
 	}
 	if (running)
diff --git a/drivers/net/ethernet/cisco/enic/enic_res.c b/drivers/net/ethernet/cisco/enic/enic_res.c
index a7179cc4b5296cfbce137c54a9e17e6b358a19ae..bbd3143ed73e77d25a1e4921e073c929e92d8230 100644
--- a/drivers/net/ethernet/cisco/enic/enic_res.c
+++ b/drivers/net/ethernet/cisco/enic/enic_res.c
@@ -59,31 +59,38 @@ int enic_get_vnic_config(struct enic *enic)
 	GET_CONFIG(intr_timer_usec);
 	GET_CONFIG(loop_tag);
 	GET_CONFIG(num_arfs);
+	GET_CONFIG(max_rq_ring);
+	GET_CONFIG(max_wq_ring);
+	GET_CONFIG(max_cq_ring);
+
+	if (!c->max_wq_ring)
+		c->max_wq_ring = ENIC_MAX_WQ_DESCS_DEFAULT;
+	if (!c->max_rq_ring)
+		c->max_rq_ring = ENIC_MAX_RQ_DESCS_DEFAULT;
+	if (!c->max_cq_ring)
+		c->max_cq_ring = ENIC_MAX_CQ_DESCS_DEFAULT;
 
 	c->wq_desc_count =
-		min_t(u32, ENIC_MAX_WQ_DESCS,
-		max_t(u32, ENIC_MIN_WQ_DESCS,
-		c->wq_desc_count));
+		min_t(u32, c->max_wq_ring,
+		      max_t(u32, ENIC_MIN_WQ_DESCS, c->wq_desc_count));
 	c->wq_desc_count &= 0xffffffe0; /* must be aligned to groups of 32 */
 
 	c->rq_desc_count =
-		min_t(u32, ENIC_MAX_RQ_DESCS,
-		max_t(u32, ENIC_MIN_RQ_DESCS,
-		c->rq_desc_count));
+		min_t(u32, c->max_rq_ring,
+		      max_t(u32, ENIC_MIN_RQ_DESCS, c->rq_desc_count));
 	c->rq_desc_count &= 0xffffffe0; /* must be aligned to groups of 32 */
 
 	if (c->mtu == 0)
 		c->mtu = 1500;
-	c->mtu = min_t(u16, ENIC_MAX_MTU,
-		max_t(u16, ENIC_MIN_MTU,
-		c->mtu));
+	c->mtu = min_t(u16, ENIC_MAX_MTU, max_t(u16, ENIC_MIN_MTU, c->mtu));
 
 	c->intr_timer_usec = min_t(u32, c->intr_timer_usec,
 		vnic_dev_get_intr_coal_timer_max(enic->vdev));
 
 	dev_info(enic_get_dev(enic),
-		"vNIC MAC addr %pM wq/rq %d/%d mtu %d\n",
-		enic->mac_addr, c->wq_desc_count, c->rq_desc_count, c->mtu);
+		 "vNIC MAC addr %pM wq/rq %d/%d max wq/rq/cq %d/%d/%d mtu %d\n",
+		 enic->mac_addr, c->wq_desc_count, c->rq_desc_count,
+		 c->max_wq_ring, c->max_rq_ring, c->max_cq_ring, c->mtu);
 
 	dev_info(enic_get_dev(enic), "vNIC csum tx/rx %s/%s "
 		"tso/lro %s/%s rss %s intr mode %s type %s timer %d usec "
diff --git a/drivers/net/ethernet/cisco/enic/enic_res.h b/drivers/net/ethernet/cisco/enic/enic_res.h
index b8ee42d297aaf7db75e711be15280b01389567c9..02dca1ae4a2246811277e5ff3aa6650f09fb0f9a 100644
--- a/drivers/net/ethernet/cisco/enic/enic_res.h
+++ b/drivers/net/ethernet/cisco/enic/enic_res.h
@@ -12,10 +12,13 @@
 #include "vnic_wq.h"
 #include "vnic_rq.h"
 
-#define ENIC_MIN_WQ_DESCS		64
-#define ENIC_MAX_WQ_DESCS		4096
-#define ENIC_MIN_RQ_DESCS		64
-#define ENIC_MAX_RQ_DESCS		4096
+#define ENIC_MIN_WQ_DESCS 64
+#define ENIC_MAX_WQ_DESCS_DEFAULT 4096
+#define ENIC_MAX_WQ_DESCS 16384
+#define ENIC_MIN_RQ_DESCS 64
+#define ENIC_MAX_RQ_DESCS 16384
+#define ENIC_MAX_RQ_DESCS_DEFAULT 4096
+#define ENIC_MAX_CQ_DESCS_DEFAULT (64 * 1024)
 
 #define ENIC_MIN_MTU			ETH_MIN_MTU
 #define ENIC_MAX_MTU			9000
diff --git a/drivers/net/ethernet/cisco/enic/enic_wq.c b/drivers/net/ethernet/cisco/enic/enic_wq.c
index 2a5ddad512e388bf4f42fddaafd9242e20a30fe5..07936f8b423171cd247c3afd695322de820f752f 100644
--- a/drivers/net/ethernet/cisco/enic/enic_wq.c
+++ b/drivers/net/ethernet/cisco/enic/enic_wq.c
@@ -93,7 +93,7 @@ unsigned int enic_wq_cq_service(struct enic *enic, unsigned int cq_index,
 	u8 type, color;
 	bool ext_wq;
 
-	ext_wq = cq->ring.size > ENIC_MAX_WQ_DESCS;
+	ext_wq = cq->ring.size > ENIC_MAX_WQ_DESCS_DEFAULT;
 
 	cq_desc = (struct cq_desc *)vnic_cq_to_clean(cq);
 	enic_wq_cq_desc_dec(cq_desc, ext_wq, &type, &color,
diff --git a/drivers/net/ethernet/cisco/enic/vnic_enet.h b/drivers/net/ethernet/cisco/enic/vnic_enet.h
index 5acc236069dea358c2f330824ad57ad7920889cc..9e8e86262a3fea0ab37f8044c81ba798b5b00c90 100644
--- a/drivers/net/ethernet/cisco/enic/vnic_enet.h
+++ b/drivers/net/ethernet/cisco/enic/vnic_enet.h
@@ -21,6 +21,11 @@ struct vnic_enet_config {
 	u16 loop_tag;
 	u16 vf_rq_count;
 	u16 num_arfs;
+	u8 reserved[66];
+	u32 max_rq_ring;	// MAX RQ ring size
+	u32 max_wq_ring;	// MAX WQ ring size
+	u32 max_cq_ring;	// MAX CQ ring size
+	u32 rdma_rsvd_lkey;	// Reserved (privileged) LKey
 };
 
 #define VENETF_TSO		0x1	/* TSO enabled */
diff --git a/drivers/net/ethernet/cisco/enic/vnic_rq.h b/drivers/net/ethernet/cisco/enic/vnic_rq.h
index 2ee4be2b9a343a7a340c2b4a81fe560ccc2e6715..a1cdd729caece5c3378c3a8025cedf9b2bf758ab 100644
--- a/drivers/net/ethernet/cisco/enic/vnic_rq.h
+++ b/drivers/net/ethernet/cisco/enic/vnic_rq.h
@@ -50,7 +50,7 @@ struct vnic_rq_ctrl {
 	(VNIC_RQ_BUF_BLK_ENTRIES(entries) * sizeof(struct vnic_rq_buf))
 #define VNIC_RQ_BUF_BLKS_NEEDED(entries) \
 	DIV_ROUND_UP(entries, VNIC_RQ_BUF_BLK_ENTRIES(entries))
-#define VNIC_RQ_BUF_BLKS_MAX VNIC_RQ_BUF_BLKS_NEEDED(4096)
+#define VNIC_RQ_BUF_BLKS_MAX VNIC_RQ_BUF_BLKS_NEEDED(16384)
 
 struct vnic_rq_buf {
 	struct vnic_rq_buf *next;
diff --git a/drivers/net/ethernet/cisco/enic/vnic_wq.h b/drivers/net/ethernet/cisco/enic/vnic_wq.h
index 75c52691107447f1ea1deb1d4eeabb0e0313b3eb..3bb4758100ba481c3bd7a873203e8b033d6b99a6 100644
--- a/drivers/net/ethernet/cisco/enic/vnic_wq.h
+++ b/drivers/net/ethernet/cisco/enic/vnic_wq.h
@@ -62,7 +62,7 @@ struct vnic_wq_buf {
 	(VNIC_WQ_BUF_BLK_ENTRIES(entries) * sizeof(struct vnic_wq_buf))
 #define VNIC_WQ_BUF_BLKS_NEEDED(entries) \
 	DIV_ROUND_UP(entries, VNIC_WQ_BUF_BLK_ENTRIES(entries))
-#define VNIC_WQ_BUF_BLKS_MAX VNIC_WQ_BUF_BLKS_NEEDED(4096)
+#define VNIC_WQ_BUF_BLKS_MAX VNIC_WQ_BUF_BLKS_NEEDED(16384)
 
 struct vnic_wq {
 	unsigned int index;

-- 
2.48.1

