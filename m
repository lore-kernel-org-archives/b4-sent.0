From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Sat, 10 Jan 2026 12:26:32 +0530
Subject: [PATCH v3 14/14] power: sequencing: pcie-m2: Create serdev device
 for WCN7850 bluetooth
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260110-pci-m2-e-v3-14-4faee7d0d5ae@oss.qualcomm.com>
References: <20260110-pci-m2-e-v3-0-4faee7d0d5ae@oss.qualcomm.com>
In-Reply-To: <20260110-pci-m2-e-v3-0-4faee7d0d5ae@oss.qualcomm.com>
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
 Daniel Scally <djrscally@gmail.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>
Cc: linux-serial@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kbuild@vger.kernel.org, platform-driver-x86@vger.kernel.org, 
 linux-pci@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-bluetooth@vger.kernel.org, 
 linux-pm@vger.kernel.org, Stephan Gerhold <stephan.gerhold@linaro.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 linux-acpi@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=5942;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=Vp7zYCRu5g++KTpycV6G46GxYVukXvcLdhL4fCvf0XY=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpYfg++CojcI/ArwvutjAh/aYmpyIOq9cl2wKAe
 28Y/hBJCleJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaWH4PgAKCRBVnxHm/pHO
 9Ql5B/9E1CdAqnK1mNQgswa7wqthDkSc9rCfk/sIks3lGXEgHCzNRoFIxTTAXs8x9BZ7uoUV6Pw
 gsJDjJxoTu1H+qIi7ZWQKMbPIPYZDgD2J+NrccRfcR9T05z8r9T/YESRPMeooyA3LwMoosxgLy0
 EcLU8B+j7nO5KAHKiGGeNt6kP9A2uFZiJlC7G0uZ8NI7n0v+HDXEZ5HY8QSQ5yPCoyI7+rP75ew
 EYlAWhJZzZMfe3fFbCOtEQenFlR+HJARr4s78hWj7XAsKbUTkN0iJNIXXdmAb5EGjsW6d2qArxV
 lterlf/QYVzMwuBnByh/jQ6HHZ8b3ko+MSYmJYmAlNdcDOZh
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For supporting bluetooth over the non-discoverable UART interface of
WCN7850, create the serdev device after enumerating the PCIe interface.
This is mandatory since the device ID is only known after the PCIe
enumeration and the ID is used for creating the serdev device.

Since there is no OF or ACPI table for the created serdev, a software node
is created with the 'compatible' property. This property will be used to
match the existing OF device id in the bluetooth driver.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/power/sequencing/pwrseq-pcie-m2.c | 125 +++++++++++++++++++++++++++++-
 1 file changed, 124 insertions(+), 1 deletion(-)

diff --git a/drivers/power/sequencing/pwrseq-pcie-m2.c b/drivers/power/sequencing/pwrseq-pcie-m2.c
index ad94090bbdb2..7c7bde563341 100644
--- a/drivers/power/sequencing/pwrseq-pcie-m2.c
+++ b/drivers/power/sequencing/pwrseq-pcie-m2.c
@@ -17,6 +17,7 @@
 #include <linux/platform_device.h>
 #include <linux/pwrseq/provider.h>
 #include <linux/regulator/consumer.h>
