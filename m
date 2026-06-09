From: Ciprian Regus <ciprian.regus@analog.com>
Date: Tue, 09 Jun 2026 18:28:10 +0300
Subject: [PATCH net-next v4 11/13] net: phy: microchip-t1s: use generic C45
 MMD access helpers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260609-adin1140-driver-v4-11-0753e28ee004@analog.com>
References: <20260609-adin1140-driver-v4-0-0753e28ee004@analog.com>
In-Reply-To: <20260609-adin1140-driver-v4-0-0753e28ee004@analog.com>
To: Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-doc@vger.kernel.org, devicetree@vger.kernel.org, 
 Ciprian Regus <ciprian.regus@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781018886; l=2642;
 i=ciprian.regus@analog.com; s=20260330; h=from:subject:message-id;
 bh=3Aiei7ngCFKSnU+5iJX1Auxf1Rr03CQY3tkR46GUZiw=;
 b=N/wRQCu3xr/pv+zbDDTHCfD/hEJ2i3TpDq4PHprUNAj7D2tsK1Ps2zE2M98GVdgBX1gZdkg2N
 oNUr5mWQRV3CKRtwnFNF3bi0RM/W748snSC/X7yfka4wthjXw6exuSV
X-Developer-Key: i=ciprian.regus@analog.com; a=ed25519;
 pk=8WoNhI0kQcQUl8YqJO5ZevROYk9HP8lOIeIgIYgjfbc=
X-Endpoint-Received: by B4 Relay for ciprian.regus@analog.com/20260330 with auth_id=703
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace the driver specific lan865x_phy_read_mmd() and
lan865x_phy_write_mmd() with the shared genphy_read_mmd_c45() and
genphy_write_mmd_c45() helpers.

No functional change.

Reviewed-by: Andrew Lunn <andrew@lunn.ch>
Signed-off-by: Ciprian Regus <ciprian.regus@analog.com>
---
v4 changelog:
 - no change
v3 changelog:
 - no change
v2 changelog:
 - New patch
---
 drivers/net/phy/microchip_t1s.c | 32 ++------------------------------
 1 file changed, 2 insertions(+), 30 deletions(-)

diff --git a/drivers/net/phy/microchip_t1s.c b/drivers/net/phy/microchip_t1s.c
index e601d56b2507..73c23d311d72 100644
--- a/drivers/net/phy/microchip_t1s.c
+++ b/drivers/net/phy/microchip_t1s.c
@@ -506,34 +506,6 @@ static int lan86xx_read_status(struct phy_device *phydev)
 	return 0;
 }
 
-/* OPEN Alliance 10BASE-T1x compliance MAC-PHYs will have both C22 and
- * C45 registers space. If the PHY is discovered via C22 bus protocol it assumes
- * it uses C22 protocol and always uses C22 registers indirect access to access
- * C45 registers. This is because, we don't have a clean separation between
- * C22/C45 register space and C22/C45 MDIO bus protocols. Resulting, PHY C45
- * registers direct access can't be used which can save multiple SPI bus access.
- * To support this feature, set .read_mmd/.write_mmd in the PHY driver to call
- * .read_c45/.write_c45 in the OPEN Alliance framework
- * drivers/net/ethernet/oa_tc6.c
- */
-static int lan865x_phy_read_mmd(struct phy_device *phydev, int devnum,
-				u16 regnum)
-{
-	struct mii_bus *bus = phydev->mdio.bus;
-	int addr = phydev->mdio.addr;
-
-	return __mdiobus_c45_read(bus, addr, devnum, regnum);
-}
-
-static int lan865x_phy_write_mmd(struct phy_device *phydev, int devnum,
-				 u16 regnum, u16 val)
-{
-	struct mii_bus *bus = phydev->mdio.bus;
-	int addr = phydev->mdio.addr;
-
-	return __mdiobus_c45_write(bus, addr, devnum, regnum, val);
-}
-
 static struct phy_driver microchip_t1s_driver[] = {
 	{
 		PHY_ID_MATCH_EXACT(PHY_ID_LAN867X_REVB1),
@@ -584,8 +556,8 @@ static struct phy_driver microchip_t1s_driver[] = {
 		.features           = PHY_BASIC_T1S_P2MP_FEATURES,
 		.config_init        = lan865x_revb_config_init,
 		.read_status        = lan86xx_read_status,
-		.read_mmd           = lan865x_phy_read_mmd,
-		.write_mmd          = lan865x_phy_write_mmd,
+		.read_mmd           = genphy_read_mmd_c45,
+		.write_mmd          = genphy_write_mmd_c45,
 		.get_plca_cfg	    = genphy_c45_plca_get_cfg,
 		.set_plca_cfg	    = lan86xx_plca_set_cfg,
 		.get_plca_status    = genphy_c45_plca_get_status,

-- 
2.43.0

