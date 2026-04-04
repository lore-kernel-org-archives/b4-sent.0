From: Joe Sandom <jsandom@axon.com>
Subject: [PATCH 0/5] arm64: dts: qcom: add QCS8550 RB5Gen2 support
Date: Sat, 04 Apr 2026 10:50:53 +0100
Message-Id: <20260404-rb5gen2-dts-v1-0-895f8fc494fc@axon.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAP3e0GkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDEwMT3aIk0/TUPCPdlJJiXUMLg+SUVIMkc0OzZCWgjoKi1LTMCrBp0bG
 1tQBwNxKLXQAAAA==
X-Change-ID: 20260404-rb5gen2-dts-180cde0b716c
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Joe Sandom <jsandom@axon.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775296270; l=1631;
 i=jsandom@axon.com; s=20260319; h=from:subject:message-id;
 bh=pf7w5tEPxeOOou+A5EAQoMnY3SiSO2iuLXfRP9MTBGw=;
 b=PQNR4qc+QRQmaWCTDKAfsavia3smfw0tdbcQvNnxWMbOcp6cpL75Jrot+IXFhLwx4GSnnE5Ck
 Ud+/OLc1uv8BwQly/+AOlIvjKgEToO+yCc3VqDqMBiYYqWQM+cNPUF+
X-Developer-Key: i=jsandom@axon.com; a=ed25519;
 pk=Q/yflwj2WhkgBVTskrS9Vl5oScD0Bp3vTzDi+OxskTo=
X-Endpoint-Received: by B4 Relay for jsandom@axon.com/20260319 with auth_id=687
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds device tree support for the Thundercomm RB5Gen2
development kit, based on the Qualcomm QCS8550 chipset.

Patches 1-3 prepare the SM8550 device tree by adding MHI register regions
and port labels to the PCIe controller nodes, then update the existing
HDK and QRD board files to match the renamed labels.

Patches 4-5 add the dt-bindings documentation and the board device tree
for the RB5Gen2. This initial submission covers the main board; the vision
mezzanine will be supported in a follow-up series.

Product page:
https://www.thundercomm.com/product/qualcomm-rb5-gen-2-development-kit

Signed-off-by: Joe Sandom <jsandom@axon.com>
---
Joe Sandom (5):
      arm64: dts: qcom: sm8550: add PCIe MHI register regions and port labels
      arm64: dts: qcom: sm8550-hdk: update PCIe port label reference
      arm64: dts: qcom: sm8550-qrd: update PCIe port label reference
      dt-bindings: arm: qcom: document QCS8550 RB5Gen2 board
      arm64: dts: qcom: qcs8550: add QCS8550 RB5Gen2 board support

 Documentation/devicetree/bindings/arm/qcom.yaml |    6 +
 arch/arm64/boot/dts/qcom/Makefile               |    1 +
 arch/arm64/boot/dts/qcom/qcs8550-rb5gen2.dts    | 1610 +++++++++++++++++++++++
 arch/arm64/boot/dts/qcom/sm8550-hdk.dts         |    2 +-
 arch/arm64/boot/dts/qcom/sm8550-qrd.dts         |    2 +-
 arch/arm64/boot/dts/qcom/sm8550.dtsi            |   14 +-
 6 files changed, 1627 insertions(+), 8 deletions(-)
---
base-commit: af241225893ac4933bb8f0615f2dfda8ea2326ce
change-id: 20260404-rb5gen2-dts-180cde0b716c

Best regards,
-- 
Joe Sandom <jsandom@axon.com>

