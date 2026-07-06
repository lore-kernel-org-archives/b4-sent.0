From: Jia Wang <wangjia@ultrarisc.com>
Date: Mon, 06 Jul 2026 17:58:51 +0800
Subject: [PATCH v2 3/3] PCI: ultrarisc: allow DP1000 driver to build as
 module
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260706-ultrarisc-pci-clk-v2-3-2f3fb6fba66b@ultrarisc.com>
References: <20260706-ultrarisc-pci-clk-v2-0-2f3fb6fba66b@ultrarisc.com>
In-Reply-To: <20260706-ultrarisc-pci-clk-v2-0-2f3fb6fba66b@ultrarisc.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783331975; l=1255;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=Tis/JJyXExoBJp3CwIeeec8uXLx/jp/sC+yiinpaepI=;
 b=aL9+qmOJDB07rLN9IJHnnPHgX/+ZZ7+1+m+87dLW8NcDO1rB/bi2esZnu8AUHTNyNrf46xSuf
 Rfjb3B8Q3bRClC1f2IoZ3u3212T5Utgx7E6V+FgyyIl6bikCE5nNHI/
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

Fixes: 5fc35740c3b3 ("PCI: ultrarisc: Add UltraRISC DP1000 PCIe Root Complex driver")
Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
 drivers/pci/controller/dwc/pcie-ultrarisc.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/pci/controller/dwc/pcie-ultrarisc.c b/drivers/pci/controller/dwc/pcie-ultrarisc.c
index 6ed244770d53..5d226e529b77 100644
--- a/drivers/pci/controller/dwc/pcie-ultrarisc.c
+++ b/drivers/pci/controller/dwc/pcie-ultrarisc.c
@@ -225,7 +225,7 @@ static struct platform_driver ultrarisc_pcie_driver = {
 	},
 	.probe = ultrarisc_pcie_probe,
 };
-builtin_platform_driver(ultrarisc_pcie_driver);
+module_platform_driver(ultrarisc_pcie_driver);
 
 MODULE_DESCRIPTION("UltraRISC DP1000 DWC PCIe host controller");
 MODULE_LICENSE("GPL");

-- 
2.34.1

