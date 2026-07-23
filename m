From: Jack Wu <jackbb_wu@compal.com>
Date: Thu, 23 Jul 2026 16:34:28 +0800
Subject: [PATCH v5 3/7] net: wwan: t9xx: Add control DMA interface
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260723-t9xx_driver_v1-v5-3-b27afb99ccbb@compal.com>
References: <20260723-t9xx_driver_v1-v5-0-b27afb99ccbb@compal.com>
In-Reply-To: <20260723-t9xx_driver_v1-v5-0-b27afb99ccbb@compal.com>
To: Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Sergey Ryazanov <ryazanov.s.a@gmail.com>, 
 Johannes Berg <johannes@sipsolutions.net>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Jack Wu <jackbb_wu@compal.com>, Wen-Zhi Huang <wen-zhi.huang@mediatek.com>, 
 Shi-Wei Yeh <shi-wei.yeh@mediatek.com>, 
 Minano Tseng <Minano.tseng@mediatek.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Simon Horman <horms@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, Robert Yu <robert_yu@compal.com>, 
 Jeff Chang <Jeff_Chang@compal.com>
Cc: linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 linux-doc@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784795676; l=93781;
 i=jackbb_wu@compal.com; s=20260526; h=from:subject:message-id;
 bh=xIfndD9lEpIvczmEyLcqHE0YP+jGweHMssBX4tSyxjg=;
 b=EjNzh5pS0COEcKllakdH0A0zElNpStvbNmsTD//3b9wBjzT7abwps3gFFskOLtlvO8BtQAOtA
 +6SSUCMRwfKC6NZpFt3KFEJmsqyqSShXzPzV9VMgyMoaMNeQDWWHqI0
X-Developer-Key: i=jackbb_wu@compal.com; a=ed25519;
 pk=VH1prTWixNl8OEUPPSfII3p46MzJpQN8J3+ecE1tZXg=
X-Endpoint-Received: by B4 Relay for jackbb_wu@compal.com/20260526 with auth_id=793
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Cross Layer Direct Memory Access(CLDMA) is the hardware
interface used by the control plane and designated to
translate data between the host and the device. It supports
8 hardware queues for the device AP and modem respectively.

CLDMA driver uses General Purpose Descriptor (GPD) to
describe transaction information that can be recognized by
CLDMA hardware. Once CLDMA hardware transaction is started,
it would fetch and parse GPD to transfer data correctly.
To facilitate the CLDMA transaction, a GPD ring for each
queue is used. Once the transaction is started, CLDMA
hardware will traverse the GPD ring to transfer data between
the host and the device until no GPD is available.

CLDMA TX flow:
Once a TX service receives the TX data from the port layer,
it uses APIs exported by the CLDMA driver to configure GPD
with the DMA address of TX data. After that, the service
triggers CLDMA to fetch the first available GPD to transfer
data.

CLDMA RX flow:
When there is RX data from the MD, CLDMA hardware asserts an
interrupt to notify the host to fetch data and dispatch it
to FSM (for handshake messages) or the port layer.
After CLDMA opening is finished, All RX GPDs are fulfilled
and ready to receive data from the device.

Signed-off-by: Jack Wu <jackbb_wu@compal.com>
---
 drivers/net/wwan/t9xx/mtk_ctrl_plane.c          |    4 +-
 drivers/net/wwan/t9xx/mtk_ctrl_plane.h          |   52 +-
 drivers/net/wwan/t9xx/pcie/Makefile             |    7 +-
 drivers/net/wwan/t9xx/pcie/mtk_cldma.c          | 1221 +++++++++++++++++++++++
 drivers/net/wwan/t9xx/pcie/mtk_cldma.h          |  170 ++++
 drivers/net/wwan/t9xx/pcie/mtk_cldma_drv.c      |  369 +++++++
 drivers/net/wwan/t9xx/pcie/mtk_cldma_drv.h      |  177 ++++
 drivers/net/wwan/t9xx/pcie/mtk_cldma_drv_m9xx.c |  183 ++++
 drivers/net/wwan/t9xx/pcie/mtk_cldma_drv_m9xx.h |  103 ++
 drivers/net/wwan/t9xx/pcie/mtk_ctrl_cfg_m9xx.c  |   24 +
 drivers/net/wwan/t9xx/pcie/mtk_pci.c            |   39 +
 drivers/net/wwan/t9xx/pcie/mtk_pci_reg.h        |    1 +
 drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c     |  541 ++++++++++
 drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.h     |   86 ++
 14 files changed, 2973 insertions(+), 4 deletions(-)

diff --git a/drivers/net/wwan/t9xx/mtk_ctrl_plane.c b/drivers/net/wwan/t9xx/mtk_ctrl_plane.c
index cf6079218e1c..4be699d1ec00 100644
--- a/drivers/net/wwan/t9xx/mtk_ctrl_plane.c
+++ b/drivers/net/wwan/t9xx/mtk_ctrl_plane.c
@@ -11,13 +11,14 @@
 /**
  * mtk_ctrl_init() - Initialize the control plane block.
  * @mdev: Pointer to the MTK modem device.
+ * @ops: HIF operations for the control plane.
  *
  * Allocates and initializes the control plane block
  * associated with @mdev.
  *
  * Return: 0 on success, -ENOMEM on allocation failure.
  */
-int mtk_ctrl_init(struct mtk_md_dev *mdev)
+int mtk_ctrl_init(struct mtk_md_dev *mdev, struct mtk_ctrl_hif_ops *ops)
 {
 	struct mtk_ctrl_blk *ctrl_blk;
 
@@ -27,6 +28,7 @@ int mtk_ctrl_init(struct mtk_md_dev *mdev)
 
 	ctrl_blk->mdev = mdev;
 	mdev->ctrl_blk = ctrl_blk;
+	ctrl_blk->ops = ops;
 
 	return 0;
 }
diff --git a/drivers/net/wwan/t9xx/mtk_ctrl_plane.h b/drivers/net/wwan/t9xx/mtk_ctrl_plane.h
index c141876ef95d..88d71ac92084 100644
--- a/drivers/net/wwan/t9xx/mtk_ctrl_plane.h
+++ b/drivers/net/wwan/t9xx/mtk_ctrl_plane.h
@@ -11,12 +11,60 @@
 
 #include "mtk_dev.h"
 
+enum mtk_trb_cmd_type {
+	TRB_CMD_MIN,
+	TRB_CMD_ENABLE,
+	TRB_CMD_TX,
+	TRB_CMD_DISABLE,
+	TRB_CMD_STOP,
+	TRB_CMD_RECOVER,
+	TRB_CMD_MAX,
+};
+
+enum mtk_hif_dev_ctrl_cmd {
+	HIF_CTRL_CMD_CHECK_TX_FULL,
+};
+
+struct trb_open_priv {
+	u8 log_rg_offset;
+	u32 tx_mtu;
+	u32 rx_mtu;
+	u32 tx_frag_size;
+	u32 rx_frag_size;
+	int (*rx_done)(struct sk_buff *skb, void *priv, bool force_recv);
+};
+
+struct trb {
+	u32 channel_id;
+	enum mtk_trb_cmd_type cmd;
+	int status;
+	struct kref kref;
+	void *priv;
+	int (*trb_complete)(struct sk_buff *skb);
+};
+
+union ctrl_hif_cmd_data {
+	u32 rx_ch;
+};
+
+struct mtk_ctrl_hif_ops {
+	int (*init)(struct mtk_md_dev *mdev);
+	int (*exit)(struct mtk_md_dev *mdev);
+	int (*submit_skb)(struct mtk_md_dev *mdev, struct sk_buff *skb, bool force_send);
+	int (*send_cmd)(struct mtk_md_dev *mdev, int cmd, void *data);
+};
+
+struct mtk_ctrl_cfg;
+struct mtk_ctrl_trans;
+
 struct mtk_ctrl_blk {
 	struct mtk_md_dev *mdev;
-	struct mtk_ctrl_trans *trans;
+	struct mtk_ctrl_hif_ops *ops;
+	void *ctrl_hw_priv;
+	struct mtk_ctrl_cfg *cfg;
 };
 
-int mtk_ctrl_init(struct mtk_md_dev *mdev);
+int mtk_ctrl_init(struct mtk_md_dev *mdev, struct mtk_ctrl_hif_ops *ops);
 void mtk_ctrl_exit(struct mtk_md_dev *mdev);
 
 #endif /* __MTK_CTRL_PLANE_H__ */
diff --git a/drivers/net/wwan/t9xx/pcie/Makefile b/drivers/net/wwan/t9xx/pcie/Makefile
index 7410d1796d27..5252f158b058 100644
--- a/drivers/net/wwan/t9xx/pcie/Makefile
+++ b/drivers/net/wwan/t9xx/pcie/Makefile
@@ -7,4 +7,9 @@ obj-$(CONFIG_MTK_T9XX_PCI) += mtk_t9xx_pcie.o
 
 mtk_t9xx_pcie-y := \
 	mtk_pci_drv_m9xx.o \
