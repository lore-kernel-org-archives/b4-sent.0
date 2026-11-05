From: Jack Wu <jackbb_wu@compal.com>
Date: Thu, 05 Nov 2026 15:56:30 +0800
Subject: [PATCH v11 4/6] net: wwan: t9xx: Add control port
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-t9xx_driver_v1-v11-4-2084aa512864@compal.com>
References: <20261105-t9xx_driver_v1-v11-0-2084aa512864@compal.com>
In-Reply-To: <20261105-t9xx_driver_v1-v11-0-2084aa512864@compal.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793865391; l=39874;
 i=jackbb_wu@compal.com; s=20260526; h=from:subject:message-id;
 bh=CgiwO1/pzLpzrBdi+O867la69U9tjAscW/iSMhc81DU=;
 b=RGg3ThKRzDpj1apGN+npWw8CR5+69Hmatm3Pk0HGD6Qdmxu/PkcCl9X+3D55qJuc27v/grsKt
 C+J45Hq/xq2BdTv/7+uPVgmgTye+BOI+dioX5t/JDRIriXrIqdt9569
X-Developer-Key: i=jackbb_wu@compal.com; a=ed25519;
 pk=VH1prTWixNl8OEUPPSfII3p46MzJpQN8J3+ecE1tZXg=
X-Endpoint-Received: by B4 Relay for jackbb_wu@compal.com/20260526 with auth_id=793
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The control port consists of port I/O and port manager.
Port I/O provides a common operation as defined by
"struct mtk_port_ops", and the operation is managed by the
"port manager". It provides interfaces to internal users, the
implemented internal interfaces are open, close, write and
recv_register.

The port manager defines and implements port management interfaces and
structures. It is responsible for port creation, destroying, and managing
port states. It sends data from port I/O to CLDMA via TRB ( Transaction
Request Block ), and dispatches received data from CLDMA to port I/O.

A TRB lives in the control buffer of the skb it describes, so it is
freed together with that skb. This patch therefore gives struct trb a
kref: the port layer initialises it in mtk_port_trb_init() and owns the
release function mtk_port_trb_free(). mtk_ctrl_trb_handler() holds a
reference for the duration of a dispatch, including on the -EAGAIN
early return, so a completion running concurrently cannot free the skb
underneath the handler.

The TX sequence number is written into the header when the trb thread
hands the packet to CLDMA, and only advanced once CLDMA has put it on
the ring, so a packet refused before that takes no number.  A packet
already on the ring keeps its number even if the queue then fails to
start or is flushed: it may have reached the modem by then, so the
number is not reused.

At this commit probe and remove only build and tear down the port
table: ->init() runs for each port, and ->disable() and ->exit() find
no port enabled.  Nothing calls ->enable(), ->recv() or the internal
port interface yet, and no TRB is processed: the port-state, RX
dispatch and TRB kref paths become live with "Add FSM thread". That
patch also provides the teardown order these paths rely on - the CLDMA
queues are quiesced and the trb services stopped before the port
manager frees the ports - so neither a TRB completion nor an armed RX
queue outlives the port it points to.

Signed-off-by: Jack Wu <jackbb_wu@compal.com>
---
 drivers/net/wwan/t9xx/Makefile              |   2 +
 drivers/net/wwan/t9xx/mtk_ctrl_plane.c      |  24 +-
 drivers/net/wwan/t9xx/mtk_ctrl_plane.h      |  12 +-
 drivers/net/wwan/t9xx/mtk_port.c            | 667 ++++++++++++++++++++++++++++
 drivers/net/wwan/t9xx/mtk_port.h            | 133 ++++++
 drivers/net/wwan/t9xx/mtk_port_io.c         | 229 ++++++++++
 drivers/net/wwan/t9xx/mtk_port_io.h         |  32 ++
 drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c |  27 +-
 8 files changed, 1119 insertions(+), 7 deletions(-)

diff --git a/drivers/net/wwan/t9xx/Makefile b/drivers/net/wwan/t9xx/Makefile
index 74bef150e3a1..d44266009362 100644
--- a/drivers/net/wwan/t9xx/Makefile
+++ b/drivers/net/wwan/t9xx/Makefile
@@ -7,6 +7,8 @@ obj-$(CONFIG_MTK_T9XX) += mtk_t9xx.o
 
 mtk_t9xx-y := \
 	mtk_ctrl_plane.o \
+	mtk_port.o \
+	mtk_port_io.o \
 	pcie/mtk_pci.o \
 	pcie/mtk_trans_ctrl.o \
 	pcie/mtk_cldma.o \
diff --git a/drivers/net/wwan/t9xx/mtk_ctrl_plane.c b/drivers/net/wwan/t9xx/mtk_ctrl_plane.c
index 81f6b3fbc0bd..af3064753b15 100644
--- a/drivers/net/wwan/t9xx/mtk_ctrl_plane.c
+++ b/drivers/net/wwan/t9xx/mtk_ctrl_plane.c
@@ -7,21 +7,24 @@
 #include <linux/device.h>
 
 #include "mtk_ctrl_plane.h"
+#include "mtk_port.h"
 
 /**
  * mtk_ctrl_init() - Initialize the control plane block.
  * @mdev: Pointer to the MTK modem device.
+ * @port_layer_cfg: Port layer configuration.
  *
  * Allocates and initializes the control plane block
  * associated with @mdev.  Runs once per bind; the allocation is
  * devres managed and is released at unbind, not by
  * mtk_ctrl_exit().
  *
- * Return: 0 on success, -ENOMEM on allocation failure.
+ * Return: 0 on success, negative error code on failure.
  */
-int mtk_ctrl_init(struct mtk_md_dev *mdev)
+int mtk_ctrl_init(struct mtk_md_dev *mdev, struct mtk_port_layer_cfg *port_layer_cfg)
 {
 	struct mtk_ctrl_blk *ctrl_blk;
+	int err;
 
 	ctrl_blk = devm_kzalloc(mdev->dev, sizeof(*ctrl_blk), GFP_KERNEL);
 	if (!ctrl_blk)
@@ -30,6 +33,13 @@ int mtk_ctrl_init(struct mtk_md_dev *mdev)
 	ctrl_blk->mdev = mdev;
 	mdev->ctrl_blk = ctrl_blk;
 
+	err = mtk_port_mngr_init(ctrl_blk, port_layer_cfg->port_cfg,
+				 port_layer_cfg->port_cnt);
+	if (err) {
+		mdev->ctrl_blk = NULL;
+		return err;
+	}
+
 	return 0;
 }
 
@@ -37,10 +47,16 @@ int mtk_ctrl_init(struct mtk_md_dev *mdev)
  * mtk_ctrl_exit() - Clean up the control plane block.
  * @mdev: Pointer to the MTK modem device.
  *
