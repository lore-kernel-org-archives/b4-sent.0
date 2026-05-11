From: Jian Hu <jian.hu@amlogic.com>
Date: Mon, 11 May 2026 20:47:28 +0800
Subject: [PATCH 06/10] clk: amlogic: PLL reset signal supports active-low
 configuration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260511-b4-a9_clk-v1-6-41cb4071b7c9@amlogic.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778503655; l=3454;
 i=jian.hu@amlogic.com; s=20260415; h=from:subject:message-id;
 bh=clfKrUtBIiCGEypSBaa2X6SEz4kq2wv6xubbYMfZPdA=;
 b=TQsjaczUkxYfqykhe1RZLaYt8pFwVorzMVt91OgYqNavgIrXbqhT5etrHMKLk00RIsy2VfBqQ
 n92VY6wnhDYCAu5gyiqoaqtcC6hb13tOUnP1+bO4u76dbbNy+GoTGTP
X-Developer-Key: i=jian.hu@amlogic.com; a=ed25519;
 pk=zHUE+rNtH9z+Sb8au1/elWknjFQmy5QDVkBoxleuOIA=
X-Endpoint-Received: by B4 Relay for jian.hu@amlogic.com/20260415 with auth_id=735
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In the A9 design, the PLL reset signal is configured as active-low.

Add the flag 'CLK_MESON_PLL_RST_N' to indicate that the PLL reset signal
is active-low.

Signed-off-by: Jian Hu <jian.hu@amlogic.com>
---
 drivers/clk/meson/clk-pll.c | 42 +++++++++++++++++++++++++++++++-----------
 drivers/clk/meson/clk-pll.h |  2 ++
 2 files changed, 33 insertions(+), 11 deletions(-)

diff --git a/drivers/clk/meson/clk-pll.c b/drivers/clk/meson/clk-pll.c
index 5a0bd75f85a9..8568ad6ba7b6 100644
--- a/drivers/clk/meson/clk-pll.c
+++ b/drivers/clk/meson/clk-pll.c
@@ -295,10 +295,14 @@ static int meson_clk_pll_is_enabled(struct clk_hw *hw)
 {
 	struct clk_regmap *clk = to_clk_regmap(hw);
 	struct meson_clk_pll_data *pll = meson_clk_pll_data(clk);
+	unsigned int rst;
 
-	if (MESON_PARM_APPLICABLE(&pll->rst) &&
-	    meson_parm_read(clk->map, &pll->rst))
-		return 0;
+	if (MESON_PARM_APPLICABLE(&pll->rst)) {
+		rst = meson_parm_read(clk->map, &pll->rst);
+		if ((rst && !(pll->flags & CLK_MESON_PLL_RST_ACTIVE_LOW)) ||
+		    (!rst && (pll->flags & CLK_MESON_PLL_RST_ACTIVE_LOW)))
+			return 0;
+	}
 
 	if (!meson_parm_read(clk->map, &pll->en) ||
 	    !meson_parm_read(clk->map, &pll->l))
@@ -326,14 +330,22 @@ static int meson_clk_pll_init(struct clk_hw *hw)
 		return 0;
 
 	if (pll->init_count) {
-		if (MESON_PARM_APPLICABLE(&pll->rst))
-			meson_parm_write(clk->map, &pll->rst, 1);
+		if (MESON_PARM_APPLICABLE(&pll->rst)) {
+			if (pll->flags & CLK_MESON_PLL_RST_ACTIVE_LOW)
+				meson_parm_write(clk->map, &pll->rst, 0);
+			else
+				meson_parm_write(clk->map, &pll->rst, 1);
+		}
 
 		regmap_multi_reg_write(clk->map, pll->init_regs,
 				       pll->init_count);
 
-		if (MESON_PARM_APPLICABLE(&pll->rst))
-			meson_parm_write(clk->map, &pll->rst, 0);
+		if (MESON_PARM_APPLICABLE(&pll->rst)) {
+			if (pll->flags & CLK_MESON_PLL_RST_ACTIVE_LOW)
+				meson_parm_write(clk->map, &pll->rst, 1);
+			else
+				meson_parm_write(clk->map, &pll->rst, 0);
+		}
 	}
 
 	return 0;
@@ -363,15 +375,23 @@ static int meson_clk_pll_enable(struct clk_hw *hw)
 		return 0;
 
 	/* Make sure the pll is in reset */
-	if (MESON_PARM_APPLICABLE(&pll->rst))
-		meson_parm_write(clk->map, &pll->rst, 1);
+	if (MESON_PARM_APPLICABLE(&pll->rst)) {
+		if (pll->flags & CLK_MESON_PLL_RST_ACTIVE_LOW)
+			meson_parm_write(clk->map, &pll->rst, 0);
+		else
+			meson_parm_write(clk->map, &pll->rst, 1);
+	}
 
 	/* Enable the pll */
 	meson_parm_write(clk->map, &pll->en, 1);
 
 	/* Take the pll out reset */
-	if (MESON_PARM_APPLICABLE(&pll->rst))
-		meson_parm_write(clk->map, &pll->rst, 0);
+	if (MESON_PARM_APPLICABLE(&pll->rst)) {
+		if (pll->flags & CLK_MESON_PLL_RST_ACTIVE_LOW)
+			meson_parm_write(clk->map, &pll->rst, 1);
+		else
+			meson_parm_write(clk->map, &pll->rst, 0);
+	}
 
 	/*
 	 * Compared with the previous SoCs, self-adaption current module
diff --git a/drivers/clk/meson/clk-pll.h b/drivers/clk/meson/clk-pll.h
index 97b7c70376a3..1be7e6e77631 100644
--- a/drivers/clk/meson/clk-pll.h
+++ b/drivers/clk/meson/clk-pll.h
@@ -31,6 +31,8 @@ struct pll_mult_range {
 #define CLK_MESON_PLL_NOINIT_ENABLED	BIT(1)
 /* l_detect signal is active-high */
 #define CLK_MESON_PLL_L_DETECT_ACTIVE_HIGH	BIT(2)
+/* rst signal is active-low (Power-on reset) */
+#define CLK_MESON_PLL_RST_ACTIVE_LOW	BIT(3)
 
 struct meson_clk_pll_data {
 	struct parm en;

-- 
2.47.1