-	mtk_pci.o
+	mtk_cldma_drv_m9xx.o \
+	mtk_ctrl_cfg_m9xx.o \
+	mtk_pci.o \
+	mtk_trans_ctrl.o \
+	mtk_cldma.o \
+	mtk_cldma_drv.o
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_cldma.c b/drivers/net/wwan/t9xx/pcie/mtk_cldma.c
new file mode 100644
index 000000000000..1d3643129b7d
--- /dev/null
+++ b/drivers/net/wwan/t9xx/pcie/mtk_cldma.c
@@ -0,0 +1,1221 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (c) 2022, MediaTek Inc.
+ */
+
+#include <linux/delay.h>
+#include <linux/device.h>
+#include <linux/dma-mapping.h>
+#include <linux/dmapool.h>
+#include <linux/err.h>
+#include <linux/interrupt.h>
+#include <linux/kdev_t.h>
+#include <linux/kernel.h>
+#include <linux/kthread.h>
+#include <linux/list.h>
+#include <linux/module.h>
+#include <linux/mutex.h>
+#include <linux/netdevice.h>
+#include <linux/sched.h>
+#include <linux/skbuff.h>
+#include <linux/slab.h>
+#include <linux/timer.h>
+#include <linux/wait.h>
+#include <linux/workqueue.h>
+#include "mtk_pci.h"
+#include "mtk_cldma.h"
+#include "mtk_cldma_drv.h"
+#include "mtk_dev.h"
+
+#define cldma_drv_ops_null	NULL
+#define DMA_POOL_NAME_LEN	(64)
+#define WAIT_HWO_ROUND		(10)
+#define WAIT_HWO_TIME		(5)
+#define CLDMA_RETRY_DELAY_MS	(100)
+#define NO_BUDGET		(0)
+
+static const int mtk_cldma_hw_id_tbl[NR_CLDMA] = {
+	[CLDMA0] = CLDMA0_HW_ID,
+	[CLDMA1] = CLDMA1_HW_ID,
+	[CLDMA4] = CLDMA4_HW_ID,
+};
+
+static void mtk_cldma_clr_bd_dsc(struct cldma_drv_info *drv_info,
+				 struct bd_dsc *bd_dsc_pool, int nr_bds)
+{
+	struct bd_dsc *bd_dsc;
+	int i;
+
+	for (i = 0; i < nr_bds; i++) {
+		bd_dsc = bd_dsc_pool + i;
+		dma_unmap_single(drv_info->mdev->dev, bd_dsc->data_dma_addr,
+				 bd_dsc->data_len, DMA_TO_DEVICE);
+		bd_dsc->data_dma_addr = 0;
+		bd_dsc->data_len = 0;
+		if (bd_dsc->bd->tx_bd.bd_flags & CLDMA_BD_FLAG_EOL) {
+			bd_dsc->bd->tx_bd.bd_flags &= ~CLDMA_BD_FLAG_EOL;
+			break;
+		}
+	}
+}
+
+static void mtk_cldma_tx_done_work(struct work_struct *work)
+{
+	struct txq *txq = container_of(work, struct txq, tx_done_work);
+	struct cldma_drv_info *drv_info;
+	struct cldma_drv_ops *drv_ops;
+	struct mtk_ctrl_trans *trans;
+	struct mtk_md_dev *mdev;
+	struct tx_req *req;
+	unsigned int state;
+	struct trb *trb;
+	int i, hif_id;
+	u32 txqno;
+
+	drv_info = txq->drv_info;
+	hif_id = drv_info->hif_id;
+	txqno = txq->txqno;
+	mdev = drv_info->mdev;
+	drv_ops = drv_info->drv_ops;
+	trans = drv_info->cd->trans;
+
+again:
+	for (i = 0; i < txq->nr_gpds; i++) {
+		if (READ_ONCE(txq->free_idx) == READ_ONCE(txq->wr_idx))
+			break;
+
+		req = txq->req_pool + txq->free_idx;
+
+		if (!req->data_vm_addr || (req->gpd->tx_gpd.gpd_flags & CLDMA_GPD_FLAG_HWO))
+			break;
+
+		dma_rmb(); /* read descriptor fields after HWO check */
+
+		if (txq->nr_bds)
+			mtk_cldma_clr_bd_dsc(drv_info, req->bd_dsc_pool, txq->nr_bds);
+		else
+			dma_unmap_single(mdev->dev, req->data_dma_addr,
+					 req->data_len, DMA_TO_DEVICE);
+
+		trb = (struct trb *)req->skb->cb;
+		trb->status = 0;
+		trb->trb_complete(req->skb);
+
+		req->data_vm_addr = NULL;
+		req->data_dma_addr = 0;
+		req->data_len = 0;
+		req->skb = NULL;
+
+		txq->free_idx = (txq->free_idx + 1) % txq->nr_gpds;
+		if (atomic_fetch_inc(&txq->req_budget) == NO_BUDGET)
+			wake_up(&trans->trb_srv[trans->srv_cfg[hif_id][txqno]]->trb_waitq);
+	}
+
+	state = drv_ops->cldma_check_intr_status(drv_info, DIR_TX, txqno, QUEUE_XFER_DONE);
+	if (state) {
+		if (unlikely(state == LINK_ERROR_VAL))
+			goto out;
+
+		drv_ops->cldma_clr_intr_status(drv_info, DIR_TX, txqno, QUEUE_XFER_DONE);
+
+		cond_resched();
+
+		goto again;
+	}
+
+out:
+	drv_ops->cldma_unmask_intr(drv_info, DIR_TX, txqno, QUEUE_XFER_DONE);
+}
+
+static void mtk_cldma_rx_skb_adjust(struct mtk_md_dev *mdev, struct rxq *rxq,
+				    struct rx_req *req)
+{
+	struct bd_dsc *bd_dsc;
+	int i;
+
+	for (i = 0; i < rxq->nr_bds; i++) {
+		bd_dsc = req->bd_dsc_pool + i;
+		if (bd_dsc->data_dma_addr) {
+			dma_unmap_single(mdev->dev, bd_dsc->data_dma_addr,
+					 req->frag_size, DMA_FROM_DEVICE);
+			bd_dsc->data_dma_addr = 0;
+		}
+		bd_dsc->skb->len = 0;
+		skb_reset_tail_pointer(bd_dsc->skb);
+		skb_put(bd_dsc->skb,
+			min_t(u16, le16_to_cpu(bd_dsc->bd->rx_bd.data_recv_len),
+			      req->frag_size));
+		if (req->skb != bd_dsc->skb) {
+			req->skb->len += bd_dsc->skb->len;
+			req->skb->data_len += bd_dsc->skb->len;
+		}
+		bd_dsc->bd->rx_bd.data_recv_len = 0;
+		bd_dsc->skb = NULL;
+	}
+	if (!rxq->nr_bds) {
+		if (req->data_dma_addr) {
+			dma_unmap_single(mdev->dev, req->data_dma_addr,
+					 req->mtu, DMA_FROM_DEVICE);
+			req->data_dma_addr = 0;
+		}
+		req->skb->len = 0;
+		skb_reset_tail_pointer(req->skb);
+		skb_put(req->skb,
+			min_t(u16, le16_to_cpu(req->gpd->rx_gpd.data_recv_len),
+			      req->mtu));
+	}
+
+	req->gpd->rx_gpd.data_recv_len = 0;
+}
+
+static int mtk_cldma_reload_rx_skb(struct mtk_md_dev *mdev, struct rxq *rxq,
+				   struct rx_req *req)
+{
+	struct sk_buff *tail = NULL;
+	struct bd_dsc *bd_dsc;
+	int nr_bds;
+	int i, ret;
+
+	nr_bds = rxq->nr_bds;
+
+	for (i = 0; i < nr_bds; i++) {
+		bd_dsc = req->bd_dsc_pool + i;
+		bd_dsc->skb = __dev_alloc_skb(req->frag_size, GFP_KERNEL);
+		if (!bd_dsc->skb) {
+			dev_warn_ratelimited(mdev->dev, "Failed to alloc SKB\n");
+			ret = -ENOMEM;
+			goto err_free_skb;
+		}
+		bd_dsc->skb->next = NULL;
+		bd_dsc->data_dma_addr = dma_map_single(mdev->dev, bd_dsc->skb->data,
+						       req->frag_size, DMA_FROM_DEVICE);
+		ret = dma_mapping_error(mdev->dev, bd_dsc->data_dma_addr);
+		if (unlikely(ret)) {
+			dev_warn_ratelimited(mdev->dev, "Failed to map SKB data\n");
+			ret = -EFAULT;
+			goto err_free_skb;
+		}
+		bd_dsc->bd->rx_bd.data_buff_ptr_h =
+			cpu_to_le32((u64)(bd_dsc->data_dma_addr) >> 32);
+		bd_dsc->bd->rx_bd.data_buff_ptr_l =
+			cpu_to_le32(bd_dsc->data_dma_addr);
+		if (tail) {
+			tail->next = bd_dsc->skb;
+			tail = bd_dsc->skb;
+			continue;
+		}
+		if (!req->skb) {
+			req->skb = bd_dsc->skb;
+		} else {
+			skb_shinfo(req->skb)->frag_list = bd_dsc->skb;
+			tail = bd_dsc->skb;
+		}
+	}
+	if (!nr_bds) {
+		req->skb = __dev_alloc_skb(req->mtu, GFP_KERNEL);
+		if (!req->skb) {
+			ret = -ENOMEM;
+			goto err_free_skb;
+		}
+
+		req->data_dma_addr = dma_map_single(mdev->dev, req->skb->data,
+						    req->mtu, DMA_FROM_DEVICE);
+		ret = dma_mapping_error(mdev->dev, req->data_dma_addr);
+		if (unlikely(ret)) {
+			dev_warn_ratelimited(mdev->dev, "Failed to map SKB data\n");
+			ret = -EFAULT;
+			goto err_free_skb;
+		}
+		req->gpd->rx_gpd.data_buff_ptr_h = cpu_to_le32((u64)req->data_dma_addr >> 32);
+		req->gpd->rx_gpd.data_buff_ptr_l = cpu_to_le32(req->data_dma_addr);
+	}
+	return 0;
+
+err_free_skb:
+	if (nr_bds) {
+		if (req->skb)
+			skb_shinfo(req->skb)->frag_list = NULL;
+		for (i = 0; i < nr_bds; i++) {
+			bd_dsc = req->bd_dsc_pool + i;
+			if (!bd_dsc->skb)
+				break;
+			if (!dma_mapping_error(mdev->dev, bd_dsc->data_dma_addr))
+				dma_unmap_single(mdev->dev, bd_dsc->data_dma_addr,
+						 req->frag_size, DMA_FROM_DEVICE);
+			bd_dsc->data_dma_addr = 0;
+			bd_dsc->skb->next = NULL;
+			dev_kfree_skb_any(bd_dsc->skb);
+			bd_dsc->skb = NULL;
+		}
+	} else {
+		req->data_dma_addr = 0;
+		if (req->skb)
+			dev_kfree_skb_any(req->skb);
+	}
+	req->skb = NULL;
+
+	return ret;
+}
+
+static int mtk_cldma_check_rx_req(struct cldma_drv_info *drv_info, struct rxq *rxq)
+{
+	struct rx_req *req = rxq->req_pool + rxq->free_idx;
+	u64 curr_addr;
+	int i;
+
+	curr_addr = drv_info->drv_ops->cldma_get_rx_curr_addr(drv_info, rxq->rxqno);
+	if (unlikely(!curr_addr))
+		return -ENXIO;
+
+	if (req->gpd_dma_addr == curr_addr)
+		return -EAGAIN;
+	for (i = 0; i < WAIT_HWO_ROUND; i++) {
+		udelay(WAIT_HWO_TIME);
+		if (!(READ_ONCE(req->gpd->rx_gpd.gpd_flags) & CLDMA_GPD_FLAG_HWO))
+			break;
+	}
+	if (i == WAIT_HWO_ROUND) {
+		dev_err((drv_info->mdev)->dev, "Failed to check HWO=0\n");
+		return -EAGAIN;
+	}
+
+	return 0;
+}
+
+static bool mtk_cldma_rx_check_again(struct rxq *rxq)
+{
+	struct cldma_drv_info *drv_info;
+	struct cldma_drv_ops *drv_ops;
+	bool need_check_again = false;
+	u32 state;
+	int rxqno;
+
+	drv_info = rxq->drv_info;
+	drv_ops = drv_info->drv_ops;
+	rxqno = rxq->rxqno;
+
+	do {
+		state = drv_ops->cldma_check_intr_status(drv_info, DIR_RX,
+							 rxqno, QUEUE_XFER_DONE);
+		if (state) {
+			if (unlikely(state == LINK_ERROR_VAL))
+				break;
+
+			drv_ops->cldma_clr_intr_status(drv_info, DIR_RX,
+						       rxqno, QUEUE_XFER_DONE);
+			cond_resched();
+			return true;
+		}
+	} while (need_check_again);
+
+	return false;
+}
+
+static void mtk_cldma_rx_done_work(struct work_struct *work)
+{
+	struct rx_req *req = NULL, *pre_req = NULL;
+	struct rxq *rxq = container_of(work, struct rxq, rx_done_work);
+	struct cldma_drv_info *drv_info;
+	struct cldma_drv_ops *drv_ops;
+	struct mtk_md_dev *mdev;
+	struct sk_buff *rx_skb;
+	int i, ret, idx;
+
+	drv_info = rxq->drv_info;
+	mdev = drv_info->mdev;
+	drv_ops = drv_info->drv_ops;
+
+again:
+	for (i = 0; i < rxq->nr_gpds; i++) {
+		req = rxq->req_pool + rxq->free_idx;
+		if (!req->skb) {
+			dev_err(mdev->dev,
+				"Failed to get valid req cldma%d rxq%d req%d\n",
+				drv_info->hw_id, rxq->rxqno, rxq->free_idx);
+			goto out;
+		}
+
+		if (req->gpd->rx_gpd.gpd_flags & CLDMA_GPD_FLAG_HWO)
+			break;
+
+		dma_rmb(); /* read descriptor fields after HWO check */
+
+		mtk_cldma_rx_skb_adjust(mdev, rxq, req);
+		rx_skb = req->skb;
+		req->skb = NULL;
+
+		ret = mtk_cldma_reload_rx_skb(mdev, rxq, req);
+		if (ret) {
+			/* Alloc failed — recycle old buffer, drop packet */
+			skb_trim(rx_skb, 0);
+			req->skb = rx_skb;
+			req->data_dma_addr = dma_map_single(mdev->dev,
+							    rx_skb->data,
+							    rxq->nr_bds ? req->frag_size : req->mtu,
+							    DMA_FROM_DEVICE);
+			if (dma_mapping_error(mdev->dev, req->data_dma_addr)) {
+				req->data_dma_addr = 0;
+				goto out;
+			}
+			req->gpd->rx_gpd.data_buff_ptr_h =
+				cpu_to_le32((u64)req->data_dma_addr >> 32);
+			req->gpd->rx_gpd.data_buff_ptr_l =
+				cpu_to_le32(req->data_dma_addr);
+		} else {
+			do {
+				ret = rxq->rx_done(rx_skb, rxq->arg,
+						   atomic_read(&rxq->need_exit) ? true : false);
+				if (ret == -EAGAIN)
+					usleep_range(1000, 2000);
+			} while (ret == -EAGAIN);
+		}
+
+		wmb(); /* ensure addr set done before HWO setup done  */
+
+		idx = rxq->free_idx == 0 ? rxq->nr_gpds - 1 : rxq->free_idx - 1;
+		pre_req = rxq->req_pool + idx;
+		pre_req->gpd->rx_gpd.gpd_flags |= CLDMA_GPD_FLAG_HWO;
+		rxq->free_idx = (rxq->free_idx + 1) % rxq->nr_gpds;
+	}
+
+	ret = mtk_cldma_check_rx_req(drv_info, rxq);
+	if (!ret)
+		goto again;
+	else if (ret == -ENXIO)
+		goto out;
+
+	if (!atomic_read(&rxq->need_exit))
+		drv_ops->cldma_resume_queue(drv_info, DIR_RX, rxq->rxqno);
+
+	if (mtk_cldma_rx_check_again(rxq))
+		goto again;
+
+out:
+	drv_ops->cldma_unmask_intr(drv_info, DIR_RX, rxq->rxqno, QUEUE_XFER_DONE);
+	drv_ops->cldma_clear_ip_busy(drv_info);
+}
+
+static int mtk_cldma_alloc_tx_bd(struct cldma_drv_info *drv_info, struct txq *txq,
+				 struct tx_req *req)
+{
+	struct bd_dsc *bd_dsc, *last_bd_dsc = NULL;
+	int i;
+
+	req->bd_dsc_pool = kcalloc(txq->nr_bds, sizeof(*bd_dsc),
+				   GFP_KERNEL);
+	if (!req->bd_dsc_pool)
+		return -ENOMEM;
+
+	for (i = 0; i < txq->nr_bds; i++) {
+		bd_dsc = req->bd_dsc_pool + i;
+		bd_dsc->bd = dma_pool_zalloc(drv_info->bd_dma_pool, GFP_KERNEL,
+					     &bd_dsc->bd_dma_addr);
+		if (!bd_dsc->bd)
+			return -ENOMEM;
+		if (!last_bd_dsc) {
+			req->gpd->tx_gpd.data_buff_ptr_h =
+				cpu_to_le32((u64)(bd_dsc->bd_dma_addr) >> 32);
+			req->gpd->tx_gpd.data_buff_ptr_l =
+				cpu_to_le32(bd_dsc->bd_dma_addr);
+		} else {
+			last_bd_dsc->bd->tx_bd.next_bd_ptr_h =
+				cpu_to_le32((u64)(bd_dsc->bd_dma_addr) >> 32);
+			last_bd_dsc->bd->tx_bd.next_bd_ptr_l =
+				cpu_to_le32(bd_dsc->bd_dma_addr);
+		}
+		last_bd_dsc = bd_dsc;
+	}
+	return 0;
+}
+
+static struct txq *mtk_cldma_txq_alloc(struct cldma_drv_info *drv_info, struct sk_buff *skb)
+{
+	struct trb *trb = (struct trb *)skb->cb;
+	struct cldma_drv_ops *drv_ops;
+	struct mtk_ctrl_trans *trans;
+	struct mtk_ctrl_blk *ctrl_blk;
+	struct mtk_md_dev *mdev;
+	struct bd_dsc *bd_dsc;
+	struct tx_req *next;
+	struct tx_req *req;
+	u16 tx_frag_size;
+	struct txq *txq;
+	int i, j, ret;
+
+	mdev = drv_info->mdev;
+	ctrl_blk = mdev->ctrl_blk;
+	trans = ctrl_blk->ctrl_hw_priv;
+	drv_ops = drv_info->drv_ops;
+
+	txq = kzalloc_obj(*txq);
+	if (!txq)
+		return NULL;
+
+	txq->que = radix_tree_lookup(&trans->queue_tbl, trb->channel_id & 0xFFFF);
+	txq->drv_info = drv_info;
+	txq->txqno = txq->que->txqno;
+	txq->nr_gpds = txq->que->tx_nr_gpds;
+	atomic_set(&txq->req_budget, txq->que->tx_nr_gpds);
+	txq->is_stopping = false;
+	tx_frag_size = txq->que->tx_frag_size;
+	if (txq->que->tx_mtu > tx_frag_size && tx_frag_size)
+		txq->nr_bds = (txq->que->tx_mtu + tx_frag_size - 1) / tx_frag_size;
+
+	txq->req_pool = kcalloc(txq->nr_gpds, sizeof(*req), GFP_KERNEL);
+	if (!txq->req_pool)
+		goto err_free_txq;
+
+	for (i = 0; i < txq->nr_gpds; i++) {
+		req = txq->req_pool + i;
+		req->mtu = txq->que->tx_mtu;
+		req->frag_size = tx_frag_size;
+		req->gpd = dma_pool_zalloc(drv_info->gpd_dma_pool, GFP_KERNEL, &req->gpd_dma_addr);
+		if (!req->gpd)
+			goto err_free_req;
+		if (txq->nr_bds) {
+			ret = mtk_cldma_alloc_tx_bd(drv_info, txq, req);
+			if (ret)
+				goto err_free_req;
+			req->gpd->tx_gpd.gpd_flags |= CLDMA_GPD_FLAG_BDP;
+		}
+	}
+
+	for (i = 0; i < txq->nr_gpds; i++) {
+		req = txq->req_pool + i;
+		next = txq->req_pool + ((i + 1) % txq->nr_gpds);
+		req->gpd->tx_gpd.gpd_flags |= CLDMA_GPD_FLAG_IOC;
+		req->gpd->tx_gpd.next_gpd_ptr_h = cpu_to_le32((u64)(next->gpd_dma_addr) >> 32);
+		req->gpd->tx_gpd.next_gpd_ptr_l = cpu_to_le32(next->gpd_dma_addr);
+	}
+
+	INIT_WORK(&txq->tx_done_work, mtk_cldma_tx_done_work);
+
+	drv_ops->cldma_stop_queue(drv_info, DIR_TX, txq->txqno);
+	txq->tx_started = false;
+	drv_ops->cldma_setup_start_addr(drv_info, DIR_TX, txq->txqno,
+					txq->req_pool[0].gpd_dma_addr);
+	drv_ops->cldma_unmask_intr(drv_info, DIR_TX, txq->txqno, QUEUE_ERROR);
+	drv_ops->cldma_unmask_intr(drv_info, DIR_TX, txq->txqno, QUEUE_XFER_DONE);
+
+	drv_info->txq[txq->txqno] = txq;
+	return txq;
+
+err_free_req:
+	for (i = 0; i < txq->nr_gpds; i++) {
+		req = txq->req_pool + i;
+		if (!req->gpd)
+			break;
+		if (req->bd_dsc_pool) {
+			for (j = 0; j < txq->nr_bds; j++) {
+				bd_dsc = req->bd_dsc_pool + j;
+				if (!bd_dsc->bd)
+					break;
+				dma_pool_free(drv_info->bd_dma_pool, bd_dsc->bd,
+					      bd_dsc->bd_dma_addr);
+			}
+			kfree(req->bd_dsc_pool);
+		}
+		dma_pool_free(drv_info->gpd_dma_pool, req->gpd, req->gpd_dma_addr);
+	}
+	kfree(txq->req_pool);
+err_free_txq:
+	kfree(txq);
+	return NULL;
+}
+
+static void mtk_cldma_txq_free(struct cldma_drv_info *drv_info, u32 txqno)
+{
+	struct cldma_drv_ops *drv_ops;
+	struct mtk_md_dev *mdev;
+	struct bd_dsc *bd_dsc;
+	struct tx_req *req;
+	struct txq *txq;
+	struct trb *trb;
+	int irq_id;
+	int i, j;
+
+	mdev = drv_info->mdev;
+	drv_ops = drv_info->drv_ops;
+
+	txq = drv_info->txq[txqno];
+	drv_info->txq[txqno] = NULL;
+	/* stop HW tx transaction */
+	drv_ops->cldma_stop_queue(drv_info, DIR_TX, txqno);
+	txq->tx_started = false;
+
+	irq_id = mtk_pci_get_virq_id(mdev, drv_info->pci_ext_irq_id);
+	synchronize_irq(irq_id);
+	/* flush on-going work */
+	flush_work(&txq->tx_done_work);
+	drv_ops->cldma_mask_intr(drv_info, DIR_TX, txqno, QUEUE_XFER_DONE);
+	drv_ops->cldma_mask_intr(drv_info, DIR_TX, txqno, QUEUE_ERROR);
+
+	/* free tx req resource */
+	for (i = 0; i < txq->nr_gpds; i++) {
+		req = txq->req_pool + txq->free_idx;
+		if (req->skb && req->data_len) {
+			if (!txq->nr_bds)
+				dma_unmap_single(mdev->dev, req->data_dma_addr,
+						 req->data_len, DMA_TO_DEVICE);
+			for (j = 0; j < txq->nr_bds; j++) {
+				bd_dsc = req->bd_dsc_pool + j;
+				if (!bd_dsc->data_dma_addr)
+					continue;
+				dma_unmap_single(mdev->dev, bd_dsc->data_dma_addr,
+						 bd_dsc->data_len, DMA_TO_DEVICE);
+			}
+			trb = (struct trb *)req->skb->cb;
+			trb->status = -EPIPE;
+			trb->trb_complete(req->skb);
+		}
+		for (j = 0; j < txq->nr_bds; j++) {
+			bd_dsc = req->bd_dsc_pool + j;
+			dma_pool_free(drv_info->bd_dma_pool, bd_dsc->bd,
+				      bd_dsc->bd_dma_addr);
+		}
+		kfree(req->bd_dsc_pool);
+		dma_pool_free(drv_info->gpd_dma_pool, req->gpd, req->gpd_dma_addr);
+		txq->free_idx = (txq->free_idx + 1) % txq->nr_gpds;
+	}
+
+	kfree(txq->req_pool);
+	kfree(txq);
+}
+
+static int mtk_cldma_alloc_rx_bd(struct cldma_drv_info *drv_info, struct rx_req *req,
+				 int nr_bds)
+{
+	struct bd_dsc *bd_dsc, *last_bd_dsc = NULL;
+	struct sk_buff *tail = NULL;
+	struct mtk_md_dev *mdev;
+	u32 left_size;
+	int ret;
+	int i;
+
+	mdev = drv_info->mdev;
+	left_size = req->mtu;
+
+	req->bd_dsc_pool = kcalloc(nr_bds, sizeof(*bd_dsc),
+				   GFP_KERNEL);
+	if (!req->bd_dsc_pool)
+		return -ENOMEM;
+	for (i = 0; i < nr_bds; i++) {
+		bd_dsc = req->bd_dsc_pool + i;
+		bd_dsc->bd = dma_pool_zalloc(drv_info->bd_dma_pool, GFP_KERNEL,
+					     &bd_dsc->bd_dma_addr);
+		if (!bd_dsc->bd)
+			return -ENOMEM;
+
+		bd_dsc->skb = __dev_alloc_skb(req->frag_size, GFP_KERNEL);
+		if (!bd_dsc->skb)
+			return -ENOMEM;
+		bd_dsc->skb->next = NULL;
+		bd_dsc->data_dma_addr =
+			dma_map_single(mdev->dev, bd_dsc->skb->data,
+				       req->frag_size, DMA_FROM_DEVICE);
+		ret = dma_mapping_error(mdev->dev, bd_dsc->data_dma_addr);
+		if (unlikely(ret))
+			return -ENOMEM;
+
+		bd_dsc->bd->rx_bd.data_buff_ptr_h =
+			cpu_to_le32((u64)(bd_dsc->data_dma_addr) >> 32);
+		bd_dsc->bd->rx_bd.data_buff_ptr_l =
+			cpu_to_le32(bd_dsc->data_dma_addr);
+		bd_dsc->bd->rx_bd.data_allow_len =
+			cpu_to_le16(min(req->frag_size, left_size));
+		left_size -= min(req->frag_size, left_size);
+		if (!last_bd_dsc) {
+			req->gpd->rx_gpd.data_buff_ptr_h =
+				cpu_to_le32((u64)(bd_dsc->bd_dma_addr) >> 32);
+			req->gpd->rx_gpd.data_buff_ptr_l =
+				cpu_to_le32(bd_dsc->bd_dma_addr);
+		} else {
+			last_bd_dsc->bd->rx_bd.next_bd_ptr_h =
+				cpu_to_le32((u64)(bd_dsc->bd_dma_addr) >> 32);
+			last_bd_dsc->bd->rx_bd.next_bd_ptr_l =
+				cpu_to_le32(bd_dsc->bd_dma_addr);
+		}
+		last_bd_dsc = bd_dsc;
+		if (tail) {
+			tail->next = bd_dsc->skb;
+			tail = bd_dsc->skb;
+			continue;
+		}
+		if (!req->skb) {
+			req->skb = bd_dsc->skb;
+		} else {
+			skb_shinfo(req->skb)->frag_list = bd_dsc->skb;
+			tail = bd_dsc->skb;
+		}
+	}
+	last_bd_dsc->bd->rx_bd.bd_flags |= CLDMA_BD_FLAG_EOL;
+	return 0;
+}
+
+static void mtk_cldma_rxq_alloc_cancel(struct cldma_drv_info *drv_info, struct rx_req *req,
+				       int nr_bds)
+{
+	struct mtk_md_dev *mdev;
+	struct bd_dsc *bd_dsc;
+	int i;
+
+	mdev = drv_info->mdev;
+
+	if (nr_bds) {
+		if (req->skb)
+			skb_shinfo(req->skb)->frag_list = NULL;
+		if (req->bd_dsc_pool) {
+			for (i = 0; i < nr_bds; i++) {
+				bd_dsc = req->bd_dsc_pool + i;
+				if (!bd_dsc->bd)
+					break;
+				if (bd_dsc->skb) {
+					if (!dma_mapping_error(mdev->dev, bd_dsc->data_dma_addr))
+						dma_unmap_single(mdev->dev, bd_dsc->data_dma_addr,
+								 req->frag_size, DMA_FROM_DEVICE);
+					bd_dsc->data_dma_addr = 0;
+					bd_dsc->skb->next = NULL;
+					dev_kfree_skb_any(bd_dsc->skb);
+				}
+				dma_pool_free(drv_info->bd_dma_pool, bd_dsc->bd,
+					      bd_dsc->bd_dma_addr);
+			}
+			kfree(req->bd_dsc_pool);
+		}
+	} else {
+		if (req->skb) {
+			if (!dma_mapping_error(mdev->dev, req->data_dma_addr))
+				dma_unmap_single(mdev->dev, req->data_dma_addr,
+						 req->mtu, DMA_FROM_DEVICE);
+			req->data_dma_addr = 0;
+			dev_kfree_skb_any(req->skb);
+		}
+	}
+	dma_pool_free(drv_info->gpd_dma_pool, req->gpd, req->gpd_dma_addr);
+}
+
+static struct rxq *mtk_cldma_rxq_alloc(struct cldma_drv_info *drv_info, struct sk_buff *skb)
+{
+	struct trb_open_priv *trb_open_priv = (struct trb_open_priv *)skb->data;
+	struct trb *trb = (struct trb *)skb->cb;
+	struct cldma_drv_ops *drv_ops;
+	struct mtk_ctrl_trans *trans;
+	struct mtk_ctrl_blk *ctrl_blk;
+	struct mtk_md_dev *mdev;
+	struct rx_req *next;
+	struct rx_req *req;
+	u16 rx_frag_size;
+	struct rxq *rxq;
+	int ret;
+	int i;
+
+	mdev = drv_info->mdev;
+	ctrl_blk = mdev->ctrl_blk;
+	trans = ctrl_blk->ctrl_hw_priv;
+	drv_ops = drv_info->drv_ops;
+
+	rxq = kzalloc_obj(*rxq);
+	if (!rxq)
+		return NULL;
+
+	rxq->que = radix_tree_lookup(&trans->queue_tbl, trb->channel_id & 0xFFFF);
+	if (rxq->que->rx_nr_gpds < MIN_GPD_NUM) {
+		dev_err(mdev->dev,
+			"Failed to alloc cldma%d rxq%d due to gpd number < 2\n",
+			drv_info->hw_id, rxq->rxqno);
+		goto err_free_rxq;
+	}
+	rxq->drv_info = drv_info;
+	rxq->rxqno = rxq->que->rxqno;
+	rxq->nr_gpds = rxq->que->rx_nr_gpds;
+	rxq->arg = trb->priv;
+	rxq->rx_done = trb_open_priv->rx_done;
+	atomic_set(&rxq->need_exit, 0);
+	rx_frag_size = rxq->que->rx_frag_size;
+	if (rxq->que->rx_mtu > rx_frag_size && rx_frag_size)
+		rxq->nr_bds = (rxq->que->rx_mtu + rx_frag_size - 1) / rx_frag_size;
+
+	rxq->req_pool = kcalloc(rxq->nr_gpds, sizeof(*req), GFP_KERNEL);
+	if (!rxq->req_pool)
+		goto err_free_rxq;
+
+	/* setup rx request */
+	for (i = 0; i < rxq->nr_gpds; i++) {
+		req = rxq->req_pool + i;
+		req->mtu = rxq->que->rx_mtu;
+		req->frag_size = rx_frag_size;
+		req->gpd = dma_pool_zalloc(drv_info->gpd_dma_pool, GFP_KERNEL, &req->gpd_dma_addr);
+		if (!req->gpd)
+			goto err_free_req;
+		if (rxq->nr_bds) {
+			ret = mtk_cldma_alloc_rx_bd(drv_info, req, rxq->nr_bds);
+			if (ret)
+				goto err_free_req;
+			req->gpd->rx_gpd.gpd_flags |= CLDMA_GPD_FLAG_BDP;
+		} else {
+			req->skb = __dev_alloc_skb(req->mtu, GFP_KERNEL);
+			if (!req->skb)
+				goto err_free_req;
+			req->data_dma_addr = dma_map_single(mdev->dev, req->skb->data,
+							    req->mtu, DMA_FROM_DEVICE);
+			ret = dma_mapping_error(mdev->dev, req->data_dma_addr);
+			if (unlikely(ret))
+				goto err_free_req;
+		}
+	}
+
+	for (i = 0; i < rxq->nr_gpds; i++) {
+		req = rxq->req_pool + i;
+		next = rxq->req_pool + ((i + 1) % rxq->nr_gpds);
+		req->gpd->rx_gpd.gpd_flags |= CLDMA_GPD_FLAG_IOC;
+		req->gpd->rx_gpd.data_allow_len = cpu_to_le16(req->mtu);
+		req->gpd->rx_gpd.next_gpd_ptr_h = cpu_to_le32((u64)(next->gpd_dma_addr) >> 32);
+		req->gpd->rx_gpd.next_gpd_ptr_l = cpu_to_le32(next->gpd_dma_addr);
+		if (!rxq->nr_bds) {
+			req->gpd->rx_gpd.data_buff_ptr_h =
+				cpu_to_le32((u64)(req->data_dma_addr) >> 32);
+			req->gpd->rx_gpd.data_buff_ptr_l = cpu_to_le32(req->data_dma_addr);
+		}
+		if (i != rxq->nr_gpds - 1)
+			req->gpd->rx_gpd.gpd_flags |= CLDMA_GPD_FLAG_HWO;
+	}
+
+	INIT_WORK(&rxq->rx_done_work, mtk_cldma_rx_done_work);
+
+	drv_info->rxq[rxq->rxqno] = rxq;
+	drv_ops->cldma_stop_queue(drv_info, DIR_RX, rxq->rxqno);
+	drv_ops->cldma_setup_start_addr(drv_info, DIR_RX,
+					rxq->rxqno, rxq->req_pool[0].gpd_dma_addr);
+	drv_ops->cldma_start_queue(drv_info, DIR_RX, rxq->rxqno);
+	drv_ops->cldma_unmask_intr(drv_info, DIR_RX, rxq->rxqno, QUEUE_ERROR);
+	drv_ops->cldma_unmask_intr(drv_info, DIR_RX, rxq->rxqno, QUEUE_XFER_DONE);
+
+	return rxq;
+
+err_free_req:
+	for (i = 0; i < rxq->nr_gpds; i++) {
+		req = rxq->req_pool + i;
+		if (!req->gpd)
+			break;
+		mtk_cldma_rxq_alloc_cancel(drv_info, req, rxq->nr_bds);
+	}
+
+	kfree(rxq->req_pool);
+err_free_rxq:
+	kfree(rxq);
+	return NULL;
+}
+
+static void mtk_cldma_rxq_free(struct cldma_drv_info *drv_info, u32 rxqno)
+{
+	struct cldma_drv_ops *drv_ops;
+	struct mtk_md_dev *mdev;
+	struct bd_dsc *bd_dsc;
+	struct rx_req *req;
+	struct rxq *rxq;
+	int irq_id;
+	int i, j;
+
+	mdev = drv_info->mdev;
+	drv_ops = drv_info->drv_ops;
+
+	rxq = drv_info->rxq[rxqno];
+	drv_info->rxq[rxqno] = NULL;
+
+	/* stop HW rx transaction */
+	atomic_set(&rxq->need_exit, 1);
+	drv_ops->cldma_stop_queue(drv_info, DIR_RX, rxqno);
+
+	irq_id = mtk_pci_get_virq_id(mdev, drv_info->pci_ext_irq_id);
+	synchronize_irq(irq_id);
+	/* flush on-going work */
+	flush_work(&rxq->rx_done_work);
+	/* mask L2 RX interrupt again to avoid race condition causing use-after-free issue */
+	drv_ops->cldma_mask_intr(drv_info, DIR_RX, rxqno, QUEUE_XFER_DONE);
+	drv_ops->cldma_mask_intr(drv_info, DIR_RX, rxqno, QUEUE_ERROR);
+
+	/* free rx req resource */
+	for (i = 0; i < rxq->nr_gpds; i++) {
+		req = rxq->req_pool + rxq->free_idx;
+		if (!(req->gpd->rx_gpd.gpd_flags & CLDMA_GPD_FLAG_HWO) &&
+		    le16_to_cpu(req->gpd->rx_gpd.data_recv_len)) {
+			mtk_cldma_rx_skb_adjust(mdev, rxq, req);
+			rxq->rx_done(req->skb, rxq->arg, true);
+			req->skb = NULL;
+		}
+		if (req->skb) {
+			if (rxq->nr_bds) {
+				skb_shinfo(req->skb)->frag_list = NULL;
+			} else {
+				if (req->data_dma_addr)
+					dma_unmap_single(mdev->dev, req->data_dma_addr,
+							 req->mtu, DMA_FROM_DEVICE);
+				dev_kfree_skb_any(req->skb);
+			}
+		}
+		for (j = 0; j < rxq->nr_bds; j++) {
+			bd_dsc = req->bd_dsc_pool + j;
+			if (bd_dsc->skb) {
+				if (bd_dsc->data_dma_addr)
+					dma_unmap_single(mdev->dev, bd_dsc->data_dma_addr,
+							 req->frag_size, DMA_FROM_DEVICE);
+				bd_dsc->skb->next = NULL;
+				dev_kfree_skb_any(bd_dsc->skb);
+			}
+			dma_pool_free(drv_info->bd_dma_pool,
+				      bd_dsc->bd, bd_dsc->bd_dma_addr);
+		}
+		kfree(req->bd_dsc_pool);
+		dma_pool_free(drv_info->gpd_dma_pool, req->gpd, req->gpd_dma_addr);
+		rxq->free_idx = (rxq->free_idx + 1) % rxq->nr_gpds;
+	}
+
+	kfree(rxq->req_pool);
+	kfree(rxq);
+}
+
+static int mtk_cldma_start_xfer(struct cldma_drv_info *drv_info, u32 qno)
+{
+	struct cldma_drv_ops *drv_ops;
+	struct txq *txq;
+	u32 val;
+
+	txq = drv_info->txq[qno];
+	drv_ops = drv_info->drv_ops;
+
+	val = drv_ops->cldma_get_tx_start_addr(drv_info, qno);
+	if (unlikely(val == LINK_ERROR_VAL))
+		return -EIO;
+
+	if (unlikely(!val)) {
+		drv_ops->cldma_drv_init(drv_info);
+		txq = drv_info->txq[qno];
+		drv_ops->cldma_setup_start_addr(drv_info, DIR_TX, qno,
+						txq->req_pool[txq->free_idx].gpd_dma_addr);
+		drv_ops->cldma_start_queue(drv_info, DIR_TX, qno);
+		txq->tx_started = true;
+	} else if (unlikely(!txq->tx_started)) {
+		drv_ops->cldma_start_queue(drv_info, DIR_TX, qno);
+		txq->tx_started = true;
+	} else {
+		drv_ops->cldma_resume_queue(drv_info, DIR_TX, qno);
+	}
+
+	return 0;
+}
+
+int mtk_cldma_init(struct mtk_ctrl_trans *trans)
+{
+	struct cldma_dev *cd;
+
+	cd = kzalloc_obj(*cd);
+	if (!cd)
+		return -ENOMEM;
+
+	cd->trans = trans;
+	trans->dev = cd;
+
+	return 0;
+}
+
+void mtk_cldma_exit(struct mtk_ctrl_trans *trans)
+{
+	if (!trans->dev)
+		return;
+
+	kfree(trans->dev);
+	trans->dev = NULL;
+}
+
+static int mtk_cldma_open(struct cldma_dev *cd, struct sk_buff *skb)
+{
+	struct trb_open_priv *trb_open_priv = (struct trb_open_priv *)skb->data;
+	struct trb *trb = (struct trb *)skb->cb;
+	struct cldma_drv_info *drv_info;
+	struct queue_info *que;
+	struct txq *txq;
+	struct rxq *rxq;
+	int ret = 0;
+
+	que = radix_tree_lookup(&cd->trans->queue_tbl, trb->channel_id & 0xFFFF);
+	drv_info = cd->cldma_drv_info[que->hif_id];
+	if (!drv_info) {
+		ret = -EIO;
+		goto out;
+	}
+
+	if (que->tx_mtu == 0 || que->rx_mtu == 0) {
+		dev_err((cd->trans->mdev)->dev,
+			"Failed to enable cldma%d txq%d rxq%d due to wrong mtu\n",
+			drv_info->hw_id, que->txqno, que->rxqno);
+		ret = -EINVAL;
+		goto out;
+	}
+
+	trb_open_priv->tx_mtu = que->tx_mtu;
+	trb_open_priv->rx_mtu = que->rx_mtu;
+	trb_open_priv->tx_frag_size = que->tx_frag_size;
+	trb_open_priv->rx_frag_size = que->rx_frag_size;
+
+	if (drv_info->txq[que->txqno] || drv_info->rxq[que->rxqno]) {
+		ret = -EBUSY;
+		goto out;
+	}
+
+	txq = mtk_cldma_txq_alloc(drv_info, skb);
+	if (!txq) {
+		ret = -ENOMEM;
+		goto out;
+	}
+
+	rxq = mtk_cldma_rxq_alloc(drv_info, skb);
+	if (!rxq) {
+		ret = -ENOMEM;
+		mtk_cldma_txq_free(drv_info, txq->txqno);
+		goto out;
+	}
+
+out:
+	trb->status = ret;
+	trb->trb_complete(skb);
+
+	return ret;
+}
+
+static int mtk_cldma_tx(struct cldma_dev *cd, struct sk_buff *skb)
+{
+	struct trb *trb = (struct trb *)skb->cb;
+	struct cldma_drv_info *drv_info;
+	struct mtk_md_dev *mdev;
+	struct queue_info *que;
+	struct txq *txq;
+	int ret;
+
+	que = radix_tree_lookup(&cd->trans->queue_tbl, trb->channel_id & 0xFFFF);
+	drv_info = cd->cldma_drv_info[que->hif_id];
+	if (unlikely(!drv_info))
+		return -EPIPE;
+	txq = drv_info->txq[que->txqno];
+	if (unlikely(!txq) || txq->is_stopping)
+		return -EPIPE;
+
+	mdev = drv_info->mdev;
+
+	ret = mtk_cldma_start_xfer(drv_info, que->txqno);
+	if (unlikely(ret))
+		dev_err(mdev->dev, "Failed to trigger cldma tx\n");
+
+	return ret;
+}
+
+static int mtk_cldma_close(struct cldma_dev *cd, struct sk_buff *skb)
+{
+	struct trb *trb = (struct trb *)skb->cb;
+	struct cldma_drv_info *drv_info;
+	struct queue_info *que;
+
+	que = radix_tree_lookup(&cd->trans->queue_tbl, trb->channel_id & 0xFFFF);
+	drv_info = cd->cldma_drv_info[que->hif_id];
+	if (unlikely(!drv_info))
+		return -EPIPE;
+
+	if (drv_info->txq[que->txqno])
+		mtk_cldma_txq_free(drv_info, que->txqno);
+	if (drv_info->rxq[que->rxqno])
+		mtk_cldma_rxq_free(drv_info, que->rxqno);
+
+	trb->status = 0;
+	trb->trb_complete(skb);
+
+	return 0;
+}
+
+static int mtk_cldma_txbuf_set(struct cldma_drv_info *drv_info, struct sk_buff *skb,
+			       struct tx_req *req, int nr_bds)
+{
+	struct sk_buff *curr_skb, *next_skb;
+	struct mtk_md_dev *mdev;
+	struct bd_dsc *bd_dsc;
+	int ret;
+	int i;
+
+	mdev = drv_info->mdev;
+
+	if (nr_bds) {
+		bd_dsc = req->bd_dsc_pool;
+		curr_skb = skb;
+		for (i = 0; i < nr_bds && curr_skb; i++) {
+			bd_dsc = req->bd_dsc_pool + i;
+			if (req->bd_dsc_pool == bd_dsc) {
+				bd_dsc->data_len = skb->len - skb->data_len;
+				next_skb = skb_shinfo(skb)->frag_list;
+			} else {
+				bd_dsc->data_len = curr_skb->len;
+				next_skb = curr_skb->next;
+			}
+			bd_dsc->data_dma_addr = dma_map_single(mdev->dev, curr_skb->data,
+							       bd_dsc->data_len, DMA_TO_DEVICE);
+			ret = dma_mapping_error(mdev->dev, bd_dsc->data_dma_addr);
+			if (unlikely(ret))
+				goto err_unmap_buffer;
+
+			bd_dsc->bd->tx_bd.data_buff_ptr_h =
+				cpu_to_le32((u64)(bd_dsc->data_dma_addr) >> 32);
+			bd_dsc->bd->tx_bd.data_buff_ptr_l = cpu_to_le32(bd_dsc->data_dma_addr);
+			bd_dsc->bd->tx_bd.data_buffer_len = cpu_to_le16(bd_dsc->data_len);
+			curr_skb = next_skb;
+		}
+		bd_dsc->bd->tx_bd.bd_flags = CLDMA_BD_FLAG_EOL;
+	} else {
+		req->data_dma_addr = dma_map_single(mdev->dev, skb->data,
+						    skb_headlen(skb), DMA_TO_DEVICE);
+		ret = dma_mapping_error(mdev->dev, req->data_dma_addr);
+		if (unlikely(ret)) {
+			req->data_dma_addr = 0;
+			goto err_exit;
+		}
+
+		req->gpd->tx_gpd.data_buff_ptr_h = cpu_to_le32((u64)(req->data_dma_addr) >> 32);
+		req->gpd->tx_gpd.data_buff_ptr_l = cpu_to_le32(req->data_dma_addr);
+	}
+
+	return 0;
+
+err_unmap_buffer:
+	for (i = 0; i < nr_bds; i++) {
+		bd_dsc = req->bd_dsc_pool + i;
+		if (dma_mapping_error(mdev->dev, bd_dsc->data_dma_addr)) {
+			bd_dsc->data_dma_addr = 0;
+			break;
+		}
+		dma_unmap_single(mdev->dev, bd_dsc->data_dma_addr,
+				 bd_dsc->data_len, DMA_TO_DEVICE);
+		bd_dsc->data_dma_addr = 0;
+	}
+err_exit:
+	dev_err(mdev->dev, "Failed to map dma! error:%d\n", ret);
+	return -EAGAIN;
+}
+
+int mtk_cldma_submit_tx(void *dev, struct sk_buff *skb)
+{
+	struct trb *trb = (struct trb *)skb->cb;
+	struct cldma_drv_info *drv_info;
+	struct cldma_dev *cd = dev;
+	struct queue_info *que;
+	struct tx_req *req;
+	struct txq *txq;
+	int ret;
+
+	que = radix_tree_lookup(&cd->trans->queue_tbl, trb->channel_id & 0xFFFF);
+	drv_info = cd->cldma_drv_info[que->hif_id];
+	if (unlikely(!drv_info))
+		return -EINVAL;
+
+	txq = drv_info->txq[que->txqno];
+	if (unlikely(!txq))
+		return -EINVAL;
+
+	if (!atomic_read(&txq->req_budget))
+		return -EAGAIN;
+
+	req = txq->req_pool + txq->wr_idx;
+	req->gpd->tx_gpd.debug_id = 0x01;
+	ret = mtk_cldma_txbuf_set(drv_info, skb, req, txq->nr_bds);
+	if (ret)
+		return ret;
+
+	req->gpd->tx_gpd.data_buff_len = cpu_to_le16(skb->len);
+
+	req->data_len = skb->len;
+	req->skb = skb;
+	req->data_vm_addr = skb->data;
+
+	wmb(); /* ensure req and data msg set done before HWO setup */
+
+	req->gpd->tx_gpd.gpd_flags |= CLDMA_GPD_FLAG_HWO;
+
+	wmb(); /* ensure HWO setup done before index update */
+
+	WRITE_ONCE(txq->wr_idx, (txq->wr_idx + 1) % txq->nr_gpds);
+	atomic_dec(&txq->req_budget);
+
+	return 0;
+}
+
+int mtk_cldma_get_tx_budget(void *dev, enum mtk_hif_id hif_id, u32 qno)
+{
+	struct cldma_drv_info *drv_info;
+	struct cldma_dev *cd = dev;
+	struct txq *txq;
+
+	if (unlikely(hif_id >= NR_CLDMA || qno >= HW_QUE_NUM || !cd))
+		return -EINVAL;
+
+	drv_info = cd->cldma_drv_info[hif_id];
+	if (!drv_info)
+		return -EINVAL;
+	txq = drv_info->txq[qno];
+	if (!txq)
+		return -EINVAL;
+	return atomic_read(&txq->req_budget);
+}
+
+static int (*trb_act_tbl[TRB_CMD_MAX])(struct cldma_dev *cd, struct sk_buff *skb) = {
+	[TRB_CMD_ENABLE] = mtk_cldma_open,
+	[TRB_CMD_TX] = mtk_cldma_tx,
+	[TRB_CMD_DISABLE] = mtk_cldma_close,
+};
+
+int mtk_cldma_trb_process(void *dev, struct sk_buff *skb)
+{
+	struct cldma_dev *cd;
+	struct trb *trb;
+
+	if (!dev || !skb)
+		return -EINVAL;
+
+	cd = (struct cldma_dev *)dev;
+	trb = (struct trb *)skb->cb;
+
+	if (!(trb->cmd > TRB_CMD_MIN && trb->cmd < TRB_CMD_STOP))
+		return -EINVAL;
+
+	return trb_act_tbl[trb->cmd](cd, skb);
+}
+
+int mtk_cldma_check_ch_cfg(void *dev, struct queue_info *que)
+{
+	struct cldma_drv_info *drv_info;
+	struct cldma_dev *cd = dev;
+	struct mtk_md_dev *mdev;
+	struct txq *txq;
+	struct rxq *rxq;
+
+	mdev = cd->trans->mdev;
+	drv_info = cd->cldma_drv_info[que->hif_id];
+
+	if (!drv_info) {
+		dev_err(mdev->dev, "CLDMA%d has not been initialized\n",
+			mtk_cldma_hw_id_tbl[que->hif_id]);
+		return -EINVAL;
+	}
+
+	txq = drv_info->txq[que->txqno];
+	rxq = drv_info->rxq[que->rxqno];
+	if (!txq || !rxq) {
+		dev_err(mdev->dev,
+			"CLDMA%d txq%d rxq%d has not been enabled\n",
+			mtk_cldma_hw_id_tbl[que->hif_id], que->txqno, que->rxqno);
+		return -EINVAL;
+	}
+
+	if (que->tx_mtu != txq->que->tx_mtu || que->rx_mtu != rxq->que->rx_mtu) {
+		dev_err(mdev->dev,
+			"Channel:%08x tx_mtu:%08x rx_mtu:%08x do not match ch cfg\n",
+			que->tx_chl, que->tx_mtu, que->rx_mtu);
+		return -EINVAL;
+	}
+
+	return 0;
+}
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_cldma.h b/drivers/net/wwan/t9xx/pcie/mtk_cldma.h
new file mode 100644
index 000000000000..74ce4f2f0b30
--- /dev/null
+++ b/drivers/net/wwan/t9xx/pcie/mtk_cldma.h
@@ -0,0 +1,170 @@
+/* SPDX-License-Identifier: GPL-2.0-only
+ *
+ * Copyright (c) 2022, MediaTek Inc.
+ */
+
+#ifndef __MTK_CLDMA_H__
+#define __MTK_CLDMA_H__
+
+#include <linux/dma-mapping.h>
+#include <linux/dmapool.h>
+#include <linux/interrupt.h>
+#include <linux/list.h>
+#include <linux/spinlock.h>
+#include <linux/types.h>
+
+#include "mtk_ctrl_plane.h"
+#include "mtk_trans_ctrl.h"
+
+struct mtk_fsm_param;
+
+#define TXQ(N)					(N)
+#define RXQ(N)					(N)
+
+#define CLDMA_GPD_FLAG_HWO			BIT(0)
+#define CLDMA_GPD_FLAG_BDP			BIT(1)
+#define CLDMA_GPD_FLAG_BPS			BIT(2)
+#define CLDMA_GPD_FLAG_IOC			BIT(7)
+#define CLDMA_BD_FLAG_EOL			BIT(0)
+
+union gpd {
+	struct {
+		u8 gpd_flags;
+		u8 non_used1;
+		__le16 data_allow_len;
+		__le32 next_gpd_ptr_h;
+		__le32 next_gpd_ptr_l;
+		__le32 data_buff_ptr_h;
+		__le32 data_buff_ptr_l;
+		__le16 data_recv_len;
+		u8 non_used2;
+		u8 debug_id;
+	} rx_gpd;
+
+	struct {
+		u8 gpd_flags;
+		u8 non_used1;
+		u8 non_used2;
+		u8 debug_id;
+		__le32 next_gpd_ptr_h;
+		__le32 next_gpd_ptr_l;
+		__le32 data_buff_ptr_h;
+		__le32 data_buff_ptr_l;
+		__le16 data_buff_len;
+		__le16 non_used3;
+	} tx_gpd;
+} __packed;
+
+union bd {
+	struct {
+		u8 bd_flags;
+		u8 non_used1;
+		__le16 data_allow_len;
+		__le32 next_bd_ptr_h;
+		__le32 next_bd_ptr_l;
+		__le32 data_buff_ptr_h;
+		__le32 data_buff_ptr_l;
+		__le16 data_recv_len;
+		__le16 non_used2;
+	} rx_bd;
+
+	struct {
+		u8 bd_flags;
+		u8 non_used1;
+		__le16 non_used2;
+		__le32 next_bd_ptr_h;
+		__le32 next_bd_ptr_l;
+		__le32 data_buff_ptr_h;
+		__le32 data_buff_ptr_l;
+		__le16 data_buffer_len;
+		u8 extension_len;
+		u8 non_used3;
+	} tx_bd;
+} __packed;
+
+struct bd_dsc {
+	union bd *bd;
+	struct sk_buff *skb;
+	dma_addr_t bd_dma_addr;
+	dma_addr_t data_dma_addr;
+	size_t data_len;
+};
+
+struct rx_req {
+	union gpd *gpd;
+	u32 mtu;
+	struct sk_buff *skb;
+	size_t data_len;
+	dma_addr_t gpd_dma_addr;
+	dma_addr_t data_dma_addr;
+	u32 frag_size;
+	struct bd_dsc *bd_dsc_pool;
+};
+
+struct rxq {
+	struct cldma_drv_info *drv_info;
+	u32 rxqno;
+	struct queue_info *que;
+	struct work_struct rx_done_work;
+	struct rx_req *req_pool;
+	u32 nr_gpds;
+	u32 free_idx;
+	unsigned short rx_done_cnt;
+	void *arg;
+	int (*rx_done)(struct sk_buff *skb, void *priv, bool force_recv);
+	u32 nr_bds;
+	atomic_t need_exit;
+};
+
+struct tx_req {
+	union gpd *gpd;
+	u32 mtu;
+	void *data_vm_addr;
+	size_t data_len;
+	dma_addr_t data_dma_addr;
+	dma_addr_t gpd_dma_addr;
+	struct sk_buff *skb;
+	int (*trb_complete)(struct sk_buff *skb);
+	u32 frag_size;
+	struct bd_dsc *bd_dsc_pool;
+};
+
+struct txq {
+	struct cldma_drv_info *drv_info;
+	u32 txqno;
+	struct queue_info *que;
+	struct work_struct tx_done_work;
+	struct tx_req *req_pool;
+	u32 nr_gpds;
+	atomic_t req_budget;
+	u32 wr_idx;
+	u32 free_idx;
+	bool tx_started;
+	bool is_stopping;
+	unsigned short tx_done_cnt;
+	u32 nr_bds;
+};
+
+struct cldma_dev {
+	struct cldma_drv_info *cldma_drv_info[NR_CLDMA];
+	struct mtk_ctrl_trans *trans;
+};
+
+struct cldma_drv_info_desc {
+	u32 hw_ver;
+	struct cldma_drv_ops *drv_ops;
+	struct cldma_hw_regs *hw_regs;
+};
+
+int mtk_cldma_init(struct mtk_ctrl_trans *trans);
+void mtk_cldma_exit(struct mtk_ctrl_trans *trans);
+int mtk_cldma_submit_tx(void *dev, struct sk_buff *skb);
+int mtk_cldma_get_tx_budget(void *dev, enum mtk_hif_id hif_id, u32 qno);
+int mtk_cldma_trb_process(void *dev, struct sk_buff *skb);
+void mtk_cldma_fsm_state_listener(struct mtk_fsm_param *param, struct mtk_ctrl_trans *trans);
+int mtk_cldma_check_ch_cfg(void *dev, struct queue_info *que);
+
+#define drv_ops_name(NAME) cldma_drv_ops_##NAME
+#define cldma_regs_name(NAME) mtk_cldma_regs_##NAME
+
+#endif
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_cldma_drv.c b/drivers/net/wwan/t9xx/pcie/mtk_cldma_drv.c
new file mode 100644
index 000000000000..8745c1470891
--- /dev/null
+++ b/drivers/net/wwan/t9xx/pcie/mtk_cldma_drv.c
@@ -0,0 +1,369 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (c) 2023, MediaTek Inc.
+ */
+
+#include <linux/delay.h>
+#include <linux/device.h>
+#include <linux/iopoll.h>
+#include <linux/dma-mapping.h>
+#include <linux/dmapool.h>
+#include <linux/err.h>
+#include <linux/interrupt.h>
+#include <linux/kdev_t.h>
+#include <linux/kernel.h>
+#include <linux/kthread.h>
+#include <linux/list.h>
+#include <linux/module.h>
+#include <linux/mutex.h>
+#include <linux/netdevice.h>
+#include <linux/sched.h>
+#include <linux/skbuff.h>
+#include <linux/slab.h>
+#include <linux/timer.h>
+#include <linux/wait.h>
+#include <linux/workqueue.h>
+
+#include "mtk_cldma_drv.h"
+#include "mtk_dev.h"
+#include "mtk_pci.h"
+#include "mtk_pci_reg.h"
+
+#define WAIT_QUEUE_STOP		(70)
+
+void mtk_cldma_drv_init(struct cldma_drv_info *drv_info)
+{
+	struct cldma_hw_regs *hw_regs;
+	struct mtk_md_dev *mdev;
+	int base;
+	u32 val;
+
+	mdev = drv_info->mdev;
+	base = drv_info->base_addr;
+	hw_regs = drv_info->hw_regs;
+
+	/* set CLDMA to 64 bit mode GPD */
+	val = mtk_pci_read32(mdev, base + hw_regs->reg_cldma_ul_cfg);
+	val = (val & (~(0x7 << 5))) | ((0x4) << 5);
+	mtk_pci_write32(mdev, base + hw_regs->reg_cldma_ul_cfg, val);
+
+	val = mtk_pci_read32(mdev, base + hw_regs->reg_cldma_so_cfg);
+	val = (val & (~(0x7 << 10))) | ((0x4) << 10) | (1 << 2);
+	mtk_pci_write32(mdev, base + hw_regs->reg_cldma_so_cfg, val);
+
+	mtk_pci_write32(mdev, base + hw_regs->reg_cldma_rx_work_to_reg_mask_set, ALLQ);
+	mtk_pci_write32(mdev, base + hw_regs->reg_cldma_ip_busy_to_pcie_mask_set,
+			ALLQ << 16);
+	mtk_pci_write32(mdev, base + hw_regs->reg_cldma_ip_busy_to_pcie_mask_clr,
+			ALLQ << 24);
+
+	/* enable interrupt to PCIe */
+	mtk_pci_write32(mdev, base + hw_regs->reg_cldma_int_mask, 0);
+
+	/* disable illegal memory check */
+	mtk_pci_write32(mdev, base + hw_regs->reg_cldma_ul_dummy_0, 1);
+	mtk_pci_write32(mdev, base + hw_regs->reg_cldma_so_dummy_0, 1);
+}
+
+void mtk_cldma_setup_start_addr(struct cldma_drv_info *drv_info, enum mtk_tx_rx dir,
+				u32 qno, dma_addr_t addr)
+{
+	struct cldma_hw_regs *hw_regs;
+	unsigned int addr_l;
+	unsigned int addr_h;
+	int base;
+
+	hw_regs = drv_info->hw_regs;
+	base = drv_info->base_addr;
+
+	if (dir == DIR_TX) {
+		addr_l = base + hw_regs->reg_cldma_ul_start_addrl_0 + qno * HW_QUEUE_NUM;
+		addr_h = base + hw_regs->reg_cldma_ul_start_addrh_0 + qno * HW_QUEUE_NUM;
+	} else {
+		addr_l = base + hw_regs->reg_cldma_so_start_addrl_0 + qno * HW_QUEUE_NUM;
+		addr_h = base + hw_regs->reg_cldma_so_start_addrh_0 + qno * HW_QUEUE_NUM;
+	}
+
+	mtk_pci_write32(drv_info->mdev, addr_l, (u32)addr);
+	mtk_pci_write32(drv_info->mdev, addr_h, (u32)((u64)addr >> 32));
+}
+
+void mtk_cldma_mask_intr(struct cldma_drv_info *drv_info, enum mtk_tx_rx dir,
+			 u32 qno, enum mtk_intr_type type)
+{
+	struct cldma_hw_regs *hw_regs;
+	int base;
+	u32 addr;
+	u32 val;
+
+	hw_regs = drv_info->hw_regs;
+	base = drv_info->base_addr;
+
+	if (dir == DIR_TX)
+		addr = base + hw_regs->reg_cldma_l2timsr0;
+	else
+		addr = base + hw_regs->reg_cldma_l2rimsr0;
+
+	if (qno == ALLQ)
+		val = qno << type;
+	else
+		val = BIT(qno) << type;
+
+	mtk_pci_write32(drv_info->mdev, addr, val);
+}
+
+void mtk_cldma_unmask_intr(struct cldma_drv_info *drv_info, enum mtk_tx_rx dir,
+			   u32 qno, enum mtk_intr_type type)
+{
+	struct cldma_hw_regs *hw_regs;
+	int base;
+	u32 addr;
+	u32 val;
+
+	hw_regs = drv_info->hw_regs;
+	base = drv_info->base_addr;
+
+	if (dir == DIR_TX)
+		addr = base + hw_regs->reg_cldma_l2timcr0;
+	else
+		addr = base + hw_regs->reg_cldma_l2rimcr0;
+
+	if (qno == ALLQ)
+		val = qno << type;
+	else
+		val = BIT(qno) << type;
+
+	mtk_pci_write32(drv_info->mdev, addr, val);
+}
+
+void mtk_cldma_clr_intr_status(struct cldma_drv_info *drv_info, enum mtk_tx_rx dir,
+			       u32 qno, enum mtk_intr_type type)
+{
+	struct cldma_hw_regs *hw_regs;
+	struct mtk_md_dev *mdev;
+	int base;
+	u32 addr;
+	u32 val;
+
+	hw_regs = drv_info->hw_regs;
+	base = drv_info->base_addr;
+	mdev = drv_info->mdev;
+
+	if (type == QUEUE_ERROR) {
+		if (dir == DIR_TX) {
+			val = mtk_pci_read32(mdev, base + hw_regs->reg_cldma_l3tisar0);
+			mtk_pci_write32(mdev, base + hw_regs->reg_cldma_l3tisar0, val);
+			val = mtk_pci_read32(mdev, base + hw_regs->reg_cldma_l3tisar1);
+			mtk_pci_write32(mdev, base + hw_regs->reg_cldma_l3tisar1, val);
+			val = mtk_pci_read32(mdev, base + hw_regs->reg_cldma_l3tisar2);
+			mtk_pci_write32(mdev, base + hw_regs->reg_cldma_l3tisar2, val);
+		} else {
+			val = mtk_pci_read32(mdev, base + hw_regs->reg_cldma_l3risar0);
+			mtk_pci_write32(mdev, base + hw_regs->reg_cldma_l3risar0, val);
+			val = mtk_pci_read32(mdev, base + hw_regs->reg_cldma_l3risar1);
+			mtk_pci_write32(mdev, base + hw_regs->reg_cldma_l3risar1, val);
+		}
+	}
+
+	if (dir == DIR_TX)
+		addr = base + hw_regs->reg_cldma_l2tisar0;
+	else
+		addr = base + hw_regs->reg_cldma_l2risar0;
+
+	if (qno == ALLQ)
+		val = qno << type;
+	else
+		val = BIT(qno) << type;
+
+	mtk_pci_write32(mdev, addr, val);
+	val = mtk_pci_read32(mdev, addr);
+}
+
+u32 mtk_cldma_check_intr_status(struct cldma_drv_info *drv_info, enum mtk_tx_rx dir,
+				u32 qno, enum mtk_intr_type type)
+{
+	struct cldma_hw_regs *hw_regs;
+	u32 addr, val, sta;
+	int base;
+
+	hw_regs = drv_info->hw_regs;
+	base = drv_info->base_addr;
+
+	if (dir == DIR_TX)
+		addr = base + hw_regs->reg_cldma_l2tisar0;
+	else
+		addr = base + hw_regs->reg_cldma_l2risar0;
+
+	val = mtk_pci_read32(drv_info->mdev, addr);
+	if (val == LINK_ERROR_VAL)
+		sta = val;
+	else if (qno == ALLQ)
+		sta = (val >> type) & 0xFF;
+	else
+		sta = (val >> type) & BIT(qno);
+
+	return sta;
+}
+
+void mtk_cldma_start_queue(struct cldma_drv_info *drv_info, enum mtk_tx_rx dir, u32 qno)
+{
+	struct cldma_hw_regs *hw_regs;
+	u32 val = BIT(qno);
+	int base;
+	u32 addr;
+
+	hw_regs = drv_info->hw_regs;
+	base = drv_info->base_addr;
+
+	if (dir == DIR_TX)
+		addr = base + hw_regs->reg_cldma_ul_start_cmd;
+	else
+		addr = base + hw_regs->reg_cldma_so_start_cmd;
+
+	mtk_pci_write32(drv_info->mdev, addr, val);
+}
+
+void mtk_cldma_resume_queue(struct cldma_drv_info *drv_info, enum mtk_tx_rx dir, u32 qno)
+{
+	struct cldma_hw_regs *hw_regs;
+	u32 val = BIT(qno);
+	int base;
+	u32 addr;
+
+	hw_regs = drv_info->hw_regs;
+	base = drv_info->base_addr;
+
+	if (dir == DIR_TX)
+		addr = base + hw_regs->reg_cldma_ul_resume_cmd;
+	else
+		addr = base + hw_regs->reg_cldma_so_resume_cmd;
+
+	mtk_pci_write32(drv_info->mdev, addr, val);
+}
+
+u32 mtk_cldma_queue_status(struct cldma_drv_info *drv_info, enum mtk_tx_rx dir, u32 qno)
+{
+	struct cldma_hw_regs *hw_regs;
+	int base;
+	u32 addr;
+	u32 val;
+
+	hw_regs = drv_info->hw_regs;
+	base = drv_info->base_addr;
+
+	if (dir == DIR_TX)
+		addr = base + hw_regs->reg_cldma_ul_status;
+	else
+		addr = base + hw_regs->reg_cldma_so_status;
+
+	val = mtk_pci_read32(drv_info->mdev, addr);
+
+	if (qno == ALLQ || val == LINK_ERROR_VAL)
+		return val;
+
+	return val & BIT(qno);
+}
+
+u32 mtk_cldma_stop_queue(struct cldma_drv_info *drv_info, enum mtk_tx_rx dir, u32 qno)
+{
+	u32 val = (qno == ALLQ) ? qno : BIT(qno);
+	struct cldma_hw_regs *hw_regs;
+	unsigned int active;
+	int base;
+	u32 addr;
+
+	hw_regs = drv_info->hw_regs;
+	base = drv_info->base_addr;
+
+	if (dir == DIR_TX)
+		addr = base + hw_regs->reg_cldma_ul_stop_cmd;
+	else
+		addr = base + hw_regs->reg_cldma_so_stop_cmd;
+
+	mtk_pci_write32(drv_info->mdev, addr, val);
+
+	read_poll_timeout(mtk_cldma_queue_status, active,
+			  active == LINK_ERROR_VAL || !active,
+			  WAIT_QUEUE_STOP, WAIT_QUEUE_STOP * 10, false,
+			  drv_info, dir, qno);
+
+	return active;
+}
+
+void mtk_cldma_clear_ip_busy(struct cldma_drv_info *drv_info)
+{
+	mtk_pci_write32(drv_info->mdev, drv_info->base_addr +
+			drv_info->hw_regs->reg_cldma_ip_busy, 0x01);
+}
+
+void mtk_cldma_get_intr_status(struct cldma_drv_info *drv_info, u32 *tx_sta, u32 *rx_sta)
+{
+	struct cldma_hw_regs *hw_regs;
+	struct mtk_md_dev *mdev;
+	u32 tx_mask, rx_mask;
+	int base;
+
+	mdev = drv_info->mdev;
+	base = drv_info->base_addr;
+	hw_regs = drv_info->hw_regs;
+
+	*tx_sta = mtk_pci_read32(mdev, base + hw_regs->reg_cldma_l2tisar0);
+	tx_mask = mtk_pci_read32(mdev, base + hw_regs->reg_cldma_l2timr0);
+	*rx_sta = mtk_pci_read32(mdev, base + hw_regs->reg_cldma_l2risar0);
+	rx_mask = mtk_pci_read32(mdev, base + hw_regs->reg_cldma_l2rimr0);
+
+	*tx_sta = (*tx_sta) & (~tx_mask);
+	*rx_sta = (*rx_sta) & (~rx_mask);
+
+	if (*tx_sta) {
+		/* TX XFER_DONE and QUEUE_ERROR mask */
+		mtk_pci_write32(mdev, base + hw_regs->reg_cldma_l2timsr0, *tx_sta);
+		/* TX XFER_DONE clear */
+		mtk_pci_write32(mdev, base + hw_regs->reg_cldma_l2tisar0,
+				(*tx_sta) & (0xFF << QUEUE_XFER_DONE));
+	}
+
+	if (*rx_sta) {
+		/* RX XFER_DONE and QUEUE_ERROR mask */
+		mtk_pci_write32(mdev, base + hw_regs->reg_cldma_l2rimsr0, *rx_sta);
+		/* RX XFER_DONE clear */
+		mtk_pci_write32(mdev, base + hw_regs->reg_cldma_l2risar0,
+				(*rx_sta) & (0xFF << QUEUE_XFER_DONE));
+	}
+}
+
+u32 mtk_cldma_get_tx_start_addr(struct cldma_drv_info *drv_info, u32 qno)
+{
+	u32 addr, val;
+
+	addr = drv_info->base_addr + drv_info->hw_regs->reg_cldma_ul_start_addrl_0 +
+	       qno * HW_QUEUE_NUM;
+	val = mtk_pci_read32(drv_info->mdev, addr);
+
+	return val;
+}
+
+u64 mtk_cldma_get_rx_curr_addr(struct cldma_drv_info *drv_info, u32 qno)
+{
+	struct cldma_hw_regs *hw_regs;
+	u32 curr_addr_h, curr_addr_l;
+	struct mtk_md_dev *mdev;
+	u64 curr_addr;
+	int base;
+	u64 addr;
+
+	hw_regs = drv_info->hw_regs;
+	base = drv_info->base_addr;
+	mdev = drv_info->mdev;
+
+	addr = base + hw_regs->reg_cldma_so_current_addrh_0 +
+	       (u64)qno * HW_QUEUE_NUM;
+	curr_addr_h = mtk_pci_read32(mdev, addr);
+	addr = base + hw_regs->reg_cldma_so_current_addrl_0 +
+	       (u64)qno * HW_QUEUE_NUM;
+	curr_addr_l = mtk_pci_read32(mdev, addr);
+	curr_addr = ((u64)curr_addr_h << 32) | curr_addr_l;
+	if (curr_addr_h == LINK_ERROR_VAL && curr_addr_l == LINK_ERROR_VAL)
+		curr_addr = 0;
+	return curr_addr;
+}
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_cldma_drv.h b/drivers/net/wwan/t9xx/pcie/mtk_cldma_drv.h
new file mode 100644
index 000000000000..8763c23abf54
--- /dev/null
+++ b/drivers/net/wwan/t9xx/pcie/mtk_cldma_drv.h
@@ -0,0 +1,177 @@
+/* SPDX-License-Identifier: GPL-2.0-only
+ *
+ * Copyright (c) 2023, MediaTek Inc.
+ */
+
+#ifndef __MTK_CLDMA_DRV_H__
+#define __MTK_CLDMA_DRV_H__
+
+#define HW_QUEUE_NUM		(8)
+#define ALLQ			(0xFF)
+#define LINK_ERROR_VAL		(0xFFFFFFFF)
+#define CLDMA0_HW_ID		(0)
+#define CLDMA1_HW_ID		(1)
+#define CLDMA4_HW_ID		(4)
+
+struct cldma_hw_regs {
+	u8 cldma_rx_skb_pool_max_size;
+	u8 cldma_rx_skb_reload_threshold;
+	u8 tq_err_int_offset;
+	u8 tq_active_start_err_int_offset;
+	u8 rq_err_int_offset;
+	u8 rq_active_start_err_int_offset;
+	u16 reg_cldma_so_cfg;
+	u16 reg_cldma_so_start_addrl_0;
+	u16 reg_cldma_so_start_addrh_0;
+	u16 reg_cldma_so_current_addrl_0;
+	u16 reg_cldma_so_current_addrh_0;
+	u16 reg_cldma_so_status;
+	u16 reg_cldma_debug_id_en;
+	u16 reg_cldma_so_last_update_addrl_0;
+	u16 reg_cldma_so_last_update_addrh_0;
+	u16 reg_cldma_l2rimr0;
+	u16 reg_cldma_l2rimr1;
+	u16 reg_cldma_l2rimcr0;
+	u16 reg_cldma_l2rimcr1;
+	u16 reg_cldma_l2rimsr0;
+	u16 reg_cldma_l2rimsr1;
+	u16 reg_cldma_int_mask;
+	u16 reg_cldma4_int_mask;
+	u16 reg_cldma_slp_mem_ctl;
+	u16 reg_cldma_busy_mask;
+	u16 reg_cldma_ip_busy_to_pcie_mask;
+	u16 reg_cldma_ip_busy_to_pcie_mask_set;
+	u16 reg_cldma_ip_busy_to_pcie_mask_clr;
+	u16 reg_cldma_ip_busy_to_ap_mask;
+	u16 reg_cldma_ip_busy_to_ap_mask_set;
+	u16 reg_cldma_ip_busy_to_ap_mask_clr;
+	u16 reg_cldma_ip_busy_to_md_mask_set;
+	u16 reg_cldma_rx_work_to_reg_mask_set;
+	u16 reg_infra_rst4_set;
+	u16 reg_infra_rst4_clr;
+	u16 reg_infra_rst2_set;
+	u16 reg_infra_rst2_clr;
+	u16 reg_infra_rst0_set;
+	u16 reg_infra_rst0_clr;
+	u32 tq_err_int_bitmask;
+	u32 tq_active_start_err_int_bitmask;
+	u32 rq_err_int_bitmask;
+	u32 cldma0_base_addr;
+	u32 cldma1_base_addr;
+	u32 cldma4_base_addr;
+	u32 rq_active_start_err_int_bitmask;
+	u32 reg_cldma_ul_start_addrl_0;
+	u32 reg_cldma_ul_start_addrh_0;
+	u32 reg_cldma_ul_current_addrl_0;
+	u32 reg_cldma_ul_current_addrh_0;
+	u32 reg_cldma_ul_status;
+	u32 reg_cldma_ul_start_cmd;
+	u32 reg_cldma_ul_resume_cmd;
+	u32 reg_cldma_ul_stop_cmd;
+	u32 reg_cldma_ul_error;
+	u32 reg_cldma_ul_cfg;
+	u32 reg_cldma_ul_dummy_0;
+	u32 reg_cldma_so_error;
+	u32 reg_cldma_so_start_cmd;
+	u32 reg_cldma_so_resume_cmd;
+	u32 reg_cldma_so_stop_cmd;
+	u32 reg_cldma_so_dummy_0;
+	u32 reg_cldma_l2tisar0;
+	u32 reg_cldma_l2tisar1;
+	u32 reg_cldma_l2timr0;
+	u32 reg_cldma_l2timr1;
+	u32 reg_cldma_l2timcr0;
+	u32 reg_cldma_l2timcr1;
+	u32 reg_cldma_l2timsr0;
+	u32 reg_cldma_l2timsr1;
+	u32 reg_cldma_l2risar0;
+	u32 reg_cldma_l2risar1;
+	u32 reg_cldma_l3tisar0;
+	u32 reg_cldma_l3tisar1;
+	u32 reg_cldma_l3tisar2;
+	u32 reg_cldma_l3risar0;
+	u32 reg_cldma_l3risar1;
+	u32 reg_cldma_ip_busy;
+};
+
+enum mtk_ip_busy_src {
+	IP_BUSY_TXDONE = 0,
+	IP_BUSY_TXEMPTY = 8,
+	IP_BUSY_TXACTIVE = 16,
+	IP_BUSY_RXDONE = 24
+};
+
+enum mtk_intr_type {
+	QUEUE_XFER_DONE = 0,
+	QUEUE_EMPTY = 8,
+	QUEUE_ERROR = 16,
+	QUEUE_ACTIVE_START = 24,
+	INVALID_TYPE
+};
+
+enum mtk_tx_rx {
+	DIR_TX,
+	DIR_RX,
+	DIR_MAX
+};
+
+struct cldma_drv_info {
+	int hif_id;
+	int hw_id;
+	int base_addr;
+	int pci_ext_irq_id;
+	struct mtk_md_dev *mdev;
+	struct cldma_dev *cd;
+	struct txq *txq[HW_QUEUE_NUM];
+	struct rxq *rxq[HW_QUEUE_NUM];
+	struct dma_pool *gpd_dma_pool;
+	struct dma_pool *bd_dma_pool;
+	struct workqueue_struct *wq;
+	struct cldma_hw_regs *hw_regs;
+	struct cldma_drv_ops *drv_ops;
+};
+
+struct cldma_drv_ops {
+	void (*cldma_drv_init)(struct cldma_drv_info *drv_info);
+	void (*cldma_drv_reset)(struct cldma_drv_info *drv_info);
+	void (*cldma_setup_start_addr)(struct cldma_drv_info *drv_info, enum mtk_tx_rx dir,
+				       u32 qno, dma_addr_t addr);
+	void (*cldma_mask_intr)(struct cldma_drv_info *drv_info, enum mtk_tx_rx dir,
+				u32 qno, enum mtk_intr_type type);
+	void (*cldma_unmask_intr)(struct cldma_drv_info *drv_info, enum mtk_tx_rx dir,
+				  u32 qno, enum mtk_intr_type type);
+	void (*cldma_clr_intr_status)(struct cldma_drv_info *drv_info, enum mtk_tx_rx dir,
+				      u32 qno, enum mtk_intr_type type);
+	u32 (*cldma_check_intr_status)(struct cldma_drv_info *drv_info, enum mtk_tx_rx dir,
+				       u32 qno, enum mtk_intr_type type);
+	void (*cldma_start_queue)(struct cldma_drv_info *drv_info, enum mtk_tx_rx dir, u32 qno);
+	void (*cldma_resume_queue)(struct cldma_drv_info *drv_info, enum mtk_tx_rx dir, u32 qno);
+	u32 (*cldma_queue_status)(struct cldma_drv_info *drv_info, enum mtk_tx_rx dir, u32 qno);
+	u32 (*cldma_stop_queue)(struct cldma_drv_info *drv_info, enum mtk_tx_rx dir, u32 qno);
+	void (*cldma_clear_ip_busy)(struct cldma_drv_info *drv_info);
+	void (*cldma_get_intr_status)(struct cldma_drv_info *drv_info, u32 *tx_sta, u32 *rx_sta);
+	u32 (*cldma_get_tx_start_addr)(struct cldma_drv_info *drv_info, u32 qno);
+	u64 (*cldma_get_rx_curr_addr)(struct cldma_drv_info *drv_info, u32 qno);
+};
+
+void mtk_cldma_drv_init(struct cldma_drv_info *drv_info);
+void mtk_cldma_setup_start_addr(struct cldma_drv_info *drv_info, enum mtk_tx_rx dir,
+				u32 qno, dma_addr_t addr);
+void mtk_cldma_mask_intr(struct cldma_drv_info *drv_info, enum mtk_tx_rx dir,
+			 u32 qno, enum mtk_intr_type type);
+void mtk_cldma_unmask_intr(struct cldma_drv_info *drv_info, enum mtk_tx_rx dir,
+			   u32 qno, enum mtk_intr_type type);
+void mtk_cldma_clr_intr_status(struct cldma_drv_info *drv_info, enum mtk_tx_rx dir,
+			       u32 qno, enum mtk_intr_type type);
+u32 mtk_cldma_check_intr_status(struct cldma_drv_info *drv_info, enum mtk_tx_rx dir,
+				u32 qno, enum mtk_intr_type type);
+void mtk_cldma_start_queue(struct cldma_drv_info *drv_info, enum mtk_tx_rx dir, u32 qno);
+void mtk_cldma_resume_queue(struct cldma_drv_info *drv_info, enum mtk_tx_rx dir, u32 qno);
+u32 mtk_cldma_queue_status(struct cldma_drv_info *drv_info, enum mtk_tx_rx dir, u32 qno);
+u32 mtk_cldma_stop_queue(struct cldma_drv_info *drv_info, enum mtk_tx_rx dir, u32 qno);
+void mtk_cldma_clear_ip_busy(struct cldma_drv_info *drv_info);
+void mtk_cldma_get_intr_status(struct cldma_drv_info *drv_info, u32 *tx_sta, u32 *rx_sta);
+u32 mtk_cldma_get_tx_start_addr(struct cldma_drv_info *drv_info, u32 qno);
+u64 mtk_cldma_get_rx_curr_addr(struct cldma_drv_info *drv_info, u32 qno);
+
+#endif
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_cldma_drv_m9xx.c b/drivers/net/wwan/t9xx/pcie/mtk_cldma_drv_m9xx.c
new file mode 100644
index 000000000000..d9145d146a5c
--- /dev/null
+++ b/drivers/net/wwan/t9xx/pcie/mtk_cldma_drv_m9xx.c
@@ -0,0 +1,183 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (c) 2023, MediaTek Inc.
+ */
+
+#include <linux/delay.h>
+#include <linux/device.h>
+#include <linux/dma-mapping.h>
+#include <linux/dmapool.h>
+#include <linux/err.h>
+#include <linux/interrupt.h>
+#include <linux/kdev_t.h>
+#include <linux/kernel.h>
+#include <linux/kthread.h>
+#include <linux/list.h>
+#include <linux/module.h>
+#include <linux/mutex.h>
+#include <linux/netdevice.h>
+#include <linux/sched.h>
+#include <linux/skbuff.h>
+#include <linux/slab.h>
+#include <linux/timer.h>
+#include <linux/wait.h>
+#include <linux/workqueue.h>
+
+#include "mtk_cldma.h"
+#include "mtk_cldma_drv.h"
+#include "mtk_cldma_drv_m9xx.h"
+#include "mtk_dev.h"
+#include "mtk_pci.h"
+#include "mtk_pci_reg.h"
+#include "mtk_trans_ctrl.h"
+
+struct cldma_hw_regs mtk_cldma_regs_m9xx = {
+	.cldma0_base_addr = CLDMA0_BASE_ADDR,
+	.cldma1_base_addr = CLDMA1_BASE_ADDR,
+	.cldma4_base_addr = CLDMA4_BASE_ADDR,
+	.cldma_rx_skb_pool_max_size = CLDMA_RX_SKB_POOL_MAX_SIZE,
+	.cldma_rx_skb_reload_threshold = CLDMA_RX_SKB_RELOAD_THRESHOLD,
+	.tq_err_int_offset = TQ_ERR_INT_OFFSET,
+	.tq_err_int_bitmask = TQ_ERR_INT_BITMASK,
+	.tq_active_start_err_int_offset = TQ_ACTIVE_START_ERR_INT_OFFSET,
+	.tq_active_start_err_int_bitmask = TQ_ACTIVE_START_ERR_INT_BITMASK,
+	.rq_err_int_offset = RQ_ERR_INT_OFFSET,
+	.rq_err_int_bitmask = RQ_ERR_INT_BITMASK,
+	.rq_active_start_err_int_offset = RQ_ACTIVE_START_ERR_INT_OFFSET,
+	.rq_active_start_err_int_bitmask = RQ_ACTIVE_START_ERR_INT_BITMASK,
+	.reg_cldma_ul_start_addrl_0 = REG_CLDMA_UL_START_ADDRL_0,
+	.reg_cldma_ul_start_addrh_0 = REG_CLDMA_UL_START_ADDRH_0,
+	.reg_cldma_ul_current_addrl_0 = REG_CLDMA_UL_CURRENT_ADDRL_0,
+	.reg_cldma_ul_current_addrh_0 = REG_CLDMA_UL_CURRENT_ADDRH_0,
+	.reg_cldma_ul_status = REG_CLDMA_UL_STATUS,
+	.reg_cldma_ul_start_cmd = REG_CLDMA_UL_START_CMD,
+	.reg_cldma_ul_resume_cmd = REG_CLDMA_UL_RESUME_CMD,
+	.reg_cldma_ul_stop_cmd = REG_CLDMA_UL_STOP_CMD,
+	.reg_cldma_ul_error = REG_CLDMA_UL_ERROR,
+	.reg_cldma_ul_cfg = REG_CLDMA_UL_CFG,
+	.reg_cldma_ul_dummy_0 = REG_CLDMA_UL_DUMMY_0,
+	.reg_cldma_so_error = REG_CLDMA_SO_ERROR,
+	.reg_cldma_so_start_cmd = REG_CLDMA_SO_START_CMD,
+	.reg_cldma_so_resume_cmd = REG_CLDMA_SO_RESUME_CMD,
+	.reg_cldma_so_stop_cmd = REG_CLDMA_SO_STOP_CMD,
+	.reg_cldma_so_dummy_0 = REG_CLDMA_SO_DUMMY_0,
+	.reg_cldma_so_cfg = REG_CLDMA_SO_CFG,
+	.reg_cldma_so_start_addrl_0 = REG_CLDMA_SO_START_ADDRL_0,
+	.reg_cldma_so_start_addrh_0 = REG_CLDMA_SO_START_ADDRH_0,
+	.reg_cldma_so_current_addrl_0 = REG_CLDMA_SO_CUR_ADDRL_0,
+	.reg_cldma_so_current_addrh_0 = REG_CLDMA_SO_CUR_ADDRH_0,
+	.reg_cldma_so_status = REG_CLDMA_SO_STATUS,
+	.reg_cldma_debug_id_en = REG_CLDMA_DEBUG_ID_EN,
+	.reg_cldma_so_last_update_addrl_0 = REG_CLDMA_SO_LAST_UPDATE_ADDRL_0,
+	.reg_cldma_so_last_update_addrh_0 = REG_CLDMA_SO_LAST_UPDATE_ADDRH_0,
+	.reg_cldma_l2tisar0 = REG_CLDMA_L2TISAR0,
+	.reg_cldma_l2tisar1 = REG_CLDMA_L2TISAR1,
+	.reg_cldma_l2timr0 = REG_CLDMA_L2TIMR0,
+	.reg_cldma_l2timr1 = REG_CLDMA_L2TIMR1,
+	.reg_cldma_l2timcr0 = REG_CLDMA_L2TIMCR0,
+	.reg_cldma_l2timcr1 = REG_CLDMA_L2TIMCR1,
+	.reg_cldma_l2timsr0 = REG_CLDMA_L2TIMSR0,
+	.reg_cldma_l2timsr1 = REG_CLDMA_L2TIMSR1,
+	.reg_cldma_l3tisar0 = REG_CLDMA_L3TISAR0,
+	.reg_cldma_l3tisar1 = REG_CLDMA_L3TISAR1,
+	.reg_cldma_l3tisar2 = REG_CLDMA_L3TISAR2,
+	.reg_cldma_l2risar0 = REG_CLDMA_L2RISAR0,
+	.reg_cldma_l2risar1 = REG_CLDMA_L2RISAR1,
+	.reg_cldma_l2rimr0 = REG_CLDMA_L2RIMR0,
+	.reg_cldma_l2rimr1 = REG_CLDMA_L2RIMR1,
+	.reg_cldma_l2rimcr0 = REG_CLDMA_L2RIMCR0,
+	.reg_cldma_l2rimcr1 = REG_CLDMA_L2RIMCR1,
+	.reg_cldma_l2rimsr0 = REG_CLDMA_L2RIMSR0,
+	.reg_cldma_l2rimsr1 = REG_CLDMA_L2RIMSR1,
+	.reg_cldma_l3risar0 = REG_CLDMA_L3RISAR0,
+	.reg_cldma_l3risar1 = REG_CLDMA_L3RISAR1,
+	.reg_cldma_ip_busy = REG_CLDMA_IP_BUSY,
+	.reg_cldma_int_mask = REG_CLDMA_INT_EAP_USIP_MASK,
+	.reg_cldma4_int_mask = REG_CLDMA_INT_WF_MASK,
+	.reg_cldma_ip_busy_to_pcie_mask = REG_CLDMA_IP_BUSY_TO_PCIE_MASK,
+	.reg_cldma_ip_busy_to_pcie_mask_set = REG_CLDMA_IP_BUSY_TO_PCIE_MASK_SET,
+	.reg_cldma_ip_busy_to_pcie_mask_clr = REG_CLDMA_IP_BUSY_TO_PCIE_MASK_CLR,
+	.reg_cldma_ip_busy_to_ap_mask = REG_CLDMA_IP_BUSY_TO_AP_MASK,
+	.reg_cldma_ip_busy_to_ap_mask_set = REG_CLDMA_IP_BUSY_TO_AP_MASK_SET,
+	.reg_cldma_ip_busy_to_ap_mask_clr = REG_CLDMA_IP_BUSY_TO_AP_MASK_CLR,
+	.reg_cldma_ip_busy_to_md_mask_set = REG_CLDMA_IP_BUSY_TO_MD_MASK_SET,
+	.reg_cldma_rx_work_to_reg_mask_set = REG_CLDMA_RX_WORK_TO_REG_MASK_SET,
+	.reg_infra_rst0_set = REG_INFRA_RST0_SET,
+	.reg_infra_rst0_clr = REG_INFRA_RST0_CLR,
+};
+
+static void mtk_cldma_drv_init_m9xx(struct cldma_drv_info *drv_info)
+{
+	struct cldma_hw_regs *hw_regs;
+	struct mtk_md_dev *mdev;
+	int base;
+	u32 val;
+
+	mdev = drv_info->mdev;
+	base = drv_info->base_addr;
+	hw_regs = drv_info->hw_regs;
+
+	/* set CLDMA to 64 bit mode GPD */
+	val = mtk_pci_read32(mdev, base + hw_regs->reg_cldma_ul_cfg);
+
+	val = (val & (~(0x7 << 5))) | ((0x4) << 5);
+	mtk_pci_write32(mdev, base + hw_regs->reg_cldma_ul_cfg, val);
+
+	val = mtk_pci_read32(mdev, base + hw_regs->reg_cldma_so_cfg);
+	val = (val & (~(0x7 << 10))) | ((0x4) << 10) | (1 << 2);
+	mtk_pci_write32(mdev, base + hw_regs->reg_cldma_so_cfg, val);
+
+	mtk_pci_write32(mdev, base + hw_regs->reg_cldma_rx_work_to_reg_mask_set, ALLQ);
+
+	mtk_pci_write32(mdev, base + hw_regs->reg_cldma_ip_busy_to_pcie_mask_set,
+			ALLQ << 16);
+	mtk_pci_write32(mdev, base + hw_regs->reg_cldma_ip_busy_to_pcie_mask_clr,
+			ALLQ << 24);
+
+	/* enable interrupt to PCIe */
+	if (drv_info->hw_id == CLDMA4_HW_ID)
+		mtk_pci_write32(mdev, base + hw_regs->reg_cldma4_int_mask, 0);
+	else
+		mtk_pci_write32(mdev, base + hw_regs->reg_cldma_int_mask, 0);
+
+	/* disable illegal memory check */
+	mtk_pci_write32(mdev, base + hw_regs->reg_cldma_ul_dummy_0, 1);
+	mtk_pci_write32(mdev, base + hw_regs->reg_cldma_so_dummy_0, 1);
+}
+
+static void mtk_cldma_drv_reset_m9xx(struct cldma_drv_info *drv_info)
+{
+	struct cldma_hw_regs *hw_regs;
+	struct mtk_md_dev *mdev;
+	u32 val;
+
+	mdev = drv_info->mdev;
+	hw_regs = drv_info->hw_regs;
+
+	val = mtk_pci_read32(mdev, REG_DEV_INFRA_BASE + hw_regs->reg_infra_rst0_set);
+
+	val |= 1 << (REG_CLDMA0_RST_SET_BIT + drv_info->hw_id);
+	mtk_pci_write32(mdev, REG_DEV_INFRA_BASE + hw_regs->reg_infra_rst0_set, val);
+	udelay(1);
+	val = mtk_pci_read32(mdev, REG_DEV_INFRA_BASE + hw_regs->reg_infra_rst0_clr);
+	val |= 1 << (REG_CLDMA0_RST_CLR_BIT + drv_info->hw_id);
+	mtk_pci_write32(mdev, REG_DEV_INFRA_BASE + hw_regs->reg_infra_rst0_clr, val);
+}
+
+struct cldma_drv_ops cldma_drv_ops_m9xx = {
+	.cldma_drv_init = mtk_cldma_drv_init_m9xx,
+	.cldma_drv_reset = mtk_cldma_drv_reset_m9xx,
+	.cldma_setup_start_addr = mtk_cldma_setup_start_addr,
+	.cldma_mask_intr = mtk_cldma_mask_intr,
+	.cldma_unmask_intr = mtk_cldma_unmask_intr,
+	.cldma_clr_intr_status = mtk_cldma_clr_intr_status,
+	.cldma_check_intr_status = mtk_cldma_check_intr_status,
+	.cldma_start_queue = mtk_cldma_start_queue,
+	.cldma_resume_queue = mtk_cldma_resume_queue,
+	.cldma_queue_status = mtk_cldma_queue_status,
+	.cldma_stop_queue = mtk_cldma_stop_queue,
+	.cldma_clear_ip_busy = mtk_cldma_clear_ip_busy,
+	.cldma_get_intr_status = mtk_cldma_get_intr_status,
+	.cldma_get_tx_start_addr = mtk_cldma_get_tx_start_addr,
+	.cldma_get_rx_curr_addr = mtk_cldma_get_rx_curr_addr,
+};
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_cldma_drv_m9xx.h b/drivers/net/wwan/t9xx/pcie/mtk_cldma_drv_m9xx.h
new file mode 100644
index 000000000000..2c63c43ff065
--- /dev/null
+++ b/drivers/net/wwan/t9xx/pcie/mtk_cldma_drv_m9xx.h
@@ -0,0 +1,103 @@
+/* SPDX-License-Identifier: GPL-2.0-only
+ *
+ * Copyright (c) 2023, MediaTek Inc.
+ */
+
+#ifndef __MTK_CLDMA_DRV_M9XX_H__
+#define __MTK_CLDMA_DRV_M9XX_H__
+
+#define CLDMA0_BASE_ADDR				(0x1021C000)
+#define CLDMA1_BASE_ADDR				(0x1021E000)
+#define CLDMA4_BASE_ADDR				(0x10224000)
+
+#define CLDMA_RX_SKB_POOL_MAX_SIZE			(64)
+#define CLDMA_RX_SKB_RELOAD_THRESHOLD			(16)
+
+/* L2TISAR0 */
+#define TQ_ERR_INT_OFFSET				(16)
+#define TQ_ERR_INT_BITMASK				(0x00FF0000)
+#define TQ_ACTIVE_START_ERR_INT_OFFSET			(24)
+#define TQ_ACTIVE_START_ERR_INT_BITMASK			(0xFF000000)
+
+/* L2RISAR0 */
+#define RQ_ERR_INT_OFFSET				(16)
+#define RQ_ERR_INT_BITMASK				(0x00FF0000)
+#define RQ_ACTIVE_START_ERR_INT_OFFSET			(24)
+#define RQ_ACTIVE_START_ERR_INT_BITMASK			(0xFF000000)
+
+/* CLDMA IN(Tx) */
+#define REG_CLDMA_UL_START_ADDRL_0			(0x0004)
+#define REG_CLDMA_UL_START_ADDRH_0			(0x0008)
+#define REG_CLDMA_UL_CURRENT_ADDRL_0			(0x0044)
+#define REG_CLDMA_UL_CURRENT_ADDRH_0			(0x0048)
+#define REG_CLDMA_UL_STATUS				(0x0084)
+#define REG_CLDMA_UL_START_CMD				(0x0088)
+#define REG_CLDMA_UL_RESUME_CMD				(0x008C)
+#define REG_CLDMA_UL_STOP_CMD				(0x0090)
+#define REG_CLDMA_UL_ERROR				(0x0094)
+#define REG_CLDMA_UL_CFG				(0x0098)
+#define REG_CLDMA_UL_DUMMY_0				(0x009C)
+
+/* CLDMA OUT(Rx) */
+#define REG_CLDMA_SO_ERROR				(0x0400 + 0x0100)
+#define REG_CLDMA_SO_START_CMD				(0x0400 + 0x01BC)
+#define REG_CLDMA_SO_RESUME_CMD				(0x0400 + 0x01C0)
+#define REG_CLDMA_SO_STOP_CMD				(0x0400 + 0x01C4)
+#define REG_CLDMA_SO_DUMMY_0				(0x0400 + 0x0108)
+#define REG_CLDMA_SO_CFG				(0x0400 + 0x0004)
+#define REG_CLDMA_SO_START_ADDRL_0			(0x0400 + 0x0078)
+#define REG_CLDMA_SO_START_ADDRH_0			(0x0400 + 0x007C)
+#define REG_CLDMA_SO_CUR_ADDRL_0			(0x0400 + 0x00B8)
+#define REG_CLDMA_SO_CUR_ADDRH_0			(0x0400 + 0x00BC)
+#define REG_CLDMA_SO_STATUS				(0x0400 + 0x00F8)
+#define REG_CLDMA_DEBUG_ID_EN				(0x0400 + 0x00FC)
+#define REG_CLDMA_SO_LAST_UPDATE_ADDRL_0		(0x0400 + 0x01C8)
+#define REG_CLDMA_SO_LAST_UPDATE_ADDRH_0		(0x0400 + 0x01CC)
+
+/* CLDMA MISC */
+#define REG_CLDMA_L2TISAR0				(0x0800 + 0x0010)
+#define REG_CLDMA_L2TISAR1				(0x0800 + 0x0014)
+#define REG_CLDMA_L2TIMR0				(0x0800 + 0x0018)
+#define REG_CLDMA_L2TIMR1				(0x0800 + 0x001C)
+#define REG_CLDMA_L2TIMCR0				(0x0800 + 0x0020)
+#define REG_CLDMA_L2TIMCR1				(0x0800 + 0x0024)
+#define REG_CLDMA_L2TIMSR0				(0x0800 + 0x0028)
+#define REG_CLDMA_L2TIMSR1				(0x0800 + 0x002C)
+#define REG_CLDMA_L3TISAR0				(0x0800 + 0x0030)
+#define REG_CLDMA_L3TISAR1				(0x0800 + 0x0034)
+#define REG_CLDMA_L2RISAR0				(0x0800 + 0x0050)
+#define REG_CLDMA_L2RISAR1				(0x0800 + 0x0054)
+#define REG_CLDMA_L3RISAR0				(0x0800 + 0x0070)
+#define REG_CLDMA_L3RISAR1				(0x0800 + 0x0074)
+#define REG_CLDMA_IP_BUSY				(0x0800 + 0x00B4)
+#define REG_CLDMA_L3TISAR2				(0x0800 + 0x00C0)
+
+#define REG_CLDMA_L2RIMR0				(0x0800 + 0x00E8)
+#define REG_CLDMA_L2RIMR1				(0x0800 + 0x00EC)
+#define REG_CLDMA_L2RIMCR0				(0x0800 + 0x00F0)
+#define REG_CLDMA_L2RIMCR1				(0x0800 + 0x00F4)
+#define REG_CLDMA_L2RIMSR0				(0x0800 + 0x00F8)
+#define REG_CLDMA_L2RIMSR1				(0x0800 + 0x00FC)
+
+#define REG_CLDMA_INT_EAP_USIP_MASK			(0x0800 + 0x011C)
+#define REG_CLDMA_INT_WF_MASK				(0x0800 + 0x0120)
+#define REG_CLDMA_RQ1_GPD_DONE_CNT			(0x0800 + 0x0174)
+#define REG_CLDMA_TQ1_GPD_DONE_CNT			(0x0800 + 0x0184)
+
+#define REG_CLDMA_IP_BUSY_TO_PCIE_MASK			(0x0800 + 0x0194)
+#define REG_CLDMA_IP_BUSY_TO_PCIE_MASK_SET		(0x0800 + 0x0198)
+#define REG_CLDMA_IP_BUSY_TO_PCIE_MASK_CLR		(0x0800 + 0x019C)
+
+#define REG_CLDMA_IP_BUSY_TO_AP_MASK			(0x0800 + 0x0200)
+#define REG_CLDMA_IP_BUSY_TO_AP_MASK_SET		(0x0800 + 0x0204)
+#define REG_CLDMA_IP_BUSY_TO_AP_MASK_CLR		(0x0800 + 0x0208)
+#define REG_CLDMA_IP_BUSY_TO_MD_MASK_SET		(0x0800 + 0x0210)
+#define REG_CLDMA_RX_WORK_TO_REG_MASK_SET		(0x0800 + 0x021C)
+
+/* CLDMA RESET */
+#define REG_INFRA_RST0_SET				(0x120)
+#define REG_INFRA_RST0_CLR				(0x124)
+#define REG_CLDMA0_RST_SET_BIT				(8)
+#define REG_CLDMA0_RST_CLR_BIT				(8)
+
+#endif
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_ctrl_cfg_m9xx.c b/drivers/net/wwan/t9xx/pcie/mtk_ctrl_cfg_m9xx.c
new file mode 100644
index 000000000000..c1bb787ee981
--- /dev/null
+++ b/drivers/net/wwan/t9xx/pcie/mtk_ctrl_cfg_m9xx.c
@@ -0,0 +1,24 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (c) 2022, MediaTek Inc.
+ */
+
+#include "mtk_cldma.h"
+#include "mtk_trans_ctrl.h"
+
+#define TRB_SRV_NUM	(1)
+
+static const int mtk_srv_cfg_m9xx[NR_CLDMA][HW_QUE_NUM] = {
+	{0},
+	{0},
+};
+
+static const struct queue_info mtk_queue_info_m9xx[] = {
+};
+
+struct mtk_ctrl_info mtk_ctrl_info_m9xx = {
+	.queue_info = (struct queue_info *)mtk_queue_info_m9xx,
+	.queue_info_num = ARRAY_SIZE(mtk_queue_info_m9xx),
+	.srv_cfg = (int **)mtk_srv_cfg_m9xx,
+	.trb_srv_num = TRB_SRV_NUM,
+};
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_pci.c b/drivers/net/wwan/t9xx/pcie/mtk_pci.c
index 9588635fab3d..da2a6926b801 100644
--- a/drivers/net/wwan/t9xx/pcie/mtk_pci.c
+++ b/drivers/net/wwan/t9xx/pcie/mtk_pci.c
@@ -877,6 +877,28 @@ static void mtk_pci_free_irq(struct mtk_md_dev *mdev)
 	pci_free_irq_vectors(pdev);
 }
 
