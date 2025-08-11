From: Brian Masney <bmasney@redhat.com>
Date: Mon, 11 Aug 2025 11:18:02 -0400
Subject: [PATCH 010/114] clk: baikal-t1: ccu-div: convert from round_rate()
 to determine_rate()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250811-clk-for-stephen-round-rate-v1-10-b3bf97b038dc@redhat.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754925497; l=3389;
 i=bmasney@redhat.com; s=20250528; h=from:subject:message-id;
 bh=nym5XjLemEq228LpveT5/ErTWDImRURr5JDDhbNCaL4=;
 b=0DjaR6QeYFxaDSfXoLB4Aix+g0nTT6SM4/R0Dv/DY/yjG/canwRVCudYkR3wHhI7WlX+hA0kw
 4DoiM292XomCrmp7d4tu+5my/w0Aqv5x0RdRRKBTga+DlCAK2UZP2pT
X-Developer-Key: i=bmasney@redhat.com; a=ed25519;
 pk=x20f2BQYftANnik+wvlm4HqLqAlNs/npfVcbhHPOK2U=
X-Endpoint-Received: by B4 Relay for bmasney@redhat.com/20250528 with auth_id=472
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The round_rate() clk ops is deprecated, so migrate this driver from
round_rate() to determine_rate() using the Coccinelle semantic patch
on the cover letter of this series.

Signed-off-by: Brian Masney <bmasney@redhat.com>
---
 drivers/clk/baikal-t1/ccu-div.c | 27 ++++++++++++++++-----------
 1 file changed, 16 insertions(+), 11 deletions(-)

diff --git a/drivers/clk/baikal-t1/ccu-div.c b/drivers/clk/baikal-t1/ccu-div.c
index 8d5fc7158f33f9c5f8a04241cb62f1ec6ced6e5d..849d1f55765f503c23954754b994d1c28fe3f525 100644
--- a/drivers/clk/baikal-t1/ccu-div.c
+++ b/drivers/clk/baikal-t1/ccu-div.c
@@ -228,15 +228,18 @@ static inline unsigned long ccu_div_var_calc_divider(unsigned long rate,
 		       CCU_DIV_CLKDIV_MAX(mask));
 }
 
-static long ccu_div_var_round_rate(struct clk_hw *hw, unsigned long rate,
-				   unsigned long *parent_rate)
+static int ccu_div_var_determine_rate(struct clk_hw *hw,
+				      struct clk_rate_request *req)
 {
 	struct ccu_div *div = to_ccu_div(hw);
 	unsigned long divider;
 
-	divider = ccu_div_var_calc_divider(rate, *parent_rate, div->mask);
+	divider = ccu_div_var_calc_divider(req->rate, req->best_parent_rate,
+					   div->mask);
 
-	return ccu_div_calc_freq(*parent_rate, divider);
+	req->rate = ccu_div_calc_freq(req->best_parent_rate, divider);
+
+	return 0;
 }
 
 /*
@@ -308,12 +311,14 @@ static unsigned long ccu_div_fixed_recalc_rate(struct clk_hw *hw,
 	return ccu_div_calc_freq(parent_rate, div->divider);
 }
 
-static long ccu_div_fixed_round_rate(struct clk_hw *hw, unsigned long rate,
-				     unsigned long *parent_rate)
+static int ccu_div_fixed_determine_rate(struct clk_hw *hw,
+					struct clk_rate_request *req)
 {
 	struct ccu_div *div = to_ccu_div(hw);
 
-	return ccu_div_calc_freq(*parent_rate, div->divider);
+	req->rate = ccu_div_calc_freq(req->best_parent_rate, div->divider);
+
+	return 0;
 }
 
 static int ccu_div_fixed_set_rate(struct clk_hw *hw, unsigned long rate,
@@ -534,14 +539,14 @@ static const struct clk_ops ccu_div_var_gate_to_set_ops = {
 	.disable = ccu_div_gate_disable,
 	.is_enabled = ccu_div_gate_is_enabled,
 	.recalc_rate = ccu_div_var_recalc_rate,
-	.round_rate = ccu_div_var_round_rate,
+	.determine_rate = ccu_div_var_determine_rate,
 	.set_rate = ccu_div_var_set_rate_fast,
 	.debug_init = ccu_div_var_debug_init
 };
 
 static const struct clk_ops ccu_div_var_nogate_ops = {
 	.recalc_rate = ccu_div_var_recalc_rate,
-	.round_rate = ccu_div_var_round_rate,
+	.determine_rate = ccu_div_var_determine_rate,
 	.set_rate = ccu_div_var_set_rate_slow,
 	.debug_init = ccu_div_var_debug_init
 };
@@ -551,7 +556,7 @@ static const struct clk_ops ccu_div_gate_ops = {
 	.disable = ccu_div_gate_disable,
 	.is_enabled = ccu_div_gate_is_enabled,
 	.recalc_rate = ccu_div_fixed_recalc_rate,
-	.round_rate = ccu_div_fixed_round_rate,
+	.determine_rate = ccu_div_fixed_determine_rate,
 	.set_rate = ccu_div_fixed_set_rate,
 	.debug_init = ccu_div_gate_debug_init
 };
@@ -565,7 +570,7 @@ static const struct clk_ops ccu_div_buf_ops = {
 
 static const struct clk_ops ccu_div_fixed_ops = {
 	.recalc_rate = ccu_div_fixed_recalc_rate,
-	.round_rate = ccu_div_fixed_round_rate,
+	.determine_rate = ccu_div_fixed_determine_rate,
 	.set_rate = ccu_div_fixed_set_rate,
 	.debug_init = ccu_div_fixed_debug_init
 };

-- 
2.50.1

