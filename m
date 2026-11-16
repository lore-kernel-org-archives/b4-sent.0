From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Subject: [PATCH v2 00/11] Add support for the Qualcomm Molokai (SM8845) and
 the Motorola Signature
Date: Mon, 16 Nov 2026 13:09:58 +0530
Message-Id: <20261116-molokai-soc-v2-0-9dc4dddc4e96@yahoo.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/41Qy27CMBD8FeRzF9lrnMac+A/EwXbWxC3BYCcRC
 OXfcQCpVcWhx1nNa+fGMqVAma0XN5ZoDDnEYwH4sWCuNcc9QWgKZsixEkJU0MVD/DYBcnRQea8
 tauXQS1YUp0Q+XB5u290T58F+ketnixcj0XkoMf2T9pNSQv9m9IeuA2s40UpUpIRcj4L9bvZGs
 z8NzkFjyDb4qWqrmn+ITI0atLO14lpygatZM3/QhtzHdH3MU05z4bdLjAI4SItEGrk30m6upo1
 x6WLHdtM03QE24EZxaAEAAA==
X-Change-ID: 20261116-molokai-soc-6ff9b295c2f3
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Kees Cook <kees@kernel.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Venkat Yadlapati <venkat.yadlapati@yahoo.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794814798; l=4502;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=oZyV2CZnxAKnIRmKaxZ/CaUsKjreVXX4pq0tIOXjOQ8=;
 b=xxaIERpZ7Ay/BC0sUpovGGIl1JLlW84lRuSiqF0uStBIHnDlC3treI61I+kRATdxSaFr4aadv
 pTdjN50vNk9AiXi0gZKt7Qy3c+xCzFQCH70XU+BgUZDfKa1CEk9wUkB
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Molokai (SM8845) is a Qualcomm SoC derived from Kaanapali (SM8850). It
has its own TLMM and GPIO to PDC wakeup map, a PDC with one more
interrupt range, no I2C master hub, no fourth QUP wrapper, a different
GPU clock controller and an Adreno 829 instead of the Adreno 840.

This series adds:
- the SoC ID (685, as reported in SMEM) and the socinfo entry
- the PDC compatible, the UBWC config and the protection domains
- the SoC compatible patterns and the board compatible
- the second DSI controller and PHY of Kaanapali, which the Motorola
  Signature uses for its panel
- the Molokai dtsi on top of the Kaanapali one, with its GPU
- a first devicetree for the Motorola Signature: UFS, USB with role
  switching and pmic-glink, the keys and the splash framebuffer

The rest of the phone (display, audio, DSPs, thermal) will follow once
the drivers it needs are reviewed.

It depends on the Molokai TLMM, GPU clock controller and Adreno 829
series, sent at the same time.

Tested on the Motorola Signature, together with the board patches that
will follow: it boots postmarketOS from UFS, with USB networking, the
keys and the battery and USB power supplies working.
dtbs_check is clean for the Motorola Signature and the Kaanapali MTP and
QRD.

I used an LLM (Claude) to help write these patches and their commit
messages. I reviewed all of them and tested the result on the device.

---
Changes in v2:
- vantage: describe the PMICs as reported by SMEM and the vendor
  devicetree: PMK8550 on SID 0 (6 GPIOs, instead of including
  pmk8850.dtsi, whose 8 GPIOs made the GPIO driver read registers that
  do not exist), PM8550 and PM8550VE RPMh regulator compatibles
  (were PMH0101/PMH0110).
- vantage: the LDOs are PMIC5 LDOs without an auto mode, start them in
  high power mode like the vendor devicetree (v1 asked for auto mode,
  which the PMIC530 table encodes as the PMIC5 low power mode).
- vantage: drop the serial0 alias of the disabled uart7.
- vantage: drop alignment from the static reserved-memory nodes.
- vantage: move the memory map comment to the reserved-memory node.
- vantage: sort /delete-node/ lines, the clocks and the label overrides.
- Link to v1: https://patch.msgid.link/20261116-molokai-soc-v1-0-3b2ee920fa3b@yahoo.com

---
Venkat Yadlapati (11):
      dt-bindings: arm: qcom,ids: Add SoC ID for SM8845
      soc: qcom: socinfo: Add SM8845 SoC ID
      dt-bindings: interrupt-controller: qcom,pdc: Document Molokai PDC
      soc: qcom: ubwc: Add config for Molokai
      soc: qcom: pd-mapper: Add support for Molokai
      dt-bindings: arm: qcom-soc: Extend pattern for Molokai
      dt-bindings: arm: qcom: Document Molokai and the Motorola Signature
      arm64: dts: qcom: kaanapali: Add the second DSI controller and PHY
      arm64: dts: qcom: Add Molokai (SM8845) SoC dtsi
      arm64: dts: qcom: molokai: Describe the Adreno 829 GPU
      arm64: dts: qcom: Add Motorola Signature (vantage)

 .../devicetree/bindings/arm/qcom-soc.yaml          |   4 +-
 Documentation/devicetree/bindings/arm/qcom.yaml    |   5 +
 .../bindings/interrupt-controller/qcom,pdc.yaml    |   1 +
 arch/arm64/boot/dts/qcom/Makefile                  |   1 +
 arch/arm64/boot/dts/qcom/kaanapali.dtsi            |  90 ++-
 .../boot/dts/qcom/molokai-motorola-vantage.dts     | 784 +++++++++++++++++++++
 arch/arm64/boot/dts/qcom/molokai.dtsi              | 327 +++++++++
 drivers/soc/qcom/qcom_pd_mapper.c                  |   1 +
 drivers/soc/qcom/socinfo.c                         |   1 +
 drivers/soc/qcom/ubwc_config.c                     |   1 +
 include/dt-bindings/arm/qcom,ids.h                 |   1 +
 11 files changed, 1212 insertions(+), 4 deletions(-)
---
base-commit: 6a876df4686788cd39128b62d7fcbff62f39278f
change-id: 20261116-molokai-soc-6ff9b295c2f3
prerequisite-change-id: 20261116-molokai-tlmm-ba0ee416e513:v1
prerequisite-patch-id: 370171903d0f17fe15c388c1656b22e24100153f
prerequisite-patch-id: 99e2c8b1997ebac9bf0463fdde3d83f6712ce487
prerequisite-change-id: 20261116-molokai-gpucc-daebd2758b5d:v1
prerequisite-patch-id: 0e6a86461e4d0ff585e2c950c87b4492ec9d96e8
prerequisite-patch-id: 6e286744dc03d7bd7216695a9c9632b22ad41f05
prerequisite-change-id: 20261116-molokai-a829-9cb850930124:v1
prerequisite-patch-id: c3a4e2985176713b54c997f91fa4975db8cdff3a
prerequisite-patch-id: c8fee006e015f2c35033a51779a4f1eb4655dcd0

Best regards,
--  
Venkat Yadlapati <venkat.yadlapati@yahoo.com>

