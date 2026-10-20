From: Eric Davis <eric.davis@broadcom.com>
Date: Mon, 19 Oct 2026 20:03:39 -0700
Subject: [PATCH rdma-next v2 12/13] RDMA/core: 64-bit memory keys
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-uet-ib-core-v2-12-8bd654f25370@broadcom.com>
References: <20261019-uet-ib-core-v2-0-8bd654f25370@broadcom.com>
In-Reply-To: <20261019-uet-ib-core-v2-0-8bd654f25370@broadcom.com>
To: Jason Gunthorpe <jgg@ziepe.ca>, Leon Romanovsky <leon@kernel.org>
Cc: linux-rdma@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Eric Davis <eric.davis@broadcom.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792465414; l=5395;
 i=eric.davis@broadcom.com; s=20261014; h=from:subject:message-id;
 bh=l/SvQB738ZzzsW40ZbLfYgaF+gfR5SifojhtKPNCnZU=;
 b=jIv0dTVbhOXUJgOv9VGEEqzz686xEM2v0kc3cz8L/yjqTG1XEX6dbnFmRAB+0urRMNj9tm8y+
 Q5OjMu7SqISCSX6FChvLeSCiWimpsQamEhhC7v31Cg09zRp4GwvZ+yb
X-Developer-Key: i=eric.davis@broadcom.com; a=ed25519;
 pk=uy3oCTOYBipIPjryXGMynBmtPvbO6qN2FOrduzpiI4A=
X-Endpoint-Received: by B4 Relay for eric.davis@broadcom.com/20261014 with auth_id=1186
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A device whose keys are wider than 32 bits has no way to name a region
through lkey and rkey. Carry the wide pair on the region and return it
from registration when userspace asks for it.

The attributes are optional in both directions, so a kernel that does not
know them ignores the request, and a region without a wide key answers
zero.

Signed-off-by: Eric Davis <eric.davis@broadcom.com>
---
 drivers/infiniband/core/uverbs_std_types_mr.c | 39 ++++++++++++++++++++++++++-
 include/rdma/ib_verbs.h                       | 12 +++++++--
 include/uapi/rdma/ib_user_ioctl_cmds.h        |  4 +++
 3 files changed, 52 insertions(+), 3 deletions(-)

diff --git a/drivers/infiniband/core/uverbs_std_types_mr.c b/drivers/infiniband/core/uverbs_std_types_mr.c
index e595c53fa34c..1ff45556e0b2 100644
--- a/drivers/infiniband/core/uverbs_std_types_mr.c
+++ b/drivers/infiniband/core/uverbs_std_types_mr.c
@@ -185,6 +185,16 @@ static int UVERBS_HANDLER(UVERBS_METHOD_QUERY_MR)(
 
 	ret = uverbs_copy_to(attrs, UVERBS_ATTR_QUERY_MR_RESP_IOVA,
 			     &mr->iova, sizeof(mr->iova));
+	if (IS_UVERBS_COPY_ERR(ret))
+		return ret;
+
+	ret = uverbs_copy_to(attrs, UVERBS_ATTR_QUERY_MR_RESP_LKEY64,
+			     &mr->lkey64, sizeof(mr->lkey64));
+	if (IS_UVERBS_COPY_ERR(ret))
+		return ret;
+
+	ret = uverbs_copy_to(attrs, UVERBS_ATTR_QUERY_MR_RESP_RKEY64,
+			     &mr->rkey64, sizeof(mr->rkey64));
 
 	return IS_UVERBS_COPY_ERR(ret) ? ret : 0;
 }
