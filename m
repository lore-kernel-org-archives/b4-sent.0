From: Manivannan Sadhasivam <mani@kernel.org>
Date: Wed, 08 Jul 2026 16:30:18 +0200
Subject: [PATCH v3 4/8] PCI/ASPM: Improve the kernel-doc for
 pci_{enable,disable}_link_state*() APIs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260708-pci-aspm-fix-v3-4-6bd72451746e@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=4034; i=mani@kernel.org;
 h=from:subject:message-id; bh=XgClAjnhyiml8XcqJmydooMNI2pyqgbp7gCJozvqSQ0=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqTl7536htPm2+Z+Y3TZ++LzfQwUsWmNTkYTsAo
 pR++Vq69LuJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCak5e+QAKCRBVnxHm/pHO
 9d6GB/4gFDbW2k6rvRFAVXErqcl6iisx10DlBU7FdtAsPYq9rrPjv9r26SgQGwr5/swGAjJOaon
 hiuNPLT58G5Y/hJs6VfYFTEyO/lWptPDC22XsXPA05Zyiyp6PQsv1jxh9hp9Kbn3+xCBx081nfE
 oMUMjO0LX9zwxjj6ecs8jTyt9rMZqH/ivA3gO9uMvStCo7DhT+iK/H33oug7FqHL5VbKv/1fgKd
 p93eH+WkbR1egae/5Z/1lwl+crm7zqTz5JPMPQlVx2FCZ0GIrbvXSeqN2CSnYgwjr1RgkeBwIw6
 1gr5mPep2A3VaNEEcPI4vA2lUMJzOejlXtKTOYSqvbcsM8+p
X-Developer-Key: i=mani@kernel.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for mani@kernel.org/default with auth_id=787
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

Add kernel-doc for pci_disable_link_state_locked() API and fix the
kernel-doc for pci_disable_link_state() API.

Also convert the kernel-doc of pci_enable_link_state() and
pci_enable_link_state_locked() APIs to the standard format and mention that
pci_force_enable_link_state() should be used to re-enable the states
disabled by pci_disable_link_state().

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/pcie/aspm.c | 47 ++++++++++++++++++++++++++++++++---------------
 1 file changed, 32 insertions(+), 15 deletions(-)

diff --git a/drivers/pci/pcie/aspm.c b/drivers/pci/pcie/aspm.c
index 6d6862fd2ebb..5e7e199c78d2 100644
--- a/drivers/pci/pcie/aspm.c
+++ b/drivers/pci/pcie/aspm.c
@@ -1483,6 +1483,17 @@ static int __pci_disable_link_state(struct pci_dev *pdev, int state, bool locked
 	return 0;
 }
 
+/**
+ * pci_disable_link_state_locked - Disable device's link state
+ * @pdev: PCI device
+ * @state: ASPM link state to disable
+ *
+ * Disable device's link state so the link will never enter specific states.
+ *
+ * Context: Caller holds pci_bus_sem read lock.
+ *
+ * Return: 0 on success, a negative errno otherwise.
+ */
 int pci_disable_link_state_locked(struct pci_dev *pdev, int state)
 {
 	lockdep_assert_held_read(&pci_bus_sem);
@@ -1555,17 +1566,20 @@ static int __pci_enable_link_state(struct pci_dev *pdev, int state, bool locked,
 }
 
 /**
- * pci_enable_link_state - Clear and set the default device link state so that
- * the link may be allowed to enter the specified states. Note that if the
- * BIOS didn't grant ASPM control to the OS, this does nothing because we can't
- * touch the LNKCTL register. Also note that this does not enable states
- * disabled by pci_disable_link_state(). Return 0 or a negative errno.
+ * pci_enable_link_state - Enable device's link state
+ * @pdev: PCI device
+ * @state: Mask of ASPM link states to enable
+ *
+ * Enable device's link state, so the link will enter the specified states.
+ * Note that if the BIOS didn't grant ASPM control to the OS, this does
+ * nothing because we can't touch the LNKCTL register. Also note that this
+ * does not enable states disabled by pci_disable_link_state(). Use
+ * pci_force_enable_link_state() for that.
  *
  * Note: The device will be transitioned to D0 state if the PCI-PM L1 Substates
  * are getting enabled.
  *
- * @pdev: PCI device
- * @state: Mask of ASPM link states to enable
+ * Return: 0 on success, a negative errno otherwise.
  */
 int pci_enable_link_state(struct pci_dev *pdev, int state)
 {
@@ -1574,19 +1588,22 @@ int pci_enable_link_state(struct pci_dev *pdev, int state)
 EXPORT_SYMBOL(pci_enable_link_state);
 
 /**
- * pci_enable_link_state_locked - Clear and set the default device link state
- * so that the link may be allowed to enter the specified states. Note that if
- * the BIOS didn't grant ASPM control to the OS, this does nothing because we
- * can't touch the LNKCTL register. Also note that this does not enable states
- * disabled by pci_disable_link_state(). Return 0 or a negative errno.
+ * pci_enable_link_state_locked - Enable device's link state
+ * @pdev: PCI device
+ * @state: Mask of ASPM link states to enable
+ *
+ * Enable device's link state, so the link will enter the specified states.
+ * Note that if the BIOS didn't grant ASPM control to the OS, this does
+ * nothing because we can't touch the LNKCTL register. Also note that this
+ * does not enable states disabled by pci_disable_link_state(). Use
+ * pci_force_enable_link_state() for that.
  *
  * Note: The device will be transitioned to D0 state if the PCI-PM L1 Substates
  * are getting enabled.
  *
- * @pdev: PCI device
- * @state: Mask of ASPM link states to enable
- *
  * Context: Caller holds pci_bus_sem read lock.
+ *
+ * Return: 0 on success, a negative errno otherwise.
  */
 int pci_enable_link_state_locked(struct pci_dev *pdev, int state)
 {

-- 
2.43.0

