From: Jack Wu <jackbb_wu@compal.com>
Date: Wed, 14 Oct 2026 10:51:02 +0800
Subject: [PATCH v10 4/6] net: wwan: t9xx: Add control port
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261014-t9xx_driver_v1-v10-4-4d0dde3613f5@compal.com>
References: <20261014-t9xx_driver_v1-v10-0-4d0dde3613f5@compal.com>
In-Reply-To: <20261014-t9xx_driver_v1-v10-0-4d0dde3613f5@compal.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791946362; l=39829;
 i=jackbb_wu@compal.com; s=20260526; h=from:subject:message-id;
 bh=cGGUfsH3QCZYnBY9NgjsCsCjDW0XcE1z8IDnvjPCKb0=;
 b=8yc7yzqpin1sc7Lv1lWERPSkd4DR3GBT1i+yF1dUQapJUy8bp25eWN1AroPPEfRCZUx0h5LGr
 JKrZATVWwJ/DJkWY17WRy41r0G5EEbTp7smDykTzco3rQVVXioEyrnr
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

Signed-off-by: Jack Wu <jackbb_wu@compal.com>
---
 drivers/net/wwan/t9xx/Makefile              |   2 +
 drivers/net/wwan/t9xx/mtk_ctrl_plane.c      |  17 +-
 drivers/net/wwan/t9xx/mtk_ctrl_plane.h      |  20 +-
 drivers/net/wwan/t9xx/mtk_port.c            | 760 ++++++++++++++++++++++++++++
 drivers/net/wwan/t9xx/mtk_port.h            | 131 +++++
 drivers/net/wwan/t9xx/mtk_port_io.c         | 230 +++++++++
 drivers/net/wwan/t9xx/mtk_port_io.h         |  34 ++
 drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c |  22 +-
 drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.h |   1 +
 9 files changed, 1210 insertions(+), 7 deletions(-)

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
index 81f6b3fbc0bd..077b55744ee6 100644
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
 
@@ -42,5 +52,8 @@ int mtk_ctrl_init(struct mtk_md_dev *mdev)
  */
 void mtk_ctrl_exit(struct mtk_md_dev *mdev)
 {
+	struct mtk_ctrl_blk *ctrl_blk = mdev->ctrl_blk;
+
+	mtk_port_mngr_exit(ctrl_blk);
 	mdev->ctrl_blk = NULL;
 }
diff --git a/drivers/net/wwan/t9xx/mtk_ctrl_plane.h b/drivers/net/wwan/t9xx/mtk_ctrl_plane.h
index 9a8454806ecd..9a015b064f7e 100644
--- a/drivers/net/wwan/t9xx/mtk_ctrl_plane.h
+++ b/drivers/net/wwan/t9xx/mtk_ctrl_plane.h
@@ -6,12 +6,13 @@
 #ifndef __MTK_CTRL_PLANE_H__
 #define __MTK_CTRL_PLANE_H__
 
+#include <linux/kref.h>
 #include <linux/skbuff.h>
 
 #include "mtk_dev.h"
 
