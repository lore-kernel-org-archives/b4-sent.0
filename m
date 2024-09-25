From: Chuan Liu <chuan.liu@amlogic.com>
Date: Wed, 25 Sep 2024 18:08:28 +0800
Subject: [PATCH v2] clk: meson: mpll: Delete a useless spinlock from the
 MPLL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240925-mpll_spinlock-v2-1-8f9b73588ec1@amlogic.com>
X-B4-Tracking: v=1; b=H4sIABvh82YC/13MSwrDIBSF4a2EO67FiJLaUfcRQlFjkkt9BC3SE
 rL32tBRh/+B822QbUKb4dpskGzBjDHUYKcGzKLCbAmOtYFRxqlsL8Svzt3zisFF8yBcSy2E4Xw
 aBdTPmuyEr8Prh9oL5mdM74Mv7Xf9SYz+SaUllAjGpZKqs0x3N+VdnNGcTfQw7Pv+AQaGveasA
 AAA
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727258930; l=8347;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=ZyPnj+RyKrSajBhQmyfJU1szWyHwl1WcQqsqZnpTU7o=;
 b=U/+tnxrfGff37ZUf7sYlp/cNh53Yt2f8WNnAnhJ4kn7XfzEjnQhjRRCLExzt4S4f2YPnJf5bH
 NG1ejpqmzuEDkAaX4lW5Dd2Via7P1aOkswd4UDgyix31p4VpDTuFPsl
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The register corresponding to MPLL does not share the same register
with other module drivers, so there is no concurrent access to the
register with other modules drivers. The spinlock defined in struct
meson_clk_mpll_data is no longer useful.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
Changes in v2:
- Squeeze into a patch.
- Modifying commit Information.
- Link to v1: https://lore.kernel.org/r/20240920-mpll_spinlock-v1-0-5249a9a7e2b7@amlogic.com
---
 drivers/clk/meson/axg.c      |  6 ------
 drivers/clk/meson/clk-mpll.c | 11 -----------
 drivers/clk/meson/clk-mpll.h |  1 -
 drivers/clk/meson/g12a.c     |  6 ------
 drivers/clk/meson/gxbb.c     |  6 ------
 drivers/clk/meson/meson8b.c  |  3 ---
 drivers/clk/meson/s4-pll.c   |  6 ------
 7 files changed, 39 deletions(-)

diff --git a/drivers/clk/meson/axg.c b/drivers/clk/meson/axg.c
index 757c7a28c53d..1b08daf579b2 100644
--- a/drivers/clk/meson/axg.c
+++ b/drivers/clk/meson/axg.c
@@ -23,8 +23,6 @@
 
 #include <dt-bindings/clock/axg-clkc.h>
 
