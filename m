From: Jian Hu <jian.hu@amlogic.com>
Date: Mon, 11 May 2026 20:47:29 +0800
Subject: [PATCH 07/10] clk: amlogic: Support POWER_OF_TWO for PLL
 pre-divider
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260511-b4-a9_clk-v1-7-41cb4071b7c9@amlogic.com>
References: <20260511-b4-a9_clk-v1-0-41cb4071b7c9@amlogic.com>
In-Reply-To: <20260511-b4-a9_clk-v1-0-41cb4071b7c9@amlogic.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, Jian Hu <jian.hu@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778503655; l=3404;
 i=jian.hu@amlogic.com; s=20260415; h=from:subject:message-id;
 bh=FRbURImYvA8PQjPZwUxTkKIfvVnFpwlbaEEEXy1Gh6U=;
 b=KrXJyAt4hyF2WeuGjIVZL8f8n3cBg3cWKcxKTvtoIKcHlRcHPl7Rp3QDx/sh3jFUER0XYtN3M
 4SqQC59BIUSAiw9KJ3WB4kh0V7HF7PbIt972ZNfe8nJpWKa2Q0AhLv9
X-Developer-Key: i=jian.hu@amlogic.com; a=ed25519;
 pk=zHUE+rNtH9z+Sb8au1/elWknjFQmy5QDVkBoxleuOIA=
X-Endpoint-Received: by B4 Relay for jian.hu@amlogic.com/20260415 with auth_id=735
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The A9 PLL pre-divider uses a division factor of 2^n to ensure a clock
duty cycle of 50% after predivision.

Add flag 'CLK_MESON_PLL_N_POWER_OF_TWO' to indicate that the PLL
pre-divider division factor is 2^n.

Signed-off-by: Jian Hu <jian.hu@amlogic.com>
---
 drivers/clk/meson/clk-pll.c | 28 +++++++++++++++++++++++-----
 drivers/clk/meson/clk-pll.h |  2 ++
 2 files changed, 25 insertions(+), 5 deletions(-)

diff --git a/drivers/clk/meson/clk-pll.c b/drivers/clk/meson/clk-pll.c
index 8568ad6ba7b6..49483e431d44 100644
--- a/drivers/clk/meson/clk-pll.c
+++ b/drivers/clk/meson/clk-pll.c
@@ -66,6 +66,9 @@ static unsigned long __pll_params_to_rate(unsigned long parent_rate,
 		rate += DIV_ROUND_UP_ULL(frac_rate, frac_max);
 	}
 
+	if (pll->flags & CLK_MESON_PLL_N_POWER_OF_TWO)
+		n = 1 << n;
+
 	return DIV_ROUND_UP_ULL(rate, n);
 }
 
@@ -83,7 +86,7 @@ static unsigned long meson_clk_pll_recalc_rate(struct clk_hw *hw,
 	 * it would result in a division by zero. The rate can't be
 	 * calculated in this case
 	 */
-	if (n == 0)
+	if (n == 0 && !(pll->flags & CLK_MESON_PLL_N_POWER_OF_TWO))
 		return 0;
 
 	m = meson_parm_read(clk->map, &pll->m);
@@ -103,7 +106,12 @@ static unsigned int __pll_params_with_frac(unsigned long rate,
 {
 	unsigned int frac_max = pll->frac_max ? pll->frac_max :
 						(1 << pll->frac.width);
-	u64 val = (u64)rate * n;
+	u64 val;
+
+	if (pll->flags & CLK_MESON_PLL_N_POWER_OF_TWO)
+		n = 1 << n;
+
+	val = (u64)rate * n;
 
 	/* Bail out if we are already over the requested rate */
 	if (rate < parent_rate * m / n)
@@ -142,7 +150,8 @@ static int meson_clk_get_pll_table_index(unsigned int index,
 					 unsigned int *n,
 					 struct meson_clk_pll_data *pll)
 {
-	if (!pll->table[index].n)
+	if (!pll->table[index].n &&
+	    !(pll->flags & CLK_MESON_PLL_N_POWER_OF_TWO))
 		return -EINVAL;
 
 	*m = pll->table[index].m;
@@ -156,7 +165,12 @@ static unsigned int meson_clk_get_pll_range_m(unsigned long rate,
 					      unsigned int n,
 					      struct meson_clk_pll_data *pll)
 {
-	u64 val = (u64)rate * n;
+	u64 val;
+
+	if (pll->flags & CLK_MESON_PLL_N_POWER_OF_TWO)
+		n = 1 << n;
+
+	val = (u64)rate * n;
 
 	if (__pll_round_closest_mult(pll))
 		return DIV_ROUND_CLOSEST_ULL(val, parent_rate);
@@ -173,11 +187,15 @@ static int meson_clk_get_pll_range_index(unsigned long rate,
 {
 	*n = index + 1;
 
+	if ((pll->flags & CLK_MESON_PLL_N_POWER_OF_TWO))
+		*n = index;
+
 	/* Check the predivider range */
 	if (*n >= (1 << pll->n.width))
 		return -EINVAL;
 
-	if (*n == 1) {
+	if ((*n == 1 && !(pll->flags & CLK_MESON_PLL_N_POWER_OF_TWO)) ||
+	    (*n == 0 && (pll->flags & CLK_MESON_PLL_N_POWER_OF_TWO))) {
 		/* Get the boundaries out the way */
 		if (rate <= pll->range->min * parent_rate) {
 			*m = pll->range->min;
diff --git a/drivers/clk/meson/clk-pll.h b/drivers/clk/meson/clk-pll.h
index 1be7e6e77631..60b2772a54c8 100644
--- a/drivers/clk/meson/clk-pll.h
+++ b/drivers/clk/meson/clk-pll.h
@@ -33,6 +33,8 @@ struct pll_mult_range {
 #define CLK_MESON_PLL_L_DETECT_ACTIVE_HIGH	BIT(2)
 /* rst signal is active-low (Power-on reset) */
 #define CLK_MESON_PLL_RST_ACTIVE_LOW	BIT(3)
+/* The division factor of the PLL pre-divider is 2^n */
+#define CLK_MESON_PLL_N_POWER_OF_TWO	BIT(4)
 
 struct meson_clk_pll_data {
 	struct parm en;

-- 
2.47.1

