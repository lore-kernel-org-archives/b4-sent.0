From: Joe Sandom <jsandom@axon.com>
Subject: [PATCH v4 0/5] arm64: dts: qcom: add QCS8550 RB5Gen2 support
Date: Mon, 20 Apr 2026 10:13:12 +0100
Message-Id: <20260420-rb5gen2-dts-v4-0-b461909c2de8@axon.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACnu5WkC/23MsQ6DIBSF4VcxzKVBuIh26ns0HQQuylBtwBAb4
 7sXnbTpeE7y/QuJGDxGcisWEjD56MchD7gUxPTt0CH1Nm/CGa8YMKBByw4HTu0UaVkzY5FpVVa
 GZPEO6Py81x7PvHsfpzF89ngqt/d/J5WU0bqRrnYGGnDm3s7jcDXji2yZxI9UnSnP1DKjHIBCV
 OKHiiNtzlRkqjOphJQWNBzouq5fXjQQ7xsBAAA=
X-Change-ID: 20260404-rb5gen2-dts-180cde0b716c
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Joe Sandom <jsandom@axon.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776676395; l=4255;
 i=jsandom@axon.com; s=20260319; h=from:subject:message-id;
 bh=8SBhTU2OOi12EWCM5Hj3umAGo+5riQev7UW56BMZGNg=;
 b=bDMGvn5FqPPNXAuR8ddCJxgw39OiLl1cDJUGAF6kBPgBgahhbvSVtx1ChIEESkEEOG1GzgI+g
 WImeSR97oTUCIxmDzbv2z72udtq5balLem5682xFs3luCWa4Rr+6UmN
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
Changes in v4:
- Renamed LT9611 regulator nodes from lt9611-regulator-* to
  regulator-lt9611-* to follow standard naming convention
- Moved pmic-glink node before regulators to match alphabetical
  ordering used by sm8550-hdk.dts
- Reordered sound dai-link sub-nodes: codec before cpu
- Added comma separation between pinctrl-0 phandle references
  (lt9611 and tc9563 entries)
- Changed firmware paths from qcom/qcs8550/ to qcom/sm8550/ for
  adsp, cdsp, modem, IPA and GPU to keep all firmware in the same
  subdirectory
- Link to v3: https://lore.kernel.org/r/20260409-rb5gen2-dts-v3-0-be736355d4b4@axon.com

Changes in v3:
- Reworded MHI commit message to describe actual usage (debugfs
  link_transition_count) per Neil's feedback
- Reordered pinctrl-0 before pinctrl-names file-wide per Konrad's
  feedback
- Removed output-high from lt9611_rst_pin since the driver handles
  reset sequencing
- Reordered tlmm pinctrl entries by GPIO number
- Changed bias-pull-up to bias-disable for regulator enable pins
  (upd_1p05_en, upd_3p3_en) since these are active-high enables
- Added comments for gpio-reserved-ranges explaining GPIOs 32-35
  are for NFC secure element and 36-39 for fingerprint sensor
- Removed max-sd-hs-hz override since upstream clock driver already
  provides the correct 37.5MHz frequency
- Updated msi-map deletion rationale with root cause: Gunyah limits
  ITS device mappings to two per root complex on SM8550
- Link to v2: https://lore.kernel.org/r/20260407-rb5gen2-dts-v2-0-d0c7f447ee73@axon.com

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
 arch/arm64/boot/dts/qcom/qcs8550-rb5gen2.dts    | 1573 +++++++++++++++++++++++
 arch/arm64/boot/dts/qcom/sm8550-hdk.dts         |    4 +-
 arch/arm64/boot/dts/qcom/sm8550-qrd.dts         |    4 +-
 arch/arm64/boot/dts/qcom/sm8550.dtsi            |   26 +-
 6 files changed, 1602 insertions(+), 12 deletions(-)
---
base-commit: af241225893ac4933bb8f0615f2dfda8ea2326ce
change-id: 20260404-rb5gen2-dts-180cde0b716c

Best regards,
-- 
Joe Sandom <jsandom@axon.com>

