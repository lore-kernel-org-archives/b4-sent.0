From: Eric Davis <eric.davis@broadcom.com>
Date: Mon, 19 Oct 2026 20:03:36 -0700
Subject: [PATCH rdma-next v2 09/13] RDMA/core: create a queue pair ready to
 send
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-uet-ib-core-v2-9-8bd654f25370@broadcom.com>
References: <20261019-uet-ib-core-v2-0-8bd654f25370@broadcom.com>
In-Reply-To: <20261019-uet-ib-core-v2-0-8bd654f25370@broadcom.com>
To: Jason Gunthorpe <jgg@ziepe.ca>, Leon Romanovsky <leon@kernel.org>
Cc: linux-rdma@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Eric Davis <eric.davis@broadcom.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792465414; l=5409;
 i=eric.davis@broadcom.com; s=20261014; h=from:subject:message-id;
 bh=fjYmbaM78O8z3VKnOCRv57FNmInPGNiFJkeFjQOBCYs=;
 b=2WNAco30kBPtpprRz/gCTLreO/yJdUztsPp/I1zeg1BoUUjrLKb4uEYL9nVOM+t0NRHw+2O4B
 GYrfQQE6AY+B09DdKu7Tog1T9IHKOHxWYswveS8eD1enLTcSMr7NaOx
X-Developer-Key: i=eric.davis@broadcom.com; a=ed25519;
 pk=uy3oCTOYBipIPjryXGMynBmtPvbO6qN2FOrduzpiI4A=
X-Endpoint-Received: by B4 Relay for eric.davis@broadcom.com/20261014 with auth_id=1186
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some transports have nothing to negotiate, so a queue pair can be ready
to send the moment it exists and the modify sequence carries no useful
information. Let a reliable unconnected queue pair be created with the
attributes that sequence would have supplied, in the same form the
modify command uses, and apply them as that modify to RTS once the
queue pair exists, so its checks run. A queue pair whose modify fails
is destroyed.

Note that the QP handle field is refused, since the create is what makes
the handle.

Signed-off-by: Eric Davis <eric.davis@broadcom.com>
---
 drivers/infiniband/core/uverbs_std_types_qp.c | 80 +++++++++++++++++++++++++++
 include/uapi/rdma/ib_user_ioctl_cmds.h        |  1 +
 2 files changed, 81 insertions(+)

diff --git a/drivers/infiniband/core/uverbs_std_types_qp.c b/drivers/infiniband/core/uverbs_std_types_qp.c
index 30fc20fb251f..c6225156fe30 100644
--- a/drivers/infiniband/core/uverbs_std_types_qp.c
+++ b/drivers/infiniband/core/uverbs_std_types_qp.c
@@ -79,6 +79,61 @@ static void set_caps(struct ib_qp_init_attr *attr,
 	}
 }
 
