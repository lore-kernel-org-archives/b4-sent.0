From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Wed, 04 Sep 2024 12:41:57 +0530
Subject: [PATCH v6 1/4] PCI: dwc: Rename 'dw_pcie::link_gen' to
 'dw_pcie::max_link_speed'
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240904-pci-qcom-gen4-stability-v6-1-ec39f7ae3f62@linaro.org>
References: <20240904-pci-qcom-gen4-stability-v6-0-ec39f7ae3f62@linaro.org>
In-Reply-To: <20240904-pci-qcom-gen4-stability-v6-0-ec39f7ae3f62@linaro.org>
To: Richard Zhu <hongxing.zhu@nxp.com>, 
 Lucas Stach <l.stach@pengutronix.de>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kw@linux.com>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Shawn Guo <shawnguo@kernel.org>, Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, Jingoo Han <jingoohan1@gmail.com>, 
 Chuanhua Lei <lchuanhua@maxlinear.com>, 
 Marek Vasut <marek.vasut+renesas@gmail.com>, 
 Yoshihiro Shimoda <yoshihiro.shimoda.uh@renesas.com>
Cc: linux-pci@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 imx@lists.linux.dev, linux-kernel@vger.kernel.org, 
 linux-renesas-soc@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 abel.vesa@linaro.org, johan+linaro@kernel.org, 
 Shashank Babu Chinta Venkata <quic_schintav@quicinc.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=5727;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=aWiNeqDs5bigirpD3howq1mVNFrK/uLYTktcbZMvHKU=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBm2Ag+RQ/huPmL/69f+nym+bU5tBEsyXhyibjXl
 sjRK9oZxH2JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZtgIPgAKCRBVnxHm/pHO
 9RaYB/9TpU0/Knu+vOe356RVs8rgfPrNyFbZCuj0fjPI22qkTFXFPy1XAWuTufswsYluaIXUK2U
 j+kbjd/kBqvQH3LQhOPQZyklKTcBQGb6ytE4hgFFElO4gkqgoVQKapoVBroK0btec9PZ6YLX+Xd
 mlD9dlbllRIoarqMMzzrQQ64KU52Z8rlL2b5KMO+WIzwt1D3zcZmiOx0wMmY2z0XfD6mxA+/SLF
 0zEkZWlFP8JtEzLrYotZ2+R26j8OY1TGJYw02o04JGLLHbp1/tst1/9DGGuvX/z1wqSwM+Bfosk
 P8rKoOsP225JAetJZXNLg10lH4g6kE6eH9V2Bo6FVj0GRiU8
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

'link_gen' field is now holding the maximum supported link speed set either
by the controller driver or by DT through 'max-link-speed' property.

But the name 'link_gen' sounds like the negotiated link speed of the PCIe
link. So let's rename it to 'max_link_speed' to make it clear that it holds
the maximum supported link speed of the controller.

NOTE: For the sake of clarity, I've used 'max_link_speed' instead of
'max_link_gen'. Also the link speed and link generation values map 1:1.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/pci/controller/dwc/pci-imx6.c        |  8 ++++----
 drivers/pci/controller/dwc/pcie-designware.c | 12 ++++++------
 drivers/pci/controller/dwc/pcie-designware.h |  2 +-
 drivers/pci/controller/dwc/pcie-intel-gw.c   |  4 ++--
 drivers/pci/controller/dwc/pcie-rcar-gen4.c  |  6 +++---
 5 files changed, 16 insertions(+), 16 deletions(-)

diff --git a/drivers/pci/controller/dwc/pci-imx6.c b/drivers/pci/controller/dwc/pci-imx6.c
index 964d67756eb2..ef12a4f31740 100644
--- a/drivers/pci/controller/dwc/pci-imx6.c
+++ b/drivers/pci/controller/dwc/pci-imx6.c
@@ -847,12 +847,12 @@ static int imx6_pcie_start_link(struct dw_pcie *pci)
 	if (ret)
 		goto err_reset_phy;
 
