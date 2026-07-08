From: Manivannan Sadhasivam <mani@kernel.org>
Date: Wed, 08 Jul 2026 16:30:17 +0200
Subject: [PATCH v3 3/8] PCI/ASPM: Transition the device to D0 (if required)
 when enabling ASPM link states
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260708-pci-aspm-fix-v3-3-6bd72451746e@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=4530; i=mani@kernel.org;
 h=from:subject:message-id; bh=eN8FiCdGdbeUI39wBlUZELPWwOUG9j0iJUbJK/xZFBw=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqTl74efK/Ai2x0uHQ4mqtQkU8ooqxnXudiFrXg
 XsrnmsIH8uJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCak5e+AAKCRBVnxHm/pHO
 9YxaCACO28V3wROkvPTSmhskvI+UjcCjrMS1wY2edQf4bTICp+480nDgV3gTbJpRm4kJttXNlwO
 bC6tgagWp9VUhLb5CVAA9u9cAYf4bH8Emjb7/iDDZTwH8pxBiJ9oDa0BJmRGTXAts0oapdpF1vk
 44Qibcc1ZpIpfVVwzENLF02X4ZjrO/CrTniD+P4LUkA0t1L+W4d9PW0icrymu0nktqayckHlJ8x
 mabEoMNDTVYcoymRyuakmV8OqwgptaadyBx+5C1FMUolVxyE+nhsa1sBAtcZwqM4bc0jnGkxVEb
 ApsGRWy9IIvgVNWTzqDA5er5LV3U891/iSpdxcuh+yrxgqcz
X-Developer-Key: i=mani@kernel.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for mani@kernel.org/default with auth_id=787
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

Per PCIe spec r6.0, sec 5.5.4:

"If setting either or both of the enable bits for PCI-PM L1 PM Substates,
both ports must be configured as described in this section while in D0."

Currently, the callers of pci_enable_link_state_locked() (vmd, pcie-qcom)
transition the device to D0 themselves before enabling the link state. But
this is easy to get wrong and has to be duplicated by every caller.

Move the D0 transition into the shared __pci_enable_link_state() helper so
that all three APIs pci_enable_link_state(), pci_enable_link_state_locked()
and pci_force_enable_link_state() perform it, and only when the PCI-PM L1
PM Substates are getting enabled.

Now that the helper handles the transition, drop the redundant D0 transition
from the vmd and pcie-qcom callers.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/controller/dwc/pcie-qcom.c |  5 -----
 drivers/pci/controller/vmd.c           |  5 -----
 drivers/pci/pcie/aspm.c                | 23 +++++++++++++++++------
 3 files changed, 17 insertions(+), 16 deletions(-)

diff --git a/drivers/pci/controller/dwc/pcie-qcom.c b/drivers/pci/controller/dwc/pcie-qcom.c
index d8eb52857f69..45f4caeb0814 100644
--- a/drivers/pci/controller/dwc/pcie-qcom.c
+++ b/drivers/pci/controller/dwc/pcie-qcom.c
@@ -1085,11 +1085,6 @@ static int qcom_pcie_post_init_2_7_0(struct qcom_pcie *pcie)
 
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
index d4ae250d4bc6..20597d2cf66e 100644
--- a/drivers/pci/controller/vmd.c
+++ b/drivers/pci/controller/vmd.c
@@ -762,11 +762,6 @@ static int vmd_pm_enable_quirk(struct pci_dev *pdev, void *userdata)
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
index c04fb71de91c..6d6862fd2ebb 100644
--- a/drivers/pci/pcie/aspm.c
+++ b/drivers/pci/pcie/aspm.c
@@ -1524,6 +1524,17 @@ static int __pci_enable_link_state(struct pci_dev *pdev, int state, bool locked,
 		return -EPERM;
 	}
 
+	/*
+	 * Ensure the device is in D0 before enabling PCI-PM L1 PM Substates, per
+	 * PCIe r6.0, sec 5.5.4.
+	 */
+	if (state & PCIE_LINK_STATE_L1_SS_PCIPM) {
+		if (locked)
+			pci_set_power_state_locked(pdev, PCI_D0);
+		else
+			pci_set_power_state(pdev, PCI_D0);
+	}
+
 	if (!locked)
 		down_read(&pci_bus_sem);
 	mutex_lock(&aspm_lock);
@@ -1550,8 +1561,8 @@ static int __pci_enable_link_state(struct pci_dev *pdev, int state, bool locked,
  * touch the LNKCTL register. Also note that this does not enable states
  * disabled by pci_disable_link_state(). Return 0 or a negative errno.
  *
- * Note: Ensure devices are in D0 before enabling PCI-PM L1 PM Substates, per
- * PCIe r6.0, sec 5.5.4.
+ * Note: The device will be transitioned to D0 state if the PCI-PM L1 Substates
+ * are getting enabled.
  *
  * @pdev: PCI device
  * @state: Mask of ASPM link states to enable
@@ -1569,8 +1580,8 @@ EXPORT_SYMBOL(pci_enable_link_state);
  * can't touch the LNKCTL register. Also note that this does not enable states
  * disabled by pci_disable_link_state(). Return 0 or a negative errno.
  *
- * Note: Ensure devices are in D0 before enabling PCI-PM L1 PM Substates, per
- * PCIe r6.0, sec 5.5.4.
+ * Note: The device will be transitioned to D0 state if the PCI-PM L1 Substates
+ * are getting enabled.
  *
  * @pdev: PCI device
  * @state: Mask of ASPM link states to enable
@@ -1600,8 +1611,8 @@ EXPORT_SYMBOL(pci_enable_link_state_locked);
  * Note that if the BIOS didn't grant ASPM control to the OS, this does nothing
  * because we can't touch the LNKCTL register.
  *
- * Note: Ensure devices are in D0 before enabling PCI-PM L1 PM Substates, per
- * PCIe r6.0, sec 5.5.4.
+ * Note: The device will be transitioned to D0 state if the PCI-PM L1 Substates
+ * are getting enabled.
  *
  * Return: 0 on success, a negative errno otherwise.
  */

-- 
2.43.0

