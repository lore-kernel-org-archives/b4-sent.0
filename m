From: Jia Wang <wangjia@ultrarisc.com>
Date: Tue, 14 Jul 2026 09:11:04 +0800
Subject: [PATCH v3 3/3] PCI: ultrarisc: allow DP1000 driver to build as
 module
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260714-ultrarisc-pci-clk-v3-3-e72723fc0ef1@ultrarisc.com>
References: <20260714-ultrarisc-pci-clk-v3-0-e72723fc0ef1@ultrarisc.com>
In-Reply-To: <20260714-ultrarisc-pci-clk-v3-0-e72723fc0ef1@ultrarisc.com>
To: Xincheng Zhang <zhangxincheng@ultrarisc.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pci@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jia Wang <wangjia@ultrarisc.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783991482; l=1888;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=XcTZmVoSZFS2n0hsc4SvpU5AR+j0HF5sHlxgI3DxZTg=;
 b=lVeYRfT+j1fweGZ2YwkwrOX/iivL/LBom7hfF+EFD1hMgVtG3nOi2X5aj2adhEPBAw53sdwu8
 Qg31WSd9KxkBIFZWImmIbCltSqkCAIziZGU4ry6MavZ/eoInRn8bV75
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=wGVm18siRScehKOkOz0WKxgxDy7IezHEszhnN4/TUCY=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260515 with auth_id=779
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

CONFIG_PCIE_ULTRARISC is a tristate option, so the driver can be selected
as a module when COMPILE_TEST or platform configuration allows it.  Using
builtin_platform_driver() leaves the module build without the module
init/exit plumbing and causes modpost failures for the generated .ko.

Use module_platform_driver() so the driver works for both module and
built-in builds while keeping the existing tristate Kconfig entry.

Add a remove callback and call dw_pcie_host_deinit() during removal so the
root bus is torn down before devres releases the controller data.

Fixes: 5fc35740c3b3 ("PCI: ultrarisc: Add UltraRISC DP1000 PCIe Root Complex driver")
Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
 drivers/pci/controller/dwc/pcie-ultrarisc.c | 10 +++++++++-
 1 file changed, 9 insertions(+), 1 deletion(-)

diff --git a/drivers/pci/controller/dwc/pcie-ultrarisc.c b/drivers/pci/controller/dwc/pcie-ultrarisc.c
index 72ba5840b62d..9bee522a20e9 100644
--- a/drivers/pci/controller/dwc/pcie-ultrarisc.c
+++ b/drivers/pci/controller/dwc/pcie-ultrarisc.c
@@ -193,6 +193,13 @@ static int ultrarisc_pcie_probe(struct platform_device *pdev)
 	return 0;
 }
 
+static void ultrarisc_pcie_remove(struct platform_device *pdev)
+{
+	struct ultrarisc_pcie *ultra = platform_get_drvdata(pdev);
+
+	dw_pcie_host_deinit(&ultra->pci.pp);
+}
+
 static int ultrarisc_pcie_suspend_noirq(struct device *dev)
 {
 	struct ultrarisc_pcie *ultra = dev_get_drvdata(dev);
@@ -256,8 +263,9 @@ static struct platform_driver ultrarisc_pcie_driver = {
 		.pm = &ultrarisc_pcie_pm_ops,
 	},
 	.probe = ultrarisc_pcie_probe,
+	.remove = ultrarisc_pcie_remove,
 };
-builtin_platform_driver(ultrarisc_pcie_driver);
+module_platform_driver(ultrarisc_pcie_driver);
 
 MODULE_DESCRIPTION("UltraRISC DP1000 DWC PCIe host controller");
 MODULE_LICENSE("GPL");

-- 
2.34.1

