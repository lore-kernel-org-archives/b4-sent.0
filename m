From: Jason Yang <jason98166@gmail.com>
Date: Mon, 10 Aug 2026 20:10:12 +0800
Subject: [PATCH v3 4/5] phy: rockchip-samsung-dcphy: model TX and RX as
 separate PHYs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260810-dcphy-rx-v1-v3-4-a2d25c29adfc@gmail.com>
References: <20260810-dcphy-rx-v1-v3-0-a2d25c29adfc@gmail.com>
In-Reply-To: <20260810-dcphy-rx-v1-v3-0-a2d25c29adfc@gmail.com>
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Guochun Huang <hero.huang@rock-chips.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: Michael Riesch <michael.riesch@collabora.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 linux-phy@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Jason Yang <jason98166@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786363808; l=13919;
 i=jason98166@gmail.com; s=20260721; h=from:subject:message-id;
 bh=aD/WXWvU1ReVxV85EUeLFEd6/rd2JzbuaAKFgp46rz0=;
 b=AcsWfFOgd6rB9Q5OzxQD+wki6SvcCAnJtoROKZCsGza2DNFcyylrrbm3Aw9vyCztWQsqo6zfa
 +SRqrwIW8leAXggj2bz30UFtFFbK/+MEWUgvThgLmnnKQtcwKktQsgy
X-Developer-Key: i=jason98166@gmail.com; a=ed25519;
 pk=xQmD001Q/ooHl39PxyQtusbUQmgbOsSfpFryRVWZ/k4=
X-Endpoint-Received: by B4 Relay for jason98166@gmail.com/20260721 with auth_id=887
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The DC-PHY drives a MIPI DSI transmitter and a MIPI CSI receiver, and
on RK3588 both can be wired up at the same time. The PHY core
reference-counts power_on() per struct phy, so a single struct phy
cannot bring the two up independently.

Register one struct phy for each and move the per-PHY state (PHY type
and lane count) into a new struct samsung_mipi_phy. of_xlate() maps
the single cell onto the two PHYs: PHY_TYPE_DSI selects the
transmitter and PHY_TYPE_CSI the receiver, while PHY_TYPE_DPHY and
PHY_TYPE_CPHY keep selecting the transmitter so existing device trees
keep working. Values outside those four are now rejected there instead
of failing later in power_on(); no in-tree devicetree uses any other
value.

The two PHYs share the common block (BIAS, and the PLL that only the
transmitter drives - RK3588 TRM section 22.2) and the block-level APB
reset. That reset has to be assumed to reset a running peer's PLL,
timing and lane configuration as well, so it must not be pulsed while
the peer is up. Guard it with a use count taken and dropped inside the
power helpers, and program the shared BIAS references on the same
transition away from zero: a count rather than a one-shot flag, so
that once every user is gone the next bring-up gets the reset and the
BIAS programming again. There is nothing to write on release itself -
the BIAS registers hold only static analog settings, with no enable
bit (section 22.4.3). A PHY that powers on while its peer is already
up therefore no longer gets the block-level reset; its bring-up
sequence programs the configuration it uses.

Folding the BIAS programming into that helper also moves it ahead of
the per-PHY reset assert, where the TRM's worked example puts it after
(section 22.6.4.1). That is safe: neither M_RESETN nor S_RESETN covers
the BIAS registers (section 22.6.1.2), and the values written are
those registers' reset defaults (section 22.4.2).

The receiver stays rejected in configure(), power_on() and power_off()
until the receiver bring-up is added in the next change.

Signed-off-by: Jason Yang <jason98166@gmail.com>
Assisted-by: Claude:claude-fable-5
---
 drivers/phy/rockchip/phy-rockchip-samsung-dcphy.c | 188 ++++++++++++++++++----
 1 file changed, 155 insertions(+), 33 deletions(-)

