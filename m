From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Tue, 06 Feb 2024 01:08:05 +0300
Subject: [PATCH net-next v5 4/7] net: dsa: mt7530: call port 6 setup from
 mt7530_mac_config()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240206-for-netnext-mt7530-improvements-2-v5-4-d7d92a185cb1@arinc9.com>
References: <20240206-for-netnext-mt7530-improvements-2-v5-0-d7d92a185cb1@arinc9.com>
In-Reply-To: <20240206-for-netnext-mt7530-improvements-2-v5-0-d7d92a185cb1@arinc9.com>
To: Daniel Golle <daniel@makrotopia.org>, DENG Qingfang <dqfext@gmail.com>, 
 Sean Wang <sean.wang@mediatek.com>, Andrew Lunn <andrew@lunn.ch>, 
 Florian Fainelli <f.fainelli@gmail.com>, 
 Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Russell King <linux@armlinux.org.uk>
Cc: mithat.guner@xeront.com, erkin.bozoglu@xeront.com, 
 Bartel Eerdekens <bartel.eerdekens@constell8.be>, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>, 
 "Russell King (Oracle)" <rmk+kernel@armlinux.org.uk>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707170890; l=2979;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=UBXiDmUmgNDE85r+ztHOrUIfTqBEqvXKt7NAM/BM3UM=;
 b=00was5bGkw7O2xyflNXvpULDNK4uI/oAl8q+Mmi/ctA5y3Ph/OEFfbROXJXfjwuEmyP6KsWX3
 FFBAh3y1X7pDgElk6nb8ksdSHFwaF6EjB8dJPpMELsjcfmQBLt/UAwB
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mt7530_pad_clk_setup() is called if port 6 is enabled. It used to do more
things than setting up port 6. That part was moved to more appropriate
locations, mt7530_setup() and mt7530_pll_setup().

Now that all it does is set up port 6, rename it to mt7530_setup_port6(),
and move it to a more appropriate location, under mt7530_mac_config().

Change mt7530_setup_port6() to void as there're no error cases.

Leave an empty mt7530_pad_clk_setup() to satisfy the pad_setup function
pointer.

This is the code path for setting up the ports before:

dsa_switch_ops :: phylink_mac_config() -> mt753x_phylink_mac_config()
-> mt753x_mac_config()
   -> mt753x_info :: mac_port_config() -> mt7530_mac_config()
      -> mt7530_setup_port5()
-> mt753x_pad_setup()
   -> mt753x_info :: pad_setup() -> mt7530_pad_clk_setup()

This is after:

dsa_switch_ops :: phylink_mac_config() -> mt753x_phylink_mac_config()
-> mt753x_mac_config()
   -> mt753x_info :: mac_port_config() -> mt7530_mac_config()
      -> mt7530_setup_port5()
      -> mt7530_setup_port6()

Reviewed-by: Vladimir Oltean <olteanv@gmail.com>
Reviewed-by: Russell King (Oracle) <rmk+kernel@armlinux.org.uk>
Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
 drivers/net/dsa/mt7530.c | 19 +++++++++++--------
 1 file changed, 11 insertions(+), 8 deletions(-)

diff --git a/drivers/net/dsa/mt7530.c b/drivers/net/dsa/mt7530.c
index e13b9c9cb19f..65c2f5f275a3 100644
--- a/drivers/net/dsa/mt7530.c
+++ b/drivers/net/dsa/mt7530.c
@@ -414,8 +414,8 @@ mt753x_preferred_default_local_cpu_port(struct dsa_switch *ds)
 }
 
 /* Setup port 6 interface mode and TRGMII TX circuit */
-static int
-mt7530_pad_clk_setup(struct dsa_switch *ds, phy_interface_t interface)
+static void
+mt7530_setup_port6(struct dsa_switch *ds, phy_interface_t interface)
 {
 	struct mt7530_priv *priv = ds->priv;
 	u32 ncpo1, ssc_delta, xtal;
@@ -426,7 +426,7 @@ mt7530_pad_clk_setup(struct dsa_switch *ds, phy_interface_t interface)
 	if (interface == PHY_INTERFACE_MODE_RGMII) {
 		mt7530_rmw(priv, MT7530_P6ECR, P6_INTF_MODE_MASK,
 			   P6_INTF_MODE(0));
-		return 0;
+		return;
 	}
 
 	mt7530_rmw(priv, MT7530_P6ECR, P6_INTF_MODE_MASK, P6_INTF_MODE(1));
@@ -465,7 +465,11 @@ mt7530_pad_clk_setup(struct dsa_switch *ds, phy_interface_t interface)
 
 	/* Enable the MT7530 TRGMII clocks */
 	core_set(priv, CORE_TRGMII_GSW_CLK_CG, REG_TRGMIICK_EN);
+}
 
+static int
+mt7530_pad_clk_setup(struct dsa_switch *ds, phy_interface_t interface)
+{
 	return 0;
 }
 
@@ -2613,11 +2617,10 @@ mt7530_mac_config(struct dsa_switch *ds, int port, unsigned int mode,
 {
 	struct mt7530_priv *priv = ds->priv;
 
-	/* Only need to setup port5. */
-	if (port != 5)
-		return 0;
-
-	mt7530_setup_port5(priv->ds, interface);
+	if (port == 5)
+		mt7530_setup_port5(priv->ds, interface);
+	else if (port == 6)
+		mt7530_setup_port6(priv->ds, interface);
 
 	return 0;
 }

-- 
2.40.1

