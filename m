From: Agustin Santiago Isasmendi <isasmendi.agus@gmail.com>
Date: Thu, 05 Nov 2026 15:49:40 +0100
Subject: [PATCH net-next] net: phy: add driver for the ZTE ZX279128S
 internal Gigabit PHY
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-phy-submit-v1-1-eb382681a76a@gmail.com>
X-B4-Tracking: v=1; b=H4sIAIOX7GoC/yWMQQqDMBQFryJv3Q9GsdBepXQR41N/oakkaVHEu
 5vqchhmVkQGZcS9WBH406gfn8FcCrjR+oGiXWZUZXU1pmxkGheJ3/atSWzd29q1vJEdcjAF9jo
 fswc8k3jOCc/T5OZFl/4vbNsOWYDOb3gAAAA=
X-Change-ID: 20261105-phy-submit-a3fa3cbe9eed
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 Agustin Santiago Isasmendi <isasmendi.agus@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793890179; l=9306;
 i=isasmendi.agus@gmail.com; s=20261105; h=from:subject:message-id;
 bh=buQMSpEZoOkRLoT9KDEdGhDKcAMPcAhBidPxPbKe87w=;
 b=nivCFy8KQVGLRy+eDC7yWdE4+/XmsBkKFTnZCggGTJRDIvPAcRN2IVhA5xls796fsjcg71nw8
 ljAbLxCesywD+v9dRIqjyjlJ/byI3/KeTRYQKc0VRvC8laAWEnq9sH8
X-Developer-Key: i=isasmendi.agus@gmail.com; a=ed25519;
 pk=QIk41j89qSxlagpY51o20QegtDwsmrs5yGga3To1GzU=
X-Endpoint-Received: by B4 Relay for isasmendi.agus@gmail.com/20261105 with auth_id=1421
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ZTE ZX279128S is a dual Cortex-A9 xPON home-gateway SoC, used in
the ZTE ZXHN H3600 router. It integrates four Gigabit copper PHYs, one
per LAN port of its on-chip switch, on the SoC's MDIO bus at addresses
10..13. They identify as 0x84b95031 (the low nibble is the revision).

There is no public datasheet. The registers and values come from the
PHY initialisation in the vendor's platform module shipped in the
router firmware (no source available); the function names below are
that module's symbols.

  - Registers 0x10/0x11 give indirect access to extended registers:
    address in 0x10, data in 0x11. The pair is done with the MDIO bus
    lock held. It is not a page select, so phy_*_paged() does not fit.
  - Register 0x17 and extended register 0xb640: the PHY's LDO.
    gephy_ldo_init() writes 0x17 = 0x2448, then 0xb640 = 0x001f, on
    every PHY. The meaning of the 0x17 fields is unknown.
  - Extended registers 0xb667..0xb6c2: the copper TX DAC drive.
    gephy_tx_dac_drv_force_enable() has a "force" and a reduced
    pattern; the driver applies the force pattern. Without it the PHY
    links and receives but does not drive the line: the MAC counts the
    transmitted frames and the link partner sees none.

The LDO is only armed when 0xb640 does not already read 0x001f: arming
it again power-cycles the PHY's analog domain, which the switch sees as
a link bounce. When nothing has armed it before, the driver does.

The board's boot firmware leaves the PHYs with BMCR_PDOWN set, hence
.resume = genphy_resume(). There is no .suspend: powering the analog
domain down and up at runtime has not been tested.

Not implemented: interrupts, since the per-PHY lines have not been
seen to fire on a cable change on this board, so phylib polls. Also
not implemented are two runtime policies of the vendor module. One
lowers the LDO setting (0xb640 = 0x001c) at or above 60 C die
temperature and restores it at or below 50 C; it needs a driver for
the SoC temperature sensor first. The other switches the TX DAC
between the two patterns from the link state.

Tested on a ZTE ZXHN H3600 with net-next: the four PHYs bind, lan0
links at 1000, 100 and 10 Mb/s full duplex with traffic, link down/up,
warm boots.

Signed-off-by: Agustin Santiago Isasmendi <isasmendi.agus@gmail.com>
---
This is the first piece of mainline support for the ZTE ZX279128S
(ZTE ZXHN H3600 router). The SoC's MDIO controller, its on-chip switch
(DSA) and packet-processor drivers will be posted separately; this PHY
driver is matched by PHY ID and does not depend on them.

