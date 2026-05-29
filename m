From: Jack Wu <jackbb_wu@compal.com>
Date: Fri, 29 May 2026 18:31:48 +0800
Subject: [PATCH 09/11] net: wwan: t9xx: Introduce WWAN interface
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260529-t9xx_driver_v1-v1-9-bdbfe2c01e57@compal.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780050705; l=18978;
 i=jackbb_wu@compal.com; s=20260526; h=from:subject:message-id;
 bh=96jycljl/8lLh45uXKB7LKNt4I3aPon4/QXr3kDaNnY=;
 b=8XY1Gbu80GkaOSoOtpuQ9cr4TdYYqEx31A3odVniPmk9PDnYUYRhMrM29tRrh2rqhtTrOgDNp
 ePRE99l7qezBw/1exHzV2kjihDAtQ2w+luCg6HwiK6WL9GwDC1pOSP/
X-Developer-Key: i=jackbb_wu@compal.com; a=ed25519;
 pk=VH1prTWixNl8OEUPPSfII3p46MzJpQN8J3+ecE1tZXg=
X-Endpoint-Received: by B4 Relay for jackbb_wu@compal.com/20260526 with auth_id=793
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Creates the WWAN interface which implements the wwan_ops
for registration with the WWAN framework. WWAN interface
also implements the net_device_ops functions used by the
network devices. Network device operations include open,
stop, start transmission and get states.

Signed-off-by: Jack Wu <jackbb_wu@compal.com>
---
 drivers/net/wwan/t9xx/Makefile              |   3 +-
 drivers/net/wwan/t9xx/mtk_data_plane.c      |  14 +-
 drivers/net/wwan/t9xx/mtk_data_plane.h      |   2 +
 drivers/net/wwan/t9xx/mtk_wwan.c            | 475 ++++++++++++++++++++++++++++
 drivers/net/wwan/t9xx/mtk_wwan.h            |  17 +
 drivers/net/wwan/t9xx/pcie/mtk_dpmaif.c     |  15 +-
 drivers/net/wwan/t9xx/pcie/mtk_dpmaif_drv.c |   1 -
 7 files changed, 521 insertions(+), 6 deletions(-)

diff --git a/drivers/net/wwan/t9xx/Makefile b/drivers/net/wwan/t9xx/Makefile
index 3776ccb4952f..6927216021cd 100644
--- a/drivers/net/wwan/t9xx/Makefile
+++ b/drivers/net/wwan/t9xx/Makefile
@@ -12,4 +12,5 @@ mtk_t9xx-y := \
 	mtk_port.o \
 	mtk_port_io.o \
 	mtk_fsm.o \
-	mtk_data_plane.o
+	mtk_data_plane.o \
+	mtk_wwan.o
diff --git a/drivers/net/wwan/t9xx/mtk_data_plane.c b/drivers/net/wwan/t9xx/mtk_data_plane.c
index d11c7de45e17..6266915f08bb 100644
--- a/drivers/net/wwan/t9xx/mtk_data_plane.c
+++ b/drivers/net/wwan/t9xx/mtk_data_plane.c
@@ -6,10 +6,13 @@
 #include "mtk_data_plane.h"
 #include "mtk_dev.h"
 #include "mtk_fsm.h"
+#include "mtk_wwan.h"
 
 static void mtk_data_stop(struct mtk_data_blk *data_blk, struct mtk_md_dev *mdev)
 {
+	mtk_wwan_notify(data_blk, DATA_EVT_TX_STOP, 0xff);
 	data_blk->hif_ops->stop(mdev);
+	mtk_wwan_notify(data_blk, DATA_EVT_UNREG_DEV, 0);
 	data_blk->hif_ops->clear(mdev);
 }
 
@@ -31,6 +34,7 @@ static void mtk_data_fsm_callback(struct mtk_fsm_param *fsm_param, void *data)
 			data_blk->hif_ops->start(data);
 		break;
 	case FSM_STATE_READY:
+		mtk_wwan_notify(data_blk, DATA_EVT_REG_DEV, 0);
 		break;
 	default:
 		break;
@@ -54,15 +58,21 @@ int mtk_data_init(struct mtk_md_dev *mdev, struct mtk_data_hif_ops *ops)
 	if (ret < 0)
 		goto data_blk_free;
 
