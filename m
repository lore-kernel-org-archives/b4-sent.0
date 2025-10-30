From: Chuan Liu <chuan.liu@amlogic.com>
Date: Thu, 30 Oct 2025 13:24:13 +0800
Subject: [PATCH v2 3/5] clk: amlogic: Add handling for PLL lock failure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251030-optimize_pll_driver-v2-3-37273f5b25ab@amlogic.com>
References: <20251030-optimize_pll_driver-v2-0-37273f5b25ab@amlogic.com>
In-Reply-To: <20251030-optimize_pll_driver-v2-0-37273f5b25ab@amlogic.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>, da@libre.computer
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761801855; l=2331;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=vrUlJ1HmRnCEyEkq2xDw1ggVFh4RddetWLmGLf94sV4=;
 b=cSkp9cTFFGr5sg6ASQ8L33zSJKDZR942ZJ8M8anl9qJse6qqWwezMYBS2WJrFMSpurm2Vpguh
 xbNHhPo/ZlBCEu/7QDJNyKvbgOsc82743NVagBbUZHSXjb5k+QBmYDc
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If the PLL fails to lock, it should be disabled, This makes the logic
more complete, and also helps save unnecessary power consumption when
the PLL is malfunctioning.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 drivers/clk/meson/clk-pll.c | 41 +++++++++++++++++++++++------------------
 1 file changed, 23 insertions(+), 18 deletions(-)

diff --git a/drivers/clk/meson/clk-pll.c b/drivers/clk/meson/clk-pll.c
index f81ebf6cc981..6c794adb8ccd 100644
--- a/drivers/clk/meson/clk-pll.c
+++ b/drivers/clk/meson/clk-pll.c
@@ -353,6 +353,23 @@ static int meson_clk_pcie_pll_enable(struct clk_hw *hw)
 	return -EIO;
 }
 
+static void meson_clk_pll_disable(struct clk_hw *hw)
+{
+	struct clk_regmap *clk = to_clk_regmap(hw);
+	struct meson_clk_pll_data *pll = meson_clk_pll_data(clk);
+
+	/* Put the pll is in reset */
+	if (MESON_PARM_APPLICABLE(&pll->rst))
+		meson_parm_write(clk->map, &pll->rst, 1);
+
+	/* Disable the pll */
+	meson_parm_write(clk->map, &pll->en, 0);
+
+	/* Disable PLL internal self-adaption current module */
+	if (MESON_PARM_APPLICABLE(&pll->current_en))
+		meson_parm_write(clk->map, &pll->current_en, 0);
+}
+
 static int meson_clk_pll_enable(struct clk_hw *hw)
 {
 	struct clk_regmap *clk = to_clk_regmap(hw);
@@ -397,29 +414,17 @@ static int meson_clk_pll_enable(struct clk_hw *hw)
 		meson_parm_write(clk->map, &pll->l_detect, 0);
 	}
 
-	if (meson_clk_pll_wait_lock(hw))
+	if (meson_clk_pll_wait_lock(hw)) {
+		/* disable PLL when PLL lock failed. */
+		meson_clk_pll_disable(hw);
+		pr_warn("%s: PLL lock failed!!!\n", clk_hw_get_name(hw));
+
 		return -EIO;
+	}
 
 	return 0;
 }
 
-static void meson_clk_pll_disable(struct clk_hw *hw)
-{
-	struct clk_regmap *clk = to_clk_regmap(hw);
-	struct meson_clk_pll_data *pll = meson_clk_pll_data(clk);
-
-	/* Put the pll is in reset */
-	if (MESON_PARM_APPLICABLE(&pll->rst))
-		meson_parm_write(clk->map, &pll->rst, 1);
-
-	/* Disable the pll */
-	meson_parm_write(clk->map, &pll->en, 0);
-
-	/* Disable PLL internal self-adaption current module */
-	if (MESON_PARM_APPLICABLE(&pll->current_en))
-		meson_parm_write(clk->map, &pll->current_en, 0);
-}
-
 static int meson_clk_pll_set_rate(struct clk_hw *hw, unsigned long rate,
 				  unsigned long parent_rate)
 {

-- 
2.42.0

