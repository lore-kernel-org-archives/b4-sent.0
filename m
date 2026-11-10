From: Eric Davis <eric.davis@broadcom.com>
Date: Mon, 09 Nov 2026 20:00:37 -0800
Subject: [PATCH rdma-next v3 04/13] RDMA/core: add the reliable unconnected
 queue pair type
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-uet-ib-core-v3-4-3e7e7ffed2e9@broadcom.com>
References: <20261109-uet-ib-core-v3-0-3e7e7ffed2e9@broadcom.com>
In-Reply-To: <20261109-uet-ib-core-v3-0-3e7e7ffed2e9@broadcom.com>
To: Jason Gunthorpe <jgg@ziepe.ca>, Leon Romanovsky <leon@kernel.org>
Cc: linux-rdma@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Eric Davis <eric.davis@broadcom.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794283250; l=6296;
 i=eric.davis@broadcom.com; s=20261014; h=from:subject:message-id;
 bh=7S0po+7OLDw6sPOuM4dE/na5F5m/Retz/CUc20NrLwk=;
 b=MESeNEtlQv4gfhyiIr2i541QU5WNGKTe8TGNqZVDZHXdKYeCLSWNMfiEFTjPBQ9r/petqWLia
 y51yhCsz8MYCEF2shR5tQfIjlOf2MAhJzgaGzfoOTiltiRtbkx3f40h
X-Developer-Key: i=eric.davis@broadcom.com; a=ed25519;
 pk=uy3oCTOYBipIPjryXGMynBmtPvbO6qN2FOrduzpiI4A=
X-Endpoint-Received: by B4 Relay for eric.davis@broadcom.com/20261014 with auth_id=1186
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add IB_QPT_RU and its userspace counterpart, together with the field
layout of a reliable unconnected queue pair number used by UET.

Such a number uses all 32 bits, unlike the 24-bit InfiniBand and RoCE
one, so exempt it from the restrack assertion that no queue pair number
sets the top byte.

A relative number is named within a job, so pairs in two jobs may share
one, but restrack keys a queue pair by its number alone. Until it keys
them by more, refuse the second such pair with -EADDRINUSE rather than
leave it untracked.

The provider posts its work requests, so the write post_send and
post_recv commands refuse such a queue pair.

Signed-off-by: Eric Davis <eric.davis@broadcom.com>
---
 drivers/infiniband/core/restrack.c      | 15 ++++++++++++++-
 drivers/infiniband/core/uverbs_cmd.c    | 14 ++++++++++++++
 drivers/infiniband/core/verbs.c         | 13 +++++++++++++
 include/rdma/ib_verbs.h                 |  1 +
 include/uapi/rdma/ib_user_ioctl_verbs.h | 21 +++++++++++++++++++++
 5 files changed, 63 insertions(+), 1 deletion(-)

diff --git a/drivers/infiniband/core/restrack.c b/drivers/infiniband/core/restrack.c
index a8b838fdc7b5..a75af79adf2c 100644
--- a/drivers/infiniband/core/restrack.c
+++ b/drivers/infiniband/core/restrack.c
@@ -241,7 +241,20 @@ void rdma_restrack_add(struct rdma_restrack_entry *res)
 		/* Special case to ensure that LQPN points to right QP */
 		struct ib_qp *qp = container_of(res, struct ib_qp, res);
 
-		WARN_ONCE(qp->qp_num >> 24 || qp->port >> 8,
+		/* An InfiniBand/RoCE QP number is 24 bits and the top byte is
+		 * where the port is folded in for SMI and GSI. A reliable
+		 * unconnected pair is an exception as its QP number is a
+		 * full 32b wide, though of the top byte only the absolute bit
+		 * may be set. An absolute number whose low bits are 0 or 1
+		 * still conflicts SMI/GSI on port 128, which takes a device
+		 * with both RU and MADs on that many ports. Two RU pairs in
+		 * different jobs may also share a relative number, and
+		 * create_qp() refuses the second.
+		 */
+		WARN_ONCE(qp->port >> 8 ||
+			  (qp->qp_type != IB_QPT_RU && qp->qp_num >> 24) ||
+			  (qp->qp_type == IB_QPT_RU &&
+			   qp->qp_num & IB_UVERBS_QPN_UET_RESERVED_MASK),
 			  "QP number 0x%0X and port 0x%0X", qp->qp_num,
 			  qp->port);
 		res->id = qp->qp_num;
diff --git a/drivers/infiniband/core/uverbs_cmd.c b/drivers/infiniband/core/uverbs_cmd.c
index ed55fbbdfc18..e4fdfa0d9548 100644
--- a/drivers/infiniband/core/uverbs_cmd.c
+++ b/drivers/infiniband/core/uverbs_cmd.c
@@ -2058,6 +2058,12 @@ static int ib_uverbs_post_send(struct uverbs_attr_bundle *attrs)
 		goto out;
 	}
 
+	/* reliable unconnected work requests are posted by the provider */
+	if (qp->qp_type == IB_QPT_RU) {
+		ret = -EOPNOTSUPP;
+		goto out_put;
+	}
+
 	is_ud = qp->qp_type == IB_QPT_UD;
 	sg_ind = 0;
 	last = NULL;
