From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 18 May 2026 20:29:16 +0530
Subject: [PATCH v8 4/5] PCI: qcom: Add support for resetting the Root Port
 due to link down event
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260518-pci-port-reset-v8-4-eb5a7d331dfc@oss.qualcomm.com>
References: <20260518-pci-port-reset-v8-0-eb5a7d331dfc@oss.qualcomm.com>
In-Reply-To: <20260518-pci-port-reset-v8-0-eb5a7d331dfc@oss.qualcomm.com>
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
 Richard Zhu <hongxing.zhu@nxp.com>, Brian Norris <briannorris@chromium.org>, 
 Wilson Ding <dingwei@marvell.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Manivannan Sadhasivam <mani@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=8416;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=HojmREZ0jAida7uK4WRsuxfksvkybUvZ4WI0dInXW7I=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqCylVI3RliwSOZLt6TTVCbTtQuwT888ePf5R/m
 C3ypFaHFjCJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCagspVQAKCRBVnxHm/pHO
 9fhCB/wP8Xp7OPTQCp+m88qqqIaR0n3rP3pOpLtRh/DSChLRJ/weFuscoPEorBj3mimvsDVTloy
 n9LdXSLLevX0LEfWvtwKygfVXxKGF3ges5I8+E2Cbax+3DMrJB0x2QY/TsNDPgW41LJHPsSSHf8
 JCnt78lMW08OoROLip6GokyHKZieDvdgOGrXJUgpI1N3//YOIz8rCy74ZKVbTNOWTICqqQzIzEP
 eXpaVrsP4Y2eiGXel5LuEm24jBs9Vpf+ICLY0+anNlAnRWZX4ppmgPBCWWe2vgxkG6TJBFGks0o
 PCwfh7is8zBqC6bDhTnrN/+8vfWV7mhjkicNi3uqm3UP6tHO
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
core handle the link down condition. Since Qcom PCIe controllers only
support one Root Port per controller instance, the API will be called only
once. But the looping is necessary as there is no PCI API available to
fetch the Root Port instance without the child 'pci_dev'.

The API will internally call, 'pci_host_bridge::reset_root_port()' callback
to reset the Root Port in a platform specific way. So implement the
callback to reset the Root Port by first resetting the PCIe core, followed
by reinitializing the resources and then finally starting the link again.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Tested-by: Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>
---
 drivers/pci/controller/dwc/pcie-qcom.c | 143 ++++++++++++++++++++++++++++++++-
 1 file changed, 142 insertions(+), 1 deletion(-)

diff --git a/drivers/pci/controller/dwc/pcie-qcom.c b/drivers/pci/controller/dwc/pcie-qcom.c
index af6bf5cce65b..feda8abf5f85 100644
--- a/drivers/pci/controller/dwc/pcie-qcom.c
+++ b/drivers/pci/controller/dwc/pcie-qcom.c
@@ -56,6 +56,10 @@
 #define PARF_AXI_MSTR_WR_ADDR_HALT_V2		0x1a8
 #define PARF_Q2A_FLUSH				0x1ac
 #define PARF_LTSSM				0x1b0
+#define PARF_INT_ALL_STATUS			0x224
+#define PARF_INT_ALL_CLEAR			0x228
+#define PARF_INT_ALL_MASK			0x22c
+#define PARF_STATUS				0x230
 #define PARF_SID_OFFSET				0x234
 #define PARF_BDF_TRANSLATE_CFG			0x24c
 #define PARF_DBI_BASE_ADDR_V2			0x350
@@ -131,6 +135,13 @@
 
 /* PARF_LTSSM register fields */
 #define LTSSM_EN				BIT(8)
+#define SW_CLEAR_FLUSH_MODE			BIT(10)
+#define FLUSH_MODE				BIT(11)
+
+/* PARF_INT_ALL_{STATUS/CLEAR/MASK} register fields */
+#define INT_ALL_LINK_DOWN			1
+#define PARF_INT_ALL_LINK_DOWN			BIT(INT_ALL_LINK_DOWN)
+#define PARF_INT_MSI_DEV_0_7			GENMASK(30, 23)
 
 /* PARF_NO_SNOOP_OVERRIDE register fields */
 #define WR_NO_SNOOP_OVERRIDE_EN			BIT(1)
@@ -142,6 +153,9 @@
 /* PARF_BDF_TO_SID_CFG fields */
 #define BDF_TO_SID_BYPASS			BIT(0)
 
+/* PARF_STATUS fields */
+#define FLUSH_COMPLETED				BIT(8)
+
 /* ELBI_SYS_CTRL register fields */
 #define ELBI_SYS_CTRL_LT_ENABLE			BIT(0)
 
@@ -166,6 +180,7 @@
 						PCIE_CAP_SLOT_POWER_LIMIT_SCALE)
 
 #define PERST_DELAY_US				1000
