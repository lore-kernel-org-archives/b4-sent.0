From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Thu, 08 Feb 2024 08:51:35 +0300
Subject: [PATCH netnext 7/8] net: dsa: mt7530: put initialising PCS devices
 code back to original order
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240208-for-netnext-mt7530-improvements-3-v1-7-d7c1cfd502ca@arinc9.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707371489; l=1570;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=/2CkKGukm0R4V69WhBvbbIMKcr0CwYye/LAy2VcbSV0=;
 b=cgYWWkSZCAhdXnX66ltsxkY85bNLVeKuY+rvkDi7qWt0AaUJl007QE1+K/VOCDyRWB+gn74zR
 AWtK+mJWyxICShfCxhlkB4+HkAyHCmc7TQzDaC61rogpfRYrm6NcEoh
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The commit fae463084032 ("net: dsa: mt753x: fix pcs conversion regression")
fixes regression caused by cpu_port_config manually calling phylink
operations. cpu_port_config was deemed useless and was removed. Therefore,
put initialising PCS devices code back to its original order.

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
 drivers/net/dsa/mt7530.c | 20 ++++++++++----------
 1 file changed, 10 insertions(+), 10 deletions(-)

diff --git a/drivers/net/dsa/mt7530.c b/drivers/net/dsa/mt7530.c
index e353c03dd1db..5c8ad41ce8cd 100644
--- a/drivers/net/dsa/mt7530.c
+++ b/drivers/net/dsa/mt7530.c
@@ -2812,17 +2812,9 @@ static int
 mt753x_setup(struct dsa_switch *ds)
 {
 	struct mt7530_priv *priv = ds->priv;
-	int i, ret;
-
-	/* Initialise the PCS devices */
-	for (i = 0; i < priv->ds->num_ports; i++) {
-		priv->pcs[i].pcs.ops = priv->info->pcs_ops;
-		priv->pcs[i].pcs.neg_mode = true;
-		priv->pcs[i].priv = priv;
-		priv->pcs[i].port = i;
-	}
+	int ret = priv->info->sw_setup(ds);
+	int i;
 
-	ret = priv->info->sw_setup(ds);
 	if (ret)
 		return ret;
 
@@ -2834,6 +2826,14 @@ mt753x_setup(struct dsa_switch *ds)
 	if (ret && priv->irq)
 		mt7530_free_irq_common(priv);
 
+	/* Initialise the PCS devices */
+	for (i = 0; i < priv->ds->num_ports; i++) {
+		priv->pcs[i].pcs.ops = priv->info->pcs_ops;
+		priv->pcs[i].pcs.neg_mode = true;
+		priv->pcs[i].priv = priv;
+		priv->pcs[i].port = i;
+	}
+
 	if (priv->create_sgmii) {
 		ret = priv->create_sgmii(priv);
 		if (ret && priv->irq)

-- 
2.40.1

