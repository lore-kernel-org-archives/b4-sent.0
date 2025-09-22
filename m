From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 22 Sep 2025 21:46:45 +0530
Subject: [PATCH v2 2/2] PCI: qcom: Remove the custom ASPM enablement code
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250922-pci-dt-aspm-v2-2-2a65cf84e326@oss.qualcomm.com>
References: <20250922-pci-dt-aspm-v2-0-2a65cf84e326@oss.qualcomm.com>
In-Reply-To: <20250922-pci-dt-aspm-v2-0-2a65cf84e326@oss.qualcomm.com>
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, "David E. Box" <david.e.box@linux.intel.com>, 
 Kai-Heng Feng <kai.heng.feng@canonical.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Chia-Lin Kao <acelan.kao@canonical.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3174;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=tvss3MdfYHL+rXNvlS+8nnRAEkq4Tu6jTREwynbA5UI=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBo0XZ0zMPEa/DPJ+/ZwL1+RCq8cOUUe8oEBjqgD
 MnAAtPBIMSJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaNF2dAAKCRBVnxHm/pHO
 9RYKB/9IT1Etlbn5Ys0d/XY24CXy3zkX6IKyRfYR1n1iRay5ZzhNSw3l8xWyKGzikZhWbZKvqCN
 YFb4fC/NV2gRjhsUUL78m0950MpeXr7LsIw//RAVZoHXCsbj6nVGq8A+uBSN4B9s9t2E8O6xTeu
 zn+ufAd3a1LhgLxmzLrEVXe9Dp3DHdi9F5JxMC4jXhX1QJ4xiQI4iMkwEJAOoZQaPm21/XV6TTF
 aRWtnJxR/DTo5hXi7swpOxEdC7ToW8sgb8z49qDWWk7BE2m5WOd3g/9FX7OAxGP/63Xzm4JYRg9
 w2gqZY7EgfwuNYrphxzXvjgzEHnAToXve4Xsweck19w9g0iI
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since the PCI subsystem has started enabling all ASPM states for all
devicetree based platforms, the ASPM enablement code from this driver can
now be dropped.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Link: https://patch.msgid.link/20250916-pci-dt-aspm-v1-2-778fe907c9ad@oss.qualcomm.com
---
 drivers/pci/controller/dwc/pcie-qcom.c | 32 --------------------------------
 1 file changed, 32 deletions(-)

diff --git a/drivers/pci/controller/dwc/pcie-qcom.c b/drivers/pci/controller/dwc/pcie-qcom.c
index 294babe1816e4d0c2b2343fe22d89af72afcd6cd..a1c4a9c31f9241e9ca679533323e33c0b972e678 100644
--- a/drivers/pci/controller/dwc/pcie-qcom.c
+++ b/drivers/pci/controller/dwc/pcie-qcom.c
@@ -247,7 +247,6 @@ struct qcom_pcie_ops {
 	int (*get_resources)(struct qcom_pcie *pcie);
 	int (*init)(struct qcom_pcie *pcie);
 	int (*post_init)(struct qcom_pcie *pcie);
-	void (*host_post_init)(struct qcom_pcie *pcie);
 	void (*deinit)(struct qcom_pcie *pcie);
 	void (*ltssm_enable)(struct qcom_pcie *pcie);
 	int (*config_sid)(struct qcom_pcie *pcie);
@@ -1040,25 +1039,6 @@ static int qcom_pcie_post_init_2_7_0(struct qcom_pcie *pcie)
 	return 0;
 }
 
-static int qcom_pcie_enable_aspm(struct pci_dev *pdev, void *userdata)
-{
-	/*
-	 * Downstream devices need to be in D0 state before enabling PCI PM
-	 * substates.
-	 */
-	pci_set_power_state_locked(pdev, PCI_D0);
-	pci_enable_link_state_locked(pdev, PCIE_LINK_STATE_ALL);
-
-	return 0;
-}
-
-static void qcom_pcie_host_post_init_2_7_0(struct qcom_pcie *pcie)
-{
-	struct dw_pcie_rp *pp = &pcie->pci->pp;
-
-	pci_walk_bus(pp->bridge->bus, qcom_pcie_enable_aspm, NULL);
-}
-
 static void qcom_pcie_deinit_2_7_0(struct qcom_pcie *pcie)
 {
 	struct qcom_pcie_resources_2_7_0 *res = &pcie->res.v2_7_0;
@@ -1358,19 +1338,9 @@ static void qcom_pcie_host_deinit(struct dw_pcie_rp *pp)
 	pcie->cfg->ops->deinit(pcie);
 }
 
-static void qcom_pcie_host_post_init(struct dw_pcie_rp *pp)
-{
-	struct dw_pcie *pci = to_dw_pcie_from_pp(pp);
-	struct qcom_pcie *pcie = to_qcom_pcie(pci);
-
-	if (pcie->cfg->ops->host_post_init)
-		pcie->cfg->ops->host_post_init(pcie);
-}
-
 static const struct dw_pcie_host_ops qcom_pcie_dw_ops = {
 	.init		= qcom_pcie_host_init,
 	.deinit		= qcom_pcie_host_deinit,
-	.post_init	= qcom_pcie_host_post_init,
 };
 
 /* Qcom IP rev.: 2.1.0	Synopsys IP rev.: 4.01a */
@@ -1432,7 +1402,6 @@ static const struct qcom_pcie_ops ops_1_9_0 = {
 	.get_resources = qcom_pcie_get_resources_2_7_0,
 	.init = qcom_pcie_init_2_7_0,
 	.post_init = qcom_pcie_post_init_2_7_0,
-	.host_post_init = qcom_pcie_host_post_init_2_7_0,
 	.deinit = qcom_pcie_deinit_2_7_0,
 	.ltssm_enable = qcom_pcie_2_3_2_ltssm_enable,
 	.config_sid = qcom_pcie_config_sid_1_9_0,
@@ -1443,7 +1412,6 @@ static const struct qcom_pcie_ops ops_1_21_0 = {
 	.get_resources = qcom_pcie_get_resources_2_7_0,
 	.init = qcom_pcie_init_2_7_0,
 	.post_init = qcom_pcie_post_init_2_7_0,
-	.host_post_init = qcom_pcie_host_post_init_2_7_0,
 	.deinit = qcom_pcie_deinit_2_7_0,
 	.ltssm_enable = qcom_pcie_2_3_2_ltssm_enable,
 };

-- 
2.48.1

