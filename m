From: Hans-Frieder Vogt <hfdevel@gmx.net>
Subject: [PATCH net-next v4 0/7] net: tn40xx: add support for AQR105 based
 cards
Date: Sat, 21 Dec 2024 15:43:35 +0100
Message-Id: <20241221-tn9510-v3a-v4-0-dafff89ba7a7@gmx.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABfUZmcC/02NwQ6DIBAFf8XsudsAKrU99T8aD4iLchAbIITG+
 O9F00OPLy8zs0EgbynAo9rAU7LBrq6M5lKBnpWbCO1YNggmGi64xOjuLWeYaoVCG827dpQdM1C
 Atydj8yl7gaOIjnKEvjyDCoSDV07Ph2xR1h3AbENc/eeMp/rEfp3bfyfVyLAZWzLSyE4Se05Lv
 pYA9Pu+fwEkONhuwwAAAA==
X-Change-ID: 20241216-tn9510-v3a-2cfc185d680f
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 FUJITA Tomonori <fujita.tomonori@gmail.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>
Cc: netdev@vger.kernel.org, Hans-Frieder Vogt <hfdevel@gmx.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1734792250; l=3890;
 i=hfdevel@gmx.net; s=20240915; h=from:subject:message-id;
 bh=WNV7VzPZ8IYtkgzuWUpSuVQulrCqx6cTlAD0PaHvaVQ=;
 b=YqIIdHSNqjf1BaCxIeg6aMOn04ua42yFiNZ6h/tGBE2EB5OWgDdDqnSy/lhqqUn4neWWq+yT5
 CYfgxbBevOsCzu2JAvtJJoh9Gug0xvDA4r5L2+HeJRoMQ6Mklf4GOzG
X-Developer-Key: i=hfdevel@gmx.net; a=ed25519;
 pk=s3DJ3DFe6BJDRAcnd7VGvvwPXcLgV8mrfbpt8B9coRc=
X-Endpoint-Received: by B4 Relay for hfdevel@gmx.net/20240915 with auth_id=209
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds support to the Tehuti tn40xx driver for TN9510 cards
which combine a TN4010 MAC with an Aquantia AQR105.
It is an update of the patch series "net: tn40xx: add support for AQR105
based cards", addressing review comments and generally cleaning up the series.

The patch was tested on a Tehuti TN9510 card (1fc9:4025:1fc9:3015).

Changes v1 -> v2:
- simplify the check for a firmware-name in a swnode in the aquantia PHY driver
(comment from Andrew Lunn)
- changed the software node definition to an mdio node with phy child nodes, to
be more in line with a typical device tree definition (also comment from
Andrew Lunn)
This also solves the problem with several TN4010-based cards that FUJITA
Tomonori reported
- clarified the cleanup calls, now calling fwnode_handle_put instead of
software_node_unregister (comment by FUJITA Tomonori)
- updated the function mdiobus_scan to support swnodes (following hint of
Andrew Lunn)
- remove the small patch to avoid failing after aqr_wait_reset_complete, now
that a proper patch by Vladimir Oltean is available
- replace setting of bit 3 in TN40_REG_MDIO_CMD_STAT by calling of
tn40_mdio_set_speed (suggestion by FUJITA Tomonori)
- cleaning up the distributed calls to set the MDIO speed in the tn40xx driver
- define supported PCI-IDs including subvendor IDs to prevent loading on
unsupported card
- Link to v1: https://lore.kernel.org/netdev/trinity-33332a4a-1c44-46b7-8526-b53b1a94ffc2-1726082106356@3c-app-gmx-bs04/

Changes v2 -> v3:
- aquantia_firmware: remove call to of_property_read_string. It should be
  called from the more generic function device_property_read_string
- add more AQR105-specific function, to support proper advertising and auto-
  negotiation
- re-organize the patches about the mdio speed and TN40_REG_MDIO_CMD_STAT,
  skipping the 1MHz intermediate speed step
- re-organized the sequence of the patches:
    1. changes to the general support functions (net/phy/mdio_bus.c)
    2. changes to the aquantia PHY driver
    3. changes to the tn40xx MAC driver, required to support the TN9510 cards
- Link to v2: https://lore.kernel.org/netdev/trinity-602c050f-bc76-4557-9824-252b0de48659-1726429697171@3c-app-gmx-bap07/

---
Changes in v4:
- use separate aqr105 specific functions instead of adding aqr105 functionality
  in common functions, with need of "chip generation" parameter
  (suggested by Andrew Lunn <andrew@lunn.ch>)
- make generation and cleanup of swnodes more symmetric
  (suggested by Andrew Lunn <andrew@lunn.ch>)
- add MDIO/PHY software nodes only for devices that have an aqr105 PHY
  (suggested by FUJITA Tomonori <fujita.tomonori@gmail.com>)
- Link to v3: https://lore.kernel.org/r/20241217-tn9510-v3a-v3-0-4d5ef6f686e0@gmx.net

---
Hans-Frieder Vogt (7):
      net: phy: Add swnode support to mdiobus_scan
      net: phy: aquantia: add probe function to aqr105 for firmware loading
      net: phy: aquantia: search for firmware-name in fwnode
      net: phy: aquantia: add essential functions to aqr105 driver
      net: tn40xx: create swnode for mdio and aqr105 phy and add to mdiobus
      net: tn40xx: prepare tn40xx driver to find phy of the TN9510 card
      net: tn40xx: add pci-id of the aqr105-based Tehuti TN4010 cards

 drivers/net/ethernet/tehuti/tn40.c           |   9 +-
 drivers/net/ethernet/tehuti/tn40.h           |  31 ++++
 drivers/net/ethernet/tehuti/tn40_mdio.c      |  80 ++++++++-
 drivers/net/phy/aquantia/aquantia_firmware.c |   7 +-
 drivers/net/phy/aquantia/aquantia_main.c     | 243 ++++++++++++++++++++++++++-
 drivers/net/phy/mdio_bus.c                   |  14 ++
 6 files changed, 375 insertions(+), 9 deletions(-)
---
base-commit: 860dbab69ad8d07a91117ed9c9eb5fb64adf7e0e
change-id: 20241216-tn9510-v3a-2cfc185d680f

Best regards,
-- 
Hans-Frieder Vogt <hfdevel@gmx.net>

