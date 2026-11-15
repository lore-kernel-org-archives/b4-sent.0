From: Igor Velkov <iav@iav.lv>
Date: Sun, 15 Nov 2026 19:22:08 +0000
Subject: [PATCH net] net: mdio: mux-meson-g12a: keep the MAC data path when
 switching MDIO
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-g12a-mux-data-path-v1-1-011dad738698@iav.lv>
X-B4-Tracking: v=1; b=H4sIAF8G+moC/x3MQQqEMAxA0atI1gZMcBTnKoOL1EbNwiptZxDEu
 1tm+Rb/X5A0miZ4VxdE/VmyPRRQXcG0SlgUzRcDN9wR0QsXYsHte6KXLHhIXrFrWZx3U+94gBI
 eUWc7/9MPBM0w3vcDR/PlzWkAAAA=
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=4492; i=iav@iav.lv;
 h=from:subject:message-id; bh=rixsLn/9QY2RgeRhk+RdadQVMXkG8S6mNv5cUWus1nk=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFm/2BK38l3+vnLXneB3c4Um/vN+9ndKXUs372TV2JmGP
 g/ehh+70FHKwiDGxSArpsgy4ZDGrYwlV//6e5g/gJnDygQyhIGLUwAmcmonw//q4PWZTL6G15tS
 ArUFlx2RiTr89XnppPMWR8ybJ/lerlrCyHDh/pOaGTX+SqGnXeY0aiQ3L36XLxrxqp1Zvtw+leX
 3Sg4A
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

Set the data path bits only when the MAC's phy-handle names a PHY on
the internal bus. As in dwmac-rk, which reads phy-is-integrated from
that node, the node phy-handle names decides; here it is the mux bus
the PHY sits on.

Fixes: 7090425104db ("net: phy: add amlogic g12a mdio mux support")
Signed-off-by: Igor Velkov <iav@iav.lv>
---
Tested on ODROID-HC4: three RTC wakeups from suspend-to-RAM with WoL in
the MAC (ETH_PHY_CNTL2 0x40, RX working), one without WoL.
---
 drivers/net/mdio/mdio-mux-meson-g12a.c | 49 ++++++++++++++++++++++++++++++----
 1 file changed, 44 insertions(+), 5 deletions(-)

diff --git a/drivers/net/mdio/mdio-mux-meson-g12a.c b/drivers/net/mdio/mdio-mux-meson-g12a.c
index 71c44385489d..ed688d48eaf0 100644
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
@@ -301,6 +304,41 @@ static int g12a_ephy_glue_clk_register(struct device *dev)
 	return 0;
 }
 
+/* Like dwmac-rk: the PHY named by the MAC's phy-handle decides the data path */
+static bool g12a_mac_uses_internal_phy(struct device_node *mux_np)
+{
+	struct device_node *parent_bus, *mac, *phy, *phy_bus, *mux;
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
+	phy = of_parse_phandle(mac, "phy-handle", 0);
+	of_node_put(mac);
+	if (!phy)
+		return false;
+
+	phy_bus = of_get_parent(phy);
+	of_node_put(phy);
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
@@ -313,6 +351,7 @@ static int g12a_mdio_mux_probe(struct platform_device *pdev)
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

