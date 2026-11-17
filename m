From: Igor Velkov <iav@iav.lv>
Date: Tue, 17 Nov 2026 00:54:06 +0000
Subject: [PATCH net v2] net: mdio: mux-meson-g12a: keep the MAC data path
 when switching MDIO
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-g12a-mux-data-path-v2-1-fc56db5973af@iav.lv>
X-B4-Tracking: v=1; b=H4sIAK6l+2oC/32NTQ6CMBCFr0Jm7RimKn8r72FYDLTCJFpIWxsM4
 e42PYDL77287+3gjRPjoSt2cCaKl8UmUKcCxpntZFB0YlClqojohhMpxvdnQ82BceUwY3VVPOh
 hrAfVQhquzjxly9IHWBOgT+EsPizum48i5eqfMxISlkSadX1pqra5C8fzK0J/HMcPQbjRyLYAA
 AA=
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: netdev@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=4841; i=iav@iav.lv;
 h=from:subject:message-id; bh=Oka1iBI9vfxsi4AhO3yJ38sooyDgeJia2wLavleLy1U=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFm/l25o1Wb33sA1P7/WYGdUtIT4ga9nZLmeb3rAPiUoe
 Y5Php1fRykLgxgXg6yYIsuEQxq3MpZc/evvYf4AZg4rE8gQBi5OAZhIqwfD/zTzR62Lp0xv87za
 +3b5mhr/Lh7x6js/L78psNGzrHt0SZHhf8WnScJL1tlOCwqYu2ZTdyFjV/f7kOyeUxZaop5nV6S
 HMwIA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Switching the mux to the internal MDIO bus writes SMI_SRC_MAC together
with USE_INTERNAL and RX_CLK_EPHY to ETH_PHY_CNTL2. The last two move the
MAC data path and RX clock to the internal PHY. On boards whose MAC uses
an external PHY, any access to the internal PHY stops reception until an
access to the external bus switches the mux back.

phylib suspends and resumes the unattached internal PHY across system
sleep. stmmac sets mac_managed_pm, and with Wake-on-LAN in the MAC
phylink_resume() does not start the external PHY, so nothing switches
the mux back. On ODROID-HC4 (RTL8211F), after suspend-to-RAM with WoL in
the MAC and an RTC wakeup, ETH_PHY_CNTL2 stays at 0x260 and the MAC
receives nothing while TX works.

With the MAC on the external PHY, SMI_SRC_MAC alone is enough to read
the internal PHY ID (0x0180/0x3301) while RX keeps running; adding
USE_INTERNAL or RX_CLK_EPHY stops RX.

Set the data path bits only when the PHY the MAC attaches sits on the
internal bus. Look the PHY up with fwnode_get_phy_node(), as stmmac
does, so phy-handle and the deprecated phy and phy-device all count.

Fixes: 7090425104db ("net: phy: add amlogic g12a mdio mux support")
Signed-off-by: Igor Velkov <iav@iav.lv>
---
Tested on ODROID-HC4: three RTC wakeups from suspend-to-RAM with WoL in
the MAC (ETH_PHY_CNTL2 0x40, RX working), one without WoL.
---
Changes in v2:
- Find the PHY with fwnode_get_phy_node(), as stmmac does, so the
  deprecated phy and phy-device references count too (Sashiko).
- Drop the dwmac-rk comparison from the comment and commit message.
- Link to v1: https://lore.kernel.org/r/20261115-g12a-mux-data-path-v1-1-011dad738698@iav.lv
---
 drivers/net/mdio/mdio-mux-meson-g12a.c | 50 ++++++++++++++++++++++++++++++----
 1 file changed, 45 insertions(+), 5 deletions(-)

diff --git a/drivers/net/mdio/mdio-mux-meson-g12a.c b/drivers/net/mdio/mdio-mux-meson-g12a.c
index 71c44385489d..e0acbd3ed383 100644
--- a/drivers/net/mdio/mdio-mux-meson-g12a.c
+++ b/drivers/net/mdio/mdio-mux-meson-g12a.c
@@ -12,6 +12,7 @@
 #include <linux/iopoll.h>
 #include <linux/mdio-mux.h>
 #include <linux/module.h>
