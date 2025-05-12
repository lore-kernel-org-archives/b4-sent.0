From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Mon, 12 May 2025 15:46:50 +0100
Subject: [PATCH v5 7/7] clk: clk-axi-clkgen: fix coding style issues
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250512-dev-axi-clkgen-limits-v5-7-a86b9a368e05@analog.com>
References: <20250512-dev-axi-clkgen-limits-v5-0-a86b9a368e05@analog.com>
In-Reply-To: <20250512-dev-axi-clkgen-limits-v5-0-a86b9a368e05@analog.com>
To: linux-clk@vger.kernel.org, linux-fpga@vger.kernel.org, 
 dmaengine@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 linux-iio@vger.kernel.org, linux-pwm@vger.kernel.org, 
 linux-spi@vger.kernel.org
Cc: Stephen Boyd <sboyd@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Moritz Fischer <mdf@kernel.org>, Wu Hao <hao.wu@intel.com>, 
 Xu Yilun <yilun.xu@intel.com>, Tom Rix <trix@redhat.com>, 
 Vinod Koul <vkoul@kernel.org>, Jean Delvare <jdelvare@suse.com>, 
 Guenter Roeck <linux@roeck-us.net>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Trevor Gamblin <tgamblin@baylibre.com>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Mark Brown <broonie@kernel.org>, 
 Mike Turquette <mturquette@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747061206; l=8991;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=Y+M/2iwPpvl3BQp8DfynaYnK0XuWtg7TRt1YeO+53iU=;
 b=0ZZPIDDC2pULGNDAjHWnky4X/Lwq312hJECha7Oh29gbZeX9d5hUwfUZYy9kKkf9pz3PwZV4y
 lFEziBKwfoXBPKxMGtd5o4+4CxBb4P1y+tL4eGO29svOObfQvVeFxk+
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is just cosmetics and so no functional changes intended.

While at it, sort header in alphabetical order.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/clk/clk-axi-clkgen.c | 85 ++++++++++++++++++++++----------------------
 1 file changed, 43 insertions(+), 42 deletions(-)

diff --git a/drivers/clk/clk-axi-clkgen.c b/drivers/clk/clk-axi-clkgen.c
index 40ca03204010a15078f90935effbe58c4c3a00bf..a268d5ccf5798dd20cc1328369c2c9c45b37282a 100644
--- a/drivers/clk/clk-axi-clkgen.c
+++ b/drivers/clk/clk-axi-clkgen.c
@@ -6,18 +6,18 @@
  *  Author: Lars-Peter Clausen <lars@metafoo.de>
  */
 
+#include <linux/adi-axi-common.h>
 #include <linux/bits.h>
-#include <linux/platform_device.h>
 #include <linux/clk.h>
 #include <linux/clk-provider.h>
-#include <linux/slab.h>
+#include <linux/err.h>
 #include <linux/io.h>
-#include <linux/of.h>
 #include <linux/module.h>
 #include <linux/mod_devicetable.h>
-#include <linux/err.h>
-
-#include <linux/adi-axi-common.h>
+#include <linux/of.h>
+#include <linux/platform_device.h>
+#include <linux/slab.h>
+#include <linux/types.h>
 
 #define AXI_CLKGEN_V2_REG_RESET		0x40
 #define AXI_CLKGEN_V2_REG_CLKSEL	0x44
@@ -97,7 +97,7 @@ static uint32_t axi_clkgen_lookup_filter(unsigned int m)
 	}
 }
 
