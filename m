From: Chuan Liu <chuan.liu@amlogic.com>
Date: Fri, 06 Sep 2024 13:52:33 +0800
Subject: [PATCH 1/4] clk: meson: Support PLL with fixed fractional
 denominators
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240906-fix_clk-v1-1-2977ef0d72e7@amlogic.com>
References: <20240906-fix_clk-v1-0-2977ef0d72e7@amlogic.com>
In-Reply-To: <20240906-fix_clk-v1-0-2977ef0d72e7@amlogic.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1725601955; l=2567;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=SoIKZiELa8FSJI7fmIZsiz6qIoB6+tJ8z3x3hDJR/OM=;
 b=HYGdsd4TDjl5DW9tu+regMVhcuVnmoqEWuyRRdEK8IXmAPDX+KAM5EnWN+mXPd6AJqh1qj1XV
 DlfZzdykYAXDTgKqia5Qg17K3yaT8fizM93sTUuRayorsD/5VsvJQC+
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some PLLs with fractional multipliers have fractional denominators that
are fixed to "100000" instead of the previous "(1 << pll->frac.width)".

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 drivers/clk/meson/clk-pll.c | 22 +++++++++++++++++++---
 drivers/clk/meson/clk-pll.h |  1 +
 2 files changed, 20 insertions(+), 3 deletions(-)

diff --git a/drivers/clk/meson/clk-pll.c b/drivers/clk/meson/clk-pll.c
index bc570a2ff3a3..f0009c174564 100644
--- a/drivers/clk/meson/clk-pll.c
+++ b/drivers/clk/meson/clk-pll.c
@@ -36,6 +36,12 @@
 #include "clk-regmap.h"
 #include "clk-pll.h"
 
+/*
+ * Some PLLs with fractional multipliers have fractional denominators that
+ * are fixed to "100000" instead of the previous "(1 << pll->frac.width)".
+ */
+#define FIXED_FRAC_MAX			100000
+
 static inline struct meson_clk_pll_data *
 meson_clk_pll_data(struct clk_regmap *clk)
 {
@@ -57,12 +63,17 @@ static unsigned long __pll_params_to_rate(unsigned long parent_rate,
 					  struct meson_clk_pll_data *pll)
 {
 	u64 rate = (u64)parent_rate * m;
+	unsigned int frac_max;
 
 	if (frac && MESON_PARM_APPLICABLE(&pll->frac)) {
 		u64 frac_rate = (u64)parent_rate * frac;
 
-		rate += DIV_ROUND_UP_ULL(frac_rate,
-					 (1 << pll->frac.width));
+		if (pll->flags & CLK_MESON_PLL_FIXED_FRAC_MAX)
+			frac_max = FIXED_FRAC_MAX;
+		else
+			frac_max = (1 << pll->frac.width);
+
+		rate += DIV_ROUND_UP_ULL(frac_rate, frac_max);
 	}
 
 	return DIV_ROUND_UP_ULL(rate, n);
@@ -100,13 +111,18 @@ static unsigned int __pll_params_with_frac(unsigned long rate,
 					   unsigned int n,
 					   struct meson_clk_pll_data *pll)
 {
-	unsigned int frac_max = (1 << pll->frac.width);
+	unsigned int frac_max;
 	u64 val = (u64)rate * n;
 
 	/* Bail out if we are already over the requested rate */
 	if (rate < parent_rate * m / n)
 		return 0;
 
+	if (pll->flags & CLK_MESON_PLL_FIXED_FRAC_MAX)
+		frac_max = FIXED_FRAC_MAX;
+	else
+		frac_max = (1 << pll->frac.width);
+
 	if (pll->flags & CLK_MESON_PLL_ROUND_CLOSEST)
 		val = DIV_ROUND_CLOSEST_ULL(val * frac_max, parent_rate);
 	else
diff --git a/drivers/clk/meson/clk-pll.h b/drivers/clk/meson/clk-pll.h
index 7b6b87274073..e996d3727eb1 100644
--- a/drivers/clk/meson/clk-pll.h
+++ b/drivers/clk/meson/clk-pll.h
@@ -29,6 +29,7 @@ struct pll_mult_range {
 
 #define CLK_MESON_PLL_ROUND_CLOSEST	BIT(0)
 #define CLK_MESON_PLL_NOINIT_ENABLED	BIT(1)
+#define CLK_MESON_PLL_FIXED_FRAC_MAX	BIT(2)
 
 struct meson_clk_pll_data {
 	struct parm en;

-- 
2.42.0

