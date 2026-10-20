From: Eric Davis <eric.davis@broadcom.com>
Date: Mon, 19 Oct 2026 20:03:35 -0700
Subject: [PATCH rdma-next v2 08/13] RDMA/uverbs: factor out the queue pair
 attribute copy
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-uet-ib-core-v2-8-8bd654f25370@broadcom.com>
References: <20261019-uet-ib-core-v2-0-8bd654f25370@broadcom.com>
In-Reply-To: <20261019-uet-ib-core-v2-0-8bd654f25370@broadcom.com>
To: Jason Gunthorpe <jgg@ziepe.ca>, Leon Romanovsky <leon@kernel.org>
Cc: linux-rdma@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Eric Davis <eric.davis@broadcom.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792465414; l=9598;
 i=eric.davis@broadcom.com; s=20261014; h=from:subject:message-id;
 bh=xdXkQszZ/RTpRqAzPH4bgxWH9OY3mxRumMhAV6qaiqs=;
 b=nH3ygd7BHzWRHHp9ZemgtsV/3aM6uLXbyhUR2WrTvPBDSqXGh6ShAMjQQM9/Lp4ztEwz5iasS
 KtHs/ZHKH9LAaDbwmK0lo2MyDJSJtdTUsT2WLBaD93vnXfMlG2yo+xn
X-Developer-Key: i=eric.davis@broadcom.com; a=ed25519;
 pk=uy3oCTOYBipIPjryXGMynBmtPvbO6qN2FOrduzpiI4A=
X-Endpoint-Received: by B4 Relay for eric.davis@broadcom.com/20261014 with auth_id=1186
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

modify_qp() validates a set of attributes that came from userspace and
copies the ones its mask names into their kernel form. Queue pair
creation needs the same work for a transport that is ready to send as
soon as the pair exists, so move it into ib_uverbs_copy_qp_attr().

No functional change.

Signed-off-by: Eric Davis <eric.davis@broadcom.com>
---
 drivers/infiniband/core/uverbs.h     |   6 ++
 drivers/infiniband/core/uverbs_cmd.c | 191 ++++++++++++++++++-----------------
 2 files changed, 105 insertions(+), 92 deletions(-)

diff --git a/drivers/infiniband/core/uverbs.h b/drivers/infiniband/core/uverbs.h
index 6bc7cc6621cb..8c461a172217 100644
--- a/drivers/infiniband/core/uverbs.h
+++ b/drivers/infiniband/core/uverbs.h
@@ -319,6 +319,12 @@ struct ib_uverbs_flow_spec {
 	};
 };
 
