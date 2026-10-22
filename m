From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Thu, 22 Oct 2026 19:43:10 +0200
Subject: [PATCH v4 4/4] wifi: ath12k: Connect to the QMI server belonging
 to the device owned by this driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-qrtr-multi-ep-v4-4-c6fdb75fcd3e@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=4303;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=12Qa0EpdKE17l7J/TlSWmlYBFBDnMCpE99H5MSImZQM=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBq2ks1l0yBojVpshNCZp9U7fxLtGT4aTO89TKkM
 GrxDwXHwP6JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCatpLNQAKCRBVnxHm/pHO
 9RasB/0UnIGBlYOFagdQugHnjX5NyZ9LrSeSLbzd9ytyzqjrZ1sJN3K0J0QsAsjo8rDOzCCIctD
 HsclzOy/kY9LVwzvBFD5zuzqz3CVaZ5FPNKKJMiI+CPAqYQrDI6D+9A9KiVIKHlILtT75aJMGV9
 8Y8tezgoEi4/iFy58BaBg3bXm/aet9yVrVEQupGDlSVPJoOk3eI1gCmNFPffDCe9ljKMvJAqRc9
 EsfvOQN53KJcQe8w8IQH18p8XGYHSabx6uxQ2dyZHfl7L/FyJySf7poITdV3HpD3lewqAfugHxh
 DAiSgnlZA7bkBxtK3lR0IJh/SYHTJFe3GlAL9JkSLfqjvu14
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When two identical ath12k PCIe devices are connected to the same host, both
advertise the WLFW service with the same service and instance id. The QMI
lookup reports both servers to each device, so a device may connect to the
firmware running on the other device.

But now, QRTR provides each MHI endpoint a unique node id which is
different from the node id announced by the device. So use the same id to
pick the correct server. Add a get_qrtr_node_id() HIF callback that returns
the node id derived from the MHI controller index and zero for transports
that do not assign one. In the new_server callback, reject any service
whose node id does not match. A node id of zero disables the check, so
transports that do not assign one keep their current behavior.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/net/wireless/ath/ath12k/hif.h |  9 +++++++++
 drivers/net/wireless/ath/ath12k/pci.c |  9 +++++++++
 drivers/net/wireless/ath/ath12k/qmi.c | 11 +++++++++++
 3 files changed, 29 insertions(+)

diff --git a/drivers/net/wireless/ath/ath12k/hif.h b/drivers/net/wireless/ath/ath12k/hif.h
index 4de8667690e9..b8592c3d84e7 100644
--- a/drivers/net/wireless/ath/ath12k/hif.h
+++ b/drivers/net/wireless/ath/ath12k/hif.h
@@ -32,6 +32,7 @@ struct ath12k_hif_ops {
 	void (*get_ce_msi_idx)(struct ath12k_base *ab, u32 ce_id, u32 *msi_idx);
 	int (*panic_handler)(struct ath12k_base *ab);
 	void (*coredump_download)(struct ath12k_base *ab);
+	unsigned int (*get_qrtr_node_id)(struct ath12k_base *ab);
 };
 
 static inline int ath12k_hif_map_service_to_pipe(struct ath12k_base *ab, u16 service_id,
@@ -162,4 +163,12 @@ static inline void ath12k_hif_coredump_download(struct ath12k_base *ab)
 	if (ab->hif.ops->coredump_download)
 		ab->hif.ops->coredump_download(ab);
 }
+
+static inline unsigned int ath12k_hif_get_qrtr_node_id(struct ath12k_base *ab)
+{
+	if (!ab->hif.ops->get_qrtr_node_id)
+		return 0;
+
+	return ab->hif.ops->get_qrtr_node_id(ab);
+}
 #endif /* ATH12K_HIF_H */
diff --git a/drivers/net/wireless/ath/ath12k/pci.c b/drivers/net/wireless/ath/ath12k/pci.c
index 6441927b5382..9b6108c1abdc 100644
--- a/drivers/net/wireless/ath/ath12k/pci.c
+++ b/drivers/net/wireless/ath/ath12k/pci.c
@@ -10,6 +10,7 @@
 #include <linux/pci.h>
 #include <linux/time.h>
 #include <linux/vmalloc.h>
+#include <net/qrtr.h>
 
 #include "pci.h"
 #include "core.h"
@@ -1491,6 +1492,13 @@ static int ath12k_pci_panic_handler(struct ath12k_base *ab)
 	return NOTIFY_OK;
 }
 
+static unsigned int ath12k_pci_get_qrtr_node_id(struct ath12k_base *ab)
+{
+	struct ath12k_pci *ab_pci = ath12k_pci_priv(ab);
+
+	return qrtr_host_node_id(ab_pci->mhi_ctrl->index);
+}
+
 static const struct ath12k_hif_ops ath12k_pci_hif_ops = {
 	.start = ath12k_pci_start,
 	.stop = ath12k_pci_stop,
@@ -1512,6 +1520,7 @@ static const struct ath12k_hif_ops ath12k_pci_hif_ops = {
 #ifdef CONFIG_ATH12K_COREDUMP
 	.coredump_download = ath12k_pci_coredump_download,
 #endif
+	.get_qrtr_node_id = ath12k_pci_get_qrtr_node_id,
 };
 
 static enum ath12k_device_family
diff --git a/drivers/net/wireless/ath/ath12k/qmi.c b/drivers/net/wireless/ath/ath12k/qmi.c
index 280e50a1f31d..507062068f8e 100644
--- a/drivers/net/wireless/ath/ath12k/qmi.c
+++ b/drivers/net/wireless/ath/ath12k/qmi.c
@@ -9,6 +9,7 @@
 #include "qmi.h"
 #include "core.h"
 #include "debug.h"
+#include "hif.h"
 #include <linux/of.h>
 #include <linux/firmware.h>
 #include <linux/of_address.h>
@@ -3940,8 +3941,18 @@ static int ath12k_qmi_ops_new_server(struct qmi_handle *qmi_hdl,
 	struct ath12k_qmi *qmi = container_of(qmi_hdl, struct ath12k_qmi, handle);
 	struct ath12k_base *ab = qmi->ab;
 	struct sockaddr_qrtr *sq = &qmi->sq;
+	unsigned int node_id;
 	int ret;
 
+	/* Identical devices advertise the same QMI services, so connect only to
+	 * the QMI server on this device's node. A node id of 0 means the
+	 * transport has not assigned a unique node id, so accept the server
+	 * unfiltered.
+	 */
+	node_id = ath12k_hif_get_qrtr_node_id(ab);
+	if (node_id && service->node != node_id)
+		return -EINVAL;
+
 	sq->sq_family = AF_QIPCRTR;
 	sq->sq_node = service->node;
 	sq->sq_port = service->port;

-- 
2.43.0

