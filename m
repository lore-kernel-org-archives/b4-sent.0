From: Brian Masney <bmasney@redhat.com>
Date: Mon, 11 Aug 2025 11:19:31 -0400
Subject: [PATCH 099/114] clk: samsung: pll: convert from round_rate() to
 determine_rate()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250811-clk-for-stephen-round-rate-v1-99-b3bf97b038dc@redhat.com>
References: <20250811-clk-for-stephen-round-rate-v1-0-b3bf97b038dc@redhat.com>
In-Reply-To: <20250811-clk-for-stephen-round-rate-v1-0-b3bf97b038dc@redhat.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Sudeep Holla <sudeep.holla@arm.com>, 
 Cristian Marussi <cristian.marussi@arm.com>, 
 Chen Wang <unicorn_wang@outlook.com>, Inochi Amaoto <inochiama@gmail.com>, 
 Nicolas Ferre <nicolas.ferre@microchip.com>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Claudiu Beznea <claudiu.beznea@tuxon.dev>, 
 Paul Cercueil <paul@crapouillou.net>, 
 Keguang Zhang <keguang.zhang@gmail.com>, 
 Taichi Sugaya <sugaya.taichi@socionext.com>, 
 Takao Orito <orito.takao@socionext.com>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, Jacky Huang <ychuang3@nuvoton.com>, 
 Shan-Chun Hung <schung@nuvoton.com>, Vladimir Zapolskiy <vz@mleia.com>, 
 Piotr Wojtaszczyk <piotr.wojtaszczyk@timesys.com>, 
 Paul Walmsley <paul.walmsley@sifive.com>, 
 Samuel Holland <samuel.holland@sifive.com>, Yixun Lan <dlan@gentoo.org>, 
 Steen Hegelund <Steen.Hegelund@microchip.com>, 
 Daniel Machon <daniel.machon@microchip.com>, UNGLinuxDriver@microchip.com, 
 Orson Zhai <orsonzhai@gmail.com>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Chunyan Zhang <zhang.lyra@gmail.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Michal Simek <michal.simek@amd.com>, Maxime Ripard <mripard@kernel.org>, 
 =?utf-8?q?Andreas_F=C3=A4rber?= <afaerber@suse.de>, 
 Manivannan Sadhasivam <mani@kernel.org>, Sven Peter <sven@kernel.org>, 
 Janne Grunau <j@jannau.net>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Neal Gompa <neal@gompa.dev>, Eugeniy Paltsev <Eugeniy.Paltsev@synopsys.com>, 
 Ray Jui <rjui@broadcom.com>, Scott Branden <sbranden@broadcom.com>, 
 Broadcom internal kernel review list <bcm-kernel-feedback-list@broadcom.com>, 
 Max Filippov <jcmvbkbc@gmail.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Daniel Palmer <daniel@thingy.jp>, Romain Perier <romain.perier@gmail.com>, 
 Andrew Lunn <andrew@lunn.ch>, Gregory Clement <gregory.clement@bootlin.com>, 
 Sebastian Hesselbarth <sebastian.hesselbarth@gmail.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Geert Uytterhoeven <geert+renesas@glider.be>, 
 Heiko Stuebner <heiko@sntech.de>, 
 Andrea della Porta <andrea.porta@suse.com>, 
 Krzysztof Kozlowski <krzk@kernel.org>, 
 Sylwester Nawrocki <s.nawrocki@samsung.com>, 
 Chanwoo Choi <cw00.choi@samsung.com>, Alim Akhtar <alim.akhtar@samsung.com>, 
 Qin Jian <qinjian@cqplus1.com>, Viresh Kumar <vireshk@kernel.org>, 
 Ulf Hansson <ulf.hansson@linaro.org>, 
 Luca Ceresoli <luca.ceresoli@bootlin.com>, 
 Alex Helms <alexander.helms.jy@renesas.com>, 
 Linus Walleij <linus.walleij@linaro.org>, Liviu Dudau <liviu.dudau@arm.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 Nobuhiro Iwamatsu <nobuhiro1.iwamatsu@toshiba.co.jp>
