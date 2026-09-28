From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Subject: [PATCH net-next v8 00/11] Support for onsemi's S2500 10Base-T1S
 MAC-PHY
Date: Mon, 28 Sep 2026 15:25:07 -0700
Message-Id: <20260928-s2500-mac-phy-support-v8-0-7e011aacc309@onsemi.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAETpumoC/3XOQW7DIBAF0KtErEsFGBjIqveossB4XFPJxgJiJ
 Yp89xC3UlNFXo5m/vtzIxlTwEyOhxtJuIQc4lQH83YgfnDTF9LQ1ZkIJjTTjNMsFGN0dJ7Ow5X
 m8zzHVKjsG4dWsL6FhtTsnLAPl839JBMWOuGlkNPPJp/bb/TlwT5uh5BLTNfthUVuid82tdO2S
 Mpoh7XN88brznzEKeMY3n0ct5JFPTFc7jGqMsYakC2IHoR6YfQTI+weoyvDjUewdd0Af2HgjwF
 m9hiojATjDYBz3Nl/zLqud+IRRgusAQAA
To: Selva Rajagopal <selvamani.rajagopal@onsemi.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Piergiorgio Beruto <pier.beruto@onsemi.com>, 
 Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Simon Horman <horms@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Richard Cochran <richardcochran@gmail.com>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>
Cc: Selva Rajagopal <Selvamani.Rajagopal@onsemi.com>, 
 netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Jerry Ray <jerry.ray@microchip.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790634319; l=7343;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=HpAtu+Uu1G28gcAvxis3+zp2rYzH8YHQG1YoXSH96cU=;
 b=B1+61qDvpUTsBDBUxt5BtliF10m6v4djcVlWqcj7Fnd/LfG6uJcxQzvImldVZ4VXh0COnvX6Q
 jFgghCIUuT9DCGjOFF3EqybwICn1NffpmjGnCrj5LgvU3sWqIKQM/WN
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series brings support for onsemi's S2500 that iss
IEEE 802.3cg compliant Ethernet transceiver with an integrated
Media Access Controller (MAC-PHY)

Driver implementation is compatible and works with OA TC6
framework that is already present. S2500 driver supports
hardware timestamping. Along with this driver, OA TC6
frame work is also changed to add hardware timestamping
support.

Driver has support for running selftest and loopback tests.
Through ethtool, it can provide traffic stats, rmon stats,
and timestamping related traffic stats.

As S2500 has an internal PHY, changes have been added
to onsemi's PHY driver to support this device.

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
To: Randy Dunlap <rdunlap@infradead.org>
Cc: netdev@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-doc@vger.kernel.org
Cc: Jerry Ray <jerry.ray@microchip.com>
Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

Changes in v8:
- Modified to use newer MMD based read/write APIs
- clean up by removing unused definitions/initializations
- Better handling of timestamp capture events by using
  bit fields so that we don't lose any event
- timestamp skb queue is protected with spinlock
- added reset-gpio in YAML file as support is recently added
- removed ioctl from OA TC6 framework as it is not needed.

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

---
Selvamani Rajagopal (11):
      dt-bindings: net: add onsemi's S2500
      Documentation: networking: Add timestamp related APIs to OA TC6 framework
      net: ethernet: oa_tc6: Move oa_tc6.c to its own directory
      net: ethernet: oa_tc6: Move constant definitions to header file
      net: ethernet: oa_tc6: Support for hardware timestamp
      net: ethernet: oa_tc6: Support for vendor specific MMS
      net: phy: ncn26000: Support for onsemi's S2500 internal phy
      net: phy: ncn26000: Enable enhanced noise immunity
      net: phy: ncn26000: Support for loopback
      onsemi: s2500: Add driver support for S2500 MAC-PHY
      onsemi: s2500: Added selftest support to onsemi's S2500 driver

 .../devicetree/bindings/net/onnn,s2500.yaml        |  72 +++
 Documentation/networking/oa-tc6-framework.rst      |  59 +++
 MAINTAINERS                                        |  13 +-
 drivers/net/ethernet/Kconfig                       |  13 +-
 drivers/net/ethernet/Makefile                      |   3 +-
 drivers/net/ethernet/adi/Kconfig                   |   1 +
 drivers/net/ethernet/microchip/lan865x/Kconfig     |   1 +
 drivers/net/ethernet/oa_tc6/Kconfig                |  17 +
 drivers/net/ethernet/oa_tc6/Makefile               |   7 +
 drivers/net/ethernet/{ => oa_tc6}/oa_tc6.c         | 433 ++++++++++++-----
 drivers/net/ethernet/oa_tc6/oa_tc6_ptp.c           |  65 +++
 drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h       | 161 +++++++
 drivers/net/ethernet/oa_tc6/oa_tc6_tstamp.c        | 224 +++++++++
 drivers/net/ethernet/onsemi/Kconfig                |  22 +
 drivers/net/ethernet/onsemi/Makefile               |   7 +
 drivers/net/ethernet/onsemi/s2500/Kconfig          |  21 +
 drivers/net/ethernet/onsemi/s2500/Makefile         |   7 +
 drivers/net/ethernet/onsemi/s2500/s2500_ethtool.c  | 375 +++++++++++++++
 drivers/net/ethernet/onsemi/s2500/s2500_hw_def.h   | 160 +++++++
 drivers/net/ethernet/onsemi/s2500/s2500_main.c     | 523 +++++++++++++++++++++
 drivers/net/ethernet/onsemi/s2500/s2500_ptp.c      | 174 +++++++
 drivers/net/phy/dp83867.c                          |  11 +-
 drivers/net/phy/ncn26000.c                         |  63 ++-
 drivers/net/phy/phy_device.c                       |  20 +
 include/linux/oa_tc6.h                             |  25 +
 include/linux/phy.h                                |   2 +
 26 files changed, 2331 insertions(+), 148 deletions(-)
---
base-commit: 014d795c73837ea2339a4ea8e8f82c6e959b845d
change-id: 20260601-s2500-mac-phy-support-4f3ae920fb73

Best regards,
-- 
Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

