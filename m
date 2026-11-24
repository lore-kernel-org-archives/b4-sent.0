From: Sai Sree Kartheek Adivi <s-adivi@ti.com>
Date: Tue, 24 Nov 2026 17:15:08 +0530
Subject: [PATCH v13 06/20] dmaengine: ti: k3-udma: move ring management
 functions to k3-udma-common.c
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-dma-upstream-v13-v13-6-bd4251fdc6d4@ti.com>
References: <20261124-dma-upstream-v13-v13-0-bd4251fdc6d4@ti.com>
In-Reply-To: <20261124-dma-upstream-v13-v13-0-bd4251fdc6d4@ti.com>
To: Vignesh Raghavendra <vigneshr@ti.com>, Vinod Koul <vkoul@kernel.org>, 
 Frank Li <Frank.Li@kernel.org>, Peter Ujfalusi <peter.ujfalusi@ti.com>, 
 Nishanth Menon <nm@ti.com>, Santosh Shilimkar <ssantosh@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 sebin.francis@ti.com, Sai Sree Kartheek Adivi <s-adivi@ti.com>, 
 Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795520723; l=9607;
 i=s-adivi@ti.com; s=20261124; h=from:subject:message-id;
 bh=GYtjFL2d97JRSvvo0vrQ/LsTe2zrkrtKVBX2YTefwYE=;
 b=t/q52ezPWt7ZxQ+I8wSfN4Z3C5dGF5dv2Z4+V9r3UZQH4OiJZBWJsKH5dVC+xa04gftNE+/Pd
 i14PHFywA9mCSJ0tUqbW4YFQhSF9AA/r5LVfYTi96iUA6qRUH1S8wch
X-Developer-Key: i=s-adivi@ti.com; a=ed25519;
 pk=EtOwVxmXDuYMgw3DqFtPDBpf8ZvbO89w1fJm4w5yPI8=
X-Endpoint-Received: by B4 Relay for s-adivi@ti.com/20261124 with auth_id=1627
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Relocate the ring management functions such as push, pop, and reset
from k3-udma.c to k3-udma-common.c file. These operations are
common across multiple K3 UDMA variants and will be reused by
future implementations like K3 UDMA v2.

No functional changes intended.

Reviewed-by: Frank Li <Frank.Li@nxp.com>
Signed-off-by: Sai Sree Kartheek Adivi <s-adivi@ti.com>
---
 drivers/dma/ti/k3-udma-common.c | 119 ++++++++++++++++++++++++++++++++++++++--
 drivers/dma/ti/k3-udma.c        | 100 ---------------------------------
 drivers/dma/ti/k3-udma.h        |  11 ++--
 3 files changed, 118 insertions(+), 112 deletions(-)

diff --git a/drivers/dma/ti/k3-udma-common.c b/drivers/dma/ti/k3-udma-common.c
index f9060bcab8a5a..c9cbe93f2391d 100644
--- a/drivers/dma/ti/k3-udma-common.c
+++ b/drivers/dma/ti/k3-udma-common.c
@@ -13,6 +13,13 @@
 
 #include "k3-udma.h"
 
+static int udma_attach_metadata(struct dma_async_tx_descriptor *desc,
+				 void *data, size_t len);
+static void *udma_get_metadata_ptr(struct dma_async_tx_descriptor *desc,
+				    size_t *payload_len, size_t *max_len);
+static int udma_set_metadata_len(struct dma_async_tx_descriptor *desc,
+				  size_t payload_len);
+
 static const struct dma_descriptor_metadata_ops metadata_ops = {
 	.attach = udma_attach_metadata,
 	.get_ptr = udma_get_metadata_ptr,
@@ -121,7 +128,7 @@ void udma_desc_free(struct virt_dma_desc *vd)
 }
 EXPORT_SYMBOL_GPL(udma_desc_free);
 
-bool udma_desc_is_rx_flush(struct udma_chan *uc, dma_addr_t addr)
+static bool udma_desc_is_rx_flush(struct udma_chan *uc, dma_addr_t addr)
 {
 	if (uc->config.dir != DMA_DEV_TO_MEM)
 		return false;
@@ -131,7 +138,6 @@ bool udma_desc_is_rx_flush(struct udma_chan *uc, dma_addr_t addr)
 
 	return false;
 }