No datasheet is available. Every vendor-specific value in the driver
comes from the vendor's PHY initialisation (function names in the
commit message), and its observed effect is described where known.
---
 MAINTAINERS                     |   6 ++
 drivers/net/phy/Kconfig         |  11 ++++
 drivers/net/phy/Makefile        |   1 +
 drivers/net/phy/zte-zx279128s.c | 136 ++++++++++++++++++++++++++++++++++++++++
 4 files changed, 154 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 09713dc4c6..6102772886 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -30906,6 +30906,12 @@ L:	netdev@vger.kernel.org
 S:	Maintained
 F:	drivers/net/ethernet/zte/
 
+ZTE ZX279128S ETHERNET PHY DRIVER
+M:	Agustin Santiago Isasmendi <isasmendi.agus@gmail.com>
+L:	netdev@vger.kernel.org
+S:	Maintained
+F:	drivers/net/phy/zte-zx279128s.c
+
 THE REST
 M:	Linus Torvalds <torvalds@linux-foundation.org>
 L:	linux-kernel@vger.kernel.org
diff --git a/drivers/net/phy/Kconfig b/drivers/net/phy/Kconfig
index 30e9d22c8d..7a5d984b8c 100644
--- a/drivers/net/phy/Kconfig
+++ b/drivers/net/phy/Kconfig
@@ -503,4 +503,15 @@ config XILINX_GMII2RGMII
 	  the Reduced Gigabit Media Independent Interface(RGMII) between
 	  Ethernet physical media devices and the Gigabit Ethernet controller.
 
+config ZTE_ZX279128S_PHY
+	tristate "ZTE ZX279128S internal Gigabit PHY"
+	help
+	  Support for the four Gigabit Ethernet PHYs integrated in the ZTE
+	  ZX279128S SoC (PHY ID 0x84b95031), found in the ZTE ZXHN H3600
+	  router. The driver powers the PHY's LDO and enables the copper
+	  TX DAC drive, without which the PHYs link but do not transmit.
+
+	  To compile this driver as a module, choose M here: the module
+	  will be called zte-zx279128s.
+
 endif # PHYLIB
diff --git a/drivers/net/phy/Makefile b/drivers/net/phy/Makefile
index 579066a638..29bd283e7e 100644
--- a/drivers/net/phy/Makefile
+++ b/drivers/net/phy/Makefile
@@ -103,3 +103,4 @@ obj-$(CONFIG_TERANETICS_PHY)	+= teranetics.o
 obj-$(CONFIG_VITESSE_PHY)	+= vitesse.o
 obj-$(CONFIG_XPOWERS_ACX00_PHY)	+= xpowers/
 obj-$(CONFIG_XILINX_GMII2RGMII) += xilinx_gmii2rgmii.o
