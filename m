From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Thu, 08 Feb 2024 08:51:32 +0300
Subject: [PATCH netnext 4/8] net: dsa: mt7530: get rid of useless error
 returns on phylink code path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240208-for-netnext-mt7530-improvements-3-v1-4-d7c1cfd502ca@arinc9.com>
References: <20240208-for-netnext-mt7530-improvements-3-v1-0-d7c1cfd502ca@arinc9.com>
In-Reply-To: <20240208-for-netnext-mt7530-improvements-3-v1-0-d7c1cfd502ca@arinc9.com>
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
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707371489; l=6745;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=EL1vGonmNpBImZU3uthb96aDLRU2riphSBzoDbxXdI8=;
 b=+ZfTF2PzXOAXJWhWYzvsWUbt3wlj8uFvX0J+2ylIt9WHjutCGTQCJj+dufi/SMtYZ8uWHmuSv
 gpM4l26s9iXBD7yzQC6105Z1XYp1dzZHcHSWaXqh0fWyy0EpWa8PSZN
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove error returns on the cases where they are already handled with the
function the mac_port_get_caps member in mt753x_table points to.

mt7531_mac_config() is also called from mt7531_cpu_port_config() outside of
phylink but the port and interface modes are already handled there.

Change the functions and the mac_port_config function pointer to void now
that there're no error returns anymore.

Remove mt753x_is_mac_port() that used to help the said error returns.

On mt7531_mac_config(), switch to if statements to simplify the code.

Remove internal phy cases from mt753x_phylink_mac_config(), there is no
need to check the interface mode as that's already handled with the
function the mac_port_get_caps member in mt753x_table points to.

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
Acked-by: Daniel Golle <daniel@makrotopia.org>
Tested-by: Daniel Golle <daniel@makrotopia.org>
Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
 drivers/net/dsa/mt7530.c | 81 ++++++++++--------------------------------------
 drivers/net/dsa/mt7530.h |  6 ++--
 2 files changed, 19 insertions(+), 68 deletions(-)

diff --git a/drivers/net/dsa/mt7530.c b/drivers/net/dsa/mt7530.c
index 296711fd5c43..c069bf273733 100644
--- a/drivers/net/dsa/mt7530.c
+++ b/drivers/net/dsa/mt7530.c
@@ -2587,7 +2587,7 @@ static void mt7988_mac_port_get_caps(struct dsa_switch *ds, int port,
 	}
 }
 
-static int
+static void
 mt7530_mac_config(struct dsa_switch *ds, int port, unsigned int mode,
 		  phy_interface_t interface)
 {
@@ -2597,22 +2597,14 @@ mt7530_mac_config(struct dsa_switch *ds, int port, unsigned int mode,
 		mt7530_setup_port5(priv->ds, interface);
 	else if (port == 6)
 		mt7530_setup_port6(priv->ds, interface);
-
-	return 0;
 }
 
-static int mt7531_rgmii_setup(struct mt7530_priv *priv, u32 port,
-			      phy_interface_t interface,
-			      struct phy_device *phydev)
+static void mt7531_rgmii_setup(struct mt7530_priv *priv, u32 port,
+			       phy_interface_t interface,
+			       struct phy_device *phydev)
 {
 	u32 val;
 
-	if (priv->p5_sgmii) {
-		dev_err(priv->dev, "RGMII mode is not available for port %d\n",
-			port);
-		return -EINVAL;
-	}
-
 	val = mt7530_read(priv, MT7531_CLKGEN_CTRL);
 	val |= GP_CLK_EN;
 	val &= ~GP_MODE_MASK;
@@ -2640,20 +2632,14 @@ static int mt7531_rgmii_setup(struct mt7530_priv *priv, u32 port,
 		case PHY_INTERFACE_MODE_RGMII_ID:
 			break;
 		default:
-			return -EINVAL;
+			break;
 		}
 	}
-	mt7530_write(priv, MT7531_CLKGEN_CTRL, val);
-
-	return 0;
-}
 
-static bool mt753x_is_mac_port(u32 port)
-{
-	return (port == 5 || port == 6);
+	mt7530_write(priv, MT7531_CLKGEN_CTRL, val);
 }
 
