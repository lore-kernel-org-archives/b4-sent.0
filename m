From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Subject: [PATCH net-next v5 00/15] Support for onsemi's S2500 10Base-T1S
 MAC-PHY
Date: Sun, 14 Jun 2026 10:00:16 -0700
Message-Id: <20260614-s2500-mac-phy-support-v5-0-89874b72f725@onsemi.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACHeLmoC/3WOOQ6DMBBFr4KmzkTGLFmq3COiADMER8K2PAaBE
 HePIWlTfv3l/RWYvCaGe7KCp0mztiaK4pSA6mvzItRt1CCFLEUpUmRZCIFDrdD1C/LonPUB8y6
 r6SZF11wyiF3nqdPzsfsEQwENzQGqr8Nj8yYV9tk922sO1i/HhSk/Gj9a8Yc25SiwpUhTaabK9
 vqwhmnQZ2UHqLZt+wBG+Vqq1wAAAA==
X-Change-ID: 20260601-s2500-mac-phy-support-4f3ae920fb73
To: Andrew Lunn <andrew@lunn.ch>, 
 Piergiorgio Beruto <pier.beruto@onsemi.com>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Selva Rajagopal <selvamani.rajagopal@onsemi.com>, 
 Richard Cochran <richardcochran@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org, 
 Jerry Ray <jerry.ray@microchip.com>, 
 Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781456462; l=5680;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=OB7aGFbniwE4XzaVoqPLH9T+eUI2xxGDdBfkp/BXjTM=;
 b=gUIWk4eWL9zySBQ+B52a6btsVB742eEdlROD1BExiktCpSDAG51pmrF/8EFwu8eZiDV9QANX7
 B5/+sN/ZgjvB17+68bu9PHVWC3bU0ZEZPX+zSS4eoRJRni25U4FHRNF
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series brings support for onsemi's S2500 that iss
IEEE 802.3cg compliant Ethernet transceiver with an integrated
Media Access Controller (MAC-PHY)

Driver implementation is compatible and works with OA TC6
framework that is already present. S2500 driver supports
hardware timestamping.

Driver has support for running selftest and loopback tests.
Through ethtool, it can provide traffic stats, rmon stats,
and timestamping related traffic stats.

As S2500 has an internal PHY, changes have been added
to onsemi's PHY driver to support this device.

---
Changes in v5:
 - kernel doc related changes in oa_tc.c, onsemi driver files and
  oa tc6 rst file
- Link to v4: https://lore.kernel.org/r/20260605-s2500-mac-phy-support-v4-0-de0fbc13c6d8@onsemi.com

Changes in v4:
 - Added return value comment for genphy_read/write_phy_mmd functions
 - Added genphy_loopback_fixed_speed helper function to be used in
   set_loopback callbacks
 - Updated networking documentation for OA TC6 framework to elaborate
   on what is expected in the ptp_clock_info structure for registration.
 - added spi-max-frequency in YAML file based on alert from sashiko-bot
 - Removed model/version from the onsemi driver's private structure as
   they were useful as "information-only" data.
 - Replaced the non-standard selftest with Linux's standard selftest
   and made it as a separate patch
 - Changed bit manipulation, shift operations to use macros so that
   it is clean and readable.
 - added new read_register and write_register apis with _mms postfix
   so that MMS (memory map selector) can be given as a parameter.
 - Fixed the wrong condition check with NETIF_F_RXFCS to subtract
   FCS size from the length of the frame.

