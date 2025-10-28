From: Chuan Liu <chuan.liu@amlogic.com>
Subject: [PATCH v4 0/8] clk: amlogic: Add A5 SoC PLLs and Peripheral clock
Date: Tue, 28 Oct 2025 17:52:26 +0800
Message-Id: <20251028-a5-clk-v4-0-e62ca0aae243@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAFqSAGkC/1WMQQqDMBBFryJZNyUTo2hXvUfpIo5THaqmJCW0i
 HdvFBS6fJ//3iwCeaYgLtksPEUO7KYE5pQJ7O3UkeQ2sdBKG1UDSFtIHJ4yL9DUFpvcEIh0fnl
 68GcL3e6Jew5v579bN8K67gmzJyJIJQsijeYBjarwasfBdYxndKNYI1EfIoBWh6iTmLgqNVBdQ
 vsvLsvyA9CB407XAAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761645153; l=3354;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=ioK5ZOkw4s9KW/LEkvm0WElrqFYWX7BayiBP0MdRiGo=;
 b=cRSuEim5T63EspU1g2+LpOzydALrYZiEHD7YePKx/x6fZFEcKe8Kxz7OB6JV43dZgm+0QTOxt
 pji4lf70lpKCA2UMsg8tEWBYOW8c9TzZ3g2vh6j60OAlgOc9XkvKkIk
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The patchset adds support for the peripheral and PLL clock controller
on the Amlogic A5 SoC family, such as A113X2.

Due to work arrangements, I will take over this patchset and be
responsible for submitting and maintaining its subsequent revisions.

I previously resubmitted these patches in another patchset [1],
Jerome pointed out that it made tracking more difficult. Therefore,
I’m continuing the submission here based on Xianwei’s v3 version.
Sorry for this causes any inconvenience to anyone.

[1] https://lore.kernel.org/all/20250930-a4_a5_add_clock_driver-v1-0-a9acf7951589@amlogic.com/

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>

---
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
 arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi        |  86 ++
 drivers/clk/meson/Kconfig                          |  27 +
 drivers/clk/meson/Makefile                         |   2 +
 drivers/clk/meson/a5-peripherals.c                 | 883 +++++++++++++++++++++
 drivers/clk/meson/a5-pll.c                         | 476 +++++++++++
 .../clock/amlogic,a5-peripherals-clkc.h            | 132 +++
 include/dt-bindings/clock/amlogic,a5-pll-clkc.h    |  24 +
 include/dt-bindings/clock/amlogic,a5-scmi-clkc.h   |  44 +
 10 files changed, 1871 insertions(+)
---
base-commit: f7d2388eeec24966fc4d5cf32d706f0514f29ac5
change-id: 20240911-a5-clk-35c49acb34e1

Best regards,
-- 
Chuan Liu <chuan.liu@amlogic.com>

