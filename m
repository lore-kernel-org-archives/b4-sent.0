From: Chuan Liu <chuan.liu@amlogic.com>
Date: Mon, 09 Sep 2024 18:08:56 +0800
Subject: [PATCH v3 1/3] clk: meson: Support PLL with fixed fractional
 denominators
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240909-fix_clk-v3-1-a6d8f6333c04@amlogic.com>
References: <20240909-fix_clk-v3-0-a6d8f6333c04@amlogic.com>
In-Reply-To: <20240909-fix_clk-v3-0-a6d8f6333c04@amlogic.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1725876555; l=1833;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=tm+eqZ6z2/fu+O9mUT6fjnN7chLjmdHoODAhOfI/R44=;
 b=U11cPwwTOmhBwh26n/Uf/6HYS90n2Yjr6nBrNusbctnjBVmkncO4x1YgCC6W4bb8CpHU6PAXJ
 FDIVkNCLdYHAyfiGCt9F3/9ZnyZv7DL6hWUl2tTSf0Oti+fqY3IWf+I
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some PLLS with fractional multipliers have fractional denominators with
fixed values, instead of the previous "(1 << pll-> frc.width)".

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 drivers/clk/meson/clk-pll.c | 8 +++++---
 drivers/clk/meson/clk-pll.h | 1 +
 2 files changed, 6 insertions(+), 3 deletions(-)

diff --git a/drivers/clk/meson/clk-pll.c b/drivers/clk/meson/clk-pll.c
index bc570a2ff3a3..89f0f04a16ab 100644
--- a/drivers/clk/meson/clk-pll.c
+++ b/drivers/clk/meson/clk-pll.c
@@ -57,12 +57,13 @@ static unsigned long __pll_params_to_rate(unsigned long parent_rate,
 					  struct meson_clk_pll_data *pll)
 {
 	u64 rate = (u64)parent_rate * m;
+	unsigned int frac_max = pll->frac_max ? pll->frac_max :
+						(1 << pll->frac.width);
 
 	if (frac && MESON_PARM_APPLICABLE(&pll->frac)) {
 		u64 frac_rate = (u64)parent_rate * frac;
 
-		rate += DIV_ROUND_UP_ULL(frac_rate,
-					 (1 << pll->frac.width));
+		rate += DIV_ROUND_UP_ULL(frac_rate, frac_max);
 	}
 
 	return DIV_ROUND_UP_ULL(rate, n);
@@ -100,7 +101,8 @@ static unsigned int __pll_params_with_frac(unsigned long rate,
 					   unsigned int n,
 					   struct meson_clk_pll_data *pll)
 {
-	unsigned int frac_max = (1 << pll->frac.width);
+	unsigned int frac_max = pll->frac_max ? pll->frac_max :
+						(1 << pll->frac.width);
 	u64 val = (u64)rate * n;
 
 	/* Bail out if we are already over the requested rate */
diff --git a/drivers/clk/meson/clk-pll.h b/drivers/clk/meson/clk-pll.h
index 7b6b87274073..949157fb7bf5 100644
--- a/drivers/clk/meson/clk-pll.h
+++ b/drivers/clk/meson/clk-pll.h
@@ -43,6 +43,7 @@ struct meson_clk_pll_data {
 	unsigned int init_count;
 	const struct pll_params_table *table;
 	const struct pll_mult_range *range;
+	unsigned int frac_max;
 	u8 flags;
 };
 

-- 
2.42.0

