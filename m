From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH v5 00/15] PCI/pwrctrl: Major rework to integrate pwrctrl
 devices with controller drivers
Date: Thu, 15 Jan 2026 12:58:52 +0530
Message-Id: <20260115-pci-pwrctrl-rework-v5-0-9d26da3ce903@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADSXaGkC/33RwW4CIRAG4FfZcC4bhoVh8eR7ND2wgJVUZYUVN
 cZ3L6tp2sPaC8lPZr5JZm4k+xR8JqvmRpIvIYd4qEG+NcRuzeHT0+BqJpxxCcAFHW2g4znZKe1
 o8ueYvqjVYNADWr5BUhvH5Dfh8kDfP2rehjzFdH3MKDD//ssVoIyq3iiOXGHfuXXMuT2ezM7G/
 b6tD5nVwn8lDrgo8VkS0kjsBj14fCF1fySuF6WuSlY5qaG3jrnhhSR+JGTA5KIkqoROgFFGaNX
 rBen+XGLyx1M9yPTcJBlM9nQuCtOqKdiCpslCrb5/A7PN89rGAQAA
X-Change-ID: 20251124-pci-pwrctrl-rework-c91a6e16c2f6
To: Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Bartosz Golaszewski <brgl@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, Jingoo Han <jingoohan1@gmail.com>
Cc: linux-pci@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Chen-Yu Tsai <wens@kernel.org>, 
 Brian Norris <briannorris@chromium.org>, 
 Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>, 
 Niklas Cassel <cassel@kernel.org>, Alex Elder <elder@riscstar.com>, 
 Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Chen-Yu Tsai <wenst@chromium.org>, 
 Bartosz Golaszewski <bartosz.golaszewski@linaro.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=8206;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=iQMoBuu6wuN6TAp0y08sjEZPbzS3peNf2Cw/XEH/LaE=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpaJc9A1FjDrjjZCP9jVS6z0jgR0fH9GU2vDOBo
 lqYfs+AQLiJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaWiXPQAKCRBVnxHm/pHO
 9TbDB/wJFN3bIgwJp5qDoidFBBgKnk8NmsnVBIhAEKBykjDJA2FZvK3pIXsEmLhMzqRCLEWTcUg
 ECtJIktoi0+ozKpJOCHFhyjEKKQjw4ePsPtBaa67Npnmnneon7PmJp1re2qTeUhCnBRcqKA4Zn8
 0WwOFrcJFPJemi3VIq/Kwn23Aj7Q1tsa1CGd8akO9dHm0VVhHtsTBXx4mw2ka0NjVB4I562pm/7
 pxxnQ3mTZqL+uqKRLY6aSC5TdqafiphnITfSEu+OArsgoAV+YKk24NfWfNVY5575Tb70RylqNTq
 1p5avHxceCTUm4uz92jV3r7+mqGAk2ZraK1ymHqWABW50KIt
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series provides a major rework for the PCI power control (pwrctrl)
framework to enable the pwrctrl devices to be controlled by the PCI controller
drivers.

Problem Statement
=================

Currently, the pwrctrl framework faces two major issues:

1. Missing PERST# integration
2. Inability to properly handle bus extenders such as PCIe switch devices

First issue arises from the disconnect between the PCI controller drivers and
pwrctrl framework. At present, the pwrctrl framework just operates on its own
with the help of the PCI core. The pwrctrl devices are created by the PCI core
during initial bus scan and the pwrctrl drivers once bind, just power on the
PCI devices during their probe(). This design conflicts with the PCI Express
Card Electromechanical Specification requirements for PERST# timing. The reason
is, PERST# signals are mostly handled by the controller drivers and often
deasserted even before the pwrctrl drivers probe. According to the spec, PERST#
should be deasserted only after power and reference clock to the device are
stable, within predefined timing parameters.

The second issue stems from the PCI bus scan completing before pwrctrl drivers
probe. This poses a significant problem for PCI bus extenders like switches
because the PCI core allocates upstream bridge resources during the initial
scan. If the upstream bridge is not hotplug capable, resources are allocated
only for the number of downstream buses detected at scan time, which might be
just one if the switch was not powered and enumerated at that time. Later, when
the pwrctrl driver powers on and enumerates the switch, enumeration fails due to
insufficient upstream bridge resources.

Proposal
========

This series addresses both issues by introducing new individual APIs for pwrctrl
device creation, destruction, power on, and power off operations. Controller
drivers are expected to invoke these APIs during their probe(), remove(),
suspend(), and resume() operations. This integration allows better coordination
between controller drivers and the pwrctrl framework, enabling enhanced features
such as D3Cold support.

The original design aimed to avoid modifying controller drivers for pwrctrl
integration. However, this approach lacked scalability because different
controllers have varying requirements for when devices should be powered on. For
example, controller drivers require devices to be powered on early for
successful PHY initialization.

By using these explicit APIs, controller drivers gain fine grained control over
their associated pwrctrl devices.

This series modified the pcie-qcom driver (only consumer of pwrctrl framework)
to adopt to these APIs and also removed the old pwrctrl code from PCI core. This
could be used as a reference to add pwrctrl support for other controller drivers
also.

For example, to control the 3.3v supply to the PCI slot where the NVMe device is
connected, below modifications are required:

