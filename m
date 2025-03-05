From: Satish Kharat <satishkh@cisco.com>
Date: Tue, 04 Mar 2025 19:56:43 -0500
Subject: [PATCH net-next v2 7/8] enic : cleanup of enic wq request
 completion path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250304-enic_cleanup_and_ext_cq-v2-7-85804263dad8@cisco.com>
References: <20250304-enic_cleanup_and_ext_cq-v2-0-85804263dad8@cisco.com>
In-Reply-To: <20250304-enic_cleanup_and_ext_cq-v2-0-85804263dad8@cisco.com>
To: Christian Benvenuti <benve@cisco.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Satish Kharat <satishkh@cisco.com>, Nelson Escobar <neescoba@cisco.com>, 
 John Daley <johndale@cisco.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741136202; l=7106;
 i=satishkh@cisco.com; s=20250226; h=from:subject:message-id;
 bh=LSUtWjfYnz6LTQxQS0/89Gz5g5ZA5PtHf5hkoJHWnVM=;
 b=EmeDT45hr5Ljoz1n0OocDR6OXc00Z2g+L9B7aBgFOGoblkV3wjzoOJe5yDFktTvfjwGK2y+Y8
 l5iQABoq4SLCLb6cJWyNH5gE9pTkSPjR6p6pZKc9hqdr9nCr/oF5Bu0
X-Developer-Key: i=satishkh@cisco.com; a=ed25519;
 pk=lkxzORFYn5ejiy0kzcsfkpGoXZDcnHMc4n3YK7jJnJo=
X-Endpoint-Received: by B4 Relay for satishkh@cisco.com/20250226 with auth_id=351
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Cleans up the enic wq request completion path needed for 16k wq size
support.

Co-developed-by: Nelson Escobar <neescoba@cisco.com>
Signed-off-by: Nelson Escobar <neescoba@cisco.com>
Co-developed-by: John Daley <johndale@cisco.com>
Signed-off-by: John Daley <johndale@cisco.com>
Signed-off-by: Satish Kharat <satishkh@cisco.com>
---
 drivers/net/ethernet/cisco/enic/enic_main.c |  7 +--
 drivers/net/ethernet/cisco/enic/enic_wq.c   | 95 ++++++++++++++---------------
 drivers/net/ethernet/cisco/enic/enic_wq.h   | 11 +---
 3 files changed, 52 insertions(+), 61 deletions(-)

diff --git a/drivers/net/ethernet/cisco/enic/enic_main.c b/drivers/net/ethernet/cisco/enic/enic_main.c
index 52174843f02f1fecc75666367ad5034cbbcf8f07..54aa3953bf7b6ed4fdadd7b9871ee7bbcf6614ea 100644
--- a/drivers/net/ethernet/cisco/enic/enic_main.c
+++ b/drivers/net/ethernet/cisco/enic/enic_main.c
@@ -1332,8 +1332,7 @@ static int enic_poll(struct napi_struct *napi, int budget)
 	unsigned int  work_done, rq_work_done = 0, wq_work_done;
 	int err;
 
-	wq_work_done = vnic_cq_service(&enic->cq[cq_wq], wq_work_to_do,
-				       enic_wq_service, NULL);
+	wq_work_done = enic_wq_cq_service(enic, cq_wq, wq_work_to_do);
 
 	if (budget > 0)
 		rq_work_done = enic_rq_cq_service(enic, cq_rq, rq_work_to_do);
@@ -1435,8 +1434,8 @@ static int enic_poll_msix_wq(struct napi_struct *napi, int budget)
 	wq_irq = wq->index;
 	cq = enic_cq_wq(enic, wq_irq);
 	intr = enic_msix_wq_intr(enic, wq_irq);
