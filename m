From: Eric Davis <eric.davis@broadcom.com>
Date: Wed, 14 Oct 2026 15:21:13 -0700
Subject: [PATCH rdma-next 04/13] RDMA/core: add the reliable unconnected
 queue pair type
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261014-uet-ib-core-v1-4-a0e626117113@broadcom.com>
References: <20261014-uet-ib-core-v1-0-a0e626117113@broadcom.com>
In-Reply-To: <20261014-uet-ib-core-v1-0-a0e626117113@broadcom.com>
To: Jason Gunthorpe <jgg@ziepe.ca>, Leon Romanovsky <leon@kernel.org>
Cc: linux-rdma@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Eric Davis <eric.davis@broadcom.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792016478; l=3535;
 i=eric.davis@broadcom.com; s=20261014; h=from:subject:message-id;
 bh=L3wMh3G54GedqHBn1oHoS/DOBV8omUdKsjOycbtDnDU=;
 b=i8Qr4lWAYjzAEIzXiqVXNaGZ95Lx1KHmJ3IvLYzFEi9rhMgPwT0zPH+u7i4Gp8JzJ0+HBDYIn
 LHn/R4FF9wtAkwDmMcjyexInZZFce15QUgmtIIQo3jAvKwDae8BSc6o
X-Developer-Key: i=eric.davis@broadcom.com; a=ed25519;
 pk=uy3oCTOYBipIPjryXGMynBmtPvbO6qN2FOrduzpiI4A=
X-Endpoint-Received: by B4 Relay for eric.davis@broadcom.com/20261014 with auth_id=1186
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add IB_QPT_RU and its userspace counterpart, together with the field
layout of a reliable unconnected queue pair number used by UET.

Such a number uses all 32 bits, unlike the 24-bit InfiniBand and RoCE
one, so exempt it from the restrack assertion that no queue pair number
sets the top byte.

Signed-off-by: Eric Davis <eric.davis@broadcom.com>
---
 drivers/infiniband/core/restrack.c      | 13 ++++++++++++-
 include/rdma/ib_verbs.h                 |  1 +
 include/uapi/rdma/ib_user_ioctl_verbs.h | 16 ++++++++++++++++
 3 files changed, 29 insertions(+), 1 deletion(-)

diff --git a/drivers/infiniband/core/restrack.c b/drivers/infiniband/core/restrack.c
index a8b838fdc7b5..ddb09b17b733 100644
--- a/drivers/infiniband/core/restrack.c
+++ b/drivers/infiniband/core/restrack.c
@@ -241,7 +241,18 @@ void rdma_restrack_add(struct rdma_restrack_entry *res)
 		/* Special case to ensure that LQPN points to right QP */
 		struct ib_qp *qp = container_of(res, struct ib_qp, res);
 
-		WARN_ONCE(qp->qp_num >> 24 || qp->port >> 8,
+		/* An InfiniBand/RoCE QP number is 24 bits and the top byte is
+		 * where the port is folded in for SMI and GSI. A reliable
+		 * unconnected pair is an exception as its QP number is a
+		 * full 32b wide, though of the top byte only the absolute bit
+		 * may be set. An absolute number whose low bits are 0 or 1
+		 * still conflicts SMI/GSI on port 128, which takes a device
+		 * with both RU and MADs on that many ports.
+		 */
+		WARN_ONCE(qp->port >> 8 ||
+			  (qp->qp_type != IB_QPT_RU && qp->qp_num >> 24) ||
+			  (qp->qp_type == IB_QPT_RU &&
+			   qp->qp_num & IB_UVERBS_QPN_UET_RESERVED_MASK),
 			  "QP number 0x%0X and port 0x%0X", qp->qp_num,
 			  qp->port);
 		res->id = qp->qp_num;
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
index ed72f48960f8..b6d46115f799 100644
--- a/include/uapi/rdma/ib_user_ioctl_verbs.h
+++ b/include/uapi/rdma/ib_user_ioctl_verbs.h
@@ -91,6 +91,7 @@ enum ib_uverbs_qp_type {
 	IB_UVERBS_QPT_RAW_PACKET = 8,
 	IB_UVERBS_QPT_XRC_INI,
 	IB_UVERBS_QPT_XRC_TGT,
+	IB_UVERBS_QPT_RU,
 	IB_UVERBS_QPT_DRIVER = 0xFF,
 };
 
@@ -302,6 +303,21 @@ struct ib_uverbs_buffer_desc {
 	__aligned_u64 length;
 };
 
+/* A UET reliable unconnected queue pair number uses all 32 bits:
+ *
+ *	[ absolute 1b | reserved 7b | resource index 12b | PIDonFEP 12b ]
+ *
+ * An absolute pair is named by its number alone. A relative one is named
+ * within a job, so it must carry a job key when it is created. The reserved
+ * bits are zero.
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

