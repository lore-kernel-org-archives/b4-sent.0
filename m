From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v6 0/6] arm64: dts: qcom: Support AYN QCS8550 Devices
Date: Thu, 30 Apr 2026 11:03:03 -0500
Message-Id: <20260430-ayn-qcs8550-v6-0-06a7e7b54aaa@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33OQW7DIBCF4atErEs1DAbjrnqPqosBDwlSYyeQW
 o0i370kWcROpS7fSN8PF1E4Jy7ibXMRmadU0jjUYV82Iuxo2LJMfd0CAS2gaiWdB3kMxRkDUtk
 Arbe6Z7SiikPmmH5utY/P+858/K7R0+O4S+U05vPtxUldr/e4VmoVn5QEGdl5jES9Ynrf7il9v
 YZxL66dCf+xWC1b2znLECH4Z6sXFnFtdbUNRXJdQHDOPdtmafXaNtVqTY6C7o2Of/5sHrYBt7a
 m2tABefYtKYNLO8/zL1GpMlurAQAA
X-Change-ID: 20260217-ayn-qcs8550-16c07b63de26
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>, 
 Xilin Wu <wuxilin123@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Teguh Sobirin <teguh@sobir.in>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777564991; l=3480;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=BZAIRb1V9RBCRADxqAkgfMETG04HaLqjZOCiMcqgnqA=;
 b=pTMlZVFUcCyKowoV2e1DRi228pQZA9I542ghkP0c2BjnQmsu8/S0w/sUkbbuc1w324fZq+X3u
 xSyYNsP8GmsB3zDV5zpcUPiFsgyz3OnzFVEc2IrXBuNaTugjXGk06HE
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This specifically includes:
* Odin 2 Mini
* Odin 2 Portal
* Thor

The original Odin 2 dts is not currently included as it has not yet
been verified.

The initial port was done by Teguh Sobirin for ROCKNIX and was made
available on the AYN github [0].

Support has been removed for things not yet supported by the upstream
kernel, these will be added later when the related drivers are submitted
and picked up. Such includes:

* All panels
* The Odin 2 Mini backlight and touch
* All rgb leds
* The built-in uart gamepad

[0] https://github.com/AYNTechnologies/linux/commits/sm8550/v6.17.5/

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Changes in v6:
- Fix comment style in patch 3
- Drop a pair of unnecessary pinmuxes in patch 3
- Lower usb sbu pins drive strength in patch 3
- Link to v5: https://lore.kernel.org/r/20260408-ayn-qcs8550-v5-0-c90abeb7a152@gmail.com

Changes in v5:
- Fix some style reviews in patch 6 which required matching labels in
  patch 3
- Drop hdmi support in patch 4, since it doesn't work
- Link to v4: https://lore.kernel.org/r/20260323-ayn-qcs8550-v4-0-33a8ac3d53fa@gmail.com

Changes in v4:
- Fold vendor description patch into the series
- Link to v3: https://lore.kernel.org/r/20260322-ayn-qcs8550-v3-0-4afa89c20888@gmail.com

Changes in v3:
- Drop unused backlight regulator in patch 3
- Move zap shader firmware to standalone reference
- Move i2c controller enables from common to devices
- Add ABL dtbo workarounds to patch 2 as per:
  https://lore.kernel.org/linux-arm-msm/dczz4uvcq4hc6p3zb6xnrsgmfeomwliagwhf36tewdz4z6mndp@afbxzhjziiwv/
- Fix multiple property alphabetical order issues in patch 2
- Use interrupts-extended for pwm-fan in patch 2
- Ensure blank line before status in patches 2-5
- Rename spk_amp_l/r to amplifier in patch 2
- Remove a few properties that are already in the soc dtsi in patch 2
- Order tlmm nodes by pin index in patch 2
- Drop qcom,dll-config from sdhc node in patch 2
- Drop dtbo support, convert common to dtsi, and include it directly in
  device specific dts'
- Link to v2: https://lore.kernel.org/r/20260311-ayn-qcs8550-v2-0-e66986e0f0cb@gmail.com

Changes in v2:
- Drop awinic bindings dep as a duplicated patch already exists
- Change Co-authored-by tags to Co-developed-by
- Drop alias to currently unused uart15 in patch 2
- Link to v1: https://lore.kernel.org/r/20260311-ayn-qcs8550-v1-0-fe8b2faad1ea@gmail.com

---
Aaron Kling (1):
      dt-bindings: arm: qcom: Add AYN QCS8550 Devices

Teguh Sobirin (4):
      arm64: dts: qcom: Add AYN QCS8550 Common
      arm64: dts: qcom: Add AYN Odin 2 Mini
      arm64: dts: qcom: Add AYN Odin 2 Portal
      arm64: dts: qcom: Add AYN Thor

Xilin Wu (1):
      dt-bindings: vendor-prefixes: Add AYN Technologies

 Documentation/devicetree/bindings/arm/qcom.yaml    |    9 +
 .../devicetree/bindings/vendor-prefixes.yaml       |    2 +
 arch/arm64/boot/dts/qcom/Makefile                  |    3 +
 .../arm64/boot/dts/qcom/qcs8550-ayntec-common.dtsi | 1740 ++++++++++++++++++++
 .../boot/dts/qcom/qcs8550-ayntec-odin2mini.dts     |   44 +
 .../boot/dts/qcom/qcs8550-ayntec-odin2portal.dts   |   84 +
 arch/arm64/boot/dts/qcom/qcs8550-ayntec-thor.dts   |  227 +++
 7 files changed, 2109 insertions(+)
---
base-commit: b9303e6bff706758c167af686b5315ad00233bf8
change-id: 20260217-ayn-qcs8550-16c07b63de26

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

