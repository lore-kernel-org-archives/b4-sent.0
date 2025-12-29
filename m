From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 29 Dec 2025 22:56:57 +0530
Subject: [PATCH v3 6/7] PCI: qcom: Drop the assert_perst() callbacks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251229-pci-pwrctrl-rework-v3-6-c7d5918cd0db@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3712;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=OxqbBaot5sb3RNdkBfSCmREAquDem1+SJOzo41RQjOs=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpUrnmP+nu1ihn6rmt7HAaYQo8uKEdf/ZEG2DSc
 Z4I0D6eg42JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaVK55gAKCRBVnxHm/pHO
 9Um0CACKWr2CxTV/7MzzNxY/3V6I/yfE5K3/Od/TTsExLfnl2cOhNRv/bhrp5QQQ6IWNCBZAuuB
 on8vEc9IMG3e9O776iWj5xGYf3VDF/vrxJCHZlkWCmr718w5LLmP7pKFIPIZ9vEMCo76zzeoAA8
 x0sP39XJeT48rkonT+wJcv/fXKWjBcYHz/+Z90rbtooT7B8xApU0DZnan1wdAR86+bbOMO904E4
 6afJAAQnU2yqn2H13kmQOn/a2HYdlk5p+UcVl5VQ40eTo5WR2tICFB+Pacog1ZpsOE+S46ylBP2
 TcktPxFAuoX8W2yyu/quLlBxuN56yrkDf5NQCYAXmyp1vmD7
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Now that the TC9563 Pwrctrl driver is converted to use the new Pwrctrl
design, there is no need for these assert_perst() callbacks. With the new
design, TC9563 will be powered on before PERST# deassert. So explicit
PERST# handling from the TC9563 driver is not needed.

Hence, drop the callbacks.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/controller/dwc/pcie-designware-host.c |  9 ---------
 drivers/pci/controller/dwc/pcie-designware.h      |  8 --------
 drivers/pci/controller/dwc/pcie-qcom.c            | 13 -------------
 include/linux/pci.h                               |  1 -
 4 files changed, 31 deletions(-)

diff --git a/drivers/pci/controller/dwc/pcie-designware-host.c b/drivers/pci/controller/dwc/pcie-designware-host.c
index 372207c33a85..4862a3a059c7 100644
--- a/drivers/pci/controller/dwc/pcie-designware-host.c
+++ b/drivers/pci/controller/dwc/pcie-designware-host.c
@@ -857,19 +857,10 @@ static void __iomem *dw_pcie_ecam_conf_map_bus(struct pci_bus *bus, unsigned int
 	return pci->dbi_base + where;
 }
 
-static int dw_pcie_op_assert_perst(struct pci_bus *bus, bool assert)
-{
-	struct dw_pcie_rp *pp = bus->sysdata;
-	struct dw_pcie *pci = to_dw_pcie_from_pp(pp);
-
-	return dw_pcie_assert_perst(pci, assert);
-}
-
 static struct pci_ops dw_pcie_ops = {
 	.map_bus = dw_pcie_own_conf_map_bus,
 	.read = pci_generic_config_read,
 	.write = pci_generic_config_write,
-	.assert_perst = dw_pcie_op_assert_perst,
 };
 
 static struct pci_ops dw_pcie_ecam_ops = {
diff --git a/drivers/pci/controller/dwc/pcie-designware.h b/drivers/pci/controller/dwc/pcie-designware.h
index 31685951a080..d24abdb9edaa 100644
--- a/drivers/pci/controller/dwc/pcie-designware.h
+++ b/drivers/pci/controller/dwc/pcie-designware.h
@@ -798,14 +798,6 @@ static inline void dw_pcie_stop_link(struct dw_pcie *pci)
 		pci->ops->stop_link(pci);
 }
 
-static inline int dw_pcie_assert_perst(struct dw_pcie *pci, bool assert)
-{
-	if (pci->ops && pci->ops->assert_perst)
-		return pci->ops->assert_perst(pci, assert);
-
-	return 0;
-}
-
 static inline enum dw_pcie_ltssm dw_pcie_get_ltssm(struct dw_pcie *pci)
 {
 	u32 val;
diff --git a/drivers/pci/controller/dwc/pcie-qcom.c b/drivers/pci/controller/dwc/pcie-qcom.c
index 198befb5be2c..6de3ff555b9d 100644
--- a/drivers/pci/controller/dwc/pcie-qcom.c
+++ b/drivers/pci/controller/dwc/pcie-qcom.c
@@ -650,18 +650,6 @@ static int qcom_pcie_post_init_1_0_0(struct qcom_pcie *pcie)
 	return 0;
 }
 
-static int qcom_pcie_assert_perst(struct dw_pcie *pci, bool assert)
-{
-	struct qcom_pcie *pcie = to_qcom_pcie(pci);
-
-	if (assert)
-		qcom_ep_reset_assert(pcie);
-	else
-		qcom_ep_reset_deassert(pcie);
-
-	return 0;
-}
-
 static void qcom_pcie_2_3_2_ltssm_enable(struct qcom_pcie *pcie)
 {
 	u32 val;
@@ -1523,7 +1511,6 @@ static const struct qcom_pcie_cfg cfg_fw_managed = {
 static const struct dw_pcie_ops dw_pcie_ops = {
 	.link_up = qcom_pcie_link_up,
 	.start_link = qcom_pcie_start_link,
-	.assert_perst = qcom_pcie_assert_perst,
 };
 
 static int qcom_pcie_icc_init(struct qcom_pcie *pcie)
diff --git a/include/linux/pci.h b/include/linux/pci.h
index 864775651c6f..3eb8fd975ad9 100644
--- a/include/linux/pci.h
+++ b/include/linux/pci.h
@@ -854,7 +854,6 @@ struct pci_ops {
 	void __iomem *(*map_bus)(struct pci_bus *bus, unsigned int devfn, int where);
 	int (*read)(struct pci_bus *bus, unsigned int devfn, int where, int size, u32 *val);
 	int (*write)(struct pci_bus *bus, unsigned int devfn, int where, int size, u32 val);
-	int (*assert_perst)(struct pci_bus *bus, bool assert);
 };
 
 /*

-- 
2.48.1

