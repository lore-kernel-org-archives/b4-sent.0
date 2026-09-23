From: Jian Hu <jian.hu@amlogic.com>
Date: Wed, 23 Sep 2026 19:14:47 +0800
Subject: [PATCH RFC 1/3] clk: meson: pll: Remove the dedicated n parameter
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260923-meson_refactor_n-v1-1-3a8ce27121a2@amlogic.com>
References: <20260923-meson_refactor_n-v1-0-3a8ce27121a2@amlogic.com>
In-Reply-To: <20260923-meson_refactor_n-v1-0-3a8ce27121a2@amlogic.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790162143; l=10655;
 i=jian.hu@amlogic.com; s=20260415; h=from:subject:message-id;
 bh=Al+kTQGUTXZOgkSHRDObWL+soFKOeqqmmJSU8iCEL1Q=;
 b=R9TSkGDzTK8pKdr7qVFLHHHARwy72wtcjL5RycccMeus7w3zEiM7oetX/orVfKXeAe+Nak/kN
 PW6QQtTM8bxCFEJ3ZXp0Z9slbADgfvLG8L3t8qd8xYxpOX7BcUniyzU
X-Developer-Key: i=jian.hu@amlogic.com; a=ed25519;
 pk=zHUE+rNtH9z+Sb8au1/elWknjFQmy5QDVkBoxleuOIA=
X-Endpoint-Received: by B4 Relay for jian.hu@amlogic.com/20260415 with auth_id=735
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Meson PLL framework models the PLL pre-divider (N) using a dedicated
field in struct meson_clk_pll_data. Since the common clock framework
already provides a generic divider implementation, there is no need to
keep PLL-specific support for it.

Remove the dedicated n parameter from the framework and simplify the PLL
rate calculation accordingly. The pre-divider will be represented as a
separate divider clock by platform drivers where needed.

Signed-off-by: Jian Hu <jian.hu@amlogic.com>
---
 drivers/clk/meson/clk-pll.c | 178 +++++++++-----------------------------------
 drivers/clk/meson/clk-pll.h |  13 ----
 2 files changed, 34 insertions(+), 157 deletions(-)

diff --git a/drivers/clk/meson/clk-pll.c b/drivers/clk/meson/clk-pll.c
index 1ea6579a760f..de56d55e3b79 100644
--- a/drivers/clk/meson/clk-pll.c
+++ b/drivers/clk/meson/clk-pll.c
@@ -14,7 +14,7 @@
  *        +--------------------------------+
  *        |                                |
  *        |             +--+               |
- *  in >>-----[ /N ]--->|  |      +-----+  |
+ *  in >>----------->|  |      +-----+  |
  *        |             |  |------| DCO |---->> out
  *        |  +--------->|  |      +--v--+  |
  *        |  |          +--+         |     |
@@ -23,7 +23,7 @@
  *        |                                |
  *        +--------------------------------+
  *
- * out = in * (m + frac / frac_max) / n
+ * out = in * (m + frac / frac_max)
  */
 
 #include <linux/clk-provider.h>