@@ -364,6 +374,10 @@ static int reg_mr_ex_attr(struct uverbs_attr_bundle *attrs, struct ib_pd *pd,
 		if (ret)
 			return ret;
 
+		/* zero names no wide key, so it can't be one */
+		if (!ex->req_rkey64)
+			return -EINVAL;
+
 		if (ex->req_rkey64 > U32_MAX && !(caps & IB_DEVICE_KEY64))
 			return -EOPNOTSUPP;
 	} else if (uverbs_attr_is_valid(attrs,
@@ -547,7 +561,18 @@ static int UVERBS_HANDLER(UVERBS_METHOD_REG_MR)(
 
 	ret = uverbs_copy_to(attrs, UVERBS_ATTR_REG_MR_RESP_RKEY,
 			     &mr->rkey, sizeof(mr->rkey));
-	return ret;
+	if (ret)
+		return ret;
+
+	ret = uverbs_copy_to(attrs, UVERBS_ATTR_REG_MR_RESP_LKEY64,
+			     &mr->lkey64, sizeof(mr->lkey64));
+	if (IS_UVERBS_COPY_ERR(ret))
+		return ret;
+
+	ret = uverbs_copy_to(attrs, UVERBS_ATTR_REG_MR_RESP_RKEY64,
+			     &mr->rkey64, sizeof(mr->rkey64));
+
+	return IS_UVERBS_COPY_ERR(ret) ? ret : 0;
 }
 
 DECLARE_UVERBS_NAMED_METHOD(
@@ -583,6 +608,12 @@ DECLARE_UVERBS_NAMED_METHOD(
 			    UVERBS_ATTR_TYPE(u64),
 			    UA_MANDATORY),
 	UVERBS_ATTR_PTR_OUT(UVERBS_ATTR_QUERY_MR_RESP_IOVA,
+			    UVERBS_ATTR_TYPE(u64),
+			    UA_OPTIONAL),
+	UVERBS_ATTR_PTR_OUT(UVERBS_ATTR_QUERY_MR_RESP_LKEY64,
+			    UVERBS_ATTR_TYPE(u64),
+			    UA_OPTIONAL),
+	UVERBS_ATTR_PTR_OUT(UVERBS_ATTR_QUERY_MR_RESP_RKEY64,
 			    UVERBS_ATTR_TYPE(u64),
 			    UA_OPTIONAL));
 
@@ -700,6 +731,12 @@ DECLARE_UVERBS_NAMED_METHOD(
 	UVERBS_ATTR_PTR_IN(UVERBS_ATTR_REG_MR_REQ_RKEY64,
 			   UVERBS_ATTR_TYPE(u64),
 			   UA_OPTIONAL),
+	UVERBS_ATTR_PTR_OUT(UVERBS_ATTR_REG_MR_RESP_LKEY64,
+			    UVERBS_ATTR_TYPE(u64),
+			    UA_OPTIONAL),
+	UVERBS_ATTR_PTR_OUT(UVERBS_ATTR_REG_MR_RESP_RKEY64,
+			    UVERBS_ATTR_TYPE(u64),
+			    UA_OPTIONAL),
 	UVERBS_ATTR_UHW());
 
 DECLARE_UVERBS_NAMED_METHOD_DESTROY(
diff --git a/include/rdma/ib_verbs.h b/include/rdma/ib_verbs.h
index b86ac63fab36..725b630a3b90 100644
--- a/include/rdma/ib_verbs.h
+++ b/include/rdma/ib_verbs.h
@@ -2084,6 +2084,9 @@ struct ib_mr {
 		struct list_head	qp_entry;	/* FR */
 	};
 
+	/* 64b keys, set by a driver reporting IB_DEVICE_KEY64, else zero */
+	u64		   lkey64;
+	u64		   rkey64;
 	/* the job this region is restricted to, NULL if it is unrestricted */
 	struct ib_jkey	  *jkey;
 	/* the region this one was derived from, NULL if registered fresh */
@@ -4851,8 +4854,8 @@ static inline u32 ib_inc_rkey(u32 rkey)
 
 /**
  * ib_mr_init_core_refs - clears what core reads back when an MR is
- *   deregistered.
- * @mr: struct ib_mr pointer to initialize.
+ *   deregistered, and the wide keys of an MR on a device without them.
+ * @mr: struct ib_mr pointer to initialize, with its device set.
  *
  * A driver's MR need not be zeroed, so every path that makes an MR calls this.
  */
@@ -4861,6 +4864,11 @@ static inline void ib_mr_init_core_refs(struct ib_mr *mr)
 	mr->jkey = NULL;
 	mr->parent = NULL;
 	atomic_set(&mr->usecnt, 0);
+
+	if (!(mr->device->attrs.device_cap_flags & IB_DEVICE_KEY64)) {
+		mr->lkey64 = 0;
+		mr->rkey64 = 0;
+	}
 }
 
 /**
diff --git a/include/uapi/rdma/ib_user_ioctl_cmds.h b/include/uapi/rdma/ib_user_ioctl_cmds.h
index fd8372c0c550..bc2797fc37fe 100644
--- a/include/uapi/rdma/ib_user_ioctl_cmds.h
+++ b/include/uapi/rdma/ib_user_ioctl_cmds.h
@@ -343,6 +343,8 @@ enum uverbs_attrs_query_mr_cmd_attr_ids {
 	UVERBS_ATTR_QUERY_MR_RESP_RKEY,
 	UVERBS_ATTR_QUERY_MR_RESP_LENGTH,
 	UVERBS_ATTR_QUERY_MR_RESP_IOVA,
+	UVERBS_ATTR_QUERY_MR_RESP_LKEY64,
+	UVERBS_ATTR_QUERY_MR_RESP_RKEY64,
 };
 
 enum uverbs_attrs_reg_dmabuf_mr_cmd_attr_ids {
@@ -374,6 +376,8 @@ enum uverbs_attrs_reg_mr_cmd_attr_ids {
 	UVERBS_ATTR_REG_MR_PARENT_MR_HANDLE,
 	UVERBS_ATTR_REG_MR_DERIVE_CNT,
 	UVERBS_ATTR_REG_MR_REQ_RKEY64,
+	UVERBS_ATTR_REG_MR_RESP_LKEY64,
+	UVERBS_ATTR_REG_MR_RESP_RKEY64,
 };
 
 enum uverbs_attrs_create_counters_cmd_attr_ids {

-- 
2.56.0

