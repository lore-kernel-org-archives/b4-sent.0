From: Aiden Isik <aidenisik@member.fsf.org>
Date: Mon, 17 Aug 2026 11:17:06 +0100
Subject: [PATCH 2/3] clk: samsung: clk-pll: Add support for pll_309
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260817-for-next-lucky7-clock-v1-2-032e4b229c76@member.fsf.org>
References: <20260817-for-next-lucky7-clock-v1-0-032e4b229c76@member.fsf.org>
In-Reply-To: <20260817-for-next-lucky7-clock-v1-0-032e4b229c76@member.fsf.org>
To: Krzysztof Kozlowski <krzk@kernel.org>, 
 Sylwester Nawrocki <s.nawrocki@samsung.com>, 
 Chanwoo Choi <cw00.choi@samsung.com>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney@redhat.com>, 
 Rob Herring <robh@kernel.org>, Conor Dooley <conor+dt@kernel.org>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>
Cc: linux-samsung-soc@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-hardening@vger.kernel.org, 
 Aiden Isik <aidenisik+git@member.fsf.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=6673;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=ZEAmFkO+Kj2Xr9987kQ0DFVLYw0y1FU5mSesoCEg7Zk=;
 b=owEBbQKS/ZANAwAIAUknAbLEetfrAcsmYgBqgt+nZuyPwpaL2xjUJWBSMW/Xre5a+jPvYxDNG
 ujARNS1YnSJAjMEAAEIAB0WIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCaoLfpwAKCRBJJwGyxHrX
 68u8D/9ENj8Tn/2On86yphQhsu7ZSYJNHQsJTBwx/KxxSkYJbzdw4ZJ5qXNXMxnvuypxj2VOahF
 3+3UN64EcsrKQC3XqbdHw2BkGbpnqk1jAfXwIRzILvae4Vgr2wkWs0+l16fwOljYKuJv7EyVTkK
 sdUpg8oANj96NskRBxI9p7bgdwHHv0X5gYnof/WGM6rzUKQZ9vfdu2H4o/vMpSOINNrN2ZdXHAC
 wM9s2s2dTdcGTY6tgJFvtEkh3SpxrMi3hBPcv+TvnVewfcN1mmIU+MIwnRb//y44CliALdwokdB
 KSgGsiiKLvIgt0t8Ma6LYlcL5sEFvwb6FVgt3gUK3NBTtl9KYnBphZoh/+f4WSkC3cyAR/NMSWy
 ReYuupZgC68vOgdXJvEKCPvmBiodwGW3K8Gl50haYc7uK68Sjc/VpXwcdEwpSokV4tNbgzBlqUb
 Be/MRfNLKGvaN4eOnrNmYrx20DnnmyAdCWV3XvsKiS5Yy8r7SbC1l1OF4RDhpqzB1beRkeJp4yO
 mWr1BUrPvHsYaxOwLpTwfhMoWabdK44dHN42MEbj6ePCI6juqgeZ6rHlD8UTLp2Mtwx0YIFLWEK
 OP851dPjzwxvYTSr9SbuUDVy5kMi7mor0wGnvJltDVDwg1+3sE4Va447W6Z9e/WJXbaNTk/FqSm
 IESkbQmlnD4iXuQ==
X-Developer-Key: i=aidenisik@member.fsf.org; a=openpgp;
 fpr=83CBC5245C6A5CDC935B11A5492701B2C47AD7EB
X-Endpoint-Received: by B4 Relay for aidenisik@member.fsf.org/default with auth_id=956
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

pll_309 (referred to in the downstream kernel sources as frd_309_rpll) is
one of two PLLs used in the Exynos5515 SoC. It is an integer/fractional
PLL with an FVCO of 600-2400MHz.

It has the same locktime (500), and kdiv/mdiv/pdiv/sdiv masks and shifts
as pll_531x, so it can be handled in exactly the same way.

When defining a PLL, the "con" parameter should be set to the CON3
register, like this:

PLL(pll_309, CLK_FOUT_AUD_PLL, "fout_aud_pll", "oscclk",
    PLL_LOCKTIME_PLL_AUD, PLL_CON3_PLL_AUD, NULL),

