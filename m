From: Eric Davis <eric.davis@broadcom.com>
Date: Mon, 09 Nov 2026 20:00:46 -0800
Subject: [PATCH rdma-next v3 13/13] RDMA/core: attach a memory region to a
 queue pair
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-uet-ib-core-v3-13-3e7e7ffed2e9@broadcom.com>
References: <20261109-uet-ib-core-v3-0-3e7e7ffed2e9@broadcom.com>
In-Reply-To: <20261109-uet-ib-core-v3-0-3e7e7ffed2e9@broadcom.com>
To: Jason Gunthorpe <jgg@ziepe.ca>, Leon Romanovsky <leon@kernel.org>
Cc: linux-rdma@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Eric Davis <eric.davis@broadcom.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794283250; l=10229;
 i=eric.davis@broadcom.com; s=20261014; h=from:subject:message-id;
 bh=i0WaytShyBt8PfdvU8b9TZhNRnftG0KclTFSm2GxxaI=;
 b=dGrkvnb60ktifKWgHTXOGvateN0UMZ/ueb/f4vEK5BDBnOJfxH7mIv75qQS1afg3OoTodT6xZ
 8dHlKAmRxyHCuN/8FScEWsbTwu6k1myrgX6t2yS2Skny7jeBwePtocV
X-Developer-Key: i=eric.davis@broadcom.com; a=ed25519;
 pk=uy3oCTOYBipIPjryXGMynBmtPvbO6qN2FOrduzpiI4A=
X-Endpoint-Received: by B4 Relay for eric.davis@broadcom.com/20261014 with auth_id=1186
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A region registered against a protection domain is reachable from every QP
in it. When a device can narrow that, let a region be attached to one QP
and detached again, so the network only reaches the MR over that QP.

Which restrictions a device supports is reported through the memory region
access capability bits.

Signed-off-by: Eric Davis <eric.davis@broadcom.com>
---
 drivers/infiniband/core/device.c              |   2 +
 drivers/infiniband/core/uverbs_std_types_mr.c |   2 +-
 drivers/infiniband/core/uverbs_std_types_qp.c | 116 +++++++++++++++++++++++++-
 drivers/infiniband/core/verbs.c               |  12 +++
 include/rdma/ib_verbs.h                       |  13 ++-
 include/uapi/rdma/ib_user_ioctl_cmds.h        |  12 +++
 6 files changed, 154 insertions(+), 3 deletions(-)

diff --git a/drivers/infiniband/core/device.c b/drivers/infiniband/core/device.c
index fd45decf9c4f..1b838bf3600d 100644
--- a/drivers/infiniband/core/device.c
+++ b/drivers/infiniband/core/device.c
@@ -3018,6 +3018,8 @@ void ib_set_device_ops(struct ib_device *dev, const struct ib_device_ops *ops)
 	SET_DEVICE_OP(dev_ops, query_pkey);
 	SET_DEVICE_OP(dev_ops, query_port);
 	SET_DEVICE_OP(dev_ops, query_port_speed);
+	SET_DEVICE_OP(dev_ops, qp_attach_mr);
+	SET_DEVICE_OP(dev_ops, qp_detach_mr);
 	SET_DEVICE_OP(dev_ops, query_qp);
 	SET_DEVICE_OP(dev_ops, query_qp_semantics);
 	SET_DEVICE_OP(dev_ops, query_srq);
