From: Satish Kharat <satishkh@cisco.com>
Date: Wed, 25 Mar 2026 00:21:43 -0700
Subject: [PATCH net-next 5/6] enic: add type-aware alloc for WQ, RQ, CQ and
 INTR resources
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260325-enic-sriov-v2-prep-v1-5-48f04ce110cc@cisco.com>
References: <20260325-enic-sriov-v2-prep-v1-0-48f04ce110cc@cisco.com>
In-Reply-To: <20260325-enic-sriov-v2-prep-v1-0-48f04ce110cc@cisco.com>
To: netdev@vger.kernel.org
Cc: linux-kernel@vger.kernel.org, Satish Kharat <satishkh@cisco.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774423298; l=10146;
 i=satishkh@cisco.com; h=from:subject:message-id;
 bh=sStTy9Bg8r3IiBcBVUP3bIWBVt484dhT5KCgXRyPs1c=;
 b=QmD2EUolDeDfroPNN0AARXNneDqrQo9YfHCPbPow6gBiHnATdgZF4W36W1FKR3pPTSJKekLOZ
 8JiMI9ACvm8DZsRjSdHuzK9IYQOeKslnk5cygrxOr66s3HCEVw2C8g4
X-Developer-Key: i=satishkh@cisco.com; a=ed25519;
 pk=4BxbLoCGvHeIMH/PbpiNVx8/2IcTjFvqcr0AD8K6WLY=
X-Endpoint-Received: by B4 Relay for satishkh@cisco.com/default with auth_id=639
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The existing vnic_wq_alloc(), vnic_rq_alloc(), vnic_cq_alloc() and
vnic_intr_alloc() hardcode data-path resource types (RES_TYPE_WQ,
RES_TYPE_RQ, RES_TYPE_CQ, RES_TYPE_INTR_CTRL). The upcoming admin
channel uses different BAR resource types (RES_TYPE_ADMIN_WQ/RQ/CQ,
RES_TYPE_SRIOV_INTR) for its queues.

Add _with_type() variants that accept an explicit resource type
parameter. Refactor the original functions as thin wrappers that
pass the default data-path type. No functional change.

Signed-off-by: Satish Kharat <satishkh@cisco.com>
---
 drivers/net/ethernet/cisco/enic/vnic_cq.c   | 14 +++++++++++---
 drivers/net/ethernet/cisco/enic/vnic_cq.h   |  3 +++
 drivers/net/ethernet/cisco/enic/vnic_intr.c | 12 +++++++++---
 drivers/net/ethernet/cisco/enic/vnic_intr.h |  2 ++
 drivers/net/ethernet/cisco/enic/vnic_rq.c   | 14 +++++++++++---
 drivers/net/ethernet/cisco/enic/vnic_rq.h   |  3 +++
 drivers/net/ethernet/cisco/enic/vnic_wq.c   | 14 +++++++++++---
 drivers/net/ethernet/cisco/enic/vnic_wq.h   |  3 +++
 8 files changed, 53 insertions(+), 12 deletions(-)

diff --git a/drivers/net/ethernet/cisco/enic/vnic_cq.c b/drivers/net/ethernet/cisco/enic/vnic_cq.c
index 27c885e91552..5a0dbb816223 100644
--- a/drivers/net/ethernet/cisco/enic/vnic_cq.c
+++ b/drivers/net/ethernet/cisco/enic/vnic_cq.c
@@ -20,13 +20,14 @@ void vnic_cq_free(struct vnic_cq *cq)
 	cq->ctrl = NULL;
 }
 
