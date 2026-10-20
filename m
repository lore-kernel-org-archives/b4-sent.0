From: Eric Davis <eric.davis@broadcom.com>
Date: Mon, 19 Oct 2026 20:03:32 -0700
Subject: [PATCH rdma-next v2 05/13] RDMA/core: extended address handle
 attributes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-uet-ib-core-v2-5-8bd654f25370@broadcom.com>
References: <20261019-uet-ib-core-v2-0-8bd654f25370@broadcom.com>
In-Reply-To: <20261019-uet-ib-core-v2-0-8bd654f25370@broadcom.com>
To: Jason Gunthorpe <jgg@ziepe.ca>, Leon Romanovsky <leon@kernel.org>
Cc: linux-rdma@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Eric Davis <eric.davis@broadcom.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792465414; l=16360;
 i=eric.davis@broadcom.com; s=20261014; h=from:subject:message-id;
 bh=+RAZArxkOHHyIz1RZJtl6WeQSvKnoLFdcl5bSdlpZos=;
 b=bP73Sq9nzVbVziSfsJSNIbfHfHDgRQar1/A+k2vKbQ/v3Ty9SYDsSMohxquGsStGE71zfENNj
 AsQIlv4UkNqB6xj8z51CtX2snbfvSZamCl7/LZKaJwM95GJGh5eU1Nv
X-Developer-Key: i=eric.davis@broadcom.com; a=ed25519;
 pk=uy3oCTOYBipIPjryXGMynBmtPvbO6qN2FOrduzpiI4A=
X-Endpoint-Received: by B4 Relay for eric.davis@broadcom.com/20261014 with auth_id=1186
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

An unconnected transport over UET resolves a peer by both its network
address and its queue pair number. The write() create-AH command has no
room for additional attributes. Add rdma_ah_attr_ex to carry new
attributes, reach it through rdma_ah_init_attr, and add an ioctl method
that supports it.

rdma_create_user_ah() now takes the init attributes rather than the
address alone, so callers pass the wider set.

Signed-off-by: Eric Davis <eric.davis@broadcom.com>
---
 drivers/infiniband/core/user_mad.c         |  4 +-
 drivers/infiniband/core/uverbs.h           |  3 ++
 drivers/infiniband/core/uverbs_cmd.c       | 60 +++++++++++++++----------
 drivers/infiniband/core/uverbs_std_types.c | 70 +++++++++++++++++++++++++++++-
 drivers/infiniband/core/verbs.c            | 43 ++++++++++--------
 include/rdma/ib_verbs.h                    | 20 +++++++--
 include/uapi/rdma/ib_user_ioctl_cmds.h     |  7 +++
 include/uapi/rdma/ib_user_ioctl_verbs.h    |  9 ++++
 8 files changed, 169 insertions(+), 47 deletions(-)

