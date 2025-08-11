From: Brian Masney <bmasney@redhat.com>
Date: Mon, 11 Aug 2025 11:19:15 -0400
Subject: [PATCH 083/114] clk: microchip: core: convert from round_rate() to
 determine_rate()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250811-clk-for-stephen-round-rate-v1-83-b3bf97b038dc@redhat.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754925498; l=4230;
 i=bmasney@redhat.com; s=20250528; h=from:subject:message-id;
 bh=YMDl5Dg1ebY0oa3yJn1kDt9B+GTjRRC9X+mnPj0mD4I=;
 b=xu1TDAVDPkAH51Z+kE+nyZyIn7jkJ+ucnQ6UYpyM4dhn8XGohcz6jVtEkAirsskvNjAeAUjcu
 blgPTKZ0CHUBpnEIuyWGuaS+gDAb1GA14gDpIqpHXimnvaVyNxaeZl0
X-Developer-Key: i=bmasney@redhat.com; a=ed25519;
 pk=x20f2BQYftANnik+wvlm4HqLqAlNs/npfVcbhHPOK2U=
X-Endpoint-Received: by B4 Relay for bmasney@redhat.com/20250528 with auth_id=472
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The round_rate() clk ops is deprecated, so migrate this driver from
round_rate() to determine_rate() using the Coccinelle semantic patch
on the cover letter of this series.

Signed-off-by: Brian Masney <bmasney@redhat.com>
---
 drivers/clk/microchip/clk-core.c | 44 ++++++++++++++++++++++++----------------
 1 file changed, 27 insertions(+), 17 deletions(-)

diff --git a/drivers/clk/microchip/clk-core.c b/drivers/clk/microchip/clk-core.c
index 6fbc6dc50ca3d9f1f0aecc5e43f4d41f23cb371a..3e03e10539c72cc28e53401093e37409c2ea3d08 100644
--- a/drivers/clk/microchip/clk-core.c
+++ b/drivers/clk/microchip/clk-core.c
@@ -155,11 +155,13 @@ static unsigned long pbclk_recalc_rate(struct clk_hw *hw,
 	return parent_rate / pbclk_read_pbdiv(pb);
 }
 
-static long pbclk_round_rate(struct clk_hw *hw, unsigned long rate,
-			     unsigned long *parent_rate)
+static int pbclk_determine_rate(struct clk_hw *hw,
+				struct clk_rate_request *req)
 {
-	return calc_best_divided_rate(rate, *parent_rate,
-				      PB_DIV_MAX, PB_DIV_MIN);
+	req->rate = calc_best_divided_rate(req->rate, req->best_parent_rate,
+					   PB_DIV_MAX, PB_DIV_MIN);
+
+	return 0;
 }
 
 static int pbclk_set_rate(struct clk_hw *hw, unsigned long rate,
@@ -207,7 +209,7 @@ const struct clk_ops pic32_pbclk_ops = {
 	.disable	= pbclk_disable,
 	.is_enabled	= pbclk_is_enabled,
 	.recalc_rate	= pbclk_recalc_rate,
-	.round_rate	= pbclk_round_rate,
+	.determine_rate = pbclk_determine_rate,
 	.set_rate	= pbclk_set_rate,
 };
 
@@ -372,16 +374,18 @@ static unsigned long roclk_recalc_rate(struct clk_hw *hw,
 	return roclk_calc_rate(parent_rate, rodiv, rotrim);
 }
 
-static long roclk_round_rate(struct clk_hw *hw, unsigned long rate,
-			     unsigned long *parent_rate)
+static int roclk_determine_rate(struct clk_hw *hw,
+				struct clk_rate_request *req)
 {
 	u32 rotrim, rodiv;
 
 	/* calculate dividers for new rate */
-	roclk_calc_div_trim(rate, *parent_rate, &rodiv, &rotrim);
+	roclk_calc_div_trim(req->rate, req->best_parent_rate, &rodiv, &rotrim);
 
 	/* caclulate new rate (rounding) based on new rodiv & rotrim */
-	return roclk_calc_rate(*parent_rate, rodiv, rotrim);
+	req->rate = roclk_calc_rate(req->best_parent_rate, rodiv, rotrim);
+
+	return 0;
 }
 
 static int roclk_determine_rate(struct clk_hw *hw,
@@ -665,12 +669,15 @@ static unsigned long spll_clk_recalc_rate(struct clk_hw *hw,
 	return rate64;
 }
 
-static long spll_clk_round_rate(struct clk_hw *hw, unsigned long rate,
-				unsigned long *parent_rate)
+static int spll_clk_determine_rate(struct clk_hw *hw,
+				   struct clk_rate_request *req)
 {
 	struct pic32_sys_pll *pll = clkhw_to_spll(hw);
 
-	return spll_calc_mult_div(pll, rate, *parent_rate, NULL, NULL);
+	req->rate = spll_calc_mult_div(pll, req->rate, req->best_parent_rate,
+				       NULL, NULL);
+
+	return 0;
 }
 
 static int spll_clk_set_rate(struct clk_hw *hw, unsigned long rate,
@@ -725,7 +732,7 @@ static int spll_clk_set_rate(struct clk_hw *hw, unsigned long rate,
 /* SPLL clock operation */
 const struct clk_ops pic32_spll_ops = {
 	.recalc_rate	= spll_clk_recalc_rate,
-	.round_rate	= spll_clk_round_rate,
+	.determine_rate = spll_clk_determine_rate,
 	.set_rate	= spll_clk_set_rate,
 };
 
@@ -780,10 +787,13 @@ static unsigned long sclk_get_rate(struct clk_hw *hw, unsigned long parent_rate)
 	return parent_rate / div;
 }
 
-static long sclk_round_rate(struct clk_hw *hw, unsigned long rate,
-			    unsigned long *parent_rate)
+static int sclk_determine_rate(struct clk_hw *hw,
+			       struct clk_rate_request *req)
 {
-	return calc_best_divided_rate(rate, *parent_rate, SLEW_SYSDIV, 1);
+	req->rate = calc_best_divided_rate(req->rate, req->best_parent_rate,
+					   SLEW_SYSDIV, 1);
+
+	return 0;
 }
 
 static int sclk_set_rate(struct clk_hw *hw,
@@ -909,7 +919,7 @@ static int sclk_init(struct clk_hw *hw)
 const struct clk_ops pic32_sclk_ops = {
 	.get_parent	= sclk_get_parent,
 	.set_parent	= sclk_set_parent,
-	.round_rate	= sclk_round_rate,
+	.determine_rate = sclk_determine_rate,
 	.set_rate	= sclk_set_rate,
 	.recalc_rate	= sclk_get_rate,
 	.init		= sclk_init,

-- 
2.50.1