Cc: linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 arm-scmi@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 sophgo@lists.linux.dev, linux-mips@vger.kernel.org, imx@lists.linux.dev, 
 linux-riscv@lists.infradead.org, spacemit@lists.linux.dev, 
 linux-stm32@st-md-mailman.stormreply.com, patches@opensource.cirrus.com, 
 linux-actions@lists.infradead.org, asahi@lists.linux.dev, 
 linux-mediatek@lists.infradead.org, linux-arm-msm@vger.kernel.org, 
 linux-renesas-soc@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-samsung-soc@vger.kernel.org, soc@lists.linux.dev, 
 Brian Masney <bmasney@redhat.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754925498; l=5057;
 i=bmasney@redhat.com; s=20250528; h=from:subject:message-id;
 bh=bsJ0S2YlN+Q/3g0XO5U/IhgIQBKwRSKYutlWFigyhKE=;
 b=Dc7hWjrwwirMj+0PVv/AthEP5h1ngg3LCNMH4rzmIwx/MdalTpUcgn92sAhNZIgEX2Ou/KxkM
 jil/8agAwA1AA03jfTcJFoX70STKB/VREbbUbizxQMNqNxV15RLiKoY
X-Developer-Key: i=bmasney@redhat.com; a=ed25519;
 pk=x20f2BQYftANnik+wvlm4HqLqAlNs/npfVcbhHPOK2U=
X-Endpoint-Received: by B4 Relay for bmasney@redhat.com/20250528 with auth_id=472
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The round_rate() clk ops is deprecated, so migrate this driver from
round_rate() to determine_rate() using the Coccinelle semantic patch
on the cover letter of this series.

Signed-off-by: Brian Masney <bmasney@redhat.com>
---
 drivers/clk/samsung/clk-pll.c | 33 +++++++++++++++++++--------------
 1 file changed, 19 insertions(+), 14 deletions(-)

diff --git a/drivers/clk/samsung/clk-pll.c b/drivers/clk/samsung/clk-pll.c
index e4faf02b631e07dea69be0bb7d141f52fa9900ae..3c04a0388ff9c6cec5b9b5779ad0c3be2b11cf07 100644
--- a/drivers/clk/samsung/clk-pll.c
+++ b/drivers/clk/samsung/clk-pll.c
@@ -49,8 +49,8 @@ static const struct samsung_pll_rate_table *samsung_get_pll_settings(
 	return NULL;
 }
 
