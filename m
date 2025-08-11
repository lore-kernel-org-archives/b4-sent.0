From: Brian Masney <bmasney@redhat.com>
Date: Mon, 11 Aug 2025 11:18:57 -0400
Subject: [PATCH 065/114] clk: xgene: convert from round_rate() to
 determine_rate()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250811-clk-for-stephen-round-rate-v1-65-b3bf97b038dc@redhat.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754925498; l=3293;
 i=bmasney@redhat.com; s=20250528; h=from:subject:message-id;
 bh=jDz7BBxKet0EXnRQYnjUdX0CJleEimNV/JM3TtnSr34=;
 b=xnfEo2xq1CgkffsRozEHGG9CkQA8QLWrqM9BHBZ3ZtHzMrqfgHUI7g4Pb3v/BGxaBoQKIoKF4
 e4GWqpi/2g5BC6+o0ZYNubkKvEDtTiXzaGwPmZYWszlL8RPwI//8mTf
X-Developer-Key: i=bmasney@redhat.com; a=ed25519;
 pk=x20f2BQYftANnik+wvlm4HqLqAlNs/npfVcbhHPOK2U=
X-Endpoint-Received: by B4 Relay for bmasney@redhat.com/20250528 with auth_id=472
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The round_rate() clk ops is deprecated, so migrate this driver from
round_rate() to determine_rate() using the Coccinelle semantic patch
on the cover letter of this series.

Signed-off-by: Brian Masney <bmasney@redhat.com>
---
 drivers/clk/clk-xgene.c | 41 ++++++++++++++++++++++++-----------------
 1 file changed, 24 insertions(+), 17 deletions(-)

diff --git a/drivers/clk/clk-xgene.c b/drivers/clk/clk-xgene.c
index 96946a8e2854c3a3fb80c920c8e3798f39386b24..92e39f3237c2f12b65d9ef67d5848948cc2c4d8d 100644
--- a/drivers/clk/clk-xgene.c
+++ b/drivers/clk/clk-xgene.c
@@ -271,23 +271,28 @@ static unsigned long xgene_clk_pmd_recalc_rate(struct clk_hw *hw,
 	return ret;
 }
 
-static long xgene_clk_pmd_round_rate(struct clk_hw *hw, unsigned long rate,
-				     unsigned long *parent_rate)
+static int xgene_clk_pmd_determine_rate(struct clk_hw *hw,
+					struct clk_rate_request *req)
 {
 	struct xgene_clk_pmd *fd = to_xgene_clk_pmd(hw);
 	u64 ret, scale;
 
-	if (!rate || rate >= *parent_rate)
-		return *parent_rate;
+	if (!req->rate || req->rate >= req->best_parent_rate) {
+		req->rate = req->best_parent_rate;
+
+		return 0;
+	}
 
 	/* freq = parent_rate * scaler / denom */
-	ret = rate * fd->denom;
-	scale = DIV_ROUND_UP_ULL(ret, *parent_rate);
+	ret = req->rate * fd->denom;
+	scale = DIV_ROUND_UP_ULL(ret, req->best_parent_rate);
 
-	ret = (u64)*parent_rate * scale;
+	ret = (u64)req->best_parent_rate * scale;
 	do_div(ret, fd->denom);
 
-	return ret;
+	req->rate = ret;
+
+	return 0;
 }
 
 static int xgene_clk_pmd_set_rate(struct clk_hw *hw, unsigned long rate,
@@ -333,7 +338,7 @@ static int xgene_clk_pmd_set_rate(struct clk_hw *hw, unsigned long rate,
 
 static const struct clk_ops xgene_clk_pmd_ops = {
 	.recalc_rate = xgene_clk_pmd_recalc_rate,
-	.round_rate = xgene_clk_pmd_round_rate,
+	.determine_rate = xgene_clk_pmd_determine_rate,
 	.set_rate = xgene_clk_pmd_set_rate,
 };
 
@@ -593,23 +598,25 @@ static int xgene_clk_set_rate(struct clk_hw *hw, unsigned long rate,
 	return parent_rate / divider_save;
 }
 
-static long xgene_clk_round_rate(struct clk_hw *hw, unsigned long rate,
-				unsigned long *prate)
+static int xgene_clk_determine_rate(struct clk_hw *hw,
+				    struct clk_rate_request *req)
 {
 	struct xgene_clk *pclk = to_xgene_clk(hw);
-	unsigned long parent_rate = *prate;
+	unsigned long parent_rate = req->best_parent_rate;
 	u32 divider;
 
 	if (pclk->param.divider_reg) {
 		/* Let's compute the divider */
-		if (rate > parent_rate)
-			rate = parent_rate;
-		divider = parent_rate / rate;   /* Rounded down */
+		if (req->rate > parent_rate)
+			req->rate = parent_rate;
+		divider = parent_rate / req->rate;   /* Rounded down */
 	} else {
 		divider = 1;
 	}
 
-	return parent_rate / divider;
+	req->rate = parent_rate / divider;
+
+	return 0;
 }
 
 static const struct clk_ops xgene_clk_ops = {
@@ -618,7 +625,7 @@ static const struct clk_ops xgene_clk_ops = {
 	.is_enabled = xgene_clk_is_enabled,
 	.recalc_rate = xgene_clk_recalc_rate,
 	.set_rate = xgene_clk_set_rate,
-	.round_rate = xgene_clk_round_rate,
+	.determine_rate = xgene_clk_determine_rate,
 };
 
 static struct clk *xgene_register_clk(struct device *dev,

-- 
2.50.1

