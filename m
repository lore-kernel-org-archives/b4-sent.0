From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Mon, 15 Jul 2024 23:03:49 +0530
Subject: [PATCH 07/14] PCI: qcom-ep: Modify 'global_irq' and 'perst_irq'
 IRQ device names
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240715-pci-qcom-hotplug-v1-7-5f3765cc873a@linaro.org>
References: <20240715-pci-qcom-hotplug-v1-0-5f3765cc873a@linaro.org>
In-Reply-To: <20240715-pci-qcom-hotplug-v1-0-5f3765cc873a@linaro.org>
To: Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kw@linux.com>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>
Cc: linux-pci@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=openpgp-sha256; l=2451;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=33LLyDEX80bmAN/A+qSdjtZSe4gPt17zqqO4Z1H5mmE=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmlV15EQrMNyKxALsdRNoBTY/z/AVzKkjRrHma4
 3xjEDgshSmJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZpVdeQAKCRBVnxHm/pHO
 9eODB/wPgHyueppr1K0JAMEG3CfhRu6n14xNTdRybozcACX+zyEjiheQUSMARuL/wOxmbv5povU
 rNPA6Ld41t3MBuBfdCPRi8/38Cqn/svXM4noQl8QemvoKIQZiARt0AI7w26BR5TNxiiwGekDkcH
 jWCuzfYXUl7Y21ynbaYgszb/GRChQ0KrxnvUm8wqxvGtsFZNTlwJk+ZMssA+EYdEeOkiis+z1f9
 R9BQy24XdLweWpQf39xzkAi4uO/k3UG2w8ih4PYVTFUeIBzd8PS0dhucRIfE0mZUUJSfcz6zBin
 kR3/ziEOzJRDud5wUkWt9ltpLo/loEJy8MOBk+CuDM8UnWQw
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, the IRQ device name for both of these IRQs doesn't have Qcom
specific prefix and PCIe domain number. This causes 2 issues:

1. Pollutes the global IRQ namespace since 'global' is a common name.
2. When more than one EP controller instance is present in the SoC, naming
conflict will occur.

Hence, add 'qcom_pcie_ep_' prefix and PCIe domain number suffix to the IRQ
names to uniquely identify the IRQs and also to fix the above mentioned
issues.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/pci/controller/dwc/pcie-qcom-ep.c | 16 ++++++++++++++--
 1 file changed, 14 insertions(+), 2 deletions(-)

diff --git a/drivers/pci/controller/dwc/pcie-qcom-ep.c b/drivers/pci/controller/dwc/pcie-qcom-ep.c
index cda5d8fdc03b..a0847eef0645 100644
--- a/drivers/pci/controller/dwc/pcie-qcom-ep.c
+++ b/drivers/pci/controller/dwc/pcie-qcom-ep.c
@@ -711,8 +711,15 @@ static irqreturn_t qcom_pcie_ep_perst_irq_thread(int irq, void *data)
 static int qcom_pcie_ep_enable_irq_resources(struct platform_device *pdev,
 					     struct qcom_pcie_ep *pcie_ep)
 {
+	struct device *dev = pcie_ep->pci.dev;
+	char *name;
 	int ret;
 
+	name = devm_kasprintf(dev, GFP_KERNEL, "qcom_pcie_ep_global_irq%d",
+			      pcie_ep->pci.ep.epc->domain_nr);
+	if (!name)
+		return -ENOMEM;
+
 	pcie_ep->global_irq = platform_get_irq_byname(pdev, "global");
 	if (pcie_ep->global_irq < 0)
 		return pcie_ep->global_irq;
@@ -720,18 +727,23 @@ static int qcom_pcie_ep_enable_irq_resources(struct platform_device *pdev,
 	ret = devm_request_threaded_irq(&pdev->dev, pcie_ep->global_irq, NULL,
 					qcom_pcie_ep_global_irq_thread,
 					IRQF_ONESHOT,
-					"global_irq", pcie_ep);
+					name, pcie_ep);
 	if (ret) {
 		dev_err(&pdev->dev, "Failed to request Global IRQ\n");
 		return ret;
 	}
 
+	name = devm_kasprintf(dev, GFP_KERNEL, "qcom_pcie_ep_perst_irq%d",
+			      pcie_ep->pci.ep.epc->domain_nr);
+	if (!name)
+		return -ENOMEM;
+
 	pcie_ep->perst_irq = gpiod_to_irq(pcie_ep->reset);
 	irq_set_status_flags(pcie_ep->perst_irq, IRQ_NOAUTOEN);
 	ret = devm_request_threaded_irq(&pdev->dev, pcie_ep->perst_irq, NULL,
 					qcom_pcie_ep_perst_irq_thread,
 					IRQF_TRIGGER_HIGH | IRQF_ONESHOT,
-					"perst_irq", pcie_ep);
+					name, pcie_ep);
 	if (ret) {
 		dev_err(&pdev->dev, "Failed to request PERST IRQ\n");
 		disable_irq(pcie_ep->global_irq);

-- 
2.25.1