To: Andrew Lunn <andrew@lunn.ch>
To: Piergiorgio Beruto <pier.beruto@onsemi.com>
To: Heiner Kallweit <hkallweit1@gmail.com>
To: Russell King <linux@armlinux.org.uk>
To: David S. Miller <davem@davemloft.net>
To: Eric Dumazet <edumazet@google.com>
To: Jakub Kicinski <kuba@kernel.org>
To: Paolo Abeni <pabeni@redhat.com>
To: Andrew Lunn <andrew+netdev@lunn.ch>
To: Parthiban Veerasooran <parthiban.veerasooran@microchip.com>
To: Selva Rajagopal <selvamani.rajagopal@onsemi.com>
To: Richard Cochran <richardcochran@gmail.com>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Simon Horman <horms@kernel.org>
To: Jonathan Corbet <corbet@lwn.net>
To: Shuah Khan <skhan@linuxfoundation.org>
Cc: netdev@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-doc@vger.kernel.org
Cc: Jerry Ray <jerry.ray@microchip.com>
Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

---
Selvamani Rajagopal (15):
      net: phy: Helper to read and write through C45 without lock
      net: phy: Helper to modify PHY loopback mode only
      net: ethernet: oa_tc6: Move oa_tc6.c to its own directory
      net: phy: microchip_t1s: Use generic APIs for C45 read and write
      net: ethernet: oa_tc6: Move constant definitions to header file
      net: ethernet: oa_tc6: Support for hardware timestamp
      net: ethernet: oa_tc6: Support for vendor specific MMS
      net: ethernet: oa_tc6: read, write interface with MMS option
      net: phy: ncn26000: Support for onsemi's S2500 internal phy
      net: phy: ncn26000: Enable enhanced noise immunity
      net: phy: ncn26000: Support for loopback
      onsemi: s2500: Add driver support for TS2500 MAC-PHY
      onsemi: s2500: Added selftest support to onsemi's S2500 driver
      dt-bindings: net: add onsemi's S2500
      Documentation: networking: Add timestamp related APIs to OA TC6 framework

 .../devicetree/bindings/net/onnn,s2500.yaml        |  67 +++
 Documentation/networking/oa-tc6-framework.rst      |  80 +++
 MAINTAINERS                                        |  13 +-
 drivers/net/ethernet/Kconfig                       |  12 +-
 drivers/net/ethernet/Makefile                      |   2 +-
 drivers/net/ethernet/microchip/lan865x/lan865x.c   |  61 +-
 drivers/net/ethernet/oa_tc6/Kconfig                |  16 +
 drivers/net/ethernet/oa_tc6/Makefile               |   7 +
 drivers/net/ethernet/{ => oa_tc6}/oa_tc6.c         | 465 +++++++++------
 drivers/net/ethernet/oa_tc6/oa_tc6_ptp.c           |  67 +++
 drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h       | 190 +++++++
 drivers/net/ethernet/oa_tc6/oa_tc6_tstamp.c        | 201 +++++++
 drivers/net/ethernet/onsemi/Kconfig                |  21 +
 drivers/net/ethernet/onsemi/Makefile               |   7 +
 drivers/net/ethernet/onsemi/s2500/Kconfig          |  22 +
 drivers/net/ethernet/onsemi/s2500/Makefile         |   7 +
 drivers/net/ethernet/onsemi/s2500/s2500_ethtool.c  | 354 ++++++++++++
 drivers/net/ethernet/onsemi/s2500/s2500_hw_def.h   | 225 ++++++++
 drivers/net/ethernet/onsemi/s2500/s2500_main.c     | 632 +++++++++++++++++++++
 drivers/net/ethernet/onsemi/s2500/s2500_ptp.c      | 233 ++++++++
 drivers/net/phy/dp83867.c                          |  11 +-
 drivers/net/phy/microchip_t1s.c                    |  32 +-
 drivers/net/phy/ncn26000.c                         |  63 +-
 drivers/net/phy/phy_device.c                       |  75 +++
 include/linux/oa_tc6.h                             |  36 ++
 include/linux/phy.h                                |   6 +
 26 files changed, 2655 insertions(+), 250 deletions(-)
---
base-commit: 2319688890d97c63da423a3c57c23b4ab5952dfc
change-id: 20260601-s2500-mac-phy-support-4f3ae920fb73

Best regards,
--  
Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