-#define Q_MTU_3_5K	(0xE00)
-#define Q_FRAG_3_5K	(0xE00)
+#define Q_MTU_3_5K			(0xE00)
+#define Q_FRAG_3_5K			(0xE00)
 
 enum mtk_ccci_ch {
 	/* to sAP */
@@ -49,6 +50,15 @@ struct trb {
 	u32 channel_id;
 	enum mtk_trb_cmd_type cmd;
 	int status;
+	/* Store-release by the completion callback, load-acquire by the
+	 * waiter: seeing it set means seeing everything the callback wrote.
+	 */
+	bool done;
+	/* The ccci header has already been pushed onto this skb. */
+	bool hdr_added;
+	/* A TX sequence number was consumed and must be rolled back on error. */
+	bool seq_taken;
+	struct kref kref;
 	void *priv;
 	int (*trb_complete)(struct sk_buff *skb);
 };
@@ -57,12 +67,16 @@ union ctrl_hif_cmd_data {
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
index 000000000000..a5ad57fff9d0
--- /dev/null
+++ b/drivers/net/wwan/t9xx/mtk_port.c
@@ -0,0 +1,760 @@
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
+
+#define MTK_PORT_ENUM_VER		(0)
+#define MTK_PORT_ENUM_HEAD_PATTERN	(0x5a5a5a5a)
+#define MTK_PORT_ENUM_TAIL_PATTERN	(0xa5a5a5a5)
+
+#define MTK_PORT_SEARCH_FROM_RADIX_TREE(p, s) ({\
+	struct mtk_port *_p;			\
+	_p = rcu_dereference_raw(*(s));		\
+	if (!_p)				\
+		continue;			\
+	p = _p;					\
+})
+
+#define MTK_PORT_INTERNAL_NODE_CHECK(p, s, i) ({\
+	if (radix_tree_is_internal_node(p)) {	\
+		s = radix_tree_iter_retry(&(i));\
+		continue;			\
+	}					\
+})
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
+/* mutex lock for the port refcount */
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
+				port->info.rx_ch & 0xFFF, port);
+	if (!ret)
+		port_mngr->port_cnt++;
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
+			  port->info.rx_ch & 0xFFF);
+	port_mngr->port_cnt--;
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
+			MTK_PORT_SEARCH_FROM_RADIX_TREE(port, slot);
+			MTK_PORT_INTERNAL_NODE_CHECK(port, slot, iter);
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
+			MTK_PORT_SEARCH_FROM_RADIX_TREE(port, slot);
+			MTK_PORT_INTERNAL_NODE_CHECK(port, slot, iter);
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
+	trb->hdr_added = false;
+	trb->seq_taken = false;
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
+	struct sk_buff *skb, *frag_skb, *next_skb;
+
+	skb = container_of((char *)trb, struct sk_buff, cb[0]);
+	/* Free frag_list for scatter gather TX */
+	if (trb->cmd == TRB_CMD_TX && skb_has_frag_list(skb)) {
+		frag_skb = skb_shinfo(skb)->frag_list;
+		while (frag_skb) {
+			next_skb = frag_skb->next;
+			frag_skb->next = NULL;
+			dev_kfree_skb_any(frag_skb);
+			frag_skb = next_skb;
+		}
+		skb_shinfo(skb)->frag_list = NULL;
+		skb->data_len = 0;
+	}
+	dev_kfree_skb_any(skb);
+}
+
+static int mtk_port_open_trb_complete(struct sk_buff *skb)
+{
+	struct trb *trb = (struct trb *)skb->cb;
+	struct mtk_port *port = trb->priv;
+
+	/* Pairs with the smp_load_acquire() of trb->done in the waiters. */
+	smp_store_release(&trb->done, true);
+	wake_up_all(&port->trb_wq);
+
+	kref_put(&trb->kref, mtk_port_trb_free);
+	return 0;
+}
+
+static int mtk_port_close_trb_complete(struct sk_buff *skb)
+{
+	struct trb *trb = (struct trb *)skb->cb;
+	struct mtk_port *port = trb->priv;
+
+	/* Pairs with the smp_load_acquire() of trb->done in the waiters. */
+	smp_store_release(&trb->done, true);
+	wake_up_all(&port->trb_wq);
+	wake_up_all(&port->rx_wq);
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
+		dev_warn(port->port_mngr->ctrl_blk->mdev->dev,
+			 "Failed to send data: status:%d, port:%s\n",
+			 trb->status, port->info.name);
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
+		/* The puts below free the skb that trb lives in, so sample
+		 * the flag while it is still valid.
+		 */
+		bool seq_taken = trb->seq_taken;
+
+		kref_put(&trb->kref, mtk_port_trb_free); /* kref count 2->1 */
+		kref_put(&trb->kref, mtk_port_trb_free); /* kref count 1->0 */
+		if (seq_taken)
+			port->tx_seq--;
+		goto out;
+	}
+
+	if (!blocking) {
+		kref_put(&trb->kref, mtk_port_trb_free);
+		ret = len;
+		goto out;
+	}
+start_wait:
+
+	/* wait trb done, and no timeout in tx blocking mode */
+	ret = wait_event_interruptible_timeout(port->trb_wq,
+					       mtk_port_trb_done(trb) ||
+					       test_bit(PORT_S_FLUSH, &port->status) ||
+					       !test_bit(PORT_S_WR, &port->status),
+					       MTK_DFLT_TRB_TIMEOUT);
+	if (!ret) {
+		goto start_wait;
+	} else if (ret == -ERESTARTSYS) {
+		ret = -EINTR;
+	} else if (ret > 0) {
+		/* Flush is the modem reset path: the port did take the data,
+		 * so report a full write.  Only a completed trb has a
+		 * meaningful status; any other wake is a write failure.
+		 */
+		if (test_bit(PORT_S_FLUSH, &port->status))
+			ret = len;
+		else if (mtk_port_trb_done(trb))
+			ret = trb->status ? trb->status : len;
+		else
+			ret = -EBADF;
+	}
+	kref_put(&trb->kref, mtk_port_trb_free);
+
+out:
+	return ret;
+}
+
+static int mtk_port_check_rx_seq(struct mtk_port *port, struct mtk_ccci_header *ccci_h)
+{
+	u16 seq_num, assert_bit, channel;
+	struct mtk_md_dev *mdev;
+
+	seq_num = FIELD_GET(MTK_HDR_FLD_SEQ, le32_to_cpu(ccci_h->status));
+	assert_bit = FIELD_GET(MTK_HDR_FLD_AST, le32_to_cpu(ccci_h->status));
+	if (assert_bit && port->rx_seq &&
+	    ((seq_num - port->rx_seq) & MTK_CHECK_RX_SEQ_MASK) != 1) {
+		mdev = port->port_mngr->ctrl_blk->mdev;
+		channel = FIELD_GET(MTK_HDR_FLD_CHN, le32_to_cpu(ccci_h->status));
+		dev_warn(mdev->dev,
+			 "<ch: %04x> seq num out-of-order %d->%d, len(%u)\n",
+			 channel, seq_num, port->rx_seq,
+			 le32_to_cpu(ccci_h->packet_len));
+
+		port->rx_seq = seq_num;
+		return -EPROTO;
+	}
+
+	return 0;
+}
+
+static int mtk_port_rx_dispatch_frag_skb(struct mtk_port *port, struct sk_buff *skb)
+{
+	struct sk_buff *frag_skb, *frag_next;
+	int ret;
+
+	frag_skb = skb_shinfo(skb)->frag_list;
+	skb->len -= skb->data_len;
+	skb->data_len = 0;
+	skb_shinfo(skb)->frag_list = NULL;
+
+	ret = mtk_port_get_ops(port->info.type)->recv(port, skb);
+	if (ret < 0) {
+		skb_shinfo(skb)->frag_list = frag_skb;
+		return ret;
+	}
+
+	while (frag_skb) {
+		frag_next = frag_skb->next;
+		if (!frag_skb->len) {
+			frag_skb->next = NULL;
+			dev_kfree_skb_any(frag_skb);
+			frag_skb = frag_next;
+			continue;
+		}
+		frag_skb->next = NULL;
+		ret = mtk_port_get_ops(port->info.type)->recv(port, frag_skb);
+		if (ret < 0) {
+			frag_skb->next = frag_next;
+			while (frag_skb) {
+				frag_next = frag_skb->next;
+				frag_skb->next = NULL;
+				dev_kfree_skb_any(frag_skb);
+				frag_skb = frag_next;
+			}
+			return -EIO;
+		}
+		frag_skb = frag_next;
+	}
+
+	return 0;
+}
+
+static int mtk_port_rx_dispatch(struct sk_buff *skb, void *priv, bool force_recv)
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
+		dev_warn(port_mngr->ctrl_blk->mdev->dev,
+			 "Unsupported: skb length(%d) is less than ccci header\n",
+			 skb->len);
+		goto drop_data;
+	}
+
+	channel = FIELD_GET(MTK_HDR_FLD_CHN, le32_to_cpu(ccci_h->status));
+	port = mtk_port_search_by_id(port_mngr, channel);
+	if (unlikely(!port)) {
+		dev_warn(port_mngr->ctrl_blk->mdev->dev,
+			 "Failed to find port by channel:%d\n", channel);
+		goto drop_data;
+	}
+
+	ret = mtk_port_check_rx_seq(port, ccci_h);
+	if (unlikely(ret))
+		goto drop_data;
+
+	port->rx_seq = FIELD_GET(MTK_HDR_FLD_SEQ, le32_to_cpu(ccci_h->status));
+	skb_pull(skb, sizeof(*ccci_h));
+
+	/* Support scatter gather transmission */
+	if (port->rx_mtu > port->rx_frag_size) {
+		ret = mtk_port_rx_dispatch_frag_skb(port, skb);
+		/* -EIO means partial data dispatch complete, does not goto drop flow */
+		if (ret < 0 && ret != -EIO)
+			goto drop_frag_skb;
+	} else {
+		ret = mtk_port_get_ops(port->info.type)->recv(port, skb);
+		if (ret < 0)
+			goto drop_data;
+	}
+
+	return ret;
+
+drop_frag_skb:
+	{
+		struct sk_buff *frag_skb, *tmp;
+
+		frag_skb = skb_shinfo(skb)->frag_list;
+		while (frag_skb) {
+			tmp = frag_skb->next;
+			frag_skb->next = NULL;
+			dev_kfree_skb_any(frag_skb);
+			frag_skb = tmp;
+		}
+		skb_shinfo(skb)->frag_list = NULL;
+	}
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
+	if (trb->hdr_added)
+		return 0;
+
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
+	ccci_h->status = cpu_to_le32(FIELD_PREP(MTK_HDR_FLD_CHN, port->info.tx_ch) |
+				     FIELD_PREP(MTK_HDR_FLD_SEQ, port->tx_seq++) |
+				     FIELD_PREP(MTK_HDR_FLD_AST, 1));
+
+	trb->hdr_added = true;
+	trb->seq_taken = true;
+
+	return 0;
+}
+
+struct mtk_ccci_header *mtk_port_strip_header(struct sk_buff *skb)
+{
+	struct mtk_ccci_header *ccci_h;
+
+	if (skb->len < sizeof(*ccci_h)) {
+		pr_err("Invalid input value\n");
+		return NULL;
+	}
+
+	ccci_h = (struct mtk_ccci_header *)skb->data;
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
+	/* The modem restarts its sequence numbering with the channel;
+	 * rx_seq is unsigned short, so -1 means "next must be 0".
+	 */
+	port->tx_seq = 0;
+	port->rx_seq = -1;
+
+	skb = __dev_alloc_skb(Q_MTU_3_5K, GFP_KERNEL);
+	if (!skb)
+		return -ENOMEM;
+
+	trb_open_priv = (struct trb_open_priv *)skb->data;
+	trb_open_priv->rx_done = mtk_port_rx_dispatch;
+
+	skb_put(skb, sizeof(struct trb_open_priv));
+	trb = (struct trb *)skb->cb;
+	mtk_port_trb_init(port, trb, TRB_CMD_ENABLE, mtk_port_open_trb_complete);
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
+		/* Pairs with the smp_store_release() of trb->status in
+		 * mtk_cldma_open(), which publishes the geometry read below.
+		 */
+		ret = smp_load_acquire(&trb->status);
+
+		/* -EBUSY means another user already owns the queue, and the
+		 * geometry it reports is that queue's - also valid here.
+		 */
+		if (!ret || ret == -EBUSY) {
+			port->tx_mtu = trb_open_priv->tx_mtu - MTK_CCCI_H_ELEN;
+			port->rx_mtu = trb_open_priv->rx_mtu - MTK_CCCI_H_ELEN;
+			port->tx_frag_size = trb_open_priv->tx_frag_size;
+			port->rx_frag_size = trb_open_priv->rx_frag_size;
+		}
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
+	skb = __dev_alloc_skb(Q_MTU_3_5K, GFP_KERNEL);
+	if (!skb)
+		return -ENOMEM;
+
+	trb = (struct trb *)skb->cb;
+	mtk_port_trb_init(port, trb, TRB_CMD_DISABLE, mtk_port_close_trb_complete);
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
+		goto err_free_port_mngr;
+	}
+
+	ctrl_blk->port_mngr = port_mngr;
+
+	return ret;
+
+err_free_port_mngr:
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
index 000000000000..6da42e81b010
--- /dev/null
+++ b/drivers/net/wwan/t9xx/mtk_port.h
@@ -0,0 +1,131 @@
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
+	unsigned short tx_seq;
+	unsigned short rx_seq;
+	unsigned int tx_mtu;
+	unsigned int rx_mtu;
+	u32 tx_frag_size;
+	u32 rx_frag_size;
+	struct sk_buff_head rx_skb_list;
+	unsigned int rx_data_len;
+	unsigned int rx_buf_size;
+	wait_queue_head_t trb_wq;
+	wait_queue_head_t rx_wq;
+	struct mtk_port_mngr *port_mngr;
+	struct mtk_internal_port i_priv;
+};
+
+struct mtk_port_mngr {
+	struct mtk_ctrl_blk *ctrl_blk;
+	struct radix_tree_root port_tbl[PORT_TBL_MAX];
+	/* protects port_tbl[] and port_cnt against concurrent mutators */
+	struct mutex port_tbl_mtx;
+	unsigned int port_cnt;
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
index 000000000000..1d6540853b04
--- /dev/null
+++ b/drivers/net/wwan/t9xx/mtk_port_io.c
@@ -0,0 +1,230 @@
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
+	skb_queue_head_init(&port->rx_skb_list);
+	port->rx_buf_size = MTK_RX_BUF_SIZE;
+	init_waitqueue_head(&port->trb_wq);
+	init_waitqueue_head(&port->rx_wq);
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
+	if (test_bit(PORT_S_ENABLE, &port->status))
+		return;
+
+	ret = mtk_port_ch_enable(port);
+	if (ret && ret != -EBUSY) {
+		/* On -ETIMEDOUT the ENABLE trb may still be queued; queue a
+		 * DISABLE behind it so the channel does not end up armed with
+		 * no software owner.
+		 */
+		mtk_port_ch_disable(port);
+		return;
+	}
+
+	set_bit(PORT_S_WR, &port->status);
+	set_bit(PORT_S_ENABLE, &port->status);
+}
+
+static void mtk_port_internal_disable(struct mtk_port *port)
+{
+	int ret;
+
+	if (!test_and_clear_bit(PORT_S_ENABLE, &port->status))
+		return;
+
+	/* PORT_S_WR is part of the blocking TX wait condition, and the waiter
+	 * loops back on timeout, so without this wake it only notices at the
+	 * next trb timeout rather than now.
+	 */
+	clear_bit(PORT_S_WR, &port->status);
+	wake_up_all(&port->trb_wq);
+
+	/* Failure must not abort teardown or keep PORT_S_ENABLE set:
+	 * usr_cnt and the queues are rebuilt together at the next
+	 * FSM_STATE_ON, and a port left with the bit set could never
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
+	struct mtk_internal_port *priv;
+	int ret = -ENXIO;
+
+	if (!test_bit(PORT_S_OPEN, &port->status))
+		goto drop_data;
+
+	priv = &port->i_priv;
+	if (!priv->recv_cb || !priv->arg)
+		goto drop_data;
+
+	ret = priv->recv_cb(priv->arg, skb);
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
+	if (test_bit(PORT_S_OPEN, &port->status))
+		return -EBUSY;
+
+	skb_queue_purge(&port->rx_skb_list);
+	set_bit(PORT_S_OPEN, &port->status);
+	clear_bit(PORT_S_FLUSH, &port->status);
+
+	return ret;
+}
+
+static void mtk_port_common_close(struct mtk_port *port)
+{
+	clear_bit(PORT_S_OPEN, &port->status);
+
+	skb_queue_purge(&port->rx_skb_list);
+	port->rx_data_len = 0;
+
+	set_bit(PORT_S_FLUSH, &port->status);
+	wake_up_all(&port->trb_wq);
+	wake_up_all(&port->rx_wq);
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
+	if (!test_bit(PORT_S_OPEN, &port->status)) {
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
+void mtk_port_internal_recv_register(void *i_port,
+				     int (*cb)(void *priv, struct sk_buff *skb),
+				     void *arg)
+{
+	struct mtk_port *port = i_port;
+	struct mtk_internal_port *priv;
+
+	priv = &port->i_priv;
+	priv->arg = arg;
+	priv->recv_cb = cb;
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
index 000000000000..6e453c56a487
--- /dev/null
+++ b/drivers/net/wwan/t9xx/mtk_port_io.h
@@ -0,0 +1,34 @@
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
+#define MTK_RX_BUF_SIZE			(1024 * 1024)
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
index b14d8ba54c60..64ce16e9cf98 100644
--- a/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c
+++ b/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c
@@ -16,6 +16,7 @@
 #include "mtk_ctrl_plane.h"
 #include "mtk_dev.h"
 #include "mtk_pci.h"
+#include "mtk_port.h"
 #include "mtk_trans_ctrl.h"
 
 #define QUEUE_CHL_MASK	0xFFFF
@@ -34,6 +35,18 @@ static const struct queue_info mtk_queue_info[] = {
 	 Q_MTU_3_5K, Q_MTU_3_5K, TX_GPD_NUM, RX_GPD_NUM, Q_FRAG_3_5K, Q_FRAG_3_5K, 0},
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
@@ -167,6 +180,7 @@ static void mtk_ctrl_trb_handler(struct trb_srv *srv, struct trans_list *trans_l
 			break;
 		}
 		trb = (struct trb *)skb->cb;
+		kref_get(&trb->kref);
 
 		switch (trb->cmd) {
 		case TRB_CMD_ENABLE:
@@ -188,8 +202,10 @@ static void mtk_ctrl_trb_handler(struct trb_srv *srv, struct trans_list *trans_l
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
@@ -230,6 +246,8 @@ static void mtk_ctrl_trb_handler(struct trb_srv *srv, struct trans_list *trans_l
 			kick = false;
 		}
 
+		kref_put(&trb->kref, mtk_port_trb_free);
+
 		loop++;
 	} while (loop < TRB_NUM_PER_ROUND);
 }
@@ -596,7 +614,7 @@ int mtk_trans_ctrl_init(struct mtk_md_dev *mdev)
 	trans->queue_info_num = ARRAY_SIZE(mtk_queue_info);
 	trans->trb_srv_num = TRB_SRV_NUM;
 
-	err = mtk_ctrl_init(mdev);
+	err = mtk_ctrl_init(mdev, &mtk_port_layer_cfg);
 	if (err)
 		return err;
 
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.h b/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.h
index 38048fac5136..3d5560be5b39 100644
--- a/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.h
+++ b/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.h
@@ -13,6 +13,7 @@
 #include <linux/xarray.h>
 
 #include "mtk_dev.h"
+#include "mtk_port.h"
 
 #define TRB_SRV_MAX_NUM			(1)
 #define HW_QUE_NUM			(8)

-- 
2.34.1

