From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Thu, 16 Jan 2025 19:39:13 +0530
Subject: [PATCH v3 3/5] PCI/pwrctrl: Skip scanning for the device further
 if pwrctrl device is created
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250116-pci-pwrctrl-slot-v3-3-827473c8fbf4@linaro.org>
References: <20250116-pci-pwrctrl-slot-v3-0-827473c8fbf4@linaro.org>
In-Reply-To: <20250116-pci-pwrctrl-slot-v3-0-827473c8fbf4@linaro.org>
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, 
 Bartosz Golaszewski <bartosz.golaszewski@linaro.org>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=2611;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=gy4PLjMdamyd52iwg/D99E/UTsDOUFjzQxLCaHwi72c=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBniRMMdKv0PONWXwBlZ/yC9+rLlA2+aPboQEGcV
 Qdk8GxoQtuJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZ4kTDAAKCRBVnxHm/pHO
 9diBCACGGQCeerSlzjd5UtoHZZdki3Fg6kHsSGUZBCdBgJwXRGqSHkW48jwQcsUlwg+Kqi1JpdH
 LHvK9O/rDjgDBS9jtSulkcnD/HOcp7Dyq6v5/HjWH4szlhO528hIGU5ZlTxDDj8/f24uihzhReA
 SATSKJzkm2NvxzASaqMteXhuGgq6fDwRk78k+W98R51kuR73yttfx53wHCxpGRIgRi3Kx50ZX2A
 rG03AAJELcStTY3dRB/tIiYoGmbe6/w8FCEOpjL9WBQaQLSEb3S4tVmBsIb8fIVmSqCRPw2aII3
 uOzVAGE5Sr/J450uO58LsGZA5FL+WkSnJa+HhAaJayV5fUM1
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The pwrctrl core will rescan the bus once the device is powered on. So
there is no need to continue scanning for the device further.

Reviewed-by: Bartosz Golaszewski <bartosz.golaszewski@linaro.org>
Tested-by: Bartosz Golaszewski <bartosz.golaszewski@linaro.org>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/pci/probe.c | 27 +++++++++++++++++----------
 1 file changed, 17 insertions(+), 10 deletions(-)

diff --git a/drivers/pci/probe.c b/drivers/pci/probe.c
index 91bdb2727c8e..6121f81f7c98 100644
--- a/drivers/pci/probe.c
+++ b/drivers/pci/probe.c
@@ -2448,11 +2448,7 @@ bool pci_bus_read_dev_vendor_id(struct pci_bus *bus, int devfn, u32 *l,
 }
 EXPORT_SYMBOL(pci_bus_read_dev_vendor_id);
 
-/*
- * Create pwrctrl device (if required) for the PCI device to handle the power
- * state.
- */
-static void pci_pwrctrl_create_device(struct pci_bus *bus, int devfn)
+static struct platform_device *pci_pwrctrl_create_device(struct pci_bus *bus, int devfn)
 {
 	struct pci_host_bridge *host = pci_find_host_bridge(bus);
 	struct platform_device *pdev;
@@ -2460,7 +2456,7 @@ static void pci_pwrctrl_create_device(struct pci_bus *bus, int devfn)
 
 	np = of_pci_find_child_device(dev_of_node(&bus->dev), devfn);
 	if (!np || of_find_device_by_node(np))
-		return;
+		return NULL;
 
 	/*
 	 * First check whether the pwrctrl device really needs to be created or
@@ -2469,13 +2465,17 @@ static void pci_pwrctrl_create_device(struct pci_bus *bus, int devfn)
 	 */
 	if (!of_pci_supply_present(np)) {
 		pr_debug("PCI/pwrctrl: Skipping OF node: %s\n", np->name);
-		return;
+		return NULL;
 	}
 
 	/* Now create the pwrctrl device */
 	pdev = of_platform_device_create(np, NULL, &host->dev);
-	if (!pdev)
-		pr_err("PCI/pwrctrl: Failed to create pwrctrl device for OF node: %s\n", np->name);
+	if (!pdev) {
+		pr_err("PCI/pwrctrl: Failed to create pwrctrl device for node: %s\n", np->name);
+		return NULL;
+	}
+
+	return pdev;
 }
 
 /*
@@ -2487,7 +2487,14 @@ static struct pci_dev *pci_scan_device(struct pci_bus *bus, int devfn)
 	struct pci_dev *dev;
 	u32 l;
 
-	pci_pwrctrl_create_device(bus, devfn);
+	/*
+	 * Create pwrctrl device (if required) for the PCI device to handle the
+	 * power state. If the pwrctrl device is created, then skip scanning
+	 * further as the pwrctrl core will rescan the bus after powering on
+	 * the device.
+	 */
+	if (pci_pwrctrl_create_device(bus, devfn))
+		return NULL;
 
 	if (!pci_bus_read_dev_vendor_id(bus, devfn, &l, 60*1000))
 		return NULL;

-- 
2.25.1

