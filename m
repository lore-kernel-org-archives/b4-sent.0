From: Eric Davis <eric.davis@broadcom.com>
Date: Wed, 14 Oct 2026 15:21:19 -0700
Subject: [PATCH rdma-next 10/13] RDMA/core: queue pair attributes for
 unconnected transports
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261014-uet-ib-core-v1-10-a0e626117113@broadcom.com>
References: <20261014-uet-ib-core-v1-0-a0e626117113@broadcom.com>
In-Reply-To: <20261014-uet-ib-core-v1-0-a0e626117113@broadcom.com>
To: Jason Gunthorpe <jgg@ziepe.ca>, Leon Romanovsky <leon@kernel.org>
Cc: linux-rdma@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Eric Davis <eric.davis@broadcom.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792016478; l=9901;
 i=eric.davis@broadcom.com; s=20261014; h=from:subject:message-id;
 bh=Im0kczol1di0F52zP1+LnH39hV64R8G8XV/e7wOhAtI=;
 b=+lqWViv80DVgxla5V0fnjS1KV25bjQvyZBsN3ywKdnDJhXeIWrqVwid9XrgEMoL8k82TMFKW9
 lqtKjYDrHA0BbztcIOgvt/WVj75mWY/+D9z3oy0VPA1xLlgCFY3Xhwo
X-Developer-Key: i=eric.davis@broadcom.com; a=ed25519;
 pk=uy3oCTOYBipIPjryXGMynBmtPvbO6qN2FOrduzpiI4A=
X-Endpoint-Received: by B4 Relay for eric.davis@broadcom.com/20261014 with auth_id=1186
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A queue pair on an unconnected transport is created with more than the
connected attributes. A job key authorizing it to act within a job, the
initiator identity it sends under, and the ordering guarantees the caller
wants it to keep.

The QP holds a reference to its job key for as long as it lives, so the
job cannot go away underneath it.

Signed-off-by: Eric Davis <eric.davis@broadcom.com>
---
 drivers/infiniband/core/uverbs_std_types_qp.c | 150 ++++++++++++++++++++++++++
 drivers/infiniband/core/verbs.c               |   5 +
 include/rdma/ib_verbs.h                       |  14 +++
 include/uapi/rdma/ib_user_ioctl_cmds.h        |   3 +
 4 files changed, 172 insertions(+)

diff --git a/drivers/infiniband/core/uverbs_std_types_qp.c b/drivers/infiniband/core/uverbs_std_types_qp.c
index c6225156fe30..47ca994f9ac9 100644
--- a/drivers/infiniband/core/uverbs_std_types_qp.c
+++ b/drivers/infiniband/core/uverbs_std_types_qp.c
@@ -79,6 +79,139 @@ static void set_caps(struct ib_qp_init_attr *attr,
 	}
 }
 
