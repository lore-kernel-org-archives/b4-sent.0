From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 29 Dec 2025 22:56:58 +0530
Subject: [PATCH v3 7/7] PCI: qcom: Rename PERST# assert/deassert helpers
 for uniformity
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251229-pci-pwrctrl-rework-v3-7-c7d5918cd0db@oss.qualcomm.com>
References: <20251229-pci-pwrctrl-rework-v3-0-c7d5918cd0db@oss.qualcomm.com>
In-Reply-To: <20251229-pci-pwrctrl-rework-v3-0-c7d5918cd0db@oss.qualcomm.com>
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
 Bartosz Golaszewski <bartosz.golaszewski@linaro.org>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2787;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=ncgLgkMFVujyqBgktgUh6eUIgflyWGjZ+0g78z7CeOY=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpUrnmxi6KB+fRNxWX9kzeLNU/o+gpdx3ATVtCN
 E8mnmZRMHuJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaVK55gAKCRBVnxHm/pHO
 9SGVB/9qNDupQXRtd6KkRvL/8ZQmLIK8PPOxYnAv+XWBcVDtUJZsvKBpuAr2T63C2b7nwKt5yYK
 ji7HpnUOUCVvMgp1GbAOQSDltv848Cq+i7DYOuuydEmPGYjdYKPCHQ128NZa1V+yq3bBY1WLQUE
 JnKLLsMXtIsGO5b9mI/Iih5bXpBb9o5LW+RIdvGvHdtOtfRRWvqXqD4e1whoLUkyZNgpTVnrVQU
 zjz7Vu8uDWRmjYpCtHvsgoMBz42lYY3LukkEZXksVDH5h0bs9gc5If1hC6Jl/isCB0Xei31lKYx
 Iz+zt+K3GT7jKPflQyGdOH/3o8yWbsbDnU2BIUeuNq6WBVKd
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Rename the PERST# assert/deassert helpers from
qcom_ep_reset_{assert/deassert}() to qcom_pcie_perst_{assert/deassert}() to
maintain uniformity.

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