diff --git a/drivers/infiniband/core/uverbs_std_types_mr.c b/drivers/infiniband/core/uverbs_std_types_mr.c
index 5a617a705904..37e591002c75 100644
--- a/drivers/infiniband/core/uverbs_std_types_mr.c
+++ b/drivers/infiniband/core/uverbs_std_types_mr.c
@@ -42,7 +42,7 @@ static int uverbs_free_mr(struct ib_uobject *uobject,
 {
 	struct ib_mr *mr = uobject->object;
 
-	/* regions derived from this one still use it */
+	/* regions derived from this one, or the QP it is attached to, use it */
 	if (atomic_read(&mr->usecnt))
 		return -EBUSY;
 
diff --git a/drivers/infiniband/core/uverbs_std_types_qp.c b/drivers/infiniband/core/uverbs_std_types_qp.c
index a1112083fb73..88a6050d1d04 100644
--- a/drivers/infiniband/core/uverbs_std_types_qp.c
+++ b/drivers/infiniband/core/uverbs_std_types_qp.c
@@ -683,12 +683,126 @@ DECLARE_UVERBS_NAMED_METHOD(
 			     enum ib_uverbs_qp_attach_comp_cntr_op,
 			     UA_MANDATORY));
 
+/* bind a region to the QP that will use it */
+static int UVERBS_HANDLER(UVERBS_METHOD_QP_ATTACH_MR)(
+	struct uverbs_attr_bundle *attrs)
+{
+	struct ib_qp *qp =
+		uverbs_attr_get_obj(attrs, UVERBS_ATTR_QP_ATTACH_MR_QP_HANDLE);
+	struct ib_mr *mr =
+		uverbs_attr_get_obj(attrs, UVERBS_ATTR_QP_ATTACH_MR_MR_HANDLE);
+	u64 caps = qp->device->attrs.device_cap_flags;
+	u32 id;
+	int ret;
+
+	if (!qp->device->ops.qp_attach_mr)
+		return -EOPNOTSUPP;
+
+	if (qp->real_qp != qp || qp->qp_type != IB_QPT_RU)
+		return -EINVAL;
+
+	if (mr->pd != qp->pd || mr->type != IB_MR_TYPE_USER)
+		return -EINVAL;
+
+	/* the device has to implement the access class the region asks for */
+	if (!(caps & (mr->jkey ? IB_DEVICE_MR_QP_JOB_RESTRICTED :
+				 IB_DEVICE_MR_QP_RESTRICTED)))
+		return -EOPNOTSUPP;
+
+	/* a region restricted to a job serves a QP in that job */
+	if (mr->jkey && (!qp->jkey || qp->jkey->job != mr->jkey->job))
+		return -EINVAL;
+
+	/* one QP at a time */
+	if (cmpxchg(&mr->attached_qp, NULL, qp))
+		return -EBUSY;
+
+	ret = xa_alloc(&qp->attached_mrs, &id, mr, xa_limit_32b, GFP_KERNEL);
+	if (ret)
+		goto err_claim;
+
+	ret = qp->device->ops.qp_attach_mr(qp, mr);
+	if (ret)
+		goto err_xa;
+
+	/* the QP holds the region until detach or its own destroy */
+	mr->attach_id = id;
+	atomic_inc(&mr->usecnt);
+	/* the MR's read lock drops with a relaxed atomic, order the hold
+	 * before it so a dereg that gets in next sees the region in use
+	 */
+	smp_mb__after_atomic();
+
+	return 0;
+
+err_xa:
+	xa_erase(&qp->attached_mrs, id);
+err_claim:
+	WRITE_ONCE(mr->attached_qp, NULL);
+	return ret;
+}
+
+static int UVERBS_HANDLER(UVERBS_METHOD_QP_DETACH_MR)(
+	struct uverbs_attr_bundle *attrs)
+{
+	struct ib_qp *qp =
+		uverbs_attr_get_obj(attrs, UVERBS_ATTR_QP_DETACH_MR_QP_HANDLE);
+	struct ib_mr *mr =
+		uverbs_attr_get_obj(attrs, UVERBS_ATTR_QP_DETACH_MR_MR_HANDLE);
+	int ret;
+
+	if (!qp->device->ops.qp_detach_mr)
+		return -EOPNOTSUPP;
+
+	if (qp->real_qp != qp)
+		return -EINVAL;
+
+	if (READ_ONCE(mr->attached_qp) != qp)
+		return -EINVAL;
+
+	ret = qp->device->ops.qp_detach_mr(qp, mr);
+	if (ret)
+		return ret;
+
+	xa_erase(&qp->attached_mrs, mr->attach_id);
+	WRITE_ONCE(mr->attached_qp, NULL);
+	/* once usecnt reads zero the MR can be freed under us */
+	smp_mb__before_atomic();
+	atomic_dec(&mr->usecnt);
+
+	return 0;
+}
+
+DECLARE_UVERBS_NAMED_METHOD(
+	UVERBS_METHOD_QP_ATTACH_MR,
+	UVERBS_ATTR_IDR(UVERBS_ATTR_QP_ATTACH_MR_QP_HANDLE,
+			UVERBS_OBJECT_QP,
+			UVERBS_ACCESS_WRITE,
+			UA_MANDATORY),
+	UVERBS_ATTR_IDR(UVERBS_ATTR_QP_ATTACH_MR_MR_HANDLE,
+			UVERBS_OBJECT_MR,
+			UVERBS_ACCESS_READ,
+			UA_MANDATORY));
+
+DECLARE_UVERBS_NAMED_METHOD(
+	UVERBS_METHOD_QP_DETACH_MR,
+	UVERBS_ATTR_IDR(UVERBS_ATTR_QP_DETACH_MR_QP_HANDLE,
+			UVERBS_OBJECT_QP,
+			UVERBS_ACCESS_WRITE,
+			UA_MANDATORY),
+	UVERBS_ATTR_IDR(UVERBS_ATTR_QP_DETACH_MR_MR_HANDLE,
+			UVERBS_OBJECT_MR,
+			UVERBS_ACCESS_READ,
+			UA_MANDATORY));
+
 DECLARE_UVERBS_NAMED_OBJECT(
 	UVERBS_OBJECT_QP,
 	UVERBS_TYPE_ALLOC_IDR_SZ(sizeof(struct ib_uqp_object), uverbs_free_qp),
 	&UVERBS_METHOD(UVERBS_METHOD_QP_CREATE),
 	&UVERBS_METHOD(UVERBS_METHOD_QP_DESTROY),
-	&UVERBS_METHOD(UVERBS_METHOD_QP_ATTACH_COMP_CNTR));
+	&UVERBS_METHOD(UVERBS_METHOD_QP_ATTACH_COMP_CNTR),
+	&UVERBS_METHOD(UVERBS_METHOD_QP_ATTACH_MR),
+	&UVERBS_METHOD(UVERBS_METHOD_QP_DETACH_MR));
 
 const struct uapi_definition uverbs_def_obj_qp[] = {
 	UAPI_DEF_CHAIN_OBJ_TREE_NAMED(UVERBS_OBJECT_QP,
diff --git a/drivers/infiniband/core/verbs.c b/drivers/infiniband/core/verbs.c
index a80d750777f4..1b6f116c6072 100644
--- a/drivers/infiniband/core/verbs.c
+++ b/drivers/infiniband/core/verbs.c
@@ -1351,6 +1351,7 @@ static struct ib_qp *create_qp(struct ib_device *dev, struct ib_pd *pd,
 
 	spin_lock_init(&qp->mr_lock);
 	xa_init(&qp->comp_cntrs);
+	xa_init_flags(&qp->attached_mrs, XA_FLAGS_ALLOC);
 	INIT_LIST_HEAD(&qp->rdma_mrs);
 	INIT_LIST_HEAD(&qp->sig_mrs);
 	init_completion(&qp->srq_completion);
@@ -1398,6 +1399,7 @@ static struct ib_qp *create_qp(struct ib_device *dev, struct ib_pd *pd,
 err_create:
 	rdma_restrack_put(&qp->res);
 	xa_destroy(&qp->comp_cntrs);
+	xa_destroy(&qp->attached_mrs);
 	kfree(qp);
 	return ERR_PTR(ret);
 
@@ -2228,6 +2230,7 @@ int ib_destroy_qp_user(struct ib_qp *qp, struct ib_udata *udata)
 	struct ib_qp_security *sec;
 	struct ib_comp_cntr *cc;
 	unsigned long index;
+	struct ib_mr *mr;
 	int ret;
 
 	WARN_ON_ONCE(qp->mrs_used > 0);
@@ -2265,6 +2268,15 @@ int ib_destroy_qp_user(struct ib_qp *qp, struct ib_udata *udata)
 		atomic_dec(&cc->usecnt);
 	xa_destroy(&qp->comp_cntrs);
 
+	/* the driver ended the bindings with the QP, release the regions */
+	xa_for_each(&qp->attached_mrs, index, mr) {
+		WRITE_ONCE(mr->attached_qp, NULL);
+		/* once usecnt reads zero the MR can be freed under us */
+		smp_mb__before_atomic();
+		atomic_dec(&mr->usecnt);
+	}
+	xa_destroy(&qp->attached_mrs);
+
 	ib_qp_usecnt_dec(qp);
 	if (sec)
 		ib_destroy_qp_security_end(sec);
diff --git a/include/rdma/ib_verbs.h b/include/rdma/ib_verbs.h
index 3b2903b1c40d..6b36df1cf759 100644
--- a/include/rdma/ib_verbs.h
+++ b/include/rdma/ib_verbs.h
@@ -2003,6 +2003,8 @@ struct ib_qp {
 	struct list_head	xrcd_list;
 	struct xarray		comp_cntrs; /* op_mask -> comp_cntr */
 	u32			comp_cntr_op_mask;
+	/* regions attached to this QP, each held until detach or destroy */
+	struct xarray		attached_mrs;
 
 	/* count times opened, mcast attaches, flow attaches */
 	atomic_t		usecnt;
@@ -2094,8 +2096,11 @@ struct ib_mr {
 	struct ib_jkey	  *jkey;
 	/* the region this one was derived from, NULL if registered fresh */
 	struct ib_mr	  *parent;
-	/* regions derived from this one that are still registered */
+	/* regions derived from this one, and an attachment, that hold it */
 	atomic_t	   usecnt;
+	/* the QP this region is attached to, NULL if none */
+	struct ib_qp	  *attached_qp;
+	u32		   attach_id; /* index in attached_qp->attached_mrs */
 
 	struct ib_dm      *dm;
 	struct ib_sig_attrs *sig_attrs; /* only for IB_MR_TYPE_INTEGRITY MRs */
@@ -2852,6 +2857,11 @@ struct ib_device_ops {
 					struct ib_mr_ex_attr *attr,
 					struct ib_udata *udata);
 	int (*dereg_mr)(struct ib_mr *mr, struct ib_udata *udata);
+	/* attach/detach a region so it is bound to single QP (restricted).
+	 * destroy_qp ends the QP's bindings, then core releases the regions.
+	 */
+	int (*qp_attach_mr)(struct ib_qp *qp, struct ib_mr *mr);
+	int (*qp_detach_mr)(struct ib_qp *qp, struct ib_mr *mr);
 	int (*query_qp_semantics)(struct ib_device *device,
 				  enum ib_qp_type qp_type,
 				  struct ib_qp_semantics *sem);
@@ -4867,6 +4877,7 @@ static inline void ib_mr_init_core_refs(struct ib_mr *mr)
 {
 	mr->jkey = NULL;
 	mr->parent = NULL;
+	mr->attached_qp = NULL;
 	atomic_set(&mr->usecnt, 0);
 
 	if (!(mr->device->attrs.device_cap_flags & IB_DEVICE_KEY64)) {
diff --git a/include/uapi/rdma/ib_user_ioctl_cmds.h b/include/uapi/rdma/ib_user_ioctl_cmds.h
index bc2797fc37fe..8de110b8db34 100644
--- a/include/uapi/rdma/ib_user_ioctl_cmds.h
+++ b/include/uapi/rdma/ib_user_ioctl_cmds.h
@@ -200,6 +200,18 @@ enum uverbs_methods_qp {
 	UVERBS_METHOD_QP_CREATE,
 	UVERBS_METHOD_QP_DESTROY,
 	UVERBS_METHOD_QP_ATTACH_COMP_CNTR,
+	UVERBS_METHOD_QP_ATTACH_MR,
+	UVERBS_METHOD_QP_DETACH_MR,
+};
+
+enum uverbs_attrs_qp_attach_mr_cmd_attr_ids {
+	UVERBS_ATTR_QP_ATTACH_MR_QP_HANDLE,
+	UVERBS_ATTR_QP_ATTACH_MR_MR_HANDLE,
+};
+
+enum uverbs_attrs_qp_detach_mr_cmd_attr_ids {
+	UVERBS_ATTR_QP_DETACH_MR_QP_HANDLE,
+	UVERBS_ATTR_QP_DETACH_MR_MR_HANDLE,
 };
 
 enum uverbs_attrs_create_srq_cmd_attr_ids {

-- 
2.56.0

