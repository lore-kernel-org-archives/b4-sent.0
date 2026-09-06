From: George Moussalem <george.moussalem@outlook.com>
Subject: [PATCH v2 00/10] Flatten USB Controller Nodes on IPQ SoCs
Date: Sun, 06 Sep 2026 07:52:39 +0400
Message-Id: <20260906-ipq-flatten-usb-v2-0-dab83120b10a@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNQQ6CMBBFr0Jm7Zi2BBBX3MOwgDKViUixLY2Gc
 Hcre5fvJf/9DTw5Jg/XbANHkT3bOYE6ZaDHbr4T8pAYlFCluKgCeXmhmboQaMbV96iroTKyMHl
 dlpBWiyPD76N4axOP7IN1n+Mgyp/934oSBRZamlxWou+pbuwaJmsfZ22f0O77/gVl3Di3sAAAA
 A==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788666763; l=3251;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=7Yq5ub7q0MZf9nnKm7SAIuTh3wlNo4yVu/BiB/oqTiI=;
 b=hPAyGLZNl5MlOY4uQBGhMsqP6taHHPd2AINyGncH0wyppAMhPXGwBtUpputzCuRmtnCQ54mcZ
 LPHsGQPXTNLBVR+5ntWRV2qN41gmG04VjhIPan3PsVTg3y28dfDYEPC
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add ability to pass the UTMI clock rate to the DWC3 core to calculate
the right values for the period and frame length adjustment. This is
required for USB controllers on chipsets where the computed values for
the period and frame length adjustment differ from hardware defaults
based on the UTMI clock rate.

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
Changes in v2:
- Dropped the "qcom,select-utmi-as-ref-clk" property from the binding
  and DTS nodes since it is no longer needed. If the UTMI clock is
  available, the glue layer will pass its clock rate to the core
  unconditionally.
- Added separate patches to move the DR mode to the relevant board DTS
  files as per Konrad's request.
- Picked up RB tags
- Link to v1: https://lore.kernel.org/r/20260825-ipq-flatten-usb-v1-0-5c1f3170bbe9@outlook.com

---
George Moussalem (10):
      usb: dwc3: core: Allow glue layer to pass reference clock rate
      usb: dwc3: qcom: Add support for selecting UTMI as reference clock
      arm64: dts: qcom: ipq5018: Flatten usb controller node
      arm64: dts: qcom: ipq5332: Flatten usb controller node
      arm64: dts: qcom: ipq5424: Flatten usb controller nodes
      arm64: dts: qcom: ipq6018: move DR mode to board DTS
      arm64: dts: qcom: ipq6018: Flatten usb controller nodes
      arm64: dts: qcom: ipq8074: move DR mode to board DTS
      arm64: dts: qcom: ipq8074: Flatten usb controller nodes
      arm64: dts: qcom: ipq9574: Flatten usb controller node

 arch/arm64/boot/dts/qcom/ipq5018-rdp432-c2.dts   |   6 +-
 arch/arm64/boot/dts/qcom/ipq5018.dtsi            |  51 +++++------
 arch/arm64/boot/dts/qcom/ipq5332-rdp468.dts      |   6 +-
 arch/arm64/boot/dts/qcom/ipq5332.dtsi            |  57 ++++++------
 arch/arm64/boot/dts/qcom/ipq5424-rdp466.dts      |  12 +--
 arch/arm64/boot/dts/qcom/ipq5424.dtsi            |  86 ++++++++----------
 arch/arm64/boot/dts/qcom/ipq6018.dtsi            |  95 +++++++++-----------
 arch/arm64/boot/dts/qcom/ipq8074-hk01.dts        |   4 +
 arch/arm64/boot/dts/qcom/ipq8074.dtsi            | 110 +++++++++++------------
 arch/arm64/boot/dts/qcom/ipq9574-rdp-common.dtsi |   6 +-
 arch/arm64/boot/dts/qcom/ipq9574.dtsi            |  40 ++++-----
 drivers/usb/dwc3/core.c                          |   6 ++
 drivers/usb/dwc3/core.h                          |   2 +
 drivers/usb/dwc3/dwc3-qcom.c                     |   9 ++
 drivers/usb/dwc3/glue.h                          |   4 +
 15 files changed, 230 insertions(+), 264 deletions(-)
---
base-commit: 32b6ef9a5d0eca44f9cd91f52f4faa89f145a0de
change-id: 20260825-ipq-flatten-usb-c7d7f15f3966

Best regards,
-- 
George Moussalem <george.moussalem@outlook.com>

