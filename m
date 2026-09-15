From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Tue, 15 Sep 2026 16:24:05 +0200
Subject: [PATCH 4/5] Bluetooth: hci_qca: Drop serdev based M.2 power
 sequencing code
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260915-pci-m2-bt-rework-v1-4-3c7d9cf9c010@oss.qualcomm.com>
References: <20260915-pci-m2-bt-rework-v1-0-3c7d9cf9c010@oss.qualcomm.com>
In-Reply-To: <20260915-pci-m2-bt-rework-v1-0-3c7d9cf9c010@oss.qualcomm.com>
To: Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 Bartosz Golaszewski <brgl@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Amitkumar Karwar <amitkumar.karwar@nxp.com>, 
 Neeraj Kale <neeraj.sanjaykale@nxp.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-kernel@vger.kernel.org, linux-bluetooth@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-pci@vger.kernel.org, 
 linux-pm@vger.kernel.org, Rahul Samana <rahul.samana@oss.qualcomm.com>, 
 Wei Deng <wei.deng@oss.qualcomm.com>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3169;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=/fJwYLZay9p/+8hufmw3DfTVYzGPwzb16kQvam8A42M=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqqVUTtZ7RZSsKXdDqzaK7jO9pzNTf8LCLVIz5F
 nkkNJaC+JGJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaqlVEwAKCRBVnxHm/pHO
 9fdpB/9rTOAZq0xBDkNYCJ0LlmndHPbMZKMOfVyx+tex1e181mCFYrUNoHkz0G2eNZXoaQEQdqK
 Ssz/T9RxMt/DGALf7xE1ovoDcIZoAeesXw7nmwwEJNjb1vIDVbZ2xhX9tLD6Nq8WSDC19AZuLuj
 uHcJbXwYS54NunvDxeTZtFxJmc3krM4m9ltNLSemmowAXeLMzZhqOXX+vNWKSwzc+WPfHQbGxS1
 K23L7/UQwmJaTMb3vN3mz35bEpNF3Qa5BrPumgZzOfGTufyVZ8u/p/3jvxBLEA44T5tuE+x7UPN
 OIOQMOsFjbiNW/GpXpSrj1fkbZhhtMvEpv9AtUGChwSfQ1c7
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Bluetooth interface in M.2 modules is now enumerated using an auxiliary
device instead of serdev. The power sequencing driver now allocates an
auxiliary device for the Bluetooth interface whenever a compatible
M.2 module shows up over PCIe. And the auxiliary device gets bind to this
hci_qca driver using the existing auxiliary driver matching logic.

Earlier the same modules were brought up by fabricating a bluetooth
node under the UART controller, so that the serdev bus matched this
driver, and qca_serdev_probe grabbed the "uart" sequencer when the M.2
connector was reachable over the OF graph. That node is no longer
created, so the serdev driver never binds for an M.2 module.

Hence, remove the serdev based M.2 power sequencing code.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/bluetooth/hci_qca.c | 37 -------------------------------------
 1 file changed, 37 deletions(-)

diff --git a/drivers/bluetooth/hci_qca.c b/drivers/bluetooth/hci_qca.c
index 15cc6cca9057..3a348f4153e7 100644
--- a/drivers/bluetooth/hci_qca.c
+++ b/drivers/bluetooth/hci_qca.c
@@ -26,7 +26,6 @@
 #include <linux/gpio/consumer.h>
 #include <linux/module.h>
 #include <linux/of.h>
-#include <linux/of_graph.h>
 #include <linux/acpi.h>
 #include <linux/platform_device.h>
 #include <linux/pwrseq/consumer.h>
@@ -2384,34 +2383,6 @@ static int qca_init_regulators(struct qca_serdev *qcadev,
 	return 0;
 }
 
-static void qca_serdev_put_pwrseq(void *data)
-{
-	pwrseq_put(data);
-}
-
-static int qca_serdev_get_m2_pwrseq(struct qca_serdev *qcadev)
-{
-	struct serdev_device *serdev = qcadev->serdev_hu.serdev;
-	struct pwrseq_desc *pwrseq;
-
-	if (!of_graph_is_present(dev_of_node(&serdev->ctrl->dev)))
-		return 0;
-
-	/* The pwrseq is looked up on the serdev controller (which holds the
-	 * OF graph to the M.2 connector), but its lifetime must follow this
-	 * serdev consumer device, not the controller. So acquire it with the
-	 * non-devres pwrseq_get() and release it via a devres action bound to
-	 * &serdev->dev instead of using devm_pwrseq_get(&serdev->ctrl->dev).
-	 */
-	pwrseq = pwrseq_get(&serdev->ctrl->dev, "uart");
-	if (IS_ERR(pwrseq))
-		return PTR_ERR(pwrseq);
-
-	qcadev->pwrseq = pwrseq;
-
-	return devm_add_action_or_reset(&serdev->dev, qca_serdev_put_pwrseq, pwrseq);
-}
-
 static int qca_serdev_probe(struct serdev_device *serdev)
 {
 	struct qca_serdev *qcadev;
@@ -2442,10 +2413,6 @@ static int qca_serdev_probe(struct serdev_device *serdev)
 	else
 		qcadev->btsoc_type = QCA_ROME;
 
-	err = qca_serdev_get_m2_pwrseq(qcadev);
-	if (err)
-		return err;
-
 	switch (qcadev->btsoc_type) {
 	case QCA_WCN3950:
 	case QCA_WCN3988:
@@ -2455,10 +2422,6 @@ static int qca_serdev_probe(struct serdev_device *serdev)
 	case QCA_WCN6750:
 	case QCA_WCN6855:
 	case QCA_WCN7850:
-		/* M.2 connector modules are powered by the pwrseq acquired above. */
-		if (qcadev->pwrseq)
-			break;
-
 		if (!device_property_present(&serdev->dev, "enable-gpios")) {
 			/*
 			 * Backward compatibility with old DT sources. If the

-- 
2.43.0