diff --git a/drivers/infiniband/core/user_mad.c b/drivers/infiniband/core/user_mad.c
index c3ef9f85c7eb..05e2898f0a6a 100644
--- a/drivers/infiniband/core/user_mad.c
+++ b/drivers/infiniband/core/user_mad.c
@@ -512,6 +512,7 @@ static ssize_t ib_umad_write(struct file *filp, const char __user *buf,
 	struct ib_umad_packet *packet;
 	struct ib_mad_agent *agent;
 	struct rdma_ah_attr ah_attr;
+	struct rdma_ah_init_attr init_attr = {};
 	struct ib_ah *ah;
 	__be64 *tid;
 	int ret, hdr_len, copy_offset, rmpp_active;
@@ -569,7 +570,8 @@ static ssize_t ib_umad_write(struct file *filp, const char __user *buf,
 		rdma_ah_set_dgid_raw(&ah_attr, packet->mad.hdr.gid);
 	}
 
-	ah = rdma_create_user_ah(agent->qp->pd, &ah_attr, NULL);
+	init_attr.ah_attr = &ah_attr;
+	ah = rdma_create_user_ah(agent->qp->pd, &init_attr, NULL);
 	if (IS_ERR(ah)) {
 		ret = PTR_ERR(ah);
 		goto err_up;
diff --git a/drivers/infiniband/core/uverbs.h b/drivers/infiniband/core/uverbs.h
index 728e09b41992..6aaac1c309f0 100644
--- a/drivers/infiniband/core/uverbs.h
+++ b/drivers/infiniband/core/uverbs.h
@@ -236,6 +236,9 @@ int ib_uverbs_dealloc_xrcd(struct ib_uobject *uobject, struct ib_xrcd *xrcd,
 int uverbs_dealloc_mw(struct ib_mw *mw);
 void ib_uverbs_detach_umcast(struct ib_qp *qp,
 			     struct ib_uqp_object *uobj);
+int copy_ah_attr_from_uverbs_ah(struct ib_device *dev,
+				struct rdma_ah_attr *rdma_attr,
+				const struct ib_uverbs_ah_attr *uverb_attr);
 
 struct bundle_alloc_head {
 	struct_group_tagged(bundle_alloc_head_hdr, hdr,
diff --git a/drivers/infiniband/core/uverbs_cmd.c b/drivers/infiniband/core/uverbs_cmd.c
index e4fdfa0d9548..cca386b2c3f0 100644
--- a/drivers/infiniband/core/uverbs_cmd.c
+++ b/drivers/infiniband/core/uverbs_cmd.c
@@ -1746,6 +1746,37 @@ static int modify_qp_mask(enum ib_qp_type qp_type, int mask)
 	}
 }
 
+/* The ib_uverbs_ah_attr counterpart of copy_ah_attr_from_uverbs() below,
+ * which takes the modify QP layout. This one also rejects an invalid port.
+ */
+int copy_ah_attr_from_uverbs_ah(struct ib_device *dev,
+				struct rdma_ah_attr *rdma_attr,
+				const struct ib_uverbs_ah_attr *uverb_attr)
+{
+	if (!rdma_is_port_valid(dev, uverb_attr->port_num))
+		return -EINVAL;
+
+	rdma_attr->type = rdma_ah_find_type(dev, uverb_attr->port_num);
+	rdma_ah_set_make_grd(rdma_attr, false);
+	rdma_ah_set_dlid(rdma_attr, uverb_attr->dlid);
+	rdma_ah_set_sl(rdma_attr, uverb_attr->sl);
+	rdma_ah_set_path_bits(rdma_attr, uverb_attr->src_path_bits);
+	rdma_ah_set_static_rate(rdma_attr, uverb_attr->static_rate);
+	rdma_ah_set_port_num(rdma_attr, uverb_attr->port_num);
+
+	if (uverb_attr->is_global) {
+		rdma_ah_set_grh(rdma_attr, NULL, uverb_attr->grh.flow_label,
+				uverb_attr->grh.sgid_index,
+				uverb_attr->grh.hop_limit,
+				uverb_attr->grh.traffic_class);
+		rdma_ah_set_dgid_raw(rdma_attr, uverb_attr->grh.dgid);
+	} else {
+		rdma_ah_set_ah_flags(rdma_attr, 0);
+	}
+
+	return 0;
+}
+
 static void copy_ah_attr_from_uverbs(struct ib_device *dev,
 				     struct rdma_ah_attr *rdma_attr,
 				     struct ib_uverbs_qp_dest *uverb_attr)
@@ -2435,6 +2466,7 @@ static int ib_uverbs_create_ah(struct uverbs_attr_bundle *attrs)
 	struct ib_pd			*pd;
 	struct ib_ah			*ah;
 	struct rdma_ah_attr		attr = {};
+	struct rdma_ah_init_attr	init_attr = {};
 	int ret;
 	struct ib_device *ib_dev;
 
@@ -2446,36 +2478,18 @@ static int ib_uverbs_create_ah(struct uverbs_attr_bundle *attrs)
 	if (IS_ERR(uobj))
 		return PTR_ERR(uobj);
 
-	if (!rdma_is_port_valid(ib_dev, cmd.attr.port_num)) {
-		ret = -EINVAL;
-		goto err;
-	}
-
 	pd = uobj_get_obj_read(pd, UVERBS_OBJECT_PD, cmd.pd_handle, attrs);
 	if (IS_ERR(pd)) {
 		ret = PTR_ERR(pd);
 		goto err;
 	}
 
-	attr.type = rdma_ah_find_type(ib_dev, cmd.attr.port_num);
-	rdma_ah_set_make_grd(&attr, false);
-	rdma_ah_set_dlid(&attr, cmd.attr.dlid);
-	rdma_ah_set_sl(&attr, cmd.attr.sl);
-	rdma_ah_set_path_bits(&attr, cmd.attr.src_path_bits);
-	rdma_ah_set_static_rate(&attr, cmd.attr.static_rate);
-	rdma_ah_set_port_num(&attr, cmd.attr.port_num);
-
-	if (cmd.attr.is_global) {
-		rdma_ah_set_grh(&attr, NULL, cmd.attr.grh.flow_label,
-				cmd.attr.grh.sgid_index,
-				cmd.attr.grh.hop_limit,
-				cmd.attr.grh.traffic_class);
-		rdma_ah_set_dgid_raw(&attr, cmd.attr.grh.dgid);
-	} else {
-		rdma_ah_set_ah_flags(&attr, 0);
-	}
+	ret = copy_ah_attr_from_uverbs_ah(ib_dev, &attr, &cmd.attr);
+	if (ret)
+		goto err_put;
 
-	ah = rdma_create_user_ah(pd, &attr, &attrs->driver_udata);
+	init_attr.ah_attr = &attr;
+	ah = rdma_create_user_ah(pd, &init_attr, &attrs->driver_udata);
 	if (IS_ERR(ah)) {
 		ret = PTR_ERR(ah);
 		goto err_put;
diff --git a/drivers/infiniband/core/uverbs_std_types.c b/drivers/infiniband/core/uverbs_std_types.c
index e160786e1df1..27cc1d162293 100644
--- a/drivers/infiniband/core/uverbs_std_types.c
+++ b/drivers/infiniband/core/uverbs_std_types.c
@@ -184,6 +184,73 @@ DECLARE_UVERBS_NAMED_OBJECT(UVERBS_OBJECT_MW,
 			    UVERBS_TYPE_ALLOC_IDR(uverbs_free_mw),
 			    &UVERBS_METHOD(UVERBS_METHOD_MW_DESTROY));
 
+/* Creating an address handle is still a write() command whose request
+ * struct cannot grow. A transport (reliable unconnected) that resolves a
+ * peer using both transport and network addresses requires additional
+ * fields in the address handle. Here the address handle create command is
+ * made available as an ioctl method, where additional attributes can be
+ * carried.
+ */
+static int UVERBS_HANDLER(UVERBS_METHOD_AH_EX_CREATE)(
+	struct uverbs_attr_bundle *attrs)
+{
+	struct ib_uobject *uobj = uverbs_attr_get_uobject(
+		attrs, UVERBS_ATTR_CREATE_AH_EX_HANDLE);
+	struct ib_pd *pd =
+		uverbs_attr_get_obj(attrs, UVERBS_ATTR_CREATE_AH_EX_PD_HANDLE);
+	struct ib_device *ib_dev = attrs->context->device;
+	struct ib_uverbs_ah_attr_ex uah;
+	struct rdma_ah_init_attr init_attr = {};
+	struct rdma_ah_attr_ex attr = {};
+	struct ib_ah *ah;
+	int ret;
+
+	/* Only a reliable unconnected device has a use for the extended
+	 * attributes.
+	 */
+	if (!(ib_dev->attrs.device_cap_flags & IB_DEVICE_RU))
+		return -EOPNOTSUPP;
+
+	ret = uverbs_copy_from_or_zero(&uah, attrs,
+				       UVERBS_ATTR_CREATE_AH_EX_AH_ATTR_EX);
+	if (ret)
+		return ret;
+
+	ret = copy_ah_attr_from_uverbs_ah(ib_dev, &attr.ah_attr, &uah.ah_attr);
+	if (ret)
+		return ret;
+
+	attr.remote_qpn = uah.remote_qpn;
+
+	init_attr.ah_attr = &attr.ah_attr;
+	init_attr.ah_attr_ex = &attr;
+
+	ah = rdma_create_user_ah(pd, &init_attr, &attrs->driver_udata);
+	if (IS_ERR(ah))
+		return PTR_ERR(ah);
+
+	ah->uobject = uobj;
+	uobj->object = ah;
+
+	return 0;
+}
+
+DECLARE_UVERBS_NAMED_METHOD(
+	UVERBS_METHOD_AH_EX_CREATE,
+	UVERBS_ATTR_IDR(UVERBS_ATTR_CREATE_AH_EX_HANDLE,
+			UVERBS_OBJECT_AH,
+			UVERBS_ACCESS_NEW,
+			UA_MANDATORY),
+	UVERBS_ATTR_IDR(UVERBS_ATTR_CREATE_AH_EX_PD_HANDLE,
+			UVERBS_OBJECT_PD,
+			UVERBS_ACCESS_READ,
+			UA_MANDATORY),
+	UVERBS_ATTR_PTR_IN(UVERBS_ATTR_CREATE_AH_EX_AH_ATTR_EX,
+			   UVERBS_ATTR_STRUCT(struct ib_uverbs_ah_attr_ex,
+					      remote_qpn),
+			   UA_MANDATORY),
+	UVERBS_ATTR_UHW());
+
 DECLARE_UVERBS_NAMED_METHOD_DESTROY(
 	UVERBS_METHOD_AH_DESTROY,
 	UVERBS_ATTR_IDR(UVERBS_ATTR_DESTROY_AH_HANDLE,
@@ -193,7 +260,8 @@ DECLARE_UVERBS_NAMED_METHOD_DESTROY(
 
 DECLARE_UVERBS_NAMED_OBJECT(UVERBS_OBJECT_AH,
 			    UVERBS_TYPE_ALLOC_IDR(uverbs_free_ah),
-			    &UVERBS_METHOD(UVERBS_METHOD_AH_DESTROY));
+			    &UVERBS_METHOD(UVERBS_METHOD_AH_DESTROY),
+			    &UVERBS_METHOD(UVERBS_METHOD_AH_EX_CREATE));
 
 DECLARE_UVERBS_NAMED_METHOD_DESTROY(
 	UVERBS_METHOD_FLOW_DESTROY,
diff --git a/drivers/infiniband/core/verbs.c b/drivers/infiniband/core/verbs.c
index 1299125752d8..2d04ffd13ad3 100644
--- a/drivers/infiniband/core/verbs.c
+++ b/drivers/infiniband/core/verbs.c
@@ -561,24 +561,23 @@ rdma_update_sgid_attr(struct rdma_ah_attr *ah_attr,
 }
 
 static struct ib_ah *_rdma_create_ah(struct ib_pd *pd,
-				     struct rdma_ah_attr *ah_attr,
-				     u32 flags,
-				     struct ib_udata *udata,
-				     struct net_device *xmit_slave)
+				     struct rdma_ah_init_attr *init_attr,
+				     struct ib_udata *udata)
 {
-	struct rdma_ah_init_attr init_attr = {};
+	struct rdma_ah_attr *ah_attr = init_attr->ah_attr;
 	struct ib_device *device = pd->device;
 	struct ib_ah *ah;
 	int ret;
 
-	might_sleep_if(flags & RDMA_CREATE_AH_SLEEPABLE);
+	might_sleep_if(init_attr->flags & RDMA_CREATE_AH_SLEEPABLE);
 
 	if (!udata && !device->ops.create_ah)
 		return ERR_PTR(-EOPNOTSUPP);
 
 	ah = rdma_zalloc_drv_obj_gfp(
 		device, ib_ah,
-		(flags & RDMA_CREATE_AH_SLEEPABLE) ? GFP_KERNEL : GFP_ATOMIC);
+		(init_attr->flags & RDMA_CREATE_AH_SLEEPABLE) ? GFP_KERNEL :
+								GFP_ATOMIC);
 	if (!ah)
 		return ERR_PTR(-ENOMEM);
 
@@ -586,14 +585,12 @@ static struct ib_ah *_rdma_create_ah(struct ib_pd *pd,
 	ah->pd = pd;
 	ah->type = ah_attr->type;
 	ah->sgid_attr = rdma_update_sgid_attr(ah_attr, NULL);
-	init_attr.ah_attr = ah_attr;
-	init_attr.flags = flags;
-	init_attr.xmit_slave = xmit_slave;
 
 	if (udata)
-		ret = device->ops.create_user_ah(ah, &init_attr, udata);
+		ret = device->ops.create_user_ah(ah, init_attr, udata);
 	else
-		ret = device->ops.create_ah(ah, &init_attr, NULL);
+		ret = device->ops.create_ah(ah, init_attr, NULL);
+
 	if (ret) {
 		if (ah->sgid_attr)
 			rdma_put_gid_attr(ah->sgid_attr);
@@ -619,6 +616,7 @@ static struct ib_ah *_rdma_create_ah(struct ib_pd *pd,
 struct ib_ah *rdma_create_ah(struct ib_pd *pd, struct rdma_ah_attr *ah_attr,
 			     u32 flags)
 {
+	struct rdma_ah_init_attr init_attr = {};
 	const struct ib_gid_attr *old_sgid_attr;
 	struct net_device *slave;
 	struct ib_ah *ah;
@@ -634,7 +632,12 @@ struct ib_ah *rdma_create_ah(struct ib_pd *pd, struct rdma_ah_attr *ah_attr,
 		rdma_unfill_sgid_attr(ah_attr, old_sgid_attr);
 		return ERR_CAST(slave);
 	}
-	ah = _rdma_create_ah(pd, ah_attr, flags, NULL, slave);
+
+	init_attr.ah_attr = ah_attr;
+	init_attr.flags = flags;
+	init_attr.xmit_slave = slave;
+
+	ah = _rdma_create_ah(pd, &init_attr, NULL);
 	rdma_lag_put_ah_roce_slave(slave);
 	rdma_unfill_sgid_attr(ah_attr, old_sgid_attr);
 	return ah;
@@ -646,18 +649,21 @@ EXPORT_SYMBOL(rdma_create_ah);
  * given address vector.
  * It resolves destination mac address for ah attribute of RoCE type.
  * @pd: The protection domain associated with the address handle.
- * @ah_attr: The attributes of the address vector.
+ * @init_attr: The address vector, and for an extended handle the
+ *             attributes beyond it.
  * @udata: pointer to user's input output buffer information need by
  *         provider driver.
  *
- * It returns 0 on success and returns appropriate error code on error.
  * The address handle is used to reference a local or global destination
  * in all UD QP post sends.
+ *
+ * Return: the address handle, or an ERR_PTR on error.
  */
 struct ib_ah *rdma_create_user_ah(struct ib_pd *pd,
-				  struct rdma_ah_attr *ah_attr,
+				  struct rdma_ah_init_attr *init_attr,
 				  struct ib_udata *udata)
 {
+	struct rdma_ah_attr *ah_attr = init_attr->ah_attr;
 	const struct ib_gid_attr *old_sgid_attr;
 	struct ib_ah *ah;
 	int err;
@@ -674,8 +680,9 @@ struct ib_ah *rdma_create_user_ah(struct ib_pd *pd,
 		}
 	}
 
-	ah = _rdma_create_ah(pd, ah_attr, RDMA_CREATE_AH_SLEEPABLE,
-			     udata, NULL);
+	init_attr->flags |= RDMA_CREATE_AH_SLEEPABLE;
+
+	ah = _rdma_create_ah(pd, init_attr, udata);
 
 out:
 	rdma_unfill_sgid_attr(ah_attr, old_sgid_attr);
diff --git a/include/rdma/ib_verbs.h b/include/rdma/ib_verbs.h
index 8d74ed4fc581..68f7a271cf7a 100644
--- a/include/rdma/ib_verbs.h
+++ b/include/rdma/ib_verbs.h
@@ -974,10 +974,14 @@ struct ib_mr_status {
  */
 __attribute_const__ enum ib_rate mult_to_ib_rate(int mult);
 
+struct rdma_ah_attr_ex;
+
 struct rdma_ah_init_attr {
 	struct rdma_ah_attr *ah_attr;
 	u32 flags;
 	struct net_device *xmit_slave;
+	/* set to name a peer by both transport+network addresses */
+	struct rdma_ah_attr_ex *ah_attr_ex;
 };
 
 enum rdma_ah_attr_type {
@@ -1016,6 +1020,11 @@ struct rdma_ah_attr {
 	};
 };
 
+struct rdma_ah_attr_ex {
+	struct rdma_ah_attr	ah_attr;
+	u32			remote_qpn;
+};
+
 enum ib_wc_status {
 	IB_WC_SUCCESS,
 	IB_WC_LOC_LEN_ERR,
@@ -3893,16 +3902,18 @@ struct ib_ah *rdma_create_ah(struct ib_pd *pd, struct rdma_ah_attr *ah_attr,
  * rdma_create_user_ah - Creates an address handle for the given address vector.
  * It resolves destination mac address for ah attribute of RoCE type.
  * @pd: The protection domain associated with the address handle.
- * @ah_attr: The attributes of the address vector.
+ * @init_attr: The address vector, and for an extended handle the
+ *             attributes beyond it.
  * @udata: pointer to user's input output buffer information need by
  *         provider driver.
  *
- * It returns 0 on success and returns appropriate error code on error.
  * The address handle is used to reference a local or global destination
  * in all UD QP post sends.
+ *
+ * Return: the address handle, or an ERR_PTR on error.
  */
 struct ib_ah *rdma_create_user_ah(struct ib_pd *pd,
-				  struct rdma_ah_attr *ah_attr,
+				  struct rdma_ah_init_attr *init_attr,
 				  struct ib_udata *udata);
 /**
  * ib_get_gids_from_rdma_hdr - Get sgid and dgid from GRH or IPv4 header
@@ -4981,7 +4992,8 @@ static inline struct ib_global_route
 	return &attr->grh;
 }
 
-static inline void rdma_ah_set_dgid_raw(struct rdma_ah_attr *attr, void *dgid)
+static inline void rdma_ah_set_dgid_raw(struct rdma_ah_attr *attr,
+					const void *dgid)
 {
 	struct ib_global_route *grh = rdma_ah_retrieve_grh(attr);
 
diff --git a/include/uapi/rdma/ib_user_ioctl_cmds.h b/include/uapi/rdma/ib_user_ioctl_cmds.h
index 816b3107464f..40fcd4bd1b5e 100644
--- a/include/uapi/rdma/ib_user_ioctl_cmds.h
+++ b/include/uapi/rdma/ib_user_ioctl_cmds.h
@@ -410,6 +410,13 @@ enum uverbs_attrs_xrcd_destroy_ids {
 
 enum uverbs_methods_ah {
 	UVERBS_METHOD_AH_DESTROY,
+	UVERBS_METHOD_AH_EX_CREATE,
+};
+
+enum uverbs_attrs_create_ah_ex_cmd_attr_ids {
+	UVERBS_ATTR_CREATE_AH_EX_HANDLE,
+	UVERBS_ATTR_CREATE_AH_EX_PD_HANDLE,
+	UVERBS_ATTR_CREATE_AH_EX_AH_ATTR_EX,
 };
 
 enum uverbs_attrs_ah_destroy_ids {
diff --git a/include/uapi/rdma/ib_user_ioctl_verbs.h b/include/uapi/rdma/ib_user_ioctl_verbs.h
index b6d46115f799..210f3f945bd7 100644
--- a/include/uapi/rdma/ib_user_ioctl_verbs.h
+++ b/include/uapi/rdma/ib_user_ioctl_verbs.h
@@ -318,6 +318,15 @@ struct ib_uverbs_buffer_desc {
 #define IB_UVERBS_QPN_UET_RESERVED_MASK		0x7f000000
 #define IB_UVERBS_QPN_UET_ABSOLUTE_ADDR_BIT	0x80000000
 
+/* An address handle that names a peer using both transport+network addresses.
+ * Used for reliable unconnected QPs in both work request address handles and
+ * a Job address table.
+ */
+struct ib_uverbs_ah_attr_ex {
+	struct ib_uverbs_ah_attr ah_attr;
+	__u32 remote_qpn;
+};
+
 enum ib_uverbs_comp_cntr_entry {
 	IB_UVERBS_COMP_CNTR_ENTRY_COMP,
 	IB_UVERBS_COMP_CNTR_ENTRY_ERR,

-- 
2.56.0

