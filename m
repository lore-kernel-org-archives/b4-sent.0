From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Tue, 15 Sep 2026 16:24:02 +0200
Subject: [PATCH 1/5] Bluetooth: hci_qca: Add auxiliary driver for PCIe M.2
 modules
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260915-pci-m2-bt-rework-v1-1-3c7d9cf9c010@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=7624;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=RMNCxswJp2WMqpIWCHfQMEALDdHbbIwauyM6oCpia9Q=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqqVUSgiOVkUYUycnwFsQ0RDjbkuR3M10PNZJ5Q
 VoUo7dYsH+JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaqlVEgAKCRBVnxHm/pHO
 9T0YB/9WMjOjLkW2yfbn8QC3FaGPBFsKWeYd7evMln8bkscPdLhaBFKe8KVkC1heBCbXJsVuxYN
 Wsfh02l+Ck1Xi9NTA6MHckPK1AXKNY6bVq2NJVc8f93gSURmSkoEcmhR2+Df4/mn+vIYaZjkDPj
 bkDcLW1j4YHKMGjJVe4lADtFMSKjQLQWT9IvT/6/Up7M1nGZJbwdEeHuSScQfqvG2bD4wXkqOZN
 67W2Ic8OOvx65b1dwKX8r+I0UWP9nN/AJ3eNYgRZuKLK+/W1GkOWO/VxJ8zn+OwbhjhABf6Tl5U
 xPp8ojRto4RatUQasU20PDEY9+/Kqm7FDx2LMOa4Asjlq778
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The QCA2066, WCN6855 and WCN7850 combo modules expose Bluetooth over
UART. Since these modules are attached over PCIe, these are not described
in firmware like devicetree. So these modules are discovered at runtime
over PCIe by the power sequencing driver, which allocates the UART serdev
and creates an auxiliary device carrying that transport and the power
sequencing target to power up the Bluetooth function.

Add an auxiliary driver that binds to this device. It reuses the serdev
provided by the producer, brings up the controller through the existing
UART transport with hci_uart_register_device() and drives power through
the sequencer obtained with devm_pwrseq_get().

Add a shared header describing the auxiliary device so that the power
sequencing driver and hci_qca agree on its layout.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 MAINTAINERS                       |   1 +
 drivers/bluetooth/Kconfig         |   1 +
 drivers/bluetooth/hci_qca.c       | 101 ++++++++++++++++++++++++++++++++++++++
 include/linux/pwrseq/pcie-m2-bt.h |  38 ++++++++++++++
 4 files changed, 141 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 3a19da74d00c..ed0c622fa83f 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -21750,6 +21750,7 @@ S:	Maintained
 F:	Documentation/devicetree/bindings/connector/pcie-m2-e-connector.yaml
 F:	Documentation/devicetree/bindings/connector/pcie-m2-m-connector.yaml
 F:	drivers/power/sequencing/pwrseq-pcie-m2.c
+F:	include/linux/pwrseq/pcie-m2-bt.h
 
 POWER STATE COORDINATION INTERFACE (PSCI)
 M:	Mark Rutland <mark.rutland@arm.com>
diff --git a/drivers/bluetooth/Kconfig b/drivers/bluetooth/Kconfig
index 4e8c24d757e9..3acaec6f90ac 100644
--- a/drivers/bluetooth/Kconfig
+++ b/drivers/bluetooth/Kconfig
@@ -244,6 +244,7 @@ config BT_HCIUART_QCA
 	depends on BT_HCIUART_SERDEV
 	select BT_HCIUART_H4
 	select BT_QCA
+	select AUXILIARY_BUS
 	help
 	  The Qualcomm Atheros protocol supports HCI In-Band Sleep feature
 	  over serial port interface(H4) between controller and host.
diff --git a/drivers/bluetooth/hci_qca.c b/drivers/bluetooth/hci_qca.c
index cfefa8b72e25..15cc6cca9057 100644
--- a/drivers/bluetooth/hci_qca.c
+++ b/drivers/bluetooth/hci_qca.c
@@ -15,6 +15,7 @@
  *  by Maxim Krasnyansky and Marcel Holtmann.
  */
 
+#include <linux/auxiliary_bus.h>
 #include <linux/kernel.h>
 #include <linux/clk.h>
 #include <linux/completion.h>
@@ -29,6 +30,7 @@
 #include <linux/acpi.h>
 #include <linux/platform_device.h>
 #include <linux/pwrseq/consumer.h>
+#include <linux/pwrseq/pcie-m2-bt.h>
 #include <linux/regulator/consumer.h>
 #include <linux/serdev.h>
 #include <linux/string_choices.h>
@@ -2850,15 +2852,114 @@ static struct serdev_device_driver qca_serdev_driver = {
 	},
 };
 
