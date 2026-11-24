From: Han Gao <gaohan@iscas.ac.cn>
Date: Wed, 25 Nov 2026 02:41:03 +0800
Subject: [PATCH 2/2] clk: eswin: Use REFDIV and the post-dividers in the
 EIC7700 PLL rate
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-eic7700-cpu-pll-postdiv-v1-2-b1ccd6339a20@iscas.ac.cn>
References: <20261125-eic7700-cpu-pll-postdiv-v1-0-b1ccd6339a20@iscas.ac.cn>
In-Reply-To: <20261125-eic7700-cpu-pll-postdiv-v1-0-b1ccd6339a20@iscas.ac.cn>
To: Yifeng Huang <huangyifeng@eswincomputing.com>, 
 Xuyang Dong <dongxuyang@eswincomputing.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>
Cc: Brian Masney <bmasney@redhat.com>, Han Gao <rabenda.cn@gmail.com>, 
 linux-clk@vger.kernel.org, Han Gao <gaohan@iscas.ac.cn>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795545672; l=1923;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=VrFwb4LbqjLwL5yeuV+0FMqYdBlAoZkY2EyJTM77sGc=;
 b=FUIU6DX3ikNkr3SZtTgnF9zNyVsAD9fsSMms6uKh5HiiO/NmSqaknVac+uS4onmZ/RLkJ87yn
 FMhBGdezhVXCG0KvDeHTdiJNWuR/V21IFz/sdJIJHsn9lXb64lkRzOn
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

clk_pll_recalc_rate() ignores REFDIV and the FOUT1 post-dividers, so
it reports the wrong rate if firmware set them. Use the full formula
from the TRM.

Link: https://github.com/eswincomputing/EIC7700X-SoC-Technical-Reference-Manual/releases/download/v1.0.0-20250103/EIC7700X_SoC_Technical_Reference_Manual_Part1.pdf
Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 drivers/clk/eswin/clk.c | 17 ++++++++++++++---
 1 file changed, 14 insertions(+), 3 deletions(-)

diff --git a/drivers/clk/eswin/clk.c b/drivers/clk/eswin/clk.c
index 7d51d3a8fc06d7b4a0d7435aeb0cb0e58e16708e..51d816c6d19b8a22045b147a863b39c9f3c9a7f1 100644
--- a/drivers/clk/eswin/clk.c
+++ b/drivers/clk/eswin/clk.c
@@ -135,9 +135,10 @@ static unsigned long clk_pll_recalc_rate(struct clk_hw *hw,
 {
 	struct eswin_clk_pll *clk = to_pll_clk(hw);
 	u64 fbdiv_val, frac_val, tmp;
-	u32 rem, val;
+	u32 refdiv, postdiv_a, postdiv_b, rem, val;
 
 	val = readl_relaxed(clk->ctrl_reg0);
+	refdiv = FIELD_GET(PLL_REFDIV_MASK, val);
 	val &= PLL_FBDIV_MASK;
 	fbdiv_val = (val >> clk->fbdiv_shift);
 
@@ -145,7 +146,17 @@ static unsigned long clk_pll_recalc_rate(struct clk_hw *hw,
 	val &= PLL_FRAC_MASK;
 	frac_val = (val >> clk->frac_shift);
 
-	/* rate = 24000000 * (fbdiv + frac / (2 ^ 24)) / 4 */
+	val = readl_relaxed(clk->ctrl_reg2);
+	postdiv_a = FIELD_GET(PLL_POSTDIV1_A_MASK, val);
+	postdiv_b = FIELD_GET(PLL_POSTDIV1_B_MASK, val);
+
+	if (!refdiv)
+		return 0;
+
+	/*
+	 * rate = parent_rate * (fbdiv + frac / 2^24) /
+	 *	  (4 * refdiv * (postdiv_a + 1) * (postdiv_b + 1))
+	 */
 	tmp = parent_rate * frac_val;
 	rem = do_div(tmp, BIT(24));
 	if (rem)
@@ -153,7 +164,7 @@ static unsigned long clk_pll_recalc_rate(struct clk_hw *hw,
 	else
 		tmp = parent_rate * fbdiv_val + tmp;
 
-	do_div(tmp, 4);
+	do_div(tmp, 4 * refdiv * (postdiv_a + 1) * (postdiv_b + 1));
 
 	return tmp;
 }

-- 
2.47.3

