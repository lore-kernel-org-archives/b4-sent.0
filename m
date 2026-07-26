From: Jason Yang <jason98166@gmail.com>
Date: Sun, 26 Jul 2026 22:55:46 +0800
Subject: [PATCH v2 3/4] phy: rockchip-samsung-dcphy: model TX and RX as
 separate PHYs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260726-dcphy-rx-v1-v2-3-cf9cc34a412a@gmail.com>
References: <20260726-dcphy-rx-v1-v2-0-cf9cc34a412a@gmail.com>
In-Reply-To: <20260726-dcphy-rx-v1-v2-0-cf9cc34a412a@gmail.com>
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Guochun Huang <hero.huang@rock-chips.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-phy@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Jason Yang <jason98166@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785077744; l=10427;
 i=jason98166@gmail.com; s=20260721; h=from:subject:message-id;
 bh=enHd/hypPBz3ePteijtVibB3GtTKn9jBTPBLK9hsNYs=;
 b=+aFveRRf2z/bYaV6jwLPnb0SNRF0PUDEmuCKbFzcMsM9TSNgWoYJWbWMyqWXd390iFy/ACwrU
 ebOJyLTPS/cCyQ8dwVn4MKze3ArDP2UXThPKacXDHgoPrS6oFgOKaPl
X-Developer-Key: i=jason98166@gmail.com; a=ed25519;
 pk=xQmD001Q/ooHl39PxyQtusbUQmgbOsSfpFryRVWZ/k4=
X-Endpoint-Received: by B4 Relay for jason98166@gmail.com/20260721 with auth_id=887
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The DC-PHY drives a MIPI DSI transmitter and a MIPI CSI receiver, and on
RK3588 both can be wired to the same PHY as independent consumers. The
PHY core reference-counts power_on() per struct phy, so a single struct
phy cannot bring the two directions up independently.

Register one struct phy per direction and move the per-direction state
(direction, PHY type, lane count and powered flag) into its own driver
data. of_xlate() accepts the legacy single cell as the transmitter and
an optional second cell that selects the direction, so existing
single-cell DSI device trees keep resolving to the transmitter.
configure() rejects the not yet supported receiver before touching any
state, and each direction keeps its own lane count.

The PHY's common block contains a single BIAS block shared by both
directions (RK3588 TRM section 22.2), so it must be programmed only
once. Whichever direction powers on first enables it; each direction
records its powered state under the per-provider mutex so that powering
one direction on does not disturb an already running one. The APB reset
is issued on the transmitter bring-up path.
The receiver bring-up itself is added in a later change.

Signed-off-by: Jason Yang <jason98166@gmail.com>
Assisted-by: Claude:claude-opus-4-8
---
 drivers/phy/rockchip/phy-rockchip-samsung-dcphy.c | 143 +++++++++++++++-------
 1 file changed, 102 insertions(+), 41 deletions(-)

diff --git a/drivers/phy/rockchip/phy-rockchip-samsung-dcphy.c b/drivers/phy/rockchip/phy-rockchip-samsung-dcphy.c
index d0d77421bd4b..95eb1200cab4 100644
--- a/drivers/phy/rockchip/phy-rockchip-samsung-dcphy.c
+++ b/drivers/phy/rockchip/phy-rockchip-samsung-dcphy.c
@@ -5,6 +5,7 @@
  *      Guochun Huang <hero.huang@rock-chips.com>
  */
 
+#include <dt-bindings/phy/rockchip,rk3588-mipi-dcphy.h>
 #include <dt-bindings/phy/phy.h>
 #include <linux/bitfield.h>
 #include <linux/clk.h>
@@ -13,6 +14,7 @@
 #include <linux/kernel.h>
 #include <linux/mfd/syscon.h>
 #include <linux/module.h>
+#include <linux/mutex.h>
 #include <linux/of.h>
 #include <linux/phy/phy.h>
 #include <linux/platform_device.h>
@@ -280,6 +282,19 @@ struct samsung_mipi_dcphy_plat_data {
 	u32 dphy_tx_max_lane_kbps;
 };
 
