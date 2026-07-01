From: Jian Hu <jian.hu@amlogic.com>
Subject: [PATCH v6 0/2] clk: amlogic: Add A9 peripherals clock controller
Date: Wed, 01 Jul 2026 16:30:01 +0800
Message-Id: <20260701-a9_peripherals-v6-0-9630f39879e5@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAArQRGoC/3XPTQrCMBAF4KuUrI1M/prWlfcQkTSd2oDakkhRp
 Hd32lUluHwD7+PNhyWMARM7FB8WcQopDA8K5a5gvnePK/LQUmYSZAklKO7qy0iVscfobolrKTT
 a2oJpPaPSGLELrxU8nSn3IT2H+F79SS7Xv9QkOXBE0VQenMDSH939NlyD3/vhzhZsUhtAQAYoA
 lqwzlZQmc6KHNBboMoATUCHQkKLmt6yOWA2gMoXGAIar0HUVoEy+heY5/kLkFdWxXEBAAA=
X-Change-ID: 20260603-a9_peripherals-4214e79705dc
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Brian Masney <bmasney@redhat.com>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, Jian Hu <jian.hu@amlogic.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782894659; l=2893;
 i=jian.hu@amlogic.com; s=20260415; h=from:subject:message-id;
 bh=EN7+luIk8ttxgrcIn29NeS7w5DT1mqmUEpqgU8cOU4w=;
 b=Xw9K4k9bePFl7wxYw4cyAoSwBxvdJXE98gki1lSauw51LcjhFKhZWqVL/NqbLD0zCnuv8t4gU
 /2+dtstXbAUAPadINiWCjQvsbYrlV3ZYbvw9AQhr0OftCJBiJrSuBtU
X-Developer-Key: i=jian.hu@amlogic.com; a=ed25519;
 pk=zHUE+rNtH9z+Sb8au1/elWknjFQmy5QDVkBoxleuOIA=
X-Endpoint-Received: by B4 Relay for jian.hu@amlogic.com/20260415 with auth_id=735
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds Amlogic A9 peripherals clock support,
including dt-binding and peripherals clock driver.

Note that this driver depends on the A9 PLL driver, which is not yet
upstream. The Meson PLL framework is currently undergoing refactoring,
and the A9 PLL driver will be submitted as a follow-up series after
that work has been completed.

Signed-off-by: Jian Hu <jian.hu@amlogic.com>
---
Changes in v6:
- Rebase onto the latest clk-meson-next.
- Update Kconfig and Makefile context to apply cleanly.
- No functional changes.
- Link to v5: https://lore.kernel.org/r/20260630-a9_peripherals-v5-0-bc4019730354@amlogic.com

Changes in v5:
- Include <linux/module.h>.
- Add missing '0' suffixes to some clocks.
- Fix typo: "encorder1" -> "encoder1".
- Fix the parent clock for a9_hdmitx1_pixel.
- Link to v4: https://lore.kernel.org/r/20260618-a9_peripherals-v4-0-fe120de44e77@amlogic.com

Changes in v4:
- Expose channel 3 for gen_clk.
- Add missing '0' suffixes to somes.
- Use helper macro for vclk clocks definitions.
- Drop forward declaration.
- Drop CLK_HW_INIT* and revert to explicit clock declarations.
- Fix can clock channel number comment.
- Rename enc clocks to encoder0/encoder1.
- Link to v3: https://lore.kernel.org/r/20260610-a9_peripherals-v3-0-d07a78085f71@amlogic.com

Changes in v3:
- Add "depend on A9 pll" instructions in the cover-letter.
- Move COMPILE_TEST after 'depends on ARM64' reported by sashiko-bot.
- Fix usb_48m_pre_sel's parent reported by sashiko-bot.
- Fix gen_div width reported by sashiko-bot.
- Fix hdmitx1_pixel's parent reported by sashiko-bot.
- Link to v2: https://lore.kernel.org/r/20260603-a9_peripherals-v2-0-ee1b8c0a1e6c@amlogic.com

Changes in v2:
- Split the A9 clock driver and send the peripherals clock separately.
- Add COMPILE_TEST in Kconfig.
- Drop the 'optional'.
- Rename apb4 to soc.
- Sort the header file.
- Rename hifi to hifi0.
- Use CLK_HW_INIT_PARENTS_DATA to describe clk_init_data.
- Use CLK_HW_INIT_HW to describe clk_init_data.
- Use CLK_HW_INIT_PARENTS_HW to describe clk_init_data.
- Link to v1: https://lore.kernel.org/all/20260511-b4-a9_clk-v1-0-41cb4071b7c9@amlogic.com/

---
Jian Hu (2):
      dt-bindings: clock: Add Amlogic A9 peripherals clock controller
      clk: amlogic: Add A9 peripherals clock controller driver

 .../clock/amlogic,a9-peripherals-clkc.yaml         |  164 ++
 drivers/clk/meson/Kconfig                          |   15 +
 drivers/clk/meson/Makefile                         |    1 +
 drivers/clk/meson/a9-peripherals.c                 | 2089 ++++++++++++++++++++
 .../clock/amlogic,a9-peripherals-clkc.h            |  351 ++++
 5 files changed, 2620 insertions(+)
---
base-commit: a1b4c3a63a7e56b98b2eccc3a82b9f31d51c2e35
change-id: 20260603-a9_peripherals-4214e79705dc

Best regards,
-- 
Jian Hu <jian.hu@amlogic.com>