-EXPORT_SYMBOL_GPL(udma_desc_is_rx_flush);
 
 bool udma_is_desc_really_done(struct udma_chan *uc, struct udma_desc *d)
 {
@@ -723,7 +729,7 @@ udma_prep_slave_sg_pkt(struct udma_chan *uc, struct scatterlist *sgl,
 	return d;
 }
 
-int udma_attach_metadata(struct dma_async_tx_descriptor *desc,
+static int udma_attach_metadata(struct dma_async_tx_descriptor *desc,
 			 void *data, size_t len)
 {
 	struct udma_desc *d = to_udma_desc(desc);
@@ -759,7 +765,7 @@ int udma_attach_metadata(struct dma_async_tx_descriptor *desc,
 	return 0;
 }
 
-void *udma_get_metadata_ptr(struct dma_async_tx_descriptor *desc,
+static void *udma_get_metadata_ptr(struct dma_async_tx_descriptor *desc,
 			    size_t *payload_len, size_t *max_len)
 {
 	struct udma_desc *d = to_udma_desc(desc);
@@ -780,7 +786,7 @@ void *udma_get_metadata_ptr(struct dma_async_tx_descriptor *desc,
 	return h_desc->epib;
 }
 
-int udma_set_metadata_len(struct dma_async_tx_descriptor *desc,
+static int udma_set_metadata_len(struct dma_async_tx_descriptor *desc,
 			  size_t payload_len)
 {
 	struct udma_desc *d = to_udma_desc(desc);
@@ -1240,5 +1246,108 @@ void udma_desc_pre_callback(struct virt_dma_chan *vc,
 }
 EXPORT_SYMBOL_GPL(udma_desc_pre_callback);
 
+int udma_push_to_ring(struct udma_chan *uc, int idx)
+{
+	struct udma_desc *d = uc->desc;
+	struct k3_ring *ring = NULL;
+	dma_addr_t paddr;
+
+	switch (uc->config.dir) {
+	case DMA_DEV_TO_MEM:
+		ring = uc->rflow->fd_ring;
+		break;
+	case DMA_MEM_TO_DEV:
+	case DMA_MEM_TO_MEM:
+		ring = uc->tchan->t_ring;
+		break;
+	default:
+		return -EINVAL;
+	}
+
+	/* RX flush packet: idx == -1 is only passed in case of DEV_TO_MEM */
+	if (idx == -1) {
+		paddr = udma_get_rx_flush_hwdesc_paddr(uc);
+	} else {
+		paddr = udma_curr_cppi5_desc_paddr(d, idx);
+
+		wmb(); /* Ensure that writes are not moved over this point */
+	}
+
+	return k3_ringacc_ring_push(ring, &paddr);
+}
+EXPORT_SYMBOL_GPL(udma_push_to_ring);
+
+int udma_pop_from_ring(struct udma_chan *uc, dma_addr_t *addr)
+{
+	struct k3_ring *ring = NULL;
+	int ret;
+
+	switch (uc->config.dir) {
+	case DMA_DEV_TO_MEM:
+		ring = uc->rflow->r_ring;
+		break;
+	case DMA_MEM_TO_DEV:
+	case DMA_MEM_TO_MEM:
+		ring = uc->tchan->tc_ring;
+		break;
+	default:
+		return -ENOENT;
+	}
+
+	ret = k3_ringacc_ring_pop(ring, addr);
+	if (ret)
+		return ret;
+
+	rmb(); /* Ensure that reads are not moved before this point */
+
+	/* Teardown completion */
+	if (cppi5_desc_is_tdcm(*addr))
+		return 0;
+
+	/* Check for flush descriptor */
+	if (udma_desc_is_rx_flush(uc, *addr))
+		return -ENOENT;
+
+	return 0;
+}
+EXPORT_SYMBOL_GPL(udma_pop_from_ring);
+
+void udma_reset_rings(struct udma_chan *uc)
+{
+	struct k3_ring *ring1 = NULL;
+	struct k3_ring *ring2 = NULL;
+
+	switch (uc->config.dir) {
+	case DMA_DEV_TO_MEM:
+		if (uc->rchan) {
+			ring1 = uc->rflow->fd_ring;
+			ring2 = uc->rflow->r_ring;
+		}
+		break;
+	case DMA_MEM_TO_DEV:
+	case DMA_MEM_TO_MEM:
+		if (uc->tchan) {
+			ring1 = uc->tchan->t_ring;
+			ring2 = uc->tchan->tc_ring;
+		}
+		break;
+	default:
+		break;
+	}
+
+	if (ring1)
+		k3_ringacc_ring_reset_dma(ring1,
+					  k3_ringacc_ring_get_occ(ring1));
+	if (ring2)
+		k3_ringacc_ring_reset(ring2);
+
+	/* make sure we are not leaking memory by stalled descriptor */
+	if (uc->terminated_desc) {
+		udma_desc_free(&uc->terminated_desc->vd);
+		uc->terminated_desc = NULL;
+	}
+}
+EXPORT_SYMBOL_GPL(udma_reset_rings);
+
 MODULE_DESCRIPTION("Texas Instruments K3 UDMA Common Library");
 MODULE_LICENSE("GPL v2");
diff --git a/drivers/dma/ti/k3-udma.c b/drivers/dma/ti/k3-udma.c
index 50c5bca7d9788..2fba734616272 100644
--- a/drivers/dma/ti/k3-udma.c
+++ b/drivers/dma/ti/k3-udma.c
@@ -174,106 +174,6 @@ static bool udma_is_chan_paused(struct udma_chan *uc)
 	return false;
 }
 
-static int udma_push_to_ring(struct udma_chan *uc, int idx)
-{
-	struct udma_desc *d = uc->desc;
-	struct k3_ring *ring = NULL;
-	dma_addr_t paddr;
-
-	switch (uc->config.dir) {
-	case DMA_DEV_TO_MEM:
-		ring = uc->rflow->fd_ring;
-		break;
-	case DMA_MEM_TO_DEV:
-	case DMA_MEM_TO_MEM:
-		ring = uc->tchan->t_ring;
-		break;
-	default:
-		return -EINVAL;
-	}
-
-	/* RX flush packet: idx == -1 is only passed in case of DEV_TO_MEM */
-	if (idx == -1) {
-		paddr = udma_get_rx_flush_hwdesc_paddr(uc);
-	} else {
-		paddr = udma_curr_cppi5_desc_paddr(d, idx);
-
-		wmb(); /* Ensure that writes are not moved over this point */
-	}
-
-	return k3_ringacc_ring_push(ring, &paddr);
-}
-
-static int udma_pop_from_ring(struct udma_chan *uc, dma_addr_t *addr)
-{
-	struct k3_ring *ring = NULL;
-	int ret;
-
-	switch (uc->config.dir) {
-	case DMA_DEV_TO_MEM:
-		ring = uc->rflow->r_ring;
-		break;
-	case DMA_MEM_TO_DEV:
-	case DMA_MEM_TO_MEM:
-		ring = uc->tchan->tc_ring;
-		break;
-	default:
-		return -ENOENT;
-	}
-
-	ret = k3_ringacc_ring_pop(ring, addr);
-	if (ret)
-		return ret;
-
-	rmb(); /* Ensure that reads are not moved before this point */
-
-	/* Teardown completion */
-	if (cppi5_desc_is_tdcm(*addr))
-		return 0;
-
-	/* Check for flush descriptor */
-	if (udma_desc_is_rx_flush(uc, *addr))
-		return -ENOENT;
-
-	return 0;
-}
-
-static void udma_reset_rings(struct udma_chan *uc)
-{
-	struct k3_ring *ring1 = NULL;
-	struct k3_ring *ring2 = NULL;
-
-	switch (uc->config.dir) {
-	case DMA_DEV_TO_MEM:
-		if (uc->rchan) {
-			ring1 = uc->rflow->fd_ring;
-			ring2 = uc->rflow->r_ring;
-		}
-		break;
-	case DMA_MEM_TO_DEV:
-	case DMA_MEM_TO_MEM:
-		if (uc->tchan) {
-			ring1 = uc->tchan->t_ring;
-			ring2 = uc->tchan->tc_ring;
-		}
-		break;
-	default:
-		break;
-	}
-
-	if (ring1)
-		k3_ringacc_ring_reset_dma(ring1,
-					  k3_ringacc_ring_get_occ(ring1));
-	if (ring2)
-		k3_ringacc_ring_reset(ring2);
-
-	/* make sure we are not leaking memory by stalled descriptor */
-	if (uc->terminated_desc) {
-		udma_desc_free(&uc->terminated_desc->vd);
-		uc->terminated_desc = NULL;
-	}
-}
-
 static void udma_decrement_byte_counters(struct udma_chan *uc, u32 val)
 {
 	if (uc->desc->dir == DMA_DEV_TO_MEM) {
diff --git a/drivers/dma/ti/k3-udma.h b/drivers/dma/ti/k3-udma.h
index 38a54226836a5..1777f0e1f085e 100644
--- a/drivers/dma/ti/k3-udma.h
+++ b/drivers/dma/ti/k3-udma.h
@@ -566,14 +566,7 @@ struct udma_desc *udma_udma_desc_from_paddr(struct udma_chan *uc,
 					    dma_addr_t paddr);
 void udma_purge_desc_work(struct work_struct *work);
 void udma_desc_free(struct virt_dma_desc *vd);
-bool udma_desc_is_rx_flush(struct udma_chan *uc, dma_addr_t addr);
 bool udma_is_desc_really_done(struct udma_chan *uc, struct udma_desc *d);
-int udma_attach_metadata(struct dma_async_tx_descriptor *desc,
-			 void *data, size_t len);
-void *udma_get_metadata_ptr(struct dma_async_tx_descriptor *desc,
-			    size_t *payload_len, size_t *max_len);
-int udma_set_metadata_len(struct dma_async_tx_descriptor *desc,
-			  size_t payload_len);
 struct dma_async_tx_descriptor *udma_prep_slave_sg(struct dma_chan *chan,
 						   struct scatterlist *sgl, unsigned int sglen,
 						   enum dma_transfer_direction dir,
@@ -589,6 +582,10 @@ void udma_desc_pre_callback(struct virt_dma_chan *vc,
 			    struct virt_dma_desc *vd,
 			    struct dmaengine_result *result);
 
+int udma_push_to_ring(struct udma_chan *uc, int idx);
+int udma_pop_from_ring(struct udma_chan *uc, dma_addr_t *addr);
+void udma_reset_rings(struct udma_chan *uc);
+
 /* Direct access to UDMA low lever resources for the glue layer */
 int xudma_navss_psil_pair(struct udma_dev *ud, u32 src_thread, u32 dst_thread);
 int xudma_navss_psil_unpair(struct udma_dev *ud, u32 src_thread,

-- 
2.55.0

