From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Mon, 15 Jul 2024 23:03:43 +0530
Subject: [PATCH 01/14] PCI: qcom-ep: Drop the redundant masking of global
 IRQ events
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240715-pci-qcom-hotplug-v1-1-5f3765cc873a@linaro.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1233;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=JFszVo8UdO0gHsfqleLS4i4GCE2Usu+8CNRMErdZNjA=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmlV13rItBTh0MhfAGXPppt1+l62bg/bl8ERcsO
 VjhnvUm+kSJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZpVddwAKCRBVnxHm/pHO
 9SHjB/0e8TptwYDehqnWgRDkRzJphvAZdfwE2hOVtC0royHz/PfPulIXhcGq4MF3RwKOapgTpYz
 9i6j9QSlGwFUWACSbhk+dUq0JUicGsDfHBminrfzhTw++hp9lfrcfk6qXwVJWR3eDgw7DrcC5TM
 li/MLxTXGxCOsk49iE/N1ZbF3BmPgdNN9i/UqkA0Geu1HIItnvDFUe1igXC3OmThfLZ+0luFeER
 15yxARvD1+hU37iBQQcppMLRgLIyq8fn6ncavNqxGDMKpDV+CisR3j0GeVaATDtG5XOAyA1cBjK
 etXlhicihF/z2kRUp8NqGrLFom8F+U2zk+jqMYICoeweseQR
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Once the events are disabled in PARF_INT_ALL_MASK register, only the
enabled events will generate global IRQ. So there is no need to do the
masking again in the IRQ handler, drop it.

If there are any spurious IRQs getting generated, they will be reported
using the existing dev_err() in the handler.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/pci/controller/dwc/pcie-qcom-ep.c | 2 --
 1 file changed, 2 deletions(-)

diff --git a/drivers/pci/controller/dwc/pcie-qcom-ep.c b/drivers/pci/controller/dwc/pcie-qcom-ep.c
index 236229f66c80..972a90eba494 100644
--- a/drivers/pci/controller/dwc/pcie-qcom-ep.c
+++ b/drivers/pci/controller/dwc/pcie-qcom-ep.c
@@ -647,11 +647,9 @@ static irqreturn_t qcom_pcie_ep_global_irq_thread(int irq, void *data)
 	struct dw_pcie *pci = &pcie_ep->pci;
 	struct device *dev = pci->dev;
 	u32 status = readl_relaxed(pcie_ep->parf + PARF_INT_ALL_STATUS);
-	u32 mask = readl_relaxed(pcie_ep->parf + PARF_INT_ALL_MASK);
 	u32 dstate, val;
 
 	writel_relaxed(status, pcie_ep->parf + PARF_INT_ALL_CLEAR);
-	status &= mask;
 
 	if (FIELD_GET(PARF_INT_ALL_LINK_DOWN, status)) {
 		dev_dbg(dev, "Received Linkdown event\n");

-- 
2.25.1

