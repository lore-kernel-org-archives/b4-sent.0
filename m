From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Subject: [PATCH net-next v12 00/15] Support for onsemi's S2500 10BASE-T1S
 MAC-PHY
Date: Tue, 24 Nov 2026 14:09:48 -0800
Message-Id: <20261124-s2500-mac-phy-support-v12-0-3575855d99f9@onsemi.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAC0LBmsC/3XRS27DIBAG4KtUrEs1A+bVVe9RdQF43FAptmUcK
 1GUuxe7VZPKYgnDfD8DV5ZpSpTZ69OVTbSknIa+LFA8P7F48P0n8dSWDSZAaNCAPAsFwI8+8vF
 w4fk0jsM086aTnpyALhjJSu84UZfOG/zOepp5T+eZffxU8il8UZxXdj17SHkepst2h6XZOn7TV
 CVtaTjwlkpaRBl1a9+GPtMxvcThuIUs6oHBpsaowlhnTROM6IxQO0Y/MMLVGF0YtJGMK2VpcMe
 YO2PA1hhTmMbYaI3xHr3bMfbOOFFlbGEMAaL3MUrYM+6PQYDqUG594kgdYQuhg3bHINwdBF1zE
 AokMSivXbAqmD2EDxDKKoTrYB5t+VB0SsR/0O12+wYfcqeHzQIAAA==
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Selva Rajagopal <selvamani.rajagopal@onsemi.com>, 
 Richard Cochran <richardcochran@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Eric Dumazet <edumazet@kernel.org>, 
 Piergiorgio Beruto <piergiorgio.beruto@gmail.com>, 
 Eric Dumazet <edumazet@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org, 
 Jerry Ray <jerry.ray@microchip.com>, 
 Ciprian Regus <ciprian.regus@analog.com>, 
 Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795558193; l=10232;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=Xsdx3629A/Jol/9s0osfmNOcTlbJxOJ8u7SwaA3F1LE=;
 b=UR/3qePJUR729WLijzQ1jW+RapkA/21f7sdgTnhyAF4pFEyIpA7MTKZBhtSp65IystGC2BQjN
 +4FDvmh7kowCw9bh9dZzgpzvUN0k1f+tVCi/1MFnjNBqo8gualKxrzh
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series brings support for onsemi's S2500, an
IEEE 802.3cg compliant 10BASE-T1S Ethernet transceiver with an
integrated Media Access Controller (MAC-PHY).

The driver works with the OA TC6 framework that is already
present, and supports hardware timestamping. The framework gets
hardware timestamp support, a quirk to map MDIO_MMD_VEND1 to a
vendor MMS, an API to set the TX credit threshold, an RX
cut-through quirk and handling of the frame drop (FD) bit. It
also moves to its own directory. A device tree binding is added
and the framework documentation is updated.

Through ethtool, the driver provides a register dump, MAC, PHY
and RMON statistics, timestamp statistics and self-test,
including PHY loopback.

As S2500 has an internal PHY, onsemi's PHY driver is extended to
support it. A new PHY core helper, genphy_loopback_no_speed(), is
added for its loopback and is also used by the dp83867 driver.

Changes to the current behavior:
- NCN26000: enhanced noise immunity (ENI) is now enabled and
  disabled together with PLCA.
- OA TC6 framework users: frames flagged with FD are dropped,
  received frames shorter than an Ethernet header are dropped,
  and drivers selecting OA_TC6 now depend on PTP_1588_CLOCK_OPTIONAL

Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
---
Changes in v12:
- Map MDIO_MMD_VEND1 to vendor MMS through a quirk parameter in oa_tc6_init
- Do not drop a TX frame when no timestamp capture register is free, send
  it without a timestamp and count an error
- Fix races in timestamp configuration and in interface down handling
- Link to v11: https://lore.kernel.org/r/20261113-s2500-mac-phy-support-v11-0-7a186141952c@onsemi.com

