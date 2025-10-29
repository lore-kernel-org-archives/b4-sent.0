From: Rohan G Thomas <rohan.g.thomas@altera.com>
Date: Wed, 29 Oct 2025 16:06:13 +0800
Subject: [PATCH net-next 1/4] net: stmmac: socfpga: Agilex5 EMAC platform
 configuration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251029-agilex5_ext-v1-1-1931132d77d6@altera.com>
References: <20251029-agilex5_ext-v1-0-1931132d77d6@altera.com>
In-Reply-To: <20251029-agilex5_ext-v1-0-1931132d77d6@altera.com>
To: Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Richard Cochran <richardcochran@gmail.com>, 
 Steffen Trumtrar <s.trumtrar@pengutronix.de>
Cc: netdev@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Rohan G Thomas <rohan.g.thomas@altera.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761725182; l=4008;
 i=rohan.g.thomas@altera.com; s=20250815; h=from:subject:message-id;
 bh=fqpheFKts6+7OsBqsj9xRO/POu9s39bQIp1U3z6E4Sk=;
 b=YohBBb/PJcQ7AlroGARqRd4AYmGE4QmSVQzy2BMDhtBTSq+CR5nGjCP4j5YphFG2mIhAp7T9/
 qCSWpLuHYEDAORQd7rU9kKLKkHWQhfhPffjsdxoTfsCfP7J9wp1rmSS
X-Developer-Key: i=rohan.g.thomas@altera.com; a=ed25519;
 pk=5yZXkXswhfUILKAQwoIn7m6uSblwgV5oppxqde4g4TY=
X-Endpoint-Received: by B4 Relay for rohan.g.thomas@altera.com/20250815 with auth_id=494
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Agilex5 HPS EMAC uses the dwxgmac-3.10a IP, unlike previous socfpga
platforms which use dwmac1000 IP. Due to differences in platform
configuration, Agilex5 requires a distinct setup.

Introduce a setup_plat_dat() callback in socfpga_dwmac_ops to handle
platform-specific setup. This callback is invoked before
stmmac_dvr_probe() to ensure the platform data is correctly
configured. Also, implemented separate setup_plat_dat() callback for
current socfpga platforms and Agilex5.

Signed-off-by: Rohan G Thomas <rohan.g.thomas@altera.com>
---
 .../net/ethernet/stmicro/stmmac/dwmac-socfpga.c    | 53 ++++++++++++++++++----
 1 file changed, 43 insertions(+), 10 deletions(-)

diff --git a/drivers/net/ethernet/stmicro/stmmac/dwmac-socfpga.c b/drivers/net/ethernet/stmicro/stmmac/dwmac-socfpga.c
index 2ff5db6d41ca08a1652d57f3eb73923b9a9558bf..3dae4f3c103802ed1c2cd390634bd5473192d4ee 100644
--- a/drivers/net/ethernet/stmicro/stmmac/dwmac-socfpga.c
+++ b/drivers/net/ethernet/stmicro/stmmac/dwmac-socfpga.c
@@ -44,6 +44,7 @@
 struct socfpga_dwmac;
 struct socfpga_dwmac_ops {
 	int (*set_phy_mode)(struct socfpga_dwmac *dwmac_priv);
+	void (*setup_plat_dat)(struct socfpga_dwmac *dwmac_priv);
 };
 
 struct socfpga_dwmac {
@@ -441,6 +442,39 @@ static int socfpga_dwmac_init(struct platform_device *pdev, void *bsp_priv)
 	return dwmac->ops->set_phy_mode(dwmac);
 }
 
+static void socfpga_common_plat_dat(struct socfpga_dwmac *dwmac)
+{
+	struct plat_stmmacenet_data *plat_dat = dwmac->plat_dat;
+
+	plat_dat->bsp_priv = dwmac;
+	plat_dat->fix_mac_speed = socfpga_dwmac_fix_mac_speed;
+	plat_dat->init = socfpga_dwmac_init;
+	plat_dat->pcs_init = socfpga_dwmac_pcs_init;
+	plat_dat->pcs_exit = socfpga_dwmac_pcs_exit;
+	plat_dat->select_pcs = socfpga_dwmac_select_pcs;
+}
+
+static void socfpga_gen5_setup_plat_dat(struct socfpga_dwmac *dwmac)
+{
+	struct plat_stmmacenet_data *plat_dat = dwmac->plat_dat;
+
+	socfpga_common_plat_dat(dwmac);
+
+	plat_dat->core_type = DWMAC_CORE_GMAC;
+
+	/* Rx watchdog timer in dwmac is buggy in this hw */
+	plat_dat->riwt_off = 1;
+}
+
+static void socfpga_agilex5_setup_plat_dat(struct socfpga_dwmac *dwmac)
+{
+	struct plat_stmmacenet_data *plat_dat = dwmac->plat_dat;
+
+	socfpga_common_plat_dat(dwmac);
+
+	plat_dat->core_type = DWMAC_CORE_XGMAC;
+}
+
 static int socfpga_dwmac_probe(struct platform_device *pdev)
 {
 	struct plat_stmmacenet_data *plat_dat;
@@ -491,31 +525,30 @@ static int socfpga_dwmac_probe(struct platform_device *pdev)
 	dwmac->ops = ops;
 	dwmac->plat_dat = plat_dat;
 
-	plat_dat->bsp_priv = dwmac;
-	plat_dat->fix_mac_speed = socfpga_dwmac_fix_mac_speed;
-	plat_dat->init = socfpga_dwmac_init;
-	plat_dat->pcs_init = socfpga_dwmac_pcs_init;
-	plat_dat->pcs_exit = socfpga_dwmac_pcs_exit;
-	plat_dat->select_pcs = socfpga_dwmac_select_pcs;
-	plat_dat->core_type = DWMAC_CORE_GMAC;
-
-	plat_dat->riwt_off = 1;
+	ops->setup_plat_dat(dwmac);
 
 	return devm_stmmac_pltfr_probe(pdev, plat_dat, &stmmac_res);
 }
 
 static const struct socfpga_dwmac_ops socfpga_gen5_ops = {
 	.set_phy_mode = socfpga_gen5_set_phy_mode,
+	.setup_plat_dat = socfpga_gen5_setup_plat_dat,
 };
 
 static const struct socfpga_dwmac_ops socfpga_gen10_ops = {
 	.set_phy_mode = socfpga_gen10_set_phy_mode,
+	.setup_plat_dat = socfpga_gen5_setup_plat_dat,
+};
+
+static const struct socfpga_dwmac_ops socfpga_agilex5_ops = {
+	.set_phy_mode = socfpga_gen10_set_phy_mode,
+	.setup_plat_dat = socfpga_agilex5_setup_plat_dat,
 };
 
 static const struct of_device_id socfpga_dwmac_match[] = {
 	{ .compatible = "altr,socfpga-stmmac", .data = &socfpga_gen5_ops },
 	{ .compatible = "altr,socfpga-stmmac-a10-s10", .data = &socfpga_gen10_ops },
-	{ .compatible = "altr,socfpga-stmmac-agilex5", .data = &socfpga_gen10_ops },
+	{ .compatible = "altr,socfpga-stmmac-agilex5", .data = &socfpga_agilex5_ops },
 	{ }
 };
 MODULE_DEVICE_TABLE(of, socfpga_dwmac_match);

-- 
2.43.7

