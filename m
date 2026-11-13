From: Han Gao <gaohan@iscas.ac.cn>
Date: Sat, 14 Nov 2026 06:33:35 +0800
Subject: [PATCH 09/19] clk: sunxi-ng: sun6i-rtc: allow variants without a
 32k fanout mux
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-v861-v1-9-eb71ec3ee523@iscas.ac.cn>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794609209; l=1175;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=IjLpSZK52EbD2RXTMonjExKRJ8v5cc72rNy+1BJSluw=;
 b=u4Lz8S44b3ToLaBsujWDUTqNOl1o4PgdcDpKDa/XwGcMxJt8sFC/p1XpwLiV3n6qI2MWpZyKs
 moCFg0R6xxABDqHcZkHiY1smc7VBl2uZEKHM2N3ESxOzRNNPALUPA2A
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some RTC clock blocks have no 32 kHz fanout mux. Do not register the
fanout clock for variants whose match data lists no fanout parents.

Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 drivers/clk/sunxi-ng/ccu-sun6i-rtc.c | 8 ++++++--
 1 file changed, 6 insertions(+), 2 deletions(-)

diff --git a/drivers/clk/sunxi-ng/ccu-sun6i-rtc.c b/drivers/clk/sunxi-ng/ccu-sun6i-rtc.c
index 98ae10307f43..0e40fd5fa624 100644
--- a/drivers/clk/sunxi-ng/ccu-sun6i-rtc.c
+++ b/drivers/clk/sunxi-ng/ccu-sun6i-rtc.c
@@ -436,8 +436,12 @@ int sun6i_rtc_ccu_probe(struct device *dev, void __iomem *reg)
 	if (data->rtc_32k_single_parent)
 		rtc_32k_init_data.num_parents = 1;
 
-	osc32k_fanout_init_data.parent_data = data->osc32k_fanout_parents;
-	osc32k_fanout_init_data.num_parents = data->osc32k_fanout_nparents;
+	if (data->osc32k_fanout_nparents) {
+		osc32k_fanout_init_data.parent_data = data->osc32k_fanout_parents;
+		osc32k_fanout_init_data.num_parents = data->osc32k_fanout_nparents;
+	} else {
+		sun6i_rtc_ccu_hw_clks.hws[CLK_OSC32K_FANOUT] = NULL;
+	}
 
 	if (data->have_dcxo_status)
 		sun6i_rtc_ccu_hw_clks.hws[CLK_OSC24M_32K_DIV] =

-- 
2.55.0

