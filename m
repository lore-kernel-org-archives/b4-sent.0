From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Subject: [PATCH v5 0/8] arm64: amlogic: T7 thermal support
Date: Fri, 24 Apr 2026 17:45:08 +0200
Message-Id: <20260424-add-thermal-t7-vim4-v5-0-9040ca36afe2@aliel.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32TzW7bMBCEX8XQuTSW/6JQFHmPoocldxmzlWRXk
 oUEgd+9tJyDk7o96LAC5hvN7uitmXkqPDfd7q2ZeC1zOY51sF92TTrg+MyiUJ0bBcqBkSCQSCw
 HngbsxeLFWgYjANh6GZFSkk1VnibO5WWjfv9xmyf+fa7w5fayGXiecYN3u68bW9cnKGfsXoKtg
 xRS/Cw47g/nJxz643NJ+3Qcvm18XNJh0zqLlrzLmWIKUSNGrVsbo7MpgvIAJmlgzx9VSnvlQgu
 yVY5II/kcpeNoyJMjwxgtGOXbjyrrOURoMbgWmbI1mjQBWZeyTGgoKogKpWvud1fN3tNtm4tpM
 NpbJWqUSi6xZ8E1NZrsg9fYreqjafQasmWjIktqA8mg2WmsTGuCTRSzSp58fGiqQdQ7iDKu2Bc
 Sp+l44ml5FTGyNRS0zl6+O/6tlZu2rv565vHc92LimRehooOWYw6EplvlI7EBtaUd0llkHMWvA
 xLOt65gkqnaW13v1a32Ko8483UhQ1m63cgv1eO2M99c23Mo83KcXreKVr9rff7bxlUKEDJkFVt
 CX2/6VNNzv8/Thqt57xD6MUJdEQCKAiA4UJ8Q+g6h5GOErghU7JW0TAD6E8LcI/7xFfXPEmSSt
 Kql2khzh7hcLn8ARWh9CrwDAAA=
X-Change-ID: 20260410-add-thermal-t7-vim4-00e571badcc1
To: Guillaume La Roque <glaroque@baylibre.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-pm@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, 
 Ronald Claveau <linux-kernel-dev@aliel.fr>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=6516;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=FSssUM/qlp7ESfovypvjaASUoJXNo+ODFXcjPxtQWdE=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQ+brCfVn9+Y/M5/nsthm/8zQaZ+35Pz5Nj+z5M08/8uGb
 jnnFr6a3lHKwiDGxSArpsjSP9fyxLvLR8983aOeAjOHlQlkCAMXpwBM5OZ2hv9FOe+8f0X/LYts
 Pyrjt03ZuFA1tFlUOqmFWbPD6tW0+z0MfyVCWr3PLvv28LIJS0WNctPLx25ZLrPtTxfJ/XR7p8X
 0hgsA
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds thermal monitoring support for the Amlogic T7 SoC,
used on the Khadas VIM4 board.

The T7 exposes six thermal sensors (a53, a73, gpu, nna, vpu, hevc),
each accessible through the secure monitor firmware interface rather
than a directly mapped eFuse register as on older SoCs.

The series is organized as follows:

- Patch 1 extends the amlogic,t7-thermal DT binding to describe the
  new amlogic,secure-monitor property.
- Patches 2-3 extend the Meson secure monitor driver to expose a
  thermal calibration read command (SMC ID 0x82000047).
- Patch 4 adds the secure monitor readout path to the amlogic thermal
  driver and introduces the amlogic,t7-thermal compatible.
- Patches 5-7 wire up the T7 DTSI with CPU cooling cells, sensor
  nodes, and thermal zones.
- Patch 8 extends the Khadas VIM4 DTS to map all thermal zones to the
  on-board MCU fan controller (states 30–100, corresponding to the
  FAN_CTRL register range 0x1E–0x64).

Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
Changes in v5:
- PATCH 4: Remove unnecessary variable and coding style alignment
           according to Neil's feedback.
- Link to v4: https://lore.kernel.org/r/20260423-add-thermal-t7-vim4-v4-0-d4c1528d5044@aliel.fr

Changes in v4:
- PATCH 4: Extract SM and syscon setup into amlogic_thermal_probe_sm() and
           amlogic_thermal_probe_syscon() removing amlogic_thermal_initialize()
           from Daniel's feedback.
           Also fix pre-existing bug: move calibration readout before
           devm_thermal_of_zone_register() to avoid reading uninitialized
           trim_info, according to Daniel's feedback.
