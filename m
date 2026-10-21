From: Cunhao Lu <1579567540@qq.com>
Date: Thu, 22 Oct 2026 00:11:19 +0800
Subject: [PATCH 22/27] phy: rockchip-naneng-combphy: Add RK3572 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-add-board-ok3572-c-v1-22-0b0fd85a31ee@qq.com>
References: <20261022-add-board-ok3572-c-v1-0-0b0fd85a31ee@qq.com>
In-Reply-To: <20261022-add-board-ok3572-c-v1-0-0b0fd85a31ee@qq.com>
To: Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Elaine Zhang <zhangqing@rock-chips.com>, Lee Jones <lee@kernel.org>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>, 
 Richard Cochran <richardcochran@gmail.com>, Ulf Hansson <ulfh@kernel.org>, 
 Andi Shyti <andi.shyti@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Jisheng Zhang <jszhang@kernel.org>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 David Wu <david.wu@rock-chips.com>, "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, 
 Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Vinod Koul <vkoul@kernel.org>, Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Jaehoon Chung <jh80.chung@samsung.com>, 
 Shawn Lin <shawn.lin@rock-chips.com>
Cc: Cunhao Lu <1579567540@qq.com>, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 mfd@lists.linux.dev, linux-gpio@vger.kernel.org, netdev@vger.kernel.org, 
 linux-pm@vger.kernel.org, linux-i2c@vger.kernel.org, 
 linux-serial@vger.kernel.org, linux-mmc@vger.kernel.org, 
 linux-stm32@st-md-mailman.stormreply.com, linux-phy@lists.infradead.org, 
 linux-usb@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792599138; l=8706;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=wC2aLPgJOhrcC7ie1Sc3x8qp5suDThHbcIf1QuP1Gno=;
 b=DzUmoa+fO7xpmPZra3NC8fmhgRM7tqdEJ+v+VPO74dHb/SZ/y1gKncl1LRskmymmm4VxE4krX
 fKu2I3IpxIyA0/dkLTBuOzaN29bA75HSzMDiQUPFwJdGWyKSPzU5m24
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Support PCIe, USB3, and SATA operation on the RK3572 combo PHY.

Signed-off-by: Cunhao Lu <1579567540@qq.com>
---
 drivers/phy/rockchip/phy-rockchip-naneng-combphy.c | 201 +++++++++++++++++++++
 1 file changed, 201 insertions(+)

diff --git a/drivers/phy/rockchip/phy-rockchip-naneng-combphy.c b/drivers/phy/rockchip/phy-rockchip-naneng-combphy.c
index 7843356a4dd4..e13a78ab5777 100644
--- a/drivers/phy/rockchip/phy-rockchip-naneng-combphy.c
+++ b/drivers/phy/rockchip/phy-rockchip-naneng-combphy.c
@@ -1000,6 +1000,204 @@ static const struct rockchip_combphy_cfg rk3568_combphy_cfgs = {
 	.combphy_cfg	= rk3568_combphy_cfg,
 };
 
