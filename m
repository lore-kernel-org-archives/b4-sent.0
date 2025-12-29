From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 29 Dec 2025 22:56:54 +0530
Subject: [PATCH v3 3/7] PCI/pwrctrl: Add APIs for explicitly creating and
 destroying pwrctrl devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251229-pci-pwrctrl-rework-v3-3-c7d5918cd0db@oss.qualcomm.com>
References: <20251229-pci-pwrctrl-rework-v3-0-c7d5918cd0db@oss.qualcomm.com>
In-Reply-To: <20251229-pci-pwrctrl-rework-v3-0-c7d5918cd0db@oss.qualcomm.com>
To: Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>
Cc: linux-pci@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Chen-Yu Tsai <wens@kernel.org>, 
 Brian Norris <briannorris@chromium.org>, 
 Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>, 
 Niklas Cassel <cassel@kernel.org>, Alex Elder <elder@riscstar.com>, 
 Bartosz Golaszewski <bartosz.golaszewski@linaro.org>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Chen-Yu Tsai <wenst@chromium.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=7390;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=FhWYfEqaBG50cN6COgy1sseIAFEg1RKECjuWPCA8w/g=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpUrnm6sWiVXj1wraiubfv1/NICOxJuAebZYrmh
 9xWBxcSxl+JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaVK55gAKCRBVnxHm/pHO
 9XECB/9grPLddqqRaLg6M5h85Cske23YGoDQZWrec8LGsVRalPFJIGuw7Zf/M1dgrL7bXuaBqij
 kAOmBXVbkFjO+a5a6OKcBWVDxiv6CZGdSZ8PYoXe/aWDj0Ov92PfjpmC325aRb/J3FfP0qCviSU
 vm7zkfkYDs2IdzjZE751pTYONb6ZKd68kOEja9dyh969An0XjcPIrQ0jb2GEq0MjCQzwF/DUUVl
 4MX6nNFnRhPr7/eVRce0Pc4ZyVdNtdMnPCUu7e0IodTg8vZMaxJc80TiGeRtgOWo0QjbmCIapFk
 hHmWzQXwQpcIoz0Cw7kogfQd5O9LHm4b+RS1N1Wf8mcDyxqU
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>

Previously, the PCI core created pwrctrl devices during pci_scan_device()
on its own and then skipped enumeration of those devices, hoping the
pwrctrl driver would power them on and trigger a bus rescan.

This approach works for endpoint devices directly connected to Root Ports,
but it fails for PCIe switches acting as bus extenders. When the switch
requires pwrctrl support, and the pwrctrl driver is not available during
the pwrctrl device creation, it's enumeration will be skipped during the
initial PCI bus scan.

This premature scan leads the PCI core to allocate resources (bridge
windows, bus numbers) for the upstream bridge based on available downstream
buses at scan time. For non-hotplug capable bridges, PCI core typically
allocates resources based on the number of buses available during the
initial bus scan, which happens to be just one if the switch is not powered
on and enumerated at that time. When the switch gets enumerated later on,
it will fail due to the lack of upstream resources.

As a result, a PCIe switch powered on by the pwrctrl driver cannot be
reliably enumerated currently. Either the switch has to be enabled in the
bootloader or the switch pwrctrl driver has to be loaded during the pwrctrl
device creation time to workaround these issues.

This commit introduces new APIs to explicitly create and destroy pwrctrl
devices from controller drivers by recursively scanning the PCI child nodes
of the controller. These APIs allow creating pwrctrl devices based on the
original criteria and are intended to be called during controller probe and
removal.

These APIs, together with the upcoming APIs for power on/off will allow the
controller drivers to power on all the devices before starting the initial
bus scan, thereby solving the resource allocation issue.

Signed-off-by: Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>
[mani: splitted the patch, cleaned up the code, and rewrote description]
Tested-by: Chen-Yu Tsai <wenst@chromium.org>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/of.c            |   1 +
 drivers/pci/pwrctrl/core.c  | 113 ++++++++++++++++++++++++++++++++++++++++++++
 include/linux/pci-pwrctrl.h |   8 +++-
 3 files changed, 121 insertions(+), 1 deletion(-)

diff --git a/drivers/pci/of.c b/drivers/pci/of.c
index 3579265f1198..9bb5f258759b 100644
--- a/drivers/pci/of.c
+++ b/drivers/pci/of.c
@@ -867,6 +867,7 @@ bool of_pci_supply_present(struct device_node *np)
 
 	return false;
 }
+EXPORT_SYMBOL_GPL(of_pci_supply_present);
 
 #endif /* CONFIG_PCI */
 
diff --git a/drivers/pci/pwrctrl/core.c b/drivers/pci/pwrctrl/core.c
index 6bdbfed584d6..844b5649b663 100644
--- a/drivers/pci/pwrctrl/core.c
+++ b/drivers/pci/pwrctrl/core.c
@@ -3,14 +3,21 @@
  * Copyright (C) 2024 Linaro Ltd.
  */
 
+#define dev_fmt(fmt) "Pwrctrl: " fmt
+
 #include <linux/device.h>
 #include <linux/export.h>
 #include <linux/kernel.h>
+#include <linux/of.h>
+#include <linux/of_platform.h>
 #include <linux/pci.h>
 #include <linux/pci-pwrctrl.h>
