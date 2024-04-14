From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Sun, 14 Apr 2024 09:07:42 +0300
Subject: [PATCH net-next v2 2/2] net: dsa: mt7530: simplify core operations
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240414-b4-for-netnext-mt7530-phy-addr-from-dt-and-simplify-core-ops-v2-2-1a7649c4d3b6@arinc9.com>
References: <20240414-b4-for-netnext-mt7530-phy-addr-from-dt-and-simplify-core-ops-v2-0-1a7649c4d3b6@arinc9.com>
In-Reply-To: <20240414-b4-for-netnext-mt7530-phy-addr-from-dt-and-simplify-core-ops-v2-0-1a7649c4d3b6@arinc9.com>
To: Daniel Golle <daniel@makrotopia.org>, DENG Qingfang <dqfext@gmail.com>, 
 Sean Wang <sean.wang@mediatek.com>, Andrew Lunn <andrew@lunn.ch>, 
 Florian Fainelli <f.fainelli@gmail.com>, 
 Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: Bartel Eerdekens <bartel.eerdekens@constell8.be>, 
 mithat.guner@xeront.com, erkin.bozoglu@xeront.com, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713074874; l=5238;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=MN/y6Syx7BQudCat3jVuTgtlGZvuyR9wy1cv/kTixQo=;
 b=yZml79ewmSDr1F1tJP+dZjXpKov/rHFKteTyG1sPQL1UgI+5dKQzLKLtv7vD6UAjVTZqK9N48
 cUl6IBBsYw0BT9KgWD4zOAxxSIa/Kqy9p/FsTkq+kJ0iV3BWYUQwdLH
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The core_rmw() function calls core_read_mmd_indirect() to read the
requested register, and then calls core_write_mmd_indirect() to write the
requested value to the register. Because Clause 22 is used to access Clause
45 registers, some operations on core_write_mmd_indirect() are
unnecessarily run. Get rid of core_read_mmd_indirect() and
core_write_mmd_indirect(), and run only the necessary operations on
core_write() and core_rmw().

Reviewed-by: Daniel Golle <daniel@makrotopia.org>
Tested-by: Daniel Golle <daniel@makrotopia.org>
Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
 drivers/net/dsa/mt7530.c | 108 +++++++++++++++++++----------------------------
 1 file changed, 43 insertions(+), 65 deletions(-)

diff --git a/drivers/net/dsa/mt7530.c b/drivers/net/dsa/mt7530.c
index fefa6dd151fa..2650eacf87a7 100644
--- a/drivers/net/dsa/mt7530.c
+++ b/drivers/net/dsa/mt7530.c
@@ -74,116 +74,94 @@ static const struct mt7530_mib_desc mt7530_mib[] = {
 	MIB_DESC(1, 0xb8, "RxArlDrop"),
 };
 
-/* Since phy_device has not yet been created and
- * phy_{read,write}_mmd_indirect is not available, we provide our own
- * core_{read,write}_mmd_indirect with core_{clear,write,set} wrappers
- * to complete this function.
- */
-static int
-core_read_mmd_indirect(struct mt7530_priv *priv, int prtad, int devad)
+static void
+mt7530_mutex_lock(struct mt7530_priv *priv)
+{
+	if (priv->bus)
+		mutex_lock_nested(&priv->bus->mdio_lock, MDIO_MUTEX_NESTED);
+}
+
+static void
+mt7530_mutex_unlock(struct mt7530_priv *priv)
+{
+	if (priv->bus)
+		mutex_unlock(&priv->bus->mdio_lock);
+}
+
+static void
+core_write(struct mt7530_priv *priv, u32 reg, u32 val)
 {
 	struct mii_bus *bus = priv->bus;
-	int value, ret;
+	int ret;
+
+	mt7530_mutex_lock(priv);
 
 	/* Write the desired MMD Devad */
 	ret = bus->write(bus, MT753X_CTRL_PHY_ADDR(priv->phy_addr),
-			 MII_MMD_CTRL, devad);
+			 MII_MMD_CTRL, MDIO_MMD_VEND2);
 	if (ret < 0)
 		goto err;
 
 	/* Write the desired MMD register address */
 	ret = bus->write(bus, MT753X_CTRL_PHY_ADDR(priv->phy_addr),
-			 MII_MMD_DATA, prtad);
+			 MII_MMD_DATA, reg);
 	if (ret < 0)
 		goto err;
 
 	/* Select the Function : DATA with no post increment */
 	ret = bus->write(bus, MT753X_CTRL_PHY_ADDR(priv->phy_addr),
-			 MII_MMD_CTRL, devad | MII_MMD_CTRL_NOINCR);
+			 MII_MMD_CTRL, MDIO_MMD_VEND2 | MII_MMD_CTRL_NOINCR);
 	if (ret < 0)
 		goto err;
 
