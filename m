From: Chuan Liu <chuan.liu@amlogic.com>
Subject: [PATCH 00/19] clk: amlogic: Add PLLs and peripheral clocks for A4
 and A5 SoCs
Date: Tue, 30 Sep 2025 17:37:13 +0800
Message-Id: <20250930-a4_a5_add_clock_driver-v1-0-a9acf7951589@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAMmk22gC/x3M0QoCIRBA0V9Z5jnBNC37lSXEnKmGYl1GkED89
 6TH83Bvh0rCVOG6dBBqXLlsE8fDAvmVticpxmkw2jgdzEWlU0wuJsSYPyW/Iwo3EmXu5xzQB+e
 thRnvQg/+/sfrbYwfl8Id9GgAAAA=
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>, Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759225047; l=4218;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=5o+htP+rM/HKQyGn1eH3S7+MzThwQ+uX1Hq8VqONr8g=;
 b=9UB/pSh4Qx25JQAEirqjDzvZLuzERi70Cm6gW7FIEkZawGXnWeEHArseYuIOn4cVV4sEtZAa/
 JbTQPGuAcNjD5619B0r6CFtJhOhE2icgF32q6i9IBU4mc7tmLmTgXXe
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series includes changes related to the PLL and peripheral
clocks for both the A4 and A5 SoCs.

The patches for A5 were previously submitted up to V3 by Xianwei.
https://lore.kernel.org/all/20250103-a5-clk-v3-0-a207ce83b9e9@amlogic.com/
After friendly coordination, I’ve taken over and continued the
submission as part of this series. The dt-bindings patch retains Rob's
original "Reviewed-by" tag, and I hope this hasn’t caused any
additional confusion.

Both A4 and A5 belong to the Audio series. Judging by their names, one
might assume that A5 is an upgrade to A4, but in fact, A5 was released
a year earlier than A4.

Since there are differences in the PLLs and peripheral clocks between
the A4 and A5 SoCs (especially the PLL), and taking into account factors
such as memory footprint and maintainability, this series does not
attempt to merge the two into a shared driver as was done for
G12A/G12B/SM1.

This patch series includes all related dt-bindings, driver, and dts
changes for the PLLs and peripheral clocks. Following our past convention
for clock-related submissions, the dts changes are placed at the end
and submitted separately. If this ordering makes it harder for
maintainers to review or pick patches, please feel free to point it out.

Co-developed-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
Chuan Liu (19):
      dt-bindings: clock: Add Amlogic A4 SCMI clock controller
      dt-bindings: clock: Add Amlogic A4 PLL clock controller
      dt-bindings: clock: Add Amlogic A4 peripherals clock controller
      clk: amlogic: Optimize PLL enable timing
      clk: amlogic: Correct l_detect bit control
      clk: amlogic: Fix out-of-range PLL frequency setting
      clk: amlogic: Add A4 PLL clock controller driver
      clk: amlogic: Add A4 clock peripherals controller driver
      arm64: dts: amlogic: A4: Add scmi-clk node
      arm64: dts: amlogic: A4: Add PLL controller node
      arm64: dts: amlogic: A4: Add peripherals clock controller node
      dt-bindings: clock: Add Amlogic A5 SCMI clock controller support
      dt-bindings: clock: Add Amlogic A5 PLL clock controller
      dt-bindings: clock: Add Amlogic A5 peripherals clock controller
      clk: amlogic: Add A5 PLL clock controller driver
      clk: amlogic: Add A5 clock peripherals controller driver
      arm64: dts: amlogic: A5: Add scmi-clk node
      arm64: dts: amlogic: A5: Add PLL controller node
      arm64: dts: amlogic: A5: Add peripheral clock controller node

 .../clock/amlogic,a4-peripherals-clkc.yaml         | 122 +++
 .../bindings/clock/amlogic,a4-pll-clkc.yaml        |  61 ++
 .../clock/amlogic,a5-peripherals-clkc.yaml         | 134 ++++
 .../bindings/clock/amlogic,a5-pll-clkc.yaml        |  63 ++
 arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi        |  80 ++
 arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi        |  87 ++
 drivers/clk/meson/Kconfig                          |  53 ++
 drivers/clk/meson/Makefile                         |   4 +
 drivers/clk/meson/a1-pll.c                         |   1 +
 drivers/clk/meson/a4-peripherals.c                 | 764 ++++++++++++++++++
 drivers/clk/meson/a4-pll.c                         | 242 ++++++
 drivers/clk/meson/a5-peripherals.c                 | 883 +++++++++++++++++++++
 drivers/clk/meson/a5-pll.c                         | 476 +++++++++++
 drivers/clk/meson/clk-pll.c                        |  76 +-
 drivers/clk/meson/clk-pll.h                        |   2 +
 .../clock/amlogic,a4-peripherals-clkc.h            | 129 +++
 include/dt-bindings/clock/amlogic,a4-pll-clkc.h    |  15 +
 include/dt-bindings/clock/amlogic,a4-scmi-clkc.h   |  42 +
 .../clock/amlogic,a5-peripherals-clkc.h            | 132 +++
 include/dt-bindings/clock/amlogic,a5-pll-clkc.h    |  24 +
 include/dt-bindings/clock/amlogic,a5-scmi-clkc.h   |  44 +
 21 files changed, 3406 insertions(+), 28 deletions(-)
---
base-commit: 01f3a6d1d59b8e25a6de243b0d73075cf0415eaf
change-id: 20250928-a4_a5_add_clock_driver-2b7c9d695633

Best regards,
-- 
Chuan Liu <chuan.liu@amlogic.com>

