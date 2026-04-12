From: Satish Kharat <satishkh@cisco.com>
Date: Sat, 11 Apr 2026 22:06:33 -0700
Subject: [PATCH net-next v4 07/10] enic: add MBOX PF handlers for VF
 register and capability
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260411-enic-sriov-v2-admin-channel-v2-v4-7-f052326c2a57@cisco.com>
References: <20260411-enic-sriov-v2-admin-channel-v2-v4-0-f052326c2a57@cisco.com>
In-Reply-To: <20260411-enic-sriov-v2-admin-channel-v2-v4-0-f052326c2a57@cisco.com>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 20260401-enic-sriov-v2-prep-v4-0-d5834b2ef1b9@cisco.com, 
 Satish Kharat <satishkh@cisco.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775970405; l=8596;
 i=satishkh@cisco.com; h=from:subject:message-id;
 bh=voSggtCvoLR86bnwm0YX5Xzvd2ag0bnsbyTA17MN1+A=;
 b=+ER1+9hyf44bOdodcYQIMJXeH2U/+IrU/rR3/YfYZL2TvWFvo08Ci7nLzycy96Khqy+Gmb+ga
 zTF5WUbHvdZBCrOD3GN8MUAeRUCt025sAkFVZ/nsi91wH5/UWaZc0RF
X-Developer-Key: i=satishkh@cisco.com; a=ed25519;
 pk=4BxbLoCGvHeIMH/PbpiNVx8/2IcTjFvqcr0AD8K6WLY=
X-Endpoint-Received: by B4 Relay for satishkh@cisco.com/default with auth_id=639
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement PF-side mailbox message processing for SR-IOV V2
admin channel communication.

When the PF receives messages from VFs, the dispatch routes
them to type-specific handlers:
  - VF_CAPABILITY_REQUEST: reply with protocol version 1
  - VF_REGISTER_REQUEST: mark VF registered, reply, then
    send PF_LINK_STATE_NOTIF with link enabled
  - VF_UNREGISTER_REQUEST: mark VF unregistered, send reply
  - PF_LINK_STATE_ACK: log errors from VF acknowledgment

Per-VF state (struct enic_vf_state) is tracked via enic->vf_state
which will be allocated when SRIOV V2 is enabled.

Remove the CONFIG_PCI_IOV guard from num_vfs in struct enic. The
PF handlers reference enic->num_vfs for VF ID bounds checking in
enic_mbox.c, which is compiled unconditionally. The field must be
visible regardless of CONFIG_PCI_IOV to avoid build failures.

Add enic_mbox_send_link_state() helper for PF-initiated link
state notifications, also used later by ndo_set_vf_link_state.

Signed-off-by: Satish Kharat <satishkh@cisco.com>
---
 drivers/net/ethernet/cisco/enic/enic.h      |   7 +-
 drivers/net/ethernet/cisco/enic/enic_mbox.c | 174 +++++++++++++++++++++++++++-
 drivers/net/ethernet/cisco/enic/enic_mbox.h |   1 +
 3 files changed, 178 insertions(+), 4 deletions(-)

