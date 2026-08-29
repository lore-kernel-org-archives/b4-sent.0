From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v3 0/4] arm64: dts: qcom: Support Retroid Pocket QCS8550
 Devices
Date: Sat, 29 Aug 2026 14:35:30 -0500
Message-Id: <20260829-rp-qcs8550-v3-0-198d5b2fc475@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22PwWrDMBBEf8XoXBV5Za1kn/IfpQd5vU4EtZ1Ir
 mgI/vcqDrQN9DgD7w1zE4lj4CS66iYi55DCMpegXypBJz8fWYahZAEKUDnlZDzLCyVnjJLOkGs
 sqhFHLQpwjjyGr1329v7IkS+fxbk+yl9lV+1CqK301/nHWCMp26MeGLDL7V3a+8SSlmkKa1exV
 gjoQPtGoQVDDG1P1lDvmBq0g+aaNaC4z59CWpd43a/let//70WupZLeeI2m93ogczhOPny8ls1
 dk+EPCuoJhYIODbF1I7faPaHbtn0DwT2z2F4BAAA=
X-Change-ID: 20260808-rp-qcs8550-85c84760f6f3
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788032140; l=2596;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=K8swZAGgof7VWw4iTiXBhaHNf2yTnB5IW5DZ4tGyzE0=;
 b=DeVh/Jkm068lVypf2P71HRF15JwgChjPUAe1eNak/KKJco1CxELHMJDUvNxtd+IGG3zD+WX2m
 zmk6+xtzVPpA4r5ujPi5nYJzI768Af01m4aN5x+LdHvIgrD/rir+HEu
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This specifically includes:
* Nova
* RP6

Retroid Pocket is effectively a sister company/brand to AYN. They are
both under Moorechip and all hardware designs are handled by Moorechip.
Thus the electrical designs are largely shared within a SoC generation.
Hence these include the AYN QCS8550 common dtsi. As such, this series
depends on the AYN QCS8550 series [0].

These two devices are almost electrically identical. The only notable
difference is the panels.

Definitions for parts of the hardware that are not yet supported by
mainline are not included. Such as:

* Panels
* All rgb leds
* The built-in uart gamepad

[0] https://lore.kernel.org/linux-arm-msm/20260727-ayn-qcs8550-v9-0-e3db456e10e5@gmail.com/

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Changes in v3:
- In patches 3 and 4, drop unnecessary status on backlight nodes
- Link to v2: https://lore.kernel.org/r/20260820-rp-qcs8550-v2-0-d4ce78fe9385@gmail.com

Changes in v2:
- In patch 1, consolidate the new devices to the existing qcs8550 list
- In patches 2 and 3, make regulator naming consistent
- In patches 2 and 3, move the mdss_dsi1 node to the correct
  alphabetical location
- In patches 2 and 3, fix some style issues with pinctrl references
- Link to v1: https://lore.kernel.org/r/20260808-rp-qcs8550-v1-0-a5a365ba3dc5@gmail.com

---
Aaron Kling (4):
      dt-bindings: vendor-prefixes: Add Retroid Pocket
      dt-bindings: arm: qcom: Add Retroid Pocket QCS8550 Devices
      arm64: dts: qcom: Add Retroid Pocket 6
      arm64: dts: qcom: Add Retroid Pocket Nova

 Documentation/devicetree/bindings/arm/qcom.yaml    |   2 +
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 arch/arm64/boot/dts/qcom/Makefile                  |   2 +
 .../boot/dts/qcom/qcs8550-retroidpocket-nova.dts   | 116 ++++++++++++++++++++
 .../boot/dts/qcom/qcs8550-retroidpocket-rp6.dts    | 120 +++++++++++++++++++++
 5 files changed, 242 insertions(+)
---
base-commit: e30626823a406725ce29bc75cb8ec467d3e1e326
change-id: 20260808-rp-qcs8550-85c84760f6f3
prerequisite-change-id: 20260217-ayn-qcs8550-16c07b63de26:v9
prerequisite-patch-id: 17ba304f7a8a08cc78f98e198db9c51f4786a22c
prerequisite-patch-id: 21873631f5dcdb9bbbdb5c20c3f5e9816cc405f9
prerequisite-patch-id: bf7b5dea0097cbbdf04929a4246d1fc65c607ea8
prerequisite-patch-id: d7f546eddc96a4f31a1e681abddbc96bd68abb32
prerequisite-patch-id: d40d784ad8efbb1204c024408be2067725a06cf2
prerequisite-patch-id: 25bbd55199a8250a912ef542b31f43dd5ccdbc90

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

