From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Subject: [PATCH net-next v4 00/16] Support for onsemi's S2500 10Base-T1S
 MAC-PHY
Date: Fri, 05 Jun 2026 22:42:31 -0700
Message-Id: <20260605-s2500-mac-phy-support-v4-0-de0fbc13c6d8@onsemi.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEizI2oC/yWMQQrCMBAAv1L27MKa1Ip+RXpI48auYBqyaamU/
 t2ox2GY2UA5Cytcmw0yL6IyxQrtoQE/uvhglHtlMGQ66uiIak5E+HIe0/hGnVOacsE2WMcXQ2E
 4W6htyhxk/X1vELlg5LVA/zc6D0/25buFff8AyBajKoMAAAA=
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
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780724562; l=4265;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=dAOA6SjpWMVvSYsnDvoLrQBjwg5fA4k8JH4p1r9yoy4=;
 b=qx2oYI5fXg+6Xkpr6RmdC6IHzvzkJPrcyap4R79wuSo6V2yTXvPJ7/Ft/+2ho1SzwEcSVoylQ
 4NggIhtkOj1AxKzm+y5nlfHKs3s3PmqGrYVbuJoEKBzhZ4U/B0IcuO4
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series brings support for onsemi's S2500 that is IEEE 802.3cg
compliant Ethernet transceiver with an integrated Media Access
Controller (MAC-PHY)

Previous versions were submitted unthreaded, without coverletter
and changelog.

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

Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
---
Selvamani Rajagopal (16):
      net: phy: Helper to read and write through C45 without lock
      net: phy: Helper to modify PHY loopback mode only.
      net: ethernet: oa_tc6: Move oa_tc6.c to its own directory
      net: phy: microchip_t1s: Use generic APIs for C45 read and write
      net: ethernet: oa_tc6: Move constant definitions to header file
      net: ethernet: oa_tc6: Support for hardware timestamp
      net: ethernet: oa_tc6: Support for vendor specific MMS
      net: ethernet: oa_tc6: Remove FCS size in RX frame
      net: ethernet: oa_tc6: read, write interface with MMS option
      net: phy: ncn26000: Support for onsemi's S2500 internal phy
      net: phy: ncn26000: Enable enhanced noise immunity
      net: phy: ncn26000: Support for loopback support
      onsemi: s2500: Add driver support for TS2500 MAC-PHY
      onsemi: s2500: Added selftest support to onsemi's S2500 driver
      dt-bindings: net: add onsemi's S2500
      Documentation: networking: Add timestamp related APIs to OA TC6 framework

 .../devicetree/bindings/net/onnn,s2500.yaml        |  67 +++
 Documentation/networking/oa-tc6-framework.rst      |  76 +++
 MAINTAINERS                                        |  13 +-
 drivers/net/ethernet/Kconfig                       |  12 +-
 drivers/net/ethernet/Makefile                      |   2 +-
 drivers/net/ethernet/microchip/lan865x/lan865x.c   |  61 +-
 drivers/net/ethernet/oa_tc6/Kconfig                |  16 +
 drivers/net/ethernet/oa_tc6/Makefile               |   7 +
 drivers/net/ethernet/{ => oa_tc6}/oa_tc6.c         | 476 ++++++++++------
 drivers/net/ethernet/oa_tc6/oa_tc6_ptp.c           |  67 +++
 drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h       | 190 +++++++
 drivers/net/ethernet/oa_tc6/oa_tc6_tstamp.c        | 202 +++++++
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
 26 files changed, 2662 insertions(+), 251 deletions(-)
---
base-commit: 903db046d5579bef0ea699eae4b279dd6455fc9f
change-id: 20260601-s2500-mac-phy-support-4f3ae920fb73

Best regards,
-- 
Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

