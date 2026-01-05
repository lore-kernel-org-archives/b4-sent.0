From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 05 Jan 2026 19:25:48 +0530
Subject: [PATCH v4 8/8] PCI: qcom: Rename PERST# assert/deassert helpers
 for uniformity
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260105-pci-pwrctrl-rework-v4-8-6d41a7a49789@oss.qualcomm.com>
References: <20260105-pci-pwrctrl-rework-v4-0-6d41a7a49789@oss.qualcomm.com>
In-Reply-To: <20260105-pci-pwrctrl-rework-v4-0-6d41a7a49789@oss.qualcomm.com>
To: Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>
Cc: linux-pci@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Chen-Yu Tsai <wens@kernel.org>, 
 Brian Norris <briannorris@chromium.org>, 
 Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>, 
 Niklas Cassel <cassel@kernel.org>, Alex Elder <elder@riscstar.com>, 
 Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2860;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=NsPRggmF+WutEVzxJ+1fg6OdEWz3rN72PxavsxzAJAM=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpW8LyZODhEFyx8+ElbRBxZdd+zdYJojC1HeXrE
 ARGhMlm0ruJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaVvC8gAKCRBVnxHm/pHO
 9So/CACVFKIGwH6FtZVklizuGvtAsCqKZFrdwyrZWHIbr7YAKwWguXf2lI7kd/bGYZqXWNPCoaw
 lC6txH3YOPZmpwXiCE9d5wzXb5EhribQdfZPpbOWA3qe25HACIteCkCV2MpQsQk+HfFgc/63auN
 MM5dOVCHcUKEqyhI4MVFnU88RJpMpufhRrh8UqOifnpVedLR7O8yR02E+URioBsZbGo38+yUHpW
 zEQRbJStuV/ET5+737zK2b+GYSgWuNfcZKXlEfnR/EM+tu/10l3xIgFSfpJolC1XJpD7dUn9n94
 7WojLFtU26zOn3I0Wji1uNOS7SjLJuPdIbnVMi3OdgmIbgxG
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Rename the PERST# assert/deassert helpers from
qcom_ep_reset_{assert/deassert}() to qcom_pcie_perst_{assert/deassert}() to
maintain uniformity.

Reviewed-by: Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/controller/dwc/pcie-qcom.c | 18 +++++++++---------
 1 file changed, 9 insertions(+), 9 deletions(-)

diff --git a/drivers/pci/controller/dwc/pcie-qcom.c b/drivers/pci/controller/dwc/pcie-qcom.c
index 6de3ff555b9d..a9293502e565 100644
--- a/drivers/pci/controller/dwc/pcie-qcom.c
+++ b/drivers/pci/controller/dwc/pcie-qcom.c
@@ -295,7 +295,7 @@ struct qcom_pcie {
 
 #define to_qcom_pcie(x)		dev_get_drvdata((x)->dev)
 
-static void qcom_perst_assert(struct qcom_pcie *pcie, bool assert)
+static void __qcom_pcie_perst_assert(struct qcom_pcie *pcie, bool assert)
 {
 	struct qcom_pcie_perst *perst;
 	struct qcom_pcie_port *port;
@@ -309,16 +309,16 @@ static void qcom_perst_assert(struct qcom_pcie *pcie, bool assert)
 	usleep_range(PERST_DELAY_US, PERST_DELAY_US + 500);
 }
 
-static void qcom_ep_reset_assert(struct qcom_pcie *pcie)
+static void qcom_pcie_perst_assert(struct qcom_pcie *pcie)
 {
-	qcom_perst_assert(pcie, true);
+	__qcom_pcie_perst_assert(pcie, true);
 }
 
-static void qcom_ep_reset_deassert(struct qcom_pcie *pcie)
+static void qcom_pcie_perst_deassert(struct qcom_pcie *pcie)
 {
 	/* Ensure that PERST has been asserted for at least 100 ms */
 	msleep(PCIE_T_PVPERL_MS);
-	qcom_perst_assert(pcie, false);
+	__qcom_pcie_perst_assert(pcie, false);
 }
 
 static int qcom_pcie_start_link(struct dw_pcie *pci)
@@ -1296,7 +1296,7 @@ static int qcom_pcie_host_init(struct dw_pcie_rp *pp)
 	struct qcom_pcie *pcie = to_qcom_pcie(pci);
 	int ret;
 
-	qcom_ep_reset_assert(pcie);
+	qcom_pcie_perst_assert(pcie);
 
 	ret = pcie->cfg->ops->init(pcie);
 	if (ret)
@@ -1322,7 +1322,7 @@ static int qcom_pcie_host_init(struct dw_pcie_rp *pp)
 
 	qcom_pcie_clear_aspm_l0s(pcie->pci);
 
-	qcom_ep_reset_deassert(pcie);
+	qcom_pcie_perst_deassert(pcie);
 
 	if (pcie->cfg->ops->config_sid) {
 		ret = pcie->cfg->ops->config_sid(pcie);
@@ -1333,7 +1333,7 @@ static int qcom_pcie_host_init(struct dw_pcie_rp *pp)
 	return 0;
 
 err_assert_reset:
-	qcom_ep_reset_assert(pcie);
+	qcom_pcie_perst_assert(pcie);
 err_pwrctrl_power_off:
 	pci_pwrctrl_power_off_devices(pci->dev);
 err_pwrctrl_destroy:
@@ -1352,7 +1352,7 @@ static void qcom_pcie_host_deinit(struct dw_pcie_rp *pp)
 	struct dw_pcie *pci = to_dw_pcie_from_pp(pp);
 	struct qcom_pcie *pcie = to_qcom_pcie(pci);
 
-	qcom_ep_reset_assert(pcie);
+	qcom_pcie_perst_assert(pcie);
 	/*
 	 * No need to destroy pwrctrl devices as this function only gets called
 	 * during system suspend as of now.

-- 
2.48.1

