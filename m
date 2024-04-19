From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Fri, 19 Apr 2024 13:09:32 +0300
Subject: [PATCH net-next 09/13] net: dsa: mt7530: define MAC speed
 capabilities per switch model
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240419-for-netnext-mt7530-improvements-4-v1-9-6d852ca79b1d@arinc9.com>
References: <20240419-for-netnext-mt7530-improvements-4-v1-0-6d852ca79b1d@arinc9.com>
In-Reply-To: <20240419-for-netnext-mt7530-improvements-4-v1-0-6d852ca79b1d@arinc9.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713521374; l=2468;
 i=arinc.unal@arinc9.com; s=arinc9-Xeront; h=from:subject:message-id;
 bh=U7m+wRsPDOynbhqa9RKx+0GeC9h4YeQt1AWk+qLy0W4=;
 b=0crF93zDGKVTpjGQEtq8n4SQMOTbZYWpe6bvUZvJS7QU9rdMeKGTO+QmpVP7+g6kxdvfi9UMQ
 IdQM4xMj7CMDeXciei7AC2vbAv1xB6047R1MFchs+fdLBBzPBx8y/R5
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=z49tLn29CyiL4uwBTrqH9HO1Wu3sZIuRp4DaLZvtP9M=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-Xeront with auth_id=137
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With the support of the MT7988 SoC switch, the MAC speed capabilities
defined on mt753x_phylink_get_caps() won't apply to all switch models
anymore. Move them to more appropriate locations instead of overwriting
config->mac_capabilities.

Remove the comment on mt753x_phylink_get_caps() as it's become invalid with
the support of MT7531 and MT7988 SoC switch.

Add break to case 6 of mt7988_mac_port_get_caps() to be explicit.

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
 drivers/net/dsa/mt7530.c | 15 ++++++++++-----
 1 file changed, 10 insertions(+), 5 deletions(-)

diff --git a/drivers/net/dsa/mt7530.c b/drivers/net/dsa/mt7530.c
index 4e9aa78ca3d0..8a141f849673 100644
--- a/drivers/net/dsa/mt7530.c
+++ b/drivers/net/dsa/mt7530.c
@@ -2685,6 +2685,8 @@ mt7531_setup(struct dsa_switch *ds)
 static void mt7530_mac_port_get_caps(struct dsa_switch *ds, int port,
 				     struct phylink_config *config)
 {
+	config->mac_capabilities |= MAC_10 | MAC_100 | MAC_1000FD;
+
 	switch (port) {
 	/* Ports which are connected to switch PHYs. There is no MII pinout. */
 	case 0 ... 4:
@@ -2716,6 +2718,8 @@ static void mt7531_mac_port_get_caps(struct dsa_switch *ds, int port,
 {
 	struct mt7530_priv *priv = ds->priv;
 
+	config->mac_capabilities |= MAC_10 | MAC_100 | MAC_1000FD;
+
 	switch (port) {
 	/* Ports which are connected to switch PHYs. There is no MII pinout. */
 	case 0 ... 4:
@@ -2755,14 +2759,17 @@ static void mt7988_mac_port_get_caps(struct dsa_switch *ds, int port,
 	case 0 ... 3:
 		__set_bit(PHY_INTERFACE_MODE_INTERNAL,
 			  config->supported_interfaces);
+
+		config->mac_capabilities |= MAC_10 | MAC_100 | MAC_1000FD;
 		break;
 
 	/* Port 6 is connected to SoC's XGMII MAC. There is no MII pinout. */
 	case 6:
 		__set_bit(PHY_INTERFACE_MODE_INTERNAL,
 			  config->supported_interfaces);
-		config->mac_capabilities = MAC_ASYM_PAUSE | MAC_SYM_PAUSE |
-					   MAC_10000FD;
+
+		config->mac_capabilities |= MAC_10000FD;
+		break;
 	}
 }
 
@@ -2932,9 +2939,7 @@ static void mt753x_phylink_get_caps(struct dsa_switch *ds, int port,
 {
 	struct mt7530_priv *priv = ds->priv;
 
-	/* This switch only supports full-duplex at 1Gbps */
-	config->mac_capabilities = MAC_ASYM_PAUSE | MAC_SYM_PAUSE |
-				   MAC_10 | MAC_100 | MAC_1000FD;
+	config->mac_capabilities = MAC_ASYM_PAUSE | MAC_SYM_PAUSE;
 
 	priv->info->mac_port_get_caps(ds, port, config);
 }

-- 
2.40.1

