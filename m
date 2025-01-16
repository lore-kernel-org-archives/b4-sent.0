From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Thu, 16 Jan 2025 19:39:11 +0530
Subject: [PATCH v3 1/5] PCI/pwrctrl: Move creation of pwrctrl devices to
 pci_scan_device()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250116-pci-pwrctrl-slot-v3-1-827473c8fbf4@linaro.org>
References: <20250116-pci-pwrctrl-slot-v3-0-827473c8fbf4@linaro.org>
In-Reply-To: <20250116-pci-pwrctrl-slot-v3-0-827473c8fbf4@linaro.org>
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, 
 Bartosz Golaszewski <bartosz.golaszewski@linaro.org>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 Lukas Wunner <lukas@wunner.de>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=5697;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=xIyJbEnDR6J92iNeHDHLDUlZlBfz305fAs7wXMTBhwA=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBniRMLIX2HwMXnBT2tXXnis0wuKYc6d3Ynt03We
 Jl4fPDu/OuJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZ4kTCwAKCRBVnxHm/pHO
 9Y7sCACDjhyzQQbLXgy8x+VeSsoFzweg2mBA99JNaC0BH//J1HrSz3XkxUBVtCIJd1ZthwrvpiF
 iPau3LPB78cLQ8HAb/whQqiZM2ve10KTvqGUknwx4SIyIjAOZdqbcHr9mseDug/7V5doB9oktMG
 bHn0tziuO4bLD4m7ea7mD1mSWWQAEFf7DQUevrkIjBjSrwGx1uhds0wFKFz3s7QrCPuwxdYrYIj
 yraVF93OSlCTfDTh6TIyVYEq72WNN9yS9/z4Potz8R9Ku8ZCLdO5HHnetSeeziaEy9+lHjNkbkh
 XCxbJhTOckCe2qx8f60gYkZmwq8JOcEZl9kzh6IY/pko4UVs
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Current way of creating pwrctrl devices requires iterating through the
child devicetree nodes of the PCI bridge in pci_pwrctrl_create_devices().
Even though it works, it creates confusion as there is no symmetry between
this and pci_pwrctrl_unregister() function that removes the pwrctrl
devices.

So to make these two functions symmetric, move the creation of pwrctrl
devices to pci_scan_device(). During the scan of each device in a slot,
the devicetree node (if exists) for the PCI device will be checked. If it
has the supplies populated, then the pwrctrl device will be created.

Since the PCI device scan happens so early, there would be no 'struct
pci_dev' available for the device. So the host bridge is used as the parent
of all pwrctrl devices.

One nice side effect of this move is that, it is now possible to have
pwrctrl devices for PCI bridges as well (to control the supplies of PCI
slots).

Suggested-by: Lukas Wunner <lukas@wunner.de>
Tested-by: Bartosz Golaszewski <bartosz.golaszewski@linaro.org>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/pci/bus.c          | 43 -------------------------------------------
 drivers/pci/probe.c        | 34 ++++++++++++++++++++++++++++++++++
 drivers/pci/pwrctrl/core.c |  2 +-
 3 files changed, 35 insertions(+), 44 deletions(-)

diff --git a/drivers/pci/bus.c b/drivers/pci/bus.c
index 98910bc0fcc4..b6851101ac36 100644
--- a/drivers/pci/bus.c
+++ b/drivers/pci/bus.c
@@ -331,47 +331,6 @@ void __weak pcibios_resource_survey_bus(struct pci_bus *bus) { }
 
 void __weak pcibios_bus_add_device(struct pci_dev *pdev) { }
 