+#include <linux/platform_device.h>
 #include <linux/property.h>
 #include <linux/slab.h>
 
+#include "../pci.h"
+
 static int pci_pwrctrl_notify(struct notifier_block *nb, unsigned long action,
 			      void *data)
 {
@@ -145,6 +152,112 @@ int devm_pci_pwrctrl_device_set_ready(struct device *dev,
 }
 EXPORT_SYMBOL_GPL(devm_pci_pwrctrl_device_set_ready);
 
+static int pci_pwrctrl_create_device(struct device_node *np, struct device *parent)
+{
+	struct platform_device *pdev;
+	int ret;
+
+	for_each_available_child_of_node_scoped(np, child) {
+		ret = pci_pwrctrl_create_device(child, parent);
+		if (ret)
+			return ret;
+	}
+
+	/* Bail out if the platform device is already available for the node */
+	pdev = of_find_device_by_node(np);
+	if (pdev) {
+		put_device(&pdev->dev);
+		return 0;
+	}
+
+	/*
+	 * Sanity check to make sure that the node has the compatible property
+	 * to allow driver binding.
+	 */
+	if (!of_property_present(np, "compatible"))
+		return 0;
+
+	/*
+	 * Check whether the pwrctrl device really needs to be created or not.
+	 * This is decided based on at least one of the power supplies being
+	 * defined in the devicetree node of the device.
+	 */
+	if (!of_pci_supply_present(np)) {
+		dev_dbg(parent, "Skipping OF node: %s\n", np->name);
+		return 0;
+	}
+
+	/* Now create the pwrctrl device */
+	pdev = of_platform_device_create(np, NULL, parent);
+	if (!pdev) {
+		dev_err(parent, "Failed to create pwrctrl device for node: %s\n", np->name);
+		return -EINVAL;
+	}
+
+	return 0;
+}
+
+/**
+ * pci_pwrctrl_create_devices - Create pwrctrl devices
+ *
+ * @parent: Parent PCI device for which the pwrctrl devices need to be created.
+ *
+ * This function recursively creates pwrctrl devices for the child nodes
+ * of the specified PCI parent device in a depth first manner. On error, all
+ * created devices will be destroyed.
+ *
+ * Returns: 0 on success, negative error number on error.
+ */
+int pci_pwrctrl_create_devices(struct device *parent)
+{
+	int ret;
+
+	for_each_available_child_of_node_scoped(parent->of_node, child) {
+		ret = pci_pwrctrl_create_device(child, parent);
+		if (ret) {
+			pci_pwrctrl_destroy_devices(parent);
+			return ret;
+		}
+	}
+
+	return 0;
+}
+EXPORT_SYMBOL_GPL(pci_pwrctrl_create_devices);
+
+static void pci_pwrctrl_destroy_device(struct device_node *np)
+{
+	struct platform_device *pdev;
+
+	for_each_available_child_of_node_scoped(np, child)
+		pci_pwrctrl_destroy_device(child);
+
+	pdev = of_find_device_by_node(np);
+	if (!pdev)
+		return;
+
+	of_device_unregister(pdev);
+	put_device(&pdev->dev);
+
+	of_node_clear_flag(np, OF_POPULATED);
+}
+
+/**
+ * pci_pwrctrl_destroy_devices - Destroy pwrctrl devices
+ *
+ * @parent: Parent PCI device for which the pwrctrl devices need to be destroyed.
+ *
+ * This function recursively destroys pwrctrl devices for the child nodes
+ * of the specified PCI parent device in a depth first manner.
+ */
+void pci_pwrctrl_destroy_devices(struct device *parent)
+{
+	struct device_node *np = parent->of_node;
+
+	for_each_available_child_of_node_scoped(np, child)
+		pci_pwrctrl_destroy_device(child);
+}
+EXPORT_SYMBOL_GPL(pci_pwrctrl_destroy_devices);
+
 MODULE_AUTHOR("Bartosz Golaszewski <bartosz.golaszewski@linaro.org>");
 MODULE_DESCRIPTION("PCI Device Power Control core driver");
 MODULE_LICENSE("GPL");
diff --git a/include/linux/pci-pwrctrl.h b/include/linux/pci-pwrctrl.h
index bd0ee9998125..5590ffec0bea 100644
--- a/include/linux/pci-pwrctrl.h
+++ b/include/linux/pci-pwrctrl.h
@@ -54,5 +54,11 @@ int pci_pwrctrl_device_set_ready(struct pci_pwrctrl *pwrctrl);
 void pci_pwrctrl_device_unset_ready(struct pci_pwrctrl *pwrctrl);
 int devm_pci_pwrctrl_device_set_ready(struct device *dev,
 				     struct pci_pwrctrl *pwrctrl);
-
+#if IS_ENABLED(CONFIG_PCI_PWRCTRL)
+int pci_pwrctrl_create_devices(struct device *parent);
+void pci_pwrctrl_destroy_devices(struct device *parent);
+#else
+static inline int pci_pwrctrl_create_devices(struct device *parent) { return 0; }
+static void pci_pwrctrl_destroy_devices(struct device *parent) { }
+#endif
 #endif /* __PCI_PWRCTRL_H__ */

-- 
2.48.1

