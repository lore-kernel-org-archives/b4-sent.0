From: Jack Wu <jackbb_wu@compal.com>
Date: Thu, 05 Nov 2026 15:56:31 +0800
Subject: [PATCH v11 5/6] net: wwan: t9xx: Add FSM thread
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-t9xx_driver_v1-v11-5-2084aa512864@compal.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793865391; l=79820;
 i=jackbb_wu@compal.com; s=20260526; h=from:subject:message-id;
 bh=tTQgFFP79UaOHT9Sg2Db02sAFaSraf1oKgzgaSZRPqY=;
 b=skj0VrpcfuQSU59QfygoYlZ6O5n91mKAuIKwffVcCwu7YqXBGRnVIwYwQsl9vYAdgBLGfXn8u
 HyPb3l1iwmvAhQAAW6IPOYHJmg6YC+8tkdfsOz7k8Jb0nr3BsZ2gW0G
X-Developer-Key: i=jackbb_wu@compal.com; a=ed25519;
 pk=VH1prTWixNl8OEUPPSfII3p46MzJpQN8J3+ecE1tZXg=
X-Endpoint-Received: by B4 Relay for jackbb_wu@compal.com/20260526 with auth_id=793
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The FSM (Finite-state Machine) thread is responsible for
synchronizing the actions of different modules. The
asynchronous events from the device or the OS will trigger
a state transition.

The FSM thread will append it to the event queue when an
event arrives. It handles the events sequentially. After
processing the event, the FSM thread notifies other modules
of the state transition.

Five FSM states are defined. They can transition from one
state to another, and self-transition in some states.

Also wire the HS1/HS2/HS3 runtime feature handshake into
the FSM: the host opens a control port on device readiness,
sends HS1 with the supported feature set, parses the HS2
reply, and confirms with HS3. MD and SAP each run this
sequence independently; the FSM advances to READY only
after both complete.

CLDMA hardware bring-up and teardown are driven by FSM
state transitions: mtk_cldma_dev_init() on FSM_STATE_BOOTUP
allocates DMA pools, creates a workqueue and registers the
MSI-X IRQ, and mtk_cldma_dev_exit() tears them down on
FSM_STATE_OFF.

Registering that IRQ is what first makes the completion
path built by the earlier patches run: mtk_cldma_isr()
dispatches tx_done_work and rx_done_work, and queues
err_work on a QUEUE_ERROR interrupt. err_work owns the
recovery policy: on a TX error it stops the offending
queue and completes every outstanding request with -EPIPE
rather than retrying it; a queue whose stop times out
keeps its requests and refuses new ones. An RX error is
handed to rx_done_work instead, which is the only context
that programs an RX queue, so a stop/restart pair cannot
race the worker's own resume.

A queue that will not stop within the timeout is still a
live DMA target, so its ring is deliberately leaked instead
of being unmapped and freed. The DMA pools are destroyed
regardless: dma_pool_destroy() does not free the pages of a
pool that still has blocks outstanding, so the leaked
descriptors stay allocated and only the pool bookkeeping is
released. The leak is bounded by the device instance and is
reported with dev_err().

Teardown is ordered to match. mtk_pcie_hif_exit() first
calls mtk_cldma_quiesce(), which silences each CLDMA
instance's interrupt output, masks the vector, waits out an
in-flight handler, drops the handler and drains the
workqueue. A quiesced instance is never re-armed, and the
trb service threads cannot queue CLDMA work through a
recovery once it is, so nothing is queued again before the
threads are joined and mtk_cldma_exit() frees what they
dereference.
Joining the kthreads is not sufficient on its own, because
the IRQ handler and the workqueue read trans->trb_srv[]
too.

Signed-off-by: Jack Wu <jackbb_wu@compal.com>
---
 drivers/net/wwan/t9xx/Makefile              |    1 +
 drivers/net/wwan/t9xx/mtk_ctrl_plane.c      |   49 ++
 drivers/net/wwan/t9xx/mtk_ctrl_plane.h      |    1 +
 drivers/net/wwan/t9xx/mtk_dev.h             |    1 +
 drivers/net/wwan/t9xx/mtk_fsm.c             | 1085 +++++++++++++++++++++++++++
 drivers/net/wwan/t9xx/mtk_fsm.h             |  153 ++++
 drivers/net/wwan/t9xx/mtk_port.c            |   64 ++
 drivers/net/wwan/t9xx/mtk_port.h            |    2 +
 drivers/net/wwan/t9xx/pcie/mtk_cldma.c      |  534 ++++++++++++-
 drivers/net/wwan/t9xx/pcie/mtk_cldma.h      |    7 +
 drivers/net/wwan/t9xx/pcie/mtk_cldma_drv.h  |   11 +-
 drivers/net/wwan/t9xx/pcie/mtk_pci.c        |   37 +-
 drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c |   34 +-
 drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.h |    3 +
 14 files changed, 1948 insertions(+), 34 deletions(-)

diff --git a/drivers/net/wwan/t9xx/Makefile b/drivers/net/wwan/t9xx/Makefile
index d44266009362..fcfddf2e5147 100644
--- a/drivers/net/wwan/t9xx/Makefile
+++ b/drivers/net/wwan/t9xx/Makefile
@@ -9,6 +9,7 @@ mtk_t9xx-y := \
 	mtk_ctrl_plane.o \
 	mtk_port.o \
 	mtk_port_io.o \
+	mtk_fsm.o \
 	pcie/mtk_pci.o \
 	pcie/mtk_trans_ctrl.o \
 	pcie/mtk_cldma.o \
diff --git a/drivers/net/wwan/t9xx/mtk_ctrl_plane.c b/drivers/net/wwan/t9xx/mtk_ctrl_plane.c
index af3064753b15..95c97efaf5b9 100644
--- a/drivers/net/wwan/t9xx/mtk_ctrl_plane.c
+++ b/drivers/net/wwan/t9xx/mtk_ctrl_plane.c
@@ -8,6 +8,41 @@
 
 #include "mtk_ctrl_plane.h"
 #include "mtk_port.h"
+#include "mtk_trans_ctrl.h"
+
+static void mtk_ctrl_trans_fsm_state_handler(struct mtk_fsm_param *param,
+					     struct mtk_ctrl_blk *ctrl_blk)
+{
+	struct mtk_md_dev *mdev = ctrl_blk->mdev;
+	int ret;
+
+	switch (param->to) {
+	case FSM_STATE_OFF:
+		mtk_pcie_hif_exit(mdev);
+		mtk_pcie_hif_fsm_indication(mdev, param);
+		break;
+	case FSM_STATE_ON:
+		ret = mtk_pcie_hif_init(mdev);
+		mtk_fsm_hif_err_record(mdev, MTK_FSM_HIF_USER_CTRL, ret);
+		if (ret) {
+			dev_err(mdev->dev, "Failed to init HIF: %d\n", ret);
+			break;
+		}
+		fallthrough;
+	default:
+		mtk_pcie_hif_fsm_indication(mdev, param);
+		break;
+	}
+}
+
+static void mtk_ctrl_fsm_state_listener(struct mtk_fsm_param *param, void *data)
+{
+	struct mtk_ctrl_blk *ctrl_blk = data;
+
+	mtk_port_mngr_fsm_state_handler(param, ctrl_blk->port_mngr);
+	mtk_ctrl_trans_fsm_state_handler(param, ctrl_blk);
+	mtk_port_mngr_fsm_state_handler_late(param, ctrl_blk->port_mngr);
+}
 
 /**
  * mtk_ctrl_init() - Initialize the control plane block.
@@ -40,7 +75,20 @@ int mtk_ctrl_init(struct mtk_md_dev *mdev, struct mtk_port_layer_cfg *port_layer
 		return err;
 	}
 
+	err = mtk_fsm_notifier_register(mdev, MTK_USER_CTRL, mtk_ctrl_fsm_state_listener,
+					ctrl_blk, FSM_PRIO_1);
+	if (err) {
+		dev_err(mdev->dev, "Fail to register fsm notification(ret = %d)\n", err);
+		goto err_port_exit;
+	}
+
 	return 0;
+
+err_port_exit:
+	mtk_port_mngr_exit(ctrl_blk);
+	mdev->ctrl_blk = NULL;
+
+	return err;
 }
 
 /**
@@ -57,6 +105,7 @@ void mtk_ctrl_exit(struct mtk_md_dev *mdev)
 {
 	struct mtk_ctrl_blk *ctrl_blk = mdev->ctrl_blk;
 
+	mtk_fsm_notifier_unregister(mdev, MTK_USER_CTRL);
 	mtk_port_mngr_exit(ctrl_blk);
 	mdev->ctrl_blk = NULL;
 }
diff --git a/drivers/net/wwan/t9xx/mtk_ctrl_plane.h b/drivers/net/wwan/t9xx/mtk_ctrl_plane.h
index 3ba66d9a4b60..617c022a24c3 100644
--- a/drivers/net/wwan/t9xx/mtk_ctrl_plane.h
+++ b/drivers/net/wwan/t9xx/mtk_ctrl_plane.h
@@ -10,6 +10,7 @@
 #include <linux/skbuff.h>
 
 #include "mtk_dev.h"
+#include "mtk_fsm.h"
 
 #define Q_MTU_3_5K	(0xE00)
 
diff --git a/drivers/net/wwan/t9xx/mtk_dev.h b/drivers/net/wwan/t9xx/mtk_dev.h
index ff3cbaa4329e..fe876a8edbe1 100644
--- a/drivers/net/wwan/t9xx/mtk_dev.h
+++ b/drivers/net/wwan/t9xx/mtk_dev.h
@@ -37,6 +37,7 @@ struct mtk_md_dev {
 	u32 hw_ver;
 	char dev_str[MTK_DEV_STR_LEN];
 	struct mtk_ctrl_blk *ctrl_blk;
+	struct mtk_md_fsm *fsm;
 };
 
 #endif /* __MTK_DEV_H__ */
