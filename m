From: Chuan Liu <chuan.liu@amlogic.com>
Subject: [PATCH 0/4] clk: meson: Fix an issue with inaccurate hifi_pll
 frequency
Date: Fri, 06 Sep 2024 13:52:32 +0800
Message-Id: <20240906-fix_clk-v1-0-2977ef0d72e7@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKCY2mYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDSwMT3bTMivjknGxdMzOLNPNEw0SjJEMzJaDqgqJUoBTYpOjY2loAryT
 uhFkAAAA=
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1725601955; l=1915;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=g01KSPJoXIPurLe84AcyOHvY7DI2Ak8ynhEFBJfoOtg=;
 b=XOPNho1g4xaPZsvq42GBw4qtdRF1HzWnaEFGPdOhELlSCEJOlNnmLj11KCyoC+vmwCDfw/SzU
 R0GqjapV8XlA3dJXBmuCQcEr9UMihJD+wZRxX8G2C3dd7VdbzhpMB49
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some PLLs with fractional multipliers have fractional denominators that
are fixed to "100000" instead of the previous "(1 << pll->frac.width)".

The hifi_pll for both C3 and S4 supports a fractional multiplier and has
a fixed fractional denominator of "100000".

Here are the results of the C3-based command tests (already defined
CLOCK_ALLOW_WRITE_DEBUGFS):
* echo 491520000 > /sys/kernel/debug/clk/hifi_pll/clk_rate
* cat /sys/kernel/debug/clk/hifi_pll/clk_rate
491520000
* echo 1 > /sys/kernel/debug/clk/hifi_pll/clk_prepare_enable
* cat /sys/kernel/debug/meson-clk-msr/clks/hifi_pll_clk
491515625       +/-15625Hz
* devmem 0xfe008100 32
0xD00304A3
* devmem 0xfe008104 32
0x00014820

Based on the register information read above, it can be obtained:
m = 0xA3 = 0d163;
n = 0x1 = 0d1
frac = 0x14820 = 0d84000
od = 0x3 = 0d3

hifi_pll calculates the output frequency:
calc_rate = xtal_rate / n * (m + (frac / frac_max)) >> od;
calc_rate = 24000000 / 1 * (163 + (84000 / 100000)) >> 3;
calc_rate = 491520000

clk_rate, msr_rate, and calc_rate all match.

The test and calculation results of S4 are consistent with those of C3,
which will not be repeated here.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
Chuan Liu (4):
      clk: meson: Support PLL with fixed fractional denominators
      clk: meson: c3: pll: hifi_pll frequency is not accurate
      clk: meson: s4: pll: hifi_pll support fractional multiplier
      clk: meson: s4: pll: hifi_pll frequency is not accurate

 drivers/clk/meson/c3-pll.c  |  1 +
 drivers/clk/meson/clk-pll.c | 22 +++++++++++++++++++---
 drivers/clk/meson/clk-pll.h |  1 +
 drivers/clk/meson/s4-pll.c  |  9 +++++++--
 4 files changed, 28 insertions(+), 5 deletions(-)
---
base-commit: adac147c6a32e2919cb04555387e12e738991a19
change-id: 20240904-fix_clk-668f7a1a2b16

Best regards,
-- 
Chuan Liu <chuan.liu@amlogic.com>

