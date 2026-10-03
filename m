From: Igor Velkov <iav@iav.lv>
Date: Sat, 03 Oct 2026 07:36:56 +0300
Subject: [PATCH 2/2] arm: mvebu: set up the AHCI controller that is being
 probed
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261003-ahci-mvebu-windows-v1-2-e382f73fc299@iav.lv>
References: <20261003-ahci-mvebu-windows-v1-0-e382f73fc299@iav.lv>
In-Reply-To: <20261003-ahci-mvebu-windows-v1-0-e382f73fc299@iav.lv>
To: Stefan Roese <stefan.roese@mailbox.org>, Tom Rini <trini@konsulko.com>, 
 Aaron Williams <awilliams@marvell.com>
Cc: Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Daniel Schwierzeck <daniel.schwierzeck@gmail.com>, 
 Chris Packham <judge.packham@gmail.com>, 
 Robert Marko <robert.marko@sartura.hr>, Baruch Siach <baruch@tkos.co.il>, 
 u-boot@lists.u-boot-project.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2256; i=iav@iav.lv;
 h=from:subject:message-id; bh=IXNqB2FfOr+AfTwgdsEd6OhEY0WR9pooeokYKG7kKAk=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFkH2jL3eqde1vl3OcG6QeNk3Q7pYzI6kid3PPdRvv/XM
 qpugejbjlIWBjEuBlkxRZYJhzRuZSy5+tffw/wBzBxWJpAhDFycAnCT/RgZpsqU/7C2drl70+N/
 xYznm/KCp0xQiVvK9LuNbdkEW16ztYwMH3avzfq/8+pjBnc79fUhcob3f+Z9eldY8qgtV/vP5Mp
 eFgA=
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

board_ahci_enable() sets the DRAM windows and the regret bit only at
MVEBU_SATA0_BASE, the first controller (sata@a8000), but the generic AHCI
driver calls it before probing each controller. On Armada 388 the second
controller, sata@e0000, is left without these windows, so its DMA does not
reach DRAM: the link comes up, the first command never completes and
scsi scan hangs.

Use the address of the controller being probed. MVEBU_SATA0_BASE has no
other user, drop it.

Tested on Helios4, whose disk is on the second controller: without this
change scsi scan hangs; with it the disk is found, and blocks read in
U-Boot have the same CRC32 as when read from Linux.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
 arch/arm/mach-mvebu/cpu.c              | 7 +++++--
 arch/arm/mach-mvebu/include/mach/soc.h | 1 -
 2 files changed, 5 insertions(+), 3 deletions(-)

diff --git a/arch/arm/mach-mvebu/cpu.c b/arch/arm/mach-mvebu/cpu.c
index 09a0292699c..c13b9d70bfd 100644
--- a/arch/arm/mach-mvebu/cpu.c
+++ b/arch/arm/mach-mvebu/cpu.c
@@ -6,6 +6,7 @@
 #include <config.h>
 #include <ahci.h>
 #include <cpu_func.h>
+#include <dm.h>
 #include <init.h>
 #include <linux/bitops.h>
 #include <linux/delay.h>
@@ -609,8 +610,10 @@ static void ahci_mvebu_regret_option(void __iomem *base)
 
 int board_ahci_enable(struct udevice *dev)
 {
-	ahci_mvebu_mbus_config((void __iomem *)MVEBU_SATA0_BASE);
-	ahci_mvebu_regret_option((void __iomem *)MVEBU_SATA0_BASE);
+	void __iomem *base = dev_remap_addr(dev);
+
+	ahci_mvebu_mbus_config(base);
+	ahci_mvebu_regret_option(base);
 
 	return 0;
 }
diff --git a/arch/arm/mach-mvebu/include/mach/soc.h b/arch/arm/mach-mvebu/include/mach/soc.h
index 33fdfd6d6c1..3ae5cffb669 100644
--- a/arch/arm/mach-mvebu/include/mach/soc.h
+++ b/arch/arm/mach-mvebu/include/mach/soc.h
@@ -77,7 +77,6 @@
 #define MVEBU_USB20_BASE	(MVEBU_REGISTER(0x58000))
 #define MVEBU_REG_PCIE0_BASE	(MVEBU_REGISTER(0x80000))
 #define MVEBU_AXP_SATA_BASE	(MVEBU_REGISTER(0xa0000))
-#define MVEBU_SATA0_BASE	(MVEBU_REGISTER(0xa8000))
 #define MVEBU_NAND_BASE		(MVEBU_REGISTER(0xd0000))
 #define MVEBU_SDIO_BASE		(MVEBU_REGISTER(0xd8000))
 #define MVEBU_LCD_BASE		(MVEBU_REGISTER(0xe0000))

-- 
2.43.0

