From: Jia Wang <wangjia@ultrarisc.com>
Subject: [PATCH 0/2] clk: ultrarisc: add DP1000 clock support
Date: Thu, 11 Jun 2026 17:40:52 +0800
Message-Id: <20260611-ultrarisc-clock-v1-0-2d93ebb4cc13@ultrarisc.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKSCKmoC/yXMQQqDQAxA0atI1h0YB1TsVYqLTIwaKyqJloJ4d
 6d2+Rb/H2CswgbP7ADlj5gsc0L+yIAGnHt20iZD8KH0RQhunzZFFSNH00Jvh3msEIu6K32EVK3
 KnXzv46v52/Y4Mm2/DZznBWXabqNzAAAA
X-Change-ID: 20260522-ultrarisc-clock-a1b7aa59f60b
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-clk@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jia Wang <wangjia@ultrarisc.com>
X-Mailer: b4 0.15-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781170862; l=1501;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=R1Q8FrqwKJw9FL7cK9Ek+UiXIxEPBTKq4QR1ZaqiXjE=;
 b=QxWbxOdL58LeJP4aRv2jkyvZGMj/np/LhmSAOWn8iNiLcWmOWSBxK1vWYGvwKqkXPotCINiPW
 myEip9IXSvZBscdqpJmw3JoZHXBFroK20KZqZweK7Sn9QxIZinlkvjR
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=wGVm18siRScehKOkOz0WKxgxDy7IezHEszhnN4/TUCY=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260515 with auth_id=779
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds the devicetree binding and the clock driver for the
UltraRISC DP1000 SoC.

The clock tree is driven by a single SYSPLL and provides fixed-factor
clocks for the subsystem including PCIe, divider-based root clocks for
GMAC and the UART, I2C, and SPI blocks, and per-instance gate clocks
for UART0-3, I2C0-3, and SPI0-1.

Testing:
- dt_binding_check and dtbs_check on ultrarisc,dp1000-clk
- Kernel build for RISC-V and boot-tested on DP1000

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
Jia Wang (2):
      dt-bindings: clock: ultrarisc: Add DP1000 Clock Controller
      clk: ultrarisc: add DP1000 clock driver

 .../bindings/clock/ultrarisc,dp1000-clk.yaml       |  72 ++++
 MAINTAINERS                                        |   8 +
 drivers/clk/Kconfig                                |   1 +
 drivers/clk/Makefile                               |   1 +
 drivers/clk/ultrarisc/Kconfig                      |  18 +
 drivers/clk/ultrarisc/Makefile                     |   4 +
 drivers/clk/ultrarisc/clk-dp1000.c                 | 152 ++++++++
 drivers/clk/ultrarisc/clk-ultrarisc.c              | 417 +++++++++++++++++++++
 drivers/clk/ultrarisc/clk-ultrarisc.h              |  73 ++++
 include/dt-bindings/clock/ultrarisc,dp1000-clk.h   |  29 ++
 10 files changed, 775 insertions(+)
---
base-commit: 2d3090a8aeb596a26935db0955d46c9a5db5c6ce
change-id: 20260522-ultrarisc-clock-a1b7aa59f60b

Best regards,
--  
Jia Wang <wangjia@ultrarisc.com>

