From: Satish Kharat <satishkh@cisco.com>
Date: Wed, 08 Apr 2026 08:08:18 -0700
Subject: [PATCH net-next v2 08/10] enic: add MBOX VF handlers for
 capability, register and link state
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260408-enic-sriov-v2-admin-channel-v2-v2-8-d05dd3623fd3@cisco.com>
References: <20260408-enic-sriov-v2-admin-channel-v2-v2-0-d05dd3623fd3@cisco.com>
In-Reply-To: <20260408-enic-sriov-v2-admin-channel-v2-v2-0-d05dd3623fd3@cisco.com>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 20260401-enic-sriov-v2-prep-v4-0-d5834b2ef1b9@cisco.com, 
 Satish Kharat <satishkh@cisco.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775660895; l=10195;
 i=satishkh@cisco.com; h=from:subject:message-id;
 bh=c/xdedJo5W/dkeP1++NJVvDZiX+AvYqQJRbzpDZ1zA0=;
 b=Bj5zudYvSf4TTdCUeD68LCnoKtalPRlqQ5N15WfaKJo53vy/FUQJMHcVsT781tK2NvsNrYR1n
 5/A6mpYh0q3D4LwXV0OC0Mh4mntgLBhHRSDxFAY32R3hwiIPIwjIfZN
X-Developer-Key: i=satishkh@cisco.com; a=ed25519;
 pk=4BxbLoCGvHeIMH/PbpiNVx8/2IcTjFvqcr0AD8K6WLY=
X-Endpoint-Received: by B4 Relay for satishkh@cisco.com/default with auth_id=639
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement VF-side mailbox message processing for SR-IOV V2
admin channel communication.

VF receive handlers:
  - VF_CAPABILITY_REPLY: store PF protocol version, signal
    completion
  - VF_REGISTER_REPLY: mark VF as registered, signal completion
  - VF_UNREGISTER_REPLY: mark VF as unregistered, signal
    completion
  - PF_LINK_STATE_NOTIF: update carrier state via
    netif_carrier_on/off, send ACK back to PF

VF initiation functions for the probe-time handshake:
  - enic_mbox_vf_capability_check: send capability request,
    wait for PF reply via completion
  - enic_mbox_vf_register: send register request, wait for
    PF confirmation via completion
  - enic_mbox_vf_unregister: send unregister request, wait
    for PF confirmation

The wait helper (enic_mbox_wait_reply) uses
wait_for_completion_timeout, signaled when the admin ISR/NAPI/
workqueue pipeline delivers the reply message.

Signed-off-by: Satish Kharat <satishkh@cisco.com>
---
 drivers/net/ethernet/cisco/enic/enic.h      |   9 +-
 drivers/net/ethernet/cisco/enic/enic_mbox.c | 220 ++++++++++++++++++++++++++++
 drivers/net/ethernet/cisco/enic/enic_mbox.h |   3 +
 3 files changed, 231 insertions(+), 1 deletion(-)

