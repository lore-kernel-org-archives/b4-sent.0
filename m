From: Serapheim Dimitropoulos <sdimitropoulos@coreweave.com>
Date: Mon, 02 Mar 2026 10:10:59 -0500
Subject: [PATCH net-next] net: mdio: add fwnode compatible matching to
 mdio_bus_match()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260302-mdio-fwnode-match-v1-1-ac542b7c53a3@coreweave.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqDMBBG4avIrDsQh1Jpr1JcRPOnzsJJSUIri
 Hc3uPwW7+1UkBWFXt1OGT8tmqyhv3U0L94+YA3NJE4eTmTgNWji+LcUwKuv88KTPDHdAwYfHbX
 umxF1u55vMlQ2bJXG4zgBis//TG0AAAA=
X-Change-ID: 20260227-mdio-fwnode-match-b29eb4de7af0
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Serapheim Dimitropoulos <sdimitropoulos@coreweave.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772464267; l=3051;
 i=sdimitropoulos@coreweave.com; s=20260302; h=from:subject:message-id;
 bh=MRrfkvAZ3+WAdPSLi3xHODK806e9I/kLyRuqHAkQMlg=;
 b=iZTvmuUSjDogsrbLldqRhLOUPu/mEq40ouAS0VkuZRPW137iZthkyPR4iDj22HW0h/iCpsk46
 7+yVlk6K3FCC2c+1+Ro8u0JB4vACBjTuaIfDZs4X7R0FUW7lRCquRMZ
X-Developer-Key: i=sdimitropoulos@coreweave.com; a=ed25519;
 pk=Qysvg7jaTIU0posaYFtqa5SKJlFwqzil4X0U1p1zo/g=
X-Endpoint-Received: by B4 Relay for sdimitropoulos@coreweave.com/20260302 with auth_id=655
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MDIO bus match function currently only supports Device Tree
(of_driver_match_device) and PHY-ID-based matching (bus_match callback).
This means MDIO drivers that rely on compatible-string matching, such as
the mv88e6xxx DSA switch driver, cannot bind on systems that describe
hardware topology via firmware nodes (fwnode/software nodes) rather than
Device Tree.

This is a problem for x86/ACPI platforms where MDIO buses are created
dynamically (e.g., USB-to-MDIO bridges) and have no Device Tree
representation. On these systems, kernel modules or ACPI tables can
describe the MDIO device topology using software nodes with a
"compatible" property, but mdio_bus_match() never checks it.

Add a fallback matching path that iterates the driver's of_match_table
and checks each compatible string against the device's fwnode using the
existing device_is_compatible() helper. This is placed after the OF
match (which handles DT natively) and before the bus_match callback
(which handles PHY-ID matching), so existing match behavior is
unchanged.

This enables DSA switch drivers like mv88e6xxx to bind on x86 systems
where the switch topology is described via software nodes or ACPI,
closing a gap in MDIO bus support for non-DT platforms.

Signed-off-by: Serapheim Dimitropoulos <sdimitropoulos@coreweave.com>
---
 drivers/net/phy/mdio_bus.c | 15 +++++++++++++++
 1 file changed, 15 insertions(+)

diff --git a/drivers/net/phy/mdio_bus.c b/drivers/net/phy/mdio_bus.c
index afdf1ad6c0e61..4575122edb475 100644
--- a/drivers/net/phy/mdio_bus.c
+++ b/drivers/net/phy/mdio_bus.c
@@ -23,6 +23,7 @@
 #include <linux/of_device.h>
 #include <linux/of_mdio.h>
 #include <linux/phy.h>
+#include <linux/property.h>
 #include <linux/reset.h>
 #include <linux/slab.h>
 #include <linux/spinlock.h>
@@ -959,6 +960,7 @@ static int mdio_bus_match(struct device *dev, const struct device_driver *drv)
 {
 	const struct mdio_driver *mdiodrv = to_mdio_driver(drv);
 	struct mdio_device *mdio = to_mdio_device(dev);
+	const struct of_device_id *id;
 
 	/* Both the driver and device must type-match */
 	if (!(mdiodrv->mdiodrv.flags & MDIO_DEVICE_IS_PHY) !=
@@ -968,6 +970,19 @@ static int mdio_bus_match(struct device *dev, const struct device_driver *drv)
 	if (of_driver_match_device(dev, drv))
 		return 1;
 
+	/*
+	 * Fall back to fwnode compatible matching for non-DT systems.
+	 * This enables MDIO drivers (e.g., DSA switch drivers) to bind
+	 * on platforms using software nodes or ACPI to describe the
+	 * MDIO device topology.
+	 */
+	if (dev_fwnode(dev) && !dev->of_node && drv->of_match_table) {
+		for (id = drv->of_match_table; id->compatible[0]; id++) {
+			if (device_is_compatible(dev, id->compatible))
+				return 1;
+		}
+	}
+
 	if (mdio->bus_match)
 		return mdio->bus_match(dev, drv);
 

---
base-commit: fd6dad4e1ae296b67b87291256878a58dad36c93
change-id: 20260227-mdio-fwnode-match-b29eb4de7af0

Best regards,
-- 
Serapheim Dimitropoulos <sdimitropoulos@coreweave.com>