diff --git a/drivers/net/ethernet/cisco/enic/enic.h b/drivers/net/ethernet/cisco/enic/enic.h
index 42f345aceced..9b1fa3857df5 100644
--- a/drivers/net/ethernet/cisco/enic/enic.h
+++ b/drivers/net/ethernet/cisco/enic/enic.h
@@ -256,9 +256,7 @@ struct enic {
 	struct enic_rx_coal rx_coalesce_setting;
 	u32 rx_coalesce_usecs;
 	u32 tx_coalesce_usecs;
-#ifdef CONFIG_PCI_IOV
 	u16 num_vfs;
-#endif
 	enum enic_vf_type vf_type;
 	unsigned int enable_count;
 	spinlock_t enic_api_lock;
@@ -310,6 +308,11 @@ struct enic {
 	/* MBOX protocol state */
 	struct mutex mbox_lock;
 	u64 mbox_msg_num;
+
+	/* PF: per-VF MBOX state, allocated when SRIOV V2 is enabled */
+	struct enic_vf_state {
+		bool registered;
+	} *vf_state;
 };
 
 static inline struct net_device *vnic_get_netdev(struct vnic_dev *vdev)
diff --git a/drivers/net/ethernet/cisco/enic/enic_mbox.c b/drivers/net/ethernet/cisco/enic/enic_mbox.c
index d144c86d9ef8..f5784624ebbd 100644
--- a/drivers/net/ethernet/cisco/enic/enic_mbox.c
+++ b/drivers/net/ethernet/cisco/enic/enic_mbox.c
@@ -124,10 +124,168 @@ int enic_mbox_send_msg(struct enic *enic, u8 msg_type, u16 dst_vnic_id,
 	return err;
 }
 
+int enic_mbox_send_link_state(struct enic *enic, u16 vf_id, u32 link_state)
+{
+	struct enic_mbox_pf_link_state_notif_msg notif = {};
+
+	if (!enic->vf_state || vf_id >= enic->num_vfs ||
+	    !enic->vf_state[vf_id].registered) {
+		netdev_dbg(enic->netdev,
+			   "MBOX: skip link state to unregistered VF %u\n",
+			   vf_id);
+		return 0;
+	}
+
+	notif.link_state = cpu_to_le32(link_state);
+	return enic_mbox_send_msg(enic, ENIC_MBOX_PF_LINK_STATE_NOTIF, vf_id,
+				  &notif, sizeof(notif));
+}
+
+static int enic_mbox_pf_handle_capability(struct enic *enic, void *msg,
+					  u16 vf_id, u64 msg_num)
+{
+	struct enic_mbox_vf_capability_reply_msg reply = {};
+
+	reply.reply.ret_major = cpu_to_le16(0);
+	reply.version = cpu_to_le32(ENIC_MBOX_CAP_VERSION_1);
+
+	return enic_mbox_send_msg(enic, ENIC_MBOX_VF_CAPABILITY_REPLY, vf_id,
+				  &reply, sizeof(reply));
+}
+
+static int enic_mbox_pf_handle_register(struct enic *enic, void *msg,
+					u16 vf_id, u64 msg_num)
+{
+	struct enic_mbox_vf_register_reply_msg reply = {};
+	int err;
+
+	if (!enic->vf_state || vf_id >= enic->num_vfs) {
+		netdev_warn(enic->netdev,
+			    "MBOX: register from invalid VF %u\n", vf_id);
+		return -EINVAL;
+	}
+
+	/* VF re-registering (e.g. guest reboot without clean unregister):
+	 * mark the previous registration inactive before accepting the new one.
+	 */
+	if (enic->vf_state[vf_id].registered) {
+		netdev_dbg(enic->netdev,
+			   "MBOX: VF %u re-register, cleaning previous state\n",
+			   vf_id);
+		enic->vf_state[vf_id].registered = false;
+	}
+
+	reply.reply.ret_major = cpu_to_le16(0);
+	err = enic_mbox_send_msg(enic, ENIC_MBOX_VF_REGISTER_REPLY, vf_id,
+				 &reply, sizeof(reply));
+	if (err)
+		return err;
+
+	enic->vf_state[vf_id].registered = true;
+	netdev_info(enic->netdev, "VF %u registered via MBOX\n", vf_id);
+
+	err = enic_mbox_send_link_state(enic, vf_id,
+					ENIC_MBOX_LINK_STATE_ENABLE);
+	if (err)
+		netdev_warn(enic->netdev,
+			    "VF %u: failed to send initial link state: %d\n",
+			    vf_id, err);
+	/* Registration succeeded; link state will be (re-)sent on next
+	 * enic_link_check() event.
+	 */
+	return 0;
+}
+
+static int enic_mbox_pf_handle_unregister(struct enic *enic, void *msg,
+					  u16 vf_id, u64 msg_num)
+{
+	struct enic_mbox_vf_register_reply_msg reply = {};
+	int err;
+
+	if (!enic->vf_state || vf_id >= enic->num_vfs) {
+		netdev_warn(enic->netdev,
+			    "MBOX: unregister from invalid VF %u\n", vf_id);
+		return -EINVAL;
+	}
+
+	reply.reply.ret_major = cpu_to_le16(0);
+	err = enic_mbox_send_msg(enic, ENIC_MBOX_VF_UNREGISTER_REPLY, vf_id,
+				 &reply, sizeof(reply));
+	if (err)
+		return err;
+
+	enic->vf_state[vf_id].registered = false;
+
+	netdev_info(enic->netdev, "VF %u unregistered via MBOX\n", vf_id);
+
+	return 0;
+}
+
+static void enic_mbox_pf_process_msg(struct enic *enic,
+				     struct enic_mbox_hdr *hdr, void *payload)
+{
+	u16 vf_id = le16_to_cpu(hdr->src_vnic_id);
+	u16 msg_len = le16_to_cpu(hdr->msg_len);
+	int err = 0;
+
+	if (!enic->vf_state) {
+		netdev_dbg(enic->netdev,
+			   "MBOX: PF received msg but SRIOV not active\n");
+		return;
+	}
+
+	if (vf_id >= enic->num_vfs) {
+		netdev_warn(enic->netdev,
+			    "MBOX: PF received msg from invalid VF %u\n",
+			    vf_id);
+		return;
+	}
+
+	switch (hdr->msg_type) {
+	case ENIC_MBOX_VF_CAPABILITY_REQUEST:
+		err = enic_mbox_pf_handle_capability(enic, payload, vf_id,
+						     le64_to_cpu(hdr->msg_num));
+		break;
+	case ENIC_MBOX_VF_REGISTER_REQUEST:
+		err = enic_mbox_pf_handle_register(enic, payload, vf_id,
+						   le64_to_cpu(hdr->msg_num));
+		break;
+	case ENIC_MBOX_VF_UNREGISTER_REQUEST:
+		err = enic_mbox_pf_handle_unregister(enic, payload, vf_id,
+						     le64_to_cpu(hdr->msg_num));
+		break;
+	case ENIC_MBOX_PF_LINK_STATE_ACK: {
+		struct enic_mbox_pf_link_state_ack_msg *ack = payload;
+
+		if (msg_len < sizeof(*hdr) + sizeof(*ack))
+			break;
+		if (le16_to_cpu(ack->ack.ret_major))
+			netdev_warn(enic->netdev,
+				    "MBOX: VF %u link state ACK error %u/%u\n",
+				    vf_id, le16_to_cpu(ack->ack.ret_major),
+				    le16_to_cpu(ack->ack.ret_minor));
+		break;
+	}
+	default:
+		netdev_dbg(enic->netdev,
+			   "MBOX: PF unhandled msg type %u from VF %u\n",
+			   hdr->msg_type, vf_id);
+		err = -EOPNOTSUPP;
+		break;
+	}
+
+	if (err)
+		netdev_warn(enic->netdev,
+			    "MBOX: PF handler for msg type %u from VF %u failed: %d\n",
+			    hdr->msg_type, vf_id, err);
+}
+
 static void enic_mbox_recv_handler(struct enic *enic, void *buf,
 				   unsigned int len)
 {
 	struct enic_mbox_hdr *hdr = buf;
+	void *payload;
+	u16 msg_len;
 
 	if (len < sizeof(*hdr)) {
 		netdev_warn(enic->netdev,
@@ -142,10 +300,22 @@ static void enic_mbox_recv_handler(struct enic *enic, void *buf,
 		return;
 	}
 
+	msg_len = le16_to_cpu(hdr->msg_len);
+	if (msg_len < sizeof(*hdr) || msg_len > len) {
+		netdev_warn(enic->netdev,
+			    "MBOX: invalid msg_len %u (buf len %u)\n",
+			    msg_len, len);
+		return;
+	}
+
 	netdev_dbg(enic->netdev,
 		   "MBOX recv: type %u from vnic %u len %u\n",
-		   hdr->msg_type, le16_to_cpu(hdr->src_vnic_id),
-		   le16_to_cpu(hdr->msg_len));
+		   hdr->msg_type, le16_to_cpu(hdr->src_vnic_id), msg_len);
+
+	payload = buf + sizeof(*hdr);
+
+	if (enic->vf_state)
+		enic_mbox_pf_process_msg(enic, hdr, payload);
 }
 
 void enic_mbox_init(struct enic *enic)
diff --git a/drivers/net/ethernet/cisco/enic/enic_mbox.h b/drivers/net/ethernet/cisco/enic/enic_mbox.h
index 554269b78780..a6f6798d14f4 100644
--- a/drivers/net/ethernet/cisco/enic/enic_mbox.h
+++ b/drivers/net/ethernet/cisco/enic/enic_mbox.h
@@ -79,5 +79,6 @@ struct enic;
 void enic_mbox_init(struct enic *enic);
 int enic_mbox_send_msg(struct enic *enic, u8 msg_type, u16 dst_vnic_id,
 		       void *payload, u16 payload_len);
+int enic_mbox_send_link_state(struct enic *enic, u16 vf_id, u32 link_state);
 
 #endif /* _ENIC_MBOX_H_ */

-- 
2.43.0

