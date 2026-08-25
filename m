From: Rudraksha Gupta <guptarud@gmail.com>
Date: Mon, 24 Aug 2026 22:18:17 -0700
Subject: [PATCH v2 2/2] clk: rk808: Select the clock function of CLK32KOUT2
 on the RK818
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260824-ppp_connectivity-v2-2-a4b0e11cd62c@gmail.com>
References: <20260824-ppp_connectivity-v2-0-a4b0e11cd62c@gmail.com>
In-Reply-To: <20260824-ppp_connectivity-v2-0-a4b0e11cd62c@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Lee Jones <lee@kernel.org>, Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney@redhat.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Rudraksha Gupta <guptarud@gmail.com>, linux-clk@vger.kernel.org, 
 mfd@lists.linux.dev, Martijn Braam <martijn@brixit.nl>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787635096; l=3455;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=btBxv1+lK3NuJ3bLMeNAP2UZMK2asFecMzZxkL+Msaw=;
 b=hc3J13W/s34ea0bH6JLfnQLZaWIagLwAHIyZadpZ16gudpVF+ttaRbDdXkMoHA+ARJ6eYeZ0m
 tdH+itjfuWeAqhiMtIVBnJgnrFLkeqGRqL+4Xo8BRLA3st+1wFsA2iB
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Martijn Braam <martijn@brixit.nl>

On the RK818 the CLK32KOUT2 pin is shared between the 32.768 kHz clock
output and a recovery function, selected by bit 1 of RK808_CLK32OUT_REG.
CLK32KOUT2_EN only takes effect on the clock function, so the output can
be enabled and still be silent. The datasheet resets the register to
zero, but that cannot be relied on: on the Pine64 PinePhone Pro it reads
0x03 once Linux is up, leaving the wifi and bluetooth without their
32.768 kHz reference.

Select the clock function when the output is prepared, so that it can
also be given back, and report the output as prepared only when it is
enabled and on the clock function. The bit is not defined on the other
variants, so give the RK818 its own clk_ops. Boards that never take the
clock are unaffected.

Based on an out-of-tree patch by Martijn Braam & Kamil Trzciński,
carried by Ondrej Jirman.

Signed-off-by: Martijn Braam <martijn@brixit.nl>
Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
 drivers/clk/clk-rk808.c   | 46 +++++++++++++++++++++++++++++++++++++++++++++-
 include/linux/mfd/rk808.h |  1 +
 2 files changed, 46 insertions(+), 1 deletion(-)

diff --git a/drivers/clk/clk-rk808.c b/drivers/clk/clk-rk808.c
index 5a75b5c91555..4aabe0234769 100644
--- a/drivers/clk/clk-rk808.c
+++ b/drivers/clk/clk-rk808.c
@@ -71,6 +71,49 @@ static const struct clk_ops rk808_clkout2_ops = {
 	.recalc_rate = rk808_clkout_recalc_rate,
 };
 
+static int rk818_clkout2_enable(struct clk_hw *hw, bool enable)
+{
+	struct rk808_clkout *rk808_clkout = container_of(hw,
+							 struct rk808_clkout,
+							 clkout2_hw);
+
+	return regmap_update_bits(rk808_clkout->regmap, RK808_CLK32OUT_REG,
+				  RK818_CLK32KOUT2_FUNC_MASK | CLK32KOUT2_EN,
+				  enable ? CLK32KOUT2_EN : 0);
+}
+
+static int rk818_clkout2_prepare(struct clk_hw *hw)
+{
+	return rk818_clkout2_enable(hw, true);
+}
+
+static void rk818_clkout2_unprepare(struct clk_hw *hw)
+{
+	rk818_clkout2_enable(hw, false);
+}
+
+static int rk818_clkout2_is_prepared(struct clk_hw *hw)
+{
+	struct rk808_clkout *rk808_clkout = container_of(hw,
+							 struct rk808_clkout,
+							 clkout2_hw);
+	u32 val;
+
+	int ret = regmap_read(rk808_clkout->regmap, RK808_CLK32OUT_REG, &val);
+
+	if (ret < 0)
+		return 0;
+
+	return (val & (RK818_CLK32KOUT2_FUNC_MASK | CLK32KOUT2_EN)) == CLK32KOUT2_EN;
+}
+
+static const struct clk_ops rk818_clkout2_ops = {
+	.prepare = rk818_clkout2_prepare,
+	.unprepare = rk818_clkout2_unprepare,
+	.is_prepared = rk818_clkout2_is_prepared,
+	.recalc_rate = rk808_clkout_recalc_rate,
+};
+
 static struct clk_hw *
 of_clk_rk808_get(struct of_phandle_args *clkspec, void *data)
 {
@@ -134,11 +177,12 @@ static const struct clk_ops *rkpmic_get_ops(long variant)
 	case RK809_ID:
 	case RK817_ID:
 		return &rk817_clkout2_ops;
+	case RK818_ID:
+		return &rk818_clkout2_ops;
 	/*
 	 * For the default case, it match the following PMIC type.
 	 * RK805_ID
 	 * RK808_ID
-	 * RK818_ID
 	 */
 	default:
 		return &rk808_clkout2_ops;
diff --git a/include/linux/mfd/rk808.h b/include/linux/mfd/rk808.h
index 7ffc904c864c..e3cb586d34a0 100644
--- a/include/linux/mfd/rk808.h
+++ b/include/linux/mfd/rk808.h
@@ -1051,6 +1051,7 @@ enum rk806_dvs_mode {
 
 #define VOUT_LO_INT	BIT(0)
 #define CLK32KOUT2_EN	BIT(0)
+#define RK818_CLK32KOUT2_FUNC_MASK	BIT(1)
 
 #define TEMP105C			0x08
 #define TEMP115C			0x0c

-- 
2.55.0

