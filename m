From: Hans-Frieder Vogt <hfdevel@gmx.net>
Date: Tue, 17 Dec 2024 22:07:32 +0100
Subject: [PATCH net-next v3 1/7] net: phy: Add swnode support to
 mdiobus_scan
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241217-tn9510-v3a-v3-1-4d5ef6f686e0@gmx.net>
References: <20241217-tn9510-v3a-v3-0-4d5ef6f686e0@gmx.net>
In-Reply-To: <20241217-tn9510-v3a-v3-0-4d5ef6f686e0@gmx.net>
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 FUJITA Tomonori <fujita.tomonori@gmail.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>
Cc: netdev@vger.kernel.org, Hans-Frieder Vogt <hfdevel@gmx.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1734469657; l=1936;
 i=hfdevel@gmx.net; s=20240915; h=from:subject:message-id;
 bh=tjXgAqiIJ9J3+v8YrXDfNqVpQpUv8M+JKJWk7sw4eKE=;
 b=pUKEW6gWmJ6Jod+VW4X1UJ6wLO2Ci8B1REHU+c8axfptUcmIuoOWlmNmB8oHwzDOqePkYKFeJ
 DfnuyFH3QzuDRhiMt3eTOw+s80CrFFlWugkLCQ8AZIGZyJ4FwlPFsjI
X-Developer-Key: i=hfdevel@gmx.net; a=ed25519;
 pk=s3DJ3DFe6BJDRAcnd7VGvvwPXcLgV8mrfbpt8B9coRc=
X-Endpoint-Received: by B4 Relay for hfdevel@gmx.net/20240915 with auth_id=209
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch will allow to use a swnode/fwnode defined for a phy_device. The
MDIO bus (mii_bus) needs to contain nodes for the PHY devices, named
"ethernet-phy@i", with i being the MDIO address (0 .. PHY_MAX_ADDR - 1).

The fwnode is only attached to the phy_device if there isn't already an
fwnode attached.

fwnode_get_named_child_node will increase the usage counter of the fwnode.
However, no new code is needed to decrease the counter again, since this is
already implemented in the phy_device_release function.

Signed-off-by: Hans-Frieder Vogt <hfdevel@gmx.net>
---
 drivers/net/phy/mdio_bus.c | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/drivers/net/phy/mdio_bus.c b/drivers/net/phy/mdio_bus.c
index 7e2f10182c0cf37bef4cea1820863f047b5cb466..ede596c1a69d1b2b986e9eef51c3beb4a5fbc805 100644
--- a/drivers/net/phy/mdio_bus.c
+++ b/drivers/net/phy/mdio_bus.c
@@ -551,6 +551,8 @@ static int mdiobus_create_device(struct mii_bus *bus,
 static struct phy_device *mdiobus_scan(struct mii_bus *bus, int addr, bool c45)
 {
 	struct phy_device *phydev = ERR_PTR(-ENODEV);
+	struct fwnode_handle *fwnode;
+	char node_name[16];
 	int err;
 
 	phydev = get_phy_device(bus, addr, c45);
@@ -562,6 +564,18 @@ static struct phy_device *mdiobus_scan(struct mii_bus *bus, int addr, bool c45)
 	 */
 	of_mdiobus_link_mdiodev(bus, &phydev->mdio);
 
+	/* Search for a swnode for the phy in the swnode hierarchy of the bus.
+	 * If there is no swnode for the phy provided, just ignore it.
+	 */
+	if (dev_fwnode(&bus->dev) && !dev_fwnode(&phydev->mdio.dev)) {
+		snprintf(node_name, sizeof(node_name), "ethernet-phy@%d",
+			 addr);
+		fwnode = fwnode_get_named_child_node(dev_fwnode(&bus->dev),
+						     node_name);
+		if (fwnode)
+			device_set_node(&phydev->mdio.dev, fwnode);
+	}
+
 	err = phy_device_register(phydev);
 	if (err) {
 		phy_device_free(phydev);

-- 
2.45.2

