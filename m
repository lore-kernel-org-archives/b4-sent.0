From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Tue, 19 Aug 2025 12:44:55 +0530
Subject: [PATCH 6/6] PCI: qcom: Allow pwrctrl core to toggle PERST# for new
 DT binding
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250819-pci-pwrctrl-perst-v1-6-4b74978d2007@oss.qualcomm.com>
References: <20250819-pci-pwrctrl-perst-v1-0-4b74978d2007@oss.qualcomm.com>
In-Reply-To: <20250819-pci-pwrctrl-perst-v1-0-4b74978d2007@oss.qualcomm.com>
To: Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Saravana Kannan <saravanak@google.com>
Cc: linux-pci@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>, 
 Brian Norris <briannorris@chromium.org>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5088;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=JjlBWjx38dz2g5JlkdI4+4PuduQxkQpEG3znVmGrG2Y=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBopCRxDdWesNZA/yxN84cNf1qOXfKBORwCjOlct
 gQI/o+3K7CJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaKQkcQAKCRBVnxHm/pHO
 9QTXB/90jcr2+9W9VPSUmZAkfoRdCixK6wAhuBmIuLVCG2afAJFoxmwpVPTxgCd0pjv7Nr2kDxZ
 tMbFPGRgyc42NKBVxyelgytlLzh9JgqJzRyy3pEv33CLb1h4Q8Px5Onbt8vj3GAVjHCb2r+DkcV
 BF84gbkwRwtmlHqiKEd9gZCpilIESTYOyaTNNxwTVzSu79jKm/ESPp2Npa1YtrNQUQyKH3hDEVl
 IqTXYYZMTXxWRG6OIjHvy26vWa7GPcINvMzeHvWSf5y2a2EyceQabRPu4asCw72X56ZbHPM1y1H
 115eWkr454kW7fYuVJmDUh1ZijPu/2o7ERx40NrVzq5Wel0K
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If the platform is using the new DT binding, let the pwrctrl core toggle
PERST# for the device. This is achieved by populating the
'pci_host_bridge::toggle_perst' callback with qcom_pcie_toggle_perst().

qcom_pcie_toggle_perst() will find the PERST# GPIO descriptor associated
with the supplied 'device_node' and toggle PERST#. If PERST# is not found
in the supplied node, the function will look for PERST# in the parent node
as a fallback. This is needed since PERST# won't be available in the
endpoint node as per the DT binding.

Note that the driver still asserts PERST# during the controller
initialization as it is needed as per the hardware documentation. Apart
from that, the driver wouldn't touch PERST# for the new binding.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/controller/dwc/pcie-qcom.c | 70 +++++++++++++++++++++++++++++-----
 1 file changed, 61 insertions(+), 9 deletions(-)

