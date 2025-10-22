From: Chuan Liu <chuan.liu@amlogic.com>
Date: Wed, 22 Oct 2025 14:58:53 +0800
Subject: [PATCH 3/3] clk: amlogic: Correct l_detect bit control
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251022-optimize_pll_driver-v1-3-a275722fb6f4@amlogic.com>
References: <20251022-optimize_pll_driver-v1-0-a275722fb6f4@amlogic.com>
In-Reply-To: <20251022-optimize_pll_driver-v1-0-a275722fb6f4@amlogic.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761116340; l=2616;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=Dv3cPzZdf9Puk7bgGlGkCfNCiEdGxmv1X3Nj/+D8POg=;
 b=BHhN2TDgNFvv/uGPJJpyLvmLNfv+ZEmzL2S9sXilJFfhJvBFD6R+79Z2raY7XQiQGmLbIXNag
 V96WVa094xKBAJKEsbT4Kw52S5AzhIJN0wziJopr6yAfXB1pIQvlO+K
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

l_detect controls the enable/disable of the PLL lock-detect module.

For A1, the l_detect signal is active-low:
0 -> Enable lock-detect module;
1 -> Disable lock-detect module.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 drivers/clk/meson/a1-pll.c  |  1 +
 drivers/clk/meson/clk-pll.c | 16 ++++++++++++----
 drivers/clk/meson/clk-pll.h |  2 ++
 3 files changed, 15 insertions(+), 4 deletions(-)

diff --git a/drivers/clk/meson/a1-pll.c b/drivers/clk/meson/a1-pll.c
index 1f82e9c7c14e..bfe559c71402 100644
--- a/drivers/clk/meson/a1-pll.c
+++ b/drivers/clk/meson/a1-pll.c
@@ -137,6 +137,7 @@ static struct clk_regmap a1_hifi_pll = {
 		.range = &a1_hifi_pll_range,
 		.init_regs = a1_hifi_pll_init_regs,
 		.init_count = ARRAY_SIZE(a1_hifi_pll_init_regs),
+		.flags = CLK_MESON_PLL_L_DETECT_N
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "hifi_pll",
diff --git a/drivers/clk/meson/clk-pll.c b/drivers/clk/meson/clk-pll.c
index 26c83db487e8..602c93aba3cc 100644
--- a/drivers/clk/meson/clk-pll.c
+++ b/drivers/clk/meson/clk-pll.c
@@ -384,8 +384,12 @@ static int meson_clk_pll_enable(struct clk_hw *hw)
 		meson_parm_write(clk->map, &pll->rst, 1);
 
 	/* Disable the PLL lock-detect module */
-	if (MESON_PARM_APPLICABLE(&pll->l_detect))
-		meson_parm_write(clk->map, &pll->l_detect, 1);
+	if (MESON_PARM_APPLICABLE(&pll->l_detect)) {
+		if (pll->flags & CLK_MESON_PLL_L_DETECT_N)
+			meson_parm_write(clk->map, &pll->l_detect, 1);
+		else
+			meson_parm_write(clk->map, &pll->l_detect, 0);
+	}
 
 	/* Enable the pll */
 	meson_parm_write(clk->map, &pll->en, 1);
@@ -413,8 +417,12 @@ static int meson_clk_pll_enable(struct clk_hw *hw)
 	udelay(20);
 
 	/* Enable the lock-detect module */
-	if (MESON_PARM_APPLICABLE(&pll->l_detect))
-		meson_parm_write(clk->map, &pll->l_detect, 0);
+	if (MESON_PARM_APPLICABLE(&pll->l_detect)) {
+		if (pll->flags & CLK_MESON_PLL_L_DETECT_N)
+			meson_parm_write(clk->map, &pll->l_detect, 0);
+		else
+			meson_parm_write(clk->map, &pll->l_detect, 1);
+	}
 
 	if (meson_clk_pll_wait_lock(hw)) {
 		/* disable PLL when PLL lock failed. */
diff --git a/drivers/clk/meson/clk-pll.h b/drivers/clk/meson/clk-pll.h
index 949157fb7bf5..83295a24721f 100644
--- a/drivers/clk/meson/clk-pll.h
+++ b/drivers/clk/meson/clk-pll.h
@@ -29,6 +29,8 @@ struct pll_mult_range {
 
 #define CLK_MESON_PLL_ROUND_CLOSEST	BIT(0)
 #define CLK_MESON_PLL_NOINIT_ENABLED	BIT(1)
+/* l_detect signal is active-low */
+#define CLK_MESON_PLL_L_DETECT_N	BIT(2)
 
 struct meson_clk_pll_data {
 	struct parm en;

-- 
2.42.0

