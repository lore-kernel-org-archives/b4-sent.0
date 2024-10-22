From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Tue, 22 Oct 2024 15:57:30 +0530
Subject: [PATCH 2/5] PCI/pwrctl: Create pwrctl devices only if at least one
 power supply is present
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241022-pci-pwrctl-rework-v1-2-94a7e90f58c5@linaro.org>
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
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 stable+noautosel@kernel.org
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=3545;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=oJ/OQynblPqFLnYyBuZFpwZHxzKNTbVvMhdHbuUg+mY=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnF34u3E/YNcybcWcET91/0zg1s6CUet/6wi8CR
 JW3UcOvPZyJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZxd+LgAKCRBVnxHm/pHO
 9UcbB/4yGoMHkD92oNUaj+8WGeH746ttw23Q7vNQytniw26Mb69OFcezMMNT3JkpJY2EWD/UbD/
 K+PDVrZzh8BcIEhwtrnLjDJTqDOKlyRpx55VsuPEUhMTpLTAP0EUQVQSvL2C7g2yMM77D3BE5Ey
 TufCOoBlv5L6MkXJNymktzhuKZgddElRRTaWCRW38PQg5jCNReQw8E7At2nJufuBhfiSIABQEaI
 yHmDKr0Ajx1brh+KXfOGBRTj/UBnPyRtUB4kXaERCzYNITzIQncSyxOckpPpsxiBulW5XZRMrZN
 GrqlkfA7majXF1wBmU9sBCczx5Wxhd7KUCJmyaxJ8R7PB93Z
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, pwrctl devices are created if the corresponding PCI nodes are
defined in devicetree. But this is not correct, because not all PCI nodes
defined in devicetree require pwrctl support. Pwrctl comes into picture
only when the device requires kernel to manage its power state. This can
be determined using the power supply properties present in the devicetree
node of the device.

So add a new API, of_pci_is_supply_present() that checks the devicetree
node if at least one power supply property is present or not. If present,
then the pwrctl device will be created for that PCI node. Otherwise, it
will be skipped.

Cc: stable+noautosel@kernel.org # Depends on of_platform_device_create() rework
Fixes: 8fb18619d910 ("PCI/pwrctl: Create platform devices for child OF nodes of the port node")
Suggested-by: Dmitry Baryshkov <dmitry.baryshkov@linaro.org>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/pci/bus.c | 11 +++++++++++
 drivers/pci/of.c  | 27 +++++++++++++++++++++++++++
 drivers/pci/pci.h |  5 +++++
 3 files changed, 43 insertions(+)

diff --git a/drivers/pci/bus.c b/drivers/pci/bus.c
index 959044b059b5..698ec98b9388 100644
--- a/drivers/pci/bus.c
+++ b/drivers/pci/bus.c
@@ -354,6 +354,17 @@ void pci_bus_add_device(struct pci_dev *dev)
 
 	if (dev_of_node(&dev->dev) && pci_is_bridge(dev)) {
 		for_each_child_of_node_scoped(dn, child) {
+			/*
+			 * First check whether the pwrctl device needs to be
+			 * created or not. This is decided based on at least
+			 * one of the power supplies being defined in the
+			 * devicetree node of the device.
+			 */
+			if (!of_pci_is_supply_present(child)) {
+				pci_dbg(dev, "skipping OF node: %s\n", child->name);
+				continue;
+			}
+
 			pdev = of_platform_device_create(child, NULL, &dev->dev);
 			if (!pdev)
 				pci_err(dev, "failed to create OF node: %s\n", child->name);
diff --git a/drivers/pci/of.c b/drivers/pci/of.c
index dacea3fc5128..1f6a15a35a82 100644
--- a/drivers/pci/of.c
+++ b/drivers/pci/of.c
@@ -728,6 +728,33 @@ void of_pci_make_dev_node(struct pci_dev *pdev)
 }
 #endif
 
+/**
+ * of_pci_is_supply_present() - Check if the power supply is present for the PCI
+ *				device
+ * @np: Device tree node
+ *
+ * Check if the power supply for the PCI device is present in the device tree
+ * node or not.
+ *
+ * Return: true if at least one power supply exists; false otherwise.
+ */
+bool of_pci_is_supply_present(struct device_node *np)
+{
+	struct property *prop;
+	char *supply;
+
+	if (!np)
+		return false;
+
+	for_each_property_of_node(np, prop) {
+		supply = strrchr(prop->name, '-');
+		if (supply && !strcmp(supply, "-supply"))
+			return true;
+	}
+
+	return false;
+}
+
 #endif /* CONFIG_PCI */
 
 /**
diff --git a/drivers/pci/pci.h b/drivers/pci/pci.h
index 14d00ce45bfa..c8081b427267 100644
--- a/drivers/pci/pci.h
+++ b/drivers/pci/pci.h
@@ -746,6 +746,7 @@ void pci_set_bus_of_node(struct pci_bus *bus);
 void pci_release_bus_of_node(struct pci_bus *bus);
 
 int devm_of_pci_bridge_init(struct device *dev, struct pci_host_bridge *bridge);
+bool of_pci_is_supply_present(struct device_node *np);
 
 #else
 static inline int
@@ -793,6 +794,10 @@ static inline int devm_of_pci_bridge_init(struct device *dev, struct pci_host_br
 	return 0;
 }
 
+static inline bool of_pci_is_supply_present(struct device_node *np);
+{
+	return false;
+}
 #endif /* CONFIG_OF */
 
 struct of_changeset;

-- 
2.25.1

