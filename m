From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Tue, 15 Sep 2026 16:24:03 +0200
Subject: [PATCH 2/5] Bluetooth: btnxpuart: Add auxiliary driver for PCIe
 M.2 modules
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260915-pci-m2-bt-rework-v1-2-3c7d9cf9c010@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=9263;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=7K0wcp3nNpEPO5o8mNQzwNVqWyirfaYgXDqIo4bzR5Q=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqqVUS2pxxHoNixyL/9U7DgyQwmVwge6LQUfwyC
 LWe0AGfW42JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaqlVEgAKCRBVnxHm/pHO
 9bPPCACJcgH6EUBoOGFfvp+muG3R//l4bMey4PrU72tB5LlCIoXJf+YO8IpRiuuEYpxvhUSoTqT
 76CMvodhayYyuvym53u/5XWF3RPqhIAySPxlQWDFGrgOx8fs4Bc3HnrreFUtYCS+qlU4MnfqEkL
 KLmVfiL0X8NfiDqRMYHRIskgmOUtuAGnOCs2Nok8B2t5TqHdDmhxxVLWsDlDXpfXuWtWDhk1U0C
 Jccaq85Lw7YaAkWwrl740Xe6oW90s3VGexjaEqORvTpxpjNGWV8vi5jbvqdRUG0ES/12trt2Rwk
 pw+gkBCAdNi4u0qbZfBN1rRJs2cuTlAY3SeYkkGfq40n6AhS
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The 88W8987 combo module exposes Bluetooth over UART. Since this module is
attached over PCIe, it is not described in firmware like devicetree. So it
is discovered at runtime over PCIe by the power sequencing driver, which
allocates the UART serdev and creates an auxiliary device carrying that
transport and the power sequencing target to power up the Bluetooth
function.

Add an auxiliary driver that binds to this device. It reuses the serdev
provided by the producer, brings up the controller through the existing
UART transport with nxp_register_dev() and drives power through the
sequencer obtained with pwrseq_get().

Factor the HCI device setup and teardown shared with the serdev probe into
helpers so both paths register the same controller.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/bluetooth/Kconfig     |   1 +
 drivers/bluetooth/btnxpuart.c | 187 +++++++++++++++++++++++++++++++++---------
 2 files changed, 147 insertions(+), 41 deletions(-)

diff --git a/drivers/bluetooth/Kconfig b/drivers/bluetooth/Kconfig
index 3acaec6f90ac..ce0cf50b663b 100644
--- a/drivers/bluetooth/Kconfig
+++ b/drivers/bluetooth/Kconfig
@@ -454,6 +454,7 @@ config BT_NXPUART
 	select BT_HCIUART_H4
 	select CRC32
 	select CRC8
+	select AUXILIARY_BUS
 	help
 	  NXP is serial driver required for NXP Bluetooth
 	  devices with UART interface.
diff --git a/drivers/bluetooth/btnxpuart.c b/drivers/bluetooth/btnxpuart.c
index 25e7b41b349f..2672e481ef15 100644
--- a/drivers/bluetooth/btnxpuart.c
+++ b/drivers/bluetooth/btnxpuart.c
@@ -7,10 +7,12 @@
 #include <linux/module.h>
 #include <linux/kernel.h>
 
+#include <linux/auxiliary_bus.h>
 #include <linux/serdev.h>
 #include <linux/of.h>
 #include <linux/of_graph.h>
 #include <linux/pwrseq/consumer.h>
+#include <linux/pwrseq/pcie-m2-bt.h>
 #include <linux/skbuff.h>
 #include <linux/unaligned.h>
 #include <linux/firmware.h>
@@ -1840,20 +1842,13 @@ static bool nxp_m2_connector_is_available(struct device *dev)
 	return remote && of_device_is_available(remote);
 }
 
