From: Han Gao <gaohan@iscas.ac.cn>
Date: Sat, 14 Nov 2026 06:33:37 +0800
Subject: [PATCH 11/19] clk: sunxi-ng: sun6i-rtc: add Allwinner V861 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-v861-v1-11-eb71ec3ee523@iscas.ac.cn>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794609209; l=1736;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=FtT3g2BsbPGWBSuneJ0o2oWXhhcqpYTjSs7COAH+YU8=;
 b=EdbVxEBsgcIrqNXI47Kh+ivqcWZsMI/zxZ4SByBdzlJzw1sOBCXPcRNpv/CWAGJtOwhd6gogI
 S8IwtXnP/rhCnSIObOMgO5DcL+JYJpzv+qW7cacx0j3ueZZ7G0KvR3A
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The V861 RTC clocks are like the A523 ones, without the 32k fanout mux.

The 24 MHz to 32k divider ratio is not documented. With the RTC running
from it, the RTC kept time with the architectural timer, which uses the
same oscillator, to within 5 ppm over 15 minutes. So the divider
outputs 32768 Hz, not 24 MHz / 750.

Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 drivers/clk/sunxi-ng/ccu-sun6i-rtc.c | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/drivers/clk/sunxi-ng/ccu-sun6i-rtc.c b/drivers/clk/sunxi-ng/ccu-sun6i-rtc.c
index b3619222fef0..1abee85271a9 100644
--- a/drivers/clk/sunxi-ng/ccu-sun6i-rtc.c
+++ b/drivers/clk/sunxi-ng/ccu-sun6i-rtc.c
@@ -392,6 +392,18 @@ static const struct sun6i_rtc_match_data sun60i_a733_rtc_ccu_data = {
 	.osc32k_fanout_nparents	= ARRAY_SIZE(sun50i_r329_osc32k_fanout_parents),
 };
 
+/*
+ * The V861 has no 32k fanout mux. Its 24 MHz to 32k divider ratio is not
+ * documented; measured against the architectural timer, it generates
+ * 32768 Hz.
+ */
+static const struct sun6i_rtc_match_data sun252i_v861_rtc_ccu_data = {
+	.have_ext_osc32k	= true,
+	.have_iosc_calibration	= true,
+	.osc24M_32k_mult	= 128,
+	.osc24M_32k_div		= 93750,
+};
+
 static const struct of_device_id sun6i_rtc_ccu_match[] = {
 	{
 		.compatible	= "allwinner,sun50i-h616-rtc",
@@ -401,6 +413,10 @@ static const struct of_device_id sun6i_rtc_ccu_match[] = {
 		.compatible	= "allwinner,sun50i-r329-rtc",
 		.data		= &sun50i_r329_rtc_ccu_data,
 	},
+	{
+		.compatible	= "allwinner,sun252i-v861-rtc",
+		.data		= &sun252i_v861_rtc_ccu_data,
+	},
 	{
 		.compatible	= "allwinner,sun55i-a523-rtc",
 		.data		= &sun55i_a523_rtc_ccu_data,

-- 
2.55.0

