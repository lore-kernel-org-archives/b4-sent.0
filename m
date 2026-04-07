From: Satish Kharat <satishkh@cisco.com>
Date: Mon, 06 Apr 2026 17:37:04 -0700
Subject: [PATCH 06/10] enic: add MBOX core send and receive for admin
 channel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260406-enic-sriov-v2-admin-channel-v2-v1-6-82cc47636a78@cisco.com>
References: <20260406-enic-sriov-v2-admin-channel-v2-v1-0-82cc47636a78@cisco.com>
In-Reply-To: <20260406-enic-sriov-v2-admin-channel-v2-v1-0-82cc47636a78@cisco.com>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 20260401-enic-sriov-v2-prep-v4-0-d5834b2ef1b9@cisco.com, 
 Satish Kharat <satishkh@cisco.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775522225; l=9171;
 i=satishkh@cisco.com; h=from:subject:message-id;
 bh=KyHgU2YHxewnHE1Bfge3P6sARAqORdBDAgbx+yBXJR4=;
 b=zpjNGWcRI7TDsQKO7euLseFryzp64crMGJL2doQnb1/ja379K3iKms7Wmu9pMS9ca6lMmIt2U
 bZpkWz1Hm5/Cwp1siIWVbdRYvlTzVsjRwJmLOxYx6EsVnCyd0fplbpR
X-Developer-Key: i=satishkh@cisco.com; a=ed25519;
 pk=4BxbLoCGvHeIMH/PbpiNVx8/2IcTjFvqcr0AD8K6WLY=
X-Endpoint-Received: by B4 Relay for satishkh@cisco.com/default with auth_id=639
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement the mailbox protocol engine used for PF-VF communication
over the admin channel.

The send path (enic_mbox_send_msg) builds a message with a common
header, DMA-maps it, posts a single WQ descriptor with the
destination vnic ID encoded in the VLAN tag field, and polls
the WQ CQ for completion.

The receive path (enic_mbox_recv_handler) is installed as the admin
RQ callback and validates incoming message headers. PF/VF-specific
dispatch will be added in subsequent commits.

Signed-off-by: Satish Kharat <satishkh@cisco.com>
---
 drivers/net/ethernet/cisco/enic/Makefile     |   2 +-
 drivers/net/ethernet/cisco/enic/enic.h       |   5 +
 drivers/net/ethernet/cisco/enic/enic_admin.c |  23 +++-
 drivers/net/ethernet/cisco/enic/enic_mbox.c  | 153 +++++++++++++++++++++++++++
 drivers/net/ethernet/cisco/enic/enic_mbox.h  |   8 ++
 5 files changed, 189 insertions(+), 2 deletions(-)

diff --git a/drivers/net/ethernet/cisco/enic/Makefile b/drivers/net/ethernet/cisco/enic/Makefile
index 7ae72fefc99a..e38aaf34c148 100644
--- a/drivers/net/ethernet/cisco/enic/Makefile
+++ b/drivers/net/ethernet/cisco/enic/Makefile
@@ -4,5 +4,5 @@ obj-$(CONFIG_ENIC) := enic.o
 enic-y := enic_main.o vnic_cq.o vnic_intr.o vnic_wq.o \
 	enic_res.o enic_dev.o enic_pp.o vnic_dev.o vnic_rq.o vnic_vic.o \
 	enic_ethtool.o enic_api.o enic_clsf.o enic_rq.o enic_wq.o \
-	enic_admin.o
+	enic_admin.o enic_mbox.o
 
