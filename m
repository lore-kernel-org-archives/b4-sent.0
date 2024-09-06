From: Chuan Liu <chuan.liu@amlogic.com>
Date: Fri, 06 Sep 2024 18:34:41 +0800
Subject: [PATCH v2 2/3] clk: meson: c3: pll: fix frac maximum value for
 hifi_pll
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240906-fix_clk-v2-2-7a3941eb2cdf@amlogic.com>
References: <20240906-fix_clk-v2-0-7a3941eb2cdf@amlogic.com>
In-Reply-To: <20240906-fix_clk-v2-0-7a3941eb2cdf@amlogic.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1725618896; l=770;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=I33Vhd+oqJKtNl4x++Y8xPKvaKodnZowE3DBu//z/PA=;
 b=SADKBH0Q0M4WKvE3kt3/P9oBlUQyRQdTGwUXOIBOYeC1DM1J+oIsLeZanYu9JVZEUNfkwxyeO
 LKUG7LOZoIMBf9/qE6ZBzEJkfCtwZ+SCdrrj54fGqYCVjdoC0hTkw2F
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The fractional denominator of C3's hifi_pll fractional multiplier is
fixed to 100000.

Fixes: 8a9a129dc565 ("clk: meson: c3: add support for the C3 SoC PLL clock")
Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 drivers/clk/meson/c3-pll.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/clk/meson/c3-pll.c b/drivers/clk/meson/c3-pll.c
index 32bd2ed9d304..35fda31a19e2 100644
--- a/drivers/clk/meson/c3-pll.c
+++ b/drivers/clk/meson/c3-pll.c
@@ -361,6 +361,7 @@ static struct clk_regmap hifi_pll_dco = {
 		.range = &c3_gp0_pll_mult_range,
 		.init_regs = c3_hifi_init_regs,
 		.init_count = ARRAY_SIZE(c3_hifi_init_regs),
+		.frac_max = 100000,
 	},
 	.hw.init = &(struct clk_init_data) {
 		.name = "hifi_pll_dco",

-- 
2.42.0