diff --git a/drivers/net/wwan/t9xx/mtk_fsm.c b/drivers/net/wwan/t9xx/mtk_fsm.c
new file mode 100644
index 000000000000..3350f6df5064
--- /dev/null
+++ b/drivers/net/wwan/t9xx/mtk_fsm.c
@@ -0,0 +1,1085 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (c) 2022, MediaTek Inc.
+ */
+
+#include <linux/bitfield.h>
+#include <linux/device.h>
+#include <linux/kref.h>
+#include <linux/kthread.h>
+#include <linux/list.h>
+#include <linux/pci.h>
+#include <linux/sched/signal.h>
+#include <linux/sched/task.h>
+#include <linux/skbuff.h>
+#include <linux/wait.h>
+
+#include "mtk_fsm.h"
+#include "mtk_pci.h"
+#include "mtk_port.h"
+#include "mtk_port_io.h"
+
+#define EVT_TF_GATECLOSED (1)
+
+#define FSM_HS_START_MASK	(FSM_F_SAP_HS_START | FSM_F_MD_HS_START)
+#define FSM_HS2_DONE_MASK	(FSM_F_SAP_HS2_DONE | FSM_F_MD_HS2_DONE)
+
+#define RTFT_DATA_SIZE		(3 * 1024)
+#define EVT_HANDLER_TIMEOUT	(HZ * 30)
+#define BLOCKING_EVT_TIMEOUT	(2 * EVT_HANDLER_TIMEOUT)
+
+#define REGION_BITMASK		0xF
+#define DEVICE_CFG_SHIFT	24
+#define DEVICE_CFG_REGION_MASK	0x3
+
+enum device_stage {
+	DEV_STAGE_IDLE = 4,
+	DEV_STAGE_MAX
+};
+
+enum device_cfg {
+	DEV_CFG_MD_ONLY = 1,
+};
+
+enum runtime_feature_support_type {
+	RTFT_TYPE_NOT_EXIST = 0,
+	RTFT_TYPE_NOT_SUPPORT = 1,
+	RTFT_TYPE_MUST_SUPPORT = 2,
+	RTFT_TYPE_OPTIONAL_SUPPORT = 3,
+	RTFT_TYPE_SUPPORT_BACKWARD_COMPAT = 4,
+};
+
+#define FEATURE_TYPE_NOT	FIELD_PREP(FEATURE_TYPE, RTFT_TYPE_NOT_SUPPORT)
+
+enum query_runtime_feature_id {
+	QUERY_RTFT_ID_MD_PORT_ENUM = 0,
+	QUERY_RTFT_ID_SAP_PORT_ENUM = 1,
+	QUERY_RTFT_ID_MD_PORT_CFG = 2,
+};
+
+enum ctrl_msg_id {
+	CTRL_MSG_HS1 = 0,
+	CTRL_MSG_HS2 = 1,
+	CTRL_MSG_HS3 = 2,
+};
+
+struct ctrl_msg_header {
+	__le32 id;
+	__le32 ex_msg;
+	__le32 data_len;
+	u8 reserved[];
+} __packed;
+
+struct runtime_feature_entry {
+	u8 feature_id;
+	struct runtime_feature_info support_info;
+	u8 reserved[2];
+	__le32 data_len;
+	u8 data[];
+} __packed;
+
+struct feature_query {
+	__le32 head_pattern;
+	struct runtime_feature_info ft_set[FEATURE_CNT];
+	__le32 tail_pattern;
+};
+
+static int mtk_fsm_send_hs1_msg(struct fsm_hs_info *hs_info)
+{
+	struct ctrl_msg_header *ctrl_msg_h;
+	struct feature_query *ft_query;
+	struct sk_buff *skb;
+	int ret, msg_size;
+
+	msg_size = sizeof(*ctrl_msg_h) + sizeof(*ft_query);
+	skb = __dev_alloc_skb(msg_size, GFP_KERNEL);
+	if (!skb)
+		return -ENOMEM;
+
+	skb_put(skb, msg_size);
+	ctrl_msg_h = (struct ctrl_msg_header *)skb->data;
+	ctrl_msg_h->id = cpu_to_le32(CTRL_MSG_HS1);
+	ctrl_msg_h->ex_msg = 0;
+	ctrl_msg_h->data_len = cpu_to_le32(sizeof(*ft_query));
+
+	ft_query = (struct feature_query *)(skb->data + sizeof(*ctrl_msg_h));
+	ft_query->head_pattern = cpu_to_le32(FEATURE_QUERY_PATTERN);
+	memcpy(ft_query->ft_set, hs_info->query_ft_set, sizeof(hs_info->query_ft_set));
+	ft_query->tail_pattern = cpu_to_le32(FEATURE_QUERY_PATTERN);
+
+	/* send handshake1 message to device */
+	ret = mtk_port_internal_write(hs_info->ctrl_port, skb);
+	if (ret <= 0)
+		return ret;
+
+	return 0;
+}
+
+static int mtk_fsm_feature_set_match(enum runtime_feature_support_type *cur_ft_spt,
+				     struct runtime_feature_info rtft_info_st,
+				     struct runtime_feature_info rtft_info_cfg)
+{
+	int ret = 0;
+
+	switch (FIELD_GET(FEATURE_TYPE, rtft_info_st.feature)) {
+	case RTFT_TYPE_NOT_EXIST:
+		fallthrough;
+	case RTFT_TYPE_NOT_SUPPORT:
+		/* Only a mandatory feature refused outright is fatal, here
+		 * and in the MUST_SUPPORT case: no action a feature can carry
+		 * is required to reach READY, so the other cases downgrade
+		 * instead of failing.
+		 */
+		if (FIELD_GET(FEATURE_TYPE, rtft_info_cfg.feature) == RTFT_TYPE_MUST_SUPPORT)
+			ret = -EPROTO;
+		else
+			*cur_ft_spt = RTFT_TYPE_NOT_EXIST;
+		break;
+	case RTFT_TYPE_MUST_SUPPORT:
+		if (FIELD_GET(FEATURE_TYPE, rtft_info_cfg.feature) == RTFT_TYPE_NOT_EXIST ||
+		    FIELD_GET(FEATURE_TYPE, rtft_info_cfg.feature) == RTFT_TYPE_NOT_SUPPORT)
+			ret = -EPROTO;
+		else
+			*cur_ft_spt = RTFT_TYPE_MUST_SUPPORT;
+		break;
+	case RTFT_TYPE_OPTIONAL_SUPPORT:
+		if (FIELD_GET(FEATURE_TYPE, rtft_info_cfg.feature) == RTFT_TYPE_NOT_EXIST ||
+		    FIELD_GET(FEATURE_TYPE, rtft_info_cfg.feature) == RTFT_TYPE_NOT_SUPPORT) {
+			*cur_ft_spt = RTFT_TYPE_NOT_SUPPORT;
+		} else {
+			if (FIELD_GET(FEATURE_VER, rtft_info_st.feature) ==
+			    FIELD_GET(FEATURE_VER, rtft_info_cfg.feature))
+				*cur_ft_spt = RTFT_TYPE_MUST_SUPPORT;
+			else
+				*cur_ft_spt = RTFT_TYPE_NOT_SUPPORT;
+		}
+		break;
+	case RTFT_TYPE_SUPPORT_BACKWARD_COMPAT:
+		/* Decided on the device's declaration alone: the host's
+		 * configured type can be the older of the two, and gating on
+		 * it would keep off a feature the device just called
+		 * compatible.
+		 */
+		if (FIELD_GET(FEATURE_VER, rtft_info_st.feature) >=
+		    FIELD_GET(FEATURE_VER, rtft_info_cfg.feature))
+			*cur_ft_spt = RTFT_TYPE_MUST_SUPPORT;
+		else
+			*cur_ft_spt = RTFT_TYPE_NOT_EXIST;
+		break;
+	default:
+		ret = -EPROTO;
+	}
+
+	return ret;
+}
+
+static int (*query_rtft_action[FEATURE_CNT])(struct mtk_md_dev *mdev,
+					     void *rt_data, u32 data_len) = {
+	[QUERY_RTFT_ID_MD_PORT_ENUM] = mtk_port_status_update,
+	[QUERY_RTFT_ID_SAP_PORT_ENUM] = mtk_port_status_update,
+};
+
+/* The runtime data skb is owned by the caller (the FSM kthread, which got
+ * it attached to the STARTUP event); its pointer and length are read once
+ * from the skb itself, never from a shared field the rx path could rewrite.
+ */
+static int mtk_fsm_parse_hs2_msg(struct mtk_md_fsm *fsm, struct fsm_hs_info *hs_info,
+				 struct sk_buff *skb)
+{
+	enum runtime_feature_support_type cur_ft_spt;
+	struct runtime_feature_entry *rtft_entry;
+	unsigned int ft_id, offset, data_len;
+	unsigned int rt_data_len;
+	char *rt_data;
+	int ret = 0;
+
+	if (!skb)
+		return -EINVAL;
+
+	rt_data = skb->data;
+	rt_data_len = skb->len;
+
+	offset = sizeof(struct feature_query);
+	for (ft_id = 0; ft_id < FEATURE_CNT; ft_id++) {
+		if (offset + sizeof(*rtft_entry) > rt_data_len)
+			break;
+
+		rtft_entry = (struct runtime_feature_entry *)(rt_data + offset);
+		ret = mtk_fsm_feature_set_match(&cur_ft_spt,
+						rtft_entry->support_info,
+						hs_info->query_ft_set[ft_id]);
+		if (ret < 0)
+			break;
+
+		data_len = le32_to_cpu(rtft_entry->data_len);
+		if (data_len > rt_data_len - offset - sizeof(*rtft_entry))
+			break;
+
+		if (cur_ft_spt == RTFT_TYPE_MUST_SUPPORT && query_rtft_action[ft_id]) {
+			if (!data_len) {
+				dev_err(fsm->mdev->dev,
+					"RTFT feature %u: zero data_len\n", ft_id);
+				ret = -EPROTO;
+				break;
+			}
+			ret = query_rtft_action[ft_id](fsm->mdev,
+						       rtft_entry->data,
+						       data_len);
+		}
+		if (ret < 0)
+			break;
+
+		offset += sizeof(*rtft_entry) + data_len;
+	}
+
+	if (ft_id != FEATURE_CNT) {
+		dev_err((fsm->mdev)->dev, "Unable to handle mistake hs2 msg, ft_id=%u\n", ft_id);
+		ret = -EPROTO;
+	}
+
+	return ret;
+}
+
+static int mtk_fsm_append_rtft_entries(void *feature_data, unsigned int *len,
+				       struct sk_buff *skb)
+{
+	struct runtime_feature_entry *rtft_entry;
+	int ft_id, ret = 0, rtdata_len = 0;
+	struct feature_query *ft_query;
+
+	if (!skb || skb->len < sizeof(*ft_query)) {
+		ret = -EPROTO;
+		goto hs_err;
+	}
+
+	ft_query = (struct feature_query *)skb->data;
+	if (le32_to_cpu(ft_query->head_pattern) != FEATURE_QUERY_PATTERN ||
+	    le32_to_cpu(ft_query->tail_pattern) != FEATURE_QUERY_PATTERN) {
+		ret = -EPROTO;
+		goto hs_err;
+	}
+
+	/* parse runtime feature query and fill runtime feature entry */
+	rtft_entry = feature_data;
+	for (ft_id = 0; ft_id < FEATURE_CNT && rtdata_len < RTFT_DATA_SIZE; ft_id++) {
+		rtft_entry->feature_id = ft_id;
+		rtft_entry->data_len = 0;
+
+		switch (FIELD_GET(FEATURE_TYPE, ft_query->ft_set[ft_id].feature)) {
+		case RTFT_TYPE_NOT_EXIST:
+			fallthrough;
+		case RTFT_TYPE_NOT_SUPPORT:
+			fallthrough;
+		case RTFT_TYPE_MUST_SUPPORT:
+			/* A MUST_SUPPORT feature is mandatory on the device side
+			 * and takes no runtime data from the host, so it is
+			 * echoed back unchanged with data_len 0.
+			 */
+			rtft_entry->support_info = ft_query->ft_set[ft_id];
+			break;
+		case RTFT_TYPE_OPTIONAL_SUPPORT:
+			fallthrough;
+		case RTFT_TYPE_SUPPORT_BACKWARD_COMPAT:
+			rtft_entry->support_info.feature = FEATURE_TYPE_NOT;
+			rtft_entry->support_info.feature |= FEATURE_VER_0;
+			break;
+		}
+
+		rtdata_len += sizeof(*rtft_entry) + le32_to_cpu(rtft_entry->data_len);
+		rtft_entry = (struct runtime_feature_entry *)(feature_data + rtdata_len);
+	}
+	*len = rtdata_len;
+	return 0;
+
+hs_err:
+	*len = 0;
+	return ret;
+}
+
+static int mtk_fsm_send_hs3_msg(struct fsm_hs_info *hs_info, struct sk_buff *rt_skb)
+{
+	unsigned int data_len, msg_size = 0;
+	struct ctrl_msg_header *ctrl_msg_h;
+	struct sk_buff *skb;
+	int ret;
+
+	skb = __dev_alloc_skb(RTFT_DATA_SIZE, GFP_KERNEL);
+	if (!skb)
+		return -ENOMEM;
+	memset(skb->data, 0, RTFT_DATA_SIZE);
+
+	msg_size += sizeof(*ctrl_msg_h);
+	ctrl_msg_h = (struct ctrl_msg_header *)skb->data;
+	ctrl_msg_h->id = cpu_to_le32(CTRL_MSG_HS3);
+	ctrl_msg_h->ex_msg = 0;
+	ret = mtk_fsm_append_rtft_entries(skb->data + sizeof(*ctrl_msg_h),
+					  &data_len, rt_skb);
+	if (ret) {
+		dev_kfree_skb(skb);
+		return ret;
+	}
+
+	ctrl_msg_h->data_len = cpu_to_le32(data_len);
+	msg_size += data_len;
+	skb_put(skb, msg_size);
+	ret = mtk_port_internal_write(hs_info->ctrl_port, skb);
+	if (ret <= 0)
+		return ret;
+
+	return 0;
+}
+
+/* The handler owns the skb on every path and always returns 0: the caller
+ * (mtk_port_rx_dispatch) frees the skb itself on a negative return, so
+ * returning an error after dev_kfree_skb() would free it twice.
+ *
+ * On success the skb is attached to the submitted event (event->data) and
+ * from then on belongs to the FSM kthread; hs_info->rt_data is kept only
+ * as the duplicate-HS2 guard, claimed with cmpxchg() and cleared by the
+ * kthread once the event has been consumed.  An event discarded instead
+ * leaves its skb on the guard, and mtk_fsm_exit() frees it there.  The
+ * kthread's store and the accesses below are the only concurrent users of
+ * the field, so they are marked: a stale non-NULL read at worst drops one
+ * retransmitted HS2, which the device repeats.
+ */
+static int mtk_fsm_ctrl_msg_handler(void *__hs_info, struct sk_buff *skb)
+{
+	struct fsm_hs_info *hs_info = __hs_info;
+	struct ctrl_msg_header *ctrl_msg_h;
+	struct mtk_md_fsm *fsm;
+	int ret;
+
+	fsm = container_of(hs_info, struct mtk_md_fsm, hs_info[hs_info->id]);
+	if (skb->len < sizeof(*ctrl_msg_h)) {
+		dev_kfree_skb(skb);
+		return 0;
+	}
+
+	ctrl_msg_h = (struct ctrl_msg_header *)skb->data;
+	if (le32_to_cpu(ctrl_msg_h->id) != CTRL_MSG_HS2) {
+		dev_err(fsm->mdev->dev, "Invalid ctrl msg id (hs%d)\n", hs_info->id);
+		dev_kfree_skb(skb);
+		return 0;
+	}
+
+	skb_pull(skb, sizeof(*ctrl_msg_h));
+	if (cmpxchg(&hs_info->rt_data, NULL, skb)) {
+		/* The guarded skb belongs to a still-queued event; only the
+		 * new skb may be freed here.
+		 */
+		dev_warn(fsm->mdev->dev, "Duplicate HS2 (hs%d), dropping\n", hs_info->id);
+		dev_kfree_skb(skb);
+		return 0;
+	}
+
+	ret = mtk_fsm_evt_submit(fsm->mdev, FSM_EVT_STARTUP,
+				 hs_info->fsm_flag_hs2, skb, 0);
+	if (ret) {
+		WRITE_ONCE(hs_info->rt_data, NULL);
+		dev_kfree_skb(skb);
+	}
+
+	return 0;
+}
+
+/* For the MHCCIF callbacks, which can race DEV_RM masking the channels from
+ * the FSM thread.  DEV_RM closes the event gate before it masks, so an
+ * unmask that lands after its mask sees the gate closed and is undone.
+ */
+static void mtk_fsm_unmask_ext_evt(struct mtk_md_fsm *fsm, u32 chs)
+{
+	mtk_pci_unmask_ext_evt(fsm->mdev, chs);
+	/* order the unmask before the gate test; pairs with the barrier in
+	 * mtk_fsm_dev_rm_act()
+	 */
+	mb();
+	if (test_bit(EVT_TF_GATECLOSED, &fsm->t_flag))
+		mtk_pci_mask_ext_evt(fsm->mdev, chs);
+}
+
+static void mtk_fsm_idle_evt_handler(struct mtk_md_dev *mdev,
+				     u32 dev_state, struct mtk_md_fsm *fsm)
+{
+	u32 dev_cfg = dev_state >> DEVICE_CFG_SHIFT & DEVICE_CFG_REGION_MASK;
+	int hs_id;
+
+	if (dev_cfg == DEV_CFG_MD_ONLY)
+		WRITE_ONCE(fsm->hs_done_flag, FSM_F_MD_HS_START | FSM_F_MD_HS2_DONE);
+	else
+		WRITE_ONCE(fsm->hs_done_flag, FSM_HS_START_MASK | FSM_HS2_DONE_MASK);
+
+	if (mtk_fsm_evt_submit(mdev, FSM_EVT_STARTUP, FSM_F_DFLT,
+			       NULL, 0))
+		dev_err(mdev->dev, "Failed to submit STARTUP evt\n");
+
+	/* The notification carrying this state is one-shot, so there is no
+	 * retry to wait for: open the handshake channels whether or not the
+	 * STARTUP above was queued.  A bare HS1 drives ON->BOOTUP as well.
+	 */
+	for (hs_id = 0; hs_id < HS_ID_MAX; hs_id++)
+		mtk_fsm_unmask_ext_evt(fsm, fsm->hs_info[hs_id].mhccif_ch);
+}
+
+static int mtk_fsm_early_bootup_handler(u32 status, void *__fsm)
+{
+	struct mtk_md_fsm *fsm = __fsm;
+	struct mtk_md_dev *mdev;
+	u32 dev_state, dev_stage;
+
+	mdev = fsm->mdev;
+	mtk_pci_mask_ext_evt(mdev, status);
+
+	dev_state = mtk_pci_get_dev_state(mdev);
+	dev_stage = dev_state & REGION_BITMASK;
+	if (dev_stage >= DEV_STAGE_MAX) {
+		dev_err(mdev->dev, "Invalid dev state 0x%x\n", dev_state);
+		goto exit;
+	}
+
+	if (dev_state == fsm->last_dev_state)
+		goto exit;
+
+	if (dev_stage == DEV_STAGE_IDLE)
+		mtk_fsm_idle_evt_handler(mdev, dev_state, fsm);
+
+	fsm->last_dev_state = dev_state;
+
+exit:
+	/* Re-arm the channel masked on entry: the device notifies once per
+	 * boot stage, so leaving it masked drops every later stage.
+	 */
+	mtk_fsm_unmask_ext_evt(fsm, status);
+	return 0;
+}
+
+static int mtk_fsm_ctrl_ch_start(struct mtk_md_fsm *fsm, struct fsm_hs_info *hs_info, int flag)
+{
+	if (!hs_info->ctrl_port) {
+		hs_info->ctrl_port = mtk_port_internal_open(fsm->mdev, hs_info->port_name, flag);
+		if (!hs_info->ctrl_port) {
+			dev_err(fsm->mdev->dev, "Failed to open ctrl port(%s)\n",
+				hs_info->port_name);
+			return -ENODEV;
+		}
+
+		mtk_port_internal_recv_register(hs_info->ctrl_port,
+						mtk_fsm_ctrl_msg_handler, hs_info);
+	}
+
+	return 0;
+}
+
+static void mtk_fsm_ctrl_ch_stop(struct mtk_md_fsm *fsm)
+{
+	struct fsm_hs_info *hs_info;
+	int hs_id;
+
+	for (hs_id = 0; hs_id < HS_ID_MAX; hs_id++) {
+		hs_info = &fsm->hs_info[hs_id];
+		if (hs_info->ctrl_port) {
+			mtk_port_internal_close(hs_info->ctrl_port);
+			hs_info->ctrl_port = NULL;
+		}
+	}
+}
+
+static void mtk_fsm_switch_state(struct mtk_md_fsm *fsm,
+				 enum mtk_fsm_state to_state, struct mtk_fsm_evt *event)
+{
+	struct mtk_fsm_notifier *nt;
+	struct mtk_fsm_param param;
+
+	param.from = fsm->state;
+	param.to = to_state;
+	param.evt_id = event ? event->id : FSM_EVT_MAX;
+	param.fsm_flag = event ? event->fsm_flag : FSM_F_DFLT;
+
+	mutex_lock(&fsm->notifier_lock);
+	fsm->state = to_state;
+	fsm->fsm_flag |= event ? event->fsm_flag : FSM_F_DFLT;
+
+	list_for_each_entry(nt, &fsm->post_notifiers, entry)
+		nt->cb(&param, nt->data);
+	mutex_unlock(&fsm->notifier_lock);
+}
+
+static int mtk_fsm_startup_act(struct mtk_md_fsm *fsm, struct mtk_fsm_evt *event)
+{
+	enum mtk_fsm_state to_state = FSM_STATE_BOOTUP;
+	struct mtk_md_dev *mdev = fsm->mdev;
+	struct fsm_hs_info *hs_info;
+	struct sk_buff *skb = NULL;
+	u32 hs_done_flag;
+	int ret = 0;
+
+	if (event->fsm_flag & FSM_HS2_DONE_MASK) {
+		/* The HS2 event owns its runtime-data skb. */
+		skb = event->data;
+		hs_info = &fsm->hs_info[(event->fsm_flag & FSM_F_MD_HS2_DONE) ?
+					HS_ID_MD : HS_ID_SAP];
+	} else {
+		/* HS1 events carry the hs_info; the bare STARTUP carries NULL. */
+		hs_info = event->data;
+	}
+
+	if (fsm->state != FSM_STATE_ON && fsm->state != FSM_STATE_BOOTUP) {
+		ret = -EPROTO;
+		goto free_skb;
+	}
+
+	if (!(event->fsm_flag & (FSM_HS_START_MASK | FSM_HS2_DONE_MASK))) {
+		/* Bare STARTUP from the boot-flow notification: only the
+		 * state switch.
+		 */
+		if (fsm->state != FSM_STATE_BOOTUP)
+			mtk_fsm_switch_state(fsm, to_state, event);
+		return 0;
+	}
+
+	if (event->fsm_flag & FSM_HS_START_MASK) {
+		/* An HS1 that raced ahead of the bare STARTUP must both
+		 * switch ON to BOOTUP and run the handshake below; returning
+		 * after the switch would consume the only trigger.
+		 */
+		mtk_fsm_switch_state(fsm, to_state, event);
+
+		ret = mtk_fsm_ctrl_ch_start(fsm, hs_info, O_NONBLOCK);
+		if (!ret)
+			ret = mtk_fsm_send_hs1_msg(hs_info);
+		if (ret)
+			goto hs_err;
+	} else if (event->fsm_flag & FSM_HS2_DONE_MASK) {
+		ret = mtk_fsm_parse_hs2_msg(fsm, hs_info, skb);
+		if (!ret)
+			ret = mtk_fsm_send_hs3_msg(hs_info, skb);
+		dev_kfree_skb(skb);
+		skb = NULL;
+		/* re-open the duplicate guard */
+		WRITE_ONCE(hs_info->rt_data, NULL);
+		if (ret)
+			goto hs_err;
+		mtk_fsm_switch_state(fsm, to_state, event);
+	}
+
+	hs_done_flag = READ_ONCE(fsm->hs_done_flag);
+	if (((fsm->fsm_flag | event->fsm_flag) & hs_done_flag) == hs_done_flag) {
+		int user;
+
+		for (user = 0; user < MTK_FSM_HIF_USER_MAX; user++) {
+			if (fsm->hif_err[user]) {
+				dev_err(mdev->dev,
+					"Refusing READY: HIF user %d init failed with %d\n",
+					user, fsm->hif_err[user]);
+				return fsm->hif_err[user];
+			}
+		}
+
+		to_state = FSM_STATE_READY;
+		mtk_fsm_switch_state(fsm, to_state, NULL);
+	}
+
+	return 0;
+
+free_skb:
+	if (skb) {
+		dev_kfree_skb(skb);
+		WRITE_ONCE(hs_info->rt_data, NULL);
+	}
+hs_err:
+	/* Re-arm only this handshake's channel, which its HS1 masked; the
+	 * other one may still have its own HS1 queued.
+	 */
+	if (hs_info)
+		mtk_pci_unmask_ext_evt(mdev, hs_info->mhccif_ch);
+	dev_err(mdev->dev, "Failed to hs with device %d:0x%x, ret=%d",
+		fsm->state, fsm->fsm_flag, ret);
+	return ret;
+}
+
+static void mtk_fsm_evt_release(struct kref *kref)
+{
+	struct mtk_fsm_evt *event = container_of(kref, struct mtk_fsm_evt, kref);
+
+	kfree(event);
+}
+
+static void mtk_fsm_evt_put(struct mtk_fsm_evt *event)
+{
+	kref_put(&event->kref, mtk_fsm_evt_release);
+}
+
+static void mtk_fsm_evt_finish(struct mtk_md_fsm *fsm,
+			       struct mtk_fsm_evt *event, int retval)
+{
+	if (event->mode & EVT_MODE_BLOCKING) {
+		event->status = retval;
+		wake_up(&fsm->evt_waitq);
+	}
+	mtk_fsm_evt_put(event);
+}
+
+static void mtk_fsm_evt_cleanup(struct mtk_md_fsm *fsm, struct list_head *evtq)
+{
+	struct mtk_fsm_evt *event, *tmp;
+
+	list_for_each_entry_safe(event, tmp, evtq, entry) {
+		list_del(&event->entry);
+		mtk_fsm_evt_finish(fsm, event, FSM_EVT_RET_FAIL);
+	}
+}
+
+static int mtk_fsm_enter_off_state(struct mtk_md_fsm *fsm, struct mtk_fsm_evt *event)
+{
+	struct mtk_md_dev *mdev = fsm->mdev;
+	int hs_id;
+
+	if (fsm->state == FSM_STATE_OFF || fsm->state == FSM_STATE_INVALID)
+		return -EPROTO;
+
+	mtk_pci_mask_ext_evt(mdev, DEV_EVT_D2H_BOOT_FLOW_SYNC);
+	for (hs_id = 0; hs_id < HS_ID_MAX; hs_id++)
+		mtk_pci_mask_ext_evt(mdev, fsm->hs_info[hs_id].mhccif_ch);
+
+	mtk_fsm_ctrl_ch_stop(fsm);
+	mtk_fsm_switch_state(fsm, FSM_STATE_OFF, event);
+
+	return 0;
+}
+
+static int mtk_fsm_dev_rm_act(struct mtk_md_fsm *fsm, struct mtk_fsm_evt *event)
+{
+	unsigned long flags;
+
+	spin_lock_irqsave(&fsm->evtq_lock, flags);
+	set_bit(EVT_TF_GATECLOSED, &fsm->t_flag);
+	mtk_fsm_evt_cleanup(fsm, &fsm->evtq);
+	spin_unlock_irqrestore(&fsm->evtq_lock, flags);
+	/* gate closed before the masks; see mtk_fsm_unmask_ext_evt() */
+	mb();
+
+	return mtk_fsm_enter_off_state(fsm, event);
+}
+
+static int mtk_fsm_hs1_handler(u32 status, void *__hs_info)
+{
+	struct fsm_hs_info *hs_info = __hs_info;
+	struct mtk_md_dev *mdev;
+	struct mtk_md_fsm *fsm;
+
+	fsm = container_of(hs_info, struct mtk_md_fsm, hs_info[hs_info->id]);
+	mdev = fsm->mdev;
+	/* Mask before the submit so exactly one side owns the channel: this
+	 * handler until the event is queued, the FSM thread afterwards,
+	 * which may already have re-armed it for a retry.
+	 */
+	mtk_pci_mask_ext_evt(mdev, hs_info->mhccif_ch);
+	if (mtk_fsm_evt_submit(mdev, FSM_EVT_STARTUP, hs_info->fsm_flag_hs1,
+			       hs_info, 0)) {
+		dev_err(mdev->dev, "Failed to submit HS1 evt(hs%d)\n", hs_info->id);
+		/* Nothing was handed over, so the channel is still ours */
+		mtk_fsm_unmask_ext_evt(fsm, hs_info->mhccif_ch);
+		return -ENOMEM;
+	}
+
+	return 0;
+}
+
+static void mtk_fsm_hs_info_init_by_hsid(struct mtk_md_fsm *fsm, int hs_id)
+{
+	struct fsm_hs_info *hs_info;
+
+	hs_info = &fsm->hs_info[hs_id];
+	hs_info->id = hs_id;
+	hs_info->ctrl_port = NULL;
+	hs_info->rt_data = NULL;
+	switch (hs_id) {
+	case HS_ID_MD:
+		snprintf(hs_info->port_name, PORT_NAME_LEN, "MDCTRL");
+		hs_info->mhccif_ch = DEV_EVT_D2H_ASYNC_HS_NOTIFY_MD;
+		hs_info->fsm_flag_hs1 = FSM_F_MD_HS_START;
+		hs_info->fsm_flag_hs2 = FSM_F_MD_HS2_DONE;
+		hs_info->query_ft_set[QUERY_RTFT_ID_MD_PORT_ENUM].feature =
+			FIELD_PREP(FEATURE_TYPE, RTFT_TYPE_MUST_SUPPORT);
+		hs_info->query_ft_set[QUERY_RTFT_ID_MD_PORT_ENUM].feature |=
+			FIELD_PREP(FEATURE_VER, 0);
+		hs_info->query_ft_set[QUERY_RTFT_ID_MD_PORT_CFG].feature =
+			FIELD_PREP(FEATURE_TYPE, RTFT_TYPE_NOT_SUPPORT);
+		break;
+	case HS_ID_SAP:
+		snprintf(hs_info->port_name, PORT_NAME_LEN, "SAPCTRL");
+		hs_info->mhccif_ch = DEV_EVT_D2H_ASYNC_HS_NOTIFY_SAP;
+		hs_info->fsm_flag_hs1 = FSM_F_SAP_HS_START;
+		hs_info->fsm_flag_hs2 = FSM_F_SAP_HS2_DONE;
+		hs_info->query_ft_set[QUERY_RTFT_ID_SAP_PORT_ENUM].feature =
+			FIELD_PREP(FEATURE_TYPE, RTFT_TYPE_MUST_SUPPORT);
+		hs_info->query_ft_set[QUERY_RTFT_ID_SAP_PORT_ENUM].feature |=
+			FIELD_PREP(FEATURE_VER, 0);
+		break;
+	}
+}
+
+static int mtk_fsm_hs_info_init(struct mtk_md_fsm *fsm)
+{
+	struct mtk_md_dev *mdev = fsm->mdev;
+	struct fsm_hs_info *hs_info;
+	int hs_id, ret;
+
+	for (hs_id = 0; hs_id < HS_ID_MAX; hs_id++) {
+		mtk_fsm_hs_info_init_by_hsid(fsm, hs_id);
+		hs_info = &fsm->hs_info[hs_id];
+		ret = mtk_pci_register_ext_evt(mdev, hs_info->mhccif_ch,
+					       mtk_fsm_hs1_handler, hs_info);
+		if (ret)
+			goto err_unregister;
+	}
+
+	return 0;
+
+err_unregister:
+	/* All or nothing: the caller must not have to know how far we got. */
+	while (--hs_id >= 0)
+		mtk_pci_unregister_ext_evt(mdev, fsm->hs_info[hs_id].mhccif_ch);
+
+	return ret;
+}
+
+static void mtk_fsm_hs_info_exit(struct mtk_md_fsm *fsm)
+{
+	struct mtk_md_dev *mdev = fsm->mdev;
+	struct fsm_hs_info *hs_info;
+	int hs_id;
+
+	for (hs_id = 0; hs_id < HS_ID_MAX; hs_id++) {
+		hs_info = &fsm->hs_info[hs_id];
+		mtk_pci_unregister_ext_evt(mdev, hs_info->mhccif_ch);
+	}
+}
+
+static int mtk_fsm_dev_add_act(struct mtk_md_fsm *fsm, struct mtk_fsm_evt *event)
+{
+	if (fsm->state != FSM_STATE_INVALID)
+		return -EPROTO;
+
+	mtk_fsm_switch_state(fsm, FSM_STATE_ON, event);
+	mtk_pci_unmask_ext_evt(fsm->mdev, DEV_EVT_D2H_BOOT_FLOW_SYNC);
+
+	return 0;
+}
+
+static int (*evts_act_tbl[FSM_EVT_MAX])(struct mtk_md_fsm *__fsm, struct mtk_fsm_evt *event) = {
+	[FSM_EVT_STARTUP] = mtk_fsm_startup_act,
+	[FSM_EVT_DEV_RM] = mtk_fsm_dev_rm_act,
+	[FSM_EVT_DEV_ADD] = mtk_fsm_dev_add_act,
+};
+
+/* Record a transport-plane init failure so the STARTUP path refuses the
+ * BOOTUP-to-READY promotion: the notifier callbacks are void and cannot
+ * reject a transition, so without this the FSM would advertise readiness
+ * on top of a data path that was never created.  Each producer owns one
+ * slot and stores its latest result there, so a retried init that
+ * succeeds clears the failure it recorded before.
+ */
+void mtk_fsm_hif_err_record(struct mtk_md_dev *mdev, enum mtk_fsm_hif_user user, int err)
+{
+	struct mtk_md_fsm *fsm = mdev->fsm;
+
+	if (fsm)
+		fsm->hif_err[user] = err;
+}
+
+static void mtk_fsm_notifier_cleanup(struct mtk_md_dev *mdev, struct list_head *ntq)
+{
+	struct mtk_fsm_notifier *nt, *tmp;
+
+	list_for_each_entry_safe(nt, tmp, ntq, entry) {
+		list_del(&nt->entry);
+		dev_warn(mdev->dev, "Having to free notifier(%d) by FSM!\n", nt->id);
+		kfree(nt);
+	}
+}
+
+static void mtk_fsm_notifier_insert(struct mtk_fsm_notifier *notifier, struct list_head *head)
+{
+	struct mtk_fsm_notifier *nt;
+
+	list_for_each_entry(nt, head, entry) {
+		if (notifier->prio > nt->prio) {
+			list_add(&notifier->entry, nt->entry.prev);
+			return;
+		}
+	}
+	list_add_tail(&notifier->entry, head);
+}
+
+int mtk_fsm_notifier_register(struct mtk_md_dev *mdev, enum mtk_user_id id,
+			      void (*cb)(struct mtk_fsm_param *, void *data),
+			      void *data, enum mtk_fsm_prio prio)
+{
+	struct mtk_md_fsm *fsm = mdev->fsm;
+	struct mtk_fsm_notifier *notifier;
+
+	if (!fsm)
+		return -EINVAL;
+
+	if (id >= MTK_USER_MAX || !cb || prio >= FSM_PRIO_MAX)
+		return -EINVAL;
+
+	notifier = kzalloc_obj(*notifier);
+	if (!notifier)
+		return -ENOMEM;
+
+	INIT_LIST_HEAD(&notifier->entry);
+	notifier->id = id;
+	notifier->cb = cb;
+	notifier->data = data;
+	notifier->prio = prio;
+
+	mutex_lock(&fsm->notifier_lock);
+	mtk_fsm_notifier_insert(notifier, &fsm->post_notifiers);
+	mutex_unlock(&fsm->notifier_lock);
+
+	return 0;
+}
+
+int mtk_fsm_notifier_unregister(struct mtk_md_dev *mdev, enum mtk_user_id id)
+{
+	struct mtk_md_fsm *fsm = mdev->fsm;
+	struct mtk_fsm_notifier *nt, *tmp;
+
+	if (!fsm)
+		return -EINVAL;
+
+	mutex_lock(&fsm->notifier_lock);
+	list_for_each_entry_safe(nt, tmp, &fsm->post_notifiers, entry) {
+		if (nt->id == id) {
+			list_del(&nt->entry);
+			kfree(nt);
+			break;
+		}
+	}
+	mutex_unlock(&fsm->notifier_lock);
+	return 0;
+}
+
+int mtk_fsm_evt_submit(struct mtk_md_dev *mdev,
+		       enum mtk_fsm_evt_id id, enum mtk_fsm_flag flag,
+		       void *data, unsigned char mode)
+{
+	struct mtk_md_fsm *fsm = mdev->fsm;
+	struct mtk_fsm_evt *event;
+	unsigned long flags;
+	int ret = 0;
+
+	if (!fsm || id >= FSM_EVT_MAX) {
+		dev_err(mdev->dev, "Invalid param!\n");
+		return -EINVAL;
+	}
+
+	if (test_bit(EVT_TF_GATECLOSED, &fsm->t_flag)) {
+		dev_err(mdev->dev, "Failed to submit evt, fsm has been removed!\n");
+		return -ENODEV;
+	}
+
+	/* callable from atomic context unless EVT_MODE_BLOCKING */
+	event = kzalloc(sizeof(*event), GFP_ATOMIC);
+	if (!event)
+		return -ENOMEM;
+
+	kref_init(&event->kref);
+	event->id = id;
+	event->fsm_flag = flag;
+	event->status = FSM_EVT_RET_ONGOING;
+	event->data = data;
+	event->mode = mode;
+
+	spin_lock_irqsave(&fsm->evtq_lock, flags);
+	if (test_bit(EVT_TF_GATECLOSED, &fsm->t_flag)) {
+		spin_unlock_irqrestore(&fsm->evtq_lock, flags);
+		mtk_fsm_evt_put(event);
+		dev_err(mdev->dev, "Failed to add event, fsm dev has been removed!\n");
+		return -ENODEV;
+	}
+
+	kref_get(&event->kref);
+	if (mode & EVT_MODE_TOHEAD)
+		list_add(&event->entry, &fsm->evtq);
+	else
+		list_add_tail(&event->entry, &fsm->evtq);
+	if (fsm->fsm_handler)
+		wake_up_process(fsm->fsm_handler);
+	spin_unlock_irqrestore(&fsm->evtq_lock, flags);
+
+	if (mode & EVT_MODE_BLOCKING) {
+		ret = wait_event_timeout(fsm->evt_waitq,
+					 (event->status != 0), BLOCKING_EVT_TIMEOUT);
+		if (event->status == FSM_EVT_RET_DONE) {
+			ret = 0;
+		} else if (!ret) {
+			dev_err(mdev->dev, "Handling fsm blocking event timeout!\n");
+			ret = -ETIMEDOUT;
+		} else {
+			ret = -EIO;
+		}
+	}
+	mtk_fsm_evt_put(event);
+
+	return ret;
+}
+
+static int mtk_fsm_evt_handler(void *__fsm)
+{
+	struct mtk_md_fsm *fsm = __fsm;
+	struct mtk_fsm_evt *event;
+	unsigned long flags;
+	int ret;
+
+wake_up:
+	set_current_state(TASK_INTERRUPTIBLE);
+	while (!kthread_should_stop() && !list_empty(&fsm->evtq)) {
+		set_current_state(TASK_RUNNING);
+		spin_lock_irqsave(&fsm->evtq_lock, flags);
+		event = list_first_entry(&fsm->evtq, struct mtk_fsm_evt, entry);
+		list_del(&event->entry);
+		spin_unlock_irqrestore(&fsm->evtq_lock, flags);
+
+		if (event->id < FSM_EVT_MAX) {
+			ret = evts_act_tbl[event->id](fsm, event);
+			if (ret) {
+				dev_err((fsm->mdev)->dev,
+					"Failed to handle evt, fsm state = %d, ret = %d\n",
+					fsm->state, ret);
+				mtk_fsm_evt_finish(fsm, event, FSM_EVT_RET_FAIL);
+			} else {
+				mtk_fsm_evt_finish(fsm, event, FSM_EVT_RET_DONE);
+			}
+		} else {
+			mtk_fsm_evt_finish(fsm, event, FSM_EVT_RET_DONE);
+		}
+	}
+
+	if (kthread_should_stop()) {
+		set_current_state(TASK_RUNNING);
+		return 0;
+	}
+
+	schedule();
+	goto wake_up;
+}
+
+int mtk_fsm_init(struct mtk_md_dev *mdev)
+{
+	struct mtk_md_fsm *fsm;
+	int ret;
+
+	fsm = devm_kzalloc(mdev->dev, sizeof(*fsm), GFP_KERNEL);
+	if (!fsm)
+		return -ENOMEM;
+
+	fsm->fsm_handler = kthread_create(mtk_fsm_evt_handler, fsm, "fsm_evt_thread%u_%s",
+					  mdev->hw_ver, mdev->dev_str);
+	if (IS_ERR(fsm->fsm_handler))
+		return PTR_ERR(fsm->fsm_handler);
+
+	/* Keep our own reference so that kthread_stop() in the teardown
+	 * paths stays safe even if the thread has already exited (e.g.
+	 * it was killed by an oops in a listener it called): without it
+	 * the task_struct may be freed and kthread_stop() would hit a
+	 * use-after-free through its internal get_task_struct().
+	 */
+	get_task_struct(fsm->fsm_handler);
+
+	fsm->mdev = mdev;
+	fsm->state = FSM_STATE_INVALID;
+	fsm->fsm_flag = FSM_F_DFLT;
+
+	INIT_LIST_HEAD(&fsm->evtq);
+	spin_lock_init(&fsm->evtq_lock);
+	init_waitqueue_head(&fsm->evt_waitq);
+
+	INIT_LIST_HEAD(&fsm->post_notifiers);
+	mutex_init(&fsm->notifier_lock);
+
+	ret = mtk_pci_register_ext_evt(mdev, DEV_EVT_D2H_BOOT_FLOW_SYNC,
+				       mtk_fsm_early_bootup_handler, fsm);
+	if (ret)
+		goto err_stop_thread;
+
+	ret = mtk_fsm_hs_info_init(fsm);
+	if (ret)
+		goto err_unregister_evt;
+
+	mdev->fsm = fsm;
+	return 0;
+
+err_unregister_evt:
+	mtk_pci_unregister_ext_evt(mdev, DEV_EVT_D2H_BOOT_FLOW_SYNC);
+err_stop_thread:
+	/* mdev->fsm is never published on failure, so mtk_fsm_exit() cannot
+	 * stop the parked kthread for us; it must be stopped here.
+	 */
+	kthread_stop(fsm->fsm_handler);
+	put_task_struct(fsm->fsm_handler);
+	return ret;
+}
+
+/* Close the event gate and join the handler thread, then release the
+ * control ports while the port table they reference is still alive.
+ * Called from the removal path before the transport plane is dismantled;
+ * every step is idempotent, so mtk_fsm_exit() may repeat them safely.
+ */
+int mtk_fsm_stop(struct mtk_md_dev *mdev)
+{
+	struct mtk_md_fsm *fsm = mdev->fsm;
+	struct task_struct *handler;
+	unsigned long flags;
+
+	if (!fsm)
+		return -EINVAL;
+
+	spin_lock_irqsave(&fsm->evtq_lock, flags);
+	set_bit(EVT_TF_GATECLOSED, &fsm->t_flag);
+	handler = fsm->fsm_handler;
+	fsm->fsm_handler = NULL;
+	spin_unlock_irqrestore(&fsm->evtq_lock, flags);
+
+	if (handler) {
+		kthread_stop(handler);
+		put_task_struct(handler);
+	}
+
+	spin_lock_irqsave(&fsm->evtq_lock, flags);
+	mtk_fsm_evt_cleanup(fsm, &fsm->evtq);
+	spin_unlock_irqrestore(&fsm->evtq_lock, flags);
+
+	mtk_fsm_ctrl_ch_stop(fsm);
+
+	return 0;
+}
+
+int mtk_fsm_exit(struct mtk_md_dev *mdev)
+{
+	struct mtk_md_fsm *fsm = mdev->fsm;
+
+	if (!fsm)
+		return -EINVAL;
+
+	/* also releases the control ports when DEV_RM never ran */
+	mtk_fsm_stop(mdev);
+
+	for (int i = 0; i < HS_ID_MAX; i++) {
+		if (fsm->hs_info[i].rt_data) {
+			dev_kfree_skb(fsm->hs_info[i].rt_data);
+			fsm->hs_info[i].rt_data = NULL;
+		}
+	}
+
+	mutex_lock(&fsm->notifier_lock);
+	mtk_fsm_notifier_cleanup(mdev, &fsm->post_notifiers);
+	mutex_unlock(&fsm->notifier_lock);
+
+	mtk_pci_unregister_ext_evt(mdev, DEV_EVT_D2H_BOOT_FLOW_SYNC);
+	mtk_fsm_hs_info_exit(fsm);
+	mdev->fsm = NULL;
+
+	return 0;
+}
diff --git a/drivers/net/wwan/t9xx/mtk_fsm.h b/drivers/net/wwan/t9xx/mtk_fsm.h
new file mode 100644
index 000000000000..f809579dc57d
--- /dev/null
+++ b/drivers/net/wwan/t9xx/mtk_fsm.h
@@ -0,0 +1,153 @@
+/* SPDX-License-Identifier: GPL-2.0-only
+ *
+ * Copyright (c) 2022, MediaTek Inc.
+ */
+
+#ifndef __MTK_FSM_H__
+#define __MTK_FSM_H__
+
+#include <linux/mutex.h>
+
+#include "mtk_dev.h"
+
+#define FEATURE_CNT		(64)
+#define FEATURE_QUERY_PATTERN	(0x49434343)
+
+#define FEATURE_TYPE		GENMASK(3, 0)
+#define FEATURE_VER		GENMASK(7, 4)
+
+#define FEATURE_VER_0		FIELD_PREP(FEATURE_VER, 0)
+
+#define EVT_MODE_BLOCKING	(0x01)
+#define EVT_MODE_TOHEAD		(0x02)
+
+#define FSM_EVT_RET_FAIL	(-1)
+#define FSM_EVT_RET_ONGOING	(0)
+#define FSM_EVT_RET_DONE	(1)
+
+enum mtk_fsm_flag {
+	FSM_F_DFLT = 0,
+	FSM_F_SAP_HS_START	= BIT(0),
+	FSM_F_SAP_HS2_DONE	= BIT(1),
+	FSM_F_MD_HS_START	= BIT(2),
+	FSM_F_MD_HS2_DONE	= BIT(3),
+};
+
+enum mtk_fsm_state {
+	FSM_STATE_INVALID = 0,
+	FSM_STATE_OFF,
+	FSM_STATE_ON,
+	FSM_STATE_BOOTUP,
+	FSM_STATE_READY,
+};
+
+enum mtk_fsm_evt_id {
+	FSM_EVT_STARTUP = 0,
+	FSM_EVT_DEV_RM,
+	FSM_EVT_DEV_ADD,
+	FSM_EVT_MAX
+};
+
+enum mtk_fsm_prio {
+	FSM_PRIO_1 = 1,
+	FSM_PRIO_MAX
+};
+
+/* One slot per transport-plane producer, so that a retried init clears
+ * only its own record.
+ */
+enum mtk_fsm_hif_user {
+	MTK_FSM_HIF_USER_CTRL = 0,
+	MTK_FSM_HIF_USER_CLDMA0,
+	MTK_FSM_HIF_USER_CLDMA1,
+	MTK_FSM_HIF_USER_MAX
+};
+
+struct mtk_fsm_param {
+	enum mtk_fsm_state from;
+	enum mtk_fsm_state to;
+	enum mtk_fsm_evt_id evt_id;
+	enum mtk_fsm_flag fsm_flag;
+};
+
+#define PORT_NAME_LEN 20
+
+enum handshake_info_id {
+	HS_ID_MD = 0,
+	HS_ID_SAP,
+	HS_ID_MAX
+};
+
+struct runtime_feature_info {
+	u8 feature;
+};
+
+struct fsm_hs_info {
+	unsigned char id;
+	void *ctrl_port;
+	char port_name[PORT_NAME_LEN];
+	unsigned int mhccif_ch;
+	unsigned int fsm_flag_hs1;
+	unsigned int fsm_flag_hs2;
+	/* the feature that the device should support */
+	struct runtime_feature_info query_ft_set[FEATURE_CNT];
+	/* Duplicate-HS2 guard only: the in-flight runtime-data skb itself
+	 * is owned by the STARTUP event it was submitted with.
+	 */
+	void *rt_data;
+};
+
+struct mtk_md_fsm {
+	struct mtk_md_dev *mdev;
+	struct task_struct *fsm_handler;
+	struct fsm_hs_info hs_info[HS_ID_MAX];
+	unsigned int hs_done_flag;
+	unsigned long t_flag;
+	u32 last_dev_state;
+	/* last transport-plane init result per producer; any non-zero entry
+	 * refuses READY
+	 */
+	int hif_err[MTK_FSM_HIF_USER_MAX];
+	enum mtk_fsm_state state;
+	unsigned int fsm_flag;
+	struct list_head evtq;
+	/* protect evtq */
+	spinlock_t evtq_lock;
+	/* waitq for fsm blocking submit */
+	wait_queue_head_t evt_waitq;
+	struct list_head post_notifiers;
+	/* protects post_notifiers */
+	struct mutex notifier_lock;
+};
+
+struct mtk_fsm_evt {
+	struct list_head entry;
+	struct kref kref;
+	enum mtk_fsm_evt_id id;
+	unsigned int fsm_flag;
+	int status;
+	unsigned char mode;
+	void *data;
+};
+
+struct mtk_fsm_notifier {
+	struct list_head entry;
+	enum mtk_user_id id;
+	void (*cb)(struct mtk_fsm_param *param, void *data);
+	void *data;
+	enum mtk_fsm_prio prio;
+};
+
+int mtk_fsm_init(struct mtk_md_dev *mdev);
+int mtk_fsm_exit(struct mtk_md_dev *mdev);
+int mtk_fsm_stop(struct mtk_md_dev *mdev);
+void mtk_fsm_hif_err_record(struct mtk_md_dev *mdev, enum mtk_fsm_hif_user user, int err);
+int mtk_fsm_notifier_register(struct mtk_md_dev *mdev, enum mtk_user_id id,
+			      void (*cb)(struct mtk_fsm_param *, void *data),
+			      void *data, enum mtk_fsm_prio prio);
+int mtk_fsm_notifier_unregister(struct mtk_md_dev *mdev, enum mtk_user_id id);
+int mtk_fsm_evt_submit(struct mtk_md_dev *mdev,
+		       enum mtk_fsm_evt_id id, enum mtk_fsm_flag flag,
+		       void *data, unsigned char mode);
+
+#endif /* __MTK_FSM_H__ */
diff --git a/drivers/net/wwan/t9xx/mtk_port.c b/drivers/net/wwan/t9xx/mtk_port.c
index 7fec696bd6db..101ec14fc993 100644
--- a/drivers/net/wwan/t9xx/mtk_port.c
+++ b/drivers/net/wwan/t9xx/mtk_port.c
@@ -626,6 +626,70 @@ int mtk_port_ch_disable(struct mtk_port *port)
 	return ret;
 }
 