Signed-off-by: Aiden Isik <aidenisik+git@member.fsf.org>
---
 drivers/clk/samsung/clk-pll.c | 57 +++++++++++++++++++++++--------------------
 drivers/clk/samsung/clk-pll.h |  1 +
 2 files changed, 32 insertions(+), 26 deletions(-)

diff --git a/drivers/clk/samsung/clk-pll.c b/drivers/clk/samsung/clk-pll.c
index e74552846ba3..8b1474aeaf0c 100644
--- a/drivers/clk/samsung/clk-pll.c
+++ b/drivers/clk/samsung/clk-pll.c
@@ -28,7 +28,7 @@ struct samsung_clk_pll {
 	unsigned short		lock_offs;
 	enum samsung_pll_type	type;
 	unsigned int		rate_count;
-	struct samsung_pll_rate_table rate_table[] __counted_by(rate_count);
+	const struct samsung_pll_rate_table *rate_table;
 };
 
 #define to_clk_pll(_hw) container_of(_hw, struct samsung_clk_pll, hw)
@@ -1593,32 +1593,35 @@ static void __init _samsung_clk_register_pll(struct samsung_clk_provider *ctx,
 {
 	struct samsung_clk_pll *pll;
 	struct clk_init_data init;
-	unsigned int len = 0;
-	int ret;
+	int ret, len;
 
-	if (pll_clk->rate_table) {
-		/* find count of rates in rate_table */
-		while (pll_clk->rate_table[len].rate != 0)
-			len++;
-	}
-
-	pll = kzalloc_flex(*pll, rate_table, len);
+	pll = kzalloc_obj(*pll);
 	if (!pll) {
 		pr_err("%s: could not allocate pll clk %s\n",
 			__func__, pll_clk->name);
 		return;
 	}
 
-	pll->rate_count = len;
-	if (len)
-		memcpy(pll->rate_table, pll_clk->rate_table,
-		       len * sizeof(*pll->rate_table));
-
 	init.name = pll_clk->name;
 	init.flags = pll_clk->flags;
 	init.parent_names = &pll_clk->parent_name;
 	init.num_parents = 1;
 
+	if (pll_clk->rate_table) {
+		/* find count of rates in rate_table */
+		for (len = 0; pll_clk->rate_table[len].rate != 0; )
+			len++;
+
+		pll->rate_count = len;
+		pll->rate_table = kmemdup_array(pll_clk->rate_table,
+						pll->rate_count,
+						sizeof(*pll->rate_table),
+						GFP_KERNEL);
+		WARN(!pll->rate_table,
+			"%s: could not allocate rate table for %s\n",
+			__func__, pll_clk->name);
+	}
+
 	switch (pll_clk->type) {
 	case pll_2126:
 		init.ops = &samsung_pll2126_clk_ops;
@@ -1637,7 +1640,7 @@ static void __init _samsung_clk_register_pll(struct samsung_clk_provider *ctx,
 	case pll_a9fracm:
 		pll->enable_offs = PLL35XX_ENABLE_SHIFT;
 		pll->lock_offs = PLL35XX_LOCK_STAT_SHIFT;
-		if (!pll->rate_count)
+		if (!pll->rate_table)
 			init.ops = &samsung_pll35xx_clk_min_ops;
 		else
 			init.ops = &samsung_pll35xx_clk_ops;
@@ -1656,7 +1659,7 @@ static void __init _samsung_clk_register_pll(struct samsung_clk_provider *ctx,
 	case pll_0732x:
 		pll->enable_offs = PLL0822X_ENABLE_SHIFT;
 		pll->lock_offs = PLL0822X_LOCK_STAT_SHIFT;
-		if (!pll->rate_count)
+		if (!pll->rate_table)
 			init.ops = &samsung_pll0822x_clk_min_ops;
 		else
 			init.ops = &samsung_pll0822x_clk_ops;
@@ -1666,7 +1669,7 @@ static void __init _samsung_clk_register_pll(struct samsung_clk_provider *ctx,
 		break;
 	case pll_4502:
 	case pll_4508:
-		if (!pll->rate_count)
+		if (!pll->rate_table)
 			init.ops = &samsung_pll45xx_clk_min_ops;
 		else
 			init.ops = &samsung_pll45xx_clk_ops;
@@ -1676,7 +1679,7 @@ static void __init _samsung_clk_register_pll(struct samsung_clk_provider *ctx,
 	case pll_2650:
 		pll->enable_offs = PLL36XX_ENABLE_SHIFT;
 		pll->lock_offs = PLL36XX_LOCK_STAT_SHIFT;
-		if (!pll->rate_count)
+		if (!pll->rate_table)
 			init.ops = &samsung_pll36xx_clk_min_ops;
 		else
 			init.ops = &samsung_pll36xx_clk_ops;
@@ -1684,7 +1687,7 @@ static void __init _samsung_clk_register_pll(struct samsung_clk_provider *ctx,
 	case pll_0831x:
 		pll->enable_offs = PLL0831X_ENABLE_SHIFT;
 		pll->lock_offs = PLL0831X_LOCK_STAT_SHIFT;
-		if (!pll->rate_count)
+		if (!pll->rate_table)
 			init.ops = &samsung_pll0831x_clk_min_ops;
 		else
 			init.ops = &samsung_pll0831x_clk_ops;
@@ -1700,7 +1703,7 @@ static void __init _samsung_clk_register_pll(struct samsung_clk_provider *ctx,
 	case pll_4650:
 	case pll_4650c:
 	case pll_1460x:
-		if (!pll->rate_count)
+		if (!pll->rate_table)
 			init.ops = &samsung_pll46xx_clk_min_ops;
 		else
 			init.ops = &samsung_pll46xx_clk_ops;
@@ -1709,29 +1712,30 @@ static void __init _samsung_clk_register_pll(struct samsung_clk_provider *ctx,
 		init.ops = &samsung_pll2550x_clk_ops;
 		break;
 	case pll_2550xx:
-		if (!pll->rate_count)
+		if (!pll->rate_table)
 			init.ops = &samsung_pll2550xx_clk_min_ops;
 		else
 			init.ops = &samsung_pll2550xx_clk_ops;
 		break;
 	case pll_2650x:
-		if (!pll->rate_count)
+		if (!pll->rate_table)
 			init.ops = &samsung_pll2650x_clk_min_ops;
 		else
 			init.ops = &samsung_pll2650x_clk_ops;
 		break;
 	case pll_2650xx:
-		if (!pll->rate_count)
+		if (!pll->rate_table)
 			init.ops = &samsung_pll2650xx_clk_min_ops;
 		else
 			init.ops = &samsung_pll2650xx_clk_ops;
 		break;
 	case pll_531x:
 	case pll_4311:
+	case pll_309:
 		init.ops = &samsung_pll531x_clk_ops;
 		break;
 	case pll_1031x:
-		if (!pll->rate_count)
+		if (!pll->rate_table)
 			init.ops = &samsung_pll1031x_clk_min_ops;
 		else
 			init.ops = &samsung_pll1031x_clk_ops;
@@ -1739,7 +1743,7 @@ static void __init _samsung_clk_register_pll(struct samsung_clk_provider *ctx,
 	case pll_a9fraco:
 		pll->enable_offs = PLLA9FRACO_ENABLE_SHIFT;
 		pll->lock_offs = PLLA9FRACO_LOCK_STAT_SHIFT;
-		if (!pll->rate_count)
+		if (!pll->rate_table)
 			init.ops = &samsung_a9fraco_clk_min_ops;
 		else
 			init.ops = &samsung_a9fraco_clk_ops;
@@ -1758,6 +1762,7 @@ static void __init _samsung_clk_register_pll(struct samsung_clk_provider *ctx,
 	if (ret) {
 		pr_err("%s: failed to register pll clock %s : %d\n",
 			__func__, pll_clk->name, ret);
+		kfree(pll->rate_table);
 		kfree(pll);
 		return;
 	}
diff --git a/drivers/clk/samsung/clk-pll.h b/drivers/clk/samsung/clk-pll.h
index d6eb3246611b..2457cf47c109 100644
--- a/drivers/clk/samsung/clk-pll.h
+++ b/drivers/clk/samsung/clk-pll.h
@@ -53,6 +53,7 @@ enum samsung_pll_type {
 	pll_1031x,
 	pll_a9fracm,
 	pll_a9fraco,
+	pll_309,
 };
 
 #define PLL_RATE(_fin, _m, _p, _s, _k, _ks) \

-- 
2.54.0