+/* what a reliable unconnected QP may be created ready to send with */
+#define CREATE_QP_ATTR_RU_MASK	(IB_QP_STATE | IB_QP_PKEY_INDEX |	\
+				 IB_QP_PORT | IB_QP_ACCESS_FLAGS |	\
+				 IB_QP_PATH_MTU)
+
+/* The attributes the QP would be modified with via modify_qp calls. Used for
+ * implementations that support having QPs be in RTS immediately after QP
+ * creation. These attributes arrive in the same format the modify command
+ * uses so that converter serves both, and they are applied as that modify
+ * to RTS, once the QP exists.
+ */
+static int create_qp_attr_set(struct uverbs_attr_bundle *attrs,
+			      struct ib_device *device,
+			      struct ib_qp_init_attr *attr,
+			      struct ib_qp_attr *qp_attr, u32 *mask)
+{
+	struct ib_uverbs_ex_modify_qp uqpa = {};
+	int ret;
+
+	*mask = 0;
+
+	if (!uverbs_attr_is_valid(attrs, UVERBS_ATTR_CREATE_QP_ATTR))
+		return 0;
+
+	if (attr->qp_type != IB_QPT_RU ||
+	    !(device->attrs.device_cap_flags & IB_DEVICE_RU))
+		return -EOPNOTSUPP;
+
+	ret = uverbs_copy_from_or_zero(&uqpa, attrs,
+				       UVERBS_ATTR_CREATE_QP_ATTR);
+	if (ret)
+		return ret;
+
+	/* the create is what makes the handle, can't be one specified */
+	if (uqpa.base.qp_handle)
+		return -EINVAL;
+
+	if (uqpa.reserved || uqpa.base.reserved[0] || uqpa.base.reserved[1])
+		return -EINVAL;
+
+	ret = ib_uverbs_copy_qp_attr(attrs, device, qp_attr, &uqpa,
+				     uqpa.base.attr_mask);
+	if (ret)
+		return ret;
+
+	if ((uqpa.base.attr_mask & ~CREATE_QP_ATTR_RU_MASK) ||
+	    ((uqpa.base.attr_mask & IB_QP_STATE) &&
+	     uqpa.base.qp_state != IB_QPS_RTS))
+		return -EINVAL;
+
+	*mask = uqpa.base.attr_mask;
+
+	return 0;
+}
+
 static int UVERBS_HANDLER(UVERBS_METHOD_QP_CREATE)(
 	struct uverbs_attr_bundle *attrs)
 {
@@ -86,6 +141,8 @@ static int UVERBS_HANDLER(UVERBS_METHOD_QP_CREATE)(
 		uverbs_attr_get_uobject(attrs, UVERBS_ATTR_CREATE_QP_HANDLE),
 		typeof(*obj), uevent.uobject);
 	struct ib_qp_init_attr attr = {};
+	struct ib_qp_attr qp_attr = {};
+	u32 qp_attr_mask;
 	struct ib_uverbs_qp_cap cap = {};
 	struct ib_rwq_ind_table *rwq_ind_tbl = NULL;
 	struct ib_qp *qp;
@@ -214,6 +271,11 @@ static int UVERBS_HANDLER(UVERBS_METHOD_QP_CREATE)(
 		attr.create_flags |= IB_QP_CREATE_SOURCE_QPN;
 	}
 
+	ret = create_qp_attr_set(attrs, device, &attr, &qp_attr,
+				 &qp_attr_mask);
+	if (ret)
+		return ret;
+
 	srq = uverbs_attr_get_obj(attrs,
 				  UVERBS_ATTR_CREATE_QP_SRQ_HANDLE);
 	if (!IS_ERR(srq)) {
@@ -264,6 +326,20 @@ static int UVERBS_HANDLER(UVERBS_METHOD_QP_CREATE)(
 	obj->uevent.uobject.object = qp;
 	uverbs_finalize_uobj_create(attrs, UVERBS_ATTR_CREATE_QP_HANDLE);
 
+	/* A reliable unconnected QP is ready to send once created. What the
+	 * caller passed is applied as the modify to RTS it stands in for, so
+	 * the modify's checks run. A failure here destroys the QP.
+	 */
+	if (attr.qp_type == IB_QPT_RU) {
+		qp_attr.qp_state = IB_QPS_RTS;
+		/* the driver's data was for create, there is none for this */
+		ret = ib_modify_qp_with_udata(qp, &qp_attr,
+					      qp_attr_mask | IB_QP_STATE,
+					      uverbs_get_cleared_udata(attrs));
+		if (ret)
+			return ret;
+	}
+
 	set_caps(&attr, &cap, false);
 	ret = uverbs_copy_to_struct_or_zero(attrs,
 					UVERBS_ATTR_CREATE_QP_RESP_CAP, &cap,
@@ -325,6 +401,10 @@ DECLARE_UVERBS_NAMED_METHOD(
 	UVERBS_ATTR_FLAGS_IN(UVERBS_ATTR_CREATE_QP_FLAGS,
 			     enum ib_uverbs_qp_create_flags,
 			     UA_OPTIONAL),
+	UVERBS_ATTR_PTR_IN(UVERBS_ATTR_CREATE_QP_ATTR,
+			   UVERBS_ATTR_STRUCT(struct ib_uverbs_ex_modify_qp,
+					      reserved),
+			   UA_OPTIONAL),
 	UVERBS_ATTR_PTR_IN(UVERBS_ATTR_CREATE_QP_SOURCE_QPN,
 			   UVERBS_ATTR_TYPE(u32),
 			   UA_OPTIONAL),
diff --git a/include/uapi/rdma/ib_user_ioctl_cmds.h b/include/uapi/rdma/ib_user_ioctl_cmds.h
index 70de1e4001c3..b2bf8ca92397 100644
--- a/include/uapi/rdma/ib_user_ioctl_cmds.h
+++ b/include/uapi/rdma/ib_user_ioctl_cmds.h
@@ -179,6 +179,7 @@ enum uverbs_attrs_create_qp_cmd_attr_ids {
 	UVERBS_ATTR_CREATE_QP_BUF_UMEM,
 	UVERBS_ATTR_CREATE_QP_RQ_BUF_UMEM,
 	UVERBS_ATTR_CREATE_QP_SQ_BUF_UMEM,
+	UVERBS_ATTR_CREATE_QP_ATTR,
 };
 
 enum uverbs_attrs_destroy_qp_cmd_attr_ids {

-- 
2.56.0