+static int rk3572_combphy_cfg(struct rockchip_combphy_priv *priv)
+{
+	const struct rockchip_combphy_grfcfg *cfg = priv->cfg->grfcfg;
+	unsigned long rate;
+
+	switch (priv->type) {
+	case PHY_TYPE_PCIE:
+		/* Set SSC downward spread spectrum */
+		rockchip_combphy_updatel(priv, GENMASK(5, 4), BIT(4), 0x7c);
+
+		rockchip_combphy_param_write(priv->phy_grf, &cfg->con0_for_pcie, true);
+		rockchip_combphy_param_write(priv->phy_grf, &cfg->con1_for_pcie, true);
+		rockchip_combphy_param_write(priv->phy_grf, &cfg->con2_for_pcie, true);
+		rockchip_combphy_param_write(priv->phy_grf, &cfg->con3_for_pcie, true);
+		break;
+	case PHY_TYPE_USB3:
+		/* Set SSC downward spread spectrum */
+		rockchip_combphy_updatel(priv, GENMASK(5, 4), BIT(4), 0x7c);
+
+		/* Enable adaptive CTLE for USB3.0 Rx */
+		rockchip_combphy_updatel(priv, GENMASK(0, 0), BIT(0), 0x38);
+
+		/* Set PLL KVCO fine tuning signals */
+		rockchip_combphy_updatel(priv, GENMASK(4, 2), BIT(3), 0x80);
+
+		/* Set PLL LPF R1 to su_trim[10:7]=1001 */
+		writel(0x4, priv->mmio + (0xb << 2));
+
+		/* Set PLL input clock divider 1/2 */
+		rockchip_combphy_updatel(priv, GENMASK(7, 6), BIT(6), 0x14);
+
+		writel(0x32, priv->mmio + (0x11 << 2));
+
+		/* Set PLL KVCO to min and set PLL charge pump current to max */
+		writel(0xf0, priv->mmio + (0xa << 2));
+
+		/* Set Rx squelch input filter bandwidth */
+		writel(0x0d, priv->mmio + (0x14 << 2));
+
+		rockchip_combphy_param_write(priv->phy_grf, &cfg->pipe_txcomp_sel, false);
+		rockchip_combphy_param_write(priv->phy_grf, &cfg->pipe_txelec_sel, false);
+		rockchip_combphy_param_write(priv->phy_grf, &cfg->usb_mode_set, true);
+		break;
+	case PHY_TYPE_SATA:
+		/* Enable adaptive CTLE for SATA Rx */
+		rockchip_combphy_updatel(priv, GENMASK(0, 0), BIT(0), 0x38);
+
+		/* Set tx_rterm = 50 ohm and rx_rterm = 43.5 ohm */
+		writel(0x8f, priv->mmio + (0x06 << 2));
+
+		rockchip_combphy_param_write(priv->phy_grf, &cfg->con0_for_sata, true);
+		rockchip_combphy_param_write(priv->phy_grf, &cfg->con1_for_sata, true);
+		rockchip_combphy_param_write(priv->phy_grf, &cfg->con2_for_sata, true);
+		rockchip_combphy_param_write(priv->phy_grf, &cfg->con3_for_sata, true);
+		rockchip_combphy_param_write(priv->pipe_grf, &cfg->pipe_con0_for_sata, true);
+		rockchip_combphy_param_write(priv->pipe_grf, &cfg->pipe_con1_for_sata, true);
+		break;
+	default:
+		dev_err(priv->dev, "incompatible PHY type\n");
+		return -EINVAL;
+	}
+
+	rate = clk_get_rate(priv->refclk);
+
+	switch (rate) {
+	case 24000000:
+		rockchip_combphy_param_write(priv->phy_grf, &cfg->pipe_clk_24m, true);
+		if (priv->type == PHY_TYPE_USB3 || priv->type == PHY_TYPE_SATA) {
+			/* Set ssc_cnt[9:0]=0101111101 & 31.5KHz */
+			rockchip_combphy_updatel(priv, GENMASK(7, 6), BIT(6), 0xe << 2);
+
+			rockchip_combphy_updatel(priv, GENMASK(7, 0), 0x5f, 0xf << 2);
+		} else if (priv->type == PHY_TYPE_PCIE) {
+			/* PLL KVCO tuning fine */
+			rockchip_combphy_updatel(priv, GENMASK(4, 2), 0x4 << 2, 0x20 << 2);
+
+			writel(0x0, priv->mmio + (0x1b << 2));
+
+			/* Set up su_trim: T0_1 */
+			writel(0x90, priv->mmio + (0xa << 2));
+			writel(0x02, priv->mmio + (0xb << 2));
+			writel(0x57, priv->mmio + (0xd << 2));
+
+			writel(0x5f, priv->mmio + (0xf << 2));
+		}
+		break;
+	case 25000000:
+		rockchip_combphy_param_write(priv->phy_grf, &cfg->pipe_clk_25m, true);
+		break;
+	case 100000000:
+		rockchip_combphy_param_write(priv->phy_grf, &cfg->pipe_clk_100m, true);
+		if (priv->type == PHY_TYPE_PCIE) {
+			/* gate_tx_pck_sel length select work for L1SS */
+			writel(0xc0, priv->mmio + 0x74);
+
+			/* PLL KVCO tuning fine */
+			rockchip_combphy_updatel(priv, GENMASK(4, 2), 0x4 << 2, 0x20 << 2);
+
+			/* Set up rx_trim: PLL LPF C1 85pf R1 1.25kohm */
+			writel(0x4c, priv->mmio + (0x1b << 2));
+
+			/* Set up su_trim: T3_P1 650mv */
+			writel(0x90, priv->mmio + (0xa << 2));
+			writel(0x43, priv->mmio + (0xb << 2));
+			writel(0x88, priv->mmio + (0xc << 2));
+			writel(0x56, priv->mmio + (0xd << 2));
+		} else if (priv->type == PHY_TYPE_SATA) {
+			/* downward spread spectrum +500ppm */
+			rockchip_combphy_updatel(priv, GENMASK(7, 4), 0x50, 0x1f << 2);
+
+			/* ssc ppm adjust to 3500ppm */
+			rockchip_combphy_updatel(priv, GENMASK(3, 0), 0x7, 0x9 << 2);
+		}
+		break;
+	default:
+		dev_err(priv->dev, "Unsupported rate: %lu\n", rate);
+		return -EINVAL;
+	}
+
+	if (priv->ext_refclk) {
+		rockchip_combphy_param_write(priv->phy_grf, &cfg->pipe_clk_ext, true);
+		if (priv->type == PHY_TYPE_PCIE && rate == 100000000) {
+			writel(0x10, priv->mmio + (0x20 << 2));
+
+			writel(0x0c, priv->mmio + (0x1b << 2));
+
+			/*
+			 * Set up su_trim: T3_P1 650mv
+			 * CKRCV termination resistor adjust 11: Hi-Z
+			 */
+			writel(0x90, priv->mmio + (0xa << 2));
+			writel(0x43, priv->mmio + (0xb << 2));
+			writel(0xb8, priv->mmio + (0xc << 2));
+			writel(0x56, priv->mmio + (0xd << 2));
+		}
+	}
+
+	if (priv->enable_ssc) {
+		rockchip_combphy_updatel(priv, GENMASK(4, 4), BIT(4), 0x7 << 2);
+		/* PLL control SSC module period should be set */
+		rockchip_combphy_updatel(priv, GENMASK(5, 5), BIT(5), 0x20 << 2);
+
+		if (priv->type == PHY_TYPE_PCIE && rate == 24000000) {
+			/* xin24m T0_1 650mV */
+			writel(0x00, priv->mmio + (0x10 << 2));
+			writel(0x32, priv->mmio + (0x11 << 2));
+			writel(0x00, priv->mmio + (0x1b << 2));
+			writel(0x90, priv->mmio + (0x0a << 2));
+			writel(0x02, priv->mmio + (0x0b << 2));
+			writel(0x08, priv->mmio + (0x0c << 2));
+			writel(0x57, priv->mmio + (0x0d << 2));
+			writel(0x40, priv->mmio + (0x0e << 2));
+			writel(0x5f, priv->mmio + (0x0f << 2));
+			writel(0x10, priv->mmio + (0x20 << 2));
+			/* ssc_cnt: 0101111101 & 31.5KHz */
+			rockchip_combphy_updatel(priv, GENMASK(7, 6), BIT(6), 0xe << 2);
+			rockchip_combphy_updatel(priv, GENMASK(7, 0), 0x5f, 0xf << 2);
+		} else if (priv->type == PHY_TYPE_PCIE && rate == 100000000) {
+			/* ssc_cnt: 1000110001 & 31.5KHz */
+			rockchip_combphy_updatel(priv, GENMASK(7, 6), BIT(6), 0xe << 2);
+			rockchip_combphy_updatel(priv, GENMASK(7, 0), 0x8c, 0xf << 2);
+		}
+	}
+
+	if (priv->type == PHY_TYPE_PCIE)
+		rockchip_combphy_updatel(priv, BIT(5), BIT(5), 0x64);
+
+	return 0;
+}
+
+static const struct rockchip_combphy_grfcfg rk3572_combphy_grfcfgs = {
+	/* pipe-phy-grf */
+	.usb_mode_set		= { 0x0000, 5, 0, 0x00, 0x04 },
+	.pipe_clk_24m		= { 0x0004, 14, 13, 0x00, 0x00 },
+	.pipe_clk_25m		= { 0x0004, 14, 13, 0x00, 0x01 },
+	.pipe_clk_100m		= { 0x0004, 14, 13, 0x00, 0x02 },
+	.pipe_txelec_sel	= { 0x0008, 12, 12, 0x00, 0x01 },
+	.pipe_txcomp_sel	= { 0x0008, 15, 15, 0x00, 0x01 },
+	.pipe_clk_ext		= { 0x000c, 9, 8, 0x02, 0x01 },
+	.pipe_phy_status	= { 0x0034, 6, 6, 0x01, 0x00 },
+	.con0_for_pcie		= { 0x0000, 15, 0, 0x00, 0x1000 },
+	.con1_for_pcie		= { 0x0004, 15, 0, 0x00, 0x0000 },
+	.con2_for_pcie		= { 0x0008, 15, 0, 0x00, 0x0101 },
+	.con3_for_pcie		= { 0x000c, 15, 0, 0x00, 0x0200 },
+	.con0_for_sata		= { 0x0000, 15, 0, 0x00, 0x0129 },
+	.con1_for_sata		= { 0x0004, 15, 0, 0x00, 0x0000 },
+	.con2_for_sata		= { 0x0008, 15, 0, 0x00, 0x80c1 },
+	.con3_for_sata		= { 0x000c, 15, 0, 0x00, 0x0407 },
+	/* php-grf */
+	.pipe_con0_for_sata	= { 0x0058, 2, 0, 0x00, 0x2 },
+	.pipe_con1_for_sata	= { 0x005c, 2, 0, 0x00, 0x2 },
+};
+
+static const struct rockchip_combphy_cfg rk3572_combphy_cfgs = {
+	.grfcfg		= &rk3572_combphy_grfcfgs,
+	.combphy_cfg	= rk3572_combphy_cfg,
+};
+
 static int rk3576_combphy_cfg(struct rockchip_combphy_priv *priv)
 {
 	const struct rockchip_combphy_grfcfg *cfg = priv->cfg->grfcfg;
@@ -1407,6 +1605,9 @@ static const struct of_device_id rockchip_combphy_of_match[] = {
 		.data = &rk3568_combphy_cfgs,
 	},
 	{
+		.compatible = "rockchip,rk3572-naneng-combphy",
+		.data = &rk3572_combphy_cfgs,
+	}, {
 		.compatible = "rockchip,rk3576-naneng-combphy",
 		.data = &rk3576_combphy_cfgs,
 	},

-- 
2.34.1