+int ib_uverbs_copy_qp_attr(struct uverbs_attr_bundle *attrs,
+			   struct ib_device *device,
+			   struct ib_qp_attr *attr,
+			   const struct ib_uverbs_ex_modify_qp *src,
+			   u32 mask);
+
 int ib_uverbs_kern_spec_to_ib_spec_filter(enum ib_flow_spec_type type,
 					  const void *kern_spec_mask,
 					  const void *kern_spec_val,
diff --git a/drivers/infiniband/core/uverbs_cmd.c b/drivers/infiniband/core/uverbs_cmd.c
index cca386b2c3f0..a35b743ab9bd 100644
--- a/drivers/infiniband/core/uverbs_cmd.c
+++ b/drivers/infiniband/core/uverbs_cmd.c
@@ -1779,7 +1779,7 @@ int copy_ah_attr_from_uverbs_ah(struct ib_device *dev,
 
 static void copy_ah_attr_from_uverbs(struct ib_device *dev,
 				     struct rdma_ah_attr *rdma_attr,
-				     struct ib_uverbs_qp_dest *uverb_attr)
+				     const struct ib_uverbs_qp_dest *uverb_attr)
 {
 	rdma_attr->type = rdma_ah_find_type(dev, uverb_attr->port_num);
 	if (uverb_attr->is_global) {
@@ -1800,6 +1800,101 @@ static void copy_ah_attr_from_uverbs(struct ib_device *dev,
 	rdma_ah_set_make_grd(rdma_attr, false);
 }
 
+/* Validate a set of QP attributes that came from userspace and copy the ones
+ * the mask names into their kernel form. Shared by the modify command, and by
+ * queue pair creation which takes the same set of attributes for a transport
+ * that is ready to send as soon as the QP is created.
+ */
+int ib_uverbs_copy_qp_attr(struct uverbs_attr_bundle *attrs,
+			   struct ib_device *device,
+			   struct ib_qp_attr *attr,
+			   const struct ib_uverbs_ex_modify_qp *src,
+			   u32 mask)
+{
+	/* Last bit is reserved for extending the attr_mask by using
+	 * another field.
+	 */
+	if (mask & ~(IB_QP_ATTR_STANDARD_BITS | IB_QP_RATE_LIMIT))
+		return -EOPNOTSUPP;
+
+	if ((mask & IB_QP_PORT) &&
+	    !rdma_is_port_valid(device, src->base.port_num))
+		return -EINVAL;
+
+	if ((mask & IB_QP_AV) &&
+	    !rdma_is_port_valid(device, src->base.dest.port_num))
+		return -EINVAL;
+
+	if ((mask & IB_QP_ALT_PATH) &&
+	    (!rdma_is_port_valid(device, src->base.alt_port_num) ||
+	     !rdma_is_port_valid(device, src->base.alt_dest.port_num) ||
+	     src->base.alt_port_num != src->base.alt_dest.port_num))
+		return -EINVAL;
+
+	if (((mask & IB_QP_CUR_STATE) && src->base.cur_qp_state > IB_QPS_ERR) ||
+	    ((mask & IB_QP_STATE) && src->base.qp_state > IB_QPS_ERR))
+		return -EINVAL;
+
+	if (mask & IB_QP_STATE)
+		attr->qp_state = src->base.qp_state;
+	if (mask & IB_QP_CUR_STATE)
+		attr->cur_qp_state = src->base.cur_qp_state;
+	if (mask & IB_QP_PATH_MTU)
+		attr->path_mtu = src->base.path_mtu;
+	if (mask & IB_QP_PATH_MIG_STATE)
+		attr->path_mig_state = src->base.path_mig_state;
+	if (mask & IB_QP_QKEY) {
+		if (src->base.qkey & IB_QP_SET_QKEY &&
+		    !(rdma_nl_get_privileged_qkey() ||
+		      rdma_uattrs_has_raw_cap(attrs)))
+			return -EPERM;
+		attr->qkey = src->base.qkey;
+	}
+	if (mask & IB_QP_RQ_PSN)
+		attr->rq_psn = src->base.rq_psn;
+	if (mask & IB_QP_SQ_PSN)
+		attr->sq_psn = src->base.sq_psn;
+	if (mask & IB_QP_DEST_QPN)
+		attr->dest_qp_num = src->base.dest_qp_num;
+	if (mask & IB_QP_ACCESS_FLAGS)
+		attr->qp_access_flags = src->base.qp_access_flags;
+	if (mask & IB_QP_PKEY_INDEX)
+		attr->pkey_index = src->base.pkey_index;
+	if (mask & IB_QP_EN_SQD_ASYNC_NOTIFY)
+		attr->en_sqd_async_notify = src->base.en_sqd_async_notify;
+	if (mask & IB_QP_MAX_QP_RD_ATOMIC)
+		attr->max_rd_atomic = src->base.max_rd_atomic;
+	if (mask & IB_QP_MAX_DEST_RD_ATOMIC)
+		attr->max_dest_rd_atomic = src->base.max_dest_rd_atomic;
+	if (mask & IB_QP_MIN_RNR_TIMER)
+		attr->min_rnr_timer = src->base.min_rnr_timer;
+	if (mask & IB_QP_PORT)
+		attr->port_num = src->base.port_num;
+	if (mask & IB_QP_TIMEOUT)
+		attr->timeout = src->base.timeout;
+	if (mask & IB_QP_RETRY_CNT)
+		attr->retry_cnt = src->base.retry_cnt;
+	if (mask & IB_QP_RNR_RETRY)
+		attr->rnr_retry = src->base.rnr_retry;
+	if (mask & IB_QP_ALT_PATH) {
+		attr->alt_port_num = src->base.alt_port_num;
+		attr->alt_timeout = src->base.alt_timeout;
+		attr->alt_pkey_index = src->base.alt_pkey_index;
+	}
+	if (mask & IB_QP_RATE_LIMIT)
+		attr->rate_limit = src->rate_limit;
+
+	if (mask & IB_QP_AV)
+		copy_ah_attr_from_uverbs(device, &attr->ah_attr,
+					 &src->base.dest);
+
+	if (mask & IB_QP_ALT_PATH)
+		copy_ah_attr_from_uverbs(device, &attr->alt_ah_attr,
+					 &src->base.alt_dest);
+
+	return 0;
+}
+
 static int modify_qp(struct uverbs_attr_bundle *attrs,
 		     struct ib_uverbs_ex_modify_qp *cmd)
 {
@@ -1818,18 +1913,7 @@ static int modify_qp(struct uverbs_attr_bundle *attrs,
 		goto out;
 	}
 
-	if ((cmd->base.attr_mask & IB_QP_PORT) &&
-	    !rdma_is_port_valid(qp->device, cmd->base.port_num)) {
-		ret = -EINVAL;
-		goto release_qp;
-	}
-
 	if ((cmd->base.attr_mask & IB_QP_AV)) {
-		if (!rdma_is_port_valid(qp->device, cmd->base.dest.port_num)) {
-			ret = -EINVAL;
-			goto release_qp;
-		}
-
 		if (cmd->base.attr_mask & IB_QP_STATE &&
 		    cmd->base.qp_state == IB_QPS_RTR) {
 		/* We are in INIT->RTR TRANSITION (if we are not,
@@ -1878,80 +1962,10 @@ static int modify_qp(struct uverbs_attr_bundle *attrs,
 		}
 	}
 
-	if ((cmd->base.attr_mask & IB_QP_ALT_PATH) &&
-	    (!rdma_is_port_valid(qp->device, cmd->base.alt_port_num) ||
-	    !rdma_is_port_valid(qp->device, cmd->base.alt_dest.port_num) ||
-	    cmd->base.alt_port_num != cmd->base.alt_dest.port_num)) {
-		ret = -EINVAL;
-		goto release_qp;
-	}
-
-	if ((cmd->base.attr_mask & IB_QP_CUR_STATE &&
-	    cmd->base.cur_qp_state > IB_QPS_ERR) ||
-	    (cmd->base.attr_mask & IB_QP_STATE &&
-	    cmd->base.qp_state > IB_QPS_ERR)) {
-		ret = -EINVAL;
+	ret = ib_uverbs_copy_qp_attr(attrs, qp->device, attr, cmd,
+				     cmd->base.attr_mask);
+	if (ret)
 		goto release_qp;
-	}
-
-	if (cmd->base.attr_mask & IB_QP_STATE)
-		attr->qp_state = cmd->base.qp_state;
-	if (cmd->base.attr_mask & IB_QP_CUR_STATE)
-		attr->cur_qp_state = cmd->base.cur_qp_state;
-	if (cmd->base.attr_mask & IB_QP_PATH_MTU)
-		attr->path_mtu = cmd->base.path_mtu;
-	if (cmd->base.attr_mask & IB_QP_PATH_MIG_STATE)
-		attr->path_mig_state = cmd->base.path_mig_state;
-	if (cmd->base.attr_mask & IB_QP_QKEY) {
-		if (cmd->base.qkey & IB_QP_SET_QKEY &&
-		    !(rdma_nl_get_privileged_qkey() ||
-		      rdma_uattrs_has_raw_cap(attrs))) {
-			ret = -EPERM;
-			goto release_qp;
-		}
-		attr->qkey = cmd->base.qkey;
-	}
-	if (cmd->base.attr_mask & IB_QP_RQ_PSN)
-		attr->rq_psn = cmd->base.rq_psn;
-	if (cmd->base.attr_mask & IB_QP_SQ_PSN)
-		attr->sq_psn = cmd->base.sq_psn;
-	if (cmd->base.attr_mask & IB_QP_DEST_QPN)
-		attr->dest_qp_num = cmd->base.dest_qp_num;
-	if (cmd->base.attr_mask & IB_QP_ACCESS_FLAGS)
-		attr->qp_access_flags = cmd->base.qp_access_flags;
-	if (cmd->base.attr_mask & IB_QP_PKEY_INDEX)
-		attr->pkey_index = cmd->base.pkey_index;
-	if (cmd->base.attr_mask & IB_QP_EN_SQD_ASYNC_NOTIFY)
-		attr->en_sqd_async_notify = cmd->base.en_sqd_async_notify;
-	if (cmd->base.attr_mask & IB_QP_MAX_QP_RD_ATOMIC)
-		attr->max_rd_atomic = cmd->base.max_rd_atomic;
-	if (cmd->base.attr_mask & IB_QP_MAX_DEST_RD_ATOMIC)
-		attr->max_dest_rd_atomic = cmd->base.max_dest_rd_atomic;
-	if (cmd->base.attr_mask & IB_QP_MIN_RNR_TIMER)
-		attr->min_rnr_timer = cmd->base.min_rnr_timer;
-	if (cmd->base.attr_mask & IB_QP_PORT)
-		attr->port_num = cmd->base.port_num;
-	if (cmd->base.attr_mask & IB_QP_TIMEOUT)
-		attr->timeout = cmd->base.timeout;
-	if (cmd->base.attr_mask & IB_QP_RETRY_CNT)
-		attr->retry_cnt = cmd->base.retry_cnt;
-	if (cmd->base.attr_mask & IB_QP_RNR_RETRY)
-		attr->rnr_retry = cmd->base.rnr_retry;
-	if (cmd->base.attr_mask & IB_QP_ALT_PATH) {
-		attr->alt_port_num = cmd->base.alt_port_num;
-		attr->alt_timeout = cmd->base.alt_timeout;
-		attr->alt_pkey_index = cmd->base.alt_pkey_index;
-	}
-	if (cmd->base.attr_mask & IB_QP_RATE_LIMIT)
-		attr->rate_limit = cmd->rate_limit;
-
-	if (cmd->base.attr_mask & IB_QP_AV)
-		copy_ah_attr_from_uverbs(qp->device, &attr->ah_attr,
-					 &cmd->base.dest);
-
-	if (cmd->base.attr_mask & IB_QP_ALT_PATH)
-		copy_ah_attr_from_uverbs(qp->device, &attr->alt_ah_attr,
-					 &cmd->base.alt_dest);
 
 	ret = ib_modify_qp_with_udata(qp, attr,
 				      modify_qp_mask(qp->qp_type,
@@ -1994,13 +2008,6 @@ static int ib_uverbs_ex_modify_qp(struct uverbs_attr_bundle *attrs)
 	if (ret)
 		return ret;
 
-	/*
-	 * Last bit is reserved for extending the attr_mask by
-	 * using another field.
-	 */
-	if (cmd.base.attr_mask & ~(IB_QP_ATTR_STANDARD_BITS | IB_QP_RATE_LIMIT))
-		return -EOPNOTSUPP;
-
 	ret = modify_qp(attrs, &cmd);
 	if (ret)
 		return ret;

-- 
2.56.0

