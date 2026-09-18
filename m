From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Fri, 18 Sep 2026 18:28:14 +0200
Subject: [PATCH 2/4] net: qrtr: Assign unique node id for MHI endpoints
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260918-qrtr-multi-ep-v1-2-8a06caa368d3@oss.qualcomm.com>
References: <20260918-qrtr-multi-ep-v1-0-8a06caa368d3@oss.qualcomm.com>
In-Reply-To: <20260918-qrtr-multi-ep-v1-0-8a06caa368d3@oss.qualcomm.com>
To: Manivannan Sadhasivam <mani@kernel.org>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Jeff Johnson <jjohnson@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-wireless@vger.kernel.org, 
 ath11k@lists.infradead.org, ath12k@lists.infradead.org, 
 Bjorn Andersson <andersson@kernel.org>, 
 Chris Lew <christopher.lew@oss.qualcomm.com>, 
 Deepak Kumar Singh <deepak.singh@oss.qualcomm.com>, 
 Raj Kumar Bhagat <raj.bhagat@oss.qualcomm.com>, 
 Juha-Matti Tilli <juha-matti.tilli@iki.fi>, 
 Jeff Hugo <jeff.hugo@oss.qualcomm.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2620;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=uOYu1U8wIC2RDVexAi1abQkUbN13SL1t/kCkWYPYdoU=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqrWaeF6Y6uwvyLe36Rr5ay4I2MYWQOIJL3dVs1
 jNepmU7vnOJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaq1mngAKCRBVnxHm/pHO
 9V4QB/9kPI0g4gGHMb3I5Vi2hxhCo0kEQntSmTve/Ue2kyHg9KUVLEW0zCa8hVLz6PnxAVHjAVA
 ylXCIxMiSZ1zKUtacpBbNWVX/s9aOZ4ssYRRpL1mestEhvCm7DeyUj2J8BaHtmoUOg/+4MiVgIx
 rtW29lzRhqyQ/KjmlziBLmWQCeO4qiHisKkHMfv8slVhRLBF17FYKFeBcXs1QnpMkzwM+0hDFKh
 ng90uQj02fm/GCTwNSgv5ajUHuZ5wzD+PJpivaSQrx/vtdIzZ/bo6lqEQi8k7rx8+l6bxSXFz4X
 jh/fhii/LHuvp7URaJdAmNt4Na3pqqrg+XH77+DLNk2iv2PX
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Now that the QRTR driver allows using the unique node id for each device,
which is different from the node id received from the remote node, compute
a unique node id using a new API, qrtr_host_node_id().

This API takes the 'index' parameter and adds it to QRTR_NODE_HOST_BASE,
whose value is outside of the node id range used by the remote nodes (0 to
0xffff).

Finally, call the new API from MHI endpoint driver by passing the MHI
controller index as the parameter. The MHI controller index is unique for
each controller, thereby for each MHI endpoint device.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 MAINTAINERS        |  1 +
 include/net/qrtr.h | 21 +++++++++++++++++++++
 net/qrtr/mhi.c     |  4 +++-
 3 files changed, 25 insertions(+), 1 deletion(-)

diff --git a/MAINTAINERS b/MAINTAINERS
index 3a19da74d00c..bc1af0cd8a8b 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -22504,6 +22504,7 @@ QUALCOMM IPC ROUTER (QRTR) DRIVER
 M:	Manivannan Sadhasivam <mani@kernel.org>
 L:	linux-arm-msm@vger.kernel.org
 S:	Maintained
+F:	include/net/qrtr.h
 F:	include/trace/events/qrtr.h
 F:	include/uapi/linux/qrtr.h
 F:	net/qrtr/
diff --git a/include/net/qrtr.h b/include/net/qrtr.h
new file mode 100644
index 000000000000..745d51b4a6ba
--- /dev/null
+++ b/include/net/qrtr.h
@@ -0,0 +1,21 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+
+#ifndef _NET_QRTR_H
+#define _NET_QRTR_H
+
+#include <linux/types.h>
+
+/* The offset is chosen carefully to not collide with the node ids allocated by
+ * the remote nodes. All the remote nodes use node ids in range 0 to 0xffff.
+ */
+#define QRTR_NODE_HOST_BASE 0x10000u
+
+/* Compute host node id from a per-device index. The index must be unique
+ * among the host assigned endpoints and smaller than QRTR_NODE_HOST_BASE.
+ */
+static inline unsigned int qrtr_host_node_id(unsigned int index)
+{
+	return QRTR_NODE_HOST_BASE + index;
+}
+
+#endif /* _NET_QRTR_H */
diff --git a/net/qrtr/mhi.c b/net/qrtr/mhi.c
index 3990da1a65dc..c920ab61f848 100644
--- a/net/qrtr/mhi.c
+++ b/net/qrtr/mhi.c
@@ -6,6 +6,7 @@
 #include <linux/mhi.h>
 #include <linux/module.h>
 #include <linux/skbuff.h>
+#include <net/qrtr.h>
 #include <net/sock.h>
 
 #include "qrtr.h"
@@ -127,7 +128,8 @@ static int qcom_mhi_qrtr_probe(struct mhi_device *mhi_dev,
 	if (rc)
 		return rc;
 
-	rc = qrtr_endpoint_register(&qdev->ep, QRTR_EP_NID_AUTO);
+	rc = qrtr_endpoint_register(&qdev->ep,
+				    qrtr_host_node_id(mhi_dev->mhi_cntrl->index));
 	if (rc)
 		goto err_unprepare;
 

-- 
2.43.0

