From: George Moussalem <george.moussalem@outlook.com>
Subject: [PATCH 0/9] Flatten USB Controller Nodes on IPQ SoCs
Date: Tue, 25 Aug 2026 14:42:25 +0400
Message-Id: <20260825-ipq-flatten-usb-v1-0-5c1f3170bbe9@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDCyNT3cyCQt20nMSSktQ83dLiJN1k8xTzNEPTNGNLMzMloK6CotS0zAq
 widGxtbUA43iwHmEAAAA=
X-Change-ID: 20260825-ipq-flatten-usb-c7d7f15f3966
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Wesley Cheng <quic_wcheng@quicinc.com>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-usb@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 George Moussalem <george.moussalem@outlook.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787654580; l=2592;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=urk0+Er5ux8uZwdpteslcND66gV+vT/aS5AwzhbtppI=;
 b=5MUNm4XTglR3MnPNMCiGyPVCu3gYeBKDunI6KDhxtgjdz9hLea2nEfjxrD2ySHsP1OUN4R7Ys
 mG2EXgCETBSDKMsLmr3FvtbSXtrvuOfgtpfCruJrJ6JGerATzxrp+77
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add property to select UTMI as reference clock for the DWC3 core to
calculate the right values for the period and frame length adjustment.

Flatten usb controller node and update to using latest bindings and
flattened driver approach.

In addition, set the right UTMI clock rate and override any clock
rate inherited from the bootloader.

I've split these patches from a larger patch set to add USB3 support on
IPQ5018 and IPQ5332 SoCs where these patches are required to ensure new
functionality is added to the new flattened driver and binding model.

link: https://lore.kernel.org/all/20260812-ipq5018-usb3-v2-0-8f355d7ff0ef@outlook.com/

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
George Moussalem (9):
      dt-bindings: usb: qcom,snps-dwc3: Add ability to select UTMI as reference clock
      usb: dwc3: core: Allow glue layer to pass reference clock
      usb: dwc3: qcom: Add support for selecting UTMI as reference clock
      arm64: dts: qcom: ipq5018: Flatten usb controller node
      arm64: dts: qcom: ipq5332: Flatten usb controller node
      arm64: dts: qcom: ipq5424: Flatten usb controller nodes
      arm64: dts: qcom: ipq6018: Flatten usb controller nodes
      arm64: dts: qcom: ipq8074: Flatten usb controller nodes
      arm64: dts: qcom: ipq9574: Flatten usb controller node

 .../devicetree/bindings/usb/qcom,snps-dwc3.yaml    |   9 ++
 arch/arm64/boot/dts/qcom/ipq5018-rdp432-c2.dts     |   6 +-
 arch/arm64/boot/dts/qcom/ipq5018.dtsi              |  52 +++++-----
 arch/arm64/boot/dts/qcom/ipq5332-rdp468.dts        |   6 +-
 arch/arm64/boot/dts/qcom/ipq5332.dtsi              |  58 +++++------
 arch/arm64/boot/dts/qcom/ipq5424-rdp466.dts        |  12 +--
 arch/arm64/boot/dts/qcom/ipq5424.dtsi              |  89 ++++++++--------
 arch/arm64/boot/dts/qcom/ipq6018.dtsi              |  99 +++++++++---------
 arch/arm64/boot/dts/qcom/ipq8074.dtsi              | 112 ++++++++++-----------
 arch/arm64/boot/dts/qcom/ipq9574-rdp-common.dtsi   |   6 +-
 arch/arm64/boot/dts/qcom/ipq9574.dtsi              |  42 ++++----
 drivers/usb/dwc3/core.c                            |  12 +++
 drivers/usb/dwc3/core.h                            |   2 +
 drivers/usb/dwc3/dwc3-qcom.c                       |  14 +++
 drivers/usb/dwc3/glue.h                            |   2 +
 15 files changed, 257 insertions(+), 264 deletions(-)
---
base-commit: 4b18edbd8e70f7e6860d56370f13244896d0f95c
change-id: 20260825-ipq-flatten-usb-c7d7f15f3966

Best regards,
-- 
George Moussalem <george.moussalem@outlook.com>

