From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Subject: [PATCH 0/7] arm64: dts: qcom: IdeaCentre Mini 01Q8X10 Hamoa +
 Purwa
Date: Sat, 05 Sep 2026 11:28:55 +0200
Message-Id: <20260905-x1-ideacentre-mini-prettify-v1-0-9a87882973bb@oldschoolsolutions.biz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MywqAIBAAfyX23II9jOxXooPkWnvIQiWK6N9bO
 s4MzAOJIlOCoXgg0smJ9yBQlQXMqw0LITthqFXdKaM0XpUYsjOFHAk3DoxHpJzZ32i1a1rjeqN
 bD3KQ4Pn67+P0vh/JascCbQAAAA==
X-Change-ID: 20260905-x1-ideacentre-mini-prettify-a5d349d8954f
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788600555; l=2740;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=002QRWWTWJ51HFztLj3s0HXrMVYjCFS25RWD/f77lTI=;
 b=6E4nAPWSta2QpvQ90KLyGjveyG1YSHrs4M96Z4uUf/2yXPTL4Xm5hi0ANfax+NNFuDw3iB+6T
 VZqDZPi1BE7DG9jsyyWYYcH056Gri39Ir6MT1n6Hhc3/3KkI7/YOytV
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The IdeaCentre Mini 01Q8X10 (board 91B6) ships with two SoCs: Hamoa
(X1E80100), already upstream, and Purwa (X1P42100 / X1-26-100). Same
chassis, different silicon. Stubble and the DTB loader need distinct
compatibles.

This series splits the board description into
x1-lenovo-ideacentre-mini-01q8x10.dtsi and adds thin leaves. Each SKU
keeps lenovo,ideacentre-mini-01q8x10 as fallback:

  lenovo,hamoa-ideacentre-mini-01q8x10, lenovo,ideacentre-mini-01q8x10,
  qcom,x1e80100

  lenovo,purwa-ideacentre-mini-01q8x10, lenovo,ideacentre-mini-01q8x10,
  qcom,x1p42100

No qcom_scm change; the fallback is already on the allowlist.

The remaining patches fix the common DTSI for both boxes:

- Build the Hamoa EL2 DTB like the other Hamoa boards.
- Second M.2 3V3 is PMC8380_3 GPIO5, not TLMM18. A 2 s startup delay
  is required or pcie3 fails to probe. always-on is a hack until there
  is a real M.2 power sequencer.
- sound-name-prefix on the three DP ports. Enable lpass_vamacro: no
  onboard mics, but it provides fsgen for tx_macro and rx_macro.
- usb_mp port 1 is not populated (no PTN3222 @ 0x4f). USB-C is
  usb_1_ss0; rear Type-A is usb_mp port 0 behind a Genesys hub.

The Genesys hub is left undescribed.

UCM [1] and AudioReach [2] topology for these devices are online, too.

Tested on:
- IdeaCentre Mini 01Q8X10, Purwa (X1-26-100), 91B6
- Hamoa: compile-tested only

[1]: https://github.com/alsa-project/alsa-ucm-conf/pull/843
[2]: https://github.com/linux-msm/audioreach-topology/pull/74

Assisted-by: Grok 4.5 (xAI)
Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
Jens Glathe (7):
      dt-bindings: arm: qcom: Distinguish IdeaCentre Mini 01Q8X10 SKUs
      arm64: dts: qcom: Split IdeaCentre Mini into a common DTSI
      arm64: dts: qcom: Add Purwa IdeaCentre Mini 01Q8X10
      arm64: dts: qcom: ideacentre-mini: Build the Hamoa EL2 DTB
      arm64: dts: qcom: ideacentre-mini: Fix the second M.2 3V3 rail
      arm64: dts: qcom: ideacentre-mini: Wire up DP sound names and VA macro
      arm64: dts: qcom: ideacentre-mini: Drop the unused USB MP port

 Documentation/devicetree/bindings/arm/qcom.yaml    |   11 +-
 arch/arm64/boot/dts/qcom/Makefile                  |    8 +-
 .../qcom/hamoa-lenovo-ideacentre-mini-01q8x10.dts  | 1188 +-------------------
 .../qcom/purwa-lenovo-ideacentre-mini-01q8x10.dts  |   42 +
 .../qcom/x1-lenovo-ideacentre-mini-01q8x10.dtsi    | 1185 +++++++++++++++++++
 5 files changed, 1246 insertions(+), 1188 deletions(-)
---
base-commit: af5f12805e5cefa4fe68d6127c7e1fb78cd5535c
change-id: 20260905-x1-ideacentre-mini-prettify-a5d349d8954f

Best regards,
-- 
Jens Glathe <jens.glathe@oldschoolsolutions.biz>

