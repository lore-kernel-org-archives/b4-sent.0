From: Manivannan Sadhasivam <mani@kernel.org>
Date: Wed, 08 Jul 2026 16:30:20 +0200
Subject: [PATCH v3 6/8] wifi: ath12k: Use pci_{enable/disable}_link_state()
 APIs to enable/disable ASPM states
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260708-pci-aspm-fix-v3-6-6bd72451746e@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3280; i=mani@kernel.org;
 h=from:subject:message-id; bh=fI4OgbaPQvxdUdvQa5firVs9z5T3bQjOqFuWB+LMbBg=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqTl75VwhT+5dcnzfCyLucqXIxYRsokyBQxiGRy
 E53judLsUqJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCak5e+QAKCRBVnxHm/pHO
 9cxgCACCZmQ4ZHcdD5iDF15DWrWzCvR8nBREuRoCrrlIwmWq63iwTxavA29WGJJWKfFBrJXcdil
 1aOMoiu/Al2R5zSjVFvRUhLFG7tt97Xx4J+pSKbos+8HKVuaJE0O3gYNoHBFHXp6X5JKkVSRdwZ
 9w8fESRhXhywBZzS3BN6iKtLxEySaXPVe09b15fmBSix7LVRjHRG5eZn0KU/hLltqijgpcZHW9K
 4tWc0FL090YuNf52Xc9J2U6WgO7nMMQ857NpXzMtiNR0LeFuDlgJt871REsetU/10At4cPcnd2Z
 7pCSogU1ACJWcmikj6ZX1r2a6k9QHDBdyoQKLXGH2srrDMsB
X-Developer-Key: i=mani@kernel.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for mani@kernel.org/default with auth_id=787
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

It is not recommended to enable/disable the ASPM states on the back of the
PCI core directly using the LNKCTL register. It will break the PCI core's
knowledge about the device ASPM states. So use the APIs exposed by the PCI
core to enable/disable ASPM states.

Tested-on: WCN7850 hw2.0 PCI WLAN.HMT.1.0.c5-00481-QCAHMTSWPL_V1.0_V2.0_SILICONZ-3

Reported-by: Qiang Yu <qiang.yu@oss.qualcomm.com>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/net/wireless/ath/ath12k/Kconfig |  2 +-
 drivers/net/wireless/ath/ath12k/pci.c   | 19 +++----------------
 drivers/net/wireless/ath/ath12k/pci.h   |  4 +++-
 3 files changed, 7 insertions(+), 18 deletions(-)

diff --git a/drivers/net/wireless/ath/ath12k/Kconfig b/drivers/net/wireless/ath/ath12k/Kconfig
index 4a2b240f967a..7852ede3eaea 100644
--- a/drivers/net/wireless/ath/ath12k/Kconfig
+++ b/drivers/net/wireless/ath/ath12k/Kconfig
@@ -1,7 +1,7 @@
 # SPDX-License-Identifier: BSD-3-Clause-Clear
 config ATH12K
 	tristate "Qualcomm Wi-Fi 7 support (ath12k)"
-	depends on MAC80211 && HAS_DMA && PCI
+	depends on MAC80211 && HAS_DMA && PCI && PCIEASPM
 	select QCOM_QMI_HELPERS
 	select MHI_BUS
 	select QRTR
diff --git a/drivers/net/wireless/ath/ath12k/pci.c b/drivers/net/wireless/ath/ath12k/pci.c
index d9a22d6afbb0..6d48fb25690d 100644
--- a/drivers/net/wireless/ath/ath12k/pci.c
+++ b/drivers/net/wireless/ath/ath12k/pci.c
@@ -884,19 +884,9 @@ static void ath12k_pci_free_region(struct ath12k_pci *ab_pci)
 
 static void ath12k_pci_aspm_disable(struct ath12k_pci *ab_pci)
 {
-	struct ath12k_base *ab = ab_pci->ab;
-
-	pcie_capability_read_word(ab_pci->pdev, PCI_EXP_LNKCTL,
-				  &ab_pci->link_ctl);
-
-	ath12k_dbg(ab, ATH12K_DBG_PCI, "pci link_ctl 0x%04x L0s %d L1 %d\n",
-		   ab_pci->link_ctl,
-		   u16_get_bits(ab_pci->link_ctl, PCI_EXP_LNKCTL_ASPM_L0S),
-		   u16_get_bits(ab_pci->link_ctl, PCI_EXP_LNKCTL_ASPM_L1));
+	ab_pci->aspm_states = pcie_aspm_enabled(ab_pci->pdev);
 
-	/* disable L0s and L1 */
-	pcie_capability_clear_word(ab_pci->pdev, PCI_EXP_LNKCTL,
-				   PCI_EXP_LNKCTL_ASPMC);
+	pci_disable_link_state(ab_pci->pdev, PCIE_LINK_STATE_ASPM_ALL);
 
 	set_bit(ATH12K_PCI_ASPM_RESTORE, &ab_pci->flags);
 }
@@ -925,10 +915,7 @@ static void ath12k_pci_aspm_restore(struct ath12k_pci *ab_pci)
 {
 	if (ab_pci->ab->hw_params->supports_aspm &&
 	    test_and_clear_bit(ATH12K_PCI_ASPM_RESTORE, &ab_pci->flags))
-		pcie_capability_clear_and_set_word(ab_pci->pdev, PCI_EXP_LNKCTL,
-						   PCI_EXP_LNKCTL_ASPMC,
-						   ab_pci->link_ctl &
-						   PCI_EXP_LNKCTL_ASPMC);
+		pci_force_enable_link_state(ab_pci->pdev, ab_pci->aspm_states);
 }
 
 static void ath12k_pci_cancel_workqueue(struct ath12k_base *ab)
diff --git a/drivers/net/wireless/ath/ath12k/pci.h b/drivers/net/wireless/ath/ath12k/pci.h
index 0e0e2020c6ae..409ef063cd69 100644
--- a/drivers/net/wireless/ath/ath12k/pci.h
+++ b/drivers/net/wireless/ath/ath12k/pci.h
@@ -128,7 +128,9 @@ struct ath12k_pci {
 
 	/* enum ath12k_pci_flags */
 	unsigned long flags;
-	u16 link_ctl;
+
+	/* Cached PCIe ASPM states */
+	u32 aspm_states;
 	unsigned long irq_flags;
 	const struct ath12k_pci_ops *pci_ops;
 	u32 qmi_instance;

-- 
2.43.0

