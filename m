From: Jia Wang <wangjia@ultrarisc.com>
Subject: [PATCH v2 0/2] clk: ultrarisc: add DP1000 clock support
Date: Wed, 17 Jun 2026 14:02:53 +0800
Message-Id: <20260617-ultrarisc-clock-v2-0-9cb16083e15e@ultrarisc.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAI04MmoC/2WNyw6CMBBFf4XM2pq2CAZX/Idh0Q6DjCI1bSEaw
 r/LI3Hj8iTnnjtBIM8U4JJM4GnkwK5fQB8SwNb0NxJcLwxa6lxmWouhi954Diiwc/gQRtmzMVn
 R5NLCsnp5avi9Fa/VzmGwd8K4Zlaj5RCd/2yXo1q9vZ4r9VcflZBC10VK1p4QVVr+jCO6J1TzP
 H8Bsb5SasQAAAA=
X-Change-ID: 20260522-ultrarisc-clock-a1b7aa59f60b
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-clk@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jia Wang <wangjia@ultrarisc.com>
X-Mailer: b4 0.15-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781676184; l=2055;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=k4Je7gBSERMamWU1GgAynav5HbHuPvN2n+14RP4eS0Q=;
 b=Cl9KmxJ0tjSzJfWFSwgvTlUUAVUGUOPRZW1be1d0yHbmpQowZXpn96mH71aUGlWKNy+z+y/v4
 /LcqAmri7TkARU9x/ug37CGFKhiy19LOCqBnjRpOeoc5eijMZdtBXJS
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=wGVm18siRScehKOkOz0WKxgxDy7IezHEszhnN4/TUCY=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260515 with auth_id=779
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds the devicetree binding and the clock driver for the
UltraRISC DP1000 SoC.

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
Changes in v2:
- Drop the redundant clock-names property from the clock binding.
- Move DP1000_CLK_NUM from the dt-bindings header into the driver.
- Clarify the divider load-bit handling in the common clock core.
- Validate that all advertised clock IDs are populated before registering
  the onecell clock provider.
- Rework divider composite clock registration so the driver builds
  correctly as a module.
- Link to v1: https://patch.msgid.link/20260611-ultrarisc-clock-v1-0-2d93ebb4cc13@ultrarisc.com

---
Jia Wang (2):
      dt-bindings: clock: ultrarisc: Add DP1000 Clock Controller
      clk: ultrarisc: add DP1000 clock driver

 .../bindings/clock/ultrarisc,dp1000-clk.yaml       |  60 +++
 MAINTAINERS                                        |   8 +
 drivers/clk/Kconfig                                |   1 +
 drivers/clk/Makefile                               |   1 +
 drivers/clk/ultrarisc/Kconfig                      |  18 +
 drivers/clk/ultrarisc/Makefile                     |   4 +
 drivers/clk/ultrarisc/clk-dp1000.c                 | 153 +++++++
 drivers/clk/ultrarisc/clk-ultrarisc.c              | 459 +++++++++++++++++++++
 drivers/clk/ultrarisc/clk-ultrarisc.h              |  73 ++++
 include/dt-bindings/clock/ultrarisc,dp1000-clk.h   |  27 ++
 10 files changed, 804 insertions(+)
---
base-commit: b1cbabe84ca1381a004fb91ee1791a1a53bce44e
change-id: 20260522-ultrarisc-clock-a1b7aa59f60b

Best regards,
--  
Jia Wang <wangjia@ultrarisc.com>