+static int mtk_pci_dev_init(struct mtk_md_dev *mdev)
+{
+	int ret;
+
+	ret = mtk_trans_ctrl_init(mdev);
+	if (ret) {
+		dev_err(mdev->dev, "Failed to initialize control plane: %d\n", ret);
+		return ret;
+	}
+
+	return 0;
+}
+
+static void mtk_pci_dev_exit(struct mtk_md_dev *mdev)
+{
+	mtk_trans_ctrl_exit(mdev);
+}
+
+static int mtk_pci_dev_start(struct mtk_md_dev *mdev)
+{
+	return 0;
+}
 static const struct mtk_dev_ops pci_hw_ops = {
 	.get_dev_state = mtk_pci_get_dev_state,
 	.ack_dev_state = mtk_pci_ack_dev_state,
@@ -953,6 +975,12 @@ static int mtk_pci_probe(struct pci_dev *pdev, const struct pci_device_id *id)
 	if (ret)
 		goto free_mhccif;
 
+	ret = mtk_pci_dev_init(mdev);
+	if (ret) {
+		dev_err(mdev->dev, "Failed to init dev.\n");
+		goto free_irq;
+	}
+
 	pci_set_master(pdev);
 	mtk_pci_unmask_irq(mdev, priv->mhccif_irq_id);
 
@@ -969,10 +997,20 @@ static int mtk_pci_probe(struct pci_dev *pdev, const struct pci_device_id *id)
 		goto clear_master;
 	}
 
