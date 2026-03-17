From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Tue, 17 Mar 2026 09:59:59 +0530
Subject: [PATCH v6 9/9] power: sequencing: pcie-m2: Create serdev device
 for WCN7850 bluetooth
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260317-pci-m2-e-v6-9-9c898f108d3d@oss.qualcomm.com>
References: <20260317-pci-m2-e-v6-0-9c898f108d3d@oss.qualcomm.com>
In-Reply-To: <20260317-pci-m2-e-v6-0-9c898f108d3d@oss.qualcomm.com>
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
 Bartosz Golaszewski <brgl@bgdev.pl>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Bartosz Golaszewski <brgl@kernel.org>
Cc: linux-serial@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kbuild@vger.kernel.org, platform-driver-x86@vger.kernel.org, 
 linux-pci@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-bluetooth@vger.kernel.org, 
 linux-pm@vger.kernel.org, Stephan Gerhold <stephan.gerhold@linaro.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 linux-acpi@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Hans de Goede <johannes.goede@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=8414;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=jB5KOLhGbLaiLJ4bcpaZm55gn4tJXN7qNgKfcUISnKw=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpuNjIclrkVvBY7VCoaNyWVWquJ6Yx78vByyqxa
 bF7t7cJibWJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCabjYyAAKCRBVnxHm/pHO
 9SrXB/0fRpzVbNwF7ayQBLRN8x0cWOsEnBURnG6hWB5LmQUReHrHKokOZ+5aZe3U5b08g4J3hHb
 3R7mzPgZ/U4hna3SS+5LIY9wyaoqqiE9/UGApFkcYQJLAmaeNxgjZLswyKVbC1/kb3nVtPir9p2
 G1aegl+fvPxPhvjzhAJLXlaSlE4yYRYOcGh3LvLzYtaf/Jf+/s5O4wYlxluyD2BCqx2rkmjmHON
 E/wJeMi7eLTByKKzJyPRfxl7NlLQ0CjlhHniu4S7PIuooFI6mmdC+YC3NUHJjQ/C5PeSqYGwcYZ
 sl+GvhX03jHygI8TtWZ+AzsIKtPO1sNlnBk1xVmxjago0zG9
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For supporting bluetooth over the non-discoverable UART interface of
WCN7850, create the serdev device after enumerating the PCIe interface.
This is mandatory since the device ID is only known after the PCIe
enumeration and the ID is used for creating the serdev device.

Since by default there is no OF or ACPI node for the created serdev,
create a dynamic OF 'bluetooth' node with the 'compatible' property and
attach it to the serdev device. This will allow the serdev device to bind
to the existing bluetooth driver.

Tested-by: Hans de Goede <johannes.goede@oss.qualcomm.com> # ThinkPad T14s gen6 (arm64)
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/power/sequencing/Kconfig          |   3 +-
 drivers/power/sequencing/pwrseq-pcie-m2.c | 178 +++++++++++++++++++++++++++++-
 2 files changed, 177 insertions(+), 4 deletions(-)

diff --git a/drivers/power/sequencing/Kconfig b/drivers/power/sequencing/Kconfig
index f5fff84566ba..55aeef125e6f 100644
--- a/drivers/power/sequencing/Kconfig
+++ b/drivers/power/sequencing/Kconfig
@@ -37,7 +37,8 @@ config POWER_SEQUENCING_TH1520_GPU
 
 config POWER_SEQUENCING_PCIE_M2
 	tristate "PCIe M.2 connector power sequencing driver"
-	depends on OF || COMPILE_TEST
+	depends on (PCI && OF) || COMPILE_TEST
+	select OF_DYNAMIC
 	help
 	  Say Y here to enable the power sequencing driver for PCIe M.2
 	  connectors. This driver handles the power sequencing for the M.2
diff --git a/drivers/power/sequencing/pwrseq-pcie-m2.c b/drivers/power/sequencing/pwrseq-pcie-m2.c
index 3507cdcb1e7b..77357439ba81 100644
--- a/drivers/power/sequencing/pwrseq-pcie-m2.c
+++ b/drivers/power/sequencing/pwrseq-pcie-m2.c
@@ -12,9 +12,11 @@
 #include <linux/of.h>
 #include <linux/of_graph.h>
 #include <linux/of_platform.h>
