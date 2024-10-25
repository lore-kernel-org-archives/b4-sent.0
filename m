From: Nelson Escobar <neescoba@cisco.com>
Date: Thu, 24 Oct 2024 18:19:45 -0700
Subject: [PATCH net-next v2 3/5] enic: Save resource counts we read from HW
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241024-remove_vic_resource_limits-v2-3-039b8cae5fdd@cisco.com>
References: <20241024-remove_vic_resource_limits-v2-0-039b8cae5fdd@cisco.com>
In-Reply-To: <20241024-remove_vic_resource_limits-v2-0-039b8cae5fdd@cisco.com>
To: John Daley <johndale@cisco.com>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Christian Benvenuti <benve@cisco.com>, Satish Kharat <satishkh@cisco.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nelson Escobar <neescoba@cisco.com>, Simon Horman <horms@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729819262; l=4213;
 i=neescoba@cisco.com; s=20241023; h=from:subject:message-id;
 bh=xLHC8wEqUFjN0bkMiGJDjRPC+kG1EB+4ffnh4Hz1IXk=;
 b=Q+8WYR68oHWq3/IeOPfaM03pP1NuQr62jm6ptrKdoBJJE9adzIhP1A0Rz792+bMhlIBPaa/e/
 lPSicyrSJCxDWkLmQ3XkHpPdzb21SM8GHAMNvAHB/yrwXRva13CZh9y
X-Developer-Key: i=neescoba@cisco.com; a=ed25519;
 pk=bLqWB7VU0KFoVybF4LVB4c2Redvnplt7+5zLHf4KwZM=
X-Endpoint-Received: by B4 Relay for neescoba@cisco.com/20241023 with auth_id=255
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Save the resources counts for wq,rq,cq, and interrupts in *_avail variables
so that we don't lose the information when adjusting the counts we are
actually using.

Report the wq_avail and rq_avail as the channel maximums in 'ethtool -l'
output.

Co-developed-by: John Daley <johndale@cisco.com>
Signed-off-by: John Daley <johndale@cisco.com>
Co-developed-by: Satish Kharat <satishkh@cisco.com>
Signed-off-by: Satish Kharat <satishkh@cisco.com>
Signed-off-by: Nelson Escobar <neescoba@cisco.com>
Reviewed-by: Simon Horman <horms@kernel.org>
---
 drivers/net/ethernet/cisco/enic/enic.h         |  4 ++++
 drivers/net/ethernet/cisco/enic/enic_ethtool.c |  4 ++--
 drivers/net/ethernet/cisco/enic/enic_res.c     | 19 ++++++++++++-------
 3 files changed, 18 insertions(+), 9 deletions(-)

diff --git a/drivers/net/ethernet/cisco/enic/enic.h b/drivers/net/ethernet/cisco/enic/enic.h
index ac7236f76a51bf32e7060ee0482b41fe82b60b44..1f32413a8f7c690060fe385b50f7447943e72596 100644
--- a/drivers/net/ethernet/cisco/enic/enic.h
+++ b/drivers/net/ethernet/cisco/enic/enic.h
@@ -206,23 +206,27 @@ struct enic {
 
 	/* work queue cache line section */
 	____cacheline_aligned struct enic_wq wq[ENIC_WQ_MAX];
+	unsigned int wq_avail;
 	unsigned int wq_count;
 	u16 loop_enable;
 	u16 loop_tag;
 
 	/* receive queue cache line section */
 	____cacheline_aligned struct enic_rq rq[ENIC_RQ_MAX];
+	unsigned int rq_avail;
 	unsigned int rq_count;
 	struct vxlan_offload vxlan;
 	struct napi_struct napi[ENIC_RQ_MAX + ENIC_WQ_MAX];
 
 	/* interrupt resource cache line section */
 	____cacheline_aligned struct vnic_intr intr[ENIC_INTR_MAX];
+	unsigned int intr_avail;
 	unsigned int intr_count;
 	u32 __iomem *legacy_pba;		/* memory-mapped */
 
 	/* completion queue cache line section */
 	____cacheline_aligned struct vnic_cq cq[ENIC_CQ_MAX];
+	unsigned int cq_avail;
 	unsigned int cq_count;
 	struct enic_rfs_flw_tbl rfs_h;
 	u32 rx_copybreak;
diff --git a/drivers/net/ethernet/cisco/enic/enic_ethtool.c b/drivers/net/ethernet/cisco/enic/enic_ethtool.c
index 909d6f7000e160cf2e15de4660c1034cad7d51ba..d607b4f0542ceaef09e9528a591ca27177986143 100644
--- a/drivers/net/ethernet/cisco/enic/enic_ethtool.c
+++ b/drivers/net/ethernet/cisco/enic/enic_ethtool.c
@@ -695,8 +695,8 @@ static void enic_get_channels(struct net_device *netdev,
 
 	switch (vnic_dev_get_intr_mode(enic->vdev)) {
 	case VNIC_DEV_INTR_MODE_MSIX:
-		channels->max_rx = ENIC_RQ_MAX;
-		channels->max_tx = ENIC_WQ_MAX;
+		channels->max_rx = min(enic->rq_avail, ENIC_RQ_MAX);
+		channels->max_tx = min(enic->wq_avail, ENIC_WQ_MAX);
 		channels->rx_count = enic->rq_count;
 		channels->tx_count = enic->wq_count;
 		break;
diff --git a/drivers/net/ethernet/cisco/enic/enic_res.c b/drivers/net/ethernet/cisco/enic/enic_res.c
index 6910f83185c44797d769434fbe8af3105215b143..e26e43dbfa9c928f40433e0b731d0afb556a694c 100644
--- a/drivers/net/ethernet/cisco/enic/enic_res.c
+++ b/drivers/net/ethernet/cisco/enic/enic_res.c
@@ -187,16 +187,21 @@ void enic_free_vnic_resources(struct enic *enic)
 
 void enic_get_res_counts(struct enic *enic)
 {
-	enic->wq_count = vnic_dev_get_res_count(enic->vdev, RES_TYPE_WQ);
-	enic->rq_count = vnic_dev_get_res_count(enic->vdev, RES_TYPE_RQ);
-	enic->cq_count = vnic_dev_get_res_count(enic->vdev, RES_TYPE_CQ);
-	enic->intr_count = vnic_dev_get_res_count(enic->vdev,
-		RES_TYPE_INTR_CTRL);
+	enic->wq_avail = vnic_dev_get_res_count(enic->vdev, RES_TYPE_WQ);
+	enic->rq_avail = vnic_dev_get_res_count(enic->vdev, RES_TYPE_RQ);
+	enic->cq_avail = vnic_dev_get_res_count(enic->vdev, RES_TYPE_CQ);
+	enic->intr_avail = vnic_dev_get_res_count(enic->vdev,
+						  RES_TYPE_INTR_CTRL);
+
+	enic->wq_count = enic->wq_avail;
+	enic->rq_count = enic->rq_avail;
+	enic->cq_count = enic->cq_avail;
+	enic->intr_count = enic->intr_avail;
 
 	dev_info(enic_get_dev(enic),
 		"vNIC resources avail: wq %d rq %d cq %d intr %d\n",
-		enic->wq_count, enic->rq_count,
-		enic->cq_count, enic->intr_count);
+		enic->wq_avail, enic->rq_avail,
+		enic->cq_avail, enic->intr_avail);
 }
 
 void enic_init_vnic_resources(struct enic *enic)

-- 
2.47.0

