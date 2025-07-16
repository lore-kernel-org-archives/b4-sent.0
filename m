From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Wed, 16 Jul 2025 18:26:20 +0530
Subject: [PATCH 1/6] PCI/ASPM: Fix the behavior of pci_enable_link_state*()
 APIs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250716-ath-aspm-fix-v1-1-dd3e62c1b692@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=4956;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=txWReBCozsV6K3h+AVzcC8X3bIUcFoipF2Mk8WMybVc=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBod6F2nYK94za955ZeieEJ9Ez0Y2Av6XhQrppa5
 ebXFfv0PFmJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaHehdgAKCRBVnxHm/pHO
 9SHlB/90r+TtbKMkBbNeCDEVH/Jrf7o4re2piyrrsGCzh0idctS+oYCCeeT7jgzfq7ggdznpMMU
 mQr0I4UlVAchEjmViMQIM08lI3ua2e6agBSoTRvDOHv7nV14qK//rdbd6R2qvzrr3/Cp0G2XZAP
 A8w3Zxfv6fi5ggd68SOJj4IywptCrpisEU1IlZqjOAXzWsjWtKSsitJLWhgunEFfCNWymj0y4qz
 /Rga/kB3tRfYTfyFYxws1/DimAikv81gVwwh3IUwZqY8a0t5Po8SPP34YhBYIhWkGv0iKT/n+Fw
 RvxtKMfnFTDvKDABbaNKGVchiHyVSO5beEi5Oh6ETnWzwiR8
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

pci_enable_link_state() and pci_enable_link_state_locked() APIs are
supposed to be symmectric with pci_disable_link_state() and
pci_disable_link_state_locked() APIs.

But unfortunately, they are not symmetric. This behavior was mentioned in
the kernel-doc of these APIs:

" Clear and set the default device link state..."

and

"Also note that this does not enable states disabled by
pci_disable_link_state()"

These APIs won't enable all the states specified by the 'state' parameter,
but only enable the ones not previously disabled by the
pci_disable_link_state*() APIs. But this behavior doesn't align with the
naming of these APIs, as they give the impression that these APIs will
enable all the specified states.

To resolve this ambiguity, allow these APIs to enable the specified states,
regardeless of whether they were previously disabled or not. This is
accomplished by clearing the previously disabled states from the
'link::aspm_disable' parameter in __pci_enable_link_state() helper. Also,
reword the kernel-doc to reflect this behavior.

The current callers of pci_enable_link_state_locked() APIs (vmd and
pcie-qcom) did not disable the ASPM states before calling this API. So it
is evident that they do not depend on the previous behavior of this API and
intend to enable all the specified states.

And the other API, pci_enable_link_state() doesn't have a caller for now,
but will be used by the 'atheros' WLAN drivers in the subsequent commits.

Suggested-by: Ilpo Järvinen <ilpo.jarvinen@linux.intel.com>
Co-developed-by: Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>
Signed-off-by: Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/pcie/aspm.c | 33 ++++++++++++++++++---------------
 1 file changed, 18 insertions(+), 15 deletions(-)

diff --git a/drivers/pci/pcie/aspm.c b/drivers/pci/pcie/aspm.c
index 29fcb0689a918f9cb123691e1680de5a1af2c115..ec63880057942cef9ffbf3f67dcd87ee3d2df17d 100644
--- a/drivers/pci/pcie/aspm.c
+++ b/drivers/pci/pcie/aspm.c
@@ -1453,6 +1453,7 @@ static int __pci_enable_link_state(struct pci_dev *pdev, int state, bool locked)
 		down_read(&pci_bus_sem);
 	mutex_lock(&aspm_lock);
 	link->aspm_default = pci_calc_aspm_enable_mask(state);
+	link->aspm_disable &= ~state;
 	pcie_config_aspm_link(link, policy_to_aspm_state(link));
 
 	link->clkpm_default = (state & PCIE_LINK_STATE_CLKPM) ? 1 : 0;
@@ -1465,17 +1466,18 @@ static int __pci_enable_link_state(struct pci_dev *pdev, int state, bool locked)
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
+ * nothing because we can't touch the LNKCTL register.
  *
  * Note: Ensure devices are in D0 before enabling PCI-PM L1 PM Substates, per
  * PCIe r6.0, sec 5.5.4.
  *
- * @pdev: PCI device
- * @state: Mask of ASPM link states to enable
+ * Return: 0 on success, a negative errno otherwise.
  */
 int pci_enable_link_state(struct pci_dev *pdev, int state)
 {
@@ -1484,19 +1486,20 @@ int pci_enable_link_state(struct pci_dev *pdev, int state)
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
+ * nothing because we can't touch the LNKCTL register.
  *
  * Note: Ensure devices are in D0 before enabling PCI-PM L1 PM Substates, per
  * PCIe r6.0, sec 5.5.4.
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
2.45.2