+obj-$(CONFIG_ZTE_ZX279128S_PHY)	+= zte-zx279128s.o
diff --git a/drivers/net/phy/zte-zx279128s.c b/drivers/net/phy/zte-zx279128s.c
new file mode 100644
index 0000000000..bd5049e871
--- /dev/null
+++ b/drivers/net/phy/zte-zx279128s.c
@@ -0,0 +1,136 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Driver for the gigabit Ethernet PHYs integrated in the ZTE ZX279128S SoC.
+ *
+ * Copyright (C) 2026 Agustin Santiago Isasmendi <isasmendi.agus@gmail.com>
+ *
+ * The SoC has four of these PHYs, one per LAN port of its on-chip switch,
+ * on the SoC's MDIO bus at addresses 10..13. There is no public datasheet:
+ * the vendor-specific registers and values below are the ones the vendor's
+ * own PHY initialisation uses.
+ *
+ * Extended registers are reached indirectly: the extended address is
+ * written to register 0x10, then the data is read or written through
+ * register 0x11. This is an address/data pair, not a page select (nothing
+ * to read back or restore), so the phy_*_paged() helpers do not apply; the
+ * pair is done with the MDIO bus lock held instead.
+ */
+
+#include <linux/bits.h>
+#include <linux/module.h>
+#include <linux/phy.h>
+
+#define ZTE_GEPHY_PHY_ID		0x84b95031
+
+#define ZTE_GEPHY_EXT_ADDR		0x10
+#define ZTE_GEPHY_EXT_DATA		0x11
+/* Written before the LDO is armed; the field layout is unknown. */
+#define ZTE_GEPHY_LDO_CTRL		0x17
+#define   ZTE_GEPHY_LDO_CTRL_VAL	0x2448
+
+/* Extended registers */
+#define ZTE_GEPHY_EXT_LDO		0xb640
+#define   ZTE_GEPHY_EXT_LDO_ON		0x001f
+
+/* Copper TX DAC drive: the vendor's full-drive ("force") pattern. Without
+ * it the PHY links and receives, but does not drive the line. The
+ * individual fields are not documented.
+ */
+static const struct {
+	u16 addr;
+	u16 val;
+} zte_gephy_tx_dac[] = {
+	{ 0xb676, 0x0003 },
+	{ 0xb677, 0x0003 },
+	{ 0xb667, 0x0003 },
+	{ 0xb668, 0x0003 },
+	{ 0xb6c2, 0x0003 },
+	{ 0xb6c1, 0x0003 },
+	{ 0xb678, 0x000f },
+	{ 0xb669, 0x0000 },
+};
+
+static int __zte_gephy_ext_write(struct phy_device *phydev, u16 addr, u16 val)
+{
+	int ret;
+
+	ret = __phy_write(phydev, ZTE_GEPHY_EXT_ADDR, addr);
+	if (ret < 0)
+		return ret;
+	return __phy_write(phydev, ZTE_GEPHY_EXT_DATA, val);
+}
+
+static int zte_gephy_ext_read(struct phy_device *phydev, u16 addr)
+{
+	int ret;
+
+	phy_lock_mdio_bus(phydev);
+	ret = __phy_write(phydev, ZTE_GEPHY_EXT_ADDR, addr);
+	if (ret >= 0)
+		ret = __phy_read(phydev, ZTE_GEPHY_EXT_DATA);
+	phy_unlock_mdio_bus(phydev);
+
+	return ret;
+}
+
+static int zte_gephy_config_init(struct phy_device *phydev)
+{
+	int ret, i, ldo;
+
+	ldo = zte_gephy_ext_read(phydev, ZTE_GEPHY_EXT_LDO);
+	if (ldo < 0)
+		return ldo;
+
+	phy_lock_mdio_bus(phydev);
+
+	/* Power the PHY's LDO, unless it already is: arming it again
+	 * power-cycles the analog domain, which the switch sees as a link
+	 * bounce.
+	 */
+	if (ldo != ZTE_GEPHY_EXT_LDO_ON) {
+		phydev_dbg(phydev, "arming LDO (was %#06x)\n", ldo);
+		ret = __phy_write(phydev, ZTE_GEPHY_LDO_CTRL,
+				  ZTE_GEPHY_LDO_CTRL_VAL);
+		if (ret >= 0)
+			ret = __zte_gephy_ext_write(phydev, ZTE_GEPHY_EXT_LDO,
+						    ZTE_GEPHY_EXT_LDO_ON);
+		if (ret < 0)
+			goto out;
+	}
+
+	for (i = 0; i < ARRAY_SIZE(zte_gephy_tx_dac); i++) {
+		ret = __zte_gephy_ext_write(phydev, zte_gephy_tx_dac[i].addr,
+					    zte_gephy_tx_dac[i].val);
+		if (ret < 0)
+			goto out;
+	}
+	ret = 0;
+out:
+	phy_unlock_mdio_bus(phydev);
+	return ret;
+}
+
+static struct phy_driver zte_gephy_driver[] = {
+	{
+		PHY_ID_MATCH_MODEL(ZTE_GEPHY_PHY_ID),
+		.name			= "ZTE ZX279128S Gigabit PHY",
+		.flags			= PHY_IS_INTERNAL,
+		.config_init		= zte_gephy_config_init,
+		/* The boot firmware hands over with BMCR_PDOWN set. No
+		 * .suspend: powering the analog domain down and up at runtime
+		 * has not been tested.
+		 */
+		.resume			= genphy_resume,
+	},
+};
+module_phy_driver(zte_gephy_driver);
+
+static const struct mdio_device_id __maybe_unused zte_gephy_tbl[] = {
+	{ PHY_ID_MATCH_MODEL(ZTE_GEPHY_PHY_ID) },
+	{ }
+};
+MODULE_DEVICE_TABLE(mdio, zte_gephy_tbl);
+
+MODULE_AUTHOR("Agustin Santiago Isasmendi <isasmendi.agus@gmail.com>");
+MODULE_DESCRIPTION("ZTE ZX279128S internal Gigabit PHY driver");
+MODULE_LICENSE("GPL");

---
base-commit: 0822d2fe38262e8b55c5ea55c970022bca8dd2a9
change-id: 20261105-phy-submit-a3fa3cbe9eed

Best regards,
--  
Agustin Santiago Isasmendi <isasmendi.agus@gmail.com>