+	ret = mtk_pci_dev_start(mdev);
+	if (ret) {
+		dev_err(mdev->dev, "Failed to start dev.\n");
+		goto free_saved_state;
+	}
+
 	return 0;
 
+free_saved_state:
+	pci_load_and_free_saved_state(pdev, &priv->saved_state);
 clear_master:
 	pci_clear_master(pdev);
+	mtk_pci_dev_exit(mdev);
+free_irq:
 	mtk_pci_free_irq(mdev);
 free_mhccif:
 	mtk_mhccif_exit(mdev);
@@ -996,6 +1034,7 @@ static void mtk_pci_remove(struct pci_dev *pdev)
 	}
 
 	pci_clear_master(pdev);
+	mtk_pci_dev_exit(mdev);
 	mtk_pci_free_irq(mdev);
 	mtk_mhccif_exit(mdev);
 	pci_load_and_free_saved_state(pdev, &priv->saved_state);
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_pci_reg.h b/drivers/net/wwan/t9xx/pcie/mtk_pci_reg.h
index 3f0667e8a846..73299ae03f89 100644
--- a/drivers/net/wwan/t9xx/pcie/mtk_pci_reg.h
+++ b/drivers/net/wwan/t9xx/pcie/mtk_pci_reg.h
@@ -21,6 +21,7 @@
 #define REG_IMASK_HOST_MSIX_SET_GRP0_0		0x3000
 #define REG_IMASK_HOST_MSIX_CLR_GRP0_0		0x3080
 #define REG_IMASK_HOST_MSIX_GRP0_0		0x3100