-static DEFINE_SPINLOCK(meson_clk_lock);
-
 static struct clk_regmap axg_fixed_pll_dco = {
 	.data = &(struct meson_clk_pll_data){
 		.en = {
@@ -506,7 +504,6 @@ static struct clk_regmap axg_mpll0_div = {
 			.shift   = 0,
 			.width	 = 1,
 		},
-		.lock = &meson_clk_lock,
 		.flags = CLK_MESON_MPLL_ROUND_CLOSEST,
 	},
 	.hw.init = &(struct clk_init_data){
@@ -557,7 +554,6 @@ static struct clk_regmap axg_mpll1_div = {
 			.shift   = 1,
 			.width	 = 1,
 		},
-		.lock = &meson_clk_lock,
 		.flags = CLK_MESON_MPLL_ROUND_CLOSEST,
 	},
 	.hw.init = &(struct clk_init_data){
@@ -613,7 +609,6 @@ static struct clk_regmap axg_mpll2_div = {
 			.shift   = 2,
 			.width	 = 1,
 		},
-		.lock = &meson_clk_lock,
 		.flags = CLK_MESON_MPLL_ROUND_CLOSEST,
 	},
 	.hw.init = &(struct clk_init_data){
@@ -664,7 +659,6 @@ static struct clk_regmap axg_mpll3_div = {
 			.shift   = 3,
 			.width	 = 1,
 		},
-		.lock = &meson_clk_lock,
 		.flags = CLK_MESON_MPLL_ROUND_CLOSEST,
 	},
 	.hw.init = &(struct clk_init_data){
diff --git a/drivers/clk/meson/clk-mpll.c b/drivers/clk/meson/clk-mpll.c
index f639d56f0fd3..aa9abd06ae65 100644
--- a/drivers/clk/meson/clk-mpll.c
+++ b/drivers/clk/meson/clk-mpll.c
@@ -112,26 +112,15 @@ static int mpll_set_rate(struct clk_hw *hw,
 	struct clk_regmap *clk = to_clk_regmap(hw);
 	struct meson_clk_mpll_data *mpll = meson_clk_mpll_data(clk);
 	unsigned int sdm, n2;
-	unsigned long flags = 0;
 
 	params_from_rate(rate, parent_rate, &sdm, &n2, mpll->flags);
 
-	if (mpll->lock)
-		spin_lock_irqsave(mpll->lock, flags);
-	else
-		__acquire(mpll->lock);
-
 	/* Set the fractional part */
 	meson_parm_write(clk->map, &mpll->sdm, sdm);
 
 	/* Set the integer divider part */
 	meson_parm_write(clk->map, &mpll->n2, n2);
 
-	if (mpll->lock)
-		spin_unlock_irqrestore(mpll->lock, flags);
-	else
-		__release(mpll->lock);
-
 	return 0;
 }
 
diff --git a/drivers/clk/meson/clk-mpll.h b/drivers/clk/meson/clk-mpll.h
index a991d568c43a..4ffd3aeef799 100644
--- a/drivers/clk/meson/clk-mpll.h
+++ b/drivers/clk/meson/clk-mpll.h
@@ -20,7 +20,6 @@ struct meson_clk_mpll_data {
 	struct parm misc;
 	const struct reg_sequence *init_regs;
 	unsigned int init_count;
-	spinlock_t *lock;
 	u8 flags;
 };
 
diff --git a/drivers/clk/meson/g12a.c b/drivers/clk/meson/g12a.c
index 02dda57105b1..d3539fe9f7af 100644
--- a/drivers/clk/meson/g12a.c
+++ b/drivers/clk/meson/g12a.c
@@ -28,8 +28,6 @@
 
 #include <dt-bindings/clock/g12a-clkc.h>
 
-static DEFINE_SPINLOCK(meson_clk_lock);
-
 static struct clk_regmap g12a_fixed_pll_dco = {
 	.data = &(struct meson_clk_pll_data){
 		.en = {
@@ -2225,7 +2223,6 @@ static struct clk_regmap g12a_mpll0_div = {
 			.shift   = 29,
 			.width	 = 1,
 		},
-		.lock = &meson_clk_lock,
 		.init_regs = g12a_mpll0_init_regs,
 		.init_count = ARRAY_SIZE(g12a_mpll0_init_regs),
 	},
@@ -2279,7 +2276,6 @@ static struct clk_regmap g12a_mpll1_div = {
 			.shift   = 29,
 			.width	 = 1,
 		},
-		.lock = &meson_clk_lock,
 		.init_regs = g12a_mpll1_init_regs,
 		.init_count = ARRAY_SIZE(g12a_mpll1_init_regs),
 	},
@@ -2333,7 +2329,6 @@ static struct clk_regmap g12a_mpll2_div = {
 			.shift   = 29,
 			.width	 = 1,
 		},
-		.lock = &meson_clk_lock,
 		.init_regs = g12a_mpll2_init_regs,
 		.init_count = ARRAY_SIZE(g12a_mpll2_init_regs),
 	},
@@ -2387,7 +2382,6 @@ static struct clk_regmap g12a_mpll3_div = {
 			.shift   = 29,
 			.width	 = 1,
 		},
-		.lock = &meson_clk_lock,
 		.init_regs = g12a_mpll3_init_regs,
 		.init_count = ARRAY_SIZE(g12a_mpll3_init_regs),
 	},
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
diff --git a/drivers/clk/meson/meson8b.c b/drivers/clk/meson/meson8b.c
index b7417ac262d3..5011768c0f4e 100644
--- a/drivers/clk/meson/meson8b.c
+++ b/drivers/clk/meson/meson8b.c
@@ -492,7 +492,6 @@ static struct clk_regmap meson8b_mpll0_div = {
 			.shift   = 25,
 			.width   = 1,
 		},
-		.lock = &meson_clk_lock,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "mpll0_div",
@@ -537,7 +536,6 @@ static struct clk_regmap meson8b_mpll1_div = {
 			.shift   = 16,
 			.width   = 9,
 		},
-		.lock = &meson_clk_lock,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "mpll1_div",
@@ -582,7 +580,6 @@ static struct clk_regmap meson8b_mpll2_div = {
 			.shift   = 16,
 			.width   = 9,
 		},
-		.lock = &meson_clk_lock,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "mpll2_div",
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

---
base-commit: 0ef513560b53d499c824b77220c537eafe1df90d
change-id: 20240918-mpll_spinlock-4b9b55c44fd5

Best regards,
-- 
Chuan Liu <chuan.liu@amlogic.com>