+struct samsung_mipi_dcphy;
+
+/* One PHY per direction: transmitter (DSI) and receiver (CSI). */
+struct samsung_mipi_dcphy_dir {
+	struct phy *phy;
+	struct samsung_mipi_dcphy *parent;
+	u8 dir;
+	u8 type;
+	unsigned int lanes;
+	/* Written under the parent's lock. */
+	bool powered;
+};
+
 struct samsung_mipi_dcphy {
 	struct device *dev;
 	struct clk *ref_clk;
@@ -290,9 +305,9 @@ struct samsung_mipi_dcphy {
 	struct reset_control *s_phy_rst;
 	struct reset_control *apb_rst;
 	struct reset_control *grf_apb_rst;
-	unsigned int lanes;
-	struct phy *phy;
-	u8 type;
+	struct samsung_mipi_dcphy_dir phys[2];
+	/* Serialises the two directions' access to the shared PHY state. */
+	struct mutex lock;
 
 	const struct samsung_mipi_dcphy_plat_data *pdata;
 	struct {
@@ -995,7 +1010,7 @@ static void samsung_mipi_dphy_lane_enable(struct samsung_mipi_dcphy *samsung)
 	regmap_update_bits(samsung->regmap, DPHY_MC_GNR_CON0,
 			   PHY_ENABLE, PHY_ENABLE);
 
-	switch (samsung->lanes) {
+	switch (samsung->phys[RK_DCPHY_DIR_TX].lanes) {
 	case 4:
 		regmap_write(samsung->regmap, DPHY_MD3_GNR_CON1,
 			     T_PHY_READY(0x2000));
@@ -1026,7 +1041,7 @@ static void samsung_mipi_dphy_lane_enable(struct samsung_mipi_dcphy *samsung)
 
 static void samsung_mipi_dphy_lane_disable(struct samsung_mipi_dcphy *samsung)
 {
-	switch (samsung->lanes) {
+	switch (samsung->phys[RK_DCPHY_DIR_TX].lanes) {
 	case 4:
 		regmap_update_bits(samsung->regmap, DPHY_MD3_GNR_CON0,
 				   PHY_ENABLE, 0);
@@ -1334,11 +1349,23 @@ samsung_mipi_dphy_data_lane_timing_init(struct samsung_mipi_dcphy *samsung)
 
 static int samsung_mipi_dphy_tx_power_on(struct samsung_mipi_dcphy *samsung)
 {
+	bool first = !samsung->phys[RK_DCPHY_DIR_RX].powered;
 	int ret;
 
+	/*
+	 * The shared BIAS block is brought up by whichever direction powers
+	 * on first, leaving an already active peer undisturbed.
+	 */
+	if (first) {
+		reset_control_assert(samsung->apb_rst);
+		udelay(1);
+		reset_control_deassert(samsung->apb_rst);
+	}
+
 	reset_control_assert(samsung->m_phy_rst);
 
-	samsung_mipi_dcphy_bias_block_enable(samsung);
+	if (first)
+		samsung_mipi_dcphy_bias_block_enable(samsung);
 	samsung_mipi_dcphy_pll_configure(samsung);
 	samsung_mipi_dphy_clk_lane_timing_init(samsung);
 	samsung_mipi_dphy_data_lane_timing_init(samsung);
@@ -1368,34 +1395,44 @@ static int samsung_mipi_dphy_tx_power_off(struct samsung_mipi_dcphy *samsung)
 
 static int samsung_mipi_dcphy_power_on(struct phy *phy)
 {
-	struct samsung_mipi_dcphy *samsung = phy_get_drvdata(phy);
-
-	reset_control_assert(samsung->apb_rst);
-	udelay(1);
-	reset_control_deassert(samsung->apb_rst);
+	struct samsung_mipi_dcphy_dir *pd = phy_get_drvdata(phy);
+	struct samsung_mipi_dcphy *samsung = pd->parent;
+	int ret;
 
-	switch (samsung->type) {
-	case PHY_TYPE_DPHY:
-		return samsung_mipi_dphy_tx_power_on(samsung);
-	default:
-		/* CPHY part to be implemented later */
+	if (pd->type != PHY_TYPE_DPHY)
 		return -EOPNOTSUPP;
-	}
 
-	return 0;
+	mutex_lock(&samsung->lock);
+	if (pd->dir == RK_DCPHY_DIR_RX)
+		ret = -EOPNOTSUPP;
+	else
+		ret = samsung_mipi_dphy_tx_power_on(samsung);
+	if (!ret)
+		pd->powered = true;
+	mutex_unlock(&samsung->lock);
+
+	return ret;
 }
 
 static int samsung_mipi_dcphy_power_off(struct phy *phy)
 {
-	struct samsung_mipi_dcphy *samsung = phy_get_drvdata(phy);
+	struct samsung_mipi_dcphy_dir *pd = phy_get_drvdata(phy);
+	struct samsung_mipi_dcphy *samsung = pd->parent;
+	int ret;
 
-	switch (samsung->type) {
-	case PHY_TYPE_DPHY:
-		return samsung_mipi_dphy_tx_power_off(samsung);
-	default:
-		/* CPHY part to be implemented later */
+	if (pd->type != PHY_TYPE_DPHY)
 		return -EOPNOTSUPP;
-	}
+
+	if (pd->dir == RK_DCPHY_DIR_RX)
+		return -EOPNOTSUPP;
+
+	mutex_lock(&samsung->lock);
+	ret = samsung_mipi_dphy_tx_power_off(samsung);
+	if (!ret)
+		pd->powered = false;
+	mutex_unlock(&samsung->lock);
+
+	return ret;
 }
 
 static int
@@ -1488,10 +1525,14 @@ samsung_mipi_dcphy_pll_calc_rate(struct samsung_mipi_dcphy *samsung,
 static int samsung_mipi_dcphy_configure(struct phy *phy,
 					union phy_configure_opts *opts)
 {
-	struct samsung_mipi_dcphy *samsung = phy_get_drvdata(phy);
+	struct samsung_mipi_dcphy_dir *pd = phy_get_drvdata(phy);
+	struct samsung_mipi_dcphy *samsung = pd->parent;
 	unsigned long long target_rate = opts->mipi_dphy.hs_clk_rate;
 
-	samsung->lanes = opts->mipi_dphy.lanes > 4 ? 4 : opts->mipi_dphy.lanes;
+	if (pd->dir == RK_DCPHY_DIR_RX)
+		return -EOPNOTSUPP;
+
+	pd->lanes = opts->mipi_dphy.lanes > 4 ? 4 : opts->mipi_dphy.lanes;
 
 	samsung_mipi_dcphy_pll_calc_rate(samsung, target_rate);
 	opts->mipi_dphy.hs_clk_rate = samsung->pll.rate;
@@ -1501,16 +1542,16 @@ static int samsung_mipi_dcphy_configure(struct phy *phy,
 
 static int samsung_mipi_dcphy_init(struct phy *phy)
 {
-	struct samsung_mipi_dcphy *samsung = phy_get_drvdata(phy);
+	struct samsung_mipi_dcphy_dir *pd = phy_get_drvdata(phy);
 
-	return pm_runtime_resume_and_get(samsung->dev);
+	return pm_runtime_resume_and_get(pd->parent->dev);
 }
 
 static int samsung_mipi_dcphy_exit(struct phy *phy)
 {
-	struct samsung_mipi_dcphy *samsung = phy_get_drvdata(phy);
+	struct samsung_mipi_dcphy_dir *pd = phy_get_drvdata(phy);
 
-	pm_runtime_put(samsung->dev);
+	pm_runtime_put(pd->parent->dev);
 
 	return 0;
 }
@@ -1536,19 +1577,29 @@ static struct phy *samsung_mipi_dcphy_xlate(struct device *dev,
 					    const struct of_phandle_args *args)
 {
 	struct samsung_mipi_dcphy *samsung = dev_get_drvdata(dev);
+	struct samsung_mipi_dcphy_dir *pd;
+	u8 dir = RK_DCPHY_DIR_TX;
 
-	if (args->args_count != 1) {
+	if (args->args_count < 1 || args->args_count > 2) {
 		dev_err(dev, "invalid number of arguments\n");
 		return ERR_PTR(-EINVAL);
 	}
 
-	if (samsung->type != PHY_NONE && samsung->type != args->args[0])
-		dev_warn(dev, "phy type select %d overwriting type %d\n",
-			 args->args[0], samsung->type);
+	if (args->args_count == 2) {
+		if (args->args[1] > RK_DCPHY_DIR_RX) {
+			dev_err(dev, "invalid direction %u\n", args->args[1]);
+			return ERR_PTR(-EINVAL);
+		}
+		dir = args->args[1];
+	}
 
-	samsung->type = args->args[0];
+	pd = &samsung->phys[dir];
+	if (pd->type != PHY_NONE && pd->type != args->args[0])
+		dev_warn(dev, "phy type select %u overwriting type %u\n",
+			 args->args[0], pd->type);
+	pd->type = args->args[0];
 
-	return samsung->phy;
+	return pd->phy;
 }
 
 static int samsung_mipi_dcphy_probe(struct platform_device *pdev)
@@ -1559,6 +1610,7 @@ static int samsung_mipi_dcphy_probe(struct platform_device *pdev)
 	struct phy_provider *phy_provider;
 	struct resource *res;
 	void __iomem *regs;
+	unsigned int i;
 	int ret;
 
 	samsung = devm_kzalloc(dev, sizeof(*samsung), GFP_KERNEL);
@@ -1568,6 +1620,7 @@ static int samsung_mipi_dcphy_probe(struct platform_device *pdev)
 	samsung->dev = dev;
 	samsung->pdata = device_get_match_data(dev);
 	platform_set_drvdata(pdev, samsung);
+	mutex_init(&samsung->lock);
 
 	res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
 	regs = devm_ioremap_resource(dev, res);
@@ -1613,11 +1666,19 @@ static int samsung_mipi_dcphy_probe(struct platform_device *pdev)
 		return dev_err_probe(dev, PTR_ERR(samsung->grf_apb_rst),
 				     "Failed to get system grf_apb_rst control\n");
 
-	samsung->phy = devm_phy_create(dev, NULL, &samsung_mipi_dcphy_ops);
-	if (IS_ERR(samsung->phy))
-		return dev_err_probe(dev, PTR_ERR(samsung->phy), "Failed to create MIPI DC-PHY\n");
+	for (i = 0; i < ARRAY_SIZE(samsung->phys); i++) {
+		struct phy *phy = devm_phy_create(dev, NULL,
+						  &samsung_mipi_dcphy_ops);
 
-	phy_set_drvdata(samsung->phy, samsung);
+		if (IS_ERR(phy))
+			return dev_err_probe(dev, PTR_ERR(phy),
+					     "Failed to create MIPI DC-PHY\n");
+
+		samsung->phys[i].phy = phy;
+		samsung->phys[i].parent = samsung;
+		samsung->phys[i].dir = i;
+		phy_set_drvdata(phy, &samsung->phys[i]);
+	}
 
 	ret = devm_pm_runtime_enable(dev);
 	if (ret)

-- 
2.43.0