-static const uint32_t axi_clkgen_lock_table[] = {
+static const u32 axi_clkgen_lock_table[] = {
 	0x060603e8, 0x060603e8, 0x080803e8, 0x0b0b03e8,
 	0x0e0e03e8, 0x111103e8, 0x131303e8, 0x161603e8,
 	0x191903e8, 0x1c1c03e8, 0x1f1f0384, 0x1f1f0339,
@@ -109,7 +109,7 @@ static const uint32_t axi_clkgen_lock_table[] = {
 	0x1f1f012c, 0x1f1f0113, 0x1f1f0113, 0x1f1f0113,
 };
 
-static uint32_t axi_clkgen_lookup_lock(unsigned int m)
+static u32 axi_clkgen_lookup_lock(unsigned int m)
 {
 	if (m < ARRAY_SIZE(axi_clkgen_lock_table))
 		return axi_clkgen_lock_table[m];
@@ -131,8 +131,9 @@ static const struct axi_clkgen_limits axi_clkgen_zynq_default_limits = {
 };
 
 static void axi_clkgen_calc_params(const struct axi_clkgen_limits *limits,
-	unsigned long fin, unsigned long fout,
-	unsigned int *best_d, unsigned int *best_m, unsigned int *best_dout)
+				   unsigned long fin, unsigned long fout,
+				   unsigned int *best_d, unsigned int *best_m,
+				   unsigned int *best_dout)
 {
 	unsigned long d, d_min, d_max, _d_min, _d_max;
 	unsigned long m, m_min, m_max;
@@ -199,9 +200,9 @@ struct axi_clkgen_div_params {
 };
 
 static void axi_clkgen_calc_clk_params(unsigned int divider,
-	unsigned int frac_divider, struct axi_clkgen_div_params *params)
+				       unsigned int frac_divider,
+				       struct axi_clkgen_div_params *params)
 {
-
 	memset(params, 0x0, sizeof(*params));
 
 	if (divider == 1) {
@@ -229,7 +230,7 @@ static void axi_clkgen_calc_clk_params(unsigned int divider,
 		if (params->edge == 0 || frac_divider == 1)
 			params->low--;
 		if (((params->edge == 0) ^ (frac_divider == 1)) ||
-			(divider == 2 && frac_divider == 1))
+		    (divider == 2 && frac_divider == 1))
 			params->frac_wf_f = 1;
 
 		params->frac_phase = params->edge * 4 + frac_divider / 2;
@@ -237,13 +238,13 @@ static void axi_clkgen_calc_clk_params(unsigned int divider,
 }
 
 static void axi_clkgen_write(struct axi_clkgen *axi_clkgen,
-	unsigned int reg, unsigned int val)
+			     unsigned int reg, unsigned int val)
 {
 	writel(val, axi_clkgen->base + reg);
 }
 
 static void axi_clkgen_read(struct axi_clkgen *axi_clkgen,
-	unsigned int reg, unsigned int *val)
+			    unsigned int reg, unsigned int *val)
 {
 	*val = readl(axi_clkgen->base + reg);
 }
@@ -264,7 +265,7 @@ static int axi_clkgen_wait_non_busy(struct axi_clkgen *axi_clkgen)
 }
 
 static int axi_clkgen_mmcm_read(struct axi_clkgen *axi_clkgen,
-	unsigned int reg, unsigned int *val)
+				unsigned int reg, unsigned int *val)
 {
 	unsigned int reg_val;
 	int ret;
@@ -288,7 +289,8 @@ static int axi_clkgen_mmcm_read(struct axi_clkgen *axi_clkgen,
 }
 
 static int axi_clkgen_mmcm_write(struct axi_clkgen *axi_clkgen,
-	unsigned int reg, unsigned int val, unsigned int mask)
+				 unsigned int reg, unsigned int val,
+				 unsigned int mask)
 {
 	unsigned int reg_val = 0;
 	int ret;
@@ -309,8 +311,7 @@ static int axi_clkgen_mmcm_write(struct axi_clkgen *axi_clkgen,
 	return 0;
 }
 
-static void axi_clkgen_mmcm_enable(struct axi_clkgen *axi_clkgen,
-	bool enable)
+static void axi_clkgen_mmcm_enable(struct axi_clkgen *axi_clkgen, bool enable)
 {
 	unsigned int val = AXI_CLKGEN_V2_RESET_ENABLE;
 
@@ -326,31 +327,31 @@ static struct axi_clkgen *clk_hw_to_axi_clkgen(struct clk_hw *clk_hw)
 }
 
 static void axi_clkgen_set_div(struct axi_clkgen *axi_clkgen,
-	unsigned int reg1, unsigned int reg2, unsigned int reg3,
-	struct axi_clkgen_div_params *params)
+			       unsigned int reg1, unsigned int reg2,
+			       unsigned int reg3,
+			       struct axi_clkgen_div_params *params)
 {
 	axi_clkgen_mmcm_write(axi_clkgen, reg1,
-		(params->high << 6) | params->low, 0xefff);
+			      (params->high << 6) | params->low, 0xefff);
 	axi_clkgen_mmcm_write(axi_clkgen, reg2,
-		(params->frac << 12) | (params->frac_en << 11) |
-		(params->frac_wf_r << 10) | (params->edge << 7) |
-		(params->nocount << 6), 0x7fff);
+			      (params->frac << 12) | (params->frac_en << 11) |
+			      (params->frac_wf_r << 10) | (params->edge << 7) |
+			      (params->nocount << 6), 0x7fff);
 	if (reg3 != 0) {
 		axi_clkgen_mmcm_write(axi_clkgen, reg3,
-			(params->frac_phase << 11) | (params->frac_wf_f << 10), 0x3c00);
+				      (params->frac_phase << 11) | (params->frac_wf_f << 10),
+				      0x3c00);
 	}
 }
 