- * Clears the control plane block pointer. The allocation
- * itself is managed by devres and freed on driver detach.
+ * Tears down what mtk_ctrl_init() set up and clears the control plane
+ * block pointer.  The allocation itself is managed by devres and freed
+ * on driver detach.
+ *
+ * Context: Process context; may sleep.
  */
 void mtk_ctrl_exit(struct mtk_md_dev *mdev)
 {
+	struct mtk_ctrl_blk *ctrl_blk = mdev->ctrl_blk;
+
+	mtk_port_mngr_exit(ctrl_blk);
 	mdev->ctrl_blk = NULL;
 }
diff --git a/drivers/net/wwan/t9xx/mtk_ctrl_plane.h b/drivers/net/wwan/t9xx/mtk_ctrl_plane.h
index cf5d6d95f3ee..3ba66d9a4b60 100644
--- a/drivers/net/wwan/t9xx/mtk_ctrl_plane.h
+++ b/drivers/net/wwan/t9xx/mtk_ctrl_plane.h
@@ -6,6 +6,7 @@
 #ifndef __MTK_CTRL_PLANE_H__
 #define __MTK_CTRL_PLANE_H__
 
+#include <linux/kref.h>
 #include <linux/skbuff.h>
 
 #include "mtk_dev.h"
@@ -46,6 +47,11 @@ struct trb {
 	u32 channel_id;
 	enum mtk_trb_cmd_type cmd;
 	int status;
+	/* Store-release by the completion callback, load-acquire by the
+	 * waiter: seeing it set means seeing everything the callback wrote.
+	 */
+	bool done;
+	struct kref kref;
 	void *priv;
 	int (*trb_complete)(struct sk_buff *skb);
 };
@@ -56,12 +62,16 @@ union ctrl_hif_cmd_data {
 	u32 rx_ch;
 };
 
+struct mtk_port_layer_cfg;
+struct mtk_port_mngr;
+
 struct mtk_ctrl_blk {
 	struct mtk_md_dev *mdev;
+	struct mtk_port_mngr *port_mngr;
 	void *ctrl_hw_priv;
 };
 
-int mtk_ctrl_init(struct mtk_md_dev *mdev);
+int mtk_ctrl_init(struct mtk_md_dev *mdev, struct mtk_port_layer_cfg *port_layer_cfg);
 void mtk_ctrl_exit(struct mtk_md_dev *mdev);
 
 #endif /* __MTK_CTRL_PLANE_H__ */