+#include <linux/serdev.h>
 #include <linux/slab.h>
 
 struct pwrseq_pcie_m2_pdata {
@@ -26,11 +27,14 @@ struct pwrseq_pcie_m2_pdata {
 struct pwrseq_pcie_m2_ctx {
 	struct pwrseq_device *pwrseq;
 	struct device_node *of_node;
+	struct fwnode_handle *fwnode;
+	struct serdev_device *serdev;
 	const struct pwrseq_pcie_m2_pdata *pdata;
 	struct regulator_bulk_data *regs;
 	size_t num_vregs;
 	struct gpio_desc *w_disable1_gpio;
 	struct gpio_desc *w_disable2_gpio;
+	struct notifier_block nb;
 	struct device *dev;
 
 };
@@ -179,9 +183,124 @@ static void pwrseq_pcie_free_resources(void *data)
 {
 	struct pwrseq_pcie_m2_ctx *ctx = data;
 
+	fwnode_handle_put(ctx->fwnode);
+	serdev_device_put(ctx->serdev);
+	bus_unregister_notifier(&pci_bus_type, &ctx->nb);
 	regulator_bulk_free(ctx->num_vregs, ctx->regs);
 }
 
+static const struct property_entry wcn7850_bt_props[] = {
+	PROPERTY_ENTRY_STRING("compatible", "qcom,wcn7850-bt"),
+};
+
+static int pwrseq_m2_pcie_notify(struct notifier_block *nb, unsigned long action,
+			      void *data)
+{
+	struct pwrseq_pcie_m2_ctx *ctx = container_of(nb, struct pwrseq_pcie_m2_ctx, nb);
+	struct pci_dev *pdev = to_pci_dev(data);
+	struct serdev_controller *serdev_ctrl;
+	struct device *dev = ctx->dev;
+	struct device_node *remote;
+	int ret;
+
+	/*
+	 * Check whether the PCI device is associated with this M.2 connector or
+	 * not, by comparing the OF node of the PCI device parent and the Port 0
+	 * (PCIe) remote node parent OF node.
+	 */
+	remote = of_graph_get_remote_node(dev_of_node(ctx->dev), 0, 0);
+	if (!remote || (remote != pdev->dev.parent->of_node)) {
+		of_node_put(remote);
+		return NOTIFY_DONE;
+	}
+	of_node_put(remote);
+
+	switch (action) {
+	case BUS_NOTIFY_ADD_DEVICE:
+		/* Create serdev device for WCN7850 */
+		if (pdev->vendor == PCI_VENDOR_ID_QCOM && pdev->device == 0x1107) {
+			remote = of_graph_get_remote_node(dev_of_node(ctx->dev), 1, 1);
+			if (!remote) {
+				of_node_put(remote);
+				return NOTIFY_DONE;
+			}
+
+			serdev_ctrl = of_find_serdev_controller_by_node(remote);
+			of_node_put(remote);
+			if (!serdev_ctrl)
+				return NOTIFY_DONE;
+
+			ctx->serdev = serdev_device_alloc(serdev_ctrl);
+			if (!ctx->serdev)
+				return NOTIFY_BAD;
+
+			ctx->fwnode = fwnode_create_software_node(wcn7850_bt_props, NULL);
+			if (IS_ERR(ctx->fwnode))
+				return notifier_from_errno(PTR_ERR(ctx->fwnode));
+
+			device_set_node(&ctx->serdev->dev, ctx->fwnode);
+
+			ret = serdev_device_add(ctx->serdev);
+			if (ret) {
+				dev_err(dev, "Failed to add serdev for WCN7850: %d\n", ret);
+				fwnode_handle_put(ctx->fwnode);
+				serdev_device_put(ctx->serdev);
+				return notifier_from_errno(ret);
+			}
+		}
+		break;
+	case BUS_NOTIFY_REMOVED_DEVICE:
+		/* Destroy serdev device for WCN7850 */
+		if (pdev->vendor == PCI_VENDOR_ID_QCOM && pdev->device == 0x1107) {
+			fwnode_handle_put(ctx->fwnode);
+			serdev_device_put(ctx->serdev);
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
+	 * 0/Endpoint 0 interface and Serial as Port 1/Endpoint 1 interface.
+	 */
+	if (pwrseq_pcie_m2_check_remote_node(dev, 1, 1, "serial")) {
+		if (pwrseq_pcie_m2_check_remote_node(dev, 0, 0, "pcie")) {
+			ctx->dev = dev;
+			ctx->nb.notifier_call = pwrseq_m2_pcie_notify;
+			ret = bus_register_notifier(&pci_bus_type, &ctx->nb);
+			if (ret) {
+				dev_err_probe(dev, ret, "Failed to register notifier for serdev\n");
+				return ret;
+			}
+		}
+	}
+
+	return 0;
+}
+
 static int pwrseq_pcie_m2_probe(struct platform_device *pdev)
 {
 	struct device *dev = &pdev->dev;
@@ -236,7 +355,11 @@ static int pwrseq_pcie_m2_probe(struct platform_device *pdev)
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
2.48.1