-static long samsung_pll_round_rate(struct clk_hw *hw,
-			unsigned long drate, unsigned long *prate)
+static int samsung_pll_determine_rate(struct clk_hw *hw,
+				      struct clk_rate_request *req)
 {
 	struct samsung_clk_pll *pll = to_clk_pll(hw);
 	const struct samsung_pll_rate_table *rate_table = pll->rate_table;
@@ -58,12 +58,17 @@ static long samsung_pll_round_rate(struct clk_hw *hw,
 
 	/* Assuming rate_table is in descending order */
 	for (i = 0; i < pll->rate_count; i++) {
-		if (drate >= rate_table[i].rate)
-			return rate_table[i].rate;
+		if (req->rate >= rate_table[i].rate) {
+			req->rate = rate_table[i].rate;
+
+			return 0;
+		}
 	}
 
 	/* return minimum supported value */
-	return rate_table[i - 1].rate;
+	req->rate = rate_table[i - 1].rate;
+
+	return 0;
 }
 
 static bool pll_early_timeout = true;
@@ -298,7 +303,7 @@ static int samsung_pll35xx_set_rate(struct clk_hw *hw, unsigned long drate,
 
 static const struct clk_ops samsung_pll35xx_clk_ops = {
 	.recalc_rate = samsung_pll35xx_recalc_rate,
-	.round_rate = samsung_pll_round_rate,
+	.determine_rate = samsung_pll_determine_rate,
 	.set_rate = samsung_pll35xx_set_rate,
 	.enable = samsung_pll3xxx_enable,
 	.disable = samsung_pll3xxx_disable,
@@ -411,7 +416,7 @@ static int samsung_pll36xx_set_rate(struct clk_hw *hw, unsigned long drate,
 static const struct clk_ops samsung_pll36xx_clk_ops = {
 	.recalc_rate = samsung_pll36xx_recalc_rate,
 	.set_rate = samsung_pll36xx_set_rate,
-	.round_rate = samsung_pll_round_rate,
+	.determine_rate = samsung_pll_determine_rate,
 	.enable = samsung_pll3xxx_enable,
 	.disable = samsung_pll3xxx_disable,
 };
@@ -514,7 +519,7 @@ static int samsung_pll0822x_set_rate(struct clk_hw *hw, unsigned long drate,
 
 static const struct clk_ops samsung_pll0822x_clk_ops = {
 	.recalc_rate = samsung_pll0822x_recalc_rate,
-	.round_rate = samsung_pll_round_rate,
+	.determine_rate = samsung_pll_determine_rate,
 	.set_rate = samsung_pll0822x_set_rate,
 	.enable = samsung_pll3xxx_enable,
 	.disable = samsung_pll3xxx_disable,
@@ -612,7 +617,7 @@ static int samsung_pll0831x_set_rate(struct clk_hw *hw, unsigned long drate,
 static const struct clk_ops samsung_pll0831x_clk_ops = {
 	.recalc_rate = samsung_pll0831x_recalc_rate,
 	.set_rate = samsung_pll0831x_set_rate,
-	.round_rate = samsung_pll_round_rate,
+	.determine_rate = samsung_pll_determine_rate,
 	.enable = samsung_pll3xxx_enable,
 	.disable = samsung_pll3xxx_disable,
 };
@@ -735,7 +740,7 @@ static int samsung_pll45xx_set_rate(struct clk_hw *hw, unsigned long drate,
 
 static const struct clk_ops samsung_pll45xx_clk_ops = {
 	.recalc_rate = samsung_pll45xx_recalc_rate,
-	.round_rate = samsung_pll_round_rate,
+	.determine_rate = samsung_pll_determine_rate,
 	.set_rate = samsung_pll45xx_set_rate,
 };
 
@@ -880,7 +885,7 @@ static int samsung_pll46xx_set_rate(struct clk_hw *hw, unsigned long drate,
 
 static const struct clk_ops samsung_pll46xx_clk_ops = {
 	.recalc_rate = samsung_pll46xx_recalc_rate,
-	.round_rate = samsung_pll_round_rate,
+	.determine_rate = samsung_pll_determine_rate,
 	.set_rate = samsung_pll46xx_set_rate,
 };
 
@@ -1093,7 +1098,7 @@ static int samsung_pll2550xx_set_rate(struct clk_hw *hw, unsigned long drate,
 
 static const struct clk_ops samsung_pll2550xx_clk_ops = {
 	.recalc_rate = samsung_pll2550xx_recalc_rate,
-	.round_rate = samsung_pll_round_rate,
+	.determine_rate = samsung_pll_determine_rate,
 	.set_rate = samsung_pll2550xx_set_rate,
 };
 
@@ -1185,7 +1190,7 @@ static int samsung_pll2650x_set_rate(struct clk_hw *hw, unsigned long drate,
 
 static const struct clk_ops samsung_pll2650x_clk_ops = {
 	.recalc_rate = samsung_pll2650x_recalc_rate,
-	.round_rate = samsung_pll_round_rate,
+	.determine_rate = samsung_pll_determine_rate,
 	.set_rate = samsung_pll2650x_set_rate,
 };
 
@@ -1277,7 +1282,7 @@ static int samsung_pll2650xx_set_rate(struct clk_hw *hw, unsigned long drate,
 static const struct clk_ops samsung_pll2650xx_clk_ops = {
 	.recalc_rate = samsung_pll2650xx_recalc_rate,
 	.set_rate = samsung_pll2650xx_set_rate,
-	.round_rate = samsung_pll_round_rate,
+	.determine_rate = samsung_pll_determine_rate,
 };
 
 static const struct clk_ops samsung_pll2650xx_clk_min_ops = {

-- 
2.50.1

