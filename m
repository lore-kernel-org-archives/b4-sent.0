From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Mon, 22 Jan 2024 08:35:57 +0300
Subject: [PATCH net-next v3 6/7] net: dsa: mt7530: do not set
 priv->p5_interface on mt7530_setup_port5()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240122-for-netnext-mt7530-improvements-1-v3-6-042401f2b279@arinc9.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705901755; l=1273;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=pshHxjZuMebpMx/Gh2fbwscWV4LBFxm7gD/pRSkDjUU=;
 b=3QO+m8i9+Ps4LZGshnpqcBCo9aNWs7CYTLbXp9XfvHkLogRSHjRTuKQahhjiOlLAM+EezZlll
 M7WXEkoq3q3AJBtDqaVD4ZqTNnAsgH2y6/N04iZ6+sNliD5XWQrHn3Z
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Running mt7530_setup_port5() from mt7530_setup() used to handle all cases
of configuring port 5, including phylink.

Setting priv->p5_interface under mt7530_setup_port5() makes sure that
mt7530_setup_port5() from mt753x_phylink_mac_config() won't run.

The commit ("net: dsa: mt7530: improve code path for setting up port 5")
makes so that mt7530_setup_port5() from mt7530_setup() runs only on
non-phylink cases.

Get rid of unnecessarily setting priv->p5_interface under
mt7530_setup_port5() as port 5 phylink configuration will be done by
running mt7530_setup_port5() from mt753x_phylink_mac_config() now.

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
 drivers/net/dsa/mt7530.c | 2 --
 1 file changed, 2 deletions(-)

diff --git a/drivers/net/dsa/mt7530.c b/drivers/net/dsa/mt7530.c
index 33c15f10de34..5394d8c6a40e 100644
--- a/drivers/net/dsa/mt7530.c
+++ b/drivers/net/dsa/mt7530.c
@@ -978,8 +978,6 @@ static void mt7530_setup_port5(struct dsa_switch *ds, phy_interface_t interface)
 	dev_dbg(ds->dev, "Setup P5, HWTRAP=0x%x, intf_sel=%s, phy-mode=%s\n",
 		val, p5_intf_modes(priv->p5_intf_sel), phy_modes(interface));
 
-	priv->p5_interface = interface;
-
 unlock_exit:
 	mutex_unlock(&priv->reg_mutex);
 }

-- 
2.40.1

