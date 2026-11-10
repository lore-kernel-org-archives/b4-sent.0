From: Eric Davis <eric.davis@broadcom.com>
Date: Mon, 09 Nov 2026 20:00:44 -0800
Subject: [PATCH rdma-next v3 11/13] RDMA/core: extended memory registration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-uet-ib-core-v3-11-3e7e7ffed2e9@broadcom.com>
References: <20261109-uet-ib-core-v3-0-3e7e7ffed2e9@broadcom.com>
In-Reply-To: <20261109-uet-ib-core-v3-0-3e7e7ffed2e9@broadcom.com>
To: Jason Gunthorpe <jgg@ziepe.ca>, Leon Romanovsky <leon@kernel.org>
Cc: linux-rdma@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Eric Davis <eric.davis@broadcom.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794283250; l=16788;
 i=eric.davis@broadcom.com; s=20261014; h=from:subject:message-id;
 bh=/P1ZKVTCIQYFoDk1FAhmhsp0eJwheAwpJBooMc7LKmk=;
 b=3j1xiVPLFCvwHv72ftQJLkElOJIyQOFO/mogVu8W6t7Slj1iVqs1xkr85qbtG+MSzGtdq2it/
 bBKGCng5DxtCY40UAhBC4mLvkqPgoegFt8MhCXftS4AgpBiqlbrKoWV
X-Developer-Key: i=eric.davis@broadcom.com; a=ed25519;
 pk=uy3oCTOYBipIPjryXGMynBmtPvbO6qN2FOrduzpiI4A=
X-Endpoint-Received: by B4 Relay for eric.davis@broadcom.com/20261014 with auth_id=1186
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Memory registration for an unconnected transport may take more than an
address and an access mask. A job to bind the region to, a key the caller
chose, or a region carved out of another. None of it fits the write()
command, so add a device method that takes the wider set of attributes
and reach it when the ioctl carries any of these new fields.

A region bound to a job holds a reference to its job key until it is
deregistered.

Signed-off-by: Eric Davis <eric.davis@broadcom.com>
---
 drivers/infiniband/core/device.c              |   1 +
 drivers/infiniband/core/uverbs_cmd.c          |   7 +-
 drivers/infiniband/core/uverbs_std_types_mr.c | 187 +++++++++++++++++++++++++-
 drivers/infiniband/core/verbs.c               |   9 ++
 include/rdma/ib_verbs.h                       |  46 +++++++
 include/uapi/rdma/ib_user_ioctl_cmds.h        |   5 +
 include/uapi/rdma/ib_user_ioctl_verbs.h       |  10 ++
 7 files changed, 260 insertions(+), 5 deletions(-)

diff --git a/drivers/infiniband/core/device.c b/drivers/infiniband/core/device.c
index cf2a59afcf76..fd45decf9c4f 100644
--- a/drivers/infiniband/core/device.c
+++ b/drivers/infiniband/core/device.c
@@ -3028,6 +3028,7 @@ void ib_set_device_ops(struct ib_device *dev, const struct ib_device_ops *ops)
 	SET_DEVICE_OP(dev_ops, reg_dm_mr);
 	SET_DEVICE_OP(dev_ops, reg_user_mr);
 	SET_DEVICE_OP(dev_ops, reg_user_mr_dmabuf);
+	SET_DEVICE_OP(dev_ops, reg_user_mr_ex);
 	SET_DEVICE_OP(dev_ops, req_notify_cq);
 	SET_DEVICE_OP(dev_ops, rereg_user_mr);
 	SET_DEVICE_OP(dev_ops, resize_user_cq);
diff --git a/drivers/infiniband/core/uverbs_cmd.c b/drivers/infiniband/core/uverbs_cmd.c
index afe891e7b42d..fa9a02ef3070 100644
--- a/drivers/infiniband/core/uverbs_cmd.c
+++ b/drivers/infiniband/core/uverbs_cmd.c
@@ -731,6 +731,7 @@ static int ib_uverbs_reg_mr(struct uverbs_attr_bundle *attrs)
 	mr->type    = IB_MR_TYPE_USER;
 	mr->dm	    = NULL;
 	mr->sig_attrs = NULL;
+	ib_mr_init_core_refs(mr);
 	mr->uobject = uobj;
 	atomic_inc(&pd->usecnt);
 	mr->iova = cmd.hca_va;
