From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Fri, 19 Apr 2024 13:09:31 +0300
Subject: [PATCH net-next 08/13] net: dsa: mt7530: return mt7530_setup_mdio
 & mt7531_setup_common on error
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240419-for-netnext-mt7530-improvements-4-v1-8-6d852ca79b1d@arinc9.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713521374; l=1000;
 i=arinc.unal@arinc9.com; s=arinc9-Xeront; h=from:subject:message-id;
 bh=dhGaiF9+p4oldvBExDhNwz/DfR5nSajm98YgCgzXa+8=;
 b=2BxAch20eM2c8wvH4hsKCRmrCfJCbUYkFInLzGJsmliu0YwKZHxbIUtyCnjWf3L2zY6HGcE7O
 lOdPe2ZZRPVDm1XFB0M03gpIYRxE1oIfpmsEqmNnYWIpJzGSVIVGTGJ
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=z49tLn29CyiL4uwBTrqH9HO1Wu3sZIuRp4DaLZvtP9M=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-Xeront with auth_id=137
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The mt7530_setup_mdio() and mt7531_setup_common() functions should be
checked for errors. Return if the functions return a non-zero value.

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
 drivers/net/dsa/mt7530.c | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/drivers/net/dsa/mt7530.c b/drivers/net/dsa/mt7530.c
index 83436723cb16..4e9aa78ca3d0 100644
--- a/drivers/net/dsa/mt7530.c
+++ b/drivers/net/dsa/mt7530.c
@@ -2667,7 +2667,9 @@ mt7531_setup(struct dsa_switch *ds)
 					 0);
 	}
 
-	mt7531_setup_common(ds);
+	ret = mt7531_setup_common(ds);
+	if (ret)
+		return ret;
 
 	/* Setup VLAN ID 0 for VLAN-unaware bridges */
 	ret = mt7530_setup_vlan0(priv);
@@ -3020,6 +3022,8 @@ mt753x_setup(struct dsa_switch *ds)
 	ret = mt7530_setup_mdio(priv);
 	if (ret && priv->irq)
 		mt7530_free_irq_common(priv);
+	if (ret)
+		return ret;
 
 	/* Initialise the PCS devices */
 	for (i = 0; i < priv->ds->num_ports; i++) {

-- 
2.40.1

