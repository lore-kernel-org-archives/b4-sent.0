From: Blake Alexander <blake.alexander@airbus.com>
Date: Mon, 09 Nov 2026 17:56:30 +0100
Subject: [PATCH net-next] net: usb: name usb ethernet mdio buses reliably
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-net-usb-mdio-naming-v1-1-f4cca6737784@airbus.com>
X-B4-Tracking: v=1; b=H4sIAD378WoC/yWNQQqEMBAEvyJzdiCJbHD3K+JB46hzcNQkiiD+f
 aMei6K6TwjkmQL8shM87Rx4lgQ6z8CNjQyE3CUGo4zVWn1RKOIWWpw6nlGaiWVA1xamt6X6uMJ
 CKhdPPR/PagV3IHREqF/jad3STXx1fV1/74gEGYQAAAA=
X-Change-ID: 20261109-net-usb-mdio-naming-cb32f6805c36
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Thangaraj Samynathan <Thangaraj.S@microchip.com>, 
 UNGLinuxDriver@microchip.com
Cc: linux-usb@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Blake Alexander <blake.alexander@airbus.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794243402; l=3082;
 i=blake.alexander@airbus.com; s=20261109; h=from:subject:message-id;
 bh=Aq+iM0Hh6B0JDL8TaEt+jovCKbEtmkgqtg3fnPSTJ7g=;
 b=zQtsDUC3IQ/9zbR59Oke/23oXkcipe+Aoo0hYfR0yshRy6+pJHAYpnxqU6DhpgCnfUZ9j4sO6
 creHUuquyHCC2m7dmNf0wVECO2+pfqkrStd6/TlvRj0bQ5/4SNqnNdh
X-Developer-Key: i=blake.alexander@airbus.com; a=ed25519;
 pk=cfpa2FQbYHF1zxIJuHbr8W+NR9T4DK/baAknnTv2I68=
X-Endpoint-Received: by B4 Relay for blake.alexander@airbus.com/20261109 with auth_id=1461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Embedded systems may utilize fixed USB ethernet controllers (such as the
LAN78xx series) which are soldered directly onto the board. Currently,
the MDIO bus names for USB ethernet devices are non-deterministic as
they rely on the USB bus and device numbers (e.g.
"usb-${bus_num}:${dev_num}").

For hot-pluggable devices a stable MDIO bus name cannot be assumed.
However, for systems using fixed devices, user-space configuration
scripts and tools require predictable bus names.

Use usb_make_path() to generate the MDIO bus name instead, ensuring a
predictable and deterministic bus naming scheme when attached at the
same position within the USB hierarchy.

Signed-off-by: Blake Alexander <blake.alexander@airbus.com>
---
 drivers/net/usb/asix_devices.c | 5 ++---
 drivers/net/usb/ax88172a.c     | 5 ++---
 drivers/net/usb/lan78xx.c      | 3 +--
 3 files changed, 5 insertions(+), 8 deletions(-)

diff --git a/drivers/net/usb/asix_devices.c b/drivers/net/usb/asix_devices.c
index 293ef80c4e30..c752fa3868b8 100644
--- a/drivers/net/usb/asix_devices.c
+++ b/drivers/net/usb/asix_devices.c
@@ -680,9 +680,8 @@ static int ax88772_init_mdio(struct usbnet *dev)
 	priv->mdio->write = &asix_mdio_bus_write;
 	priv->mdio->name = "Asix MDIO Bus";
 	priv->mdio->phy_mask = ~(BIT(priv->phy_addr & 0x1f) | BIT(AX_EMBD_PHY_ADDR));
-	/* mii bus name is usb-<usb bus number>-<usb device number> */
-	snprintf(priv->mdio->id, MII_BUS_ID_SIZE, "usb-%03d:%03d",
-		 dev->udev->bus->busnum, dev->udev->devnum);
+
+	usb_make_path(dev->udev, priv->mdio->id, MII_BUS_ID_SIZE);
 
 	ret = mdiobus_register(priv->mdio);
 	if (ret) {
diff --git a/drivers/net/usb/ax88172a.c b/drivers/net/usb/ax88172a.c
index f5036451f086..9f050de0cddb 100644
--- a/drivers/net/usb/ax88172a.c
+++ b/drivers/net/usb/ax88172a.c
@@ -73,9 +73,8 @@ static int ax88172a_init_mdio(struct usbnet *dev)
 	priv->mdio->read = &asix_mdio_bus_read;
 	priv->mdio->write = &asix_mdio_bus_write;
 	priv->mdio->name = "Asix MDIO Bus";
-	/* mii bus name is usb-<usb bus number>-<usb device number> */
-	snprintf(priv->mdio->id, MII_BUS_ID_SIZE, "usb-%03d:%03d",
-		 dev->udev->bus->busnum, dev->udev->devnum);
+
+	usb_make_path(dev->udev, priv->mdio->id, MII_BUS_ID_SIZE);
 
 	ret = mdiobus_register(priv->mdio);
 	if (ret) {
diff --git a/drivers/net/usb/lan78xx.c b/drivers/net/usb/lan78xx.c
index d73002b2c21a..153aa56b8e68 100644
--- a/drivers/net/usb/lan78xx.c
+++ b/drivers/net/usb/lan78xx.c
@@ -2117,8 +2117,7 @@ static int lan78xx_mdio_init(struct lan78xx_net *dev)
 	dev->mdiobus->name = "lan78xx-mdiobus";
 	dev->mdiobus->parent = &dev->udev->dev;
 
-	snprintf(dev->mdiobus->id, MII_BUS_ID_SIZE, "usb-%03d:%03d",
-		 dev->udev->bus->busnum, dev->udev->devnum);
+	usb_make_path(dev->udev, dev->mdiobus->id, MII_BUS_ID_SIZE);
 
 	switch (dev->chipid) {
 	case ID_REV_CHIP_ID_7800_:

---
base-commit: fa5196392691051963726787944db872420dfa75
change-id: 20261109-net-usb-mdio-naming-cb32f6805c36

Best regards,
--  
Blake Alexander <blake.alexander@airbus.com>

