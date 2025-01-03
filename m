From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v3 0/5] Add A5 SoC PLLs and Peripheral clock
Date: Fri, 03 Jan 2025 13:36:40 +0800
Message-Id: <20250103-a5-clk-v3-0-a207ce83b9e9@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGl3d2cC/1WMQQqDMBBFryJZNyUTo2hXvUfpIo5THaqmJCW0i
 HdvFBS6fJ//3iwCeaYgLtksPEUO7KYE+SkT2NupI8ltYqGVNqoGkLaQODxlXqCpLTa5IRDp/PL
 04M8Wut0T9xzezn+3boR13RNmT0SQShZEGs0DGlXh1Y6D6xjP6EaxRqI+RACtDlEnMXFVaqC6h
 PZfXJblB2doYz3XAAAA
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chuan Liu <chuan.liu@amlogic.com>, 
 Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735882602; l=2678;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=ZptAS+5MfVYHwRbyK5bmvm62nwegy8I9wdDDR18v5n4=;
 b=zL9UkYY6YjfifjhPWGcgbd6WLqUytsG2stmsDAanVcuNKVg1DnIXfNZT0t6duvz7/uQ9UPdP0
 y4UhupkQEgzB7VlGR/wfDoDm2CAkZuS9j8AKyGqYL1PGz+TLOvwUWW6
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The patchset adds support for the peripheral and PLL clock controller
found on the Amlogic A5 SoC family, such as A113X2.

Some clocks are provided by security zones. These clock accessed
througth SCMI driver in linux, inlcuding OSC, SYS_CLK, AXI_CLK,
CPU_CLK, DSU_CLK, GP1_PLL, FIXED_PLL_DCO, FIXED_PLL, SYS_PLL_DIV16,
ACLKM, CPU_CLK_DIV16, FCLK_50M_PREDIV, FCLK_50M_DIV, FCLK_50M, 
FCLK_DIV2_DIV, FCLK_DIV2, FCLK_DIV2P5_DIV, FCLK_DIV2P5, FCLK_DIV3_DIV,
FCLK_DIV3, FCLK_DIV4_DIV, FCLK_DIV4, FCLK_DIV5_DIV, FCLK_DIV5,
FCLK_DIV7_DIV, FCLK_DIV7, CLKID_SYS_MMC_PCLK, CLKID_SYS_CPU_CTRL,
CLKID_SYS_IRQ_CTRL, CLKID_SYS_GIC, CLKID_SYS_BIG_NIC, CLKID_AXI_SYS_NIC,
and CLKID_AXI_CPU_DMC.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
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
Chuan Liu (5):
      dt-bindings: clock: add Amlogic A5 SCMI clock controller support
      dt-bindings: clock: add Amlogic A5 PLL clock controller
      dt-bindings: clock: add Amlogic A5 peripherals clock controller
      clk: meson: add support for the A5 SoC PLL clock
      clk: meson: add A5 clock peripherals controller driver

 .../clock/amlogic,a5-peripherals-clkc.yaml         |  132 ++
 .../bindings/clock/amlogic,a5-pll-clkc.yaml        |   63 +
 drivers/clk/meson/Kconfig                          |   27 +
 drivers/clk/meson/Makefile                         |    2 +
 drivers/clk/meson/a5-peripherals.c                 | 1408 ++++++++++++++++++++
 drivers/clk/meson/a5-pll.c                         |  532 ++++++++
 .../clock/amlogic,a5-peripherals-clkc.h            |  132 ++
 include/dt-bindings/clock/amlogic,a5-pll-clkc.h    |   24 +
 include/dt-bindings/clock/amlogic,a5-scmi-clkc.h   |   44 +
 9 files changed, 2364 insertions(+)
---
base-commit: 961101258aa2da34b032ea21f32599a895448996
change-id: 20240911-a5-clk-35c49acb34e1

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

