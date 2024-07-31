From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Subject: [PATCH v3 00/13] PCI: qcom: Enumerate endpoints based on Link up
 event in 'global_irq' interrupt
Date: Wed, 31 Jul 2024 16:20:03 +0530
Message-Id: <20240731-pci-qcom-hotplug-v3-0-a1426afdee3b@linaro.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANsWqmYC/33NTQ6CMBCG4auQrq3ptGDRlfcwLqA/MAnS2mKjI
 dzdwkoT4/L9knlmJtEENJGcipkEkzCiG3OIXUFU34ydoahzE854ySRU1Cukd+VutHeTHx4dbZU
 2oEDoI1iSz3wwFp8bebnm7jFOLry2DwnW9Q+WgDJaWSEPlVK1FM15wLEJbu9CR1Yt8U9B/hB4F
 iRowcq2BmnrL2FZljcDtfCn8wAAAA==
To: Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kw@linux.com>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-pci@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=openpgp-sha256; l=4411;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=EAZazIW0ecVgv+rOZil0RH9jYexC29jp0No/WKnprf0=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmqhbdAmqAJqOStLYtTZAKIpiye+giwhygrdEV2
 Wvf1wZlP8CJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZqoW3QAKCRBVnxHm/pHO
 9StlB/97VGY1SIflUmdYKUjob72nuIbOyt/JCdDZiZ1S2sVUD4nvm8+Ginjz251eBZHdVgnpt0W
 6Kq1t9SUC9isTYJSOaZ2cwtbR/P63oh+E/k7LtvJee7iLDAthJuEvlXaYK9k07v/mSx/pkmr3lt
 bvVQS2Pdu9RH6QNzZ2qXuaWM66bIZz9RsEE00scXZYkDGDAHQQSeaBitwh4cXybh4mc/+7e0dVn
 QsKPB/BZYhj2gRdZAOTyfAiGwe2595zG6YYtJrBkXStOKZWyldvxK3NY5AaQ8qTGipPTz258o2q
 qPMhwP5MeLd3AgVndzRQ280e4NKqoJx7or/sDTwxkql6JvKA
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series adds support to enumerate the PCIe endpoint devices using the Qcom
specific 'Link up' event in 'global' IRQ. Historically, Qcom PCIe RC controllers
lacked standard hotplug support. So when an endpoint is attached to the SoC,
users have to rescan the bus manually to enumerate the device. But this can be
avoided by rescanning the bus upon receiving 'Link up' event.

Qcom PCIe RC controllers are capable of generating the 'global' SPI interrupt
to the host CPUs. The device driver can use this interrupt to identify events
such as PCIe link specific events, safety events etc...

One such event is the PCIe Link up event generated when an endpoint is detected
on the bus and the Link is 'up'. This event can be used to enumerate the
endpoint devices.

So add support for capturing the PCIe Link up event using the 'global' interrupt
in the driver. Once the Link up event is received, the bus underneath the host
bridge is scanned to enumerate PCIe endpoint devices.

This series also has some cleanups to the Qcom PCIe EP controller driver for
interrupt handling.

NOTE: During v2 review, there was a discussion about removing the devices when
'Link Down' event is received. But this needs some more investigation, so I'm
planning to add it later.

Testing
=======

This series is tested on Qcom SM8450 based development board that has 2 SoCs
connected over PCIe.

Merging Strategy
================

I'm expecting the binding and PCI driver changes to go through PCI tree and DTS
patches through Qcom tree.

- Mani

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
Changes in v3:
- Removed the usage of 'simulating hotplug' and just used 'Link up' as we are
  not fully emulating the hotplug support
- Fixed the build issue wtih CONFIG_PCI_DOMAINS_GENERIC
- Moved the 'global' IRQ entry to last in the binding and also mentioned the ABI
  break and its necessity in patch description.
- Collected tags
- Rebased on top of v6.11-rc1
- Link to v2: https://lore.kernel.org/r/20240717-pci-qcom-hotplug-v2-0-71d304b817f8@linaro.org

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
      PCI: qcom: Enumerate endpoints based on Link up event in 'global_irq' interrupt
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
 drivers/pci/endpoint/pci-epc-core.c                | 14 ++++++
 include/linux/pci-epc.h                            |  2 +
 12 files changed, 120 insertions(+), 17 deletions(-)
---
base-commit: 8400291e289ee6b2bf9779ff1c83a291501f017b
change-id: 20240715-pci-qcom-hotplug-bcde1c13d91f

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>

