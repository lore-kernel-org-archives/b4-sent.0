From: Chuan Liu <chuan.liu@amlogic.com>
Date: Wed, 22 Oct 2025 14:58:52 +0800
Subject: [PATCH 2/3] clk: amlogic: Optimize PLL enable timing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251022-optimize_pll_driver-v1-2-a275722fb6f4@amlogic.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761116340; l=4402;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=bsdTchbiRzU7fQnKSjIW161Jtz+ZayPt5sUS3k0V7QU=;
 b=AEy5PXpFUMdDMXW6q9jCnGv15v8j0xAtKltUNJgWlUAFVhON3sKl2AoUsoePKRadfRMVcNgjv
 Qj49HwbWa0bDBPIE1TIVUT3cZvV2sp/7ONf6SARkAIpNAB4XiYubxvF
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Amlogic PLL locking procedure shall follow this timing sequence:
1 Assert reset signal: Ensures PLL circuits enter known initial state.
2 Deassert lock-detect signal: Avoid lock signal false triggering.
3 Assert enable signal: Powers up PLL supply.
4 udelay(20): Wait for Bandgap and LDO to power up and stabilize.
5 Enable self-adaptation current module (Optional).
6 Deassert reset signal: Releases PLL to begin normal operation.
7 udelay(20): Wait for PLL loop stabilization.
8 Assert lock-detect signal: lock detection circuit starts to work.
9 Monitor lock status signal: Wait for PLL lock completion.
10 If the PLL fails to lock, it should be disabled, This makes the
logic more complete, and also helps save unnecessary power consumption
when the PLL is malfunctioning.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 drivers/clk/meson/clk-pll.c | 68 ++++++++++++++++++++++++++-------------------
 1 file changed, 40 insertions(+), 28 deletions(-)

diff --git a/drivers/clk/meson/clk-pll.c b/drivers/clk/meson/clk-pll.c
index b07e1eb19d12..26c83db487e8 100644
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
@@ -366,53 +383,48 @@ static int meson_clk_pll_enable(struct clk_hw *hw)
 	if (MESON_PARM_APPLICABLE(&pll->rst))
 		meson_parm_write(clk->map, &pll->rst, 1);
 
+	/* Disable the PLL lock-detect module */
+	if (MESON_PARM_APPLICABLE(&pll->l_detect))
+		meson_parm_write(clk->map, &pll->l_detect, 1);
+
 	/* Enable the pll */
 	meson_parm_write(clk->map, &pll->en, 1);
-
-	/* Take the pll out reset */
-	if (MESON_PARM_APPLICABLE(&pll->rst))
-		meson_parm_write(clk->map, &pll->rst, 0);
+	/* Wait for Bandgap and LDO to power up and stabilize */
+	udelay(20);
 
 	/*
 	 * Compared with the previous SoCs, self-adaption current module
 	 * is newly added for A1, keep the new power-on sequence to enable the
 	 * PLL. The sequence is:
-	 * 1. enable the pll, delay for 10us
+	 * 1. enable the pll, ensure a minimum delay of 10μs
 	 * 2. enable the pll self-adaption current module, delay for 40us
 	 * 3. enable the lock detect module
 	 */
 	if (MESON_PARM_APPLICABLE(&pll->current_en)) {
-		udelay(10);
 		meson_parm_write(clk->map, &pll->current_en, 1);
-		udelay(40);
-	}
-
-	if (MESON_PARM_APPLICABLE(&pll->l_detect)) {
-		meson_parm_write(clk->map, &pll->l_detect, 1);
-		meson_parm_write(clk->map, &pll->l_detect, 0);
+		udelay(20);
 	}
 
-	if (meson_clk_pll_wait_lock(hw))
-		return -EIO;
+	/* Take the pll out reset */
+	if (MESON_PARM_APPLICABLE(&pll->rst))
+		meson_parm_write(clk->map, &pll->rst, 0);
 
-	return 0;
-}
+	/* Wait for PLL loop stabilization */
+	udelay(20);
 
-static void meson_clk_pll_disable(struct clk_hw *hw)
-{
-	struct clk_regmap *clk = to_clk_regmap(hw);
-	struct meson_clk_pll_data *pll = meson_clk_pll_data(clk);
+	/* Enable the lock-detect module */
+	if (MESON_PARM_APPLICABLE(&pll->l_detect))
+		meson_parm_write(clk->map, &pll->l_detect, 0);
 
-	/* Put the pll is in reset */
-	if (MESON_PARM_APPLICABLE(&pll->rst))
-		meson_parm_write(clk->map, &pll->rst, 1);
+	if (meson_clk_pll_wait_lock(hw)) {
+		/* disable PLL when PLL lock failed. */
+		meson_clk_pll_disable(hw);
+		pr_warn("%s: PLL lock failed!!!\n", clk_hw_get_name(hw));
 
-	/* Disable the pll */
-	meson_parm_write(clk->map, &pll->en, 0);
+		return -EIO;
+	}
 
-	/* Disable PLL internal self-adaption current module */
-	if (MESON_PARM_APPLICABLE(&pll->current_en))
-		meson_parm_write(clk->map, &pll->current_en, 0);
+	return 0;
 }
 
 static int meson_clk_pll_set_rate(struct clk_hw *hw, unsigned long rate,

-- 
2.42.0