Changes in v11:
- Create new patches to move vendor changes to its own patch
- Improve commit message to be more informative of the changes
- Add clarity to kernel documentation in oa-tc6-framework.rst
- Fix issues potential Oops issue in S2500 driver.
- Add logic to take care of frame drop bit from MAC-PHY 
- Link to v10: https://lore.kernel.org/r/20261106-s2500-mac-phy-support-v10-0-31b5a69b85b7@onsemi.com

Changes in v10:
 - Removed config_intr callback in S2500 PHY driver
 - Removed writing status0/config0 from s2500 driver
 - Implemented API to set tx credit threshold and 
   to enable RX cut-through mode
 - Drop the frame when frame drop bit in footer is set
 - Module name restored back to oa_tc6.ko from oa_tc6_mod.ko
- Link to v9: https://lore.kernel.org/r/20261009-s2500-mac-phy-support-v9-0-dcefe1d0bf0d@onsemi.com

Changes in v9:
- Renamed the new phy API from having "fixed_speed" to "no_speed"
- Fixed compilation issue due to having changes in the wrong patch
- Added the MAINTAINERS changes to where files were introduced.
- Fixed coding style issues reported.
- Moved the order of patches so that selftest changes goes after
  s2500 support.
- Made Pier's email ID consistent across to be consistent across 
  the codebase.

- Link to v8: https://lore.kernel.org/r/20260928-s2500-mac-phy-support-v8-0-7e011aacc309@onsemi.com

Changes in v8:
- Modified to use newer MMD based read/write APIs
- clean up by removing unused definitions/initializations
- Better handling of timestamp capture events by using
  bit fields so that we don't lose any event
- timestamp skb queue is protected with spinlock
- added reset-gpio in YAML file as support is recently added
- removed ioctl from OA TC6 framework as it is not needed.

- Link to v7: https://lore.kernel.org/all/20260708-s2500-mac-phy-support-v7-0-478c877aa1a9@onsemi.com

Changes in v7:
- Fixed compiler warning due to prototype mismatch
- Moved the order of patches to ensure dt-bindings comes first
  before it is being used
- Added missing review tag
- Added missing MODULE_DEVICE_TABLE
- OA_TC6 framework enables 64 bit timestamping mode by default.

- Compiler related warnings fixed.
- Link to v6: https://lore.kernel.org/r/20260629-s2500-mac-phy-support-v6-0-18ce79500371@onsemi.com

Changes in v6:
- Changes to ensure onsemi code stay within 80 columns.
- Fixed the error of "not described in comments section"
  in comments section.

- Fixed compiler warnings.
- Link to v5: https://patch.msgid.link/20260614-s2500-mac-phy-support-v5-0-89874b72f725@onsemi.com

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
 - Link to v3: https://lore.kernel.org/r/CY8PR02MB92499C9080614FA3CEB8CD0483162@CY8PR02MB9249.namprd02.prod.outlook.com

Changes in v3:
 - Moved OA TC6 framework to its own directory.
 - Split changes to smaller patches based on feedback.
 - Added PHY loopback support as a separate patch.
 - New, read and write register APIs with extra parameter MMS
 - Link to v2: https://lore.kernel.org/r/CY8PR02MB924920C8825C7AE5D22EFA4483382@CY8PR02MB9249.namprd02.prod.outlook.com

Changes in v2:
 - API to add vendor specific MMS to mdio device map.
 - Link to v1: https://lore.kernel.org/r/CY8PR02MB9249D083B637477C254F9B0583322@CY8PR02MB9249.namprd02.prod.outlook.com

To: Selva Rajagopal <selvamani.rajagopal@onsemi.com>
To: Andrew Lunn <andrew+netdev@lunn.ch>
To: David S. Miller <davem@davemloft.net>
To: Eric Dumazet <edumazet@google.com>
To: Jakub Kicinski <kuba@kernel.org>
To: Paolo Abeni <pabeni@redhat.com>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Parthiban Veerasooran <parthiban.veerasooran@microchip.com>
To: Simon Horman <horms@kernel.org>
To: Jonathan Corbet <corbet@lwn.net>
To: Shuah Khan <skhan@linuxfoundation.org>
To: Randy Dunlap <rdunlap@infradead.org>
To: Richard Cochran <richardcochran@gmail.com>
To: Andrew Lunn <andrew@lunn.ch>
To: Heiner Kallweit <hkallweit1@gmail.com>
To: Russell King <linux@armlinux.org.uk>
To: Eric Dumazet <edumazet@kernel.org>
To: Piergiorgio Beruto <piergiorgio.beruto@gmail.com>
Cc: Selva Rajagopal <Selvamani.Rajagopal@onsemi.com>
Cc: netdev@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: linux-doc@vger.kernel.org