-static int axi_clkgen_set_rate(struct clk_hw *clk_hw,
-	unsigned long rate, unsigned long parent_rate)
+static int axi_clkgen_set_rate(struct clk_hw *clk_hw, unsigned long rate,
+			       unsigned long parent_rate)
 {
 	struct axi_clkgen *axi_clkgen = clk_hw_to_axi_clkgen(clk_hw);
 	const struct axi_clkgen_limits *limits = &axi_clkgen->limits;
 	unsigned int d, m, dout;
 	struct axi_clkgen_div_params params;
-	uint32_t power = 0;
-	uint32_t filter;
-	uint32_t lock;
+	u32 power = 0, filter, lock;
 
 	if (parent_rate == 0 || rate == 0)
 		return -EINVAL;
@@ -370,22 +371,22 @@ static int axi_clkgen_set_rate(struct clk_hw *clk_hw,
 
 	axi_clkgen_calc_clk_params(dout >> 3, dout & 0x7, &params);
 	axi_clkgen_set_div(axi_clkgen,  MMCM_REG_CLKOUT0_1, MMCM_REG_CLKOUT0_2,
-		MMCM_REG_CLKOUT5_2, &params);
+			   MMCM_REG_CLKOUT5_2, &params);
 
 	axi_clkgen_calc_clk_params(d, 0, &params);
 	axi_clkgen_mmcm_write(axi_clkgen, MMCM_REG_CLK_DIV,
-		(params.edge << 13) | (params.nocount << 12) |
-		(params.high << 6) | params.low, 0x3fff);
+			      (params.edge << 13) | (params.nocount << 12) |
+			      (params.high << 6) | params.low, 0x3fff);
 
 	axi_clkgen_calc_clk_params(m >> 3, m & 0x7, &params);
 	axi_clkgen_set_div(axi_clkgen,  MMCM_REG_CLK_FB1, MMCM_REG_CLK_FB2,
-		MMCM_REG_CLKOUT6_2, &params);
+			   MMCM_REG_CLKOUT6_2, &params);
 
 	axi_clkgen_mmcm_write(axi_clkgen, MMCM_REG_LOCK1, lock & 0x3ff, 0x3ff);
 	axi_clkgen_mmcm_write(axi_clkgen, MMCM_REG_LOCK2,
-		(((lock >> 16) & 0x1f) << 10) | 0x1, 0x7fff);
+			      (((lock >> 16) & 0x1f) << 10) | 0x1, 0x7fff);
 	axi_clkgen_mmcm_write(axi_clkgen, MMCM_REG_LOCK3,
-		(((lock >> 24) & 0x1f) << 10) | 0x3e9, 0x7fff);
+			      (((lock >> 24) & 0x1f) << 10) | 0x3e9, 0x7fff);
 	axi_clkgen_mmcm_write(axi_clkgen, MMCM_REG_FILTER1, filter >> 16, 0x9900);
 	axi_clkgen_mmcm_write(axi_clkgen, MMCM_REG_FILTER2, filter, 0x9900);
 
@@ -414,7 +415,7 @@ static int axi_clkgen_determine_rate(struct clk_hw *hw,
 }
 
 static unsigned int axi_clkgen_get_div(struct axi_clkgen *axi_clkgen,
-	unsigned int reg1, unsigned int reg2)
+				       unsigned int reg1, unsigned int reg2)
 {
 	unsigned int val1, val2;
 	unsigned int div;
@@ -441,7 +442,7 @@ static unsigned int axi_clkgen_get_div(struct axi_clkgen *axi_clkgen,
 }
 
 static unsigned long axi_clkgen_recalc_rate(struct clk_hw *clk_hw,
-	unsigned long parent_rate)
+					    unsigned long parent_rate)
 {
 	struct axi_clkgen *axi_clkgen = clk_hw_to_axi_clkgen(clk_hw);
 	unsigned int d, m, dout;
@@ -449,9 +450,9 @@ static unsigned long axi_clkgen_recalc_rate(struct clk_hw *clk_hw,
 	unsigned int val;
 
 	dout = axi_clkgen_get_div(axi_clkgen, MMCM_REG_CLKOUT0_1,
-		MMCM_REG_CLKOUT0_2);
+				  MMCM_REG_CLKOUT0_2);
 	m = axi_clkgen_get_div(axi_clkgen, MMCM_REG_CLK_FB1,
-		MMCM_REG_CLK_FB2);
+			       MMCM_REG_CLK_FB2);
 
 	axi_clkgen_mmcm_read(axi_clkgen, MMCM_REG_CLK_DIV, &val);
 	if (val & MMCM_CLK_DIV_NOCOUNT)
@@ -624,7 +625,7 @@ static int axi_clkgen_probe(struct platform_device *pdev)
 
 	clk_name = pdev->dev.of_node->name;
 	of_property_read_string(pdev->dev.of_node, "clock-output-names",
-		&clk_name);
+				&clk_name);
 
 	init.name = clk_name;
 	init.ops = &axi_clkgen_ops;

-- 
2.49.0

