From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 05 Jan 2026 19:25:46 +0530
Subject: [PATCH v4 6/8] PCI: qcom: Drop the assert_perst() callbacks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260105-pci-pwrctrl-rework-v4-6-6d41a7a49789@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3855;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=baYMtKTp90ApL15LaiFMPwlqAO9hm8z1KzVLol2ZneE=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpW8LyAxa1Y1E832qLma03nRs9XbUdX7ui6rLBx
 JBNS8HCbJSJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaVvC8gAKCRBVnxHm/pHO
 9VhmB/9ricWpjy73JlNoWp6RCWQP0ryQrPLxZ/ZxxLhqA8C50EtFCZbNa69jAxZRxFtDgDJH7tw
 aQfxYMeJDZ/MTO5Pxcmpkt+OQ6Nw/RngKbyw9LOzLVOQ4uX2LY+VafDSVwPnc6wfVBHEKUgxX7O
 63NVOCUcamxHModZUsWtHk0qyg5Lr7/pC6scG+17gPeRM1zvQnzVbSm+3wsRRALvEYYKb7fUeh/
 HYHsH570W7nixnakU3sZCKRgTmuO7QJK+mCBUKc2eZ5Mp2NhIngRcmQP60TGuM4v/Hi8nayjGq4
 G7BR7+YewsCLWYZVIkXaCLBUjUcop0qwoiVyZTBdXFnbhDK0
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Previously, the pcie-qcom driver probed first, deasserted PERST#, enabled
link training and scanned the bus. By the time the pwrctrl driver probe got
called, link training was already enabled by the controller driver.

Thus the pwrctrl drivers had to call the .assert_perst() callback, to
assert PERST#, power on the needed resources, and then call the
.assert_perst() callback to deassert PERST#.

Now since all pwrctrl drivers and this controller driver have been
converted to the new pwrctrl design where the pwrctrl drivers will first
power on the devices before this driver deasserts PERST# and scan the bus.
So there is no longer a need for .assert_perst() callback in this driver
and in DWC core driver. Hence, drop them.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/controller/dwc/pcie-designware-host.c |  9 ---------
 drivers/pci/controller/dwc/pcie-designware.h      |  9 ---------
 drivers/pci/controller/dwc/pcie-qcom.c            | 13 -------------
 3 files changed, 31 deletions(-)

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
index 31685951a080..da32bb5f936c 100644
--- a/drivers/pci/controller/dwc/pcie-designware.h
+++ b/drivers/pci/controller/dwc/pcie-designware.h
@@ -493,7 +493,6 @@ struct dw_pcie_ops {
 	enum dw_pcie_ltssm (*get_ltssm)(struct dw_pcie *pcie);
 	int	(*start_link)(struct dw_pcie *pcie);
 	void	(*stop_link)(struct dw_pcie *pcie);
-	int	(*assert_perst)(struct dw_pcie *pcie, bool assert);
 };
 
 struct debugfs_info {
@@ -798,14 +797,6 @@ static inline void dw_pcie_stop_link(struct dw_pcie *pci)
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

-- 
2.48.1

