From: Brian Masney <bmasney@redhat.com>
Date: Mon, 11 Aug 2025 11:18:56 -0400
Subject: [PATCH 064/114] clk: x86: cgu: convert from round_rate() to
 determine_rate()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250811-clk-for-stephen-round-rate-v1-64-b3bf97b038dc@redhat.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754925498; l=3471;
 i=bmasney@redhat.com; s=20250528; h=from:subject:message-id;
 bh=2RBCUExrTQRGIMW73rBPsDh5zLe+IgAz/gGOGsl4Yp8=;
 b=loelU/WUdJANpcU9iSvl5G2LK6liGfDBslwXfM311k9G69yL9FzODuTNtumS/YheMTfIibkp6
 BlkwtsPcmP2DuD3s5QllMy6dYHv9W+x+/Y1Tiui3Qv1exlFhdQugBIz
X-Developer-Key: i=bmasney@redhat.com; a=ed25519;
 pk=x20f2BQYftANnik+wvlm4HqLqAlNs/npfVcbhHPOK2U=
X-Endpoint-Received: by B4 Relay for bmasney@redhat.com/20250528 with auth_id=472
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The round_rate() clk ops is deprecated, so migrate this driver from
round_rate() to determine_rate() using the Coccinelle semantic patch
on the cover letter of this series.

Signed-off-by: Brian Masney <bmasney@redhat.com>
---
 drivers/clk/x86/clk-cgu.c | 35 ++++++++++++++++++++---------------
 1 file changed, 20 insertions(+), 15 deletions(-)

diff --git a/drivers/clk/x86/clk-cgu.c b/drivers/clk/x86/clk-cgu.c
index 89b53f280aee03b7838e4656eae3571f00eaa263..177e2a8f5bba354c07a524f9175e2cb51f08258a 100644
--- a/drivers/clk/x86/clk-cgu.c
+++ b/drivers/clk/x86/clk-cgu.c
@@ -132,14 +132,15 @@ lgm_clk_divider_recalc_rate(struct clk_hw *hw, unsigned long parent_rate)
 				   divider->flags, divider->width);
 }
 
-static long
-lgm_clk_divider_round_rate(struct clk_hw *hw, unsigned long rate,
-			   unsigned long *prate)
+static int lgm_clk_divider_determine_rate(struct clk_hw *hw,
+					  struct clk_rate_request *req)
 {
 	struct lgm_clk_divider *divider = to_lgm_clk_divider(hw);
 
-	return divider_round_rate(hw, rate, prate, divider->table,
-				  divider->width, divider->flags);
+	req->rate = divider_round_rate(hw, req->rate, &req->best_parent_rate, divider->table,
+				       divider->width, divider->flags);
+
+	return 0;
 }
 
 static int
@@ -182,7 +183,7 @@ static void lgm_clk_divider_disable(struct clk_hw *hw)
 
 static const struct clk_ops lgm_clk_divider_ops = {
 	.recalc_rate = lgm_clk_divider_recalc_rate,
-	.round_rate = lgm_clk_divider_round_rate,
+	.determine_rate = lgm_clk_divider_determine_rate,
 	.set_rate = lgm_clk_divider_set_rate,
 	.enable = lgm_clk_divider_enable,
 	.disable = lgm_clk_divider_disable,
@@ -487,15 +488,14 @@ lgm_clk_ddiv_set_rate(struct clk_hw *hw, unsigned long rate,
 	return 0;
 }
 
-static long
-lgm_clk_ddiv_round_rate(struct clk_hw *hw, unsigned long rate,
-			unsigned long *prate)
+static int lgm_clk_ddiv_determine_rate(struct clk_hw *hw,
+				       struct clk_rate_request *req)
 {
 	struct lgm_clk_ddiv *ddiv = to_lgm_clk_ddiv(hw);
 	u32 div, ddiv1, ddiv2;
 	u64 rate64;
 
-	div = DIV_ROUND_CLOSEST_ULL((u64)*prate, rate);
+	div = DIV_ROUND_CLOSEST_ULL((u64) req->best_parent_rate, req->rate);
 
 	/* if predivide bit is enabled, modify div by factor of 2.5 */
 	if (lgm_get_clk_val(ddiv->membase, ddiv->reg, ddiv->shift2, 1)) {
@@ -503,14 +503,17 @@ lgm_clk_ddiv_round_rate(struct clk_hw *hw, unsigned long rate,
 		div = DIV_ROUND_CLOSEST_ULL((u64)div, 5);
 	}
 
-	if (div <= 0)
-		return *prate;
+	if (div <= 0) {
+		req->rate = req->best_parent_rate;
+
+		return 0;
+	}
 
 	if (lgm_clk_get_ddiv_val(div, &ddiv1, &ddiv2) != 0)
 		if (lgm_clk_get_ddiv_val(div + 1, &ddiv1, &ddiv2) != 0)
 			return -EINVAL;
 
-	rate64 = *prate;
+	rate64 = req->best_parent_rate;
 	do_div(rate64, ddiv1);
 	do_div(rate64, ddiv2);
 
@@ -520,7 +523,9 @@ lgm_clk_ddiv_round_rate(struct clk_hw *hw, unsigned long rate,
 		rate64 = DIV_ROUND_CLOSEST_ULL(rate64, 5);
 	}
 
-	return rate64;
+	req->rate = rate64;
+
+	return 0;
 }
 
 static const struct clk_ops lgm_clk_ddiv_ops = {
@@ -528,7 +533,7 @@ static const struct clk_ops lgm_clk_ddiv_ops = {
 	.enable	= lgm_clk_ddiv_enable,
 	.disable = lgm_clk_ddiv_disable,
 	.set_rate = lgm_clk_ddiv_set_rate,
-	.round_rate = lgm_clk_ddiv_round_rate,
+	.determine_rate = lgm_clk_ddiv_determine_rate,
 };
 
 int lgm_clk_register_ddiv(struct lgm_clk_provider *ctx,

-- 
2.50.1

