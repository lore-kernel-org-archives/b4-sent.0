From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Wed, 07 Jan 2026 13:41:59 +0530
Subject: [PATCH v4 6/6] PCI: dwc: Skip failure during
 dw_pcie_resume_noirq() if no device is available
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260107-pci-dwc-suspend-rework-v4-6-9b5f3c72df0a@oss.qualcomm.com>
References: <20260107-pci-dwc-suspend-rework-v4-0-9b5f3c72df0a@oss.qualcomm.com>
In-Reply-To: <20260107-pci-dwc-suspend-rework-v4-0-9b5f3c72df0a@oss.qualcomm.com>
To: Jingoo Han <jingoohan1@gmail.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 vincent.guittot@linaro.org, zhangsenchuan@eswincomputing.com, 
 Shawn Lin <shawn.lin@rock-chips.com>, Richard Zhu <hongxing.zhu@nxp.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2136;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=A+dYXc5n837LUvYZ/2oH3XrvOeQd2MIwA/IwRECz2uo=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpXhVOUjSqOMt6oipJjhHgmBL0+vEUiOzLr77dK
 o/yZ0+6BlCJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaV4VTgAKCRBVnxHm/pHO
 9SdDB/sGCaPHvWbzjXbEQqHunIZGnTeF+jfGN8X1HvypQRxSWaoCrN9PnHi7fF7M+jLrmu4Vqei
 m0LaOVq3Giiu0o6UW2kqQWcYlNjZRQXvKH9VkTX+fAgE+guRIXtiKQXmfcuyhxggZtgvJSyVP7t
 B3AsEKuKKTzyCCEGQrX/uIEgpVs56RfU5u4tSFJKbdiqchedKmuz7DDghmf7/VIJcBFQLQW1Xwq
 PPPDUx30SHfrnCzcrbGNSS7ECaJxbjE9cGPE9D9eS06eeQznMAhBdi/v1ivyAPWRbx4qQrOQG/1
 54RUjRClQzvsILf5oV6wviHq4rb2mi7WLJiYEuEKedS4t79I
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If there is no device attached to any of the Root Ports available under the
Root bus before suspend and during resume, then there is no point in
returning failure.

So skip returning failure so that the resume succeeds and allow the device
to get attached later.

If there was a device before suspend and not available during resume, then
propagate the error to indicate that the device got removed during suspend.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/controller/dwc/pcie-designware-host.c | 17 ++++++++++++-----
 1 file changed, 12 insertions(+), 5 deletions(-)

diff --git a/drivers/pci/controller/dwc/pcie-designware-host.c b/drivers/pci/controller/dwc/pcie-designware-host.c
index ccde12b85463..c30a2ed324cd 100644
--- a/drivers/pci/controller/dwc/pcie-designware-host.c
+++ b/drivers/pci/controller/dwc/pcie-designware-host.c
@@ -20,6 +20,7 @@
 #include <linux/platform_device.h>
 
 #include "../../pci.h"
+#include "../pci-host-common.h"
 #include "pcie-designware.h"
 
 static struct pci_ops dw_pcie_ops;
@@ -1227,6 +1228,7 @@ EXPORT_SYMBOL_GPL(dw_pcie_suspend_noirq);
 
 int dw_pcie_resume_noirq(struct dw_pcie *pci)
 {
+	struct dw_pcie_rp *pp = &pci->pp;
 	int ret;
 
 	if (!pci->suspended)
@@ -1234,23 +1236,28 @@ int dw_pcie_resume_noirq(struct dw_pcie *pci)
 
 	pci->suspended = false;
 
-	if (pci->pp.ops->init) {
-		ret = pci->pp.ops->init(&pci->pp);
+	if (pp->ops->init) {
+		ret = pp->ops->init(pp);
 		if (ret) {
 			dev_err(pci->dev, "Host init failed: %d\n", ret);
 			return ret;
 		}
 	}
 
-	dw_pcie_setup_rc(&pci->pp);
+	dw_pcie_setup_rc(pp);
 
 	ret = dw_pcie_start_link(pci);
 	if (ret)
 		return ret;
 
 	ret = dw_pcie_wait_for_link(pci);
-	if (ret)
-		return ret;
+	/*
+	 * Skip failure if there is no device attached to the bus now and before
+	 * suspend. But the error should be returned if a device was attached
+	 * before suspend and not available now.
+	 */
+	if (ret == -ENODEV && !pci_root_ports_have_device(pp->bridge->bus))
+		return 0;
 
 	return ret;
 }

-- 
2.48.1