-/*
- * Create pwrctrl devices (if required) for the PCI devices to handle the power
- * state.
- */
-static void pci_pwrctrl_create_devices(struct pci_dev *dev)
-{
-	struct device_node *np = dev_of_node(&dev->dev);
-	struct device *parent = &dev->dev;
-	struct platform_device *pdev;
-
-	/*
-	 * First ensure that we are starting from a PCI bridge and it has a
-	 * corresponding devicetree node.
-	 */
-	if (np && pci_is_bridge(dev)) {
-		/*
-		 * Now look for the child PCI device nodes and create pwrctrl
-		 * devices for them. The pwrctrl device drivers will manage the
-		 * power state of the devices.
-		 */
-		for_each_available_child_of_node_scoped(np, child) {
-			/*
-			 * First check whether the pwrctrl device really
-			 * needs to be created or not. This is decided
-			 * based on at least one of the power supplies
-			 * being defined in the devicetree node of the
-			 * device.
-			 */
-			if (!of_pci_supply_present(child)) {
-				pci_dbg(dev, "skipping OF node: %s\n", child->name);
-				return;
-			}
-
-			/* Now create the pwrctrl device */
-			pdev = of_platform_device_create(child, NULL, parent);
-			if (!pdev)
-				pci_err(dev, "failed to create OF node: %s\n", child->name);
-		}
-	}
-}
-
 /**
  * pci_bus_add_device - start driver for a single device
  * @dev: device to add
@@ -396,8 +355,6 @@ void pci_bus_add_device(struct pci_dev *dev)
 	pci_proc_attach_device(dev);
 	pci_bridge_d3_update(dev);
 
-	pci_pwrctrl_create_devices(dev);
-
 	/*
 	 * If the PCI device is associated with a pwrctrl device with a
 	 * power supply, create a device link between the PCI device and
diff --git a/drivers/pci/probe.c b/drivers/pci/probe.c
index 2e81ab0f5a25..91bdb2727c8e 100644
--- a/drivers/pci/probe.c
+++ b/drivers/pci/probe.c
@@ -9,6 +9,8 @@
 #include <linux/pci.h>
 #include <linux/msi.h>
 #include <linux/of_pci.h>
+#include <linux/of_platform.h>
+#include <linux/platform_device.h>
 #include <linux/pci_hotplug.h>
 #include <linux/slab.h>
 #include <linux/module.h>
@@ -2446,6 +2448,36 @@ bool pci_bus_read_dev_vendor_id(struct pci_bus *bus, int devfn, u32 *l,
 }
 EXPORT_SYMBOL(pci_bus_read_dev_vendor_id);
 
+/*
+ * Create pwrctrl device (if required) for the PCI device to handle the power
+ * state.
+ */
+static void pci_pwrctrl_create_device(struct pci_bus *bus, int devfn)
+{
+	struct pci_host_bridge *host = pci_find_host_bridge(bus);
+	struct platform_device *pdev;
+	struct device_node *np;
+
+	np = of_pci_find_child_device(dev_of_node(&bus->dev), devfn);
+	if (!np || of_find_device_by_node(np))
+		return;
+
+	/*
+	 * First check whether the pwrctrl device really needs to be created or
+	 * not. This is decided based on at least one of the power supplies
+	 * being defined in the devicetree node of the device.
+	 */
+	if (!of_pci_supply_present(np)) {
+		pr_debug("PCI/pwrctrl: Skipping OF node: %s\n", np->name);
+		return;
+	}
+
+	/* Now create the pwrctrl device */
+	pdev = of_platform_device_create(np, NULL, &host->dev);
+	if (!pdev)
+		pr_err("PCI/pwrctrl: Failed to create pwrctrl device for OF node: %s\n", np->name);
+}
+
 /*
  * Read the config data for a PCI device, sanity-check it,
  * and fill in the dev structure.
@@ -2455,6 +2487,8 @@ static struct pci_dev *pci_scan_device(struct pci_bus *bus, int devfn)
 	struct pci_dev *dev;
 	u32 l;
 
+	pci_pwrctrl_create_device(bus, devfn);
+
 	if (!pci_bus_read_dev_vendor_id(bus, devfn, &l, 60*1000))
 		return NULL;
 
diff --git a/drivers/pci/pwrctrl/core.c b/drivers/pci/pwrctrl/core.c
index 2fb174db91e5..9cc7e2b7f2b5 100644
--- a/drivers/pci/pwrctrl/core.c
+++ b/drivers/pci/pwrctrl/core.c
@@ -44,7 +44,7 @@ static void rescan_work_func(struct work_struct *work)
 						   struct pci_pwrctrl, work);
 
 	pci_lock_rescan_remove();
-	pci_rescan_bus(to_pci_dev(pwrctrl->dev->parent)->bus);
+	pci_rescan_bus(to_pci_host_bridge(pwrctrl->dev->parent)->bus);
 	pci_unlock_rescan_remove();
 }
 

-- 
2.25.1