diff --git a/drivers/net/wwan/t9xx/mtk_port.c b/drivers/net/wwan/t9xx/mtk_port.c
new file mode 100644
index 000000000000..7fec696bd6db
--- /dev/null
+++ b/drivers/net/wwan/t9xx/mtk_port.c
@@ -0,0 +1,667 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (c) 2022, MediaTek Inc.
+ */
+
+#include <linux/bitfield.h>
+#include <linux/device.h>
+#include <linux/err.h>
+#include <linux/kernel.h>
+#include <linux/netdevice.h>
+#include <linux/slab.h>
+#include <linux/wait.h>
+
+#include "mtk_port.h"
+#include "mtk_port_io.h"
+#include "mtk_trans_ctrl.h"
+
+#define MTK_DFLT_TRB_TIMEOUT		(5 * HZ)
+#define MTK_DFLT_TRB_STATUS		(0x1)
+#define MTK_CHECK_RX_SEQ_MASK		(0x7fff)
+#define MTK_INVALID_RX_SEQ		(0xffff)
+
+#define MTK_PORT_ENUM_VER		(0)
+#define MTK_PORT_ENUM_HEAD_PATTERN	(0x5a5a5a5a)
+#define MTK_PORT_ENUM_TAIL_PATTERN	(0xa5a5a5a5)
+
+struct mtk_port_info {
+	__le16 channel;
+	__le16 reserved;
+} __packed;
+
+struct mtk_port_enum_msg {
+	__le32 head_pattern;
+	__le16 port_cnt;
+	__le16 version;
+	__le32 tail_pattern;
+	u8 data[];
+} __packed;
+
+/* Returns NULL for an empty slot, or after restarting the walk at an
+ * internal node; the caller then skips to the next slot.
+ */
+static struct mtk_port *mtk_port_tbl_slot(void __rcu ***slot, struct radix_tree_iter *iter)
+{
+	struct mtk_port *port = rcu_dereference_raw(**slot);
+
+	if (radix_tree_is_internal_node(port)) {
+		*slot = radix_tree_iter_retry(iter);
+		return NULL;
+	}
+
+	return port;
+}
+
+/* Serialises a lookup and its kref_get() against the removal of the port
+ * from the table and the kref_put() that may free it.
+ */
+DEFINE_MUTEX(mtk_port_mngr_grp_mtx);
+
+/* Called with mtk_port_mngr_grp_mtx held. */
+void mtk_port_release(struct kref *port_kref)
+{
+	struct mtk_port *port;
+
+	port = container_of(port_kref, struct mtk_port, kref);
+	mtk_port_get_ops(port->info.type)->exit(port);
+	kfree_rcu(port, rcu);
+}
+
+static int mtk_port_tbl_add(struct mtk_port_mngr *port_mngr, struct mtk_port *port)
+{
+	int ret;
+
+	mutex_lock(&port_mngr->port_tbl_mtx);
+	ret = radix_tree_insert(&port_mngr->port_tbl[MTK_PORT_TBL_TYPE(port->info.rx_ch)],
+				MTK_CH_ID(port->info.rx_ch), port);
+	mutex_unlock(&port_mngr->port_tbl_mtx);
+
+	if (ret)
+		dev_err(port_mngr->ctrl_blk->mdev->dev,
+			"port(%s) add to port_tbl failed, return %d\n",
+			port->info.name, ret);
+
+	return ret;
+}
+
+static void mtk_port_tbl_del(struct mtk_port_mngr *port_mngr, struct mtk_port *port)
+{
+	mutex_lock(&port_mngr->port_tbl_mtx);
+	radix_tree_delete(&port_mngr->port_tbl[MTK_PORT_TBL_TYPE(port->info.rx_ch)],
+			  MTK_CH_ID(port->info.rx_ch));
+	mutex_unlock(&port_mngr->port_tbl_mtx);
+}
+
+static struct mtk_port *mtk_port_alloc_and_add(struct mtk_port_mngr *port_mngr,
+					       const struct mtk_port_cfg *dflt_info)
+{
+	struct mtk_port *port;
+	int ret;
+
+	port = kzalloc_obj(*port, GFP_KERNEL);
+	if (!port) {
+		ret = -ENOMEM;
+		goto err_alloc_port;
+	}
+	memcpy(&port->info, dflt_info, sizeof(*dflt_info));
+
+	ret = mtk_port_tbl_add(port_mngr, port);
+	if (ret < 0) {
+		dev_err(port_mngr->ctrl_blk->mdev->dev,
+			"Failed to add port(%s) to port tbl\n", dflt_info->name);
+		goto err_free_port;
+	}
+
+	port->port_mngr = port_mngr;
+	ret = mtk_port_get_ops(port->info.type)->init(port);
+	if (ret < 0) {
+		mtk_port_tbl_del(port_mngr, port);
+		goto err_free_port;
+	}
+
+	return port;
+
+err_free_port:
+	kfree(port);
+err_alloc_port:
+	return ERR_PTR(ret);
+}
+
+static void mtk_port_free(struct mtk_port_mngr *port_mngr, struct mtk_port *port)
+{
+	mutex_lock(&mtk_port_mngr_grp_mtx);
+	mtk_port_tbl_del(port_mngr, port);
+	kref_put(&port->kref, mtk_port_release);
+	mutex_unlock(&mtk_port_mngr_grp_mtx);
+}
+
+/* No lock: every caller runs in a context that is stopped before the control
+ * plane destroys the port table.  A caller without that guarantee must use
+ * mtk_port_get_by_name() instead.
+ */
+static struct mtk_port *mtk_port_search_by_id(struct mtk_port_mngr *port_mngr, int rx_ch)
+{
+	int tbl_type = MTK_PORT_TBL_TYPE(rx_ch);
+
+	if (tbl_type < PORT_TBL_SAP || tbl_type >= PORT_TBL_MAX)
+		return NULL;
+
+	return radix_tree_lookup(&port_mngr->port_tbl[tbl_type], MTK_CH_ID(rx_ch));
+}
+
+static struct mtk_port *mtk_port_search_by_name(struct mtk_port_mngr *port_mngr,
+						const char *name)
+{
+	int tbl_type = PORT_TBL_SAP;
+	struct radix_tree_iter iter;
+	struct mtk_port *port;
+	void __rcu **slot;
+
+	lockdep_assert_held(&mtk_port_mngr_grp_mtx);
+
+	do {
+		radix_tree_for_each_slot(slot, &port_mngr->port_tbl[tbl_type], &iter, 0) {
+			port = mtk_port_tbl_slot(&slot, &iter);
+			if (!port)
+				continue;
+			if (!strncmp(port->info.name, name, MTK_DFLT_PORT_NAME_LEN))
+				return port;
+		}
+		tbl_type++;
+	} while (tbl_type < PORT_TBL_MAX);
+
+	return NULL;
+}
+
+struct mtk_port *mtk_port_get_by_name(struct mtk_port_mngr *port_mngr, const char *name,
+				      enum mtk_port_type type)
+{
+	struct mtk_port *port;
+
+	mutex_lock(&mtk_port_mngr_grp_mtx);
+	port = mtk_port_search_by_name(port_mngr, name);
+	if (port && port->info.type == type)
+		kref_get(&port->kref);
+	else
+		port = NULL;
+	mutex_unlock(&mtk_port_mngr_grp_mtx);
+
+	return port;
+}
+
+static int mtk_port_tbl_create(struct mtk_port_mngr *port_mngr, const struct mtk_port_cfg *cfg,
+			       const int port_cnt)
+{
+	const struct mtk_port_cfg *dflt_port;
+	struct mtk_port *port;
+	int i;
+
+	INIT_RADIX_TREE(&port_mngr->port_tbl[PORT_TBL_SAP], GFP_KERNEL);
+	INIT_RADIX_TREE(&port_mngr->port_tbl[PORT_TBL_MD], GFP_KERNEL);
+
+	/* copy ports from static port cfg table */
+	for (i = 0; i < port_cnt; i++) {
+		dflt_port = cfg + i;
+		if (!mtk_port_search_by_id(port_mngr, dflt_port->rx_ch)) {
+			port = mtk_port_alloc_and_add(port_mngr, dflt_port);
+			if (IS_ERR(port))
+				return PTR_ERR(port);
+		}
+	}
+
+	return 0;
+}
+
+static void mtk_port_tbl_destroy(struct mtk_port_mngr *port_mngr)
+{
+	struct radix_tree_iter iter;
+	struct mtk_port *port;
+	void __rcu **slot;
+	int tbl_type;
+
+	tbl_type = PORT_TBL_SAP;
+	do {
+		radix_tree_for_each_slot(slot, &port_mngr->port_tbl[tbl_type], &iter, 0) {
+			port = mtk_port_tbl_slot(&slot, &iter);
+			if (!port)
+				continue;
+			mtk_port_get_ops(port->info.type)->disable(port);
+		}
+
+		while (radix_tree_gang_lookup(&port_mngr->port_tbl[tbl_type],
+					      (void **)&port, 0, 1))
+			mtk_port_free(port_mngr, port);
+	} while (++tbl_type < PORT_TBL_MAX);
+}
+
+void mtk_port_trb_init(struct mtk_port *port, struct trb *trb, enum mtk_trb_cmd_type cmd,
+		       int (*trb_complete)(struct sk_buff *skb))
+{
+	kref_init(&trb->kref);
+	trb->channel_id = port->info.rx_ch;
+	trb->status = MTK_DFLT_TRB_STATUS;
+	trb->done = false;
+	/* No reference is taken: the port must outlive every trb that names
+	 * it and every RX queue armed with this pointer as rxq->arg.
+	 */
+	trb->priv = port;
+	trb->cmd = cmd;
+	trb->trb_complete = trb_complete;
+}
+
+static bool mtk_port_trb_done(struct trb *trb)
+{
+	/* Pairs with the smp_store_release() in the completion callbacks. */
+	return smp_load_acquire(&trb->done);
+}
+
+void mtk_port_trb_free(struct kref *trb_kref)
+{
+	struct trb *trb = container_of(trb_kref, struct trb, kref);
+
+	dev_kfree_skb_any(container_of((char *)trb, struct sk_buff, cb[0]));
+}
+
+static int mtk_port_ch_trb_complete(struct sk_buff *skb)
+{
+	struct trb *trb = (struct trb *)skb->cb;
+	struct mtk_port *port = trb->priv;
+
+	/* Pairs with the smp_load_acquire() of trb->done in the waiters. */
+	smp_store_release(&trb->done, true);
+	wake_up_all(&port->trb_wq);
+	kref_put(&trb->kref, mtk_port_trb_free);
+
+	return 0;
+}
+
+static int mtk_port_tx_complete(struct sk_buff *skb)
+{
+	struct trb *trb = (struct trb *)skb->cb;
+	struct mtk_port *port = trb->priv;
+
+	if (trb->status < 0)
+		dev_warn_ratelimited(port->port_mngr->ctrl_blk->mdev->dev,
+				     "Failed to send data: status:%d, port:%s\n",
+				     trb->status, port->info.name);
+
+	/* Pairs with the smp_load_acquire() of trb->done in the waiters. */
+	smp_store_release(&trb->done, true);
+	wake_up_all(&port->trb_wq);
+	kref_put(&trb->kref, mtk_port_trb_free);
+
+	return 0;
+}
+
+int mtk_port_status_check(struct mtk_port *port)
+{
+	if (!test_bit(PORT_S_ENABLE, &port->status))
+		return -ENODEV;
+
+	if (!test_bit(PORT_S_OPEN, &port->status) || test_bit(PORT_S_FLUSH, &port->status) ||
+	    !test_bit(PORT_S_WR, &port->status))
+		return -EBADF;
+
+	return 0;
+}
+
+int mtk_port_send_data(struct mtk_port *port, void *data, bool blocking, bool force_send)
+{
+	struct mtk_port_mngr *port_mngr;
+	struct sk_buff *skb = data;
+	struct trb *trb;
+	int ret, len;
+
+	port_mngr = port->port_mngr;
+
+	trb = (struct trb *)skb->cb;
+	mtk_port_trb_init(port, trb, TRB_CMD_TX, mtk_port_tx_complete);
+	len = skb->len;
+	kref_get(&trb->kref); /* kref count 1->2 */
+
+	/* add ccci header */
+	ret = mtk_port_add_header(skb);
+	if (!ret)
+		ret = mtk_port_status_check(port);
+	if (!ret)
+		ret = mtk_pcie_hif_submit_skb(port_mngr->ctrl_blk->mdev, skb,
+					      force_send);
+
+	if (ret < 0) {
+		kref_put(&trb->kref, mtk_port_trb_free); /* kref count 2->1 */
+		kref_put(&trb->kref, mtk_port_trb_free); /* kref count 1->0 */
+		goto out;
+	}
+
+	if (!blocking) {
+		kref_put(&trb->kref, mtk_port_trb_free);
+		ret = len;
+		goto out;
+	}
+
+	/* no timeout in tx blocking mode */
+	ret = wait_event_interruptible(port->trb_wq,
+				       mtk_port_trb_done(trb) ||
+				       test_bit(PORT_S_FLUSH, &port->status) ||
+				       !test_bit(PORT_S_WR, &port->status));
+	/* Only a completed trb has a meaningful status; any other wake is
+	 * a write failure.
+	 */
+	if (ret)
+		ret = -EINTR;
+	else if (mtk_port_trb_done(trb))
+		ret = trb->status ? trb->status : len;
+	else
+		ret = -EBADF;
+	kref_put(&trb->kref, mtk_port_trb_free);
+
+out:
+	return ret;
+}
+
+/* A gap only means an earlier packet was lost; this one is still delivered. */
+static void mtk_port_check_rx_seq(struct mtk_port *port, struct mtk_ccci_header *ccci_h)
+{
+	u16 seq_num, assert_bit, channel;
+	struct mtk_md_dev *mdev;
+
+	seq_num = FIELD_GET(MTK_HDR_FLD_SEQ, le32_to_cpu(ccci_h->status));
+	assert_bit = FIELD_GET(MTK_HDR_FLD_AST, le32_to_cpu(ccci_h->status));
+	if (assert_bit && port->rx_seq != MTK_INVALID_RX_SEQ &&
+	    ((seq_num - port->rx_seq) & MTK_CHECK_RX_SEQ_MASK) != 1) {
+		mdev = port->port_mngr->ctrl_blk->mdev;
+		channel = FIELD_GET(MTK_HDR_FLD_CHN, le32_to_cpu(ccci_h->status));
+		dev_warn_ratelimited(mdev->dev,
+				     "<ch: %04x> seq num out-of-order %d->%d, len(%u)\n",
+				     channel, port->rx_seq, seq_num,
+				     le32_to_cpu(ccci_h->packet_len));
+	}
+}
+
+static int mtk_port_rx_dispatch(struct sk_buff *skb, void *priv)
+{
+	struct mtk_port_mngr *port_mngr;
+	struct mtk_ccci_header *ccci_h;
+	struct mtk_port *port = priv;
+	int ret = -EPROTO;
+	u16 channel;
+
+	if (!skb || !priv) {
+		pr_err("Invalid input value in rx dispatch\n");
+		return -EINVAL;
+	}
+
+	port_mngr = port->port_mngr;
+
+	ccci_h = mtk_port_strip_header(skb);
+	if (unlikely(!ccci_h)) {
+		dev_warn_ratelimited(port_mngr->ctrl_blk->mdev->dev,
+				     "Unsupported: skb length(%u) is less than ccci header\n",
+				     skb->len);
+		goto drop_data;
+	}
+
+	channel = FIELD_GET(MTK_HDR_FLD_CHN, le32_to_cpu(ccci_h->status));
+	/* A CLDMA instance carries the channels of one peer only (sAP or MD),
+	 * the peer of the port that armed this queue.
+	 */
+	if (MTK_PEER_ID(channel) == MTK_PEER_ID(port->info.rx_ch))
+		port = mtk_port_search_by_id(port_mngr, channel);
+	else
+		port = NULL;
+	if (unlikely(!port)) {
+		dev_warn_ratelimited(port_mngr->ctrl_blk->mdev->dev,
+				     "Failed to find port by channel:%d\n", channel);
+		goto drop_data;
+	}
+
+	mtk_port_check_rx_seq(port, ccci_h);
+	port->rx_seq = FIELD_GET(MTK_HDR_FLD_SEQ, le32_to_cpu(ccci_h->status));
+
+	ret = mtk_port_get_ops(port->info.type)->recv(port, skb);
+	if (ret < 0)
+		goto drop_data;
+
+	return ret;
+
+drop_data:
+	dev_kfree_skb_any(skb);
+	return ret;
+}
+
+int mtk_port_add_header(struct sk_buff *skb)
+{
+	struct mtk_ccci_header *ccci_h;
+	struct mtk_port *port;
+	struct trb *trb;
+	int ret;
+
+	trb = (struct trb *)skb->cb;
+	port = trb->priv;
+	if (!port)
+		return -EINVAL;
+
+	ret = skb_cow_head(skb, sizeof(*ccci_h));
+	if (ret)
+		return ret;
+
+	ccci_h = skb_push(skb, sizeof(*ccci_h));
+
+	ccci_h->packet_header = cpu_to_le32(0);
+	ccci_h->packet_len = cpu_to_le32(skb->len);
+	ccci_h->ex_msg = cpu_to_le32(0);
+	/* SEQ is stamped at hand-off, see mtk_port_tx_seq_stamp() */
+	ccci_h->status = cpu_to_le32(FIELD_PREP(MTK_HDR_FLD_CHN, port->info.tx_ch) |
+				     FIELD_PREP(MTK_HDR_FLD_AST, 1));
+
+	return 0;
+}
+
+/* Called around the hardware hand-off of a TX TRB, so a packet that
+ * fails before it reaches the ring does not consume a number.
+ */
+void mtk_port_tx_seq_stamp(struct sk_buff *skb)
+{
+	struct mtk_ccci_header *ccci_h = (struct mtk_ccci_header *)skb->data;
+	struct mtk_port *port = ((struct trb *)skb->cb)->priv;
+	u32 status = le32_to_cpu(ccci_h->status) & ~MTK_HDR_FLD_SEQ;
+
+	ccci_h->status = cpu_to_le32(status |
+				     FIELD_PREP(MTK_HDR_FLD_SEQ, port->tx_seq));
+}
+
+void mtk_port_tx_seq_advance(struct sk_buff *skb)
+{
+	struct mtk_port *port = ((struct trb *)skb->cb)->priv;
+
+	port->tx_seq++;
+}
+
+struct mtk_ccci_header *mtk_port_strip_header(struct sk_buff *skb)
+{
+	struct mtk_ccci_header *ccci_h;
+
+	if (!pskb_may_pull(skb, sizeof(*ccci_h)))
+		return NULL;
+
+	ccci_h = (struct mtk_ccci_header *)skb->data;
+	skb_pull(skb, sizeof(*ccci_h));
+
+	return ccci_h;
+}
+
+int mtk_port_status_update(struct mtk_md_dev *mdev, void *data, u32 data_len)
+{
+	struct mtk_port_enum_msg *msg = data;
+	struct mtk_port_info *port_info;
+	struct mtk_port_mngr *port_mngr;
+	struct mtk_ctrl_blk *ctrl_blk;
+	struct mtk_port *port;
+	int port_id;
+	u16 ch_id;
+
+	if (unlikely(!mdev || !msg))
+		return -EINVAL;
+
+	if (data_len < sizeof(*msg))
+		return -EPROTO;
+
+	ctrl_blk = mdev->ctrl_blk;
+	port_mngr = ctrl_blk->port_mngr;
+	if (le16_to_cpu(msg->version) != MTK_PORT_ENUM_VER ||
+	    le32_to_cpu(msg->head_pattern) != MTK_PORT_ENUM_HEAD_PATTERN ||
+	    le32_to_cpu(msg->tail_pattern) != MTK_PORT_ENUM_TAIL_PATTERN)
+		return -EPROTO;
+
+	if (data_len < sizeof(*msg) +
+	    le16_to_cpu(msg->port_cnt) * sizeof(*port_info))
+		return -EPROTO;
+
+	for (port_id = 0; port_id < le16_to_cpu(msg->port_cnt); port_id++) {
+		port_info = (struct mtk_port_info *)(msg->data +
+						   (sizeof(*port_info) * port_id));
+		ch_id = FIELD_GET(MTK_INFO_FLD_CHID, le16_to_cpu(port_info->channel));
+		port = mtk_port_search_by_id(port_mngr, ch_id);
+		if (!port)
+			continue;
+		port->enable = FIELD_GET(MTK_INFO_FLD_EN, le16_to_cpu(port_info->channel));
+	}
+
+	return 0;
+}
+
+int mtk_port_ch_enable(struct mtk_port *port)
+{
+	struct mtk_port_mngr *port_mngr = port->port_mngr;
+	struct trb_open_priv *trb_open_priv;
+	struct sk_buff *skb;
+	struct trb *trb;
+	int ret;
+
+	/* The modem restarts its sequence numbering with the channel, and
+	 * the first packet after it is not checked.
+	 */
+	port->tx_seq = 0;
+	port->rx_seq = MTK_INVALID_RX_SEQ;
+
+	skb = __dev_alloc_skb(sizeof(*trb_open_priv), GFP_KERNEL);
+	if (!skb)
+		return -ENOMEM;
+
+	trb_open_priv = (struct trb_open_priv *)skb->data;
+	trb_open_priv->rx_done = mtk_port_rx_dispatch;
+
+	skb_put(skb, sizeof(struct trb_open_priv));
+	trb = (struct trb *)skb->cb;
+	mtk_port_trb_init(port, trb, TRB_CMD_ENABLE, mtk_port_ch_trb_complete);
+	kref_get(&trb->kref);
+
+	ret = mtk_pcie_hif_submit_skb(port_mngr->ctrl_blk->mdev, skb, true);
+	if (ret) {
+		dev_err(port_mngr->ctrl_blk->mdev->dev,
+			"Failed to submit trb for port(%s), ret=%d\n",
+			port->info.name, ret);
+		kref_put(&trb->kref, mtk_port_trb_free);
+		kref_put(&trb->kref, mtk_port_trb_free);
+		return ret;
+	}
+
+	ret = wait_event_timeout(port->trb_wq, mtk_port_trb_done(trb),
+				 MTK_DFLT_TRB_TIMEOUT);
+	if (!ret) {
+		ret = -ETIMEDOUT;
+	} else {
+		/* The trb->done acquire in mtk_port_trb_done() orders the
+		 * geometry read below, on the -EBUSY completion too.  Pairs
+		 * with the smp_store_release() of trb->status in mtk_cldma_open().
+		 */
+		ret = smp_load_acquire(&trb->status);
+
+		/* -EBUSY means another user already owns the queue, and the
+		 * geometry it reports is that queue's - also valid here.
+		 */
+		if (!ret || ret == -EBUSY)
+			port->tx_mtu = trb_open_priv->tx_mtu - MTK_CCCI_H_ELEN;
+	}
+
+	kref_put(&trb->kref, mtk_port_trb_free);
+
+	return ret;
+}
+
+int mtk_port_ch_disable(struct mtk_port *port)
+{
+	struct mtk_port_mngr *port_mngr = port->port_mngr;
+	struct sk_buff *skb;
+	struct trb *trb;
+	int ret;
+
+	skb = __dev_alloc_skb(0, GFP_KERNEL);
+	if (!skb)
+		return -ENOMEM;
+
+	trb = (struct trb *)skb->cb;
+	mtk_port_trb_init(port, trb, TRB_CMD_DISABLE, mtk_port_ch_trb_complete);
+	kref_get(&trb->kref);
+
+	ret = mtk_pcie_hif_submit_skb(port_mngr->ctrl_blk->mdev, skb, true);
+	if (ret) {
+		dev_warn(port_mngr->ctrl_blk->mdev->dev,
+			 "Failed to submit trb for port(%s), ret=%d\n",
+			 port->info.name, ret);
+		kref_put(&trb->kref, mtk_port_trb_free);
+		kref_put(&trb->kref, mtk_port_trb_free);
+		return ret;
+	}
+
+	ret = wait_event_timeout(port->trb_wq, mtk_port_trb_done(trb),
+				 MTK_DFLT_TRB_TIMEOUT);
+	if (!ret)
+		ret = -ETIMEDOUT;
+	else
+		ret = trb->status;
+
+	kref_put(&trb->kref, mtk_port_trb_free);
+
+	return ret;
+}
+
+int mtk_port_mngr_init(struct mtk_ctrl_blk *ctrl_blk, const struct mtk_port_cfg *port_cfg,
+		       int port_cnt)
+{
+	struct mtk_port_mngr *port_mngr;
+	int ret = -ENOMEM;
+
+	port_mngr = devm_kzalloc(ctrl_blk->mdev->dev, sizeof(*port_mngr), GFP_KERNEL);
+	if (unlikely(!port_mngr)) {
+		dev_err((ctrl_blk->mdev)->dev, "Failed to alloc memory for port_mngr\n");
+		goto err_out;
+	}
+
+	port_mngr->ctrl_blk = ctrl_blk;
+	mutex_init(&port_mngr->port_tbl_mtx);
+
+	ret = mtk_port_tbl_create(port_mngr, port_cfg, port_cnt);
+	if (unlikely(ret)) {
+		dev_err((ctrl_blk->mdev)->dev, "Failed to create port_tbl\n");
+		goto err_destroy_tbl;
+	}
+
+	ctrl_blk->port_mngr = port_mngr;
+
+	return ret;
+
+err_destroy_tbl:
+	mtk_port_tbl_destroy(port_mngr);
+err_out:
+	return ret;
+}
+
+void mtk_port_mngr_exit(struct mtk_ctrl_blk *ctrl_blk)
+{
+	struct mtk_port_mngr *port_mngr = ctrl_blk->port_mngr;
+
+	mtk_port_tbl_destroy(port_mngr);
+
+	ctrl_blk->port_mngr = NULL;
+}
diff --git a/drivers/net/wwan/t9xx/mtk_port.h b/drivers/net/wwan/t9xx/mtk_port.h
new file mode 100644
index 000000000000..157eda4b4220
--- /dev/null
+++ b/drivers/net/wwan/t9xx/mtk_port.h
@@ -0,0 +1,133 @@
+/* SPDX-License-Identifier: GPL-2.0-only
+ *
+ * Copyright (c) 2022, MediaTek Inc.
+ */
+
+#ifndef __MTK_PORT_H__
+#define __MTK_PORT_H__
+
+#include <linux/bits.h>
+#include <linux/device.h>
+#include <linux/radix-tree.h>
+#include <linux/skbuff.h>
+#include <linux/types.h>
+
+#include "mtk_ctrl_plane.h"
+#include "mtk_dev.h"
+
+#define MTK_PEER_ID_MASK			(0xF000)
+#define MTK_PEER_ID_SHIFT			(12)
+#define MTK_PEER_ID(ch)				(((ch) & MTK_PEER_ID_MASK) >> MTK_PEER_ID_SHIFT)
+#define MTK_CH_ID_MASK				(0x0FFF)
+#define MTK_CH_ID(ch)				((ch) & MTK_CH_ID_MASK)
+#define MTK_DFLT_PORT_NAME_LEN			(20)
+
+/* Mapping MTK_PEER_ID and mtk_port_tbl index */
+#define MTK_PORT_TBL_TYPE(ch)			(MTK_PEER_ID(ch) - 1)
+
+/* ccci header length + reserved space that is used in exception flow */
+#define MTK_CCCI_H_ELEN		(128)
+
+#define MTK_HDR_FLD_AST		((u32)BIT(31))
+#define MTK_HDR_FLD_SEQ		GENMASK(30, 16)
+#define MTK_HDR_FLD_CHN		GENMASK(15, 0)
+
+#define MTK_INFO_FLD_EN		((u16)BIT(15))
+#define MTK_INFO_FLD_CHID	GENMASK(14, 0)
+
+/* State bits, not locks: callers serialise ->enable(), ->disable() and
+ * open of a port.  The atomic bitops only make a repeated call a no-op.
+ */
+enum mtk_port_status {
+	PORT_S_ENABLE,
+	PORT_S_OPEN,
+	PORT_S_WR,
+	PORT_S_FLUSH,
+};
+
+enum mtk_port_flag {
+	PORT_F_DFLT = 0,
+	PORT_F_BLOCKING = BIT(1),
+};
+
+enum mtk_port_tbl {
+	PORT_TBL_SAP,
+	PORT_TBL_MD,
+	PORT_TBL_MAX
+};
+
+enum mtk_port_type {
+	PORT_TYPE_INTERNAL,
+	PORT_TYPE_MAX
+};
+
+struct mtk_internal_port {
+	void *arg;
+	int (*recv_cb)(void *arg, struct sk_buff *skb);
+};
+
+struct mtk_port_cfg {
+	enum mtk_ccci_ch tx_ch;
+	enum mtk_ccci_ch rx_ch;
+	enum mtk_port_type type;
+	char name[MTK_DFLT_PORT_NAME_LEN];
+	unsigned char flags;
+};
+
+struct mtk_port {
+	struct mtk_port_cfg info;
+	struct kref kref;
+	struct rcu_head rcu;
+	bool enable;
+	unsigned long status;
+	/* tx_seq is stamped and advanced only at hardware hand-off, by the one
+	 * thread serving this port's TX queue; rx_seq only from the rx_done
+	 * callback of the one queue serving this channel.  Both are reset
+	 * while the channel is disabled, so neither needs a lock.
+	 */
+	unsigned short tx_seq;
+	unsigned short rx_seq;
+	unsigned int tx_mtu;
+	wait_queue_head_t trb_wq;
+	struct mtk_port_mngr *port_mngr;
+	struct mtk_internal_port i_priv;
+};
+
+struct mtk_port_mngr {
+	struct mtk_ctrl_blk *ctrl_blk;
+	struct radix_tree_root port_tbl[PORT_TBL_MAX];
+	/* protects port_tbl[] against concurrent mutators */
+	struct mutex port_tbl_mtx;
+};
+
+struct mtk_ccci_header {
+	__le32 packet_header;
+	__le32 packet_len;
+	__le32 status;
+	__le32 ex_msg;
+};
+
+struct mtk_port_layer_cfg {
+	const struct mtk_port_cfg *port_cfg;
+	int port_cnt;
+};
+
+void mtk_port_release(struct kref *port_kref);
+void mtk_port_trb_free(struct kref *trb_kref);
+struct mtk_port *mtk_port_get_by_name(struct mtk_port_mngr *port_mngr, const char *name,
+				      enum mtk_port_type type);
+int mtk_port_add_header(struct sk_buff *skb);
+void mtk_port_tx_seq_stamp(struct sk_buff *skb);
+void mtk_port_tx_seq_advance(struct sk_buff *skb);
+struct mtk_ccci_header *mtk_port_strip_header(struct sk_buff *skb);
+int mtk_port_status_check(struct mtk_port *port);
+int mtk_port_send_data(struct mtk_port *port, void *data, bool blocking, bool force_send);
+int mtk_port_status_update(struct mtk_md_dev *mdev, void *data, u32 data_len);
+int mtk_port_ch_enable(struct mtk_port *port);
+int mtk_port_ch_disable(struct mtk_port *port);
+int mtk_port_mngr_init(struct mtk_ctrl_blk *ctrl_blk, const struct mtk_port_cfg *port_cfg,
+		       int port_cnt);
+void mtk_port_mngr_exit(struct mtk_ctrl_blk *ctrl_blk);
+void mtk_port_trb_init(struct mtk_port *port, struct trb *trb, enum mtk_trb_cmd_type cmd,
+		       int (*trb_complete)(struct sk_buff *skb));
+#endif /* __MTK_PORT_H__ */
diff --git a/drivers/net/wwan/t9xx/mtk_port_io.c b/drivers/net/wwan/t9xx/mtk_port_io.c
new file mode 100644
index 000000000000..e92ce1cb7c00
--- /dev/null
+++ b/drivers/net/wwan/t9xx/mtk_port_io.c
@@ -0,0 +1,229 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (c) 2022, MediaTek Inc.
+ */
+#include <linux/netdevice.h>
+
+#include "mtk_port_io.h"
+
+static void mtk_port_put_locked(struct mtk_port *port)
+{
+	mutex_lock(&mtk_port_mngr_grp_mtx);
+	kref_put(&port->kref, mtk_port_release);
+	mutex_unlock(&mtk_port_mngr_grp_mtx);
+}
+
+static void mtk_port_struct_init(struct mtk_port *port)
+{
+	clear_bit(PORT_S_ENABLE, &port->status);
+	kref_init(&port->kref);
+	init_waitqueue_head(&port->trb_wq);
+}
+
+static int mtk_port_internal_init(struct mtk_port *port)
+{
+	mtk_port_struct_init(port);
+	port->enable = false;
+
+	return 0;
+}
+
+static void mtk_port_internal_exit(struct mtk_port *port)
+{
+	if (test_bit(PORT_S_ENABLE, &port->status))
+		mtk_port_get_ops(port->info.type)->disable(port);
+}
+
+static void mtk_port_internal_enable(struct mtk_port *port)
+{
+	int ret;
+
+	if (test_and_set_bit(PORT_S_ENABLE, &port->status))
+		return;
+
+	ret = mtk_port_ch_enable(port);
+	if (ret && ret != -EBUSY) {
+		/* On -ETIMEDOUT the ENABLE trb may still be queued; queue a
+		 * DISABLE behind it so the channel does not end up armed with
+		 * no software owner.
+		 */
+		mtk_port_ch_disable(port);
+		clear_bit(PORT_S_ENABLE, &port->status);
+		return;
+	}
+
+	set_bit(PORT_S_WR, &port->status);
+}
+
+static void mtk_port_internal_disable(struct mtk_port *port)
+{
+	int ret;
+
+	if (!test_and_clear_bit(PORT_S_ENABLE, &port->status))
+		return;
+
+	/* PORT_S_WR is in the blocking TX wait condition: wake the waiters. */
+	clear_bit(PORT_S_WR, &port->status);
+	wake_up_all(&port->trb_wq);
+
+	/* Failure must not abort teardown or keep PORT_S_ENABLE set:
+	 * usr_cnt and the queues are rebuilt together by the next
+	 * mtk_pcie_hif_init(), and a port left with the bit set could never
+	 * be re-enabled (mtk_port_internal_enable() early-returns).
+	 */
+	ret = mtk_port_ch_disable(port);
+	if (ret)
+		dev_warn(port->port_mngr->ctrl_blk->mdev->dev,
+			 "Failed to disable channel for port(%s): %d\n",
+			 port->info.name, ret);
+}
+
+static int mtk_port_internal_recv(struct mtk_port *port, struct sk_buff *skb)
+{
+	int (*recv_cb)(void *priv, struct sk_buff *skb);
+	struct mtk_internal_port *priv;
+	int ret = -ENXIO;
+
+	if (!test_bit(PORT_S_OPEN, &port->status))
+		goto drop_data;
+
+	priv = &port->i_priv;
+	/* Pairs with the smp_store_release() in mtk_port_internal_recv_register(). */
+	recv_cb = smp_load_acquire(&priv->recv_cb);
+	if (!recv_cb || !priv->arg)
+		goto drop_data;
+
+	ret = recv_cb(priv->arg, skb);
+	return ret;
+
+drop_data:
+	return ret;
+}
+
+static int mtk_port_common_open(struct mtk_port *port)
+{
+	int ret = 0;
+
+	if (!test_bit(PORT_S_ENABLE, &port->status))
+		return -ENODEV;
+
+	if (test_and_set_bit(PORT_S_OPEN, &port->status))
+		return -EBUSY;
+
+	clear_bit(PORT_S_FLUSH, &port->status);
+
+	return ret;
+}
+
+static void mtk_port_common_close(struct mtk_port *port)
+{
+	clear_bit(PORT_S_OPEN, &port->status);
+
+	set_bit(PORT_S_FLUSH, &port->status);
+	wake_up_all(&port->trb_wq);
+}
+
+void *mtk_port_internal_open(struct mtk_md_dev *mdev, char *name, int flag)
+{
+	struct mtk_port_mngr *port_mngr;
+	struct mtk_ctrl_blk *ctrl_blk;
+	struct mtk_port *port;
+	int ret;
+
+	ctrl_blk = mdev->ctrl_blk;
+	port_mngr = ctrl_blk->port_mngr;
+
+	port = mtk_port_get_by_name(port_mngr, name, PORT_TYPE_INTERNAL);
+	if (!port)
+		goto out;
+
+	ret = mtk_port_common_open(port);
+	if (ret) {
+		mtk_port_put_locked(port);
+		port = NULL;
+		goto out;
+	}
+
+	if (flag & O_NONBLOCK)
+		port->info.flags &= ~PORT_F_BLOCKING;
+	else
+		port->info.flags |= PORT_F_BLOCKING;
+out:
+	return port;
+}
+
+int mtk_port_internal_close(void *i_port)
+{
+	struct mtk_port *port = i_port;
+	int ret = 0;
+
+	if (!port) {
+		ret = -EINVAL;
+		goto end;
+	}
+
+	if (!test_and_clear_bit(PORT_S_OPEN, &port->status)) {
+		pr_err("Port(%s) has been closed\n", port->info.name);
+		ret = -EBADF;
+		goto end;
+	}
+
+	mtk_port_common_close(port);
+	mtk_port_put_locked(port);
+end:
+	return ret;
+}
+
+/* Consumes @skb, on failure too. */
+int mtk_port_internal_write(void *i_port, struct sk_buff *skb)
+{
+	struct mtk_port *port = i_port;
+	bool blocking;
+
+	if (!port || !skb) {
+		if (skb)
+			dev_kfree_skb_any(skb);
+		pr_err_ratelimited("Internal write: invalid input\n");
+		return -EINVAL;
+	}
+
+	blocking = !!(port->info.flags & PORT_F_BLOCKING);
+
+	return mtk_port_send_data(port, skb, blocking, blocking);
+}
+
+/* @cb and @arg must stay valid until the receive path has been drained:
+ * closing the port does not unregister them or wait for a callback that is
+ * already running, so close alone does not make freeing @arg safe.
+ * @cb owns the skb when it returns 0 or more; on a negative return the
+ * caller frees it, so @cb must not.
+ */
+void mtk_port_internal_recv_register(void *i_port,
+				     int (*cb)(void *priv, struct sk_buff *skb),
+				     void *arg)
+{
+	struct mtk_port *port = i_port;
+	struct mtk_internal_port *priv;
+
+	priv = &port->i_priv;
+	priv->arg = arg;
+	/* Pairs with the smp_load_acquire() in mtk_port_internal_recv(). */
+	smp_store_release(&priv->recv_cb, cb);
+}
+
+static const struct mtk_port_ops port_internal_ops = {
+	.init = mtk_port_internal_init,
+	.exit = mtk_port_internal_exit,
+	.enable = mtk_port_internal_enable,
+	.disable = mtk_port_internal_disable,
+	.recv = mtk_port_internal_recv,
+};
+
+static const struct mtk_port_ops *mtk_port_ops_tbl[PORT_TYPE_MAX] = {
+	&port_internal_ops,
+};
+
+const struct mtk_port_ops *mtk_port_get_ops(enum mtk_port_type type)
+{
+	return mtk_port_ops_tbl[type];
+}
diff --git a/drivers/net/wwan/t9xx/mtk_port_io.h b/drivers/net/wwan/t9xx/mtk_port_io.h
new file mode 100644
index 000000000000..db1d9ae52d9a
--- /dev/null
+++ b/drivers/net/wwan/t9xx/mtk_port_io.h
@@ -0,0 +1,32 @@
+/* SPDX-License-Identifier: GPL-2.0-only
+ *
+ * Copyright (c) 2022, MediaTek Inc.
+ */
+
+#ifndef __MTK_PORT_IO_H__
+#define __MTK_PORT_IO_H__
+
+#include <linux/skbuff.h>
+
+#include "mtk_port.h"
+
+extern struct mutex mtk_port_mngr_grp_mtx;
+
+struct mtk_port_ops {
+	int (*init)(struct mtk_port *port);
+	void (*exit)(struct mtk_port *port);
+	void (*enable)(struct mtk_port *port);
+	void (*disable)(struct mtk_port *port);
+	int (*recv)(struct mtk_port *port, struct sk_buff *skb);
+};
+
+const struct mtk_port_ops *mtk_port_get_ops(enum mtk_port_type type);
+
+void *mtk_port_internal_open(struct mtk_md_dev *mdev, char *name, int flag);
+int mtk_port_internal_close(void *i_port);
+int mtk_port_internal_write(void *i_port, struct sk_buff *skb);
+void mtk_port_internal_recv_register(void *i_port,
+				     int (*cb)(void *priv, struct sk_buff *skb),
+				     void *arg);
+
+#endif /* __MTK_PORT_IO_H__ */
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c b/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c
index 826e548b2d4d..8b61c3eac035 100644
--- a/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c
+++ b/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c
@@ -13,6 +13,7 @@
 #include "mtk_ctrl_plane.h"
 #include "mtk_dev.h"
 #include "mtk_pci.h"
