From: Jack Wu <jackbb_wu@compal.com>
Date: Fri, 29 May 2026 18:31:47 +0800
Subject: [PATCH 08/11] net: wwan: t9xx: Add data plane transaction layer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260529-t9xx_driver_v1-v1-8-bdbfe2c01e57@compal.com>
References: <20260529-t9xx_driver_v1-v1-0-bdbfe2c01e57@compal.com>
In-Reply-To: <20260529-t9xx_driver_v1-v1-0-bdbfe2c01e57@compal.com>
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
 Shuah Khan <skhan@linuxfoundation.org>
Cc: linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 linux-doc@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780050704; l=86030;
 i=jackbb_wu@compal.com; s=20260526; h=from:subject:message-id;
 bh=Np6/kDyVxKTrHw4ZLcnAlBRppZXzzQJUBe98NM9SOwQ=;
 b=sHrnAlNsOOXN9+KeXGW4oOoIiQIaC5bgKZTgEG/nUQq+xO4ra13UYjpGHcvbXF8i4g3qPgd0x
 WnWXkt1011kA32Dy/TR7bl4Jysx9XaulfdqxYeQfZ2uwuWolWQR5/wn
X-Developer-Key: i=jackbb_wu@compal.com; a=ed25519;
 pk=VH1prTWixNl8OEUPPSfII3p46MzJpQN8J3+ecE1tZXg=
X-Endpoint-Received: by B4 Relay for jackbb_wu@compal.com/20260526 with auth_id=793
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Data Path Modem AP Interface (DPMAIF) provides methods for
initialization, ring buffer management, ISR, control and
handling of TX/RX services' flows.

DPMAIF TX
It exposes the function 'mtk_dpmaif_send' which can be
called by the port layer indirectly to transmit packets.
The transaction layer manages uplink data with Descriptor
Ring Buffer (DRB), which includes one message DRB entry
and one or more normal DRB entries. Message DRB holds the
general packet information and each normal DRB entry holds
the address of the packet segment. At the same time, DPMAIF
provides multiple virtual queues with different priorities.

DPMAIF RX
The downlink buffer management uses Buffer Address Table
(BAT), which includes normal BAT and fragment BAT, and
Packet Information Table (PIT) rings. The BAT ring holds
the address of the skb data buffer for the hardware to use,
while the PIT contains metadata about a whole network packet
including a reference to the BAT entry holding the data
buffer address. The driver reads the PIT and BAT entries
written by the modem. When reaching a threshold, the driver
reloads the PIT and BAT rings.

Signed-off-by: Jack Wu <jackbb_wu@compal.com>
---
 drivers/net/wwan/t9xx/Makefile               |    3 +-
 drivers/net/wwan/t9xx/mtk_data_plane.c       |   92 +
 drivers/net/wwan/t9xx/mtk_data_plane.h       |  103 +
 drivers/net/wwan/t9xx/mtk_dev.h              |    1 +
 drivers/net/wwan/t9xx/pcie/Makefile          |    1 +
 drivers/net/wwan/t9xx/pcie/mtk_dpmaif.c      | 2674 ++++++++++++++++++++++++++
 drivers/net/wwan/t9xx/pcie/mtk_dpmaif.h      |   14 +
 drivers/net/wwan/t9xx/pcie/mtk_dpmaif_drv.c  |    1 +
 drivers/net/wwan/t9xx/pcie/mtk_dpmaif_drv.h  |    9 +
 drivers/net/wwan/t9xx/pcie/mtk_dpmaif_ring.c |    2 +-
 drivers/net/wwan/t9xx/pcie/mtk_pci.c         |    8 +
 drivers/net/wwan/t9xx/pcie/mtk_pci.h         |    3 +-
 12 files changed, 2907 insertions(+), 4 deletions(-)

diff --git a/drivers/net/wwan/t9xx/Makefile b/drivers/net/wwan/t9xx/Makefile
index 75760b2039dc..3776ccb4952f 100644
--- a/drivers/net/wwan/t9xx/Makefile
+++ b/drivers/net/wwan/t9xx/Makefile
@@ -11,4 +11,5 @@ mtk_t9xx-y := \
 	mtk_ctrl_plane.o \
 	mtk_port.o \
 	mtk_port_io.o \
-	mtk_fsm.o
+	mtk_fsm.o \
+	mtk_data_plane.o
diff --git a/drivers/net/wwan/t9xx/mtk_data_plane.c b/drivers/net/wwan/t9xx/mtk_data_plane.c
new file mode 100644
index 000000000000..d11c7de45e17
--- /dev/null
+++ b/drivers/net/wwan/t9xx/mtk_data_plane.c
@@ -0,0 +1,92 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (c) 2023, MediaTek Inc.
+ */
+
+#include "mtk_data_plane.h"
+#include "mtk_dev.h"
+#include "mtk_fsm.h"
+
+static void mtk_data_stop(struct mtk_data_blk *data_blk, struct mtk_md_dev *mdev)
+{
+	data_blk->hif_ops->stop(mdev);
+	data_blk->hif_ops->clear(mdev);
+}
+
+static void mtk_data_fsm_callback(struct mtk_fsm_param *fsm_param, void *data)
+{
+	struct mtk_data_blk *data_blk;
+
+	if (!data || !fsm_param)
+		return;
+
+	data_blk = ((struct mtk_md_dev *)data)->data_blk;
+
+	switch (fsm_param->to) {
+	case FSM_STATE_OFF:
+		mtk_data_stop(data_blk, data);
+		break;
+	case FSM_STATE_BOOTUP:
+		if (fsm_param->fsm_flag & FSM_F_MD_HS_START)
+			data_blk->hif_ops->start(data);
+		break;
+	case FSM_STATE_READY:
+		break;
+	default:
+		break;
+	}
+}
+
+int mtk_data_init(struct mtk_md_dev *mdev, struct mtk_data_hif_ops *ops)
+{
+	struct mtk_data_blk *data_blk;
+	int ret;
+
+	data_blk = devm_kzalloc(mdev->dev, sizeof(*data_blk), GFP_KERNEL);
+	if (!data_blk)
+		return -ENOMEM;
+
+	data_blk->mdev = mdev;
+	mdev->data_blk = data_blk;
+	data_blk->hif_ops = ops;
+
+	ret = data_blk->hif_ops->init(mdev);
+	if (ret < 0)
+		goto data_blk_free;
+
+	ret = mtk_fsm_notifier_register(mdev, MTK_USER_DATA, mtk_data_fsm_callback, mdev,
+					FSM_PRIO_1, false);
+	if (ret < 0) {
+		dev_err(mdev->dev, "Failed to register FSM notifier\n");
+		goto hif_exit;
+	}
+
+	return 0;
+
+hif_exit:
+	data_blk->hif_ops->exit(mdev);
+data_blk_free:
+	devm_kfree(mdev->dev, data_blk);
+	mdev->data_blk = NULL;
+
+	return ret;
+}
+EXPORT_SYMBOL(mtk_data_init);
+
+int mtk_data_exit(struct mtk_md_dev *mdev)
+{
+	struct mtk_data_blk *data_blk = mdev->data_blk;
+
+	if (!data_blk)
+		return -EINVAL;
+
+	mtk_fsm_notifier_unregister(mdev, MTK_USER_DATA);
+
+	data_blk->hif_ops->exit(mdev);
+
+	devm_kfree(mdev->dev, data_blk);
+	mdev->data_blk = NULL;
+
+	return 0;
+}
+EXPORT_SYMBOL(mtk_data_exit);
diff --git a/drivers/net/wwan/t9xx/mtk_data_plane.h b/drivers/net/wwan/t9xx/mtk_data_plane.h
new file mode 100644
index 000000000000..1464fab544f1
--- /dev/null
+++ b/drivers/net/wwan/t9xx/mtk_data_plane.h
@@ -0,0 +1,103 @@
+/* SPDX-License-Identifier: GPL-2.0-only
+ *
+ * Copyright (c) 2022, MediaTek Inc.
+ */
+
+#ifndef __MTK_DATA_PLANE_H__
+#define __MTK_DATA_PLANE_H__
+
+#include <linux/bitops.h>
+#include <linux/completion.h>
+#include <linux/skbuff.h>
+
+#define SKB_TO_CMD(skb) ((struct mtk_data_cmd *)(skb)->data)
+#define CMD_TO_DATA(cmd) (*(void **)(cmd)->data)
+#define SKB_TO_CMD_DATA(skb) (*(void **)SKB_TO_CMD(skb)->data)
+
+#define IPV4_VERSION 0x40
+#define IPV6_VERSION 0x60
+
+enum mtk_data_feature {
+	DATA_F_MULTI_NETDEV = BIT(16),
+};
+
+struct mtk_data_trans_info {
+	u32 cap;
+	unsigned char rxq_cnt;
+	unsigned char txq_cnt;
+	unsigned int max_mtu;
+	struct napi_struct **napis;
+};
+
+struct mtk_data_blk {
+	struct mtk_md_dev *mdev;
+	void *dcb;
+	struct mtk_data_hif_ops *hif_ops;
+	struct mtk_data_trans_info trans_info;
+};
+
+enum mtk_data_type {
+	DATA_PKT,
+	DATA_CMD,
+};
+
+enum mtk_pkt_type {
+	PURE_IP,
+};
+
+enum mtk_data_cmd_type {
+	DATA_CMD_TRANS_CTL,
+};
+
+struct mtk_data_trans_ctl {
+	bool enable;
+};
+
+struct mtk_data_cmd {
+	enum mtk_data_cmd_type cmd;
+	unsigned int len;
+	char data[];
+};
+
+struct mtk_tx_pkt_info {
+	unsigned char intf_id;
+	unsigned char cnt;
+};
+
+struct mtk_rx_pkt_info {
+	unsigned char ch_id;
+	unsigned char q_id;
+};
+
+union mtk_data_pkt_info {
+	struct mtk_tx_pkt_info tx;
+	struct mtk_rx_pkt_info rx;
+};
+
+#define DATA_SKB_CB(__skb) ((union mtk_data_pkt_info *)&((__skb)->cb[0]))
+
+enum mtk_data_evt {
+	DATA_EVT_MIN,
+	DATA_EVT_TX_START,
+	DATA_EVT_TX_STOP,
+	DATA_EVT_RX_STOP,
+	DATA_EVT_REG_DEV,
+	DATA_EVT_UNREG_DEV,
+	DATA_EVT_MAX,
+};
+
+struct mtk_data_hif_ops {
+	int (*init)(struct mtk_md_dev *mdev);
+	int (*exit)(struct mtk_md_dev *mdev);
+	int (*stop)(struct mtk_md_dev *mdev);
+	int (*start)(struct mtk_md_dev *mdev);
+	void (*clear)(struct mtk_md_dev *mdev);
+	int (*poll)(struct napi_struct *napi, int budget);
+	int (*send)(struct mtk_data_blk *data_blk, enum mtk_data_type type,
+		    struct sk_buff *skb);
+};
+
+int mtk_data_init(struct mtk_md_dev *mdev, struct mtk_data_hif_ops *ops);
+int mtk_data_exit(struct mtk_md_dev *mdev);
+
+#endif /* __MTK_DATA_PLANE_H__ */
diff --git a/drivers/net/wwan/t9xx/mtk_dev.h b/drivers/net/wwan/t9xx/mtk_dev.h
index bf412b49b19d..8913cbeed670 100644
--- a/drivers/net/wwan/t9xx/mtk_dev.h
+++ b/drivers/net/wwan/t9xx/mtk_dev.h
@@ -58,6 +58,7 @@ struct mtk_md_dev {
 	u32 hw_ver;
 	char dev_str[MTK_DEV_STR_LEN];
 	void *ctrl_blk;
+	void *data_blk;
 	struct mtk_md_fsm *fsm;
 };
 
diff --git a/drivers/net/wwan/t9xx/pcie/Makefile b/drivers/net/wwan/t9xx/pcie/Makefile
index 78a765f8e79a..961faed51498 100644
--- a/drivers/net/wwan/t9xx/pcie/Makefile
+++ b/drivers/net/wwan/t9xx/pcie/Makefile
@@ -12,6 +12,7 @@ mtk_t9xx_pcie-y := \
 	mtk_ctrl_cfg_m9xx.o \
 	mtk_pci.o \
 	mtk_trans_ctrl.o \
