From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v9 0/6] arm64: dts: qcom: Support AYN QCS8550 Devices
Date: Mon, 27 Jul 2026 19:20:08 -0500
Message-Id: <20260727-ayn-qcs8550-v9-0-e3db456e10e5@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33Py27CMBAF0F9BXtfV2ONXuup/VF1MnDFYKgQSG
 hWh/HsNLPJAYnlHOndmrqLnLnMvPjZX0fGQ+9weSqjeNiLu6LBlmZuShQbtQCsv6XKQp9gHa0E
 qF8HXDhvWThRx7Djlv3vb1/cjd3z6LaXnabjL/bntLveNg7pNH+Wo1KJ8UBJk4lDrRNQops/tn
 vLPe2z34tYz6BdWF8vOVcExJIj12uLMar20WKyhRKGKGkIIa2vmFpfWFItIgSI2FtPTzXayBsL
 S2mJjBVRz7UlZvbZuZhGW1hULjjz72hqip73+hfXF2kpR5TzaRLi2YbIWVv+GYhuPmCxbb4yb2
 3Ec/wHuG6umXwIAAA==
X-Change-ID: 20260217-ayn-qcs8550-16c07b63de26
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Teguh Sobirin <teguh@sobir.in>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785198012; l=4384;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=wfyDTMZsh3mVx0GSk6DrAqznk5sGqgRtPNh7Xz1fR3o=;
 b=Ivf/TE6XAbUmV5RlPsxyAmFuTO0UcVpfrzlqfd00nXIWQiEIOBbmBGZwVmGaGrtfkSTdO6yUG
 Soi+KllHpcYBsHxTt1ycV7Sg8MZayiEi1XCczw+EsynjOI/eZvA9j3Y
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

* The Odin 2 Mini panel, backlight, and touch
* All rgb leds
* The built-in uart gamepad

[0] https://github.com/AYNTechnologies/linux/commits/sm8550/v6.17.5/

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Changes in v9:
- Add mi2s clock control in patch 2 as driver support for such was
  recently picked up
- Drop unnecessary address and size cells from patches 4 and 5
- Track renamed pcie port label from current linux-next
- Add panels to patches 4 and 5 as driver support has been picked up
- Add patch to document chipwealth vendor as used by patch 5
- Delete ipa node in patch 2 as it now depends on the mem node already
  being deleted
- Link to v8: https://lore.kernel.org/r/20260503-ayn-qcs8550-v8-0-d733f5e57446@gmail.com

Changes in v8:
- Properly order and format amplifier properties
- Set amplifiers name prefix to Amplifier L/R
- Link to v7: https://lore.kernel.org/r/20260430-ayn-qcs8550-v7-0-591a96735fa3@gmail.com

Changes in v7:
- Add back pinmuxes dropped last revision, but without output-low
- Link to v6: https://lore.kernel.org/r/20260430-ayn-qcs8550-v6-0-06a7e7b54aaa@gmail.com

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
Aaron Kling (2):
      dt-bindings: vendor-prefixes: Add Chip Wealth Technology
      dt-bindings: arm: qcom: Add AYN QCS8550 Devices

Teguh Sobirin (4):
      arm64: dts: qcom: Add AYN QCS8550 Common
      arm64: dts: qcom: Add AYN Odin 2 Mini
      arm64: dts: qcom: Add AYN Odin 2 Portal
      arm64: dts: qcom: Add AYN Thor

 Documentation/devicetree/bindings/arm/qcom.yaml    |    9 +
 .../devicetree/bindings/vendor-prefixes.yaml       |    2 +
 arch/arm64/boot/dts/qcom/Makefile                  |    3 +
 .../arm64/boot/dts/qcom/qcs8550-ayntec-common.dtsi | 1819 ++++++++++++++++++++
 .../boot/dts/qcom/qcs8550-ayntec-odin2mini.dts     |   44 +
 .../boot/dts/qcom/qcs8550-ayntec-odin2portal.dts   |   99 ++
 arch/arm64/boot/dts/qcom/qcs8550-ayntec-thor.dts   |  250 +++
 7 files changed, 2226 insertions(+)
---
base-commit: 0d33d21e47d9dc66f91e44da3fc9220c74d93df7
change-id: 20260217-ayn-qcs8550-16c07b63de26

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