+static int qca_bt_aux_probe(struct auxiliary_device *adev,
+			    const struct auxiliary_device_id *id)
+{
+	struct pcie_m2_bt_auxdev *bt_auxdev = to_pcie_m2_bt_auxdev(adev);
+	struct serdev_device *serdev = bt_auxdev->serdev;
+	const struct qca_device_data *data;
+	struct qca_serdev *qcadev;
+	struct hci_dev *hdev;
+	bool controllable;
+	int err;
+
+	data = (const struct qca_device_data *)id->driver_data;
+	if (!data)
+		return -ENODEV;
+
+	qcadev = devm_kzalloc(&adev->dev, sizeof(*qcadev), GFP_KERNEL);
+	if (!qcadev)
+		return -ENOMEM;
+
+	qcadev->serdev_hu.serdev = serdev;
+	qcadev->btsoc_type = data->soc_type;
+	serdev_device_set_drvdata(serdev, qcadev);
+
+	qcadev->pwrseq = devm_pwrseq_get(&adev->dev, bt_auxdev->pwrseq_target);
+	if (IS_ERR(qcadev->pwrseq))
+		return dev_err_probe(&adev->dev, PTR_ERR(qcadev->pwrseq),
+				     "failed to acquire power sequencer\n");
+
+	/*
+	 * When the host cannot gate the BT power individually, treat it as
+	 * always-on.
+	 */
+	controllable = pwrseq_is_controllable(qcadev->pwrseq);
+	if (!controllable) {
+		pwrseq_enable(qcadev->pwrseq);
+		qcadev->pwrseq = NULL;
+	}
+
+	err = hci_uart_register_device(&qcadev->serdev_hu, &qca_proto);
+	if (err)
+		return dev_err_probe(&adev->dev, err,
+				     "failed to register hci_uart device\n");
+
+	hdev = qcadev->serdev_hu.hdev;
+
+	if (controllable) {
+		hci_set_quirk(hdev, HCI_QUIRK_NON_PERSISTENT_SETUP);
+		hdev->shutdown = qca_hci_shutdown;
+	}
+
+	if (data->capabilities & QCA_CAP_WIDEBAND_SPEECH)
+		hci_set_quirk(hdev, HCI_QUIRK_WIDEBAND_SPEECH_SUPPORTED);
+
+	if (!(data->capabilities & QCA_CAP_VALID_LE_STATES))
+		hci_set_quirk(hdev, HCI_QUIRK_BROKEN_LE_STATES);
+
+	if (data->capabilities & QCA_CAP_HFP_HW_OFFLOAD)
+		qcadev->support_hfp_hw_offload = true;
+
+	auxiliary_set_drvdata(adev, qcadev);
+
+	return 0;
+}
+
+static void qca_bt_aux_remove(struct auxiliary_device *adev)
+{
+	struct qca_serdev *qcadev = auxiliary_get_drvdata(adev);
+
+	hci_uart_unregister_device(&qcadev->serdev_hu);
+}
+
+static const struct auxiliary_device_id qca_bt_aux_id_table[] = {
+	{
+		.name = "pwrseq_pcie_m2.qca2066-bt",
+		.driver_data = (kernel_ulong_t)&qca_soc_data_qca2066,
+	},
+	{
+		.name = "pwrseq_pcie_m2.wcn6855-bt",
+		.driver_data = (kernel_ulong_t)&qca_soc_data_wcn6855,
+	},
+	{
+		.name = "pwrseq_pcie_m2.wcn7850-bt",
+		.driver_data = (kernel_ulong_t)&qca_soc_data_wcn7850,
+	},
+	{ }
+};
+MODULE_DEVICE_TABLE(auxiliary, qca_bt_aux_id_table);
+
+static struct auxiliary_driver qca_bt_aux_driver = {
+	.name = "qca_bt",
+	.probe = qca_bt_aux_probe,
+	.remove = qca_bt_aux_remove,
+	.id_table = qca_bt_aux_id_table,
+};
+
 int __init qca_init(void)
 {
 	serdev_device_driver_register(&qca_serdev_driver);
 
+	auxiliary_driver_register(&qca_bt_aux_driver);
+
 	return hci_uart_register_proto(&qca_proto);
 }
 
 int __exit qca_deinit(void)
 {
+	auxiliary_driver_unregister(&qca_bt_aux_driver);
+
 	serdev_device_driver_unregister(&qca_serdev_driver);
 
 	return hci_uart_unregister_proto(&qca_proto);
diff --git a/include/linux/pwrseq/pcie-m2-bt.h b/include/linux/pwrseq/pcie-m2-bt.h
new file mode 100644
index 000000000000..39e7475d7962
--- /dev/null
+++ b/include/linux/pwrseq/pcie-m2-bt.h
@@ -0,0 +1,38 @@
+/* SPDX-License-Identifier: GPL-2.0-only */
+/*
+ * Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
+ * Author: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
+ */
+
+#ifndef __POWER_SEQUENCING_PCIE_M2_BT_H__
+#define __POWER_SEQUENCING_PCIE_M2_BT_H__
+
+#include <linux/auxiliary_bus.h>
+#include <linux/container_of.h>
+
+struct serdev_device;
+
+/**
+ * struct pcie_m2_bt_auxdev - Auxiliary device for the Bluetooth function of a
+ *                            PCIe M.2 module.
+ * @adev: Auxiliary device.
+ * @serdev: Serdev device representing the UART transport. Allocated and owned
+ *          by the producer (power sequencing driver).
+ * @pwrseq_target: Power sequencing target the consumer requests to power up the
+ *                 Bluetooth function.
+ *
+ * On M.2 modules exposing Bluetooth over UART, the controller is not described
+ * in firmware. The power sequencing driver detects the module over PCIe and
+ * publishes this auxiliary device so that the Bluetooth driver can bind to the
+ * pre-allocated serdev transport and drive power sequencing.
+ */
+struct pcie_m2_bt_auxdev {
+	struct auxiliary_device adev;
+	struct serdev_device *serdev;
+	const char *pwrseq_target;
+};
+
+#define to_pcie_m2_bt_auxdev(_adev) \
+	container_of(_adev, struct pcie_m2_bt_auxdev, adev)
+
+#endif /* __POWER_SEQUENCING_PCIE_M2_BT_H__ */

-- 
2.43.0

