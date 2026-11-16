From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Mon, 16 Nov 2026 08:45:07 +0000
Subject: [PATCH v2 1/2] clk: sunxi-ng: h616: Gate the PLLs with their
 output enable bit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-h616-pll-output-gate-v2-1-a418026ffae6@gmail.com>
References: <20261116-h616-pll-output-gate-v2-0-a418026ffae6@gmail.com>
In-Reply-To: <20261116-h616-pll-output-gate-v2-0-a418026ffae6@gmail.com>
To: Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Stephen Boyd <sboyd@kernel.org>, 
 Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>
Cc: Andre Przywara <andre.przywara@arm.com>, 
 Maxime Ripard <mripard@kernel.org>, 
 Philippe Simons <simons.philippe@gmail.com>, 
 Ilya Titov <ilya.titov@wirenboard.com>, linux-clk@vger.kernel.org, 
 linux-sunxi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794818707; l=4955;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=8jODp0ifglQsXJHJh7FAOxppXVcA5WOgGJP8Gd4G8UQ=;
 b=lcVILKaaUIqNwmfPoDq7OsVPyU9PQI7Va8OL8g2mnN5zlfOtrwpotn90YOF1jCKJOVHhuRWM/
 oHmTpOlEoxABhhLOnTwnJ3zjebpso2ewYjnN8rF+mPt2w2mOgYgKyCH
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Gate the H616 PLLs with the output enable bit (27) instead of the enable
bit (31), which powers the PLL down, as the manual (3.3.3.6) recommends
and the A100, D1 and A523 drivers do. Power them up once at probe.

On an Orange Pi Zero2, powering pll-video0 down at 453 MHz crashes the
CPU doing the write.

Fixes: 88dde5e23da1 ("clk: sunxi-ng: Add support for the Allwinner H616 CCU")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/clk/sunxi-ng/ccu-sun50i-h616.c | 28 ++++++++++++++--------------
 1 file changed, 14 insertions(+), 14 deletions(-)

