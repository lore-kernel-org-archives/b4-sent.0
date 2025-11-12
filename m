From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Wed, 12 Nov 2025 20:15:20 +0530
Subject: [PATCH 8/9] Bluetooth: hci_qca: Add support for WCN7850 PCIe M.2
 card
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251112-pci-m2-e-v1-8-97413d6bf824@oss.qualcomm.com>
References: <20251112-pci-m2-e-v1-0-97413d6bf824@oss.qualcomm.com>
In-Reply-To: <20251112-pci-m2-e-v1-0-97413d6bf824@oss.qualcomm.com>
To: Rob Herring <robh@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Nathan Chancellor <nathan@kernel.org>, 
 Nicolas Schier <nicolas.schier@linux.dev>, Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Mark Pearson <mpearson-lenovo@squebb.ca>, 
 "Derek J. Clark" <derekjohn.clark@gmail.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>
Cc: linux-serial@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kbuild@vger.kernel.org, platform-driver-x86@vger.kernel.org, 
 linux-pci@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-bluetooth@vger.kernel.org, 
 linux-pm@vger.kernel.org, Stephan Gerhold <stephan.gerhold@linaro.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2696;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=BvmMTIXQ1GNDFtswjVs+6kgwmDbVSZjbebNDSNmVGWY=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpFJ2HGzyZfvK1wWuuh2R0+XpgrtuddR6FBBMSs
 h9ujHKvehqJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaRSdhwAKCRBVnxHm/pHO
 9ZJMB/9CsIHjXFLhSxMyD3KH42rNli77Z0cMlgKT76aBTmR1yHjj4rM5kkkP9+YqQAIK9g4dvKj
 IhkioadhbwsVBbgv0No2SGnsLJesOHwDW1/Q4OebgTR4Osg78Iai2xvxB6ybVmW+J6O3tjaDD0q
 9JzWdanKbxsb3neIa4HtYsw9W7ORxGryz49PoqcK5wdXLCaIV64MbruswFeUp8ZG1BA30MgCzT9
 y1cCjIgjBov6xWYWpuGK8J7PpHe8NbfwoUfv50vZMwZXTKNS8zVdy7n7LNVNBV9R+NxLK5Xh+2t
 bGn/mmnez+yaIgjVC7MDJ1nhWAcFKF3DMa2D4HnzUFGqMoje
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The WCN7850 PCIe M.2 card connected to the UART controller exposes the
'WCN7850' serdev device and is controlled using the pwrseq framework.

Hence, add support for it in the driver. It reuses the existing
'qca_soc_data_wcn7850' driver data.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/bluetooth/hci_qca.c | 20 ++++++++++++++++++++
 1 file changed, 20 insertions(+)

diff --git a/drivers/bluetooth/hci_qca.c b/drivers/bluetooth/hci_qca.c
index 4cff4d9be3132561ee9bae4ddf2c8ac0bc13ecd7..09bfb3bba93698f496947775bf6b31f2f20279f1 100644
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
@@ -2344,6 +2345,9 @@ static int qca_serdev_probe(struct serdev_device *serdev)
 
 	qcadev->serdev_hu.serdev = serdev;
 	data = device_get_match_data(&serdev->dev);
+	if (!data && serdev->id)
+		data = (const struct qca_device_data *) serdev->id->driver_data;
+
 	serdev_device_set_drvdata(serdev, qcadev);
 	device_property_read_string_array(&serdev->dev, "firmware-name",
 					 qcadev->firmware_name, ARRAY_SIZE(qcadev->firmware_name));
@@ -2384,6 +2388,15 @@ static int qca_serdev_probe(struct serdev_device *serdev)
 	case QCA_WCN6855:
 	case QCA_WCN7850:
 	case QCA_WCN6750:
+		if (of_graph_is_present(dev_of_node(&serdev->ctrl->dev))) {
+			qcadev->bt_power->pwrseq = devm_pwrseq_get(&serdev->ctrl->dev,
+								   "uart");
+			if (IS_ERR(qcadev->bt_power->pwrseq))
+				qcadev->bt_power->pwrseq = NULL;
+			else
+				break;
+		}
+
 		if (!device_property_present(&serdev->dev, "enable-gpios")) {
 			/*
 			 * Backward compatibility with old DT sources. If the
@@ -2740,6 +2753,12 @@ static const struct acpi_device_id qca_bluetooth_acpi_match[] = {
 MODULE_DEVICE_TABLE(acpi, qca_bluetooth_acpi_match);
 #endif
 
+static const struct serdev_device_id qca_bluetooth_serdev_match[] = {
+	{ "WCN7850", (kernel_ulong_t)&qca_soc_data_wcn7850 },
+	{ },
+};
+MODULE_DEVICE_TABLE(serdev, qca_bluetooth_serdev_match);
+
 #ifdef CONFIG_DEV_COREDUMP
 static void hciqca_coredump(struct device *dev)
 {
@@ -2756,6 +2775,7 @@ static void hciqca_coredump(struct device *dev)
 static struct serdev_device_driver qca_serdev_driver = {
 	.probe = qca_serdev_probe,
 	.remove = qca_serdev_remove,
+	.id_table = qca_bluetooth_serdev_match,
 	.driver = {
 		.name = "hci_uart_qca",
 		.of_match_table = of_match_ptr(qca_bluetooth_of_match),

-- 
2.48.1

