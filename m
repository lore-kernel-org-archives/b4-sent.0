From: Satish Kharat <satishkh@cisco.com>
Date: Wed, 08 Apr 2026 09:36:23 -0700
Subject: [PATCH net-next v3 02/10] enic: add admin channel open and close
 for SR-IOV
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260408-enic-sriov-v2-admin-channel-v2-v3-2-1d4999a03cec@cisco.com>
References: <20260408-enic-sriov-v2-admin-channel-v2-v3-0-1d4999a03cec@cisco.com>
In-Reply-To: <20260408-enic-sriov-v2-admin-channel-v2-v3-0-1d4999a03cec@cisco.com>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 20260401-enic-sriov-v2-prep-v4-0-d5834b2ef1b9@cisco.com, 
 Satish Kharat <satishkh@cisco.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775666183; l=7692;
 i=satishkh@cisco.com; h=from:subject:message-id;
 bh=MSrD6SHhLimV7ZBBHtD+FMA9ZuwQh8TK6KZclm5ORVk=;
 b=E07YPanIdD96REj+/TKxRf6PUtK6ISBV+/9g2fRVVcc306XH2Sb9NVD4zp13TRxRMcOJsVMq3
 hQ9Der8etSFCEI1eO8b0KRHQ/d3fVW7yEgWQdknxSrmmNODtXnNTvvh
X-Developer-Key: i=satishkh@cisco.com; a=ed25519;
 pk=4BxbLoCGvHeIMH/PbpiNVx8/2IcTjFvqcr0AD8K6WLY=
X-Endpoint-Received: by B4 Relay for satishkh@cisco.com/default with auth_id=639
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The V2 SR-IOV design uses a dedicated admin channel (WQ/RQ/CQ/INTR
on separate BAR resources) for PF-VF mailbox communication rather
than firmware-proxied devcmds.

Introduce enic_admin_channel_open() and enic_admin_channel_close().
Open allocates and initialises the admin WQ, RQ, two CQs (one per
direction) and one SR-IOV interrupt, then issues CMD_QP_TYPE_SET to
tell firmware the queues are admin-type. Close reverses the sequence.

Add CMD_QP_TYPE_SET (97) and QP_TYPE_ADMIN/DATA defines to
vnic_devcmd.h.

Signed-off-by: Satish Kharat <satishkh@cisco.com>
---
 drivers/net/ethernet/cisco/enic/Makefile      |   3 +-
 drivers/net/ethernet/cisco/enic/enic_admin.c  | 175 ++++++++++++++++++++++++++
 drivers/net/ethernet/cisco/enic/enic_admin.h  |  15 +++
 drivers/net/ethernet/cisco/enic/vnic_devcmd.h |   9 ++
 4 files changed, 201 insertions(+), 1 deletion(-)

diff --git a/drivers/net/ethernet/cisco/enic/Makefile b/drivers/net/ethernet/cisco/enic/Makefile
index a96b8332e6e2..7ae72fefc99a 100644
--- a/drivers/net/ethernet/cisco/enic/Makefile
+++ b/drivers/net/ethernet/cisco/enic/Makefile
@@ -3,5 +3,6 @@ obj-$(CONFIG_ENIC) := enic.o
 
 enic-y := enic_main.o vnic_cq.o vnic_intr.o vnic_wq.o \
 	enic_res.o enic_dev.o enic_pp.o vnic_dev.o vnic_rq.o vnic_vic.o \
-	enic_ethtool.o enic_api.o enic_clsf.o enic_rq.o enic_wq.o
+	enic_ethtool.o enic_api.o enic_clsf.o enic_rq.o enic_wq.o \
+	enic_admin.o
 