+	mtk_dpmaif.o \
 	mtk_cldma.o \
 	mtk_dpmaif_drv.o \
 	mtk_cldma_drv.o \
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_dpmaif.c b/drivers/net/wwan/t9xx/pcie/mtk_dpmaif.c
new file mode 100644
index 000000000000..1c58dba738fa
--- /dev/null
+++ b/drivers/net/wwan/t9xx/pcie/mtk_dpmaif.c
@@ -0,0 +1,2674 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (c) 2022, MediaTek Inc.
+ */
+
+#define pr_fmt(fmt) "DATA_TRANS: " fmt
+
+#include <linux/bitfield.h>
+#include <linux/bitmap.h>
+#include <linux/ip.h>
+#include <linux/kthread.h>
+#include <linux/pm_wakeup.h>
+#include <linux/sched/clock.h>
+#include <linux/skbuff.h>
+#include <net/gro.h>
+#include <net/ipv6.h>
+#include <net/pkt_sched.h>
+
+#include "mtk_data_plane.h"
+#include "mtk_dev.h"
+#include "mtk_dpmaif.h"
+#include "mtk_dpmaif_drv.h"
+#include "mtk_dpmaif_ring.h"
+#include "mtk_pci_reg.h"
+#include "mtk_pci.h"
+
+#define MTK_DATA_WS_NAME_LEN		32
+#define DPMAIF_PIT_CNT_UPDATE_THRESHOLD 60
+#define DPMAIF_SKB_TX_WEIGHT		32
+#define DPMAIF_REL_BAT_WEIGHT		128
+#define MIN_BAT_BURST_CNT	64
+
+static struct dpmaif_drv_ops_desc dpmaif_drv_ops_tbl[] = {
+	{0x01CA, &drv_ops_name(m9xx)},
+	{0, NULL},
+};
+
+enum dpmaif_state {
+	DPMAIF_STATE_MIN,
+	DPMAIF_STATE_PWROFF,
+	DPMAIF_STATE_PWRON,
+	DPMAIF_STATE_MAX
+};
+
+struct dpmaif_vq {
+	unsigned char srv_id;
+	unsigned char q_id;
+	u32 max_len; /* align network tx qdisc 1000 */
+	struct sk_buff_head list;
+};
+
+struct dpmaif_tx_srv {
+	struct mtk_dpmaif_ctlb *dcb;
+	unsigned char id;
+	int nice;
+	wait_queue_head_t wait;
+	struct task_struct *srv;
+
+	unsigned long txq_drb_lack_sta;
+	unsigned char cur_vq_id;
+	unsigned char vq_cnt;
+	struct dpmaif_vq *vq[DPMAIF_TXQ_CNT_MAX];
+};
+
+struct dpmaif_drb_skb {
+	struct sk_buff *skb;
+	dma_addr_t data_dma_addr;
+	unsigned short data_len;
+	unsigned short drb_idx:13;
+	unsigned short is_msg:1;
+	unsigned short is_frag:1;
+	unsigned short is_last:1;
+};
+
+struct dpmaif_txq {
+	struct mtk_dpmaif_ctlb *dcb;
+	unsigned char id;
+	atomic_t budget;
+	atomic_t to_submit_cnt;
+	struct dpmaif_pd_drb *drb_base;
+	dma_addr_t drb_dma_addr;
+	unsigned int drb_cnt;
+	unsigned short drb_wr_idx;
+	unsigned short drb_rd_idx;
+	unsigned short drb_rel_rd_idx;
+	struct dpmaif_drb_skb *sw_drb_base;
+	struct delayed_work tx_done_work;
+};
+
+struct dpmaif_rx_record {
+	bool msg_pit_recv;
+	struct sk_buff *cur_skb;
+	struct sk_buff_head rx_list;
+	unsigned short ip_protocol;
+};
+
+struct dpmaif_rxq {
+	struct mtk_dpmaif_ctlb *dcb;
+	unsigned char id;
+	bool started;
+	struct dpmaif_pd_pit *pit_base;
+	dma_addr_t pit_dma_addr;
+	unsigned int pit_cnt;
+	unsigned short pit_wr_idx;
+	unsigned short pit_rd_idx;
+	unsigned short pit_rel_rd_idx;
+	unsigned char pit_seq_expect;
+	atomic_t pit_rel_cnt;
+	atomic_t pit_stats;
+	bool pit_cnt_err_intr_set;
+	unsigned int pit_burst_rel_cnt;
+	unsigned int pit_seq_fail_cnt;
+	struct napi_struct napi;
+	struct dpmaif_rx_record rx_record;
+	/* Record the latest BID polled by this DLQ pit ring. */
+	unsigned int pit_bid;
+	unsigned char bat_ring_id;
+	unsigned int pit_seq_max;
+	struct dpmaif_rx_info *rx_info;
+	struct wakeup_source *ws;
+};
+
+struct skb_mapped_t {
+	struct sk_buff *skb;
+	dma_addr_t data_dma_addr;
+	unsigned int data_len;
+};
+
+union dpmaif_bat_record {
+	struct skb_mapped_t normal;
+};
+
+struct dpmaif_bat_ring {
+	unsigned char id;
+	struct dpmaif_bat *bat_base;
+	dma_addr_t bat_dma_addr;
+	unsigned int bat_cnt;
+	unsigned short bat_wr_idx;
+	unsigned short bat_rd_idx;
+	/* current max relaod bat cnt */
+	unsigned short max_reload_cnt;
+	atomic_t to_reload_cnt;
+	/* reloaded bat cnt, not doorbelled */
+	atomic_t reload_cnt;
+	atomic_t bat_stats;
+	union dpmaif_bat_record *sw_record_base;
+	unsigned int buf_size;
+	unsigned long *mask_tbl;
+	bool bat_cnt_err_intr_set;
+	int (*alloc)(struct mtk_dpmaif_ctlb *dcb,
+		     struct dpmaif_bat_ring *bat_ring,
+				 unsigned short bat_idx);
+};
+
+struct dpmaif_task_ctlb {
+	wait_queue_head_t wait;
+	bool need_wp;
+};
+
+struct dpmaif_bat_info {
+	struct mtk_dpmaif_ctlb *dcb;
+	unsigned int max_mtu;
+
+	struct dpmaif_bat_ring normal_bat_ring;
+	struct task_struct *reload_task;
+	struct dpmaif_task_ctlb task_ctlb;
+};
+
+struct dpmaif_irq_param {
+	unsigned char idx;
+	struct mtk_dpmaif_ctlb *dcb;
+	enum mtk_irq_src dpmaif_irq_src;
+	int dev_irq_id;
+	int dev_virq_id;
+};
+
+struct dpmaif_tx_evt {
+	unsigned long long ul_done;
+};
+
+struct dpmaif_rx_evt {
+	unsigned long long dl_done;
+};
+
+struct mtk_dpmaif_ctlb {
+	struct mtk_data_blk *data_blk;
+	struct dpmaif_drv_info *drv_info;
+	struct napi_struct *napi[DPMAIF_RXQ_CNT_MAX];
+
+	enum dpmaif_state dpmaif_state;
+	struct mutex trans_ctl_lock; /* protect structure fields */
+
+	struct dpmaif_tx_srv *tx_srvs;
+	struct dpmaif_vq *tx_vqs;
+
+	struct workqueue_struct *tx_done_wq;
+	struct task_struct *db_thread;
+	struct dpmaif_task_ctlb db_task_ctlb;
+	struct dpmaif_txq *txqs;
+	struct dpmaif_rxq *rxqs;
+	struct dpmaif_bat_info *bat_infos;
+	bool irq_enabled;
+	struct dpmaif_irq_param *irq_params;
+
+	bool dpmaif_sw_reset;
+	unsigned char rxq_cnt;
+	unsigned char txq_cnt;
+};
+
+#define DCB_TO_DEV(dcb) ((dcb)->data_blk->mdev->dev)
+#define DCB_TO_MDEV(dcb) ((dcb)->data_blk->mdev)
+#define DCB_TO_DEV_STR(dcb) ((dcb)->data_blk->mdev->dev_str)
+#define DPMAIF_GET_HW_VER(dcb) ((dcb)->data_blk->mdev->hw_ver)
+#define DPMAIF_GET_DRB_CNT(__skb) (skb_shinfo(__skb)->nr_frags + 1 + 1)
+#define DPMAIF_JUMBO_SIZE 9000
+#define DPMAIF_DFLT_MTU 3000
+#define DPMAIF_DL_BUF_MIN_SIZE 128
+
+static int mtk_dpmaif_rx_napi_poll(struct napi_struct *napi, int budget);
+
+static int mtk_dpmaif_send(struct mtk_data_blk *data_blk, enum mtk_data_type type,
+			   struct sk_buff *skb);
+
+static bool mtk_pci_mmio_check(struct mtk_md_dev *mdev)
+{
+	return mtk_pci_mac_read32(mdev->hw_priv, REG_ATR_PCIE_WIN0_T0_SRC_ADDR_LSB) == (u32)-1;
+}
+
+static void mtk_dpmaif_common_err_handle(struct mtk_dpmaif_ctlb *dcb, bool is_hw)
+{
+	if (!is_hw) {
+		dev_err((DCB_TO_MDEV(dcb))->dev, "ASSERT file: %s, function: %s, line %d",
+			__FILE__, __func__, __LINE__);
+		return;
+	}
+
+	if (mtk_pci_mmio_check(DCB_TO_MDEV(dcb)))
+		mtk_pci_send_ext_evt(DCB_TO_MDEV(dcb), EXT_EVT_H2D_RESERVED_FOR_DPMAIF);
+	else
+		dev_err((DCB_TO_MDEV(dcb))->dev, "Failed to access mmio\n");
+}
+
+static void mtk_dpmaif_disable_irq(struct mtk_dpmaif_ctlb *dcb)
+{
+	unsigned char irq_cnt = dcb->drv_info->cfg->intr_cfg.irq_cnt;
+	struct dpmaif_irq_param *irq_param;
+	int i;
+
+	if (!dcb->irq_enabled)
+		return;
+
+	dcb->irq_enabled = false;
+	for (i = 0; i < irq_cnt; i++) {
+		irq_param = &dcb->irq_params[i];
+		if (mtk_pci_mask_irq(DCB_TO_MDEV(dcb), irq_param->dev_irq_id) != 0)
+			dev_err((DCB_TO_MDEV(dcb))->dev,
+				"Failed to mask dev irq%d\n", irq_param->dev_irq_id);
+		synchronize_irq(irq_param->dev_virq_id);
+	}
+}
+
+static void mtk_dpmaif_enable_irq(struct mtk_dpmaif_ctlb *dcb)
+{
+	unsigned char irq_cnt = dcb->drv_info->cfg->intr_cfg.irq_cnt;
+	struct dpmaif_irq_param *irq_param;
+	int i;
+
+	if (dcb->irq_enabled)
+		return;
+
+	dcb->irq_enabled = true;
+	for (i = 0; i < irq_cnt; i++) {
+		irq_param = &dcb->irq_params[i];
+		if (mtk_pci_unmask_irq(DCB_TO_MDEV(dcb), irq_param->dev_irq_id) != 0)
+			dev_err((DCB_TO_MDEV(dcb))->dev,
+				"Failed to unmask dev irq%d\n", irq_param->dev_irq_id);
+	}
+}
+
+static int mtk_dpmaif_alloc_skb(struct mtk_dpmaif_ctlb *dcb, struct dpmaif_bat_ring *bat_ring,
+				unsigned short bat_idx)
+{
+	union dpmaif_bat_record *cur_bat_record;
+	struct skb_mapped_t *skb_info;
+	struct dpmaif_bat *cur_bat;
+
+	cur_bat_record = bat_ring->sw_record_base + bat_idx;
+	skb_info = &cur_bat_record->normal;
+
+	if (skb_info->skb)
+		return 0;
+
+	skb_info->skb = __dev_alloc_skb(bat_ring->buf_size, GFP_ATOMIC);
+	if (unlikely(!skb_info->skb))
+		return -ENOMEM;
+
+	skb_info->data_len = bat_ring->buf_size;
+	skb_info->data_dma_addr = dma_map_single(DCB_TO_DEV(dcb), skb_info->skb->data,
+						 skb_info->data_len, DMA_FROM_DEVICE);
+	if (dma_mapping_error(DCB_TO_DEV(dcb), skb_info->data_dma_addr)) {
+		dev_err((DCB_TO_MDEV(dcb))->dev, "Failed to map dma!\n");
+		dev_kfree_skb_any(skb_info->skb);
+		skb_info->skb = NULL;
+		return -ENOMEM;
+	}
+
+	cur_bat = bat_ring->bat_base + bat_idx;
+	cur_bat->buf_addr_high = cpu_to_le32(upper_32_bits(skb_info->data_dma_addr));
+	cur_bat->buf_addr_low = cpu_to_le32(lower_32_bits(skb_info->data_dma_addr));
+
+	return 0;
+}
+
+static int mtk_dpmaif_reload_rx_buff(struct mtk_dpmaif_ctlb *dcb,
+				     struct dpmaif_bat_ring *bat_ring, unsigned int to_reload_cnt)
+{
+	unsigned short cur_bat_idx;
+	int ret = -ENOMEM;
+	unsigned int i;
+
+	/* Pin rx buffers to BAT entries */
+	cur_bat_idx = bat_ring->bat_wr_idx;
+	for (i = 0; i < to_reload_cnt; i++) {
+		if (!test_and_clear_bit(cur_bat_idx, bat_ring->mask_tbl)) {
+			ret = -EINVAL;
+			break;
+		}
+
+		ret = bat_ring->alloc(dcb, bat_ring, cur_bat_idx);
+		if (unlikely(ret)) {
+			dev_warn((DCB_TO_MDEV(dcb))->dev,
+				 "Failed to alloc rx buff, bat%u bid=%u\n",
+				 bat_ring->id, cur_bat_idx);
+			set_bit(cur_bat_idx, bat_ring->mask_tbl);
+			break;
+		}
+
+		cur_bat_idx = mtk_dpmaif_ring_buf_get_next_idx(bat_ring->bat_cnt, cur_bat_idx);
+	}
+
+	if (unlikely(!i))
+		return ret;
+
+	dma_wmb();
+	atomic_add(i, &bat_ring->reload_cnt);
+	atomic_sub(i, &bat_ring->to_reload_cnt);
+	bat_ring->bat_wr_idx = cur_bat_idx;
+
+	return ret;
+}
+
+static void mtk_dpmaif_preload_rx_buf(struct mtk_dpmaif_ctlb *dcb,
+				      struct dpmaif_bat_ring *bat_ring, unsigned int preload_cnt)
+{
+	int i, idx, ret;
+
+	idx = bat_ring->bat_wr_idx;
+	for (i = 0; i < preload_cnt; i++) {
+		/* the next set bit means this buff consumed */
+		idx = find_next_bit(bat_ring->mask_tbl, bat_ring->bat_cnt, idx + 1);
+		if (idx >= bat_ring->bat_cnt)
+			goto find_from_begin;
+
+		ret = bat_ring->alloc(dcb, bat_ring, idx);
+		if (ret) {
+			dev_warn((DCB_TO_MDEV(dcb))->dev,
+				 "Failed to preload rx buff, bat%u bid=%u\n",
+				 bat_ring->id, idx);
+			break;
+		}
+	}
+
+	goto out;
+
+find_from_begin:
+	idx = -1;
+	for (; i < preload_cnt; i++) {
+		idx = find_next_bit(bat_ring->mask_tbl, bat_ring->bat_wr_idx, idx + 1);
+		if (idx >= bat_ring->bat_wr_idx)
+			break;
+
+		ret = bat_ring->alloc(dcb, bat_ring, idx);
+		if (ret) {
+			dev_warn((DCB_TO_MDEV(dcb))->dev,
+				 "Failed to preload rx buff, bat%u bid=%u\n",
+				 bat_ring->id, idx);
+			break;
+		}
+	}
+
+out:;
+}
+
+static void mtk_dpmaif_task_wakeup(struct dpmaif_task_ctlb *task_ctlb)
+{
+	task_ctlb->need_wp = true;
+	wake_up(&task_ctlb->wait);
+}
+
+static int mtk_dpmaif_reload_bat(struct mtk_dpmaif_ctlb *dcb, struct dpmaif_bat_ring *bat_ring)
+{
+	int pre_reload_cnt;
+	int to_reload_cnt;
+	int ret = 0;
+
+	to_reload_cnt = atomic_read(&bat_ring->to_reload_cnt);
+	while (to_reload_cnt > 0) {
+		pre_reload_cnt = to_reload_cnt > DPMAIF_REL_BAT_WEIGHT ?
+				 DPMAIF_REL_BAT_WEIGHT : to_reload_cnt;
+
+		ret = mtk_dpmaif_reload_rx_buff(dcb, bat_ring, pre_reload_cnt);
+		if (unlikely(ret))
+			break;
+		if (atomic_read(&bat_ring->reload_cnt) >= MIN_BAT_BURST_CNT)
+			mtk_dpmaif_task_wakeup(&dcb->db_task_ctlb);
+		to_reload_cnt -= pre_reload_cnt;
+	}
+
+	if ((ret || bat_ring->bat_cnt_err_intr_set) && atomic_read(&bat_ring->reload_cnt))
+		mtk_dpmaif_task_wakeup(&dcb->db_task_ctlb);
+
+	/* Prefetch rx buff to accelerate next reload work */
+	if (ret == -EINVAL) {
+		mtk_dpmaif_preload_rx_buf(dcb, bat_ring, to_reload_cnt);
+		ret = 0;
+	}
+
+	return ret;
+}
+
+static int mtk_dpmaif_bat_reload_thread(void *arg)
+{
+	struct dpmaif_bat_info *bat_info = arg;
+	struct dpmaif_task_ctlb *task_ctlb;
+	struct dpmaif_bat_ring *bat_ring;
+	int ret;
+
+	task_ctlb = &bat_info->task_ctlb;
+
+	while (1) {
+		ret = wait_event_interruptible(task_ctlb->wait,
+					       task_ctlb->need_wp ||
+					       kthread_should_stop());
+		task_ctlb->need_wp = false;
+		if (unlikely(ret == -ERESTARTSYS))
+			continue;
+
+		if (kthread_should_stop())
+			break;
+
+		bat_ring = &bat_info->normal_bat_ring;
+		if (atomic_read(&bat_ring->to_reload_cnt) > 0)
+			mtk_dpmaif_reload_bat(bat_info->dcb, bat_ring);
+
+		cond_resched();
+	}
+
+	return 0;
+}
+
+static int mtk_dpmaif_bat_ring_init(struct mtk_dpmaif_ctlb *dcb, struct dpmaif_bat_ring *bat_ring,
+				    int bat_ring_id)
+{
+	int ret;
+
+	bat_ring->bat_cnt = dcb->drv_info->cfg->rx_cfg.bats[bat_ring_id].bat_cnt;
+	bat_ring->max_reload_cnt = dcb->drv_info->cfg->rx_cfg.bats[bat_ring_id].reload_cnt;
+	bat_ring->alloc = mtk_dpmaif_alloc_skb;
+
+	bat_ring->id = bat_ring_id;
+	bat_ring->bat_cnt_err_intr_set = false;
+	atomic_set(&bat_ring->to_reload_cnt, bat_ring->max_reload_cnt);
+
+	/* Allocate BAT memory for HW and SW. */
+	bat_ring->bat_base = dma_alloc_coherent(DCB_TO_DEV(dcb), (bat_ring->bat_cnt +
+						dcb->drv_info->cfg->rx_cfg.bat_wrap_cnt) *
+						sizeof(*bat_ring->bat_base),
+						&bat_ring->bat_dma_addr, GFP_KERNEL);
+	if (!bat_ring->bat_base) {
+		dev_err((DCB_TO_MDEV(dcb))->dev, "Failed to allocate bat%u buffer\n", bat_ring->id);
+		return -ENOMEM;
+	}
+
+	/* Allocate buffer for SW to record skb information */
+	bat_ring->sw_record_base = devm_kcalloc(DCB_TO_DEV(dcb), bat_ring->bat_cnt,
+						sizeof(*bat_ring->sw_record_base), GFP_KERNEL);
+	if (!bat_ring->sw_record_base) {
+		ret = -ENOMEM;
+		goto free_bat_buf;
+	}
+
+	/* Allocate buffer for SW to recycle BAT. */
+	bat_ring->mask_tbl = bitmap_alloc(bat_ring->bat_cnt, GFP_KERNEL);
+	if (!bat_ring->mask_tbl) {
+		ret = -ENOMEM;
+		goto free_sw_record_base;
+	}
+
+	bitmap_fill(bat_ring->mask_tbl, bat_ring->bat_cnt);
+
+	return 0;
+
+free_sw_record_base:
+	devm_kfree(DCB_TO_DEV(dcb), bat_ring->sw_record_base);
+
+free_bat_buf:
+	dma_free_coherent(DCB_TO_DEV(dcb), (bat_ring->bat_cnt +
+			  dcb->drv_info->cfg->rx_cfg.bat_wrap_cnt) *
+			  sizeof(*bat_ring->bat_base),
+			  bat_ring->bat_base, bat_ring->bat_dma_addr);
+
+	return ret;
+}
+
+static void mtk_dpmaif_bat_ring_exit(struct mtk_dpmaif_ctlb *dcb, struct dpmaif_bat_ring *bat_ring)
+{
+	union dpmaif_bat_record *bat_record;
+	int i;
+
+	bitmap_free(bat_ring->mask_tbl);
+
+	for (i = 0; i < bat_ring->bat_cnt; i++) {
+		bat_record = bat_ring->sw_record_base + i;
+		if (!bat_record->normal.skb)
+			continue;
+
+		dma_unmap_single(DCB_TO_DEV(dcb),
+				 bat_record->normal.data_dma_addr,
+				 bat_record->normal.data_len,
+				 DMA_FROM_DEVICE);
+		dev_kfree_skb_any(bat_record->normal.skb);
+	}
+
+	devm_kfree(DCB_TO_DEV(dcb), bat_ring->sw_record_base);
+
+	dma_free_coherent(DCB_TO_DEV(dcb), (bat_ring->bat_cnt +
+			  dcb->drv_info->cfg->rx_cfg.bat_wrap_cnt) *
+			  sizeof(*bat_ring->bat_base),
+			  bat_ring->bat_base, bat_ring->bat_dma_addr);
+}
+
+static void mtk_dpmaif_bat_ring_reset(struct dpmaif_bat_ring *bat_ring)
+{
+	bat_ring->bat_cnt_err_intr_set = false;
+	bat_ring->bat_wr_idx = 0;
+	bat_ring->bat_rd_idx = 0;
+	atomic_set(&bat_ring->reload_cnt, 0);
+	atomic_set(&bat_ring->bat_stats, 0);
+	atomic_set(&bat_ring->to_reload_cnt, bat_ring->max_reload_cnt);
+
+	bitmap_fill(bat_ring->mask_tbl, bat_ring->bat_cnt);
+}
+
+static void mtk_dpmaif_bat_res_reset(struct mtk_dpmaif_ctlb *dcb)
+{
+	unsigned int bat_ring_num = dcb->drv_info->cfg->rx_cfg.bat_ring_num;
+	struct dpmaif_bat_ring *bat_ring;
+	int i;
+
+	for (i = 0; i < bat_ring_num; i++) {
+		bat_ring = &dcb->bat_infos[i].normal_bat_ring;
+		bat_ring->max_reload_cnt = dcb->drv_info->cfg->rx_cfg.bats[i].reload_cnt;
+			mtk_dpmaif_bat_ring_reset(bat_ring);
+	}
+}
+
+static void mtk_dpmaif_set_bat_buf_size(struct mtk_dpmaif_ctlb *dcb)
+{
+	int bat_ring_num = dcb->drv_info->cfg->rx_cfg.bat_ring_num;
+	struct dpmaif_bat_info *bat_infos = dcb->bat_infos;
+	unsigned int buf_size;
+	int i;
+
+	for (i = 0; i < bat_ring_num; i++) {
+		bat_infos[i].max_mtu = dcb->drv_info->cfg->rx_cfg.mtu;
+
+		/* Set max mtu, DPMAIF_JUMBO_SIZE. */
+		if (bat_infos[i].max_mtu > DPMAIF_JUMBO_SIZE)
+			bat_infos[i].max_mtu = DPMAIF_JUMBO_SIZE;
+
+		/* Normal BAT buffer size setting. */
+		buf_size = bat_infos[i].max_mtu + dcb->drv_info->cfg->rx_cfg.pkt_alignment +
+			dcb->drv_info->cfg->rx_cfg.normal_bat_rsv_length;
+
+		bat_infos[i].normal_bat_ring.buf_size = ALIGN(buf_size,
+							      DPMAIF_DL_BUF_MIN_SIZE);
+	}
+	dcb->drv_info->cfg->rx_cfg.mtu = dcb->bat_infos[0].max_mtu;
+}
+
+static void mtk_dpmaif_bat_info_exit(struct mtk_dpmaif_ctlb *dcb, int bat_ring_id)
+{
+	struct dpmaif_bat_info *bat_info = &dcb->bat_infos[bat_ring_id];
+
+	if (bat_info->reload_task) {
+		kthread_stop(bat_info->reload_task);
+		bat_info->reload_task = NULL;
+	}
+
+	mtk_dpmaif_bat_ring_exit(dcb, &bat_info->normal_bat_ring);
+}
+
+static void mtk_dpmaif_bat_res_exit(struct mtk_dpmaif_ctlb *dcb)
+{
+	int bat_ring_num = dcb->drv_info->cfg->rx_cfg.bat_ring_num;
+	int i;
+
+	for (i = 0; i < bat_ring_num; i++)
+		mtk_dpmaif_bat_info_exit(dcb, i);
+
+	devm_kfree(DCB_TO_DEV(dcb), dcb->bat_infos);
+}
+
+static int mtk_dpmaif_bat_info_init(struct mtk_dpmaif_ctlb *dcb,
+				    struct dpmaif_bat_info *bat_info, int bat_ring_id)
+{
+	int ret;
+
+	bat_info->dcb = dcb;
+	ret = mtk_dpmaif_bat_ring_init(dcb, &bat_info->normal_bat_ring, bat_ring_id);
+	if (ret < 0) {
+		dev_err((DCB_TO_MDEV(dcb))->dev, "Failed to initialize normal bat ring\n");
+		return ret;
+	}
+
+	init_waitqueue_head(&bat_info->task_ctlb.wait);
+	bat_info->reload_task = kthread_run(mtk_dpmaif_bat_reload_thread, bat_info,
+					    "dpmaif_reload_%d", bat_ring_id);
+	if (IS_ERR(bat_info->reload_task)) {
+		dev_err((DCB_TO_MDEV(dcb))->dev, "Failed to create bat reload thread\n");
+		ret = PTR_ERR(bat_info->reload_task);
+		bat_info->reload_task = NULL;
+		mtk_dpmaif_bat_ring_exit(dcb, &bat_info->normal_bat_ring);
+		return ret;
+	}
+
+	return 0;
+}
+
+static int mtk_dpmaif_bat_res_init(struct mtk_dpmaif_ctlb *dcb)
+{
+	int bat_ring_num = dcb->drv_info->cfg->rx_cfg.bat_ring_num;
+	int i, j;
+	int ret;
+
+	dcb->bat_infos = devm_kcalloc(DCB_TO_DEV(dcb), bat_ring_num, sizeof(*dcb->bat_infos),
+				      GFP_KERNEL);
+	if (!dcb->bat_infos)
+		return -ENOMEM;
+
+	/* Check and set bat buffer size. */
+	mtk_dpmaif_set_bat_buf_size(dcb);
+
+	for (i = 0; i < bat_ring_num; i++) {
+		ret = mtk_dpmaif_bat_info_init(dcb, &dcb->bat_infos[i], i);
+		if (ret < 0) {
+			dev_err((DCB_TO_MDEV(dcb))->dev, "Failed to initialize bat_info%d\n", i);
+			goto bat_info_exit;
+		}
+	}
+
+	return 0;
+
+bat_info_exit:
+	for (j = i - 1; j >= 0; j--)
+		mtk_dpmaif_bat_info_exit(dcb, j);
+
+	devm_kfree(DCB_TO_DEV(dcb), dcb->bat_infos);
+
+	return ret;
+}
+
+static int mtk_dpmaif_rxq_init(struct mtk_dpmaif_ctlb *dcb, struct dpmaif_rxq *rxq)
+{
+	char ws_name[MTK_DATA_WS_NAME_LEN];
+	int ret;
+
+	rxq->pit_seq_max = dcb->drv_info->cfg->rx_cfg.rxqs[rxq->id].pit_seq_max;
+	rxq->bat_ring_id = dcb->drv_info->cfg->rx_cfg.rxqs[rxq->id].bat_ring_id;
+	rxq->pit_cnt = dcb->drv_info->cfg->rx_cfg.rxqs[rxq->id].pit_cnt;
+	rxq->pit_burst_rel_cnt = DPMAIF_PIT_CNT_UPDATE_THRESHOLD;
+
+	snprintf(ws_name, sizeof(ws_name), "dpmaif_rxq%d_ws", rxq->id);
+
+	rxq->ws = wakeup_source_register(NULL, ws_name);
+	if (!rxq->ws) {
+		dev_err((DCB_TO_MDEV(dcb))->dev,
+			"Failed to register rxq%d wakeup source\n", rxq->id);
+		return -ENOMEM;
+	}
+
+	rxq->pit_base = dma_alloc_coherent(DCB_TO_DEV(dcb),
+					   rxq->pit_cnt * sizeof(*rxq->pit_base),
+					   &rxq->pit_dma_addr, GFP_KERNEL);
+	if (!rxq->pit_base) {
+		dev_err((DCB_TO_MDEV(dcb))->dev,
+			"Failed to allocate rxq%u pit resource\n", rxq->id);
+		ret = -ENOMEM;
+		goto unregister_ws;
+	}
+
+	__skb_queue_head_init(&rxq->rx_record.rx_list);
+
+	return 0;
+unregister_ws:
+	wakeup_source_unregister(rxq->ws);
+
+	return ret;
+}
+
+static void mtk_dpmaif_rxq_exit(struct mtk_dpmaif_ctlb *dcb, struct dpmaif_rxq *rxq)
+{
+	dma_free_coherent(DCB_TO_DEV(dcb), rxq->pit_cnt * sizeof(*rxq->pit_base),
+			  rxq->pit_base, rxq->pit_dma_addr);
+	wakeup_source_unregister(rxq->ws);
+}
+
+static int mtk_dpmaif_sw_stop_rxq(struct mtk_dpmaif_ctlb *dcb, struct dpmaif_rxq *rxq)
+{
+	/* Rxq done process will check this flag, if rxq->started is false, process will stop. */
+	rxq->started = false;
+
+	/* Make sure rxq->started value update done. */
+	smp_mb();
+
+	/* Wait rxq process done. */
+	napi_synchronize(&rxq->napi);
+
+	return 0;
+}
+
+static void mtk_dpmaif_sw_stop_rx(struct mtk_dpmaif_ctlb *dcb)
+{
+	struct dpmaif_rxq *rxq;
+	int i;
+
+	/* Stop all rx process. */
+	for (i = 0; i < dcb->rxq_cnt; i++) {
+		rxq = &dcb->rxqs[i];
+		mtk_dpmaif_sw_stop_rxq(dcb, rxq);
+	}
+
+	/* Stop PIT polling NAPI. */
+}
+
+static void mtk_dpmaif_sw_start_rx(struct mtk_dpmaif_ctlb *dcb)
+{
+	struct dpmaif_rxq *rxq;
+	int i;
+
+	/* Start PIT polling NAPI. */
+
+	for (i = 0; i < dcb->rxq_cnt; i++) {
+		rxq = &dcb->rxqs[i];
+		rxq->started = true;
+	}
+}
+
+static void mtk_dpmaif_sw_reset_rxq(struct dpmaif_rxq *rxq)
+{
+	memset(rxq->pit_base, 0x00, (rxq->pit_cnt * sizeof(*rxq->pit_base)));
+	memset(&rxq->rx_record, 0x00, sizeof(rxq->rx_record));
+	__skb_queue_head_init(&rxq->rx_record.rx_list);
+
+	rxq->started = false;
+	rxq->pit_wr_idx = 0;
+	rxq->pit_rd_idx = 0;
+	rxq->pit_rel_rd_idx = 0;
+	rxq->pit_seq_expect = 0;
+	atomic_set(&rxq->pit_rel_cnt, 0);
+	rxq->pit_cnt_err_intr_set = false;
+	rxq->pit_seq_fail_cnt = 0;
+}
+
+static void mtk_dpmaif_rx_res_reset(struct mtk_dpmaif_ctlb *dcb)
+{
+	struct dpmaif_rxq *rxq;
+	int i;
+
+	for (i = 0; i < dcb->rxq_cnt; i++) {
+		rxq = &dcb->rxqs[i];
+		mtk_dpmaif_sw_reset_rxq(rxq);
+	}
+}
+
+static int mtk_dpmaif_rx_res_init(struct mtk_dpmaif_ctlb *dcb)
+{
+	struct dpmaif_rxq *rxq;
+	int i, j;
+	int ret;
+
+	dcb->rxqs = devm_kcalloc(DCB_TO_DEV(dcb), dcb->rxq_cnt, sizeof(*rxq), GFP_KERNEL);
+	if (!dcb->rxqs)
+		return -ENOMEM;
+
+	for (i = 0; i < dcb->rxq_cnt; i++) {
+		rxq = &dcb->rxqs[i];
+		rxq->id = i;
+		rxq->dcb = dcb;
+		ret = mtk_dpmaif_rxq_init(dcb, rxq);
+		if (ret < 0) {
+			dev_err((DCB_TO_MDEV(dcb))->dev,
+				"Failed to init rxq%u resource\n", rxq->id);
+			goto exit_rxq;
+		}
+	}
+
+	return 0;
+
+exit_rxq:
+	for (j = i - 1; j >= 0; j--)
+		mtk_dpmaif_rxq_exit(dcb, &dcb->rxqs[j]);
+
+	devm_kfree(DCB_TO_DEV(dcb), dcb->rxqs);
+
+	return ret;
+}
+
+static void mtk_dpmaif_rx_res_exit(struct mtk_dpmaif_ctlb *dcb)
+{
+	int i;
+
+	for (i = 0; i < dcb->rxq_cnt; i++)
+		mtk_dpmaif_rxq_exit(dcb, &dcb->rxqs[i]);
+
+	devm_kfree(DCB_TO_DEV(dcb), dcb->rxqs);
+}
+
+static unsigned int mtk_dpmaif_poll_tx_drb(struct dpmaif_txq *txq)
+{
+	unsigned short old_sw_rd_idx, new_hw_rd_idx;
+	struct mtk_dpmaif_ctlb *dcb = txq->dcb;
+	unsigned int drb_cnt;
+	int ret;
+
+	old_sw_rd_idx = txq->drb_rd_idx;
+	ret = dcb->drv_info->drv_ops->get_ring_idx(dcb->drv_info, DPMAIF_DRB_RIDX, txq->id);
+	if (unlikely(ret < 0)) {
+		dev_err((DCB_TO_MDEV(dcb))->dev,
+			"Failed to read txq%u drb_rd_idx, ret=%d\n", txq->id, ret);
+		mtk_dpmaif_common_err_handle(dcb, true);
+		return 0;
+	}
+
+	new_hw_rd_idx = ret;
+
+	if (old_sw_rd_idx <= new_hw_rd_idx)
+		drb_cnt = new_hw_rd_idx - old_sw_rd_idx;
+	else
+		drb_cnt = txq->drb_cnt - old_sw_rd_idx + new_hw_rd_idx;
+
+	txq->drb_rd_idx = new_hw_rd_idx;
+
+	return drb_cnt;
+}
+
+static int mtk_dpmaif_tx_rel_internal(struct dpmaif_txq *txq,
+				      unsigned int rel_cnt, unsigned int *real_rel_cnt)
+{
+	struct dpmaif_pd_drb *cur_drb = NULL, *drb_base = txq->drb_base;
+	struct mtk_dpmaif_ctlb *dcb = txq->dcb;
+	struct dpmaif_drb_skb *cur_drb_skb;
+	struct dpmaif_tx_srv *tx_srv;
+	struct sk_buff *skb_free;
+	unsigned short cur_idx;
+	unsigned char srv_id;
+	unsigned int i;
+
+	cur_idx = txq->drb_rel_rd_idx;
+	for (i = 0; i < rel_cnt; i++) {
+		cur_drb = drb_base + cur_idx;
+		cur_drb_skb = txq->sw_drb_base + cur_idx;
+		if (cur_drb_skb->is_msg == PD_DRB) {
+			dma_unmap_single(DCB_TO_DEV(dcb), cur_drb_skb->data_dma_addr,
+					 cur_drb_skb->data_len, DMA_TO_DEVICE);
+
+			/* The last one drb entry of one tx packet, so, skb will be released. */
+			if (cur_drb_skb->is_last) {
+				skb_free = cur_drb_skb->skb;
+				if (likely(skb_free)) {
+					dev_consume_skb_any(skb_free);
+				} else {
+					dev_err((DCB_TO_MDEV(dcb))->dev,
+						"Failed to free skb,txq%u pkt%u,w=%u,r=%u,rel=%u,cnt=%u\n",
+						txq->id, cur_idx, txq->drb_wr_idx,
+						txq->drb_rd_idx, txq->drb_rel_rd_idx, rel_cnt);
+					mtk_dpmaif_common_err_handle(dcb, false);
+				}
+			}
+		}
+
+		cur_drb_skb->skb = NULL;
+		cur_idx = mtk_dpmaif_ring_buf_get_next_idx(txq->drb_cnt, cur_idx);
+		txq->drb_rel_rd_idx = cur_idx;
+		atomic_inc(&txq->budget);
+	}
+
+	*real_rel_cnt = i;
+
+	if (likely(cur_drb)) {
+		if (unlikely(!cur_drb_skb->is_last)) {
+			dev_warn((DCB_TO_MDEV(dcb))->dev,
+				 "txq%u done, last one c_bit != 0\n", txq->id);
+			mtk_dpmaif_common_err_handle(dcb, true);
+		}
+	}
+
+	if (atomic_read(&txq->budget) > txq->drb_cnt >> 3) {
+		srv_id = dcb->tx_vqs[txq->id].srv_id;
+		tx_srv = &dcb->tx_srvs[srv_id];
+		clear_bit(txq->id, &tx_srv->txq_drb_lack_sta);
+		wake_up(&tx_srv->wait);
+	}
+
+	return 0;
+}
+
+static int mtk_dpmaif_tx_rel(struct dpmaif_txq *txq)
+{
+	unsigned int real_rel_cnt = 0;
+	int ret = 0, rel_cnt;
+
+	mtk_dpmaif_poll_tx_drb(txq);
+
+	rel_cnt = mtk_dpmaif_ring_buf_releasable(txq->drb_cnt, txq->drb_rel_rd_idx,
+						 txq->drb_rd_idx);
+
+	if (likely(rel_cnt > 0)) {
+		/* Release tx data buffer. */
+		ret = mtk_dpmaif_tx_rel_internal(txq, rel_cnt, &real_rel_cnt);
+	}
+
+	return ret;
+}
+
+static void mtk_dpmaif_tx_done(struct work_struct *work)
+{
+	struct delayed_work *dwork = to_delayed_work(work);
+	struct mtk_dpmaif_ctlb *dcb;
+	struct dpmaif_txq *txq;
+
+	txq = container_of(dwork, struct dpmaif_txq, tx_done_work);
+	dcb = txq->dcb;
+
+	/* Recycle drb and release hardware tx done buffer around drb. */
+	mtk_dpmaif_tx_rel(txq);
+
+	mtk_dpmaif_drv_intr_complete(dcb->drv_info, DPMAIF_INTR_UL_DONE,
+				     txq->id, DPMAIF_UNMASK_INTR);
+}
+
+static int mtk_dpmaif_doorbell_thread(void *arg)
+{
+	struct mtk_dpmaif_ctlb *dcb = arg;
+	int bat_ring_num = dcb->drv_info->cfg->rx_cfg.bat_ring_num;
+	int doorbell_cnt, i, ret;
+
+	while (1) {
+		ret = wait_event_interruptible(dcb->db_task_ctlb.wait,
+					       dcb->db_task_ctlb.need_wp ||
+					       kthread_should_stop());
+		dcb->db_task_ctlb.need_wp = false;
+		if (unlikely(ret == -ERESTARTSYS))
+			continue;
+
+		if (kthread_should_stop())
+			break;
+
+		/* TX DRB doorbell */
+		for (i = 0; i < dcb->txq_cnt; i++) {
+			doorbell_cnt = atomic_read(&dcb->txqs[i].to_submit_cnt);
+			if (doorbell_cnt > 0) {
+				ret = mtk_dpmaif_drv_send_doorbell(dcb->drv_info,
+								   DPMAIF_DRB, i,
+								   doorbell_cnt);
+				if (unlikely(ret < 0)) {
+					dev_err(DCB_TO_DEV(dcb),
+						"Failed to send txq%d doorbell\n", i);
+					mtk_dpmaif_common_err_handle(dcb, true);
+					break;
+				}
+				atomic_sub(doorbell_cnt, &dcb->txqs[i].to_submit_cnt);
+			}
+		}
+
+		/* BAT doorbell */
+		for (i = 0; i < bat_ring_num; i++) {
+			struct dpmaif_bat_ring *bat_ring = &dcb->bat_infos[i].normal_bat_ring;
+
+			/* Send BAT doorbell to notify HW about newly reloaded BAT entries. */
+			doorbell_cnt = atomic_read(&bat_ring->reload_cnt);
+			if (doorbell_cnt > 0) {
+				ret = mtk_dpmaif_drv_send_doorbell(dcb->drv_info,
+								   DPMAIF_BAT,
+								   bat_ring->id,
+								   doorbell_cnt);
+				if (unlikely(ret < 0)) {
+					dev_err(DCB_TO_DEV(dcb),
+						"Failed to send bat%u doorbell\n", bat_ring->id);
+					mtk_dpmaif_common_err_handle(dcb, true);
+					continue;
+				}
+
+				atomic_sub(doorbell_cnt, &bat_ring->reload_cnt);
+				if (bat_ring->bat_cnt_err_intr_set) {
+					bat_ring->bat_cnt_err_intr_set = false;
+					mtk_dpmaif_drv_intr_complete(dcb->drv_info,
+								     DPMAIF_INTR_DL_BATCNT_LEN_ERR,
+								     bat_ring->id, 0);
+				}
+			}
+		}
+
+		/* PIT doorbell for all RX queues */
+		for (i = 0; i < dcb->rxq_cnt; i++) {
+			struct dpmaif_rxq *rxq = &dcb->rxqs[i];
+
+			doorbell_cnt = atomic_read(&rxq->pit_rel_cnt);
+			if (doorbell_cnt >= 0) {
+				ret = mtk_dpmaif_drv_send_doorbell(dcb->drv_info,
+								   DPMAIF_PIT, rxq->id,
+								   doorbell_cnt);
+				if (unlikely(ret < 0)) {
+					dev_err(DCB_TO_DEV(dcb),
+						"Failed to send rxq%d pit doorbell\n", i);
+					mtk_dpmaif_common_err_handle(dcb, true);
+				} else {
+					atomic_sub(doorbell_cnt, &rxq->pit_rel_cnt);
+				}
+			}
+		}
+
+		cond_resched();
+	}
+
+	return 0;
+}
+
+static int mtk_dpmaif_txq_init(struct mtk_dpmaif_ctlb *dcb, struct dpmaif_txq *txq)
+{
+	struct dpmaif_txq_cfg *txq_cfg = &dcb->drv_info->cfg->tx_cfg.txqs[txq->id];
+	int ret;
+
+	txq->drb_cnt = txq_cfg->drb_cnt;
+	atomic_set(&txq->budget, txq->drb_cnt);
+
+	/* Allocate DRB memory for HW and SW. */
+	txq->drb_base = dma_alloc_coherent(DCB_TO_DEV(dcb), txq->drb_cnt * sizeof(*txq->drb_base),
+					   &txq->drb_dma_addr, GFP_KERNEL);
+	if (!txq->drb_base)
+		return -ENOMEM;
+
+	/* Allocate buffer for SW to record the skb information. */
+	txq->sw_drb_base = devm_kcalloc(DCB_TO_DEV(dcb), txq->drb_cnt, sizeof(*txq->sw_drb_base),
+					GFP_KERNEL);
+	if (!txq->sw_drb_base) {
+		ret = -ENOMEM;
+		goto free_drb;
+	}
+
+	INIT_DELAYED_WORK(&txq->tx_done_work, mtk_dpmaif_tx_done);
+
+	return 0;
+
+free_drb:
+	dma_free_coherent(DCB_TO_DEV(dcb), txq->drb_cnt * sizeof(*txq->drb_base),
+			  txq->drb_base, txq->drb_dma_addr);
+
+	return ret;
+}
+
+static void mtk_dpmaif_txq_exit(struct mtk_dpmaif_ctlb *dcb, struct dpmaif_txq *txq)
+{
+	struct dpmaif_drb_skb *drb_skb;
+	int i;
+
+	dma_free_coherent(DCB_TO_DEV(dcb), txq->drb_cnt * sizeof(*txq->drb_base),
+			  txq->drb_base, txq->drb_dma_addr);
+
+	for (i = 0; i < txq->drb_cnt; i++) {
+		drb_skb = txq->sw_drb_base + i;
+		if (!drb_skb->skb)
+			continue;
+
+		/* Verify msg drb or payload drb, and only payload drb need to unmap dma. */
+		if (drb_skb->data_dma_addr)
+			dma_unmap_single(DCB_TO_DEV(dcb),
+					 drb_skb->data_dma_addr,
+					 drb_skb->data_len, DMA_TO_DEVICE);
+		if (drb_skb->is_last)
+			dev_kfree_skb_any(drb_skb->skb);
+	}
+
+	devm_kfree(DCB_TO_DEV(dcb), txq->sw_drb_base);
+}
+
+static int mtk_dpmaif_sw_wait_txq_stop(struct mtk_dpmaif_ctlb *dcb, struct dpmaif_txq *txq)
+{
+	/* Wait tx done work done. */
+	flush_delayed_work(&txq->tx_done_work);
+
+	return 0;
+}
+
+static void mtk_dpmaif_sw_wait_tx_stop(struct mtk_dpmaif_ctlb *dcb)
+{
+	unsigned char txq_cnt = dcb->drv_info->cfg->tx_cfg.txq_cnt;
+	int i;
+
+	/* Wait all tx handle complete */
+	for (i = 0; i < txq_cnt; i++)
+		mtk_dpmaif_sw_wait_txq_stop(dcb, &dcb->txqs[i]);
+}
+
+static void mtk_dpmaif_sw_reset_txq(struct dpmaif_txq *txq)
+{
+	struct dpmaif_drb_skb *drb_skb;
+	int i;
+
+	/* Drop all tx buffer around drb. */
+	for (i = 0; i < txq->drb_cnt; i++) {
+		drb_skb = txq->sw_drb_base + i;
+		if (!drb_skb->skb)
+			continue;
+
+		if (drb_skb->data_dma_addr)
+			dma_unmap_single(DCB_TO_DEV(txq->dcb), drb_skb->data_dma_addr,
+					 drb_skb->data_len, DMA_TO_DEVICE);
+		if (drb_skb->is_last) {
+			dev_kfree_skb_any(drb_skb->skb);
+			drb_skb->skb = NULL;
+		}
+	}
+
+	/* Reset all txq resource. */
+	memset(txq->drb_base, 0x00, (txq->drb_cnt * sizeof(*txq->drb_base)));
+	memset(txq->sw_drb_base, 0x00, (txq->drb_cnt * sizeof(*txq->sw_drb_base)));
+
+	atomic_set(&txq->budget, txq->drb_cnt);
+	atomic_set(&txq->to_submit_cnt, 0);
+	txq->drb_rd_idx = 0;
+	txq->drb_wr_idx = 0;
+	txq->drb_rel_rd_idx = 0;
+}
+
+static void mtk_dpmaif_tx_res_reset(struct mtk_dpmaif_ctlb *dcb)
+{
+	unsigned char txq_cnt = dcb->drv_info->cfg->tx_cfg.txq_cnt;
+	struct dpmaif_txq *txq;
+	int i;
+
+	for (i = 0; i < txq_cnt; i++) {
+		txq = &dcb->txqs[i];
+		mtk_dpmaif_sw_reset_txq(txq);
+	}
+}
+
+static int mtk_dpmaif_tx_res_init(struct mtk_dpmaif_ctlb *dcb)
+{
+	struct dpmaif_txq *txq;
+	int i, j;
+	int ret;
+
+	dcb->txqs = devm_kcalloc(DCB_TO_DEV(dcb), dcb->txq_cnt, sizeof(*txq), GFP_KERNEL);
+	if (!dcb->txqs)
+		return -ENOMEM;
+
+	for (i = 0; i < dcb->txq_cnt; i++) {
+		txq = &dcb->txqs[i];
+		txq->id = i;
+		txq->dcb = dcb;
+		ret = mtk_dpmaif_txq_init(dcb, txq);
+		if (ret < 0) {
+			dev_err((DCB_TO_MDEV(dcb))->dev,
+				"Failed to init txq%d resource\n", txq->id);
+			goto exit_txq;
+		}
+	}
+
+	dcb->tx_done_wq = alloc_workqueue("dpmaif_tx_done_wq_%s",
+					  WQ_UNBOUND | WQ_MEM_RECLAIM | WQ_HIGHPRI,
+					  dcb->txq_cnt, DCB_TO_DEV_STR(dcb));
+	if (!dcb->tx_done_wq) {
+		dev_err((DCB_TO_MDEV(dcb))->dev, "Failed to allocate tx done workqueue\n");
+		ret = -ENOMEM;
+		goto exit_txq;
+	}
+
+	init_waitqueue_head(&dcb->db_task_ctlb.wait);
+	dcb->db_thread = kthread_run(mtk_dpmaif_doorbell_thread, dcb,
+				     "dpmaif_db_%s", DCB_TO_DEV_STR(dcb));
+	if (IS_ERR(dcb->db_thread)) {
+		dev_err((DCB_TO_MDEV(dcb))->dev, "Failed to create doorbell thread\n");
+		ret = PTR_ERR(dcb->db_thread);
+		dcb->db_thread = NULL;
+		goto destroy_tx_done_wq;
+	}
+
+	return 0;
+
+destroy_tx_done_wq:
+	flush_workqueue(dcb->tx_done_wq);
+	destroy_workqueue(dcb->tx_done_wq);
+
+exit_txq:
+	for (j = i - 1; j >= 0; j--)
+		mtk_dpmaif_txq_exit(dcb, &dcb->txqs[j]);
+
+	devm_kfree(DCB_TO_DEV(dcb), dcb->txqs);
+
+	return ret;
+}
+
+static void mtk_dpmaif_tx_res_exit(struct mtk_dpmaif_ctlb *dcb)
+{
+	struct dpmaif_txq *txq;
+	int i;
+
+	if (dcb->db_thread) {
+		kthread_stop(dcb->db_thread);
+		dcb->db_thread = NULL;
+	}
+
+	for (i = 0; i < dcb->txq_cnt; i++) {
+		txq = &dcb->txqs[i];
+		flush_delayed_work(&txq->tx_done_work);
+	}
+
+	if (dcb->tx_done_wq) {
+		flush_workqueue(dcb->tx_done_wq);
+		destroy_workqueue(dcb->tx_done_wq);
+		dcb->tx_done_wq = NULL;
+	}
+
+	for (i = 0; i < dcb->txq_cnt; i++)
+		mtk_dpmaif_txq_exit(dcb, &dcb->txqs[i]);
+
+	devm_kfree(DCB_TO_DEV(dcb), dcb->txqs);
+}
+
+static int mtk_dpmaif_sw_res_init(struct mtk_dpmaif_ctlb *dcb)
+{
+	int ret;
+
+	ret = mtk_dpmaif_bat_res_init(dcb);
+	if (ret < 0)
+		return ret;
+
+	ret = mtk_dpmaif_rx_res_init(dcb);
+	if (ret < 0)
+		goto bat_res_exit;
+
+	ret = mtk_dpmaif_tx_res_init(dcb);
+	if (ret < 0)
+		goto rx_res_exit;
+
+	return 0;
+
+rx_res_exit:
+	mtk_dpmaif_rx_res_exit(dcb);
+
+bat_res_exit:
+	mtk_dpmaif_bat_res_exit(dcb);
+
+	return ret;
+}
+
+static void mtk_dpmaif_sw_res_exit(struct mtk_dpmaif_ctlb *dcb)
+{
+	mtk_dpmaif_tx_res_exit(dcb);
+	mtk_dpmaif_rx_res_exit(dcb);
+	mtk_dpmaif_bat_res_exit(dcb);
+}
+
+static bool mtk_dpmaif_all_vqs_empty_or_busy(struct dpmaif_tx_srv *tx_srv)
+{
+	bool is_empty_or_busy = true;
+	struct dpmaif_vq *vq;
+	int i;
+
+	for (i = 0; i < tx_srv->vq_cnt; i++) {
+		vq = tx_srv->vq[i];
+		if (!skb_queue_empty(&vq->list) && !test_bit(vq->q_id, &tx_srv->txq_drb_lack_sta)) {
+			is_empty_or_busy = false;
+			break;
+		}
+	}
+
+	return is_empty_or_busy;
+}
+
+static void mtk_dpmaif_record_drb_skb(struct mtk_dpmaif_ctlb *dcb, unsigned char q_id,
+				      unsigned short cur_idx, struct sk_buff *skb,
+				      unsigned short is_msg, unsigned short is_frag,
+				      unsigned short is_last, dma_addr_t data_dma_addr,
+				      unsigned int data_len)
+{
+	struct dpmaif_drb_skb *drb_skb = dcb->txqs[q_id].sw_drb_base + cur_idx;
+
+	drb_skb->skb = skb;
+	drb_skb->data_dma_addr = data_dma_addr;
+	drb_skb->data_len = data_len;
+	drb_skb->drb_idx = cur_idx;
+	drb_skb->is_msg = is_msg;
+	drb_skb->is_frag = is_frag;
+	drb_skb->is_last = is_last;
+}
+
+static int mtk_dpmaif_tx_fill_drb(struct mtk_dpmaif_ctlb *dcb,
+				  unsigned char q_id, struct sk_buff *skb)
+{
+	unsigned short cur_idx, cur_backup_idx, is_frag, is_last;
+	unsigned int send_drb_cnt, wt_cnt, payload_cnt;
+	struct dpmaif_txq *txq = &dcb->txqs[q_id];
+	struct dpmaif_drb_skb *cur_drb_skb;
+	struct dpmaif_msg_drb *msg_drb;
+	struct dpmaif_tx_info tx_info;
+	struct dpmaif_pd_drb *pd_drb;
+	struct skb_shared_info *info;
+	dma_addr_t data_dma_addr;
+	unsigned int data_len;
+	skb_frag_t *frag;
+	void *data_addr;
+	int i, ret;
+
+	info = skb_shinfo(skb);
+	if (unlikely(info->frag_list))
+		dev_warn((DCB_TO_MDEV(dcb))->dev, "txq%d not support skb frag_list\n", q_id);
+
+	send_drb_cnt = DPMAIF_GET_DRB_CNT(skb);
+	payload_cnt = send_drb_cnt - 1;
+	cur_idx = txq->drb_wr_idx;
+	cur_backup_idx = cur_idx;
+
+	tx_info.msg_pkt_len = skb->len;
+	tx_info.msg_channel_id = DATA_SKB_CB(skb)->tx.intf_id;
+	tx_info.msg_txcsum = 1;
+
+	/* Update tx drb, a msg drb first, then payload drb. */
+	/* Update and record payload drb information. */
+	msg_drb = (struct dpmaif_msg_drb *)dcb->txqs[txq->id].drb_base + cur_idx;
+	dcb->drv_info->drv_ops->fill_tx_info(msg_drb, &tx_info, MSG_DRB);
+	mtk_dpmaif_record_drb_skb(dcb, txq->id, cur_idx, skb, 1, 0, 0, 0, 0);
+
+	/* Payload drb: skb->data + frags[]. */
+	cur_idx = mtk_dpmaif_ring_buf_get_next_idx(txq->drb_cnt, cur_idx);
+	for (wt_cnt = 0; wt_cnt < payload_cnt; wt_cnt++) {
+		/* Get data_addr and data_len. */
+		if (wt_cnt == 0) {
+			data_len = skb_headlen(skb);
+			data_addr = skb->data;
+			is_frag = 0;
+		} else {
+			frag = info->frags + wt_cnt - 1;
+			data_len = skb_frag_size(frag);
+			data_addr = skb_frag_address(frag);
+			is_frag = 1;
+		}
+
+		if (wt_cnt == payload_cnt - 1)
+			is_last = 1;
+		else
+			is_last = 0;
+
+		data_dma_addr = dma_map_single(DCB_TO_DEV(dcb),
+					       data_addr, data_len, DMA_TO_DEVICE);
+		ret = dma_mapping_error(DCB_TO_DEV(dcb), data_dma_addr);
+		if (unlikely(ret)) {
+			dev_warn((DCB_TO_MDEV(dcb))->dev, "dma mapping fail\n");
+			ret = -DATA_DMA_MAP_ERR;
+			goto unmap_dma;
+		}
+		tx_info.pd_is_last = is_last;
+		tx_info.pd_data_len = data_len;
+		tx_info.pd_data_dma_addr = data_dma_addr;
+
+		/* Update and record payload drb information. */
+		pd_drb = dcb->txqs[txq->id].drb_base + cur_idx;
+		dcb->drv_info->drv_ops->fill_tx_info(pd_drb, &tx_info, PD_DRB);
+		mtk_dpmaif_record_drb_skb(dcb, txq->id, cur_idx, skb, 0, is_frag, is_last,
+					  data_dma_addr, data_len);
+
+		cur_idx = mtk_dpmaif_ring_buf_get_next_idx(txq->drb_cnt, cur_idx);
+	}
+
+	dma_wmb();
+	txq->drb_wr_idx = cur_idx;
+
+	return 0;
+
+unmap_dma:
+	mtk_dpmaif_record_drb_skb(dcb, txq->id, cur_backup_idx, NULL, 0, 0, 0, 0, 0);
+	cur_backup_idx = mtk_dpmaif_ring_buf_get_next_idx(txq->drb_cnt, cur_backup_idx);
+	for (i = 0; i < wt_cnt; i++) {
+		cur_drb_skb = txq->sw_drb_base + cur_backup_idx;
+
+		dma_unmap_single(DCB_TO_DEV(dcb),
+				 cur_drb_skb->data_dma_addr, cur_drb_skb->data_len,
+				 DMA_TO_DEVICE);
+
+		cur_backup_idx = mtk_dpmaif_ring_buf_get_next_idx(txq->drb_cnt, cur_backup_idx);
+		mtk_dpmaif_record_drb_skb(dcb, txq->id, cur_backup_idx, NULL, 0, 0, 0, 0, 0);
+	}
+
+	return ret;
+}
+
+static void mtk_dpmaif_tx_update_ring(struct mtk_dpmaif_ctlb *dcb, struct dpmaif_tx_srv *tx_srv,
+				      struct dpmaif_vq *vq)
+{
+	struct dpmaif_txq *txq = &dcb->txqs[vq->q_id];
+	unsigned char q_id = vq->q_id;
+	unsigned char skb_drb_cnt;
+	int i, drb_available_cnt;
+	struct sk_buff *skb;
+
+	drb_available_cnt = mtk_dpmaif_ring_buf_writable(txq->drb_cnt,
+							 txq->drb_rel_rd_idx, txq->drb_wr_idx);
+
+	for (i = 0; i < DPMAIF_SKB_TX_WEIGHT; i++) {
+		skb = skb_dequeue(&vq->list);
+		if (!skb)
+			break;
+
+		skb_drb_cnt = DPMAIF_GET_DRB_CNT(skb);
+		if (drb_available_cnt < skb_drb_cnt) {
+			skb_queue_head(&vq->list, skb);
+			set_bit(q_id, &tx_srv->txq_drb_lack_sta);
+			break;
+		}
+
+		if (mtk_dpmaif_tx_fill_drb(dcb, q_id, skb) < 0) {
+			skb_queue_head(&vq->list, skb);
+			break;
+		}
+
+		drb_available_cnt -= skb_drb_cnt;
+		atomic_sub(skb_drb_cnt, &txq->budget);
+		atomic_add(skb_drb_cnt, &txq->to_submit_cnt);
+	}
+}
+
+static struct dpmaif_vq *mtk_dpmaif_srv_select_vq(struct dpmaif_tx_srv *tx_srv)
+{
+	struct dpmaif_vq *vq;
+	int i;
+
+	/* Round robin select tx vqs. */
+	for (i = 0; i < tx_srv->vq_cnt; i++) {
+		tx_srv->cur_vq_id = tx_srv->cur_vq_id % tx_srv->vq_cnt;
+		vq = tx_srv->vq[tx_srv->cur_vq_id];
+		tx_srv->cur_vq_id++;
+		if (!skb_queue_empty(&vq->list) && !test_bit(vq->q_id, &tx_srv->txq_drb_lack_sta))
+			return vq;
+	}
+
+	return NULL;
+}
+
+static void mtk_dpmaif_tx(struct dpmaif_tx_srv *tx_srv)
+{
+	struct mtk_dpmaif_ctlb *dcb = tx_srv->dcb;
+	struct dpmaif_vq *vq;
+
+	while (!kthread_should_stop() && (dcb->dpmaif_state == DPMAIF_STATE_PWRON)) {
+		vq = mtk_dpmaif_srv_select_vq(tx_srv);
+		if (!vq)
+			break;
+
+		mtk_dpmaif_tx_update_ring(dcb, tx_srv, vq);
+
+		if (atomic_read(&dcb->txqs[vq->q_id].to_submit_cnt) > 0)
+			mtk_dpmaif_task_wakeup(&dcb->db_task_ctlb);
+
+		cond_resched();
+	}
+}
+
+static int mtk_dpmaif_tx_thread(void *arg)
+{
+	struct dpmaif_tx_srv *tx_srv = arg;
+	struct mtk_dpmaif_ctlb *dcb;
+	int ret;
+
+	dcb = tx_srv->dcb;
+	set_user_nice(current, tx_srv->nice);
+	while (!kthread_should_stop()) {
+		ret = wait_event_interruptible(tx_srv->wait,
+					       (!mtk_dpmaif_all_vqs_empty_or_busy(tx_srv) &&
+					       (dcb->dpmaif_state == DPMAIF_STATE_PWRON)) ||
+					       kthread_should_stop());
+
+		if (ret == -ERESTARTSYS)
+			continue;
+
+		/* Send packets of all tx virtual queues belong to the tx service. */
+		mtk_dpmaif_tx(tx_srv);
+	}
+
+	return 0;
+}
+
+static int mtk_dpmaif_tx_srvs_start(struct mtk_dpmaif_ctlb *dcb)
+{
+	unsigned char srvs_cnt = dcb->drv_info->cfg->tx_srvs_cfg.tx_srv_cnt;
+	struct dpmaif_tx_srv *tx_srv;
+	int i, j, ret;
+
+	for (i = 0; i < srvs_cnt; i++) {
+		tx_srv = &dcb->tx_srvs[i];
+		tx_srv->cur_vq_id = 0;
+		tx_srv->txq_drb_lack_sta = 0;
+		if (tx_srv->srv)
+			continue;
+
+		tx_srv->srv = kthread_run(mtk_dpmaif_tx_thread,
+					  tx_srv, "dpmaif_tx_srv%u_%s",
+					  tx_srv->id, DCB_TO_DEV_STR(dcb));
+		if (IS_ERR(tx_srv->srv)) {
+			dev_err((DCB_TO_MDEV(dcb))->dev,
+				"Failed to alloc dpmaif tx_srv%u\n", tx_srv->id);
+			ret = PTR_ERR(tx_srv->srv);
+			tx_srv->srv = NULL;
+			goto free_tx_srvs;
+		}
+	}
+
+	return 0;
+
+free_tx_srvs:
+	for (j = i - 1; j >= 0; j--) {
+		tx_srv = &dcb->tx_srvs[j];
+		kthread_stop(tx_srv->srv);
+		tx_srv->srv = NULL;
+	}
+
+	return ret;
+}
+
+static void mtk_dpmaif_tx_srvs_stop(struct mtk_dpmaif_ctlb *dcb)
+{
+	unsigned char srvs_cnt = dcb->drv_info->cfg->tx_srvs_cfg.tx_srv_cnt;
+	struct dpmaif_tx_srv *tx_srv;
+	int i;
+
+	for (i = 0; i < srvs_cnt; i++) {
+		tx_srv = &dcb->tx_srvs[i];
+		if (tx_srv->srv) {
+			kthread_stop(tx_srv->srv);
+			tx_srv->srv = NULL;
+		}
+	}
+}
+
+static int mtk_dpmaif_tx_srvs_init(struct mtk_dpmaif_ctlb *dcb)
+{
+	const struct dpmaif_tx_srvs_cfg *tx_srvs_cfg = &dcb->drv_info->cfg->tx_srvs_cfg;
+	struct dpmaif_tx_srv *tx_srv;
+	struct dpmaif_vq *tx_vq;
+	int i, j, vq_id;
+	int ret;
+
+	/* Initialize all data packet tx vitrual queue. */
+	dcb->tx_vqs = devm_kcalloc(DCB_TO_DEV(dcb), tx_srvs_cfg->tx_vq_cnt, sizeof(*dcb->tx_vqs),
+				   GFP_KERNEL);
+	if (!dcb->tx_vqs)
+		return -ENOMEM;
+
+	for (i = 0; i < tx_srvs_cfg->tx_vq_cnt; i++) {
+		tx_vq = &dcb->tx_vqs[i];
+		tx_vq->q_id = i;
+		tx_vq->max_len = DEFAULT_TX_QUEUE_LEN;
+		skb_queue_head_init(&tx_vq->list);
+	}
+
+	/* Initialize all data packet tx services. */
+	dcb->tx_srvs = devm_kcalloc(DCB_TO_DEV(dcb), tx_srvs_cfg->tx_srv_cnt, sizeof(*dcb->tx_srvs),
+				    GFP_KERNEL);
+	if (!dcb->tx_srvs) {
+		ret = -ENOMEM;
+		goto free_tx_vqs;
+	}
+
+	for (i = 0; i < tx_srvs_cfg->tx_srv_cnt; i++) {
+		tx_srv = &dcb->tx_srvs[i];
+		tx_srv->dcb = dcb;
+		tx_srv->id = i;
+		tx_srv->nice = tx_srvs_cfg->tx_srvs[i].nice;
+		tx_srv->cur_vq_id = 0;
+		tx_srv->txq_drb_lack_sta = 0;
+		init_waitqueue_head(&tx_srv->wait);
+
+		/* Set virtual queues and tx service mapping. */
+		tx_srv->vq_cnt = tx_srvs_cfg->tx_srvs[i].vq_cnt;
+		for (j = 0; j < tx_srv->vq_cnt; j++) {
+			vq_id = tx_srvs_cfg->tx_srvs[i].vqs[j];
+			tx_srv->vq[j] = &dcb->tx_vqs[vq_id];
+			tx_srv->vq[j]->srv_id = tx_srv->id;
+		}
+	}
+
+	return 0;
+
+free_tx_vqs:
+	devm_kfree(DCB_TO_DEV(dcb), dcb->tx_vqs);
+
+	return ret;
+}
+
+static void mtk_dpmaif_tx_vqs_reset(struct mtk_dpmaif_ctlb *dcb)
+{
+	unsigned char vqs_cnt = dcb->drv_info->cfg->tx_srvs_cfg.tx_vq_cnt;
+	struct dpmaif_vq *tx_vq;
+	int i;
+
+	/* Drop all packet in tx virtual queues. */
+	for (i = 0; i < vqs_cnt; i++) {
+		tx_vq = &dcb->tx_vqs[i];
+		if (tx_vq)
+			skb_queue_purge(&tx_vq->list);
+	}
+}
+
+static void mtk_dpmaif_tx_srvs_exit(struct mtk_dpmaif_ctlb *dcb)
+{
+	mtk_dpmaif_tx_srvs_stop(dcb);
+	devm_kfree(DCB_TO_DEV(dcb), dcb->tx_srvs);
+	mtk_dpmaif_tx_vqs_reset(dcb);
+	devm_kfree(DCB_TO_DEV(dcb), dcb->tx_vqs);
+}
+
+static void mtk_dpmaif_trans_enable(struct mtk_dpmaif_ctlb *dcb)
+{
+	struct dpmaif_drv_info *drv_info = dcb->drv_info;
+
+	mtk_dpmaif_sw_start_rx(dcb);
+	mtk_dpmaif_enable_irq(dcb);
+
+	if (drv_info->drv_ops->start_queue(drv_info, DPMAIF_RX) < 0) {
+		dev_err((DCB_TO_MDEV(dcb))->dev, "Failed to start dpmaif hw rx\n");
+		mtk_dpmaif_common_err_handle(dcb, true);
+		return;
+	}
+
+	if (drv_info->drv_ops->start_queue(drv_info, DPMAIF_TX) < 0) {
+		dev_err((DCB_TO_MDEV(dcb))->dev, "Failed to start dpmaif hw tx\n");
+		mtk_dpmaif_common_err_handle(dcb, true);
+		return;
+	}
+}
+
+static void mtk_dpmaif_trans_disable(struct mtk_dpmaif_ctlb *dcb)
+{
+	struct dpmaif_drv_info *drv_info = dcb->drv_info;
+	bool io_err = false;
+
+	/* Stop dpmaif hw tx and rx. */
+	if (drv_info->drv_ops->stop_queue(drv_info, DPMAIF_TX) < 0) {
+		io_err = true;
+		dev_err((DCB_TO_MDEV(dcb))->dev, "Failed to stop dpmaif hw tx\n");
+	}
+
+	if (drv_info->drv_ops->stop_queue(drv_info, DPMAIF_RX) < 0) {
+		io_err = true;
+		dev_err((DCB_TO_MDEV(dcb))->dev, "Failed to stop dpmaif hw rx\n");
+	}
+
+	if (io_err)
+		mtk_dpmaif_common_err_handle(dcb, true);
+
+	/* Disable all dpmaif L1 interrupt. */
+	mtk_dpmaif_disable_irq(dcb);
+
+	/* Wait tx done work complete */
+	mtk_dpmaif_sw_wait_tx_stop(dcb);
+
+	/* Stop and wait rx handle done  */
+	mtk_dpmaif_sw_stop_rx(dcb);
+}
+
+static void mtk_dpmaif_trans_ctl(struct mtk_dpmaif_ctlb *dcb, bool enable)
+{
+	if (enable) {
+		if (dcb->dpmaif_state == DPMAIF_STATE_PWRON)
+			mtk_dpmaif_trans_enable(dcb);
+	} else {
+		mtk_dpmaif_trans_disable(dcb);
+	}
+}
+
+static void mtk_dpmaif_cmd_trans_ctl(struct mtk_dpmaif_ctlb *dcb, void *data)
+{
+	struct mtk_data_trans_ctl *trans_ctl = data;
+
+	/* Try best to drop all tx vq packets when disable trans */
+	if (!trans_ctl->enable)
+		mtk_dpmaif_tx_vqs_reset(dcb);
+
+	mutex_lock(&dcb->trans_ctl_lock);
+	mtk_dpmaif_trans_ctl(dcb, trans_ctl->enable);
+	mutex_unlock(&dcb->trans_ctl_lock);
+}
+
+static struct dpmaif_drv_ops *mtk_dpmaif_get_drv_ops(u32 hw_ver)
+{
+	struct dpmaif_drv_ops_desc *p_drv_ops;
+	unsigned char i;
+
+	for (i = 0; (p_drv_ops = &dpmaif_drv_ops_tbl[i]) && p_drv_ops && p_drv_ops->drv_ops; i++)
+		if (p_drv_ops->hw_ver == hw_ver)
+			return p_drv_ops->drv_ops;
+
+	return NULL;
+}
+
+static int mtk_dpmaif_drv_res_init(struct mtk_dpmaif_ctlb *dcb)
+{
+	dcb->drv_info = devm_kzalloc(DCB_TO_DEV(dcb), sizeof(*dcb->drv_info), GFP_KERNEL);
+	if (!dcb->drv_info)
+		return -ENOMEM;
+
+	dcb->drv_info->mdev = DCB_TO_MDEV(dcb);
+	dcb->drv_info->drv_ops = mtk_dpmaif_get_drv_ops(DPMAIF_GET_HW_VER(dcb));
+	if (!dcb->drv_info->drv_ops) {
+		dev_err((DCB_TO_MDEV(dcb))->dev,
+			"Unsupported mdev, hw_ver=0x%x\n", DPMAIF_GET_HW_VER(dcb));
+		devm_kfree(DCB_TO_DEV(dcb), dcb->drv_info);
+		return -EFAULT;
+	}
+
+	dcb->drv_info->drv_ops->init(dcb->drv_info, NULL);
+	dcb->rxq_cnt = dcb->drv_info->cfg->rx_cfg.rxq_cnt;
+	dcb->txq_cnt = dcb->drv_info->cfg->tx_cfg.txq_cnt;
+
+	return 0;
+}
+
+static void mtk_dpmaif_drv_res_exit(struct mtk_dpmaif_ctlb *dcb)
+{
+	devm_kfree(DCB_TO_DEV(dcb), dcb->drv_info);
+}
+
+static void mtk_dpmaif_irq_tx_done(struct mtk_dpmaif_ctlb *dcb, unsigned int q_mask)
+{
+	unsigned int ulq_done;
+	int drb_rd_idx;
+	int i;
+
+	for (i = 0; i < dcb->drv_info->cfg->tx_cfg.txq_cnt; i++) {
+		ulq_done = q_mask & BIT(i);
+		if (!ulq_done)
+			continue;
+
+		drb_rd_idx = dcb->drv_info->drv_ops->get_ring_idx(dcb->drv_info,
+								  DPMAIF_DRB_RIDX, i);
+		if (unlikely(drb_rd_idx < 0)) {
+			dev_err((DCB_TO_MDEV(dcb))->dev,
+				"Failed to read txq%u drb_rd_idx, ret=%d\n",
+				i, drb_rd_idx);
+			mtk_dpmaif_common_err_handle(dcb, true);
+			break;
+		}
+
+		dcb->txqs[i].drb_rd_idx = drb_rd_idx;
+		queue_delayed_work(dcb->tx_done_wq,
+				   &dcb->txqs[i].tx_done_work,
+				   msecs_to_jiffies(0));
+	}
+}
+
+static void mtk_dpmaif_irq_rx_done(struct mtk_dpmaif_ctlb *dcb, unsigned int q_id)
+{
+	struct dpmaif_rxq *rxq;
+	int pit_widx;
+
+	rxq = &dcb->rxqs[q_id];
+	__pm_stay_awake(rxq->ws);
+
+	pit_widx = dcb->drv_info->drv_ops->get_ring_idx(dcb->drv_info, DPMAIF_PIT_WIDX, q_id);
+	if (unlikely(pit_widx < 0)) {
+		dev_err((DCB_TO_MDEV(dcb))->dev,
+			"Failed to read rxq%u hw pit_wr_idx, ret=%d\n",
+			q_id, pit_widx);
+		mtk_dpmaif_common_err_handle(dcb, true);
+		return;
+	}
+
+	rxq->pit_wr_idx = pit_widx;
+	napi_schedule(&rxq->napi);
+}
+
+static void mtk_dpmaif_irq_pit_len_err(struct mtk_dpmaif_ctlb *dcb, unsigned int q_id)
+{
+	dcb->rxqs[q_id].pit_cnt_err_intr_set = true;
+}
+
+static int mtk_dpmaif_irq_handle(int irq_id, void *data)
+{
+	struct dpmaif_drv_intr_info intr_info;
+	struct dpmaif_irq_param *irq_param;
+	struct dpmaif_bat_ring *bat_ring;
+	struct mtk_dpmaif_ctlb *dcb;
+	int bat_id;
+	int ret;
+	int i;
+
+	irq_param = data;
+	dcb = irq_param->dcb;
+
+	if (unlikely(dcb->dpmaif_state != DPMAIF_STATE_PWRON)) {
+		dev_err((DCB_TO_MDEV(dcb))->dev, "Invalid parameter, unexpected dpmaif irq\n");
+		goto out;
+	}
+
+	memset(&intr_info, 0x00, sizeof(struct dpmaif_drv_intr_info));
+	ret = mtk_dpmaif_drv_intr_handle(dcb->drv_info, &intr_info, irq_param->idx);
+	if (ret < 0) {
+		dev_err((DCB_TO_MDEV(dcb))->dev, "Failed to get dpmaif drv irq info\n");
+		goto clean_drv_irq_info;
+	}
+
+	for (i = 0; i < intr_info.intr_cnt; i++) {
+		switch (intr_info.intr_types[i]) {
+		case DPMAIF_INTR_UL_DONE:
+			mtk_dpmaif_irq_tx_done(dcb, intr_info.intr_queues[i]);
+			break;
+		case DPMAIF_INTR_DL_BATCNT_LEN_ERR:
+			bat_id = intr_info.intr_queues[i];
+			bat_ring = &dcb->bat_infos[bat_id].normal_bat_ring;
+			bat_ring->bat_cnt_err_intr_set = true;
+			mtk_dpmaif_task_wakeup(&dcb->bat_infos[bat_id].task_ctlb);
+			break;
+		case DPMAIF_INTR_DL_PITCNT_LEN_ERR:
+			mtk_dpmaif_irq_pit_len_err(dcb, intr_info.intr_queues[i]);
+			break;
+		case DPMAIF_INTR_DL_DONE:
+			mtk_dpmaif_irq_rx_done(dcb, intr_info.intr_queues[i]);
+			break;
+		case DPMAIF_INTR_TRAS_SYNC:
+			break;
+		default:
+			break;
+		}
+	}
+
+clean_drv_irq_info:
+	mtk_pci_clear_irq(DCB_TO_MDEV(dcb), irq_param->dev_irq_id);
+	mtk_pci_unmask_irq(DCB_TO_MDEV(dcb), irq_param->dev_irq_id);
+out:
+	return IRQ_HANDLED;
+}
+
+static int mtk_dpmaif_irq_init(struct mtk_dpmaif_ctlb *dcb)
+{
+	unsigned char irq_cnt = dcb->drv_info->cfg->intr_cfg.irq_cnt;
+	struct dpmaif_irq_param *irq_param;
+	enum mtk_irq_src irq_src;
+	int i, j;
+	int ret;
+
+	dcb->irq_params = devm_kcalloc(DCB_TO_DEV(dcb), irq_cnt, sizeof(*irq_param), GFP_KERNEL);
+	if (!dcb->irq_params)
+		return -ENOMEM;
+
+	for (i = 0; i < irq_cnt; i++) {
+		irq_param = &dcb->irq_params[i];
+		irq_param->idx = i;
+		irq_param->dcb = dcb;
+		irq_src = dcb->drv_info->cfg->intr_cfg.irqs[i].id;
+		irq_param->dpmaif_irq_src = irq_src;
+		irq_param->dev_irq_id = mtk_pci_get_irq_id(DCB_TO_MDEV(dcb), irq_src);
+		if (irq_param->dev_irq_id < 0) {
+			dev_err((DCB_TO_MDEV(dcb))->dev,
+				"Failed to allocate irq id, irq_src=%d\n", irq_src);
+			ret = -EINVAL;
+			goto unregister_irq;
+		}
+
+		ret = mtk_pci_register_irq(DCB_TO_MDEV(dcb), irq_param->dev_irq_id,
+					   mtk_dpmaif_irq_handle, irq_param);
+		if (ret < 0) {
+			dev_err((DCB_TO_MDEV(dcb))->dev,
+				"Failed to register irq, irq_src=%d\n", irq_src);
+			goto unregister_irq;
+		}
+		irq_param->dev_virq_id = mtk_pci_get_virq_id(DCB_TO_MDEV(dcb),
+							     irq_param->dev_irq_id);
+	}
+
+	/* HW layer default mask dpmaif interrupt. */
+	dcb->irq_enabled = false;
+
+	return 0;
+
+unregister_irq:
+	for (j = i - 1; j >= 0; j--) {
+		irq_param = &dcb->irq_params[j];
+		mtk_pci_unregister_irq(DCB_TO_MDEV(dcb), irq_param->dev_irq_id);
+	}
+
+	devm_kfree(DCB_TO_DEV(dcb), dcb->irq_params);
+
+	return ret;
+}
+
+static int mtk_dpmaif_irq_exit(struct mtk_dpmaif_ctlb *dcb)
+{
+	unsigned char irq_cnt = dcb->drv_info->cfg->intr_cfg.irq_cnt;
+	struct dpmaif_irq_param *irq_param;
+	int i;
+
+	for (i = 0; i < irq_cnt; i++) {
+		irq_param = &dcb->irq_params[i];
+		mtk_pci_unregister_irq(DCB_TO_MDEV(dcb), irq_param->dev_irq_id);
+	}
+
+	devm_kfree(DCB_TO_DEV(dcb), dcb->irq_params);
+
+	return 0;
+}
+
+static int mtk_dpmaif_port_cfg(struct mtk_dpmaif_ctlb *dcb)
+{
+	struct mtk_data_trans_info *trans_info = &dcb->data_blk->trans_info;
+	struct dpmaif_drv_cfg *cfg = dcb->drv_info->cfg;
+	struct dpmaif_rxq *rxq;
+	int i;
+
+	memset(trans_info, 0x00, sizeof(struct mtk_data_trans_info));
+
+	trans_info->txq_cnt = cfg->tx_cfg.txq_cnt;
+	trans_info->rxq_cnt = cfg->rx_cfg.rxq_cnt;
+	trans_info->max_mtu = cfg->rx_cfg.mtu;
+
+	for (i = 0; i < trans_info->rxq_cnt; i++) {
+		rxq = &dcb->rxqs[i];
+		dcb->napi[i] = &rxq->napi;
+	}
+	trans_info->napis = dcb->napi;
+
+	return 0;
+}
+
+static int mtk_dpmaif_hw_init(struct mtk_dpmaif_ctlb *dcb)
+{
+	unsigned int bat_ring_num = dcb->drv_info->cfg->rx_cfg.bat_ring_num;
+	struct dpmaif_drv_cfg *cfg = dcb->drv_info->cfg;
+	struct dpmaif_bat_ring *bat_ring;
+	unsigned int bat_reload_cnt;
+	struct dpmaif_rxq *rxq;
+	struct dpmaif_txq *txq;
+	int ret, i;
+
+	for (i = 0; i < bat_ring_num; i++) {
+		bat_ring = &dcb->bat_infos[i].normal_bat_ring;
+		bat_reload_cnt = atomic_read(&bat_ring->to_reload_cnt);
+		mtk_dpmaif_reload_rx_buff(dcb, bat_ring, bat_reload_cnt);
+		if (!atomic_read(&bat_ring->reload_cnt)) {
+			dev_err((DCB_TO_MDEV(dcb))->dev, "Failed to reload normal bat%d buf\n", i);
+			return -ENOMEM;
+		}
+
+		cfg->rx_cfg.bats[i].bat_base = bat_ring->bat_dma_addr;
+		cfg->rx_cfg.bats[i].buf_size = bat_ring->buf_size;
+		cfg->rx_cfg.bats[i].real_reload_cnt = atomic_read(&bat_ring->reload_cnt);
+	}
+
+	for (i = 0; i < cfg->rx_cfg.rxq_cnt; i++) {
+		rxq = &dcb->rxqs[i];
+		cfg->rx_cfg.rxqs[i].pit_base = rxq->pit_dma_addr;
+	}
+
+	for (i = 0; i < cfg->tx_cfg.txq_cnt; i++) {
+		txq = &dcb->txqs[i];
+		cfg->tx_cfg.txqs[i].drb_base = txq->drb_dma_addr;
+	}
+
+	ret = dcb->drv_info->drv_ops->init(dcb->drv_info, NULL);
+	if (ret < 0)
+		dev_err((DCB_TO_MDEV(dcb))->dev, "Failed to initialize dpmaif hw\n");
+
+	for (i = 0; i < bat_ring_num; i++) {
+		bat_ring = &dcb->bat_infos[i].normal_bat_ring;
+		atomic_sub(cfg->rx_cfg.bats[i].real_reload_cnt, &bat_ring->reload_cnt);
+	}
+	return ret;
+}
+
+static int mtk_dpmaif_start(struct mtk_md_dev *mdev)
+{
+	struct mtk_dpmaif_ctlb *dcb = ((struct mtk_data_blk *)(mdev->data_blk))->dcb;
+	int ret;
+
+	if (dcb->dpmaif_state == DPMAIF_STATE_PWRON) {
+		dev_warn((DCB_TO_MDEV(dcb))->dev, "Invalid parameters, dpmaif_state in PWRON\n");
+		ret = -EINVAL;
+		goto out;
+	}
+
+	/* Initialize dpmaif hw. */
+	ret = mtk_dpmaif_hw_init(dcb);
+	if (ret < 0) {
+		dev_err((DCB_TO_MDEV(dcb))->dev, "Failed to initialize dpmaif hw\n");
+		goto out;
+	}
+
+	/* Initialize and run all tx services. */
+	ret = mtk_dpmaif_tx_srvs_start(dcb);
+	if (ret) {
+		dev_warn((DCB_TO_MDEV(dcb))->dev, "Failed to start all tx srvs\n");
+		goto out;
+	}
+
+	dcb->dpmaif_state = DPMAIF_STATE_PWRON;
+	dcb->dpmaif_sw_reset = false;
+	mtk_dpmaif_disable_irq(dcb);
+
+	return 0;
+out:
+	return ret;
+}
+
+static void mtk_dpmaif_sw_reset(struct mtk_dpmaif_ctlb *dcb)
+{
+	if (!dcb->dpmaif_sw_reset) {
+		dcb->dpmaif_sw_reset = true;
+		mtk_dpmaif_tx_res_reset(dcb);
+		mtk_dpmaif_rx_res_reset(dcb);
+		mtk_dpmaif_bat_res_reset(dcb);
+		mtk_dpmaif_tx_vqs_reset(dcb);
+	}
+}
+
+static int mtk_dpmaif_stop(struct mtk_md_dev *mdev)
+{
+	struct mtk_dpmaif_ctlb *dcb = ((struct mtk_data_blk *)(mdev->data_blk))->dcb;
+
+	if (dcb->dpmaif_state == DPMAIF_STATE_PWROFF)
+		goto out;
+
+	dcb->dpmaif_state = DPMAIF_STATE_PWROFF;
+
+	/* Stop all tx service. */
+	mtk_dpmaif_tx_srvs_stop(dcb);
+
+	mutex_lock(&dcb->trans_ctl_lock);
+
+	/* Stop dpmaif tx/rx handle. */
+	mtk_dpmaif_trans_ctl(dcb, false);
+
+	mutex_unlock(&dcb->trans_ctl_lock);
+
+out:
+	return 0;
+}
+
+static void mtk_dpmaif_clear(struct mtk_md_dev *mdev)
+{
+	struct mtk_dpmaif_ctlb *dcb = ((struct mtk_data_blk *)(mdev->data_blk))->dcb;
+
+	mtk_dpmaif_sw_reset(dcb);
+}
+
+static int mtk_dpmaif_sw_init(struct mtk_md_dev *mdev)
+{
+	struct mtk_data_blk *data_blk = mdev->data_blk;
+	struct mtk_dpmaif_ctlb *dcb;
+	int ret;
+
+	dcb = devm_kzalloc(data_blk->mdev->dev, sizeof(*dcb), GFP_KERNEL);
+	if (!dcb)
+		return -ENOMEM;
+
+	data_blk->dcb = dcb;
+	dcb->data_blk = data_blk;
+	dcb->dpmaif_state = DPMAIF_STATE_PWROFF;
+	dcb->dpmaif_sw_reset = false;
+	mutex_init(&dcb->trans_ctl_lock);
+
+	ret = mtk_dpmaif_drv_res_init(dcb);
+	if (ret < 0)
+		goto free_dcb;
+
+	ret = mtk_dpmaif_sw_res_init(dcb);
+	if (ret < 0)
+		goto drv_res_exit;
+
+	ret = mtk_dpmaif_tx_srvs_init(dcb);
+	if (ret < 0)
+		goto sw_res_exit;
+
+	ret = mtk_dpmaif_port_cfg(dcb);
+	if (ret < 0)
+		goto tx_srvs_exit;
+
+	ret = mtk_dpmaif_irq_init(dcb);
+	if (ret < 0)
+		goto tx_srvs_exit;
+
+	return 0;
+
+tx_srvs_exit:
+	mtk_dpmaif_tx_srvs_exit(dcb);
+sw_res_exit:
+	mtk_dpmaif_sw_res_exit(dcb);
+drv_res_exit:
+	mtk_dpmaif_drv_res_exit(dcb);
+free_dcb:
+	devm_kfree(DCB_TO_DEV(dcb), dcb);
+
+	return ret;
+}
+
+static int mtk_dpmaif_sw_exit(struct mtk_md_dev *mdev)
+{
+	struct mtk_dpmaif_ctlb *dcb = ((struct mtk_data_blk *)(mdev->data_blk))->dcb;
+
+	if (!dcb) {
+		pr_err("Invalid parameter\n");
+		return -EINVAL;
+	}
+
+	mtk_dpmaif_irq_exit(dcb);
+	mtk_dpmaif_tx_srvs_exit(dcb);
+	mtk_dpmaif_sw_res_exit(dcb);
+	mtk_dpmaif_drv_res_exit(dcb);
+
+	devm_kfree(DCB_TO_DEV(dcb), dcb);
+	return 0;
+}
+
+static int mtk_dpmaif_poll_rx_pit(struct dpmaif_rxq *rxq)
+{
+	struct mtk_dpmaif_ctlb *dcb = rxq->dcb;
+	unsigned int sw_rd_idx, hw_wr_idx;
+	unsigned int pit_cnt;
+	int ret;
+
+	sw_rd_idx = rxq->pit_rd_idx;
+	ret = dcb->drv_info->drv_ops->get_ring_idx(dcb->drv_info, DPMAIF_PIT_WIDX, rxq->id);
+	if (unlikely(ret < 0)) {
+		dev_err((DCB_TO_MDEV(dcb))->dev,
+			"Failed to read rxq%u hw pit_wr_idx, ret=%d\n",
+			rxq->id, ret);
+		mtk_dpmaif_common_err_handle(dcb, true);
+		goto out;
+	}
+
+	hw_wr_idx = ret;
+	pit_cnt = mtk_dpmaif_ring_buf_readable(rxq->pit_cnt, sw_rd_idx, hw_wr_idx);
+	rxq->pit_wr_idx = hw_wr_idx;
+
+	return pit_cnt;
+
+out:
+	return ret;
+}
+
+static int mtk_dpmaif_pit_bid_check(struct dpmaif_rxq *rxq, unsigned int cur_bid)
+{
+	union dpmaif_bat_record *cur_bat_record;
+	struct mtk_dpmaif_ctlb *dcb = rxq->dcb;
+	struct dpmaif_bat_ring *bat_ring;
+
+	bat_ring = &rxq->dcb->bat_infos[rxq->bat_ring_id].normal_bat_ring;
+	cur_bat_record = bat_ring->sw_record_base + cur_bid;
+
+	if (unlikely(!cur_bat_record->normal.skb || cur_bid >= bat_ring->bat_cnt)) {
+		dev_err((DCB_TO_MDEV(dcb))->dev,
+			"Invalid parameter rxq%u bat%u, bid=%u, bat_cnt=%u\n",
+			rxq->id, bat_ring->id, cur_bid, bat_ring->bat_cnt);
+
+		return -DATA_FLOW_CHK_ERR;
+	}
+
+	rxq->pit_bid = cur_bid;
+
+	return 0;
+}
+
+static int mtk_dpmaif_rx_set_data_to_skb(struct dpmaif_rxq *rxq, struct dpmaif_pd_pit *pit_info,
+					 struct dpmaif_rx_record *rx_record)
+{
+	struct dpmaif_bat_ring *bat_ring = &rxq->dcb->bat_infos[rxq->bat_ring_id].normal_bat_ring;
+	struct mtk_dpmaif_ctlb *dcb = rxq->dcb;
+	unsigned long long data_dma_base_addr;
+	union dpmaif_bat_record *bat_record;
+	unsigned int data_len;
+	struct sk_buff *new_skb;
+	int data_offset;
+
+	bat_record = bat_ring->sw_record_base + rxq->rx_info->pit_pd_cur_bid;
+	new_skb = bat_record->normal.skb;
+	data_dma_base_addr = (unsigned long long)bat_record->normal.data_dma_addr;
+
+	dma_unmap_single(DCB_TO_DEV(dcb), bat_record->normal.data_dma_addr,
+			 bat_record->normal.data_len, DMA_FROM_DEVICE);
+
+	/* Calculate data address and data length. */
+	data_offset = (int)(rxq->rx_info->pit_pd_dma_addr - data_dma_base_addr);
+	data_len = rxq->rx_info->pit_pd_data_len;
+
+	/* Check and rebuild skb. */
+	new_skb->len = 0;
+	if (unlikely((new_skb->tail + data_offset + data_len) > new_skb->end)) {
+		dev_err((DCB_TO_MDEV(dcb))->dev,
+			"Invalid packet(%u/%u):data_len=%u,offset=0x%llx-0x%llx,skb(%llx,%llx,%u,%u)\n",
+			rxq->pit_rd_idx, rxq->rx_info->pit_pd_cur_bid,
+			data_len, rxq->rx_info->pit_pd_dma_addr,
+			data_dma_base_addr, (u64)new_skb->head,
+			(u64)new_skb->data, (unsigned int)new_skb->tail,
+			(unsigned int)new_skb->end);
+
+		return -DATA_FLOW_CHK_ERR;
+	}
+
+	skb_put(new_skb, data_offset + data_len);
+	skb_pull(new_skb, data_offset);
+
+	__skb_queue_tail(&rx_record->rx_list, new_skb);
+	rx_record->cur_skb = new_skb;
+
+	bat_record->normal.skb = NULL;
+
+	return 0;
+}
+
+static void mtk_dpmaif_bat_ring_set_mask(struct mtk_dpmaif_ctlb *dcb,
+					 unsigned int bat_idx, int bat_ring_id)
+{
+	struct dpmaif_bat_ring *bat_ring;
+
+	bat_ring = &dcb->bat_infos[bat_ring_id].normal_bat_ring;
+
+	set_bit(bat_idx, bat_ring->mask_tbl);
+
+	atomic_inc(&bat_ring->bat_stats);
+	atomic_inc(&bat_ring->to_reload_cnt);
+}
+
+static int mtk_dpmaif_get_rx_pkt(struct dpmaif_rxq *rxq, struct dpmaif_pd_pit *pit_info,
+				 struct dpmaif_rx_record *rx_record)
+{
+	struct mtk_dpmaif_ctlb *dcb = rxq->dcb;
+	int ret;
+
+	/* Check the bid in pit information, don't exceed bat size. */
+	ret = mtk_dpmaif_pit_bid_check(rxq, rxq->rx_info->pit_pd_cur_bid);
+	if (unlikely(ret < 0))
+		goto out;
+
+	/* Receive data from bat and save to rx_record. */
+	ret = mtk_dpmaif_rx_set_data_to_skb(rxq, pit_info, rx_record);
+	if (unlikely(ret < 0))
+		goto out;
+
+	/* Make sure saving data from bat is completed. */
+	wmb();
+
+	/* Set bat mask that have been received. */
+	mtk_dpmaif_bat_ring_set_mask(dcb, rxq->rx_info->pit_pd_cur_bid, rxq->bat_ring_id);
+
+	return 0;
+
+out:
+	return ret;
+}
+
+static int mtk_dpmaif_update_rx_skb_info(struct sk_buff *skb,
+					 struct dpmaif_rxq *rxq, struct dpmaif_rx_record *rx_record)
+{
+	union mtk_data_pkt_info *pkt_info = DATA_SKB_CB(skb);
+	unsigned int gso_type = 0;
+	unsigned short l4_proto;
+	int inner_offset;
+	__be16 frag_off;
+	u8 packet_type;
+	u8 nexthdr;
+
+	skb_reset_network_header(skb);
+	skb_reset_mac_header(skb);
+
+	skb_set_hash(skb, rxq->rx_info->pit_msg_hash, PKT_HASH_TYPE_L4);
+	skb_record_rx_queue(skb, rxq->id);
+
+	if (rxq->rx_info->pit_msg_checksum == CS_RESULT_PASS) {
+		skb->ip_summed = CHECKSUM_UNNECESSARY;
+		if (rxq->rx_info->pit_msg_ip == DPMAIF_PIT_IPV4)
+			skb->protocol = htons(ETH_P_IP);
+		else
+			skb->protocol = htons(ETH_P_IPV6);
+
+		if (rxq->rx_info->pit_msg_pro == DPMAIF_PIT_TCP) {
+			gso_type = SKB_GSO_TCPV4;
+			rx_record->ip_protocol = IPPROTO_TCP;
+		} else if (rxq->rx_info->pit_msg_pro == DPMAIF_PIT_UDP) {
+			rx_record->ip_protocol = IPPROTO_UDP;
+		} else {
+			goto out;
+		}
+	} else {
+		packet_type = skb->data[0] & 0xF0;
+		skb->ip_summed = CHECKSUM_NONE;
+		if (packet_type == IPV4_VERSION) {
+			skb->protocol = htons(ETH_P_IP);
+			l4_proto = ((struct iphdr *)skb->data)->protocol;
+			rx_record->ip_protocol = l4_proto;
+			if (l4_proto == IPPROTO_TCP)
+				gso_type = SKB_GSO_TCPV4;
+			else
+				goto out;
+
+		} else if (packet_type == IPV6_VERSION) {
+			skb->protocol = htons(ETH_P_IPV6);
+			nexthdr = ((struct ipv6hdr *)skb->data)->nexthdr;
+			/* Now skip over extension headers. */
+			inner_offset = ipv6_skip_exthdr(skb, sizeof(struct ipv6hdr),
+							&nexthdr, &frag_off);
+			if (unlikely(inner_offset < 0))
+				goto out;
+
+			rx_record->ip_protocol = nexthdr;
+			if (nexthdr == IPPROTO_TCP)
+				gso_type = SKB_GSO_TCPV6;
+			else
+				goto out;
+
+		} else {
+			dev_err((DCB_TO_MDEV(rxq->dcb))->dev,
+				"Invalid packet type, value=%u\n", packet_type);
+			goto free_skb;
+		}
+	}
+
+out:
+	pkt_info->rx.ch_id = rxq->rx_info->pit_msg_chnl_id;
+	pkt_info->rx.q_id = rxq->id;
+
+	return 0;
+
+free_skb:
+	dev_kfree_skb_any(skb);
+
+	return -DATA_HW_UNK_PKT;
+}
+
+static int mtk_dpmaif_rx_skb(struct dpmaif_rxq *rxq, struct dpmaif_rx_record *rx_record)
+{
+	struct sk_buff *new_skb;
+	int ret;
+
+	if (unlikely(rxq->rx_info->pit_msg_dp || rxq->rx_info->pit_msg_err)) {
+		__skb_queue_purge(&rx_record->rx_list);
+		return 0;
+	}
+
+	do {
+		/* Logically, the rx_list should contain at least one skb. */
+		new_skb = __skb_dequeue(&rx_record->rx_list);
+		ret = mtk_dpmaif_update_rx_skb_info(new_skb, rxq, rx_record);
+		if (unlikely(ret < 0))
+			continue;
+
+		/* Send skb to data port. */
+		/* Data would be sent to network stack here */
+	} while (!skb_queue_empty(&rx_record->rx_list));
+
+	return ret;
+}
+
+static void mtk_dpmaif_recycle_pit_internal(struct dpmaif_rxq *rxq, unsigned short pit_rel_cnt)
+{
+	unsigned short old_sw_rel_idx, new_sw_rel_idx, old_hw_wr_idx;
+	struct mtk_dpmaif_ctlb *dcb = rxq->dcb;
+
+	old_sw_rel_idx = rxq->pit_rel_rd_idx;
+	new_sw_rel_idx = old_sw_rel_idx + pit_rel_cnt;
+	old_hw_wr_idx = rxq->pit_wr_idx;
+
+	/* pit_rel_rd_idx should not exceed pit_wr_idx. */
+	if (old_hw_wr_idx < old_sw_rel_idx) {
+		if (new_sw_rel_idx >= rxq->pit_cnt)
+			new_sw_rel_idx = new_sw_rel_idx - rxq->pit_cnt;
+	}
+
+	atomic_add(pit_rel_cnt, &rxq->pit_rel_cnt);
+	rxq->pit_rel_rd_idx = new_sw_rel_idx;
+
+	if (atomic_read(&rxq->pit_rel_cnt) >= rxq->pit_burst_rel_cnt)
+		mtk_dpmaif_task_wakeup(&dcb->db_task_ctlb);
+}
+
+static int mtk_dpmaif_recycle_rx_ring(struct dpmaif_rxq *rxq)
+{
+	unsigned int pit_rel_cnt;
+
+	pit_rel_cnt = mtk_dpmaif_ring_buf_releasable(rxq->pit_cnt,
+						     rxq->pit_rel_rd_idx,
+						     rxq->pit_rd_idx);
+
+	if (unlikely(pit_rel_cnt > rxq->pit_cnt)) {
+		dev_err((DCB_TO_MDEV(rxq->dcb))->dev,
+			"Invalid rxq%u pit release count, %u>%u\n",
+			rxq->id, pit_rel_cnt, rxq->pit_cnt);
+		mtk_dpmaif_common_err_handle(rxq->dcb, false);
+		return -DATA_FLOW_CHK_ERR;
+	}
+
+	mtk_dpmaif_recycle_pit_internal(rxq, pit_rel_cnt);
+	mtk_dpmaif_task_wakeup(&rxq->dcb->bat_infos[rxq->bat_ring_id].task_ctlb);
+
+	return 0;
+}
+
+#define DPMAIF_PIT_SEQ_CHECK_FAIL_CNT 2500
+
+static int mtk_dpmaif_rx_data_collect_internal(struct dpmaif_rxq *rxq, int pit_cnt,
+					       unsigned int *pkt_cnt)
+{
+	unsigned long time_limit = jiffies + msecs_to_jiffies(2);
+	struct dpmaif_rx_record *rx_record = &rxq->rx_record;
+	unsigned int recv_pkt_cnt = 0, pit_rd_cnt = 0;
+	struct mtk_dpmaif_ctlb *dcb = rxq->dcb;
+	struct dpmaif_pd_pit *pit_info;
+	struct dpmaif_rx_info rx_info;
+	unsigned int rx_cnt, cur_pit;
+	int ret = 0;
+
+	cur_pit = rxq->pit_rd_idx;
+	for (rx_cnt = 0; rx_cnt < pit_cnt; rx_cnt++) {
+		if (!rx_record->msg_pit_recv && time_after_eq(jiffies, time_limit)) {
+			ret = -DATA_DL_ONCE_MORE;
+			break;
+		}
+
+		/* Pit sequence check. */
+		pit_info = rxq->pit_base + cur_pit;
+		ret = dcb->drv_info->drv_ops->get_rx_info(pit_info, &rx_info,
+						rxq->pit_seq_expect, rxq->id);
+		if (likely(!ret)) {
+			rxq->pit_seq_expect++;
+			if (rxq->pit_seq_expect >= rxq->pit_seq_max)
+				rxq->pit_seq_expect = 0;
+
+			rxq->pit_seq_fail_cnt = 0;
+		} else {
+			rxq->pit_seq_fail_cnt++;
+			if (rxq->pit_seq_fail_cnt >= DPMAIF_PIT_SEQ_CHECK_FAIL_CNT) {
+				rxq->pit_seq_fail_cnt = 0;
+				return -DATA_FLOW_CHK_ERR;
+			}
+			break;
+		}
+		rxq->rx_info = &rx_info;
+
+		/* Parse message pit. */
+		if (rx_info.msg_pit) {
+			if (unlikely(rx_record->msg_pit_recv)) {
+				__skb_queue_purge(&rx_record->rx_list);
+				memset(rx_record, 0x00, sizeof(*rx_record));
+				__skb_queue_head_init(&rx_record->rx_list);
+				dev_err((DCB_TO_MDEV(dcb))->dev,
+					"Invalid pit, rxq%u two continuous message pit\n",
+					rxq->id);
+				return -DATA_FLOW_CHK_ERR;
+			}
+
+			rx_record->msg_pit_recv = true;
+
+		} else {
+			/* Parse normal pit. */
+			ret = mtk_dpmaif_get_rx_pkt(rxq, pit_info, rx_record);
+
+			if (unlikely(ret < 0)) {
+				__skb_queue_purge(&rx_record->rx_list);
+
+				dev_err((DCB_TO_MDEV(dcb))->dev,
+					"Invalid packet, error payload, rxq%u pit_idx=%d\n",
+					rxq->id, cur_pit);
+				return ret;
+			}
+
+			/* Last one pit of a packet. */
+			if (!rx_info.pit_continue) {
+				mtk_dpmaif_rx_skb(rxq, rx_record);
+				memset(rx_record, 0x00, sizeof(*rx_record));
+				__skb_queue_head_init(&rx_record->rx_list);
+				recv_pkt_cnt++;
+			}
+		}
+
+		cur_pit = mtk_dpmaif_ring_buf_get_next_idx(rxq->pit_cnt, cur_pit);
+		rxq->pit_rd_idx = cur_pit;
+
+		pit_rd_cnt++;
+		/* Recycle pit/bat in batches (rx packet budget). */
+		if (pit_rd_cnt == DPMAIF_PIT_CNT_UPDATE_THRESHOLD) {
+			atomic_add(DPMAIF_PIT_CNT_UPDATE_THRESHOLD, &rxq->pit_stats);
+			mtk_dpmaif_recycle_rx_ring(rxq);
+			pit_rd_cnt = 0;
+		}
+	}
+
+	if (pit_rd_cnt) {
+		atomic_add(pit_rd_cnt, &rxq->pit_stats);
+		mtk_dpmaif_recycle_rx_ring(rxq);
+	}
+
+	*pkt_cnt = recv_pkt_cnt;
+
+	return ret;
+}
+
+static int mtk_dpmaif_rx_data_collect(struct dpmaif_rxq *rxq, unsigned int *pkt_cnt)
+{
+	struct mtk_dpmaif_ctlb *dcb = rxq->dcb;
+	unsigned int pit_cnt;
+	int ret;
+
+	ret = mtk_dpmaif_poll_rx_pit(rxq);
+	if (unlikely(ret < 0))
+		return ret;
+
+	pit_cnt = ret;
+
+	/* Collect rx packets. */
+	if (likely(pit_cnt > 0)) {
+		ret = mtk_dpmaif_rx_data_collect_internal(rxq, pit_cnt, pkt_cnt);
+		if (ret <= -DATA_DL_ONCE_MORE) {
+			ret = -DATA_DL_ONCE_MORE;
+		} else if (ret <= -DATA_ERR_STOP_MAX) {
+			ret = -DATA_ERR_STOP_MAX;
+			mtk_dpmaif_common_err_handle(dcb, true);
+		} else {
+			ret = 0;
+		}
+	}
+
+	return ret;
+}
+
+static int mtk_dpmaif_rx_data_collect_more(struct dpmaif_rxq *rxq, int *work_done)
+{
+	unsigned long time_limit = jiffies + msecs_to_jiffies(2);
+	unsigned int total_pkt_cnt = 0, pkt_cnt;
+	int ret = 0;
+
+	do {
+		if (time_after_eq(jiffies, time_limit)) {
+			ret = -DATA_DL_ONCE_MORE;
+			break;
+		}
+
+		pkt_cnt = 0;
+		ret = mtk_dpmaif_rx_data_collect(rxq, &pkt_cnt);
+		total_pkt_cnt += pkt_cnt;
+		if (ret < 0)
+			break;
+	} while (pkt_cnt > 0 && rxq->started);
+
+	*work_done = total_pkt_cnt;
+
+	return ret;
+}
+
+static int mtk_dpmaif_rx_napi_poll(struct napi_struct *napi, int budget)
+{
+	struct dpmaif_rxq *rxq = container_of(napi, struct dpmaif_rxq, napi);
+	struct mtk_dpmaif_ctlb *dcb = rxq->dcb;
+	int work_done = 0;
+	int ret = 0;
+
+	if (likely(rxq->started)) {
+		ret = mtk_dpmaif_rx_data_collect_more(rxq, &work_done);
+
+		if (ret == -DATA_DL_ONCE_MORE) {
+			napi_gro_flush(napi, false);
+			work_done = budget;
+		} else {
+			if (unlikely(ret == -DATA_ERR_STOP_MAX))
+				rxq->started = false;
+			if (work_done > budget)
+				work_done = budget - 1;
+		}
+	}
+
+	if (work_done < budget) {
+		napi_complete_done(napi, work_done);
+		__pm_wakeup_event(rxq->ws, jiffies_to_msecs(HZ));
+		mtk_dpmaif_drv_intr_complete(dcb->drv_info, DPMAIF_INTR_DL_DONE, rxq->id, 0);
+	}
+
+	return work_done;
+}
+
+static int mtk_dpmaif_send_pkt(struct mtk_dpmaif_ctlb *dcb, struct sk_buff *skb)
+{
+	unsigned char vq_id = skb_get_queue_mapping(skb);
+	struct dpmaif_vq *vq;
+	int ret = 0;
+
+	vq = &dcb->tx_vqs[vq_id];
+	if (likely(skb_queue_len(&vq->list) < vq->max_len))
+		skb_queue_tail(&vq->list, skb);
+	else
+		ret = -EBUSY;
+
+	wake_up(&dcb->tx_srvs[vq->srv_id].wait);
+
+	return ret;
+}
+
+static int mtk_dpmaif_send_cmd(struct mtk_dpmaif_ctlb *dcb, struct sk_buff *skb)
+{
+	struct mtk_data_cmd *cmd_info = SKB_TO_CMD(skb);
+
+	if (dcb->dpmaif_state != DPMAIF_STATE_PWRON)
+		return -EINVAL;
+
+	switch (cmd_info->cmd) {
+	case DATA_CMD_TRANS_CTL:
+		mtk_dpmaif_cmd_trans_ctl(dcb, CMD_TO_DATA(cmd_info));
+		break;
+	default:
+		dev_warn((DCB_TO_MDEV(dcb))->dev, "Unknown cmd type=%d\n", cmd_info->cmd);
+		return -EOPNOTSUPP;
+	}
+
+	return 0;
+}
+
+static int mtk_dpmaif_send(struct mtk_data_blk *data_blk, enum mtk_data_type type,
+			   struct sk_buff *skb)
+{
+	struct mtk_dpmaif_ctlb *dcb;
+	int ret;
+
+	if (unlikely(!data_blk || !data_blk->dcb)) {
+		pr_warn("Invalid parameter\n");
+		return -EINVAL;
+	}
+
+	dcb = data_blk->dcb;
+
+	if (unlikely(dcb->dpmaif_state == DPMAIF_STATE_PWROFF))
+		return -EINVAL;
+
+	if (likely(type == DATA_PKT))
+		ret = mtk_dpmaif_send_pkt(dcb, skb);
+	else
+		ret = mtk_dpmaif_send_cmd(dcb, skb);
+
+	return ret;
+}
+
+static struct mtk_data_hif_ops pcie_data_ops = {
+	.init = mtk_dpmaif_sw_init,
+	.exit = mtk_dpmaif_sw_exit,
+	.stop = mtk_dpmaif_stop,
+	.start = mtk_dpmaif_start,
+	.clear = mtk_dpmaif_clear,
+	.poll = mtk_dpmaif_rx_napi_poll,
+	.send = mtk_dpmaif_send,
+};
+
+int mtk_pcie_data_init(struct mtk_md_dev *mdev)
+{
+	return mtk_data_init(mdev, &pcie_data_ops);
+}
+
+int mtk_pcie_data_exit(struct mtk_md_dev *mdev)
+{
+	return mtk_data_exit(mdev);
+}
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_dpmaif.h b/drivers/net/wwan/t9xx/pcie/mtk_dpmaif.h
new file mode 100644
index 000000000000..e7e2f333141c
--- /dev/null
+++ b/drivers/net/wwan/t9xx/pcie/mtk_dpmaif.h
@@ -0,0 +1,14 @@
+/* SPDX-License-Identifier: GPL-2.0-only
+ *
+ * Copyright (c) 2022, MediaTek Inc.
+ */
+
+#ifndef __MTK_DPMAIF_H__
+#define __MTK_DPMAIF_H__
+
+#include "mtk_dev.h"
+
+int mtk_pcie_data_init(struct mtk_md_dev *mdev);
+int mtk_pcie_data_exit(struct mtk_md_dev *mdev);
+
+#endif /* __MTK_DPMAIF_H__ */
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_drv.c b/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_drv.c
index 3fd2b33d1199..077600389ab4 100644
--- a/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_drv.c
+++ b/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_drv.c
@@ -8,6 +8,7 @@
 #include <linux/delay.h>
 
 #include "mtk_dev.h"