---
Selvamani Rajagopal (15):
      dt-bindings: net: add onsemi's S2500
      Documentation: networking: Add timestamp related APIs to OA TC6 framework
      net: ethernet: oa_tc6: Move oa_tc6.c to its own directory
      net: ethernet: oa_tc6: Move constant definitions to header file
      net: ethernet: microchip: lan865x: Depends on PTP_1588_CLOCK_OPTIONAL
      net: ethernet: adi: adin1140: Depends on PTP_1588_CLOCK_OPTIONAL
      net: ethernet: oa_tc6: Support for hardware timestamp
      net: ethernet: oa_tc6: Drop frames if footer has FD bit set
      net: ethernet: oa_tc6: Support for vendor specific MMS
      net: ethernet: oa_tc6: APIs to customize CONFIG0 settings
      net: phy: ncn26000: Enable enhanced noise immunity
      net: phy: Add helper to modify only the PHY loopback bit
      net: phy: ncn26000: Support for onsemi's S2500 internal phy
      net: phy: dp83867: Use genphy_loopback_no_speed()
      net: ethernet: onsemi: s2500: Add driver support for S2500

 .../devicetree/bindings/net/onnn,s2500.yaml        |  71 +++
 Documentation/networking/oa-tc6-framework.rst      | 113 ++++-
 MAINTAINERS                                        |  11 +-
 drivers/net/ethernet/Kconfig                       |  13 +-
 drivers/net/ethernet/Makefile                      |   3 +-
 drivers/net/ethernet/adi/Kconfig                   |   1 +
 drivers/net/ethernet/microchip/lan865x/Kconfig     |   1 +
 drivers/net/ethernet/oa_tc6/Kconfig                |  16 +
 drivers/net/ethernet/oa_tc6/Makefile               |   7 +
 .../ethernet/{oa_tc6.c => oa_tc6/oa_tc6_main.c}    | 561 ++++++++++++++++-----
 drivers/net/ethernet/oa_tc6/oa_tc6_ptp.c           |  68 +++
 drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h       | 186 +++++++
 drivers/net/ethernet/oa_tc6/oa_tc6_tstamp.c        | 304 +++++++++++
 drivers/net/ethernet/onsemi/Kconfig                |  21 +
 drivers/net/ethernet/onsemi/Makefile               |   6 +
 drivers/net/ethernet/onsemi/s2500/Kconfig          |  20 +
 drivers/net/ethernet/onsemi/s2500/Makefile         |   6 +
 drivers/net/ethernet/onsemi/s2500/s2500_ethtool.c  | 389 ++++++++++++++
 drivers/net/ethernet/onsemi/s2500/s2500_hw_def.h   | 165 ++++++
 drivers/net/ethernet/onsemi/s2500/s2500_main.c     | 496 ++++++++++++++++++
 drivers/net/ethernet/onsemi/s2500/s2500_ptp.c      | 156 ++++++
 drivers/net/phy/Kconfig                            |   2 +-
 drivers/net/phy/dp83867.c                          |  11 +-
 drivers/net/phy/ncn26000.c                         |  68 ++-
 drivers/net/phy/phy_device.c                       |  24 +
 include/linux/oa_tc6.h                             |  33 ++
 include/linux/phy.h                                |   2 +
 27 files changed, 2602 insertions(+), 152 deletions(-)
---
base-commit: c2621b518b38ed38e280e008aa33e6c2d302f8cc
change-id: 20260601-s2500-mac-phy-support-4f3ae920fb73

Best regards,
-- 
Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

