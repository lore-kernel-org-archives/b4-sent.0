From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Tue, 22 Oct 2024 15:57:32 +0530
Subject: [PATCH 4/5] PCI/pwrctl: Move pwrctl device creation to its own
 helper function
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241022-pci-pwrctl-rework-v1-4-94a7e90f58c5@linaro.org>
References: <20241022-pci-pwrctl-rework-v1-0-94a7e90f58c5@linaro.org>
In-Reply-To: <20241022-pci-pwrctl-rework-v1-0-94a7e90f58c5@linaro.org>
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Bartosz Golaszewski <bartosz.golaszewski@linaro.org>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dmitry Baryshkov <dmitry.baryshkov@linaro.org>, 
 Johan Hovold <johan+linaro@kernel.org>, Abel Vesa <abel.vesa@linaro.org>, 
 Stephan Gerhold <stephan.gerhold@linaro.org>, 
 Srinivas Kandagatla <srinivas.kandagatla@linaro.org>, 
 Bjorn Andersson <bjorn.andersson@oss.qualcomm.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=2866;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=ysOLKy+185AD3GOipcG2TEA807qZUk22GeUQ5Y6pe4o=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnF34vmsof+M+5wL5XmngmSZCCByb+moVH/g2gE
 BwhvmPs2BiJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZxd+LwAKCRBVnxHm/pHO
 9RUxB/9DKZS3wBi+FU7eP7EVhMTHc/nh9MECM0XNE1queAtb+/Si7BtnEdjcqvRwamCngW/kN0R
 q8U9RflthcVPaEor0YjkTnlPMM49we3BVurBjFoZp833MNguajLNFZJlC5308PwNEuxBfPfkRny
 jjZACCHEWlxya5zXo5YjqbQpsp71GtpuqqlQbU9bAUFwAdd0Pk8ygGygSZ47awBmhuyUGLUsm0Z
 2qwuluPr00FNCLDRqtBbw4p6EnlJztA9DX1EdeXj7oYXa30GA+1gKUEk1MBcYmQyFm+mC7OhJRz
 ZPdOVSoenL2EiN2B2i9vDphxWm3XFnVHb2L1RZm011JfFtnY
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This makes the pci_bus_add_device() API easier to maintain. Also add more
comments to the helper to describe how the devices are created.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/pci/bus.c | 59 ++++++++++++++++++++++++++++++++++++++-----------------
 1 file changed, 41 insertions(+), 18 deletions(-)

diff --git a/drivers/pci/bus.c b/drivers/pci/bus.c
index 351af581904f..c4cae1775c9e 100644
--- a/drivers/pci/bus.c
+++ b/drivers/pci/bus.c
@@ -321,6 +321,46 @@ void __weak pcibios_resource_survey_bus(struct pci_bus *bus) { }
 
 void __weak pcibios_bus_add_device(struct pci_dev *pdev) { }
 
+/*
+ * Create pwrctl devices (if required) for the PCI devices to handle the power
+ * state.
+ */
+static void pci_pwrctl_create_devices(struct pci_dev *dev)
+{
+	struct device_node *np = dev_of_node(&dev->dev);
+	struct device *parent = &dev->dev;
+	struct platform_device *pdev;
+
+	/*
+	 * First ensure that we are starting from a PCI bridge and it has a
+	 * corresponding devicetree node.
+	 */
+	if (np && pci_is_bridge(dev)) {
+		/*
+		 * Now look for the child PCI device nodes and create pwrctl
+		 * devices for them. The pwrctl device drivers will manage the
+		 * power state of the devices.
+		 */
+		for_each_child_of_node_scoped(np, child) {
+			/*
+			 * First check whether the pwrctl device really needs to
+			 * be created or not. This is decided based on at least
+			 * one of the power supplies being defined in the
+			 * devicetree node of the device.
+			 */
+			if (!of_pci_is_supply_present(child)) {
+				pci_dbg(dev, "skipping OF node: %s\n", child->name);
+				return;
+			}
+
+			/* Now create the pwrctl device */
+			pdev = of_platform_device_create(child, NULL, parent);
+			if (!pdev)
+				pci_err(dev, "failed to create OF node: %s\n", child->name);
+		}
+	}
+}
+
 /**
  * pci_bus_add_device - start driver for a single device
  * @dev: device to add
@@ -345,24 +385,7 @@ void pci_bus_add_device(struct pci_dev *dev)
 	pci_proc_attach_device(dev);
 	pci_bridge_d3_update(dev);
 
-	if (dev_of_node(&dev->dev) && pci_is_bridge(dev)) {
-		for_each_child_of_node_scoped(dn, child) {
-			/*
-			 * First check whether the pwrctl device needs to be
-			 * created or not. This is decided based on at least
-			 * one of the power supplies being defined in the
-			 * devicetree node of the device.
-			 */
-			if (!of_pci_is_supply_present(child)) {
-				pci_dbg(dev, "skipping OF node: %s\n", child->name);
-				continue;
-			}
-
-			pdev = of_platform_device_create(child, NULL, &dev->dev);
-			if (!pdev)
-				pci_err(dev, "failed to create OF node: %s\n", child->name);
-		}
-	}
+	pci_pwrctl_create_devices(dev);
 
 	/*
 	 * Create a device link between the PCI device and pwrctl device (if

-- 
2.25.1

