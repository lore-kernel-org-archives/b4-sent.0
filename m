From: Han Gao <gaohan@iscas.ac.cn>
Date: Sat, 14 Nov 2026 06:33:36 +0800
Subject: [PATCH 10/19] clk: sunxi-ng: sun6i-rtc: allow another 24 MHz to
 32k divider ratio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-v861-v1-10-eb71ec3ee523@iscas.ac.cn>
References: <20261114-v861-v1-0-eb71ec3ee523@iscas.ac.cn>
In-Reply-To: <20261114-v861-v1-0-eb71ec3ee523@iscas.ac.cn>
To: Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Albert Ou <aou@eecs.berkeley.edu>, Alexandre Ghiti <alex@ghiti.fr>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Guo Ren <guoren@kernel.org>, 
 Thomas Gleixner <tglx@kernel.org>, Radu Rendec <radu@rendec.net>, 
 Samuel Holland <samuel.holland@sifive.com>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Anup Patel <anup@brainfault.org>, Han Gao <gaohan@iscas.ac.cn>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Maxime Ripard <mripard@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Andre Przywara <andre.przywara@arm.com>
Cc: Han Gao <rabenda.cn@gmail.com>, linux-riscv@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@sifive.com>, Conor Dooley <conor@kernel.org>, 
 devicetree@vger.kernel.org, linux-csky@vger.kernel.org, 
 linux-sunxi@lists.linux.dev, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rtc@vger.kernel.org, 
 linux-gpio@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794609209; l=1317;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=4J4UFeD/eghp455M83eHVDqg8JSEWGJn1Ho+53uK9kw=;
 b=bxWPhg/JyaODgEHvYWbpaZH47om1EuJoYhcMyIKsswhKOxOfeMIeHT2Vc0XRwXRU3X7LU3/uc
 m6Q1MIe7JxADYv5O0YTn0lRP85QuG5yZexTgEa7RBlOQGEcBUeb3z0M
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The fixed 24 MHz to 32 kHz divider does not divide by 750 on all
variants. Allow the match data to override its multiplier and divider.

Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 drivers/clk/sunxi-ng/ccu-sun6i-rtc.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/drivers/clk/sunxi-ng/ccu-sun6i-rtc.c b/drivers/clk/sunxi-ng/ccu-sun6i-rtc.c
index 0e40fd5fa624..b3619222fef0 100644
--- a/drivers/clk/sunxi-ng/ccu-sun6i-rtc.c
+++ b/drivers/clk/sunxi-ng/ccu-sun6i-rtc.c
@@ -54,6 +54,8 @@ struct sun6i_rtc_match_data {
 	bool				have_dcxo_status	: 1;
 	bool				have_phy_ref_gates	: 1;
 	bool				rtc_32k_single_parent	: 1;
+	unsigned int			osc24M_32k_mult;
+	unsigned int			osc24M_32k_div;
 	const struct clk_parent_data	*osc32k_fanout_parents;
 	u8				osc32k_fanout_nparents;
 };
@@ -436,6 +438,11 @@ int sun6i_rtc_ccu_probe(struct device *dev, void __iomem *reg)
 	if (data->rtc_32k_single_parent)
 		rtc_32k_init_data.num_parents = 1;
 
+	if (data->osc24M_32k_div) {
+		osc24M_32k_div_clk.mult = data->osc24M_32k_mult;
+		osc24M_32k_div_clk.div = data->osc24M_32k_div;
+	}
+
 	if (data->osc32k_fanout_nparents) {
 		osc32k_fanout_init_data.parent_data = data->osc32k_fanout_parents;
 		osc32k_fanout_init_data.num_parents = data->osc32k_fanout_nparents;

-- 
2.55.0

