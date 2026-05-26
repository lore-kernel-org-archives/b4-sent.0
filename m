From: Ciprian Regus <ciprian.regus@analog.com>
Subject: [PATCH net-next v2 00/10] net: Add ADIN1140 support
Date: Wed, 27 May 2026 00:51:45 +0300
Message-Id: <20260527-adin1140-driver-v2-0-37e5c8d4e0a0@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPEVFmoC/2WNwQrCMBBEf6Xs2cgmqbV68j+kh9DdtguaSFJCp
 fTfDbl6m8cwb3ZIHIUT3JsdImdJEnwBc2pgXJyfWQkVBoOmw9bclCPxWreoKErmqG7WMZK9dlb
 3UFafyJNs1fgEz6vyvK0wlGaRtIb4rVdZ175aL2j/rFmrkglbOxL1/YQP590rzOcxvGE4juMHU
 edR9rkAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779832338; l=5877;
 i=ciprian.regus@analog.com; s=20260330; h=from:subject:message-id;
 bh=qkV3wqiPc1gtpJtbhMXrlyafax8/y9M8/g7Z6MlDhOU=;
 b=cmkxchONzMnbGnAMVlKNZCnrkikd8TFL0iz7in8o2Pl4GaMAePC9zkw2gKZqK1W+CxPvQTd6E
 LsKRcdEpmTNC8cB99GwnGT8Fdu07W5EuW8Qm1QDIVQetKpkJekSaBYM
X-Developer-Key: i=ciprian.regus@analog.com; a=ed25519;
 pk=8WoNhI0kQcQUl8YqJO5ZevROYk9HP8lOIeIgIYgjfbc=
X-Endpoint-Received: by B4 Relay for ciprian.regus@analog.com/20260330 with auth_id=703
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series introduces support for the ADIN1140 (also called AD3306)
10BASE-T1S single port MACPHY. The device integrates the MAC and PHY in
the same package. The communication with the host CPU is done through an
SPI interface, using the Open Alliance TC6 protocol for control and data
transactions. As a result, the oa_tc6 framework is used to implement
the communication with the device (register accesses and Ethernet frame
RX/TX).

The MAC and PHY are connected internally using an MII and MDIO bus.

The PHY is a half duplex 10Mbps device, which implements both the PLCA
RS (IEEE 802.3 clause 148) and CSMA/CD methods of accessing the Ethernet
medium. The 10BASE-T1S standard allows multiple PHY devices to be
connected (in parallel) on the same single twisted pair network segment,
so PLCA can be configured in order to provide a fair access scheme to
all the nodes and reduce the jitter introduced by the unordered CSMA/CD
transmits. The PHY's internal register map can be accessed using the
direct MDIO mode of the OA TC6. The control, status, phy id 1 & 2 C22
registers are mapped to the 0xFF00 - 0xFF03 range. As for C45
addressable devices, the PHY has PCS, PMA and PLCA blocks.

The oa_tc6 framework patches are changes that would make the library
usable by the subsequent ADIN1140 MAC driver.

The protected mode patch is required because the ADIN1140 only allows
protected mode OA TC6 control transactions, which the oa_tc6 framework
doesn't currently implement.

The OA_TC6_BROKEN_PHY quirk patch is required in order to allow the MAC
driver to have a custom implementation for the mii_bus access methods as a
workaround for hardware issues:

1. The OA TC6 standard defines the direct and indirect access modes for
   MDIO transactions. The ADIN1140 incorrectly advertises indirect mode
   only (supported capabilities register - 0x2, bit 9), while actually
   implementing just the direct mode. We cannot rely on the CAP register
   to choose an access method (which oa_tc6 does by default, even though
   it only implements the direct mode), so the driver has to use its
   own.
2. The ADIN1140 cannot access the C22 register space of the internal
   PHY, while the PHY is busy receiving frames. If that happens, the
   CONFIG0 and CONFIG2 registers of the MAC will get corrupted and the
   data transfer will stop. Those two registers configure settings for
   the transfer protocol between the MAC and host, so the value for some
   of their subfields shouldn't be changed while the netdev is up.
   Since we know the PHY is internal, the MAC driver can implement a
   custom mii_bus, which can intercept C22 accesses. Most of the
   registers mapped in the 0x0 - 0x3 range (the only ones the PHY offers)
   are read only, and their value can be read from somewhere else (e.g
   the PHYID 1 & 2 have the same value as 0x1 in the MAC memory map).
   C45 accesses do not cause this issue, so we can properly implement
   them.

Even though they have different driver, the MAC one cannot function
without the PHY driver, since the PHY is not compatible with the generic
c22 driver. As such CONFIG_ADIN1140 selects CONFIG_ADIN1140_PHY.

Signed-off-by: Ciprian Regus <ciprian.regus@analog.com>
---
Changes in v2:
- Add the OA_TC6_BROKEN_PHY quirk flag to the oa_tc6 framework in order
  to allow ethernet drivers to manage their own mii_bus struct and PHY.
- Move the OA TC6 standard register definitions in the oa_tc6.h header
  so other drivers can use them. Do the same for the C45 access
  functions
- Add the genphy_read_mmd_c45 and genphy_write_mmd_c45 functions to
  genphy, which allow drivers that have been discovered over C22 to make
  direct C45 operations, without using the 0xD and 0xE register. The
  change was implemented based on the suggestion in this thread:
  https://lore.kernel.org/all/CY8PR02MB9249CDA8F2C560FDD0F662D883382@CY8PR02MB9249.namprd02.prod.outlook.com/
- Link to v1: https://lore.kernel.org/r/20260503-adin1140-driver-v1-0-dd043cdd88f0@analog.com

---
Ciprian Regus (10):
      dt-bindings: net: Add ADIN1140
      net: ethernet: oa_tc6: Handle the OA TC6 SPI protected mode
      net: ethernet: oa_tc6: add OA_TC6_BROKEN_PHY quirk flag
      net: ethernet: oa_tc6: Export the C45 access functions
      net: ethernet: oa_tc6: Export standard defined registers
      net: ethernet: oa_tc6: Add MMS register formatting macro
      net: phy: add generic helpers for direct C45 MMD access
      net: phy: microchip-t1s: use generic C45 MMD access helpers
      net: phy: Add support for the ADIN1140 PHY
      net: ethernet: adi: Add a driver for the ADIN1140 MACPHY

 .../devicetree/bindings/net/adi,adin1140.yaml      |  69 ++
 Documentation/networking/oa-tc6-framework.rst      |   3 +-
 MAINTAINERS                                        |  15 +
 drivers/net/ethernet/adi/Kconfig                   |  12 +
 drivers/net/ethernet/adi/Makefile                  |   1 +
 drivers/net/ethernet/adi/adin1140.c                | 811 +++++++++++++++++++++
 drivers/net/ethernet/microchip/lan865x/lan865x.c   |   6 +-
 drivers/net/ethernet/oa_tc6.c                      | 202 ++---
 drivers/net/phy/Kconfig                            |   6 +
 drivers/net/phy/Makefile                           |   1 +
 drivers/net/phy/adin1140-phy.c                     |  72 ++
 drivers/net/phy/microchip_t1s.c                    |  32 +-
 drivers/net/phy/phy_device.c                       |  25 +
 include/linux/oa_tc6.h                             |  63 +-
 include/linux/phy.h                                |   3 +
 15 files changed, 1203 insertions(+), 118 deletions(-)
---
base-commit: b217a5c25fe4a5fdb63f57d028a88da470601f57
change-id: 20260429-adin1140-driver-93ae0d376318

Best regards,
-- 
Ciprian Regus <ciprian.regus@analog.com>

