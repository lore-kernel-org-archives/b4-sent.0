From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Subject: [PATCH v2 00/13] PCI: qcom: Simulate PCIe hotplug using 'global'
 interrupt
Date: Wed, 17 Jul 2024 22:33:05 +0530
Message-Id: <20240717-pci-qcom-hotplug-v2-0-71d304b817f8@linaro.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEn5l2YC/32NQQ6CMBBFr0Jm7RjaWlFX3sOwqNNSJsEWWyQaw
 t2tHMDle8l/f4HsErsMl2qB5GbOHEMBuauAehO8Q7aFQdbyUDdC40iMT4oP7OM0Di+Pd7JOkFD
 2LDooszG5jt9b8tYW7jlPMX22h1n87J/YLLBG3anmqIlOjTLXgYNJcR+Th3Zd1y/tpdaKsQAAA
 A==
To: Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kw@linux.com>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>
Cc: linux-pci@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=openpgp-sha256; l=3577;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=Gl1Lq4eAwwgbdu9A+/5F0Vm/X1cX0EaWkeT2ZW+e1L4=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBml/lMWZqx1/Pu5k8yOvC0cHLJvHvnFyhXkKdAr
 CC/3RTnQY6JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZpf5TAAKCRBVnxHm/pHO
 9aBjB/oDBwWK+E0JQrCLxm+aj51YYDYhHG2it2pHg3tdqnaQrrAWumg8aclJ2rg1sXfJ1t9SCL8
 eqcpg+C6apu+yd/8uS8TwyJ8e3KnC0/EJs23u4BKYHOxm451J/rY2LLmHxCU63Ey9fKuqHzvoh4
 IuoA1FIENtU1IkgLpq2HBsfVIiXSB6mSmcTY59vczYa1GTTZ6MNfSmn3+q9DX1wSj3pnmdvvB2n
 Ud60Upb7Jnai9DwtOEZOFqRNbasvIbcml+NjPSVUNuoX6aMCnm9str2Ur9ETFG6QxY/EK0gWXyq
 4TLhnqxOXNOI20qM46EzD0QwngLpZG6HEpyF68YzGhGoKaRS
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series adds support to simulate PCIe hotplug using the Qcom specific
'global' IRQ. Historically, Qcom PCIe RC controllers lack standard hotplug
support. So when an endpoint is attached to the SoC, users have to rescan the
bus manually to enumerate the device. But this can be avoided by simulating the
PCIe hotplug using Qcom specific way.

Qcom PCIe RC controllers are capable of generating the 'global' SPI interrupt
to the host CPUs. The device driver can use this event to identify events such
as PCIe link specific events, safety events etc...

One such event is the PCIe Link up event generated when an endpoint is detected
on the bus and the Link is 'up'. This event can be used to simulate the PCIe
hotplug in the Qcom SoCs.

So add support for capturing the PCIe Link up event using the 'global' interrupt
in the driver. Once the Link up event is received, the bus underneath the host
bridge is scanned to enumerate PCIe endpoint devices, thus simulating hotplug.

This series also has some cleanups to the Qcom PCIe EP controller driver for
interrupt handling.

Testing
=======

This series is tested on Qcom SM8450 based development board that has 2 SoCs
connected over PCIe.

- Mani

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
Changes in v2:
- Added CONFIG_PCI_DOMAINS_GENERIC guard for domain_nr
- Switched to dev_WARN_ONCE() for unhandled interrupts
- Squashed the 'linux,pci-domain' bindings patches into one
- Link to v1: https://lore.kernel.org/r/20240715-pci-qcom-hotplug-v1-0-5f3765cc873a@linaro.org

---
Manivannan Sadhasivam (13):
      PCI: qcom-ep: Drop the redundant masking of global IRQ events
      PCI: qcom-ep: Reword the error message for receiving unknown global IRQ event
      dt-bindings: PCI: pci-ep: Update Maintainers
      dt-bindings: PCI: pci-ep: Document 'linux,pci-domain' property
      PCI: endpoint: Assign PCI domain number for endpoint controllers
      PCI: qcom-ep: Modify 'global_irq' and 'perst_irq' IRQ device names
      ARM: dts: qcom: sdx55: Add 'linux,pci-domain' to PCIe EP controller node
      ARM: dts: qcom: sdx65: Add 'linux,pci-domain' to PCIe EP controller node
      arm64: dts: qcom: sa8775p: Add 'linux,pci-domain' to PCIe EP controller nodes
      dt-bindings: PCI: qcom: Add 'global' interrupt
      dt-bindings: PCI: qcom,pcie-sm8450: Add 'global' interrupt
      PCI: qcom: Simulate PCIe hotplug using 'global' interrupt
      arm64: dts: qcom: sm8450: Add 'global' interrupt to the PCIe RC node

 Documentation/devicetree/bindings/pci/pci-ep.yaml  | 14 +++++-
 .../devicetree/bindings/pci/qcom,pcie-common.yaml  |  4 +-
 .../devicetree/bindings/pci/qcom,pcie-ep.yaml      |  1 +
 .../devicetree/bindings/pci/qcom,pcie-sm8450.yaml  | 10 ++--
 arch/arm/boot/dts/qcom/qcom-sdx55.dtsi             |  1 +
 arch/arm/boot/dts/qcom/qcom-sdx65.dtsi             |  1 +
 arch/arm64/boot/dts/qcom/sa8775p.dtsi              |  2 +
 arch/arm64/boot/dts/qcom/sm8450.dtsi               | 12 +++--
 drivers/pci/controller/dwc/pcie-qcom-ep.c          | 21 +++++++--
 drivers/pci/controller/dwc/pcie-qcom.c             | 55 +++++++++++++++++++++-
 drivers/pci/endpoint/pci-epc-core.c                | 10 ++++
 include/linux/pci-epc.h                            |  2 +
 12 files changed, 116 insertions(+), 17 deletions(-)
---
base-commit: 91e3b24eb7d297d9d99030800ed96944b8652eaf
change-id: 20240715-pci-qcom-hotplug-bcde1c13d91f

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>

