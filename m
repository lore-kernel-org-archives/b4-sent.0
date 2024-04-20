From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Sat, 20 Apr 2024 19:46:06 +0300
Subject: [PATCH 4/4] net: dsa: mt7530: fix enabling EEE on MT7531 switch on
 all boards
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240420-for-stable-5-15-backports-v1-4-007bfa19d044@arinc9.com>
References: <20240420-for-stable-5-15-backports-v1-0-007bfa19d044@arinc9.com>
In-Reply-To: <20240420-for-stable-5-15-backports-v1-0-007bfa19d044@arinc9.com>
To: stable@vger.kernel.org
Cc: Daniel Golle <daniel@makrotopia.org>, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>, 
 Florian Fainelli <florian.fainelli@broadcom.com>, 
 Jakub Kicinski <kuba@kernel.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713631565; l=4744;
 i=arinc.unal@arinc9.com; s=arinc9-Xeront; h=from:subject:message-id;
 bh=wI+VNPUDKMADiqTcJvasF28AuwQZJ6Eh4q11OnAtrCI=;
 b=mc1cJvPV45O1nrZM2w9joefDvw6oBTsEhTeYs9mlaliBk71lneBUQssAPOuc3cDlurt/2DOHq
 zBTAKwJ9VS6ALJiYgrSozDMDME5l9jFpC2rLSw4YSfKKmSHbUzK5GvF
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=z49tLn29CyiL4uwBTrqH9HO1Wu3sZIuRp4DaLZvtP9M=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-Xeront with auth_id=137
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

[ Upstream commit 06dfcd4098cfdc4d4577d94793a4f9125386da8b ]

The commit 40b5d2f15c09 ("net: dsa: mt7530: Add support for EEE features")
brought EEE support but did not enable EEE on MT7531 switch MACs. EEE is
enabled on MT7531 switch MACs by pulling the LAN2LED0 pin low on the board
(bootstrapping), unsetting the EEE_DIS bit on the trap register, or setting
the internal EEE switch bit on the CORE_PLL_GROUP4 register. Thanks to
SkyLake Huang (黃啟澤) from MediaTek for providing information on the
internal EEE switch bit.

There are existing boards that were not designed to pull the pin low.
Because of that, the EEE status currently depends on the board design.

The EEE_DIS bit on the trap pertains to the LAN2LED0 pin which is usually
used to control an LED. Once the bit is unset, the pin will be low. That
will make the active low LED turn on. The pin is controlled by the switch
PHY. It seems that the PHY controls the pin in the way that it inverts the
pin state. That means depending on the wiring of the LED connected to
LAN2LED0 on the board, the LED may be on without an active link.

To not cause this unwanted behaviour whilst enabling EEE on all boards, set
the internal EEE switch bit on the CORE_PLL_GROUP4 register.

My testing on MT7531 shows a certain amount of traffic loss when EEE is
enabled. That said, I haven't come across a board that enables EEE. So
enable EEE on the switch MACs but disable EEE advertisement on the switch
PHYs. This way, we don't change the behaviour of the majority of the boards
that have this switch. The mediatek-ge PHY driver already disables EEE
advertisement on the switch PHYs but my testing shows that it is somehow
enabled afterwards. Disabling EEE advertisement before the PHY driver
initialises keeps it off.

With this change, EEE can now be enabled using ethtool.

Fixes: 40b5d2f15c09 ("net: dsa: mt7530: Add support for EEE features")
Reviewed-by: Florian Fainelli <florian.fainelli@broadcom.com>
Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
Tested-by: Daniel Golle <daniel@makrotopia.org>
Reviewed-by: Daniel Golle <daniel@makrotopia.org>
Link: https://lore.kernel.org/r/20240408-for-net-mt7530-fix-eee-for-mt7531-mt7988-v3-1-84fdef1f008b@arinc9.com
Signed-off-by: Jakub Kicinski <kuba@kernel.org>
Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
 drivers/net/dsa/mt7530.c | 19 +++++++++++++------
 drivers/net/dsa/mt7530.h |  1 +
 2 files changed, 14 insertions(+), 6 deletions(-)

diff --git a/drivers/net/dsa/mt7530.c b/drivers/net/dsa/mt7530.c
index ebf0a85f6657..bc4d8b0bc5e7 100644
--- a/drivers/net/dsa/mt7530.c
+++ b/drivers/net/dsa/mt7530.c
@@ -2581,7 +2581,7 @@ mt7531_setup(struct dsa_switch *ds)
 	struct mt7530_priv *priv = ds->priv;
 	struct mt7530_dummy_poll p;
 	u32 val, id;
-	int ret;
+	int ret, i;
 
 	/* Reset whole chip through gpio pin or memory-mapped registers for
 	 * different type of hardware
@@ -2641,18 +2641,25 @@ mt7531_setup(struct dsa_switch *ds)
 	priv->p5_interface = PHY_INTERFACE_MODE_NA;
 	priv->p6_interface = PHY_INTERFACE_MODE_NA;
 
-	/* Enable PHY core PLL, since phy_device has not yet been created
-	 * provided for phy_[read,write]_mmd_indirect is called, we provide
-	 * our own mt7531_ind_mmd_phy_[read,write] to complete this
-	 * function.
+	/* Enable Energy-Efficient Ethernet (EEE) and PHY core PLL, since
+	 * phy_device has not yet been created provided for
+	 * phy_[read,write]_mmd_indirect is called, we provide our own
+	 * mt7531_ind_mmd_phy_[read,write] to complete this function.
 	 */
 	val = mt7531_ind_c45_phy_read(priv, MT753X_CTRL_PHY_ADDR,
 				      MDIO_MMD_VEND2, CORE_PLL_GROUP4);
-	val |= MT7531_PHY_PLL_BYPASS_MODE;
+	val |= MT7531_RG_SYSPLL_DMY2 | MT7531_PHY_PLL_BYPASS_MODE;
 	val &= ~MT7531_PHY_PLL_OFF;
 	mt7531_ind_c45_phy_write(priv, MT753X_CTRL_PHY_ADDR, MDIO_MMD_VEND2,
 				 CORE_PLL_GROUP4, val);
 
+	/* Disable EEE advertisement on the switch PHYs. */
+	for (i = MT753X_CTRL_PHY_ADDR;
+	     i < MT753X_CTRL_PHY_ADDR + MT7530_NUM_PHYS; i++) {
+		mt7531_ind_c45_phy_write(priv, i, MDIO_MMD_AN, MDIO_AN_EEE_ADV,
+					 0);
+	}
+
 	mt7531_setup_common(ds);
 
 	/* Setup VLAN ID 0 for VLAN-unaware bridges */
diff --git a/drivers/net/dsa/mt7530.h b/drivers/net/dsa/mt7530.h
index 22152d74b327..de4badbf27ef 100644
--- a/drivers/net/dsa/mt7530.h
+++ b/drivers/net/dsa/mt7530.h
@@ -669,6 +669,7 @@ enum mt7531_clk_skew {
 #define  RG_SYSPLL_DDSFBK_EN		BIT(12)
 #define  RG_SYSPLL_BIAS_EN		BIT(11)
 #define  RG_SYSPLL_BIAS_LPF_EN		BIT(10)
+#define  MT7531_RG_SYSPLL_DMY2		BIT(6)
 #define  MT7531_PHY_PLL_OFF		BIT(5)
 #define  MT7531_PHY_PLL_BYPASS_MODE	BIT(4)
 

-- 
2.40.1