diff --git a/drivers/pci/controller/dwc/pcie-qcom.c b/drivers/pci/controller/dwc/pcie-qcom.c
index 5d73c46095af3219687ff77e5922f08bb41e43a9..fd07cd493f9fb974acfc924778c7a5e980630ae6 100644
--- a/drivers/pci/controller/dwc/pcie-qcom.c
+++ b/drivers/pci/controller/dwc/pcie-qcom.c
@@ -294,12 +294,44 @@ struct qcom_pcie {
 
 #define to_qcom_pcie(x)		dev_get_drvdata((x)->dev)
 
-static void qcom_perst_assert(struct qcom_pcie *pcie, bool assert)
+static void qcom_toggle_perst_per_device(struct qcom_pcie *pcie,
+					 struct device_node *np, int val)
+{
+	struct gpio_desc *perst;
+	int bdf;
+
+	bdf = of_pci_get_bdf(np);
+	if (bdf < 0)
+		return;
+
+	perst = idr_find(&pcie->perst, bdf);
+	if (perst)
+		goto toggle_perst;
+
+	/*
+	 * If PERST# is not available in the current node, try the parent. This
+	 * fallback is needed if the current node belongs to an endpoint.
+	 */
+	bdf = of_pci_get_bdf(np->parent);
+	if (bdf < 0)
+		return;
+
+	perst = idr_find(&pcie->perst, bdf);
+toggle_perst:
+	/* gpiod* APIs handle NULL gpio_desc gracefully. So no need to check. */
+	gpiod_set_value_cansleep(perst, val);
+}
+
+static void qcom_perst_assert(struct qcom_pcie *pcie, struct device_node *np,
+			      bool assert)
 {
 	int val = assert ? 1 : 0;
 	struct gpio_desc *perst;
 	int bdf;
 
+	if (np)
+		return qcom_toggle_perst_per_device(pcie, np, val);
+
 	if (idr_is_empty(&pcie->perst))
 		gpiod_set_value_cansleep(pcie->reset, val);
 
@@ -307,22 +339,34 @@ static void qcom_perst_assert(struct qcom_pcie *pcie, bool assert)
 		gpiod_set_value_cansleep(perst, val);
 }
 
-static void qcom_ep_reset_assert(struct qcom_pcie *pcie)
+static void qcom_ep_reset_assert(struct qcom_pcie *pcie, struct device_node *np)
 {
-	qcom_perst_assert(pcie, true);
+	qcom_perst_assert(pcie, np, true);
 	usleep_range(PERST_DELAY_US, PERST_DELAY_US + 500);
 }
 
-static void qcom_ep_reset_deassert(struct qcom_pcie *pcie)
+static void qcom_ep_reset_deassert(struct qcom_pcie *pcie,
+				   struct device_node *np)
 {
 	struct dw_pcie_rp *pp = &pcie->pci->pp;
 
 	msleep(PCIE_T_PVPERL_MS);
-	qcom_perst_assert(pcie, false);
+	qcom_perst_assert(pcie, np, false);
 	if (!pp->use_linkup_irq)
 		msleep(PCIE_RESET_CONFIG_WAIT_MS);
 }
 
+static void qcom_pcie_toggle_perst(struct pci_host_bridge *bridge,
+				    struct device_node *np, bool assert)
+{
+	struct qcom_pcie *pcie = dev_get_drvdata(bridge->dev.parent);
+
+	if (assert)
+		qcom_ep_reset_assert(pcie, np);
+	else
+		qcom_ep_reset_deassert(pcie, np);
+}
+
 static int qcom_pcie_start_link(struct dw_pcie *pci)
 {
 	struct qcom_pcie *pcie = to_qcom_pcie(pci);
@@ -1317,7 +1361,7 @@ static int qcom_pcie_host_init(struct dw_pcie_rp *pp)
 	struct qcom_pcie *pcie = to_qcom_pcie(pci);
 	int ret;
 
-	qcom_ep_reset_assert(pcie);
+	qcom_ep_reset_assert(pcie, NULL);
 
 	ret = pcie->cfg->ops->init(pcie);
 	if (ret)
@@ -1333,7 +1377,13 @@ static int qcom_pcie_host_init(struct dw_pcie_rp *pp)
 			goto err_disable_phy;
 	}
 
-	qcom_ep_reset_deassert(pcie);
+	/*
+	 * Only deassert PERST# for all devices here if legacy binding is used.
+	 * For the new binding, pwrctrl driver is expected to toggle PERST# for
+	 * individual devices.
+	 */
+	if (idr_is_empty(&pcie->perst))
+		qcom_ep_reset_deassert(pcie, NULL);
 
 	if (pcie->cfg->ops->config_sid) {
 		ret = pcie->cfg->ops->config_sid(pcie);
@@ -1341,10 +1391,12 @@ static int qcom_pcie_host_init(struct dw_pcie_rp *pp)
 			goto err_assert_reset;
 	}
 
+	pci->pp.bridge->toggle_perst = qcom_pcie_toggle_perst;
+
 	return 0;
 
 err_assert_reset:
-	qcom_ep_reset_assert(pcie);
+	qcom_ep_reset_assert(pcie, NULL);
 err_disable_phy:
 	qcom_pcie_phy_power_off(pcie);
 err_deinit:
@@ -1358,7 +1410,7 @@ static void qcom_pcie_host_deinit(struct dw_pcie_rp *pp)
 	struct dw_pcie *pci = to_dw_pcie_from_pp(pp);
 	struct qcom_pcie *pcie = to_qcom_pcie(pci);
 
-	qcom_ep_reset_assert(pcie);
+	qcom_ep_reset_assert(pcie, NULL);
 	qcom_pcie_phy_power_off(pcie);
 	pcie->cfg->ops->deinit(pcie);
 }

-- 
2.45.2

