From: Brian Masney <bmasney@redhat.com>
Date: Mon, 11 Aug 2025 11:19:11 -0400
Subject: [PATCH 079/114] clk: bm1880: convert from round_rate() to
 determine_rate()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250811-clk-for-stephen-round-rate-v1-79-b3bf97b038dc@redhat.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754925498; l=2146;
 i=bmasney@redhat.com; s=20250528; h=from:subject:message-id;
 bh=i4/zUwvMmSNXthJvzQxhg+vS/kwTrhaPDh6vzaYBr/Y=;
 b=R+e0rJ26ayqoVsrbB80+wdnnEe+4dIQYa/IcZLbwrsXzdPK+R+VX4dAXHJbr5Hhl2egxnKejt
 HsnRyFQazBNC+2TZhSPqsBcma/hpbZwiz4PdxTAPM1chEOBtUaxmNG3
X-Developer-Key: i=bmasney@redhat.com; a=ed25519;
 pk=x20f2BQYftANnik+wvlm4HqLqAlNs/npfVcbhHPOK2U=
X-Endpoint-Received: by B4 Relay for bmasney@redhat.com/20250528 with auth_id=472
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The round_rate() clk ops is deprecated, so migrate this driver from
round_rate() to determine_rate() using the Coccinelle semantic patch
on the cover letter of this series.

Signed-off-by: Brian Masney <bmasney@redhat.com>
---
 drivers/clk/clk-bm1880.c | 21 +++++++++++++--------
 1 file changed, 13 insertions(+), 8 deletions(-)

diff --git a/drivers/clk/clk-bm1880.c b/drivers/clk/clk-bm1880.c
index 002f7360b1c6c6e3058606a0808115b48fd3147a..dac190bc6e19a6dd4be413ea52d41f74934a1aa9 100644
--- a/drivers/clk/clk-bm1880.c
+++ b/drivers/clk/clk-bm1880.c
@@ -608,8 +608,8 @@ static unsigned long bm1880_clk_div_recalc_rate(struct clk_hw *hw,
 	return rate;
 }
 
-static long bm1880_clk_div_round_rate(struct clk_hw *hw, unsigned long rate,
-				      unsigned long *prate)
+static int bm1880_clk_div_determine_rate(struct clk_hw *hw,
+					 struct clk_rate_request *req)
 {
 	struct bm1880_div_hw_clock *div_hw = to_bm1880_div_clk(hw);
 	struct bm1880_div_clock *div = &div_hw->div;
@@ -621,13 +621,18 @@ static long bm1880_clk_div_round_rate(struct clk_hw *hw, unsigned long rate,
 		val = readl(reg_addr) >> div->shift;
 		val &= clk_div_mask(div->width);
 
-		return divider_ro_round_rate(hw, rate, prate, div->table,
-					     div->width, div->flags,
-					     val);
+		req->rate = divider_ro_round_rate(hw, req->rate,
+						  &req->best_parent_rate,
+						  div->table,
+						  div->width, div->flags, val);
+
+		return 0;
 	}
 
-	return divider_round_rate(hw, rate, prate, div->table,
-				  div->width, div->flags);
+	req->rate = divider_round_rate(hw, req->rate, &req->best_parent_rate,
+				       div->table, div->width, div->flags);
+
+	return 0;
 }
 
 static int bm1880_clk_div_set_rate(struct clk_hw *hw, unsigned long rate,
@@ -665,7 +670,7 @@ static int bm1880_clk_div_set_rate(struct clk_hw *hw, unsigned long rate,
 
 static const struct clk_ops bm1880_clk_div_ops = {
 	.recalc_rate = bm1880_clk_div_recalc_rate,
-	.round_rate = bm1880_clk_div_round_rate,
+	.determine_rate = bm1880_clk_div_determine_rate,
 	.set_rate = bm1880_clk_div_set_rate,
 };
 

-- 
2.50.1

