From: "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
Date: Sun, 24 Nov 2024 23:42:34 +0100
Subject: [PATCH RFC net-next v6 03/15] net: stmmac: Fix clock rate
 variables size
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241124-upstream_s32cc_gmac-v6-3-dc5718ccf001@oss.nxp.com>
References: <20241124-upstream_s32cc_gmac-v6-0-dc5718ccf001@oss.nxp.com>
In-Reply-To: <20241124-upstream_s32cc_gmac-v6-0-dc5718ccf001@oss.nxp.com>
To: Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Jose Abreu <joabreu@synopsys.com>, "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Vinod Koul <vkoul@kernel.org>, 
 Richard Cochran <richardcochran@gmail.com>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, Emil Renner Berthing <kernel@esmil.dk>, 
 Minda Chen <minda.chen@starfivetech.com>, 
 Nicolas Ferre <nicolas.ferre@microchip.com>, 
 Claudiu Beznea <claudiu.beznea@tuxon.dev>, 
 Iyappan Subramanian <iyappan@os.amperecomputing.com>, 
 Keyur Chudgar <keyur@os.amperecomputing.com>, 
 Quan Nguyen <quan@os.amperecomputing.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Giuseppe Cavallaro <peppe.cavallaro@st.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>
Cc: linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 netdev@vger.kernel.org, linux-arm-msm@vger.kernel.org, imx@lists.linux.dev, 
 devicetree@vger.kernel.org, NXP S32 Linux Team <s32@nxp.com>, 
 "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>, 
 Serge Semin <fancer.lancer@gmail.com>, 
 "Russell King (Oracle)" <rmk+kernel@armlinux.org.uk>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732488190; l=4080;
 i=jan.petrous@oss.nxp.com; s=20240922; h=from:subject:message-id;
 bh=PjyG/bciJnCl1zgeP+KpvNNgB+qJrOmgZuJqhRBWPuo=;
 b=znvrXADUMs7BxpCCyJgP1HuR3JqECd26+Chy+zoixcHYROslkHXw/fTTAB+uowr5PemF3CLtK
 01+r6V+Ys4WB5tuqI6/KCRdJHwt2810f73zX4oeBSttpiWq16dO6c9R
X-Developer-Key: i=jan.petrous@oss.nxp.com; a=ed25519;
 pk=Ke3wwK7rb2Me9UQRf6vR8AsfJZfhTyoDaxkUCqmSWYY=
X-Endpoint-Received: by B4 Relay for jan.petrous@oss.nxp.com/20240922 with auth_id=217
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The clock API clk_get_rate() returns unsigned long value.
Expand affected members of stmmac platform data and
convert the stmmac_clk_csr_set() and dwmac4_core_init() methods
to defining the unsigned long clk_rate local variables.

Reviewed-by: Andrew Lunn <andrew@lunn.ch>
Reviewed-by: Serge Semin <fancer.lancer@gmail.com>
Reviewed-by: Russell King (Oracle) <rmk+kernel@armlinux.org.uk>
Signed-off-by: Jan Petrous (OSS) <jan.petrous@oss.nxp.com>
---
 drivers/net/ethernet/stmicro/stmmac/dwmac-qcom-ethqos.c | 2 +-
 drivers/net/ethernet/stmicro/stmmac/dwmac4_core.c       | 2 +-
 drivers/net/ethernet/stmicro/stmmac/stmmac_main.c       | 2 +-
 drivers/net/ethernet/stmicro/stmmac/stmmac_platform.c   | 2 +-
 include/linux/stmmac.h                                  | 6 +++---
 5 files changed, 7 insertions(+), 7 deletions(-)

diff --git a/drivers/net/ethernet/stmicro/stmmac/dwmac-qcom-ethqos.c b/drivers/net/ethernet/stmicro/stmmac/dwmac-qcom-ethqos.c
index 901a3c1959fa..2a5b38723635 100644
--- a/drivers/net/ethernet/stmicro/stmmac/dwmac-qcom-ethqos.c
+++ b/drivers/net/ethernet/stmicro/stmmac/dwmac-qcom-ethqos.c
@@ -777,7 +777,7 @@ static void ethqos_ptp_clk_freq_config(struct stmmac_priv *priv)
 		netdev_err(priv->dev, "Failed to max out clk_ptp_ref: %d\n", err);
 	plat_dat->clk_ptp_rate = clk_get_rate(plat_dat->clk_ptp_ref);
 
