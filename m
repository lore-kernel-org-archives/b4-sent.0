From: Ciprian Regus <ciprian.regus@analog.com>
Subject: [PATCH net-next v5 00/13] net: Add ADIN1140 support
Date: Wed, 08 Jul 2026 01:33:28 +0300
Message-Id: <20260708-adin1140-driver-v5-0-4aca7b51a58b@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALh+TWoC/2XQwY4CIQwG4FcxnJdNoSC4p30P4wFpVZJdxjATo
 jHz7hIuari1+dOvaR9i5pJ4Fj+bhyhc05ym3Br7tRHxEvKZZaLWCw16C0bvZKCUlTIgqaTKRe4
 wMBC6LSov2tS18CndurgXmReZ+baIQ0suaV6mcu+rqup5Vy3goFYlW01gMBJ5f4LfkMPfdP6O0
 3/Hqn4DtBsB3QB0bKMnwxBGAF9Au2wEsAGW+EhHVA6jGQDzDoyPqaYB4Cyy9swAn8C6rk/4PjQ
 8fAEAAA==
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
 Ciprian Regus <ciprian.regus@analog.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783463678; l=7828;
 i=ciprian.regus@analog.com; s=20260330; h=from:subject:message-id;
 bh=GKek7BKxQB7/xxzN++vZHwPvtziG5YW58YNpawvGyBs=;
 b=Z/jUDDxu4FoUgkngr88l/D/Q7DfRrjnKeHq5WdVUuZvzZJIcjxISuATxdQnZ/F80zbyfxVhfS
 vcOKFfqQW7TB/0x0WXA2tWx9hnajZoZ8joeMj6+K7jh8eoGIdPH5mrc
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
Changes in v5:
- Used ndo_set_rx_mode_async instead of ndo_set_rx_mode for configuring
  the MAC filter table in the adin1140 driver.
- Updated the MAC filter logic to allow setting individual
  unicast/multicast entries when IFF_ALLMULTI is enabled.
- Configured the MAC hardware to clear statistics registers on read and
  accumulated the values in the software stats counter.
- Removed some MAC statistics counters from the custom ethtool strings,
  since they were already included in the standard set.
- Link to v4: https://lore.kernel.org/r/20260609-adin1140-driver-v4-0-0753e28ee004@analog.com

Changes in v4:
- Renamed the dt bindings file after the adi,ad3306 compatible.
- Renamed a few register address macros to match the OA TC6 standard and
  the ADIN1140 reference manual.
- Link to v3: https://lore.kernel.org/r/20260604-adin1140-driver-v3-0-5debdb3173c4@analog.com

Changes in v3:
- Added adi,ad3306 as a fallback compatible in the DT schema.
- Keep the current spi_device and net_device parameters for
  oa_tc6_init() and add a new struct parameter for passing the quirk
  flags, insted of changing the function to take a single config
  parameter.
- Add the oa_tc6_write_register_mms() and oa_tc6_read_register_mms()
  functions instead of defining a new macro for MMS and register address
  formatting.
- Split the OA TC6 register address macro exports patch into two
  different commits (export + rename).
- Use the devres API for mii_bus and net_device management in the
  ADIN1140 driver.
- Fix a bug related to the destination MAC filter mask in the ADIN1140
  driver.
- Link to v2: https://lore.kernel.org/r/20260527-adin1140-driver-v2-0-37e5c8d4e0a0@analog.com

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
Ciprian Regus (13):
      dt-bindings: net: Add ADIN1140
      net: ethernet: oa_tc6: Handle the OA TC6 SPI protected mode
      net: ethernet: oa_tc6: add OA_TC6_BROKEN_PHY quirk flag
      net: ethernet: oa_tc6: Export the C45 access functions
      net: ethernet: oa_tc6: Export standard defined registers
      net: ethernet: oa_tc6: Add the OA_TC6_ prefix to standard registers
      net: ethernet: oa_tc6: Add read_mms/write_mms register access functions
      net: ethernet: oa_tc6: Use the read_mms/write_mms functions for C45
      net: ethernet: oa_tc6: Add new register address defines
      net: phy: add generic helpers for direct C45 MMD access
      net: phy: microchip-t1s: use generic C45 MMD access helpers
      net: phy: Add support for the ADIN1140 PHY
      net: ethernet: adi: Add a driver for the ADIN1140 MACPHY

 .../devicetree/bindings/net/adi,ad3306.yaml        |  71 ++
 Documentation/networking/oa-tc6-framework.rst      |   3 +-
 MAINTAINERS                                        |  15 +
 drivers/net/ethernet/adi/Kconfig                   |  12 +
 drivers/net/ethernet/adi/Makefile                  |   1 +
 drivers/net/ethernet/adi/adin1140.c                | 791 +++++++++++++++++++++
 drivers/net/ethernet/microchip/lan865x/lan865x.c   |   2 +-
 drivers/net/ethernet/oa_tc6.c                      | 263 ++++---
 drivers/net/phy/Kconfig                            |   6 +
 drivers/net/phy/Makefile                           |   1 +
 drivers/net/phy/adin1140-phy.c                     |  72 ++
 drivers/net/phy/microchip_t1s.c                    |  32 +-
 drivers/net/phy/phy_device.c                       |  25 +
 include/linux/oa_tc6.h                             |  73 +-
 include/linux/phy.h                                |   3 +
 15 files changed, 1240 insertions(+), 130 deletions(-)
---
base-commit: 538d89fd914610852a6fb20b823ba70566153d46
change-id: 20260429-adin1140-driver-93ae0d376318

Best regards,
-- 
Ciprian Regus <ciprian.regus@analog.com>