- Link to v3: https://lore.kernel.org/r/20260421-add-thermal-t7-vim4-v3-0-a2e7215ed003@aliel.fr

Changes in v3:
- PATCH 1: Replace second if check by an else statement.
  Remove unnecessary label in example according to Conor's feedback
- Link to v2: https://lore.kernel.org/r/20260413-add-thermal-t7-vim4-v2-0-1002d90a0602@aliel.fr

Changes in v2:
- PATCH 1: change two const entries to enum, explain why sensor index is needed
  reorder conditional compatible for required, and fallback only according to
  Krzysztof's feedback.
- PATCH 3: Add kerneldoc for meson_sm_get_thermal_calib exported function
  according to Krzysztof's feedback.
- Link to v1: https://lore.kernel.org/r/20260410-add-thermal-t7-vim4-v1-0-19f2b8da74d7@aliel.fr

---
Ronald Claveau (8):
      dt-bindings: thermal: amlogic: Add support for T7
      firmware: meson: sm: Thermal calibration read via secure monitor
      firmware: meson: sm: Add thermal calibration SMC call
      thermal: amlogic: Add support for secure monitor calibration readout
      arm64: dts: amlogic: t7: Add cooling cells to all CPUs
      arm64: dts: amlogic: t7: Add thermal sensor nodes
      arm64: dts: amlogic: t7: Add thermal zones
      arm64: dts: amlogic: t7: khadas-vim4: Add fan cooling to thermal zones

 .../bindings/thermal/amlogic,thermal.yaml          |  37 +++-
 .../dts/amlogic/amlogic-t7-a311d2-khadas-vim4.dts  | 102 +++++++++
 arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi        | 245 +++++++++++++++++++++
 drivers/firmware/meson/meson_sm.c                  |  29 ++-
 drivers/thermal/amlogic_thermal.c                  | 112 +++++++---
 include/linux/firmware/meson/meson_sm.h            |   3 +
 6 files changed, 491 insertions(+), 37 deletions(-)
---
base-commit: f7b64ed948718290209074a50bb0df17e5944873
change-id: 20260410-add-thermal-t7-vim4-00e571badcc1
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
prerequisite-change-id: 20260402-add-mcu-fan-khadas-vim4-ac1cbe553c9b:v5
prerequisite-patch-id: f03a086b4137158412b2d47b3de793b858de8dde
prerequisite-patch-id: 123970c9b29c2090440f2fd71c85d3c6fd8e36de
prerequisite-patch-id: 3e2e56b0926ba327b520f935df4ced5089bbe503
prerequisite-patch-id: 65a5d76ffdbc9b3aab3385bb65cb027004c30e7e
prerequisite-patch-id: 237269801826dd3ad7fb16eb4d7d6d4eab504278
prerequisite-patch-id: 57e9b08a968aedf543d3d0d56cf1ca4db20b2a16
prerequisite-patch-id: cd98b74fa56af72af2553f391c400981d83cd4f4
prerequisite-patch-id: b730f5e42be1d89d193e63a0265495cdbf2c7d7b
prerequisite-patch-id: 8d675e7a239985c762843515b241f0a2f45f9c92
prerequisite-patch-id: 9debd88fa60febed9cd7208f86603b4c2d270520
prerequisite-patch-id: 314ef9ff0c4d1d15dab1dea9d92aa065f1eac3e9
prerequisite-patch-id: e6a1b58b91a877504a12ae68bee71eb4e496c33b
prerequisite-patch-id: 406f88d7dabd3a870b358fb53c21686f29eb32b7
prerequisite-patch-id: d7a75ae3be0f54e0a7e81ccb0043a2f05423c9d0
prerequisite-patch-id: 5e19dc5ace12b532284246f5c2ff3f214d8a9c4f
prerequisite-patch-id: 06e85862f502b682dac8a0932986d43f0bb82770
prerequisite-patch-id: 4809bbedf79f59e1abc52c17cffc0b1bbb43d365
prerequisite-patch-id: c050e8bac4b5491f6c7008a5ccb26f20fad38b46
prerequisite-patch-id: 30677db8fc57270787245103c0d5acf8791307b0

Best regards,
-- 
Ronald Claveau <linux-kernel-dev@aliel.fr>

