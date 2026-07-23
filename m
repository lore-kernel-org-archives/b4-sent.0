From: Jack Wu <jackbb_wu@compal.com>
Date: Thu, 23 Jul 2026 16:34:29 +0800
Subject: [PATCH v5 4/7] net: wwan: t9xx: Add control port
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260723-t9xx_driver_v1-v5-4-b27afb99ccbb@compal.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784795676; l=46529;
 i=jackbb_wu@compal.com; s=20260526; h=from:subject:message-id;
 bh=ODbFbYflk+ZtSP1E5/sv1kAc2VmuhIwe627W6ZXwgNI=;
 b=yszso3MGgxElDj7wz7UOv5/eXNRJ8H0oW85u9zyQZJH1irSQStB/UHFNFF/KupZhfGPEQlBhA
 1Rpffhk+I1xCfvkLVMPjP8EggKJjXT3dxrwaYPpeTZRkpQq2xp1VCYV
X-Developer-Key: i=jackbb_wu@compal.com; a=ed25519;
 pk=VH1prTWixNl8OEUPPSfII3p46MzJpQN8J3+ecE1tZXg=
X-Endpoint-Received: by B4 Relay for jackbb_wu@compal.com/20260526 with auth_id=793
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The control port consists of port I/O and port manager.
Port I/O provides a common operation as defined by "struct port_ops",
and the operation is managed by the "port manager". It provides
interfaces to internal users, the implemented internal interfaces are
open, close, write and recv_register.

The port manager defines and implements port management interfaces and
structures. It is responsible for port creation, destroying, and managing
port states. It sends data from port I/O to CLDMA via TRB ( Transaction
Request Block ), and dispatches received data from CLDMA to port I/O.
The using port will be held in the "stale list" when the driver destroys
it, and after creating it again, the user can continue to use it.

Signed-off-by: Jack Wu <jackbb_wu@compal.com>
---
 drivers/net/wwan/t9xx/Makefile                 |   4 +-
 drivers/net/wwan/t9xx/mtk_ctrl_plane.c         |  19 +-
 drivers/net/wwan/t9xx/mtk_ctrl_plane.h         |  20 +-
 drivers/net/wwan/t9xx/mtk_dev.c                |  22 +
 drivers/net/wwan/t9xx/mtk_port.c               | 875 +++++++++++++++++++++++++
 drivers/net/wwan/t9xx/mtk_port.h               | 159 +++++
 drivers/net/wwan/t9xx/mtk_port_io.c            | 238 +++++++
 drivers/net/wwan/t9xx/mtk_port_io.h            |  36 +
 drivers/net/wwan/t9xx/pcie/mtk_ctrl_cfg_m9xx.c |  25 +-
 drivers/net/wwan/t9xx/pcie/mtk_pci.c           |   2 +
 drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c    |  22 +-
 drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.h    |   1 +
 12 files changed, 1412 insertions(+), 11 deletions(-)

diff --git a/drivers/net/wwan/t9xx/Makefile b/drivers/net/wwan/t9xx/Makefile
index ae9d6f2344ab..db3b1aa1928b 100644
--- a/drivers/net/wwan/t9xx/Makefile
+++ b/drivers/net/wwan/t9xx/Makefile
@@ -8,4 +8,6 @@ obj-$(CONFIG_MTK_T9XX_PCI) += pcie/
 
 mtk_t9xx-y := \
 	mtk_dev.o \
-	mtk_ctrl_plane.o
+	mtk_ctrl_plane.o \
+	mtk_port.o \
+	mtk_port_io.o
diff --git a/drivers/net/wwan/t9xx/mtk_ctrl_plane.c b/drivers/net/wwan/t9xx/mtk_ctrl_plane.c
index 4be699d1ec00..6ed47d074556 100644
--- a/drivers/net/wwan/t9xx/mtk_ctrl_plane.c
+++ b/drivers/net/wwan/t9xx/mtk_ctrl_plane.c
@@ -7,20 +7,23 @@
 #include <linux/device.h>
 
 #include "mtk_ctrl_plane.h"
+#include "mtk_port.h"
 
 /**
  * mtk_ctrl_init() - Initialize the control plane block.
  * @mdev: Pointer to the MTK modem device.
  * @ops: HIF operations for the control plane.
+ * @cfg: Control plane configuration.
  *
  * Allocates and initializes the control plane block
  * associated with @mdev.
  *
- * Return: 0 on success, -ENOMEM on allocation failure.
+ * Return: 0 on success, negative error code on failure.
  */
-int mtk_ctrl_init(struct mtk_md_dev *mdev, struct mtk_ctrl_hif_ops *ops)
+int mtk_ctrl_init(struct mtk_md_dev *mdev, struct mtk_ctrl_hif_ops *ops, struct mtk_ctrl_cfg *cfg)
 {
 	struct mtk_ctrl_blk *ctrl_blk;
+	int err;
 
 	ctrl_blk = devm_kzalloc(mdev->dev, sizeof(*ctrl_blk), GFP_KERNEL);
 	if (!ctrl_blk)
@@ -29,8 +32,17 @@ int mtk_ctrl_init(struct mtk_md_dev *mdev, struct mtk_ctrl_hif_ops *ops)
 	ctrl_blk->mdev = mdev;
 	mdev->ctrl_blk = ctrl_blk;
 	ctrl_blk->ops = ops;
+	ctrl_blk->cfg = cfg;
+
+	err = mtk_port_mngr_init(ctrl_blk, cfg->port_layer_cfg->port_cfg,
+				 cfg->port_layer_cfg->port_cnt);
+	if (err)
+		goto err_free_mem;
 
 	return 0;
+
+err_free_mem:
+	return err;
 }
 EXPORT_SYMBOL(mtk_ctrl_init);
 
