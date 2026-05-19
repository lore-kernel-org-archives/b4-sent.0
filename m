From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Tue, 19 May 2026 14:26:02 +0530
Subject: [PATCH v3 7/9] Bluetooth: hci_qca: Add M.2 Bluetooth device
 support using pwrseq
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260519-pwrseq-m2-bt-v3-7-b39dc2ae3966@oss.qualcomm.com>
References: <20260519-pwrseq-m2-bt-v3-0-b39dc2ae3966@oss.qualcomm.com>
In-Reply-To: <20260519-pwrseq-m2-bt-v3-0-b39dc2ae3966@oss.qualcomm.com>
To: Manivannan Sadhasivam <mani@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, 
 Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: linux-pci@vger.kernel.org, linux-pm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-bluetooth@vger.kernel.org, Wei Deng <wei.deng@oss.qualcomm.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1767;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=GJhR3pGJmBkuBiEdPQiIZNdHJxFMj5cpBFli453SiCY=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqDCWg/NhLg95CymCV+6e6aupP7h1F+Dx/209WG
 f2ElDHg9A2JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCagwloAAKCRBVnxHm/pHO
 9RhyB/4qW2SabwLglJuVqNLjX5mS6UgCDHU7M7gLCNR7ptwdlInK6eZw8kFVW16ULVJgiRKYSDp
 dVFdwttt7eu8tFN3wBCcr168pwI4Vj1NHoJC+vLguUGhHjBd4u1pE6I+C2akORGknv8Quw8+Tya
 iD4wcFyLlfRkQWbYZnjEnxmPGHw856/qouL46oWFRcEjYrFI/RvCvChs9Pn7+lmMIn3Dw8O6GrK
 fyednYHarb1ypB8alcjpLOLfAPFIN43mvj00AB4tBr8Vsa4lGWNhKFIG6zEWVQo/iuslD8YH0Yu
 rJJXOcOkE+Tm4PzpCziVwOmhXBzt0Mp9B4Nb7PCJ7yW35kha
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Power supply to the M.2 Bluetooth device attached to the host using M.2
connector is controlled using the 'uart' pwrseq device. So add support for
getting the pwrseq device if the OF graph link is present. Once obtained,
the existing pwrseq APIs can be used to control the power supplies of the
M.2 card.

Tested-by: Wei Deng <wei.deng@oss.qualcomm.com>
Reviewed-by: Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>
Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/bluetooth/hci_qca.c | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/drivers/bluetooth/hci_qca.c b/drivers/bluetooth/hci_qca.c
index cd1834246b47..c83fe72bc549 100644
--- a/drivers/bluetooth/hci_qca.c
+++ b/drivers/bluetooth/hci_qca.c
@@ -26,6 +26,7 @@
 #include <linux/mod_devicetable.h>
 #include <linux/module.h>
 #include <linux/of.h>
+#include <linux/of_graph.h>
 #include <linux/acpi.h>
 #include <linux/platform_device.h>
 #include <linux/pwrseq/consumer.h>
@@ -2443,6 +2444,18 @@ static int qca_serdev_probe(struct serdev_device *serdev)
 	case QCA_WCN6750:
 	case QCA_WCN6855:
 	case QCA_WCN7850:
+		/*
+		 * OF graph link is only present for BT devices attached through
+		 * the M.2 Key E connector.
+		 */
+		if (of_graph_is_present(dev_of_node(&serdev->ctrl->dev))) {
+			qcadev->bt_power->pwrseq = devm_pwrseq_get(&serdev->ctrl->dev,
+								   "uart");
+			if (IS_ERR(qcadev->bt_power->pwrseq))
+				return PTR_ERR(qcadev->bt_power->pwrseq);
+			break;
+		}
+
 		if (!device_property_present(&serdev->dev, "enable-gpios")) {
 			/*
 			 * Backward compatibility with old DT sources. If the

-- 
2.48.1

