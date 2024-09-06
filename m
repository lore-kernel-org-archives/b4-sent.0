From: Chuan Liu <chuan.liu@amlogic.com>
Subject: [PATCH v2 0/3] clk: meson: Fix an issue with inaccurate hifi_pll
 frequency
Date: Fri, 06 Sep 2024 18:34:39 +0800
Message-Id: <20240906-fix_clk-v2-0-7a3941eb2cdf@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAL/a2mYC/z3MQQrCMBCF4auUWRtJhpJYV95DisR00g62TUmkK
 CV3NxZ0+c88vg0SRaYE52qDSCsnDnMJPFTgBjv3JLgrDSixlo2shefXzY0PofXJG6ss3pWGsl4
 ildcuXdvSA6dniO8dXtX3+jP031iVkAIbY8jLziCZi53G0LM7ujBBm3P+ALL78/ugAAAA
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1725618896; l=2030;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=7v54Zyw0i0C7dV0JkDzLhWAWLm9ZlK6RJGxHS8FL/Mo=;
 b=edTobeBEWT7l5dp1KG9XBG20u88x9MHA5yUkCW5VI+uHjOQNbuVboAoWqLOhYqX6RvsOilHm9
 HXorFqcrXw3B/6ASQW/BrWaJqJgVvTW+QHvSQGQrFADat7+1Bnw9rsd
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some PLLS with fractional multipliers have fractional denominators with
fixed values, instead of the previous "(1 << pll-> frc.width)".

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
Changes in v2:
- Added frac_max to the pll parameter instead of flag.
- frac_max is added to hifi_pll for C3 and S4.
- Link to v1: https://lore.kernel.org/r/20240906-fix_clk-v1-0-2977ef0d72e7@amlogic.com

---
Chuan Liu (3):
      clk: meson: Support PLL with fixed fractional denominators
      clk: meson: c3: pll: fix frac maximum value for hifi_pll
      clk: meson: s4: pll: fix frac maximum value for hifi_pll

 drivers/clk/meson/c3-pll.c  | 1 +
 drivers/clk/meson/clk-pll.c | 8 +++++---
 drivers/clk/meson/clk-pll.h | 1 +
 drivers/clk/meson/s4-pll.c  | 1 +
 4 files changed, 8 insertions(+), 3 deletions(-)
---
base-commit: 80344f4c1a1edec507a20adca476af84ea58cd4c
change-id: 20240904-fix_clk-668f7a1a2b16

Best regards,
-- 
Chuan Liu <chuan.liu@amlogic.com>

