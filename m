From: Igor Velkov <iav@iav.lv>
Date: Wed, 30 Sep 2026 19:34:45 +0000
Subject: [PATCH net] net: stmmac: dwmac-rk: keep the GMAC powered when the
 PHY wakes the system
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-dwmac-rk-phy-wol-v1-1-9fdc50bd9ae4@iav.lv>
X-B4-Tracking: v=1; b=H4sIAFRkvWoC/x3MQQ5AMBBA0avIrE1SJJNwFbEohk5Q0oqSxt01l
 m/xfwTPTthDk0VwfImX3SYUeQaD0XZmlDEZSlWSqiuFY9j0gG7BwzwY9hV7LliTJkXUQ8oOx5P
 c/7IFyyd07/sBjY2M0WcAAAA=
To: Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Heiko Stuebner <heiko@sntech.de>, 
 Eric Dumazet <edumazet@kernel.org>
Cc: "Russell King (Oracle)" <rmk+kernel@armlinux.org.uk>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, netdev@vger.kernel.org, 
 linux-rockchip@lists.infradead.org, 
 linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2718; i=iav@iav.lv;
 h=from:subject:message-id; bh=v2FMuWUABRc83FaiGNq51H6LZX+xOp9sURDtyb+WJCs=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFl7U8JcJqjtMr1SfGhbwq86VaVL/1MuRUq7PIqVaL2io
 GEjv0y3o5SFQYyLQVZMkWXCIY1bGUuu/vX3MH8AM4eVCWQIAxenAEzkTg8jwzmJwFPGq3ZeYFsS
 VPt7jdRjNfmM5R/j5KKmbAtOF7U142dkmPtLeZd1f+6e3RFn/2wsXTBTxan4v5GWQnXAL3sDvfP
 HOAE=
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit 6911308d7d11 ("net: stmmac: convert to phylink-managed
Wake-on-Lan"), the MAC device gets its wakeup flag only when the MAC
handles Wake-on-LAN itself. When the PHY handles it, device_may_wakeup()
is false for the MAC, and rk_gmac_suspend() powers the GMAC down: its
clocks stop and phy-supply is released.

On Helios64 (RTL8211F, Wake-on-LAN in the PHY) the board then hangs on
the first or second suspend with a magic-packet wake.

Also keep the GMAC powered when phy_may_wakeup() is true, and remember
the decision for resume.

Fixes: 6911308d7d11 ("net: stmmac: convert to phylink-managed Wake-on-Lan")
Assisted-by: LLM
Signed-off-by: Igor Velkov <iav@iav.lv>
---
Tested on Helios64 with 7.3-rc5: 20 of 20 suspends woke on a magic
packet. The mainline Helios64 DT has no PHY node, so the test used a
DT that describes the PHY with its interrupt and wakeup-source (a DT
patch will follow), together with [1], which fixes an interrupt storm
on resume.

[1] https://lore.kernel.org/r/20260930-stmmac-irq-shut-v1-1-104d1a1dcb28@iav.lv
---
 drivers/net/ethernet/stmicro/stmmac/dwmac-rk.c | 11 +++++++----
 1 file changed, 7 insertions(+), 4 deletions(-)

diff --git a/drivers/net/ethernet/stmicro/stmmac/dwmac-rk.c b/drivers/net/ethernet/stmicro/stmmac/dwmac-rk.c
index 72bdbcb5e863..06faeb156b97 100644
--- a/drivers/net/ethernet/stmicro/stmmac/dwmac-rk.c
+++ b/drivers/net/ethernet/stmicro/stmmac/dwmac-rk.c
@@ -98,6 +98,7 @@ struct rk_priv_data {
 	bool integrated_phy;
 	bool supports_rgmii;
 	bool supports_rmii;
+	bool suspend_powerdown;
 
 	struct clk_bulk_data *clks;
 	int num_clks;
@@ -1530,10 +1531,13 @@ static int rk_set_clk_tx_rate(void *bsp_priv_, struct clk *clk_tx_i,
 
 static int rk_gmac_suspend(struct device *dev, void *bsp_priv_)
 {
+	struct net_device *ndev = dev_get_drvdata(dev);
 	struct rk_priv_data *bsp_priv = bsp_priv_;
 
-	/* Keep the PHY up if we use Wake-on-Lan. */
-	if (!device_may_wakeup(dev))
+	/* Keep the MAC and PHY powered if either of them wakes the system. */
+	bsp_priv->suspend_powerdown = !device_may_wakeup(dev) &&
+		!(ndev->phydev && phy_may_wakeup(ndev->phydev));
+	if (bsp_priv->suspend_powerdown)
 		rk_gmac_powerdown(bsp_priv);
 
 	return 0;
@@ -1543,8 +1547,7 @@ static int rk_gmac_resume(struct device *dev, void *bsp_priv_)
 {
 	struct rk_priv_data *bsp_priv = bsp_priv_;
 
-	/* The PHY was up for Wake-on-Lan. */
-	if (!device_may_wakeup(dev))
+	if (bsp_priv->suspend_powerdown)
 		rk_gmac_powerup(bsp_priv);
 
 	return 0;

---
base-commit: 99b43ede9e355ba35244cc9470bf1819774ce39d
change-id: 20260930-dwmac-rk-phy-wol-be1ea6a6066b

Best regards,
-- 
Igor Velkov <iav@iav.lv>

