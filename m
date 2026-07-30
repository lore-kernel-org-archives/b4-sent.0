From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH 00/22] arm64: dts: qcom: Fix the PCIe iommu-map entries
Date: Thu, 30 Jul 2026 13:55:41 +0200
Message-Id: <20260730-iommu-map-fix-v1-0-83405d37ba41@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAL07a2oC/yXM0QpAQBCF4VfRXJtaK8SryMUag1GLdpGSd7e4/
 E6d/wLPTthDFV3g+BAvyxyQxBHQaOaBUbpg0ErnqkgVymLtjtas2MuJRidMZU+KygzCZ3Uc5q9
 XN7/93k5M2xuB+34ANdJEQHEAAAA=
X-Change-ID: 20260730-iommu-map-fix-a21ec9fc0c95
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Manivannan Sadhasivam <mani@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Bjorn Andersson <bjorn.andersson@oss.qualcomm.com>, 
 Krzysztof Kozlowski <krzk@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3950;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=Jv+Y+B7vW5zw3dtOTvZ7DUoUVDoPl9faWBEpmq7vOFg=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqazvU6wfi+7nPSDv4gG0rmYtE7MjBcxIEFvjXY
 N/Pf0xQ1KuJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCams71AAKCRBVnxHm/pHO
 9TSBB/0QSpb1PekwaQMaBy/Alfc+h2gKqXTo2opNHcnG8tv9qRZDEcEUtSqqExYdproF92ggfgY
 Y49+flXXBoYqgjBhS//ZiHeaieGaMjSbqD0dJHmBNAULDd6vwQ1ZYh2biMJllMyx3gmIfe9uqWP
 qgmmzVvS8EC4hpV0wTfTWXQSV6a/7KutwQohW4AaRg77DoCZ0M/It3pqfzEIWxpDL6MgoxDg0jh
 qlO0drKdWa38tPtxbSXul7IoKr8x7o9MckeKakp0FFB4sOxCeg4jPBAqSySVG/0+xqfbG9GP2iX
 KqilFfPIs84HAhuBIcX0oSbLTKy5PQTUiAvD6kKxZyZeeVrD
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Several Qualcomm SoCs declare their IOMMU providers like apps_smmu and
pcie_smmu, with '#iommu-cells = <2>', where the two cells are the SID
and the SID mask. But the PCIe iommu-map entries on these SoCs specify
only one output cell for the SID and omit the mask. This went unnoticed
until the OF core started warning with commit
ccb2fd725d41 ("of: Respect #{iommu,msi}-cells in maps"):

  iommu-map has 1-cell entries targeting 2-cell #iommu-cells, treating as 1-cell output

So this series fixes the iommu-map entries across the affected SoC, SoM, board
and overlay files to match the provider's '#iommu-cells' property.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
Manivannan Sadhasivam (22):
      arm64: dts: qcom: kaanapali: Fix the PCIe iommu-map entries
      arm64: dts: qcom: kodiak: Fix the PCIe iommu-map entries
      arm64: dts: qcom: sar2130p: Fix the PCIe iommu-map entries
      arm64: dts: qcom: sc8180x: Fix the PCIe iommu-map entries
      arm64: dts: qcom: sdm845: Fix the PCIe iommu-map entries
      arm64: dts: qcom: sm8150: Fix the PCIe iommu-map entries
      arm64: dts: qcom: sm8250: Fix the PCIe iommu-map entries
      arm64: dts: qcom: sm8350: Fix the PCIe iommu-map entries
      arm64: dts: qcom: sm8450: Fix the PCIe iommu-map entries
      arm64: dts: qcom: sm8550: Fix the PCIe iommu-map entries
      arm64: dts: qcom: sm8650: Fix the PCIe iommu-map entries
      arm64: dts: qcom: sm8750: Fix the PCIe iommu-map entries
      arm64: dts: qcom: talos: Fix the PCIe iommu-map entries
      arm64: dts: qcom: lemans: Fix the PCIe iommu-map entries
      arm64: dts: qcom: monaco: Fix the PCIe iommu-map entries
      arm64: dts: qcom: monaco-monza-som: Fix the PCIe iommu-map entries
      arm64: dts: qcom: monaco-evk-ifp-mezzanine: Fix the PCIe iommu-map entries
      arm64: dts: qcom: lemans-evk-ifp-mezzanine: Fix the PCIe iommu-map entries
      arm64: dts: qcom: qcs6490-radxa-dragon-q6a: Fix the PCIe iommu-map entries
      arm64: dts: qcom: qcs6490-thundercomm-minipc-g1iot: Fix the PCIe iommu-map entries
      arm64: dts: qcom: qcs6490-rb3gen2: Fix the PCIe iommu-map entries
      arm64: dts: qcom: qcs6490-rb3gen2-industrial-mezzanine: Fix the PCIe iommu-map entries

 arch/arm64/boot/dts/qcom/kaanapali.dtsi            |  4 +-
 arch/arm64/boot/dts/qcom/kodiak.dtsi               |  8 +--
 .../boot/dts/qcom/lemans-evk-ifp-mezzanine.dtso    | 18 +++---
 arch/arm64/boot/dts/qcom/lemans.dtsi               |  8 +--
 .../boot/dts/qcom/monaco-evk-ifp-mezzanine.dtso    | 18 +++---
 arch/arm64/boot/dts/qcom/monaco-monza-som.dtsi     | 16 +++---
 arch/arm64/boot/dts/qcom/monaco.dtsi               |  8 +--
 .../boot/dts/qcom/qcs6490-radxa-dragon-q6a.dts     | 18 +++---
 .../qcom/qcs6490-rb3gen2-industrial-mezzanine.dtso | 50 ++++++++---------
 arch/arm64/boot/dts/qcom/qcs6490-rb3gen2.dts       | 18 +++---
 .../dts/qcom/qcs6490-thundercomm-minipc-g1iot.dts  | 18 +++---
 arch/arm64/boot/dts/qcom/sar2130p.dtsi             |  8 +--
 arch/arm64/boot/dts/qcom/sc8180x.dtsi              | 16 +++---
 arch/arm64/boot/dts/qcom/sdm845.dtsi               | 64 +++++++++++-----------
 arch/arm64/boot/dts/qcom/sm8150.dtsi               |  8 +--
 arch/arm64/boot/dts/qcom/sm8250.dtsi               | 12 ++--
 arch/arm64/boot/dts/qcom/sm8350.dtsi               |  8 +--
 arch/arm64/boot/dts/qcom/sm8450.dtsi               |  8 +--
 arch/arm64/boot/dts/qcom/sm8550.dtsi               |  8 +--
 arch/arm64/boot/dts/qcom/sm8650.dtsi               |  8 +--
 arch/arm64/boot/dts/qcom/sm8750.dtsi               |  4 +-
 arch/arm64/boot/dts/qcom/talos.dtsi                |  4 +-
 22 files changed, 166 insertions(+), 166 deletions(-)
---
base-commit: dc59e4fea9d83f03bad6bddf3fa2e52491777482
change-id: 20260730-iommu-map-fix-a21ec9fc0c95

Best regards,
--  
மணிவண்ணன் சதாசிவம்