+	ret = mtk_wwan_init(data_blk);
+	if (ret < 0)
+		goto hif_exit;
+
 	ret = mtk_fsm_notifier_register(mdev, MTK_USER_DATA, mtk_data_fsm_callback, mdev,
 					FSM_PRIO_1, false);
 	if (ret < 0) {
 		dev_err(mdev->dev, "Failed to register FSM notifier\n");
-		goto hif_exit;
+		goto wwan_exit;
 	}
 
 	return 0;
 
+wwan_exit:
+	mtk_wwan_exit(data_blk);
 hif_exit:
 	data_blk->hif_ops->exit(mdev);
 data_blk_free:
@@ -82,6 +92,8 @@ int mtk_data_exit(struct mtk_md_dev *mdev)
 
 	mtk_fsm_notifier_unregister(mdev, MTK_USER_DATA);
 
+	mtk_wwan_exit(data_blk);
+
 	data_blk->hif_ops->exit(mdev);
 
 	devm_kfree(mdev->dev, data_blk);
diff --git a/drivers/net/wwan/t9xx/mtk_data_plane.h b/drivers/net/wwan/t9xx/mtk_data_plane.h
index 1464fab544f1..351b30ebbbe5 100644
--- a/drivers/net/wwan/t9xx/mtk_data_plane.h
+++ b/drivers/net/wwan/t9xx/mtk_data_plane.h
@@ -31,6 +31,7 @@ struct mtk_data_trans_info {
 
 struct mtk_data_blk {
 	struct mtk_md_dev *mdev;
+	struct mtk_wwan_ctlb *wcb;
 	void *dcb;
 	struct mtk_data_hif_ops *hif_ops;
 	struct mtk_data_trans_info trans_info;
@@ -80,6 +81,7 @@ enum mtk_data_evt {
 	DATA_EVT_MIN,
 	DATA_EVT_TX_START,
 	DATA_EVT_TX_STOP,
+	DATA_EVT_RX_START,
 	DATA_EVT_RX_STOP,
 	DATA_EVT_REG_DEV,
 	DATA_EVT_UNREG_DEV,
diff --git a/drivers/net/wwan/t9xx/mtk_wwan.c b/drivers/net/wwan/t9xx/mtk_wwan.c
new file mode 100644
index 000000000000..a1534c312358
--- /dev/null
+++ b/drivers/net/wwan/t9xx/mtk_wwan.c
@@ -0,0 +1,475 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (c) 2022, MediaTek Inc.
+ */
+
+#include <linux/if_arp.h>
+#include <linux/netdevice.h>
+#include <linux/skbuff.h>
+#include <linux/types.h>
+#include <linux/wwan.h>
+#include <net/pkt_sched.h>
+
+#include "mtk_data_plane.h"
+#include "mtk_dev.h"
+#include "mtk_wwan.h"
+
+#define MTK_NETDEV_MAX		20
+#define MTK_DFLT_INTF_ID	0
+#define MTK_NETDEV_WDT (HZ)
+#define MTK_CMD_WDT (HZ)
+#define MTK_MAX_INTF_ID (MTK_NETDEV_MAX - 1)
+#define MTK_NAPI_POLL_WEIGHT	128
+
+static unsigned int napi_budget = MTK_NAPI_POLL_WEIGHT;
+
+struct mtk_wwan_instance {
+	struct mtk_wwan_ctlb *wcb;
+	struct net_device *netdev;
+	unsigned int intf_id;
+	struct mtk_data_hif_ops *hif_ops;
+};
+
+struct mtk_wwan_ctlb {
+	struct mtk_data_blk *data_blk;
+	struct mtk_md_dev *mdev;
+	struct mtk_wwan_instance __rcu *wwan_inst[MTK_NETDEV_MAX];
+	struct net_device *dummy_dev;
+	struct napi_struct **gro_napis;
+	atomic_t napi_enabled;
+	unsigned int active_cnt;
+	bool reg_done;
+};
+
+int mtk_wwan_recv(struct mtk_data_blk *data_blk, struct sk_buff *skb)
+{
+	union mtk_data_pkt_info *pkt_info = DATA_SKB_CB(skb);
+	struct mtk_wwan_instance *wwan_inst;
+	unsigned char q_id;
+
+	if (unlikely(pkt_info->rx.ch_id > MTK_MAX_INTF_ID)) {
+		dev_warn(data_blk->mdev->dev,
+			 "Invalid interface id=%d\n", pkt_info->rx.ch_id);
+		goto free_skb;
+	}
+
+	q_id = pkt_info->rx.q_id;
+
+	rcu_read_lock();
+	wwan_inst = rcu_dereference(data_blk->wcb->wwan_inst[pkt_info->rx.ch_id]);
+	if (unlikely(!wwan_inst)) {
+		rcu_read_unlock();
+		goto free_skb;
+	}
+
+	skb->dev = wwan_inst->netdev;
+
+	napi_gro_receive(data_blk->wcb->gro_napis[q_id], skb);
+
+	rcu_read_unlock();
+	return 0;
+
+free_skb:
+	dev_kfree_skb_any(skb);
+	return -EINVAL;
+}
+EXPORT_SYMBOL(mtk_wwan_recv);
+
+static void mtk_wwan_napi_enable(struct mtk_wwan_ctlb *wcb)
+{
+	int i;
+
+	if (atomic_cmpxchg(&wcb->napi_enabled, 0, 1) == 0) {
+		for (i = 0; i < wcb->data_blk->trans_info.rxq_cnt; i++)
+			napi_enable(wcb->data_blk->trans_info.napis[i]);
+	}
+}
+
+static void mtk_wwan_napi_disable(struct mtk_wwan_ctlb *wcb)
+{
+	int i;
+
+	if (atomic_cmpxchg(&wcb->napi_enabled, 1, 0) == 1) {
+		for (i = 0; i < wcb->data_blk->trans_info.rxq_cnt; i++) {
+			napi_synchronize(wcb->data_blk->trans_info.napis[i]);
+			napi_disable(wcb->data_blk->trans_info.napis[i]);
+		}
+	}
+}
+
+static int mtk_wwan_open(struct net_device *dev)
+{
+	struct mtk_wwan_instance *wwan_inst = wwan_netdev_drvpriv(dev);
+	struct mtk_wwan_ctlb *wcb = wwan_inst->wcb;
+	struct mtk_data_trans_ctl trans_ctl;
+	int ret;
+
+	if (wcb->active_cnt == 0) {
+		trans_ctl.enable = true;
+		ret = mtk_wwan_cmd_execute(dev, DATA_CMD_TRANS_CTL, &trans_ctl);
+		if (ret < 0) {
+			dev_err(wcb->mdev->dev, "Failed to enable trans\n");
+			return ret;
+		}
+	}
+
+	wcb->active_cnt++;
+
+	netif_tx_start_all_queues(dev);
+	netif_carrier_on(dev);
+
+	return 0;
+}
+
+static int mtk_wwan_stop(struct net_device *dev)
+{
+	struct mtk_wwan_instance *wwan_inst = wwan_netdev_drvpriv(dev);
+	struct mtk_wwan_ctlb *wcb = wwan_inst->wcb;
+	struct mtk_data_trans_ctl trans_ctl;
+	int ret;
+
+	netif_carrier_off(dev);
+	netif_tx_disable(dev);
+
+	if (wcb->active_cnt == 1) {
+		trans_ctl.enable = false;
+		ret = mtk_wwan_cmd_execute(dev, DATA_CMD_TRANS_CTL, &trans_ctl);
+		if (ret < 0)
+			dev_err(wcb->mdev->dev, "Failed to disable trans\n");
+	}
+	wcb->active_cnt--;
+
+	return 0;
+}
+
+static netdev_tx_t mtk_wwan_start_xmit(struct sk_buff *skb, struct net_device *dev)
+{
+	struct mtk_wwan_instance *wwan_inst = wwan_netdev_drvpriv(dev);
+	union mtk_data_pkt_info *pkt_info = DATA_SKB_CB(skb);
+	int ret;
+
+	skb_set_queue_mapping(skb, 0);
+	pkt_info->tx.intf_id = wwan_inst->intf_id;
+
+	ret = wwan_inst->hif_ops->send(wwan_inst->wcb->data_blk, DATA_PKT, skb);
+	if (ret == -EBUSY)
+		return NETDEV_TX_BUSY;
+	else if (ret == -EINVAL)
+		dev_kfree_skb_any(skb);
+
+	return NETDEV_TX_OK;
+}
+
+static const struct net_device_ops mtk_netdev_ops = {
+	.ndo_open = mtk_wwan_open,
+	.ndo_stop = mtk_wwan_stop,
+	.ndo_start_xmit = mtk_wwan_start_xmit,
+};
+
+static int mtk_wwan_cmd_check(struct net_device *dev, enum mtk_data_cmd_type cmd)
+{
+	int ret = 0;
+
+	switch (cmd) {
+	case DATA_CMD_TRANS_CTL:
+		break;
+	default:
+		ret = -EOPNOTSUPP;
+		break;
+	}
+
+	return ret;
+}
+
+static struct sk_buff *mtk_wwan_cmd_alloc(enum mtk_data_cmd_type cmd, unsigned int len)
+{
+	struct mtk_data_cmd *event;
+	struct sk_buff *skb;
+
+	skb = dev_alloc_skb(sizeof(*event) + len);
+	if (unlikely(!skb))
+		return NULL;
+
+	skb_put(skb, len + sizeof(*event));
+	event = (struct mtk_data_cmd *)skb->data;
+	event->cmd = cmd;
+	event->len = len;
+
+	return skb;
+}
+
+static int mtk_wwan_cmd_send(struct net_device *dev, struct sk_buff *skb)
+{
+	struct mtk_wwan_instance *wwan_inst = wwan_netdev_drvpriv(dev);
+
+	return wwan_inst->hif_ops->send(wwan_inst->wcb->data_blk, DATA_CMD, skb);
+}
+
+int mtk_wwan_cmd_execute(struct net_device *dev,
+			 enum mtk_data_cmd_type cmd, void *data)
+{
+	struct mtk_wwan_instance *wwan_inst;
+	struct sk_buff *skb;
+	int ret;
+
+	if (mtk_wwan_cmd_check(dev, cmd))
+		return -EOPNOTSUPP;
+
+	skb = mtk_wwan_cmd_alloc(cmd, sizeof(void *));
+	if (unlikely(!skb))
+		return -ENOMEM;
+
+	SKB_TO_CMD_DATA(skb) = data;
+
+	ret = mtk_wwan_cmd_send(dev, skb);
+	if (ret < 0) {
+		wwan_inst = wwan_netdev_drvpriv(dev);
+		dev_err(wwan_inst->wcb->mdev->dev,
+			"Failed to excute command:ret=%d,cmd=%d\n", ret, cmd);
+	}
+
+	dev_consume_skb_any(skb);
+
+	return ret;
+}
+
+static int mtk_wwan_start_txq(struct mtk_wwan_ctlb *wcb, u32 qmask)
+{
+	struct mtk_wwan_instance *wwan_inst;
+	struct net_device *dev;
+	int i;
+
+	rcu_read_lock();
+	for (i = 0; i < MTK_NETDEV_MAX; i++) {
+		wwan_inst = rcu_dereference(wcb->wwan_inst[i]);
+		if (!wwan_inst)
+			continue;
+
+		dev = wwan_inst->netdev;
+
+		if (!(dev->flags & IFF_UP))
+			continue;
+
+		netif_tx_wake_all_queues(dev);
+		netif_carrier_on(dev);
+	}
+	rcu_read_unlock();
+
+	return 0;
+}
+
+static int mtk_wwan_stop_txq(struct mtk_wwan_ctlb *wcb, u32 qmask)
+{
+	struct mtk_wwan_instance *wwan_inst;
+	struct net_device *dev;
+	int i;
+
+	rcu_read_lock();
+	for (i = 0; i < MTK_NETDEV_MAX; i++) {
+		wwan_inst = rcu_dereference(wcb->wwan_inst[i]);
+		if (!wwan_inst)
+			continue;
+
+		dev = wwan_inst->netdev;
+
+		if (!(dev->flags & IFF_UP))
+			continue;
+
+		netif_carrier_off(dev);
+		netif_tx_stop_all_queues(dev);
+	}
+	rcu_read_unlock();
+
+	return 0;
+}
+
+static void mtk_wwan_napi_exit(struct mtk_wwan_ctlb *wcb)
+{
+	int i;
+
+	for (i = 0; i < wcb->data_blk->trans_info.rxq_cnt; i++) {
+		if (!wcb->data_blk->trans_info.napis[i])
+			continue;
+		netif_napi_del(wcb->data_blk->trans_info.napis[i]);
+	}
+}
+
+static int mtk_wwan_napi_init(struct mtk_wwan_ctlb *wcb, struct net_device *dev)
+{
+	int i;
+
+	for (i = 0; i < wcb->data_blk->trans_info.rxq_cnt; i++) {
+		if (!wcb->data_blk->trans_info.napis[i]) {
+			dev_err(wcb->mdev->dev, "Invalid napi pointer, napi=%d\n", i);
+			goto out;
+		}
+		netif_napi_add_weight(dev, wcb->data_blk->trans_info.napis[i],
+				      wcb->data_blk->hif_ops->poll, napi_budget);
+	}
+
+	return 0;
+
+out:
+	for (--i; i >= 0; i--)
+		netif_napi_del(wcb->data_blk->trans_info.napis[i]);
+	return -EINVAL;
+}
+
+static void mtk_wwan_setup(struct net_device *dev)
+{
+	dev->watchdog_timeo = MTK_NETDEV_WDT;
+	dev->mtu = ETH_DATA_LEN;
+	dev->min_mtu = ETH_MIN_MTU;
+
+	dev->features = NETIF_F_SG;
+	dev->hw_features = NETIF_F_SG;
+
+	dev->features |= NETIF_F_GRO;
+	dev->hw_features |= NETIF_F_GRO;
+
+	dev->tx_queue_len = DEFAULT_TX_QUEUE_LEN;
+
+	dev->flags = IFF_NOARP;
+	dev->type = ARPHRD_NONE;
+
+	dev->needs_free_netdev = true;
+
+	dev->netdev_ops = &mtk_netdev_ops;
+}
+
+static int mtk_wwan_newlink(void *ctxt, struct net_device *dev, u32 intf_id,
+			    struct netlink_ext_ack *extack)
+{
+	struct mtk_wwan_instance *wwan_inst = wwan_netdev_drvpriv(dev);
+	struct mtk_wwan_ctlb *wcb = ctxt;
+	int ret;
+
+	if (intf_id > MTK_MAX_INTF_ID)
+		return -EINVAL;
+
+	if (rcu_access_pointer(wcb->wwan_inst[intf_id]))
+		return -EBUSY;
+
+	dev->max_mtu = wcb->data_blk->trans_info.max_mtu;
+
+	wwan_inst->wcb = wcb;
+	wwan_inst->netdev = dev;
+	wwan_inst->intf_id = intf_id;
+	wwan_inst->hif_ops = wcb->data_blk->hif_ops;
+
+	ret = register_netdevice(dev);
+	if (ret)
+		return ret;
+
+	rcu_assign_pointer(wcb->wwan_inst[intf_id], wwan_inst);
+
+	netif_device_attach(dev);
+
+	return 0;
+}
+
+static void mtk_wwan_dellink(void *ctxt, struct net_device *dev,
+			     struct list_head *head)
+{
+	struct mtk_wwan_instance *wwan_inst = wwan_netdev_drvpriv(dev);
+	int intf_id = wwan_inst->intf_id;
+	struct mtk_wwan_ctlb *wcb = ctxt;
+
+	if (WARN_ON(rcu_access_pointer(wcb->wwan_inst[intf_id]) != wwan_inst))
+		return;
+
+	RCU_INIT_POINTER(wcb->wwan_inst[intf_id], NULL);
+	unregister_netdevice_queue(dev, head);
+}
+
+static const struct wwan_ops mtk_wwan_ops = {
+	.priv_size = sizeof(struct mtk_wwan_instance),
+	.setup = mtk_wwan_setup,
+	.newlink = mtk_wwan_newlink,
+	.dellink = mtk_wwan_dellink,
+};
+
+void mtk_wwan_notify(struct mtk_data_blk *data_blk, enum mtk_data_evt evt, u64 data)
+{
+	struct mtk_wwan_ctlb *wcb;
+
+	if (unlikely(!data_blk || !data_blk->wcb))
+		return;
+
+	wcb = data_blk->wcb;
+
+	switch (evt) {
+	case DATA_EVT_TX_START:
+		mtk_wwan_start_txq(wcb, data);
+		break;
+	case DATA_EVT_TX_STOP:
+		mtk_wwan_stop_txq(wcb, data);
+		break;
+	case DATA_EVT_RX_START:
+		mtk_wwan_napi_enable(wcb);
+		break;
+	case DATA_EVT_RX_STOP:
+		mtk_wwan_napi_disable(wcb);
+		break;
+	case DATA_EVT_REG_DEV:
+		if (!wcb->reg_done) {
+			wwan_register_ops(wcb->mdev->dev, &mtk_wwan_ops, wcb, MTK_DFLT_INTF_ID);
+			wcb->reg_done = true;
+		}
+		break;
+	case DATA_EVT_UNREG_DEV:
+		if (wcb->reg_done) {
+			wwan_unregister_ops(wcb->mdev->dev);
+			wcb->reg_done = false;
+		}
+		break;
+	default:
+		break;
+	}
+}
+EXPORT_SYMBOL(mtk_wwan_notify);
+
+int mtk_wwan_init(struct mtk_data_blk *data_blk)
+{
+	struct mtk_wwan_ctlb *wcb;
+	int ret;
+
+	wcb = devm_kzalloc(data_blk->mdev->dev, sizeof(*wcb), GFP_KERNEL);
+	if (unlikely(!wcb))
+		return -ENOMEM;
+
+	wcb->mdev = data_blk->mdev;
+	wcb->data_blk = data_blk;
+
+	wcb->dummy_dev = alloc_netdev_dummy(0);
+	if (!wcb->dummy_dev) {
+		devm_kfree(data_blk->mdev->dev, wcb);
+		return -ENOMEM;
+	}
+
+	data_blk->wcb = wcb;
+
+	wcb->gro_napis = data_blk->trans_info.napis;
+	ret = mtk_wwan_napi_init(wcb, wcb->dummy_dev);
+	if (ret < 0) {
+		free_netdev(wcb->dummy_dev);
+		devm_kfree(data_blk->mdev->dev, wcb);
+		data_blk->wcb = NULL;
+		return ret;
+	}
+
+	return 0;
+}
+
+void mtk_wwan_exit(struct mtk_data_blk *data_blk)
+{
+	struct mtk_wwan_ctlb *wcb = data_blk->wcb;
+
+	if (unlikely(!wcb))
+		return;
+
+	mtk_wwan_napi_exit(wcb);
+	free_netdev(wcb->dummy_dev);
+	devm_kfree(data_blk->mdev->dev, wcb);
+	data_blk->wcb = NULL;
+}
diff --git a/drivers/net/wwan/t9xx/mtk_wwan.h b/drivers/net/wwan/t9xx/mtk_wwan.h
new file mode 100644
index 000000000000..8005aeb1ed97
--- /dev/null
+++ b/drivers/net/wwan/t9xx/mtk_wwan.h
@@ -0,0 +1,17 @@
+/* SPDX-License-Identifier: GPL-2.0-only
+ *
+ * Copyright (c) 2022, MediaTek Inc.
+ */
+
+#ifndef __MTK_WWAN_H__
+#define __MTK_WWAN_H__
+#include <linux/netdevice.h>
+#include "mtk_data_plane.h"
+
+int mtk_wwan_init(struct mtk_data_blk *data_blk);
+void mtk_wwan_exit(struct mtk_data_blk *data_blk);
+int mtk_wwan_recv(struct mtk_data_blk *data_blk, struct sk_buff *skb);
+void mtk_wwan_notify(struct mtk_data_blk *data_blk, enum mtk_data_evt evt, u64 data);
+int mtk_wwan_cmd_execute(struct net_device *dev, enum mtk_data_cmd_type cmd, void *data);
+
+#endif /* __MTK_WWAN_H__ */
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_dpmaif.c b/drivers/net/wwan/t9xx/pcie/mtk_dpmaif.c
index 1c58dba738fa..43803587bfc3 100644
--- a/drivers/net/wwan/t9xx/pcie/mtk_dpmaif.c
+++ b/drivers/net/wwan/t9xx/pcie/mtk_dpmaif.c
@@ -20,9 +20,11 @@
 #include "mtk_dev.h"
 #include "mtk_dpmaif.h"
 #include "mtk_dpmaif_drv.h"
+#include "mtk_dpmaif_reg.h"
 #include "mtk_dpmaif_ring.h"
 #include "mtk_pci_reg.h"
 #include "mtk_pci.h"
+#include "mtk_wwan.h"
 
 #define MTK_DATA_WS_NAME_LEN		32
 #define DPMAIF_PIT_CNT_UPDATE_THRESHOLD 60
@@ -741,6 +743,7 @@ static void mtk_dpmaif_sw_stop_rx(struct mtk_dpmaif_ctlb *dcb)
 	}
 
 	/* Stop PIT polling NAPI. */
+	mtk_wwan_notify(dcb->data_blk, DATA_EVT_RX_STOP, 0xff);
 }
 
 static void mtk_dpmaif_sw_start_rx(struct mtk_dpmaif_ctlb *dcb)
@@ -749,6 +752,7 @@ static void mtk_dpmaif_sw_start_rx(struct mtk_dpmaif_ctlb *dcb)
 	int i;
 
 	/* Start PIT polling NAPI. */
+	mtk_wwan_notify(dcb->data_blk, DATA_EVT_RX_START, 0xff);
 
 	for (i = 0; i < dcb->rxq_cnt; i++) {
 		rxq = &dcb->rxqs[i];
@@ -910,6 +914,7 @@ static int mtk_dpmaif_tx_rel_internal(struct dpmaif_txq *txq,
 		tx_srv = &dcb->tx_srvs[srv_id];
 		clear_bit(txq->id, &tx_srv->txq_drb_lack_sta);
 		wake_up(&tx_srv->wait);
+		mtk_wwan_notify(dcb->data_blk, DATA_EVT_TX_START, (u64)1 << txq->id);
 	}
 
 	return 0;
@@ -1426,6 +1431,7 @@ static void mtk_dpmaif_tx_update_ring(struct mtk_dpmaif_ctlb *dcb, struct dpmaif
 		if (drb_available_cnt < skb_drb_cnt) {
 			skb_queue_head(&vq->list, skb);
 			set_bit(q_id, &tx_srv->txq_drb_lack_sta);
+			mtk_wwan_notify(dcb->data_blk, DATA_EVT_TX_STOP, (u64)1 << q_id);
 			break;
 		}
 
@@ -2346,6 +2352,7 @@ static int mtk_dpmaif_update_rx_skb_info(struct sk_buff *skb,
 
 static int mtk_dpmaif_rx_skb(struct dpmaif_rxq *rxq, struct dpmaif_rx_record *rx_record)
 {
+	struct mtk_dpmaif_ctlb *dcb = rxq->dcb;
 	struct sk_buff *new_skb;
 	int ret;
 
@@ -2362,7 +2369,7 @@ static int mtk_dpmaif_rx_skb(struct dpmaif_rxq *rxq, struct dpmaif_rx_record *rx
 			continue;
 
 		/* Send skb to data port. */
-		/* Data would be sent to network stack here */
+		mtk_wwan_recv(dcb->data_blk, new_skb);
 	} while (!skb_queue_empty(&rx_record->rx_list));
 
 	return ret;
@@ -2600,10 +2607,12 @@ static int mtk_dpmaif_send_pkt(struct mtk_dpmaif_ctlb *dcb, struct sk_buff *skb)
 	int ret = 0;
 
 	vq = &dcb->tx_vqs[vq_id];
-	if (likely(skb_queue_len(&vq->list) < vq->max_len))
+	if (likely(skb_queue_len(&vq->list) < vq->max_len)) {
 		skb_queue_tail(&vq->list, skb);
-	else
+	} else {
+		mtk_wwan_notify(dcb->data_blk, DATA_EVT_TX_STOP, (u64)1 << vq_id);
 		ret = -EBUSY;
+	}
 
 	wake_up(&dcb->tx_srvs[vq->srv_id].wait);
 
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_drv.c b/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_drv.c
index 077600389ab4..3fd2b33d1199 100644
--- a/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_drv.c
+++ b/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_drv.c
@@ -8,7 +8,6 @@
 #include <linux/delay.h>
 
 #include "mtk_dev.h"
-#include "mtk_data_plane.h"
 #include "mtk_dpmaif_drv.h"
 #include "mtk_dpmaif_reg.h"
 #include "mtk_pci.h"

-- 
2.34.1

