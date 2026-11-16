From: Joseph Telaak <joseph@telaak.dev>
Subject: [PATCH v3 0/4] clk: Add the Siflower SF19A2890 clock manager and
 peripheral clock and reset managers
Date: Mon, 16 Nov 2026 17:04:46 -0500
Message-Id: <20261116-sf19a2890-sysm-v3-0-b07bc7833a87@telaak.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAP59+2oC/2WOSQ7CMAxFr4KyJih2CwVW3AOxSBOHhpm4jahQ7
 07KIKbls/7731fBFDyxmA+uIlD07I+HBNlwIEylD2uS3iYWqHACoFCyg5nG6UxJbnkvtQFXmhL
 B2rFI0imQ85d74XL1YG7KDZm6b3kmAp2btFS/Y5Xn+hja+xsR+utrMf9djCCV1LnTRhXWTTFb1
 LTTejuyFEXfFfHDB/jzMfkWnSkLzCh38OV3XXcDf8V9gBQBAAA=
X-Change-ID: 20261102-sf19a2890-sysm-ac1fbcb21dd5
To: Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: Chuanhong Guo <gch981213@gmail.com>, Yao Zi <me@ziyao.cc>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@baylibre.com>, 
 linux-mips@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Conor Dooley <conor.dooley@microchip.com>, 
 Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794866701; l=4774;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=lj+d99xoFwkdyN2+RnvfppViMpO8GlW8yclhuqv6J6I=;
 b=63QImwQ1uC8d3XutETgwiR66VqeySik1W+fW3phzPCG4D9Hk0TSkvRLSBDHKvlL+RM6StiF+D
 mC8qobbjblTCIZEwdEvx4kdVEpnIRJbAxIWyx0Uafxbidik/4Eg0TAG
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
Changes in v3:
- Patches 1 and 2: name the NPU clock CLK_MUXDIV_NPU_PE, without the _CLK
  suffix that no other clock has (Brian).
- Patch 3: add Conor's Ack.
- Patch 4: take the spinlock with guard(spinlock_irqsave) (Philipp).
- Patch 4: explain each multi-bit reset group in the commit message, not
  just the GMAC's (Philipp).
- Patch 4: add Philipp's Reviewed-by.
- Link to v2: https://patch.msgid.link/20261111-sf19a2890-sysm-v2-0-d2fcb723e4f1@telaak.dev

Changes in v2:
- Write my notes on Chuanhong's patches as lists, with Co-developed-by.
- Use GPL-2.0-only, not the deprecated GPL-2.0 identifier, in the clock
  header's SPDX line.
- Add a MAINTAINERS entry for the drivers, their bindings and the
  headers, with an F: line per driver, since drivers/clk/siflower/ will
  also hold the SF21 drivers.
- Include <linux/device-id/of.h> instead of <linux/mod_devicetable.h>
  (Uwe).
- Word the error messages the same way, and use the current SPDX
  identifiers in the new files.
- Explain in the commit message why some resets cover more than one bit
  (Philipp, Chuanhong).
- Patch 1: add Conor's Ack.
- Patch 2: with the PLL's fractional modulator on, scale the fraction by
  the reference rate, not by the integer VCO rate; and reject a rate of 0
  in the mux dividers instead of dividing by it.
- Patch 3: add include/dt-bindings/clock/siflower,sf19a2890-periph-crm.h,
  naming the clocks and resets of each manager, instead of listing the
  resets in the description; patch 4 indexes its tables by it (Conor).
- Patch 4: no comma after the match table's sentinel (Uwe).
- Link to v1: https://patch.msgid.link/20261104-sf19a2890-sysm-v1-0-a4fac07df823@telaak.dev

---
Chuanhong Guo (2):
      clk: siflower: Add SF19A2890 clock manager driver
      clk: siflower: Add SF19A2890 peripheral clock and reset manager driver

Joseph Telaak (2):
      dt-bindings: clock: Add Siflower SF19A2890 clock manager
      dt-bindings: clock: Add Siflower SF19A2890 peripheral clock/reset managers

 .../bindings/clock/siflower,sf19a2890-clk.yaml     |  57 +++
 .../clock/siflower,sf19a2890-periph-crm.yaml       | 166 ++++++++
 MAINTAINERS                                        |  11 +
 drivers/clk/Kconfig                                |   1 +
 drivers/clk/Makefile                               |   1 +
 drivers/clk/siflower/Kconfig                       |  22 ++
 drivers/clk/siflower/Makefile                      |   3 +
 drivers/clk/siflower/clk-sf19a2890-periphcrm.c     | 362 ++++++++++++++++++
 drivers/clk/siflower/clk-sf19a2890.c               | 419 +++++++++++++++++++++
 include/dt-bindings/clock/siflower,sf19a2890-clk.h |  27 ++
 .../clock/siflower,sf19a2890-periph-crm.h          |  87 +++++
 11 files changed, 1156 insertions(+)
---
base-commit: fc1f8f0ceb3b949b58c2f7819976644f5cf84249
change-id: 20261102-sf19a2890-sysm-ac1fbcb21dd5

Best regards,
--  
Joseph Telaak <joseph@telaak.dev>

