From: Chuan Liu <chuan.liu@amlogic.com>
Subject: [PATCH v5 0/8] clk: amlogic: Add A5 SoC PLLs and Peripheral clock
Date: Thu, 08 Jan 2026 14:08:14 +0800
Message-Id: <20260108-a5-clk-v5-0-9a69fc1ef00a@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAM5JX2kC/2XMTQqDMBCG4atI1k3JjIloV71H6SKOo4b6U0wJL
 eLdGwWF0uU3zPPOwvPk2ItLMouJg/NuHOIwp0RQa4eGpaviFqhQqwJAWiOpe8jUkC4slalmEPH
 5OXHt3lvodo+7df41Tp+tG2C97gm9JwJIJQ0zkq6hVDldbd+NjaMzjb1YIwEPCIDqgBhh3HmGw
 EUG1T/UOzSgMD+gjpAzJKusZdTpL1yW5QsTZL2sEAEAAA==
To: Chuan Liu <chuan.liu@amlogic.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767852503; l=3239;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=RYHvBenPbSd/Yi3PszJcY9ayngdFIumRsmnQpcNICxs=;
 b=bNmkHioG5afqUsiyHyWBmdJF5FymiZB8FvlwfnAAkHB9zBkDq58F6ck1JB+W3dKVC1+97bR+2
 Zk8BKItr/F+AHr7k7GgC+5esELm5Wny+ymECuG/t+DPCW3Rp3PBtvmD
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The patchset adds support for the peripheral and PLL clock controller
on the Amlogic A5 SoC family, such as A113X2.

Co-developed-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>

---
Changes in v5:
- Add “Co-developed-by” tag for Xianwei.
- Change rtc_clk flags to CLK_SET_RATE_NO_REPARENT.
- Optimize the macro definitions for clock configuration.
- Unified naming of clock parent related variables.
- Link to v4: https://lore.kernel.org/r/20251028-a5-clk-v4-0-e62ca0aae243@amlogic.com

Changes in v4:
- dt-binding for peripheral clocks (kept Rob’s 'Reviewed-by' here):
  - Added optional clock source rtc pll.
  - Renamed rtc_clk’s clkid to better reflect its function.
- PLL/Clock driver:
  - Adapted to Jerome’s refactored driver interface, naming
conventions, and macros.
  - Updated related CONFIG entries in Kconfig.
- Added dts patch of PLL/Clock.
- Link to v3: https://lore.kernel.org/r/20250103-a5-clk-v3-0-a207ce83b9e9@amlogic.com

Changes in v3:
- Rename xtal_24m to xtal, and modify some description of Kconfig.
- Drop some comment of PLL source code.
- Move definition of A5_CLK_GATE_FW frome common code into A5 peripheral source code.
- Use hw instead of name to describe parent_data.
- Making SCMI binding the first to submit.
- Link to v2: https://lore.kernel.org/r/20241120-a5-clk-v2-0-1208621e961d@amlogic.com

Changes in v2:
- Move some sys clock and axi clock from peripheral to scmi impletement.
- Remove  ARM_SCMI_PROTOCOL in Kconfig and correct name A5 but not A4.
- Add two optional clock inputs for the peripheral(ddr pll and clk-measure)
- Make some changes and adjustments according to suggestions.
- Link to v1: https://lore.kernel.org/r/20240914-a5-clk-v1-0-5ee2c4f1b08c@amlogic.com

---
Chuan Liu (8):
      dt-bindings: clock: Add Amlogic A5 SCMI clock controller support
      dt-bindings: clock: Add Amlogic A5 PLL clock controller
      dt-bindings: clock: Add Amlogic A5 peripherals clock controller
      clk: amlogic: Add A5 PLL clock controller driver
      clk: amlogic: Add A5 clock peripherals controller driver
      arm64: dts: amlogic: A5: Add scmi-clk node
      arm64: dts: amlogic: A5: Add PLL controller node
      arm64: dts: amlogic: A5: Add peripheral clock controller node

 .../clock/amlogic,a5-peripherals-clkc.yaml         | 134 ++++
 .../bindings/clock/amlogic,a5-pll-clkc.yaml        |  63 ++
 arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi        |  86 +++
 drivers/clk/meson/Kconfig                          |  27 +
 drivers/clk/meson/Makefile                         |   2 +
 drivers/clk/meson/a5-peripherals.c                 | 796 +++++++++++++++++++++
 drivers/clk/meson/a5-pll.c                         | 478 +++++++++++++
 .../clock/amlogic,a5-peripherals-clkc.h            | 132 ++++
 include/dt-bindings/clock/amlogic,a5-pll-clkc.h    |  24 +
 include/dt-bindings/clock/amlogic,a5-scmi-clkc.h   |  44 ++
 10 files changed, 1786 insertions(+)
---
base-commit: f0b9d8eb98dfee8d00419aa07543bdc2c1a44fb1
change-id: 20240911-a5-clk-35c49acb34e1

Best regards,
-- 
Chuan Liu <chuan.liu@amlogic.com>