+#include "mtk_data_plane.h"
 #include "mtk_dpmaif_drv.h"
 #include "mtk_dpmaif_reg.h"
 #include "mtk_pci.h"
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_drv.h b/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_drv.h
index 5a68d2431063..b2385478abee 100644
--- a/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_drv.h
+++ b/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_drv.h
@@ -256,4 +256,13 @@ static inline int mtk_dpmaif_drv_send_doorbell(struct dpmaif_drv_info *drv_info,
 	return drv_info->drv_ops->send_doorbell(drv_info, type, q_id, cnt);
 }
 
+struct dpmaif_drv_ops_desc {
+	u32 hw_ver;
+	struct dpmaif_drv_ops *drv_ops;
+};
+
+#define drv_ops_name(NAME) dpmaif_drv_ops_##NAME
+
+extern struct dpmaif_drv_ops dpmaif_drv_ops_m9xx;
+
 #endif
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_ring.c b/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_ring.c
index a8e183b5f4ee..701e50bfe8b1 100644
--- a/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_ring.c
+++ b/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_ring.c
@@ -14,7 +14,7 @@
 
 #define PIT_PD_DATA_LEN		GENMASK(31, 16) /* Indicates the data length of current packet. */
 #define PIT_PD_BUF_ID		GENMASK(15, 3) /* The low order of buffer index */
