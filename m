From: Ciprian Regus <ciprian.regus@analog.com>
Subject: [PATCH net-next 0/5] net: Add ADIN1140 support
Date: Sun, 03 May 2026 02:24:49 +0300
Message-Id: <20260503-adin1140-driver-v1-0-dd043cdd88f0@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMGH9mkC/x3MSwqDQBBF0a1IjS3oj/jbimTQpF9iTUqpFhHEv
 afJ8AzuvanABIXm5ibDKUU2rfBtQ+816RcsuZqCC73rwsQpi3rfOc4mJ4ynmOByHProR6rVbvj
 I9T8upDhYcR30ep4fRQP+YWsAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777764335; l=4571;
 i=ciprian.regus@analog.com; s=20260330; h=from:subject:message-id;
 bh=/W92qVR03CbZRW8UHk+eSWnYxaVea1W7O/eNRCZFrvU=;
 b=9I5lCGeJwQ9U+jGD0xmD1gwarv3Gl44zOKfWaLZYM3N8pEDydrjZYK0E0Ox5CF7T+bz7356b+
 1+XrxzC/yGqDm09arGzec4f0OJlkwgthto3HkJGoD1O7xbsyBcWzdbc
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

The first 2 patches in the series are changes to the oa_tc6, that would
make the framework usable by the subsequent ADIN1140 MAC driver.

The first commit is required because the ADIN1140 only allows protected
mode OA TC6 control transactions, which the oa_tc6 framework doesn't
currently implement.

The second commit is required in order to allow the MAC driver to have a
custom implementation for the mii_bus access methods as a workaround for
hardware issues:

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
Ciprian Regus (5):
      net: ethernet: oa_tc6: Handle the OA TC6 SPI protected mode
      net: ethernet: oa_tc6: Allow custom mii_bus
      net: phy: Add support for the ADIN1140 PHY
      net: ethernet: adi: Add a driver for the ADIN1140 MACPHY
      dt-bindings: net: Add bindings for the ADIN1140

 .../devicetree/bindings/net/adi,adin1140.yaml      |  69 ++
 Documentation/networking/oa-tc6-framework.rst      |   3 +-
 MAINTAINERS                                        |  15 +
 drivers/net/ethernet/adi/Kconfig                   |  12 +
 drivers/net/ethernet/adi/Makefile                  |   1 +
 drivers/net/ethernet/adi/adin1140.c                | 805 +++++++++++++++++++++
 drivers/net/ethernet/microchip/lan865x/lan865x.c   |   6 +-
 drivers/net/ethernet/oa_tc6.c                      | 194 +++--
 drivers/net/phy/Kconfig                            |   6 +
 drivers/net/phy/Makefile                           |   1 +
 drivers/net/phy/adin1140.c                         | 102 +++
 include/linux/oa_tc6.h                             |   9 +-
 12 files changed, 1173 insertions(+), 50 deletions(-)
---
base-commit: fbf6f64a4322cfeb0d98f39baf8ce18246dd12c0
change-id: 20260429-adin1140-driver-93ae0d376318

Best regards,
-- 
Ciprian Regus <ciprian.regus@analog.com>

