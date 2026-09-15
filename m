From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Tue, 15 Sep 2026 16:24:04 +0200
Subject: [PATCH 3/5] power: sequencing: pcie-m2: Create auxiliary device
 for the M.2 BT interface
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260915-pci-m2-bt-rework-v1-3-3c7d9cf9c010@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=9879;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=ysdYQzQTS6vV5RimaY4+yjdKUGeSc5gOn2WXxQ/9ltg=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqqVUSc4FVnWW9dvtIIVeOclToM1k8bzAypjESU
 i2EyBGGkQ6JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaqlVEgAKCRBVnxHm/pHO
 9Q5GB/wNCfs5K5guix1U95aAVoWht4Lu1gHZBDY3WjE5+zxFf9nOqf578hPwLgJtKGy0BjYTi3b
 Jmfg8Kcx8nzV7E0GZdbTvynVtw/PQtv9lTyzWYNBT0zPtg3+SDRYmy6GgPn/Zee90SX04SaJYRr
 MGrEtN1q7oYKLQ8O7nW5mphnUcyEet5/KXygAQYVOQUtJukxtIw9bYpoq+P/WUnXmoCp9FHe2yf
 SPI16DfUgHVosjZeF6OVH8sZoYpBKvrJxB6Zd/VAdM1mrbVqAqZt1S/Sv4jpgsgnBpX13nDXWTT
 MubVjkOVSatWDHA8Fi3wLNPn8wUI59WH36EQy5BPgS8x0tej
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, the driver instantiates the BT interface of the WCN6855 and
WCN7850 combo modules by creating a devicetree node at runtime using an
of_changeset, with the compatible passed through the PCI ID table. But this
method of creating a devicetree node just for matching with the driver is
not recommended.

So create an auxiliary device for the BT interface instead. The serdev
transport is still allocated here and handed over to the Bluetooth driver
through the auxiliary device, along with the power sequencing target used
to power up the controller. Also extend the provider match so that the
auxiliary device created for this connector is matched as its power
sequencing consumer.

Since the runtime node creation is now gone, select AUXILIARY_BUS in
place of OF_DYNAMIC.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/power/sequencing/Kconfig          |   2 +-
 drivers/power/sequencing/pwrseq-pcie-m2.c | 137 ++++++++++++++++--------------
 2 files changed, 75 insertions(+), 64 deletions(-)

diff --git a/drivers/power/sequencing/Kconfig b/drivers/power/sequencing/Kconfig
index 1c5f5820f5b7..2943af5db135 100644
--- a/drivers/power/sequencing/Kconfig
+++ b/drivers/power/sequencing/Kconfig
@@ -40,7 +40,7 @@ config POWER_SEQUENCING_PCIE_M2
 	depends on OF
 	depends on PCI
 	depends on SERIAL_DEV_BUS
-	select OF_DYNAMIC
+	select AUXILIARY_BUS
 	help
 	  Say Y here to enable the power sequencing driver for PCIe M.2
 	  connectors. This driver handles the power sequencing for the M.2
diff --git a/drivers/power/sequencing/pwrseq-pcie-m2.c b/drivers/power/sequencing/pwrseq-pcie-m2.c
index bee1aa0e077d..9e485641695c 100644
--- a/drivers/power/sequencing/pwrseq-pcie-m2.c
+++ b/drivers/power/sequencing/pwrseq-pcie-m2.c
@@ -4,16 +4,18 @@
  * Author: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
  */
 
+#include <linux/auxiliary_bus.h>
 #include <linux/device.h>
 #include <linux/delay.h>
 #include <linux/gpio/consumer.h>
+#include <linux/idr.h>
 #include <linux/list.h>
 #include <linux/module.h>
 #include <linux/of.h>
 #include <linux/of_graph.h>
-#include <linux/of_platform.h>
 #include <linux/pci.h>
 #include <linux/platform_device.h>
+#include <linux/pwrseq/pcie-m2-bt.h>
 #include <linux/pwrseq/provider.h>
 #include <linux/regulator/consumer.h>
 #include <linux/serdev.h>
@@ -21,7 +23,7 @@
 
 struct pwrseq_pci_dev {
 	struct serdev_device *serdev;
-	struct of_changeset *ocs;
+	struct pcie_m2_bt_auxdev *bt;
 	struct pci_dev *pdev;
 	struct list_head list;
 };
