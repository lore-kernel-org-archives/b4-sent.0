From: Satish Kharat <satishkh@cisco.com>
Date: Thu, 06 Mar 2025 19:15:24 -0500
Subject: [PATCH net-next v3 3/8] enic: enic rq extended cq defines
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250306-enic_cleanup_and_ext_cq-v3-3-92bc165344cf@cisco.com>
References: <20250306-enic_cleanup_and_ext_cq-v3-0-92bc165344cf@cisco.com>
In-Reply-To: <20250306-enic_cleanup_and_ext_cq-v3-0-92bc165344cf@cisco.com>
To: Christian Benvenuti <benve@cisco.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Satish Kharat <satishkh@cisco.com>, Nelson Escobar <neescoba@cisco.com>, 
 John Daley <johndale@cisco.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741306525; l=4129;
 i=satishkh@cisco.com; s=20250226; h=from:subject:message-id;
 bh=lCdejaRbYIFkRngxAAsLt06YyI38y1e/5BxDAW6GFew=;
 b=3Dxv3R0Zy/UhbcMK65CliRw0sfVUjFR0RyHB/NDN6hmZhCHvRROSuamiKYzJm5pnvGnHx3NZS
 MRjhF9txuulCj+cTGYN3d8/8S/Tjcae5Dr9nwEOQoSgzgk3QDmJKwFq
X-Developer-Key: i=satishkh@cisco.com; a=ed25519;
 pk=lkxzORFYn5ejiy0kzcsfkpGoXZDcnHMc4n3YK7jJnJo=
X-Endpoint-Received: by B4 Relay for satishkh@cisco.com/20250226 with auth_id=351
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds the defines for 32 and 64 byte receive queue completion queue
descriptors.
Adds devcmd define to get rq cq descriptor size/s supported by hw.

Co-developed-by: Nelson Escobar <neescoba@cisco.com>
Signed-off-by: Nelson Escobar <neescoba@cisco.com>
Co-developed-by: John Daley <johndale@cisco.com>
Signed-off-by: John Daley <johndale@cisco.com>
Signed-off-by: Satish Kharat <satishkh@cisco.com>
---
 drivers/net/ethernet/cisco/enic/cq_enet_desc.h | 56 ++++++++++++++++++++++++++
 drivers/net/ethernet/cisco/enic/vnic_devcmd.h  | 19 +++++++++
 2 files changed, 75 insertions(+)

diff --git a/drivers/net/ethernet/cisco/enic/cq_enet_desc.h b/drivers/net/ethernet/cisco/enic/cq_enet_desc.h
index 6abc134d07032a737c8b3d2987e3c7a4b8191991..809a3f30b87f78285414990a2a42c9a30a8662c6 100644
--- a/drivers/net/ethernet/cisco/enic/cq_enet_desc.h
+++ b/drivers/net/ethernet/cisco/enic/cq_enet_desc.h
@@ -24,6 +24,23 @@ static inline void cq_enet_wq_desc_dec(struct cq_enet_wq_desc *desc,
 		color, q_number, completed_index);
 }
 
