From: Satish Kharat <satishkh@cisco.com>
Date: Tue, 04 Mar 2025 19:56:40 -0500
Subject: [PATCH net-next v2 4/8] enic: enable rq extended cq support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250304-enic_cleanup_and_ext_cq-v2-4-85804263dad8@cisco.com>
References: <20250304-enic_cleanup_and_ext_cq-v2-0-85804263dad8@cisco.com>
In-Reply-To: <20250304-enic_cleanup_and_ext_cq-v2-0-85804263dad8@cisco.com>
To: Christian Benvenuti <benve@cisco.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Satish Kharat <satishkh@cisco.com>, Nelson Escobar <neescoba@cisco.com>, 
 John Daley <johndale@cisco.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741136202; l=12808;
 i=satishkh@cisco.com; s=20250226; h=from:subject:message-id;
 bh=4QdHHiaBhEaGz+aozi+RNm0r9jFQ8UxgwC9RRxuvcdU=;
 b=dgB028ZgSQPNStT4/reCGrIpy7xp1n7lNIOjOs9CFYIyxeskNFaySdeCTQWnJegCxpLt+XO7W
 QiiDiK9FZHUCpEITOhuQDE1tJ9e+OHS/rEr53GzFyr7VJ9JrRf+Pyzb
X-Developer-Key: i=satishkh@cisco.com; a=ed25519;
 pk=lkxzORFYn5ejiy0kzcsfkpGoXZDcnHMc4n3YK7jJnJo=
X-Endpoint-Received: by B4 Relay for satishkh@cisco.com/20250226 with auth_id=351
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enables getting from hw all the supported rq cq sizes and
uses the highest supported cq size.

Co-developed-by: Nelson Escobar <neescoba@cisco.com>
Signed-off-by: Nelson Escobar <neescoba@cisco.com>
Co-developed-by: John Daley <johndale@cisco.com>
Signed-off-by: John Daley <johndale@cisco.com>
Signed-off-by: Satish Kharat <satishkh@cisco.com>
---
 drivers/net/ethernet/cisco/enic/cq_desc.h   |   3 +
 drivers/net/ethernet/cisco/enic/enic.h      |   9 +++
 drivers/net/ethernet/cisco/enic/enic_main.c |   4 ++
 drivers/net/ethernet/cisco/enic/enic_res.c  |  58 ++++++++++++++-
 drivers/net/ethernet/cisco/enic/enic_rq.c   | 105 +++++++++++++++++++++-------
 5 files changed, 150 insertions(+), 29 deletions(-)

