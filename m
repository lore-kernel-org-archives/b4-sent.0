From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Thu, 08 Feb 2024 08:51:34 +0300
Subject: [PATCH netnext 6/8] net: dsa: mt7530: get rid of
 mt753x_mac_config()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240208-for-netnext-mt7530-improvements-3-v1-6-d7c1cfd502ca@arinc9.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707371489; l=1494;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=8u7euwYTcc58UJEZ934iSyhrRKaOIduS6lOdsKOd2oQ=;
 b=4kXZwrGfjQOP/O9zg/NSniCnR4s8JpB6Wq32o9H3OeS/SQbaUVeLD1kCRlsgJBEeBsabQ6bAE
 4nvyQ4j5XXyBTtoQDmIykCTp5YlEDVAD1MYjb83pgx6d2n6a0RFzb1G
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There is no need for a separate function to call
priv->info->mac_port_config(). Call it from mt753x_phylink_mac_config()
instead and remove mt753x_mac_config().

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
 drivers/net/dsa/mt7530.c | 14 ++------------
 1 file changed, 2 insertions(+), 12 deletions(-)

diff --git a/drivers/net/dsa/mt7530.c b/drivers/net/dsa/mt7530.c
index 80b65f064310..e353c03dd1db 100644
--- a/drivers/net/dsa/mt7530.c
+++ b/drivers/net/dsa/mt7530.c
@@ -2634,16 +2634,6 @@ mt7531_mac_config(struct dsa_switch *ds, int port, unsigned int mode,
 	}
 }
 
-static void
-mt753x_mac_config(struct dsa_switch *ds, int port, unsigned int mode,
-		  const struct phylink_link_state *state)
-{
-	struct mt7530_priv *priv = ds->priv;
-
-	if (priv->info->mac_port_config)
-		priv->info->mac_port_config(ds, port, mode, state->interface);
-}
-
 static struct phylink_pcs *
 mt753x_phylink_mac_select_pcs(struct dsa_switch *ds, int port,
 			      phy_interface_t interface)
@@ -2669,8 +2659,8 @@ mt753x_phylink_mac_config(struct dsa_switch *ds, int port, unsigned int mode,
 	struct mt7530_priv *priv = ds->priv;
 	u32 mcr_cur, mcr_new;
 
-	if (port == 5 || port == 6)
-		mt753x_mac_config(ds, port, mode, state);
+	if ((port == 5 || port == 6) && priv->info->mac_port_config)
+		priv->info->mac_port_config(ds, port, mode, state->interface);
 
 	mcr_cur = mt7530_read(priv, MT7530_PMCR_P(port));
 	mcr_new = mcr_cur;

-- 
2.40.1

