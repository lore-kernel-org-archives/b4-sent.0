From: Brian Masney <bmasney@redhat.com>
Date: Mon, 11 Aug 2025 11:17:54 -0400
Subject: [PATCH 002/114] clk: at91: peripheral: convert from round_rate()
 to determine_rate()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250811-clk-for-stephen-round-rate-v1-2-b3bf97b038dc@redhat.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754925497; l=3764;
 i=bmasney@redhat.com; s=20250528; h=from:subject:message-id;
 bh=zyirca0yClNWaEsyA4yRgSm6IFANUNOLKtijue+IPEE=;
 b=xHxpbiLsoHOJfs6e9F9K2fRn+qjwW0kTAOujiN6+xnAyQ/u85/MgOQbCfuxXUqagPg+DhuFsi
 tjlaNX3CkRnDuZ/BhKkfkxulkwqkrNMislS7D8M4mmchajF/BU1U3yg
X-Developer-Key: i=bmasney@redhat.com; a=ed25519;
 pk=x20f2BQYftANnik+wvlm4HqLqAlNs/npfVcbhHPOK2U=
X-Endpoint-Received: by B4 Relay for bmasney@redhat.com/20250528 with auth_id=472
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The round_rate() clk ops is deprecated, so migrate this driver from
round_rate() to determine_rate() using the Coccinelle semantic patch
on the cover letter of this series.

This driver already has a clk_sam9x5_peripheral_determine_rate()
implementation, however it can change the parent rate. The existing
round rate does not have this functionality. I could add a check
for CLK_SET_RATE_PARENT, and combine the two functions, however there
are some other minor differences in the two implementations. I don't
have access to this particular hardware. I believe that they could
be combined, however it would need to be tested on real hardware.
So, let's play it safe and convert the existing round rate
implementation to ensure that the driver keeps the same functionality
as before.

Signed-off-by: Brian Masney <bmasney@redhat.com>
---
 drivers/clk/at91/clk-peripheral.c | 41 +++++++++++++++++++++++----------------
 1 file changed, 24 insertions(+), 17 deletions(-)

diff --git a/drivers/clk/at91/clk-peripheral.c b/drivers/clk/at91/clk-peripheral.c
index 629f050a855aaebfd1a03ff87c2b016cd2284a5a..e700f40fd87f9327365f250366f7f7bde01f5987 100644
--- a/drivers/clk/at91/clk-peripheral.c
+++ b/drivers/clk/at91/clk-peripheral.c
@@ -335,50 +335,57 @@ static int clk_sam9x5_peripheral_determine_rate(struct clk_hw *hw,
 	return 0;
 }
 
-static long clk_sam9x5_peripheral_round_rate(struct clk_hw *hw,
-					     unsigned long rate,
-					     unsigned long *parent_rate)
+static int clk_sam9x5_peripheral_no_parent_determine_rate(struct clk_hw *hw,
+							  struct clk_rate_request *req)
 {
 	int shift = 0;
 	unsigned long best_rate;
 	unsigned long best_diff;
-	unsigned long cur_rate = *parent_rate;
+	unsigned long cur_rate = req->best_parent_rate;
 	unsigned long cur_diff;
 	struct clk_sam9x5_peripheral *periph = to_clk_sam9x5_peripheral(hw);
 
-	if (periph->id < PERIPHERAL_ID_MIN || !periph->range.max)
-		return *parent_rate;
+	if (periph->id < PERIPHERAL_ID_MIN || !periph->range.max) {
+		req->rate = req->best_parent_rate;
+
+		return 0;
+	}
 
 	if (periph->range.max) {
 		for (; shift <= PERIPHERAL_MAX_SHIFT; shift++) {
-			cur_rate = *parent_rate >> shift;
+			cur_rate = req->best_parent_rate >> shift;
 			if (cur_rate <= periph->range.max)
 				break;
 		}
 	}
 
-	if (rate >= cur_rate)
-		return cur_rate;
+	if (req->rate >= cur_rate) {
+		req->rate = cur_rate;
+
+		return 0;
+	}
 
-	best_diff = cur_rate - rate;
+	best_diff = cur_rate - req->rate;
 	best_rate = cur_rate;
 	for (; shift <= PERIPHERAL_MAX_SHIFT; shift++) {
-		cur_rate = *parent_rate >> shift;
-		if (cur_rate < rate)
-			cur_diff = rate - cur_rate;
+		cur_rate = req->best_parent_rate >> shift;
+		if (cur_rate < req->rate)
+			cur_diff = req->rate - cur_rate;
 		else
-			cur_diff = cur_rate - rate;
+			cur_diff = cur_rate - req->rate;
 
 		if (cur_diff < best_diff) {
 			best_diff = cur_diff;
 			best_rate = cur_rate;
 		}
 
-		if (!best_diff || cur_rate < rate)
+		if (!best_diff || cur_rate < req->rate)
 			break;
 	}
 
-	return best_rate;
+	req->rate = best_rate;
+
+	return 0;
 }
 
 static int clk_sam9x5_peripheral_set_rate(struct clk_hw *hw,
@@ -430,7 +437,7 @@ static const struct clk_ops sam9x5_peripheral_ops = {
 	.disable = clk_sam9x5_peripheral_disable,
 	.is_enabled = clk_sam9x5_peripheral_is_enabled,
 	.recalc_rate = clk_sam9x5_peripheral_recalc_rate,
-	.round_rate = clk_sam9x5_peripheral_round_rate,
+	.determine_rate = clk_sam9x5_peripheral_no_parent_determine_rate,
 	.set_rate = clk_sam9x5_peripheral_set_rate,
 	.save_context = clk_sam9x5_peripheral_save_context,
 	.restore_context = clk_sam9x5_peripheral_restore_context,

-- 
2.50.1

