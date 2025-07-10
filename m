From: Frank Li <Frank.Li@nxp.com>
Date: Thu, 10 Jul 2025 15:13:47 -0400
Subject: [PATCH v21 1/9] PCI: imx6: Add helper function
 imx_pcie_add_lut_by_rid()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250710-ep-msi-v21-1-57683fc7fb25@nxp.com>
References: <20250710-ep-msi-v21-0-57683fc7fb25@nxp.com>
In-Reply-To: <20250710-ep-msi-v21-0-57683fc7fb25@nxp.com>
To: Kishon Vijay Abraham I <kishon@kernel.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Thomas Gleixner <tglx@linutronix.de>, Anup Patel <apatel@ventanamicro.com>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, Marc Zyngier <maz@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>, Arnd Bergmann <arnd@arndb.de>, 
 Shuah Khan <shuah@kernel.org>, Richard Zhu <hongxing.zhu@nxp.com>, 
 Lucas Stach <l.stach@pengutronix.de>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, Rob Herring <robh@kernel.org>, 
 Shawn Guo <shawnguo@kernel.org>, Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Manivannan Sadhasivam <mani@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>
Cc: Niklas Cassel <cassel@kernel.org>, dlemoal@kernel.org, jdmason@kudzu.us, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-pci@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 imx@lists.linux.dev, devicetree@vger.kernel.org, 
 Niklas Cassel <cassel@kernel.org>, Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752174836; l=1939;
 i=Frank.Li@nxp.com; s=20240130; h=from:subject:message-id;
 bh=FTsRKbmGJkqXdF0l3uL9gIhRFF4JXE9vNw1HW1VASns=;
 b=pl4q2ntiFNC+d0WkC3fXBmdd1gqe/CxBTx1BZqQJEmeumRTScrSLvt3T8awwwY9n6HD/z7skj
 3YNPpGXey6rAS+uVXG9/oWf2slSD0psgmFdz42M2s6eWD2I+0J7wxqM
X-Developer-Key: i=Frank.Li@nxp.com; a=ed25519;
 pk=I0L1sDUfPxpAkRvPKy7MdauTuSENRq+DnA+G4qcS94Q=
X-Endpoint-Received: by B4 Relay for Frank.Li@nxp.com/20240130 with auth_id=121
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add helper function imx_pcie_add_lut_by_rid(), which will be used for MSI
doorbell support in endpoint mode in the future. No functional change.

Signed-off-by: Frank Li <Frank.Li@nxp.com>
---
- change in v20
- update commit message.

change from v14 to v16
- none

change from v13 to v14
- new patch
---
 drivers/pci/controller/dwc/pci-imx6.c | 17 ++++++++++-------
 1 file changed, 10 insertions(+), 7 deletions(-)

diff --git a/drivers/pci/controller/dwc/pci-imx6.c b/drivers/pci/controller/dwc/pci-imx6.c
index 5a38cfaf989b1c9606660f2e0bcd10d88fa2d6b1..032b906c44dfaa374a32f511098402a494ef5677 100644
--- a/drivers/pci/controller/dwc/pci-imx6.c
+++ b/drivers/pci/controller/dwc/pci-imx6.c
@@ -1096,18 +1096,14 @@ static void imx_pcie_remove_lut(struct imx_pcie *imx_pcie, u16 rid)
 	}
 }
 
-static int imx_pcie_enable_device(struct pci_host_bridge *bridge,
-				  struct pci_dev *pdev)
+static int imx_pcie_add_lut_by_rid(struct imx_pcie *imx_pcie, u32 rid)
 {
-	struct imx_pcie *imx_pcie = to_imx_pcie(to_dw_pcie_from_pp(bridge->sysdata));
-	u32 sid_i, sid_m, rid = pci_dev_id(pdev);
+	struct device *dev = imx_pcie->pci->dev;
 	struct device_node *target;
-	struct device *dev;
+	u32 sid_i, sid_m;
 	int err_i, err_m;
 	u32 sid = 0;
 
-	dev = imx_pcie->pci->dev;
-
 	target = NULL;
 	err_i = of_map_id(dev->of_node, rid, "iommu-map", "iommu-map-mask",
 			  &target, &sid_i);
@@ -1182,6 +1178,13 @@ static int imx_pcie_enable_device(struct pci_host_bridge *bridge,
 	return imx_pcie_add_lut(imx_pcie, rid, sid);
 }
 
+static int imx_pcie_enable_device(struct pci_host_bridge *bridge, struct pci_dev *pdev)
+{
+	struct imx_pcie *imx_pcie = to_imx_pcie(to_dw_pcie_from_pp(bridge->sysdata));
+
+	return imx_pcie_add_lut_by_rid(imx_pcie, pci_dev_id(pdev));
+}
+
 static void imx_pcie_disable_device(struct pci_host_bridge *bridge,
 				    struct pci_dev *pdev)
 {

-- 
2.34.1

