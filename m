From: George Moussalem <george.moussalem@outlook.com>
Subject: [PATCH v5 0/6] Enable IPQ5018 PCI support
Date: Fri, 21 Mar 2025 13:09:49 +0400
Message-Id: <20250321-ipq5018-pcie-v5-0-aae2caa1f418@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAN0s3WcC/1WMuw6CMABFf4V0tk0fNBQnQXQzMToaBqRFGoXWF
 omG8O9WNsdzc8+ZgFdOKw/W0QScGrXXpg/AVxGo26q/KahlYEAx5ZhRArV9ckwEtLVWkMg4rq4
 NVrThICjWqUa/l9ylDNxqPxj3Weoj+a2gOCfHE0kPuRCC7SlnIsuSAsfJjrAtwTRPi4LSzd8N9
 VVnnSQpss5IZF7Dw5g7qk0Hynmev42qZl7FAAAA
To: Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Nitheesh Sekar <quic_nsekar@quicinc.com>, 
 Varadarajan Narayanan <quic_varada@quicinc.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kw@linux.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 Bjorn Helgaas <bhelgaas@google.com>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-pci@vger.kernel.org, George Moussalem <george.moussalem@outlook.com>, 
 20250317100029.881286-2-quic_varada@quicinc.com, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 Sricharan Ramabadhran <quic_srichara@quicinc.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742548192; l=5246;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=SQrVa5hcvNGbT7b8PFbqplfHsajPW5GpR0t3KiUbwo8=;
 b=cRcavix89+BN+5gtWvU3+jeOnLSD0aAOOOX8Lkq/7qD9/H5WqUxx7ptJUukvrkeqaFOL0Adpq
 QboYMBEdN79AFz3m67U/uwyriFL5ccRI+nHIJMP+oBKW0Uuv5wiu0Wk
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds the relevant phy and controller
DT configurations for enabling PCI gen2 support
on IPQ5018. IPQ5018 has two phys and two controllers, 
one dual-lane and one single-lane.

Last patch series (v3) submitted dates back to August 30, 2024.
As I've worked to add IPQ5018 platform support in OpenWrt, I'm
continuing the efforts to add Linux kernel support.

To: Vinod Koul <vkoul@kernel.org>
To: Kishon Vijay Abraham I <kishon@kernel.org>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Nitheesh Sekar <quic_nsekar@quicinc.com>
To: Varadarajan Narayanan <quic_varada@quicinc.com>
To: Bjorn Helgaas <bhelgaas@google.com>
To: Lorenzo Pieralisi <lpieralisi@kernel.org>
To: Krzysztof Wilczyński <kw@linux.com>
To: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
To: Bjorn Andersson <andersson@kernel.org>
To: Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org
Cc: linux-phy@lists.infradead.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: linux-pci@vger.kernel.org
Signed-off-by: George Moussalem <george.moussalem@outlook.com>

v5:
  *) Re-ordered reg and reg-names in dt-bindings and dts to align with
     other IPQ SoCs
  *) Corrected nr of interrupts in dt-bindings: phy: qcom: Add IPQ5018 SoC
  *) Corrected ranges property of pcie controller nodes
  *) Removed newlines between cells properties in pcie phy nodes
  *) Modified dt bindings to add descriptions and separate conditions for
     ipq5018 and ipq5332 as they have different nr of clocks and resets
     As such, also removed Krzysztof's RB tag for validation
  *) Ran dtbs_check and fixed:
     interrupt-map property in pcie nodes:
     /soc@0/pcie@80000000:interrupt-map: Cell 13 is not a phandle(0)
     /soc@0/pcie@a0000000:interrupt-map: Cell 13 is not a phandle(0)
  *) Added missing gpio header file to ipq5018-rdp432-c2.dts
  *) Added MHI register requirement to bindings and to PCIe nodes as per:
     Depends-on: <20250317100029.881286-2-quic_varada@quicinc.com>