diff --git a/drivers/clk/sunxi-ng/ccu-sun50i-h616.c b/drivers/clk/sunxi-ng/ccu-sun50i-h616.c
index c5e5b3f78846..4037c5f022a8 100644
--- a/drivers/clk/sunxi-ng/ccu-sun50i-h616.c
+++ b/drivers/clk/sunxi-ng/ccu-sun50i-h616.c
@@ -36,7 +36,7 @@
  */
 #define SUN50I_H616_PLL_CPUX_REG	0x000
 static struct ccu_mult pll_cpux_clk = {
-	.enable		= BIT(31),
+	.enable		= BIT(27),
 	.lock		= BIT(28),
 	.mult		= _SUNXI_CCU_MULT_MIN(8, 8, 12),
 	.common		= {
@@ -50,7 +50,7 @@ static struct ccu_mult pll_cpux_clk = {
 /* Some PLLs are input * N / div1 / P. Model them as NKMP with no K */
 #define SUN50I_H616_PLL_DDR0_REG	0x010
 static struct ccu_nkmp pll_ddr0_clk = {
-	.enable		= BIT(31),
+	.enable		= BIT(27),
 	.lock		= BIT(28),
 	.n		= _SUNXI_CCU_MULT_MIN(8, 8, 12),
 	.m		= _SUNXI_CCU_DIV(1, 1), /* input divider */
@@ -65,7 +65,7 @@ static struct ccu_nkmp pll_ddr0_clk = {
 
 #define SUN50I_H616_PLL_DDR1_REG	0x018
 static struct ccu_nkmp pll_ddr1_clk = {
-	.enable		= BIT(31),
+	.enable		= BIT(27),
 	.lock		= BIT(28),
 	.n		= _SUNXI_CCU_MULT_MIN(8, 8, 12),
 	.m		= _SUNXI_CCU_DIV(1, 1), /* input divider */
@@ -80,7 +80,7 @@ static struct ccu_nkmp pll_ddr1_clk = {
 
 #define SUN50I_H616_PLL_PERIPH0_REG	0x020
 static struct ccu_nkmp pll_periph0_clk = {
-	.enable		= BIT(31),
+	.enable		= BIT(27),
 	.lock		= BIT(28),
 	.n		= _SUNXI_CCU_MULT_MIN(8, 8, 12),
 	.m		= _SUNXI_CCU_DIV(1, 1), /* input divider */
@@ -97,7 +97,7 @@ static struct ccu_nkmp pll_periph0_clk = {
 
 #define SUN50I_H616_PLL_PERIPH1_REG	0x028
 static struct ccu_nkmp pll_periph1_clk = {
-	.enable		= BIT(31),
+	.enable		= BIT(27),
 	.lock		= BIT(28),
 	.n		= _SUNXI_CCU_MULT_MIN(8, 8, 12),
 	.m		= _SUNXI_CCU_DIV(1, 1), /* input divider */
@@ -114,7 +114,7 @@ static struct ccu_nkmp pll_periph1_clk = {
 
 #define SUN50I_H616_PLL_GPU_REG		0x030
 static struct ccu_nkmp pll_gpu_clk = {
-	.enable		= BIT(31),
+	.enable		= BIT(27),
 	.lock		= BIT(28),
 	.n		= _SUNXI_CCU_MULT_MIN(8, 8, 12),
 	.m		= _SUNXI_CCU_DIV(1, 1), /* input divider */
@@ -133,7 +133,7 @@ static struct ccu_nkmp pll_gpu_clk = {
  */
 #define SUN50I_H616_PLL_VIDEO0_REG	0x040
 static struct ccu_nm pll_video0_clk = {
-	.enable		= BIT(31),
+	.enable		= BIT(27),
 	.lock		= BIT(28),
 	.n		= _SUNXI_CCU_MULT_MIN(8, 8, 12),
 	.m		= _SUNXI_CCU_DIV(1, 1), /* input divider */
@@ -151,7 +151,7 @@ static struct ccu_nm pll_video0_clk = {
 
 #define SUN50I_H616_PLL_VIDEO1_REG	0x048
 static struct ccu_nm pll_video1_clk = {
-	.enable		= BIT(31),
+	.enable		= BIT(27),
 	.lock		= BIT(28),
 	.n		= _SUNXI_CCU_MULT_MIN(8, 8, 12),
 	.m		= _SUNXI_CCU_DIV(1, 1), /* input divider */
@@ -169,7 +169,7 @@ static struct ccu_nm pll_video1_clk = {
 
 #define SUN50I_H616_PLL_VIDEO2_REG	0x050
 static struct ccu_nm pll_video2_clk = {
-	.enable		= BIT(31),
+	.enable		= BIT(27),
 	.lock		= BIT(28),
 	.n		= _SUNXI_CCU_MULT_MIN(8, 8, 12),
 	.m		= _SUNXI_CCU_DIV(1, 1), /* input divider */
@@ -187,7 +187,7 @@ static struct ccu_nm pll_video2_clk = {
 
 #define SUN50I_H616_PLL_VE_REG		0x058
 static struct ccu_nkmp pll_ve_clk = {
-	.enable		= BIT(31),
+	.enable		= BIT(27),
 	.lock		= BIT(28),
 	.n		= _SUNXI_CCU_MULT_MIN(8, 8, 12),
 	.m		= _SUNXI_CCU_DIV(1, 1), /* input divider */
@@ -202,7 +202,7 @@ static struct ccu_nkmp pll_ve_clk = {
 
 #define SUN50I_H616_PLL_DE_REG		0x060
 static struct ccu_nkmp pll_de_clk = {
-	.enable		= BIT(31),
+	.enable		= BIT(27),
 	.lock		= BIT(28),
 	.n		= _SUNXI_CCU_MULT_MIN(8, 8, 12),
 	.m		= _SUNXI_CCU_DIV(1, 1), /* input divider */
@@ -229,7 +229,7 @@ static struct ccu_sdm_setting pll_audio_sdm_table[] = {
 
 #define SUN50I_H616_PLL_AUDIO_REG	0x078
 static struct ccu_nm pll_audio_hs_clk = {
-	.enable		= BIT(31),
+	.enable		= BIT(27),
 	.lock		= BIT(28),
 	.n		= _SUNXI_CCU_MULT_MIN(8, 8, 12),
 	.m		= _SUNXI_CCU_DIV(16, 6),
@@ -1183,10 +1183,10 @@ static int sun50i_h616_ccu_probe(struct platform_device *pdev)
 	if (IS_ERR(reg))
 		return PTR_ERR(reg);
 
-	/* Enable the lock bits and the output enable bits on all PLLs */
+	/* Power up and lock-enable all PLLs; bit 27 gates them (3.3.3.6) */
 	for (i = 0; i < ARRAY_SIZE(pll_regs); i++) {
 		val = readl(reg + pll_regs[i]);
-		val |= BIT(29) | BIT(27);
+		val |= BIT(31) | BIT(29);
 		writel(val, reg + pll_regs[i]);
 	}
 

-- 
2.55.0