-	wq_work_done = vnic_cq_service(&enic->cq[cq], wq_work_to_do,
-				       enic_wq_service, NULL);
+
+	wq_work_done = enic_wq_cq_service(enic, cq, wq_work_to_do);
 
 	vnic_intr_return_credits(&enic->intr[intr], wq_work_done,
 				 0 /* don't unmask intr */,
diff --git a/drivers/net/ethernet/cisco/enic/enic_wq.c b/drivers/net/ethernet/cisco/enic/enic_wq.c
index 59b02906a1f91f695757c649e74e3f6f117abab3..2a5ddad512e388bf4f42fddaafd9242e20a30fe5 100644
--- a/drivers/net/ethernet/cisco/enic/enic_wq.c
+++ b/drivers/net/ethernet/cisco/enic/enic_wq.c
@@ -6,8 +6,12 @@
 #include "enic.h"
 #include "enic_wq.h"
 
-static void cq_desc_dec(const struct cq_desc *desc_arg, u8 *type, u8 *color,
-			u16 *q_number, u16 *completed_index)
+#define ENET_CQ_DESC_COMP_NDX_BITS 14
+#define ENET_CQ_DESC_COMP_NDX_MASK GENMASK(ENET_CQ_DESC_COMP_NDX_BITS - 1, 0)
+
+static void enic_wq_cq_desc_dec(const struct cq_desc *desc_arg, bool ext_wq,
+				u8 *type, u8 *color, u16 *q_number,
+				u16 *completed_index)
 {
 	const struct cq_desc *desc = desc_arg;
 	const u8 type_color = desc->type_color;
@@ -25,48 +29,13 @@ static void cq_desc_dec(const struct cq_desc *desc_arg, u8 *type, u8 *color,
 
 	*type = type_color & CQ_DESC_TYPE_MASK;
 	*q_number = le16_to_cpu(desc->q_number) & CQ_DESC_Q_NUM_MASK;
-	*completed_index = le16_to_cpu(desc->completed_index) &
-		CQ_DESC_COMP_NDX_MASK;
-}
-
-unsigned int vnic_cq_service(struct vnic_cq *cq, unsigned int work_to_do,
-			     int (*q_service)(struct vnic_dev *vdev,
-					      struct cq_desc *cq_desc, u8 type,
-					      u16 q_number, u16 completed_index,
-					      void *opaque), void *opaque)
-{
-	struct cq_desc *cq_desc;
-	unsigned int work_done = 0;
-	u16 q_number, completed_index;
-	u8 type, color;
-
-	cq_desc = (struct cq_desc *)((u8 *)cq->ring.descs +
-		   cq->ring.desc_size * cq->to_clean);
-	cq_desc_dec(cq_desc, &type, &color,
-		    &q_number, &completed_index);
-
-	while (color != cq->last_color) {
-		if ((*q_service)(cq->vdev, cq_desc, type, q_number,
-				 completed_index, opaque))
-			break;
-
-		cq->to_clean++;
-		if (cq->to_clean == cq->ring.desc_count) {
-			cq->to_clean = 0;
-			cq->last_color = cq->last_color ? 0 : 1;
-		}
-
-		cq_desc = (struct cq_desc *)((u8 *)cq->ring.descs +
-			cq->ring.desc_size * cq->to_clean);
-		cq_desc_dec(cq_desc, &type, &color,
-			    &q_number, &completed_index);
 
-		work_done++;
-		if (work_done >= work_to_do)
-			break;
-	}
-
-	return work_done;
+	if (ext_wq)
+		*completed_index = le16_to_cpu(desc->completed_index) &
+			ENET_CQ_DESC_COMP_NDX_MASK;
+	else
+		*completed_index = le16_to_cpu(desc->completed_index) &
+			CQ_DESC_COMP_NDX_MASK;
 }
 
 void enic_free_wq_buf(struct vnic_wq *wq, struct vnic_wq_buf *buf)
@@ -94,15 +63,15 @@ static void enic_wq_free_buf(struct vnic_wq *wq, struct cq_desc *cq_desc,
 	enic_free_wq_buf(wq, buf);
 }
 
-int enic_wq_service(struct vnic_dev *vdev, struct cq_desc *cq_desc, u8 type,
-		    u16 q_number, u16 completed_index, void *opaque)
+static void enic_wq_service(struct vnic_dev *vdev, struct cq_desc *cq_desc,
+			    u8 type, u16 q_number, u16 completed_index)
 {
 	struct enic *enic = vnic_dev_priv(vdev);
 
 	spin_lock(&enic->wq[q_number].lock);
 
 	vnic_wq_service(&enic->wq[q_number].vwq, cq_desc,
-			completed_index, enic_wq_free_buf, opaque);
+			completed_index, enic_wq_free_buf, NULL);
 
 	if (netif_tx_queue_stopped(netdev_get_tx_queue(enic->netdev, q_number))
 	    && vnic_wq_desc_avail(&enic->wq[q_number].vwq) >=
@@ -112,7 +81,37 @@ int enic_wq_service(struct vnic_dev *vdev, struct cq_desc *cq_desc, u8 type,
 	}
 
 	spin_unlock(&enic->wq[q_number].lock);
-
-	return 0;
 }
 
+unsigned int enic_wq_cq_service(struct enic *enic, unsigned int cq_index,
+				unsigned int work_to_do)
+{
+	struct vnic_cq *cq = &enic->cq[cq_index];
+	u16 q_number, completed_index;
+	unsigned int work_done = 0;
+	struct cq_desc *cq_desc;
+	u8 type, color;
+	bool ext_wq;
+
+	ext_wq = cq->ring.size > ENIC_MAX_WQ_DESCS;
+
+	cq_desc = (struct cq_desc *)vnic_cq_to_clean(cq);
+	enic_wq_cq_desc_dec(cq_desc, ext_wq, &type, &color,
+			    &q_number, &completed_index);
+
+	while (color != cq->last_color) {
+		enic_wq_service(cq->vdev, cq_desc, type, q_number,
+				completed_index);
+
+		vnic_cq_inc_to_clean(cq);
+
+		if (++work_done >= work_to_do)
+			break;
+
+		cq_desc = (struct cq_desc *)vnic_cq_to_clean(cq);
+		enic_wq_cq_desc_dec(cq_desc, ext_wq, &type, &color,
+				    &q_number, &completed_index);
+	}
+
+	return work_done;
+}
diff --git a/drivers/net/ethernet/cisco/enic/enic_wq.h b/drivers/net/ethernet/cisco/enic/enic_wq.h
index cc4d6a969a9fb11d6ec3b0e8e56ac106b6d34be2..12acb3f2fbc94e5dab04e300c55c95deb7576de7 100644
--- a/drivers/net/ethernet/cisco/enic/enic_wq.h
+++ b/drivers/net/ethernet/cisco/enic/enic_wq.h
@@ -2,13 +2,6 @@
  * Copyright 2025 Cisco Systems, Inc.  All rights reserved.
  */
 
-unsigned int vnic_cq_service(struct vnic_cq *cq, unsigned int work_to_do,
-			     int (*q_service)(struct vnic_dev *vdev,
-					      struct cq_desc *cq_desc, u8 type,
-					      u16 q_number, u16 completed_index,
-					      void *opaque), void *opaque);
-
 void enic_free_wq_buf(struct vnic_wq *wq, struct vnic_wq_buf *buf);
-
-int enic_wq_service(struct vnic_dev *vdev, struct cq_desc *cq_desc, u8 type,
-		    u16 q_number, u16 completed_index, void *opaque);
+unsigned int enic_wq_cq_service(struct enic *enic, unsigned int cq_index,
+				unsigned int work_to_do);

-- 
2.48.1

