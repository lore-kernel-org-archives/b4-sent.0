From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Sat, 14 Nov 2026 06:26:14 -0800
Subject: [PATCH net-next v6 2/4] net: qrtr: Assign unique node id for MHI
 endpoints
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-qrtr-multi-ep-v6-2-2eb9885659e2@oss.qualcomm.com>
References: <20261114-qrtr-multi-ep-v6-0-2eb9885659e2@oss.qualcomm.com>
In-Reply-To: <20261114-qrtr-multi-ep-v6-0-2eb9885659e2@oss.qualcomm.com>
To: Manivannan Sadhasivam <mani@kernel.org>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Jeff Johnson <jjohnson@kernel.org>, Eric Dumazet <edumazet@kernel.org>, 
 Eric Dumazet <edumazet@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3283;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=/mk4KdzpVcWWvNuNI4IR+JOBKyEh5ixXNDCmghcPA1w=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBq+G+Lh1Yq2gHtGGj+kgVuJakXYCcwOfivdyhI6
 PSJIar0jdGJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCavhviwAKCRBVnxHm/pHO
 9VUAB/9IzaGbMTpsXnd2PGz8c3gcqZy+Z+jxOiamRn/UjfTo06hrOYU1fkCp+YemMD12Oe2ymlA
 2hpgWJ6qfcSNmWm7QP212nafX4Lc5oyHEMB7W3Ir6lJqtSzNsCDe+BGVjgmmN6015Yhe4sYrTkg
 gHsZDn75WBS6NAYOqbskC0/QzAz0w9/j2xoaih8eNdwDGxEwUHHcrMfXrhXonk2nGK62Ao1EyMD
 7fB+4+NX4XCtn/0mzlP90JAz5snM/9h0ivmzv5+o6LBgFslxqA+ML64Ru7BZtwrdgR6A7NGhA8O
 4uc76PuzAFjH5V44iL5Qqc/CDtgAdqHEnyjkaL5CGZU0G1HE
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Now that the QRTR driver allows using the unique node id for each device,
which is different from the node id received from the remote node, compute
a unique node id using a new API, qrtr_host_node_id().

This API takes the 'index' parameter and adds it to QRTR_NODE_HOST_BASE.
The index comes from an allocator, so the host assigned ids are unique
among themselves. The base is chosen just above the 16-bit range a v2
header can express, so an endpoint using v2 can never claim an id in the
host range. An endpoint using v1 can claim any 32-bit id, so a collision
is possible, but unlikely as the firmware assigned node ids are either
smaller than this base or in the range of 0x08e5ff85. Such a collision is
caught when the id is added to the node lookup table.

Finally, call the new API from MHI endpoint driver by passing the MHI
controller index as the parameter. The MHI controller index is unique for
each controller, thereby for each MHI endpoint device.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 MAINTAINERS        |  1 +
 include/net/qrtr.h | 27 +++++++++++++++++++++++++++
 net/qrtr/mhi.c     |  4 +++-
 3 files changed, 31 insertions(+), 1 deletion(-)

diff --git a/MAINTAINERS b/MAINTAINERS
index 0cf311e6c4be..dfec5181c6e1 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -23139,6 +23139,7 @@ QUALCOMM IPC ROUTER (QRTR) DRIVER
 M:	Manivannan Sadhasivam <mani@kernel.org>
 L:	linux-arm-msm@vger.kernel.org
 S:	Maintained
+F:	include/net/qrtr.h
 F:	include/trace/events/qrtr.h
 F:	include/uapi/linux/qrtr.h
 F:	net/qrtr/
diff --git a/include/net/qrtr.h b/include/net/qrtr.h
new file mode 100644
index 000000000000..e2a8d93564b5
--- /dev/null
+++ b/include/net/qrtr.h
@@ -0,0 +1,27 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+
+#ifndef _NET_QRTR_H
+#define _NET_QRTR_H
+
+#include <linux/types.h>
+
+/*
+ * Base for the node ids the host assigns to endpoints. It sits just above the
+ * 16-bit range a v2 header can express, so a v2 endpoint can never claim an id
+ * in it. A v1 endpoint can claim any 32-bit id, so a collision is possible,
+ * but unlikely as the firmware assigned node ids are either smaller than this
+ * base or in the range of 0x08e5ff85. A collision is caught when the id is
+ * added to the node lookup table.
+ */
+#define QRTR_NODE_HOST_BASE 0x10000u
+
+/*
+ * Compute host node id from a per-device index. The index must be unique among
+ * the host assigned endpoints.
+ */
+static inline unsigned int qrtr_host_node_id(unsigned int index)
+{
+	return QRTR_NODE_HOST_BASE + index;
+}
+
+#endif /* _NET_QRTR_H */
diff --git a/net/qrtr/mhi.c b/net/qrtr/mhi.c
index 1040c3c8cfd6..e9377f818b4d 100644
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

