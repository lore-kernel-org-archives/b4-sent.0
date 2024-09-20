From: Chuan Liu <chuan.liu@amlogic.com>
Date: Fri, 20 Sep 2024 16:16:14 +0800
Subject: [PATCH 4/6] clk: meson: gxbb: Delete the spinlock from the MPLL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240920-mpll_spinlock-v1-4-5249a9a7e2b7@amlogic.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726820173; l=1458;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=r/V4f8IDG1LGpMtumtpaJ0LFZXwZ5q/tzNNHh8H7+Ng=;
 b=NtifgucIpJ4Mvxn1mZSWmWBsWYiHyWJUsScY1EzaHpJAZqr8qLzhX8/r5U3bVyAU6Q7KgpmrE
 5Qi+Dq7JQwADH+ieFl7XPqEZ9egM5mtM6IaxvziEggqp0Z8Gfgv2thW
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It is meaningless to define a spinlock in the struct meson_clk_mpll_data.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 drivers/clk/meson/gxbb.c | 6 ------
 1 file changed, 6 deletions(-)

diff --git a/drivers/clk/meson/gxbb.c b/drivers/clk/meson/gxbb.c
index f071faad1ebb..262c318edbd5 100644
--- a/drivers/clk/meson/gxbb.c
+++ b/drivers/clk/meson/gxbb.c
@@ -19,8 +19,6 @@
 
 #include <dt-bindings/clock/gxbb-clkc.h>
 
-static DEFINE_SPINLOCK(meson_clk_lock);
-
 static const struct pll_params_table gxbb_gp0_pll_params_table[] = {
 	PLL_PARAMS(32, 1),
 	PLL_PARAMS(33, 1),
@@ -731,7 +729,6 @@ static struct clk_regmap gxbb_mpll0_div = {
 			.shift   = 16,
 			.width   = 9,
 		},
-		.lock = &meson_clk_lock,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "mpll0_div",
@@ -760,7 +757,6 @@ static struct clk_regmap gxl_mpll0_div = {
 			.shift   = 16,
 			.width   = 9,
 		},
-		.lock = &meson_clk_lock,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "mpll0_div",
@@ -812,7 +808,6 @@ static struct clk_regmap gxbb_mpll1_div = {
 			.shift   = 16,
 			.width   = 9,
 		},
-		.lock = &meson_clk_lock,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "mpll1_div",
@@ -855,7 +850,6 @@ static struct clk_regmap gxbb_mpll2_div = {
 			.shift   = 16,
 			.width   = 9,
 		},
-		.lock = &meson_clk_lock,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "mpll2_div",

-- 
2.42.0

