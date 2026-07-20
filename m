From: Jia Wang <wangjia@ultrarisc.com>
Subject: [PATCH v4 0/3] clk: ultrarisc: add DP1000 clock support
Date: Mon, 20 Jul 2026 08:38:03 +0800
Message-Id: <20260720-ultrarisc-clock-v4-0-fe639d63bbac@ultrarisc.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOttXWoC/23NQQ6CMBQE0KuQrq3pb6GIK+9hXLSfr1ZRTAtEQ
 7i7RRI14nKSmTc9C+QdBbZOeuapc8HV1xjSRcLwaK4H4q6MmUkhtcik5G3VeONdQI5VjWduwOb
 GZMVeC8vi6uZp7+4vcbubcmjtibAZmbFxdKGp/eN12cHYm3QNMNM74ILLslBkbYoIavNuLLG+s
 PGhk99GPjdkNAq0oMVKEWT0z1AfI4d0bqhopBYQjZHaqvzXGIbhCcdSYq5MAQAA
X-Change-ID: 20260522-ultrarisc-clock-a1b7aa59f60b
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-clk@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jia Wang <wangjia@ultrarisc.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784507902; l=3527;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=kj8HP71mEfWIL2iv8ejHqIAfFKBllPg7LGkcLea/LOc=;
 b=W6Yi9IKwL9P1T0rPkJZCfj1DhuWwKURZsvr8YBq9WTRL6UkpAe777e/+TfZXJ7/9iKaHXB7vr
 6bpFASQQZIGBTicMC5gBypX95gu6s4OZ1YdoNj6a13eOXkoUnfgQSoq
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
Changes in v4:
- Drop the initial clk_hw_get_rate() max-rate warning after setting the
  divider rate range.
- Link to v3: https://patch.msgid.link/20260714-ultrarisc-clock-v3-0-4b1ccaa26b37@ultrarisc.com

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

 .../bindings/clock/ultrarisc,dp1000-clk.yaml       |  60 ++++
 MAINTAINERS                                        |   8 +
 drivers/clk/Kconfig                                |   1 +
 drivers/clk/Makefile                               |   1 +
 drivers/clk/clk-composite.c                        |   1 +
 drivers/clk/ultrarisc/Kconfig                      |  18 +
 drivers/clk/ultrarisc/Makefile                     |   4 +
 drivers/clk/ultrarisc/clk-dp1000.c                 | 154 ++++++++
 drivers/clk/ultrarisc/clk-ultrarisc.c              | 399 +++++++++++++++++++++
 drivers/clk/ultrarisc/clk-ultrarisc.h              |  71 ++++
 include/dt-bindings/clock/ultrarisc,dp1000-clk.h   |  27 ++
 11 files changed, 744 insertions(+)
---
base-commit: a13c140cc289c0b7b3770bce5b3ad42ab35074aa
change-id: 20260522-ultrarisc-clock-a1b7aa59f60b

Best regards,
--  
Jia Wang <wangjia@ultrarisc.com>

