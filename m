From: Luca Lauro <famlauro93l@gmail.com>
Subject: [PATCH v3 00/15] ARM: mvebu: add Netgear RN102/RN104 support and
 related drivers
Date: Sun, 02 Aug 2026 15:16:16 +0200
Message-Id: <20260802-rn102-rn104-series-v3-0-f7685a279fb5@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIACBDb2oC/32NQQ7CIBREr9KwFgPUUurKexgXBT4txlIDlWia3
 l1oN10YN5O8ZObNjAJ4CwGdixl5iDbY0SUoDwVSfes6wFYnRowwTmpWYu8oYWue8LbFmnMBkjS
 aGIPS8OnB2Pcqvd42Di95BzVlU270Nkyj/6yvkebe34NIMcE1b4RmlTaC80s3tPZxVOOA8kFke
 4X4qWBJ0UJJTVXJWiqxVyzL8gXbpu45CQEAAA==
X-Change-ID: 20260723-rn102-rn104-series-d668eb09d0ff
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 "open list:BAREBOX" <barebox@lists.infradead.org>
Cc: Luca Lauro <famlauro93l@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785676613; l=4441;
 i=famlauro93l@gmail.com; s=20260723; h=from:subject:message-id;
 bh=LmiGkzBFnVrjE+essPAZ9Fwjyu54plXBA9CNDLfWgmU=;
 b=tTMOXYCQYugCzl95+ncpiDBSQyrHCVXkpBOiDkKGSrIz53tpMZyGh8mXpGlyZw7L+7OaWG7RD
 bIb3b1WRyw8CcNqSwb1USdFW9xj/H+eplOx6lyQNQaddFjS8rEYkd2v
X-Developer-Key: i=famlauro93l@gmail.com; a=ed25519;
 pk=OAJlcD69ugQCl99Vy6w+Aeu+ZUb1IVGcz1Ijxo6Ch78=
X-Endpoint-Received: by B4 Relay for famlauro93l@gmail.com/20260723 with auth_id=892
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds full barebox support for the Netgear RN102 and RN104
NAS platforms based on the Marvell Armada 370 SoC. Both devices share
the same hardware architecture, differing mainly in the number of drive
bays and board‑level integration.

The series introduces:
 - lowlevel initialization code for RN102 and RN104
 - board support files and environment integration
 - barebox‑specific device tree overlays for both platforms
 - image generation support and defconfig updates
 - fan controller subsystem and G76x driver
 - fan control command and Kconfig/Makefile integration
 - Marvell‑specific EHCI host controller driver
 - USB/EHCI fixes
 - ATA/AHCI improvements

The goal is to provide complete bootloader support for these NAS
devices, enabling reliable initialization of storage, USB, fan control,
and board‑specific peripherals. The patches have been tested on RN102.

Changes in v3:
 - cleaned up whitespace and indentation issues
 - squashed fan command integration into a single commit
 - removed noisy or unrelated changes
 - improved commit messages and structure

Link to v2:
https://patch.msgid.link/20260728-rn102-rn104-series-v2-0-ae31f55b7bc8@gmail.com

Signed-off-by: Luca Lauro <famlauro93l@gmail.com>

---
Luca Lauro (15):
      ARM: mvebu: add Netgear RN102 support
      ARM: mvebu: enable RN102 in mvebu_defconfig
      ARM: mvebu: improve Netgear RN104 support
      ARM: mvebu: rename PUTC_LL to MVEBU_PUTC_LL
      drivers: fan: add fan subsystem, core API and G76x fan controller driver
      commands: add fan control command
      usb: ehci: add Marvell EHCI host controller driver
      usb: ehci: initialize periodic_queue_dma
      ata: ahci: add PCI AHCI and Marvell 9170 controller support
      ata: ahci: fix zero-length DMA handling
      ata: ahci: add helper for ATA commands without data
      ata: ahci: improve AHCI port bring-up sequence
      ata: ahci: add FLUSH EXT and STANDBY IMMEDIATE support during shutdown
      ata: ahci: add shutdown helpers for AHCI controllers
      ata: ahci: cleanup legacy code and remove unused paths

 arch/arm/boards/Makefile                   |    1 +
 arch/arm/boards/netgear-rn102/Makefile     |    4 +
 arch/arm/boards/netgear-rn102/board.c      |  243 ++++++
 arch/arm/boards/netgear-rn102/lowlevel.c   |   58 ++
 arch/arm/boards/netgear-rn104/Makefile     |    1 +
 arch/arm/boards/netgear-rn104/board.c      |  182 +++++
 arch/arm/boards/netgear-rn104/lowlevel.c   |   37 +-
 arch/arm/configs/mvebu_defconfig           |    1 +
 arch/arm/dts/Makefile                      |    1 +
 arch/arm/dts/armada-370-rn102-bb.dts       |   82 ++
 arch/arm/dts/armada-370-rn104-bb.dts       |   73 +-
 arch/arm/mach-mvebu/Kconfig                |    4 +
 commands/Kconfig                           |    7 +
 commands/Makefile                          |    2 +
 commands/fan.c                             |  286 +++++++
 drivers/Kconfig                            |    1 +
 drivers/Makefile                           |    1 +
 drivers/ata/ahci.c                         |  429 ++++++----
 drivers/ata/ahci.h                         |    1 +
 drivers/fan/Kconfig                        |   35 +
 drivers/fan/Makefile                       |    8 +
 drivers/fan/fan.c                          |  180 +++++
 drivers/fan/i2c_fan_controllers/Kconfig    |    6 +
 drivers/fan/i2c_fan_controllers/Makefile   |    5 +
 drivers/fan/i2c_fan_controllers/g76x.c     | 1185 ++++++++++++++++++++++++++++
 drivers/fan/other_fan_controllers/Kconfig  |    7 +
 drivers/fan/other_fan_controllers/Makefile |    3 +
 drivers/fan/spi_fan_controllers/Kconfig    |    1 +
 drivers/fan/spi_fan_controllers/Makefile   |    3 +
 drivers/usb/host/Kconfig                   |    7 +
 drivers/usb/host/Makefile                  |   13 +-
 drivers/usb/host/ehci-hcd.c                |    7 +-
 drivers/usb/host/ehci-marvell.c            |  228 ++++++
 images/Makefile.mvebu                      |   13 +-
 include/fan/fan.h                          |   94 +++
 include/fan/i2c_fan_controllers/g76x.h     |   37 +
 include/mach/mvebu/debug_ll.h              |    2 +-
 37 files changed, 3064 insertions(+), 184 deletions(-)
---
base-commit: f9cc366e5b67680473e4ab7837eeb27bf1b5a567
change-id: 20260723-rn102-rn104-series-d668eb09d0ff

Best regards,
--  
Luca Lauro <famlauro93l@gmail.com>

