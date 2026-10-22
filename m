From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Thu, 22 Oct 2026 19:43:08 +0200
Subject: [PATCH v4 2/4] net: qrtr: Assign unique node id for MHI endpoints
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-qrtr-multi-ep-v4-2-c6fdb75fcd3e@oss.qualcomm.com>
References: <20261022-qrtr-multi-ep-v4-0-c6fdb75fcd3e@oss.qualcomm.com>
In-Reply-To: <20261022-qrtr-multi-ep-v4-0-c6fdb75fcd3e@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3964;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=YoEVGfn6pJagg3BMv8pSYGkO4MTCJESp0TWcBZdgqL0=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBq2ks0vhlFnClGHeItG3ycQMIpF0sxPskgHG9yp
 YQtb7wH+nWJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCatpLNAAKCRBVnxHm/pHO
 9c4KB/9BZ9UB5TqxY/WW3iYzlOOZUCzvatQQhXhbp+QAChdrkob/igzvFhLyekAks633VNEj1Hf
 e20Rkxm+ULE91vXMArBuufXbhVQo3YR7+VyHo8MDnWakpRhqLzs2Qfc8+hDRHSiz31VXq9twS3R
 p5ZASCejKGRZArBkvOhTSgucHQZWhgeKEkz6APCu8wKEGHF0vWwVy1QiynRJyxy+E8UlIgFrt+y
 bQGfX67qxYJHUMJFX3maunIlerSFW7/Q7IXScREBSP0J+O7qpGCtFt2Br/gz4zDwzE0mdkErdSj
 dlxjUnR8hRjBjcT1CjVRnR7n9Odp0ptO42fTOkOQQyDHbUxd
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Now that the QRTR driver allows using the unique node id for each device,
which is different from the node id received from the remote node, compute
a unique node id using a new API, qrtr_host_node_id().

This API takes the 'index' parameter and adds it to QRTR_NODE_HOST_BASE.
The base is chosen well above the node ids in use by the remote nodes, so
that the host assigned ids never collide with the pre-existing ones.

Since the ids at and above the base now belong to the host, reject any
packet carrying one as the source node id or as the node id of an
announced server in qrtr_endpoint_post().

Finally, call the new API from MHI endpoint driver by passing the MHI
controller index as the parameter. The MHI controller index is unique for
each controller, thereby for each MHI endpoint device.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 MAINTAINERS        |  1 +
 include/net/qrtr.h | 22 ++++++++++++++++++++++
 net/qrtr/af_qrtr.c |  9 +++++++++
 net/qrtr/mhi.c     |  4 +++-
 4 files changed, 35 insertions(+), 1 deletion(-)

diff --git a/MAINTAINERS b/MAINTAINERS
index df8ab9b82402..9c8bb086be28 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -22511,6 +22511,7 @@ QUALCOMM IPC ROUTER (QRTR) DRIVER
 M:	Manivannan Sadhasivam <mani@kernel.org>
 L:	linux-arm-msm@vger.kernel.org
 S:	Maintained
+F:	include/net/qrtr.h
 F:	include/trace/events/qrtr.h
 F:	include/uapi/linux/qrtr.h
 F:	net/qrtr/
diff --git a/include/net/qrtr.h b/include/net/qrtr.h
new file mode 100644
index 000000000000..6beefe89943b
--- /dev/null
+++ b/include/net/qrtr.h
@@ -0,0 +1,22 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+
+#ifndef _NET_QRTR_H
+#define _NET_QRTR_H
+
+#include <linux/types.h>
+
+/* Node ids at and above this base are reserved for the host and are never
+ * accepted from an endpoint. The base is well above the ids used by the
+ * remote nodes, so that pre-existing node ids stay untouched.
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
diff --git a/net/qrtr/af_qrtr.c b/net/qrtr/af_qrtr.c
index efa70b95f8a7..7a59ccf15490 100644
--- a/net/qrtr/af_qrtr.c
+++ b/net/qrtr/af_qrtr.c
@@ -11,6 +11,7 @@
 #include <linux/wait.h>
 #include <linux/workqueue.h>
 
+#include <net/qrtr.h>
 #include <net/sock.h>
 
 #include "qrtr.h"
@@ -590,6 +591,12 @@ int qrtr_endpoint_post(struct qrtr_endpoint *ep, const void *data, size_t len)
 	    cb->type != QRTR_TYPE_RESUME_TX)
 		goto err;
 
+	/* Host assigned node ids are not supposed to overlap with
+	 * remote node ids
+	 */
+	if (cb->src_node >= QRTR_NODE_HOST_BASE)
+		goto err;
+
 	skb_put_data(skb, data + hdrlen, size);
 
 	nid = cb->src_node;
@@ -615,6 +622,8 @@ int qrtr_endpoint_post(struct qrtr_endpoint *ep, const void *data, size_t len)
 		const struct qrtr_ctrl_pkt *pkt = data + hdrlen;
 
 		nid = le32_to_cpu(pkt->server.node);
+		if (nid >= QRTR_NODE_HOST_BASE)
+			goto err;
 
 		if (nid != READ_ONCE(node->ep_nid)) {
 			rc = qrtr_node_assign(node, nid);
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

