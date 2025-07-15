From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Tue, 15 Jul 2025 19:51:06 +0530
Subject: [PATCH v6 3/4] PCI: qcom: Add support for resetting the Root Port
 due to link down event
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250715-pci-port-reset-v6-3-6f9cce94e7bb@oss.qualcomm.com>
References: <20250715-pci-port-reset-v6-0-6f9cce94e7bb@oss.qualcomm.com>
In-Reply-To: <20250715-pci-port-reset-v6-0-6f9cce94e7bb@oss.qualcomm.com>
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Mahesh J Salgaonkar <mahesh@linux.ibm.com>, 
 Oliver O'Halloran <oohall@gmail.com>, Will Deacon <will@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Heiko Stuebner <heiko@sntech.de>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linuxppc-dev@lists.ozlabs.org, linux-arm-kernel@lists.infradead.org, 
 linux-arm-msm@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 Niklas Cassel <cassel@kernel.org>, 
 Wilfred Mallawa <wilfred.mallawa@wdc.com>, 
 Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>, 
 mani@kernel.org, Lukas Wunner <lukas@wunner.de>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Manivannan Sadhasivam <mani@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=8942;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=hcHUE0Es+rhE1k65uaN43jzCwIv2KxCfrP4I/tTARuY=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBodmPU7h4g+XiDGSCp70X2Mbn0SjERWhtNglsfA
 wwuX+QzMCqJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaHZj1AAKCRBVnxHm/pHO
 9c1aB/9ZXgau1A2R7jRCcx+v1G7ANPo8guKtUwp2ehiqWQZH7I+bAbr2CbE1DDDZ5RgitzGddvx
 HYya5RGzlC4C8gWmM2liAGPGzVK7KybirCIp5xRctnMMKJPe3iVSQFT/UHNA0tG5E5rWjOtKqK3
 6Uo52UtsP2MNZbfO0/ouFqwC0glZysSfSJdQkaAu6Rj0KOLGA7rMgcBpVtonP/od+SjskcHasqI
 Yf2fVhIuc3QK216G+MzLYQ6QXbkGbcrxI9B/35VdHaHejwrGhIfSE72OGqlNqSaP/18Papfvh9q
 NPrTgY7xRKJx0jaJt6MpEtsItzJb4zj2D7QzVb/TboVhufYU
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Manivannan Sadhasivam <mani@kernel.org>

The PCIe link can go down under circumstances such as the device firmware
crash, link instability, etc... When that happens, the PCIe Root Port needs
to be reset to make it operational again. Currently, the driver is not
handling the link down event, due to which the users have to restart the
machine to make PCIe link operational again. So fix it by detecting the
link down event and resetting the Root Port.

Since the Qcom PCIe controllers report the link down event through the
'global' IRQ, enable the link down event by setting PARF_INT_ALL_LINK_DOWN
bit in PARF_INT_ALL_MASK register.

In the case of the event, iterate through the available Root Ports and call
pci_host_handle_link_down() API with Root Port 'pci_dev' to let the PCI
core handle the link down condition. Note that both link up and link down
events could be set at a time when the handler runs. So always handle link
down first. Since Qcom PCIe controllers only support one Root Port per
controller instance, the API will be called only once. But the looping is
necessary as there is no PCI API available to fetch the Root Port instance
without the child 'pci_dev'.

The API will internally call, 'pci_host_bridge::reset_root_port()' callback
to reset the Root Port in a platform specific way. So implement the
callback to reset the Root Port by first resetting the PCIe core, followed
by reinitializing the resources and then finally starting the link again.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/controller/dwc/Kconfig     |   1 +
 drivers/pci/controller/dwc/pcie-qcom.c | 120 ++++++++++++++++++++++++++++++---
 2 files changed, 113 insertions(+), 8 deletions(-)

diff --git a/drivers/pci/controller/dwc/Kconfig b/drivers/pci/controller/dwc/Kconfig
index d9f0386396edf66ad0e514a0f545ed24d89fcb6c..ce04ee6fbd99cbcce5d2f3a75ebd72a17070b7b7 100644
--- a/drivers/pci/controller/dwc/Kconfig
+++ b/drivers/pci/controller/dwc/Kconfig
@@ -296,6 +296,7 @@ config PCIE_QCOM
 	select PCIE_DW_HOST
 	select CRC8
 	select PCIE_QCOM_COMMON
+	select PCI_HOST_COMMON
 	help
 	  Say Y here to enable PCIe controller support on Qualcomm SoCs. The
 	  PCIe controller uses the DesignWare core plus Qualcomm-specific
