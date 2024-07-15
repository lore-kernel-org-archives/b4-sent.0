From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Subject: [PATCH 00/14] PCI: qcom: Simulate PCIe hotplug using 'global'
 interrupt
Date: Mon, 15 Jul 2024 23:03:42 +0530
Message-Id: <20240715-pci-qcom-hotplug-v1-0-5f3765cc873a@linaro.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHZdlWYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDc0NT3YLkTN3C5Pxc3Yz8koKc0nTdpOSUVMNkQ+MUS8M0JaC2gqLUtMw
 KsJHRsbW1AGKo7+JiAAAA
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3353;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=XTJGJcJtJ9q3xS6FcYJEn2b9I/JOzQleE68JYB3eyNE=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmlV13maAX8I4o+y3OFuBOPbkCeBTBFrFWJcdmH
 pCZf5cw49uJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZpVddwAKCRBVnxHm/pHO
 9VBBB/9VPNho4Ta793DhxS1UooDi6ZUjbse7lJmJRXYOwNijJgHBEsmuQcIueZCya4U//MTX7T4
 5k61CKGFDsqrasalpiIpBHR5BtwBJwFAbGnaWPtgmQbKTjCs99gxvrY50/61PqzpbSmHAjPcorh
 Y0PRyyq2YvavoV9eB2jFUAnUEoBhrfp4KAVud019B0myLYyt3ual7lzxk203gI/6kemiJ89lbTp
 6haTOpwL4irKh+dfz1AGWPBaEykSZtUmEwFF1jr2q170IBBsjQyq8qb42B8BaKmcWGpJEwKkaNU
 INjP4BnirSOH+i0gxScZcoaiecnRSPdQ9lnoY0NI+k0C9d6J
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
Manivannan Sadhasivam (14):
      PCI: qcom-ep: Drop the redundant masking of global IRQ events
      PCI: qcom-ep: Reword the error message for receiving unknown global IRQ event
      dt-bindings: PCI: pci-ep: Update Maintainers
      dt-bindings: PCI: pci-ep: Document 'linux,pci-domain' property
      dt-bindings: PCI: qcom-ep: Document "linux,pci-domain" property
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
 drivers/pci/controller/dwc/pcie-qcom.c             | 55 ++++++++++++++++++++++
 drivers/pci/endpoint/pci-epc-core.c                |  1 +
 include/linux/pci-epc.h                            |  2 +
 12 files changed, 108 insertions(+), 16 deletions(-)
---
base-commit: 91e3b24eb7d297d9d99030800ed96944b8652eaf
change-id: 20240715-pci-qcom-hotplug-bcde1c13d91f

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>

