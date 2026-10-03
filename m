From: Igor Velkov <iav@iav.lv>
Subject: [PATCH 0/2] ata/mvebu: set up each Armada 388 AHCI controller
Date: Sat, 03 Oct 2026 07:36:54 +0300
Message-Id: <20261003-ahci-mvebu-windows-v1-0-e382f73fc299@iav.lv>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGaGwGoC/x3MQQqAIBBA0avErBvQDImuEi1Mp5xFGkoZRHdPW
 r7F/w9kSkwZxuaBRBdnjqFCtg1Yb8JGyK4aOtFpKYRC4y3jftFyYuHgYsnorJG6J6nEQFDDI9H
 K9z+d5vf9ABwKjvhkAAAA
To: Stefan Roese <stefan.roese@mailbox.org>, Tom Rini <trini@konsulko.com>, 
 Aaron Williams <awilliams@marvell.com>
Cc: Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Daniel Schwierzeck <daniel.schwierzeck@gmail.com>, 
 Chris Packham <judge.packham@gmail.com>, 
 Robert Marko <robert.marko@sartura.hr>, Baruch Siach <baruch@tkos.co.il>, 
 u-boot@lists.u-boot-project.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1205; i=iav@iav.lv;
 h=from:subject:message-id; bh=OidSXasQZk7bkSAOandgD1nP0OTio/kipKejGpilY0M=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFkH2jK6HQ4J1XP4ahzpfKF087j267zsrCOpQp7/Pv782
 bOcWTqjo5SFQYyLQVZMkWXCIY1bGUuu/vX3MH8AM4eVCWQIAxenAEzkMx8jw8HiQE6+ay0N1sp+
 B6/OSm8Rl+pO0voRX5m14+ud/dMN9jL8L/8atvJWm9Dxf6nNO2cePa74i01x5pe9HrXpvL4hXtU
 5nAA=
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On Armada 388 the second AHCI controller (sata@e0000) never gets its
MBus DRAM windows: board_ahci_enable() only knows MVEBU_SATA0_BASE.
Pass the probed device to board_ahci_enable() and use its address.

Tested on Helios4 (disk on sata@e0000): scsi scan now finds the disk,
and the CRC32 of blocks read in U-Boot matches Linux. Builds: helios4,
clearfog, mvebu_db-88f3720, octeon_ebb7304, octeon_nic23. SPL SATA boot
(clearfog_sata) is not tested on hardware.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
Igor Velkov (2):
      ata: ahci_generic: pass the AHCI device to board_ahci_enable()
      arm: mvebu: set up the AHCI controller that is being probed

 arch/arm/mach-mvebu/cpu.c               |  9 ++++++---
 arch/arm/mach-mvebu/include/mach/soc.h  |  1 -
 arch/mips/mach-octeon/cpu.c             |  3 ++-
 board/Marvell/mvebu_armada-37xx/board.c |  3 ++-
 drivers/ata/ahci_generic.c              |  4 ++--
 include/ahci.h                          | 10 ++++++++++
 6 files changed, 22 insertions(+), 8 deletions(-)
---
base-commit: a6ab6a66146ed0bf1420db0ee858b49005783222
change-id: 20261003-ahci-mvebu-windows-dca164e1308e

Best regards,
-- 
Igor Velkov <iav@iav.lv>

