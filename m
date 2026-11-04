From: Joseph Telaak <joseph@telaak.dev>
Subject: [PATCH 0/4] clk: Add the Siflower SF19A2890 clock manager and
 peripheral clock and reset managers
Date: Wed, 04 Nov 2026 02:20:57 -0500
Message-Id: <20261104-sf19a2890-sysm-v1-0-a4fac07df823@telaak.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANnc6moC/y2N3QqCQBBGX0XmuoWdgUJ7lehif2ZzBK12VBLx3
 d3KywPnO98KyllY4VqtkHkWledQAE8VhNYNDzYSCwNZuiBaMpqwcVQ31uiivXEBkw+eMMYzlNE
 rc5LPL3i7/1kn33EYv5XDyPyeytN4aNu2Azm2mpWHAAAA
X-Change-ID: 20261102-sf19a2890-sysm-ac1fbcb21dd5
To: Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: Chuanhong Guo <gch981213@gmail.com>, Yao Zi <me@ziyao.cc>, 
 linux-mips@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793776865; l=3209;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=0jX11La/VS5MQPtenvFdwlHA+r9r5Mqnpr1EmOgdYCY=;
 b=P7wQLj3jIHJltUhMTiJw74lswKMgKPQUsuM9lzZA9YSlpd+wsscDhrtemQ08qXOdEuNyLzI0Q
 z9s3GD/+oQJDEwpLVuOKwKJ7TH7UuBhFDl/tCYiQHQvrskomv0HnOdo
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Siflower SF19A2890, a MIPS SoC for home routers, has a clock manager
with its PLLs and the muxes and dividers that feed the CPU, the buses
and the peripherals, and for each peripheral block a small clock and
reset manager with its gates, its resets and a bus output enable. This
series adds bindings and drivers for both.

Both drivers are Chuanhong Guo's, from his SF19A2890 branch [1], with
his authorship kept and my changes noted in each. The clock manager's
driver is unchanged apart from fixes. The peripheral managers' binding
is rewritten: Chuanhong's described every block with one compatible and
its bit layout in properties (siflower,valid-gates, siflower,reset-masks
and so on); here each block has its own compatible and the layouts are
tables in the driver. Clock N of a block is its input clock N, gated.

Following Conor's review of Chuanhong's SF21 clock binding, the header
has no count at its end.

The clock manager registers from CLK_OF_DECLARE because the GIC timer
runs from the CPU clock. The SoC support itself (MACH_SIFLOWER_MIPS)
goes through the MIPS tree; until then the drivers build with
COMPILE_TEST.

The MAINTAINERS entry that covers these files comes with the MIPS series
"MIPS: Add support for the Siflower SF19A2890"; this series applies on
its own. That entry is also why checkpatch's question about updating
MAINTAINERS for the new files is left unanswered here.

Tested on a GL.iNet GL-SFT1200: the rates in clk_summary match the
vendor firmware's (CMN PLL 1.5 GHz, buses 300, 300 and 375 MHz, PBUS
100 MHz, UART 125 MHz, GMAC reference 125 MHz, USB PHY reference
50 MHz), and the CPU clock reads 800 MHz, the rate the GIC timer was
checked at against a reference clock with the MIPS series; the console,
DDR and buses survive the unused clock sweep; the UART, SPI NAND, I2C,
GPIO, GMAC, USB and watchdog drivers probe with these clocks and resets;
and the I2C controller works again after an unbind and bind, which
cycles its reset.

[1] https://github.com/981213/linux/commits/siflower-7.1

---
Chuanhong Guo (2):
      clk: siflower: Add SF19A2890 clock manager driver
      clk: siflower: Add SF19A2890 peripheral clock and reset manager driver

Joseph Telaak (2):
      dt-bindings: clock: Add Siflower SF19A2890 clock manager
      dt-bindings: clock: Add Siflower SF19A2890 peripheral clock/reset managers

 .../bindings/clock/siflower,sf19a2890-clk.yaml     |  57 +++
 .../clock/siflower,sf19a2890-periph-crm.yaml       | 169 +++++++++
 drivers/clk/Kconfig                                |   1 +
 drivers/clk/Makefile                               |   1 +
 drivers/clk/siflower/Kconfig                       |  22 ++
 drivers/clk/siflower/Makefile                      |   2 +
 drivers/clk/siflower/clk-sf19a2890-periphcrm.c     | 360 ++++++++++++++++++
 drivers/clk/siflower/clk-sf19a2890.c               | 406 +++++++++++++++++++++
 include/dt-bindings/clock/siflower,sf19a2890-clk.h |  27 ++
 9 files changed, 1045 insertions(+)
---
base-commit: fc1f8f0ceb3b949b58c2f7819976644f5cf84249
change-id: 20261102-sf19a2890-sysm-ac1fbcb21dd5

Best regards,
--  
Joseph Telaak <joseph@telaak.dev>