+/*
+ * Defines and Capabilities for CMD_CQ_ENTRY_SIZE_SET
+ */
+#define VNIC_RQ_ALL (~0ULL)
+
+#define VNIC_RQ_CQ_ENTRY_SIZE_16 0
+#define VNIC_RQ_CQ_ENTRY_SIZE_32 1
+#define VNIC_RQ_CQ_ENTRY_SIZE_64 2
+
+#define VNIC_RQ_CQ_ENTRY_SIZE_16_CAPABLE BIT(VNIC_RQ_CQ_ENTRY_SIZE_16)
+#define VNIC_RQ_CQ_ENTRY_SIZE_32_CAPABLE BIT(VNIC_RQ_CQ_ENTRY_SIZE_32)
+#define VNIC_RQ_CQ_ENTRY_SIZE_64_CAPABLE BIT(VNIC_RQ_CQ_ENTRY_SIZE_64)
+
+#define VNIC_RQ_CQ_ENTRY_SIZE_ALL_BIT  (VNIC_RQ_CQ_ENTRY_SIZE_16_CAPABLE | \
+					VNIC_RQ_CQ_ENTRY_SIZE_32_CAPABLE | \
+					VNIC_RQ_CQ_ENTRY_SIZE_64_CAPABLE)
+
 /* Completion queue descriptor: Ethernet receive queue, 16B */
 struct cq_enet_rq_desc {
 	__le16 completed_index_flags;
@@ -36,6 +53,45 @@ struct cq_enet_rq_desc {
 	u8 type_color;
 };
 
+/* Completion queue descriptor: Ethernet receive queue, 32B */
+struct cq_enet_rq_desc_32 {
+	__le16 completed_index_flags;
+	__le16 q_number_rss_type_flags;
+	__le32 rss_hash;
+	__le16 bytes_written_flags;
+	__le16 vlan;
+	__le16 checksum_fcoe;
+	u8 flags;
+	u8 fetch_index_flags;
+	__le32 time_stamp;
+	__le16 time_stamp2;
+	__le16 pie_info;
+	__le32 pie_info2;
+	__le16 pie_info3;
+	u8 pie_info4;
+	u8 type_color;
+};
+
+/* Completion queue descriptor: Ethernet receive queue, 64B */
+struct cq_enet_rq_desc_64 {
+	__le16 completed_index_flags;
+	__le16 q_number_rss_type_flags;
+	__le32 rss_hash;
+	__le16 bytes_written_flags;
+	__le16 vlan;
+	__le16 checksum_fcoe;
+	u8 flags;
+	u8 fetch_index_flags;
+	__le32 time_stamp;
+	__le16 time_stamp2;
+	__le16 pie_info;
+	__le32 pie_info2;
+	__le16 pie_info3;
+	u8 pie_info4;
+	u8 reserved[32];
+	u8 type_color;
+};
+
 #define CQ_ENET_RQ_DESC_FLAGS_INGRESS_PORT          (0x1 << 12)
 #define CQ_ENET_RQ_DESC_FLAGS_FCOE                  (0x1 << 13)
 #define CQ_ENET_RQ_DESC_FLAGS_EOP                   (0x1 << 14)
diff --git a/drivers/net/ethernet/cisco/enic/vnic_devcmd.h b/drivers/net/ethernet/cisco/enic/vnic_devcmd.h
index db56d778877a73b0ef2adf59120cbc57999732ee..605ef17f967e4a7d62738b776bf4dbfdf172ba2a 100644
--- a/drivers/net/ethernet/cisco/enic/vnic_devcmd.h
+++ b/drivers/net/ethernet/cisco/enic/vnic_devcmd.h
@@ -436,6 +436,25 @@ enum vnic_devcmd_cmd {
 	 * in: (u16) a2 = unsigned short int port information
 	 */
 	CMD_OVERLAY_OFFLOAD_CFG = _CMDC(_CMD_DIR_WRITE, _CMD_VTYPE_ENET, 73),
+
+	/*
+	 * Set extended CQ field in MREGS of RQ (or all RQs)
+	 * for given vNIC
+	 * in: (u64) a0 = RQ selection (VNIC_RQ_ALL for all RQs)
+	 *     (u32) a1 = CQ entry size
+	 *         VNIC_RQ_CQ_ENTRY_SIZE_16 --> 16 bytes
+	 *         VNIC_RQ_CQ_ENTRY_SIZE_32 --> 32 bytes
+	 *         VNIC_RQ_CQ_ENTRY_SIZE_64 --> 64 bytes
+	 *
+	 * Capability query:
+	 * out: (u32) a0 = errno, 0:valid cmd
+	 *      (u32) a1 = value consisting of supported entries
+	 *         bit 0: 16 bytes
+	 *         bit 1: 32 bytes
+	 *         bit 2: 64 bytes
+	 */
+	CMD_CQ_ENTRY_SIZE_SET = _CMDC(_CMD_DIR_WRITE, _CMD_VTYPE_ENET, 90),
+
 };
 
 /* CMD_ENABLE2 flags */

-- 
2.48.1