-#define PIT_PD_BUF_TYPE		BIT(2) /* 0b: normal BAT entry; 1b: fragment BAT entry */
+#define PIT_PD_BUF_TYPE		BIT(2) /* 0b: normal BAT entry */
 #define PIT_PD_CONT		BIT(1) /* 0b: last entry; 1b: more entry */
 #define PIT_PD_PKT_TYPE		BIT(0) /* 0b: normal PIT entry; 1b: message PIT entry */
 
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_pci.c b/drivers/net/wwan/t9xx/pcie/mtk_pci.c
index aec1c5211c70..baac3692f1e3 100644
--- a/drivers/net/wwan/t9xx/pcie/mtk_pci.c
+++ b/drivers/net/wwan/t9xx/pcie/mtk_pci.c
@@ -14,6 +14,7 @@
 #include <linux/module.h>
 
 #include "mtk_dev.h"
+#include "mtk_dpmaif.h"
 #include "mtk_trans_ctrl.h"
 #include "mtk_pci.h"
 #include "mtk_pci_reg.h"
@@ -776,7 +777,13 @@ static int mtk_pci_dev_init(struct mtk_md_dev *mdev)
 	if (ret)
 		goto free_fsm;
 
+	ret = mtk_pcie_data_init(mdev);
+	if (ret)
+		goto free_ctrl_plane;
+
 	return 0;
+free_ctrl_plane:
+	mtk_trans_ctrl_exit(mdev);
 free_fsm:
 	mtk_fsm_exit(mdev);
 	return ret;
@@ -786,6 +793,7 @@ static void mtk_pci_dev_exit(struct mtk_md_dev *mdev)
 {
 	mtk_fsm_evt_submit(mdev, FSM_EVT_DEV_RM, 0, NULL, 0,
 			   EVT_MODE_BLOCKING | EVT_MODE_TOHEAD);
+	mtk_pcie_data_exit(mdev);
 	mtk_trans_ctrl_exit(mdev);
 	mtk_fsm_exit(mdev);
 }
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_pci.h b/drivers/net/wwan/t9xx/pcie/mtk_pci.h
index bb657aa786b6..1e88f9c60a11 100644
--- a/drivers/net/wwan/t9xx/pcie/mtk_pci.h
+++ b/drivers/net/wwan/t9xx/pcie/mtk_pci.h
@@ -7,8 +7,7 @@
 #define __MTK_PCI_H__
 
 #include <linux/pci.h>
-
-#include "../mtk_dev.h"
+#include "mtk_dev.h"
 
 enum mtk_irq_src {
 	MTK_IRQ_SRC_MIN,

-- 
2.34.1

