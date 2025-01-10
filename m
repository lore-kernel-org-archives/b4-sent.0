From: Chuan Liu <chuan.liu@amlogic.com>
Subject: [PATCH 0/2] clk: amlogic: Limit the rate boundaries of clk_hw
Date: Fri, 10 Jan 2025 19:47:09 +0800
Message-Id: <20250110-limit-rate-range-of-clk-v1-0-dd618adc4aa8@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAL0IgWcC/x2MSwqAMAwFr1KyNtAWWsGriAutUYNf2iKCeHejm
 4FheO+GRJEpQaVuiHRy4n0TMYWCMLXbSMi9OFhtnTZG48IrZ4xtJsHX9wHDMqM33vpQdr4PDmR
 9RBr4+p/r5nleLUKm2GkAAAA=
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-amlogic@lists.infradead.org, linux-arm-kernel@lists.infradead.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1736509666; l=1897;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=CQAk7BNs7sCcSti/FzDNut5RqmprsFJZKhzVyPEixDU=;
 b=K/a3PUYWKhuKUwR/mV8m0LWvJiDK+kJ4UGtfSAsu+LGb3ueehwFWJ7GnAvwTTf5lm2umeQD+w
 D3z32mIAdFNBggglBhIP2ZH8UbCXQ6YSwbkdCwNXoahb14mEEDXtE84
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The following figure shows a rough hardware connection block diagram
between "clk_hw" and "clk_consumer". The frequency of the clock is
affected by the following two situations:
1. The hardware limitations of "clk_hw" itself. For instance, the
effective output frequency range of some PLL designs is 3G to 6G.
2. The timing constraints for the electrical "line" between "clk_hw" and
"clk_consumer". Timing constraints are applied to each clock network
within the chip, which limits the maximum frequency of the "line".

   ________             ________________
  |        |   line    |                |
  | clk_hw |-----+---->| clk_consumer 1 |
  |________|     |     |________________|
                 |
		 |            ...
                 |      ________________
		 |     |                |
		 +---->| clk_consumer n |
		       |________________|

The frequency boundaries specified for clk_hw in the patch are the
combined frequency boundaries of "clk_hw" and "line", just like the
frequency boundaries obtained after clk_core_get_boundaries() combines
each clks_node.

The min_rate/max_rate of the clk_hw can be described in a less strict
way as follows:
* min_rate = max("clk_hw", "line");
* max_rate = min("clk_hw", "line");

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
Chuan Liu (2):
      clk: Add initialize the rate boundaries of the clk provider
      clk: amlogic: c3: Limit the rate boundaries of clk_hw

 drivers/clk/clk.c                  |  4 ++--
 drivers/clk/meson/c3-peripherals.c | 21 +++++++++++++++++++++
 drivers/clk/meson/c3-pll.c         |  4 ++++
 include/linux/clk-provider.h       |  4 ++++
 4 files changed, 31 insertions(+), 2 deletions(-)
---
base-commit: 1e1fd26ed4ca05cc1f0e5857918da4dd54967f7d
change-id: 20250110-limit-rate-range-of-clk-61626c7b6dc5

Best regards,
-- 
Chuan Liu <chuan.liu@amlogic.com>