-static int nxp_serdev_probe(struct serdev_device *serdev)
+static int nxp_register_dev(struct btnxpuart_dev *nxpdev)
 {
+	struct serdev_device *serdev = nxpdev->serdev;
 	struct hci_dev *hdev;
-	struct btnxpuart_dev *nxpdev;
 	bdaddr_t ba = {0};
 	int err;
 
-	nxpdev = devm_kzalloc(&serdev->dev, sizeof(*nxpdev), GFP_KERNEL);
-	if (!nxpdev)
-		return -ENOMEM;
-
-	nxpdev->nxp_data = (struct btnxpuart_data *)device_get_match_data(&serdev->dev);
-
-	nxpdev->serdev = serdev;
 	serdev_device_set_drvdata(serdev, nxpdev);
 
 	serdev_device_set_client_ops(serdev, &btnxpuart_client_ops);
@@ -1864,12 +1859,12 @@ static int nxp_serdev_probe(struct serdev_device *serdev)
 	init_waitqueue_head(&nxpdev->fw_dnld_done_wait_q);
 	init_waitqueue_head(&nxpdev->check_boot_sign_wait_q);
 
-	device_property_read_u32(&nxpdev->serdev->dev, "fw-init-baudrate",
+	device_property_read_u32(&serdev->dev, "fw-init-baudrate",
 				 &nxpdev->fw_init_baudrate);
 	if (!nxpdev->fw_init_baudrate)
 		nxpdev->fw_init_baudrate = FW_INIT_BAUDRATE;
 
-	device_property_read_u32(&nxpdev->serdev->dev, "max-speed",
+	device_property_read_u32(&serdev->dev, "max-speed",
 				 &nxpdev->secondary_baudrate);
 	if (!nxpdev->secondary_baudrate ||
 	    (nxpdev->secondary_baudrate != HCI_NXP_SEC_BAUDRATE_3M &&
@@ -1884,36 +1879,11 @@ static int nxp_serdev_probe(struct serdev_device *serdev)
 
 	crc8_populate_msb(crc8_table, POLYNOMIAL8);
 
-	nxpdev->pdn = devm_reset_control_get_optional_shared(&serdev->dev, NULL);
-	if (IS_ERR(nxpdev->pdn))
-		return PTR_ERR(nxpdev->pdn);
-
-	err = devm_regulator_get_enable(&serdev->dev, "vcc");
-	if (err) {
-		dev_err(&serdev->dev, "Failed to enable vcc regulator\n");
-		return err;
-	}
-
-	if (nxp_m2_connector_is_available(&serdev->ctrl->dev)) {
-		struct pwrseq_desc *pwrseq;
-
-		pwrseq = pwrseq_get(&serdev->ctrl->dev, "uart");
-		if (IS_ERR(pwrseq))
-			return dev_err_probe(&serdev->dev, PTR_ERR(pwrseq),
-					     "failed to get pwrseq\n");
-
-		nxpdev->pwrseq = pwrseq;
-		err = pwrseq_enable(pwrseq);
-		if (err)
-			goto err_pwrseq_put;
-	}
-
 	/* Initialize and register HCI device */
 	hdev = hci_alloc_dev();
 	if (!hdev) {
 		dev_err(&serdev->dev, "Can't allocate HCI device\n");
-		err = -ENOMEM;
-		goto err_pwrseq_put;
+		return -ENOMEM;
 	}
 
 	reset_control_deassert(nxpdev->pdn);
@@ -1938,7 +1908,7 @@ static int nxp_serdev_probe(struct serdev_device *serdev)
 	hdev->set_bdaddr = nxp_set_bdaddr;
 	SET_HCIDEV_DEV(hdev, &serdev->dev);
 
-	device_property_read_u8_array(&nxpdev->serdev->dev,
+	device_property_read_u8_array(&serdev->dev,
 				      "local-bd-address",
 				      (u8 *)&ba, sizeof(ba));
 	if (bacmp(&ba, BDADDR_ANY))
@@ -1965,15 +1935,61 @@ static int nxp_serdev_probe(struct serdev_device *serdev)
 probe_fail:
 	reset_control_assert(nxpdev->pdn);
 	hci_free_dev(hdev);
+
+	return err;
+}
+
+static int nxp_serdev_probe(struct serdev_device *serdev)
+{
+	struct btnxpuart_dev *nxpdev;
+	int err;
+
+	nxpdev = devm_kzalloc(&serdev->dev, sizeof(*nxpdev), GFP_KERNEL);
+	if (!nxpdev)
+		return -ENOMEM;
+
+	nxpdev->nxp_data = (struct btnxpuart_data *)device_get_match_data(&serdev->dev);
+
+	nxpdev->serdev = serdev;
+
+	nxpdev->pdn = devm_reset_control_get_optional_shared(&serdev->dev, NULL);
+	if (IS_ERR(nxpdev->pdn))
+		return PTR_ERR(nxpdev->pdn);
+
+	err = devm_regulator_get_enable(&serdev->dev, "vcc");
+	if (err) {
+		dev_err(&serdev->dev, "Failed to enable vcc regulator\n");
+		return err;
+	}
+
+	if (nxp_m2_connector_is_available(&serdev->ctrl->dev)) {
+		struct pwrseq_desc *pwrseq;
+
+		pwrseq = pwrseq_get(&serdev->ctrl->dev, "uart");
+		if (IS_ERR(pwrseq))
+			return dev_err_probe(&serdev->dev, PTR_ERR(pwrseq),
+					     "failed to get pwrseq\n");
+
+		nxpdev->pwrseq = pwrseq;
+		err = pwrseq_enable(pwrseq);
+		if (err)
+			goto err_pwrseq_put;
+	}
+
+	err = nxp_register_dev(nxpdev);
+	if (err)
+		goto err_pwrseq_put;
+
+	return 0;
+
 err_pwrseq_put:
 	if (nxpdev->pwrseq)
 		pwrseq_put(nxpdev->pwrseq);
 	return err;
 }
 
-static void nxp_serdev_remove(struct serdev_device *serdev)
+static void __nxp_remove(struct btnxpuart_dev *nxpdev)
 {
-	struct btnxpuart_dev *nxpdev = serdev_device_get_drvdata(serdev);
 	struct hci_dev *hdev = nxpdev->hdev;
 
 	if (is_fw_downloading(nxpdev)) {
@@ -2000,6 +2016,58 @@ static void nxp_serdev_remove(struct serdev_device *serdev)
 	hci_free_dev(hdev);
 }
 
+static void nxp_serdev_remove(struct serdev_device *serdev)
+{
+	struct btnxpuart_dev *nxpdev = serdev_device_get_drvdata(serdev);
+
+	__nxp_remove(nxpdev);
+}
+
+static int nxp_bt_aux_probe(struct auxiliary_device *adev,
+			    const struct auxiliary_device_id *id)
+{
+	struct pcie_m2_bt_auxdev *bt_auxdev = to_pcie_m2_bt_auxdev(adev);
+	struct btnxpuart_dev *nxpdev;
+	struct pwrseq_desc *pwrseq;
+	int err;
+
+	nxpdev = devm_kzalloc(&adev->dev, sizeof(*nxpdev), GFP_KERNEL);
+	if (!nxpdev)
+		return -ENOMEM;
+
+	nxpdev->nxp_data = (struct btnxpuart_data *)id->driver_data;
+	nxpdev->serdev = bt_auxdev->serdev;
+
+	pwrseq = pwrseq_get(&adev->dev, bt_auxdev->pwrseq_target);
+	if (IS_ERR(pwrseq))
+		return dev_err_probe(&adev->dev, PTR_ERR(pwrseq),
+				     "failed to get pwrseq\n");
+
+	nxpdev->pwrseq = pwrseq;
+	err = pwrseq_enable(pwrseq);
+	if (err)
+		goto err_pwrseq_put;
+
+	err = nxp_register_dev(nxpdev);
+	if (err)
+		goto err_pwrseq_put;
+
+	auxiliary_set_drvdata(adev, nxpdev);
+
+	return 0;
+
+err_pwrseq_put:
+	pwrseq_put(nxpdev->pwrseq);
+	return err;
+}
+
+static void nxp_bt_aux_remove(struct auxiliary_device *adev)
+{
+	struct btnxpuart_dev *nxpdev = auxiliary_get_drvdata(adev);
+
+	__nxp_remove(nxpdev);
+}
+
 static int __maybe_unused nxp_serdev_suspend(struct device *dev)
 {
 	struct btnxpuart_dev *nxpdev = dev_get_drvdata(dev);
@@ -2075,7 +2143,44 @@ static struct serdev_device_driver nxp_serdev_driver = {
 	},
 };
 
-module_serdev_device_driver(nxp_serdev_driver);
+static const struct auxiliary_device_id nxp_bt_aux_id_table[] = {
+	{
+		.name = "pwrseq_pcie_m2.88w8987-bt",
+		.driver_data = (kernel_ulong_t)&w8987_data,
+	},
+	{ }
+};
+MODULE_DEVICE_TABLE(auxiliary, nxp_bt_aux_id_table);
+
+static struct auxiliary_driver nxp_bt_aux_driver = {
+	.name = "nxp_bt",
+	.probe = nxp_bt_aux_probe,
+	.remove = nxp_bt_aux_remove,
+	.id_table = nxp_bt_aux_id_table,
+};
+
+static int __init nxp_bt_init(void)
+{
+	int err;
+
+	err = serdev_device_driver_register(&nxp_serdev_driver);
+	if (err)
+		return err;
+
+	err = auxiliary_driver_register(&nxp_bt_aux_driver);
+	if (err)
+		serdev_device_driver_unregister(&nxp_serdev_driver);
+
+	return err;
+}
+module_init(nxp_bt_init);
+
+static void __exit nxp_bt_exit(void)
+{
+	auxiliary_driver_unregister(&nxp_bt_aux_driver);
+	serdev_device_driver_unregister(&nxp_serdev_driver);
+}
+module_exit(nxp_bt_exit);
 
 MODULE_AUTHOR("Neeraj Sanjay Kale <neeraj.sanjaykale@nxp.com>");
 MODULE_DESCRIPTION("NXP Bluetooth Serial driver");

-- 
2.43.0

