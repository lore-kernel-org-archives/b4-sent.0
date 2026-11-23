From: Cunhao Lu <1579567540@qq.com>
Date: Mon, 23 Nov 2026 11:07:28 +0800
Subject: [PATCH net-next v5 2/2] net: stmmac: dwmac-rk: Add RK3572 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-add-board-ok3572-c-net-v5-2-8ec9012b578f@qq.com>
References: <20261123-add-board-ok3572-c-net-v5-0-8ec9012b578f@qq.com>
In-Reply-To: <20261123-add-board-ok3572-c-net-v5-0-8ec9012b578f@qq.com>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 David Wu <david.wu@rock-chips.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Giuseppe Cavallaro <peppe.cavallaro@st.com>, 
 Jose Abreu <joabreu@synopsys.com>, 
 Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>
Cc: Cunhao Lu <1579567540@qq.com>, netdev@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-stm32@st-md-mailman.stormreply.com
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795403251; l=4857;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=Er103tsloFwxtyv/kT9C0DhrwH98VW9zC6CCWRpsoHU=;
 b=Z2V7b5VvyQH25FE4KjoGgEHT/QYwAgUWmxRBa4lT7hyDodKvBmN1PGaFBn2b0tjmKvzPYotf2
 8ZldegRrchOBOkORIJ9EUuLmJ9wSOqR7024Wu6tPNVt8zXlkW4xgOCr
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The RK3572 has two GMAC controllers with separate mode and clock control
registers in the PHP and NVM0 GRFs. RGMII delay lines are configured
through the IOC.

Add the register layout and delay callback for both controllers so the
Rockchip glue driver can configure their RGMII and RMII interfaces and
select the appropriate clocks for each link speed. Skip parsing the
deprecated tx_delay and rx_delay properties for RK3572.

Signed-off-by: Cunhao Lu <1579567540@qq.com>
---
Changes in v5:
- Use skip_rgmii_delay_props to control tx_delay and rx_delay parsing.

Changes in v4:
- Skip legacy delay properties and disable MAC RGMII delays on RK3572.
---
 drivers/net/ethernet/stmicro/stmmac/dwmac-rk.c | 75 ++++++++++++++++++++++++--
 1 file changed, 71 insertions(+), 4 deletions(-)

diff --git a/drivers/net/ethernet/stmicro/stmmac/dwmac-rk.c b/drivers/net/ethernet/stmicro/stmmac/dwmac-rk.c
index ad2bae308323..01fec12aa16a 100644
--- a/drivers/net/ethernet/stmicro/stmmac/dwmac-rk.c
+++ b/drivers/net/ethernet/stmicro/stmmac/dwmac-rk.c
@@ -66,6 +66,9 @@ struct rk_gmac_ops {
 	bool supports_rgmii;
 	bool supports_rmii;
 	bool supports_sgmii;
+	/* Skip parsing legacy tx_delay and rx_delay properties on new SoCs. */
+	bool skip_rgmii_delay_props;
+
 	bool php_grf_required;
 	bool regs_valid;
 	u32 regs[];
@@ -900,6 +903,67 @@ static const struct rk_gmac_ops rk3568_ops = {
 	},
 };
 
