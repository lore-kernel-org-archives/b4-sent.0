From: Manivannan Sadhasivam <mani@kernel.org>
Date: Wed, 08 Jul 2026 16:30:15 +0200
Subject: [PATCH v3 1/8] PCI/ASPM: Always disable ASPM when driver requests
 it
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260708-pci-aspm-fix-v3-1-6bd72451746e@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=4353; i=mani@kernel.org;
 h=from:subject:message-id; bh=D4w9YT637FWLwgGnXYf3ez0AiW99miyOiPTxsYowQUw=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqTl73FnTd3FyCB9aJRYE2UOKhmwqdo19Kc5ziJ
 7sAwr/kAXSJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCak5e9wAKCRBVnxHm/pHO
 9f50B/92ojehwpKQmD7fMrpHqUlkMXlLamTGMqdbknwGUnu/SaSgOmRdv6pQPrzr5EGUI3MBTIr
 mZ+pcC9qimhjXzkzAfuMJaLtNLW1bM2Fyk/sTbPnG7cG3dkWx1Lo2UuCHZcppRdOjocDScSjuup
 X7voUBR4odulK89JVh+URt2I2Dn/NF0mcrlU/dOVo7mS1tglGAHXlMSKZpLl+LiaSSQ7taZHfiH
 TtYuOD03UTxXhCOoWYlkkVjM/fobA6tiE1aF4aDv/up2b1smVe/0V5xfF8RhOR2nm4DQY8whvho
 ZF0E9epv6ByhHnflSnJuKlByNi4Ky1tPc0IltsOr9dYJl3t0
X-Developer-Key: i=mani@kernel.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for mani@kernel.org/default with auth_id=787
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Ilpo Järvinen <ilpo.jarvinen@linux.intel.com>

PCI core/ASPM service driver allows controlling ASPM state through
pci_disable_link_state() API. It was decided earlier (see the Link
below), to not allow ASPM changes when OS does not have control over it
but only log a warning about the problem 'commit 2add0ec14c25 ("PCI/ASPM:
Warn when driver asks to disable ASPM, but we can't do it")'.

A number of drivers have added workarounds to force ASPM off with own
writes into the Link Control Register (some even with comments
explaining why PCI core does not disable it under some circumstances).
According to the comments, some drivers require ASPM to be off for
reliable operation.

Having custom ASPM handling in drivers is problematic because the state
kept in the ASPM service driver is not updated by the changes made
outside the link state management API.

As the first step to address this issue, make pci_disable_link_state()
to unconditionally disable ASPM so the motivation for drivers to come
up with custom ASPM handling code is eliminated.

To fully take advantage of the ASPM handling core provides, the drivers
that need to quirk ASPM have to be altered depend on PCIEASPM and the
custom ASPM code is removed. This is to be done separately. As PCIEASPM
is already behind EXPERT, it should be no problem to limit disabling it
for configurations that do not require touching ASPM.

Make pci_disable_link_state() function comment to comply kerneldoc
formatting while changing the description.

Link: https://lore.kernel.org/all/CANUX_P3F5YhbZX3WGU-j1AGpbXb_T9Bis2ErhvKkFMtDvzatVQ@mail.gmail.com/
Link: https://lore.kernel.org/all/20230511131441.45704-1-ilpo.jarvinen@linux.intel.com/
Signed-off-by: Ilpo Järvinen <ilpo.jarvinen@linux.intel.com>
[mani: commit message fixup]
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/pcie/aspm.c | 33 ++++++++++++++++++++-------------
 1 file changed, 20 insertions(+), 13 deletions(-)

diff --git a/drivers/pci/pcie/aspm.c b/drivers/pci/pcie/aspm.c
index 172783e7f519..1c15a14718e8 100644
--- a/drivers/pci/pcie/aspm.c
+++ b/drivers/pci/pcie/aspm.c
@@ -1449,16 +1449,23 @@ static int __pci_disable_link_state(struct pci_dev *pdev, int state, bool locked
 		return -EINVAL;
 	/*
 	 * A driver requested that ASPM be disabled on this device, but
-	 * if we don't have permission to manage ASPM (e.g., on ACPI
+	 * if we might not have permission to manage ASPM (e.g., on ACPI
 	 * systems we have to observe the FADT ACPI_FADT_NO_ASPM bit and
-	 * the _OSC method), we can't honor that request.  Windows has
-	 * a similar mechanism using "PciASPMOptOut", which is also
-	 * ignored in this situation.
+	 * the _OSC method), previously we chose to not honor disable
+	 * request in that case. Windows has a similar mechanism using
+	 * "PciASPMOptOut", which is also ignored in this situation.
+	 *
+	 * Not honoring the requests to disable ASPM, however, led to
+	 * drivers forcing ASPM off on their own. As such changes of ASPM
+	 * state are not tracked by this service driver, the state kept here
+	 * became out of sync.
+	 *
+	 * Therefore, honor ASPM disable requests even when OS does not have
+	 * ASPM control. Plain disable for ASPM is assumed to be slightly
+	 * safer than fully managing it.
 	 */
-	if (aspm_disabled) {
-		pci_warn(pdev, "can't disable ASPM; OS doesn't have ASPM control\n");
-		return -EPERM;
-	}
+	if (aspm_disabled)
+		pci_warn(pdev, "OS doesn't have ASPM control, disabling ASPM anyway\n");
 
 	if (!locked)
 		down_read(&pci_bus_sem);
@@ -1485,13 +1492,13 @@ int pci_disable_link_state_locked(struct pci_dev *pdev, int state)
 EXPORT_SYMBOL(pci_disable_link_state_locked);
 
 /**
- * pci_disable_link_state - Disable device's link state, so the link will
- * never enter specific states.  Note that if the BIOS didn't grant ASPM
- * control to the OS, this does nothing because we can't touch the LNKCTL
- * register. Returns 0 or a negative errno.
- *
+ * pci_disable_link_state - Disable device's link state
  * @pdev: PCI device
  * @state: ASPM link state to disable
+ *
+ * Disable device's link state so the link will never enter specific states.
+ *
+ * Return: 0 or a negative errno
  */
 int pci_disable_link_state(struct pci_dev *pdev, int state)
 {

-- 
2.43.0

