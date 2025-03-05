From: Satish Kharat <satishkh@cisco.com>
Date: Tue, 04 Mar 2025 19:56:42 -0500
Subject: [PATCH net-next v2 6/8] enic : added enic_wq.c and enic_wq.h
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250304-enic_cleanup_and_ext_cq-v2-6-85804263dad8@cisco.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741136202; l=11927;
 i=satishkh@cisco.com; s=20250226; h=from:subject:message-id;
 bh=EeYgiBx6VHDfzMmmGoc4ZdtH1pe6AyWH8ejPrRUgPrw=;
 b=rS+yQK/V2WR4Mrergcsc1XrDr+12TGYg3Cj5uiaQVqFEkVMUAUnPTZVBcAcY0HM/0ZXDWCe0G
 4tI0Rm9xZ9tCbt+a14a4Xq6Ss4Ff3Uggdz9m6e1dBll+X1xbeW0uxvc
X-Developer-Key: i=satishkh@cisco.com; a=ed25519;
 pk=lkxzORFYn5ejiy0kzcsfkpGoXZDcnHMc4n3YK7jJnJo=
X-Endpoint-Received: by B4 Relay for satishkh@cisco.com/20250226 with auth_id=351
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Moves wq related function to enic_wq.c. Prepares for
a cleaup of enic wq code path.

Co-developed-by: Nelson Escobar <neescoba@cisco.com>
Signed-off-by: Nelson Escobar <neescoba@cisco.com>
Co-developed-by: John Daley <johndale@cisco.com>
Signed-off-by: John Daley <johndale@cisco.com>
Signed-off-by: Satish Kharat <satishkh@cisco.com>
---
 drivers/net/ethernet/cisco/enic/Makefile    |   2 +-
 drivers/net/ethernet/cisco/enic/cq_desc.h   |  24 ------
 drivers/net/ethernet/cisco/enic/enic.h      |   4 +
 drivers/net/ethernet/cisco/enic/enic_main.c |  52 +-----------
 drivers/net/ethernet/cisco/enic/enic_wq.c   | 118 ++++++++++++++++++++++++++++
 drivers/net/ethernet/cisco/enic/enic_wq.h   |  14 ++++
 drivers/net/ethernet/cisco/enic/vnic_cq.h   |  41 ----------
 7 files changed, 138 insertions(+), 117 deletions(-)

diff --git a/drivers/net/ethernet/cisco/enic/Makefile b/drivers/net/ethernet/cisco/enic/Makefile
index b3b5196b2dfcc3e59366474ba78fc7a4cd746eb0..a96b8332e6e2a87da6e50a2da3ef9546d61b589c 100644
--- a/drivers/net/ethernet/cisco/enic/Makefile
+++ b/drivers/net/ethernet/cisco/enic/Makefile
@@ -3,5 +3,5 @@ obj-$(CONFIG_ENIC) := enic.o
 
 enic-y := enic_main.o vnic_cq.o vnic_intr.o vnic_wq.o \
 	enic_res.o enic_dev.o enic_pp.o vnic_dev.o vnic_rq.o vnic_vic.o \
-	enic_ethtool.o enic_api.o enic_clsf.o enic_rq.o
+	enic_ethtool.o enic_api.o enic_clsf.o enic_rq.o enic_wq.o
 
