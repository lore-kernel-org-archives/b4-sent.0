From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Mon, 22 Jan 2024 08:35:58 +0300
Subject: [PATCH net-next v3 7/7] net: dsa: mt7530: do not run
 mt7530_setup_port5() if port 5 is disabled
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240122-for-netnext-mt7530-improvements-1-v3-7-042401f2b279@arinc9.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705901755; l=1954;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=CX1ZTLft5JNnPSpvgA9ppPM0W5zZnVzbF5jhuxeYZts=;
 b=m7xRK80HiKn4Yf5gYVKbcOAJuPiW2ZQjrweTiy/ng47qxoKCiENascUa+CONss3MADnR3scXe
 bi2arpEKxnkDpyM3moD6BJkZxd+h2xHCHl22YVS7vuxFGjITKlV6wVM
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There's no need to run all the code on mt7530_setup_port5() if port 5 is
disabled. The only case for calling mt7530_setup_port5() from
mt7530_setup() is when PHY muxing is enabled. That is because port 5 is not
defined as a port on the devicetree, therefore, it cannot be controlled by
phylink.

Because of this, run mt7530_setup_port5() if priv->p5_intf_sel is
P5_INTF_SEL_PHY_P0 or P5_INTF_SEL_PHY_P4. Remove the P5_DISABLED case from
mt7530_setup_port5().

Stop initialising the interface variable as the remaining cases will always
call mt7530_setup_port5() with it initialised.

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
Reviewed-by: Vladimir Oltean <olteanv@gmail.com>
---
 drivers/net/dsa/mt7530.c | 9 +++------
 1 file changed, 3 insertions(+), 6 deletions(-)

diff --git a/drivers/net/dsa/mt7530.c b/drivers/net/dsa/mt7530.c
index 5394d8c6a40e..cd7673ecea51 100644
--- a/drivers/net/dsa/mt7530.c
+++ b/drivers/net/dsa/mt7530.c
@@ -942,9 +942,6 @@ static void mt7530_setup_port5(struct dsa_switch *ds, phy_interface_t interface)
 		/* MT7530_P5_MODE_GMAC: P5 -> External phy or 2nd GMAC */
 		val &= ~MHWTRAP_P5_DIS;
 		break;
-	case P5_DISABLED:
-		interface = PHY_INTERFACE_MODE_NA;
-		break;
 	default:
 		dev_err(ds->dev, "Unsupported p5_intf_sel %d\n",
 			priv->p5_intf_sel);
@@ -2313,8 +2310,6 @@ mt7530_setup(struct dsa_switch *ds)
 		 * Set priv->p5_intf_sel to the appropriate value if PHY muxing
 		 * is detected.
 		 */
-		interface = PHY_INTERFACE_MODE_NA;
-
 		for_each_child_of_node(dn, mac_np) {
 			if (!of_device_is_compatible(mac_np,
 						     "mediatek,eth-mac"))
@@ -2346,7 +2341,9 @@ mt7530_setup(struct dsa_switch *ds)
 			break;
 		}
 
-		mt7530_setup_port5(ds, interface);
+		if (priv->p5_intf_sel == P5_INTF_SEL_PHY_P0 ||
+		    priv->p5_intf_sel == P5_INTF_SEL_PHY_P4)
+			mt7530_setup_port5(ds, interface);
 	}
 
 #ifdef CONFIG_GPIOLIB

-- 
2.40.1