+#include <linux/pci.h>
 #include <linux/platform_device.h>
 #include <linux/pwrseq/provider.h>
 #include <linux/regulator/consumer.h>
+#include <linux/serdev.h>
 #include <linux/slab.h>
 
 struct pwrseq_pcie_m2_pdata {
@@ -30,6 +32,9 @@ struct pwrseq_pcie_m2_ctx {
 	struct notifier_block nb;
 	struct gpio_desc *w_disable1_gpio;
 	struct gpio_desc *w_disable2_gpio;
+	struct serdev_device *serdev;
+	struct of_changeset *ocs;
+	struct device *dev;
 };
 
 static int pwrseq_pcie_m2_vregs_enable(struct pwrseq_device *pwrseq)
@@ -172,13 +177,176 @@ static int pwrseq_pcie_m2_match(struct pwrseq_device *pwrseq,
 	return PWRSEQ_NO_MATCH;
 }
 
-static void pwrseq_pcie_m2_free_regulators(void *data)
+static void pwrseq_pcie_m2_free_resources(void *data)
 {
 	struct pwrseq_pcie_m2_ctx *ctx = data;
 
+	serdev_device_remove(ctx->serdev);
+	bus_unregister_notifier(&pci_bus_type, &ctx->nb);
+	of_changeset_revert(ctx->ocs);
+	of_changeset_destroy(ctx->ocs);
 	regulator_bulk_free(ctx->num_vregs, ctx->regs);
 }
 
+static int pwrseq_m2_pcie_create_bt_node(struct pwrseq_pcie_m2_ctx *ctx,
+					struct device_node *parent)
+{
+	struct device *dev = ctx->dev;
+	struct device_node *np;
+	int ret;
+
+	ctx->ocs = devm_kzalloc(dev, sizeof(*ctx->ocs), GFP_KERNEL);
+	if (!ctx->ocs)
+		return -ENOMEM;
+
+	of_changeset_init(ctx->ocs);
+
+	np = of_changeset_create_node(ctx->ocs, parent, "bluetooth");
+	if (!np) {
+		dev_err(dev, "Failed to create bluetooth node\n");
+		ret = -ENODEV;
+		goto err_destroy_changeset;
+	}
+
+	ret = of_changeset_add_prop_string(ctx->ocs, np, "compatible", "qcom,wcn7850-bt");
+	if (ret) {
+		dev_err(dev, "Failed to add bluetooth compatible: %d\n", ret);
+		goto err_destroy_changeset;
+	}
+
+	ret = of_changeset_apply(ctx->ocs);
+	if (ret) {
+		dev_err(dev, "Failed to apply changeset: %d\n", ret);
+		goto err_destroy_changeset;
+	}
+
+	ret = device_add_of_node(&ctx->serdev->dev, np);
+	if (ret) {
+		dev_err(dev, "Failed to add OF node: %d\n", ret);
+		goto err_revert_changeset;
+	}
+
+	return 0;
+
+err_revert_changeset:
+	of_changeset_revert(ctx->ocs);
+err_destroy_changeset:
+	of_changeset_destroy(ctx->ocs);
+
+	return ret;
+}
+
+static int pwrseq_m2_pcie_notify(struct notifier_block *nb, unsigned long action,
+			      void *data)
+{
+	struct pwrseq_pcie_m2_ctx *ctx = container_of(nb, struct pwrseq_pcie_m2_ctx, nb);
+	struct pci_dev *pdev = to_pci_dev(data);
+	struct serdev_controller *serdev_ctrl;
+	struct device *dev = ctx->dev;
+	int ret;
+
+	/*
+	 * Check whether the PCI device is associated with this M.2 connector or
+	 * not, by comparing the OF node of the PCI device parent and the Port 0
+	 * (PCIe) remote node parent OF node.
+	 */
+	struct device_node *pci_parent __free(device_node) =
+			of_graph_get_remote_node(dev_of_node(ctx->dev), 0, 0);
+	if (!pci_parent || (pci_parent != pdev->dev.parent->of_node))
+		return NOTIFY_DONE;
+
+	switch (action) {
+	case BUS_NOTIFY_ADD_DEVICE:
+		/* Create serdev device for WCN7850 */
+		if (pdev->vendor == PCI_VENDOR_ID_QCOM && pdev->device == 0x1107) {
+			struct device_node *serdev_parent __free(device_node) =
+				of_graph_get_remote_node(dev_of_node(ctx->dev), 1, 1);
+			if (!serdev_parent)
+				return NOTIFY_DONE;
+
+			serdev_ctrl = of_find_serdev_controller_by_node(serdev_parent);
+			if (!serdev_ctrl)
+				return NOTIFY_DONE;
+
+			/*
+			 * Bail out if the device was already attached to this
+			 * controller.
+			 */
+			if (serdev_ctrl->serdev)
+				return NOTIFY_DONE;
+
+			ctx->serdev = serdev_device_alloc(serdev_ctrl);
+			if (!ctx->serdev)
+				return NOTIFY_BAD;
+
+			ret = pwrseq_m2_pcie_create_bt_node(ctx, serdev_parent);
+			if (ret) {
+				serdev_device_put(ctx->serdev);
+				return notifier_from_errno(ret);
+			}
+
+			ret = serdev_device_add(ctx->serdev);
+			if (ret) {
+				dev_err(dev, "Failed to add serdev for WCN7850: %d\n", ret);
+				of_changeset_revert(ctx->ocs);
+				of_changeset_destroy(ctx->ocs);
+				serdev_device_put(ctx->serdev);
+				return notifier_from_errno(ret);
+			}
+		}
+		break;
+	case BUS_NOTIFY_REMOVED_DEVICE:
+		/* Destroy serdev device for WCN7850 */
+		if (pdev->vendor == PCI_VENDOR_ID_QCOM && pdev->device == 0x1107) {
+			serdev_device_remove(ctx->serdev);
+			of_changeset_revert(ctx->ocs);
+			of_changeset_destroy(ctx->ocs);
+		}
+		break;
+	}
+
+	return NOTIFY_OK;
+}
+
+static bool pwrseq_pcie_m2_check_remote_node(struct device *dev, u8 port, u8 endpoint,
+					     const char *node)
+{
+	struct device_node *remote __free(device_node) =
+			of_graph_get_remote_node(dev_of_node(dev), port, endpoint);
+
+	if (remote && of_node_name_eq(remote, node))
+		return true;
+
+	return false;
+}
+
+/*
+ * If the connector exposes a non-discoverable bus like UART, the respective
+ * protocol device needs to be created manually with the help of the notifier
+ * of the discoverable bus like PCIe.
+ */
+static int pwrseq_pcie_m2_register_notifier(struct pwrseq_pcie_m2_ctx *ctx, struct device *dev)
+{
+	int ret;
+
+	/*
+	 * Register a PCI notifier for Key E connector that has PCIe as Port
+	 * 0/Endpoint 0 interface and Serial as Port 3/Endpoint 0 interface.
+	 */
+	if (pwrseq_pcie_m2_check_remote_node(dev, 3, 0, "serial")) {
+		if (pwrseq_pcie_m2_check_remote_node(dev, 0, 0, "pcie")) {
+			ctx->dev = dev;
+			ctx->nb.notifier_call = pwrseq_m2_pcie_notify;
+			ret = bus_register_notifier(&pci_bus_type, &ctx->nb);
+			if (ret)
+				return dev_err_probe(dev, ret,
+						     "Failed to register notifier for serdev\n");
+		}
+	}
+
+	return 0;
+}
+
 static int pwrseq_pcie_m2_probe(struct platform_device *pdev)
 {
 	struct device *dev = &pdev->dev;
@@ -218,7 +386,7 @@ static int pwrseq_pcie_m2_probe(struct platform_device *pdev)
 
 	ctx->num_vregs = ret;
 
-	ret = devm_add_action_or_reset(dev, pwrseq_pcie_m2_free_regulators, ctx);
+	ret = devm_add_action_or_reset(dev, pwrseq_pcie_m2_free_resources, ctx);
 	if (ret)
 		return ret;
 
@@ -233,7 +401,11 @@ static int pwrseq_pcie_m2_probe(struct platform_device *pdev)
 		return dev_err_probe(dev, PTR_ERR(ctx->pwrseq),
 				     "Failed to register the power sequencer\n");
 
-	return 0;
+	/*
+	 * Register a notifier for creating protocol devices for
+	 * non-discoverable busses like UART.
+	 */
+	return pwrseq_pcie_m2_register_notifier(ctx, dev);
 }
 
 static const struct of_device_id pwrseq_pcie_m2_of_match[] = {

-- 
2.51.0

