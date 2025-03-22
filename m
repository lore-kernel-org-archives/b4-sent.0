From: Hans-Frieder Vogt <hfdevel@gmx.net>
Subject: [PATCH net-next v7 0/7] net: tn40xx: add support for AQR105 based
 cards
Date: Sat, 22 Mar 2025 11:45:51 +0100
Message-Id: <20250322-tn9510-v3a-v7-0-672a9a3d8628@gmx.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAN+U3mcC/1XNTW7DIBCG4atErEs1/ENXvUfVBTZDzCIkAgu5i
 nz3EqtVwnI0er73TiqWhJV8nO6kYEs1XXM/zNuJzIvPZ6Qp9Jtw4JJxpumanWJAm/CUz3FmVgV
 tIZIObgVj2o6xL5JxpRm3lXz3z+Qr0qn4PC+PsYtP+QGWVNdr+TniTRzsr2NeO01QoDIojDpqq
 xE+z5ftvQeO7SZfIGcDlB0GH2O0bvLGmxGqf6iAcz5A1aFzQiuQBgW4EeonFMwOUHdowXoH1gU
 upyfc9/0XHJhj424BAAA=
X-Change-ID: 20241216-tn9510-v3a-2cfc185d680f
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 FUJITA Tomonori <fujita.tomonori@gmail.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Hans-Frieder Vogt <hfdevel@gmx.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742640367; l=5168;
 i=hfdevel@gmx.net; s=20240915; h=from:subject:message-id;
 bh=dy7hnpEpmljpvnmL7VUaERJFKqdCMUh00qJI84ZH+hY=;
 b=b2krxJvHp5+OhOArQcSFecb2wM4Tk2k+Uo9UyRO0v0MSxwvczVKs3kSNbk9Ca0NsfM92qR9W9
 GKlKin1KN6KCkD+DvT0F4xxh7/XCpQt1kg5DOeoRxzh5xqybcUkUiok
X-Developer-Key: i=hfdevel@gmx.net; a=ed25519;
 pk=s3DJ3DFe6BJDRAcnd7VGvvwPXcLgV8mrfbpt8B9coRc=
X-Endpoint-Received: by B4 Relay for hfdevel@gmx.net/20240915 with auth_id=209
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds support to the Tehuti tn40xx driver for TN9510 cards
which combine a TN4010 MAC with an Aquantia AQR105.
It is an update of the patch series "net: tn40xx: add support for AQR105
based cards", addressing review comments and generally cleaning up the series.

The patch was tested on a Tehuti TN9510 card (1fc9:4025:1fc9:3015).

---
Changes in v7:
- change function name aqr105_config_speed to aqr105_setup_forced, in line with
  naming of generic functions
  (suggested by Andrew Lunn <andrew@lunn.ch>)
- replace device id 0x4025 with symbolic name PCI_DEVICE_ID_TEHUTI_TN9510
  (suggested by Andrew Lunn <andrew@lunn.ch>)
- because of last change, remove the Reviewed-by: entries for PATCH 7/7
- Link to v6: https://lore.kernel.org/r/20250318-tn9510-v3a-v6-0-808a9089d24b@gmx.net

Changes in v6:
- rebaseline to net-next
- remove unneeded loop timing ability advertisment in aquantia_main.c
  (highlighted by Maxime Chevallier <maxime.chevallier@bootlin.com>)
- add failure path in tn40_mdio.c if device_add_software_node fails
  (suggested by Ratheesh Kannoth <rkannoth@marvell.com>)
- Link to v5: https://lore.kernel.org/r/20250222-tn9510-v3a-v5-0-99365047e309@gmx.net

Changes in v5:
- changed version because "b4 send --resend v4" did not succeed
- used opportunity to rebaseline to net-next
- only source code change is merging a split string in tn40_mdio.c, removing
  a warning from b4 prep --check
- changed format of cover letter in line with b4 (sequence of changes from
  latest to oldest)
- Link to v4: https://lore.kernel.org/r/20241221-tn9510-v3a-v4-0-dafff89ba7a7@gmx.net

Changes in v4:
- use separate aqr105 specific functions instead of adding aqr105 functionality
  in common functions, with need of "chip generation" parameter
  (suggested by Andrew Lunn <andrew@lunn.ch>)
- make generation and cleanup of swnodes more symmetric
  (suggested by Andrew Lunn <andrew@lunn.ch>)
- add MDIO/PHY software nodes only for devices that have an aqr105 PHY
  (suggested by FUJITA Tomonori <fujita.tomonori@gmail.com>)
- Link to v3: https://lore.kernel.org/r/20241217-tn9510-v3a-v3-0-4d5ef6f686e0@gmx.net

Changes in v3:
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

Changes in v2:
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
 drivers/net/ethernet/tehuti/tn40.h           |  33 ++++
 drivers/net/ethernet/tehuti/tn40_mdio.c      |  84 +++++++++-
 drivers/net/phy/aquantia/aquantia_firmware.c |   7 +-
 drivers/net/phy/aquantia/aquantia_main.c     | 240 ++++++++++++++++++++++++++-
 drivers/net/phy/mdio_bus.c                   |  14 ++
 6 files changed, 378 insertions(+), 9 deletions(-)
---
base-commit: 23c9ff659140f97d44bf6fb59f89526a168f2b86
change-id: 20241216-tn9510-v3a-2cfc185d680f

Best regards,
-- 
Hans-Frieder Vogt <hfdevel@gmx.net>

