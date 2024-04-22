From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Mon, 22 Apr 2024 10:15:21 +0300
Subject: [PATCH net-next v2 14/15] net: dsa: mt7530: do not pass port
 variable to mt7531_rgmii_setup()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240422-for-netnext-mt7530-improvements-4-v2-14-a75157ba76ad@arinc9.com>
References: <20240422-for-netnext-mt7530-improvements-4-v2-0-a75157ba76ad@arinc9.com>
In-Reply-To: <20240422-for-netnext-mt7530-improvements-4-v2-0-a75157ba76ad@arinc9.com>
To: Daniel Golle <daniel@makrotopia.org>, DENG Qingfang <dqfext@gmail.com>, 
 Sean Wang <sean.wang@mediatek.com>, Andrew Lunn <andrew@lunn.ch>, 
 Florian Fainelli <f.fainelli@gmail.com>, 
 Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Russell King <linux@armlinux.org.uk>
Cc: Bartel Eerdekens <bartel.eerdekens@constell8.be>, 
 mithat.guner@xeront.com, erkin.bozoglu@xeront.com, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713770127; l=1111;
 i=arinc.unal@arinc9.com; s=arinc9-Xeront; h=from:subject:message-id;
 bh=Q1j4jaCBiZXdXWGCY6tFpliJwSXL75dq4VnMljuW2Zw=;
 b=4edWHZvzNJRTxMTUE0wiBeIEW7Iu4gYhfzaEG4rSVBrQN4GpNEFRAkN0qFdg0HmYp8vS7lSnt
 a/JDc1cAa1ODoctBTyvB6iFiv1Ld2Sv5i5/ytpRPb3P/IaNP9ia9DRL
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=z49tLn29CyiL4uwBTrqH9HO1Wu3sZIuRp4DaLZvtP9M=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-Xeront with auth_id=137
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The mt7531_rgmii_setup() function does not use the port variable, do not
pass the variable to it.

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
 drivers/net/dsa/mt7530.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/net/dsa/mt7530.c b/drivers/net/dsa/mt7530.c
index 55954a165a15..1f6cd24de4b7 100644
--- a/drivers/net/dsa/mt7530.c
+++ b/drivers/net/dsa/mt7530.c
@@ -2785,7 +2785,7 @@ mt7530_mac_config(struct dsa_switch *ds, int port, unsigned int mode,
 		mt7530_setup_port6(priv->ds, interface);
 }
 
-static void mt7531_rgmii_setup(struct mt7530_priv *priv, u32 port,
+static void mt7531_rgmii_setup(struct mt7530_priv *priv,
 			       phy_interface_t interface,
 			       struct phy_device *phydev)
 {
@@ -2836,7 +2836,7 @@ mt7531_mac_config(struct dsa_switch *ds, int port, unsigned int mode,
 	if (phy_interface_mode_is_rgmii(interface)) {
 		dp = dsa_to_port(ds, port);
 		phydev = dp->user->phydev;
-		mt7531_rgmii_setup(priv, port, interface, phydev);
+		mt7531_rgmii_setup(priv, interface, phydev);
 	}
 }
 

-- 
2.40.1