-	netdev_dbg(priv->dev, "PTP rate %d\n", plat_dat->clk_ptp_rate);
+	netdev_dbg(priv->dev, "PTP rate %lu\n", plat_dat->clk_ptp_rate);
 }
 
 static int qcom_ethqos_probe(struct platform_device *pdev)
diff --git a/drivers/net/ethernet/stmicro/stmmac/dwmac4_core.c b/drivers/net/ethernet/stmicro/stmmac/dwmac4_core.c
index c25781874aa7..c36f90a782c5 100644
--- a/drivers/net/ethernet/stmicro/stmmac/dwmac4_core.c
+++ b/drivers/net/ethernet/stmicro/stmmac/dwmac4_core.c
@@ -27,7 +27,7 @@ static void dwmac4_core_init(struct mac_device_info *hw,
 	struct stmmac_priv *priv = netdev_priv(dev);
 	void __iomem *ioaddr = hw->pcsr;
 	u32 value = readl(ioaddr + GMAC_CONFIG);
-	u32 clk_rate;
+	unsigned long clk_rate;
 
 	value |= GMAC_CORE_INIT;
 
diff --git a/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c b/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
index 8304f82b3a50..efbf34456612 100644
--- a/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
+++ b/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
@@ -301,7 +301,7 @@ static void stmmac_global_err(struct stmmac_priv *priv)
  */
 static void stmmac_clk_csr_set(struct stmmac_priv *priv)
 {
-	u32 clk_rate;
+	unsigned long clk_rate;
 
 	clk_rate = clk_get_rate(priv->plat->stmmac_clk);
 
diff --git a/drivers/net/ethernet/stmicro/stmmac/stmmac_platform.c b/drivers/net/ethernet/stmicro/stmmac/stmmac_platform.c
index 3ac32444e492..06e07e6e180b 100644
--- a/drivers/net/ethernet/stmicro/stmmac/stmmac_platform.c
+++ b/drivers/net/ethernet/stmicro/stmmac/stmmac_platform.c
@@ -640,7 +640,7 @@ stmmac_probe_config_dt(struct platform_device *pdev, u8 *mac)
 		dev_info(&pdev->dev, "PTP uses main clock\n");
 	} else {
 		plat->clk_ptp_rate = clk_get_rate(plat->clk_ptp_ref);
-		dev_dbg(&pdev->dev, "PTP rate %d\n", plat->clk_ptp_rate);
+		dev_dbg(&pdev->dev, "PTP rate %lu\n", plat->clk_ptp_rate);
 	}
 
 	plat->stmmac_rst = devm_reset_control_get_optional(&pdev->dev,
diff --git a/include/linux/stmmac.h b/include/linux/stmmac.h
index 865d0fe26f98..c9878a612e53 100644
--- a/include/linux/stmmac.h
+++ b/include/linux/stmmac.h
@@ -252,8 +252,8 @@ struct plat_stmmacenet_data {
 	struct clk *stmmac_clk;
 	struct clk *pclk;
 	struct clk *clk_ptp_ref;
-	unsigned int clk_ptp_rate;
-	unsigned int clk_ref_rate;
+	unsigned long clk_ptp_rate;
+	unsigned long clk_ref_rate;
 	unsigned int mult_fact_100ns;
 	s32 ptp_max_adj;
 	u32 cdc_error_adj;
@@ -265,7 +265,7 @@ struct plat_stmmacenet_data {
 	int mac_port_sel_speed;
 	int has_xgmac;
 	u8 vlan_fail_q;
-	unsigned int eee_usecs_rate;
+	unsigned long eee_usecs_rate;
 	struct pci_dev *pdev;
 	int int_snapshot_num;
 	int msi_mac_vec;

-- 
2.47.0