-static int
+static void
 mt7531_mac_config(struct dsa_switch *ds, int port, unsigned int mode,
 		  phy_interface_t interface)
 {
@@ -2661,42 +2647,21 @@ mt7531_mac_config(struct dsa_switch *ds, int port, unsigned int mode,
 	struct phy_device *phydev;
 	struct dsa_port *dp;
 
-	if (!mt753x_is_mac_port(port)) {
-		dev_err(priv->dev, "port %d is not a MAC port\n", port);
-		return -EINVAL;
-	}
-
-	switch (interface) {
-	case PHY_INTERFACE_MODE_RGMII:
-	case PHY_INTERFACE_MODE_RGMII_ID:
-	case PHY_INTERFACE_MODE_RGMII_RXID:
-	case PHY_INTERFACE_MODE_RGMII_TXID:
+	if (phy_interface_mode_is_rgmii(interface)) {
 		dp = dsa_to_port(ds, port);
 		phydev = dp->user->phydev;
-		return mt7531_rgmii_setup(priv, port, interface, phydev);
-	case PHY_INTERFACE_MODE_SGMII:
-	case PHY_INTERFACE_MODE_NA:
-	case PHY_INTERFACE_MODE_1000BASEX:
-	case PHY_INTERFACE_MODE_2500BASEX:
-		/* handled in SGMII PCS driver */
-		return 0;
-	default:
-		return -EINVAL;
+		mt7531_rgmii_setup(priv, port, interface, phydev);
 	}
-
-	return -EINVAL;
 }
 
-static int
+static void
 mt753x_mac_config(struct dsa_switch *ds, int port, unsigned int mode,
 		  const struct phylink_link_state *state)
 {
 	struct mt7530_priv *priv = ds->priv;
 
-	if (!priv->info->mac_port_config)
-		return 0;
-
-	return priv->info->mac_port_config(ds, port, mode, state->interface);
+	if (priv->info->mac_port_config)
+		priv->info->mac_port_config(ds, port, mode, state->interface);
 }
 
 static struct phylink_pcs *
@@ -2725,17 +2690,11 @@ mt753x_phylink_mac_config(struct dsa_switch *ds, int port, unsigned int mode,
 	u32 mcr_cur, mcr_new;
 
 	switch (port) {
-	case 0 ... 4:
-		if (state->interface != PHY_INTERFACE_MODE_GMII &&
-		    state->interface != PHY_INTERFACE_MODE_INTERNAL)
-			goto unsupported;
-		break;
 	case 5:
 		if (priv->p5_interface == state->interface)
 			break;
 
-		if (mt753x_mac_config(ds, port, mode, state) < 0)
-			goto unsupported;
+		mt753x_mac_config(ds, port, mode, state);
 
 		if (priv->p5_intf_sel != P5_DISABLED)
 			priv->p5_interface = state->interface;
@@ -2744,16 +2703,10 @@ mt753x_phylink_mac_config(struct dsa_switch *ds, int port, unsigned int mode,
 		if (priv->p6_interface == state->interface)
 			break;
 
-		if (mt753x_mac_config(ds, port, mode, state) < 0)
-			goto unsupported;
+		mt753x_mac_config(ds, port, mode, state);
 
 		priv->p6_interface = state->interface;
 		break;
-	default:
-unsupported:
-		dev_err(ds->dev, "%s: unsupported %s port: %i\n",
-			__func__, phy_modes(state->interface), port);
-		return;
 	}
 
 	mcr_cur = mt7530_read(priv, MT7530_PMCR_P(port));
@@ -2836,7 +2789,6 @@ mt7531_cpu_port_config(struct dsa_switch *ds, int port)
 	struct mt7530_priv *priv = ds->priv;
 	phy_interface_t interface;
 	int speed;
-	int ret;
 
 	switch (port) {
 	case 5:
@@ -2861,9 +2813,8 @@ mt7531_cpu_port_config(struct dsa_switch *ds, int port)
 	else
 		speed = SPEED_1000;
 
-	ret = mt7531_mac_config(ds, port, MLO_AN_FIXED, interface);
-	if (ret)
-		return ret;
+	mt7531_mac_config(ds, port, MLO_AN_FIXED, interface);
+
 	mt7530_write(priv, MT7530_PMCR_P(port),
 		     PMCR_CPU_PORT_SETTING(priv->id));
 	mt753x_phylink_mac_link_up(ds, port, MLO_AN_FIXED, interface, NULL,
diff --git a/drivers/net/dsa/mt7530.h b/drivers/net/dsa/mt7530.h
index 26a6d2160c08..b1665de7f640 100644
--- a/drivers/net/dsa/mt7530.h
+++ b/drivers/net/dsa/mt7530.h
@@ -730,9 +730,9 @@ struct mt753x_info {
 	void (*mac_port_validate)(struct dsa_switch *ds, int port,
 				  phy_interface_t interface,
 				  unsigned long *supported);
-	int (*mac_port_config)(struct dsa_switch *ds, int port,
-			       unsigned int mode,
-			       phy_interface_t interface);
+	void (*mac_port_config)(struct dsa_switch *ds, int port,
+				unsigned int mode,
+				phy_interface_t interface);
 };
 
 /* struct mt7530_priv -	This is the main data structure for holding the state

-- 
2.40.1

