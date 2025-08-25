From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 25 Aug 2025 23:14:43 +0530
Subject: [PATCH v2 8/8] wifi: ath10k: Use pci_{enable/disable}_link_state()
 APIs to enable/disable ASPM states
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250825-ath-aspm-fix-v2-8-61b2f2db7d89@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2981;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=uyS1xPT5jai72N0zPRdwC7Qm7l2NSu7PXBp1orIlTxc=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBorKEPRWN+gOX5AI/H8Qt+I/bU07xvKvOqN3b//
 wAwlMaWZYSJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaKyhDwAKCRBVnxHm/pHO
 9ZvaB/0aBwu3PdJ2Emz8jlL9GAiOxXptrtjecGqLk6v30XEdaVaojuE7OgGSLZEJCUioo/Pr8Rr
 AhPxQZ8wVvR4Gs3aLlaHHK0yXOlR773NdbR4fjzmmMd2voUct61ZoOf1bMjUV1bfYmsJRAokE4y
 kLcYOFSsm6gkZgXU+LO+qBUM/F70H1K3cbIRW0jsFKFudESOATJ4xLyL+uTmiUHM4Z2qN/WNaD/
 8dX2TNfTic37YyIHb7q5c0IOzK16nEdKKuI49YQ89jMSGmyoO/6WVNpz6dQ9OniobDFv+qmc1EM
 lZK49YL/I5S1vBsg/SqO8l8h9ecsqMjPBCqr99TB9C5NnoB5
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
 drivers/net/wireless/ath/ath10k/Kconfig |  2 +-
 drivers/net/wireless/ath/ath10k/pci.c   | 11 ++++-------
 drivers/net/wireless/ath/ath10k/pci.h   |  5 ++---
 3 files changed, 7 insertions(+), 11 deletions(-)

diff --git a/drivers/net/wireless/ath/ath10k/Kconfig b/drivers/net/wireless/ath/ath10k/Kconfig
index 876aed76583318724e4dab0b537d5c93c77460c6..02f9a78e252b124666edcc2395fda01d779803f1 100644
--- a/drivers/net/wireless/ath/ath10k/Kconfig
+++ b/drivers/net/wireless/ath/ath10k/Kconfig
@@ -17,7 +17,7 @@ config ATH10K_CE
 
 config ATH10K_PCI
 	tristate "Atheros ath10k PCI support"
-	depends on ATH10K && PCI
+	depends on ATH10K && PCI && PCIEASPM
 	help
 	  This module adds support for PCIE bus
 
diff --git a/drivers/net/wireless/ath/ath10k/pci.c b/drivers/net/wireless/ath/ath10k/pci.c
index 97b49bf4ad80916dd139acd5f5744922317191aa..c11266cf31370abf1218ba08ac344598aa655cff 100644
--- a/drivers/net/wireless/ath/ath10k/pci.c
+++ b/drivers/net/wireless/ath/ath10k/pci.c
@@ -1966,9 +1966,7 @@ static int ath10k_pci_hif_start(struct ath10k *ar)
 	ath10k_pci_irq_enable(ar);
 	ath10k_pci_rx_post(ar);
 
-	pcie_capability_clear_and_set_word(ar_pci->pdev, PCI_EXP_LNKCTL,
-					   PCI_EXP_LNKCTL_ASPMC,
-					   ar_pci->link_ctl & PCI_EXP_LNKCTL_ASPMC);
+	pci_enable_link_state(ar_pci->pdev, ar_pci->aspm_states);
 
 	return 0;
 }
@@ -2823,10 +2821,9 @@ static int ath10k_pci_hif_power_up(struct ath10k *ar,
 
 	ath10k_dbg(ar, ATH10K_DBG_BOOT, "boot hif power up\n");
 
-	pcie_capability_read_word(ar_pci->pdev, PCI_EXP_LNKCTL,
-				  &ar_pci->link_ctl);
-	pcie_capability_clear_word(ar_pci->pdev, PCI_EXP_LNKCTL,
-				   PCI_EXP_LNKCTL_ASPMC);
+	ar_pci->aspm_states = pcie_aspm_enabled(ar_pci->pdev);
+
+	pci_disable_link_state(ar_pci->pdev, PCIE_LINK_STATE_ALL);
 
 	/*
 	 * Bring the target up cleanly.
diff --git a/drivers/net/wireless/ath/ath10k/pci.h b/drivers/net/wireless/ath/ath10k/pci.h
index 4c3f536f2ea1a95a78a0703d1f82d37d52f4b6d4..5f3e5739276f0bb1a14292bb596b4b5fa34e0acc 100644
--- a/drivers/net/wireless/ath/ath10k/pci.h
+++ b/drivers/net/wireless/ath/ath10k/pci.h
@@ -128,10 +128,9 @@ struct ath10k_pci {
 	struct timer_list rx_post_retry;
 
 	/* Due to HW quirks it is recommended to disable ASPM during device
-	 * bootup. To do that the original PCI-E Link Control is stored before
-	 * device bootup is executed and re-programmed later.
+	 * bootup. To do that the ASPM states are saved and re-programmed later.
 	 */
-	u16 link_ctl;
+	u32 aspm_states;
 
 	/* Protects ps_awake and ps_wake_refcount */
 	spinlock_t ps_lock;

-- 
2.45.2

