From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH v4 0/7] clk: clk-axi-clkgen: improvements and some fixes
Date: Mon, 05 May 2025 17:41:31 +0100
Message-Id: <20250505-dev-axi-clkgen-limits-v4-0-3ad5124e19e1@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIADvqGGgC/33QQWrDMBAF0KsEraMizShW3FXvUbKQRyNnqGMXK
 4iU4LtXCS1pKe7yD/z3Ya4q8yyc1fPmqmYukmUaa3DbjaJjGHvWEmtWYGBnwO515KLDRTQNbz2
 PepCTnLNuMHWGdky471Ttvs+c5HJ3Xw81HyWfp/njPlPs7fottitisdpoaJLnZB3Fll7CGIapf
 6LppG5kgQeDFtcYqIz1GBhCbNDaPww+GGf8GoOVQSSfwFMbm/Yns/16jwP7X92Bwc4ljkC/6od
 lWT4BukOctYgBAAA=
X-Change-ID: 20250218-dev-axi-clkgen-limits-63fb0c5ec38b
To: linux-clk@vger.kernel.org, linux-fpga@vger.kernel.org, 
 dmaengine@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 linux-iio@vger.kernel.org, linux-pwm@vger.kernel.org, 
 linux-spi@vger.kernel.org
Cc: Stephen Boyd <sboyd@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Moritz Fischer <mdf@kernel.org>, Wu Hao <hao.wu@intel.com>, 
 Xu Yilun <yilun.xu@intel.com>, Tom Rix <trix@redhat.com>, 
 Vinod Koul <vkoul@kernel.org>, Jean Delvare <jdelvare@suse.com>, 
 Guenter Roeck <linux@roeck-us.net>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Trevor Gamblin <tgamblin@baylibre.com>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Mark Brown <broonie@kernel.org>, 
 Mike Turquette <mturquette@linaro.org>, Xu Yilun <yilun.xu@linux.intel.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746463295; l=2004;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=UfQERZUmaMDG9Xd7FBgSPsejb+n6JanVqO6qHKkPXWI=;
 b=0lBYprgJYebAK6Horu/uWNWFd6GFkQ2PlVGU3azekb21t7s2fu46YHefFGLmf+R3vr3EO1NTk
 FlsW+6os/PLAa3EvuOgo6vyQW+638w2qt+0t0GIGgVEhUjKWDI1Mr1X
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series starts with a small fix and then a bunch of small
improvements. The main change though is to allow detecting of
struct axi_clkgen_limits during probe().

---
Changes in v4:
- Patch 3:
    * New patch to move the adi-axi-common header. 
- Link to v3: https://lore.kernel.org/r/20250421-dev-axi-clkgen-limits-v3-0-4203b4fed2c9@analog.com

Changes in v3:
- Patch 6:
    * Revert change and parenthesis back on 'if (((params->edge == 0) ^
      (frac_divider == 1))'. While checkpatch complains, it's more
      readable like this and in some configs we might even get -Wparentheses.
- Link to v2: https://lore.kernel.org/r/20250313-dev-axi-clkgen-limits-v2-0-173ae2ad6311@analog.com

Changes in v2:
- Patch 3
   * Rename adi_axi_fgpa_technology -> adi_axi_fpga_technology.

- Link to v1: https://lore.kernel.org/r/20250219-dev-axi-clkgen-limits-v1-0-26f7ef14cd9c@analog.com

---
Nuno Sá (7):
      clk: clk-axi-clkgen: fix fpfd_max frequency for zynq
      clk: clk-axi-clkgen: make sure to include mod_devicetable.h
      include: linux: move adi-axi-common.h out of fpga
      include: fpga: adi-axi-common: add new helper macros
      clk: clk-axi-clkgen: detect axi_clkgen_limits at runtime
      clk: clk-axi-clkgen move to min/max()
      clk: clk-axi-clkgen: fix coding style issues

 drivers/clk/clk-axi-clkgen.c        | 147 +++++++++++++++++++++++++-----------
 drivers/dma/dma-axi-dmac.c          |   2 +-
 drivers/hwmon/axi-fan-control.c     |   2 +-
 drivers/iio/adc/adi-axi-adc.c       |   3 +-
 drivers/iio/dac/adi-axi-dac.c       |   2 +-
 drivers/pwm/pwm-axi-pwmgen.c        |   2 +-
 drivers/spi/spi-axi-spi-engine.c    |   2 +-
 include/linux/adi-axi-common.h      |  58 ++++++++++++++
 include/linux/fpga/adi-axi-common.h |  23 ------
 9 files changed, 169 insertions(+), 72 deletions(-)
---
base-commit: 82f69876ef45ad66c0b114b786c7c6ac0f6a4580
change-id: 20250218-dev-axi-clkgen-limits-63fb0c5ec38b
--

Thanks!
- Nuno Sá