-int vnic_cq_alloc(struct vnic_dev *vdev, struct vnic_cq *cq, unsigned int index,
-	unsigned int desc_count, unsigned int desc_size)
+int vnic_cq_alloc_with_type(struct vnic_dev *vdev, struct vnic_cq *cq,
+			    unsigned int index, unsigned int desc_count,
+			    unsigned int desc_size, unsigned int res_type)
 {
 	cq->index = index;
 	cq->vdev = vdev;
 
-	cq->ctrl = vnic_dev_get_res(vdev, RES_TYPE_CQ, index);
+	cq->ctrl = vnic_dev_get_res(vdev, res_type, index);
 	if (!cq->ctrl) {
 		vdev_err(vdev, "Failed to hook CQ[%d] resource\n", index);
 		return -EINVAL;
@@ -35,6 +36,13 @@ int vnic_cq_alloc(struct vnic_dev *vdev, struct vnic_cq *cq, unsigned int index,
 	return vnic_dev_alloc_desc_ring(vdev, &cq->ring, desc_count, desc_size);
 }
 
+int vnic_cq_alloc(struct vnic_dev *vdev, struct vnic_cq *cq, unsigned int index,
+		  unsigned int desc_count, unsigned int desc_size)
+{
+	return vnic_cq_alloc_with_type(vdev, cq, index, desc_count, desc_size,
+				       RES_TYPE_CQ);
+}
+
 void vnic_cq_init(struct vnic_cq *cq, unsigned int flow_control_enable,
 	unsigned int color_enable, unsigned int cq_head, unsigned int cq_tail,
 	unsigned int cq_tail_color, unsigned int interrupt_enable,
diff --git a/drivers/net/ethernet/cisco/enic/vnic_cq.h b/drivers/net/ethernet/cisco/enic/vnic_cq.h
index 0e37f5d5e527..d46d4d2ef6bb 100644
--- a/drivers/net/ethernet/cisco/enic/vnic_cq.h
+++ b/drivers/net/ethernet/cisco/enic/vnic_cq.h
@@ -73,6 +73,9 @@ static inline void vnic_cq_inc_to_clean(struct vnic_cq *cq)
 void vnic_cq_free(struct vnic_cq *cq);
 int vnic_cq_alloc(struct vnic_dev *vdev, struct vnic_cq *cq, unsigned int index,
 	unsigned int desc_count, unsigned int desc_size);
+int vnic_cq_alloc_with_type(struct vnic_dev *vdev, struct vnic_cq *cq,
+			    unsigned int index, unsigned int desc_count,
+			    unsigned int desc_size, unsigned int res_type);
 void vnic_cq_init(struct vnic_cq *cq, unsigned int flow_control_enable,
 	unsigned int color_enable, unsigned int cq_head, unsigned int cq_tail,
 	unsigned int cq_tail_color, unsigned int interrupt_enable,
diff --git a/drivers/net/ethernet/cisco/enic/vnic_intr.c b/drivers/net/ethernet/cisco/enic/vnic_intr.c
index 25319f072a04..010ad8c2108d 100644
--- a/drivers/net/ethernet/cisco/enic/vnic_intr.c
+++ b/drivers/net/ethernet/cisco/enic/vnic_intr.c
@@ -19,13 +19,13 @@ void vnic_intr_free(struct vnic_intr *intr)
 	intr->ctrl = NULL;
 }
 
-int vnic_intr_alloc(struct vnic_dev *vdev, struct vnic_intr *intr,
-	unsigned int index)
+int vnic_intr_alloc_with_type(struct vnic_dev *vdev, struct vnic_intr *intr,
+			      unsigned int index, unsigned int res_type)
 {
 	intr->index = index;
 	intr->vdev = vdev;
 
-	intr->ctrl = vnic_dev_get_res(vdev, RES_TYPE_INTR_CTRL, index);
+	intr->ctrl = vnic_dev_get_res(vdev, res_type, index);
 	if (!intr->ctrl) {
 		vdev_err(vdev, "Failed to hook INTR[%d].ctrl resource\n",
 			 index);
@@ -35,6 +35,12 @@ int vnic_intr_alloc(struct vnic_dev *vdev, struct vnic_intr *intr,
 	return 0;
 }
 
+int vnic_intr_alloc(struct vnic_dev *vdev, struct vnic_intr *intr,
+		    unsigned int index)
+{
+	return vnic_intr_alloc_with_type(vdev, intr, index, RES_TYPE_INTR_CTRL);
+}
+
 void vnic_intr_init(struct vnic_intr *intr, u32 coalescing_timer,
 	unsigned int coalescing_type, unsigned int mask_on_assertion)
 {
diff --git a/drivers/net/ethernet/cisco/enic/vnic_intr.h b/drivers/net/ethernet/cisco/enic/vnic_intr.h
index 33a72aa10b26..2bc2dbffdb80 100644
--- a/drivers/net/ethernet/cisco/enic/vnic_intr.h
+++ b/drivers/net/ethernet/cisco/enic/vnic_intr.h
@@ -89,6 +89,8 @@ static inline u32 vnic_intr_legacy_pba(u32 __iomem *legacy_pba)
 void vnic_intr_free(struct vnic_intr *intr);
 int vnic_intr_alloc(struct vnic_dev *vdev, struct vnic_intr *intr,
 	unsigned int index);
+int vnic_intr_alloc_with_type(struct vnic_dev *vdev, struct vnic_intr *intr,
+			      unsigned int index, unsigned int res_type);
 void vnic_intr_init(struct vnic_intr *intr, u32 coalescing_timer,
 	unsigned int coalescing_type, unsigned int mask_on_assertion);
 void vnic_intr_coalescing_timer_set(struct vnic_intr *intr,
diff --git a/drivers/net/ethernet/cisco/enic/vnic_rq.c b/drivers/net/ethernet/cisco/enic/vnic_rq.c
index 5ae80551f17c..a662d9fd1199 100644
--- a/drivers/net/ethernet/cisco/enic/vnic_rq.c
+++ b/drivers/net/ethernet/cisco/enic/vnic_rq.c
@@ -69,15 +69,16 @@ void vnic_rq_free(struct vnic_rq *rq)
 	rq->ctrl = NULL;
 }
 
-int vnic_rq_alloc(struct vnic_dev *vdev, struct vnic_rq *rq, unsigned int index,
-	unsigned int desc_count, unsigned int desc_size)
+int vnic_rq_alloc_with_type(struct vnic_dev *vdev, struct vnic_rq *rq,
+			    unsigned int index, unsigned int desc_count,
+			    unsigned int desc_size, unsigned int res_type)
 {
 	int err;
 
 	rq->index = index;
 	rq->vdev = vdev;
 
-	rq->ctrl = vnic_dev_get_res(vdev, RES_TYPE_RQ, index);
+	rq->ctrl = vnic_dev_get_res(vdev, res_type, index);
 	if (!rq->ctrl) {
 		vdev_err(vdev, "Failed to hook RQ[%d] resource\n", index);
 		return -EINVAL;
@@ -98,6 +99,13 @@ int vnic_rq_alloc(struct vnic_dev *vdev, struct vnic_rq *rq, unsigned int index,
 	return 0;
 }
 
+int vnic_rq_alloc(struct vnic_dev *vdev, struct vnic_rq *rq, unsigned int index,
+		  unsigned int desc_count, unsigned int desc_size)
+{
+	return vnic_rq_alloc_with_type(vdev, rq, index, desc_count, desc_size,
+				       RES_TYPE_RQ);
+}
+
 static void vnic_rq_init_start(struct vnic_rq *rq, unsigned int cq_index,
 	unsigned int fetch_index, unsigned int posted_index,
 	unsigned int error_interrupt_enable,
diff --git a/drivers/net/ethernet/cisco/enic/vnic_rq.h b/drivers/net/ethernet/cisco/enic/vnic_rq.h
index a1cdd729caec..9fc2090eac44 100644
--- a/drivers/net/ethernet/cisco/enic/vnic_rq.h
+++ b/drivers/net/ethernet/cisco/enic/vnic_rq.h
@@ -196,6 +196,9 @@ static inline int vnic_rq_fill(struct vnic_rq *rq,
 void vnic_rq_free(struct vnic_rq *rq);
 int vnic_rq_alloc(struct vnic_dev *vdev, struct vnic_rq *rq, unsigned int index,
 	unsigned int desc_count, unsigned int desc_size);
+int vnic_rq_alloc_with_type(struct vnic_dev *vdev, struct vnic_rq *rq,
+			    unsigned int index, unsigned int desc_count,
+			    unsigned int desc_size, unsigned int res_type);
 void vnic_rq_init(struct vnic_rq *rq, unsigned int cq_index,
 	unsigned int error_interrupt_enable,
 	unsigned int error_interrupt_offset);
diff --git a/drivers/net/ethernet/cisco/enic/vnic_wq.c b/drivers/net/ethernet/cisco/enic/vnic_wq.c
index 29c7900349b2..5a20bdc62141 100644
--- a/drivers/net/ethernet/cisco/enic/vnic_wq.c
+++ b/drivers/net/ethernet/cisco/enic/vnic_wq.c
@@ -72,15 +72,16 @@ void vnic_wq_free(struct vnic_wq *wq)
 	wq->ctrl = NULL;
 }
 
-int vnic_wq_alloc(struct vnic_dev *vdev, struct vnic_wq *wq, unsigned int index,
-	unsigned int desc_count, unsigned int desc_size)
+int vnic_wq_alloc_with_type(struct vnic_dev *vdev, struct vnic_wq *wq,
+			    unsigned int index, unsigned int desc_count,
+			    unsigned int desc_size, unsigned int res_type)
 {
 	int err;
 
 	wq->index = index;
 	wq->vdev = vdev;
 
-	wq->ctrl = vnic_dev_get_res(vdev, RES_TYPE_WQ, index);
+	wq->ctrl = vnic_dev_get_res(vdev, res_type, index);
 	if (!wq->ctrl) {
 		vdev_err(vdev, "Failed to hook WQ[%d] resource\n", index);
 		return -EINVAL;
@@ -101,6 +102,13 @@ int vnic_wq_alloc(struct vnic_dev *vdev, struct vnic_wq *wq, unsigned int index,
 	return 0;
 }
 
+int vnic_wq_alloc(struct vnic_dev *vdev, struct vnic_wq *wq, unsigned int index,
+		  unsigned int desc_count, unsigned int desc_size)
+{
+	return vnic_wq_alloc_with_type(vdev, wq, index, desc_count, desc_size,
+				       RES_TYPE_WQ);
+}
+
 int enic_wq_devcmd2_alloc(struct vnic_dev *vdev, struct vnic_wq *wq,
 			  unsigned int desc_count, unsigned int desc_size)
 {
diff --git a/drivers/net/ethernet/cisco/enic/vnic_wq.h b/drivers/net/ethernet/cisco/enic/vnic_wq.h
index 3bb4758100ba..1d448b7a9ba2 100644
--- a/drivers/net/ethernet/cisco/enic/vnic_wq.h
+++ b/drivers/net/ethernet/cisco/enic/vnic_wq.h
@@ -165,6 +165,9 @@ static inline void vnic_wq_service(struct vnic_wq *wq,
 void vnic_wq_free(struct vnic_wq *wq);
 int vnic_wq_alloc(struct vnic_dev *vdev, struct vnic_wq *wq, unsigned int index,
 	unsigned int desc_count, unsigned int desc_size);
+int vnic_wq_alloc_with_type(struct vnic_dev *vdev, struct vnic_wq *wq,
+			    unsigned int index, unsigned int desc_count,
+			    unsigned int desc_size, unsigned int res_type);
 void vnic_wq_init(struct vnic_wq *wq, unsigned int cq_index,
 	unsigned int error_interrupt_enable,
 	unsigned int error_interrupt_offset);

-- 
2.43.0

