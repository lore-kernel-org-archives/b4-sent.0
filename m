From: Igor Velkov <iav@iav.lv>
Date: Sat, 03 Oct 2026 07:36:55 +0300
Subject: [PATCH 1/2] ata: ahci_generic: pass the AHCI device to
 board_ahci_enable()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261003-ahci-mvebu-windows-v1-1-e382f73fc299@iav.lv>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3663; i=iav@iav.lv;
 h=from:subject:message-id; bh=7+gIMq43dS+isEi/l16AqsbIu+D/GsrJCavd9JkOvFg=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFkH2jI+/J/y6c+Bwwsv7fF44uU0WVP0EPPqCC8jFs2tz
 VcvbVtY3VHKwiDGxSArpsgy4ZDGrYwlV//6e5g/gJnDygQyhIGLUwAm8sqRkeHN0U6+mYZv1k4z
 DT1w/BC33qKpns9/Rk2dNlei9O/ZR4URjAw/+gXCtLTv3Vh+a2FlwpPl6qvNg3R55k9+n6p1+PF
 Or2p2AA==
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The generic AHCI driver calls board_ahci_enable() before it probes each
controller, but does not tell it which one. Board code that sets up a
controller can only use a fixed address, as the Armada 38x code does
with the address of its first controller.

Pass the device being probed and declare the function in ahci.h. The
existing implementations do not use the argument yet.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
 arch/arm/mach-mvebu/cpu.c               |  2 +-
 arch/mips/mach-octeon/cpu.c             |  3 ++-
 board/Marvell/mvebu_armada-37xx/board.c |  3 ++-
 drivers/ata/ahci_generic.c              |  4 ++--
 include/ahci.h                          | 10 ++++++++++
 5 files changed, 17 insertions(+), 5 deletions(-)

diff --git a/arch/arm/mach-mvebu/cpu.c b/arch/arm/mach-mvebu/cpu.c
index a1eb6927c3e..09a0292699c 100644
--- a/arch/arm/mach-mvebu/cpu.c
+++ b/arch/arm/mach-mvebu/cpu.c
@@ -607,7 +607,7 @@ static void ahci_mvebu_regret_option(void __iomem *base)
 	writel(0x80, base + AHCI_VENDOR_SPECIFIC_0_DATA);
 }
 
-int board_ahci_enable(void)
+int board_ahci_enable(struct udevice *dev)
 {
 	ahci_mvebu_mbus_config((void __iomem *)MVEBU_SATA0_BASE);
 	ahci_mvebu_regret_option((void __iomem *)MVEBU_SATA0_BASE);
diff --git a/arch/mips/mach-octeon/cpu.c b/arch/mips/mach-octeon/cpu.c
index c771da61a68..049b5f05337 100644
--- a/arch/mips/mach-octeon/cpu.c
+++ b/arch/mips/mach-octeon/cpu.c
@@ -3,6 +3,7 @@
  * Copyright (C) 2020-2022 Marvell International Ltd.
  */
 
+#include <ahci.h>
 #include <dm.h>
 #include <dm/uclass.h>
 #include <env.h>
@@ -457,7 +458,7 @@ int arch_misc_init(void)
 	return 0;
 }
 
-int board_ahci_enable(void)
+int board_ahci_enable(struct udevice *dev)
 {
 	cvmx_sata_uctl_shim_cfg_t shim_cfg;
 
diff --git a/board/Marvell/mvebu_armada-37xx/board.c b/board/Marvell/mvebu_armada-37xx/board.c
index c30fca6cffd..126f5d78262 100644
--- a/board/Marvell/mvebu_armada-37xx/board.c
+++ b/board/Marvell/mvebu_armada-37xx/board.c
@@ -4,6 +4,7 @@
  */
 
 #include <config.h>
+#include <ahci.h>
 #include <dm.h>
 #include <dm/device-internal.h>
 #include <env.h>
@@ -190,7 +191,7 @@ int board_late_init(void)
 #endif
 
 /* Board specific AHCI / SATA enable code */
-int board_ahci_enable(void)
+int board_ahci_enable(struct udevice *ahci_dev)
 {
 	struct udevice *dev;
 	int ret;
diff --git a/drivers/ata/ahci_generic.c b/drivers/ata/ahci_generic.c
index 6e5a6cbafd8..8a21d70c68a 100644
--- a/drivers/ata/ahci_generic.c
+++ b/drivers/ata/ahci_generic.c
@@ -11,7 +11,7 @@
  * Dummy implementation that can be overwritten by a board
  * specific function
  */
-__weak int board_ahci_enable(void)
+__weak int board_ahci_enable(struct udevice *dev)
 {
 	return 0;
 }
@@ -36,7 +36,7 @@ static int generic_ahci_probe(struct udevice *dev)
 	 * Board specific SATA / AHCI enable code, e.g. enable the
 	 * AHCI power or deassert reset
 	 */
-	board_ahci_enable();
+	board_ahci_enable(dev);
 
 	ahci_probe_scsi(dev, (ulong)dev_remap_addr(dev));
 
diff --git a/include/ahci.h b/include/ahci.h
index 470cda006de..76f4e3ef5c8 100644
--- a/include/ahci.h
+++ b/include/ahci.h
@@ -278,4 +278,14 @@ int ahci_probe_scsi(struct udevice *ahci_dev, ulong base);
  */
 int ahci_probe_scsi_pci(struct udevice *ahci_dev);
 
+/**
+ * board_ahci_enable() - board specific setup of an AHCI controller
+ *
+ * Called by the generic AHCI driver before it probes each controller.
+ *
+ * @ahci_dev: AHCI controller being probed
+ * Return: 0 if OK, -ve on error
+ */
+int board_ahci_enable(struct udevice *ahci_dev);
+
 #endif

-- 
2.43.0

