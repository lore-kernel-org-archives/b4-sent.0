From: Chuan Liu <chuan.liu@amlogic.com>
Date: Fri, 20 Sep 2024 16:16:16 +0800
Subject: [PATCH 6/6] clk: meson: s4: Delete the spinlock from the MPLL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240920-mpll_spinlock-v1-6-5249a9a7e2b7@amlogic.com>
References: <20240920-mpll_spinlock-v1-0-5249a9a7e2b7@amlogic.com>
In-Reply-To: <20240920-mpll_spinlock-v1-0-5249a9a7e2b7@amlogic.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726820174; l=1660;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=kO2S9WluZnKsZu8WbD08FCxRfFkq+Y8JsWEudLTTuJE=;
 b=XoCk+GChXy9oiDtXd6sz8adYDgdcRqK51hXoqH8GCDNNc/qoUkYn7Gv9MKWO5M+QWeYQuOBUM
 L6QxNxGTq4kCsmICSgdLYk2oDQPdZiwAsiVXPVaK4uYGyhXIAE4IDFG
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It is meaningless to define a spinlock in the struct meson_clk_mpll_data.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 drivers/clk/meson/s4-pll.c | 6 ------
 1 file changed, 6 deletions(-)

diff --git a/drivers/clk/meson/s4-pll.c b/drivers/clk/meson/s4-pll.c
index 9697f6577e06..d8e621e79428 100644
--- a/drivers/clk/meson/s4-pll.c
+++ b/drivers/clk/meson/s4-pll.c
@@ -17,8 +17,6 @@
 #include "meson-clkc-utils.h"
 #include <dt-bindings/clock/amlogic,s4-pll-clkc.h>
 
-static DEFINE_SPINLOCK(meson_clk_lock);
-
 /*
  * These clock are a fixed value (fixed_pll is 2GHz) that is initialized by ROMcode.
  * The chip was changed fixed pll for security reasons. Fixed PLL registers are not writable
@@ -547,7 +545,6 @@ static struct clk_regmap s4_mpll0_div = {
 			.shift   = 29,
 			.width	 = 1,
 		},
-		.lock = &meson_clk_lock,
 		.init_regs = s4_mpll0_init_regs,
 		.init_count = ARRAY_SIZE(s4_mpll0_init_regs),
 	},
@@ -601,7 +598,6 @@ static struct clk_regmap s4_mpll1_div = {
 			.shift   = 29,
 			.width	 = 1,
 		},
-		.lock = &meson_clk_lock,
 		.init_regs = s4_mpll1_init_regs,
 		.init_count = ARRAY_SIZE(s4_mpll1_init_regs),
 	},
@@ -655,7 +651,6 @@ static struct clk_regmap s4_mpll2_div = {
 			.shift   = 29,
 			.width	 = 1,
 		},
-		.lock = &meson_clk_lock,
 		.init_regs = s4_mpll2_init_regs,
 		.init_count = ARRAY_SIZE(s4_mpll2_init_regs),
 	},
@@ -709,7 +704,6 @@ static struct clk_regmap s4_mpll3_div = {
 			.shift   = 29,
 			.width	 = 1,
 		},
-		.lock = &meson_clk_lock,
 		.init_regs = s4_mpll3_init_regs,
 		.init_count = ARRAY_SIZE(s4_mpll3_init_regs),
 	},

-- 
2.42.0

