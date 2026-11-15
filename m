From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sun, 15 Nov 2026 08:31:42 +0000
Subject: [PATCH] clk: sunxi-ng: h616: Gate the PLLs with their output
 enable bit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-h616-pll-output-gate-v1-1-4cb3fc4d6c48@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQqDMBBA4avIrDvg2BCIV5EuYjLVKaIhP1IQ7
 25sl9/ivQMSR+EEfXNA5F2SbGsFPRpws10nRvHV0LWdJiKFsyaNYVlwKzmUjJPNjM74p1dWtYY
 N1DREfsv3tx1ef6cyftjl+wXneQFswm10eAAAAA==
X-Change-ID: 20261114-h616-pll-output-gate-c9d3d4a409e9
To: Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Stephen Boyd <sboyd@kernel.org>, 
 Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>
Cc: Andre Przywara <andre.przywara@arm.com>, linux-clk@vger.kernel.org, 
 linux-sunxi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794731501; l=5371;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=5Vv85VfVPju/Igwsb+cpuc7jYn8XWlxuDjDD7l4TQCg=;
 b=QCRHF0O3JplLAB6RsnHmUj4RBDxn54eIU3pvv4s3WPOBKl1ni4J/ys9QUw1OQKW1ERki6XpdX
 WcXhHQLNsjxC4yOr27rLRlEnzJtvn0NIrqp2V24ANDTjX/Rk8AxfZpV
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
No Cc: stable: the crash needs out-of-tree H616 HDMI. Tested on an
Orange Pi Zero2 (7.3.4 with HDMI patches): the failing mode set 40
times without an oops. Idle power not measured.

Developed with Claude (Anthropic); I reviewed it.
---
 drivers/clk/sunxi-ng/ccu-sun50i-h616.c | 31 +++++++++++++++++++------------
 1 file changed, 19 insertions(+), 12 deletions(-)

diff --git a/drivers/clk/sunxi-ng/ccu-sun50i-h616.c b/drivers/clk/sunxi-ng/ccu-sun50i-h616.c
index 955c614830fa..da4156b39c2c 100644
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
@@ -1214,6 +1214,13 @@ static int sun50i_h616_ccu_probe(struct platform_device *pdev)
 	val |= BIT(0);
 	writel(val, reg + SUN50I_H616_PLL_AUDIO_REG);
 
+	/* Keep the PLLs powered and gate them with bit 27 (manual 3.3.3.6). */
+	for (i = 0; i < ARRAY_SIZE(pll_regs); i++) {
+		val = readl(reg + pll_regs[i]);
+		val |= BIT(31);
+		writel(val, reg + pll_regs[i]);
+	}
+
 	/*
 	 * Set the input-divider for the gpu1 clock to 3, to reach a safe 400 MHz.
 	 */

---
base-commit: 280af24c860569000b375edda6436ba8e3ee4b3a
change-id: 20261114-h616-pll-output-gate-c9d3d4a409e9

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

