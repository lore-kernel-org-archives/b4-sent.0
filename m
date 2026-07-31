From: Jia Wang <wangjia@ultrarisc.com>
Date: Fri, 31 Jul 2026 09:14:30 +0800
Subject: [PATCH v4 3/3] PCI: ultrarisc: use module_platform_driver()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260731-ultrarisc-pci-clk-v4-3-d738b491e49a@ultrarisc.com>
References: <20260731-ultrarisc-pci-clk-v4-0-d738b491e49a@ultrarisc.com>
In-Reply-To: <20260731-ultrarisc-pci-clk-v4-0-d738b491e49a@ultrarisc.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785460469; l=1066;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=peRDpMKKHgxmxfFJTmmW4y1XH8UWyNDI4nxaz6qI5+o=;
 b=ISyUdZJpfcX4jzGcRBoVy6KvH83lFss0KJuoc1oGWzJe5rKs9IcNDHaapd/wqohde027wEIbk
 ffuFpITtylBD64xlOdAkC/NOie0iycTOV1P/YWpTT8pS3kOaeZJ5ZZU
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=wGVm18siRScehKOkOz0WKxgxDy7IezHEszhnN4/TUCY=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260515 with auth_id=779
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

CONFIG_PCIE_ULTRARISC is a tristate option and may be built as a module.
Use module_platform_driver() so the driver uses the standard registration
helper for both built-in and module configurations.

Leave .remove unset because the driver registers an internal MSI
controller that cannot be safely disposed during removal.

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
 drivers/pci/controller/dwc/pcie-ultrarisc.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/pci/controller/dwc/pcie-ultrarisc.c b/drivers/pci/controller/dwc/pcie-ultrarisc.c
index 8e57135453b7..51e89180490d 100644
--- a/drivers/pci/controller/dwc/pcie-ultrarisc.c
+++ b/drivers/pci/controller/dwc/pcie-ultrarisc.c
@@ -240,7 +240,7 @@ static struct platform_driver ultrarisc_pcie_driver = {
 	},
 	.probe = ultrarisc_pcie_probe,
 };
-builtin_platform_driver(ultrarisc_pcie_driver);
+module_platform_driver(ultrarisc_pcie_driver);
 
 MODULE_DESCRIPTION("UltraRISC DP1000 DWC PCIe host controller");
 MODULE_LICENSE("GPL");

-- 
2.34.1

