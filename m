From: Brian Masney <bmasney@redhat.com>
Date: Mon, 11 Aug 2025 11:19:14 -0400
Subject: [PATCH 082/114] clk: mediatek: pll: convert from round_rate() to
 determine_rate()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250811-clk-for-stephen-round-rate-v1-82-b3bf97b038dc@redhat.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754925498; l=3081;
 i=bmasney@redhat.com; s=20250528; h=from:subject:message-id;
 bh=a8aukRMUr/LVlOLTZykxjOpqsA9Tn+cOVTLG+KDo0yo=;
 b=Q+x4G5I0ZfRmk9Duu2jCzyROZGlOOPSIfghRQ0Br/Q4JnpbrG+uqr7txefMWlnE2T3P5ob/Dk
 MASVZc/1KHWCqa/x+PAQA/BBDf/o4ULuU/5BgciyiQG51dvtQNEMOrS
X-Developer-Key: i=bmasney@redhat.com; a=ed25519;
 pk=x20f2BQYftANnik+wvlm4HqLqAlNs/npfVcbhHPOK2U=
X-Endpoint-Received: by B4 Relay for bmasney@redhat.com/20250528 with auth_id=472
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The round_rate() clk ops is deprecated, so migrate this driver from
round_rate() to determine_rate() using the Coccinelle semantic patch
on the cover letter of this series.

Signed-off-by: Brian Masney <bmasney@redhat.com>
---
 drivers/clk/mediatek/clk-pll.c   | 13 ++++++++-----
 drivers/clk/mediatek/clk-pll.h   |  3 +--
 drivers/clk/mediatek/clk-pllfh.c |  2 +-
 3 files changed, 10 insertions(+), 8 deletions(-)

diff --git a/drivers/clk/mediatek/clk-pll.c b/drivers/clk/mediatek/clk-pll.c
index ce453e1718e5357e992d590fa174cbd1f061d5e1..139d3bfcf45f9ab094aa429e7b2913abaa3e29ea 100644
--- a/drivers/clk/mediatek/clk-pll.c
+++ b/drivers/clk/mediatek/clk-pll.c
@@ -200,16 +200,19 @@ unsigned long mtk_pll_recalc_rate(struct clk_hw *hw, unsigned long parent_rate)
 	return __mtk_pll_recalc_rate(pll, parent_rate, pcw, postdiv);
 }
 
-long mtk_pll_round_rate(struct clk_hw *hw, unsigned long rate,
-			unsigned long *prate)
+int mtk_pll_determine_rate(struct clk_hw *hw, struct clk_rate_request *req)
 {
 	struct mtk_clk_pll *pll = to_mtk_clk_pll(hw);
 	u32 pcw = 0;
 	int postdiv;
 
-	mtk_pll_calc_values(pll, &pcw, &postdiv, rate, *prate);
+	mtk_pll_calc_values(pll, &pcw, &postdiv, req->rate,
+			    req->best_parent_rate);
 
-	return __mtk_pll_recalc_rate(pll, *prate, pcw, postdiv);
+	req->rate = __mtk_pll_recalc_rate(pll, req->best_parent_rate, pcw,
+					  postdiv);
+
+	return 0;
 }
 
 int mtk_pll_prepare(struct clk_hw *hw)
@@ -279,7 +282,7 @@ const struct clk_ops mtk_pll_ops = {
 	.prepare	= mtk_pll_prepare,
 	.unprepare	= mtk_pll_unprepare,
 	.recalc_rate	= mtk_pll_recalc_rate,
-	.round_rate	= mtk_pll_round_rate,
+	.determine_rate = mtk_pll_determine_rate,
 	.set_rate	= mtk_pll_set_rate,
 };
 
diff --git a/drivers/clk/mediatek/clk-pll.h b/drivers/clk/mediatek/clk-pll.h
index 285c8db958b39e4cd30fe76f41a091806da9839e..670fa2e9b898c2ccb53da26e63b30552199fb6b5 100644
--- a/drivers/clk/mediatek/clk-pll.h
+++ b/drivers/clk/mediatek/clk-pll.h
@@ -96,8 +96,7 @@ void mtk_pll_calc_values(struct mtk_clk_pll *pll, u32 *pcw, u32 *postdiv,
 			 u32 freq, u32 fin);
 int mtk_pll_set_rate(struct clk_hw *hw, unsigned long rate,
 		     unsigned long parent_rate);
-long mtk_pll_round_rate(struct clk_hw *hw, unsigned long rate,
-			unsigned long *prate);
+int mtk_pll_determine_rate(struct clk_hw *hw, struct clk_rate_request *req);
 
 struct clk_hw *mtk_clk_register_pll_ops(struct mtk_clk_pll *pll,
 					const struct mtk_pll_data *data,
diff --git a/drivers/clk/mediatek/clk-pllfh.c b/drivers/clk/mediatek/clk-pllfh.c
index 094ec8a26d66832d510dba94c96cb555f289ad27..83630ee07ee976bf980c8cf2dd35ea24c1b40821 100644
--- a/drivers/clk/mediatek/clk-pllfh.c
+++ b/drivers/clk/mediatek/clk-pllfh.c
@@ -42,7 +42,7 @@ static const struct clk_ops mtk_pllfh_ops = {
 	.prepare	= mtk_pll_prepare,
 	.unprepare	= mtk_pll_unprepare,
 	.recalc_rate	= mtk_pll_recalc_rate,
-	.round_rate	= mtk_pll_round_rate,
+	.determine_rate = mtk_pll_determine_rate,
 	.set_rate	= mtk_fhctl_set_rate,
 };
 

-- 
2.50.1

