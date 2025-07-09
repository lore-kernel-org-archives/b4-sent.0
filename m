From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Subject: [PATCH v6 0/3] arm64: dts: qcom: x1-hp-x14: Add support for
 X1P42100 HP Omnibook X14
Date: Wed, 09 Jul 2025 21:26:51 +0200
Message-Id: <20250709-hp-x14-x1p-v6-0-f45cc186a62d@oldschoolsolutions.biz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIHCbmgC/33OTWrDMBAF4KsEraui0Z+lrnqPkoVljWqBiYyVm
 qTBd+/EKxsaL2bxBt7He7CKU8bKPk4PNuGcay4XCvbtxLq+vXwjz5Eyk0Ia0QjJ+5HfQNONHIO
 SSVtvo7eMCuOEKd9W7OtMuc/1Wqb7as/w/P7LzMAFl+CVseiUFM1nGWLt+lKGWoafKy2q7yH/s
 qc5y9eOJKdNJhjnIvjGHzpq66ido1YnIQgVNK06dPTWMTtHkwOdMhADtgncoWO2jts5hhytOw8
 WU+sb9dJZluUP5Fj5vdEBAAA=
X-Change-ID: 20250702-hp-x14-x1p-eb32f4696d96
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752089228; l=3154;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=9xgq7Yye1wmMDCjeCn2l/VYFm3PkgPlGRaN6phVB+SY=;
 b=G9GipB54aRQHawnqgL67IVL0d0u7HSYkPxlXnAxUFPMRHePz6LRumPKjql1MYb/5hy5clLfJR
 4Ducc3Lsu4IB1ydeildbOyJhhST+BLYAcXJhSI/1/731zhbBHvB7QII
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds support for the HP Omnibook X Laptop 14-fe1xxx. [1]

Since this is actually the same model as the 14-fe0xxx, but with an
X1P-42-100 SoC (Purwa), it needs a slightly different device tree.
To have as minimal duplicate definition as possible, the hp X14 gets 
commonalized into a dtsi (and it stays compatible to the derived 
device trees, like the Ultrabook G1q). 

The supported features are the same as for the original Omnibook X14:

- Keyboard (no function keys though)
- Display
- PWM brightness control
- Touchpad
- Touchscreen
- PCIe ports (pcie4, pcie6a)
- USB type-c, type-a
- WCN6855 Wifi-6E
- WCN6855 Bluetooth
- ADSP and CDSP
- X1 GPU
- GPIO Keys (Lid switch)
- Audio definition (works via USB and with internal speakers)

[1]: https://www.hp.com/us-en/shop/pdp/hp-omnibook-x-laptop-next-gen-ai-pc-14-fe100-14-a4nd1av-1#techSpecs

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
Changes in v6:
- rebased to next-20250709.
- picked up reviewed-by for patch #1 (thanks)
- corrected typo in patch #1
- removed model, compatible, chassis nodes from x1-hp-omnibook-x14.dtsi
- amended copyright strings as discussed
- Link to v5: https://lore.kernel.org/r/20250708-hp-x14-x1p-v5-0-44c916efa973@oldschoolsolutions.biz

Changes in v5:
- rebased to next-20250708.
- changed commit message for patch #1 to reflect what happens
- moved gpu node into the common dtsi part (always supported now)
- switched over to gpu_zap_shader definition in the individual parts
- Link to v4: https://lore.kernel.org/r/20250705-hp-x14-x1p-v4-0-1c351dbeaf18@oldschoolsolutions.biz

Changes in v4:
- leave the qcom,jp-omnibook-x14 ABI unchanged, reuse it for the -fe0 variant
- hacked b4 to create an easier reviewable patch: https://lore.kernel.org/all/20250705-format-harder-v1-1-55c5342be55c@oldschoolsolutions.biz
- Link to v3: https://lore.kernel.org/r/20250703-hp-x14-x1p-v3-0-affe103b4356@oldschoolsolutions.biz

Changes in v3:
- removed copyright strings
- amended changed commit message  
- Link to v2: https://lore.kernel.org/r/20250702-hp-x14-x1p-v2-0-af5b588d1979@oldschoolsolutions.biz

Changes in v2:
- remove pm8010 handling
- Link to v1: https://lore.kernel.org/r/20250702-hp-x14-x1p-v1-0-219356e83207@oldschoolsolutions.biz

---
Jens Glathe (3):
      dt-bindings: arm: qcom: Add HP Omnibook X14 AI X1P4200 variant
      arm64: dts: qcom: x1-hp-x14: Commonalize HP Omnibook X14 device tree
      arm64: dts: qcom: x1-hp-x14: Add support for X1P42100 HP Omnibook X14

 Documentation/devicetree/bindings/arm/qcom.yaml    |    1 +
 arch/arm64/boot/dts/qcom/Makefile                  |    2 +
 arch/arm64/boot/dts/qcom/x1-hp-omnibook-x14.dtsi   | 1549 ++++++++++++++++++++
 .../boot/dts/qcom/x1e80100-hp-omnibook-x14.dts     | 1549 +-------------------
 .../boot/dts/qcom/x1p42100-hp-omnibook-x14.dts     |   33 +
 5 files changed, 1589 insertions(+), 1545 deletions(-)
---
base-commit: 835244aba90de290b4b0b1fa92b6734f3ee7b3d9
change-id: 20250702-hp-x14-x1p-eb32f4696d96

Best regards,
-- 
Jens Glathe <jens.glathe@oldschoolsolutions.biz>