diff --git a/drivers/net/ethernet/cisco/enic/cq_desc.h b/drivers/net/ethernet/cisco/enic/cq_desc.h
index 462c5435a206b4cc93b3734fdc96a2192b53a235..8fc313b6ed0434bd55b8e10bf3086ef848acbdf1 100644
--- a/drivers/net/ethernet/cisco/enic/cq_desc.h
+++ b/drivers/net/ethernet/cisco/enic/cq_desc.h
@@ -40,6 +40,9 @@ struct cq_desc {
 #define CQ_DESC_COMP_NDX_BITS    12
 #define CQ_DESC_COMP_NDX_MASK    ((1 << CQ_DESC_COMP_NDX_BITS) - 1)
 
+#define CQ_DESC_32_FI_MASK (BIT(0) | BIT(1))
+#define CQ_DESC_64_FI_MASK (BIT(0) | BIT(1))
+
 static inline void cq_desc_dec(const struct cq_desc *desc_arg,
 	u8 *type, u8 *color, u16 *q_number, u16 *completed_index)
 {
diff --git a/drivers/net/ethernet/cisco/enic/enic.h b/drivers/net/ethernet/cisco/enic/enic.h
index 305ed12aa0311ca6cc53bfbffcc300182a8011a7..d60e55accafd0e4f83728524da4f167a474d6213 100644
--- a/drivers/net/ethernet/cisco/enic/enic.h
+++ b/drivers/net/ethernet/cisco/enic/enic.h
@@ -31,6 +31,13 @@
 
 #define ENIC_AIC_LARGE_PKT_DIFF	3
 
+enum ext_cq {
+	ENIC_RQ_CQ_ENTRY_SIZE_16,
+	ENIC_RQ_CQ_ENTRY_SIZE_32,
+	ENIC_RQ_CQ_ENTRY_SIZE_64,
+	ENIC_RQ_CQ_ENTRY_SIZE_MAX,
+};
+
 struct enic_msix_entry {
 	int requested;
 	char devname[IFNAMSIZ + 8];
@@ -228,6 +235,7 @@ struct enic {
 	struct enic_rfs_flw_tbl rfs_h;
 	u8 rss_key[ENIC_RSS_LEN];
 	struct vnic_gen_stats gen_stats;
+	enum ext_cq ext_cq;
 };
 
 static inline struct net_device *vnic_get_netdev(struct vnic_dev *vdev)
@@ -349,5 +357,6 @@ int enic_is_valid_vf(struct enic *enic, int vf);
 int enic_is_dynamic(struct enic *enic);
 void enic_set_ethtool_ops(struct net_device *netdev);
 int __enic_set_rsskey(struct enic *enic);
+void enic_ext_cq(struct enic *enic);
 
 #endif /* _ENIC_H_ */
diff --git a/drivers/net/ethernet/cisco/enic/enic_main.c b/drivers/net/ethernet/cisco/enic/enic_main.c
index 080234ef4c2bb53c19e26601ca9bb38d26a738b7..d716514366dfc56b4e08260d18d78fddd23f6253 100644
--- a/drivers/net/ethernet/cisco/enic/enic_main.c
+++ b/drivers/net/ethernet/cisco/enic/enic_main.c
@@ -2192,6 +2192,7 @@ static void enic_reset(struct work_struct *work)
 	enic_init_vnic_resources(enic);
 	enic_set_rss_nic_cfg(enic);
 	enic_dev_set_ig_vlan_rewrite_mode(enic);
+	enic_ext_cq(enic);
 	enic_open(enic->netdev);
 
 	/* Allow infiniband to fiddle with the device again */
@@ -2218,6 +2219,7 @@ static void enic_tx_hang_reset(struct work_struct *work)
 	enic_init_vnic_resources(enic);
 	enic_set_rss_nic_cfg(enic);
 	enic_dev_set_ig_vlan_rewrite_mode(enic);
+	enic_ext_cq(enic);
 	enic_open(enic->netdev);
 
 	/* Allow infiniband to fiddle with the device again */
@@ -2592,6 +2594,8 @@ static int enic_dev_init(struct enic *enic)
 
 	enic_get_res_counts(enic);
 
+	enic_ext_cq(enic);
+
 	err = enic_alloc_enic_resources(enic);
 	if (err) {
 		dev_err(dev, "Failed to allocate enic resources\n");
diff --git a/drivers/net/ethernet/cisco/enic/enic_res.c b/drivers/net/ethernet/cisco/enic/enic_res.c
index 1261251998330c8b8363c4dd2db1ccc25847476c..a7179cc4b5296cfbce137c54a9e17e6b358a19ae 100644
--- a/drivers/net/ethernet/cisco/enic/enic_res.c
+++ b/drivers/net/ethernet/cisco/enic/enic_res.c
@@ -312,6 +312,7 @@ void enic_init_vnic_resources(struct enic *enic)
 int enic_alloc_vnic_resources(struct enic *enic)
 {
 	enum vnic_dev_intr_mode intr_mode;
+	int rq_cq_desc_size;
 	unsigned int i;
 	int err;
 
@@ -326,6 +327,24 @@ int enic_alloc_vnic_resources(struct enic *enic)
 		intr_mode == VNIC_DEV_INTR_MODE_MSIX ? "MSI-X" :
 		"unknown");
 
+	switch (enic->ext_cq) {
+	case ENIC_RQ_CQ_ENTRY_SIZE_16:
+		rq_cq_desc_size = 16;
+		break;
+	case ENIC_RQ_CQ_ENTRY_SIZE_32:
+		rq_cq_desc_size = 32;
+		break;
+	case ENIC_RQ_CQ_ENTRY_SIZE_64:
+		rq_cq_desc_size = 64;
+		break;
+	default:
+		dev_err(enic_get_dev(enic),
+			"Unable to determine rq cq desc size: %d",
+			enic->ext_cq);
+		err = -ENODEV;
+		goto err_out;
+	}
+
 	/* Allocate queue resources
 	 */
 
@@ -348,8 +367,8 @@ int enic_alloc_vnic_resources(struct enic *enic)
 	for (i = 0; i < enic->cq_count; i++) {
 		if (i < enic->rq_count)
 			err = vnic_cq_alloc(enic->vdev, &enic->cq[i], i,
-				enic->config.rq_desc_count,
-				sizeof(struct cq_enet_rq_desc));
+					enic->config.rq_desc_count,
+					rq_cq_desc_size);
 		else
 			err = vnic_cq_alloc(enic->vdev, &enic->cq[i], i,
 				enic->config.wq_desc_count,
@@ -380,6 +399,39 @@ int enic_alloc_vnic_resources(struct enic *enic)
 
 err_out_cleanup:
 	enic_free_vnic_resources(enic);
-
+err_out:
 	return err;
 }
+
+/*
+ * CMD_CQ_ENTRY_SIZE_SET can fail on older hw generations that don't support
+ * that command
+ */
+void enic_ext_cq(struct enic *enic)
+{
+	u64 a0 = CMD_CQ_ENTRY_SIZE_SET, a1 = 0;
+	int wait = 1000;
+	int ret;
+
+	spin_lock_bh(&enic->devcmd_lock);
+	ret = vnic_dev_cmd(enic->vdev, CMD_CAPABILITY, &a0, &a1, wait);
+	if (ret || a0) {
+		dev_info(&enic->pdev->dev,
+			 "CMD_CQ_ENTRY_SIZE_SET not supported.");
+		enic->ext_cq = ENIC_RQ_CQ_ENTRY_SIZE_16;
+		goto out;
+	}
+	a1 &= VNIC_RQ_CQ_ENTRY_SIZE_ALL_BIT;
+	enic->ext_cq = fls(a1) - 1;
+	a0 = VNIC_RQ_ALL;
+	a1 = enic->ext_cq;
+	ret = vnic_dev_cmd(enic->vdev, CMD_CQ_ENTRY_SIZE_SET, &a0, &a1, wait);
+	if (ret) {
+		dev_info(&enic->pdev->dev, "CMD_CQ_ENTRY_SIZE_SET failed.");
+		enic->ext_cq = ENIC_RQ_CQ_ENTRY_SIZE_16;
+	}
+out:
+	spin_unlock_bh(&enic->devcmd_lock);
+	dev_info(&enic->pdev->dev, "CQ entry size set to %d bytes",
+		 16 << enic->ext_cq);
+}
diff --git a/drivers/net/ethernet/cisco/enic/enic_rq.c b/drivers/net/ethernet/cisco/enic/enic_rq.c
index 842b273c2e2a59e81a7c1423449b023d646f5e81..ccbf5c9a21d0ffe33c7c74042d5425497ea0f9dc 100644
--- a/drivers/net/ethernet/cisco/enic/enic_rq.c
+++ b/drivers/net/ethernet/cisco/enic/enic_rq.c
@@ -21,24 +21,76 @@ static void enic_intr_update_pkt_size(struct vnic_rx_bytes_counter *pkt_size,
 		pkt_size->small_pkt_bytes_cnt += pkt_len;
 }
 
-static void enic_rq_cq_desc_dec(struct cq_enet_rq_desc *desc, u8 *type,
+static void enic_rq_cq_desc_dec(void *cq_desc, u8 cq_desc_size, u8 *type,
 				u8 *color, u16 *q_number, u16 *completed_index)
 {
 	/* type_color is the last field for all cq structs */
-	u8 type_color = desc->type_color;
+	u8 type_color;
+
+	switch (cq_desc_size) {
+	case VNIC_RQ_CQ_ENTRY_SIZE_16: {
+		struct cq_enet_rq_desc *desc =
+			(struct cq_enet_rq_desc *)cq_desc;
+		type_color = desc->type_color;
+
+		/* Make sure color bit is read from desc *before* other fields
+		 * are read from desc.  Hardware guarantees color bit is last
+		 * bit (byte) written.  Adding the rmb() prevents the compiler
+		 * and/or CPU from reordering the reads which would potentially
+		 * result in reading stale values.
+		 */
+		rmb();
 
-	/* Make sure color bit is read from desc *before* other fields
-	 * are read from desc.  Hardware guarantees color bit is last
-	 * bit (byte) written.  Adding the rmb() prevents the compiler
-	 * and/or CPU from reordering the reads which would potentially
-	 * result in reading stale values.
-	 */
-	rmb();
+		*q_number = le16_to_cpu(desc->q_number_rss_type_flags) &
+			    CQ_DESC_Q_NUM_MASK;
+		*completed_index = le16_to_cpu(desc->completed_index_flags) &
+				   CQ_DESC_COMP_NDX_MASK;
+		break;
+	}
+	case VNIC_RQ_CQ_ENTRY_SIZE_32: {
+		struct cq_enet_rq_desc_32 *desc =
+			(struct cq_enet_rq_desc_32 *)cq_desc;
+		type_color = desc->type_color;
+
+		/* Make sure color bit is read from desc *before* other fields
+		 * are read from desc.  Hardware guarantees color bit is last
+		 * bit (byte) written.  Adding the rmb() prevents the compiler
+		 * and/or CPU from reordering the reads which would potentially
+		 * result in reading stale values.
+		 */
+		rmb();
+
+		*q_number = le16_to_cpu(desc->q_number_rss_type_flags) &
+			    CQ_DESC_Q_NUM_MASK;
+		*completed_index = le16_to_cpu(desc->completed_index_flags) &
+				   CQ_DESC_COMP_NDX_MASK;
+		*completed_index |= (desc->fetch_index_flags & CQ_DESC_32_FI_MASK) <<
+				CQ_DESC_COMP_NDX_BITS;
+		break;
+	}
+	case VNIC_RQ_CQ_ENTRY_SIZE_64: {
+		struct cq_enet_rq_desc_64 *desc =
+			(struct cq_enet_rq_desc_64 *)cq_desc;
+		type_color = desc->type_color;
+
+		/* Make sure color bit is read from desc *before* other fields
+		 * are read from desc.  Hardware guarantees color bit is last
+		 * bit (byte) written.  Adding the rmb() prevents the compiler
+		 * and/or CPU from reordering the reads which would potentially
+		 * result in reading stale values.
+		 */
+		rmb();
+
+		*q_number = le16_to_cpu(desc->q_number_rss_type_flags) &
+			    CQ_DESC_Q_NUM_MASK;
+		*completed_index = le16_to_cpu(desc->completed_index_flags) &
+				   CQ_DESC_COMP_NDX_MASK;
+		*completed_index |= (desc->fetch_index_flags & CQ_DESC_64_FI_MASK) <<
+				CQ_DESC_COMP_NDX_BITS;
+		break;
+	}
+	}
 
-	*q_number = le16_to_cpu(desc->q_number_rss_type_flags) &
-		CQ_DESC_Q_NUM_MASK;
-	*completed_index = le16_to_cpu(desc->completed_index_flags) &
-	CQ_DESC_COMP_NDX_MASK;
 	*color = (type_color >> CQ_DESC_COLOR_SHIFT) & CQ_DESC_COLOR_MASK;
 	*type = type_color & CQ_DESC_TYPE_MASK;
 }
@@ -113,6 +165,10 @@ static void enic_rq_set_skb_flags(struct vnic_rq *vrq, u8 type, u32 rss_hash,
 	}
 }
 
+/*
+ * cq_enet_rq_desc accesses section uses only the 1st 15 bytes of the cq which
+ * is identical for all type (16,32 and 64 byte) of cqs.
+ */
 static void cq_enet_rq_desc_dec(struct cq_enet_rq_desc *desc, u8 *ingress_port,
 				u8 *fcoe, u8 *eop, u8 *sop, u8 *rss_type,
 				u8 *csum_not_calc, u32 *rss_hash,
@@ -258,9 +314,8 @@ void enic_free_rq_buf(struct vnic_rq *rq, struct vnic_rq_buf *buf)
 }
 
 static void enic_rq_indicate_buf(struct enic *enic, struct vnic_rq *rq,
-				 struct vnic_rq_buf *buf,
-				 struct cq_enet_rq_desc *cq_desc, u8 type,
-				 u16 q_number, u16 completed_index)
+				 struct vnic_rq_buf *buf, void *cq_desc,
+				 u8 type, u16 q_number, u16 completed_index)
 {
 	struct sk_buff *skb;
 	struct vnic_cq *cq = &enic->cq[enic_cq_rq(enic, rq->index)];
@@ -277,7 +332,7 @@ static void enic_rq_indicate_buf(struct enic *enic, struct vnic_rq *rq,
 
 	rqstats->packets++;
 
-	cq_enet_rq_desc_dec(cq_desc, &ingress_port,
+	cq_enet_rq_desc_dec((struct cq_enet_rq_desc *)cq_desc, &ingress_port,
 			    &fcoe, &eop, &sop, &rss_type, &csum_not_calc,
 			    &rss_hash, &bytes_written, &packet_error,
 			    &vlan_stripped, &vlan_tci, &checksum, &fcoe_sof,
@@ -329,8 +384,8 @@ static void enic_rq_indicate_buf(struct enic *enic, struct vnic_rq *rq,
 	}
 }
 
-static void enic_rq_service(struct enic *enic, struct cq_enet_rq_desc *cq_desc,
-			    u8 type, u16 q_number, u16 completed_index)
+static void enic_rq_service(struct enic *enic, void *cq_desc, u8 type,
+			    u16 q_number, u16 completed_index)
 {
 	struct enic_rq_stats *rqstats = &enic->rq[q_number].stats;
 	struct vnic_rq *vrq = &enic->rq[q_number].vrq;
@@ -357,14 +412,12 @@ unsigned int enic_rq_cq_service(struct enic *enic, unsigned int cq_index,
 				unsigned int work_to_do)
 {
 	struct vnic_cq *cq = &enic->cq[cq_index];
-	struct cq_enet_rq_desc *cq_desc;
+	void *cq_desc = vnic_cq_to_clean(cq);
 	u16 q_number, completed_index;
 	unsigned int work_done = 0;
 	u8 type, color;
 
-	cq_desc = (struct cq_enet_rq_desc *)vnic_cq_to_clean(cq);
-
-	enic_rq_cq_desc_dec(cq_desc,  &type, &color, &q_number,
+	enic_rq_cq_desc_dec(cq_desc, enic->ext_cq, &type, &color, &q_number,
 			    &completed_index);
 
 	while (color != cq->last_color) {
@@ -374,9 +427,9 @@ unsigned int enic_rq_cq_service(struct enic *enic, unsigned int cq_index,
 		if (++work_done >= work_to_do)
 			break;
 
-		cq_desc = (struct cq_enet_rq_desc *)vnic_cq_to_clean(cq);
-		enic_rq_cq_desc_dec(cq_desc, &type, &color, &q_number,
-				    &completed_index);
+		cq_desc = vnic_cq_to_clean(cq);
+		enic_rq_cq_desc_dec(cq_desc, enic->ext_cq, &type, &color,
+				    &q_number, &completed_index);
 	}
 
 	return work_done;

-- 
2.48.1

