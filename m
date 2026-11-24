From: Han Gao <gaohan@iscas.ac.cn>
Date: Wed, 25 Nov 2026 02:41:02 +0800
Subject: [PATCH 1/2] clk: eswin: Fix the EIC7700 PLL post-divider
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-eic7700-cpu-pll-postdiv-v1-1-b1ccd6339a20@iscas.ac.cn>
References: <20261125-eic7700-cpu-pll-postdiv-v1-0-b1ccd6339a20@iscas.ac.cn>
In-Reply-To: <20261125-eic7700-cpu-pll-postdiv-v1-0-b1ccd6339a20@iscas.ac.cn>
To: Yifeng Huang <huangyifeng@eswincomputing.com>, 
 Xuyang Dong <dongxuyang@eswincomputing.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>
Cc: Brian Masney <bmasney@redhat.com>, Han Gao <rabenda.cn@gmail.com>, 
 linux-clk@vger.kernel.org, Han Gao <gaohan@iscas.ac.cn>, 
 Jingkun Zheng <zhengjingkun@iscas.ac.cn>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795545672; l=2174;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=K7CbBbwRL7SATfIfwvhHdIvzguPw8xQ/hwuAz02UZhg=;
 b=J+PHDdEF/5xW9rq1nnIDUZ7SDjsXFHDB8D67iM0bKs856vLcTRGOBdfpNULzyLAhWAm3Cpph8
 WTxVqm9vcJqBj5raZzvbru7qdR4n47uQUf0XTA21SeYHEhOAuXIdz8C
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Both PLL clocks are FOUT1 of their PLL. Per the TRM:

  FOUT1 = FREF * (FBDIV + FRAC / 2^24) /
          (4 * REFDIV * (POSTDIV1_A + 1) * (POSTDIV1_B + 1))

The driver leaves the post-dividers out of its rate math, but
clk_pll_set_rate() sets POSTDIV1_A (bits 10:8) to 1, which halves the
output. It also writes bits 18:16 as "POSTDIV2", which is really
POSTDIV2_A for FOUT2.

On the HiFive Premier P550 the CPU ran at 699 MHz when CPUFreq set
1.4 GHz.

Clear POSTDIV1_A and POSTDIV1_B (bits 14:12) instead, and leave FOUT2
alone.

Fixes: cd44f127c1d4 ("clk: eswin: Add eic7700 clock driver")
Reported-by: Jingkun Zheng <zhengjingkun@iscas.ac.cn>
Link: https://github.com/eswincomputing/EIC7700X-SoC-Technical-Reference-Manual/releases/download/v1.0.0-20250103/EIC7700X_SoC_Technical_Reference_Manual_Part1.pdf
Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 drivers/clk/eswin/clk.c | 9 ++++-----
 1 file changed, 4 insertions(+), 5 deletions(-)

diff --git a/drivers/clk/eswin/clk.c b/drivers/clk/eswin/clk.c
index e8851283ccdbf0ea57002511f991c9d68a7f4788..7d51d3a8fc06d7b4a0d7435aeb0cb0e58e16708e 100644
--- a/drivers/clk/eswin/clk.c
+++ b/drivers/clk/eswin/clk.c
@@ -21,8 +21,8 @@
 #define PLL_REFDIV_MASK		GENMASK(17, 12)
 #define PLL_FBDIV_MASK		GENMASK(31, 20)
 #define PLL_FRAC_MASK		GENMASK(27, 4)
-#define PLL_POSTDIV1_MASK	GENMASK(10, 8)
-#define PLL_POSTDIV2_MASK	GENMASK(18, 16)
+#define PLL_POSTDIV1_A_MASK	GENMASK(10, 8)
+#define PLL_POSTDIV1_B_MASK	GENMASK(14, 12)
 
 struct eswin_clock_data *eswin_clk_init(struct platform_device *pdev,
 					size_t nr_clks)
@@ -110,10 +110,9 @@ static int clk_pll_set_rate(struct clk_hw *hw, unsigned long rate,
 	val |= FIELD_PREP(PLL_FRAC_MASK, frac_val);
 	writel_relaxed(val, clk->ctrl_reg1);
 
+	/* eswin_calc_pll() assumes FOUT1 is not post-divided */
 	val = readl_relaxed(clk->ctrl_reg2);
-	val &= ~(PLL_POSTDIV1_MASK | PLL_POSTDIV2_MASK);
-	val |= FIELD_PREP(PLL_POSTDIV1_MASK, 1);
-	val |= FIELD_PREP(PLL_POSTDIV2_MASK, 1);
+	val &= ~(PLL_POSTDIV1_A_MASK | PLL_POSTDIV1_B_MASK);
 	writel_relaxed(val, clk->ctrl_reg2);
 
 	/* Last, enable pll */

-- 
2.47.3

