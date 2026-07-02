From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Subject: [PATCH v8 0/8] Add VIM4 MCU/FAN support
Date: Thu, 02 Jul 2026 11:55:53 +0200
Message-Id: <20260702-add-mcu-fan-khadas-vim4-v8-0-244feee91a36@aliel.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4XSzW7bMAwA4FcJfJ4C/dMKhqHvMexAilLjNXY62
 wlaFH33MW6AJtmy+UYZ/EiRemumMnZlajart2Ysx27q9oME7ZdVk7c4PBbVscSN1TZqr61CZtX
 ng6o4qKctMk7q2PVeYTaZSgguJ2ok+3kstXtZ5O8/PuKx/DpIgfnjsCGcisr7vu/mzWooL7Nai
 jgLp/y+TBMu5Terr+cfUScbfVgbHSQwyqifHQ7r7eEB+93+sctr4b4t1XHO2yU3BgwMsVYm6cw
 hknNtIIohk7agtc9OFyjXWdaBjanVprWR2SFDJRMLeQaO7AtS0N5Ce50VoCTSLabYYuEavGPHm
 kPM1WT0TFaTRROby+lKsfPtltlS7r2DYE+TEbmjXVFFbo2+QgKHm6O9LkrgdA3FWyqG28QmuRI
 dihl8Cpmp2gwM9NeiTivZkuqGI+46Vs/j/rmM86siWaXn5FwFc674Z65ZcmX0agY1HHY7NZapy
 Bop6rZQTYx+czTNaf3bbpr34+vyzuTotP//PqmjUVowY2XumIH0gzRZdus6LqS0dcG4+4wVBuT
 JRLLWu4Q3jLtgDNxnnDAYEWoATcbQDeMvGGvuM14Y78EYj7atlm+YcMn4+0w4dVNzRTAByLobJ
 n4ywcT7TBQmy5comupjuGHgk4n/GjEIE5InPD3+wO0F8/7+/hvK4aiSZgQAAA==
X-Change-ID: 20260402-add-mcu-fan-khadas-vim4-ac1cbe553c9b
To: Neil Armstrong <neil.armstrong@linaro.org>, Lee Jones <lee@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andi Shyti <andi.shyti@kernel.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Beniamino Galvani <b.galvani@gmail.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Liam Girdwood <lgirdwood@gmail.com>, 
 Mark Brown <broonie@kernel.org>
Cc: linux-amlogic@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-i2c@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-pm@vger.kernel.org, 
 Ronald Claveau <linux-kernel-dev@aliel.fr>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=5896;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=MkhDiz+wCQAykONWhcbRMorveNR9GQKaWPHd4CcDRxc=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQ5ab6Vuu6L5rcV0hr39WrA7/U2Unfmnxrve/EpYnlHudW
 DJd4c6/jlIWBjEuBlkxRZb+uZYn3l0+eubrHvUUmDmsTCBDGLg4BWAiHJcZ/ucULmgtO5pQ8pT1
 55xsO0Y2xZybDrN3er+6OV8zaJ6s1nKGf8ZOKyJSU878uHl6c7b4Sqvw1hmL/uruZvP4ZSu4o6d
 8Gi8A
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Khadas VIM4 board features a different MCU variant compared to
previous VIM boards.
While it shares the same I2C-based communication model,
it differs in some ways:

  - A distinct register map with its own volatile/writeable register set
  - A fan control with 0–100 levels instead of the 0–3 levels previously
  - A fan power supply gated through a regulator

This series adds support for this new variant by:

  1. Refactoring the khadas-mcu MFD driver to use per-variant data
     structures (regmap config, cells, fan platform data),
     and adding the khadas,vim4-mcu compatible string.

  2. Extending the fan thermal driver to retrieve the fan register
     and maximum level from platform_data,
     and to optionally manage a power regulator for the fan supply.

  3. Adding the corresponding DTS node for the VIM4, wiring the MCU to
     the I2C AO_A bus and exposing it as a thermal cooling device.

Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
Changes in v8:
- PATCH 4: Define constant for fan max level, remove extra space for unnecessary alignment.
           Thanks to Lee's review.
- Link to v7: https://lore.kernel.org/r/20260603-add-mcu-fan-khadas-vim4-v7-0-594ba8a965d8@aliel.fr

Changes in v7:
- PATCH 3-4: Simplify the per-variant handling by using local variables in khadas_mcu_probe()
             instead of introducing a dedicated data structure. Thanks to Lee's review.
- Link to v6: https://lore.kernel.org/r/20260516-add-mcu-fan-khadas-vim4-v6-0-cccc9b61f465@aliel.fr

Changes in v6:
- PATCH 4: Address Lee's review comments:
  - Use an enum to discriminate between MCU types instead of passing
    MFD data through the DT match table
  - Fix error code from -EINVAL to -ENODEV when no MCU type is matched
  - Make khadas_mcu_fan_cells and khadas_mcu_cells const
  - Use dev_err_probe() for regmap initialization error
  - Document fan speed levels for max_level
- Link to v5: https://lore.kernel.org/r/20260424-add-mcu-fan-khadas-vim4-v5-0-afcfa7157b23@aliel.fr

