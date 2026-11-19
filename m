From: Blake Alexander <blake.alexander@airbus.com>
Date: Thu, 19 Nov 2026 11:50:00 +0100
Subject: [PATCH net] net: dsa: mv88e6xxx: do not override PHYIDs on
 external MDIO
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-mv88e6xxx-fix-v1-1-2db604f3516f@airbus.com>
X-B4-Tracking: v=1; b=H4sIAFfU/moC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQ0MD3dwyC4tUs4qKCt20TCA2skw1NzI0sbA0T1UC6ikoSgUKg82LjoX
 wi0uTslKTS0CGKNXWAgC4JhAocQAAAA==
X-Change-ID: 20261110-mv88e6xxx-fix-f29e7214897e
To: Andrew Lunn <andrew@lunn.ch>, Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Florian Fainelli <f.fainelli@gmail.com>, 
 Vivien Didelot <vivien.didelot@gmail.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Blake Alexander <blake.alexander@airbus.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795085413; l=2771;
 i=blake.alexander@airbus.com; s=20261109; h=from:subject:message-id;
 bh=DEvRstpM6J0VNGLN6y0A8zWK7GLAM0NdyvBdHfH9s/U=;
 b=OfmZz6PPSSGr42KEyWN02aE+/S0tChV3uv/5keBZmbwX94dTMLQ3JST8THEblY1iUhcjGJTor
 PcoeOc1NVP9CU9KhwH9V2k2jdVF2C4+8B3cJI0a1dYM6k4gwFWPfUAX
X-Developer-Key: i=blake.alexander@airbus.com; a=ed25519;
 pk=cfpa2FQbYHF1zxIJuHbr8W+NR9T4DK/baAknnTv2I68=
X-Endpoint-Received: by B4 Relay for blake.alexander@airbus.com/20261109 with auth_id=1461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some variants of the Marvell 88E6xxx family (such as MV88E6390) support
an external MDIO bus (in addition to the internal MDIO bus for
configuring internal PHYs). A typical use-case for the external bus is
to configure PHYs that are external to the switch. On switches that do
not assign a PHYID for internal PHYs (i.e. the value is 0), the
mv88e6xxx_mdio_read() function traps read calls to the PHYID registers
and sets the PHYID equal to the family ID of the switch.

The mv88e6xxx_mdio_read() function is reused for both internal and mdio
bus operations. The PHYID overwrite trap does not check whether the MDIO
bus is internal or external and wrongly modifies the PHYID of devices on
the external bus when their PHYID2 register reports a value of 0. When a
C22 device reports a PHYID of 0, get_phy_device() will reprobe the
device as C45 and if successful create a C45 device. Overriding the
PHYID in this case will prevent a C45 device (such as Aquantia AQR115)
from being reprobed and their driver will fail to bind.

This was observed on a development board during the bring-up phase. The
board included an MV88E6393X with external AQR115 PHYs. The MDIO bus of
the PHYs was connected to the external MDIO bus of the Marvell switch.
Prior to applying this patch, the aquantia driver failed to detect the
AQR115 and instead detected a generic C22 device (as a PHYID of
0x00000393 does not match a known PHY). After applying this fix, the
external AQR115s were detected correctly and their respective driver
bound to them successfully.

Do not modify the returned PHYID in mv88e6xxx_mdio_read() when reading
from a device on the external MDIO bus.

Fixes: da9f33018e2c ("net: dsa: mv88e6xxx: Workaround missing PHY ID on mv88e6390")
Cc: stable@vger.kernel.org
Signed-off-by: Blake Alexander <blake.alexander@airbus.com>
---
 drivers/net/dsa/mv88e6xxx/chip.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/net/dsa/mv88e6xxx/chip.c b/drivers/net/dsa/mv88e6xxx/chip.c
index 46aef6dfe77e..bf077e476fd1 100644
--- a/drivers/net/dsa/mv88e6xxx/chip.c
+++ b/drivers/net/dsa/mv88e6xxx/chip.c
@@ -3779,7 +3779,7 @@ static int mv88e6xxx_mdio_read(struct mii_bus *bus, int phy, int reg)
 	mv88e6xxx_reg_unlock(chip);
 
 	/* Some internal PHYs don't have a model number. */
-	if (reg == MII_PHYSID2 && !(val & 0x3f0) &&
+	if (!mdio_bus->external && reg == MII_PHYSID2 && !(val & 0x3f0) &&
 	    chip->info->family < ARRAY_SIZE(family_prod_id_table)) {
 		prod_id = family_prod_id_table[chip->info->family];
 		if (prod_id)

---
base-commit: af6f95c3300e3d234c813b80f831dd7b80b3eaf2
change-id: 20261110-mv88e6xxx-fix-f29e7214897e

Best regards,
--  
Blake Alexander <blake.alexander@airbus.com>