+#define FLUSH_TIMEOUT_US			100
 
 #define QCOM_PCIE_CRC8_POLYNOMIAL		(BIT(2) | BIT(1) | BIT(0))
 
@@ -282,11 +297,14 @@ struct qcom_pcie {
 	const struct qcom_pcie_cfg *cfg;
 	struct dentry *debugfs;
 	struct list_head ports;
+	int global_irq;
 	bool suspended;
 	bool use_pm_opp;
 };
 
 #define to_qcom_pcie(x)		dev_get_drvdata((x)->dev)
+static int qcom_pcie_reset_root_port(struct pci_host_bridge *bridge,
+				  struct pci_dev *pdev);
 
 static void __qcom_pcie_perst_assert(struct qcom_pcie *pcie, bool assert)
 {
@@ -1330,6 +1348,8 @@ static int qcom_pcie_host_init(struct dw_pcie_rp *pp)
 			goto err_assert_reset;
 	}
 
+	pp->bridge->reset_root_port = qcom_pcie_reset_root_port;
+
 	return 0;
 
 err_assert_reset:
@@ -1613,6 +1633,78 @@ static void qcom_pcie_icc_opp_update(struct qcom_pcie *pcie)
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
+		writel_relaxed(PARF_INT_ALL_LINK_DOWN | PARF_INT_MSI_DEV_0_7,
+				pcie->parf + PARF_INT_ALL_MASK);
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
@@ -1650,6 +1742,27 @@ static void qcom_pcie_init_debugfs(struct qcom_pcie *pcie)
 				    qcom_pcie_link_transition_count);
 }
 
+static irqreturn_t qcom_pcie_global_irq_thread(int irq, void *data)
+{
+	struct qcom_pcie *pcie = data;
+	struct dw_pcie_rp *pp = &pcie->pci->pp;
+	struct device *dev = pcie->pci->dev;
+	struct pci_dev *port;
+	unsigned long status = readl_relaxed(pcie->parf + PARF_INT_ALL_STATUS);
+
+	writel_relaxed(status, pcie->parf + PARF_INT_ALL_CLEAR);
+
+	if (test_and_clear_bit(INT_ALL_LINK_DOWN, &status)) {
+		dev_dbg(dev, "Received Link down event\n");
+		for_each_pci_bridge(port, pp->bridge->bus) {
+			if (pci_pcie_type(port) == PCI_EXP_TYPE_ROOT_PORT)
+				pci_host_handle_link_down(port);
+		}
+	}
+
+	return IRQ_HANDLED;
+}
+
 static void qcom_pci_free_msi(void *ptr)
 {
 	struct dw_pcie_rp *pp = (struct dw_pcie_rp *)ptr;
@@ -1852,7 +1965,7 @@ static int qcom_pcie_probe(struct platform_device *pdev)
 	struct dw_pcie_rp *pp;
 	struct resource *res;
 	struct dw_pcie *pci;
-	int ret;
+	int ret, irq;
 
 	pcie_cfg = of_device_get_match_data(dev);
 	if (!pcie_cfg) {
@@ -2009,6 +2122,32 @@ static int qcom_pcie_probe(struct platform_device *pdev)
 		goto err_phy_exit;
 	}
 
+	irq = platform_get_irq_byname_optional(pdev, "global");
+	if (irq > 0) {
+		const char *name;
+
+		name = devm_kasprintf(dev, GFP_KERNEL, "qcom_pcie_global_irq%d",
+				      pci_domain_nr(pp->bridge->bus));
+		if (!name) {
+			ret = -ENOMEM;
+			goto err_host_deinit;
+		}
+
+		ret = devm_request_threaded_irq(&pdev->dev, irq, NULL,
+						qcom_pcie_global_irq_thread,
+						IRQF_ONESHOT, name, pcie);
+		if (ret) {
+			dev_err_probe(&pdev->dev, ret,
+				      "Failed to request Global IRQ\n");
+			goto err_host_deinit;
+		}
+
+		writel_relaxed(PARF_INT_ALL_LINK_DOWN | PARF_INT_MSI_DEV_0_7,
+				pcie->parf + PARF_INT_ALL_MASK);
+
+		pcie->global_irq = irq;
+	}
+
 	qcom_pcie_icc_opp_update(pcie);
 
 	if (pcie->mhi)
@@ -2016,6 +2155,8 @@ static int qcom_pcie_probe(struct platform_device *pdev)
 
 	return 0;
 
+err_host_deinit:
+	dw_pcie_host_deinit(pp);
 err_phy_exit:
 	list_for_each_entry_safe(port, tmp_port, &pcie->ports, list) {
 		list_for_each_entry_safe(perst, tmp_perst, &port->perst, list)

-- 
2.48.1

