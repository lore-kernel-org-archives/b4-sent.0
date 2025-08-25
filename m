From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 25 Aug 2025 23:14:40 +0530
Subject: [PATCH v2 5/8] PCI/ASPM: Return enabled ASPM states from
 pcie_aspm_enabled() API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250825-ath-aspm-fix-v2-5-61b2f2db7d89@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2836;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=jMfN6qwvopwk5oh/k0Cf9IL8m25slb1JveeGwVNhrME=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBorKEPiwhWp+/PSd/iBSrmb3dl5Tv2stjEC5I9s
 hxFRCLyDCmJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaKyhDwAKCRBVnxHm/pHO
 9U8+B/0c1VbCfjh2R58dS1EgS8LhCsvsrwAoexW6nBilgkDlYrlhBMoBaLI9cifrzAIzOEwcpwp
 NcFXH/cJcNB4HE8+VOkeAosGiDRPAmkzhw0lCs0Zlke9MbptGXuiPFDUt3GmgUZFkni+1PmQiZ6
 t6ufSeZOuHr+lb4VOpYPvZuElkBpX9XkBPc2DkTZqNa2qxW6FlpPDQju2PvMuVCv7T7pt2oMDuZ
 cZ90VmyDcXelHokd348TRdPfCo7jMmed/A1/r531KO5UTv8PLsuSq9Qvt5HkrI2hNPVe0r0BCKj
 ycJ81OSii5p8Cs+xcBp48q2Q8kYaaB30f/wEOr4w8XM10UxL
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

pcie_aspm_enabled() returns 'pcie_link_state::aspm_enabled' parameter which
contains the enabled states. But the API currently returns the 'bool' type
which is used by the callers to decide if ASPM is enabled or not.

To allow the future callers to also make use of the enabled ASPM states,
return the actual type of 'pcie_link_state::aspm_enabled' parameter, 'u32'.

Existing callers can still treat the return value as a 'bool' as the C11
standard guarantees the behavior (this API relied on the same behavior
before as well).

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/pcie/aspm.c | 6 ++++--
 include/linux/pci.h     | 4 ++--
 2 files changed, 6 insertions(+), 4 deletions(-)

diff --git a/drivers/pci/pcie/aspm.c b/drivers/pci/pcie/aspm.c
index 3c8101023e80d3c0550136f729782c0e0a3e28cf..fed44b7cb46e9f34c9ef6d5fa6a7b009976cbfdc 100644
--- a/drivers/pci/pcie/aspm.c
+++ b/drivers/pci/pcie/aspm.c
@@ -1582,15 +1582,17 @@ module_param_call(policy, pcie_aspm_set_policy, pcie_aspm_get_policy,
 	NULL, 0644);
 
 /**
- * pcie_aspm_enabled - Check if PCIe ASPM has been enabled for a device.
+ * pcie_aspm_enabled - Get the enabled PCIe ASPM states for a device.
  * @pdev: Target device.
  *
  * Relies on the upstream bridge's link_state being valid.  The link_state
  * is deallocated only when the last child of the bridge (i.e., @pdev or a
  * sibling) is removed, and the caller should be holding a reference to
  * @pdev, so this should be safe.
+ *
+ * Return: Enabled PCIe ASPM states. 0 if ASPM is disabled.
  */
-bool pcie_aspm_enabled(struct pci_dev *pdev)
+u32 pcie_aspm_enabled(struct pci_dev *pdev)
 {
 	struct pcie_link_state *link = pcie_aspm_get_link(pdev);
 
diff --git a/include/linux/pci.h b/include/linux/pci.h
index 59876de13860dbe50ee6c207cd57e54f51a11079..6f3c5d6a9a959abefbb69e1165aec704da507313 100644
--- a/include/linux/pci.h
+++ b/include/linux/pci.h
@@ -1851,7 +1851,7 @@ int pci_enable_link_state(struct pci_dev *pdev, int state);
 int pci_enable_link_state_locked(struct pci_dev *pdev, int state);
 void pcie_no_aspm(void);
 bool pcie_aspm_support_enabled(void);
-bool pcie_aspm_enabled(struct pci_dev *pdev);
+u32 pcie_aspm_enabled(struct pci_dev *pdev);
 #else
 static inline int pci_disable_link_state(struct pci_dev *pdev, int state)
 { return 0; }
@@ -1863,7 +1863,7 @@ static inline int pci_enable_link_state_locked(struct pci_dev *pdev, int state)
 { return 0; }
 static inline void pcie_no_aspm(void) { }
 static inline bool pcie_aspm_support_enabled(void) { return false; }
-static inline bool pcie_aspm_enabled(struct pci_dev *pdev) { return false; }
+static inline u32 pcie_aspm_enabled(struct pci_dev *pdev) { return false; }
 #endif
 
 #ifdef CONFIG_HOTPLUG_PCI

-- 
2.45.2

