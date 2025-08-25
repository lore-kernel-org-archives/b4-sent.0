From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 25 Aug 2025 23:14:42 +0530
Subject: [PATCH v2 7/8] wifi: ath11k: Use pci_{enable/disable}_link_state()
 APIs to enable/disable ASPM states
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250825-ath-aspm-fix-v2-7-61b2f2db7d89@oss.qualcomm.com>
References: <20250825-ath-aspm-fix-v2-0-61b2f2db7d89@oss.qualcomm.com>
In-Reply-To: <20250825-ath-aspm-fix-v2-0-61b2f2db7d89@oss.qualcomm.com>
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Nirmal Patel <nirmal.patel@linux.intel.com>, 
 Jonathan Derrick <jonathan.derrick@linux.dev>, 
 Jeff Johnson <jjohnson@kernel.org>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-wireless@vger.kernel.org, 
 ath12k@lists.infradead.org, ath11k@lists.infradead.org, 
 ath10k@lists.infradead.org, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3144;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=K8FTwvItCiUnOOZrxrN2h/nq2BvbT+Wy0KtDYhVyhrY=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBorKEPYMGTaSp8NMZfMxZegLgw/ywSID5AZ1Ba+
 gsX7ZfIHlSJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaKyhDwAKCRBVnxHm/pHO
 9UQuB/9rHiAkPXNCloNwt2ZMvvMg2V+yPJgaGgkUtvckx77vEpqrmTqabjua6TM5frI4eUkTZT4
 mjQ6L+/s1x51XvU3xRwVXz7LpJzD+6ZPzllkd6bSKTWzHYs2ud/muci1b7D189UPBPHOubDyMJR
 qRGH7dS6UY9wsodC+1pYXlVtRazVcWN7v8VA6dFzjUTeETBEeuFHdLgTDaP6p8DbuT1Vo1ROaHp
 nyBCSyoBDKmotIFDmIhAF+2sIazt4Yb+uQs1g8dpBC5nccYDDPmBEI04zyo+qUYHByPpzRzNll2
 bePWYZk7FWt403okq5s9prQ8oPpKOoWSFwSiW+XwYorkfvs6
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
 drivers/net/wireless/ath/ath11k/Kconfig |  2 +-
 drivers/net/wireless/ath/ath11k/pci.c   | 19 +++----------------
 drivers/net/wireless/ath/ath11k/pci.h   |  3 ++-
 3 files changed, 6 insertions(+), 18 deletions(-)

diff --git a/drivers/net/wireless/ath/ath11k/Kconfig b/drivers/net/wireless/ath/ath11k/Kconfig
index 659ef134ef168f5e5ad9a532ccd485d20d8701d5..9e19823fbd1a8d48517dcf1c2e644686f7e0ff57 100644
--- a/drivers/net/wireless/ath/ath11k/Kconfig
+++ b/drivers/net/wireless/ath/ath11k/Kconfig
@@ -20,7 +20,7 @@ config ATH11K_AHB
 
 config ATH11K_PCI
 	tristate "Atheros ath11k PCI support"
-	depends on ATH11K && PCI
+	depends on ATH11K && PCI && PCIEASPM
 	select MHI_BUS
 	select QRTR
 	select QRTR_MHI
diff --git a/drivers/net/wireless/ath/ath11k/pci.c b/drivers/net/wireless/ath/ath11k/pci.c
index d8655badd96d0f4b6946f8af927d878aaa3147ad..94bf5973d146754173d076eebd36580b820dc894 100644
--- a/drivers/net/wireless/ath/ath11k/pci.c
+++ b/drivers/net/wireless/ath/ath11k/pci.c
@@ -586,19 +586,9 @@ static void ath11k_pci_free_region(struct ath11k_pci *ab_pci)
 
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
+	pci_disable_link_state(ab_pci->pdev, PCIE_LINK_STATE_ALL);
 
 	set_bit(ATH11K_PCI_ASPM_RESTORE, &ab_pci->flags);
 }
@@ -606,10 +596,7 @@ static void ath11k_pci_aspm_disable(struct ath11k_pci *ab_pci)
 static void ath11k_pci_aspm_restore(struct ath11k_pci *ab_pci)
 {
 	if (test_and_clear_bit(ATH11K_PCI_ASPM_RESTORE, &ab_pci->flags))
-		pcie_capability_clear_and_set_word(ab_pci->pdev, PCI_EXP_LNKCTL,
-						   PCI_EXP_LNKCTL_ASPMC,
-						   ab_pci->link_ctl &
-						   PCI_EXP_LNKCTL_ASPMC);
+		pci_enable_link_state(ab_pci->pdev, ab_pci->aspm_states);
 }
 
 #ifdef CONFIG_DEV_COREDUMP
diff --git a/drivers/net/wireless/ath/ath11k/pci.h b/drivers/net/wireless/ath/ath11k/pci.h
index c33c7865145cc666394135e7fd8e10dd4462e5df..fe58ce814aeff1d71b5d6e44ccfd9d5b3cd9d48d 100644
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
2.45.2