diff --git a/drivers/net/ethernet/cisco/enic/enic.h b/drivers/net/ethernet/cisco/enic/enic.h
index 9700fe14e51f..c2ca8d6a4a1c 100644
--- a/drivers/net/ethernet/cisco/enic/enic.h
+++ b/drivers/net/ethernet/cisco/enic/enic.h
@@ -292,6 +292,7 @@ struct enic {
 
 	/* Admin channel resources for SR-IOV MBOX */
 	bool has_admin_channel;
+	bool mbox_send_disabled;	/* set on send timeout; cleared on channel re-open */
 	struct vnic_wq admin_wq;
 	struct vnic_rq admin_rq;
 	struct vnic_cq admin_cq[2];
@@ -303,6 +304,10 @@ struct enic {
 	struct list_head admin_msg_list;
 	u64 admin_msg_drop_cnt;
 	void (*admin_rq_handler)(struct enic *enic, void *buf, unsigned int len);
+
+	/* MBOX protocol state */
+	struct mutex mbox_lock;
+	u64 mbox_msg_num;
 };
 
 static inline struct net_device *vnic_get_netdev(struct vnic_dev *vdev)
diff --git a/drivers/net/ethernet/cisco/enic/enic_admin.c b/drivers/net/ethernet/cisco/enic/enic_admin.c
index 31f9f754941e..d3ba2cf8f9d3 100644
--- a/drivers/net/ethernet/cisco/enic/enic_admin.c
+++ b/drivers/net/ethernet/cisco/enic/enic_admin.c
@@ -19,6 +19,7 @@
 #include "cq_enet_desc.h"
 #include "wq_enet_desc.h"
 #include "rq_enet_desc.h"
+#include "enic_mbox.h"
 
 /* No-op: admin WQ buffers are freed inline after completion polling */
 static void enic_admin_wq_buf_clean(struct vnic_wq *wq,
@@ -154,7 +155,26 @@ unsigned int enic_admin_rq_cq_service(struct enic *enic, unsigned int budget)
 					buf->dma_addr, buf->len,
 					DMA_FROM_DEVICE);
 
-		enic_admin_msg_enqueue(enic, buf->os_buf, buf->len);
+		if (enic->admin_rq_handler) {
+			struct cq_enet_rq_desc *rq_desc = desc;
+			u16 sender_vlan;
+
+			/* Firmware sets the CQ VLAN field to identify the
+			 * sender: 0 = PF, 1-based = VF index.  Overwrite
+			 * the untrusted src_vnic_id in the MBOX header with
+			 * the hardware-verified value.
+			 */
+			sender_vlan = le16_to_cpu(rq_desc->vlan);
+			if (buf->len >= sizeof(struct enic_mbox_hdr)) {
+				struct enic_mbox_hdr *hdr = buf->os_buf;
+
+				hdr->src_vnic_id = (sender_vlan == 0) ?
+					cpu_to_le16(ENIC_MBOX_DST_PF) :
+					cpu_to_le16(sender_vlan - 1);
+			}
+
+			enic_admin_msg_enqueue(enic, buf->os_buf, buf->len);
+		}
 
 		enic_admin_rq_buf_clean(rq, rq->to_clean);
 		rq->to_clean = rq->to_clean->next;
@@ -387,6 +407,7 @@ int enic_admin_channel_open(struct enic *enic)
 	if (!enic->has_admin_channel)
 		return -ENODEV;
 
+	enic->mbox_send_disabled = false;
 	err = enic_admin_alloc_resources(enic);
 	if (err) {
 		netdev_err(enic->netdev,
diff --git a/drivers/net/ethernet/cisco/enic/enic_mbox.c b/drivers/net/ethernet/cisco/enic/enic_mbox.c
new file mode 100644
index 000000000000..d7fee4353e14
--- /dev/null
+++ b/drivers/net/ethernet/cisco/enic/enic_mbox.c
@@ -0,0 +1,153 @@
+// SPDX-License-Identifier: GPL-2.0-only
+// Copyright 2025 Cisco Systems, Inc.  All rights reserved.
+
+#include <linux/kernel.h>
+#include <linux/netdevice.h>
+#include <linux/dma-mapping.h>
+#include <linux/delay.h>
+
+#include "vnic_dev.h"
+#include "vnic_wq.h"
+#include "vnic_cq.h"
+#include "enic.h"
+#include "enic_admin.h"
+#include "enic_mbox.h"
+#include "wq_enet_desc.h"
+
+#define ENIC_MBOX_POLL_TIMEOUT_US	5000000
+#define ENIC_MBOX_POLL_INTERVAL_US	100
+
+static void enic_mbox_fill_hdr(struct enic *enic, struct enic_mbox_hdr *hdr,
+			       u8 msg_type, u16 dst_vnic_id, u16 msg_len)
+{
+	memset(hdr, 0, sizeof(*hdr));
+	hdr->dst_vnic_id = cpu_to_le16(dst_vnic_id);
+	hdr->msg_type = msg_type;
+	hdr->msg_len = cpu_to_le16(msg_len);
+	hdr->msg_num = cpu_to_le64(++enic->mbox_msg_num);
+}
+
+int enic_mbox_send_msg(struct enic *enic, u8 msg_type, u16 dst_vnic_id,
+		       void *payload, u16 payload_len)
+{
+	u16 total_len = sizeof(struct enic_mbox_hdr) + payload_len;
+	struct vnic_wq *wq = &enic->admin_wq;
+	struct wq_enet_desc *desc;
+	dma_addr_t dma_addr;
+	unsigned long timeout;
+	u16 vlan_tag;
+	void *buf;
+	int err;
+
+	/* Serialize MBOX sends. The admin channel is a low-frequency
+	 * control path; holding the mutex across the poll is acceptable.
+	 */
+	mutex_lock(&enic->mbox_lock);
+
+	if (!enic->has_admin_channel || enic->mbox_send_disabled) {
+		err = -ENODEV;
+		goto unlock;
+	}
+
+	if (vnic_wq_desc_avail(wq) == 0) {
+		err = -ENOSPC;
+		goto unlock;
+	}
+
+	buf = kmalloc(total_len, GFP_KERNEL);
+	if (!buf) {
+		err = -ENOMEM;
+		goto unlock;
+	}
+
+	enic_mbox_fill_hdr(enic, buf, msg_type, dst_vnic_id, total_len);
+	if (payload_len)
+		memcpy(buf + sizeof(struct enic_mbox_hdr), payload, payload_len);
+
+	dma_addr = dma_map_single(&enic->pdev->dev, buf, total_len,
+				  DMA_TO_DEVICE);
+	if (dma_mapping_error(&enic->pdev->dev, dma_addr)) {
+		kfree(buf);
+		err = -ENOMEM;
+		goto unlock;
+	}
+
+	/* Firmware uses vlan field for routing: 0 = PF, 1-based = VF index */
+	if (dst_vnic_id == ENIC_MBOX_DST_PF)
+		vlan_tag = 0;
+	else
+		vlan_tag = dst_vnic_id + 1;
+
+	desc = vnic_wq_next_desc(wq);
+	wq_enet_desc_enc(desc, (u64)dma_addr | VNIC_PADDR_TARGET,
+			 total_len, 0, 0, 0, 1, 1, 0, 1, vlan_tag, 0);
+	vnic_wq_post(wq, buf, dma_addr, total_len, 1, 1, 1, 1, 0, 0);
+	vnic_wq_doorbell(wq);
+
+	timeout = jiffies + usecs_to_jiffies(ENIC_MBOX_POLL_TIMEOUT_US);
+	err = -ETIMEDOUT;
+	while (time_before(jiffies, timeout)) {
+		if (enic_admin_wq_cq_service(enic)) {
+			err = 0;
+			break;
+		}
+		usleep_range(ENIC_MBOX_POLL_INTERVAL_US,
+			     ENIC_MBOX_POLL_INTERVAL_US + 50);
+	}
+
+	if (!err) {
+		wq->to_clean = wq->to_clean->next;
+		wq->ring.desc_avail++;
+		dma_unmap_single(&enic->pdev->dev, dma_addr, total_len,
+				 DMA_TO_DEVICE);
+		kfree(buf);
+	} else {
+		netdev_err(enic->netdev,
+			   "MBOX send timed out (type %u dst %u), disabling channel\n",
+			   msg_type, dst_vnic_id);
+		/*
+		 * The WQ descriptor is still live in hardware. Do not unmap
+		 * or free the buffer: the device may still DMA from dma_addr.
+		 * Mark the channel unusable so no further sends are attempted.
+		 */
+		enic->mbox_send_disabled = true;
+	}
+
+	netdev_dbg(enic->netdev,
+		   "MBOX send msg_type %u dst %u vlan %u err %d\n",
+		   msg_type, dst_vnic_id, vlan_tag, err);
+unlock:
+	mutex_unlock(&enic->mbox_lock);
+	return err;
+}
+
+static void enic_mbox_recv_handler(struct enic *enic, void *buf,
+				   unsigned int len)
+{
+	struct enic_mbox_hdr *hdr = buf;
+
+	if (len < sizeof(*hdr)) {
+		netdev_warn(enic->netdev,
+			    "MBOX: truncated message (len %u < %zu)\n",
+			    len, sizeof(*hdr));
+		return;
+	}
+
+	if (hdr->msg_type >= ENIC_MBOX_MAX) {
+		netdev_warn(enic->netdev, "MBOX: unknown msg type %u\n",
+			    hdr->msg_type);
+		return;
+	}
+
+	netdev_dbg(enic->netdev,
+		   "MBOX recv: type %u from vnic %u len %u\n",
+		   hdr->msg_type, le16_to_cpu(hdr->src_vnic_id),
+		   le16_to_cpu(hdr->msg_len));
+}
+
+void enic_mbox_init(struct enic *enic)
+{
+	enic->mbox_msg_num = 0;
+	mutex_init(&enic->mbox_lock);
+	enic->admin_rq_handler = enic_mbox_recv_handler;
+}
diff --git a/drivers/net/ethernet/cisco/enic/enic_mbox.h b/drivers/net/ethernet/cisco/enic/enic_mbox.h
index 84cb6bbc1ead..554269b78780 100644
--- a/drivers/net/ethernet/cisco/enic/enic_mbox.h
+++ b/drivers/net/ethernet/cisco/enic/enic_mbox.h
@@ -72,4 +72,12 @@ struct enic_mbox_pf_link_state_ack_msg {
 	struct enic_mbox_generic_reply ack;
 };
 
+#define ENIC_MBOX_DST_PF	0xFFFF
+
+struct enic;
+
+void enic_mbox_init(struct enic *enic);
+int enic_mbox_send_msg(struct enic *enic, u8 msg_type, u16 dst_vnic_id,
+		       void *payload, u16 payload_len);
+
 #endif /* _ENIC_MBOX_H_ */

-- 
2.43.0