v4:
  *) removed dependency as the following have been applied:
	dt-bindings: phy: qcom,uniphy-pcie: Document PCIe uniphy
	phy: qcom: Introduce PCIe UNIPHY 28LP driver
	dt-bindings: PCI: qcom: Document the IPQ5332 PCIe controller
     Link: https://lore.kernel.org/all/20250313080600.1719505-1-quic_varada@quicinc.com/
  *) added Mani's RB tag to: PCI: qcom: Add support for IPQ5018
  *) Removed power-domains property requirement in dt-bindings for IPQ5018
     and removed Krzysztof's RB tag from:
     dt-bindings: PCI: qcom: Add IPQ5018 SoC
  *) fixed author chain and retained Sricharan Ramabadhran in SoB tags and
     kept Nitheesh Sekar as the original author
  *) Removed comments as per Konrad's comment in:
     arm64: dts: qcom: ipq5018: Add PCIe related nodes
  *) Link to v3 submitted by Sricharan Ramabadhran:
     Link: https://lore.kernel.org/all/20240830081132.4016860-1-quic_srichara@quicinc.com/
  *) Link to v3, incorrectly versioned:
     Link: https://lore.kernel.org/all/DS7PR19MB8883BC190797BECAA78EC50F9DCB2@DS7PR19MB8883.namprd19.prod.outlook.com/

v3 (incorrectly versioned):
  *) Depends on
     Link: https://patchwork.kernel.org/project/linux-arm-msm/cover/20250220094251.230936-1-quic_varada@quicinc.com/
  *) Added 8 MSI SPI and 1 global interrupts (Thanks Mani for confirming)
  *) Added hw revision (internal/synopsys) and nr of lanes in patch 4
     commit msg
  *) Sorted reg addresses and moved PCIe nodes accordingly
  *) Moved to GIC based interrupts
  *) Added rootport node in controller nodes
  *) Tested on Linksys devices (MX5500/SPNMX56)
  *) Link to v2:
     Link: https://lore.kernel.org/all/20240827045757.1101194-1-quic_srichara@quicinc.com/

v3:
  Added Reviewed-by tag for patch#1.
  Fixed dev_err_probe usage in patch#3.
  Added pinctrl/wak pins for pcie1 in patch#6.

v2:
  Fixed all review comments from Krzysztof, Robert Marko,
  Dmitry Baryshkov, Manivannan Sadhasivam, Konrad Dybcio.
  Updated the respective patches for their changes.

v1:

Link: https://lore.kernel.org/lkml/32389b66-48f3-8ee8-e2f1-1613feed3cc7@gmail.com/T/
---
Nitheesh Sekar (6):
      dt-bindings: phy: qcom: uniphy-pcie: Add ipq5018 compatible
      phy: qualcomm: qcom-uniphy-pcie 28LP add support for IPQ5018
      dt-bindings: PCI: qcom: Add IPQ5018 SoC
      PCI: qcom: Add support for IPQ5018
      arm64: dts: qcom: ipq5018: Add PCIe related nodes
      arm64: dts: qcom: ipq5018: Enable PCIe

 .../devicetree/bindings/pci/qcom,pcie.yaml         |  50 +++++
 .../bindings/phy/qcom,ipq5332-uniphy-pcie-phy.yaml |  57 ++++-
 arch/arm64/boot/dts/qcom/ipq5018-rdp432-c2.dts     |  40 ++++
 arch/arm64/boot/dts/qcom/ipq5018.dtsi              | 234 ++++++++++++++++++++-
 drivers/pci/controller/dwc/pcie-qcom.c             |   1 +
 drivers/phy/qualcomm/phy-qcom-uniphy-pcie-28lp.c   |  45 ++++
 6 files changed, 417 insertions(+), 10 deletions(-)
---
base-commit: 5744a64fddfc33629f3bcc9a06a646f7443077a7
change-id: 20250321-ipq5018-pcie-1d44abf0e2f5

Best regards,
-- 
George Moussalem <george.moussalem@outlook.com>

