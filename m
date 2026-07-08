From: Manivannan Sadhasivam <mani@kernel.org>
Date: Wed, 08 Jul 2026 16:30:21 +0200
Subject: [PATCH v3 7/8] wifi: ath11k: Use pci_{enable/disable}_link_state()
 APIs to enable/disable ASPM states
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260708-pci-aspm-fix-v3-7-6bd72451746e@kernel.org>
References: <20260708-pci-aspm-fix-v3-0-6bd72451746e@kernel.org>
In-Reply-To: <20260708-pci-aspm-fix-v3-0-6bd72451746e@kernel.org>
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Nirmal Patel <nirmal.patel@linux.intel.com>, 
 Jonathan Derrick <jonathan.derrick@linux.dev>, 
 Jeff Johnson <jjohnson@kernel.org>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-wireless@vger.kernel.org, 
 ath12k@lists.infradead.org, ath11k@lists.infradead.org, 
 ath10k@lists.infradead.org, 
 Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>, 
 Qiang Yu <qiang.yu@oss.qualcomm.com>, mani@kernel.org, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2987; i=mani@kernel.org;
 h=from:subject:message-id; bh=59wUpl/E90ZN2ijmP67COqOAAWZoyF3++0KlktxUhMw=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqTl76AXfVIr8lqqmcElFkQxvRb8nDLwSolH+U2
 iY07JQuAxuJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCak5e+gAKCRBVnxHm/pHO
 9Wy6B/4nR2x6UIp/WP9pSP7RSsfelBYusTRvVs4+R8UckgV8QXSru8c3ChXtF9OQA25L+uTJIPt
 cPxnbkzy/D+vaVEXLXlKcvbiNwCVpX6wOPUmjt871CfxhHdbHzPiKCWyRSWqnc+Cp76e4N92F5z
 dO+CNQfuRXGBKMEeOa/ZeWWXGpvB4TpnOB1x8eoNVvtxSsFV9hNI7e4Cyn4VK/+Dpak80cfm5qc
 8dbw7VfNliQlhn3a/BK96N5h4fCU7mQwAFHFH481OTDGcGKl6nFaW31jtf3t9efq1gHu0Tn8pS6
 b3TB8xLvXYX3IaziB8Y8XVlT15A7Px8rfBobRQIPmiCafNLm
X-Developer-Key: i=mani@kernel.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for mani@kernel.org/default with auth_id=787
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

It is not recommended to enable/disable the ASPM states on the back of the
PCI core directly using the LNKCTL register. It will break the PCI core's
knowledge about the device ASPM states. So use the APIs exposed by the PCI
core to enable/disable ASPM states.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/net/wireless/ath/ath11k/Kconfig |  2 +-
 drivers/net/wireless/ath/ath11k/pci.c   | 19 +++----------------
 drivers/net/wireless/ath/ath11k/pci.h   |  3 ++-
 3 files changed, 6 insertions(+), 18 deletions(-)

diff --git a/drivers/net/wireless/ath/ath11k/Kconfig b/drivers/net/wireless/ath/ath11k/Kconfig
index 122726f84492..c8b418521173 100644
--- a/drivers/net/wireless/ath/ath11k/Kconfig
+++ b/drivers/net/wireless/ath/ath11k/Kconfig
@@ -19,7 +19,7 @@ config ATH11K_AHB
 
 config ATH11K_PCI
 	tristate "Atheros ath11k PCI support"
-	depends on ATH11K && PCI
+	depends on ATH11K && PCI && PCIEASPM
 	select MHI_BUS
 	select QRTR
 	select QRTR_MHI
diff --git a/drivers/net/wireless/ath/ath11k/pci.c b/drivers/net/wireless/ath/ath11k/pci.c
index 35bb9e7a63a2..da980e01d1fc 100644
--- a/drivers/net/wireless/ath/ath11k/pci.c
+++ b/drivers/net/wireless/ath/ath11k/pci.c
@@ -604,19 +604,9 @@ static void ath11k_pci_free_region(struct ath11k_pci *ab_pci)
 
 static void ath11k_pci_aspm_disable(struct ath11k_pci *ab_pci)
 {
-	struct ath11k_base *ab = ab_pci->ab;
-
-	pcie_capability_read_word(ab_pci->pdev, PCI_EXP_LNKCTL,
-				  &ab_pci->link_ctl);
-
-	ath11k_dbg(ab, ATH11K_DBG_PCI, "link_ctl 0x%04x L0s %d L1 %d\n",
-		   ab_pci->link_ctl,
-		   u16_get_bits(ab_pci->link_ctl, PCI_EXP_LNKCTL_ASPM_L0S),
-		   u16_get_bits(ab_pci->link_ctl, PCI_EXP_LNKCTL_ASPM_L1));
+	ab_pci->aspm_states = pcie_aspm_enabled(ab_pci->pdev);
 
-	/* disable L0s and L1 */
-	pcie_capability_clear_word(ab_pci->pdev, PCI_EXP_LNKCTL,
-				   PCI_EXP_LNKCTL_ASPMC);
+	pci_disable_link_state(ab_pci->pdev, PCIE_LINK_STATE_ASPM_ALL);
 
 	set_bit(ATH11K_PCI_ASPM_RESTORE, &ab_pci->flags);
 }
@@ -624,10 +614,7 @@ static void ath11k_pci_aspm_disable(struct ath11k_pci *ab_pci)
 static void ath11k_pci_aspm_restore(struct ath11k_pci *ab_pci)
 {
 	if (test_and_clear_bit(ATH11K_PCI_ASPM_RESTORE, &ab_pci->flags))
-		pcie_capability_clear_and_set_word(ab_pci->pdev, PCI_EXP_LNKCTL,
-						   PCI_EXP_LNKCTL_ASPMC,
-						   ab_pci->link_ctl &
-						   PCI_EXP_LNKCTL_ASPMC);
+		pci_force_enable_link_state(ab_pci->pdev, ab_pci->aspm_states);
 }
 
 #ifdef CONFIG_DEV_COREDUMP
diff --git a/drivers/net/wireless/ath/ath11k/pci.h b/drivers/net/wireless/ath/ath11k/pci.h
index 1e3005a4b64c..474c18741418 100644
--- a/drivers/net/wireless/ath/ath11k/pci.h
+++ b/drivers/net/wireless/ath/ath11k/pci.h
@@ -72,7 +72,8 @@ struct ath11k_pci {
 
 	/* enum ath11k_pci_flags */
 	unsigned long flags;
-	u16 link_ctl;
+	/* Cached PCIe ASPM states */
+	u32 aspm_states;
 	u64 dma_mask;
 };
 

-- 
2.43.0

