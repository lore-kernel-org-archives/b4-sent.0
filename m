From: Jian Hu <jian.hu@amlogic.com>
Subject: [PATCH RFC RFT v2 0/3] clk: meson: Refactor PLL pre-divider as a
 divider clock
Date: Thu, 29 Oct 2026 17:30:51 +0800
Message-Id: <20261029-meson_refactor_n-v2-0-ff4ac74e527b@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEsS42oC/3VN3QqCMBR+FTnXLbZjanYVBD6AdBciYx31QNtiC
 ynEd29539XH979ApMAU4ZQtEGjmyN4lgrsMzKTdSILviQNKLGWNubAUvesDDdq8fOidoGrAopY
 HKvISUu2ZPH5vkzdom8tPa5srdAknjqn02d5mtSX+D89KSJHroyGsFCqNZ20ffmSzN95Ct67rF
 zwQkza+AAAA
X-Change-ID: 20260923-meson_refactor_n-e7f25904e536
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, Stephen Boyd <sboyd@kernel.org>, 
 Brian Masney <bmasney+clk@redhat.com>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Jian Hu <jian.hu@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793266267; l=3965;
 i=jian.hu@amlogic.com; s=20260415; h=from:subject:message-id;
 bh=+xz8hM24ZaI8tpLRSfQtNJtwQnB5D4aMVwHyBZ3ov9g=;
 b=zNADH7GFiXTzeR3FlkuLyerMA/cjtZxzMP3X4vmtMB4MI98CrbRZptm66+UdHRaKtW+buP8Wt
 Ti+T/HM8Z7JAv7z0+Z1AGAIQVM71D78R9g7jp21GZGBZV0yv6eRtnac
X-Developer-Key: i=jian.hu@amlogic.com; a=ed25519;
 pk=zHUE+rNtH9z+Sb8au1/elWknjFQmy5QDVkBoxleuOIA=
X-Endpoint-Received: by B4 Relay for jian.hu@amlogic.com/20260415 with auth_id=735
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series refactors the Meson PLL framework to remove the dedicated
PLL pre-divider (N) parameter from the PLL implementation and model it
as a separate divider clock.

Currently, the Meson PLL framework models the PLL pre-divider using a
dedicated n field in struct meson_clk_pll_data. This makes the
pre-divider part of the PLL-specific implementation, although the
Common Clock Framework already provides a generic divider clock.

The pre-divider is not intended to be dynamically adjusted. Each PLL
has a fixed N value as part of its configuration. Most PLLs use N = 1,
while a few special cases use N = 3 to satisfy their PLL input frequency
constraints. Modeling the pre-divider as a separate divider clock
removes PLL-specific handling and simplifies the PLL framework.

The series updates the Amlogic SoC clock drivers to use standalone
pre-divider clocks, with the PLL DCO taking the pre-divider clock as
its parent instead of the input clock directly. It also adds the
required clock IDs.

Some Amlogic PLL pre-dividers read as zero after reset, which
does not produce a usable clock. The existing divider implementation
reports the parent rate for a zero divisor, potentially hiding this
invalid state. In addition, when the requested pre-divider rate equals
the parent rate, the divider must be configured with a divisor of 1.
The zero value read from the register after reset must not prevent the
divider from being configured correctly.

To address these issues, the series introduces
CLK_DIVIDER_INVALID_ZERO, allowing dividers with an invalid zero
value to report a rate of zero instead of incorrectly reporting the
parent rate.

Signed-off-by: Jian Hu <jian.hu@amlogic.com>
---
Changes in v2:
- Add CLK_DIVIDER_INVALID_ZERO.
- Add all SoCs prediv clock index.
- Support table for pll m.
- Fix the `determine` logic: when `best_parent_rate` equals 0,
  recalculate a new `parent_rate`.
- Add all SoCs pll prediv clocks.
- Link to v1: https://lore.kernel.org/r/20260923-meson_refactor_n-v1-0-3a8ce27121a2@amlogic.com

---
Jian Hu (3):
      dt-bindings: clock: amlogic: Add PLL pre-divider clock IDs
      clk: divider: add CLK_DIVIDER_INVALID_ZERO flag
      clk: meson: pll: Remove the dedicated n parameter

 drivers/clk/clk-divider.c                       |   3 +
 drivers/clk/meson/a1-pll.c                      |  69 ++++--
 drivers/clk/meson/axg.c                         | 230 ++++++++++++------
 drivers/clk/meson/c3-pll.c                      |  99 ++++++--
 drivers/clk/meson/clk-pll.c                     | 203 ++++++----------
 drivers/clk/meson/clk-pll.h                     |  17 +-
 drivers/clk/meson/clk-regmap.h                  |   2 +-
 drivers/clk/meson/g12a.c                        | 265 ++++++++++++++++-----
 drivers/clk/meson/gxbb.c                        | 304 ++++++++++++++++--------
 drivers/clk/meson/meson8-ddr.c                  |  39 ++-
 drivers/clk/meson/meson8b.c                     | 238 +++++++++++++------
 drivers/clk/meson/s4-pll.c                      | 128 +++++++---
 drivers/clk/meson/t7-pll.c                      | 186 +++++++++++----
 include/dt-bindings/clock/amlogic,a1-pll-clkc.h |   3 +
 include/dt-bindings/clock/amlogic,c3-pll-clkc.h |   3 +
 include/dt-bindings/clock/amlogic,s4-pll-clkc.h |   4 +
 include/dt-bindings/clock/amlogic,t7-pll-clkc.h |   6 +
 include/dt-bindings/clock/axg-clkc.h            |   5 +
 include/dt-bindings/clock/g12a-clkc.h           |   8 +
 include/dt-bindings/clock/gxbb-clkc.h           |   4 +
 include/dt-bindings/clock/meson8-ddr-clkc.h     |   1 +
 include/dt-bindings/clock/meson8b-clkc.h        |   4 +
 include/linux/clk-provider.h                    |   6 +
 23 files changed, 1271 insertions(+), 556 deletions(-)
---
base-commit: 43e1705ecab981c66baee89041e6f728c0436f19
change-id: 20260923-meson_refactor_n-e7f25904e536

Best regards,
-- 
Jian Hu <jian.hu@amlogic.com>