diff --git a/drivers/net/ethernet/cisco/enic/enic_admin.c b/drivers/net/ethernet/cisco/enic/enic_admin.c
new file mode 100644
index 000000000000..d1abe6a50095
--- /dev/null
+++ b/drivers/net/ethernet/cisco/enic/enic_admin.c
@@ -0,0 +1,175 @@
+// SPDX-License-Identifier: GPL-2.0-only
+// Copyright 2025 Cisco Systems, Inc.  All rights reserved.
+
+#include <linux/kernel.h>
+#include <linux/netdevice.h>
+
+#include "vnic_dev.h"
+#include "vnic_wq.h"
+#include "vnic_rq.h"
+#include "vnic_cq.h"
+#include "vnic_intr.h"
+#include "vnic_resource.h"
+#include "vnic_devcmd.h"
+#include "enic.h"
+#include "enic_admin.h"
+#include "cq_desc.h"
+#include "wq_enet_desc.h"
+#include "rq_enet_desc.h"
+
+/* No-op: admin WQ buffers are freed inline after completion polling */
+static void enic_admin_wq_buf_clean(struct vnic_wq *wq,
+				    struct vnic_wq_buf *buf)
+{
+}
+
+/* No-op: admin RQ buffer teardown is handled in enic_admin_channel_close */
+static void enic_admin_rq_buf_clean(struct vnic_rq *rq,
+				    struct vnic_rq_buf *buf)
+{
+}
+
+static int enic_admin_qp_type_set(struct enic *enic, u32 enable)
+{
+	u64 a0 = QP_TYPE_ADMIN, a1 = enable;
+	int wait = 1000;
+	int err;
+
+	spin_lock_bh(&enic->devcmd_lock);
+	err = vnic_dev_cmd(enic->vdev, CMD_QP_TYPE_SET, &a0, &a1, wait);
+	spin_unlock_bh(&enic->devcmd_lock);
+
+	return err;
+}
+
+static int enic_admin_alloc_resources(struct enic *enic)
+{
+	int err;
+
+	err = vnic_wq_alloc_with_type(enic->vdev, &enic->admin_wq, 0,
+				      ENIC_ADMIN_DESC_COUNT,
+				      sizeof(struct wq_enet_desc),
+				      RES_TYPE_ADMIN_WQ);
+	if (err)
+		return err;
+
+	err = vnic_rq_alloc_with_type(enic->vdev, &enic->admin_rq, 0,
+				      ENIC_ADMIN_DESC_COUNT,
+				      sizeof(struct rq_enet_desc),
+				      RES_TYPE_ADMIN_RQ);
+	if (err)
+		goto free_wq;
+
+	err = vnic_cq_alloc_with_type(enic->vdev, &enic->admin_cq[0], 0,
+				      ENIC_ADMIN_DESC_COUNT,
+				      sizeof(struct cq_desc),
+				      RES_TYPE_ADMIN_CQ);
+	if (err)
+		goto free_rq;
+
+	err = vnic_cq_alloc_with_type(enic->vdev, &enic->admin_cq[1], 1,
+				      ENIC_ADMIN_DESC_COUNT,
+				      16 << enic->ext_cq,
+				      RES_TYPE_ADMIN_CQ);
+	if (err)
+		goto free_cq0;
+
+	/* PFs have dedicated SRIOV_INTR resources for admin channel.
+	 * VFs lack SRIOV_INTR; use a regular INTR_CTRL slot instead.
+	 */
+	if (vnic_dev_get_res_count(enic->vdev, RES_TYPE_SRIOV_INTR) >= 1)
+		err = vnic_intr_alloc_with_type(enic->vdev,
+						&enic->admin_intr, 0,
+						RES_TYPE_SRIOV_INTR);
+	else
+		err = vnic_intr_alloc(enic->vdev, &enic->admin_intr,
+				      enic->intr_count);
+	if (err)
+		goto free_cq1;
+
+	return 0;
+
+free_cq1:
+	vnic_cq_free(&enic->admin_cq[1]);
+free_cq0:
+	vnic_cq_free(&enic->admin_cq[0]);
+free_rq:
+	vnic_rq_free(&enic->admin_rq);
+free_wq:
+	vnic_wq_free(&enic->admin_wq);
+	return err;
+}
+
+static void enic_admin_free_resources(struct enic *enic)
+{
+	vnic_intr_free(&enic->admin_intr);
+	vnic_cq_free(&enic->admin_cq[1]);
+	vnic_cq_free(&enic->admin_cq[0]);
+	vnic_rq_free(&enic->admin_rq);
+	vnic_wq_free(&enic->admin_wq);
+}
+
+static void enic_admin_init_resources(struct enic *enic)
+{
+	vnic_wq_init(&enic->admin_wq, 0, 0, 0);
+	vnic_rq_init(&enic->admin_rq, 1, 0, 0);
+	vnic_cq_init(&enic->admin_cq[0], 0, 1, 0, 0, 1, 0, 1, 0, 0, 0);
+	vnic_cq_init(&enic->admin_cq[1], 0, 1, 0, 0, 1, 0, 1, 0, 0, 0);
+	vnic_intr_init(&enic->admin_intr, 0, 0, 1);
+}
+
+int enic_admin_channel_open(struct enic *enic)
+{
+	int err;
+
+	if (!enic->has_admin_channel)
+		return -ENODEV;
+
+	err = enic_admin_alloc_resources(enic);
+	if (err) {
+		netdev_err(enic->netdev,
+			   "Failed to alloc admin channel resources: %d\n",
+			   err);
+		return err;
+	}
+
+	enic_admin_init_resources(enic);
+
+	vnic_wq_enable(&enic->admin_wq);
+	vnic_rq_enable(&enic->admin_rq);
+
+	err = enic_admin_qp_type_set(enic, 1);
+	if (err) {
+		netdev_err(enic->netdev,
+			   "Failed to set admin QP type: %d\n", err);
+		goto disable_queues;
+	}
+
+	return 0;
+
+disable_queues:
+	vnic_wq_disable(&enic->admin_wq);
+	vnic_rq_disable(&enic->admin_rq);
+	enic_admin_qp_type_set(enic, 0);
+	enic_admin_free_resources(enic);
+	return err;
+}
+
+void enic_admin_channel_close(struct enic *enic)
+{
+	if (!enic->has_admin_channel)
+		return;
+
+	vnic_wq_disable(&enic->admin_wq);
+	vnic_rq_disable(&enic->admin_rq);
+
+	enic_admin_qp_type_set(enic, 0);
+
+	vnic_wq_clean(&enic->admin_wq, enic_admin_wq_buf_clean);
+	vnic_rq_clean(&enic->admin_rq, enic_admin_rq_buf_clean);
+	vnic_cq_clean(&enic->admin_cq[0]);
+	vnic_cq_clean(&enic->admin_cq[1]);
+	vnic_intr_clean(&enic->admin_intr);
+
+	enic_admin_free_resources(enic);
+}
diff --git a/drivers/net/ethernet/cisco/enic/enic_admin.h b/drivers/net/ethernet/cisco/enic/enic_admin.h
new file mode 100644
index 000000000000..569aadeb9312
--- /dev/null
+++ b/drivers/net/ethernet/cisco/enic/enic_admin.h
@@ -0,0 +1,15 @@
+/* SPDX-License-Identifier: GPL-2.0-only */
+/* Copyright 2025 Cisco Systems, Inc.  All rights reserved. */
+
+#ifndef _ENIC_ADMIN_H_
+#define _ENIC_ADMIN_H_
+
+#define ENIC_ADMIN_DESC_COUNT	64
+#define ENIC_ADMIN_BUF_SIZE	2048
+
+struct enic;
+
+int enic_admin_channel_open(struct enic *enic);
+void enic_admin_channel_close(struct enic *enic);
+
+#endif /* _ENIC_ADMIN_H_ */
diff --git a/drivers/net/ethernet/cisco/enic/vnic_devcmd.h b/drivers/net/ethernet/cisco/enic/vnic_devcmd.h
index 7a4bce736105..a1c8f522c7d7 100644
--- a/drivers/net/ethernet/cisco/enic/vnic_devcmd.h
+++ b/drivers/net/ethernet/cisco/enic/vnic_devcmd.h
@@ -455,8 +455,17 @@ enum vnic_devcmd_cmd {
 	 */
 	CMD_CQ_ENTRY_SIZE_SET = _CMDC(_CMD_DIR_WRITE, _CMD_VTYPE_ENET, 90),
 
+	/*
+	 * Set queue pair type (admin or data)
+	 * in: (u32) a0 = queue pair type (0 = admin, 1 = data)
+	 * in: (u32) a1 = enable (1) / disable (0)
+	 */
+	CMD_QP_TYPE_SET = _CMDC(_CMD_DIR_WRITE, _CMD_VTYPE_ENET, 97),
 };
 
+#define QP_TYPE_ADMIN	0
+#define QP_TYPE_DATA	1
+
 /* CMD_ENABLE2 flags */
 #define CMD_ENABLE2_STANDBY 0x0
 #define CMD_ENABLE2_ACTIVE  0x1

-- 
2.43.0

