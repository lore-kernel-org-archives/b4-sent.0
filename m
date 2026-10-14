From: Eric Davis <eric.davis@broadcom.com>
Date: Wed, 14 Oct 2026 15:21:15 -0700
Subject: [PATCH rdma-next 06/13] RDMA/core: query the semantics a queue
 pair type guarantees
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261014-uet-ib-core-v1-6-a0e626117113@broadcom.com>
References: <20261014-uet-ib-core-v1-0-a0e626117113@broadcom.com>
In-Reply-To: <20261014-uet-ib-core-v1-0-a0e626117113@broadcom.com>
To: Jason Gunthorpe <jgg@ziepe.ca>, Leon Romanovsky <leon@kernel.org>
Cc: linux-rdma@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Eric Davis <eric.davis@broadcom.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792016478; l=9629;
 i=eric.davis@broadcom.com; s=20261014; h=from:subject:message-id;
 bh=eWFu2QE49zyCcjqx1b/fkiLANYq7Qlq2FghZjkJuTQM=;
 b=GQEppNx+j/7eXp6PpkpKvVYNwk3MWdUlsUupvgxJEvmvFEAho8gn2Onz47UlT7LRTfRN8/wAI
 BX00LjuSvxPA9nnRmG6HASvNH4ySTO1mPS2ikXlU7XDxXexUPO0tKxc
X-Developer-Key: i=eric.davis@broadcom.com; a=ed25519;
 pk=uy3oCTOYBipIPjryXGMynBmtPvbO6qN2FOrduzpiI4A=
X-Endpoint-Received: by B4 Relay for eric.davis@broadcom.com/20261014 with auth_id=1186
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

An unconnected transport orders far less than a connected one, and how
much varies by device. Add a device method that reports, for a queue pair
type, which operations it orders against which, the largest packet it
puts on the wire, how wide an immediate it carries, and whether a memory
region may be attached to a QP so it's only reachable over that QP.

Signed-off-by: Eric Davis <eric.davis@broadcom.com>
---
 drivers/infiniband/core/device.c                  |  1 +
 drivers/infiniband/core/uverbs_std_types_device.c | 73 ++++++++++++++++++++++-
 include/rdma/ib_verbs.h                           | 15 +++++
 include/uapi/rdma/ib_user_ioctl_cmds.h            |  6 ++
 include/uapi/rdma/ib_user_ioctl_verbs.h           | 63 +++++++++++++++++++
 5 files changed, 157 insertions(+), 1 deletion(-)

diff --git a/drivers/infiniband/core/device.c b/drivers/infiniband/core/device.c
index 7c65a9373701..8b1563de4726 100644
--- a/drivers/infiniband/core/device.c
+++ b/drivers/infiniband/core/device.c
@@ -3011,6 +3011,7 @@ void ib_set_device_ops(struct ib_device *dev, const struct ib_device_ops *ops)
 	SET_DEVICE_OP(dev_ops, query_port);
 	SET_DEVICE_OP(dev_ops, query_port_speed);
 	SET_DEVICE_OP(dev_ops, query_qp);
+	SET_DEVICE_OP(dev_ops, query_qp_semantics);
 	SET_DEVICE_OP(dev_ops, query_srq);
 	SET_DEVICE_OP(dev_ops, query_ucontext);
 	SET_DEVICE_OP(dev_ops, rdma_netdev_get_params);
diff --git a/drivers/infiniband/core/uverbs_std_types_device.c b/drivers/infiniband/core/uverbs_std_types_device.c
index db65032e80b4..997fc82f9010 100644
--- a/drivers/infiniband/core/uverbs_std_types_device.c
+++ b/drivers/infiniband/core/uverbs_std_types_device.c
@@ -591,6 +591,76 @@ DECLARE_UVERBS_NAMED_METHOD(
 			    UVERBS_ATTR_TYPE(u32),
 			    UA_OPTIONAL));
 
