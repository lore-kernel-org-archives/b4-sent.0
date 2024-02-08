From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Thu, 08 Feb 2024 08:51:31 +0300
Subject: [PATCH netnext 3/8] net: dsa: mt7530: do not use SW_PHY_RST to
 reset MT7531 switch
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240208-for-netnext-mt7530-improvements-3-v1-3-d7c1cfd502ca@arinc9.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707371489; l=1298;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=ecurYkRWOTqqGU2AKHni4Fzup3XR61+gzZ3STlqM5Z4=;
 b=b9VDNMoY49Q3hQXGaelaQQGU9njla99nADPmBBsMFgG6+sLkgV6dTFLgcxR3xwicbe8v5YjB/
 QUbfKb63s/bAWQS4VVEgivcMh5LXkwLvTS/ghzQdKgOVOMBAzfkIBiJ
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

According to the document MT7531 Reference Manual for Development Board
v1.0, the SW_PHY_RST bit on the SYS_CTRL register doesn't exist for
MT7531. This is likely why forcing link down on all ports is necessary for
MT7531.

Therefore, do not set SW_PHY_RST on mt7531_setup().

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
 drivers/net/dsa/mt7530.c | 6 ++----
 1 file changed, 2 insertions(+), 4 deletions(-)

diff --git a/drivers/net/dsa/mt7530.c b/drivers/net/dsa/mt7530.c
index 5cfd303b773f..296711fd5c43 100644
--- a/drivers/net/dsa/mt7530.c
+++ b/drivers/net/dsa/mt7530.c
@@ -2451,14 +2451,12 @@ mt7531_setup(struct dsa_switch *ds)
 	val = mt7530_read(priv, MT7531_TOP_SIG_SR);
 	priv->p5_sgmii = !!(val & PAD_DUAL_SGMII_EN);
 
-	/* all MACs must be forced link-down before sw reset */
+	/* Force link down on all ports before internal reset */
 	for (i = 0; i < MT7530_NUM_PORTS; i++)
 		mt7530_write(priv, MT7530_PMCR_P(i), MT7531_FORCE_LNK);
 
 	/* Reset the switch through internal reset */
-	mt7530_write(priv, MT7530_SYS_CTRL,
-		     SYS_CTRL_PHY_RST | SYS_CTRL_SW_RST |
-		     SYS_CTRL_REG_RST);
+	mt7530_write(priv, MT7530_SYS_CTRL, SYS_CTRL_SW_RST | SYS_CTRL_REG_RST);
 
 	if (!priv->p5_sgmii) {
 		mt7531_pll_setup(priv);

-- 
2.40.1

