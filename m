From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Wed, 22 Apr 2026 16:54:50 +0530
Subject: [PATCH 09/12] Bluetooth: hci_qca: Add M.2 Bluetooth device support
 using pwrseq
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260422-pwrseq-m2-bt-v1-9-720d02545a64@oss.qualcomm.com>
References: <20260422-pwrseq-m2-bt-v1-0-720d02545a64@oss.qualcomm.com>
In-Reply-To: <20260422-pwrseq-m2-bt-v1-0-720d02545a64@oss.qualcomm.com>
To: Bartosz Golaszewski <brgl@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 Shuai Zhang <quic_shuaz@quicinc.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-pci@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-bluetooth@vger.kernel.org, Wei Deng <wei.deng@oss.qualcomm.com>, 
 Luiz Augusto von Dentz <luiz.von.dentz@intel.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>
X-Mailer: b4 0.15.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1651;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=qvK9ciP9Mieq+7bzZAQ97BmIuJooRLI2mcgnenl9gDE=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBp6LAVVuUjoZeqgIvI+Eh9dYh8Z1Endxct3JPBg
 LpEE1N6j2KJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaeiwFQAKCRBVnxHm/pHO
 9UxvB/9FVPbDboBVhdi4RzMfCrwPtrAQFlqXLDsyG/Krp20mLA2rUfusw3SKzfIvcg7D4B5hduy
 ICBO/nlJO9AmlUcOxEEZHJrzO2F1ktuUwVrcvFPtpa6d0VMG91uh9rNJChdQI0sKNuWHioaghqA
 BOltkglY6kZ+ZUVMyQFX9sEWWPTnXw29wbSIKNFbGCwXm6hT44tOA73+gOlz2eGYqYPuZcpYr4L
 DT83m7DCYQqQCsdrnuIfZg3G4JCpZkMbml7vqe4LrEZqx8qwDs6bW8BHnDZs8Rw58P4C8UsceUs
 1kp/pceLn0NkibTWlvurvQ32jtJWSLPjAPO2dexj1tJcXSJA
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Power supply to the M.2 Bluetooth device attached to the host using M.2
connector is controlled using the 'uart' pwrseq device. So add support for
getting the pwrseq device if the OF graph link is present. Once obtained,
the existing pwrseq APIs can be used to control the power supplies of the
M.2 card.

Reviewed-by: Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>
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
2.51.0