+/* the semantics fields, ordering bits and usage flags uverbs knows of */
+#define QP_SEMANTICS_MASK_ALL	((IB_UVERBS_QP_SEMANTICS_MASK_USAGE << 1) - 1)
+#define QP_ORDER_ALL		((IB_UVERBS_QP_ORDER_WAW << 1) - 1)
+#define QP_USAGE_ALL		IB_UVERBS_QP_USAGE_IMM_DATA_RQ
+
+/* A QP may relax what its type guarantees on this device, but not ask for
+ * more than the device advertises for it.
+ */
+static int create_qp_semantics_check(struct ib_device *device,
+				     const struct ib_qp_semantics *req)
+{
+	struct ib_qp_semantics adv = {};
+	u32 m = req->comp_mask;
+	int ret;
+
+	if (!device->ops.query_qp_semantics)
+		return -EOPNOTSUPP;
+
+	ret = device->ops.query_qp_semantics(device, IB_QPT_RU, &adv);
+	if (ret)
+		return ret;
+
+	if (m & ~adv.comp_mask)
+		return -EINVAL;
+
+	if (((m & IB_UVERBS_QP_SEMANTICS_MASK_MSG_ORDER) &&
+	     (req->msg_order & ~adv.msg_order)) ||
+	    ((m & IB_UVERBS_QP_SEMANTICS_MASK_RAW) &&
+	     req->max_rdma_raw_size > adv.max_rdma_raw_size) ||
+	    ((m & IB_UVERBS_QP_SEMANTICS_MASK_WAR) &&
+	     req->max_rdma_war_size > adv.max_rdma_war_size) ||
+	    ((m & IB_UVERBS_QP_SEMANTICS_MASK_WAW) &&
+	     req->max_rdma_waw_size > adv.max_rdma_waw_size) ||
+	    ((m & IB_UVERBS_QP_SEMANTICS_MASK_PDU) &&
+	     req->max_pdu > adv.max_pdu) ||
+	    ((m & IB_UVERBS_QP_SEMANTICS_MASK_IMM) &&
+	     req->imm_data_size > adv.imm_data_size) ||
+	    ((m & IB_UVERBS_QP_SEMANTICS_MASK_USAGE) &&
+	     (req->usage_flags & ~adv.usage_flags)))
+		return -EINVAL;
+
+	return 0;
+}
+
+/* Process the optional creation attributes. A job to act within, a source
+ * identity, a set of ordering guarantees to ask for. They and the checks on
+ * a requested QP number belong to a reliable unconnected QP.
+ */
+static int create_qp_opt_attrs(struct uverbs_attr_bundle *attrs,
+			       struct ib_device *device, struct ib_pd *pd,
+			       struct ib_qp_init_attr *attr,
+			       struct ib_qp_semantics *sem)
+{
+	struct ib_uverbs_qp_semantics usem = {};
+	struct ib_jkey *jkey;
+	bool has_semantics;
+	int ret;
+
+	has_semantics = uverbs_attr_is_valid(attrs,
+					     UVERBS_ATTR_CREATE_QP_SEMANTICS);
+
+	if (attr->qp_type != IB_QPT_RU ||
+	    !(device->attrs.device_cap_flags & IB_DEVICE_RU)) {
+		if (has_semantics ||
+		    uverbs_attr_is_valid(attrs, UVERBS_ATTR_CREATE_QP_SRC_ID) ||
+		    uverbs_attr_is_valid(attrs, UVERBS_ATTR_CREATE_QP_JOB_KEY))
+			return -EOPNOTSUPP;
+
+		return 0;
+	}
+
+	if (uverbs_attr_is_valid(attrs, UVERBS_ATTR_CREATE_QP_SRC_ID)) {
+		ret = uverbs_copy_from(&attr->src_id, attrs,
+				       UVERBS_ATTR_CREATE_QP_SRC_ID);
+		if (ret)
+			return ret;
+	}
+
+	if (uverbs_attr_is_valid(attrs, UVERBS_ATTR_CREATE_QP_JOB_KEY)) {
+		jkey = uverbs_attr_get_obj(attrs,
+					   UVERBS_ATTR_CREATE_QP_JOB_KEY);
+		if (IS_ERR(jkey))
+			return PTR_ERR(jkey);
+
+		/* a key acts within the PD it was made on */
+		if (jkey->pd != pd)
+			return -EINVAL;
+
+		attr->jkey = jkey;
+	}
+
+	if (attr->create_flags & IB_QP_CREATE_SOURCE_QPN) {
+		if (attr->source_qpn & IB_UVERBS_QPN_UET_RESERVED_MASK)
+			return -EINVAL;
+
+		/* a relative QP is named within a job, so it needs a key */
+		if (!(attr->source_qpn &
+		      IB_UVERBS_QPN_UET_ABSOLUTE_ADDR_BIT) &&
+		    !attr->jkey)
+			return -EINVAL;
+	}
+
+	if (has_semantics) {
+		ret = uverbs_copy_from_or_zero(&usem, attrs,
+					       UVERBS_ATTR_CREATE_QP_SEMANTICS);
+		if (ret)
+			return ret;
+
+		if ((usem.comp_mask & ~QP_SEMANTICS_MASK_ALL) ||
+		    (usem.msg_order & ~QP_ORDER_ALL) ||
+		    (usem.usage_flags & ~QP_USAGE_ALL) ||
+		    memchr_inv(usem.reserved, 0, sizeof(usem.reserved)))
+			return -EINVAL;
+
+		sem->comp_mask = usem.comp_mask;
+		sem->msg_order = usem.msg_order;
+		sem->max_rdma_raw_size = usem.max_rdma_raw_size;
+		sem->max_rdma_war_size = usem.max_rdma_war_size;
+		sem->max_rdma_waw_size = usem.max_rdma_waw_size;
+		sem->max_pdu = usem.max_pdu;
+		sem->usage_flags = usem.usage_flags;
+		sem->imm_data_size = usem.imm_data_size;
+
+		ret = create_qp_semantics_check(device, sem);
+		if (ret)
+			return ret;
+
+		attr->qp_semantics = sem;
+	}
+
+	return 0;
+}
+
 /* what a reliable unconnected QP may be created ready to send with */
 #define CREATE_QP_ATTR_RU_MASK	(IB_QP_STATE | IB_QP_PKEY_INDEX |	\
 				 IB_QP_PORT | IB_QP_ACCESS_FLAGS |	\
