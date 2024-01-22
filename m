From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Mon, 22 Jan 2024 08:35:55 +0300
Subject: [PATCH net-next v3 4/7] net: dsa: mt7530: improve comments
 regarding switch ports
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240122-for-netnext-mt7530-improvements-1-v3-4-042401f2b279@arinc9.com>
References: <20240122-for-netnext-mt7530-improvements-1-v3-0-042401f2b279@arinc9.com>
In-Reply-To: <20240122-for-netnext-mt7530-improvements-1-v3-0-042401f2b279@arinc9.com>
To: Daniel Golle <daniel@makrotopia.org>, 
 Landen Chao <Landen.Chao@mediatek.com>, DENG Qingfang <dqfext@gmail.com>, 
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
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705901755; l=4567;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=rLcHCbYDzkt28v28nq9XIDczR9kM3jpJ8YmzJ0uoUlo=;
 b=P9VOv8+icSWtarQqBoOfyPHXdJUQtTer/Hw1RKxWe3HptZ6UWnYL15uVjd13g8sHELrl5aVez
 DZ0Bb8gDDuYBbL8SBFGTOYBY/b98Q7SFPz4h42o7MxTgYsK7IPd7/fB
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There's no logic to numerically order the CPU ports. Just state the port
number instead.

Remove the irrelevant PHY muxing information from
mt7530_mac_port_get_caps(). Explain the supported MII modes instead.

Remove the out of place PHY muxing information from
mt753x_phylink_mac_config(). The function is for MT7530, MT7531, and the
switch on the MT7988 SoC but there's no PHY muxing on MT7531 or the switch
on the MT7988 SoC.

These comments were gradually introduced with the commits below.
commit ca366d6c889b ("net: dsa: mt7530: Convert to PHYLINK API")
commit 38f790a80560 ("net: dsa: mt7530: Add support for port 5")
commit 88bdef8be9f6 ("net: dsa: mt7530: Extend device data ready for adding
a new hardware")
commit c288575f7810 ("net: dsa: mt7530: Add the support of MT7531 switch")

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
Acked-by: Daniel Golle <daniel@makrotopia.org>
Reviewed-by: Andrew Lunn <andrew@lunn.ch>
Reviewed-by: Vladimir Oltean <olteanv@gmail.com>
---
 drivers/net/dsa/mt7530.c | 30 ++++++++++++++++++++----------
 1 file changed, 20 insertions(+), 10 deletions(-)

diff --git a/drivers/net/dsa/mt7530.c b/drivers/net/dsa/mt7530.c
index c77092506c3f..93d8498ce274 100644
--- a/drivers/net/dsa/mt7530.c
+++ b/drivers/net/dsa/mt7530.c
@@ -2520,12 +2520,14 @@ static void mt7530_mac_port_get_caps(struct dsa_switch *ds, int port,
 				     struct phylink_config *config)
 {
 	switch (port) {
-	case 0 ... 4: /* Internal phy */
+	/* Ports which are connected to switch PHYs. There is no MII pinout. */
+	case 0 ... 4:
 		__set_bit(PHY_INTERFACE_MODE_GMII,
 			  config->supported_interfaces);
 		break;
 
-	case 5: /* 2nd cpu port with phy of port 0 or 4 / external phy */
+	/* Port 5 supports rgmii with delays, mii, and gmii. */
+	case 5:
 		phy_interface_set_rgmii(config->supported_interfaces);
 		__set_bit(PHY_INTERFACE_MODE_MII,
 			  config->supported_interfaces);
@@ -2533,7 +2535,8 @@ static void mt7530_mac_port_get_caps(struct dsa_switch *ds, int port,
 			  config->supported_interfaces);
 		break;
 
-	case 6: /* 1st cpu port */
+	/* Port 6 supports rgmii and trgmii. */
+	case 6:
 		__set_bit(PHY_INTERFACE_MODE_RGMII,
 			  config->supported_interfaces);
 		__set_bit(PHY_INTERFACE_MODE_TRGMII,
@@ -2548,19 +2551,24 @@ static void mt7531_mac_port_get_caps(struct dsa_switch *ds, int port,
 	struct mt7530_priv *priv = ds->priv;
 
 	switch (port) {
-	case 0 ... 4: /* Internal phy */
+	/* Ports which are connected to switch PHYs. There is no MII pinout. */
+	case 0 ... 4:
 		__set_bit(PHY_INTERFACE_MODE_GMII,
 			  config->supported_interfaces);
 		break;
 
-	case 5: /* 2nd cpu port supports either rgmii or sgmii/8023z */
+	/* Port 5 supports rgmii with delays on MT7531BE, sgmii/802.3z on
+	 * MT7531AE.
+	 */
+	case 5:
 		if (!priv->p5_sgmii) {
 			phy_interface_set_rgmii(config->supported_interfaces);
 			break;
 		}
 		fallthrough;
 
-	case 6: /* 1st cpu port supports sgmii/8023z only */
+	/* Port 6 supports sgmii/802.3z. */
+	case 6:
 		__set_bit(PHY_INTERFACE_MODE_SGMII,
 			  config->supported_interfaces);
 		__set_bit(PHY_INTERFACE_MODE_1000BASEX,
@@ -2579,11 +2587,13 @@ static void mt7988_mac_port_get_caps(struct dsa_switch *ds, int port,
 	phy_interface_zero(config->supported_interfaces);
 
 	switch (port) {
-	case 0 ... 4: /* Internal phy */
+	/* Ports which are connected to switch PHYs. There is no MII pinout. */
+	case 0 ... 4:
 		__set_bit(PHY_INTERFACE_MODE_INTERNAL,
 			  config->supported_interfaces);
 		break;
 
+	/* Port 6 is connected to SoC's XGMII MAC. There is no MII pinout. */
 	case 6:
 		__set_bit(PHY_INTERFACE_MODE_INTERNAL,
 			  config->supported_interfaces);
@@ -2747,12 +2757,12 @@ mt753x_phylink_mac_config(struct dsa_switch *ds, int port, unsigned int mode,
 	u32 mcr_cur, mcr_new;
 
 	switch (port) {
-	case 0 ... 4: /* Internal phy */
+	case 0 ... 4:
 		if (state->interface != PHY_INTERFACE_MODE_GMII &&
 		    state->interface != PHY_INTERFACE_MODE_INTERNAL)
 			goto unsupported;
 		break;
-	case 5: /* 2nd cpu port with phy of port 0 or 4 / external phy */
+	case 5:
 		if (priv->p5_interface == state->interface)
 			break;
 
@@ -2762,7 +2772,7 @@ mt753x_phylink_mac_config(struct dsa_switch *ds, int port, unsigned int mode,
 		if (priv->p5_intf_sel != P5_DISABLED)
 			priv->p5_interface = state->interface;
 		break;
-	case 6: /* 1st cpu port */
+	case 6:
 		if (priv->p6_interface == state->interface)
 			break;
 

-- 
2.40.1

