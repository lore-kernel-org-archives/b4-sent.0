From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Fri, 25 Oct 2024 13:24:54 +0530
Subject: [PATCH v2 4/5] PCI/pwrctl: Move pwrctl device creation to its own
 helper function
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241025-pci-pwrctl-rework-v2-4-568756156cbe@linaro.org>
References: <20241025-pci-pwrctl-rework-v2-0-568756156cbe@linaro.org>
In-Reply-To: <20241025-pci-pwrctl-rework-v2-0-568756156cbe@linaro.org>
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Bartosz Golaszewski <bartosz.golaszewski@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dmitry Baryshkov <dmitry.baryshkov@linaro.org>, 
 Johan Hovold <johan+linaro@kernel.org>, Abel Vesa <abel.vesa@linaro.org>, 
 Stephan Gerhold <stephan.gerhold@linaro.org>, 
 Srinivas Kandagatla <srinivas.kandagatla@linaro.org>, 
 Bjorn Andersson <bjorn.andersson@oss.qualcomm.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 Krishna chaitanya chundru <quic_krichai@quicinc.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=3016;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=umde/gEf3xryIYWhEQXTOZb+OYyr+RucmbbfjNEuNcQ=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnG07UGAg9nkrolL4cB2g9Lnx0saPQGfzOUZKEF
 4f39fULM7uJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZxtO1AAKCRBVnxHm/pHO
 9XIyCACmIiZaGcBALCNfIceqSQuEMavLpnbUGB4PRhmxgVrRK3KsjTE3altX3gKuayVDbA6MR3Z
 YiUMRxKobB14WbeJfc/fRDsre7fZ2+azeqIhWHn+u8UYO7SH7+jOE+hh+9jmwrebUljwPUfz8JH
 +8vK8++I8r4WniCN1YNdSVFJHIIhhG1UAbNsC+1wnoFEuM03eV6J0EQ9+4TB68NzIe2r0laSe0h
 1THtkvz3FZ7xxNR3pX5foODZnCS6KsBzIagXJ2Woiv+gNZ1nkt6A0bFU20MFJj+r+In1XBy79lE
 Ysj3gxw/BxiBmLvcIRKdN9h8CNds8DilRH01bXxFviD4AVYd
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This makes the pci_bus_add_device() API easier to maintain. Also add more
comments to the helper to describe how the devices are created.

Tested-by: Krishna chaitanya chundru <quic_krichai@quicinc.com>
Tested-by: Bartosz Golaszewski <bartosz.golaszewski@linaro.org>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/pci/bus.c | 59 ++++++++++++++++++++++++++++++++++++++-----------------
 1 file changed, 41 insertions(+), 18 deletions(-)

diff --git a/drivers/pci/bus.c b/drivers/pci/bus.c
index 645bbb75f8f9..6e38984e576d 100644
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
+		for_each_available_child_of_node_scoped(np, child) {
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
-		for_each_available_child_of_node_scoped(dn, child) {
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

