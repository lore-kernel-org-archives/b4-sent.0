From: Cunhao Lu <1579567540@qq.com>
Date: Wed, 11 Nov 2026 17:56:29 +0800
Subject: [PATCH net-next v2 2/2] net: stmmac: dwmac-rk: Add RK3572 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-add-board-ok3572-c-net-v2-2-304466394970@qq.com>
References: <20261111-add-board-ok3572-c-net-v2-0-304466394970@qq.com>
In-Reply-To: <20261111-add-board-ok3572-c-net-v2-0-304466394970@qq.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794391206; l=3142;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=bJZr2jTjg4023AjgAd/Zj2CWJraJeUFEaOgI88A3Cbk=;
 b=jEQpmIjRN58KDsmIItARMWGBR9/tQFG9sLJdgCnv3tiEkLj98mJUEUUC9c0t/JiC7ZJXHDEJN
 se60OOE7HDgBwGvEfdETUlLxU6Ep4JJ/F8R1aNpxxWA3irkjAbFxbXR
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The RK3572 has two GMAC controllers with separate mode and clock control
registers in the PHP and NVM0 GRFs. RGMII delay lines are configured
through the IOC.

Add the register layout and delay callback for both controllers so the
Rockchip glue driver can configure their RGMII and RMII interfaces and
select the appropriate clocks for each link speed.

Signed-off-by: Cunhao Lu <1579567540@qq.com>
---
 drivers/net/ethernet/stmicro/stmmac/dwmac-rk.c | 53 ++++++++++++++++++++++++++
 1 file changed, 53 insertions(+)

diff --git a/drivers/net/ethernet/stmicro/stmmac/dwmac-rk.c b/drivers/net/ethernet/stmicro/stmmac/dwmac-rk.c
index a37df5767d84..c9d8d8bf51f7 100644
--- a/drivers/net/ethernet/stmicro/stmmac/dwmac-rk.c
+++ b/drivers/net/ethernet/stmicro/stmmac/dwmac-rk.c
@@ -900,6 +900,58 @@ static const struct rk_gmac_ops rk3568_ops = {
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
+				int tx_delay, int rx_delay)
+{
+	u32 val = GRF_FIELD(14, 8, rx_delay) | GRF_FIELD(6, 0, tx_delay) |
+		  GRF_FIELD(15, 15, !!rx_delay) | GRF_FIELD(7, 7, !!tx_delay);
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
+	.gmac_phy_intf_sel_mask = GENMASK_U16(11, 9),
+	.gmac_rmii_mode_mask = BIT_U16(3),
+	.clock.io_clksel_io_mask = BIT_U16(7),
+	.clock.gmii_clk_sel_mask = GENMASK_U16(6, 5),
+	.clock.rmii_clk_sel_mask = BIT_U16(5),
+	.clock.rmii_gate_en_mask = BIT_U16(4),
+	.supports_rmii = true,
+	.php_grf_required = true,
+	.regs_valid = true,
+	.regs = { 0x29d20000, 0x2a040000, 0 },
+};
+
 /* VCCIO0_1_3_IOC */
 #define RK3576_VCCIO0_1_3_IOC_CON2		0X6408
 #define RK3576_VCCIO0_1_3_IOC_CON3		0X640c
@@ -1720,6 +1772,7 @@ static const struct of_device_id rk_gmac_dwmac_match[] = {
 	{ .compatible = "rockchip,rk3506-gmac", .data = &rk3506_ops },
 	{ .compatible = "rockchip,rk3528-gmac", .data = &rk3528_ops },
 	{ .compatible = "rockchip,rk3568-gmac", .data = &rk3568_ops },
+	{ .compatible = "rockchip,rk3572-gmac", .data = &rk3572_ops },
 	{ .compatible = "rockchip,rk3576-gmac", .data = &rk3576_ops },
 	{ .compatible = "rockchip,rk3588-gmac", .data = &rk3588_ops },
 	{ .compatible = "rockchip,rv1108-gmac", .data = &rv1108_ops },

-- 
2.34.1