+#define RK3572_VCCIO0_3_VO_IOC_CON1		0x10608
+#define RK3572_VCCIO1_2_4_VI_IOC_CON1		0x12604
+#define RK3572_VCCIO5_6_IOC_MISC0		0x14630
+#define RK3572_PHP_GRF_GMAC0_CON		0x0070
+#define RK3572_NVM0_GRF_GMAC1_CON		0x0020
+
+static int rk3572_init(struct rk_priv_data *bsp_priv)
+{
+	switch (bsp_priv->id) {
+	case 0:
+		bsp_priv->gmac_grf_reg = RK3572_PHP_GRF_GMAC0_CON;
+		break;
+	case 1:
+		bsp_priv->gmac_grf_reg = RK3572_NVM0_GRF_GMAC1_CON;
+		break;
+	default:
+		return -EINVAL;
+	}
+
+	bsp_priv->clock_grf_reg = bsp_priv->gmac_grf_reg;
+	return 0;
+}
+
+static void rk3572_set_to_rgmii(struct rk_priv_data *bsp_priv,
+				int __always_unused tx_delay,
+				int __always_unused rx_delay)
+{
+	u32 val = GRF_CLR_BIT(15) | GRF_CLR_BIT(7);
+
+	if (bsp_priv->id == 1) {
+		regmap_write(bsp_priv->php_grf, RK3572_VCCIO0_3_VO_IOC_CON1, val);
+		regmap_write(bsp_priv->php_grf, RK3572_VCCIO5_6_IOC_MISC0, val);
+	} else {
+		regmap_write(bsp_priv->php_grf, RK3572_VCCIO1_2_4_VI_IOC_CON1, val);
+	}
+}
+
+static const struct rk_gmac_ops rk3572_ops = {
+	.init = rk3572_init,
+	.set_to_rgmii = rk3572_set_to_rgmii,
+
+	.gmac_phy_intf_sel_mask = GENMASK_U16(11, 9),
+	.gmac_rmii_mode_mask = BIT_U16(3),
+
+	.clock.io_clksel_io_mask = BIT_U16(7),
+	.clock.gmii_clk_sel_mask = GENMASK_U16(6, 5),
+	.clock.rmii_clk_sel_mask = BIT_U16(5),
+	.clock.rmii_gate_en_mask = BIT_U16(4),
+
+	.supports_rmii = true,
+	.skip_rgmii_delay_props = true,
+
+	.php_grf_required = true,
+	.regs_valid = true,
+	.regs = {
+		0x29d20000, /* gmac0 */
+		0x2a040000, /* gmac1 */
+		0x0, /* sentinel */
+	},
+};
+
 /* VCCIO0_1_3_IOC */
 #define RK3576_VCCIO0_1_3_IOC_CON2		0X6408
 #define RK3576_VCCIO0_1_3_IOC_CON3		0X640c
@@ -1341,8 +1405,9 @@ static struct rk_priv_data *rk_gmac_setup(struct platform_device *pdev,
 	 * provide (see rk_gmac_powerup()), so only the delay values for
 	 * those directions are needed.
 	 */
-	if (bsp_priv->phy_iface == PHY_INTERFACE_MODE_RGMII ||
-	    bsp_priv->phy_iface == PHY_INTERFACE_MODE_RGMII_RXID) {
+	if (!ops->skip_rgmii_delay_props &&
+	    (bsp_priv->phy_iface == PHY_INTERFACE_MODE_RGMII ||
+	     bsp_priv->phy_iface == PHY_INTERFACE_MODE_RGMII_RXID)) {
 		ret = of_property_read_u32(dev->of_node, "tx_delay", &value);
 		if (ret) {
 			bsp_priv->tx_delay = 0x30;
@@ -1355,8 +1420,9 @@ static struct rk_priv_data *rk_gmac_setup(struct platform_device *pdev,
 		}
 	}
 
-	if (bsp_priv->phy_iface == PHY_INTERFACE_MODE_RGMII ||
-	    bsp_priv->phy_iface == PHY_INTERFACE_MODE_RGMII_TXID) {
+	if (!ops->skip_rgmii_delay_props &&
+	    (bsp_priv->phy_iface == PHY_INTERFACE_MODE_RGMII ||
+	     bsp_priv->phy_iface == PHY_INTERFACE_MODE_RGMII_TXID)) {
 		ret = of_property_read_u32(dev->of_node, "rx_delay", &value);
 		if (ret) {
 			bsp_priv->rx_delay = 0x10;
@@ -1736,6 +1802,7 @@ static const struct of_device_id rk_gmac_dwmac_match[] = {
 	{ .compatible = "rockchip,rk3506-gmac", .data = &rk3506_ops },
 	{ .compatible = "rockchip,rk3528-gmac", .data = &rk3528_ops },
 	{ .compatible = "rockchip,rk3568-gmac", .data = &rk3568_ops },
+	{ .compatible = "rockchip,rk3572-gmac", .data = &rk3572_ops },
 	{ .compatible = "rockchip,rk3576-gmac", .data = &rk3576_ops },
 	{ .compatible = "rockchip,rk3588-gmac", .data = &rk3588_ops },
 	{ .compatible = "rockchip,rv1108-gmac", .data = &rv1108_ops },

-- 
2.34.1

