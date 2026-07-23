From: Luca Lauro <famlauro93l@gmail.com>
Subject: [PATCH 00/19] ARM: mvebu: add Netgear RN102/RN104 support and
 related drivers
Date: Thu, 23 Jul 2026 15:57:38 +0200
Message-Id: <20260723-rn102-rn104-series-v1-0-7698d25df866@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANMdYmoC/yWMyw5AMBAAf0X2rMkqqceviAO6ZR1KWkTS+HfFZ
 ZI5zATw5Jg8NEkARyd7Xm2ULE1gnHs7kWAdHSRKhaXMhbMZyo+F+FuhlapowFqjMRDDzZHh65u
 23e/+GBYa9/cE9/0APg1Ri3YAAAA=
X-Change-ID: 20260723-rn102-rn104-series-d668eb09d0ff
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 "open list:BAREBOX" <barebox@lists.infradead.org>
Cc: Luca Lauro <famlauro93l@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784815061; l=4603;
 i=famlauro93l@gmail.com; s=20260723; h=from:subject:message-id;
 bh=IglEVpr8truAqAYGrx5gD4CwPENqWf02m5FMJQ9nkLM=;
 b=L/rI4hACLoXK4la8mDDw0rWeikJ/8nrBlfWdYD2oorx1Zn00J01vp7oZJA6IK450OJTlGZE9V
 nhxVLXoSR88BnF6O3+K2a1wwlxybCpZfYMx2pBmJRrLLYCPWl6n7uOO
X-Developer-Key: i=famlauro93l@gmail.com; a=ed25519;
 pk=OAJlcD69ugQCl99Vy6w+Aeu+ZUb1IVGcz1Ijxo6Ch78=
X-Endpoint-Received: by B4 Relay for famlauro93l@gmail.com/20260723 with auth_id=892
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds full barebox support for the Netgear RN102 and RN104
NAS platforms based on the Marvell Armada 370 SoC. Both devices share
the same hardware architecture, with differences mainly in the number
of drive bays and the associated board-level integration.

The series introduces:
 - lowlevel initialization code for RN102 and RN104
 - board support files and environment integration
 - barebox-specific device trees for both platforms
 - image generation support and defconfig updates
 - fan controller framework and G76x driver
 - fan control command and Kconfig/Makefile integration
 - Marvell-specific EHCI host controller driver
 - AHCI/SATA fixes improving compatibility with Armada 370
 - USB/AHCI integration updates

The goal is to provide complete bootloader support for these NAS
devices, enabling reliable initialization of storage, USB, fan control,
and board-specific peripherals. The patches have been tested on
RN102 only.

Signed-off-by: Luca Lauro <famlauro93l@gmail.com>

---
Luca Lauro (19):
      ARM: mvebu: add board support for Netgear RN102
      ARM: mvebu: add lowlevel support for Netgear RN102
      ARM: dts: add barebox device tree for Netgear RN102
      ARM: dts: update RN102 Linux DTS
      ARM: mvebu: add Kconfig entry for Netgear RN102
      ARM: mvebu: add RN102 image support
      ARM: mvebu: enable RN102 in mvebu_defconfig
      ARM: mvebu: rn104: placeholder bay management
      ARM: mvebu: add lowlevel support for Netgear RN104
      ARM: dts: update RN104 Linux DTS
      ARM: mvebu: adapt RN104 image support
      ARM: mvebu: rename PUTC_LL to MVEBU_PUTC_LL
      drivers: fan: add fan framework and API
      commands: add fan control command
      commands: integrate fan command into Kconfig and Makefile
      usb: ehci: add Marvell EHCI host controller driver
      usb: ehci: minor fixes for Marvell compatibility
      ata: ahci: fixes and updates for Marvell SATA controller
      drivers: integrate USB/AHCI changes

 arch/arm/boards/Makefile                         |    1 +
 arch/arm/boards/netgear-rn102/Makefile           |    4 +
 arch/arm/boards/netgear-rn102/board.c            |  243 +++++
 arch/arm/boards/netgear-rn102/lowlevel.c         |   49 +
 arch/arm/boards/netgear-rn104/board.c            |  193 ++++
 arch/arm/boards/netgear-rn104/lowlevel.c         |   43 +-
 arch/arm/configs/mvebu_defconfig                 |    1 +
 arch/arm/dts/Makefile                            |    1 +
 arch/arm/dts/armada-370-rn102-bb.dts             |   13 +
 arch/arm/mach-mvebu/Kconfig                      |    4 +
 commands/Kconfig                                 |    7 +
 commands/Makefile                                |    2 +
 commands/fan.c                                   |  286 ++++++
 drivers/Kconfig                                  |    1 +
 drivers/Makefile                                 |    1 +
 drivers/ata/ahci.c                               |  656 ++++++------
 drivers/ata/ahci.h                               |    1 +
 drivers/fan/Kconfig                              |   35 +
 drivers/fan/Makefile                             |    8 +
 drivers/fan/fan.c                                |  180 ++++
 drivers/fan/i2c_fan_controllers/Kconfig          |    6 +
 drivers/fan/i2c_fan_controllers/Makefile         |    5 +
 drivers/fan/i2c_fan_controllers/g76x.c           | 1184 ++++++++++++++++++++++
 drivers/fan/other_fan_controllers/Kconfig        |    7 +
 drivers/fan/other_fan_controllers/Makefile       |    3 +
 drivers/fan/spi_fan_controllers/Kconfig          |    1 +
 drivers/fan/spi_fan_controllers/Makefile         |    3 +
 drivers/usb/host/Kconfig                         |    7 +
 drivers/usb/host/Makefile                        |   13 +-
 drivers/usb/host/ehci-hcd.c                      |   22 +-
 drivers/usb/host/ehci-marvell.c                  |  229 +++++
 dts/src/arm/marvell/armada-370-netgear-rn102.dts |  114 ++-
 dts/src/arm/marvell/armada-370-netgear-rn104.dts |  173 ++--
 images/Makefile.mvebu                            |   13 +-
 include/fan/fan.h                                |   94 ++
 include/fan/i2c_fan_controllers/g76x.h           |   37 +
 include/mach/mvebu/debug_ll.h                    |    2 +-
 rebuild-series.sh                                |   39 +
 38 files changed, 3257 insertions(+), 424 deletions(-)
---
base-commit: d6c5023bc58092b15a0cd8c01f708480efb26640
change-id: 20260723-rn102-rn104-series-d668eb09d0ff

Best regards,
--  
Luca Lauro <famlauro93l@gmail.com>

