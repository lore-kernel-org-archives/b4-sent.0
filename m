From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Subject: [PATCH v6 0/4] arm64: amlogic: T7 thermal support
Date: Thu, 15 Oct 2026 19:54:08 +0200
Message-Id: <20261015-add-thermal-t7-vim4-v6-0-37d1c954390c@aliel.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33QzW6EIBQF4FcxrHubyxV0nFXfo+kC4VpJ/JkiN
 dNMfPeiszHGdnlIzseBh5g4eJ7ENXuIwLOf/DikULxkwrZm+GTwLmVBSAUqiWCcg9hy6E0HsYT
 Z9woQWZeyNs5aKVLzFrjx9019/3jmwF/fCY/PQ1GbicGOfe/jNRv4HmG9QKJUYi20fopj+NlWz
 XJr/DtgloAgq4bqizOlcuWb6Tx3r03YuJn2RH5O0EogkqvQYIF0IPIdQfKcyBNhiEuSmh1ifiD
 UnvhjRfpMcMpKTRenUakDofeEOid0IipUaE1emIb3D1mW5RfMQaoh8gEAAA==
X-Change-ID: 20260410-add-thermal-t7-vim4-00e571badcc1
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ronald Claveau <linux-kernel-dev@aliel.fr>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3497;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=OLOxCWkG1uAfbEHQrZsIv+PXDRKyrTYk6AYh4axR+Ek=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQ9ZF4UKf6484s8q/x8/Skz9VW2lQ0Mf/07Unkjvz/t7Ds
 yfKtwh0lLIwiHExyIopsvTPtTzx7vLRM1/3qKfAzGFlAhnCwMUpABNxcmdkOFX2sJR17fnIpr/K
 /B/4PPhrfJ9FGusmvzsRrXj+k9Y1oIoZ7yuuc6Rz+TreaflQorXS1qV6L8/pz3rnPrvdmXN9/jt
 GAA==
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
Changes in v6:
- Rebased on next-20261014 (patches 1/8 to 4/8 already applied, dropped from this series).
- PATCH 2: Add bus clocks and clock-names to all thermal sensor nodes.
- PATCH 4: Change cooling device map min and max values from 30-100 to 1-5.
           The driver maps (0,1,2,3,4,5) to (0,30,40,55,75,100)
- Link to v5: https://lore.kernel.org/r/20260424-add-thermal-t7-vim4-v5-0-9040ca36afe2@aliel.fr

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
Ronald Claveau (4):
      arm64: dts: amlogic: t7: Add cooling cells to all CPUs
      arm64: dts: amlogic: t7: Add thermal sensor nodes
      arm64: dts: amlogic: t7: Add thermal zones
      arm64: dts: amlogic: t7: khadas-vim4: Add fan cooling to thermal zones

 .../dts/amlogic/amlogic-t7-a311d2-khadas-vim4.dts  | 102 +++++++++
 arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi        | 253 +++++++++++++++++++++
 2 files changed, 355 insertions(+)
---
base-commit: ab8eada9868faeee95f25d81d3d6fed0d1c98b78
change-id: 20260410-add-thermal-t7-vim4-00e571badcc1

Best regards,
-- 
Ronald Claveau <linux-kernel-dev@aliel.fr>

