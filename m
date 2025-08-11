From: Brian Masney <bmasney@redhat.com>
Date: Mon, 11 Aug 2025 11:18:20 -0400
Subject: [PATCH 028/114] clk: milbeaut: convert from round_rate() to
 determine_rate()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250811-clk-for-stephen-round-rate-v1-28-b3bf97b038dc@redhat.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754925497; l=2218;
 i=bmasney@redhat.com; s=20250528; h=from:subject:message-id;
 bh=5TdaCYdNCxvtkvciw+iLI7X0B3hQqFVvjJmg7rSFzmU=;
 b=e/NyMnffsCwpeedyIkqkgkajSKAMa4dsuRJNgY+hbjCH1vZeUN/Z2aGHGhUDQNmD4KDP64ttS
 hAypdkGK3uHCv6C6A9OVfoqzT9uwhDOYr9qD1oeu/ATPAEsOUa15Z3T
X-Developer-Key: i=bmasney@redhat.com; a=ed25519;
 pk=x20f2BQYftANnik+wvlm4HqLqAlNs/npfVcbhHPOK2U=
X-Endpoint-Received: by B4 Relay for bmasney@redhat.com/20250528 with auth_id=472
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The round_rate() clk ops is deprecated, so migrate this driver from
round_rate() to determine_rate() using the Coccinelle semantic patch
on the cover letter of this series.

Signed-off-by: Brian Masney <bmasney@redhat.com>
---
 drivers/clk/clk-milbeaut.c | 22 ++++++++++++++--------
 1 file changed, 14 insertions(+), 8 deletions(-)

diff --git a/drivers/clk/clk-milbeaut.c b/drivers/clk/clk-milbeaut.c
index 18c20aff45f7698ac40451ef8000ec4fc4efc96b..b4f9b7143eaa658a7f2a14ff3cc9d91d8aa071c6 100644
--- a/drivers/clk/clk-milbeaut.c
+++ b/drivers/clk/clk-milbeaut.c
@@ -386,8 +386,8 @@ static unsigned long m10v_clk_divider_recalc_rate(struct clk_hw *hw,
 				   divider->flags, divider->width);
 }
 
-static long m10v_clk_divider_round_rate(struct clk_hw *hw, unsigned long rate,
-				unsigned long *prate)
+static int m10v_clk_divider_determine_rate(struct clk_hw *hw,
+					   struct clk_rate_request *req)
 {
 	struct m10v_clk_divider *divider = to_m10v_div(hw);
 
@@ -398,13 +398,19 @@ static long m10v_clk_divider_round_rate(struct clk_hw *hw, unsigned long rate,
 		val = readl(divider->reg) >> divider->shift;
 		val &= clk_div_mask(divider->width);
 
-		return divider_ro_round_rate(hw, rate, prate, divider->table,
-					     divider->width, divider->flags,
-					     val);
+		req->rate = divider_ro_round_rate(hw, req->rate,
+						  &req->best_parent_rate,
+						  divider->table,
+						  divider->width,
+						  divider->flags, val);
+
+		return 0;
 	}
 
-	return divider_round_rate(hw, rate, prate, divider->table,
-				  divider->width, divider->flags);
+	req->rate = divider_round_rate(hw, req->rate, &req->best_parent_rate,
+				       divider->table, divider->width, divider->flags);
+
+	return 0;
 }
 
 static int m10v_clk_divider_set_rate(struct clk_hw *hw, unsigned long rate,
@@ -450,7 +456,7 @@ static int m10v_clk_divider_set_rate(struct clk_hw *hw, unsigned long rate,
 
 static const struct clk_ops m10v_clk_divider_ops = {
 	.recalc_rate = m10v_clk_divider_recalc_rate,
-	.round_rate = m10v_clk_divider_round_rate,
+	.determine_rate = m10v_clk_divider_determine_rate,
 	.set_rate = m10v_clk_divider_set_rate,
 };
 

-- 
2.50.1

