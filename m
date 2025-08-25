From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 25 Aug 2025 23:14:38 +0530
Subject: [PATCH v2 3/8] PCI/ASPM: Transition the device to D0 (if required)
 inside pci_enable_link_state_locked() API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250825-ath-aspm-fix-v2-3-61b2f2db7d89@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=4214;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=Qjbd70IC+ShOK3ZDf4DRoBiUH5NS5aHCnprLq7DQ7iM=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBorKEPLbdqO2EWRQxfmgtisJzzWpgiy2ZIIPyDr
 wXo38kcIkeJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaKyhDwAKCRBVnxHm/pHO
 9Y3zB/9zEs5uWjC3Xrp3WhZFy5crlFwe49xFUi+A+EJpbRJDiMhgTxouJpKvRY/cZvY8DxcuyWq
 Q6VKk/Q1UWHC054LHzynKwqasTaviVYQgMqMwjJ4C06i9hMSyr/L2Hywarv9Nni8mhUD372eY4O
 Ry0svyzfWZJplUYBwqnbbhvSYfeX3oN++0ibNInhZ9fFX4dLGMvQUfAj1+EoX7Zk11ND+Z44c7q
 /34v40Br95YeTKp/FOIwVK8dayq7uZiqEKwRc3AcrXGobv4humuJVCA8HaXe79RalBT9kairD6/
 KQbjIRML/SnxYy9jMFN3tTtwmRh5tpXkjm+u8YXE6E7wjWXP
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Both of the current callers of the pci_enable_link_state_locked() API
transition the device to D0 before calling. This aligns with the PCIe spec
r6.0, sec 5.5.4:

"If setting either or both of the enable bits for PCI-PM L1 PM Substates,
both ports must be configured as described in this section while in D0."

But it looks redundant to let the callers transition the device to D0. So
move the logic inside the API and perform D0 transition only if the PCI-PM
L1 Substates are getting enabled.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/controller/dwc/pcie-qcom.c |  5 -----
 drivers/pci/controller/vmd.c           |  5 -----
 drivers/pci/pcie/aspm.c                | 22 ++++++++++++++++++----
 3 files changed, 18 insertions(+), 14 deletions(-)

diff --git a/drivers/pci/controller/dwc/pcie-qcom.c b/drivers/pci/controller/dwc/pcie-qcom.c
index 294babe1816e4d0c2b2343fe22d89af72afcd6cd..af705d71f72b2b7c3004cbb69cbd779c637bb22b 100644
--- a/drivers/pci/controller/dwc/pcie-qcom.c
+++ b/drivers/pci/controller/dwc/pcie-qcom.c
@@ -1042,11 +1042,6 @@ static int qcom_pcie_post_init_2_7_0(struct qcom_pcie *pcie)
 
 static int qcom_pcie_enable_aspm(struct pci_dev *pdev, void *userdata)
 {
-	/*
-	 * Downstream devices need to be in D0 state before enabling PCI PM
-	 * substates.
-	 */
-	pci_set_power_state_locked(pdev, PCI_D0);
 	pci_enable_link_state_locked(pdev, PCIE_LINK_STATE_ALL);
 
 	return 0;
diff --git a/drivers/pci/controller/vmd.c b/drivers/pci/controller/vmd.c
index b679c7f28f51c13468b60f1e6481a26d5967d4eb..85cfd8cbc6f7ed2730f4f8e5357d9b90d8906ad3 100644
--- a/drivers/pci/controller/vmd.c
+++ b/drivers/pci/controller/vmd.c
@@ -768,11 +768,6 @@ static int vmd_pm_enable_quirk(struct pci_dev *pdev, void *userdata)
 	pci_info(pdev, "VMD: Default LTR value set by driver\n");
 
 out_state_change:
-	/*
-	 * Ensure devices are in D0 before enabling PCI-PM L1 PM Substates, per
-	 * PCIe r6.0, sec 5.5.4.
-	 */
-	pci_set_power_state_locked(pdev, PCI_D0);
 	pci_enable_link_state_locked(pdev, PCIE_LINK_STATE_ALL);
 	return 0;
 }
diff --git a/drivers/pci/pcie/aspm.c b/drivers/pci/pcie/aspm.c
index fac46113a90c7fac6c97125e6a7e385045780005..1243715bc054f859af175143a7ffaef0971f097a 100644
--- a/drivers/pci/pcie/aspm.c
+++ b/drivers/pci/pcie/aspm.c
@@ -1480,13 +1480,20 @@ static int __pci_enable_link_state(struct pci_dev *pdev, int state, bool locked)
  * Note that if the BIOS didn't grant ASPM control to the OS, this does
  * nothing because we can't touch the LNKCTL register.
  *
- * Note: Ensure devices are in D0 before enabling PCI-PM L1 PM Substates, per
- * PCIe r6.0, sec 5.5.4.
+ * Note: The device will be transitioned to D0 state if the PCI-PM L1 Substates
+ * are getting enabled.
  *
  * Return: 0 on success, a negative errno otherwise.
  */
 int pci_enable_link_state(struct pci_dev *pdev, int state)
 {
+	/*
+	 * Ensure the device is in D0 before enabling PCI-PM L1 PM Substates, per
+	 * PCIe r6.0, sec 5.5.4.
+	 */
+	if (FIELD_GET(PCIE_LINK_STATE_L1_SS_PCIPM, state))
+		pci_set_power_state(pdev, PCI_D0);
+
 	return __pci_enable_link_state(pdev, state, false);
 }
 EXPORT_SYMBOL(pci_enable_link_state);
@@ -1500,8 +1507,8 @@ EXPORT_SYMBOL(pci_enable_link_state);
  * Note that if the BIOS didn't grant ASPM control to the OS, this does
  * nothing because we can't touch the LNKCTL register.
  *
- * Note: Ensure devices are in D0 before enabling PCI-PM L1 PM Substates, per
- * PCIe r6.0, sec 5.5.4.
+ * Note: The device will be transitioned to D0 state if the PCI-PM L1 Substates
+ * are getting enabled.
  *
  * Context: Caller holds pci_bus_sem read lock.
  *
@@ -1511,6 +1518,13 @@ int pci_enable_link_state_locked(struct pci_dev *pdev, int state)
 {
 	lockdep_assert_held_read(&pci_bus_sem);
 
+	/*
+	 * Ensure the device is in D0 before enabling PCI-PM L1 PM Substates, per
+	 * PCIe r6.0, sec 5.5.4.
+	 */
+	if (FIELD_GET(PCIE_LINK_STATE_L1_SS_PCIPM, state))
+		pci_set_power_state(pdev, PCI_D0);
+
 	return __pci_enable_link_state(pdev, state, true);
 }
 EXPORT_SYMBOL(pci_enable_link_state_locked);

-- 
2.45.2