diff --git a/drivers/pci/controller/dwc/pcie-qcom.c b/drivers/pci/controller/dwc/pcie-qcom.c
index c789e3f856550bcfa1ce09962ba9c086d117de05..5f7b2b80aace742780e5bc5b479f4f64ab778453 100644
--- a/drivers/pci/controller/dwc/pcie-qcom.c
+++ b/drivers/pci/controller/dwc/pcie-qcom.c
@@ -34,6 +34,7 @@
 #include <linux/units.h>
 
 #include "../../pci.h"
+#include "../pci-host-common.h"
 #include "pcie-designware.h"
 #include "pcie-qcom-common.h"
 
@@ -55,6 +56,7 @@
 #define PARF_INT_ALL_STATUS			0x224
 #define PARF_INT_ALL_CLEAR			0x228
 #define PARF_INT_ALL_MASK			0x22c
+#define PARF_STATUS				0x230
 #define PARF_SID_OFFSET				0x234
 #define PARF_BDF_TRANSLATE_CFG			0x24c
 #define PARF_DBI_BASE_ADDR_V2			0x350
@@ -130,9 +132,14 @@
 
 /* PARF_LTSSM register fields */
 #define LTSSM_EN				BIT(8)
+#define SW_CLEAR_FLUSH_MODE			BIT(10)
+#define FLUSH_MODE				BIT(11)
 
 /* PARF_INT_ALL_{STATUS/CLEAR/MASK} register fields */
-#define PARF_INT_ALL_LINK_UP			BIT(13)
+#define INT_ALL_LINK_DOWN			1
+#define INT_ALL_LINK_UP				13
+#define PARF_INT_ALL_LINK_DOWN			BIT(INT_ALL_LINK_DOWN)
+#define PARF_INT_ALL_LINK_UP			BIT(INT_ALL_LINK_UP)
 #define PARF_INT_MSI_DEV_0_7			GENMASK(30, 23)
 
 /* PARF_NO_SNOOP_OVERRIDE register fields */
@@ -145,6 +152,9 @@
 /* PARF_BDF_TO_SID_CFG fields */
 #define BDF_TO_SID_BYPASS			BIT(0)
 
+/* PARF_STATUS fields */
+#define FLUSH_COMPLETED				BIT(8)
+
 /* ELBI_SYS_CTRL register fields */
 #define ELBI_SYS_CTRL_LT_ENABLE			BIT(0)
 
@@ -169,6 +179,7 @@
 						PCIE_CAP_SLOT_POWER_LIMIT_SCALE)
 
 #define PERST_DELAY_US				1000
+#define FLUSH_TIMEOUT_US			100
 
 #define QCOM_PCIE_CRC8_POLYNOMIAL		(BIT(2) | BIT(1) | BIT(0))
 
@@ -274,11 +285,14 @@ struct qcom_pcie {
 	struct icc_path *icc_cpu;
 	const struct qcom_pcie_cfg *cfg;
 	struct dentry *debugfs;
+	int global_irq;
 	bool suspended;
 	bool use_pm_opp;
 };
 
 #define to_qcom_pcie(x)		dev_get_drvdata((x)->dev)
+static int qcom_pcie_reset_root_port(struct pci_host_bridge *bridge,
+				  struct pci_dev *pdev);
 
 static void qcom_ep_reset_assert(struct qcom_pcie *pcie)
 {
@@ -1263,6 +1277,8 @@ static int qcom_pcie_host_init(struct dw_pcie_rp *pp)
 			goto err_assert_reset;
 	}
 
+	pp->bridge->reset_root_port = qcom_pcie_reset_root_port;
+
 	return 0;
 
 err_assert_reset:
@@ -1517,6 +1533,78 @@ static void qcom_pcie_icc_opp_update(struct qcom_pcie *pcie)
 	}
 }
 