-	/* Read the content of the MMD's selected register */
-	value = bus->read(bus, MT753X_CTRL_PHY_ADDR(priv->phy_addr),
-			  MII_MMD_DATA);
-
-	return value;
+	/* Write the data into MMD's selected register */
+	ret = bus->write(bus, MT753X_CTRL_PHY_ADDR(priv->phy_addr),
+			 MII_MMD_DATA, val);
 err:
-	dev_err(&bus->dev,  "failed to read mmd register\n");
+	if (ret < 0)
+		dev_err(&bus->dev, "failed to write mmd register\n");
 
-	return ret;
+	mt7530_mutex_unlock(priv);
 }
 
-static int
-core_write_mmd_indirect(struct mt7530_priv *priv, int prtad,
-			int devad, u32 data)
+static void
+core_rmw(struct mt7530_priv *priv, u32 reg, u32 mask, u32 set)
 {
 	struct mii_bus *bus = priv->bus;
+	u32 val;
 	int ret;
 
+	mt7530_mutex_lock(priv);
+
 	/* Write the desired MMD Devad */
 	ret = bus->write(bus, MT753X_CTRL_PHY_ADDR(priv->phy_addr),
-			 MII_MMD_CTRL, devad);
+			 MII_MMD_CTRL, MDIO_MMD_VEND2);
 	if (ret < 0)
 		goto err;
 
 	/* Write the desired MMD register address */
 	ret = bus->write(bus, MT753X_CTRL_PHY_ADDR(priv->phy_addr),
-			 MII_MMD_DATA, prtad);
+			 MII_MMD_DATA, reg);
 	if (ret < 0)
 		goto err;
 
 	/* Select the Function : DATA with no post increment */
 	ret = bus->write(bus, MT753X_CTRL_PHY_ADDR(priv->phy_addr),
-			 MII_MMD_CTRL, devad | MII_MMD_CTRL_NOINCR);
+			 MII_MMD_CTRL, MDIO_MMD_VEND2 | MII_MMD_CTRL_NOINCR);
 	if (ret < 0)
 		goto err;
 
+	/* Read the content of the MMD's selected register */
+	val = bus->read(bus, MT753X_CTRL_PHY_ADDR(priv->phy_addr),
+			MII_MMD_DATA);
+	val &= ~mask;
+	val |= set;
 	/* Write the data into MMD's selected register */
 	ret = bus->write(bus, MT753X_CTRL_PHY_ADDR(priv->phy_addr),
-			 MII_MMD_DATA, data);
+			 MII_MMD_DATA, val);
 err:
 	if (ret < 0)
-		dev_err(&bus->dev,
-			"failed to write mmd register\n");
-	return ret;
-}
-
-static void
-mt7530_mutex_lock(struct mt7530_priv *priv)
-{
-	if (priv->bus)
-		mutex_lock_nested(&priv->bus->mdio_lock, MDIO_MUTEX_NESTED);
-}
-
-static void
-mt7530_mutex_unlock(struct mt7530_priv *priv)
-{
-	if (priv->bus)
-		mutex_unlock(&priv->bus->mdio_lock);
-}
-
-static void
-core_write(struct mt7530_priv *priv, u32 reg, u32 val)
-{
-	mt7530_mutex_lock(priv);
-
-	core_write_mmd_indirect(priv, reg, MDIO_MMD_VEND2, val);
-
-	mt7530_mutex_unlock(priv);
-}
-
-static void
-core_rmw(struct mt7530_priv *priv, u32 reg, u32 mask, u32 set)
-{
-	u32 val;
-
-	mt7530_mutex_lock(priv);
-
-	val = core_read_mmd_indirect(priv, reg, MDIO_MMD_VEND2);
-	val &= ~mask;
-	val |= set;
-	core_write_mmd_indirect(priv, reg, MDIO_MMD_VEND2, val);
+		dev_err(&bus->dev, "failed to write mmd register\n");
 
 	mt7530_mutex_unlock(priv);
 }

-- 
2.40.1