+#include "mtk_port.h"
 #include "mtk_trans_ctrl.h"
 
 #define QUEUE_CHL_MASK	0xFFFF
@@ -31,6 +32,18 @@ static const struct queue_info mtk_queue_info[] = {
 	 Q_MTU_3_5K, Q_MTU_3_5K, TX_GPD_NUM, RX_GPD_NUM, 0},
 };
 
+static const struct mtk_port_cfg mtk_port_cfg_tbl[] = {
+	{CCCI_CONTROL_TX, CCCI_CONTROL_RX, PORT_TYPE_INTERNAL, "MDCTRL",
+		PORT_F_DFLT},
+	{CCCI_SAP_CONTROL_TX, CCCI_SAP_CONTROL_RX, PORT_TYPE_INTERNAL, "SAPCTRL",
+		PORT_F_DFLT},
+};
+
+static struct mtk_port_layer_cfg mtk_port_layer_cfg = {
+	.port_cfg = mtk_port_cfg_tbl,
+	.port_cnt = ARRAY_SIZE(mtk_port_cfg_tbl),
+};
+
 static bool mtk_queue_list_is_full(struct mtk_ctrl_trans *trans, struct queue_info *que)
 {
 	return skb_queue_len_lockless(&trans->trans_list[que->hif_id].skb_list[que->txqno]) >=
@@ -170,6 +183,7 @@ static void mtk_ctrl_trb_handler(struct trb_srv *srv, struct trans_list *trans_l
 			break;
 		}
 		trb = (struct trb *)skb->cb;
+		kref_get(&trb->kref);
 
 		switch (trb->cmd) {
 		case TRB_CMD_ENABLE:
@@ -185,14 +199,17 @@ static void mtk_ctrl_trb_handler(struct trb_srv *srv, struct trans_list *trans_l
 			break;
 		case TRB_CMD_TX:
 			spin_unlock_irqrestore(&skb_list->lock, flags);
+			mtk_port_tx_seq_stamp(skb);
 			err = mtk_cldma_submit_tx(trans->dev, skb);
 			if (err) {
 				if (trans_list->tx_burst_cnt[qno]) {
 					kick = true;
 					break;
 				}
-				if (err == -EAGAIN)
+				if (err == -EAGAIN) {
+					kref_put(&trb->kref, mtk_port_trb_free);
 					return;
+				}
 
 				skb_unlink(skb, skb_list);
 				trb->status = err;
@@ -200,6 +217,7 @@ static void mtk_ctrl_trb_handler(struct trb_srv *srv, struct trans_list *trans_l
 				break;
 			}
 
+			mtk_port_tx_seq_advance(skb);
 			trans_list->tx_burst_cnt[qno]++;
 			spin_lock_irqsave(&skb_list->lock, flags);
 			if (trans_list->tx_burst_cnt[qno] >= TX_BURST_MAX_CNT ||
@@ -233,6 +251,8 @@ static void mtk_ctrl_trb_handler(struct trb_srv *srv, struct trans_list *trans_l
 			kick = false;
 		}
 
+		kref_put(&trb->kref, mtk_port_trb_free);
+
 		loop++;
 	} while (loop < TRB_NUM_PER_ROUND);
 }
@@ -479,6 +499,9 @@ int mtk_pcie_hif_exit(struct mtk_md_dev *mdev)
 	return 0;
 }
 
+/* skb->cb holds a trb set up by mtk_port_trb_init(); a TX skb starts with
+ * its CCCI header and has the sending port as trb->priv.
+ */
 int mtk_pcie_hif_submit_skb(struct mtk_md_dev *mdev, struct sk_buff *skb, bool force_send)
 {
 	struct mtk_ctrl_blk *ctrl_blk = mdev->ctrl_blk;
@@ -600,7 +623,7 @@ int mtk_trans_ctrl_init(struct mtk_md_dev *mdev)
 	trans->queue_info_num = ARRAY_SIZE(mtk_queue_info);
 	trans->trb_srv_num = TRB_SRV_NUM;
 
-	err = mtk_ctrl_init(mdev);
+	err = mtk_ctrl_init(mdev, &mtk_port_layer_cfg);
 	if (err)
 		return err;
 

-- 
2.34.1