@@ -42,6 +54,9 @@ EXPORT_SYMBOL(mtk_ctrl_init);
  */
 void mtk_ctrl_exit(struct mtk_md_dev *mdev)
 {
+	struct mtk_ctrl_blk *ctrl_blk = mdev->ctrl_blk;
+
+	mtk_port_mngr_exit(ctrl_blk);
 	mdev->ctrl_blk = NULL;
 }
 EXPORT_SYMBOL(mtk_ctrl_exit);
diff --git a/drivers/net/wwan/t9xx/mtk_ctrl_plane.h b/drivers/net/wwan/t9xx/mtk_ctrl_plane.h
index 88d71ac92084..d7fcccde8a1b 100644
--- a/drivers/net/wwan/t9xx/mtk_ctrl_plane.h
+++ b/drivers/net/wwan/t9xx/mtk_ctrl_plane.h
@@ -11,6 +11,17 @@
 
 #include "mtk_dev.h"
 
+#define Q_MTU_2K			(0x800)
+#define Q_MTU_3_5K			(0xE00)
+#define Q_MTU_7K			(0x1C00)
+#define Q_MTU_32K			(0x8000)
+#define Q_MTU_63K			(0xFC00)
+#define Q_FRAG_2K			(0x800)
+#define Q_FRAG_3_5K			(0xE00)
+#define Q_FRAG_7K			(0x1C00)
+#define Q_FRAG_32K			(0x8000)
+#define Q_FRAG_63K			(0xFC00)
+
 enum mtk_trb_cmd_type {
 	TRB_CMD_MIN,
 	TRB_CMD_ENABLE,
@@ -54,17 +65,22 @@ struct mtk_ctrl_hif_ops {
 	int (*send_cmd)(struct mtk_md_dev *mdev, int cmd, void *data);
 };
 
-struct mtk_ctrl_cfg;
+struct mtk_ctrl_cfg {
+	struct mtk_port_layer_cfg *port_layer_cfg;
+};
+
 struct mtk_ctrl_trans;
 
 struct mtk_ctrl_blk {
 	struct mtk_md_dev *mdev;
+	struct mtk_port_mngr *port_mngr;
 	struct mtk_ctrl_hif_ops *ops;
 	void *ctrl_hw_priv;
 	struct mtk_ctrl_cfg *cfg;
 };
 
-int mtk_ctrl_init(struct mtk_md_dev *mdev, struct mtk_ctrl_hif_ops *ops);
+int mtk_ctrl_init(struct mtk_md_dev *mdev, struct mtk_ctrl_hif_ops *ops,
+		  struct mtk_ctrl_cfg *cfg);
 void mtk_ctrl_exit(struct mtk_md_dev *mdev);
 
 #endif /* __MTK_CTRL_PLANE_H__ */
diff --git a/drivers/net/wwan/t9xx/mtk_dev.c b/drivers/net/wwan/t9xx/mtk_dev.c
index 50f77d5a210c..7c449030a35f 100644
--- a/drivers/net/wwan/t9xx/mtk_dev.c
+++ b/drivers/net/wwan/t9xx/mtk_dev.c
@@ -6,6 +6,28 @@
 #include <linux/module.h>
 
 #include "mtk_dev.h"
+#include "mtk_port.h"
+#include "mtk_port_io.h"
+
+static int __init mtk_common_drv_init(void)
+{
+	int ret;
+
+	ret = mtk_port_io_init();
+	if (ret)
+		goto err_init_devid;
+
+err_init_devid:
+	return ret;
+}
+module_init(mtk_common_drv_init);
+
+static void __exit mtk_common_drv_exit(void)
+{
+	mtk_port_io_exit();
+	mtk_port_stale_list_grp_cleanup();
+}
+module_exit(mtk_common_drv_exit);
 
 MODULE_DESCRIPTION("MediaTek T9xx PCIe WWAN driver");
 MODULE_LICENSE("GPL");
diff --git a/drivers/net/wwan/t9xx/mtk_port.c b/drivers/net/wwan/t9xx/mtk_port.c
new file mode 100644
index 000000000000..bce3671a63fc
--- /dev/null
+++ b/drivers/net/wwan/t9xx/mtk_port.c
@@ -0,0 +1,875 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (c) 2022, MediaTek Inc.
+ */
+
+#include <linux/bitfield.h>
+#include <linux/device.h>
+#include <linux/err.h>
+#include <linux/kernel.h>
+#include <linux/list.h>
+#include <linux/netdevice.h>
+#include <linux/slab.h>
+#include <linux/wait.h>
+
+#include "mtk_port.h"
+#include "mtk_port_io.h"
+
+#define MTK_DFLT_TRB_TIMEOUT		(5 * HZ)
+#define MTK_DFLT_TRB_STATUS		(0x1)
+#define MTK_TRB_HEADER_ADDED		(0xADDED)
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
+/* global group for stale ports */
+static LIST_HEAD(stale_list_grp);
+/* mutex lock for stale_list_group */
+DEFINE_MUTEX(port_mngr_grp_mtx);
+
+static DEFINE_IDA(ccci_dev_ids);
+
+/* This function working always under mutex lock port_mngr_grp_mtx */
+void mtk_port_release(struct kref *port_kref)
+{
+	struct mtk_stale_list *s_list;
+	struct mtk_port *port;
+
+	port = container_of(port_kref, struct mtk_port, kref);
+	if (!test_bit(PORT_S_ON_STALE_LIST, &port->status))
+		goto port_exit;
+
+	list_del(&port->stale_entry);
+	list_for_each_entry(s_list, &stale_list_grp, entry) {
+		if (!strncmp(s_list->dev_str, port->dev_str, MTK_DEV_STR_LEN) &&
+		    list_empty(&s_list->ports) && s_list->dev_id >= 0) {
+			ida_free(&ccci_dev_ids, s_list->dev_id);
+			s_list->dev_id = -1;
+			break;
+		}
+	}
+port_exit:
+	ports_ops[port->info.type]->exit(port);
+	kfree(port);
+}
+
+static int mtk_port_tbl_add(struct mtk_port_mngr *port_mngr, struct mtk_port *port)
+{
+	int ret;
+
+	ret = radix_tree_insert(&port_mngr->port_tbl[MTK_PORT_TBL_TYPE(port->info.rx_ch)],
+				port->info.rx_ch & 0xFFF, port);
+	if (ret)
+		dev_err(port_mngr->ctrl_blk->mdev->dev,
+			"port(%s) add to port_tbl failed, return %d\n",
+			port->info.name, ret);
+	else
+		port_mngr->port_cnt++;
+
+	return ret;
+}
+
+static void mtk_port_tbl_del(struct mtk_port_mngr *port_mngr, struct mtk_port *port)
+{
+	radix_tree_delete(&port_mngr->port_tbl[MTK_PORT_TBL_TYPE(port->info.rx_ch)],
+			  port->info.rx_ch & 0xFFF);
+	port_mngr->port_cnt--;
+}
+
+static struct mtk_port *mtk_port_restore_from_stale_list(struct mtk_port_mngr *port_mngr,
+							 struct mtk_stale_list *s_list)
+{
+	struct mtk_port *port, *next_port;
+	int ret;
+
+	mutex_lock(&port_mngr_grp_mtx);
+	list_for_each_entry_safe(port, next_port, &s_list->ports, stale_entry) {
+		kref_get(&port->kref);
+		list_del(&port->stale_entry);
+		ret = mtk_port_tbl_add(port_mngr, port);
+		if (ret) {
+			list_add_tail(&port->stale_entry, &s_list->ports);
+			kref_put(&port->kref, mtk_port_release);
+			mutex_unlock(&port_mngr_grp_mtx);
+			dev_err(port_mngr->ctrl_blk->mdev->dev,
+				"Failed when adding (%s) to port mngr\n",
+				port->info.name);
+			return ERR_PTR(ret);
+		}
+
+		port->port_mngr = port_mngr;
+		clear_bit(PORT_S_ON_STALE_LIST, &port->status);
+		ports_ops[port->info.type]->reset(port);
+	}
+	mutex_unlock(&port_mngr_grp_mtx);
+
+	return NULL;
+}
+
+static struct mtk_port *mtk_port_alloc_and_add(struct mtk_port_mngr *port_mngr,
+					       struct mtk_port_cfg *dflt_info)
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
+	ret = ports_ops[port->info.type]->init(port);
+	if (ret < 0) {
+		mtk_port_tbl_del(port_mngr, port);
+		goto err_free_port;
+	}
+
+	memcpy(port->dev_str, port_mngr->ctrl_blk->mdev->dev_str, MTK_DEV_STR_LEN);
+	return port;
+
+err_free_port:
+	kfree(port);
+err_alloc_port:
+	return ERR_PTR(ret);
+}
+
+static void mtk_port_free_or_backup(struct mtk_port_mngr *port_mngr,
+				    struct mtk_port *port, struct mtk_stale_list *s_list)
+{
+	mutex_lock(&port_mngr_grp_mtx);
+	mtk_port_tbl_del(port_mngr, port);
+	if (port->info.type != PORT_TYPE_INTERNAL) {
+		if (test_bit(PORT_S_OPEN, &port->status)) {
+			list_add_tail(&port->stale_entry, &s_list->ports);
+			set_bit(PORT_S_ON_STALE_LIST, &port->status);
+			memcpy(port->dev_str, port_mngr->ctrl_blk->mdev->dev_str,
+			       MTK_DEV_STR_LEN);
+			port->port_mngr = NULL;
+		}
+		kref_put(&port->kref, mtk_port_release);
+	} else {
+		kref_put(&port->kref, mtk_port_release);
+	}
+	mutex_unlock(&port_mngr_grp_mtx);
+}
+
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
+struct mtk_port *mtk_port_search_by_name(struct mtk_port_mngr *port_mngr, char *name)
+{
+	int tbl_type = PORT_TBL_SAP;
+	struct radix_tree_iter iter;
+	struct mtk_port *port;
+	void __rcu **slot;
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
+static int mtk_port_tbl_create(struct mtk_port_mngr *port_mngr, struct mtk_port_cfg *cfg,
+			       const int port_cnt, struct mtk_stale_list *s_list)
+{
+	struct mtk_port_cfg *dflt_port;
+	struct mtk_port *port;
+	int i;
+
+	INIT_RADIX_TREE(&port_mngr->port_tbl[PORT_TBL_SAP], GFP_KERNEL);
+	INIT_RADIX_TREE(&port_mngr->port_tbl[PORT_TBL_MD], GFP_KERNEL);
+
+	mtk_port_restore_from_stale_list(port_mngr, s_list);
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
+static void mtk_port_tbl_destroy(struct mtk_port_mngr *port_mngr, struct mtk_stale_list *s_list)
+{
+	struct radix_tree_iter iter;
+	struct mtk_port *port;
+	void __rcu **slot;
+	int tbl_type;
+
+	tbl_type = PORT_TBL_SAP;
+	do {
+		radix_tree_for_each_slot(slot, &port_mngr->port_tbl[tbl_type], &iter, 0) {
+			port = radix_tree_deref_slot(slot);
+			if (!port)
+				continue;
+			ports_ops[port->info.type]->disable(port);
+		}
+
+		while (radix_tree_gang_lookup(&port_mngr->port_tbl[tbl_type],
+					      (void **)&port, 0, 1))
+			mtk_port_free_or_backup(port_mngr, port, s_list);
+	} while (++tbl_type < PORT_TBL_MAX);
+}
+
+static struct mtk_stale_list *mtk_port_stale_list_create(struct mtk_ctrl_blk *ctrl_blk)
+{
+	struct mtk_stale_list *s_list;
+
+	s_list = kzalloc_obj(*s_list, GFP_KERNEL);
+	if (!s_list)
+		return NULL;
+
+	memcpy(s_list->dev_str, ctrl_blk->mdev->dev_str, MTK_DEV_STR_LEN);
+	s_list->dev_id = -1;
+	INIT_LIST_HEAD(&s_list->ports);
+	rwlock_init(&s_list->port_mngr_lock);
+
+	mutex_lock(&port_mngr_grp_mtx);
+	list_add_tail(&s_list->entry, &stale_list_grp);
+	mutex_unlock(&port_mngr_grp_mtx);
+
+	return s_list;
+}
+
+static void mtk_port_stale_list_destroy(struct mtk_stale_list *s_list)
+{
+	mutex_lock(&port_mngr_grp_mtx);
+	list_del(&s_list->entry);
+	mutex_unlock(&port_mngr_grp_mtx);
+	kfree(s_list);
+}
+
+static struct mtk_stale_list *mtk_port_stale_list_search(const char *dev_str)
+{
+	struct mtk_stale_list *tmp, *s_list = NULL;
+
+	mutex_lock(&port_mngr_grp_mtx);
+	list_for_each_entry(tmp, &stale_list_grp, entry) {
+		if (!strncmp(tmp->dev_str, dev_str, MTK_DEV_STR_LEN)) {
+			s_list = tmp;
+			break;
+		}
+	}
+	mutex_unlock(&port_mngr_grp_mtx);
+
+	return s_list;
+}
+
+void mtk_port_stale_list_grp_cleanup(void)
+{
+	struct mtk_stale_list *s_list, *next_s_list;
+	struct mtk_port *port, *next_port;
+
+	mutex_lock(&port_mngr_grp_mtx);
+	list_for_each_entry_safe(s_list, next_s_list, &stale_list_grp, entry) {
+		list_del(&s_list->entry);
+
+		list_for_each_entry_safe(port, next_port, &s_list->ports, stale_entry) {
+			clear_bit(PORT_S_ON_STALE_LIST, &port->status);
+			kref_put(&port->kref, mtk_port_release);
+		}
+
+		if (s_list->dev_id >= 0)
+			ida_free(&ccci_dev_ids, s_list->dev_id);
+		kfree(s_list);
+	}
+	mutex_unlock(&port_mngr_grp_mtx);
+}
+
+static struct mtk_stale_list *mtk_port_stale_list_init(struct mtk_ctrl_blk *ctrl_blk, int *dev_id)
+{
+	struct mtk_stale_list *s_list;
+
+	s_list = mtk_port_stale_list_search(ctrl_blk->mdev->dev_str);
+	if (!s_list) {
+		s_list = mtk_port_stale_list_create(ctrl_blk);
+		if (unlikely(!s_list))
+			return NULL;
+	}
+
+	mutex_lock(&port_mngr_grp_mtx);
+	if (s_list->dev_id < 0) {
+		*dev_id = ida_alloc_range(&ccci_dev_ids, 0, MTK_DFLT_MAX_DEV_CNT - 1, GFP_KERNEL);
+	} else {
+		*dev_id = s_list->dev_id;
+		s_list->dev_id = -1;
+	}
+	mutex_unlock(&port_mngr_grp_mtx);
+
+	return s_list;
+}
+
+static void mtk_port_stale_list_exit(struct mtk_ctrl_blk *ctrl_blk,
+				     struct mtk_stale_list *s_list, int dev_id)
+{
+	if (!s_list)
+		return;
+	mutex_lock(&port_mngr_grp_mtx);
+	if (list_empty(&s_list->ports)) {
+		ida_free(&ccci_dev_ids, dev_id);
+		mutex_unlock(&port_mngr_grp_mtx);
+		mtk_port_stale_list_destroy(s_list);
+	} else {
+		s_list->dev_id = dev_id;
+		mutex_unlock(&port_mngr_grp_mtx);
+	}
+}
+
+void mtk_port_trb_init(struct mtk_port *port, struct trb *trb, enum mtk_trb_cmd_type cmd,
+		       int (*trb_complete)(struct sk_buff *skb))
+{
+	kref_init(&trb->kref);
+	trb->channel_id = port->info.rx_ch;
+	trb->status = MTK_DFLT_TRB_STATUS;
+	trb->priv = port;
+	trb->cmd = cmd;
+	trb->trb_complete = trb_complete;
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
+EXPORT_SYMBOL(mtk_port_trb_free);
+
+static int mtk_port_open_trb_complete(struct sk_buff *skb)
+{
+	struct trb_open_priv *trb_open_priv = (struct trb_open_priv *)skb->data;
+	struct trb *trb = (struct trb *)skb->cb;
+	struct mtk_port *port = trb->priv;
+
+	if (!trb->status) {
+		port->tx_mtu = trb_open_priv->tx_mtu;
+		port->rx_mtu = trb_open_priv->rx_mtu;
+		port->tx_frag_size = trb_open_priv->tx_frag_size;
+		port->rx_frag_size = trb_open_priv->rx_frag_size;
+		port->tx_mtu -= MTK_CCCI_H_ELEN;
+		port->rx_mtu -= MTK_CCCI_H_ELEN;
+	}
+
+	wake_up_interruptible_all(&port->trb_wq);
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
+	wake_up_interruptible_all(&port->trb_wq);
+	wake_up_interruptible_all(&port->rx_wq);
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
+	wake_up_interruptible_all(&port->trb_wq);
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
+int mtk_port_send_data(struct mtk_port *port, void *data)
+{
+	struct mtk_port_mngr *port_mngr;
+	struct sk_buff *skb = data;
+	bool force_send;
+	struct trb *trb;
+	int ret, len;
+
+	port_mngr = port->port_mngr;
+
+	force_send = !!(port->info.flags & (PORT_F_BLOCKING | PORT_F_FORCE_SEND));
+	trb = (struct trb *)skb->cb;
+	mtk_port_trb_init(port, trb, TRB_CMD_TX, mtk_port_tx_complete);
+	len = skb->len;
+	kref_get(&trb->kref); /* kref count 1->2 */
+
+	/* add ccci header */
+	mtk_port_add_header(skb);
+	ret = mtk_port_status_check(port);
+	if (!ret)
+		ret = port_mngr->ctrl_blk->ops->submit_skb(port_mngr->ctrl_blk->mdev,
+							   skb, force_send);
+
+	if (ret < 0) {
+		kref_put(&trb->kref, mtk_port_trb_free); /* kref count 2->1 */
+		kref_put(&trb->kref, mtk_port_trb_free); /* kref count 1->0 */
+		port->tx_seq--;
+		goto out;
+	}
+
+	if (!(port->info.flags & PORT_F_BLOCKING)) {
+		kref_put(&trb->kref, mtk_port_trb_free);
+		ret = len;
+		goto out;
+	}
+start_wait:
+
+	/* wait trb done, and no timeout in tx blocking mode */
+	ret = wait_event_interruptible_timeout(port->trb_wq,
+					       trb->status <= 0 ||
+					       test_bit(PORT_S_FLUSH, &port->status) ||
+					       !test_bit(PORT_S_WR, &port->status),
+					       MTK_DFLT_TRB_TIMEOUT);
+	if (!ret) {
+		goto start_wait;
+	} else if (ret == -ERESTARTSYS) {
+		ret = -EINTR;
+	} else if (ret > 0) {
+		if (test_bit(PORT_S_FLUSH, &port->status))
+			ret = len;
+		else
+			ret = (!trb->status) ? len : trb->status;
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
+	ret = ports_ops[port->info.type]->recv(port, skb);
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
+		ret = ports_ops[port->info.type]->recv(port, frag_skb);
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
+		ret = ports_ops[port->info.type]->recv(port, skb);
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
+
+	trb = (struct trb *)skb->cb;
+	if (trb->status == MTK_TRB_HEADER_ADDED)
+		return 0;
+
+	port = trb->priv;
+	if (!port)
+		return -EINVAL;
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
+	trb->status = MTK_TRB_HEADER_ADDED;
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
+	ret = port_mngr->ctrl_blk->ops->submit_skb(port_mngr->ctrl_blk->mdev, skb, true);
+	if (ret) {
+		dev_err(port_mngr->ctrl_blk->mdev->dev,
+			"Failed to submit trb for port(%s), ret=%d\n",
+			port->info.name, ret);
+		kref_put(&trb->kref, mtk_port_trb_free);
+		kref_put(&trb->kref, mtk_port_trb_free);
+		return ret;
+	}
+
+	ret = wait_event_timeout(port->trb_wq, trb->status <= 0,
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
+	ret = port_mngr->ctrl_blk->ops->submit_skb(port_mngr->ctrl_blk->mdev, skb, true);
+	if (ret) {
+		dev_warn(port_mngr->ctrl_blk->mdev->dev,
+			 "Failed to submit trb for port(%s), ret=%d\n",
+			 port->info.name, ret);
+		kref_put(&trb->kref, mtk_port_trb_free);
+		kref_put(&trb->kref, mtk_port_trb_free);
+		return ret;
+	}
+
+	ret = wait_event_timeout(port->trb_wq, trb->status <= 0,
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
+int mtk_port_mngr_init(struct mtk_ctrl_blk *ctrl_blk, struct mtk_port_cfg *port_cfg, int port_cnt)
+{
+	struct mtk_port_mngr *port_mngr;
+	struct mtk_stale_list *s_list;
+	int ret = -ENOMEM;
+	int dev_id;
+
+	s_list = mtk_port_stale_list_init(ctrl_blk, &dev_id);
+	if (!s_list) {
+		dev_err((ctrl_blk->mdev)->dev, "Failed to init mtk_stale_list\n");
+		goto err_out;
+	}
+
+	port_mngr = devm_kzalloc(ctrl_blk->mdev->dev, sizeof(*port_mngr), GFP_KERNEL);
+	if (unlikely(!port_mngr)) {
+		dev_err((ctrl_blk->mdev)->dev, "Failed to alloc memory for port_mngr\n");
+		goto err_exit_stale_list;
+	}
+
+	port_mngr->ctrl_blk = ctrl_blk;
+	port_mngr->dev_id = dev_id;
+
+	ret = mtk_port_tbl_create(port_mngr, port_cfg, port_cnt, s_list);
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
+	mtk_port_tbl_destroy(port_mngr, s_list);
+err_exit_stale_list:
+	mtk_port_stale_list_exit(ctrl_blk, s_list, dev_id);
+err_out:
+	return ret;
+}
+
+void mtk_port_mngr_exit(struct mtk_ctrl_blk *ctrl_blk)
+{
+	struct mtk_port_mngr *port_mngr = ctrl_blk->port_mngr;
+	struct mtk_stale_list *s_list;
+	int dev_id;
+
+	s_list = mtk_port_stale_list_search(port_mngr->ctrl_blk->mdev->dev_str);
+	dev_id = port_mngr->dev_id;
+
+	mtk_port_tbl_destroy(port_mngr, s_list);
+
+	ctrl_blk->port_mngr = NULL;
+	mtk_port_stale_list_exit(ctrl_blk, s_list, dev_id);
+}
diff --git a/drivers/net/wwan/t9xx/mtk_port.h b/drivers/net/wwan/t9xx/mtk_port.h
new file mode 100644
index 000000000000..0a42313e348f
--- /dev/null
+++ b/drivers/net/wwan/t9xx/mtk_port.h
@@ -0,0 +1,159 @@
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
+#define MTK_PEER_ID_SAP				(0x1)
+#define MTK_PEER_ID_MD				(0x2)
+#define MTK_CH_ID_MASK				(0x0FFF)
+#define MTK_CH_ID(ch)				((ch) & MTK_CH_ID_MASK)
+#define MTK_DFLT_MAX_DEV_CNT			(10)
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
+	PORT_S_DFLT = 0,
+	PORT_S_ENABLE,
+	PORT_S_OPEN,
+	PORT_S_RD,
+	PORT_S_WR,
+	PORT_S_FLUSH,
+	PORT_S_ON_STALE_LIST,
+	PORT_S_STOP,
+};
+
+enum mtk_ccci_ch {
+	/* to sAP */
+	CCCI_SAP_CONTROL_RX			= 0x1000,
+	CCCI_SAP_CONTROL_TX			= 0x1001,
+	/* to MD */
+	CCCI_CONTROL_RX				= 0x2000,
+	CCCI_CONTROL_TX				= 0x2001,
+};
+
+enum mtk_port_flag {
+	PORT_F_DFLT = 0,
+	PORT_F_BLOCKING = BIT(1),
+	PORT_F_ALLOW_DROP = BIT(2),
+	PORT_F_FORCE_SEND = BIT(6),
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
+	bool enable;
+	unsigned long status;
+	unsigned int minor;
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
+	struct list_head stale_entry;
+	char dev_str[MTK_DEV_STR_LEN];
+	struct mtk_port_mngr *port_mngr;
+	struct mtk_internal_port i_priv;
+};
+
+struct mtk_port_mngr {
+	struct mtk_ctrl_blk *ctrl_blk;
+	struct radix_tree_root port_tbl[PORT_TBL_MAX];
+	unsigned int port_cnt;
+	int dev_id;
+};
+
+struct mtk_stale_list {
+	struct list_head entry;
+	struct list_head ports;
+	char dev_str[MTK_DEV_STR_LEN];
+	int dev_id;
+	rwlock_t port_mngr_lock;
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
+	struct mtk_port_cfg *port_cfg;
+	int port_cnt;
+};
+
+extern const struct port_ops *ports_ops[PORT_TYPE_MAX];
+
+void mtk_port_release(struct kref *port_kref);
+void mtk_port_trb_free(struct kref *trb_kref);
+struct mtk_port *mtk_port_search_by_name(struct mtk_port_mngr *port_mngr, char *name);
+void mtk_port_stale_list_grp_cleanup(void);
+int mtk_port_add_header(struct sk_buff *skb);
+struct mtk_ccci_header *mtk_port_strip_header(struct sk_buff *skb);
+int mtk_port_status_check(struct mtk_port *port);
+int mtk_port_send_data(struct mtk_port *port, void *data);
+int mtk_port_status_update(struct mtk_md_dev *mdev, void *data, u32 data_len);
+int mtk_port_ch_enable(struct mtk_port *port);
+int mtk_port_ch_disable(struct mtk_port *port);
+int mtk_port_mngr_init(struct mtk_ctrl_blk *ctrl_blk, struct mtk_port_cfg *port_cfg, int port_cnt);
+void mtk_port_mngr_exit(struct mtk_ctrl_blk *ctrl_blk);
+void mtk_port_trb_init(struct mtk_port *port, struct trb *trb, enum mtk_trb_cmd_type cmd,
+		       int (*trb_complete)(struct sk_buff *skb));
+#endif /* __MTK_PORT_H__ */
diff --git a/drivers/net/wwan/t9xx/mtk_port_io.c b/drivers/net/wwan/t9xx/mtk_port_io.c
new file mode 100644
index 000000000000..5dc0e1191332
--- /dev/null
+++ b/drivers/net/wwan/t9xx/mtk_port_io.c
@@ -0,0 +1,238 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (c) 2022, MediaTek Inc.
+ */
+#include <linux/netdevice.h>
+
+#include "mtk_port_io.h"
+
+static int mtk_port_get_locked(struct mtk_port *port)
+{
+	int ret = 0;
+
+	mutex_lock(&port_mngr_grp_mtx);
+	if (!port) {
+		mutex_unlock(&port_mngr_grp_mtx);
+		pr_err("Port does not exist\n");
+		return -ENODEV;
+	}
+	kref_get(&port->kref);
+	mutex_unlock(&port_mngr_grp_mtx);
+
+	return ret;
+}
+
+static void mtk_port_put_locked(struct mtk_port *port)
+{
+	mutex_lock(&port_mngr_grp_mtx);
+	kref_put(&port->kref, mtk_port_release);
+	mutex_unlock(&port_mngr_grp_mtx);
+}
+
+static void mtk_port_struct_init(struct mtk_port *port)
+{
+	port->tx_seq = 0;
+	port->rx_seq = -1;
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
+		ports_ops[port->info.type]->disable(port);
+}
+
+static void mtk_port_reset(struct mtk_port *port)
+{
+	port->tx_seq = 0;
+	port->rx_seq = -1;
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
+	if (ret && ret != -EBUSY)
+		return;
+
+	set_bit(PORT_S_WR, &port->status);
+	set_bit(PORT_S_ENABLE, &port->status);
+}
+
+static void mtk_port_internal_disable(struct mtk_port *port)
+{
+	if (!test_and_clear_bit(PORT_S_ENABLE, &port->status))
+		return;
+
+	clear_bit(PORT_S_WR, &port->status);
+	mtk_port_ch_disable(port);
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
+	wake_up_interruptible_all(&port->trb_wq);
+	wake_up_interruptible_all(&port->rx_wq);
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
+	port = mtk_port_search_by_name(port_mngr, name);
+	if (port && port->info.type != PORT_TYPE_INTERNAL) {
+		port = NULL;
+		goto out;
+	}
+
+	ret = mtk_port_get_locked(port);
+	if (ret)
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
+
+	if (!port || !skb) {
+		if (skb)
+			dev_kfree_skb_any(skb);
+		pr_err_ratelimited("Internal write: invalid input\n");
+		return -EINVAL;
+	}
+	return mtk_port_send_data(port, skb);
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
+int mtk_port_io_init(void)
+{
+	return 0;
+}
+
+void mtk_port_io_exit(void)
+{
+}
+
+static const struct port_ops port_internal_ops = {
+	.init = mtk_port_internal_init,
+	.exit = mtk_port_internal_exit,
+	.reset = mtk_port_reset,
+	.enable = mtk_port_internal_enable,
+	.disable = mtk_port_internal_disable,
+	.recv = mtk_port_internal_recv,
+};
+
+const struct port_ops *ports_ops[PORT_TYPE_MAX] = {
+	&port_internal_ops,
+};
diff --git a/drivers/net/wwan/t9xx/mtk_port_io.h b/drivers/net/wwan/t9xx/mtk_port_io.h
new file mode 100644
index 000000000000..0c10e893b7e0
--- /dev/null
+++ b/drivers/net/wwan/t9xx/mtk_port_io.h
@@ -0,0 +1,36 @@
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
+extern struct mutex port_mngr_grp_mtx;
+
+struct port_ops {
+	int (*init)(struct mtk_port *port);
+	void (*exit)(struct mtk_port *port);
+	void (*reset)(struct mtk_port *port);
+	void (*enable)(struct mtk_port *port);
+	void (*disable)(struct mtk_port *port);
+	int (*recv)(struct mtk_port *port, struct sk_buff *skb);
+};
+
+void *mtk_port_internal_open(struct mtk_md_dev *mdev, char *name, int flag);
+int mtk_port_internal_close(void *i_port);
+int mtk_port_internal_write(void *i_port, struct sk_buff *skb);
+void mtk_port_internal_recv_register(void *i_port,
+				     int (*cb)(void *priv, struct sk_buff *skb),
+				     void *arg);
+
+int mtk_port_io_init(void);
+void mtk_port_io_exit(void);
+
+#endif /* __MTK_PORT_IO_H__ */
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_ctrl_cfg_m9xx.c b/drivers/net/wwan/t9xx/pcie/mtk_ctrl_cfg_m9xx.c
index c1bb787ee981..8611561dd67c 100644
--- a/drivers/net/wwan/t9xx/pcie/mtk_ctrl_cfg_m9xx.c
+++ b/drivers/net/wwan/t9xx/pcie/mtk_ctrl_cfg_m9xx.c
@@ -4,6 +4,7 @@
  */
 
 #include "mtk_cldma.h"
+#include "mtk_port.h"
 #include "mtk_trans_ctrl.h"
 
 #define TRB_SRV_NUM	(1)
@@ -13,12 +14,34 @@ static const int mtk_srv_cfg_m9xx[NR_CLDMA][HW_QUE_NUM] = {
 	{0},
 };
 
+/* the number of RX GPDs should be at last two */
 static const struct queue_info mtk_queue_info_m9xx[] = {
+	{CCCI_CONTROL_TX, CCCI_CONTROL_RX, CLDMA1, TXQ(0), RXQ(0),
+	 Q_MTU_3_5K, Q_MTU_3_5K, TX_GPD_NUM, RX_GPD_NUM, Q_FRAG_3_5K, Q_FRAG_3_5K, 0},
+	{CCCI_SAP_CONTROL_TX, CCCI_SAP_CONTROL_RX, CLDMA0, TXQ(0), RXQ(0),
+	 Q_MTU_3_5K, Q_MTU_3_5K, TX_GPD_NUM, RX_GPD_NUM, Q_FRAG_3_5K, Q_FRAG_3_5K, 0},
+};
+
+static const struct mtk_port_cfg port_cfg_m9xx[] = {
+	{CCCI_CONTROL_TX, CCCI_CONTROL_RX, PORT_TYPE_INTERNAL, "MDCTRL",
+		PORT_F_ALLOW_DROP},
+	{CCCI_SAP_CONTROL_TX, CCCI_SAP_CONTROL_RX, PORT_TYPE_INTERNAL, "SAPCTRL",
+		PORT_F_ALLOW_DROP},
+};
+
+static struct mtk_port_layer_cfg port_layer_cfg_m9xx = {
+	.port_cfg = (struct mtk_port_cfg *)port_cfg_m9xx,
+	.port_cnt = ARRAY_SIZE(port_cfg_m9xx),
+};
+
+static struct mtk_ctrl_cfg mtk_ctrl_cfg_m9xx = {
+	.port_layer_cfg = &port_layer_cfg_m9xx,
 };
 
 struct mtk_ctrl_info mtk_ctrl_info_m9xx = {
+	.ctrl_cfg = &mtk_ctrl_cfg_m9xx,
+	.srv_cfg = (int **)mtk_srv_cfg_m9xx,
 	.queue_info = (struct queue_info *)mtk_queue_info_m9xx,
 	.queue_info_num = ARRAY_SIZE(mtk_queue_info_m9xx),
-	.srv_cfg = (int **)mtk_srv_cfg_m9xx,
 	.trb_srv_num = TRB_SRV_NUM,
 };
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_pci.c b/drivers/net/wwan/t9xx/pcie/mtk_pci.c
index da2a6926b801..dbc17da590bc 100644
--- a/drivers/net/wwan/t9xx/pcie/mtk_pci.c
+++ b/drivers/net/wwan/t9xx/pcie/mtk_pci.c
@@ -17,6 +17,8 @@
 #include "mtk_trans_ctrl.h"
 #include "mtk_pci.h"
 #include "mtk_pci_reg.h"
+#include "mtk_port.h"
+#include "mtk_port_io.h"
 
 #define MTK_PCI_BAR_NUM		6
 #define MTK_PCI_TRANSPARENT_ATR_SIZE	(0x3F)
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c b/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c
index 55297cfcdbc6..6a0a415a556e 100644
--- a/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c
+++ b/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c
@@ -16,12 +16,13 @@
 #include "mtk_ctrl_plane.h"
 #include "mtk_dev.h"
 #include "mtk_pci.h"
+#include "mtk_port.h"
 #include "mtk_trans_ctrl.h"
 
 #define MTK_DFLT_PORT_NAME_LEN			(20)
 
 static struct mtk_ctrl_info_desc mtk_ctrl_info_tbl[] = {
-	{2304, &ctrl_info_name(m9xx)},
+	{0x01CA, &ctrl_info_name(m9xx)},
 	{0, NULL},
 };
 
@@ -131,6 +132,7 @@ static void mtk_ctrl_trb_handler(struct trb_srv *srv, struct trans_list *trans_l
 		if (!skb)
 			break;
 		trb = (struct trb *)skb->cb;
+		kref_get(&trb->kref);
 
 		switch (trb->cmd) {
 		case TRB_CMD_ENABLE:
@@ -150,8 +152,10 @@ static void mtk_ctrl_trb_handler(struct trb_srv *srv, struct trans_list *trans_l
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
@@ -182,6 +186,8 @@ static void mtk_ctrl_trb_handler(struct trb_srv *srv, struct trans_list *trans_l
 			kick = false;
 		}
 
+		kref_put(&trb->kref, mtk_port_trb_free);
+
 		loop++;
 	} while (loop < TRB_NUM_PER_ROUND);
 }
@@ -492,6 +498,7 @@ static void mtk_trans_get_ctrl_info(struct mtk_ctrl_cfg *cfg,
 			continue;
 
 		ctrl_info = ctrl_info_desc->ctrl_info;
+		cfg->port_layer_cfg = ctrl_info->ctrl_cfg->port_layer_cfg;
 		memcpy(trans->srv_cfg, ctrl_info->srv_cfg,
 		       sizeof(int) * NR_CLDMA * HW_QUE_NUM);
 		trans->queue_info = ctrl_info->queue_info;
@@ -504,6 +511,7 @@ int mtk_trans_ctrl_init(struct mtk_md_dev *mdev)
 {
 	struct mtk_ctrl_trans *trans;
 	struct mtk_ctrl_blk *ctrl_blk;
+	struct mtk_ctrl_cfg *cfg;
 	int err;
 
 	trans = devm_kzalloc(mdev->dev, sizeof(*trans), GFP_KERNEL);
@@ -512,15 +520,19 @@ int mtk_trans_ctrl_init(struct mtk_md_dev *mdev)
 	trans->mdev = mdev;
 	trans->queues_cnt = 0;
 
-	mtk_trans_get_ctrl_info(NULL, trans, mdev->hw_ver);
-	if (!trans->queue_info ||
+	cfg = devm_kzalloc(mdev->dev, sizeof(*cfg), GFP_KERNEL);
+	if (!cfg)
+		return -ENOMEM;
+
+	mtk_trans_get_ctrl_info(cfg, trans, mdev->hw_ver);
+	if (!cfg->port_layer_cfg || !trans->queue_info ||
 	    trans->trb_srv_num <= 0 || trans->trb_srv_num > TRB_SRV_MAX_NUM ||
 	    trans->queue_info_num <= 0) {
 		dev_err(mdev->dev, "Failed to get ctrl info!\n");
 		goto err_free_cfg;
 	}
 
-	err = mtk_ctrl_init(mdev, &pcie_ctrl_ops);
+	err = mtk_ctrl_init(mdev, &pcie_ctrl_ops, cfg);
 	if (err)
 		goto err_free_cfg;
 
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.h b/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.h
index 0d25d1f51671..a3ff56ddf86f 100644
--- a/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.h
+++ b/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.h
@@ -12,6 +12,7 @@
 #include <linux/types.h>
 
 #include "mtk_dev.h"
+#include "mtk_port.h"
 
 #define TRB_SRV_MAX_NUM			(1)
 #define HW_QUE_NUM			(8)

-- 
2.34.1

