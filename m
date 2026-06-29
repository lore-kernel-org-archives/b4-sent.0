From: Jia Wang <wangjia@ultrarisc.com>
Date: Mon, 29 Jun 2026 13:59:51 +0800
Subject: [PATCH 2/2] PCI: ultrarisc: get and enable DP1000 PCIe clocks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260629-ultrarisc-pci-clk-v1-2-5ea3308fdab3@ultrarisc.com>
References: <20260629-ultrarisc-pci-clk-v1-0-5ea3308fdab3@ultrarisc.com>
In-Reply-To: <20260629-ultrarisc-pci-clk-v1-0-5ea3308fdab3@ultrarisc.com>
To: Xincheng Zhang <zhangxincheng@ultrarisc.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pci@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jia Wang <wangjia@ultrarisc.com>
X-Mailer: b4 0.15-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782712801; l=3985;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=LtJ66+myRw3X2vCGc+65Ap5gE7bLwVO+Sf4xHFQmlfE=;
 b=MwLsvGel0miFh1m/CsqhcqyhlWjcj9ABZiQcYV9GLudA9sNZHyysEEht7zGI/ohO+kuOKDOYC
 9l0jGwIGC0JDC7FbhPyTKnPAGmywPtX+w/tVIsl+VfYlUlcI+w+JvET
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=wGVm18siRScehKOkOz0WKxgxDy7IezHEszhnN4/TUCY=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260515 with auth_id=779
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the required core, dbi, and aux clocks for the DP1000 PCIe
controller and enable them before initializing the DesignWare host.

Also manage the clocks across system suspend and resume.

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
 drivers/pci/controller/dwc/pcie-ultrarisc.c | 74 ++++++++++++++++++++++++++---
 1 file changed, 67 insertions(+), 7 deletions(-)

diff --git a/drivers/pci/controller/dwc/pcie-ultrarisc.c b/drivers/pci/controller/dwc/pcie-ultrarisc.c
index 6ee661ceff67..74010a86244e 100644
--- a/drivers/pci/controller/dwc/pcie-ultrarisc.c
+++ b/drivers/pci/controller/dwc/pcie-ultrarisc.c
@@ -5,6 +5,7 @@
  * Copyright (C) 2026 UltraRISC Technology (Shanghai) Co., Ltd.
  */
 
+#include <linux/clk.h>
 #include <linux/kernel.h>
 #include <linux/module.h>
 #include <linux/of_device.h>
@@ -23,6 +24,11 @@
 
 #define ULTRARISC_PCIE_COMP_TIMEOUT_65_210MS	0x6
 
+struct ultrarisc_pcie {
+	struct dw_pcie pci;
+	struct clk_bulk_data clks[3];
+};
+
 static struct pci_ops ultrarisc_pci_ops = {
 	.map_bus = dw_pcie_own_conf_map_bus,
 	.read = pci_generic_config_read32,
@@ -98,17 +104,46 @@ static const struct dw_pcie_ops dw_pcie_ops = {
 	.start_link = ultrarisc_pcie_start_link,
 };
 
+static void ultrarisc_pcie_disable_clks(void *data)
+{
+	struct ultrarisc_pcie *ultra = data;
+
+	clk_bulk_disable_unprepare(ARRAY_SIZE(ultra->clks), ultra->clks);
+}
+
+static int ultrarisc_pcie_init_clks(struct ultrarisc_pcie *ultra)
+{
+	struct device *dev = ultra->pci.dev;
+	int ret;
+
+	ultra->clks[0].id = "core";
+	ultra->clks[1].id = "dbi";
+	ultra->clks[2].id = "aux";
+
+	ret = devm_clk_bulk_get(dev, ARRAY_SIZE(ultra->clks), ultra->clks);
+	if (ret)
+		return dev_err_probe(dev, ret, "Failed to get clocks\n");
+
+	ret = clk_bulk_prepare_enable(ARRAY_SIZE(ultra->clks), ultra->clks);
+	if (ret)
+		return dev_err_probe(dev, ret, "Failed to enable clocks\n");
+
+	return devm_add_action_or_reset(dev, ultrarisc_pcie_disable_clks, ultra);
+}
+
 static int ultrarisc_pcie_probe(struct platform_device *pdev)
 {
+	struct ultrarisc_pcie *ultra;
 	struct device *dev = &pdev->dev;
 	struct dw_pcie_rp *pp;
 	struct dw_pcie *pci;
 	int ret;
 
-	pci = devm_kzalloc(dev, sizeof(*pci), GFP_KERNEL);
-	if (!pci)
+	ultra = devm_kzalloc(dev, sizeof(*ultra), GFP_KERNEL);
+	if (!ultra)
 		return -ENOMEM;
 
+	pci = &ultra->pci;
 	pci->dev = dev;
 	pci->ops = &dw_pcie_ops;
 
@@ -117,7 +152,11 @@ static int ultrarisc_pcie_probe(struct platform_device *pdev)
 
 	pp = &pci->pp;
 
-	platform_set_drvdata(pdev, pci);
+	platform_set_drvdata(pdev, ultra);
+
+	ret = ultrarisc_pcie_init_clks(ultra);
+	if (ret)
+		return ret;
 
 	pp->num_vectors = MAX_MSI_IRQS;
 	/* No L2/L3 Ready indication is available on this platform */
@@ -135,16 +174,37 @@ static int ultrarisc_pcie_probe(struct platform_device *pdev)
 
 static int ultrarisc_pcie_suspend_noirq(struct device *dev)
 {
-	struct dw_pcie *pci = dev_get_drvdata(dev);
+	struct ultrarisc_pcie *ultra = dev_get_drvdata(dev);
+	struct dw_pcie *pci = &ultra->pci;
+	int ret;
+
+	ret = dw_pcie_suspend_noirq(pci);
+	if (ret)
+		return ret;
 
-	return dw_pcie_suspend_noirq(pci);
+	if (pci->suspended)
+		clk_bulk_disable_unprepare(ARRAY_SIZE(ultra->clks), ultra->clks);
+
+	return 0;
 }
 
 static int ultrarisc_pcie_resume_noirq(struct device *dev)
 {
-	struct dw_pcie *pci = dev_get_drvdata(dev);
+	struct ultrarisc_pcie *ultra = dev_get_drvdata(dev);
+	struct dw_pcie *pci = &ultra->pci;
+	int ret;
+
+	if (pci->suspended) {
+		ret = clk_bulk_prepare_enable(ARRAY_SIZE(ultra->clks), ultra->clks);
+		if (ret)
+			return ret;
+	}
+
+	ret = dw_pcie_resume_noirq(pci);
+	if (ret && pci->suspended)
+		clk_bulk_disable_unprepare(ARRAY_SIZE(ultra->clks), ultra->clks);
 
-	return dw_pcie_resume_noirq(pci);
+	return ret;
 }
 
 static const struct dev_pm_ops ultrarisc_pcie_pm_ops = {

-- 
2.34.1

