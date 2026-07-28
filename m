From: Luca Lauro <famlauro93l@gmail.com>
Subject: [PATCH v2 00/10] ARM: mvebu: add Netgear RN102/RN104 support and
 related drivers
Date: Tue, 28 Jul 2026 19:43:12 +0200
Message-Id: <20260728-rn102-rn104-series-v2-0-ae31f55b7bc8@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIADDqaGoC/32NQQ6CMBREr0L+2pq2agFX3sOwAPoL30hrWiQaw
 t1ty97NJC+ZN7NCQE8Y4Fqs4HGhQM5GkIcC+rG1AzLSkUFyqXgpT8xbwWXOM9tdppWqsOO15sZ
 AFF8eDX3y6L3ZOby7B/ZzWkqNkcLs/De/LiL1/h4sgnFWqrrS8qJNpdRtmFp6Hns3QbNt2w9o7
 A1BxgAAAA==
X-Change-ID: 20260723-rn102-rn104-series-d668eb09d0ff
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 "open list:BAREBOX" <barebox@lists.infradead.org>
Cc: Luca Lauro <famlauro93l@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785260594; l=5094;
 i=famlauro93l@gmail.com; s=20260723; h=from:subject:message-id;
 bh=H00v4HUVKl9uzNkmyI0LrvhRsTZAVpRTj0v61hqhmGE=;
 b=q/LCC4wvwWp5E3trRttpK7jA44NzAgvj2cX7aD8G6Hxr2MiUkLvVyJxflpJzg51qYqW1wStO8
 f6PyKiUQZA1DJDZ/KUNixbFXVsqj23Syj4WnBq0kTyxrE4PVOc7siOn
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
Changes in v2:

Hi Sascha,

thanks for the review of the v1 series.

This v2 reorganizes the series to make it clearer and easier to review.
Platform‑specific patches have been grouped into thematic commits, noisy
changes should have been removed, and commit messages have been rewritten 
to better describe the functional modifications.

The AHCI patch has been cleaned up and clarified, the EHCI patches now
contain only functional changes, and the fan framework integration has
been consolidated. The previous “USB/AHCI integration” patch has been
squashed into the relevant commits.

No functional changes have been introduced beyond what was already
present in v1.

Thanks again for your feedback,
Luca Lauro

Link to v1:
https://patch.msgid.link/20260723-rn102-rn104-series-v1-0-7698d25df866@gmail.com

To: Sascha Hauer <s.hauer@pengutronix.de>
To: "open list:BAREBOX" <barebox@lists.infradead.org>

---
Luca Lauro (10):
      ARM: mvebu: add Netgear RN102 support
      ARM: mvebu: enable RN102 in mvebu_defconfig
      ARM: mvebu: add Netgear RN104 support
      ARM: mvebu: rename PUTC_LL to MVEBU_PUTC_LL
      drivers: fan: add fan framework and API
      commands: add fan control command
      commands: integrate fan command into Kconfig and Makefile
      usb: ehci: add Marvell EHCI host controller driver
      usb: ehci: minor fixes for Marvell compatibility
      ata: ahci: add PCI AHCI support and Marvell-specific fixes

 arch/arm/boards/Makefile                         |    1 +
 arch/arm/boards/netgear-rn102/Makefile           |    4 +
 arch/arm/boards/netgear-rn102/board.c            |  243 +++++
 arch/arm/boards/netgear-rn102/lowlevel.c         |   58 ++
 arch/arm/boards/netgear-rn104/board.c            |  182 ++++
 arch/arm/boards/netgear-rn104/lowlevel.c         |   43 +-
 arch/arm/configs/mvebu_defconfig                 |    1 +
 arch/arm/dts/Makefile                            |    1 +
 arch/arm/dts/armada-370-rn102-bb.dts             |   80 ++
 arch/arm/dts/armada-370-rn104-bb.dts             |   75 +-
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
 drivers/usb/host/ehci-hcd.c                      |   23 +-
 drivers/usb/host/ehci-marvell.c                  |  228 +++++
 dts/src/arm/marvell/armada-370-netgear-rn102.dts |  114 ++-
 dts/src/arm/marvell/armada-370-netgear-rn104.dts |  173 ++--
 images/Makefile.mvebu                            |   13 +-
 include/fan/fan.h                                |   94 ++
 include/fan/i2c_fan_controllers/g76x.h           |   37 +
 include/mach/mvebu/debug_ll.h                    |    2 +-
 38 files changed, 3354 insertions(+), 428 deletions(-)
---
base-commit: f9cc366e5b67680473e4ab7837eeb27bf1b5a567
change-id: 20260723-rn102-rn104-series-d668eb09d0ff

Best regards,
--  
Luca Lauro <famlauro93l@gmail.com>

