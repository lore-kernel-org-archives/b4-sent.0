From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH v2 0/2] PCI/ASPM: Enable ASPM and Clock PM by default on
 devicetree platforms
Date: Mon, 22 Sep 2025 21:46:43 +0530
Message-Id: <20250922-pci-dt-aspm-v2-0-2a65cf84e326@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGt20WgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyjHQUlJIzE
 vPSU3UzU4B8JSMDI1MDS0Mz3YLkTN2UEt3E4oJcXYsk40TzVIsUo+Q0QyWgjoKi1LTMCrBp0bG
 1tQDLM5X6XQAAAA==
X-Change-ID: 20250916-pci-dt-aspm-8b3a7e8d2cf1
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, "David E. Box" <david.e.box@linux.intel.com>, 
 Kai-Heng Feng <kai.heng.feng@canonical.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Chia-Lin Kao <acelan.kao@canonical.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Bjorn Helgaas <helgaas@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3211;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=VrVbBbAkZX7N6X1ZFNXfWGktbwkiMT+UGCeuD3oUrho=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBo0XZu+sVRoNvesArpOMqAyXXGDhGGtiBu/MQrC
 MvA5UcMprqJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaNF2bgAKCRBVnxHm/pHO
 9VDDB/sGzXZBIjGWh/XLdq/tQ505y4S/Iy0tr4X9enEgJMfKDwizHblZ0/OjDhcDJ4qttRLcAQQ
 edMyfOVWIT/+4phq0V9wGr2AcK7doEsmeey6eUZ1qtgXMfneNJQs/rIwrChVwQnisPvk4RznPik
 7h6HM8osZeYqGg63mDgjTEubQQtSriUer9Wljb8c0gM97uzk0EFwi9JB43AboMx7VstKUgf2Gkr
 yT0NVk2UQ/oaZDf6XVaG/u9OJ1jaJqwLaifSVDFF+DXnv4Mh2o8BCpXMbhVhCkPRpRolgyJjXDe
 9VZlILCw1RGL+zqjcHJTBOaEyOiBX4dYTJawC/ElVg+MXX4a
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series is one of the 'let's bite the bullet' kind, where we have decided to
enable all ASPM and Clock PM states by default on devicetree platforms [1]. The
reason why devicetree platforms were chosen because, it will be of minimal
impact compared to the ACPI platforms. So seemed ideal to test the waters.

Problem Statement
=================

Historically, PCI subsystem relied on the BIOS to enable ASPM and Clock PM
states for PCI devices before the kernel boot if the default states are
selected using:

* Kconfig: CONFIG_PCIEASPM_DEFAULT=y, or
* cmdline: "pcie_aspm=off", or
* FADT: ACPI_FADT_NO_ASPM

This was done to avoid enabling ASPM for the buggy devices that are known to
create issues with ASPM (even though they advertise the ASPM capability). But
BIOS is not at all a thing on most of the non-x86 platforms. For instance, the
majority of the Embedded and Compute ARM based platforms using devicetree have
something called bootloader, which is not anyway near the standard BIOS used in
x86 based platforms. And these bootloaders wouldn't touch PCIe at all, unless
they boot using PCIe storage, even then there would be no guarantee that the
ASPM states will get enabled. Another example is the Intel's VMD domain that is
not at all configured by the BIOS. But, this series is not enabling ASPM/Clock
PM for VMD domain. I hope it will be done similarly in the future patches.

Solution
========

So to avoid relying on BIOS, it was agreed [2] that the PCI subsystem has to
enable ASPM and Clock PM states based on the device capability. If any devices
misbehave, then they should be quirked accordingly.

First patch of this series introduces two helper functions to enable all ASPM
and Clock PM states if of_have_populated_dt() is true. Second patch drops the
custom ASPM enablement code from the pcie-qcom driver as it is no longer needed.

Testing
=======

This series is tested on Lenovo Thinkpad T14s based on Snapdragon X1 SoC. All
supported ASPM states are getting enabled for both the NVMe and WLAN devices by
default.

[1] https://lore.kernel.org/linux-pci/a47sg5ahflhvzyzqnfxvpk3dw4clkhqlhznjxzwqpf4nyjx5dk@bcghz5o6zolk
[2] https://lore.kernel.org/linux-pci/20250828204345.GA958461@bhelgaas

Changes in v2:

- Used of_have_populated_dt() instead of CONFIG_OF to identify devicetree
  platforms
- Renamed the override helpers and changed the override print
- Moved setting the default state back to the original place and only kept the
  override in helpers

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
Manivannan Sadhasivam (2):
      PCI/ASPM: Override the ASPM and Clock PM states set by BIOS for devicetree platforms
      PCI: qcom: Remove the custom ASPM enablement code

 drivers/pci/controller/dwc/pcie-qcom.c | 32 --------------------------
 drivers/pci/pcie/aspm.c                | 42 ++++++++++++++++++++++++++++++++--
 2 files changed, 40 insertions(+), 34 deletions(-)
---
base-commit: 8f5ae30d69d7543eee0d70083daf4de8fe15d585
change-id: 20250916-pci-dt-aspm-8b3a7e8d2cf1

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

