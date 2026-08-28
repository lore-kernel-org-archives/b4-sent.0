From: Jack Wu <jackbb_wu@compal.com>
Date: Fri, 28 Aug 2026 17:17:22 +0800
Subject: [PATCH v7 5/6] net: wwan: t9xx: Add FSM thread
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260828-t9xx_driver_v1-v7-5-bf8f6074d88a@compal.com>
References: <20260828-t9xx_driver_v1-v7-0-bf8f6074d88a@compal.com>
In-Reply-To: <20260828-t9xx_driver_v1-v7-0-bf8f6074d88a@compal.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787908678; l=54113;
 i=jackbb_wu@compal.com; s=20260526; h=from:subject:message-id;
 bh=8JDj2ZdZLe5k/m0BcXhSXjmnzRph/hi/5UQbnrD11Og=;
 b=RPAtTrWC1oxrFY3K19cXiT/PZY6akY1jmyUPre+zjyCfNePow9C8YUfziL2DzzCSsG3DK9hzZ
 TjfR8tpOBwKCz0ZhaNhEqx3buYz5H/rTX9O1UY2Q4lYJDe9XsO9ki0x
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
before and after the state transition.

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
allocates DMA pools, creates a workqueue, and registers
the MSI-X IRQ; mtk_cldma_dev_exit() tears them down on
FSM_STATE_OFF.

Signed-off-by: Jack Wu <jackbb_wu@compal.com>
---
 drivers/net/wwan/t9xx/Makefile                  |    3 +-
 drivers/net/wwan/t9xx/mtk_ctrl_plane.c          |   51 ++
 drivers/net/wwan/t9xx/mtk_ctrl_plane.h          |    2 +
 drivers/net/wwan/t9xx/mtk_dev.h                 |    1 +
 drivers/net/wwan/t9xx/mtk_fsm.c                 | 1006 +++++++++++++++++++++++
 drivers/net/wwan/t9xx/mtk_fsm.h                 |  144 ++++
 drivers/net/wwan/t9xx/mtk_port.c                |   66 ++
 drivers/net/wwan/t9xx/mtk_port.h                |    2 +
 drivers/net/wwan/t9xx/mtk_utility.h             |   33 +
 drivers/net/wwan/t9xx/pcie/mtk_cldma.c          |  238 +++++-
 drivers/net/wwan/t9xx/pcie/mtk_cldma_drv_m9xx.h |    1 -
 drivers/net/wwan/t9xx/pcie/mtk_pci.c            |   26 +-
 drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c     |   23 +
 13 files changed, 1589 insertions(+), 7 deletions(-)

diff --git a/drivers/net/wwan/t9xx/Makefile b/drivers/net/wwan/t9xx/Makefile
index db3b1aa1928b..75760b2039dc 100644
--- a/drivers/net/wwan/t9xx/Makefile
+++ b/drivers/net/wwan/t9xx/Makefile
@@ -10,4 +10,5 @@ mtk_t9xx-y := \
 	mtk_dev.o \
 	mtk_ctrl_plane.o \
 	mtk_port.o \
-	mtk_port_io.o
+	mtk_port_io.o \
+	mtk_fsm.o
diff --git a/drivers/net/wwan/t9xx/mtk_ctrl_plane.c b/drivers/net/wwan/t9xx/mtk_ctrl_plane.c
index 59e69b5e3efa..2f9f19680e73 100644
--- a/drivers/net/wwan/t9xx/mtk_ctrl_plane.c
+++ b/drivers/net/wwan/t9xx/mtk_ctrl_plane.c
@@ -5,10 +5,51 @@
  */
 
 #include <linux/device.h>
+#include <linux/freezer.h>
+#include <linux/kthread.h>
+#include <linux/list.h>
+#include <linux/pm_runtime.h>
+#include <linux/sched.h>
+#include <linux/wait.h>
 
 #include "mtk_ctrl_plane.h"
 #include "mtk_port.h"
 
