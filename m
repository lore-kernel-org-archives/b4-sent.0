From: Joe Sandom <jsandom@axon.com>
Subject: [PATCH v2 0/5] arm64: dts: qcom: add QCS8550 RB5Gen2 support
Date: Tue, 07 Apr 2026 16:46:43 +0100
Message-Id: <20260407-rb5gen2-dts-v2-0-d0c7f447ee73@axon.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOMm1WkC/23MQQ6DIBCF4auYWXcaIGi1q96jcaHDoCwKDRhiY
 7h7qesu/5e874DE0XGCe3NA5OySC76GujRA6+QXRmdqgxKqE1pojHO7sFdotoSyF2RYzDfZEdT
 HO7J1+6k9x9qrS1uInxPP8rf+d7JEgf3Q2t6SHrSlx7QHf6XwgrGU8gWEx1PfpQAAAA==
X-Change-ID: 20260404-rb5gen2-dts-180cde0b716c
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Joe Sandom <jsandom@axon.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775576820; l=2699;
 i=jsandom@axon.com; s=20260319; h=from:subject:message-id;
 bh=n5DZ/2/rUyaYQzTqM/i7xw0BlntkOKwWDMmmePbEDNU=;
 b=sIRtwMpw7um4PASGmn0Z2tIvRkXoeHqaVDUfXiVCGTQTVgYjZkNlqOO4zBxfxgzrkR5nA2mmZ
 3I7SXtrOeXbAzcpRzTHEWN22B6nLQqqlS9jS3ITBCE/8w3dkxVPyzCO
X-Developer-Key: i=jsandom@axon.com; a=ed25519;
 pk=Q/yflwj2WhkgBVTskrS9Vl5oScD0Bp3vTzDi+OxskTo=
X-Endpoint-Received: by B4 Relay for jsandom@axon.com/20260319 with auth_id=687
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds device tree support for the Thundercomm RB5Gen2
development kit, based on the Qualcomm QCS8550 chipset.

Patches 1-3 prepares for the RB5gen2 device tree by adding MHI register
regions and port labels to the PCIe controller nodes, as well as moving
common IPA properties into sm8550.dtsi. Then update the existing HDK
and QRD board files accordingly.

Patches 4-5 add the dt-bindings documentation and the board device tree
for the RB5Gen2. This initial submission covers the main board; the vision
mezzanine will be supported in a follow-up series.

Product page:
https://www.thundercomm.com/product/qualcomm-rb5-gen-2-development-kit

Signed-off-by: Joe Sandom <jsandom@axon.com>
---
Changes in v2:
- Lowercase hex in MHI region definitions for pcie0 and pcie1 nodes +
  vertical alignment
- Change pcie0 and pcie1 reg-names for one entry per line
- Ensured pcie port labels + changes to sm8550-hdk.dts and sm8550-qrd.dts
  are done in a single commit
- Moved IPA gsi-loader and memory-region to sm8550.dtsi since they are common
  properties. Reflect changes in sm8550-hdk.dts and sm8550-qrd.dts
- Removed usbhub_reset since this is not required
- Added swctrl-gpios property to wcn7850-pmu
- Split sw_ctrl_default gpio from bt_default grouping and referenced the
  pinctrl separately
- Replaced upd_reset regulator-fixed with pinctrl and vddpe-3v3-supply
  on pcie0
- Aligned firmware-name values vertically on the quote mark
- Changed cdsp, adsp and modem remoteprocs to .mbn file type instead of
  .mdt
- Added remark in rb5gen2 dts commit explaining the rationale for
  deleting msi-map in pcie0 and pcie1 nodes
- Link to v1: https://lore.kernel.org/r/20260404-rb5gen2-dts-v1-0-895f8fc494fc@axon.com

---
Joe Sandom (5):
      arm64: dts: qcom: sm8550: add PCIe MHI register regions
      arm64: dts: qcom: sm8550: add PCIe port labels
      arm64: dts: qcom: sm8550: move IPA properties to SoC device tree
      dt-bindings: arm: qcom: document QCS8550 RB5Gen2 board
      arm64: dts: qcom: qcs8550: add QCS8550 RB5Gen2 board support

 Documentation/devicetree/bindings/arm/qcom.yaml |    6 +
 arch/arm64/boot/dts/qcom/Makefile               |    1 +
 arch/arm64/boot/dts/qcom/qcs8550-rb5gen2.dts    | 1574 +++++++++++++++++++++++
 arch/arm64/boot/dts/qcom/sm8550-hdk.dts         |    4 +-
 arch/arm64/boot/dts/qcom/sm8550-qrd.dts         |    4 +-
 arch/arm64/boot/dts/qcom/sm8550.dtsi            |   26 +-
 6 files changed, 1603 insertions(+), 12 deletions(-)
---
base-commit: af241225893ac4933bb8f0615f2dfda8ea2326ce
change-id: 20260404-rb5gen2-dts-180cde0b716c

Best regards,
-- 
Joe Sandom <jsandom@axon.com>

