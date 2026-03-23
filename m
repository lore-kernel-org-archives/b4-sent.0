From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v4 0/6] arm64: dts: qcom: Support AYN QCS8550 Devices
Date: Mon, 23 Mar 2026 11:27:42 -0500
Message-Id: <20260323-ayn-qcs8550-v4-0-33a8ac3d53fa@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33NQQ6CMBCF4auYrq1pByjVlfcwLkqZahMBabGRE
 O5ugYXgwuWb5PtnIB6dRU9Ou4E4DNbbpo4j3e+Ivqv6htSWcRNgIBjwnKq+pq32MssY5UKzvBB
 JiSBIFE+Hxr7n2uW6bIftK0a77/Fufde4fv4Y+HRd4gnnm3jglFGDsgCjVMlRnW+Vso+Dbioyd
 QL8sRAtCnGUAplhuvi1ycoCbG0SbaqMkkcNTEq5tuM4fgB3QKrYMwEAAA==
X-Change-ID: 20260217-ayn-qcs8550-16c07b63de26
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>, 
 Xilin Wu <wuxilin123@gmail.com>, Teguh Sobirin <teguh@sobir.in>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774283267; l=3250;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=mAIONOJXN9qDLiD2zg6/6yjTKQjH5j/wK0B7TSQ0MeE=;
 b=m5luLhRY05a6rFuC6+NC+g8IhHYE8LcU4WFTyd5n0MdpaOdgbW1Lay2dJ2LWFEHdApTG83iv2
 Lic61un0fHcBptIUb2eDT3WN7NaX3PrT8fIVMx/Po1Awi7t5o3x2PIj
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This specifically includes:
* Odin 2 Mini
* Odin 2 Portal
* Thor

The original Odin 2 dtso is not currently included as it has not yet
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

This series depends on one other series as described in b4 deps. Namely,
the one adding the AYN vendor [1]. This must be merged first for schema
checks to succeed.

[0] https://github.com/AYNTechnologies/linux/commits/sm8550/v6.17.5/
[1] https://lore.kernel.org/all/20260220-ayn-vendor-v1-1-292cbbb682b3@gmail.com/

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
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
 .../arm64/boot/dts/qcom/qcs8550-ayntec-common.dtsi | 1762 ++++++++++++++++++++
 .../boot/dts/qcom/qcs8550-ayntec-odin2mini.dts     |  140 ++
 .../boot/dts/qcom/qcs8550-ayntec-odin2portal.dts   |   84 +
 arch/arm64/boot/dts/qcom/qcs8550-ayntec-thor.dts   |  230 +++
 7 files changed, 2230 insertions(+)
---
base-commit: 785f0eb2f85decbe7c1ef9ae922931f0194ffc2e
change-id: 20260217-ayn-qcs8550-16c07b63de26

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

