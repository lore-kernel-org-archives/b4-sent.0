From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Wed, 04 Nov 2026 08:46:04 -0800
Subject: [PATCH net-next v5 4/4] wifi: ath12k: Connect to the QMI server
 belonging to the device owned by this driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-qrtr-multi-ep-v5-4-4cdb2b4f1920@oss.qualcomm.com>
References: <20261104-qrtr-multi-ep-v5-0-4cdb2b4f1920@oss.qualcomm.com>
In-Reply-To: <20261104-qrtr-multi-ep-v5-0-4cdb2b4f1920@oss.qualcomm.com>
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
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Daizhuang Bai <daizhuang.bai@oss.qualcomm.com>, 
 Jeff Johnson <jeff.johnson@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4724;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=mhErcsLQdS5uRROGeaSOA51h7VNX0VQpNNW/OtbOflM=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBq62FQQ+e73zlMkQF+JuIZ6XZ0mdAZt9RxUsC4F
 GjvsyPFLMiJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCauthUAAKCRBVnxHm/pHO
 9evWB/9/LYxl9U54MCxD1UJD42IV/qA1YSt+cs8LuG7azAex5n1APg9aQgiYrPk5tKnCO45v8G7
 IAcrCUVEg1X1f1XMJ2wppe/3TUTDcSZYmnwUabbwqH1p6q5TcGCyaiuvmKWPw4MafFaoaeFVW4m
 X0BJhGecv0n875+Jblcgvak15aZ/TS9DjE8qcT3gJZjNAvFAegC1R/bNoSGONrNRTklr5ncoUFP
 eFnILIAfHr1Zyk8dx/ypg8ggoRIPeUc8O/eDoZkJSK/Y7Qb4GP28Epwvb4T8OjuEH2RV1WTpzUs
 LYkrZ/mdRA/m7kVqRAnUWZ2R8OnO+ffcYE84aJmLeeLeRUD8
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

Tested-on: 2x WCN7850 hw2.0 WLAN.IOE_HMT.1.1-00018-QCAHMTSWPL_V1.0_V2.0_SILICONZ-1
Tested-on: QCC2072 hw1.0 PCI WLAN.COL.1.0.c2-00277-QCACOLSWPL_V1_TO_SILICONZ-1

Reviewed-by: Simon Horman <horms@kernel.org>
Tested-by: Juha-Matti Tilli <juha-matti.tilli@iki.fi>
Tested-by: Daizhuang Bai <daizhuang.bai@oss.qualcomm.com>
Acked-by: Jeff Johnson <jeff.johnson@oss.qualcomm.com>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/net/wireless/ath/ath12k/hif.h |  9 +++++++++
 drivers/net/wireless/ath/ath12k/pci.c |  9 +++++++++
 drivers/net/wireless/ath/ath12k/qmi.c | 12 ++++++++++++
 3 files changed, 30 insertions(+)

diff --git a/drivers/net/wireless/ath/ath12k/hif.h b/drivers/net/wireless/ath/ath12k/hif.h
index aecdb0c5f285..c2cfe9a75493 100644
--- a/drivers/net/wireless/ath/ath12k/hif.h
+++ b/drivers/net/wireless/ath/ath12k/hif.h
@@ -31,6 +31,7 @@ struct ath12k_hif_ops {
 	void (*ce_irq_disable)(struct ath12k_base *ab);
 	void (*get_ce_msi_idx)(struct ath12k_base *ab, u32 ce_id, u32 *msi_idx);
 	void (*coredump_download)(struct ath12k_base *ab);
+	unsigned int (*get_qrtr_node_id)(struct ath12k_base *ab);
 };
 
 static inline int ath12k_hif_map_service_to_pipe(struct ath12k_base *ab, u16 service_id,
@@ -153,4 +154,12 @@ static inline void ath12k_hif_coredump_download(struct ath12k_base *ab)
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
index 12bbb75570f1..e56f2f9d721e 100644
--- a/drivers/net/wireless/ath/ath12k/pci.c
+++ b/drivers/net/wireless/ath/ath12k/pci.c
@@ -10,6 +10,7 @@
 #include <linux/pci.h>
 #include <linux/time.h>
 #include <linux/vmalloc.h>
+#include <net/qrtr.h>
 
 #include "pci.h"
 #include "core.h"
@@ -1493,6 +1494,13 @@ void ath12k_pci_power_down(struct ath12k_base *ab, bool is_suspend)
 	ath12k_pci_sw_reset(ab_pci->ab, false);
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
@@ -1513,6 +1521,7 @@ static const struct ath12k_hif_ops ath12k_pci_hif_ops = {
 #ifdef CONFIG_ATH12K_COREDUMP
 	.coredump_download = ath12k_pci_coredump_download,
 #endif
+	.get_qrtr_node_id = ath12k_pci_get_qrtr_node_id,
 };
 
 static enum ath12k_device_family
diff --git a/drivers/net/wireless/ath/ath12k/qmi.c b/drivers/net/wireless/ath/ath12k/qmi.c
index 817bd820623d..86ec7f2431e2 100644
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
@@ -3992,8 +3993,19 @@ static int ath12k_qmi_ops_new_server(struct qmi_handle *qmi_hdl,
 	struct ath12k_qmi *qmi = container_of(qmi_hdl, struct ath12k_qmi, handle);
 	struct ath12k_base *ab = qmi->ab;
 	struct sockaddr_qrtr *sq = &qmi->sq;
+	unsigned int node_id;
 	int ret;
 
+	/*
+	 * Identical devices advertise the same QMI services, so connect only
+	 * to the QMI server on this device's node. A node id of 0 means the
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