diff --git a/drivers/net/ethernet/cisco/enic/cq_desc.h b/drivers/net/ethernet/cisco/enic/cq_desc.h
index 8fc313b6ed0434bd55b8e10bf3086ef848acbdf1..bfb3f14e89f5d6cfb0159bdf041b8004c774d7e8 100644
--- a/drivers/net/ethernet/cisco/enic/cq_desc.h
+++ b/drivers/net/ethernet/cisco/enic/cq_desc.h
@@ -43,28 +43,4 @@ struct cq_desc {
 #define CQ_DESC_32_FI_MASK (BIT(0) | BIT(1))
 #define CQ_DESC_64_FI_MASK (BIT(0) | BIT(1))
 
-static inline void cq_desc_dec(const struct cq_desc *desc_arg,
-	u8 *type, u8 *color, u16 *q_number, u16 *completed_index)
-{
-	const struct cq_desc *desc = desc_arg;
-	const u8 type_color = desc->type_color;
-
-	*color = (type_color >> CQ_DESC_COLOR_SHIFT) & CQ_DESC_COLOR_MASK;
-
-	/*
-	 * Make sure color bit is read from desc *before* other fields
-	 * are read from desc.  Hardware guarantees color bit is last
-	 * bit (byte) written.  Adding the rmb() prevents the compiler
-	 * and/or CPU from reordering the reads which would potentially
-	 * result in reading stale values.
-	 */
-
-	rmb();
-
-	*type = type_color & CQ_DESC_TYPE_MASK;
-	*q_number = le16_to_cpu(desc->q_number) & CQ_DESC_Q_NUM_MASK;
-	*completed_index = le16_to_cpu(desc->completed_index) &
-		CQ_DESC_COMP_NDX_MASK;
-}
-
 #endif /* _CQ_DESC_H_ */
diff --git a/drivers/net/ethernet/cisco/enic/enic.h b/drivers/net/ethernet/cisco/enic/enic.h
index d60e55accafd0e4f83728524da4f167a474d6213..9c12e967e9f1299e1cf3e280a16fb9bf93ac607b 100644
--- a/drivers/net/ethernet/cisco/enic/enic.h
+++ b/drivers/net/ethernet/cisco/enic/enic.h
@@ -83,6 +83,10 @@ struct enic_rx_coal {
 #define ENIC_SET_INSTANCE		(1 << 3)
 #define ENIC_SET_HOST			(1 << 4)
 
+#define MAX_TSO			BIT(16)
+#define WQ_ENET_MAX_DESC_LEN	BIT(WQ_ENET_LEN_BITS)
+#define ENIC_DESC_MAX_SPLITS	(MAX_TSO / WQ_ENET_MAX_DESC_LEN + 1)
+
 struct enic_port_profile {
 	u32 set;
 	u8 request;
diff --git a/drivers/net/ethernet/cisco/enic/enic_main.c b/drivers/net/ethernet/cisco/enic/enic_main.c
index d716514366dfc56b4e08260d18d78fddd23f6253..52174843f02f1fecc75666367ad5034cbbcf8f07 100644
--- a/drivers/net/ethernet/cisco/enic/enic_main.c
+++ b/drivers/net/ethernet/cisco/enic/enic_main.c
@@ -59,11 +59,9 @@
 #include "enic_pp.h"
 #include "enic_clsf.h"
 #include "enic_rq.h"
+#include "enic_wq.h"
 
 #define ENIC_NOTIFY_TIMER_PERIOD	(2 * HZ)
-#define WQ_ENET_MAX_DESC_LEN		(1 << WQ_ENET_LEN_BITS)
-#define MAX_TSO				(1 << 16)
-#define ENIC_DESC_MAX_SPLITS		(MAX_TSO / WQ_ENET_MAX_DESC_LEN + 1)
 
 #define PCI_DEVICE_ID_CISCO_VIC_ENET         0x0043  /* ethernet vnic */
 #define PCI_DEVICE_ID_CISCO_VIC_ENET_DYN     0x0044  /* enet dynamic vnic */
@@ -321,54 +319,6 @@ int enic_is_valid_vf(struct enic *enic, int vf)
 #endif
 }
 
-static void enic_free_wq_buf(struct vnic_wq *wq, struct vnic_wq_buf *buf)
-{
-	struct enic *enic = vnic_dev_priv(wq->vdev);
-
-	if (buf->sop)
-		dma_unmap_single(&enic->pdev->dev, buf->dma_addr, buf->len,
-				 DMA_TO_DEVICE);
-	else
-		dma_unmap_page(&enic->pdev->dev, buf->dma_addr, buf->len,
-			       DMA_TO_DEVICE);
-
-	if (buf->os_buf)
-		dev_kfree_skb_any(buf->os_buf);
-}
-
-static void enic_wq_free_buf(struct vnic_wq *wq,
-	struct cq_desc *cq_desc, struct vnic_wq_buf *buf, void *opaque)
-{
-	struct enic *enic = vnic_dev_priv(wq->vdev);
-
-	enic->wq[wq->index].stats.cq_work++;
-	enic->wq[wq->index].stats.cq_bytes += buf->len;
-	enic_free_wq_buf(wq, buf);
-}
-
-static int enic_wq_service(struct vnic_dev *vdev, struct cq_desc *cq_desc,
-	u8 type, u16 q_number, u16 completed_index, void *opaque)
-{
-	struct enic *enic = vnic_dev_priv(vdev);
-
-	spin_lock(&enic->wq[q_number].lock);
-
-	vnic_wq_service(&enic->wq[q_number].vwq, cq_desc,
-		completed_index, enic_wq_free_buf,
-		opaque);
-
-	if (netif_tx_queue_stopped(netdev_get_tx_queue(enic->netdev, q_number)) &&
-	    vnic_wq_desc_avail(&enic->wq[q_number].vwq) >=
-	    (MAX_SKB_FRAGS + ENIC_DESC_MAX_SPLITS)) {
-		netif_wake_subqueue(enic->netdev, q_number);
-		enic->wq[q_number].stats.wake++;
-	}
-
-	spin_unlock(&enic->wq[q_number].lock);
-
-	return 0;
-}
-
 static bool enic_log_q_error(struct enic *enic)
 {
 	unsigned int i;
diff --git a/drivers/net/ethernet/cisco/enic/enic_wq.c b/drivers/net/ethernet/cisco/enic/enic_wq.c
new file mode 100644
index 0000000000000000000000000000000000000000..59b02906a1f91f695757c649e74e3f6f117abab3
--- /dev/null
+++ b/drivers/net/ethernet/cisco/enic/enic_wq.c
@@ -0,0 +1,118 @@
+// SPDX-License-Identifier: GPL-2.0-only
+// Copyright 2025 Cisco Systems, Inc.  All rights reserved.
+
+#include <net/netdev_queues.h>
+#include "enic_res.h"
+#include "enic.h"
+#include "enic_wq.h"
+
+static void cq_desc_dec(const struct cq_desc *desc_arg, u8 *type, u8 *color,
+			u16 *q_number, u16 *completed_index)
+{
+	const struct cq_desc *desc = desc_arg;
+	const u8 type_color = desc->type_color;
+
+	*color = (type_color >> CQ_DESC_COLOR_SHIFT) & CQ_DESC_COLOR_MASK;
+
+	/*
+	 * Make sure color bit is read from desc *before* other fields
+	 * are read from desc.  Hardware guarantees color bit is last
+	 * bit (byte) written.  Adding the rmb() prevents the compiler
+	 * and/or CPU from reordering the reads which would potentially
+	 * result in reading stale values.
+	 */
+	rmb();
+
+	*type = type_color & CQ_DESC_TYPE_MASK;
+	*q_number = le16_to_cpu(desc->q_number) & CQ_DESC_Q_NUM_MASK;
+	*completed_index = le16_to_cpu(desc->completed_index) &
+		CQ_DESC_COMP_NDX_MASK;
+}
+
+unsigned int vnic_cq_service(struct vnic_cq *cq, unsigned int work_to_do,
+			     int (*q_service)(struct vnic_dev *vdev,
+					      struct cq_desc *cq_desc, u8 type,
+					      u16 q_number, u16 completed_index,
+					      void *opaque), void *opaque)
+{
+	struct cq_desc *cq_desc;
+	unsigned int work_done = 0;
+	u16 q_number, completed_index;
+	u8 type, color;
+
+	cq_desc = (struct cq_desc *)((u8 *)cq->ring.descs +
+		   cq->ring.desc_size * cq->to_clean);
+	cq_desc_dec(cq_desc, &type, &color,
+		    &q_number, &completed_index);
+
+	while (color != cq->last_color) {
+		if ((*q_service)(cq->vdev, cq_desc, type, q_number,
+				 completed_index, opaque))
+			break;
+
+		cq->to_clean++;
+		if (cq->to_clean == cq->ring.desc_count) {
+			cq->to_clean = 0;
+			cq->last_color = cq->last_color ? 0 : 1;
+		}
+
+		cq_desc = (struct cq_desc *)((u8 *)cq->ring.descs +
+			cq->ring.desc_size * cq->to_clean);
+		cq_desc_dec(cq_desc, &type, &color,
+			    &q_number, &completed_index);
+
+		work_done++;
+		if (work_done >= work_to_do)
+			break;
+	}
+
+	return work_done;
+}
+
+void enic_free_wq_buf(struct vnic_wq *wq, struct vnic_wq_buf *buf)
+{
+	struct enic *enic = vnic_dev_priv(wq->vdev);
+
+	if (buf->sop)
+		dma_unmap_single(&enic->pdev->dev, buf->dma_addr, buf->len,
+				 DMA_TO_DEVICE);
+	else
+		dma_unmap_page(&enic->pdev->dev, buf->dma_addr, buf->len,
+			       DMA_TO_DEVICE);
+
+	if (buf->os_buf)
+		dev_kfree_skb_any(buf->os_buf);
+}
+
+static void enic_wq_free_buf(struct vnic_wq *wq, struct cq_desc *cq_desc,
+			     struct vnic_wq_buf *buf, void *opaque)
+{
+	struct enic *enic = vnic_dev_priv(wq->vdev);
+
+	enic->wq[wq->index].stats.cq_work++;
+	enic->wq[wq->index].stats.cq_bytes += buf->len;
+	enic_free_wq_buf(wq, buf);
+}
+
+int enic_wq_service(struct vnic_dev *vdev, struct cq_desc *cq_desc, u8 type,
+		    u16 q_number, u16 completed_index, void *opaque)
+{
+	struct enic *enic = vnic_dev_priv(vdev);
+
+	spin_lock(&enic->wq[q_number].lock);
+
+	vnic_wq_service(&enic->wq[q_number].vwq, cq_desc,
+			completed_index, enic_wq_free_buf, opaque);
+
+	if (netif_tx_queue_stopped(netdev_get_tx_queue(enic->netdev, q_number))
+	    && vnic_wq_desc_avail(&enic->wq[q_number].vwq) >=
+	    (MAX_SKB_FRAGS + ENIC_DESC_MAX_SPLITS)) {
+		netif_wake_subqueue(enic->netdev, q_number);
+		enic->wq[q_number].stats.wake++;
+	}
+
+	spin_unlock(&enic->wq[q_number].lock);
+
+	return 0;
+}
+
diff --git a/drivers/net/ethernet/cisco/enic/enic_wq.h b/drivers/net/ethernet/cisco/enic/enic_wq.h
new file mode 100644
index 0000000000000000000000000000000000000000..cc4d6a969a9fb11d6ec3b0e8e56ac106b6d34be2
--- /dev/null
+++ b/drivers/net/ethernet/cisco/enic/enic_wq.h
@@ -0,0 +1,14 @@
+/* SPDX-License-Identifier: GPL-2.0-only
+ * Copyright 2025 Cisco Systems, Inc.  All rights reserved.
+ */
+
+unsigned int vnic_cq_service(struct vnic_cq *cq, unsigned int work_to_do,
+			     int (*q_service)(struct vnic_dev *vdev,
+					      struct cq_desc *cq_desc, u8 type,
+					      u16 q_number, u16 completed_index,
+					      void *opaque), void *opaque);
+
+void enic_free_wq_buf(struct vnic_wq *wq, struct vnic_wq_buf *buf);
+
+int enic_wq_service(struct vnic_dev *vdev, struct cq_desc *cq_desc, u8 type,
+		    u16 q_number, u16 completed_index, void *opaque);
diff --git a/drivers/net/ethernet/cisco/enic/vnic_cq.h b/drivers/net/ethernet/cisco/enic/vnic_cq.h
index 21d97c01f9424fde3d3c1d9b6cb4b7ef6de144b1..0e37f5d5e5272ed82773b9c16008087ef2dc6dd7 100644
--- a/drivers/net/ethernet/cisco/enic/vnic_cq.h
+++ b/drivers/net/ethernet/cisco/enic/vnic_cq.h
@@ -56,47 +56,6 @@ struct vnic_cq {
 	ktime_t prev_ts;
 };
 
-static inline unsigned int vnic_cq_service(struct vnic_cq *cq,
-	unsigned int work_to_do,
-	int (*q_service)(struct vnic_dev *vdev, struct cq_desc *cq_desc,
-	u8 type, u16 q_number, u16 completed_index, void *opaque),
-	void *opaque)
-{
-	struct cq_desc *cq_desc;
-	unsigned int work_done = 0;
-	u16 q_number, completed_index;
-	u8 type, color;
-
-	cq_desc = (struct cq_desc *)((u8 *)cq->ring.descs +
-		cq->ring.desc_size * cq->to_clean);
-	cq_desc_dec(cq_desc, &type, &color,
-		&q_number, &completed_index);
-
-	while (color != cq->last_color) {
-
-		if ((*q_service)(cq->vdev, cq_desc, type,
-			q_number, completed_index, opaque))
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
-			&q_number, &completed_index);
-
-		work_done++;
-		if (work_done >= work_to_do)
-			break;
-	}
-
-	return work_done;
-}
-
 static inline void *vnic_cq_to_clean(struct vnic_cq *cq)
 {
 	return ((u8 *)cq->ring.descs + cq->ring.desc_size * cq->to_clean);

-- 
2.48.1

