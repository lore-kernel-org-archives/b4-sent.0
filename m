From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Tue, 31 Dec 2024 15:13:45 +0530
Subject: [PATCH v2 4/6] PCI/pwrctrl: Skip scanning for the device further
 if pwrctrl device is created
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241231-pci-pwrctrl-slot-v2-4-6a15088ba541@linaro.org>
References: <20241231-pci-pwrctrl-slot-v2-0-6a15088ba541@linaro.org>
In-Reply-To: <20241231-pci-pwrctrl-slot-v2-0-6a15088ba541@linaro.org>
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Qiang Yu <quic_qianyu@quicinc.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=2479;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=ZL4/V6JFUdmO0YAXp+rd+0EQhZLXt3iJU/vJV6wd1WE=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnc7zreRTAGViodhIerB4qBU+JGtkIrfAxenxfp
 1BjYCey/LCJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZ3O86wAKCRBVnxHm/pHO
 9Xo5B/4k+7/RJtlU1DjUuo7dbArcYUOgE4GUwF22dv/aaIMygYddilkPq2OMFf+y/EGPrpqoXun
 LGMhs0Sj5Cqw2CY8wbsNpwU9RXLwfL9L66StOq7Koq3sbq2++3DwTKuSMD6wkZES6MeFT3YMVf3
 OM72sPqwIPIiW7MLDhvyCYWaylUX2Dc1pjTLndJ3Jiuphzk7PaVuGofY5EmKQ7MdWGhwKzdyP+v
 BvdSLJH7W6A+5eZ1vrUC8py6a2qsH+m7LJVpPkk0Y6yZ14UT2O0Eue1wJjPkABHxEDq18Sv3BtQ
 WW3CO76Fqxh1qREaveLfBycZMwv41a6FWwoGEWojQFOwnrvy
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The pwrctrl core will rescan the bus once the device is powered on. So
there is no need to continue scanning for the device further.

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