@@ -196,6 +198,14 @@ static int pwrseq_pcie_m2_match(struct pwrseq_device *pwrseq,
 	struct pwrseq_pcie_m2_ctx *ctx = pwrseq_device_get_drvdata(pwrseq);
 	struct device_node *endpoint __free(device_node) = NULL;
 
+	/*
+	 * The Bluetooth function is represented by an auxiliary device created
+	 * by this driver. It has no OF node, so match it by verifying that it
+	 * is a child of this connector.
+	 */
+	if (dev_is_auxiliary(dev) && dev->parent == ctx->dev)
+		return PWRSEQ_MATCH_OK;
+
 	/*
 	 * Traverse the 'remote-endpoint' nodes and check if the remote node's
 	 * parent matches the OF node of 'dev'.
@@ -210,78 +220,86 @@ static int pwrseq_pcie_m2_match(struct pwrseq_device *pwrseq,
 	return PWRSEQ_NO_MATCH;
 }
 
+/*
+ * The Bluetooth interface of a supported module is exposed as an auxiliary
+ * device. Its name (combined with this driver's module name) is matched by
+ * the Bluetooth driver. Store that name as the PCI ID driver data.
+ */
 static const struct pci_device_id pwrseq_m2_pci_ids[] = {
 	{ PCI_DEVICE(PCI_VENDOR_ID_MARVELL_EXT, 0x2b43),
-	  .driver_data = (kernel_ulong_t)"nxp,88w8987-bt" },
+	  .driver_data = (kernel_ulong_t)"88w8987-bt" },
 	{ PCI_DEVICE(PCI_VENDOR_ID_PHILIPS, 0x3003),
-	  .driver_data = (kernel_ulong_t)"nxp,88w8987-bt" },
+	  .driver_data = (kernel_ulong_t)"88w8987-bt" },
 	{ PCI_DEVICE_SUB(PCI_VENDOR_ID_QCOM, 0x1103, PCI_VENDOR_ID_QCOM, 0x0108),
-	  .driver_data = (kernel_ulong_t)"qcom,qca2066-bt" },
+	  .driver_data = (kernel_ulong_t)"qca2066-bt" },
 	{ PCI_DEVICE_SUB(PCI_VENDOR_ID_QCOM, 0x1103, PCI_VENDOR_ID_FOXCONN, 0xe105),
-	  .driver_data = (kernel_ulong_t)"qcom,wcn6855-bt" },
+	  .driver_data = (kernel_ulong_t)"wcn6855-bt" },
 	{ PCI_DEVICE_SUB(PCI_VENDOR_ID_QCOM, 0x1103, PCI_VENDOR_ID_QCOM, 0x337e),
-	  .driver_data = (kernel_ulong_t)"qcom,wcn6855-bt" },
+	  .driver_data = (kernel_ulong_t)"wcn6855-bt" },
 	{ PCI_DEVICE_SUB(PCI_VENDOR_ID_QCOM, 0x1107, PCI_VENDOR_ID_QCOM, 0x337c),
-	  .driver_data = (kernel_ulong_t)"qcom,wcn7850-bt" },
+	  .driver_data = (kernel_ulong_t)"wcn7850-bt" },
 	{ } /* Sentinel */
 };
 