+#define TAG "CTRL"
+
+static void mtk_ctrl_trans_fsm_state_handler(struct mtk_fsm_param *param,
+					     struct mtk_ctrl_blk *ctrl_blk)
+{
+	struct mtk_md_dev *mdev = ctrl_blk->mdev;
+	int ret;
+
+	switch (param->to) {
+	case FSM_STATE_OFF:
+		ctrl_blk->ops->exit(mdev);
+		ctrl_blk->ops->fsm_indication(mdev, param);
+		break;
+	case FSM_STATE_ON:
+		ret = ctrl_blk->ops->init(mdev);
+		if (ret) {
+			dev_err(mdev->dev, "Failed to init HIF: %d\n", ret);
+			break;
+		}
+		fallthrough;
+	default:
+		ctrl_blk->ops->fsm_indication(mdev, param);
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
+
 /**
  * mtk_ctrl_init() - Initialize the control plane block.
  * @mdev: Pointer to the MTK modem device.
@@ -39,8 +80,17 @@ int mtk_ctrl_init(struct mtk_md_dev *mdev, struct mtk_ctrl_hif_ops *ops, struct
 	if (err)
 		goto err_free_mem;
 
+	err = mtk_fsm_notifier_register(mdev, MTK_USER_CTRL, mtk_ctrl_fsm_state_listener,
+					ctrl_blk, FSM_PRIO_1, false);
+	if (err) {
+		dev_err(mdev->dev, "Fail to register fsm notification(ret = %d)\n", err);
+		goto err_port_exit;
+	}
+
 	return 0;
 
+err_port_exit:
+	mtk_port_mngr_exit(ctrl_blk);
 err_free_mem:
 	return err;
 }
@@ -57,6 +107,7 @@ void mtk_ctrl_exit(struct mtk_md_dev *mdev)
 {
 	struct mtk_ctrl_blk *ctrl_blk = mdev->ctrl_blk;
 
+	mtk_fsm_notifier_unregister(mdev, MTK_USER_CTRL);
 	mtk_port_mngr_exit(ctrl_blk);
 	mdev->ctrl_blk = NULL;
 }
diff --git a/drivers/net/wwan/t9xx/mtk_ctrl_plane.h b/drivers/net/wwan/t9xx/mtk_ctrl_plane.h
index d7fcccde8a1b..92817e92a2e4 100644
--- a/drivers/net/wwan/t9xx/mtk_ctrl_plane.h
+++ b/drivers/net/wwan/t9xx/mtk_ctrl_plane.h
@@ -10,6 +10,7 @@
 #include <linux/skbuff.h>
 
 #include "mtk_dev.h"
+#include "mtk_fsm.h"
 
 #define Q_MTU_2K			(0x800)
 #define Q_MTU_3_5K			(0xE00)
@@ -62,6 +63,7 @@ struct mtk_ctrl_hif_ops {
 	int (*init)(struct mtk_md_dev *mdev);
 	int (*exit)(struct mtk_md_dev *mdev);
 	int (*submit_skb)(struct mtk_md_dev *mdev, struct sk_buff *skb, bool force_send);
+	void (*fsm_indication)(struct mtk_md_dev *mdev, struct mtk_fsm_param *param);
 	int (*send_cmd)(struct mtk_md_dev *mdev, int cmd, void *data);
 };
 
diff --git a/drivers/net/wwan/t9xx/mtk_dev.h b/drivers/net/wwan/t9xx/mtk_dev.h
index 9843171fe2ae..b4777b7c5d49 100644
--- a/drivers/net/wwan/t9xx/mtk_dev.h
+++ b/drivers/net/wwan/t9xx/mtk_dev.h
@@ -59,6 +59,7 @@ struct mtk_md_dev {
 	u32 hw_ver;
 	char dev_str[MTK_DEV_STR_LEN];
 	struct mtk_ctrl_blk *ctrl_blk;
+	struct mtk_md_fsm *fsm;
 };
 
 static inline u32 mtk_dev_get_dev_state(struct mtk_md_dev *mdev)
diff --git a/drivers/net/wwan/t9xx/mtk_fsm.c b/drivers/net/wwan/t9xx/mtk_fsm.c
new file mode 100644
index 000000000000..724ea76cdbdc
--- /dev/null
+++ b/drivers/net/wwan/t9xx/mtk_fsm.c
@@ -0,0 +1,1006 @@
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
+#include <linux/skbuff.h>
+#include <linux/wait.h>
+
+#include "mtk_fsm.h"
+#include "mtk_port.h"
+#include "mtk_port_io.h"
+#include "mtk_utility.h"
+
+#define EVT_TF_GATECLOSED (1)
+#define MTK_FSM_INFO_LEN	(64)
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
+	DEV_CFG_NORMAL = 0,
+	DEV_CFG_MD_ONLY,
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
+enum query_runtime_feature_id {
+	QUERY_RTFT_ID_MD_PORT_ENUM = 0,
+	QUERY_RTFT_ID_SAP_PORT_ENUM = 1,
+	QUERY_RTFT_ID_MD_PORT_CFG = 2,
+	QUERY_RTFT_ID_MAX
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
+};
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
+		*cur_ft_spt = RTFT_TYPE_NOT_EXIST;
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
+static int mtk_fsm_parse_hs2_msg(struct fsm_hs_info *hs_info)
+{
+	struct mtk_md_fsm *fsm = container_of(hs_info, struct mtk_md_fsm, hs_info[hs_info->id]);
+	char *rt_data = ((struct sk_buff *)hs_info->rt_data)->data;
+	enum runtime_feature_support_type cur_ft_spt;
+	struct runtime_feature_entry *rtft_entry;
+	unsigned int ft_id, offset, data_len;
+	int ret = 0;
+
+	offset = sizeof(struct feature_query);
+	for (ft_id = 0; ft_id < FEATURE_CNT; ft_id++) {
+		if (offset + sizeof(*rtft_entry) > hs_info->rt_data_len)
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
+		if (data_len > hs_info->rt_data_len - offset - sizeof(*rtft_entry))
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
+		dev_err((fsm->mdev)->dev, "Unable to handle mistake hs2 msg, ft_id=%d\n", ft_id);
+		ret = -EPROTO;
+	}
+
+	return ret;
+}
+
+static int mtk_fsm_append_rtft_entries(struct mtk_md_dev *mdev, void *feature_data,
+				       unsigned int *len, struct fsm_hs_info *hs_info)
+{
+	char *rt_data = ((struct sk_buff *)hs_info->rt_data)->data;
+	struct runtime_feature_entry *rtft_entry;
+	int ft_id, ret = 0, rtdata_len = 0;
+	struct feature_query *ft_query;
+
+	ft_query = (struct feature_query *)rt_data;
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
+static int mtk_fsm_send_hs3_msg(struct fsm_hs_info *hs_info)
+{
+	struct mtk_md_fsm *fsm = container_of(hs_info, struct mtk_md_fsm, hs_info[hs_info->id]);
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
+	ret = mtk_fsm_append_rtft_entries(fsm->mdev,
+					  skb->data + sizeof(*ctrl_msg_h),
+					  &data_len, hs_info);
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
+static int mtk_fsm_sap_ctrl_msg_handler(void *__fsm, struct sk_buff *skb)
+{
+	struct ctrl_msg_header *ctrl_msg_h;
+	struct mtk_md_fsm *fsm = __fsm;
+	struct fsm_hs_info *hs_info;
+	int ret;
+
+	if (skb->len < sizeof(*ctrl_msg_h)) {
+		dev_kfree_skb(skb);
+		return -EINVAL;
+	}
+
+	ctrl_msg_h = (struct ctrl_msg_header *)skb->data;
+	skb_pull(skb, sizeof(*ctrl_msg_h));
+
+	hs_info = &fsm->hs_info[HS_ID_SAP];
+	if (le32_to_cpu(ctrl_msg_h->id) != CTRL_MSG_HS2) {
+		dev_kfree_skb(skb);
+		return -EPROTO;
+	}
+
+	if (hs_info->rt_data) {
+		dev_warn(fsm->mdev->dev, "Duplicate SAP HS2, dropping\n");
+		dev_kfree_skb(skb);
+		return 0;
+	}
+
+	hs_info->rt_data = skb;
+	hs_info->rt_data_len = skb->len;
+	ret = mtk_fsm_evt_submit(fsm->mdev, FSM_EVT_STARTUP,
+				 hs_info->fsm_flag_hs2, hs_info, sizeof(*hs_info), 0);
+	if (ret == FSM_EVT_RET_FAIL) {
+		dev_kfree_skb(skb);
+		hs_info->rt_data = NULL;
+	}
+
+	return 0;
+}
+
+static int mtk_fsm_md_ctrl_msg_handler(void *__fsm, struct sk_buff *skb)
+{
+	struct ctrl_msg_header *ctrl_msg_h;
+	struct mtk_md_fsm *fsm = __fsm;
+	struct fsm_hs_info *hs_info;
+	bool consumed_skb = false;
+	int ret;
+
+	if (skb->len < sizeof(*ctrl_msg_h)) {
+		dev_kfree_skb(skb);
+		return -EINVAL;
+	}
+
+	ctrl_msg_h = (struct ctrl_msg_header *)skb->data;
+	hs_info = &fsm->hs_info[HS_ID_MD];
+	switch (le32_to_cpu(ctrl_msg_h->id)) {
+	case CTRL_MSG_HS2:
+		if (hs_info->rt_data) {
+			dev_warn(fsm->mdev->dev, "Duplicate MD HS2, dropping\n");
+			break;
+		}
+		skb_pull(skb, sizeof(*ctrl_msg_h));
+		hs_info->rt_data = skb;
+		hs_info->rt_data_len = skb->len;
+		ret = mtk_fsm_evt_submit(fsm->mdev, FSM_EVT_STARTUP,
+					 hs_info->fsm_flag_hs2, hs_info, sizeof(*hs_info), 0);
+		if (ret != FSM_EVT_RET_FAIL)
+			consumed_skb = true;
+		break;
+	default:
+		dev_err(fsm->mdev->dev, "Invalid ctrl msg id\n");
+	}
+
+	if (!consumed_skb) {
+		dev_kfree_skb(skb);
+		hs_info->rt_data = NULL;
+	}
+
+	return 0;
+}
+
+static int (*ctrl_msg_handler[HS_ID_MAX])(void *__fsm, struct sk_buff *skb) = {
+	[HS_ID_MD] = mtk_fsm_md_ctrl_msg_handler,
+	[HS_ID_SAP] = mtk_fsm_sap_ctrl_msg_handler,
+};
+
+static void mtk_fsm_idle_evt_handler(struct mtk_md_dev *mdev,
+				     u32 dev_state, struct mtk_md_fsm *fsm)
+{
+	u32 dev_cfg = dev_state >> DEVICE_CFG_SHIFT & DEVICE_CFG_REGION_MASK;
+	int hs_id;
+
+	if (dev_cfg == DEV_CFG_MD_ONLY)
+		fsm->hs_done_flag = FSM_F_MD_HS_START | FSM_F_MD_HS2_DONE;
+	else
+		fsm->hs_done_flag = FSM_HS_START_MASK | FSM_HS2_DONE_MASK;
+
+	mtk_fsm_evt_submit(mdev, FSM_EVT_STARTUP, FSM_F_DFLT, NULL, 0, 0);
+
+	for (hs_id = 0; hs_id < HS_ID_MAX; hs_id++)
+		mtk_dev_unmask_dev_evt(mdev, fsm->hs_info[hs_id].mhccif_ch);
+}
+
+static int mtk_fsm_early_bootup_handler(u32 status, void *__fsm)
+{
+	struct mtk_md_fsm *fsm = __fsm;
+	struct mtk_md_dev *mdev;
+	u32 dev_state, dev_stage;
+
+	mdev = fsm->mdev;
+	mtk_dev_mask_dev_evt(mdev, status);
+	mtk_dev_clear_dev_evt(mdev, status);
+
+	dev_state = mtk_dev_get_dev_state(mdev);
+	dev_stage = dev_state & REGION_BITMASK;
+	if (dev_stage >= DEV_STAGE_MAX) {
+		dev_err(mdev->dev, "Invalid dev state 0x%x\n", dev_state);
+		return -ENXIO;
+	}
+
+	if (dev_state == fsm->last_dev_state)
+		goto exit;
+	fsm->last_dev_state = dev_state;
+
+	if (dev_stage == DEV_STAGE_IDLE)
+		mtk_fsm_idle_evt_handler(mdev, dev_state, fsm);
+
+exit:
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
+						ctrl_msg_handler[hs_info->id], fsm);
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
+	char fsm_info[MTK_FSM_INFO_LEN];
+	struct mtk_fsm_notifier *nt;
+	struct mtk_fsm_param param;
+
+	param.from = fsm->state;
+	param.to = to_state;
+	param.evt_id = event ? event->id : FSM_EVT_MAX;
+	param.fsm_flag = event ? event->fsm_flag : FSM_F_DFLT;
+
+	mutex_lock(&fsm->notifier_lock);
+	list_for_each_entry(nt, &fsm->pre_notifiers, entry)
+		nt->cb(&param, nt->data);
+
+	fsm->state = to_state;
+	fsm->fsm_flag |= event ? event->fsm_flag : FSM_F_DFLT;
+
+	snprintf(fsm_info, MTK_FSM_INFO_LEN,
+		 "state=%d, fsm_flag=0x%x", to_state, fsm->fsm_flag);
+	mtk_uevent_notify(fsm->mdev->dev, MTK_UEVENT_FSM, fsm_info);
+
+	list_for_each_entry(nt, &fsm->post_notifiers, entry)
+		nt->cb(&param, nt->data);
+	mutex_unlock(&fsm->notifier_lock);
+}
+
+static int mtk_fsm_startup_act(struct mtk_md_fsm *fsm, struct mtk_fsm_evt *event)
+{
+	enum mtk_fsm_state to_state = FSM_STATE_BOOTUP;
+	struct fsm_hs_info *hs_info = event->data;
+	struct mtk_md_dev *mdev = fsm->mdev;
+	int ret = 0;
+
+	if (fsm->state != FSM_STATE_ON && fsm->state != FSM_STATE_BOOTUP) {
+		ret = -EPROTO;
+		goto free_rt_data;
+	}
+
+	if (fsm->state != FSM_STATE_BOOTUP) {
+		mtk_fsm_switch_state(fsm, to_state, event);
+		return 0;
+	}
+
+	if (event->fsm_flag & FSM_HS_START_MASK) {
+		mtk_fsm_switch_state(fsm, to_state, event);
+
+		ret = mtk_fsm_ctrl_ch_start(fsm, hs_info, O_NONBLOCK);
+		if (!ret)
+			ret = mtk_fsm_send_hs1_msg(hs_info);
+		if (ret)
+			goto hs_err;
+	} else if (event->fsm_flag & FSM_HS2_DONE_MASK) {
+		ret = mtk_fsm_parse_hs2_msg(hs_info);
+		if (!ret)
+			ret = mtk_fsm_send_hs3_msg(hs_info);
+		dev_kfree_skb(hs_info->rt_data);
+		hs_info->rt_data = NULL;
+		if (ret)
+			goto hs_err;
+		mtk_fsm_switch_state(fsm, to_state, event);
+	}
+
+	if (((fsm->fsm_flag | event->fsm_flag) & fsm->hs_done_flag) == fsm->hs_done_flag) {
+		to_state = FSM_STATE_READY;
+		mtk_fsm_switch_state(fsm, to_state, NULL);
+	}
+
+	return 0;
+
+free_rt_data:
+	if (hs_info && hs_info->rt_data) {
+		dev_kfree_skb(hs_info->rt_data);
+		hs_info->rt_data = NULL;
+	}
+hs_err:
+	for (int hs_id = 0; hs_id < HS_ID_MAX; hs_id++)
+		mtk_dev_unmask_dev_evt(mdev, fsm->hs_info[hs_id].mhccif_ch);
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
+	mtk_dev_mask_dev_evt(mdev, DEV_EVT_D2H_BOOT_FLOW_SYNC);
+	for (hs_id = 0; hs_id < HS_ID_MAX; hs_id++)
+		mtk_dev_mask_dev_evt(mdev, fsm->hs_info[hs_id].mhccif_ch);
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
+	mtk_fsm_evt_submit(mdev, FSM_EVT_STARTUP,
+			   hs_info->fsm_flag_hs1, hs_info, sizeof(*hs_info), 0);
+	mtk_dev_mask_dev_evt(mdev, hs_info->mhccif_ch);
+	mtk_dev_clear_dev_evt(mdev, hs_info->mhccif_ch);
+
+	return 0;
+}
+
+static void mtk_fsm_hs_info_init_by_hsid(struct mtk_md_fsm *fsm, int hs_id)
+{
+	struct fsm_hs_info *hs_info;
+
+	if (hs_id < 0 || hs_id >= HS_ID_MAX) {
+		dev_warn((fsm->mdev)->dev, "hs_id = %d, invalid.\n", hs_id);
+		return;
+	}
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
+		ret = mtk_dev_register_dev_evt(mdev, hs_info->mhccif_ch,
+					       mtk_fsm_hs1_handler, hs_info);
+		if (ret)
+			return ret;
+	}
+
+	return 0;
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
+		mtk_dev_unregister_dev_evt(mdev, hs_info->mhccif_ch);
+	}
+}
+
+static int mtk_fsm_dev_add_act(struct mtk_md_fsm *fsm, struct mtk_fsm_evt *event)
+{
+	if (fsm->state != FSM_STATE_OFF && fsm->state != FSM_STATE_INVALID)
+		return -EPROTO;
+
+	mtk_fsm_switch_state(fsm, FSM_STATE_ON, event);
+	mtk_dev_unmask_dev_evt(fsm->mdev, DEV_EVT_D2H_BOOT_FLOW_SYNC);
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
+int mtk_fsm_start(struct mtk_md_dev *mdev)
+{
+	struct mtk_md_fsm *fsm = mdev->fsm;
+
+	if (!fsm)
+		return -EINVAL;
+
+	if (!fsm->fsm_handler)
+		return -EFAULT;
+
+	wake_up_process(fsm->fsm_handler);
+	return 0;
+}
+EXPORT_SYMBOL(mtk_fsm_start);
+
+static void mkt_fsm_notifier_cleanup(struct mtk_md_dev *mdev, struct list_head *ntq)
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
+			      void *data, enum mtk_fsm_prio prio, bool is_pre)
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
+	if (is_pre)
+		mtk_fsm_notifier_insert(notifier, &fsm->pre_notifiers);
+	else
+		mtk_fsm_notifier_insert(notifier, &fsm->post_notifiers);
+	mutex_unlock(&fsm->notifier_lock);
+
+	return 0;
+}
+EXPORT_SYMBOL(mtk_fsm_notifier_register);
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
+	list_for_each_entry_safe(nt, tmp, &fsm->pre_notifiers, entry) {
+		if (nt->id == id) {
+			list_del(&nt->entry);
+			kfree(nt);
+			break;
+		}
+	}
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
+EXPORT_SYMBOL(mtk_fsm_notifier_unregister);
+
+int mtk_fsm_evt_submit(struct mtk_md_dev *mdev,
+		       enum mtk_fsm_evt_id id, enum mtk_fsm_flag flag,
+		       void *data, unsigned int len, unsigned char mode)
+{
+	struct mtk_md_fsm *fsm = mdev->fsm;
+	struct mtk_fsm_evt *event;
+	unsigned long flags;
+	int ret = 0;
+
+	if (!fsm || id >= FSM_EVT_MAX) {
+		dev_err(mdev->dev, "Invalid param!\n");
+		return FSM_EVT_RET_FAIL;
+	}
+
+	if (test_bit(EVT_TF_GATECLOSED, &fsm->t_flag)) {
+		dev_err(mdev->dev, "Failed to submit evt, fsm has been removed!\n");
+		return FSM_EVT_RET_FAIL;
+	}
+
+	event = kzalloc(sizeof(*event),
+			(in_hardirq() || in_softirq() || irqs_disabled()) ?
+			GFP_ATOMIC : GFP_KERNEL);
+	if (!event)
+		return FSM_EVT_RET_FAIL;
+
+	kref_init(&event->kref);
+	event->mdev = mdev;
+	event->id = id;
+	event->fsm_flag = flag;
+	event->status = FSM_EVT_RET_ONGOING;
+	event->data = data;
+	event->len = len;
+	event->mode = mode;
+
+	spin_lock_irqsave(&fsm->evtq_lock, flags);
+	if (test_bit(EVT_TF_GATECLOSED, &fsm->t_flag)) {
+		spin_unlock_irqrestore(&fsm->evtq_lock, flags);
+		mtk_fsm_evt_put(event);
+		dev_err(mdev->dev, "Failed to add event, fsm dev has been removed!\n");
+		return FSM_EVT_RET_FAIL;
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
+		if (!ret && event->status != FSM_EVT_RET_DONE) {
+			dev_err(mdev->dev, "Handling fsm blocking event timeout!\n");
+			ret = -ETIMEDOUT;
+		} else {
+			ret = event->status;
+		}
+	}
+	mtk_fsm_evt_put(event);
+
+	return ret;
+}
+EXPORT_SYMBOL(mtk_fsm_evt_submit);
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
+	fsm->fsm_handler = kthread_create(mtk_fsm_evt_handler, fsm, "fsm_evt_thread%d_%s",
+					  mdev->hw_ver, mdev->dev_str);
+	if (IS_ERR(fsm->fsm_handler)) {
+		ret = PTR_ERR(fsm->fsm_handler);
+		goto exit;
+	}
+
+	fsm->mdev = mdev;
+	fsm->state = FSM_STATE_INVALID;
+	fsm->fsm_flag = FSM_F_DFLT;
+
+	INIT_LIST_HEAD(&fsm->evtq);
+	spin_lock_init(&fsm->evtq_lock);
+	init_waitqueue_head(&fsm->evt_waitq);
+
+	INIT_LIST_HEAD(&fsm->pre_notifiers);
+	INIT_LIST_HEAD(&fsm->post_notifiers);
+	mutex_init(&fsm->notifier_lock);
+
+	ret = mtk_dev_register_dev_evt(mdev, DEV_EVT_D2H_BOOT_FLOW_SYNC,
+				       mtk_fsm_early_bootup_handler, fsm);
+	if (ret)
+		goto exit;
+
+	ret = mtk_fsm_hs_info_init(fsm);
+	if (ret) {
+		mtk_dev_unregister_dev_evt(mdev, DEV_EVT_D2H_BOOT_FLOW_SYNC);
+		goto exit;
+	}
+
+	mdev->fsm = fsm;
+	return 0;
+exit:
+	return ret;
+}
+EXPORT_SYMBOL(mtk_fsm_init);
+
+int mtk_fsm_exit(struct mtk_md_dev *mdev)
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
+	if (handler)
+		kthread_stop(handler);
+
+	spin_lock_irqsave(&fsm->evtq_lock, flags);
+	if (WARN_ON(!list_empty(&fsm->evtq)))
+		mtk_fsm_evt_cleanup(fsm, &fsm->evtq);
+	spin_unlock_irqrestore(&fsm->evtq_lock, flags);
+
+	for (int i = 0; i < HS_ID_MAX; i++) {
+		if (fsm->hs_info[i].rt_data) {
+			dev_kfree_skb(fsm->hs_info[i].rt_data);
+			fsm->hs_info[i].rt_data = NULL;
+		}
+	}
+
+	mutex_lock(&fsm->notifier_lock);
+	mkt_fsm_notifier_cleanup(mdev, &fsm->pre_notifiers);
+	mkt_fsm_notifier_cleanup(mdev, &fsm->post_notifiers);
+	mutex_unlock(&fsm->notifier_lock);
+
+	mtk_dev_unregister_dev_evt(mdev, DEV_EVT_D2H_BOOT_FLOW_SYNC);
+	mtk_fsm_hs_info_exit(fsm);
+	mdev->fsm = NULL;
+
+	return 0;
+}
+EXPORT_SYMBOL(mtk_fsm_exit);
diff --git a/drivers/net/wwan/t9xx/mtk_fsm.h b/drivers/net/wwan/t9xx/mtk_fsm.h
new file mode 100644
index 000000000000..154f3ddae4bb
--- /dev/null
+++ b/drivers/net/wwan/t9xx/mtk_fsm.h
@@ -0,0 +1,144 @@
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
+#define FEATURE_TYPE_NOT	FIELD_PREP(FEATURE_TYPE, RTFT_TYPE_NOT_SUPPORT)
+#define FEATURE_TYPE_MUST	FIELD_PREP(FEATURE_TYPE, RTFT_TYPE_MUST_SUPPORT)
+#define FEATURE_TYPE_OPTIONAL	FIELD_PREP(FEATURE_TYPE, RTFT_TYPE_OPTIONAL_SUPPORT)
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
+	FSM_PRIO_0 = 0,
+	FSM_PRIO_1 = 1,
+	FSM_PRIO_MAX
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
+	/* runtime data from device need to be parsed by host */
+	void *rt_data;
+	unsigned int rt_data_len;
+};
+
+struct mtk_md_fsm {
+	struct mtk_md_dev *mdev;
+	struct task_struct *fsm_handler;
+	struct fsm_hs_info hs_info[HS_ID_MAX];
+	unsigned int hs_done_flag;
+	unsigned long t_flag;
+	u32 last_dev_state;
+	enum mtk_fsm_state state;
+	unsigned int fsm_flag;
+	struct list_head evtq;
+	/* protect evtq */
+	spinlock_t evtq_lock;
+	/* waitq for fsm blocking submit */
+	wait_queue_head_t evt_waitq;
+	struct list_head pre_notifiers;
+	struct list_head post_notifiers;
+	/* protects pre_notifiers and post_notifiers lists */
+	struct mutex notifier_lock;
+};
+
+struct mtk_fsm_evt {
+	struct list_head entry;
+	struct kref kref;
+	struct mtk_md_dev *mdev;
+	enum mtk_fsm_evt_id id;
+	unsigned int fsm_flag;
+	int status;
+	unsigned char mode;
+	unsigned int len;
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
+int mtk_fsm_start(struct mtk_md_dev *mdev);
+int mtk_fsm_notifier_register(struct mtk_md_dev *mdev, enum mtk_user_id id,
+			      void (*cb)(struct mtk_fsm_param *, void *data),
+			      void *data, enum mtk_fsm_prio prio, bool is_pre);
+int mtk_fsm_notifier_unregister(struct mtk_md_dev *mdev, enum mtk_user_id id);
+int mtk_fsm_evt_submit(struct mtk_md_dev *mdev,
+		       enum mtk_fsm_evt_id id, enum mtk_fsm_flag flag,
+		       void *data, unsigned int len, unsigned char mode);
+
+#endif /* __MTK_FSM_H__ */
diff --git a/drivers/net/wwan/t9xx/mtk_port.c b/drivers/net/wwan/t9xx/mtk_port.c
index a71c097c6d39..82eb0feb84fe 100644
--- a/drivers/net/wwan/t9xx/mtk_port.c
+++ b/drivers/net/wwan/t9xx/mtk_port.c
@@ -716,6 +716,9 @@ int mtk_port_status_update(struct mtk_md_dev *mdev, void *data, u32 data_len)
 	if (unlikely(!mdev || !msg))
 		return -EINVAL;
 
+	if (data_len < sizeof(*msg))
+		return -EPROTO;
+
 	ctrl_blk = mdev->ctrl_blk;
 	port_mngr = ctrl_blk->port_mngr;
 	if (le16_to_cpu(msg->version) != MTK_PORT_ENUM_VER ||
@@ -819,6 +822,69 @@ int mtk_port_ch_disable(struct mtk_port *port)
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
+			MTK_PORT_SEARCH_FROM_RADIX_TREE(port, slot);
+			MTK_PORT_INTERNAL_NODE_CHECK(port, slot, iter);
+			ports_ops[port->info.type]->disable(port);
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
+				ports_ops[port->info.type]->enable(port);
+		} else if (fsm_param->fsm_flag & FSM_F_SAP_HS_START) {
+			port = mtk_port_search_by_id(port_mngr, CCCI_SAP_CONTROL_RX);
+			if (port)
+				ports_ops[port->info.type]->enable(port);
+		}
+		break;
+	default:
+		break;
+	}
+}
+
 int mtk_port_mngr_init(struct mtk_ctrl_blk *ctrl_blk, struct mtk_port_cfg *port_cfg, int port_cnt)
 {
 	struct mtk_port_mngr *port_mngr;
diff --git a/drivers/net/wwan/t9xx/mtk_port.h b/drivers/net/wwan/t9xx/mtk_port.h
index 0a42313e348f..ba69eb37c7f9 100644
--- a/drivers/net/wwan/t9xx/mtk_port.h
+++ b/drivers/net/wwan/t9xx/mtk_port.h
@@ -152,6 +152,8 @@ int mtk_port_send_data(struct mtk_port *port, void *data);
 int mtk_port_status_update(struct mtk_md_dev *mdev, void *data, u32 data_len);
 int mtk_port_ch_enable(struct mtk_port *port);
 int mtk_port_ch_disable(struct mtk_port *port);
+void mtk_port_mngr_fsm_state_handler(struct mtk_fsm_param *fsm_param, void *arg);
+void mtk_port_mngr_fsm_state_handler_late(struct mtk_fsm_param *fsm_param, void *arg);
 int mtk_port_mngr_init(struct mtk_ctrl_blk *ctrl_blk, struct mtk_port_cfg *port_cfg, int port_cnt);
 void mtk_port_mngr_exit(struct mtk_ctrl_blk *ctrl_blk);
 void mtk_port_trb_init(struct mtk_port *port, struct trb *trb, enum mtk_trb_cmd_type cmd,
diff --git a/drivers/net/wwan/t9xx/mtk_utility.h b/drivers/net/wwan/t9xx/mtk_utility.h
new file mode 100644
index 000000000000..b72db3842d2d
--- /dev/null
+++ b/drivers/net/wwan/t9xx/mtk_utility.h
@@ -0,0 +1,33 @@
+/* SPDX-License-Identifier: GPL-2.0-only
+ *
+ * Copyright (c) 2022, MediaTek Inc.
+ */
+
+#ifndef __MTK_UTILITY_H__
+#define __MTK_UTILITY_H__
+
+#include <linux/device.h>
+#include "mtk_dev.h"
+
+#define MTK_UEVENT_INFO_LEN 128
+
+/* MTK uevent */
+enum mtk_uevent_id {
+	MTK_UEVENT_UNDEF = 0,
+	MTK_UEVENT_FSM = 1,
+	MTK_UEVENT_MINIDUMP = 2,
+	MTK_UEVENT_LOWPOWER = 3,
+	MTK_UEVENT_MAX
+};
+
+static inline void mtk_uevent_notify(struct device *dev, enum mtk_uevent_id id, const char *info)
+{
+	char buf[MTK_UEVENT_INFO_LEN];
+	char *ext[2] = {NULL, NULL};
+
+	snprintf(buf, MTK_UEVENT_INFO_LEN, "%s:event_id=%d, info=%s",
+		 dev->kobj.name, id, info);
+	ext[0] = buf;
+	kobject_uevent_env(&dev->kobj, KOBJ_CHANGE, ext);
+}
+#endif /* __MTK_UTILITY_H__ */
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_cldma.c b/drivers/net/wwan/t9xx/pcie/mtk_cldma.c
index 7af9ef2c35af..717f30fea29e 100644
--- a/drivers/net/wwan/t9xx/pcie/mtk_cldma.c
+++ b/drivers/net/wwan/t9xx/pcie/mtk_cldma.c
@@ -34,11 +34,179 @@
 #define CLDMA_RETRY_DELAY_MS	(100)
 #define NO_BUDGET		(0)
 
+static struct cldma_drv_info_desc cldma_drv_info_tbl[] = {
+	{0x01CA, &drv_ops_name(m9xx), &cldma_regs_name(m9xx)},
+	{0, NULL},
+};
+
+static void mtk_cldma_get_drv_info(struct cldma_drv_info *drv_info, u32 hw_ver)
+{
+	struct cldma_drv_info_desc *p_drv_info;
+	u8 i;
+
+	for (i = 0; (p_drv_info = &cldma_drv_info_tbl[i]) && p_drv_info &&
+	     p_drv_info->drv_ops && p_drv_info->hw_regs; i++)
+		if (p_drv_info->hw_ver == hw_ver) {
+			drv_info->drv_ops = p_drv_info->drv_ops;
+			drv_info->hw_regs = p_drv_info->hw_regs;
+		}
+}
+
+static int mtk_cldma_isr(int irq_id, void *param)
+{
+	struct cldma_drv_info *drv_info = param;
+	struct mtk_md_dev *mdev;
+	u32 tx_done, rx_done;
+	u32 tx_sta, rx_sta;
+	struct txq *txq;
+	struct rxq *rxq;
+	int i;
+
+	mdev = drv_info->mdev;
+	drv_info->drv_ops->cldma_get_intr_status(drv_info, &tx_sta, &rx_sta);
+	tx_done = (tx_sta >> QUEUE_XFER_DONE) & 0xFF;
+	rx_done = (rx_sta >> QUEUE_XFER_DONE) & 0xFF;
+
+	if ((tx_sta >> QUEUE_ERROR) & 0xFF)
+		dev_err(mdev->dev, "CLDMA%d TX queue error: 0x%x\n",
+			drv_info->hif_id, (tx_sta >> QUEUE_ERROR) & 0xFF);
+	if ((rx_sta >> QUEUE_ERROR) & 0xFF)
+		dev_err(mdev->dev, "CLDMA%d RX queue error: 0x%x\n",
+			drv_info->hif_id, (rx_sta >> QUEUE_ERROR) & 0xFF);
+
+	if (tx_done) {
+		for (i = 0; i < HW_QUEUE_NUM; i++) {
+			txq = drv_info->txq[i];
+			if (!(tx_done & BIT(i)) || !txq)
+				continue;
+			queue_work(drv_info->wq, &txq->tx_done_work);
+		}
+	}
+	if (rx_done) {
+		for (i = 0; i < HW_QUEUE_NUM; i++) {
+			rxq = drv_info->rxq[i];
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
+	char bd_pool_name[DMA_POOL_NAME_LEN];
+	struct cldma_drv_info *drv_info;
+	struct cldma_hw_regs *hw_regs;
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
+	mtk_cldma_get_drv_info(drv_info, mdev->hw_ver);
+
+	if (!drv_info->drv_ops || !drv_info->hw_regs) {
+		dev_err(mdev->dev, "Failed to find CLDMA Driver for PCI %x\n", mdev->hw_ver);
+		ret = -EIO;
+		goto err_free_drv_info;
+	}
+
+	hw_regs = drv_info->hw_regs;
+	snprintf(gpd_pool_name, DMA_POOL_NAME_LEN, "cldma%d_gpd_pool_%s",
+		 hw_id, mdev->dev_str);
+	snprintf(bd_pool_name, DMA_POOL_NAME_LEN, "cldma%d_bd_pool_%s",
+		 hw_id, mdev->dev_str);
+	drv_info->gpd_dma_pool = dma_pool_create(gpd_pool_name, mdev->dev,
+						 sizeof(union gpd), 4, 0);
+	if (!drv_info->gpd_dma_pool) {
+		dev_err(mdev->dev, "Failed to alloc gpd dma pool for cldma%d\n", hw_id);
+		ret = -ENOMEM;
+		goto err_free_drv_info;
+	}
+	drv_info->bd_dma_pool = dma_pool_create(bd_pool_name, mdev->dev,
+						sizeof(union bd), 4, 0);
+	if (!drv_info->bd_dma_pool) {
+		dev_err(mdev->dev, "Failed to alloc bd dma pool for cldma%d\n", hw_id);
+		ret = -ENOMEM;
+		goto err_destroy_gpd_pool;
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
+		goto err_destroy_dma_pool;
+	}
+
+	flag = WQ_UNBOUND | WQ_MEM_RECLAIM | WQ_HIGHPRI;
+	drv_info->wq = alloc_workqueue("cldma%d_workq_%s", flag, 0, hw_id, mdev->dev_str);
+	if (!drv_info->wq) {
+		dev_err(mdev->dev, "Failed to alloc work queue for cldma%d\n", hw_id);
+		ret = -ENOMEM;
+		goto err_destroy_dma_pool;
+	}
+
+	drv_info->drv_ops->cldma_drv_init(drv_info);
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
+	cd->cldma_drv_info[hif_id] = drv_info;
+	return 0;
+
+err_destroy_wq:
+	destroy_workqueue(drv_info->wq);
+err_destroy_dma_pool:
+	dma_pool_destroy(drv_info->bd_dma_pool);
+err_destroy_gpd_pool:
+	dma_pool_destroy(drv_info->gpd_dma_pool);
+err_free_drv_info:
+	kfree(drv_info);
+
+	return ret;
+}
+
 static void mtk_cldma_clr_bd_dsc(struct cldma_drv_info *drv_info,
 				 struct bd_dsc *bd_dsc_pool, int nr_bds)
 {
@@ -917,6 +1085,44 @@ static void mtk_cldma_rxq_free(struct cldma_drv_info *drv_info, u32 rxqno)
 	kfree(rxq);
 }
 
+static int mtk_cldma_dev_exit(struct cldma_dev *cd, int hif_id)
+{
+	struct cldma_drv_info *drv_info;
+	struct mtk_md_dev *mdev;
+	int virq_id;
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
+	virq_id = mtk_pci_get_virq_id(mdev, drv_info->pci_ext_irq_id);
+	mtk_pci_unregister_irq(mdev, drv_info->pci_ext_irq_id);
+	mtk_pci_mask_irq(mdev, drv_info->pci_ext_irq_id);
+	synchronize_irq(virq_id);
+	for (i = 0; i < HW_QUEUE_NUM; i++) {
+		if (drv_info->txq[i])
+			mtk_cldma_txq_free(drv_info, drv_info->txq[i]->txqno);
+		if (drv_info->rxq[i])
+			mtk_cldma_rxq_free(drv_info, drv_info->rxq[i]->rxqno);
+	}
+
+	flush_workqueue(drv_info->wq);
+	destroy_workqueue(drv_info->wq);
+	dma_pool_destroy(drv_info->bd_dma_pool);
+	dma_pool_destroy(drv_info->gpd_dma_pool);
+
+	cd->cldma_drv_info[hif_id] = NULL;
+	kfree(drv_info);
+
+	return 0;
+}
+
 static int mtk_cldma_start_xfer(struct cldma_drv_info *drv_info, u32 qno)
 {
 	struct cldma_drv_ops *drv_ops;
@@ -967,10 +1173,19 @@ int mtk_cldma_init(struct mtk_ctrl_trans *trans)
 
 void mtk_cldma_exit(struct mtk_ctrl_trans *trans)
 {
-	if (!trans->dev)
+	struct cldma_dev *cd = trans->dev;
+	int i;
+
+	if (!cd)
 		return;
 
-	kfree(trans->dev);
+	/* The caller has already stopped the trb service threads, so the
+	 * per-hif teardown has to happen here, while cd is still alive.
+	 */
+	for (i = 0; i < NR_CLDMA; i++)
+		mtk_cldma_dev_exit(cd, i);
+
+	kfree(cd);
 	trans->dev = NULL;
 }
 
@@ -1245,6 +1460,25 @@ int mtk_cldma_trb_process(void *dev, struct sk_buff *skb)
 	return trb_act_tbl[trb->cmd](cd, skb);
 }
 
+void mtk_cldma_fsm_state_listener(struct mtk_fsm_param *param, struct mtk_ctrl_trans *trans)
+{
+	struct cldma_dev *cd = trans->dev;
+	int ret = 0;
+
+	switch (param->to) {
+	case FSM_STATE_BOOTUP:
+		if (param->fsm_flag & FSM_F_SAP_HS_START)
+			ret = mtk_cldma_dev_init(cd, CLDMA0);
+		else if (param->fsm_flag & FSM_F_MD_HS_START)
+			ret = mtk_cldma_dev_init(cd, CLDMA1);
+		if (ret)
+			dev_err(trans->mdev->dev, "Failed to init CLDMA: %d\n", ret);
+		break;
+	default:
+		break;
+	}
+}
+
 int mtk_cldma_check_ch_cfg(void *dev, struct queue_info *que)
 {
 	struct cldma_drv_info *drv_info;
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_cldma_drv_m9xx.h b/drivers/net/wwan/t9xx/pcie/mtk_cldma_drv_m9xx.h
index 58c45bfe0a8b..f113c4c1068a 100644
--- a/drivers/net/wwan/t9xx/pcie/mtk_cldma_drv_m9xx.h
+++ b/drivers/net/wwan/t9xx/pcie/mtk_cldma_drv_m9xx.h
@@ -79,7 +79,6 @@
 #define REG_CLDMA_L2RIMSR1				(0x0800 + 0x00FC)
 
 #define REG_CLDMA_INT_EAP_USIP_MASK			(0x0800 + 0x011C)
-#define REG_CLDMA_INT_WF_MASK				(0x0800 + 0x0120)
 #define REG_CLDMA_RQ1_GPD_DONE_CNT			(0x0800 + 0x0174)
 #define REG_CLDMA_TQ1_GPD_DONE_CNT			(0x0800 + 0x0184)
 
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_pci.c b/drivers/net/wwan/t9xx/pcie/mtk_pci.c
index 22a8134cf090..2c3672cd319d 100644
--- a/drivers/net/wwan/t9xx/pcie/mtk_pci.c
+++ b/drivers/net/wwan/t9xx/pcie/mtk_pci.c
@@ -900,23 +900,43 @@ static int mtk_pci_dev_init(struct mtk_md_dev *mdev)
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
+	ret = mtk_fsm_evt_submit(mdev, FSM_EVT_DEV_RM, 0, NULL, 0,
+				 EVT_MODE_BLOCKING | EVT_MODE_TOHEAD);
+	if (ret < 0 || ret == FSM_EVT_RET_FAIL)
+		dev_err(mdev->dev, "FSM DEV_RM failed: %d, forcing cleanup\n", ret);
 	mtk_trans_ctrl_exit(mdev);
+	mtk_fsm_exit(mdev);
 }
 
 static int mtk_pci_dev_start(struct mtk_md_dev *mdev)
 {
-	return 0;
+	int ret;
+
+	ret = mtk_fsm_evt_submit(mdev, FSM_EVT_DEV_ADD, 0, NULL, 0, 0);
+	if (ret == FSM_EVT_RET_FAIL)
+		return -ENOMEM;
+
+	return mtk_fsm_start(mdev);
 }
 static const struct mtk_dev_ops pci_hw_ops = {
 	.get_dev_state = mtk_pci_get_dev_state,
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c b/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c
index fe68f6256f4b..7ec62a3127fb 100644
--- a/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c
+++ b/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.c
@@ -334,6 +334,8 @@ static void mtk_ctrl_trb_srv_exit(struct mtk_ctrl_trans *trans)
 
 	for (i = 0; i < trans->trb_srv_num; i++) {
 		srv = trans->trb_srv[i];
+		if (!srv)
+			continue;
 		kthread_stop(srv->trb_thread);
 		for (j = 0; j < NR_CLDMA; j++) {
 			list_for_each_entry_safe(srv_que, next_srv_que,
@@ -497,6 +499,15 @@ static int mtk_pcie_hif_submit_skb(struct mtk_md_dev *mdev, struct sk_buff *skb,
 	return ret;
 }
 
+static void mtk_pcie_hif_fsm_indication(struct mtk_md_dev *mdev, struct mtk_fsm_param *param)
+{
+	struct mtk_ctrl_blk *ctrl_blk = mdev->ctrl_blk;
+	struct mtk_ctrl_trans *trans;
+
+	trans = ctrl_blk->ctrl_hw_priv;
+	mtk_cldma_fsm_state_listener(param, trans);
+}
+
 static int mtk_pcie_hif_cmd_func(struct mtk_md_dev *mdev, int cmd, void *data)
 {
 	struct mtk_ctrl_blk *ctrl_blk = mdev->ctrl_blk;
@@ -524,6 +535,7 @@ static struct mtk_ctrl_hif_ops pcie_ctrl_ops = {
 	.init = mtk_pcie_hif_init,
 	.exit = mtk_pcie_hif_exit,
 	.submit_skb = mtk_pcie_hif_submit_skb,
+	.fsm_indication = mtk_pcie_hif_fsm_indication,
 	.send_cmd = mtk_pcie_hif_cmd_func,
 };
 
@@ -588,6 +600,17 @@ int mtk_trans_ctrl_init(struct mtk_md_dev *mdev)
 
 int mtk_trans_ctrl_exit(struct mtk_md_dev *mdev)
 {
+	struct mtk_ctrl_blk *ctrl_blk = mdev->ctrl_blk;
+	struct mtk_ctrl_trans *trans = ctrl_blk->ctrl_hw_priv;
+
+	/* FSM_STATE_OFF normally tears the HIF down. If that never ran, the
+	 * trb kthreads and the CLDMA irq callback would outlive the devm
+	 * allocations they point at, so do it here. trans->available is only
+	 * set once mtk_pcie_hif_init() has completed.
+	 */
+	if (atomic_read(&trans->available))
+		mtk_pcie_hif_exit(mdev);
+
 	mtk_ctrl_exit(mdev);
 
 	return 0;

-- 
2.34.1