+/* What a QP type guarantees on this device. Which operations it orders
+ * against, how large a packet it puts on the wire, how wide an immediate it
+ * carries.
+ */
+static int UVERBS_HANDLER(UVERBS_METHOD_QUERY_QP_SEMANTICS)(
+	struct uverbs_attr_bundle *attrs)
+{
+	struct ib_uverbs_qp_semantics resp = {};
+	struct ib_qp_semantics sem = {};
+	struct ib_ucontext *ucontext;
+	struct ib_device *ib_dev;
+	enum ib_qp_type qp_type;
+	int ret;
+
+	ucontext = ib_uverbs_get_ucontext(attrs);
+	if (IS_ERR(ucontext))
+		return PTR_ERR(ucontext);
+	ib_dev = ucontext->device;
+
+	if (!ib_dev->ops.query_qp_semantics)
+		return -EOPNOTSUPP;
+
+	ret = uverbs_get_const(&qp_type, attrs,
+			       UVERBS_ATTR_QUERY_QP_SEMANTICS_QP_TYPE);
+	if (ret)
+		return ret;
+
+	/* only the types userspace can create */
+	switch (qp_type) {
+	case IB_UVERBS_QPT_RC:
+	case IB_UVERBS_QPT_UC:
+	case IB_UVERBS_QPT_UD:
+	case IB_UVERBS_QPT_RAW_PACKET:
+	case IB_UVERBS_QPT_XRC_INI:
+	case IB_UVERBS_QPT_XRC_TGT:
+	case IB_UVERBS_QPT_RU:
+	case IB_UVERBS_QPT_DRIVER:
+		break;
+	default:
+		return -EINVAL;
+	}
+
+	ret = ib_dev->ops.query_qp_semantics(ib_dev, qp_type, &sem);
+	if (ret)
+		return ret;
+
+	resp.comp_mask = sem.comp_mask;
+	resp.msg_order = sem.msg_order;
+	resp.max_rdma_raw_size = sem.max_rdma_raw_size;
+	resp.max_rdma_war_size = sem.max_rdma_war_size;
+	resp.max_rdma_waw_size = sem.max_rdma_waw_size;
+	resp.max_pdu = sem.max_pdu;
+	resp.usage_flags = sem.usage_flags;
+	resp.imm_data_size = sem.imm_data_size;
+
+	return uverbs_copy_to_struct_or_zero(
+		attrs, UVERBS_ATTR_QUERY_QP_SEMANTICS_RESP, &resp,
+		sizeof(resp));
+}
+
+DECLARE_UVERBS_NAMED_METHOD(
+	UVERBS_METHOD_QUERY_QP_SEMANTICS,
+	UVERBS_ATTR_CONST_IN(UVERBS_ATTR_QUERY_QP_SEMANTICS_QP_TYPE,
+			     enum ib_uverbs_qp_type,
+			     UA_MANDATORY),
+	UVERBS_ATTR_PTR_OUT(UVERBS_ATTR_QUERY_QP_SEMANTICS_RESP,
+			    UVERBS_ATTR_STRUCT(struct ib_uverbs_qp_semantics,
+					       imm_data_size),
+			    UA_MANDATORY));
+
 DECLARE_UVERBS_GLOBAL_METHODS(UVERBS_OBJECT_DEVICE,
 			      &UVERBS_METHOD(UVERBS_METHOD_GET_CONTEXT),
 			      &UVERBS_METHOD(UVERBS_METHOD_INVOKE_WRITE),
@@ -600,7 +670,8 @@ DECLARE_UVERBS_GLOBAL_METHODS(UVERBS_OBJECT_DEVICE,
 			      &UVERBS_METHOD(UVERBS_METHOD_QUERY_CONTEXT),
 			      &UVERBS_METHOD(UVERBS_METHOD_QUERY_GID_TABLE),
 			      &UVERBS_METHOD(UVERBS_METHOD_QUERY_GID_ENTRY),
-			      &UVERBS_METHOD(UVERBS_METHOD_QUERY_COMP_CNTR_CAPS));
+			      &UVERBS_METHOD(UVERBS_METHOD_QUERY_COMP_CNTR_CAPS),
+			      &UVERBS_METHOD(UVERBS_METHOD_QUERY_QP_SEMANTICS));
 
 const struct uapi_definition uverbs_def_obj_device[] = {
 	UAPI_DEF_CHAIN_OBJ_TREE_NAMED(UVERBS_OBJECT_DEVICE),
diff --git a/include/rdma/ib_verbs.h b/include/rdma/ib_verbs.h
index 68f7a271cf7a..003b70424429 100644
--- a/include/rdma/ib_verbs.h
+++ b/include/rdma/ib_verbs.h
@@ -2496,6 +2496,18 @@ struct ib_counters {
 	atomic_t	usecnt;
 };
 
+/* what a queue pair of a given type guarantees (query_qp_semantics) */
+struct ib_qp_semantics {
+	u32	comp_mask;		/* enum ib_uverbs_qp_semantics_mask */
+	u32	msg_order;		/* enum ib_uverbs_qp_msg_order */
+	u32	max_rdma_raw_size;
+	u32	max_rdma_war_size;
+	u32	max_rdma_waw_size;
+	u32	max_pdu;
+	u32	usage_flags;		/* enum ib_uverbs_qp_usage_flags */
+	u8	imm_data_size;		/* bits */
+};
+
 struct ib_counters_read_attr {
 	u64	*counters_buff;
 	u32	ncounters;
@@ -2751,6 +2763,9 @@ struct ib_device_ops {
 				       int mr_access_flags, struct ib_pd *pd,
 				       struct ib_udata *udata);
 	int (*dereg_mr)(struct ib_mr *mr, struct ib_udata *udata);
+	int (*query_qp_semantics)(struct ib_device *device,
+				  enum ib_qp_type qp_type,
+				  struct ib_qp_semantics *sem);
 	struct ib_mr *(*alloc_mr)(struct ib_pd *pd, enum ib_mr_type mr_type,
 				  u32 max_num_sg);
 	struct ib_mr *(*alloc_mr_integrity)(struct ib_pd *pd,
diff --git a/include/uapi/rdma/ib_user_ioctl_cmds.h b/include/uapi/rdma/ib_user_ioctl_cmds.h
index 40fcd4bd1b5e..fb746257eb2c 100644
--- a/include/uapi/rdma/ib_user_ioctl_cmds.h
+++ b/include/uapi/rdma/ib_user_ioctl_cmds.h
@@ -77,6 +77,12 @@ enum uverbs_methods_device {
 	UVERBS_METHOD_QUERY_GID_ENTRY,
 	UVERBS_METHOD_QUERY_PORT_SPEED,
 	UVERBS_METHOD_QUERY_COMP_CNTR_CAPS,
+	UVERBS_METHOD_QUERY_QP_SEMANTICS,
+};
+
+enum uverbs_attrs_query_qp_semantics_attr_ids {
+	UVERBS_ATTR_QUERY_QP_SEMANTICS_QP_TYPE,
+	UVERBS_ATTR_QUERY_QP_SEMANTICS_RESP,
 };
 
 enum uverbs_attrs_invoke_write_cmd_attr_ids {
diff --git a/include/uapi/rdma/ib_user_ioctl_verbs.h b/include/uapi/rdma/ib_user_ioctl_verbs.h
index 210f3f945bd7..3d05a6c7ca8f 100644
--- a/include/uapi/rdma/ib_user_ioctl_verbs.h
+++ b/include/uapi/rdma/ib_user_ioctl_verbs.h
@@ -318,6 +318,50 @@ struct ib_uverbs_buffer_desc {
 #define IB_UVERBS_QPN_UET_RESERVED_MASK		0x7f000000
 #define IB_UVERBS_QPN_UET_ABSOLUTE_ADDR_BIT	0x80000000
 
+enum ib_uverbs_qp_semantics_mask {
+	IB_UVERBS_QP_SEMANTICS_MASK_MSG_ORDER	= 1 << 0,
+	IB_UVERBS_QP_SEMANTICS_MASK_RAW		= 1 << 1,
+	IB_UVERBS_QP_SEMANTICS_MASK_WAR		= 1 << 2,
+	IB_UVERBS_QP_SEMANTICS_MASK_WAW		= 1 << 3,
+	IB_UVERBS_QP_SEMANTICS_MASK_PDU		= 1 << 4,
+	IB_UVERBS_QP_SEMANTICS_MASK_IMM		= 1 << 5,
+	IB_UVERBS_QP_SEMANTICS_MASK_USAGE	= 1 << 6,
+};
+
+/* Ordering guarantees between operations on one QP. "X after Y" means an
+ * X may not pass a Y posted before it. A bit that is clear means the pair
+ * does not order that combination, and an application that needs it must
+ * wait for the earlier completion.
+ */
+enum ib_uverbs_qp_msg_order {
+	/* atomic after atomic */
+	IB_UVERBS_QP_ORDER_ATOMIC_RAR	= 1 << 0,
+	IB_UVERBS_QP_ORDER_ATOMIC_RAW	= 1 << 1,
+	IB_UVERBS_QP_ORDER_ATOMIC_WAR	= 1 << 2,
+	IB_UVERBS_QP_ORDER_ATOMIC_WAW	= 1 << 3,
+	/* rma after rma */
+	IB_UVERBS_QP_ORDER_RDMA_RAR	= 1 << 4,
+	IB_UVERBS_QP_ORDER_RDMA_RAW	= 1 << 5,
+	IB_UVERBS_QP_ORDER_RDMA_WAR	= 1 << 6,
+	IB_UVERBS_QP_ORDER_RDMA_WAW	= 1 << 7,
+	/* send against atomic and rma */
+	IB_UVERBS_QP_ORDER_RAS		= 1 << 8,
+	IB_UVERBS_QP_ORDER_SAR		= 1 << 9,
+	IB_UVERBS_QP_ORDER_SAS		= 1 << 10,
+	IB_UVERBS_QP_ORDER_SAW		= 1 << 11,
+	IB_UVERBS_QP_ORDER_WAS		= 1 << 12,
+	/* rma and atomic, either kind, against each other */
+	IB_UVERBS_QP_ORDER_RAR		= 1 << 13,
+	IB_UVERBS_QP_ORDER_RAW		= 1 << 14,
+	IB_UVERBS_QP_ORDER_WAR		= 1 << 15,
+	IB_UVERBS_QP_ORDER_WAW		= 1 << 16,
+};
+
+enum ib_uverbs_qp_usage_flags {
+	/* immediate data consumes a posted receive */
+	IB_UVERBS_QP_USAGE_IMM_DATA_RQ	= 1 << 0,
+};
+
 /* An address handle that names a peer using both transport+network addresses.
  * Used for reliable unconnected QPs in both work request address handles and
  * a Job address table.
@@ -327,6 +371,25 @@ struct ib_uverbs_ah_attr_ex {
 	__u32 remote_qpn;
 };
 
+struct ib_uverbs_qp_semantics {
+	__u32 comp_mask;		/* enum ib_uverbs_qp_semantics_mask */
+	__u32 msg_order;		/* enum ib_uverbs_qp_msg_order */
+	/*
+	 * Data ordering: the largest transfer, in bytes, for which the target
+	 * memory reflects the order of the pair under its RDMA_ and plain
+	 * msg_order bits. 0 if not provided, and those bits are then clear.
+	 * There is no read-after-read size, as two reads leave memory
+	 * unchanged.
+	 */
+	__u32 max_rdma_raw_size;	/* read after write */
+	__u32 max_rdma_war_size;	/* write after read */
+	__u32 max_rdma_waw_size;	/* write after write */
+	__u32 max_pdu;			/* largest packet, bytes */
+	__u32 usage_flags;		/* enum ib_uverbs_qp_usage_flags */
+	__u8  imm_data_size;		/* widest immediate, in bits */
+	__u8  reserved[3];
+};
+
 enum ib_uverbs_comp_cntr_entry {
 	IB_UVERBS_COMP_CNTR_ENTRY_COMP,
 	IB_UVERBS_COMP_CNTR_ENTRY_ERR,

-- 
2.56.0