+/*
+ * Qcom PCIe controllers only support one Root Port per controller instance. So
+ * this function ignores the 'pci_dev' associated with the Root Port and just
+ * resets the host bridge, which in turn resets the Root Port also.
+ */
+static int qcom_pcie_reset_root_port(struct pci_host_bridge *bridge,
+				  struct pci_dev *pdev)
+{
+	struct pci_bus *bus = bridge->bus;
+	struct dw_pcie_rp *pp = bus->sysdata;
+	struct dw_pcie *pci = to_dw_pcie_from_pp(pp);
+	struct qcom_pcie *pcie = to_qcom_pcie(pci);
+	struct device *dev = pcie->pci->dev;
+	u32 val;
+	int ret;
+
+	/* Wait for the pending transactions to be completed */
+	ret = readl_relaxed_poll_timeout(pcie->parf + PARF_STATUS, val,
+					 val & FLUSH_COMPLETED, 10,
+					 FLUSH_TIMEOUT_US);
+	if (ret) {
+		dev_err(dev, "Flush completion failed: %d\n", ret);
+		goto err_host_deinit;
+	}
+
+	/* Clear the FLUSH_MODE to allow the core to be reset */
+	val = readl(pcie->parf + PARF_LTSSM);
+	val |= SW_CLEAR_FLUSH_MODE;
+	writel(val, pcie->parf + PARF_LTSSM);
+
+	/* Wait for the FLUSH_MODE to clear */
+	ret = readl_relaxed_poll_timeout(pcie->parf + PARF_LTSSM, val,
+					 !(val & FLUSH_MODE), 10,
+					 FLUSH_TIMEOUT_US);
+	if (ret) {
+		dev_err(dev, "Flush mode clear failed: %d\n", ret);
+		goto err_host_deinit;
+	}
+
+	qcom_pcie_host_deinit(pp);
+
+	ret = qcom_pcie_host_init(pp);
+	if (ret) {
+		dev_err(dev, "Host init failed\n");
+		return ret;
+	}
+
+	ret = dw_pcie_setup_rc(pp);
+	if (ret)
+		goto err_host_deinit;
+
+	/*
+	 * Re-enable global IRQ events as the PARF_INT_ALL_MASK register is
+	 * non-sticky.
+	 */
+	if (pcie->global_irq)
+		writel_relaxed(PARF_INT_ALL_LINK_UP | PARF_INT_ALL_LINK_DOWN |
+			       PARF_INT_MSI_DEV_0_7, pcie->parf + PARF_INT_ALL_MASK);
+
+	qcom_pcie_start_link(pci);
+	dw_pcie_wait_for_link(pci);
+
+	dev_dbg(dev, "Root Port reset completed\n");
+
+	return 0;
+
+err_host_deinit:
+	qcom_pcie_host_deinit(pp);
+
+	return ret;
+}
+
 static int qcom_pcie_link_transition_count(struct seq_file *s, void *data)
 {
 	struct qcom_pcie *pcie = (struct qcom_pcie *)dev_get_drvdata(s->private);
@@ -1559,11 +1647,24 @@ static irqreturn_t qcom_pcie_global_irq_thread(int irq, void *data)
 	struct qcom_pcie *pcie = data;
 	struct dw_pcie_rp *pp = &pcie->pci->pp;
 	struct device *dev = pcie->pci->dev;
-	u32 status = readl_relaxed(pcie->parf + PARF_INT_ALL_STATUS);
+	struct pci_dev *port;
+	unsigned long status = readl_relaxed(pcie->parf + PARF_INT_ALL_STATUS);
 
 	writel_relaxed(status, pcie->parf + PARF_INT_ALL_CLEAR);
 
-	if (FIELD_GET(PARF_INT_ALL_LINK_UP, status)) {
+	/*
+	 * It is possible that both Link Up and Link Down events might have
+	 * happended. So always handle Link Down first.
+	 */
+	if (test_and_clear_bit(INT_ALL_LINK_DOWN, &status)) {
+		dev_dbg(dev, "Received Link down event\n");
+		for_each_pci_bridge(port, pp->bridge->bus) {
+			if (pci_pcie_type(port) == PCI_EXP_TYPE_ROOT_PORT)
+				pci_host_handle_link_down(port);
+		}
+	}
+
+	if (test_and_clear_bit(INT_ALL_LINK_UP, &status)) {
 		dev_dbg(dev, "Received Link up event. Starting enumeration!\n");
 		/* Rescan the bus to enumerate endpoint devices */
 		pci_lock_rescan_remove();
@@ -1571,11 +1672,12 @@ static irqreturn_t qcom_pcie_global_irq_thread(int irq, void *data)
 		pci_unlock_rescan_remove();
 
 		qcom_pcie_icc_opp_update(pcie);
-	} else {
-		dev_WARN_ONCE(dev, 1, "Received unknown event. INT_STATUS: 0x%08x\n",
-			      status);
 	}
 
+	if (status)
+		dev_WARN_ONCE(dev, 1, "Received unknown event. INT_STATUS: 0x%08x\n",
+			      (u32) status);
+
 	return IRQ_HANDLED;
 }
 
@@ -1732,8 +1834,10 @@ static int qcom_pcie_probe(struct platform_device *pdev)
 			goto err_host_deinit;
 		}
 
-		writel_relaxed(PARF_INT_ALL_LINK_UP | PARF_INT_MSI_DEV_0_7,
-			       pcie->parf + PARF_INT_ALL_MASK);
+		writel_relaxed(PARF_INT_ALL_LINK_UP | PARF_INT_ALL_LINK_DOWN |
+			       PARF_INT_MSI_DEV_0_7, pcie->parf + PARF_INT_ALL_MASK);
+
+		pcie->global_irq = irq;
 	}
 
 	qcom_pcie_icc_opp_update(pcie);

-- 
2.45.2