+#include <linux/of.h>
 #include <linux/phy.h>
 #include <linux/platform_device.h>
 
@@ -56,6 +57,7 @@ struct g12a_mdio_mux {
 	void __iomem *regs;
 	void *mux_handle;
 	struct clk *pll;
+	bool mac_uses_internal_phy;
 };
 
 struct g12a_ephy_pll {
@@ -149,7 +151,7 @@ static const struct clk_ops g12a_ephy_pll_ops = {
 
 static int g12a_enable_internal_mdio(struct g12a_mdio_mux *priv)
 {
-	u32 value;
+	u32 value, cntl2;
 	int ret;
 
 	/* Enable the phy clock */
@@ -169,10 +171,11 @@ static int g12a_enable_internal_mdio(struct g12a_mdio_mux *priv)
 		PHY_CNTL1_CLK_EN |
 		PHY_CNTL1_CLKFREQ;
 	writel(value, priv->regs + ETH_PHY_CNTL1);
-	writel(PHY_CNTL2_USE_INTERNAL |
-	       PHY_CNTL2_SMI_SRC_MAC |
-	       PHY_CNTL2_RX_CLK_EPHY,
-	       priv->regs + ETH_PHY_CNTL2);
+
+	cntl2 = PHY_CNTL2_SMI_SRC_MAC;
+	if (priv->mac_uses_internal_phy)
+		cntl2 |= PHY_CNTL2_USE_INTERNAL | PHY_CNTL2_RX_CLK_EPHY;
+	writel(cntl2, priv->regs + ETH_PHY_CNTL2);
 
 	value |= PHY_CNTL1_PHY_ENB;
 	writel(value, priv->regs + ETH_PHY_CNTL1);
@@ -301,6 +304,42 @@ static int g12a_ephy_glue_clk_register(struct device *dev)
 	return 0;
 }
 
+/* The data path follows the PHY the MAC attaches, looked up as stmmac does */
+static bool g12a_mac_uses_internal_phy(struct device_node *mux_np)
+{
+	struct device_node *parent_bus, *mac, *phy_bus, *mux;
+	struct fwnode_handle *phy;
+	bool internal = false;
+	u32 reg;
+
+	parent_bus = of_parse_phandle(mux_np, "mdio-parent-bus", 0);
+	if (!parent_bus)
+		return false;
+
+	mac = of_get_parent(parent_bus);
+	of_node_put(parent_bus);
+	if (!mac)
+		return false;
+
+	phy = fwnode_get_phy_node(of_fwnode_handle(mac));
+	of_node_put(mac);
+	if (IS_ERR(phy))
+		return false;
+
+	phy_bus = of_get_parent(to_of_node(phy));
+	fwnode_handle_put(phy);
+	if (!phy_bus)
+		return false;
+
+	mux = of_get_parent(phy_bus);
+	if (mux == mux_np && !of_property_read_u32(phy_bus, "reg", &reg))
+		internal = (reg == MESON_G12A_MDIO_INTERNAL_ID);
+	of_node_put(mux);
+	of_node_put(phy_bus);
+
+	return internal;
+}
+
 static int g12a_mdio_mux_probe(struct platform_device *pdev)
 {
 	struct device *dev = &pdev->dev;
@@ -313,6 +352,7 @@ static int g12a_mdio_mux_probe(struct platform_device *pdev)
 		return -ENOMEM;
 
 	platform_set_drvdata(pdev, priv);
+	priv->mac_uses_internal_phy = g12a_mac_uses_internal_phy(dev->of_node);
 
 	priv->regs = devm_platform_ioremap_resource(pdev, 0);
 	if (IS_ERR(priv->regs))

---
base-commit: aa40afa831ebfe45e40a23721711059f2ac584d4
change-id: 20261115-g12a-mux-data-path-642abdbc7b29

Best regards,
-- 
Igor Velkov <iav@iav.lv>