@@ -143,6 +276,7 @@ static int UVERBS_HANDLER(UVERBS_METHOD_QP_CREATE)(
 	struct ib_qp_init_attr attr = {};
 	struct ib_qp_attr qp_attr = {};
 	u32 qp_attr_mask;
+	struct ib_qp_semantics qp_semantics = {};
 	struct ib_uverbs_qp_cap cap = {};
 	struct ib_rwq_ind_table *rwq_ind_tbl = NULL;
 	struct ib_qp *qp;
@@ -197,6 +331,7 @@ static int UVERBS_HANDLER(UVERBS_METHOD_QP_CREATE)(
 	case IB_UVERBS_QPT_UC:
 	case IB_UVERBS_QPT_UD:
 	case IB_UVERBS_QPT_XRC_INI:
+	case IB_UVERBS_QPT_RU:
 	case IB_UVERBS_QPT_DRIVER:
 		if (uverbs_attr_is_valid(attrs,
 					 UVERBS_ATTR_CREATE_QP_XRCD_HANDLE) ||
@@ -271,6 +406,10 @@ static int UVERBS_HANDLER(UVERBS_METHOD_QP_CREATE)(
 		attr.create_flags |= IB_QP_CREATE_SOURCE_QPN;
 	}
 
+	ret = create_qp_opt_attrs(attrs, device, pd, &attr, &qp_semantics);
+	if (ret)
+		return ret;
+
 	ret = create_qp_attr_set(attrs, device, &attr, &qp_attr,
 				 &qp_attr_mask);
 	if (ret)
@@ -401,6 +540,17 @@ DECLARE_UVERBS_NAMED_METHOD(
 	UVERBS_ATTR_FLAGS_IN(UVERBS_ATTR_CREATE_QP_FLAGS,
 			     enum ib_uverbs_qp_create_flags,
 			     UA_OPTIONAL),
+	UVERBS_ATTR_PTR_IN(UVERBS_ATTR_CREATE_QP_SRC_ID,
+			   UVERBS_ATTR_TYPE(u32),
+			   UA_OPTIONAL),
+	UVERBS_ATTR_PTR_IN(UVERBS_ATTR_CREATE_QP_SEMANTICS,
+			   UVERBS_ATTR_STRUCT(struct ib_uverbs_qp_semantics,
+					      imm_data_size),
+			   UA_OPTIONAL),
+	UVERBS_ATTR_IDR(UVERBS_ATTR_CREATE_QP_JOB_KEY,
+			UVERBS_OBJECT_JKEY,
+			UVERBS_ACCESS_READ,
+			UA_OPTIONAL),
 	UVERBS_ATTR_PTR_IN(UVERBS_ATTR_CREATE_QP_ATTR,
 			   UVERBS_ATTR_STRUCT(struct ib_uverbs_ex_modify_qp,
 					      reserved),
diff --git a/drivers/infiniband/core/verbs.c b/drivers/infiniband/core/verbs.c
index 0a5340642abb..3446aaa16ef4 100644
--- a/drivers/infiniband/core/verbs.c
+++ b/drivers/infiniband/core/verbs.c
@@ -1343,6 +1343,7 @@ static struct ib_qp *create_qp(struct ib_device *dev, struct ib_pd *pd,
 	qp->qp_type = attr->qp_type;
 	qp->rwq_ind_tbl = attr->rwq_ind_tbl;
 	qp->srq = attr->srq;
+	qp->jkey = attr->jkey;
 	qp->event_handler = __ib_qp_event_handler;
 	qp->registered_event_handler = attr->event_handler;
 	qp->port = attr->port_num;
@@ -1438,11 +1439,15 @@ void ib_qp_usecnt_inc(struct ib_qp *qp)
 		atomic_inc(&qp->srq->usecnt);
 	if (qp->rwq_ind_tbl)
 		atomic_inc(&qp->rwq_ind_tbl->usecnt);
+	if (qp->jkey)
+		atomic_inc(&qp->jkey->usecnt);
 }
 EXPORT_SYMBOL(ib_qp_usecnt_inc);
 
 void ib_qp_usecnt_dec(struct ib_qp *qp)
 {
+	if (qp->jkey)
+		atomic_dec(&qp->jkey->usecnt);
 	if (qp->rwq_ind_tbl)
 		atomic_dec(&qp->rwq_ind_tbl->usecnt);
 	if (qp->srq)
diff --git a/include/rdma/ib_verbs.h b/include/rdma/ib_verbs.h
index 6aa8e7120e71..3e43d0b8b495 100644
--- a/include/rdma/ib_verbs.h
+++ b/include/rdma/ib_verbs.h
@@ -1243,6 +1243,9 @@ enum ib_qp_create_flags {
  * callback to destroy the passed in QP.
  */
 
+struct ib_jkey;
+struct ib_qp_semantics;
+
 struct ib_qp_init_attr {
 	/* This callback occurs in workqueue context */
 	void                  (*event_handler)(struct ib_event *, void *);
@@ -1263,6 +1266,15 @@ struct ib_qp_init_attr {
 	u32			port_num;
 	struct ib_rwq_ind_table *rwq_ind_tbl;
 	u32			source_qpn;
+
+	/* The initiator ID this QP sends with, the caller's rank in its job.
+	 * UET lets the caller choose it; the JobID is what is trusted.
+	 */
+	u32			src_id;
+	/* the job this QP belongs to */
+	struct ib_jkey		*jkey;
+	/* what the caller asked the QP to guarantee, NULL if it didn't ask */
+	struct ib_qp_semantics	*qp_semantics;
 };
 
 struct ib_qp_open_attr {
@@ -2009,6 +2021,8 @@ struct ib_qp {
 	enum ib_qp_type		qp_type;
 	struct ib_rwq_ind_table *rwq_ind_tbl;
 	struct ib_qp_security  *qp_sec;
+	/* the job key this pair was created within, NULL if none */
+	struct ib_jkey	       *jkey;
 	u32			port;
 
 	bool			integrity_en;
diff --git a/include/uapi/rdma/ib_user_ioctl_cmds.h b/include/uapi/rdma/ib_user_ioctl_cmds.h
index 6a0cd11e7b31..e1ffe3a662a0 100644
--- a/include/uapi/rdma/ib_user_ioctl_cmds.h
+++ b/include/uapi/rdma/ib_user_ioctl_cmds.h
@@ -178,6 +178,9 @@ enum uverbs_attrs_create_qp_cmd_attr_ids {
 	UVERBS_ATTR_CREATE_QP_BUF_UMEM,
 	UVERBS_ATTR_CREATE_QP_RQ_BUF_UMEM,
 	UVERBS_ATTR_CREATE_QP_SQ_BUF_UMEM,
+	UVERBS_ATTR_CREATE_QP_SRC_ID,
+	UVERBS_ATTR_CREATE_QP_SEMANTICS,
+	UVERBS_ATTR_CREATE_QP_JOB_KEY,
 	UVERBS_ATTR_CREATE_QP_ATTR,
 };
 

-- 
2.56.0

