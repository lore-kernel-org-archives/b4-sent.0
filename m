From: Chuan Liu <chuan.liu@amlogic.com>
Subject: [PATCH v6 0/5] clk: amlogic: Add A5 SoC PLLs and Peripheral clock
Date: Fri, 23 Jan 2026 13:54:54 +0800
Message-Id: <20260123-a5-clk-v6-0-6d3bbf0ec1ea@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAC4Nc2kC/2XM3QrCMAyG4VuRHltJsrasHnkf4kHMsln8mWwyF
 Nm9W4VNxMMv5HmfptcuaW/Wi6fpdEh9ai95hOXCyIEvjdpU5W0IyEFEtOytnI628OIiy75wiiY
 /Xzut0/0T2u7yPqT+1naPT3fA93VKuCkxoAXrVUlcjXsoZcPnU9skWUl7Nu/IQDNEJJghZZh3G
 Qg1Bqz+oZugR6Byhi5DDSQMzEqu+Id+ggEQvtBnGDnEWlBrAP6F4zi+AMeM3k1JAQAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769147703; l=3892;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=zHQ4wCU8bGYwasn2b503Clo2bqnsQewMVrK57mvYXGM=;
 b=rLw2OixInyvP6GpRqMjLEO0pWPScYdXXlias5U6jFnZ0M8x6/3iQvZ6SGzvJJKfZeloPaBhtB
 UYtpJtH9qK7D4DyOypRNPByMZoAmm6ithjyi14DvXVS9RqRLfCY5Zse
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The patchset adds support for the peripheral and PLL clock controller
on the Amlogic A5 SoC family, such as A113X2.

To make it easier for the maintainer to manage the patches, the
DTS-related commits have been removed from this version of the
patchset.

For the convenience of the maintainer and reviewers, the DTS patches
have been pushed to github separately for reference [1], [2], [3], and
they will be submitted upstream separately after this patchset is
merged. I hope this does not cause any additional inconvenience.

[1] https://github.com/chuan-aml/linux/commit/edb8fa5e13ca35b37363fe08d8067511613968cd
[2] https://github.com/chuan-aml/linux/commit/c600dadb45f581e200991dd0beacf3575ff971f1
[3] https://github.com/chuan-aml/linux/commit/7d373cf78e22ee767a5232010d0a0568e7228086

Co-developed-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>

---
Changes in v6:
- Use unified macros for sys_clk/axi_clk.
- Remove DTS changes to ease maintainer patch management.
- Link to v5: https://lore.kernel.org/r/20260108-a5-clk-v5-0-9a69fc1ef00a@amlogic.com

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
Chuan Liu (5):
      dt-bindings: clock: Add Amlogic A5 SCMI clock controller support
      dt-bindings: clock: Add Amlogic A5 PLL clock controller
      dt-bindings: clock: Add Amlogic A5 peripherals clock controller
      clk: amlogic: Add A5 PLL clock controller driver
      clk: amlogic: Add A5 clock peripherals controller driver

 .../clock/amlogic,a5-peripherals-clkc.yaml         | 134 ++++
 .../bindings/clock/amlogic,a5-pll-clkc.yaml        |  63 ++
 drivers/clk/meson/Kconfig                          |  27 +
 drivers/clk/meson/Makefile                         |   2 +
 drivers/clk/meson/a5-peripherals.c                 | 781 +++++++++++++++++++++
 drivers/clk/meson/a5-pll.c                         | 478 +++++++++++++
 .../clock/amlogic,a5-peripherals-clkc.h            | 132 ++++
 include/dt-bindings/clock/amlogic,a5-pll-clkc.h    |  24 +
 include/dt-bindings/clock/amlogic,a5-scmi-clkc.h   |  44 ++
 9 files changed, 1685 insertions(+)
---
base-commit: f0b9d8eb98dfee8d00419aa07543bdc2c1a44fb1
change-id: 20240911-a5-clk-35c49acb34e1

Best regards,
-- 
Chuan Liu <chuan.liu@amlogic.com>