diff --git a/drivers/net/ethernet/cisco/enic/enic.h b/drivers/net/ethernet/cisco/enic/enic.h
index 9b1fa3857df5..29ce26284493 100644
--- a/drivers/net/ethernet/cisco/enic/enic.h
+++ b/drivers/net/ethernet/cisco/enic/enic.h
@@ -258,6 +258,8 @@ struct enic {
 	u32 tx_coalesce_usecs;
 	u16 num_vfs;
 	enum enic_vf_type vf_type;
+	bool vf_registered;
+	u32 pf_cap_version;
 	unsigned int enable_count;
 	spinlock_t enic_api_lock;
 	bool enic_api_busy;
@@ -305,9 +307,14 @@ struct enic {
 	void (*admin_rq_handler)(struct enic *enic, void *buf,
 				 unsigned int len);
 
-	/* MBOX protocol state */
+	/* MBOX protocol state -- single-flight: on the VF, all callers
+	 * that wait on mbox_comp run under RTNL or during probe/remove,
+	 * so only one completion is outstanding at a time. mbox_lock
+	 * protects the shared admin WQ from concurrent senders.
+	 */
 	struct mutex mbox_lock;
 	u64 mbox_msg_num;
+	struct completion mbox_comp;
 
 	/* PF: per-VF MBOX state, allocated when SRIOV V2 is enabled */
 	struct enic_vf_state {
diff --git a/drivers/net/ethernet/cisco/enic/enic_mbox.c b/drivers/net/ethernet/cisco/enic/enic_mbox.c
index eb5049b538b1..0db05b124557 100644
--- a/drivers/net/ethernet/cisco/enic/enic_mbox.c
+++ b/drivers/net/ethernet/cisco/enic/enic_mbox.c
@@ -5,6 +5,7 @@
 #include <linux/netdevice.h>
 #include <linux/dma-mapping.h>
 #include <linux/delay.h>
+#include <linux/completion.h>
 
 #include "vnic_dev.h"
 #include "vnic_wq.h"
@@ -124,6 +125,16 @@ int enic_mbox_send_msg(struct enic *enic, u8 msg_type, u16 dst_vnic_id,
 	return err;
 }
 
+static int enic_mbox_wait_reply(struct enic *enic, unsigned long timeout_ms)
+{
+	unsigned long left;
+
+	left = wait_for_completion_timeout(&enic->mbox_comp,
+					   msecs_to_jiffies(timeout_ms));
+
+	return left ? 0 : -ETIMEDOUT;
+}
+
 int enic_mbox_send_link_state(struct enic *enic, u16 vf_id, u32 link_state)
 {
 	struct enic_mbox_pf_link_state_notif_msg notif = {};
@@ -280,6 +291,136 @@ static void enic_mbox_pf_process_msg(struct enic *enic,
 			    hdr->msg_type, vf_id, err);
 }
 
+static void enic_mbox_vf_handle_capability_reply(struct enic *enic,
+						 void *payload)
+{
+	struct enic_mbox_vf_capability_reply_msg *reply = payload;
+
+	if (le16_to_cpu(reply->reply.ret_major) == 0)
+		enic->pf_cap_version = le32_to_cpu(reply->version);
+	complete(&enic->mbox_comp);
+}
+
+static void enic_mbox_vf_handle_register_reply(struct enic *enic,
+					       void *payload)
+{
+	struct enic_mbox_vf_register_reply_msg *reply = payload;
+
+	if (le16_to_cpu(reply->reply.ret_major)) {
+		netdev_warn(enic->netdev,
+			    "MBOX: VF register rejected by PF: %u/%u\n",
+			    le16_to_cpu(reply->reply.ret_major),
+			    le16_to_cpu(reply->reply.ret_minor));
+	} else {
+		enic->vf_registered = true;
+	}
+	complete(&enic->mbox_comp);
+}
+
+static void enic_mbox_vf_handle_unregister_reply(struct enic *enic,
+						 void *payload)
+{
+	struct enic_mbox_vf_register_reply_msg *reply = payload;
+
+	if (le16_to_cpu(reply->reply.ret_major)) {
+		netdev_warn(enic->netdev,
+			    "MBOX: VF unregister rejected by PF: %u/%u\n",
+			    le16_to_cpu(reply->reply.ret_major),
+			    le16_to_cpu(reply->reply.ret_minor));
+	} else {
+		enic->vf_registered = false;
+	}
+	complete(&enic->mbox_comp);
+}
+
+static void enic_mbox_vf_handle_link_state(struct enic *enic, void *payload)
+{
+	struct enic_mbox_pf_link_state_notif_msg *notif = payload;
+	struct enic_mbox_pf_link_state_ack_msg ack = {};
+
+	switch (le32_to_cpu(notif->link_state)) {
+	case ENIC_MBOX_LINK_STATE_ENABLE:
+		if (!netif_carrier_ok(enic->netdev))
+			netif_carrier_on(enic->netdev);
+		netdev_dbg(enic->netdev, "MBOX: link state -> UP\n");
+		break;
+	case ENIC_MBOX_LINK_STATE_DISABLE:
+		if (netif_carrier_ok(enic->netdev))
+			netif_carrier_off(enic->netdev);
+		netdev_dbg(enic->netdev, "MBOX: link state -> DOWN\n");
+		break;
+	default:
+		netdev_warn(enic->netdev, "MBOX: unknown link state %u\n",
+			    le32_to_cpu(notif->link_state));
+		ack.ack.ret_major = cpu_to_le16(ENIC_MBOX_ERR_GENERIC);
+		break;
+	}
+
+	enic_mbox_send_msg(enic, ENIC_MBOX_PF_LINK_STATE_ACK, ENIC_MBOX_DST_PF,
+			   &ack, sizeof(ack));
+}
+
+static bool enic_mbox_vf_payload_ok(struct enic *enic, u8 msg_type,
+				    u16 payload_len, size_t min_len)
+{
+	if (payload_len < min_len) {
+		netdev_warn(enic->netdev,
+			    "MBOX: short payload for type %u (%u < %zu)\n",
+			    msg_type, payload_len, min_len);
+		return false;
+	}
+	return true;
+}
+
+static void enic_mbox_vf_process_msg(struct enic *enic,
+				     struct enic_mbox_hdr *hdr, void *payload,
+				     u16 payload_len)
+{
+	switch (hdr->msg_type) {
+	case ENIC_MBOX_VF_CAPABILITY_REPLY: {
+		size_t exp = sizeof(struct enic_mbox_vf_capability_reply_msg);
+
+		if (!enic_mbox_vf_payload_ok(enic, hdr->msg_type,
+					     payload_len, exp))
+			return;
+		enic_mbox_vf_handle_capability_reply(enic, payload);
+		break;
+	}
+	case ENIC_MBOX_VF_REGISTER_REPLY: {
+		size_t exp = sizeof(struct enic_mbox_vf_register_reply_msg);
+
+		if (!enic_mbox_vf_payload_ok(enic, hdr->msg_type,
+					     payload_len, exp))
+			return;
+		enic_mbox_vf_handle_register_reply(enic, payload);
+		break;
+	}
+	case ENIC_MBOX_VF_UNREGISTER_REPLY: {
+		size_t exp = sizeof(struct enic_mbox_vf_register_reply_msg);
+
+		if (!enic_mbox_vf_payload_ok(enic, hdr->msg_type,
+					     payload_len, exp))
+			return;
+		enic_mbox_vf_handle_unregister_reply(enic, payload);
+		break;
+	}
+	case ENIC_MBOX_PF_LINK_STATE_NOTIF: {
+		size_t exp = sizeof(struct enic_mbox_pf_link_state_notif_msg);
+
+		if (!enic_mbox_vf_payload_ok(enic, hdr->msg_type,
+					     payload_len, exp))
+			return;
+		enic_mbox_vf_handle_link_state(enic, payload);
+		break;
+	}
+	default:
+		netdev_dbg(enic->netdev,
+			   "MBOX: VF unhandled msg type %u\n",
+			   hdr->msg_type);
+		break;
+	}
+}
+
 static void enic_mbox_recv_handler(struct enic *enic, void *buf,
 				   unsigned int len)
 {
@@ -316,11 +457,90 @@ static void enic_mbox_recv_handler(struct enic *enic, void *buf,
 
 	if (enic->vf_state)
 		enic_mbox_pf_process_msg(enic, hdr, payload);
+	else
+		enic_mbox_vf_process_msg(enic, hdr, payload,
+					 msg_len - (u16)sizeof(*hdr));
+}
+
+int enic_mbox_vf_capability_check(struct enic *enic)
+{
+	struct enic_mbox_vf_capability_msg req = {};
+	int err;
+
+	enic->pf_cap_version = 0;
+	reinit_completion(&enic->mbox_comp);
+	req.version = cpu_to_le32(ENIC_MBOX_CAP_VERSION_1);
+
+	err = enic_mbox_send_msg(enic, ENIC_MBOX_VF_CAPABILITY_REQUEST,
+				 ENIC_MBOX_DST_PF, &req, sizeof(req));
+	if (err)
+		return err;
+
+	err = enic_mbox_wait_reply(enic, 3000);
+	if (err) {
+		netdev_warn(enic->netdev,
+			    "MBOX: no capability reply from PF\n");
+		return err;
+	}
+
+	if (enic->pf_cap_version < ENIC_MBOX_CAP_VERSION_1) {
+		netdev_warn(enic->netdev,
+			    "MBOX: PF version %u too old\n",
+			    enic->pf_cap_version);
+		return -EOPNOTSUPP;
+	}
+
+	return 0;
+}
+
+int enic_mbox_vf_register(struct enic *enic)
+{
+	int err;
+
+	enic->vf_registered = false;
+	reinit_completion(&enic->mbox_comp);
+
+	err = enic_mbox_send_msg(enic, ENIC_MBOX_VF_REGISTER_REQUEST,
+				 ENIC_MBOX_DST_PF, NULL, 0);
+	if (err)
+		return err;
+
+	err = enic_mbox_wait_reply(enic, 3000);
+	if (err) {
+		netdev_warn(enic->netdev,
+			    "MBOX: VF registration with PF timed out\n");
+		return err;
+	}
+
+	if (!enic->vf_registered)
+		return -ENODEV;
+
+	return 0;
+}
+
+int enic_mbox_vf_unregister(struct enic *enic)
+{
+	int err;
+
+	if (!enic->vf_registered)
+		return 0;
+
+	reinit_completion(&enic->mbox_comp);
+
+	err = enic_mbox_send_msg(enic, ENIC_MBOX_VF_UNREGISTER_REQUEST,
+				 ENIC_MBOX_DST_PF, NULL, 0);
+	if (err)
+		return err;
+
+	err = enic_mbox_wait_reply(enic, 3000);
+
+	return enic->vf_registered ? -ETIMEDOUT : 0;
 }
 
 void enic_mbox_init(struct enic *enic)
 {
 	enic->mbox_msg_num = 0;
 	mutex_init(&enic->mbox_lock);
+	init_completion(&enic->mbox_comp);
 	enic->admin_rq_handler = enic_mbox_recv_handler;
 }
diff --git a/drivers/net/ethernet/cisco/enic/enic_mbox.h b/drivers/net/ethernet/cisco/enic/enic_mbox.h
index a6f6798d14f4..fa2fb08bf7d0 100644
--- a/drivers/net/ethernet/cisco/enic/enic_mbox.h
+++ b/drivers/net/ethernet/cisco/enic/enic_mbox.h
@@ -80,5 +80,8 @@ void enic_mbox_init(struct enic *enic);
 int enic_mbox_send_msg(struct enic *enic, u8 msg_type, u16 dst_vnic_id,
 		       void *payload, u16 payload_len);
 int enic_mbox_send_link_state(struct enic *enic, u16 vf_id, u32 link_state);
+int enic_mbox_vf_capability_check(struct enic *enic);
+int enic_mbox_vf_register(struct enic *enic);
+int enic_mbox_vf_unregister(struct enic *enic);
 
 #endif /* _ENIC_MBOX_H_ */

-- 
2.43.0

