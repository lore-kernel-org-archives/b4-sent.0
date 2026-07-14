From: Jia Wang <wangjia@ultrarisc.com>
Subject: [PATCH v3 0/3] clk: ultrarisc: add DP1000 clock support
Date: Tue, 14 Jul 2026 09:35:06 +0800
Message-Id: <20260714-ultrarisc-clock-v3-0-4b1ccaa26b37@ultrarisc.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEuSVWoC/2XNyw6CMBQE0F8hXVvTh4C48j+Mi/ZykfqgpoVGQ
 /h3W0iMkeUkM2dG4tEZ9OSQjcRhMN7YLga5yQi0qrsgNXXMRDBRsFwIOtx7p5zxQOFu4UYV16V
 SedUUTJO4ejpszGsWT+cl+0FfEfrEpEZrfG/de74MPPUWveB8pQdOGRV1JVHrHQCXx29jC/ZB0
 kMQv0a5NkQ0KtC8YHuJPMd/Y5qmD8BwEIUIAQAA
X-Change-ID: 20260522-ultrarisc-clock-a1b7aa59f60b
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-clk@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jia Wang <wangjia@ultrarisc.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783992908; l=3315;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=1+0h5Czi3945BvDh1x4hHUXcjf/w1aukAvvcGRam85U=;
 b=41r9EoV30RQxk3tELxyntfYSeX23Mx7E4y3Ato3uUdnZdQVvO4oBbfwpGxokZ2qNZJnXHxuuD
 7FdDxEJ9kQvBIvyog5mbMH4DNI8NBMgDTG4UpfvY6Nwpm9SDPjZcB0c
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=wGVm18siRScehKOkOz0WKxgxDy7IezHEszhnN4/TUCY=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260515 with auth_id=779
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series exports a small common clock helper and adds the devicetree
binding and clock driver for the UltraRISC DP1000 SoC.

The clock tree is driven by a SYSPLL and provides fixed-factor clocks for
the subsystem and PCIe, divider-based root clocks for GMAC and the UART,
I2C, and SPI blocks, and per-instance gate clocks for UART0-3, I2C0-3,
and SPI0-1.

Testing:
- dt_binding_check and dtbs_check on ultrarisc,dp1000-clk
- Kernel build for RISC-V and boot-tested on DP1000
- Modules build test for CLK_ULTRARISC_DP1000

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
Changes in v3:
- Add a preparatory clk core patch exporting
  devm_clk_hw_register_composite_pdata().
- Use devm_clk_hw_register_composite_pdata() for DP1000 divider composite
  clock registration.
- Export ultrarisc_clk_probe() in the CLK_ULTRARISC namespace and import it
  from the DP1000 clock driver.
- Drop the local devres composite wrapper and use clk_parent_data for
  divider parents.
- Remove the optional no-gate divider path and model DP1000 dividers as
  divider+gate composites.
- Drop CLK_GET_RATE_NOCACHE from fixed-factor, gate, and divider composite
  registrations where it is not needed.
- Link to v2: https://patch.msgid.link/20260617-ultrarisc-clock-v2-0-9cb16083e15e@ultrarisc.com

Changes in v2:
- Drop the redundant clock-names property from the clock binding.
- Move DP1000_CLK_NUM from the dt-bindings header into the driver.
- Clarify the divider load-bit handling in the common clock core.
- Validate that all advertised clock IDs are populated before registering
  the onecell clock provider.
- Rework divider composite clock registration so the driver builds
  correctly as a module.
- Link to v1: https://patch.msgid.link/20260611-ultrarisc-clock-v1-0-2d93ebb4cc13@ultrarisc.com

To: Michael Turquette <mturquette@baylibre.com>
To: Stephen Boyd <sboyd@kernel.org>
To: Brian Masney <bmasney@redhat.com>
To: Jia Wang <wangjia@ultrarisc.com>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
Cc: linux-clk@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: devicetree@vger.kernel.org

---
Jia Wang (3):
      clk: composite: Export devm composite pdata helper
      dt-bindings: clock: ultrarisc: Add DP1000 Clock Controller
      clk: ultrarisc: Add DP1000 clock driver

 .../bindings/clock/ultrarisc,dp1000-clk.yaml       |  60 +++
 MAINTAINERS                                        |   8 +
 drivers/clk/Kconfig                                |   1 +
 drivers/clk/Makefile                               |   1 +
 drivers/clk/clk-composite.c                        |   1 +
 drivers/clk/ultrarisc/Kconfig                      |  18 +
 drivers/clk/ultrarisc/Makefile                     |   4 +
 drivers/clk/ultrarisc/clk-dp1000.c                 | 154 ++++++++
 drivers/clk/ultrarisc/clk-ultrarisc.c              | 407 +++++++++++++++++++++
 drivers/clk/ultrarisc/clk-ultrarisc.h              |  71 ++++
 include/dt-bindings/clock/ultrarisc,dp1000-clk.h   |  27 ++
 11 files changed, 752 insertions(+)
---
base-commit: a13c140cc289c0b7b3770bce5b3ad42ab35074aa
change-id: 20260522-ultrarisc-clock-a1b7aa59f60b

Best regards,
--  
Jia Wang <wangjia@ultrarisc.com>