+static void mtk_port_disable(struct mtk_port_mngr *port_mngr)
+{
+	struct radix_tree_iter iter;
+	struct mtk_port *port;
+	void __rcu **slot;
+	int tbl_type;
+
+	tbl_type = PORT_TBL_SAP;
+	do {
+		radix_tree_for_each_slot(slot, &port_mngr->port_tbl[tbl_type],
+					 &iter, 0) {
+			port = mtk_port_tbl_slot(&slot, &iter);
+			if (!port)
+				continue;
+			mtk_port_get_ops(port->info.type)->disable(port);
+		}
+	} while (++tbl_type < PORT_TBL_MAX);
+}
+
+void mtk_port_mngr_fsm_state_handler(struct mtk_fsm_param *fsm_param, void *arg)
+{
+	struct mtk_port_mngr *port_mngr;
+
+	if (!fsm_param || !arg)
+		return;
+
+	port_mngr = arg;
+
+	switch (fsm_param->to) {
+	case FSM_STATE_OFF:
+		mtk_port_disable(port_mngr);
+		break;
+	default:
+		break;
+	}
+}
+
+void mtk_port_mngr_fsm_state_handler_late(struct mtk_fsm_param *fsm_param, void *arg)
+{
+	struct mtk_port_mngr *port_mngr;
+	struct mtk_port *port;
+
+	if (!fsm_param || !arg)
+		return;
+
+	port_mngr = arg;
+
+	switch (fsm_param->to) {
+	case FSM_STATE_BOOTUP:
+		if (fsm_param->fsm_flag & FSM_F_MD_HS_START) {
+			port = mtk_port_search_by_id(port_mngr, CCCI_CONTROL_RX);
+			if (port)
+				mtk_port_get_ops(port->info.type)->enable(port);
+		} else if (fsm_param->fsm_flag & FSM_F_SAP_HS_START) {
+			port = mtk_port_search_by_id(port_mngr, CCCI_SAP_CONTROL_RX);
+			if (port)
+				mtk_port_get_ops(port->info.type)->enable(port);
+		}
+		break;
+	default:
+		break;
+	}
+}
+
 int mtk_port_mngr_init(struct mtk_ctrl_blk *ctrl_blk, const struct mtk_port_cfg *port_cfg,
 		       int port_cnt)
 {
diff --git a/drivers/net/wwan/t9xx/mtk_port.h b/drivers/net/wwan/t9xx/mtk_port.h
index 157eda4b4220..d160f73c1834 100644
--- a/drivers/net/wwan/t9xx/mtk_port.h
+++ b/drivers/net/wwan/t9xx/mtk_port.h
@@ -125,6 +125,8 @@ int mtk_port_send_data(struct mtk_port *port, void *data, bool blocking, bool fo
 int mtk_port_status_update(struct mtk_md_dev *mdev, void *data, u32 data_len);
 int mtk_port_ch_enable(struct mtk_port *port);
 int mtk_port_ch_disable(struct mtk_port *port);
+void mtk_port_mngr_fsm_state_handler(struct mtk_fsm_param *fsm_param, void *arg);
+void mtk_port_mngr_fsm_state_handler_late(struct mtk_fsm_param *fsm_param, void *arg);
 int mtk_port_mngr_init(struct mtk_ctrl_blk *ctrl_blk, const struct mtk_port_cfg *port_cfg,
 		       int port_cnt);
 void mtk_port_mngr_exit(struct mtk_ctrl_blk *ctrl_blk);
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_cldma.c b/drivers/net/wwan/t9xx/pcie/mtk_cldma.c
index d8763cdd67da..4893edfebf79 100644
--- a/drivers/net/wwan/t9xx/pcie/mtk_cldma.c
+++ b/drivers/net/wwan/t9xx/pcie/mtk_cldma.c
@@ -27,15 +27,176 @@
 #include "mtk_cldma_drv.h"
 #include "mtk_dev.h"
 
+#define DMA_POOL_NAME_LEN	(64)
 #define WAIT_HWO_ROUND		(10)
 #define WAIT_HWO_TIME		(5)
 #define NO_BUDGET		(0)
 
+static void mtk_cldma_err_work(struct work_struct *work);
+
+static int mtk_cldma_isr(int irq_id, void *param)
+{
+	struct cldma_drv_info *drv_info = param;
+	u32 tx_err, rx_err;
+	struct mtk_md_dev *mdev;
+	u32 tx_done, rx_done;
+	u32 tx_sta, rx_sta;
+	struct txq *txq;
+	struct rxq *rxq;
+	int i;
+
+	mdev = drv_info->mdev;
+	mtk_cldma_get_intr_status(drv_info, &tx_sta, &rx_sta);
+	tx_done = (tx_sta >> QUEUE_XFER_DONE) & 0xFF;
+	rx_done = (rx_sta >> QUEUE_XFER_DONE) & 0xFF;
+	tx_err = (tx_sta >> QUEUE_ERROR) & 0xFF;
+	rx_err = (rx_sta >> QUEUE_ERROR) & 0xFF;
+
+	if (tx_err || rx_err) {
+		dev_err_ratelimited(mdev->dev, "CLDMA%d queue error: TX 0x%x RX 0x%x\n",
+				    drv_info->hif_id, tx_err, rx_err);
+		/* Left masked by mtk_cldma_get_intr_status() until err_work
+		 * has handled the queue: a queue still in error would raise
+		 * it again as soon as it is unmasked.
+		 */
+		for (i = 0; i < HW_QUE_NUM; i++) {
+			if (tx_err & BIT(i))
+				mtk_cldma_clr_intr_status(drv_info, DIR_TX,
+							  i, QUEUE_ERROR);
+			if (rx_err & BIT(i))
+				mtk_cldma_clr_intr_status(drv_info, DIR_RX,
+							  i, QUEUE_ERROR);
+		}
+		atomic_or(tx_err, &drv_info->tx_err_qs);
+		atomic_or(rx_err, &drv_info->rx_err_qs);
+		queue_work(drv_info->wq, &drv_info->err_work);
+	}
+
+	if (tx_done) {
+		for (i = 0; i < HW_QUE_NUM; i++) {
+			/* pairs with smp_store_release() in txq_alloc */
+			txq = smp_load_acquire(&drv_info->txq[i]);
+			if (!(tx_done & BIT(i)) || !txq)
+				continue;
+			queue_work(drv_info->wq, &txq->tx_done_work);
+		}
+	}
+	if (rx_done) {
+		for (i = 0; i < HW_QUE_NUM; i++) {
+			/* pairs with smp_store_release() in rxq_alloc */
+			rxq = smp_load_acquire(&drv_info->rxq[i]);
+			if (!(rx_done & BIT(i)) || !rxq)
+				continue;
+			queue_work(drv_info->wq, &rxq->rx_done_work);
+		}
+	}
+
+	mtk_pci_clear_irq(mdev, drv_info->pci_ext_irq_id);
+	mtk_pci_unmask_irq(mdev, drv_info->pci_ext_irq_id);
+
+	return IRQ_HANDLED;
+}
+
 static const int mtk_cldma_hw_id_tbl[NR_CLDMA] = {
 	[CLDMA0] = CLDMA0_HW_ID,
 	[CLDMA1] = CLDMA1_HW_ID,
 };
 
+static int mtk_cldma_dev_init(struct cldma_dev *cd, int hif_id)
+{
+	char gpd_pool_name[DMA_POOL_NAME_LEN];
+	struct cldma_drv_info *drv_info;
+	const struct cldma_hw_regs *hw_regs;
+	struct mtk_md_dev *mdev;
+	unsigned int flag;
+	int hw_id, ret;
+
+	if (!cd || hif_id >= NR_CLDMA)
+		return -EINVAL;
+
+	if (cd->cldma_drv_info[hif_id])
+		return 0;
+
+	hw_id = mtk_cldma_hw_id_tbl[hif_id];
+	mdev = cd->trans->mdev;
+	drv_info = kzalloc_obj(*drv_info);
+	if (!drv_info)
+		return -ENOMEM;
+
+	drv_info->cd = cd;
+	drv_info->mdev = mdev;
+	drv_info->hif_id = hif_id;
+	drv_info->hw_id = hw_id;
+	drv_info->hw_regs = &mtk_cldma_regs_m9xx;
+
+	hw_regs = drv_info->hw_regs;
+	snprintf(gpd_pool_name, DMA_POOL_NAME_LEN, "cldma%d_gpd_pool_%s",
+		 hw_id, mdev->dev_str);
+	drv_info->gpd_dma_pool = dma_pool_create(gpd_pool_name, mdev->dev,
+						 sizeof(union gpd), 16, 0);
+	if (!drv_info->gpd_dma_pool) {
+		dev_err(mdev->dev, "Failed to alloc gpd dma pool for cldma%d\n", hw_id);
+		ret = -ENOMEM;
+		goto err_free_drv_info;
+	}
+
+	switch (hif_id) {
+	case CLDMA0:
+		drv_info->pci_ext_irq_id = mtk_pci_get_irq_id(mdev, MTK_IRQ_SRC_CLDMA0);
+		drv_info->base_addr = hw_regs->cldma0_base_addr;
+		break;
+	case CLDMA1:
+		drv_info->pci_ext_irq_id = mtk_pci_get_irq_id(mdev, MTK_IRQ_SRC_CLDMA1);
+		drv_info->base_addr = hw_regs->cldma1_base_addr;
+		break;
+	default:
+		ret = -EINVAL;
+		goto err_destroy_gpd_pool;
+	}
+
+	flag = WQ_UNBOUND | WQ_MEM_RECLAIM | WQ_HIGHPRI;
+	drv_info->wq = alloc_workqueue("cldma%d_workq_%s", flag, 0, hw_id, mdev->dev_str);
+	if (!drv_info->wq) {
+		dev_err(mdev->dev, "Failed to alloc work queue for cldma%d\n", hw_id);
+		ret = -ENOMEM;
+		goto err_destroy_gpd_pool;
+	}
+
+	INIT_WORK(&drv_info->err_work, mtk_cldma_err_work);
+	mutex_init(&drv_info->rearm_lock);
+	atomic_set(&drv_info->tx_err_qs, 0);
+	atomic_set(&drv_info->rx_err_qs, 0);
+
+	mtk_cldma_drv_init(drv_info);
+
+	/* mask/clear PCI CLDMA L1 interrupt */
+	mtk_pci_mask_irq(mdev, drv_info->pci_ext_irq_id);
+	mtk_pci_clear_irq(mdev, drv_info->pci_ext_irq_id);
+
+	/* register CLDMA interrupt handler */
+	ret = mtk_pci_register_irq(mdev, drv_info->pci_ext_irq_id, mtk_cldma_isr, drv_info);
+	if (ret)
+		goto err_destroy_wq;
+
+	/* unmask PCI CLDMA L1 interrupt */
+	mtk_pci_unmask_irq(mdev, drv_info->pci_ext_irq_id);
+
+	/* Publish only once drv_info is fully built; pairs with the acquire
+	 * loads in the transfer paths below.
+	 */
+	smp_store_release(&cd->cldma_drv_info[hif_id], drv_info);
+	return 0;
+
+err_destroy_wq:
+	destroy_workqueue(drv_info->wq);
+err_destroy_gpd_pool:
+	dma_pool_destroy(drv_info->gpd_dma_pool);
+err_free_drv_info:
+	kfree(drv_info);
+
+	return ret;
+}
+
 static void mtk_cldma_tx_done_work(struct work_struct *work)
 {
 	struct txq *txq = container_of(work, struct txq, tx_done_work);
@@ -56,6 +217,10 @@ static void mtk_cldma_tx_done_work(struct work_struct *work)
 	txqno = txq->txqno;
 	mdev = drv_info->mdev;
 	trans = drv_info->cd->trans;
+	/* One load for the whole walk: the slot is written only by service
+	 * init and teardown, and teardown cannot run while this worker does.
+	 */
+	srv = trans->trb_srv[trans->srv_cfg[hif_id][txqno]];
 
 again:
 	for (i = 0; i < txq->nr_gpds; i++) {
@@ -93,10 +258,9 @@ static void mtk_cldma_tx_done_work(struct work_struct *work)
 		trb->status = 0;
 		trb->trb_complete(skb);
 
-		/* The service may already have been torn down; completing the
-		 * TRB is still correct, there is just nobody left to wake.
+		/* The service may never have been started; completing the TRB
+		 * is still correct, there is just nobody left to wake.
 		 */
-		srv = trans->trb_srv[trans->srv_cfg[hif_id][txqno]];
 		if (was_starved && srv)
 			wake_up(&srv->trb_waitq);
 	}
@@ -215,15 +379,32 @@ static bool mtk_cldma_rx_check_again(struct rxq *rxq)
 	return true;
 }
 
-/* Point the device at the GPD it should fill next and start the queue.
- * free_idx is owned by mtk_cldma_rx_done_work(), so this may only run
- * from that worker, at a point where every consumed GPD is re-armed.
+/* May only run from mtk_cldma_rx_done_work(), which owns free_idx and is the
+ * only context allowed to program an RX queue.  A work item never runs
+ * concurrently with itself, so keeping the stop here too - rather than in
+ * whoever asked for the restart - serialises it without a lock.
  */
 static void mtk_cldma_rxq_restart(struct cldma_drv_info *drv_info, struct rxq *rxq)
 {
+	int ret;
+
+	ret = mtk_cldma_stop_queue(drv_info, DIR_RX, rxq->rxqno);
+	if (ret) {
+		/* Leave it stopped, with QUEUE_ERROR masked: TRB_CMD_DISABLE
+		 * tears the queue down and has the leak-the-ring handling for
+		 * a stop that timed out.
+		 */
+		dev_err(drv_info->mdev->dev,
+			"RX queue %u stop failed (%d), leaving it stopped\n",
+			rxq->rxqno, ret);
+		return;
+	}
+
 	mtk_cldma_setup_start_addr(drv_info, DIR_RX, rxq->rxqno,
 				   rxq->req_pool[rxq->free_idx].gpd_dma_addr);
 	mtk_cldma_start_queue(drv_info, DIR_RX, rxq->rxqno);
+	/* the ISR left it masked if an error is what asked for the restart */
+	mtk_cldma_unmask_intr(drv_info, DIR_RX, rxq->rxqno, QUEUE_ERROR);
 }
 
 static void mtk_cldma_rx_done_work(struct work_struct *work)
@@ -331,7 +512,7 @@ static void mtk_cldma_rx_done_work(struct work_struct *work)
 	 * not wait, such as a DMA mapping one.
 	 */
 	usleep_range(1000, 2000);
-	if (!atomic_read(&rxq->need_exit))
+	if (!atomic_read(&rxq->need_exit) && !READ_ONCE(drv_info->quiesced))
 		queue_work(drv_info->wq, &rxq->rx_done_work);
 out:
 	mtk_cldma_unmask_intr(drv_info, DIR_RX, rxq->rxqno, QUEUE_XFER_DONE);
@@ -358,6 +539,7 @@ static struct txq *mtk_cldma_txq_alloc(struct cldma_drv_info *drv_info, struct q
 	txq->nr_gpds = txq->que->tx_nr_gpds;
 	atomic_set(&txq->req_budget, txq->que->tx_nr_gpds);
 	spin_lock_init(&txq->ring_lock);
+	txq->is_stopping = false;
 
 	txq->req_pool = kcalloc(txq->nr_gpds, sizeof(*req), GFP_KERNEL);
 	if (!txq->req_pool)
@@ -427,10 +609,13 @@ static void mtk_cldma_rearm_queues(struct cldma_drv_info *drv_info)
 	struct rxq *rxq;
 	int i;
 
-	/* The caller holds rearm_lock from the reset to the end of the re-arm:
-	 * no queue is kicked or resumed while the instance has no addresses.
+	/* The caller holds rearm_lock across the whole re-arm, so the quiesce
+	 * either drains what this queued or makes it return here: no work is
+	 * queued after a quiesce.
 	 */
 	lockdep_assert_held(&drv_info->rearm_lock);
+	if (drv_info->quiesced)
+		return;
 
 	mtk_cldma_drv_init(drv_info);
 
@@ -445,8 +630,12 @@ static void mtk_cldma_rearm_queues(struct cldma_drv_info *drv_info)
 			 * next start_xfer() issue a fresh START.
 			 */
 			req = txq->req_pool + txq->free_idx;
-			if (READ_ONCE(txq->tx_started) &&
-			    !(req->gpd->tx_gpd.gpd_flags & CLDMA_GPD_FLAG_HWO)) {
+			if (txq->is_stopping) {
+				/* Being stopped: restarting it would let the
+				 * device walk buffers the stopper is unmapping.
+				 */
+			} else if (READ_ONCE(txq->tx_started) &&
+				   !(req->gpd->tx_gpd.gpd_flags & CLDMA_GPD_FLAG_HWO)) {
 				WRITE_ONCE(txq->tx_started, false);
 				/* Its XFER_DONE may have been lost in the
 				 * reset; without this free_idx never advances.
@@ -458,7 +647,7 @@ static void mtk_cldma_rearm_queues(struct cldma_drv_info *drv_info)
 			}
 			mtk_cldma_unmask_intr(drv_info, DIR_TX, i, QUEUE_ERROR);
 			mtk_cldma_unmask_intr(drv_info, DIR_TX, i, QUEUE_XFER_DONE);
-			if (READ_ONCE(txq->tx_started))
+			if (READ_ONCE(txq->tx_started) && !txq->is_stopping)
 				mtk_cldma_start_queue(drv_info, DIR_TX, i);
 			spin_unlock(&txq->ring_lock);
 		}
@@ -512,12 +701,32 @@ static void mtk_cldma_txq_free(struct cldma_drv_info *drv_info, u32 txqno)
 	}
 	txq->tx_started = false;
 
+	/* Mask before waiting on anything: a QUEUE_ERROR latched after the
+	 * flushes below would outlive this queue and be acted on for the
+	 * next occupant of the same queue number.
+	 */
+	mtk_cldma_mask_intr(drv_info, DIR_TX, txqno, QUEUE_XFER_DONE);
+	mtk_cldma_mask_intr(drv_info, DIR_TX, txqno, QUEUE_ERROR);
 	irq_id = mtk_pci_get_virq_id(mdev, drv_info->pci_ext_irq_id);
 	synchronize_irq(irq_id);
-	/* flush on-going work */
+	/* flush on-going work, err_work first: it may have loaded this txq
+	 * before it was unpublished above and still be stopping and
+	 * flushing it.
+	 */
+	flush_work(&drv_info->err_work);
 	flush_work(&txq->tx_done_work);
+	/* workers retired by the flushes unmask XFER_DONE on their way out,
+	 * and err_work re-arms QUEUE_ERROR for a queue it handled
+	 */
 	mtk_cldma_mask_intr(drv_info, DIR_TX, txqno, QUEUE_XFER_DONE);
 	mtk_cldma_mask_intr(drv_info, DIR_TX, txqno, QUEUE_ERROR);
+	/* Drop an error latched before that mask, and the err_work it
+	 * queued: the slot is unpublished, so either could only act on the
+	 * next occupant of this number.
+	 */
+	synchronize_irq(irq_id);
+	atomic_andnot(BIT(txqno), &drv_info->tx_err_qs);
+	flush_work(&drv_info->err_work);
 
 	if (ret == -ETIMEDOUT) {
 		/* Still a live DMA target: leak the ring rather than hand it
@@ -525,6 +734,7 @@ static void mtk_cldma_txq_free(struct cldma_drv_info *drv_info, u32 txqno)
 		 */
 		dev_err(mdev->dev, "TX queue %u cannot be stopped, leaking its ring\n",
 			txqno);
+		drv_info->ring_leaked = true;
 		return;
 	}
 
@@ -696,17 +906,35 @@ static void mtk_cldma_rxq_free(struct cldma_drv_info *drv_info, u32 rxqno)
 		mutex_unlock(&drv_info->rearm_lock);
 	}
 
+	/* Mask before waiting on anything: a QUEUE_ERROR latched after the
+	 * flushes below would outlive this queue and restart the next
+	 * occupant of the same queue number.
+	 */
+	mtk_cldma_mask_intr(drv_info, DIR_RX, rxqno, QUEUE_XFER_DONE);
+	mtk_cldma_mask_intr(drv_info, DIR_RX, rxqno, QUEUE_ERROR);
 	irq_id = mtk_pci_get_virq_id(mdev, drv_info->pci_ext_irq_id);
 	synchronize_irq(irq_id);
+	/* flush on-going work, err_work first: it ends by queueing
+	 * rx_done_work, so flushing the per-queue worker first would leave
+	 * it free to queue it again afterwards.
+	 */
+	flush_work(&drv_info->err_work);
 	/* not flush_work(): the worker re-queues itself on a refill failure */
 	cancel_work_sync(&rxq->rx_done_work);
 	/* a cancelled pass would have cleared it on its way out */
 	mtk_cldma_clear_ip_busy(drv_info);
-	/* only now: a worker retired by the cancel unmasks XFER_DONE on its
-	 * way out
+	/* a worker retired by the cancel unmasks XFER_DONE on its way out,
+	 * and a restart re-arms QUEUE_ERROR
 	 */
 	mtk_cldma_mask_intr(drv_info, DIR_RX, rxqno, QUEUE_XFER_DONE);
 	mtk_cldma_mask_intr(drv_info, DIR_RX, rxqno, QUEUE_ERROR);
+	/* Drop an error latched before that mask, and the err_work it
+	 * queued: the slot is unpublished, so either could only act on the
+	 * next occupant of this number.
+	 */
+	synchronize_irq(irq_id);
+	atomic_andnot(BIT(rxqno), &drv_info->rx_err_qs);
+	flush_work(&drv_info->err_work);
 
 	/* The worker can resume or restart the queue between its need_exit
 	 * check and the MMIO write that follows it, so cancel_work_sync() does
@@ -721,6 +949,7 @@ static void mtk_cldma_rxq_free(struct cldma_drv_info *drv_info, u32 rxqno)
 		 */
 		dev_err(mdev->dev, "RX queue %u cannot be stopped, leaking its ring\n",
 			rxqno);
+		drv_info->ring_leaked = true;
 		return;
 	}
 
@@ -771,6 +1000,105 @@ static int mtk_cldma_hw_recovery(struct cldma_drv_info *drv_info, struct txq *tx
 	return 0;
 }
 
+/* Silence the IP's interrupt output as well as the vector: a handler already
+ * past the mask unmasks it again on its way out.  Repeated calls are no-ops,
+ * so the teardown path can run it again without unregistering twice.
+ */
+static void mtk_cldma_drv_quiesce(struct cldma_drv_info *drv_info)
+{
+	struct mtk_md_dev *mdev = drv_info->mdev;
+
+	mutex_lock(&drv_info->rearm_lock);
+	if (drv_info->quiesced) {
+		mutex_unlock(&drv_info->rearm_lock);
+		return;
+	}
+	/* also read by the RX worker: no refill retry outlives the drain */
+	WRITE_ONCE(drv_info->quiesced, true);
+	mutex_unlock(&drv_info->rearm_lock);
+
+	mtk_pci_write32(mdev, drv_info->base_addr + drv_info->hw_regs->reg_cldma_int_mask,
+			LINK_ERROR_VAL);
+	mtk_pci_mask_irq(mdev, drv_info->pci_ext_irq_id);
+	synchronize_irq(mtk_pci_get_virq_id(mdev, drv_info->pci_ext_irq_id));
+	mtk_pci_unregister_irq(mdev, drv_info->pci_ext_irq_id);
+	/* not flush: err_work queues rx_done_work */
+	drain_workqueue(drv_info->wq);
+}
+
+/* Must be called before freeing state the workers dereference: joining the
+ * service kthreads leaves the interrupt and the workqueue running.
+ */
+void mtk_cldma_quiesce(struct mtk_ctrl_trans *trans)
+{
+	struct cldma_drv_info *drv_info;
+	struct cldma_dev *cd = trans->dev;
+	int i;
+
+	if (!cd)
+		return;
+
+	for (i = 0; i < NR_CLDMA; i++) {
+		drv_info = READ_ONCE(cd->cldma_drv_info[i]);
+		if (drv_info)
+			mtk_cldma_drv_quiesce(drv_info);
+	}
+}
+
+static int mtk_cldma_dev_exit(struct cldma_dev *cd, int hif_id)
+{
+	struct cldma_drv_info *drv_info;
+	struct mtk_md_dev *mdev;
+	int i;
+
+	if (!cd || hif_id >= NR_CLDMA)
+		return -EINVAL;
+
+	if (!cd->cldma_drv_info[hif_id])
+		return 0;
+
+	/* free cldma descriptor */
+	drv_info = cd->cldma_drv_info[hif_id];
+	mdev = cd->trans->mdev;
+
+	/* Unpublish before teardown; pairs with the acquire loads of this
+	 * slot. No release is needed, there is no prior store to expose.
+	 */
+	WRITE_ONCE(cd->cldma_drv_info[hif_id], NULL);
+
+	mtk_cldma_drv_quiesce(drv_info);
+	for (i = 0; i < HW_QUE_NUM; i++) {
+		if (drv_info->txq[i])
+			mtk_cldma_txq_free(drv_info, drv_info->txq[i]->txqno);
+		if (drv_info->rxq[i])
+			mtk_cldma_rxq_free(drv_info, drv_info->rxq[i]->rxqno);
+	}
+
+	flush_workqueue(drv_info->wq);
+	destroy_workqueue(drv_info->wq);
+
+	/* Best-effort: reset the IP so it drops its queue state before the
+	 * descriptor memory goes away.  Not guaranteed to stop the engine,
+	 * hence ring_leaked.
+	 */
+	mtk_cldma_drv_reset(drv_info);
+	/* A handler retired by the quiesce may have unmasked the vector on
+	 * its way out, and nothing handles it any more: leave it masked.
+	 */
+	mtk_pci_mask_irq(mdev, drv_info->pci_ext_irq_id);
+
+	if (drv_info->ring_leaked)
+		dev_err(mdev->dev, "CLDMA%d rings leaked\n", drv_info->hw_id);
+	/* A pool with blocks outstanding keeps its pages, so a leaked ring
+	 * stays allocated; only the pool bookkeeping is freed.
+	 */
+	dma_pool_destroy(drv_info->gpd_dma_pool);
+
+	kfree(drv_info);
+
+	return 0;
+}
+
 /* After a re-arm the slot at free_idx may hold a descriptor the device
  * completed but tx_done_work has not reaped yet; a START there parks the
  * engine on HWO=0.  Start at the first slot the device still owns.
@@ -820,6 +1148,12 @@ static int mtk_cldma_start_xfer(struct cldma_drv_info *drv_info, u32 qno)
 	 * names; tx_done_work advances free_idx under the same lock.
 	 */
 	spin_lock(&txq->ring_lock);
+	if (unlikely(txq->is_stopping)) {
+		spin_unlock(&txq->ring_lock);
+		ret = -EPIPE;
+		goto out;
+	}
+
 	if (unlikely(!READ_ONCE(txq->tx_started))) {
 		mtk_cldma_setup_start_addr(drv_info, DIR_TX, qno,
 					   txq->req_pool[mtk_cldma_tx_start_idx(txq)].gpd_dma_addr);
@@ -850,11 +1184,22 @@ int mtk_cldma_init(struct mtk_ctrl_trans *trans)
 
 void mtk_cldma_exit(struct mtk_ctrl_trans *trans)
 {
-	if (!trans->dev)
+	struct cldma_dev *cd = trans->dev;
+	int i;
+
+	if (!cd)
 		return;
 
-	kfree(trans->dev);
+	/* Clear up front so any later submit bails out instead of walking
+	 * freed queues.  Callers hold trans->submit_lock, except the init
+	 * unwind, where trans->available is still false.
+	 */
 	trans->dev = NULL;
+
+	for (i = 0; i < NR_CLDMA; i++)
+		mtk_cldma_dev_exit(cd, i);
+
+	kfree(cd);
 }
 
 static int mtk_cldma_open(struct cldma_dev *cd, struct sk_buff *skb)
@@ -873,7 +1218,8 @@ static int mtk_cldma_open(struct cldma_dev *cd, struct sk_buff *skb)
 		trb->trb_complete(skb);
 		return -EINVAL;
 	}
-	drv_info = cd->cldma_drv_info[que->hif_id];
+	/* pairs with smp_store_release() in mtk_cldma_dev_init */
+	drv_info = smp_load_acquire(&cd->cldma_drv_info[que->hif_id]);
 	if (!drv_info) {
 		ret = -EIO;
 		goto out;
@@ -939,6 +1285,11 @@ static void mtk_cldma_txq_flush(struct cldma_drv_info *drv_info,
 	struct trb *trb;
 	int i;
 
+	/* One load for the whole walk: the slot is written only by service
+	 * init and teardown, and teardown cannot run while this flush does.
+	 */
+	srv = trans->trb_srv[trans->srv_cfg[hif_id][txqno]];
+
 	for (i = 0; i < txq->nr_gpds; i++) {
 		spin_lock(&txq->ring_lock);
 
@@ -967,15 +1318,94 @@ static void mtk_cldma_txq_flush(struct cldma_drv_info *drv_info,
 		trb->status = err;
 		trb->trb_complete(skb);
 
-		/* The service may already have been torn down; completing the
-		 * TRB is still correct, there is just nobody left to wake.
+		/* The service may never have been started; completing the TRB
+		 * is still correct, there is just nobody left to wake.
 		 */
-		srv = trans->trb_srv[trans->srv_cfg[hif_id][txqno]];
 		if (was_starved && srv)
 			wake_up(&srv->trb_waitq);
 	}
 }
 
+static void mtk_cldma_err_tx_one(struct cldma_drv_info *drv_info, u32 qno)
+{
+	struct txq *txq;
+	int ret;
+
+	/* pairs with smp_store_release() in txq_alloc */
+	txq = smp_load_acquire(&drv_info->txq[qno]);
+	if (!txq)
+		return;
+
+	/* Keep the producer out so start_xfer cannot ring the doorbell
+	 * between the stop and the flush.
+	 */
+	spin_lock(&txq->ring_lock);
+	txq->is_stopping = true;
+	spin_unlock(&txq->ring_lock);
+
+	ret = mtk_cldma_stop_queue(drv_info, DIR_TX, qno);
+	/* -ENODEV: the link is dead, nothing is walking the ring */
+	if (ret && ret != -ENODEV) {
+		/* the device may still be walking the ring: unmapping its
+		 * buffers here would leave it writing into unmapped memory.
+		 * is_stopping is left set so nothing submits to it again,
+		 * and QUEUE_ERROR masked until an instance re-arm.
+		 */
+		dev_err(drv_info->mdev->dev,
+			"TX queue %u stop failed (%d), keeping its requests\n",
+			qno, ret);
+		return;
+	}
+
+	spin_lock(&txq->ring_lock);
+	WRITE_ONCE(txq->tx_started, false);
+	spin_unlock(&txq->ring_lock);
+	mtk_cldma_txq_flush(drv_info, txq, -EPIPE);
+
+	spin_lock(&txq->ring_lock);
+	txq->is_stopping = false;
+	spin_unlock(&txq->ring_lock);
+	/* handled: re-arm what the ISR left masked */
+	mtk_cldma_unmask_intr(drv_info, DIR_TX, qno, QUEUE_ERROR);
+}
+
+/* Handed to the worker because it owns free_idx and is the only context
+ * allowed to program an RX queue; a stopped queue raises no further
+ * interrupt, so nothing else would re-arm it.
+ */
+static void mtk_cldma_err_rx_one(struct cldma_drv_info *drv_info, u32 qno)
+{
+	struct rxq *rxq;
+
+	/* pairs with smp_store_release() in rxq_alloc */
+	rxq = smp_load_acquire(&drv_info->rxq[qno]);
+	if (!rxq)
+		return;
+
+	atomic_set(&rxq->need_restart, 1);
+	queue_work(drv_info->wq, &rxq->rx_done_work);
+}
+
+/* The latched bits are consumed up front, so an early exit on one direction
+ * must not swallow the other's error.
+ */
+static void mtk_cldma_err_work(struct work_struct *work)
+{
+	struct cldma_drv_info *drv_info = container_of(work, struct cldma_drv_info, err_work);
+	u32 tx_err, rx_err;
+	int i;
+
+	tx_err = atomic_xchg(&drv_info->tx_err_qs, 0);
+	rx_err = atomic_xchg(&drv_info->rx_err_qs, 0);
+
+	for (i = 0; i < HW_QUE_NUM; i++) {
+		if (tx_err & BIT(i))
+			mtk_cldma_err_tx_one(drv_info, i);
+		if (rx_err & BIT(i))
+			mtk_cldma_err_rx_one(drv_info, i);
+	}
+}
+
 static int mtk_cldma_tx(struct cldma_dev *cd, struct sk_buff *skb)
 {
 	struct trb *trb = (struct trb *)skb->cb;
@@ -988,7 +1418,8 @@ static int mtk_cldma_tx(struct cldma_dev *cd, struct sk_buff *skb)
 	que = xa_load(&cd->trans->queue_tbl, trb->channel_id & 0xFFFF);
 	if (unlikely(!que))
 		return -EPIPE;
-	drv_info = cd->cldma_drv_info[que->hif_id];
+	/* pairs with smp_store_release() in mtk_cldma_dev_init */
+	drv_info = smp_load_acquire(&cd->cldma_drv_info[que->hif_id]);
 	if (unlikely(!drv_info))
 		return -EPIPE;
 	txq = drv_info->txq[que->txqno];
@@ -998,6 +1429,13 @@ static int mtk_cldma_tx(struct cldma_dev *cd, struct sk_buff *skb)
 	mdev = drv_info->mdev;
 
 	ret = mtk_cldma_start_xfer(drv_info, que->txqno);
+	/* The queue is being stopped and nothing was kicked: the requests in
+	 * the ring are the ones recovery is keeping, so this must not fall
+	 * into the flush below and unmap them.
+	 */
+	if (unlikely(ret == -EPIPE))
+		return ret;
+
 	if (unlikely(ret)) {
 		dev_err(mdev->dev, "Failed to trigger cldma tx\n");
 		/* A failed start does not mean the engine is idle - recovery
@@ -1035,7 +1473,8 @@ static int mtk_cldma_close(struct cldma_dev *cd, struct sk_buff *skb)
 		trb->trb_complete(skb);
 		return -EPIPE;
 	}
-	drv_info = cd->cldma_drv_info[que->hif_id];
+	/* pairs with smp_store_release() in mtk_cldma_dev_init */
+	drv_info = smp_load_acquire(&cd->cldma_drv_info[que->hif_id]);
 	if (unlikely(!drv_info)) {
 		trb->status = -EPIPE;
 		trb->trb_complete(skb);
@@ -1096,7 +1535,8 @@ int mtk_cldma_submit_tx(void *dev, struct sk_buff *skb)
 	que = xa_load(&cd->trans->queue_tbl, trb->channel_id & 0xFFFF);
 	if (unlikely(!que))
 		return -EINVAL;
-	drv_info = cd->cldma_drv_info[que->hif_id];
+	/* pairs with smp_store_release() in mtk_cldma_dev_init */
+	drv_info = smp_load_acquire(&cd->cldma_drv_info[que->hif_id]);
 	if (unlikely(!drv_info))
 		return -EINVAL;
 
@@ -1106,6 +1546,14 @@ int mtk_cldma_submit_tx(void *dev, struct sk_buff *skb)
 
 	spin_lock(&txq->ring_lock);
 
+	/* Publishing another HWO descriptor into a ring the device may still
+	 * be walking is exactly what the stop is trying to prevent.
+	 */
+	if (unlikely(txq->is_stopping)) {
+		spin_unlock(&txq->ring_lock);
+		return -EPIPE;
+	}
+
 	if (!atomic_read(&txq->req_budget)) {
 		spin_unlock(&txq->ring_lock);
 		return -EAGAIN;
@@ -1145,7 +1593,8 @@ int mtk_cldma_get_tx_budget(void *dev, enum mtk_hif_id hif_id, u32 qno)
 	if (unlikely(hif_id >= NR_CLDMA || qno >= HW_QUE_NUM || !cd))
 		return -EINVAL;
 
-	drv_info = cd->cldma_drv_info[hif_id];
+	/* pairs with smp_store_release() in mtk_cldma_dev_init */
+	drv_info = smp_load_acquire(&cd->cldma_drv_info[hif_id]);
 	if (!drv_info)
 		return -EINVAL;
 	txq = drv_info->txq[qno];
@@ -1177,6 +1626,38 @@ int mtk_cldma_trb_process(void *dev, struct sk_buff *skb)
 	return trb_act_tbl[trb->cmd](cd, skb);
 }
 
+void mtk_cldma_fsm_state_listener(struct mtk_fsm_param *param, struct mtk_ctrl_trans *trans)
+{
+	struct cldma_dev *cd = trans->dev;
+	enum mtk_fsm_hif_user user;
+	enum mtk_hif_id hif_id;
+	int ret;
+
+	switch (param->to) {
+	case FSM_STATE_BOOTUP:
+		if (param->fsm_flag & FSM_F_SAP_HS_START) {
+			hif_id = CLDMA0;
+			user = MTK_FSM_HIF_USER_CLDMA0;
+		} else if (param->fsm_flag & FSM_F_MD_HS_START) {
+			hif_id = CLDMA1;
+			user = MTK_FSM_HIF_USER_CLDMA1;
+		} else {
+			break;
+		}
+
+		ret = mtk_cldma_dev_init(cd, hif_id);
+		if (ret)
+			dev_err(trans->mdev->dev, "Failed to init CLDMA%d: %d\n", hif_id, ret);
+		/* Record the success too: HS1 is retried, so a later good init
+		 * has to clear what the failed attempt left behind.
+		 */
+		mtk_fsm_hif_err_record(trans->mdev, user, ret);
+		break;
+	default:
+		break;
+	}
+}
+
 int mtk_cldma_check_ch_cfg(void *dev, struct queue_info *que)
 {
 	struct cldma_drv_info *drv_info;
@@ -1186,7 +1667,8 @@ int mtk_cldma_check_ch_cfg(void *dev, struct queue_info *que)
 	struct rxq *rxq;
 
 	mdev = cd->trans->mdev;
-	drv_info = cd->cldma_drv_info[que->hif_id];
+	/* pairs with smp_store_release() in mtk_cldma_dev_init */
+	drv_info = smp_load_acquire(&cd->cldma_drv_info[que->hif_id]);
 
 	if (!drv_info) {
 		dev_err(mdev->dev, "CLDMA%d has not been initialized\n",
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_cldma.h b/drivers/net/wwan/t9xx/pcie/mtk_cldma.h
index 8abde07ebd55..f6d26b80589f 100644
--- a/drivers/net/wwan/t9xx/pcie/mtk_cldma.h
+++ b/drivers/net/wwan/t9xx/pcie/mtk_cldma.h
@@ -103,6 +103,12 @@ struct txq {
 	u32 wr_idx;
 	u32 free_idx;
 	bool tx_started;
+	/* Set by err_work while it stops this queue, and left set if the
+	 * stop failed: the device may still be walking the ring, so new
+	 * requests are refused with -EPIPE and the ones already queued are
+	 * kept.  Read under ring_lock by the producer.
+	 */
+	bool is_stopping;
 };
 
 struct cldma_dev {
@@ -111,6 +117,7 @@ struct cldma_dev {
 };
 
 int mtk_cldma_init(struct mtk_ctrl_trans *trans);
+void mtk_cldma_quiesce(struct mtk_ctrl_trans *trans);
 void mtk_cldma_exit(struct mtk_ctrl_trans *trans);
 int mtk_cldma_submit_tx(void *dev, struct sk_buff *skb);
 int mtk_cldma_get_tx_budget(void *dev, enum mtk_hif_id hif_id, u32 qno);
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_cldma_drv.h b/drivers/net/wwan/t9xx/pcie/mtk_cldma_drv.h
index f7b5018d3a73..b32301b0240a 100644
--- a/drivers/net/wwan/t9xx/pcie/mtk_cldma_drv.h
+++ b/drivers/net/wwan/t9xx/pcie/mtk_cldma_drv.h
@@ -78,8 +78,17 @@ struct cldma_drv_info {
 	struct dma_pool *gpd_dma_pool;
 	struct workqueue_struct *wq;
 	const struct cldma_hw_regs *hw_regs;
+	struct work_struct err_work;
+	atomic_t tx_err_qs;
+	atomic_t rx_err_qs;
+	/* a ring could not be stopped and was leaked on free */
+	bool ring_leaked;
+	/* this instance's interrupt and workers have already been retired;
+	 * makes the quiesce safe to repeat on the teardown path
+	 */
+	bool quiesced;
 	/* serialises the instance reset and re-arm against queue kicks and
-	 * RX resume/restart: no queue is kicked while it has no address
+	 * RX resume/restart, and re-arming against setting quiesced
 	 */
 	struct mutex rearm_lock;
 };
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_pci.c b/drivers/net/wwan/t9xx/pcie/mtk_pci.c
index 68e39ea4f69d..8a5b4a143ed2 100644
--- a/drivers/net/wwan/t9xx/pcie/mtk_pci.c
+++ b/drivers/net/wwan/t9xx/pcie/mtk_pci.c
@@ -12,6 +12,7 @@
 #include <linux/module.h>
 
 #include "mtk_dev.h"
+#include "mtk_fsm.h"
 #include "mtk_trans_ctrl.h"
 #include "mtk_pci.h"
 #include "mtk_pci_reg.h"
@@ -858,18 +859,41 @@ static int mtk_pci_dev_init(struct mtk_md_dev *mdev)
 {
 	int ret;
 
-	ret = mtk_trans_ctrl_init(mdev);
+	ret = mtk_fsm_init(mdev);
 	if (ret) {
-		dev_err(mdev->dev, "Failed to initialize control plane: %d\n", ret);
+		dev_err(mdev->dev, "Failed to initialize FSM: %d\n", ret);
 		return ret;
 	}
 
+	ret = mtk_trans_ctrl_init(mdev);
+	if (ret)
+		goto free_fsm;
+
 	return 0;
+free_fsm:
+	mtk_fsm_exit(mdev);
+	return ret;
 }
 
 static void mtk_pci_dev_exit(struct mtk_md_dev *mdev)
 {
+	int ret;
+
+	ret = mtk_fsm_evt_submit(mdev, FSM_EVT_DEV_RM, 0, NULL,
+				 EVT_MODE_BLOCKING | EVT_MODE_TOHEAD);
+	if (ret < 0)
+		dev_err(mdev->dev, "FSM DEV_RM failed: %d, forcing cleanup\n", ret);
+	/* Close the event gate and park the FSM thread before the transport
+	 * plane it drives is torn down.
+	 */
+	mtk_fsm_stop(mdev);
 	mtk_trans_ctrl_exit(mdev);
+	mtk_fsm_exit(mdev);
+}
+
+static int mtk_pci_dev_start(struct mtk_md_dev *mdev)
+{
+	return mtk_fsm_evt_submit(mdev, FSM_EVT_DEV_ADD, 0, NULL, 0);
 }
 
 static int mtk_pci_probe(struct pci_dev *pdev, const struct pci_device_id *id)
@@ -960,8 +984,17 @@ static int mtk_pci_probe(struct pci_dev *pdev, const struct pci_device_id *id)
 	pci_set_master(pdev);
 	mtk_pci_unmask_irq(mdev, priv->mhccif_irq_id);
 
+	ret = mtk_pci_dev_start(mdev);
+	if (ret) {
+		dev_err(mdev->dev, "Failed to start dev.\n");
+		goto clear_master;
+	}
+
 	return 0;
 
+clear_master:
+	pci_clear_master(pdev);
+	pci_load_and_free_saved_state(pdev, &priv->saved_state);
 dev_exit:
 	mtk_pci_dev_exit(mdev);
 free_irq:
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c b/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c
index 8b61c3eac035..d87cb61d5326 100644
--- a/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c
+++ b/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c
@@ -480,19 +480,27 @@ int mtk_pcie_hif_exit(struct mtk_md_dev *mdev)
 
 	trans = ctrl_blk->ctrl_hw_priv;
 
+	/* Hold submit_lock across the whole teardown: late submitters either
+	 * see available and finish before the teardown starts, or block here
+	 * and then bail out on !available. Also makes this exit idempotent,
+	 * so both the FSM listener and device removal may call it.
+	 */
 	mutex_lock(&trans->submit_lock);
+	if (!trans->available) {
+		mutex_unlock(&trans->submit_lock);
+		return 0;
+	}
 	trans->available = false;
-	mutex_unlock(&trans->submit_lock);
-
+	/* The CLDMA interrupt and its workers read trans->trb_srv[] too, so
+	 * joining the service threads below does not cover them.
+	 */
+	mtk_cldma_quiesce(trans);
 	/* Join the service threads before freeing what they dereference: they
 	 * read trans->dev without a lock, so clearing it cannot stop a
 	 * consumer that has already loaded the pointer.
 	 */
 	mtk_ctrl_trb_srv_exit(trans);
 	mtk_cldma_exit(trans);
-
-	/* Late submitters may still hold the lock and walk the tree. */
-	mutex_lock(&trans->submit_lock);
 	mtk_ctrl_remove_queue_tbl(trans);
 	mutex_unlock(&trans->submit_lock);
 
@@ -573,6 +581,15 @@ int mtk_pcie_hif_submit_skb(struct mtk_md_dev *mdev, struct sk_buff *skb, bool f
 	return ret;
 }
 
+void mtk_pcie_hif_fsm_indication(struct mtk_md_dev *mdev, struct mtk_fsm_param *param)
+{
+	struct mtk_ctrl_blk *ctrl_blk = mdev->ctrl_blk;
+	struct mtk_ctrl_trans *trans;
+
+	trans = ctrl_blk->ctrl_hw_priv;
+	mtk_cldma_fsm_state_listener(param, trans);
+}
+
 int mtk_pcie_hif_cmd_func(struct mtk_md_dev *mdev, int cmd, void *data)
 {
 	struct mtk_ctrl_blk *ctrl_blk = mdev->ctrl_blk;
@@ -635,6 +652,13 @@ int mtk_trans_ctrl_init(struct mtk_md_dev *mdev)
 
 int mtk_trans_ctrl_exit(struct mtk_md_dev *mdev)
 {
+	/* FSM_STATE_OFF normally tears the HIF down. If that never ran, the
+	 * trb kthreads and the CLDMA irq callback would outlive the devm
+	 * allocations they point at, so do it here. mtk_pcie_hif_exit() is
+	 * idempotent under trans->submit_lock, so calling it again is safe.
+	 */
+	mtk_pcie_hif_exit(mdev);
+
 	mtk_ctrl_exit(mdev);
 
 	return 0;
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.h b/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.h
index ee036f01a875..960ccc9fc706 100644
--- a/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.h
+++ b/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.h
@@ -75,9 +75,12 @@ struct trb_srv {
 	struct task_struct *trb_thread;
 };
 
+struct mtk_fsm_param;
+
 int mtk_pcie_hif_init(struct mtk_md_dev *mdev);
 int mtk_pcie_hif_exit(struct mtk_md_dev *mdev);
 int mtk_pcie_hif_submit_skb(struct mtk_md_dev *mdev, struct sk_buff *skb, bool force_send);
+void mtk_pcie_hif_fsm_indication(struct mtk_md_dev *mdev, struct mtk_fsm_param *param);
 int mtk_pcie_hif_cmd_func(struct mtk_md_dev *mdev, int cmd, void *data);
 int mtk_trans_ctrl_init(struct mtk_md_dev *mdev);
 int mtk_trans_ctrl_exit(struct mtk_md_dev *mdev);

-- 
2.34.1

