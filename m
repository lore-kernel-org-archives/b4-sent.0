From: Brian Masney <bmasney@redhat.com>
Date: Mon, 11 Aug 2025 11:18:01 -0400
Subject: [PATCH 009/114] clk: at91: usb: convert from round_rate() to
 determine_rate()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250811-clk-for-stephen-round-rate-v1-9-b3bf97b038dc@redhat.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754925497; l=2365;
 i=bmasney@redhat.com; s=20250528; h=from:subject:message-id;
 bh=CkFMBEvlwfAF/1cEEy4Ux9bAaDiae91CQftu/7tBiVg=;
 b=vpTO7eOQYukHmLekMXIJSVYs3w9GG4/WssMKC/2mI2HAxwcIzMt0GCj6VUqJnxzFixBn/JvKm
 Esu7k+ZiHvXDrtocEhKF/UU1z0pLz8UQpLpHbc07PNiXyK8vJhCFEyF
X-Developer-Key: i=bmasney@redhat.com; a=ed25519;
 pk=x20f2BQYftANnik+wvlm4HqLqAlNs/npfVcbhHPOK2U=
X-Endpoint-Received: by B4 Relay for bmasney@redhat.com/20250528 with auth_id=472
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The round_rate() clk ops is deprecated, so migrate this driver from
round_rate() to determine_rate() using the Coccinelle semantic patch
on the cover letter of this series.

Signed-off-by: Brian Masney <bmasney@redhat.com>
---
 drivers/clk/at91/clk-usb.c | 20 +++++++++++---------
 1 file changed, 11 insertions(+), 9 deletions(-)

diff --git a/drivers/clk/at91/clk-usb.c b/drivers/clk/at91/clk-usb.c
index b0696a928aa98d6fd75c3f2e1911aa9b6d1827e6..e906928cfbf05143a1fa4fc69cd7004a30824b6b 100644
--- a/drivers/clk/at91/clk-usb.c
+++ b/drivers/clk/at91/clk-usb.c
@@ -319,8 +319,8 @@ static unsigned long at91rm9200_clk_usb_recalc_rate(struct clk_hw *hw,
 	return 0;
 }
 
-static long at91rm9200_clk_usb_round_rate(struct clk_hw *hw, unsigned long rate,
-					  unsigned long *parent_rate)
+static int at91rm9200_clk_usb_determine_rate(struct clk_hw *hw,
+					     struct clk_rate_request *req)
 {
 	struct at91rm9200_clk_usb *usb = to_at91rm9200_clk_usb(hw);
 	struct clk_hw *parent = clk_hw_get_parent(hw);
@@ -336,25 +336,27 @@ static long at91rm9200_clk_usb_round_rate(struct clk_hw *hw, unsigned long rate,
 		if (!usb->divisors[i])
 			continue;
 
-		tmp_parent_rate = rate * usb->divisors[i];
+		tmp_parent_rate = req->rate * usb->divisors[i];
 		tmp_parent_rate = clk_hw_round_rate(parent, tmp_parent_rate);
 		tmprate = DIV_ROUND_CLOSEST(tmp_parent_rate, usb->divisors[i]);
-		if (tmprate < rate)
-			tmpdiff = rate - tmprate;
+		if (tmprate < req->rate)
+			tmpdiff = req->rate - tmprate;
 		else
-			tmpdiff = tmprate - rate;
+			tmpdiff = tmprate - req->rate;
 
 		if (bestdiff < 0 || bestdiff > tmpdiff) {
 			bestrate = tmprate;
 			bestdiff = tmpdiff;
-			*parent_rate = tmp_parent_rate;
+			req->best_parent_rate = tmp_parent_rate;
 		}
 
 		if (!bestdiff)
 			break;
 	}
 
-	return bestrate;
+	req->rate = bestrate;
+
+	return 0;
 }
 
 static int at91rm9200_clk_usb_set_rate(struct clk_hw *hw, unsigned long rate,
@@ -384,7 +386,7 @@ static int at91rm9200_clk_usb_set_rate(struct clk_hw *hw, unsigned long rate,
 
 static const struct clk_ops at91rm9200_usb_ops = {
 	.recalc_rate = at91rm9200_clk_usb_recalc_rate,
-	.round_rate = at91rm9200_clk_usb_round_rate,
+	.determine_rate = at91rm9200_clk_usb_determine_rate,
 	.set_rate = at91rm9200_clk_usb_set_rate,
 };
 

-- 
2.50.1

