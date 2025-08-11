From: Brian Masney <bmasney@redhat.com>
Date: Mon, 11 Aug 2025 11:18:07 -0400
Subject: [PATCH 015/114] clk: fractional-divider: convert from round_rate()
 to determine_rate()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250811-clk-for-stephen-round-rate-v1-15-b3bf97b038dc@redhat.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754925497; l=2318;
 i=bmasney@redhat.com; s=20250528; h=from:subject:message-id;
 bh=/o+cz3JnxAohEBFk0Q6flk11ZK2B5GlFanpUK6pxSB0=;
 b=cv7K+VUcxLaSvuke6V5+DTyW7HLszBz+TY7aN6vsOtNEEGx1L+zhSi4oLVYgIkl7XliPU9rBx
 LoYTZHQJWnRAdHuJhabFXxUJ9BDe7IVMv681j2Qwg0CMh3KGRIw+tcG
X-Developer-Key: i=bmasney@redhat.com; a=ed25519;
 pk=x20f2BQYftANnik+wvlm4HqLqAlNs/npfVcbhHPOK2U=
X-Endpoint-Received: by B4 Relay for bmasney@redhat.com/20250528 with auth_id=472
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The round_rate() clk ops is deprecated, so migrate this driver from
round_rate() to determine_rate() using the Coccinelle semantic patch
on the cover letter of this series.

Signed-off-by: Brian Masney <bmasney@redhat.com>
---
 drivers/clk/clk-fractional-divider.c | 25 ++++++++++++++++---------
 1 file changed, 16 insertions(+), 9 deletions(-)

diff --git a/drivers/clk/clk-fractional-divider.c b/drivers/clk/clk-fractional-divider.c
index da057172cc90f145743a4f7dfd71870bd63b564b..cd36a6e27f251f88c5fdf06e7de4bd8cbe332c24 100644
--- a/drivers/clk/clk-fractional-divider.c
+++ b/drivers/clk/clk-fractional-divider.c
@@ -151,25 +151,32 @@ void clk_fractional_divider_general_approximation(struct clk_hw *hw,
 }
 EXPORT_SYMBOL_GPL(clk_fractional_divider_general_approximation);
 
-static long clk_fd_round_rate(struct clk_hw *hw, unsigned long rate,
-			      unsigned long *parent_rate)
+static int clk_fd_determine_rate(struct clk_hw *hw,
+				 struct clk_rate_request *req)
 {
 	struct clk_fractional_divider *fd = to_clk_fd(hw);
 	unsigned long m, n;
 	u64 ret;
 
-	if (!rate || (!clk_hw_can_set_rate_parent(hw) && rate >= *parent_rate))
-		return *parent_rate;
+	if (!req->rate || (!clk_hw_can_set_rate_parent(hw) && req->rate >= req->best_parent_rate)) {
+		req->rate = req->best_parent_rate;
+
+		return 0;
+	}
 
 	if (fd->approximation)
-		fd->approximation(hw, rate, parent_rate, &m, &n);
+		fd->approximation(hw, req->rate, &req->best_parent_rate, &m, &n);
 	else
-		clk_fractional_divider_general_approximation(hw, rate, parent_rate, &m, &n);
+		clk_fractional_divider_general_approximation(hw, req->rate,
+							     &req->best_parent_rate,
+							     &m, &n);
 
-	ret = (u64)*parent_rate * m;
+	ret = (u64)req->best_parent_rate * m;
 	do_div(ret, n);
 
-	return ret;
+	req->rate = ret;
+
+	return 0;
 }
 
 static int clk_fd_set_rate(struct clk_hw *hw, unsigned long rate,
@@ -250,7 +257,7 @@ static void clk_fd_debug_init(struct clk_hw *hw, struct dentry *dentry)
 
 const struct clk_ops clk_fractional_divider_ops = {
 	.recalc_rate = clk_fd_recalc_rate,
-	.round_rate = clk_fd_round_rate,
+	.determine_rate = clk_fd_determine_rate,
 	.set_rate = clk_fd_set_rate,
 #ifdef CONFIG_DEBUG_FS
 	.debug_init = clk_fd_debug_init,

-- 
2.50.1

