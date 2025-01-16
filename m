From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Subject: [PATCH v3 0/5] PCI/pwrctrl: Rework pwrctrl driver integration and
 add driver for PCI slot
Date: Thu, 16 Jan 2025 19:39:10 +0530
Message-Id: <20250116-pci-pwrctrl-slot-v3-0-827473c8fbf4@linaro.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAYTiWcC/32NQQ6CMBBFr0Jm7ZhpqUpccQ/DoqkDTEIomZKqI
 dzdygFcvpf89zdIrMIJ7tUGylmSxLlAfaogjH4eGOVZGCxZZ6whXILg8tKw6oRpiiuSDcThWpu
 b7aHMFuVe3kfy0RUeJa1RP8dDNj/7J5YNErJnd2HXNOSonWT2Gs9RB+j2ff8CtdsNkrEAAAA=
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, 
 Bartosz Golaszewski <bartosz.golaszewski@linaro.org>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 Lukas Wunner <lukas@wunner.de>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=3486;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=d32Y8ya8jL+ULXXbLr4QB/QI6XLp7Oo0AcqFQN1IDQw=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBniRML9/YkDU3ck+xoWOFje58AxDDajMHV6pMrD
 Jvob5t/DNaJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZ4kTCwAKCRBVnxHm/pHO
 9WFLB/43+VASUO9CgoplbEcO9UQM06la6OubEUHjeuwMQrmK8fJO1mrPtr7adDeHPkmWv1ri6Oj
 4Qk/34QC1sVj0PHLFiQttDyyhr2InEdT8sfUS9opkurbNMNnmTW9GoeFHfzc9MT+zLFywbi3i5l
 dw5VxBLsYTkHwg65Xj4hTW+j6XRXhwP7prXomRwvnSYHo2bDmTFZIDPl8w7e7rA0E9okCuYRRHA
 fZ2UODNyHnUECFpp5YePR/Ylxi8NdHsd5q9heHfHxNWKVjrt1A8aZZ22ghB2qP5qGDqRNVsqJ9b
 OVgmNt7S57PqB/cgPgQ4b9ril0eVCTwpmCRJ+x4Wkjp2iPyX
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series reworks the PCI pwrctrl integration (again) by moving the creation
and removal of pwrctrl devices to pci_scan_device() and pci_destroy_dev() APIs.
This is based on the suggestion provided by Lukas Wunner [1][2]. With this
change, it is now possible to create pwrctrl devices for PCI bridges as well.
This is required to control the power state of the PCI slots in a system. Since
the PCI slots are not explicitly defined in devicetree, the agreement is to
define the supplies for PCI slots in PCI bridge nodes itself [3].

Based on this, a pwrctrl driver to control the supplies of PCI slots are also
added in patch 4. With this driver, it is now possible to control the voltage
regulators powering the PCI slots defined in PCI bridge nodes as below:

```
pcie@0 {
	compatible "pciclass,0604"
	...

	vpcie12v-supply = <&vpcie12v_reg>;
	vpcie3v3-supply = <&vpcie3v3_reg>;
	vpcie3v3aux-supply = <&vpcie3v3aux_reg>;
};
```

To make use of this driver, the PCI bridge DT node should also have the
compatible "pciclass,0604". But adding this compatible triggers the following
checkpatch warning:

WARNING: DT compatible string vendor "pciclass" appears un-documented --
check ./Documentation/devicetree/bindings/vendor-prefixes.yaml

For fixing it, I added patch 3. But due to some reason, checkpatch is not
picking the 'pciclass' vendor prefix alone, and requires adding the full
compatible 'pciclass,0604' in the vendor-prefixes list. Since my perl skills are
not great, I'm leaving it in the hands of Rob to fix the checkpatch script.

[1] https://lore.kernel.org/linux-pci/Z0yLDBMAsh0yKWf2@wunner.de
[2] https://lore.kernel.org/linux-pci/Z0xAdQ2ozspEnV5g@wunner.de
[3] https://github.com/devicetree-org/dt-schema/issues/145

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
Changes in v3:
- Fixed the Kbuild bot issue with a regulator patch and submitted it separately
  along with one more regulator patch from this series. Both patches got merged
  and are in linux-next.
- Collected tags

Changes in v2:
- Added new patch to skip the device scan if pwrctrl device is found
- Added a new patch to fix the build issue
- Collected tags
- Link to v1: https://lore.kernel.org/r/20241210-pci-pwrctrl-slot-v1-0-eae45e488040@linaro.org

---
Manivannan Sadhasivam (5):
      PCI/pwrctrl: Move creation of pwrctrl devices to pci_scan_device()
      PCI/pwrctrl: Move pci_pwrctrl_unregister() to pci_destroy_dev()
      PCI/pwrctrl: Skip scanning for the device further if pwrctrl device is created
      dt-bindings: vendor-prefixes: Document the 'pciclass' prefix
      PCI/pwrctrl: Add pwrctrl driver for PCI Slots

 .../devicetree/bindings/vendor-prefixes.yaml       |  2 +-
 drivers/pci/bus.c                                  | 43 ----------
 drivers/pci/probe.c                                | 41 ++++++++++
 drivers/pci/pwrctrl/Kconfig                        | 11 +++
 drivers/pci/pwrctrl/Makefile                       |  3 +
 drivers/pci/pwrctrl/core.c                         |  2 +-
 drivers/pci/pwrctrl/slot.c                         | 93 ++++++++++++++++++++++
 drivers/pci/remove.c                               |  2 +-
 8 files changed, 151 insertions(+), 46 deletions(-)
---
base-commit: 40384c840ea1944d7c5a392e8975ed088ecf0b37
change-id: 20241210-pci-pwrctrl-slot-02c0ec63172f

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>