@@ -790,7 +791,10 @@ static int ib_uverbs_rereg_mr(struct uverbs_attr_bundle *attrs)
 
 	mr = uobj->object;
 
-	if (mr->dm) {
+	/* A region bound to a job or to another region is re-created rather
+	 * than re-registered, so those bindings can't be lost or bypassed.
+	 */
+	if (mr->dm || mr->jkey || mr->parent || atomic_read(&mr->usecnt)) {
 		ret = -EINVAL;
 		goto put_uobjs;
 	}
@@ -838,6 +842,7 @@ static int ib_uverbs_rereg_mr(struct uverbs_attr_bundle *attrs)
 		new_mr->device = new_pd->device;
 		new_mr->pd = new_pd;
 		new_mr->type = IB_MR_TYPE_USER;
+		ib_mr_init_core_refs(new_mr);
 		new_mr->uobject = uobj;
 		atomic_inc(&new_pd->usecnt);
 		new_uobj->object = new_mr;
diff --git a/drivers/infiniband/core/uverbs_std_types_mr.c b/drivers/infiniband/core/uverbs_std_types_mr.c
index 0c72f801e0d3..8d281d13d210 100644
--- a/drivers/infiniband/core/uverbs_std_types_mr.c
+++ b/drivers/infiniband/core/uverbs_std_types_mr.c
@@ -40,8 +40,13 @@ static int uverbs_free_mr(struct ib_uobject *uobject,
 			  enum rdma_remove_reason why,
 			  struct uverbs_attr_bundle *attrs)
 {
-	return ib_dereg_mr_user((struct ib_mr *)uobject->object,
-				&attrs->driver_udata);
+	struct ib_mr *mr = uobject->object;
+
+	/* regions derived from this one still use it */
+	if (atomic_read(&mr->usecnt))
+		return -EBUSY;
+
+	return ib_dereg_mr_user(mr, &attrs->driver_udata);
 }
 
 static int UVERBS_HANDLER(UVERBS_METHOD_ADVISE_MR)(
@@ -132,6 +137,7 @@ static int UVERBS_HANDLER(UVERBS_METHOD_DM_MR_REG)(
 	mr->pd      = pd;
 	mr->type    = IB_MR_TYPE_DM;
 	mr->dm      = dm;
+	ib_mr_init_core_refs(mr);
 	mr->uobject = uobj;
 	atomic_inc(&pd->usecnt);
 	atomic_inc(&dm->usecnt);
@@ -246,6 +252,9 @@ static int UVERBS_HANDLER(UVERBS_METHOD_REG_DMABUF_MR)(
 	mr->device = pd->device;
 	mr->pd = pd;
 	mr->type = IB_MR_TYPE_USER;
+	mr->iova = iova;
+	mr->length = length;
+	ib_mr_init_core_refs(mr);
 	mr->uobject = uobj;
 	atomic_inc(&pd->usecnt);
 
@@ -266,6 +275,118 @@ static int UVERBS_HANDLER(UVERBS_METHOD_REG_DMABUF_MR)(
 	return ret;
 }
 
+/* Attributes that an extended MR registration uses. The 64b wide keys are
+ * not in the list as they are not a property of how the MR was registered
+ * and instead a device property which could be used by an ordinary register.
+ */
+static const u16 reg_mr_ext_attrs[] = {
+	UVERBS_ATTR_REG_MR_FLAGS,
+	UVERBS_ATTR_REG_MR_JKEY_HANDLE,
+	UVERBS_ATTR_REG_MR_PARENT_MR_HANDLE,
+	UVERBS_ATTR_REG_MR_DERIVE_CNT,
+	UVERBS_ATTR_REG_MR_REQ_RKEY64,
+};
+
+static bool reg_mr_has_ext_attrs(struct uverbs_attr_bundle *attrs)
+{
+	unsigned int i;
+
+	for (i = 0; i < ARRAY_SIZE(reg_mr_ext_attrs); i++)
+		if (uverbs_attr_is_valid(attrs, reg_mr_ext_attrs[i]))
+			return true;
+
+	return false;
+}
+
+static int reg_mr_ex_attr(struct uverbs_attr_bundle *attrs, struct ib_pd *pd,
+			  struct ib_mr_ex_attr *ex)
+{
+	u64 caps = pd->device->attrs.device_cap_flags;
+	int ret;
+
+	ret = uverbs_get_flags32(&ex->flags, attrs, UVERBS_ATTR_REG_MR_FLAGS,
+				 (IB_UVERBS_REG_MR_USER_RKEY |
+				  IB_UVERBS_REG_MR_IDEMPOTENT_SAFE));
+	if (ret)
+		return ret;
+
+	if (uverbs_attr_is_valid(attrs, UVERBS_ATTR_REG_MR_JKEY_HANDLE)) {
+		struct ib_jkey *jkey = uverbs_attr_get_obj(
+			attrs, UVERBS_ATTR_REG_MR_JKEY_HANDLE);
+
+		if (IS_ERR(jkey))
+			return PTR_ERR(jkey);
+
+		/* a key acts within the PD it was made on */
+		if (jkey->pd != pd)
+			return -EINVAL;
+
+		if (!(caps & (IB_DEVICE_MR_JOB_RESTRICTED |
+			      IB_DEVICE_MR_QP_JOB_RESTRICTED)))
+			return -EOPNOTSUPP;
+
+		ex->jkey = jkey;
+	}
+
+	/* a region carved out of another, execute the range check */
+	if (uverbs_attr_is_valid(attrs, UVERBS_ATTR_REG_MR_PARENT_MR_HANDLE)) {
+		struct ib_mr *parent = uverbs_attr_get_obj(
+			attrs, UVERBS_ATTR_REG_MR_PARENT_MR_HANDLE);
+
+		if (IS_ERR(parent))
+			return PTR_ERR(parent);
+
+		if (parent->pd != pd || parent->type != IB_MR_TYPE_USER)
+			return -EINVAL;
+
+		/* a window stays within its parent's job */
+		if (parent->jkey &&
+		    (!ex->jkey || ex->jkey->job != parent->jkey->job))
+			return -EINVAL;
+
+		if ((ex->iova < parent->iova) ||
+		    (ex->length > parent->length) ||
+		    ((ex->iova - parent->iova) >
+		     (parent->length - ex->length)))
+			return -EINVAL;
+
+		ex->parent_mr = parent;
+	}
+
+	if (uverbs_attr_is_valid(attrs, UVERBS_ATTR_REG_MR_DERIVE_CNT)) {
+		ret = uverbs_copy_from(&ex->derive_cnt, attrs,
+				       UVERBS_ATTR_REG_MR_DERIVE_CNT);
+		if (ret)
+			return ret;
+	}
+
+	if (ex->flags & IB_UVERBS_REG_MR_USER_RKEY) {
+		if (!(caps & IB_DEVICE_USER_RKEY))
+			return -EOPNOTSUPP;
+
+		ret = uverbs_copy_from(&ex->req_rkey64, attrs,
+				       UVERBS_ATTR_REG_MR_REQ_RKEY64);
+		if (ret)
+			return ret;
+
+		if (ex->req_rkey64 > U32_MAX && !(caps & IB_DEVICE_KEY64))
+			return -EOPNOTSUPP;
+	} else if (uverbs_attr_is_valid(attrs,
+					UVERBS_ATTR_REG_MR_REQ_RKEY64)) {
+		/* a key with no flag to say it is the caller's */
+		return -EINVAL;
+	}
+
+	/* Idempotent-safe is a property of the key so it can only be asked
+	 * for on a key the caller chose.
+	 */
+	if ((ex->flags & IB_UVERBS_REG_MR_IDEMPOTENT_SAFE) &&
+	    !(ex->flags & IB_UVERBS_REG_MR_USER_RKEY))
+		return -EINVAL;
+
+	return 0;
+}
+
 static int UVERBS_HANDLER(UVERBS_METHOD_REG_MR)(
 	struct uverbs_attr_bundle *attrs)
 {
@@ -276,10 +397,12 @@ static int UVERBS_HANDLER(UVERBS_METHOD_REG_MR)(
 	u32 valid_access_flags = IB_ACCESS_SUPPORTED;
 	u64 length, iova, fd_offset = 0, addr = 0;
 	struct ib_device *ib_dev = pd->device;
+	struct ib_mr_ex_attr ex = { .fd = -1 };
 	struct ib_dmah *dmah = NULL;
 	bool has_fd_offset = false;
 	bool has_addr = false;
 	bool has_fd = false;
+	bool has_ext;
 	u32 access_flags;
 	struct ib_mr *mr;
 	int fd;
@@ -293,6 +416,10 @@ static int UVERBS_HANDLER(UVERBS_METHOD_REG_MR)(
 	if (ret)
 		return ret;
 
+	has_ext = reg_mr_has_ext_attrs(attrs);
+	if (has_ext && !ib_dev->ops.reg_user_mr_ex)
+		return -EOPNOTSUPP;
+
 	if (uverbs_attr_is_valid(attrs, UVERBS_ATTR_REG_MR_ADDR)) {
 		ret = uverbs_copy_from(&addr, attrs,
 				       UVERBS_ATTR_REG_MR_ADDR);
@@ -318,7 +445,8 @@ static int UVERBS_HANDLER(UVERBS_METHOD_REG_MR)(
 	}
 
 	if (has_fd) {
-		if (!ib_dev->ops.reg_user_mr_dmabuf)
+		/* an extended registration hands the fd to reg_user_mr_ex */
+		if (!has_ext && !ib_dev->ops.reg_user_mr_dmabuf)
 			return -EOPNOTSUPP;
 
 		/* FD requires offset and can't come with addr */
@@ -358,7 +486,27 @@ static int UVERBS_HANDLER(UVERBS_METHOD_REG_MR)(
 	if (ret)
 		return ret;
 
-	if (has_fd)
+	if (has_ext) {
+		ex.addr = addr;
+		ex.length = length;
+		ex.iova = iova;
+		ex.access_flags = access_flags;
+		ex.dmah = dmah;
+		if (has_fd) {
+			/* -1 already names host memory to the driver */
+			if (fd < 0)
+				return -EBADF;
+			ex.fd = fd;
+			ex.fd_offset = fd_offset;
+		}
+
+		ret = reg_mr_ex_attr(attrs, pd, &ex);
+		if (ret)
+			return ret;
+
+		mr = pd->device->ops.reg_user_mr_ex(pd, &ex,
+						    &attrs->driver_udata);
+	} else if (has_fd)
 		mr = pd->device->ops.reg_user_mr_dmabuf(pd, fd_offset, length,
 							iova, fd, access_flags,
 							dmah, attrs);
@@ -373,12 +521,26 @@ static int UVERBS_HANDLER(UVERBS_METHOD_REG_MR)(
 	mr->device = pd->device;
 	mr->pd = pd;
 	mr->type = IB_MR_TYPE_USER;
+	mr->iova = iova;
+	mr->length = length;
+	ib_mr_init_core_refs(mr);
 	mr->uobject = uobj;
 	atomic_inc(&pd->usecnt);
 	if (dmah) {
 		mr->dmah = dmah;
 		atomic_inc(&dmah->usecnt);
 	}
+
+	/* hold a reference to the job key, deregistration will drop it */
+	mr->jkey = ex.jkey;
+	if (ex.jkey)
+		atomic_inc(&ex.jkey->usecnt);
+
+	/* and to the region this one was derived from */
+	mr->parent = ex.parent_mr;
+	if (ex.parent_mr)
+		atomic_inc(&ex.parent_mr->usecnt);
+
 	rdma_restrack_new(&mr->res, RDMA_RESTRACK_MR);
 	rdma_restrack_set_name(&mr->res, NULL);
 	rdma_restrack_add(&mr->res);
@@ -529,6 +691,23 @@ DECLARE_UVERBS_NAMED_METHOD(
 	UVERBS_ATTR_PTR_OUT(UVERBS_ATTR_REG_MR_RESP_RKEY,
 			    UVERBS_ATTR_TYPE(u32),
 			    UA_MANDATORY),
+	UVERBS_ATTR_FLAGS_IN(UVERBS_ATTR_REG_MR_FLAGS,
+			     enum ib_uverbs_reg_mr_flags,
+			     UA_OPTIONAL),
+	UVERBS_ATTR_IDR(UVERBS_ATTR_REG_MR_JKEY_HANDLE,
+			UVERBS_OBJECT_JKEY,
+			UVERBS_ACCESS_READ,
+			UA_OPTIONAL),
+	UVERBS_ATTR_IDR(UVERBS_ATTR_REG_MR_PARENT_MR_HANDLE,
+			UVERBS_OBJECT_MR,
+			UVERBS_ACCESS_READ,
+			UA_OPTIONAL),
+	UVERBS_ATTR_PTR_IN(UVERBS_ATTR_REG_MR_DERIVE_CNT,
+			   UVERBS_ATTR_TYPE(u32),
+			   UA_OPTIONAL),
+	UVERBS_ATTR_PTR_IN(UVERBS_ATTR_REG_MR_REQ_RKEY64,
+			   UVERBS_ATTR_TYPE(u64),
+			   UA_OPTIONAL),
 	UVERBS_ATTR_UHW());
 
 DECLARE_UVERBS_NAMED_METHOD_DESTROY(
diff --git a/drivers/infiniband/core/verbs.c b/drivers/infiniband/core/verbs.c
index 9359318141b7..a80d750777f4 100644
--- a/drivers/infiniband/core/verbs.c
+++ b/drivers/infiniband/core/verbs.c
@@ -2374,6 +2374,7 @@ struct ib_mr *ib_reg_user_mr(struct ib_pd *pd, u64 start, u64 length,
 	mr->type = IB_MR_TYPE_USER;
 	mr->pd = pd;
 	mr->dm = NULL;
+	ib_mr_init_core_refs(mr);
 	atomic_inc(&pd->usecnt);
 	mr->iova =  virt_addr;
 	mr->length = length;
@@ -2405,6 +2406,8 @@ int ib_dereg_mr_user(struct ib_mr *mr, struct ib_udata *udata)
 	struct ib_pd *pd = mr->pd;
 	struct ib_dm *dm = mr->dm;
 	struct ib_dmah *dmah = mr->dmah;
+	struct ib_jkey *jkey = mr->jkey;
+	struct ib_mr *parent = mr->parent;
 	struct ib_sig_attrs *sig_attrs = mr->sig_attrs;
 	int ret;
 
@@ -2417,6 +2420,10 @@ int ib_dereg_mr_user(struct ib_mr *mr, struct ib_udata *udata)
 			atomic_dec(&dm->usecnt);
 		if (dmah)
 			atomic_dec(&dmah->usecnt);
+		if (jkey)
+			atomic_dec(&jkey->usecnt);
+		if (parent)
+			atomic_dec(&parent->usecnt);
 		kfree(sig_attrs);
 	}
 
@@ -2464,6 +2471,7 @@ struct ib_mr *ib_alloc_mr(struct ib_pd *pd, enum ib_mr_type mr_type,
 	mr->need_inval = false;
 	mr->type = mr_type;
 	mr->sig_attrs = NULL;
+	ib_mr_init_core_refs(mr);
 
 	rdma_restrack_new(&mr->res, RDMA_RESTRACK_MR);
 	rdma_restrack_parent_name(&mr->res, &pd->res);
@@ -2525,6 +2533,7 @@ struct ib_mr *ib_alloc_mr_integrity(struct ib_pd *pd,
 	mr->need_inval = false;
 	mr->type = IB_MR_TYPE_INTEGRITY;
 	mr->sig_attrs = sig_attrs;
+	ib_mr_init_core_refs(mr);
 
 	rdma_restrack_new(&mr->res, RDMA_RESTRACK_MR);
 	rdma_restrack_parent_name(&mr->res, &pd->res);
diff --git a/include/rdma/ib_verbs.h b/include/rdma/ib_verbs.h
index 8be766b80ce0..07fd5731d458 100644
--- a/include/rdma/ib_verbs.h
+++ b/include/rdma/ib_verbs.h
@@ -2084,6 +2084,13 @@ struct ib_mr {
 		struct list_head	qp_entry;	/* FR */
 	};
 
+	/* the job this region is restricted to, NULL if it is unrestricted */
+	struct ib_jkey	  *jkey;
+	/* the region this one was derived from, NULL if registered fresh */
+	struct ib_mr	  *parent;
+	/* regions derived from this one that are still registered */
+	atomic_t	   usecnt;
+
 	struct ib_dm      *dm;
 	struct ib_sig_attrs *sig_attrs; /* only for IB_MR_TYPE_INTEGRITY MRs */
 	struct ib_dmah *dmah;
@@ -2098,6 +2105,28 @@ struct ib_mr {
 	struct rdma_restrack_entry res;
 };
 
+struct ib_mr_ex_attr {
+	u64			addr;
+	u64			length;
+	u64			iova;
+	u32			access_flags;	/* enum ib_access_flags */
+	u32			flags;		/* enum ib_uverbs_reg_mr_flags */
+	int			fd;		/* -1 = host memory addr */
+	u64			fd_offset;
+	struct ib_dmah		*dmah;
+	/* bind the region to a job, NULL leaves it unrestricted */
+	struct ib_jkey		*jkey;
+	/* carve/derive the region out of this one, NULL registers fresh. The
+	 * driver refuses a region outside the parent's memory, or with access
+	 * the parent lacks.
+	 */
+	struct ib_mr		*parent_mr;
+	/* how many regions the user expects to derive from this one */
+	u32			derive_cnt;
+	/* the key the user chose, valid with IB_UVERBS_REG_MR_USER_RKEY */
+	u64			req_rkey64;
+};
+
 struct ib_mw {
 	struct ib_device	*device;
 	struct ib_pd		*pd;
@@ -2813,6 +2842,9 @@ struct ib_device_ops {
 				       u64 length, u64 virt_addr,
 				       int mr_access_flags, struct ib_pd *pd,
 				       struct ib_udata *udata);
+	struct ib_mr *(*reg_user_mr_ex)(struct ib_pd *pd,
+					struct ib_mr_ex_attr *attr,
+					struct ib_udata *udata);
 	int (*dereg_mr)(struct ib_mr *mr, struct ib_udata *udata);
 	int (*query_qp_semantics)(struct ib_device *device,
 				  enum ib_qp_type qp_type,
@@ -4818,6 +4850,20 @@ static inline u32 ib_inc_rkey(u32 rkey)
 	return ((rkey + 1) & mask) | (rkey & ~mask);
 }
 
+/**
+ * ib_mr_init_core_refs - clears what core reads back when an MR is
+ *   deregistered.
+ * @mr: struct ib_mr pointer to initialize.
+ *
+ * A driver's MR need not be zeroed, so every path that makes an MR calls this.
+ */
+static inline void ib_mr_init_core_refs(struct ib_mr *mr)
+{
+	mr->jkey = NULL;
+	mr->parent = NULL;
+	atomic_set(&mr->usecnt, 0);
+}
+
 /**
  * ib_attach_mcast - Attaches the specified QP to a multicast group.
  * @qp: QP to attach to the multicast group.  The QP must be type
diff --git a/include/uapi/rdma/ib_user_ioctl_cmds.h b/include/uapi/rdma/ib_user_ioctl_cmds.h
index 1de6a1ffd92c..fd8372c0c550 100644
--- a/include/uapi/rdma/ib_user_ioctl_cmds.h
+++ b/include/uapi/rdma/ib_user_ioctl_cmds.h
@@ -369,6 +369,11 @@ enum uverbs_attrs_reg_mr_cmd_attr_ids {
 	UVERBS_ATTR_REG_MR_FD_OFFSET,
 	UVERBS_ATTR_REG_MR_RESP_LKEY,
 	UVERBS_ATTR_REG_MR_RESP_RKEY,
+	UVERBS_ATTR_REG_MR_FLAGS,
+	UVERBS_ATTR_REG_MR_JKEY_HANDLE,
+	UVERBS_ATTR_REG_MR_PARENT_MR_HANDLE,
+	UVERBS_ATTR_REG_MR_DERIVE_CNT,
+	UVERBS_ATTR_REG_MR_REQ_RKEY64,
 };
 
 enum uverbs_attrs_create_counters_cmd_attr_ids {
diff --git a/include/uapi/rdma/ib_user_ioctl_verbs.h b/include/uapi/rdma/ib_user_ioctl_verbs.h
index 9ae45f7d3dc0..c0532fa418a7 100644
--- a/include/uapi/rdma/ib_user_ioctl_verbs.h
+++ b/include/uapi/rdma/ib_user_ioctl_verbs.h
@@ -303,6 +303,16 @@ struct ib_uverbs_buffer_desc {
 	__aligned_u64 length;
 };
 
+/* Extended memory registration, for devices whose memory keys are 64 bits
+ * wide and may be bound to a job. See UVERBS_ATTR_REG_MR_FLAGS.
+ */
+enum ib_uverbs_reg_mr_flags {
+	/* REQ_RKEY64 carries the key, rather than the device assigning one */
+	IB_UVERBS_REG_MR_USER_RKEY		= 1 << 0,
+	/* the region tolerates a replayed idempotent operation */
+	IB_UVERBS_REG_MR_IDEMPOTENT_SAFE	= 1 << 1,
+};
+
 /* A UET reliable unconnected queue pair number uses all 32 bits:
  *
  *	[ absolute 1b | reserved 7b | resource index 12b | PIDonFEP 12b ]

-- 
2.56.0