-static int pwrseq_pcie_m2_create_bt_node(struct pwrseq_pcie_m2_ctx *ctx,
+static DEFINE_IDA(pwrseq_pcie_m2_bt_ida);
+
+static void pwrseq_pcie_m2_bt_release(struct device *dev)
+{
+	struct pcie_m2_bt_auxdev *bt =
+		to_pcie_m2_bt_auxdev(to_auxiliary_dev(dev));
+
+	ida_free(&pwrseq_pcie_m2_bt_ida, bt->adev.id);
+	kfree(bt);
+}
+
+static int pwrseq_pcie_m2_create_bt_aux(struct pwrseq_pcie_m2_ctx *ctx,
 					struct pwrseq_pci_dev *pci_dev,
-					struct device_node *parent,
 					struct pci_dev *pdev)
 {
 	const struct pci_device_id *id;
 	struct device *dev = ctx->dev;
-	const char *compatible;
-	struct device_node *np;
+	struct pcie_m2_bt_auxdev *bt;
 	int ret;
 
 	id = pci_match_id(pwrseq_m2_pci_ids, pdev);
 	if (WARN_ON_ONCE(!id)) /* Shouldn't happen */
 		return -ENODEV;
 
-	compatible = (const char *)id->driver_data;
-
-	pci_dev->ocs = kzalloc_obj(*pci_dev->ocs);
-	if (!pci_dev->ocs)
+	bt = kzalloc_obj(*bt);
+	if (!bt)
 		return -ENOMEM;
 
-	of_changeset_init(pci_dev->ocs);
+	ret = ida_alloc(&pwrseq_pcie_m2_bt_ida, GFP_KERNEL);
+	if (ret < 0)
+		goto err_free_bt;
 
-	np = of_changeset_create_node(pci_dev->ocs, parent, "bluetooth");
-	if (!np) {
-		dev_err(dev, "Failed to create bluetooth node\n");
-		ret = -ENODEV;
-		goto err_destroy_changeset;
-	}
+	bt->serdev = pci_dev->serdev;
+	bt->pwrseq_target = "uart";
+	bt->adev.id = ret;
+	bt->adev.name = (const char *)id->driver_data;
+	bt->adev.dev.parent = dev;
+	bt->adev.dev.release = pwrseq_pcie_m2_bt_release;
 
-	ret = of_changeset_add_prop_string(pci_dev->ocs, np, "compatible", compatible);
-	if (ret) {
-		dev_err(dev, "Failed to add bluetooth compatible: %d\n", ret);
-		goto err_destroy_changeset;
-	}
+	ret = auxiliary_device_init(&bt->adev);
+	if (ret)
+		goto err_free_ida;
 
-	ret = of_changeset_apply(pci_dev->ocs);
+	ret = auxiliary_device_add(&bt->adev);
 	if (ret) {
-		dev_err(dev, "Failed to apply changeset: %d\n", ret);
-		goto err_destroy_changeset;
+		dev_err(dev, "Failed to add bluetooth auxiliary device: %d\n",
+			ret);
+		auxiliary_device_uninit(&bt->adev);
+		return ret;
 	}
 
-	ret = device_add_of_node(&pci_dev->serdev->dev, np);
-	if (ret) {
-		dev_err(dev, "Failed to add OF node: %d\n", ret);
-		goto err_revert_changeset;
-	}
+	pci_dev->bt = bt;
 
 	return 0;
 
-err_revert_changeset:
-	of_changeset_revert(pci_dev->ocs);
-err_destroy_changeset:
-	of_changeset_destroy(pci_dev->ocs);
-	kfree(pci_dev->ocs);
-	pci_dev->ocs = NULL;
+err_free_ida:
+	ida_free(&pwrseq_pcie_m2_bt_ida, bt->adev.id);
+err_free_bt:
+	kfree(bt);
 
 	return ret;
 }
@@ -329,17 +347,17 @@ static int pwrseq_pcie_m2_create_serdev_one(struct pwrseq_pcie_m2_ctx *ctx,
 		goto err_free_pci_dev;
 	}
 
-	ret = pwrseq_pcie_m2_create_bt_node(ctx, pci_dev, serdev_parent, pdev);
-	if (ret)
-		goto err_free_serdev;
-
 	ret = serdev_device_add(pci_dev->serdev);
 	if (ret) {
 		dev_err(dev, "Failed to add serdev for PCI device (%s): %d\n",
 			pci_name(pdev), ret);
-		goto err_free_dt_node;
+		goto err_free_serdev;
 	}
 
+	ret = pwrseq_pcie_m2_create_bt_aux(ctx, pci_dev, pdev);
+	if (ret)
+		goto err_remove_serdev;
+
 	serdev_controller_put(serdev_ctrl);
 
 	pci_dev->pdev = pci_dev_get(pdev);
@@ -350,15 +368,11 @@ static int pwrseq_pcie_m2_create_serdev_one(struct pwrseq_pcie_m2_ctx *ctx,
 
 	return 0;
 
-err_free_dt_node:
-	device_remove_of_node(&pci_dev->serdev->dev);
-	of_changeset_revert(pci_dev->ocs);
-	of_changeset_destroy(pci_dev->ocs);
-	kfree(pci_dev->ocs);
-	pci_dev->ocs = NULL;
+err_remove_serdev:
+	serdev_device_remove(pci_dev->serdev);
+	goto err_free_pci_dev;
 err_free_serdev:
 	serdev_device_put(pci_dev->serdev);
-	pci_dev->serdev = NULL;
 err_free_pci_dev:
 	kfree(pci_dev);
 err_put_ctrl:
@@ -370,16 +384,13 @@ static int pwrseq_pcie_m2_create_serdev_one(struct pwrseq_pcie_m2_ctx *ctx,
 static void __pwrseq_pcie_m2_remove_serdev(struct pwrseq_pcie_m2_ctx *ctx,
 					   struct pwrseq_pci_dev *pci_dev)
 {
-	if (pci_dev->serdev) {
-		device_remove_of_node(&pci_dev->serdev->dev);
-		serdev_device_remove(pci_dev->serdev);
+	if (pci_dev->bt) {
+		auxiliary_device_delete(&pci_dev->bt->adev);
+		auxiliary_device_uninit(&pci_dev->bt->adev);
 	}
 
-	if (pci_dev->ocs) {
-		of_changeset_revert(pci_dev->ocs);
-		of_changeset_destroy(pci_dev->ocs);
-		kfree(pci_dev->ocs);
-	}
+	if (pci_dev->serdev)
+		serdev_device_remove(pci_dev->serdev);
 
 	pci_dev_put(pci_dev->pdev);
 	list_del(&pci_dev->list);
@@ -526,6 +537,7 @@ static int pwrseq_pcie_m2_probe(struct platform_device *pdev)
 		return -ENOMEM;
 
 	platform_set_drvdata(pdev, ctx);
+	ctx->dev = dev;
 	ctx->of_node = dev_of_node(dev);
 	ctx->pdata = device_get_match_data(dev);
 	if (!ctx->pdata)
@@ -573,7 +585,6 @@ static int pwrseq_pcie_m2_probe(struct platform_device *pdev)
 
 	mutex_init(&ctx->list_lock);
 	INIT_LIST_HEAD(&ctx->pci_devices);
-	ctx->dev = dev;
 
 	/* Create serdev for available PCI devices (if required) */
 	ret = pwrseq_pcie_m2_create_serdev(ctx);

-- 
2.43.0