+#define REG_DEV_INFRA_BASE			0x10001000
 
 /* mhccif registers */
 #define MHCCIF_RC2EP_SW_BSY			0x4
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c b/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c
new file mode 100644
index 000000000000..55297cfcdbc6
--- /dev/null
+++ b/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c
@@ -0,0 +1,541 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (c) 2022, MediaTek Inc.
+ */
+
+#include <linux/device.h>
+#include <linux/freezer.h>
+#include <linux/hashtable.h>
+#include <linux/kthread.h>
+#include <linux/list.h>
+#include <linux/nospec.h>
+#include <linux/sched.h>
+#include <linux/wait.h>
+
+#include "mtk_cldma.h"
+#include "mtk_ctrl_plane.h"
+#include "mtk_dev.h"
+#include "mtk_pci.h"
+#include "mtk_trans_ctrl.h"
+
+#define MTK_DFLT_PORT_NAME_LEN			(20)
+
+static struct mtk_ctrl_info_desc mtk_ctrl_info_tbl[] = {
+	{2304, &ctrl_info_name(m9xx)},
+	{0, NULL},
+};
+
+#define QUEUE_CHL_MASK	0xFFFF
+
+static bool mtk_queue_list_is_full(struct mtk_ctrl_trans *trans, struct queue_info *que)
+{
+	return trans->trans_list[que->hif_id].skb_list[que->txqno].qlen >= SKB_LIST_MAX_LEN;
+}
+
+static bool mtk_ctrl_chs_is_busy_or_empty(struct trb_srv *srv)
+{
+	struct srv_que *srv_que;
+	int i;
+
+	for (i = 0; i < NR_CLDMA; i++)
+		list_for_each_entry(srv_que, &srv->srv_q_list[i], list)
+			if (!skb_queue_empty(&srv->trans->trans_list[i].skb_list[srv_que->qno]) &&
+			    mtk_cldma_get_tx_budget(srv->trans->dev, i, srv_que->qno))
+				return false;
+
+	return true;
+}
+
+static void mtk_ctrl_ch_flush(struct sk_buff_head *skb_list)
+{
+	struct sk_buff *skb;
+	struct trb *trb;
+
+	while (!skb_queue_empty(skb_list)) {
+		skb = skb_dequeue(skb_list);
+		trb = (struct trb *)skb->cb;
+		trb->status = -EIO;
+		trb->trb_complete(skb);
+	}
+}
+
+static void mtk_ctrl_chs_flush(struct trb_srv *srv)
+{
+	struct srv_que *srv_que;
+	int i;
+
+	for (i = 0; i < NR_CLDMA; i++)
+		list_for_each_entry(srv_que, &srv->srv_q_list[i], list)
+			mtk_ctrl_ch_flush(&srv->trans->trans_list[i].skb_list[srv_que->qno]);
+}
+
+static int mtk_ch_status_check(struct mtk_ctrl_trans *trans, struct sk_buff *skb)
+{
+	struct trb *trb = (struct trb *)skb->cb;
+	struct trb_open_priv *trb_open_priv;
+	struct queue_info *que;
+	int ret = 0;
+
+	que = radix_tree_lookup(&trans->queue_tbl, trb->channel_id & QUEUE_CHL_MASK);
+
+	switch (trb->cmd) {
+	case TRB_CMD_ENABLE:
+		trb_open_priv = (struct trb_open_priv *)skb->data;
+		trb_open_priv->log_rg_offset = que->log_rg_offset;
+		trans->usr_cnt[que->hif_id][que->txqno]++;
+		if (trans->usr_cnt[que->hif_id][que->txqno] == 1)
+			break;
+		trb_open_priv->tx_mtu = que->tx_mtu;
+		trb_open_priv->rx_mtu = que->rx_mtu;
+		trb_open_priv->tx_frag_size = que->tx_frag_size;
+		trb_open_priv->rx_frag_size = que->rx_frag_size;
+		if (mtk_cldma_check_ch_cfg(trans->dev, que)) {
+			trb->status = -EINVAL;
+			ret = -EINVAL;
+		} else {
+			trb->status = -EBUSY;
+			ret = -EBUSY;
+		}
+		trb->trb_complete(skb);
+		break;
+	case TRB_CMD_DISABLE:
+		if (trans->usr_cnt[que->hif_id][que->txqno] > 0) {
+			trans->usr_cnt[que->hif_id][que->txqno]--;
+			if (!trans->usr_cnt[que->hif_id][que->txqno])
+				break;
+		}
+		trb->status = -EBUSY;
+		trb->trb_complete(skb);
+		ret = -EBUSY;
+		break;
+	default:
+		dev_err((trans->mdev)->dev, "Invalid trb command(%d)\n", trb->cmd);
+		ret = -EINVAL;
+		break;
+	}
+	return ret;
+}
+
+static void mtk_ctrl_trb_handler(struct trb_srv *srv, struct trans_list *trans_list, u32 qno)
+{
+	struct sk_buff_head *skb_list = &trans_list->skb_list[qno];
+	struct mtk_ctrl_trans *trans = srv->trans;
+	struct sk_buff *skb, *skb_next;
+	struct trb *trb, *trb_next;
+	bool kick = false;
+	int loop = 0;
+	int err;
+
+	do {
+		skb = skb_peek(skb_list);
+		if (!skb)
+			break;
+		trb = (struct trb *)skb->cb;
+
+		switch (trb->cmd) {
+		case TRB_CMD_ENABLE:
+		case TRB_CMD_DISABLE:
+			skb_unlink(skb, skb_list);
+			err = mtk_ch_status_check(trans, skb);
+			if (!err) {
+				kick = true;
+				if (trb->cmd == TRB_CMD_DISABLE)
+					mtk_ctrl_ch_flush(skb_list);
+			}
+			break;
+		case TRB_CMD_TX:
+			err = mtk_cldma_submit_tx(trans->dev, skb);
+			if (err) {
+				if (trans_list->tx_burst_cnt[qno]) {
+					kick = true;
+					break;
+				}
+				if (err == -EAGAIN)
+					return;
+
+				skb_unlink(skb, skb_list);
+				trb->status = err;
+				trb->trb_complete(skb);
+				break;
+			}
+
+			trans_list->tx_burst_cnt[qno]++;
+			if (trans_list->tx_burst_cnt[qno] >= TX_BURST_MAX_CNT ||
+			    skb_queue_is_last(skb_list, skb)) {
+				kick = true;
+			} else {
+				skb_next = skb_peek_next(skb, skb_list);
+				trb_next = (struct trb *)skb_next->cb;
+				if (trb_next->cmd != TRB_CMD_TX)
+					kick = true;
+			}
+
+			skb_unlink(skb, skb_list);
+			break;
+		default:
+			skb_unlink(skb, skb_list);
+		}
+
+		if (kick) {
+			mtk_cldma_trb_process(trans->dev, skb);
+			trans_list->tx_burst_cnt[qno] = 0;
+			kick = false;
+		}
+
+		loop++;
+	} while (loop < TRB_NUM_PER_ROUND);
+}
+
+static void mtk_ctrl_trb_process(struct trb_srv *srv)
+{
+	struct mtk_ctrl_trans *trans = srv->trans;
+	struct srv_que *srv_que;
+	int i;
+
+	for (i = 0; i < NR_CLDMA; i++)
+		list_for_each_entry(srv_que, &srv->srv_q_list[i], list)
+			mtk_ctrl_trb_handler(srv, &trans->trans_list[i], srv_que->qno);
+}
+
+static int mtk_ctrl_trb_thread(void *args)
+{
+	struct trb_srv *srv = args;
+
+	for (;;) {
+		wait_event_interruptible(srv->trb_waitq,
+					 !mtk_ctrl_chs_is_busy_or_empty(srv) ||
+					 kthread_should_stop() || kthread_should_park());
+		if (kthread_should_stop())
+			break;
+
+		if (kthread_should_park())
+			kthread_parkme();
+
+		do {
+			mtk_ctrl_trb_process(srv);
+			cond_resched();
+		} while (!mtk_ctrl_chs_is_busy_or_empty(srv) && !kthread_should_stop() &&
+			 !kthread_should_park());
+	}
+	mtk_ctrl_chs_flush(srv);
+	return 0;
+}
+
+static int mtk_ctrl_trb_srv_init(struct mtk_ctrl_trans *trans)
+{
+	struct srv_que *srv_que;
+	struct trb_srv *srv;
+	int i, j;
+	int ret;
+
+	for (i = 0; i < trans->trb_srv_num; i++) {
+		srv = kzalloc_obj(*srv);
+		if (!srv) {
+			ret = -ENOMEM;
+			goto err_free_srv;
+		}
+
+		srv->trans = trans;
+		srv->srv_id = i;
+		trans->trb_srv[i] = srv;
+
+		init_waitqueue_head(&srv->trb_waitq);
+		for (j = 0; j < NR_CLDMA; j++)
+			INIT_LIST_HEAD(&srv->srv_q_list[j]);
+	}
+
+	for (i = 0; i < NR_CLDMA; i++)
+		for (j = 0; j < HW_QUE_NUM; j++) {
+			if (trans->srv_cfg[i][j] < 0 ||
+			    trans->srv_cfg[i][j] >= trans->trb_srv_num)
+				trans->srv_cfg[i][j] = 0;
+			srv_que = kzalloc_obj(*srv_que);
+			if (!srv_que) {
+				ret = -ENOMEM;
+				goto err_free_srv_que;
+			}
+			srv_que->hif_id = i;
+			srv_que->qno = j;
+			list_add_tail(&srv_que->list,
+				      &trans->trb_srv[trans->srv_cfg[i][j]]->srv_q_list[i]);
+		}
+
+	for (i = 0; i < trans->trb_srv_num; i++) {
+		trans->trb_srv[i]->trb_thread = kthread_run(mtk_ctrl_trb_thread, trans->trb_srv[i],
+							    "mtk_trb_srv%d_%s", i,
+							    trans->mdev->dev_str);
+		if (IS_ERR(trans->trb_srv[i]->trb_thread)) {
+			ret = PTR_ERR(trans->trb_srv[i]->trb_thread);
+			trans->trb_srv[i]->trb_thread = NULL;
+			goto err_stop_kthread;
+		}
+	}
+
+	return 0;
+err_stop_kthread:
+	while (--i >= 0)
+		kthread_stop(trans->trb_srv[i]->trb_thread);
+err_free_srv_que:
+	for (i = 0; i < trans->trb_srv_num; i++) {
+		for (j = 0; j < NR_CLDMA; j++) {
+			struct srv_que *next_srv_que;
+
+			list_for_each_entry_safe(srv_que, next_srv_que,
+						 &trans->trb_srv[i]->srv_q_list[j], list) {
+				list_del(&srv_que->list);
+				kfree(srv_que);
+			}
+		}
+	}
+err_free_srv:
+	for (i = 0; i < trans->trb_srv_num; i++) {
+		if (!trans->trb_srv[i])
+			break;
+		kfree(trans->trb_srv[i]);
+		trans->trb_srv[i] = NULL;
+	}
+
+	return ret;
+}
+
+static void mtk_ctrl_trb_srv_exit(struct mtk_ctrl_trans *trans)
+{
+	struct srv_que *srv_que, *next_srv_que;
+	struct trb_srv *srv;
+	int i, j;
+
+	for (i = 0; i < trans->trb_srv_num; i++) {
+		srv = trans->trb_srv[i];
+		kthread_stop(srv->trb_thread);
+		for (j = 0; j < NR_CLDMA; j++) {
+			list_for_each_entry_safe(srv_que, next_srv_que,
+						 &trans->trb_srv[i]->srv_q_list[j], list) {
+				list_del(&srv_que->list);
+				kfree(srv_que);
+			}
+		}
+		kfree(srv);
+		trans->trb_srv[i] = NULL;
+	}
+}
+
+static void mtk_ctrl_remove_radix_tree(struct mtk_ctrl_trans *trans)
+{
+	struct radix_tree_iter iter;
+	struct queue_info *queue;
+	void __rcu **slot;
+
+	radix_tree_for_each_slot(slot, &trans->queue_tbl, &iter, 0) {
+		queue = radix_tree_deref_slot(slot);
+		if (!queue)
+			continue;
+		radix_tree_delete(&trans->queue_tbl, iter.index);
+		kfree(queue);
+	}
+}
+
+static int mtk_pcie_hif_init(struct mtk_md_dev *mdev)
+{
+	struct mtk_ctrl_blk *ctrl_blk = mdev->ctrl_blk;
+	struct queue_info *queue, *queue_info;
+	struct mtk_ctrl_trans *trans;
+	int i, j;
+	int ret;
+
+	trans = ctrl_blk->ctrl_hw_priv;
+	trans->ctrl_blk = ctrl_blk;
+	queue_info = trans->queue_info;
+
+	INIT_RADIX_TREE(&trans->queue_tbl, GFP_KERNEL);
+	for (i = 0; i < trans->queue_info_num; i++) {
+		queue = kmemdup(queue_info + i, sizeof(*queue), GFP_KERNEL);
+		if (!queue) {
+			ret = -ENOMEM;
+			goto err_free_radix_tree;
+		}
+		if (queue->txqno >= HW_QUE_NUM || queue->rxqno >= HW_QUE_NUM ||
+		    queue->hif_id >= NR_CLDMA) {
+			dev_err(mdev->dev, "Failed to get correct queue info %x\n",
+				queue->rx_chl);
+			kfree(queue);
+			ret = -EINVAL;
+			goto err_free_radix_tree;
+		}
+		ret = radix_tree_insert(&trans->queue_tbl, queue->rx_chl & QUEUE_CHL_MASK, queue);
+		if (ret) {
+			dev_err(mdev->dev, "Insert %x fail, ret: %d", queue->rx_chl, ret);
+			kfree(queue);
+			goto err_free_radix_tree;
+		}
+		trans->queues_cnt++;
+	}
+
+	for (i = 0; i < NR_CLDMA; i++) {
+		for (j = 0; j < HW_QUE_NUM; j++) {
+			skb_queue_head_init(&trans->trans_list[i].skb_list[j]);
+			trans->trans_list[i].tx_burst_cnt[j] = 0;
+		}
+	}
+	ret = mtk_cldma_init(trans);
+	if (ret)
+		goto err_free_radix_tree;
+
+	ret = mtk_ctrl_trb_srv_init(trans);
+	if (ret)
+		goto err_cldma_exit;
+
+	atomic_set(&trans->available, 1);
+
+	return 0;
+
+err_cldma_exit:
+	mtk_cldma_exit(trans);
+err_free_radix_tree:
+	mtk_ctrl_remove_radix_tree(trans);
+
+	return ret;
+}
+
+static int mtk_pcie_hif_exit(struct mtk_md_dev *mdev)
+{
+	struct mtk_ctrl_blk *ctrl_blk = mdev->ctrl_blk;
+	struct mtk_ctrl_trans *trans;
+
+	trans = ctrl_blk->ctrl_hw_priv;
+
+	atomic_set(&trans->available, 0);
+	mtk_ctrl_trb_srv_exit(trans);
+	mtk_ctrl_remove_radix_tree(trans);
+	mtk_cldma_exit(trans);
+
+	return 0;
+}
+
+static int mtk_pcie_hif_submit_skb(struct mtk_md_dev *mdev, struct sk_buff *skb, bool force_send)
+{
+	struct mtk_ctrl_blk *ctrl_blk = mdev->ctrl_blk;
+	struct mtk_ctrl_trans *trans;
+	struct queue_info *que;
+	struct trb *trb;
+
+	trans = ctrl_blk->ctrl_hw_priv;
+	trb = (struct trb *)skb->cb;
+
+	if (trb->cmd == TRB_CMD_STOP || trb->cmd == TRB_CMD_RECOVER) {
+		trb->trb_complete(skb);
+		return 0;
+	}
+
+	que = radix_tree_lookup(&trans->queue_tbl, trb->channel_id & QUEUE_CHL_MASK);
+	if (!que) {
+		dev_warn(mdev->dev, "lookup que fail, ch_id: %x, que: 0x%p\n",
+			 trb->channel_id, que);
+		return -EINVAL;
+	}
+
+	if (!atomic_read(&trans->available))
+		return -EIO;
+
+	if (mtk_queue_list_is_full(trans, que) && !force_send)
+		return -EAGAIN;
+
+	if (trb->cmd == TRB_CMD_DISABLE)
+		skb_queue_head(&trans->trans_list[que->hif_id].skb_list[que->txqno], skb);
+	else
+		skb_queue_tail(&trans->trans_list[que->hif_id].skb_list[que->txqno], skb);
+
+	wake_up(&trans->trb_srv[trans->srv_cfg[que->hif_id][que->txqno]]->trb_waitq);
+
+	return 0;
+}
+
+static int mtk_pcie_hif_cmd_func(struct mtk_md_dev *mdev, int cmd, void *data)
+{
+	struct mtk_ctrl_blk *ctrl_blk = mdev->ctrl_blk;
+	struct mtk_ctrl_trans *trans;
+	struct queue_info *que;
+
+	switch (cmd) {
+	case HIF_CTRL_CMD_CHECK_TX_FULL:
+		trans = ctrl_blk->ctrl_hw_priv;
+		que = radix_tree_lookup(&trans->queue_tbl,
+					((union ctrl_hif_cmd_data *)data)->rx_ch & QUEUE_CHL_MASK);
+		if (!que) {
+			dev_warn(mdev->dev, "Failed to find que to check tx full\n");
+			return -EINVAL;
+		}
+		return mtk_queue_list_is_full(trans, que);
+	default:
+		return -EINVAL;
+	}
+
+	return 0;
+}
+
+static struct mtk_ctrl_hif_ops pcie_ctrl_ops = {
+	.init = mtk_pcie_hif_init,
+	.exit = mtk_pcie_hif_exit,
+	.submit_skb = mtk_pcie_hif_submit_skb,
+	.send_cmd = mtk_pcie_hif_cmd_func,
+};
+
+static void mtk_trans_get_ctrl_info(struct mtk_ctrl_cfg *cfg,
+				    struct mtk_ctrl_trans *trans, u32 hw_ver)
+{
+	struct mtk_ctrl_info_desc *ctrl_info_desc;
+	struct mtk_ctrl_info *ctrl_info;
+	u8 i;
+
+	for (i = 0; (ctrl_info_desc = &mtk_ctrl_info_tbl[i]) && ctrl_info_desc &&
+	     ctrl_info_desc->ctrl_info; i++) {
+		if (ctrl_info_desc->hw_ver != hw_ver)
+			continue;
+
+		ctrl_info = ctrl_info_desc->ctrl_info;
+		memcpy(trans->srv_cfg, ctrl_info->srv_cfg,
+		       sizeof(int) * NR_CLDMA * HW_QUE_NUM);
+		trans->queue_info = ctrl_info->queue_info;
+		trans->queue_info_num = ctrl_info->queue_info_num;
+		trans->trb_srv_num = ctrl_info->trb_srv_num;
+	}
+}
+
+int mtk_trans_ctrl_init(struct mtk_md_dev *mdev)
+{
+	struct mtk_ctrl_trans *trans;
+	struct mtk_ctrl_blk *ctrl_blk;
+	int err;
+
+	trans = devm_kzalloc(mdev->dev, sizeof(*trans), GFP_KERNEL);
+	if (!trans)
+		return -ENOMEM;
+	trans->mdev = mdev;
+	trans->queues_cnt = 0;
+
+	mtk_trans_get_ctrl_info(NULL, trans, mdev->hw_ver);
+	if (!trans->queue_info ||
+	    trans->trb_srv_num <= 0 || trans->trb_srv_num > TRB_SRV_MAX_NUM ||
+	    trans->queue_info_num <= 0) {
+		dev_err(mdev->dev, "Failed to get ctrl info!\n");
+		goto err_free_cfg;
+	}
+
+	err = mtk_ctrl_init(mdev, &pcie_ctrl_ops);
+	if (err)
+		goto err_free_cfg;
+
+	ctrl_blk = mdev->ctrl_blk;
+	ctrl_blk->ctrl_hw_priv = trans;
+
+	return 0;
+
+err_free_cfg:
+	return -ENOMEM;
+}
+
+int mtk_trans_ctrl_exit(struct mtk_md_dev *mdev)
+{
+	mtk_ctrl_exit(mdev);
+
+	return 0;
+}
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.h b/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.h
index d6de4c43b529..0d25d1f51671 100644
--- a/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.h
+++ b/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.h
@@ -13,9 +13,95 @@
 
 #include "mtk_dev.h"
 
