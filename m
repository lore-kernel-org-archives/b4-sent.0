From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Wed, 16 Jul 2025 18:26:24 +0530
Subject: [PATCH 5/6] wifi: ath11k: Use pci_{enable/disable}_link_state()
 APIs to enable/disable ASPM states
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250716-ath-aspm-fix-v1-5-dd3e62c1b692@oss.qualcomm.com>
References: <20250716-ath-aspm-fix-v1-0-dd3e62c1b692@oss.qualcomm.com>
In-Reply-To: <20250716-ath-aspm-fix-v1-0-dd3e62c1b692@oss.qualcomm.com>
To: Jeff Johnson <jjohnson@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Nirmal Patel <nirmal.patel@linux.intel.com>, 
 Jonathan Derrick <jonathan.derrick@linux.dev>
Cc: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 ath12k@lists.infradead.org, ath11k@lists.infradead.org, 
 ath10k@lists.infradead.org, Bjorn Helgaas <helgaas@kernel.org>, 
 ilpo.jarvinen@linux.intel.com, linux-arm-msm@vger.kernel.org, 
 linux-pci@vger.kernel.org, 
 Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1863;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=kXpW2mQuCN8+CNqdT+kLur7VSEl5MgZkBtsfbPtL7RY=;
 b=owEBbAGT/pANAwAKAVWfEeb+kc71AcsmYgBod6F22QPsndaD+8odr4XoI0/ocyp1ircoReHgt
 YGA0cbP6aCJATIEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaHehdgAKCRBVnxHm/pHO
 9Sb9B/i3iAtipHaPFAxLp2zZTxGLgKyKliJu5K7gSsTqxmv7SltOMJyZmnTaGZYLk6v3zQnRcg6
 sw2o2uIH9fSmM8+4XO79TkWTmnh6trf1HQAgJs02XVm8x90kChSY3mH+1mglMtfm1Z5wZsMFXMD
 6d2HdNNBDBi7DvWJnPlv3kjjhOQa6eBwGh9J0tCBghOy2ZOsg27sEwItnHNfsCEpPNpi4zMluiq
 3zhfrwOB3g3t8SfYyX+0Zs1X2Rv2MVfl8EahkwZra0x7yV32Ina7XpSomJ1UGz46Atp4b61+BFT
 FRYW9/TtiB1XC9iicOaEtvo4z7d87s1a+ypf/M1h6fxvkfE=
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It is not recommended to enable/disable the ASPM states on the back of the
PCI core directly using the LNKCTL register. It will break the PCI core's
knowledge about the device ASPM states. So use the APIs exposed by the PCI
core to enable/disable ASPM states.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/net/wireless/ath/ath11k/pci.c | 10 ++++------
 1 file changed, 4 insertions(+), 6 deletions(-)

diff --git a/drivers/net/wireless/ath/ath11k/pci.c b/drivers/net/wireless/ath/ath11k/pci.c
index 78444f8ea15356f1f4c90a496efd52780499bfb2..cec399765e04104ddcfcee5003c209e14c7d4ca0 100644
--- a/drivers/net/wireless/ath/ath11k/pci.c
+++ b/drivers/net/wireless/ath/ath11k/pci.c
@@ -19,6 +19,8 @@
 #include "pcic.h"
 #include "qmi.h"
 
+#include "../ath.h"
+
 #define ATH11K_PCI_BAR_NUM		0
 #define ATH11K_PCI_DMA_MASK		36
 #define ATH11K_PCI_COHERENT_DMA_MASK	32
@@ -597,8 +599,7 @@ static void ath11k_pci_aspm_disable(struct ath11k_pci *ab_pci)
 		   u16_get_bits(ab_pci->link_ctl, PCI_EXP_LNKCTL_ASPM_L1));
 
 	/* disable L0s and L1 */
-	pcie_capability_clear_word(ab_pci->pdev, PCI_EXP_LNKCTL,
-				   PCI_EXP_LNKCTL_ASPMC);
+	pci_disable_link_state(ab_pci->pdev, PCIE_LINK_STATE_L0S | PCIE_LINK_STATE_L1);
 
 	set_bit(ATH11K_PCI_ASPM_RESTORE, &ab_pci->flags);
 }
@@ -606,10 +607,7 @@ static void ath11k_pci_aspm_disable(struct ath11k_pci *ab_pci)
 static void ath11k_pci_aspm_restore(struct ath11k_pci *ab_pci)
 {
 	if (test_and_clear_bit(ATH11K_PCI_ASPM_RESTORE, &ab_pci->flags))
-		pcie_capability_clear_and_set_word(ab_pci->pdev, PCI_EXP_LNKCTL,
-						   PCI_EXP_LNKCTL_ASPMC,
-						   ab_pci->link_ctl &
-						   PCI_EXP_LNKCTL_ASPMC);
+		pci_enable_link_state(ab_pci->pdev, ath_pci_aspm_state(ab_pci->link_ctl));
 }
 
 #ifdef CONFIG_DEV_COREDUMP

-- 
2.45.2