-	if (pci->link_gen > 1) {
+	if (pci->max_link_speed > 1) {
 		/* Allow faster modes after the link is up */
 		dw_pcie_dbi_ro_wr_en(pci);
 		tmp = dw_pcie_readl_dbi(pci, offset + PCI_EXP_LNKCAP);
 		tmp &= ~PCI_EXP_LNKCAP_SLS;
-		tmp |= pci->link_gen;
+		tmp |= pci->max_link_speed;
 		dw_pcie_writel_dbi(pci, offset + PCI_EXP_LNKCAP, tmp);
 
 		/*
@@ -1386,8 +1386,8 @@ static int imx6_pcie_probe(struct platform_device *pdev)
 		imx6_pcie->tx_swing_low = 127;
 
 	/* Limit link speed */
-	pci->link_gen = 1;
-	of_property_read_u32(node, "fsl,max-link-speed", &pci->link_gen);
+	pci->max_link_speed = 1;
+	of_property_read_u32(node, "fsl,max-link-speed", &pci->max_link_speed);
 
 	imx6_pcie->vpcie = devm_regulator_get_optional(&pdev->dev, "vpcie");
 	if (IS_ERR(imx6_pcie->vpcie)) {
diff --git a/drivers/pci/controller/dwc/pcie-designware.c b/drivers/pci/controller/dwc/pcie-designware.c
index 1b5aba1f0c92..86c49ba097c6 100644
--- a/drivers/pci/controller/dwc/pcie-designware.c
+++ b/drivers/pci/controller/dwc/pcie-designware.c
@@ -166,8 +166,8 @@ int dw_pcie_get_resources(struct dw_pcie *pci)
 			return ret;
 	}
 
-	if (pci->link_gen < 1)
-		pci->link_gen = of_pci_get_max_link_speed(np);
+	if (pci->max_link_speed < 1)
+		pci->max_link_speed = of_pci_get_max_link_speed(np);
 
 	of_property_read_u32(np, "num-lanes", &pci->num_lanes);
 
@@ -687,7 +687,7 @@ void dw_pcie_upconfig_setup(struct dw_pcie *pci)
 }
 EXPORT_SYMBOL_GPL(dw_pcie_upconfig_setup);
 
-static void dw_pcie_link_set_max_speed(struct dw_pcie *pci, u32 link_gen)
+static void dw_pcie_link_set_max_speed(struct dw_pcie *pci, u32 max_link_speed)
 {
 	u32 cap, ctrl2, link_speed;
 	u8 offset = dw_pcie_find_capability(pci, PCI_CAP_ID_EXP);
@@ -696,7 +696,7 @@ static void dw_pcie_link_set_max_speed(struct dw_pcie *pci, u32 link_gen)
 	ctrl2 = dw_pcie_readl_dbi(pci, offset + PCI_EXP_LNKCTL2);
 	ctrl2 &= ~PCI_EXP_LNKCTL2_TLS;
 
-	switch (pcie_link_speed[link_gen]) {
+	switch (pcie_link_speed[max_link_speed]) {
 	case PCIE_SPEED_2_5GT:
 		link_speed = PCI_EXP_LNKCTL2_TLS_2_5GT;
 		break;
@@ -1058,8 +1058,8 @@ void dw_pcie_setup(struct dw_pcie *pci)
 {
 	u32 val;
 
-	if (pci->link_gen > 0)
-		dw_pcie_link_set_max_speed(pci, pci->link_gen);
+	if (pci->max_link_speed > 0)
+		dw_pcie_link_set_max_speed(pci, pci->max_link_speed);
 
 	/* Configure Gen1 N_FTS */
 	if (pci->n_fts[0]) {
diff --git a/drivers/pci/controller/dwc/pcie-designware.h b/drivers/pci/controller/dwc/pcie-designware.h
index 53c4c8f399c8..22765564f301 100644
--- a/drivers/pci/controller/dwc/pcie-designware.h
+++ b/drivers/pci/controller/dwc/pcie-designware.h
@@ -421,7 +421,7 @@ struct dw_pcie {
 	u32			type;
 	unsigned long		caps;
 	int			num_lanes;
-	int			link_gen;
+	int			max_link_speed;
 	u8			n_fts[2];
 	struct dw_edma_chip	edma;
 	struct clk_bulk_data	app_clks[DW_PCIE_NUM_APP_CLKS];
diff --git a/drivers/pci/controller/dwc/pcie-intel-gw.c b/drivers/pci/controller/dwc/pcie-intel-gw.c
index acbe4f6d3291..676d2aba4fbd 100644
--- a/drivers/pci/controller/dwc/pcie-intel-gw.c
+++ b/drivers/pci/controller/dwc/pcie-intel-gw.c
@@ -132,7 +132,7 @@ static void intel_pcie_link_setup(struct intel_pcie *pcie)
 
 static void intel_pcie_init_n_fts(struct dw_pcie *pci)
 {
-	switch (pci->link_gen) {
+	switch (pci->max_link_speed) {
 	case 3:
 		pci->n_fts[1] = PORT_AFR_N_FTS_GEN3;
 		break;
@@ -252,7 +252,7 @@ static int intel_pcie_wait_l2(struct intel_pcie *pcie)
 	int ret;
 	struct dw_pcie *pci = &pcie->pci;
 
-	if (pci->link_gen < 3)
+	if (pci->max_link_speed < 3)
 		return 0;
 
 	/* Send PME_TURN_OFF message */
diff --git a/drivers/pci/controller/dwc/pcie-rcar-gen4.c b/drivers/pci/controller/dwc/pcie-rcar-gen4.c
index f0f3ebd1a033..00ad4832f2cf 100644
--- a/drivers/pci/controller/dwc/pcie-rcar-gen4.c
+++ b/drivers/pci/controller/dwc/pcie-rcar-gen4.c
@@ -141,10 +141,10 @@ static int rcar_gen4_pcie_start_link(struct dw_pcie *dw)
 	}
 
 	/*
-	 * Require direct speed change with retrying here if the link_gen is
-	 * PCIe Gen2 or higher.
+	 * Require direct speed change with retrying here if the max_link_speed
+	 * is PCIe Gen2 or higher.
 	 */
-	changes = min_not_zero(dw->link_gen, RCAR_MAX_LINK_SPEED) - 1;
+	changes = min_not_zero(dw->max_link_speed, RCAR_MAX_LINK_SPEED) - 1;
 
 	/*
 	 * Since dw_pcie_setup_rc() sets it once, PCIe Gen2 will be trained.

-- 
2.25.1

