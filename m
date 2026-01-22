From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH v6 0/4] PCI: Add initial support for handling PCIe M.2
 connectors in devicetree
Date: Thu, 22 Jan 2026 22:46:50 +0530
Message-Id: <20260122-pci-m2-v6-0-575da9f97239@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIJbcmkC/3XPy2rDMBAF0F8JWkdBM3oNWfU/Shd6JoI4Tq3Wt
 AT/e+WA4yzqzcAddO6gO6tpKKmy4+7OhjSWWvprC2a/Y+HsrqfES2yZoUANICS/hcI75NZIaSR
 4k51j7fFtSLn8PIreP1o+l/rVD7+P3hHm7VKhl4oRuOCkvM6QIelEb32th89vdwl91x3aYHPTi
 K+anhqbTuSDitZnhXFDyxeN623ZdNBIQqFLTtkNrVaNuN5WTWtDigx5EXXe0HrRRoCwT63nf4O
 VkZxFo+AfPU3TH9Yw9YubAQAA
X-Change-ID: 20251103-pci-m2-7633631b6faa
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bartosz Golaszewski <brgl@bgdev.pl>, 
 Damien Le Moal <dlemoal@kernel.org>, Niklas Cassel <cassel@kernel.org>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-pci@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Stephan Gerhold <stephan.gerhold@linaro.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 linux-pm@vger.kernel.org, linux-ide@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Frank Li <Frank.Li@nxp.com>, 
 Bartosz Golaszewski <bartosz.golaszewski@linaro.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=4535;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=ogm5Oj9lUDa4ikOcwS4o+wR+qaXVbFoVraP2UR9Q/hg=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpcluDzIip8VQqQDMLX+hmGJn1U99vEBi73FrT1
 s+jKEyp2kOJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaXJbgwAKCRBVnxHm/pHO
 9SduCACgTvLlnPBLDoqTA4XToyaqzD1GcXUHnoCoRX9hKhaL4+xdSMHubpHUXpyvLTAeLHdbVJ1
 1NsUzBVaXax0BWNpyxIAvXCoVynTAaNKm6LdX6uf+btVSDcvfeTGS2kPKpwu5GR+kmPFbgqcg/c
 jzHnHaxO1t0f4k5TMtjkTKNLYU2P5Di4uod76amT4YWZSZ9FOvxsMQoXmZFEjAi7DvNa64PDyUT
 cjJajhOdEBDgJ9aiFvH58zPeqa7ppA4NLf4OYJWNCOmZFIqsBxscU8mZIopJTMciKYu6I/k38Vr
 5Eh/aSuL8EuNy1fk9bUzyQRi+1vXgyCJxzxM1M96ElB5rVc6
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series is an initial attempt to support the PCIe M.2 connectors in the
kernel and devicetree binding. The PCIe M.2 connectors as defined in the PCI
Express M.2 Specification are widely used in Notebooks/Tablet form factors (even
in PCs). On the ACPI platforms, power to these connectors are mostly handled by
the firmware/BIOS and the kernel never bothered to directly power manage them as
like other PCIe connectors. But on the devicetree platforms, the kernel needs to
power manage these connectors with the help of the devicetree description. But
so far, there is no proper representation of the M.2 connectors in devicetree
binding. This forced the developers to fake the M.2 connectors as PMU nodes [1]
and fixed regulators in devicetree.

So to properly support the M.2 connectors in devicetree platforms, this series
introduces the devicetree binding for Mechanical Key M connector as an example
and also the corresponding pwrseq driver and PCI changes in kernel to driver the
connector.

The Mechanical Key M connector is used to connect SSDs to the host machine over
PCIe/SATA interfaces. Due to the hardware constraints, this series only adds
support for driving the PCIe interface of the connector in the kernel.

Also, the optional interfaces supported by the Key M connectors are not
supported in the driver and left for the future enhancements.

Testing
=======

This series, together with the devicetree changes [2] [3] were tested on the
Qualcomm X1e based Lenovo Thinkpad T14s Laptop which has the NVMe SSD connected
over PCIe.

[1] https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/arch/arm64/boot/dts/qcom/x1e80100-qcp.dts?h=v6.18-rc4&id=d09ab685a8f51ba412d37305ea62628a01cbea57
[2] https://github.com/Mani-Sadhasivam/linux/commit/40120d02219f34d2040ffa6328f0d406b1e4c04d
[3] https://github.com/Mani-Sadhasivam/linux/commit/ff6c3075836cc794a3700b0ec6a4a9eb21d14c6f

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
Changes in v6:
- Used 'ports' to describe interfaces instead of endpoints in the binding
- Added GPIOs and USB to the example in binding
- Incorporated minor comments in the pwrseq driver
- Dropped the ata binding patch as it got applied
- Link to v5: https://lore.kernel.org/r/20260107-pci-m2-v5-0-8173d8a72641@oss.qualcomm.com

Changes in v5:
- used of_node_get() and devm_action to free regulators
- Link to v4: https://lore.kernel.org/r/20251228-pci-m2-v4-0-5684868b0d5f@oss.qualcomm.com

Changes in v4:
- Added graph property to SATA in this series and PCI to dtschema:
  https://github.com/devicetree-org/dt-schema/pull/180
- Used 'i2c-parent' instead of SMBus port
- Reworded the -gpios property description
- Rebased on top of v6.19-rc1
- Link to v3: https://lore.kernel.org/r/20251125-pci-m2-v3-0-c528042aea47@oss.qualcomm.com

Changes in v3:
- Changed the VIO supply name as per dtschema
- Added explicit endpoint properties to port 0 node for host I/F
- Used scope based cleanup for OF node in pwrseq driver
- Collected review tags
- Link to v2: https://lore.kernel.org/r/20251108-pci-m2-v2-0-e8bc4d7bf42d@oss.qualcomm.com

Changes in v2:
- Incorporated comments from Bartosz and Frank for pwrseq and dt-binding
  patches, especially adding the pwrseq match() code.
- Link to v1: https://lore.kernel.org/r/20251105-pci-m2-v1-0-84b5f1f1e5e8@oss.qualcomm.com

---
Manivannan Sadhasivam (4):
      dt-bindings: connector: Add PCIe M.2 Mechanical Key M connector
      PCI/pwrctrl: Add support for handling PCIe M.2 connectors
      PCI/pwrctrl: Create pwrctrl device if the graph port is found
      power: sequencing: Add the Power Sequencing driver for the PCIe M.2 connectors

 .../bindings/connector/pcie-m2-m-connector.yaml    | 145 ++++++++++++++++++
 MAINTAINERS                                        |   7 +
 drivers/pci/probe.c                                |   3 +-
 drivers/pci/pwrctrl/Kconfig                        |   1 +
 drivers/pci/pwrctrl/slot.c                         |  35 ++++-
 drivers/power/sequencing/Kconfig                   |   8 +
 drivers/power/sequencing/Makefile                  |   1 +
 drivers/power/sequencing/pwrseq-pcie-m2.c          | 168 +++++++++++++++++++++
 8 files changed, 362 insertions(+), 6 deletions(-)
---
base-commit: 8f0b4cce4481fb22653697cced8d0d04027cb1e8
change-id: 20251103-pci-m2-7633631b6faa

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