@@ -2335,6 +2341,14 @@ static int ib_uverbs_post_recv(struct uverbs_attr_bundle *attrs)
 		goto out;
 	}
 
+	/* reliable unconnected work requests are posted by the provider */
+	if (qp->qp_type == IB_QPT_RU) {
+		rdma_lookup_put_uobject(&qp->uobject->uevent.uobject,
+					UVERBS_LOOKUP_READ);
+		ret = -EOPNOTSUPP;
+		goto out;
+	}
+
 	resp.bad_wr = 0;
 	ret = qp->device->ops.post_recv(qp->real_qp, wr, &bad_wr);
 
diff --git a/drivers/infiniband/core/verbs.c b/drivers/infiniband/core/verbs.c
index 1299125752d8..ccdb08284432 100644
--- a/drivers/infiniband/core/verbs.c
+++ b/drivers/infiniband/core/verbs.c
@@ -1333,10 +1333,23 @@ static struct ib_qp *create_qp(struct ib_device *dev, struct ib_pd *pd,
 		goto err_security;
 
 	rdma_restrack_add(&qp->res);
+
+	/* restrack keys a QP by its number alone, so an RU QP whose number
+	 * another QP has, as one in another job may, is refused rather than
+	 * left untracked
+	 */
+	if (qp->qp_type == IB_QPT_RU && !qp->res.valid) {
+		ret = -EADDRINUSE;
+		goto err_track;
+	}
+
 	return qp;
 
+err_track:
+	ib_destroy_qp_security_begin(qp->qp_sec);
 err_security:
 	qp->device->ops.destroy_qp(qp, uverbs_get_cleared_udata(uattrs));
+	ib_destroy_qp_security_end(qp->qp_sec);
 err_create:
 	rdma_restrack_put(&qp->res);
 	xa_destroy(&qp->comp_cntrs);
diff --git a/include/rdma/ib_verbs.h b/include/rdma/ib_verbs.h
index 02f3312c7cf2..8d74ed4fc581 100644
--- a/include/rdma/ib_verbs.h
+++ b/include/rdma/ib_verbs.h
@@ -1188,6 +1188,7 @@ enum ib_qp_type {
 	IB_QPT_RAW_PACKET = IB_UVERBS_QPT_RAW_PACKET,
 	IB_QPT_XRC_INI = IB_UVERBS_QPT_XRC_INI,
 	IB_QPT_XRC_TGT = IB_UVERBS_QPT_XRC_TGT,
+	IB_QPT_RU = IB_UVERBS_QPT_RU,
 	IB_QPT_MAX,
 	IB_QPT_DRIVER = IB_UVERBS_QPT_DRIVER,
 	/* Reserve a range for qp types internal to the low level driver.
diff --git a/include/uapi/rdma/ib_user_ioctl_verbs.h b/include/uapi/rdma/ib_user_ioctl_verbs.h
index ed72f48960f8..c568ed365c28 100644
--- a/include/uapi/rdma/ib_user_ioctl_verbs.h
+++ b/include/uapi/rdma/ib_user_ioctl_verbs.h
@@ -91,6 +91,7 @@ enum ib_uverbs_qp_type {
 	IB_UVERBS_QPT_RAW_PACKET = 8,
 	IB_UVERBS_QPT_XRC_INI,
 	IB_UVERBS_QPT_XRC_TGT,
+	IB_UVERBS_QPT_RU,
 	IB_UVERBS_QPT_DRIVER = 0xFF,
 };
 
@@ -302,6 +303,26 @@ struct ib_uverbs_buffer_desc {
 	__aligned_u64 length;
 };
 
+/* A UET reliable unconnected queue pair number uses all 32 bits:
+ *
+ *	[ absolute 1b | reserved 7b | resource index 12b | PIDonFEP 12b ]
+ *
+ * An absolute pair is named by its number alone. A relative one is named
+ * within a job, so it must carry a job key when it is created, and a number
+ * the device picks is relative only for a pair that has one. The reserved
+ * bits are zero.
+ *
+ * Two pairs on one device can't yet share a number, even in different jobs,
+ * as the kernel tracks a pair by its number alone. Creating the second fails
+ * with EADDRINUSE.
+ */
+#define IB_UVERBS_QPN_UET_PID_ON_FEP_MASK	0x00000fff
+#define IB_UVERBS_QPN_UET_PID_ON_FEP_SHIFT	0
+#define IB_UVERBS_QPN_UET_RI_MASK		0x00fff000
+#define IB_UVERBS_QPN_UET_RI_SHIFT		12
+#define IB_UVERBS_QPN_UET_RESERVED_MASK		0x7f000000
+#define IB_UVERBS_QPN_UET_ABSOLUTE_ADDR_BIT	0x80000000
+
 enum ib_uverbs_comp_cntr_entry {
 	IB_UVERBS_COMP_CNTR_ENTRY_COMP,
 	IB_UVERBS_COMP_CNTR_ENTRY_ERR,

-- 
2.56.0