@@ -52,8 +52,7 @@ static int __pll_round_closest_mult(struct meson_clk_pll_data *pll)
 }
 
 static unsigned long __pll_params_to_rate(unsigned long parent_rate,
-					  unsigned int m, unsigned int n,
-					  unsigned int frac,
+					  unsigned int m, unsigned int frac,
 					  struct meson_clk_pll_data *pll)
 {
 	u64 rate = (u64)parent_rate * m;
@@ -66,7 +65,7 @@ static unsigned long __pll_params_to_rate(unsigned long parent_rate,
 		rate += DIV_ROUND_UP_ULL(frac_rate, frac_max);
 	}
 
-	return DIV_ROUND_UP_ULL(rate, n);
+	return rate;
 }
 
 static unsigned long meson_clk_pll_recalc_rate(struct clk_hw *hw,
@@ -74,17 +73,7 @@ static unsigned long meson_clk_pll_recalc_rate(struct clk_hw *hw,
 {
 	struct clk_regmap *clk = to_clk_regmap(hw);
 	struct meson_clk_pll_data *pll = meson_clk_pll_data(clk);
-	unsigned int m, n, frac;
-
-	n = meson_parm_read(clk->map, &pll->n);
-
-	/*
-	 * On some HW, N is set to zero on init. This value is invalid as
-	 * it would result in a division by zero. The rate can't be
-	 * calculated in this case
-	 */
-	if (n == 0)
-		return 0;
+	unsigned int m, frac;
 
 	m = meson_parm_read(clk->map, &pll->m);
 
@@ -92,21 +81,20 @@ static unsigned long meson_clk_pll_recalc_rate(struct clk_hw *hw,
 		meson_parm_read(clk->map, &pll->frac) :
 		0;
 
-	return __pll_params_to_rate(parent_rate, m, n, frac, pll);
+	return __pll_params_to_rate(parent_rate, m, frac, pll);
 }
 
 static unsigned int __pll_params_with_frac(unsigned long rate,
 					   unsigned long parent_rate,
 					   unsigned int m,
-					   unsigned int n,
 					   struct meson_clk_pll_data *pll)
 {
 	unsigned int frac_max = pll->frac_max ? pll->frac_max :
 						(1 << pll->frac.width);
-	u64 val = (u64)rate * n;
+	u64 val = (u64)rate;
 
 	/* Bail out if we are already over the requested rate */
-	if (rate < parent_rate * m / n)
+	if (rate < parent_rate * m)
 		return 0;
 
 	if (pll->flags & CLK_MESON_PLL_ROUND_CLOSEST)
@@ -119,145 +107,48 @@ static unsigned int __pll_params_with_frac(unsigned long rate,
 	return min((unsigned int)val, (frac_max - 1));
 }
 
-static bool meson_clk_pll_is_better(unsigned long rate,
-				    unsigned long best,
-				    unsigned long now,
-				    struct meson_clk_pll_data *pll)
-{
-	if (__pll_round_closest_mult(pll)) {
-		/* Round Closest */
-		if (abs(now - rate) < abs(best - rate))
-			return true;
-	} else {
-		/* Round down */
-		if (now <= rate && best < now)
-			return true;
-	}
-
-	return false;
-}
-
-static int meson_clk_get_pll_table_index(unsigned int index,
-					 unsigned int *m,
-					 unsigned int *n,
-					 struct meson_clk_pll_data *pll)
+static int meson_clk_get_pll_multiplier(unsigned long rate,
+					unsigned long parent_rate,
+					unsigned int *m,
+					struct meson_clk_pll_data *pll)
 {
-	if (!pll->table[index].n)
+	if (!pll->range)
 		return -EINVAL;
 
-	*m = pll->table[index].m;
-	*n = pll->table[index].n;
-
-	return 0;
-}
-
-static unsigned int meson_clk_get_pll_range_m(unsigned long rate,
-					      unsigned long parent_rate,
-					      unsigned int n,
-					      struct meson_clk_pll_data *pll)
-{
-	u64 val = (u64)rate * n;
-
-	if (__pll_round_closest_mult(pll))
-		return DIV_ROUND_CLOSEST_ULL(val, parent_rate);
-
-	return div_u64(val,  parent_rate);
-}
-
-static int meson_clk_get_pll_range_index(unsigned long rate,
-					 unsigned long parent_rate,
-					 unsigned int index,
-					 unsigned int *m,
-					 unsigned int *n,
-					 struct meson_clk_pll_data *pll)
-{
-	*n = index + 1;
-
-	/* Check the predivider range */
-	if (*n >= (1 << pll->n.width))
-		return -EINVAL;
-
-	if (*n == 1) {
-		/* Get the boundaries out the way */
-		if (rate <= pll->range->min * parent_rate) {
-			*m = pll->range->min;
-			return -ENODATA;
-		} else if (rate >= pll->range->max * parent_rate) {
-			*m = pll->range->max;
-			return -ENODATA;
-		}
+	if (rate <= pll->range->min * parent_rate) {
+		*m = pll->range->min;
+		return -ENODATA;
+	} else if (rate >= pll->range->max * parent_rate) {
+		*m = pll->range->max;
+		return -ENODATA;
 	}
 
-	*m = meson_clk_get_pll_range_m(rate, parent_rate, *n, pll);
+	if (__pll_round_closest_mult(pll))
+		*m = DIV_ROUND_CLOSEST_ULL(rate, parent_rate);
+	else
+		*m = div_u64(rate, parent_rate);
 
-	/* the pre-divider gives a multiplier too big - stop */
+	/* Multiplier exceeds hardware range */
 	if (*m >= (1 << pll->m.width))
 		return -EINVAL;
 
 	return 0;
 }
 
-static int meson_clk_get_pll_get_index(unsigned long rate,
-				       unsigned long parent_rate,
-				       unsigned int index,
-				       unsigned int *m,
-				       unsigned int *n,
-				       struct meson_clk_pll_data *pll)
-{
-	if (pll->range)
-		return meson_clk_get_pll_range_index(rate, parent_rate,
-						     index, m, n, pll);
-	else if (pll->table)
-		return meson_clk_get_pll_table_index(index, m, n, pll);
-
-	return -EINVAL;
-}
-
-static int meson_clk_get_pll_settings(unsigned long rate,
-				      unsigned long parent_rate,
-				      unsigned int *best_m,
-				      unsigned int *best_n,
-				      struct meson_clk_pll_data *pll)
-{
-	unsigned long best = 0, now = 0;
-	unsigned int i, m, n;
-	int ret;
-
-	for (i = 0, ret = 0; !ret; i++) {
-		ret = meson_clk_get_pll_get_index(rate, parent_rate,
-						  i, &m, &n, pll);
-		if (ret == -EINVAL)
-			break;
-
-		now = __pll_params_to_rate(parent_rate, m, n, 0, pll);
-		if (meson_clk_pll_is_better(rate, best, now, pll)) {
-			best = now;
-			*best_m = m;
-			*best_n = n;
-
-			if (now == rate)
-				break;
-		}
-	}
-
-	return best ? 0 : -EINVAL;
-}
-
 static int meson_clk_pll_determine_rate(struct clk_hw *hw,
 					struct clk_rate_request *req)
 {
 	struct clk_regmap *clk = to_clk_regmap(hw);
 	struct meson_clk_pll_data *pll = meson_clk_pll_data(clk);
-	unsigned int m, n, frac;
+	unsigned int m, frac;
 	unsigned long round;
 	int ret;
 
-	ret = meson_clk_get_pll_settings(req->rate, req->best_parent_rate,
-					 &m, &n, pll);
-	if (ret)
+	ret = meson_clk_get_pll_multiplier(req->rate, req->best_parent_rate, &m, pll);
+	if (ret && ret != -ENODATA)
 		return ret;
 
-	round = __pll_params_to_rate(req->best_parent_rate, m, n, 0, pll);
+	round = __pll_params_to_rate(req->best_parent_rate, m, 0, pll);
 
 	if (!MESON_PARM_APPLICABLE(&pll->frac) || req->rate == round) {
 		req->rate = round;
@@ -268,8 +159,8 @@ static int meson_clk_pll_determine_rate(struct clk_hw *hw,
 	 * The rate provided by the setting is not an exact match, let's
 	 * try to improve the result using the fractional parameter
 	 */
-	frac = __pll_params_with_frac(req->rate, req->best_parent_rate, m, n, pll);
-	req->rate = __pll_params_to_rate(req->best_parent_rate, m, n, frac, pll);
+	frac = __pll_params_with_frac(req->rate, req->best_parent_rate, m, pll);
+	req->rate = __pll_params_to_rate(req->best_parent_rate, m, frac, pll);
 
 	return 0;
 }
@@ -420,7 +311,7 @@ static int meson_clk_pll_set_rate(struct clk_hw *hw, unsigned long rate,
 {
 	struct clk_regmap *clk = to_clk_regmap(hw);
 	struct meson_clk_pll_data *pll = meson_clk_pll_data(clk);
-	unsigned int enabled, m, n, frac = 0;
+	unsigned int enabled, m, frac = 0;
 	unsigned long old_rate;
 	int ret;
 
@@ -429,19 +320,18 @@ static int meson_clk_pll_set_rate(struct clk_hw *hw, unsigned long rate,
 
 	old_rate = clk_hw_get_rate(hw);
 
-	ret = meson_clk_get_pll_settings(rate, parent_rate, &m, &n, pll);
-	if (ret)
+	ret = meson_clk_get_pll_multiplier(rate, parent_rate, &m, pll);
+	if (ret && ret != -ENODATA)
 		return ret;
 
 	enabled = meson_parm_read(clk->map, &pll->en);
 	if (enabled)
 		meson_clk_pll_disable(hw);
 
-	meson_parm_write(clk->map, &pll->n, n);
 	meson_parm_write(clk->map, &pll->m, m);
 
 	if (MESON_PARM_APPLICABLE(&pll->frac)) {
-		frac = __pll_params_with_frac(rate, parent_rate, m, n, pll);
+		frac = __pll_params_with_frac(rate, parent_rate, m, pll);
 		meson_parm_write(clk->map, &pll->frac, frac);
 	}
 
diff --git a/drivers/clk/meson/clk-pll.h b/drivers/clk/meson/clk-pll.h
index 949157fb7bf5..46feee72830f 100644
--- a/drivers/clk/meson/clk-pll.h
+++ b/drivers/clk/meson/clk-pll.h
@@ -11,29 +11,17 @@
 #include <linux/regmap.h>
 #include "parm.h"
 
-struct pll_params_table {
-	unsigned int	m;
-	unsigned int	n;
-};
-
 struct pll_mult_range {
 	unsigned int	min;
 	unsigned int	max;
 };
 
-#define PLL_PARAMS(_m, _n)						\
-	{								\
-		.m		= (_m),					\
-		.n		= (_n),					\
-	}
-
 #define CLK_MESON_PLL_ROUND_CLOSEST	BIT(0)
 #define CLK_MESON_PLL_NOINIT_ENABLED	BIT(1)
 
 struct meson_clk_pll_data {
 	struct parm en;
 	struct parm m;
-	struct parm n;
 	struct parm frac;
 	struct parm l;
 	struct parm rst;
@@ -41,7 +29,6 @@ struct meson_clk_pll_data {
 	struct parm l_detect;
 	const struct reg_sequence *init_regs;
 	unsigned int init_count;
-	const struct pll_params_table *table;
 	const struct pll_mult_range *range;
 	unsigned int frac_max;
 	u8 flags;

-- 
2.47.1

