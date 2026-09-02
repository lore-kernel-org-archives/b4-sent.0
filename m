From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Subject: [PATCH v11 0/6] Add VIM4 MCU/FAN support
Date: Wed, 02 Sep 2026 14:51:04 +0200
Message-Id: <20260902-add-mcu-fan-khadas-vim4-v11-0-5f1610d83bf0@aliel.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4XSzWrDMAwA4FcpPs/D8m/c095j7CD/rWZtuiVp6
 Ch99znpIcGQzjcJ9ElIvpE+djn2ZL+7kS6Ouc/ntgQALzviD9h+RppDSRDOuGaScYoh0JO/0IQ
 t/TpgwJ6O+SQpevAuKiW8daRUf3cx5etMv3884i7+XEqH4ZEkDvtI/fl0ysN+18brQOcmRgCZC
 g65H87d7zzaCHPFv0OMQBnlDnh0Er1x7A2POR5fUzeTI18zYpvhhTFMCe04l8JixYgVA2abEYV
 BjSYpwxyAqxi5YjhsM7IwUhoAibxJPFSMWjNym1HTNMknNKCM46Ji9MIo0NuMLowvzzoNSWpVM
 WZh9LMVm8IoKx02aLUKTcU0C2OeHbyZDi5lijFaQKErxi5Mw9Q2Y6eDq5BMY4A5GysG2OJY9uR
 UwKYlRx+ctUqhWH/A+/3+ByxBB0lwAwAA
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
 mfd@lists.linux.dev, Ronald Claveau <linux-kernel-dev@aliel.fr>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=5707;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=3U+Pkz6+oDicvNgDi+v7MEvMt0z2EC/nlxN4WJYgGF8=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQ9YM6btVa40kvUoeOup33rl9tU5da/tE74LYM4dv5Hfwh
 99yL/veUcrCIMbFICumyNI/1/LEu8tHz3zdo54CM4eVCWQIAxenAEzkyReGP1xZikLngipK3hrf
 bFdIvJXst9ijc8rJOH6uV1Wbpf+k+DEyHMziPlqU2q5edad57TbRUw9MuQ8aLe5cxGx1rqz8hkM
 4EwA=
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

As the thermal patch depends on MFD, it should go through MFD tree.

Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
Changes in v11:
- PATCH 4: Use of_node_get to avoid reference count underflow.
           Check pdata for NULL pointer on probe.
           Manage rollback for regulator_disable failure on suspend.
           Remove regulator disable on resume failure, managed by devm reset.
- Link to v10: https://lore.kernel.org/r/20260901-add-mcu-fan-khadas-vim4-v10-0-aecdb9955a30@aliel.fr

Changes in v10:
- PATCH 1: makes KHADAS_MCU_GENERIC explicitly non-zero to remove the ambiguity with
           of_device_get_match_data() returning NULL/0 on a failed match. Reported by Sashiko.
- PATCH 4: devres for the regulator and cooling device are now attached to the child device (not the parent),
           closing a leak/use-after-free window. Also adds proper regulator teardown on unbind,
           fixes a level-vs-index mixup in shutdown/suspend, and disables the regulator if resume fails.
- Link to v9: https://lore.kernel.org/r/20260805-add-mcu-fan-khadas-vim4-v9-0-75df78710b9e@aliel.fr

Changes in v9:
- Rebased on next-20260731 (patches 1/8, 2/8 and 6/8 already applied, dropped from this series).
- PATCH 1: Add levels table and nlevels in khadas_mcu_fan_pdata struct.
- PATCH 2: Use MFD_CELL_* macros instead of open-coding mfd_cell.
- PATCH 3: Provide levels table and nlevels to platform data.
           Check match_data before the switch.
- PATCH 4: Use levels[] and nlevels from platform data. VIM4 levels is (0, 30, 40, 55, 75, 100).
- Link to v8: https://lore.kernel.org/r/20260702-add-mcu-fan-khadas-vim4-v8-0-244feee91a36@aliel.fr

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
Ronald Claveau (6):
      mfd: khadas-mcu: Add per-variant configuration infrastructure and VIM4 support
      mfd: khadas-mcu: Use MFD_CELL_* macros for cell declarations
      mfd: khadas-mcu: Add support for VIM4 MCU variant
      thermal: khadas-mcu-fan: Add fan config from platform data Add regulator support
      arm64: dts: amlogic: t7: Add i2c controller node
      arm64: dts: amlogic: t7: khadas-vim4: Add i2c MCU fan node

 .../dts/amlogic/amlogic-t7-a311d2-khadas-vim4.dts  |  13 +++
 arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi        |  10 ++
 drivers/mfd/khadas-mcu.c                           | 126 ++++++++++++++++++---
 drivers/thermal/khadas_mcu_fan.c                   |  90 +++++++++++----
 include/linux/mfd/khadas-mcu.h                     |  24 ++++
 5 files changed, 225 insertions(+), 38 deletions(-)
---
base-commit: 9dba66b6217aacb924d997de3866e7e4c0dcf952
change-id: 20260402-add-mcu-fan-khadas-vim4-ac1cbe553c9b

Best regards,
-- 
Ronald Claveau <linux-kernel-dev@aliel.fr>