diff --git a/drivers/phy/rockchip/phy-rockchip-samsung-dcphy.c b/drivers/phy/rockchip/phy-rockchip-samsung-dcphy.c
index 99ca0e1cc574..09dbcf438f99 100644
--- a/drivers/phy/rockchip/phy-rockchip-samsung-dcphy.c
+++ b/drivers/phy/rockchip/phy-rockchip-samsung-dcphy.c
@@ -11,8 +11,10 @@
 #include <linux/hw_bitfield.h>
 #include <linux/init.h>
 #include <linux/kernel.h>
+#include <linux/lockdep.h>
 #include <linux/mfd/syscon.h>
 #include <linux/module.h>
+#include <linux/mutex.h>
 #include <linux/of.h>
 #include <linux/phy/phy.h>
 #include <linux/platform_device.h>
@@ -280,6 +282,24 @@ struct samsung_mipi_dcphy_plat_data {
 	u32 dphy_tx_max_lane_kbps;
 };
 
+struct samsung_mipi_dcphy;
+
+/* Index of the two PHYs the block exposes. */
+enum {
+	SAMSUNG_MIPI_TX,
+	SAMSUNG_MIPI_RX,
+	SAMSUNG_MIPI_PHY_MAX,
+};
+
+struct samsung_mipi_phy {
+	struct phy *phy;
+	struct samsung_mipi_dcphy *parent;
+	u8 id;
+	/* Electrical layer (PHY_TYPE_DPHY/CPHY), not the DT cell value. */
+	u8 type;
+	unsigned int lanes;
+};
+
 struct samsung_mipi_dcphy {
 	struct device *dev;
 	struct clk *ref_clk;
@@ -290,9 +310,14 @@ struct samsung_mipi_dcphy {
 	struct reset_control *s_phy_rst;
 	struct reset_control *apb_rst;
 	struct reset_control *grf_apb_rst;
-	unsigned int lanes;
-	struct phy *phy;
-	u8 type;
+	struct samsung_mipi_phy phys[SAMSUNG_MIPI_PHY_MAX];
+	/* Serialises the two PHYs' access to the shared common block. */
+	struct mutex lock;
+	/*
+	 * Number of powered-on PHYs using the common block (APB reset
+	 * and BIAS references).  Written under the lock above.
+	 */
+	unsigned int common_users;
 
 	const struct samsung_mipi_dcphy_plat_data *pdata;
 	struct {
@@ -973,8 +998,25 @@ struct samsung_mipi_dphy_timing samsung_mipi_dphy_timing_table[] = {
 	{  80,  2,   0,  0, 28,  5,  0, 22,  2,  0,  5},
 };
 
-static void samsung_mipi_dcphy_bias_block_enable(struct samsung_mipi_dcphy *samsung)
+/*
+ * The APB reset is block-level and has to be assumed to return the whole
+ * register file to the defaults of TRM section 22.4.2, which would leave
+ * a running peer PHY unconfigured - so it may only run while neither PHY
+ * is powered.  The pairing of get and put relies on the phy core calling
+ * power_on/power_off only on the 0<->1 transitions of each phy's own
+ * power_count.
+ */
+static void samsung_mipi_dcphy_common_get(struct samsung_mipi_dcphy *samsung)
 {
+	lockdep_assert_held(&samsung->lock);
+
+	if (samsung->common_users++)
+		return;
+
+	reset_control_assert(samsung->apb_rst);
+	udelay(1);
+	reset_control_deassert(samsung->apb_rst);
+
 	regmap_write(samsung->regmap, BIAS_CON0, I_DEV_DIV_6 | I_RES_100_2UA);
 	regmap_write(samsung->regmap, BIAS_CON1, I_VBG_SEL_820MV | I_BGR_VREF_820MV |
 						 I_LADDER_1_00V);
@@ -984,18 +1026,34 @@ static void samsung_mipi_dcphy_bias_block_enable(struct samsung_mipi_dcphy *sams
 	/* default output voltage select:
 	 * dphy: 400mv
 	 * cphy: 530mv
+	 * C-PHY is not supported yet, so the D-PHY value serves both PHYs.
 	 */
 	regmap_update_bits(samsung->regmap, BIAS_CON4,
 			   I_MUX_SEL_MASK, I_MUX_400MV);
 }
 
+/*
+ * Nothing to undo on the way down: the BIAS registers hold only static
+ * analog settings - current and voltage references, the bandgap chopper
+ * divider and the D-PHY/C-PHY level select - with no enable bit.
+ */
+static void samsung_mipi_dcphy_common_put(struct samsung_mipi_dcphy *samsung)
+{
+	lockdep_assert_held(&samsung->lock);
+
+	if (WARN_ON(!samsung->common_users))
+		return;
+
+	samsung->common_users--;
+}
+
 static void samsung_mipi_dphy_lane_enable(struct samsung_mipi_dcphy *samsung)
 {
 	regmap_write(samsung->regmap, DPHY_MC_GNR_CON1, T_PHY_READY(0x2000));
 	regmap_update_bits(samsung->regmap, DPHY_MC_GNR_CON0,
 			   PHY_ENABLE, PHY_ENABLE);
 
-	switch (samsung->lanes) {
+	switch (samsung->phys[SAMSUNG_MIPI_TX].lanes) {
 	case 4:
 		regmap_write(samsung->regmap, DPHY_MD3_GNR_CON1,
 			     T_PHY_READY(0x2000));
@@ -1026,7 +1084,7 @@ static void samsung_mipi_dphy_lane_enable(struct samsung_mipi_dcphy *samsung)
 
 static void samsung_mipi_dphy_lane_disable(struct samsung_mipi_dcphy *samsung)
 {
-	switch (samsung->lanes) {
+	switch (samsung->phys[SAMSUNG_MIPI_TX].lanes) {
 	case 4:
 		regmap_update_bits(samsung->regmap, DPHY_MD3_GNR_CON0,
 				   PHY_ENABLE, 0);
@@ -1336,15 +1394,16 @@ static int samsung_mipi_dphy_tx_power_on(struct samsung_mipi_dcphy *samsung)
 {
 	int ret;
 
+	samsung_mipi_dcphy_common_get(samsung);
+
 	reset_control_assert(samsung->m_phy_rst);
 
-	samsung_mipi_dcphy_bias_block_enable(samsung);
 	samsung_mipi_dcphy_pll_configure(samsung);
 	samsung_mipi_dphy_clk_lane_timing_init(samsung);
 	samsung_mipi_dphy_data_lane_timing_init(samsung);
 	ret = samsung_mipi_dcphy_pll_enable(samsung);
 	if (ret < 0)
-		return ret;
+		goto err_put;
 
 	samsung_mipi_dphy_lane_enable(samsung);
 
@@ -1356,6 +1415,11 @@ static int samsung_mipi_dphy_tx_power_on(struct samsung_mipi_dcphy *samsung)
 	usleep_range(100, 110);
 
 	return 0;
+
+err_put:
+	samsung_mipi_dcphy_common_put(samsung);
+
+	return ret;
 }
 
 static int samsung_mipi_dphy_tx_power_off(struct samsung_mipi_dcphy *samsung)
@@ -1363,33 +1427,49 @@ static int samsung_mipi_dphy_tx_power_off(struct samsung_mipi_dcphy *samsung)
 	samsung_mipi_dphy_lane_disable(samsung);
 	samsung_mipi_dcphy_pll_disable(samsung);
 
+	samsung_mipi_dcphy_common_put(samsung);
+
 	return 0;
 }
 
 static int samsung_mipi_dcphy_power_on(struct phy *phy)
 {
-	struct samsung_mipi_dcphy *samsung = phy_get_drvdata(phy);
-
-	reset_control_assert(samsung->apb_rst);
-	udelay(1);
-	reset_control_deassert(samsung->apb_rst);
+	struct samsung_mipi_phy *samsung_phy = phy_get_drvdata(phy);
+	struct samsung_mipi_dcphy *samsung = samsung_phy->parent;
+	int ret;
 
 	/* CPHY part to be implemented later */
-	if (samsung->type != PHY_TYPE_DPHY)
+	if (samsung_phy->type != PHY_TYPE_DPHY)
 		return -EOPNOTSUPP;
 
-	return samsung_mipi_dphy_tx_power_on(samsung);
+	mutex_lock(&samsung->lock);
+	if (samsung_phy->id == SAMSUNG_MIPI_RX)
+		ret = -EOPNOTSUPP;
+	else
+		ret = samsung_mipi_dphy_tx_power_on(samsung);
+	mutex_unlock(&samsung->lock);
+
+	return ret;
 }
 
 static int samsung_mipi_dcphy_power_off(struct phy *phy)
 {
-	struct samsung_mipi_dcphy *samsung = phy_get_drvdata(phy);
+	struct samsung_mipi_phy *samsung_phy = phy_get_drvdata(phy);
+	struct samsung_mipi_dcphy *samsung = samsung_phy->parent;
+	int ret;
 
 	/* CPHY part to be implemented later */
-	if (samsung->type != PHY_TYPE_DPHY)
+	if (samsung_phy->type != PHY_TYPE_DPHY)
 		return -EOPNOTSUPP;
 
-	return samsung_mipi_dphy_tx_power_off(samsung);
+	mutex_lock(&samsung->lock);
+	if (samsung_phy->id == SAMSUNG_MIPI_RX)
+		ret = -EOPNOTSUPP;
+	else
+		ret = samsung_mipi_dphy_tx_power_off(samsung);
+	mutex_unlock(&samsung->lock);
+
+	return ret;
 }
 
 static int
@@ -1482,10 +1562,15 @@ samsung_mipi_dcphy_pll_calc_rate(struct samsung_mipi_dcphy *samsung,
 static int samsung_mipi_dcphy_configure(struct phy *phy,
 					union phy_configure_opts *opts)
 {
-	struct samsung_mipi_dcphy *samsung = phy_get_drvdata(phy);
+	struct samsung_mipi_phy *samsung_phy = phy_get_drvdata(phy);
+	struct samsung_mipi_dcphy *samsung = samsung_phy->parent;
 	unsigned long long target_rate = opts->mipi_dphy.hs_clk_rate;
 
-	samsung->lanes = opts->mipi_dphy.lanes > 4 ? 4 : opts->mipi_dphy.lanes;
+	/* The receiver is brought up in a later change. */
+	if (samsung_phy->id == SAMSUNG_MIPI_RX)
+		return -EOPNOTSUPP;
+
+	samsung_phy->lanes = opts->mipi_dphy.lanes > 4 ? 4 : opts->mipi_dphy.lanes;
 
 	samsung_mipi_dcphy_pll_calc_rate(samsung, target_rate);
 	opts->mipi_dphy.hs_clk_rate = samsung->pll.rate;
@@ -1495,16 +1580,16 @@ static int samsung_mipi_dcphy_configure(struct phy *phy,
 
 static int samsung_mipi_dcphy_init(struct phy *phy)
 {
-	struct samsung_mipi_dcphy *samsung = phy_get_drvdata(phy);
+	struct samsung_mipi_phy *samsung_phy = phy_get_drvdata(phy);
 
-	return pm_runtime_resume_and_get(samsung->dev);
+	return pm_runtime_resume_and_get(samsung_phy->parent->dev);
 }
 
 static int samsung_mipi_dcphy_exit(struct phy *phy)
 {
-	struct samsung_mipi_dcphy *samsung = phy_get_drvdata(phy);
+	struct samsung_mipi_phy *samsung_phy = phy_get_drvdata(phy);
 
-	pm_runtime_put(samsung->dev);
+	pm_runtime_put(samsung_phy->parent->dev);
 
 	return 0;
 }
@@ -1530,19 +1615,43 @@ static struct phy *samsung_mipi_dcphy_xlate(struct device *dev,
 					    const struct of_phandle_args *args)
 {
 	struct samsung_mipi_dcphy *samsung = dev_get_drvdata(dev);
+	struct samsung_mipi_phy *samsung_phy;
+	u8 id = SAMSUNG_MIPI_TX;
+	u8 type;
 
 	if (args->args_count != 1) {
 		dev_err(dev, "invalid number of arguments\n");
 		return ERR_PTR(-EINVAL);
 	}
 
-	if (samsung->type != PHY_NONE && samsung->type != args->args[0])
-		dev_warn(dev, "phy type select %d overwriting type %d\n",
-			 args->args[0], samsung->type);
+	switch (args->args[0]) {
+	case PHY_TYPE_CSI:
+		id = SAMSUNG_MIPI_RX;
+		fallthrough;
+	case PHY_TYPE_DSI:
+		/*
+		 * Both protocols run over D-PHY here; C-PHY is selected
+		 * with PHY_TYPE_CPHY and is not supported yet.
+		 */
+		type = PHY_TYPE_DPHY;
+		break;
+	case PHY_TYPE_DPHY:
+	case PHY_TYPE_CPHY:
+		/* Electrical-layer selectors for the transmitter. */
+		type = args->args[0];
+		break;
+	default:
+		dev_err(dev, "invalid phy type %u\n", args->args[0]);
+		return ERR_PTR(-EINVAL);
+	}
 
-	samsung->type = args->args[0];
+	samsung_phy = &samsung->phys[id];
+	if (samsung_phy->type != PHY_NONE && samsung_phy->type != type)
+		dev_warn(dev, "phy type select %u overwriting type %u\n",
+			 type, samsung_phy->type);
+	samsung_phy->type = type;
 
-	return samsung->phy;
+	return samsung_phy->phy;
 }
 
 static int samsung_mipi_dcphy_probe(struct platform_device *pdev)
@@ -1553,6 +1662,7 @@ static int samsung_mipi_dcphy_probe(struct platform_device *pdev)
 	struct phy_provider *phy_provider;
 	struct resource *res;
 	void __iomem *regs;
+	unsigned int i;
 	int ret;
 
 	samsung = devm_kzalloc(dev, sizeof(*samsung), GFP_KERNEL);
@@ -1563,6 +1673,10 @@ static int samsung_mipi_dcphy_probe(struct platform_device *pdev)
 	samsung->pdata = device_get_match_data(dev);
 	platform_set_drvdata(pdev, samsung);
 
+	ret = devm_mutex_init(dev, &samsung->lock);
+	if (ret)
+		return ret;
+
 	res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
 	regs = devm_ioremap_resource(dev, res);
 	if (IS_ERR(regs))
@@ -1607,11 +1721,19 @@ static int samsung_mipi_dcphy_probe(struct platform_device *pdev)
 		return dev_err_probe(dev, PTR_ERR(samsung->grf_apb_rst),
 				     "Failed to get system grf_apb_rst control\n");
 
-	samsung->phy = devm_phy_create(dev, NULL, &samsung_mipi_dcphy_ops);
-	if (IS_ERR(samsung->phy))
-		return dev_err_probe(dev, PTR_ERR(samsung->phy), "Failed to create MIPI DC-PHY\n");
+	for (i = 0; i < ARRAY_SIZE(samsung->phys); i++) {
+		struct phy *phy = devm_phy_create(dev, NULL,
+						  &samsung_mipi_dcphy_ops);
+
+		if (IS_ERR(phy))
+			return dev_err_probe(dev, PTR_ERR(phy),
+					     "Failed to create MIPI DC-PHY\n");
 
-	phy_set_drvdata(samsung->phy, samsung);
+		samsung->phys[i].phy = phy;
+		samsung->phys[i].parent = samsung;
+		samsung->phys[i].id = i;
+		phy_set_drvdata(phy, &samsung->phys[i]);
+	}
 
 	ret = devm_pm_runtime_enable(dev);
 	if (ret)

-- 
2.43.0

