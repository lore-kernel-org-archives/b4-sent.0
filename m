From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Wed, 16 Jul 2025 18:26:25 +0530
Subject: [PATCH 6/6] wifi: ath10k: Use pci_{enable/disable}_link_state()
 APIs to enable/disable ASPM states
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250716-ath-aspm-fix-v1-6-dd3e62c1b692@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1518;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=Fx4ej/EicH41+mIOpWKF1WcnMWq9PYq0rbjy+/KSq0Q=;
 b=kA0DAAoBVZ8R5v6RzvUByyZiAGh3oXbIxqk80Tgh+RxdditU6/SfcGzUbtEKyagt0528i4qmg
 okBMwQAAQoAHRYhBGelQyqBSMvYpFgnl1WfEeb+kc71BQJod6F2AAoJEFWfEeb+kc71+zwH/j9g
 77XQ+TyQtXbct+iV57W9c8g3ZQmgOtKIHRMLu+mcrcqHfSxz/V/4OcFnyjatqAbs33eteSiCZ55
 LoVeVbo3qOjovyINbJXFwgSGgb7MrPELoEBPbwyZvr7H6mp2v1GP3XUzZsi6NwIHjh1J7BQUqHV
 aDnAaoWlbmAChlKp0tbmRkWVN2LpMwTe6EfcYqrCmz7nBm1x0QLTpGPJkNYzV/HgleNa8aMEQFV
 eQP3tLVUolrRr8ZS4IJHlOEVQus5Ub4hqfKpnW3BFAvywjtvLCovpSp6Diwn0zkfZ0WLLS5Xk0R
 6jeK1WBsuL8Emy0OHC085U9qIOq5psdkZ9ca4Pc=
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
 drivers/net/wireless/ath/ath10k/pci.c | 7 ++-----
 1 file changed, 2 insertions(+), 5 deletions(-)

diff --git a/drivers/net/wireless/ath/ath10k/pci.c b/drivers/net/wireless/ath/ath10k/pci.c
index 1e6d43285138ece619b9d7dc49f113a439e2085d..b20ab535a850ef1f5fe606bd7e7a230ebcd894c8 100644
--- a/drivers/net/wireless/ath/ath10k/pci.c
+++ b/drivers/net/wireless/ath/ath10k/pci.c
@@ -1965,9 +1965,7 @@ static int ath10k_pci_hif_start(struct ath10k *ar)
 	ath10k_pci_irq_enable(ar);
 	ath10k_pci_rx_post(ar);
 
-	pcie_capability_clear_and_set_word(ar_pci->pdev, PCI_EXP_LNKCTL,
-					   PCI_EXP_LNKCTL_ASPMC,
-					   ar_pci->link_ctl & PCI_EXP_LNKCTL_ASPMC);
+	pci_enable_link_state(ar_pci->pdev, ath_pci_aspm_state(ar_pci->link_ctl));
 
 	return 0;
 }
@@ -2824,8 +2822,7 @@ static int ath10k_pci_hif_power_up(struct ath10k *ar,
 
 	pcie_capability_read_word(ar_pci->pdev, PCI_EXP_LNKCTL,
 				  &ar_pci->link_ctl);
-	pcie_capability_clear_word(ar_pci->pdev, PCI_EXP_LNKCTL,
-				   PCI_EXP_LNKCTL_ASPMC);
+	pci_disable_link_state(ar_pci->pdev, PCIE_LINK_STATE_L0S | PCIE_LINK_STATE_L1);
 
 	/*
 	 * Bring the target up cleanly.

-- 
2.45.2