Devicetree
----------

	// In SoC dtsi:

	pci@1bf8000 { // controller node
		...
		pcie1_port0: pcie@0 { // PCI Root Port node
			compatible = "pciclass,0604"; // required for pwrctrl
							 driver bind
			...
		};
	};

	// In board dts:

	&pcie1_port0 {
		reset-gpios = <&tlmm 152 GPIO_ACTIVE_LOW>; // optional
		vpcie3v3-supply = <&vreg_nvme>; // NVMe power supply
	};

Controller driver
-----------------

	// Select PCI_PWRCTRL_SLOT in controller Kconfig

	probe() {
		...
		// Initialize controller resources
		pci_pwrctrl_create_devices(&pdev->dev);
		pci_pwrctrl_power_on_devices(&pdev->dev);
		// Deassert PERST# (optional)
		...
		pci_host_probe(); // Allocate host bridge and start bus scan
	}

	suspend {
		// PME_Turn_Off broadcast
		// Assert PERST# (optional)
		pci_pwrctrl_power_off_devices(&pdev->dev);
		...
	}

	resume {
		...
		pci_pwrctrl_power_on_devices(&pdev->dev);
		// Deassert PERST# (optional)
	}

I will add a documentation for the pwrctrl framework in the coming days to make
it easier to use.

Testing
=======

This series is tested on the Lenovo Thinkpad T14s laptop based on Qcom X1E
chipset and RB3Gen2 development board with TC9563 switch based on Qcom QCS6490
chipset.

**NOTE**: With this series, the controller driver may undergo multiple probe
deferral if the pwrctrl driver was not available during the controller driver
probe. This is pretty much required to avoid the resource allocation issue. I
plan to replace probe deferral with blocking wait in the coming days.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
Changes in v5:
- Incorporated cleanups from Bjorn
- Splitted the power on/off callback changes
- Collected tags
- Link to v4: https://lore.kernel.org/r/20260105-pci-pwrctrl-rework-v4-0-6d41a7a49789@oss.qualcomm.com

Changes in v4:
- Used platform_device_put()
- Changed the return value of power_off() callback to 'int'
- Splitted patch 6 into two and reworded the commit message
- Collected tags
- Link to v3: https://lore.kernel.org/r/20251229-pci-pwrctrl-rework-v3-0-c7d5918cd0db@oss.qualcomm.com

Changes in v3:
- Integrated TC9563 change
- Reworked the power_on API to properly power off the devices in error path
- Fixed the error path in pcie-qcom.c to not destroy pwrctrl devices during
  probe deferral
- Rebased on top of pci/controller/dwc-qcom branch and dropped the PERST# patch
- Added a patch for TC9563 to fix the refcount dropping for i2c adapter
- Added patches to drop the assert_perst callback and rename the PERST# helpers in
  pcie-qcom.c
- Link to v2: https://lore.kernel.org/r/20251216-pci-pwrctrl-rework-v2-0-745a563b9be6@oss.qualcomm.com

Changes in v2:
- Exported of_pci_supply_present() API
- Demoted the -EPROBE_DEFER log to dev_dbg()
- Collected tags and rebased on top of v6.19-rc1
- Link to v1: https://lore.kernel.org/r/20251124-pci-pwrctrl-rework-v1-0-78a72627683d@oss.qualcomm.com

---
Bjorn Helgaas (5):
      PCI/pwrctrl: pwrseq: Rename private struct and pointers for consistency
      PCI/pwrctrl: slot: Rename private struct and pointers for consistency
      PCI/pwrctrl: tc9563: Clean up whitespace
      PCI/pwrctrl: tc9563: Add local variables to reduce repetition
      PCI/pwrctrl: tc9563: Rename private struct and pointers for consistency

Krishna Chaitanya Chundru (1):
      PCI/pwrctrl: Add APIs to create, destroy pwrctrl devices

Manivannan Sadhasivam (9):
      PCI/pwrctrl: tc9563: Use put_device() instead of i2c_put_adapter()
      PCI/pwrctrl: slot: Factor out power on/off code to helpers
      PCI/pwrctrl: pwrseq: Factor out power on/off code to helpers
      PCI/pwrctrl: Add 'struct pci_pwrctrl::power_{on/off}' callbacks
      PCI/pwrctrl: Add APIs to power on/off pwrctrl devices
      PCI/pwrctrl: Switch to pwrctrl create, power on/off, destroy APIs
      PCI: qcom: Drop the assert_perst() callbacks
      PCI: Drop the assert_perst() callback
      PCI: qcom: Rename PERST# assert/deassert helpers for uniformity

 drivers/pci/bus.c                                 |  19 --
 drivers/pci/controller/dwc/pcie-designware-host.c |   9 -
 drivers/pci/controller/dwc/pcie-designware.h      |   9 -
 drivers/pci/controller/dwc/pcie-qcom.c            |  55 +++--
 drivers/pci/of.c                                  |   1 +
 drivers/pci/probe.c                               |  59 -----
 drivers/pci/pwrctrl/core.c                        | 259 ++++++++++++++++++++--
 drivers/pci/pwrctrl/pci-pwrctrl-pwrseq.c          |  50 +++--
 drivers/pci/pwrctrl/pci-pwrctrl-tc9563.c          | 226 ++++++++++---------
 drivers/pci/pwrctrl/slot.c                        |  60 +++--
 drivers/pci/remove.c                              |  20 --
 include/linux/pci-pwrctrl.h                       |  16 +-
 include/linux/pci.h                               |   1 -
 13 files changed, 484 insertions(+), 300 deletions(-)
---
base-commit: 3e7f562e20ee87a25e104ef4fce557d39d62fa85
change-id: 20251124-pci-pwrctrl-rework-c91a6e16c2f6

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

