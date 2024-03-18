From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Mon, 18 Mar 2024 10:46:23 +0300
Subject: [PATCH 1/3] net: dsa: mt7530: fix enabling EEE on MT7531 switch on
 all boards
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240318-for-net-mt7530-fix-eee-for-mt7531-mt7988-v1-1-3f17226344e8@arinc9.com>
References: <20240318-for-net-mt7530-fix-eee-for-mt7531-mt7988-v1-0-3f17226344e8@arinc9.com>
In-Reply-To: <20240318-for-net-mt7530-fix-eee-for-mt7531-mt7988-v1-0-3f17226344e8@arinc9.com>
To: Daniel Golle <daniel@makrotopia.org>, DENG Qingfang <dqfext@gmail.com>, 
 Sean Wang <sean.wang@mediatek.com>, Andrew Lunn <andrew@lunn.ch>, 
 Florian Fainelli <f.fainelli@gmail.com>, 
 Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 =?utf-8?q?Ren=C3=A9_van_Dorst?= <opensource@vdorst.com>, 
 Russell King <linux@armlinux.org.uk>, 
 SkyLake Huang <SkyLake.Huang@mediatek.com>, 
 Heiner Kallweit <hkallweit1@gmail.com>
Cc: Bartel Eerdekens <bartel.eerdekens@constell8.be>, 
 mithat.guner@xeront.com, erkin.bozoglu@xeront.com, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1710748010; l=2411;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=n6GBg3P0wOtkdb07AnyqLGs2kfHYSdBgEmtkDwKT6B8=;
 b=I2LmPwjiQmjqjwCuXvNT3y9Oy+74/n1FBJ1U/eAziVxdZ8NilIckTM/4zYde6k4K5Ari39+4m
 ZWJOVvadHrTCRVVdUIeNpsCFYJciXsPmNKj4nHEmpDy9B+jOl3NrFwy
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The commit 40b5d2f15c09 ("net: dsa: mt7530: Add support for EEE features")
brought EEE support but did not enable EEE on MT7531 switch MACs. EEE is
enabled on MT7531 switch MACs either by pulling the LAN2LED0 pin low on the
board (bootstrapping), or unsetting the EEE_DIS bit on the trap register.

There are existing boards that were not designed to pull the pin low.
Therefore, unset the EEE_DIS bit on the trap register.

Unlike MT7530, the modifiable trap register won't be populated identical to
the trap status register after reset. Therefore, read from the trap status
register, modify the bits, then write to the modifiable trap register.

The disable EEE bit on the trap pertains to the LAN2LED0 pin which is
usually used to control an LED. Once the bit is unset, the pin will be low.
That will make the active low LED turn on.

The pin is controlled by the switch PHY. It seems that the PHY controls the
pin in the way that it inverts the pin state. That means depending on the
wiring of the LED connected to LAN2LED0 on the board, the LED may be on
without an active link.

Fixes: 40b5d2f15c09 ("net: dsa: mt7530: Add support for EEE features")
Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
 drivers/net/dsa/mt7530.c | 7 +++++++
 drivers/net/dsa/mt7530.h | 1 +
 2 files changed, 8 insertions(+)

diff --git a/drivers/net/dsa/mt7530.c b/drivers/net/dsa/mt7530.c
index 678b51f9cea6..d741d03969eb 100644
--- a/drivers/net/dsa/mt7530.c
+++ b/drivers/net/dsa/mt7530.c
@@ -2458,6 +2458,13 @@ mt7531_setup(struct dsa_switch *ds)
 	/* Reset the switch through internal reset */
 	mt7530_write(priv, MT7530_SYS_CTRL, SYS_CTRL_SW_RST | SYS_CTRL_REG_RST);
 
+	/* Allow modifying the trap and enable Energy-Efficient Ethernet (EEE).
+	 */
+	val = mt7530_read(priv, MT7531_HWTRAP);
+	val |= CHG_STRAP;
+	val &= ~EEE_DIS;
+	mt7530_write(priv, MT7530_MHWTRAP, val);
+
 	if (!priv->p5_sgmii) {
 		mt7531_pll_setup(priv);
 	} else {
diff --git a/drivers/net/dsa/mt7530.h b/drivers/net/dsa/mt7530.h
index a71166e0a7fc..509ed5362236 100644
--- a/drivers/net/dsa/mt7530.h
+++ b/drivers/net/dsa/mt7530.h
@@ -457,6 +457,7 @@ enum mt7531_clk_skew {
 #define  XTAL_FSEL_M			BIT(7)
 #define  PHY_EN				BIT(6)
 #define  CHG_STRAP			BIT(8)
+#define  EEE_DIS			BIT(4)
 
 /* Register for hw trap modification */
 #define MT7530_MHWTRAP			0x7804

-- 
2.40.1

