From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH v2 0/8] PCI/ASPM: Fix pci_enable_link_state*() APIs
 behavior
Date: Mon, 25 Aug 2025 23:14:35 +0530
Message-Id: <20250825-ath-aspm-fix-v2-0-61b2f2db7d89@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAOhrGgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyjHQUlJIzE
 vPSU3UzU4B8JSMDI1MDCyNT3cSSDN3E4oJc3bTMCl1TC4s0Q2PTZMu0JEsloJaColSgMNi46Nj
 aWgCyZBHJXgAAAA==
X-Change-ID: 20250825-ath-aspm-fix-588f135c9fb9
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
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Qiang Yu <qiang.yu@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3844;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=ScdUxidEQcv0lLc6SYd7NOOa4CGgpMbRHWOtssqifAA=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBorKEOm8o854j5OzwtUCAtHgkO4SxNcFD6l/mTW
 yDz9WsMo+mJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaKyhDgAKCRBVnxHm/pHO
 9cICCACoyDcpWLciZ9mGj6v2OKCXgoebAq/c+dWKacvurO+u8zkaubUrk5WvEDHZGBa/tgGuKb3
 eMt1nbQflaBPVZoMw7ozg/NEmw0k9MMPUYBGhQEllopS6NL2aUAXq74QB086EkRHiHlXmneANPV
 GyrAXimgn2Vu+0aLWPqfMIVgRvELuqudksg4B9epcrkSwctK/IBBi+cCDCD2txW6qglb/My28ty
 v3avopLz4kbih4mKNBYeGyM0ZefuNeQJYgN+6Tpfw+aCep01fzpTcd0VlxseIxks0ZOk7Cxjkmx
 aDV7BjvfbnjMxah3VTmJk6tRKwyTIfddLgWrCA8XYUh6KRF8
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series fixes the behavior of the pci_enable_link_state() and
pci_enable_link_state_locked() APIs to be in symmetry with
pci_disable_link_state*() couterparts.

First 5 patches fixes and cleans up the ASPM code and the last 3 patches
modifies the atheros drivers to use the pci{enable/disable}_link_state() APIs
instead of modifying the LNKCTL register directly for enabling ASPM.

NOTE: The current callers of the pci_enable_link_state_locked() APIs (vmd and
pcie-qcom) drivers doesn't look like depending on the old behavior of the API. I
can atleast assure that for pcie-qcom. For VMD, it would be great if VMD folks
CCed could provide their review tags for patch 2/6.

Also in this version, I've included a patch from Ilpo (patch 1) that disables
ASPM forcefully even if BIOS/ACPI didn't grant us permission. More details are
in the patch description. I think this patch is needed anyway since the device
drivers are forcefully disabling it even if PCI core was skipping ASPM disable
previously.

Testing
=======

I've tested this series on Lenovo Thinkpad T14s with WCN7850 chipset (so that's
just ath12k driver). Rest of the drivers are compile tested only.

Merging Strategy
================

Even though there is no build dependency between PCI core and atheros patches,
there is a functional dependency. So I'd recommend creating an immutable branch
with PCI patches and merging that branch into both PCI and linux-wireless trees
and finally merging the atheros patches into linux-wireless tree.

If immutable branch seems like a hassle, then PCI core patches could get merged
for 6.18 and atheros patches can wait for 6.19.

- Mani

Changes in v2:

* Reworked the pcie_aspm_enabled() API to return the enabled states instead of
  bool and used it to save/restore the ASPM states in ath drivers.
* Added a patch from Ilpo to disable ASPM even if BIOS didn't grant permission
* Added the CONFIG_PCIEASPM dependency to ath{10/11/12}k drivers as they now
  depend on the ASPM APIs for stable operation.
* Rebased on top of v6.17-rc1

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
Ilpo Järvinen (1):
      PCI/ASPM: Always disable ASPM when driver requests it

Manivannan Sadhasivam (7):
      PCI/ASPM: Fix the behavior of pci_enable_link_state*() APIs
      PCI/ASPM: Transition the device to D0 (if required) inside pci_enable_link_state_locked() API
      PCI/ASPM: Improve the kernel-doc for pci_disable_link_state*() APIs
      PCI/ASPM: Return enabled ASPM states from pcie_aspm_enabled() API
      wifi: ath12k: Use pci_{enable/disable}_link_state() APIs to enable/disable ASPM states
      wifi: ath11k: Use pci_{enable/disable}_link_state() APIs to enable/disable ASPM states
      wifi: ath10k: Use pci_{enable/disable}_link_state() APIs to enable/disable ASPM states

 drivers/net/wireless/ath/ath10k/Kconfig |   2 +-
 drivers/net/wireless/ath/ath10k/pci.c   |  11 ++--
 drivers/net/wireless/ath/ath10k/pci.h   |   5 +-
 drivers/net/wireless/ath/ath11k/Kconfig |   2 +-
 drivers/net/wireless/ath/ath11k/pci.c   |  19 +-----
 drivers/net/wireless/ath/ath11k/pci.h   |   3 +-
 drivers/net/wireless/ath/ath12k/Kconfig |   2 +-
 drivers/net/wireless/ath/ath12k/pci.c   |  19 +-----
 drivers/net/wireless/ath/ath12k/pci.h   |   4 +-
 drivers/pci/controller/dwc/pcie-qcom.c  |   5 --
 drivers/pci/controller/vmd.c            |   5 --
 drivers/pci/pcie/aspm.c                 | 103 ++++++++++++++++++++++----------
 include/linux/pci.h                     |   4 +-
 13 files changed, 92 insertions(+), 92 deletions(-)
---
base-commit: 8f5ae30d69d7543eee0d70083daf4de8fe15d585
change-id: 20250825-ath-aspm-fix-588f135c9fb9

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