Changes in v5:
- PATCH 5: Replace devm_regulator_get_optional() with devm_regulator_get()
           to simplify error handling and remove NULL checks, also
           ordering as reverse christmas according to Neil's feedback.
- Link to v4: https://lore.kernel.org/r/20260421-add-mcu-fan-khadas-vim4-v4-0-447114a28f2d@aliel.fr

Changes in v4:
- PATCH 1: limit fan-supply property by compatible according to Conor's feedback.
- Link to v3: https://lore.kernel.org/r/20260417-add-mcu-fan-khadas-vim4-v3-0-a6a7f570b11b@aliel.fr

Changes in v3:
- PATCH 1: adding comment on vim4 compatible saying it is not discoverable,
           thanks to Rob's and Neil's feedback.
- Link to v2: https://lore.kernel.org/r/20260403-add-mcu-fan-khadas-vim4-v2-0-70536b22439a@aliel.fr

Changes in v2:
- PATCH 5: Add regulator_disable on suspend thanks to Neil's feedback.
- Link to v1: https://lore.kernel.org/r/20260402-add-mcu-fan-khadas-vim4-v1-0-2b12eb4ac7b0@aliel.fr

---
Ronald Claveau (8):
      dt-bindings: mfd: khadas: Add new compatible for Khadas VIM4 MCU
      dt-bindings: i2c: amlogic: Add compatible for T7 SOC
      mfd: khadas-mcu: Add per-variant configuration infrastructure and VIM4 support
      mfd: khadas-mcu: Add support for VIM4 MCU variant
      thermal: khadas-mcu-fan: Add fan config from platform data Add regulator support
      arm64: dts: amlogic: t7: Add i2c pinctrl node
      arm64: dts: amlogic: t7: Add i2c controller node
      arm64: dts: amlogic: t7: khadas-vim4: Add i2c MCU fan node

 .../bindings/i2c/amlogic,meson6-i2c.yaml           |  13 ++-
 .../devicetree/bindings/mfd/khadas,mcu.yaml        |  18 ++++
 .../dts/amlogic/amlogic-t7-a311d2-khadas-vim4.dts  |  13 +++
 arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi        |  20 ++++
 drivers/mfd/khadas-mcu.c                           | 118 ++++++++++++++++++---
 drivers/thermal/khadas_mcu_fan.c                   |  37 +++++--
 include/linux/mfd/khadas-mcu.h                     |  22 ++++
 7 files changed, 214 insertions(+), 27 deletions(-)
---
base-commit: f7b64ed948718290209074a50bb0df17e5944873
change-id: 20260402-add-mcu-fan-khadas-vim4-ac1cbe553c9b
prerequisite-message-id: <20260326092645.1053261-1-jian.hu@amlogic.com>
prerequisite-patch-id: f03a086b4137158412b2d47b3de793b858de8dde
prerequisite-patch-id: 123970c9b29c2090440f2fd71c85d3c6fd8e36de
prerequisite-patch-id: 3e2e56b0926ba327b520f935df4ced5089bbe503
prerequisite-patch-id: 65a5d76ffdbc9b3aab3385bb65cb027004c30e7e
prerequisite-patch-id: 237269801826dd3ad7fb16eb4d7d6d4eab504278
prerequisite-patch-id: 57e9b08a968aedf543d3d0d56cf1ca4db20b2a16
prerequisite-change-id: 20260326-add-bcm43752-compatible-e264a4f7973a:v2
prerequisite-patch-id: cd98b74fa56af72af2553f391c400981d83cd4f4
prerequisite-patch-id: b730f5e42be1d89d193e63a0265495cdbf2c7d7b
prerequisite-change-id: 20260330-fix-invalid-property-bbe54d933f71:v2
prerequisite-patch-id: 8d675e7a239985c762843515b241f0a2f45f9c92
prerequisite-change-id: 20260331-fix-aml-t7-null-reset-2b608ebf9da4:v1
prerequisite-patch-id: 5b5de77af11747ce964404fb827d2ee2bff47ea5
prerequisite-patch-id: 1e37fc75fed1e533adee0f3e7e6ead1f8ff3c55c
prerequisite-patch-id: 65a5d76ffdbc9b3aab3385bb65cb027004c30e7e
prerequisite-patch-id: 2daf583fb5e7449a02bd217d8aca330171b598aa
prerequisite-patch-id: 237269801826dd3ad7fb16eb4d7d6d4eab504278
prerequisite-patch-id: d1ddf9b7710e91f8062de83bd7ba55afb2c4c112
prerequisite-patch-id: 57e9b08a968aedf543d3d0d56cf1ca4db20b2a16
prerequisite-patch-id: cd98b74fa56af72af2553f391c400981d83cd4f4
prerequisite-patch-id: b730f5e42be1d89d193e63a0265495cdbf2c7d7b
prerequisite-patch-id: 9debd88fa60febed9cd7208f86603b4c2d270520
prerequisite-patch-id: 314ef9ff0c4d1d15dab1dea9d92aa065f1eac3e9

Best regards,
-- 
Ronald Claveau <linux-kernel-dev@aliel.fr>