+#define TRB_SRV_MAX_NUM			(1)
+#define HW_QUE_NUM			(8)
+#define TX_GPD_NUM			(16)
+#define RX_GPD_NUM			(TX_GPD_NUM)
+#define MIN_GPD_NUM			(2)
+#define SKB_LIST_MAX_LEN		(16)
+#define MTU_RSV_ROOM			(0x100)
+#define TRB_NUM_PER_ROUND		(TX_GPD_NUM)
+#define TX_BURST_MAX_CNT		(TX_GPD_NUM / 4 + 1)
+
+#define HIF_ID(peer_id)			((peer_id) - 1)
+
+enum mtk_hif_id {
+	CLDMA0,
+	CLDMA1,
+	CLDMA4,
+	NR_CLDMA
+};
+
+struct queue_info {
+	u32 tx_chl;
+	u32 rx_chl;
+	enum mtk_hif_id hif_id;
+	u32 txqno;
+	u32 rxqno;
+	u32 tx_mtu;
+	u32 rx_mtu;
+	u32 tx_nr_gpds;
+	u32 rx_nr_gpds;
+	u32 tx_frag_size;
+	u32 rx_frag_size;
+	u8 log_rg_offset;
+};
+
+struct trans_list {
+	struct sk_buff_head skb_list[HW_QUE_NUM];
+	u8 tx_burst_cnt[HW_QUE_NUM];
+};
+
 struct mtk_ctrl_trans {
 	struct mtk_ctrl_blk *ctrl_blk;
+	struct trb_srv *trb_srv[TRB_SRV_MAX_NUM];
+	struct trans_list trans_list[NR_CLDMA];
+	void *dev;
+	struct radix_tree_root queue_tbl;
 	struct mtk_md_dev *mdev;
+	int usr_cnt[NR_CLDMA][HW_QUE_NUM];
+	u32 tx_mtu_cfg[NR_CLDMA][HW_QUE_NUM];
+	u32 rx_mtu_cfg[NR_CLDMA][HW_QUE_NUM];
+	atomic_t available;
+	int queues_cnt;
+	int srv_cfg[NR_CLDMA][HW_QUE_NUM];
+	struct queue_info *queue_info;
+	int queue_info_num;
+	int trb_srv_num;
+};
+
+struct srv_que {
+	u32 hif_id;
+	u32 qno;
+	struct list_head list;
 };
 
+struct trb_srv {
+	u32 srv_id;
+	struct list_head srv_q_list[NR_CLDMA];
+	struct mtk_ctrl_trans *trans;
+	wait_queue_head_t trb_waitq;
+	struct task_struct *trb_thread;
+};
+
+struct mtk_ctrl_info {
+	struct mtk_ctrl_cfg *ctrl_cfg;
+	int **srv_cfg;
+	struct queue_info *queue_info;
+	u32 queue_info_num;
+	u32 trb_srv_num;
+};
+
+struct mtk_ctrl_info_desc {
+	u32 hw_ver;
+	struct mtk_ctrl_info *ctrl_info;
+};
+
+#define ctrl_info_name(NAME)	mtk_ctrl_info_##NAME
+
+extern struct mtk_ctrl_info mtk_ctrl_info_m9xx;
+
+int mtk_trans_ctrl_init(struct mtk_md_dev *mdev);
+int mtk_trans_ctrl_exit(struct mtk_md_dev *mdev);
+
 #endif

-- 
2.34.1

