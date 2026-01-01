From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Thu, 01 Jan 2026 17:41:55 +0100
Subject: [PATCH v2] powerpc: mpc83xx: Check the size of peripheral structs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260101-immap-size-v2-1-31f15acea735@posteo.net>
X-B4-Tracking: v=1; b=H4sIANKjVmkC/23MQQ7CIBCF4as0sxYDGNvgyns0XdA62FkUCEOI2
 nB3sWuX/0vetwNjImS4dTskLMQUfAt96mBZrX+ioEdr0FJfpVaDoG2zUTB9UCzOuN7JXl0MQjv
 EhI5eBzZOrVfiHNL7sIv6rX+ZooQUzsyo0eAwK3uPgTOGs8cMU631CynIbg2lAAAA
X-Change-ID: 20250217-immap-size-cf9f6f06139e
To: u-boot@lists.denx.de
Cc: Tom Rini <trini@konsulko.com>, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767285717; l=10548;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=TVlU3hNU8m5wN24VzurUN8t4Ih+sBa9+LQBrLdMYvL0=;
 b=em5oWHg4H2VTb56cHBddtPTgYhJvZ9n3koCIybuNST720ae8x4UTB+QK+CCzbePG0LWneGFlu
 DzWc4u7Nj6YDwibUUts22Emeq090erfZMqDMssr30dORcd9HL8RViR1
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Peripheral registers on MPC83xx-series chips are declared in
immap_83xx.h as a set of structs that ultimately fill the entire MMIO
space of 1 MiB. This patch introduces a compile-time check of the size
of each peripheral struct. The purpose of these checks is two-fold:

1. To quickly tell readers of the code the total size of each struct
2. To verify that the size does not change when a struct is edited

If the size of a peripheral struct were to change by a few bytes due
to an editing error, the result would be mayhem for all following
peripherals, because all offsets would shift by the amount of the error.

All new checks have been compile-tested.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
Changes in v2:
- Drop patch 2 "powerpc: mpc8xxx_spi: Catch bad chip variants earlier",
  which turned out to cause failures in too many cases
- Link to v1: https://lore.kernel.org/r/20250217-immap-size-v1-0-f9be2e9e7b1a@posteo.net
---
 arch/powerpc/include/asm/fsl_i2c.h     |  2 ++
 arch/powerpc/include/asm/fsl_lbc.h     |  1 +
 arch/powerpc/include/asm/immap_83xx.h  | 37 ++++++++++++++++++++++++++++++++++
 arch/powerpc/include/asm/mpc8xxx_spi.h |  1 +
 4 files changed, 41 insertions(+)

diff --git a/arch/powerpc/include/asm/fsl_i2c.h b/arch/powerpc/include/asm/fsl_i2c.h
index 1b1766180a7..6b728f833db 100644
--- a/arch/powerpc/include/asm/fsl_i2c.h
+++ b/arch/powerpc/include/asm/fsl_i2c.h
@@ -15,6 +15,7 @@
 
 #include <asm/types.h>
 #include <linux/compiler.h>
+#include <linux/build_bug.h>
 
 typedef struct fsl_i2c_base {
 
@@ -67,6 +68,7 @@ typedef struct fsl_i2c_base {
 	/* Fill out the reserved block */
 	u8 res6[0xE8];
 } fsl_i2c_t;
+static_assert(sizeof(fsl_i2c_t) == 0x100);
 
 #if CONFIG_IS_ENABLED(DM_I2C)
 struct fsl_i2c_dev {
diff --git a/arch/powerpc/include/asm/fsl_lbc.h b/arch/powerpc/include/asm/fsl_lbc.h
index 95f0f559b4c..f07535cb5ea 100644
--- a/arch/powerpc/include/asm/fsl_lbc.h
+++ b/arch/powerpc/include/asm/fsl_lbc.h
@@ -526,6 +526,7 @@ typedef struct fsl_lbc {
 	u8      res9[0xF28];
 #endif
 } fsl_lbc_t;
+static_assert(sizeof(fsl_lbc_t) == 0x1000);
 
 #endif /* __ASSEMBLY__ */
 #endif /* __ASM_PPC_FSL_LBC_H */
diff --git a/arch/powerpc/include/asm/immap_83xx.h b/arch/powerpc/include/asm/immap_83xx.h
index 24bd438c143..1fa6073b268 100644
--- a/arch/powerpc/include/asm/immap_83xx.h
+++ b/arch/powerpc/include/asm/immap_83xx.h
@@ -19,6 +19,7 @@
 #include <asm/mpc8xxx_spi.h>
 #include <asm/fsl_lbc.h>
 #include <asm/fsl_dma.h>
+#include <linux/build_bug.h>
 
 /*
  * Local Access Window
@@ -27,6 +28,7 @@ typedef struct law83xx {
 	u32 bar;		/* LBIU local access window base address register */
 	u32 ar;			/* LBIU local access window attribute register */
 } law83xx_t;
+static_assert(sizeof(law83xx_t) == 8);
 
 /*
  * System configuration registers
@@ -66,6 +68,7 @@ typedef struct sysconf83xx {
 #endif
 	u8 res9[0xB8];
 } sysconf83xx_t;
+static_assert(sizeof(sysconf83xx_t) == 0x200);
 
 /*
  * Watch Dog Timer (WDT) Registers
@@ -78,6 +81,7 @@ typedef struct wdt83xx {
 	u16 swsrr;		/* System watchdog service register */
 	u8 res2[0xF0];
 } wdt83xx_t;
+static_assert(sizeof(wdt83xx_t) == 0x100);
 
 /*
  * RTC/PIT Module Registers
@@ -91,6 +95,7 @@ typedef struct rtclk83xx {
 	u32 alr;		/* alarm register */
 	u8 res0[0xE8];
 } rtclk83xx_t;
+static_assert(sizeof(rtclk83xx_t) == 0x100);
 
 /*
  * Global timer module
@@ -126,6 +131,7 @@ typedef struct gtm83xx {
 	u16 psr4;		/* Timer4 Prescaler Register */
 	u8 res[0xC0];
 } gtm83xx_t;
+static_assert(sizeof(gtm83xx_t) == 0x100);
 
 /*
  * Integrated Programmable Interrupt Controller
@@ -159,6 +165,7 @@ typedef struct ipic83xx {
 	u32 smvcr;		/* System Management Interrupt Vector Register */
 	u8 res[0x98];
 } ipic83xx_t;
+static_assert(sizeof(ipic83xx_t) == 0x100);
 
 /*
  * System Arbiter Registers
@@ -175,6 +182,7 @@ typedef struct arbiter83xx {
 	u32 aerr;		/* Arbiter Event Response Register */
 	u8 res1[0xDC];
 } arbiter83xx_t;
+static_assert(sizeof(arbiter83xx_t) == 0x100);
 
 /*
  * Reset Module
@@ -190,6 +198,7 @@ typedef struct reset83xx {
 	u32 rcer;		/* Reset Control Enable Register */
 	u8 res1[0xDC];
 } reset83xx_t;
+static_assert(sizeof(reset83xx_t) == 0x100);
 
 /*
  * Clock Module
@@ -200,6 +209,7 @@ typedef struct clk83xx {
 	u32 sccr;		/* system clock control Register */
 	u8 res0[0xF4];
 } clk83xx_t;
+static_assert(sizeof(clk83xx_t) == 0x100);
 
 /*
  * Power Management Control Module
@@ -212,6 +222,7 @@ typedef struct pmc83xx {
 	u32 pmccr2;		/* PMC Configuration Register 2 */
 	u8 res0[0xEC];
 } pmc83xx_t;
+static_assert(sizeof(pmc83xx_t) == 0x100);
 
 /*
  * General purpose I/O module
@@ -225,6 +236,7 @@ typedef struct gpio83xx {
 	u32 icr;		/* external interrupt control register */
 	u8 res0[0xE8];
 } gpio83xx_t;
+static_assert(sizeof(gpio83xx_t) == 0x100);
 
 /*
  * QE Ports Interrupts Registers
@@ -236,6 +248,7 @@ typedef struct qepi83xx {
 	u32 qepicr;		/* QE Ports Interrupt Control Register */
 	u8 res1[0xE8];
 } qepi83xx_t;
+static_assert(sizeof(qepi83xx_t) == 0x100);
 
 /*
  * QE Parallel I/O Ports
@@ -248,11 +261,13 @@ typedef struct gpio_n {
 	u32 ppar1;		/* Pin Assignment Register 1 */
 	u32 ppar2;		/* Pin Assignment Register 2 */
 } gpio_n_t;
+static_assert(sizeof(gpio_n_t) == 0x18);
 
 typedef struct qegpio83xx {
 	gpio_n_t ioport[0x7];
 	u8 res0[0x358];
 } qepio83xx_t;
+static_assert(sizeof(qepio83xx_t) == 0x400);
 
 /*
  * QE Secondary Bus Access Windows
@@ -268,6 +283,7 @@ typedef struct qesba83xx {
 	u32 sdmcar;		/* Secondary DDR memory controller attributes */
 	u8 res2[0x378];
 } qesba83xx_t;
+static_assert(sizeof(qesba83xx_t) == 0x400);
 
 /*
  * DDR Memory Controller Memory Map for DDR1
@@ -278,6 +294,7 @@ typedef struct ddr_cs_bnds {
 	u32 csbnds;
 	u8 res0[4];
 } ddr_cs_bnds_t;
+static_assert(sizeof(ddr_cs_bnds_t) == 8);
 
 typedef struct ddr83xx {
 	ddr_cs_bnds_t csbnds[4];/* Chip Select x Memory Bounds */
@@ -323,6 +340,7 @@ typedef struct ddr83xx {
 	u32 debug_reg;
 	u8 res9[0xFC];
 } ddr83xx_t;
+static_assert(sizeof(ddr83xx_t) == 0x1000);
 #endif
 
 /*
@@ -342,6 +360,7 @@ typedef struct duart83xx {
 	u8 res1[3];
 	u8 res2[0xEC];
 } duart83xx_t;
+static_assert(sizeof(duart83xx_t) == 0x100);
 
 /*
  * DMA/Messaging Unit
@@ -364,6 +383,7 @@ typedef struct dma83xx {
 	u32 res4[0x1E];		/* 0x88-0x99 reserved */
 	struct fsl_dma dma[4];
 } dma83xx_t;
+static_assert(sizeof(dma83xx_t) == 0x300);
 
 /*
  * PCI Software Configuration Registers
@@ -374,6 +394,7 @@ typedef struct pciconf83xx {
 	u32 int_ack;
 	u8 res[116];
 } pciconf83xx_t;
+static_assert(sizeof(pciconf83xx_t) == 0x80);
 
 /*
  * PCI Outbound Translation Register
@@ -386,6 +407,7 @@ typedef struct pci_outbound_window {
 	u32 pocmr;
 	u8 res2[4];
 } pot83xx_t;
+static_assert(sizeof(pot83xx_t) == 0x18);
 
 /*
  * Sequencer
@@ -398,6 +420,7 @@ typedef struct ios83xx {
 	u32 dtcr;
 	u8 res2[4];
 } ios83xx_t;
+static_assert(sizeof(ios83xx_t) == 0x100);
 
 /*
  * PCI Controller Control and Status Registers
@@ -434,6 +457,7 @@ typedef struct pcictrl83xx {
 	u32 piwar0;
 	u8 res7[132];
 } pcictrl83xx_t;
+static_assert(sizeof(pcictrl83xx_t) == 0x100);
 
 /*
  * USB
@@ -441,6 +465,7 @@ typedef struct pcictrl83xx {
 typedef struct usb83xx {
 	u8 fixme[0x1000];
 } usb83xx_t;
+static_assert(sizeof(usb83xx_t) == 0x1000);
 
 /*
  * TSEC
@@ -448,6 +473,7 @@ typedef struct usb83xx {
 typedef struct tsec83xx {
 	u8 fixme[0x1000];
 } tsec83xx_t;
+static_assert(sizeof(tsec83xx_t) == 0x1000);
 
 /*
  * Security
@@ -455,6 +481,7 @@ typedef struct tsec83xx {
 typedef struct security83xx {
 	u8 fixme[0x10000];
 } security83xx_t;
+static_assert(sizeof(security83xx_t) == 0x10000);
 
 /*
  *  PCI Express
@@ -564,6 +591,7 @@ typedef struct pex83xx {
 	struct pex_csb_bridge bridge;
 	u8 res12[0x160];
 } pex83xx_t;
+static_assert(sizeof(pex83xx_t) == 0x1000);
 
 /*
  * SATA
@@ -571,6 +599,7 @@ typedef struct pex83xx {
 typedef struct sata83xx {
 	u8 fixme[0x1000];
 } sata83xx_t;
+static_assert(sizeof(sata83xx_t) == 0x1000);
 
 /*
  * eSDHC
@@ -578,6 +607,7 @@ typedef struct sata83xx {
 typedef struct sdhc83xx {
 	u8 fixme[0x1000];
 } sdhc83xx_t;
+static_assert(sizeof(sdhc83xx_t) == 0x1000);
 
 /*
  * SerDes
@@ -592,6 +622,7 @@ typedef struct serdes83xx {
 	u32 srdsrstctl;
 	u8 res1[0xdc];
 } serdes83xx_t;
+static_assert(sizeof(serdes83xx_t) == 0x100);
 
 /*
  * On Chip ROM
@@ -606,6 +637,7 @@ typedef struct rom83xx {
 typedef struct tdm83xx {
 	u8 fixme[0x200];
 } tdm83xx_t;
+static_assert(sizeof(tdm83xx_t) == 0x200);
 
 /*
  * TDM DMAC
@@ -613,6 +645,7 @@ typedef struct tdm83xx {
 typedef struct tdmdmac83xx {
 	u8 fixme[0x2000];
 } tdmdmac83xx_t;
+static_assert(sizeof(tdmdmac83xx_t) == 0x2000);
 
 #if defined(CONFIG_ARCH_MPC834X)
 typedef struct immap {
@@ -725,6 +758,7 @@ typedef struct immap {
 	serdes83xx_t		serdes[1];	/* SerDes Registers */
 	u8			res9[0x1CF00];
 } immap_t;
+static_assert(sizeof(immap_t) == 0x100000);
 
 #elif defined(CONFIG_ARCH_MPC837X)
 typedef struct immap {
@@ -769,6 +803,7 @@ typedef struct immap {
 	u8			res11[0xCE00];
 	rom83xx_t		rom;		/* On Chip ROM */
 } immap_t;
+static_assert(sizeof(immap_t) == 0x100000);
 
 #elif defined(CONFIG_ARCH_MPC8360)
 typedef struct immap {
@@ -809,6 +844,7 @@ typedef struct immap {
 	u8			res10[0xC0000];
 	u8			qe[0x100000];	/* QE block */
 } immap_t;
+static_assert(sizeof(immap_t) == 0x200000);
 
 #elif defined(CONFIG_ARCH_MPC832X)
 typedef struct immap {
@@ -846,6 +882,7 @@ typedef struct immap {
 	u8			res8[0xC0000];
 	u8			qe[0x100000];	/* QE block */
 } immap_t;
+static_assert(sizeof(immap_t) == 0x200000);
 #endif
 
 struct ccsr_gpio {
diff --git a/arch/powerpc/include/asm/mpc8xxx_spi.h b/arch/powerpc/include/asm/mpc8xxx_spi.h
index 8e9411aefb3..2b2095ad481 100644
--- a/arch/powerpc/include/asm/mpc8xxx_spi.h
+++ b/arch/powerpc/include/asm/mpc8xxx_spi.h
@@ -26,6 +26,7 @@ typedef struct spi8xxx {
 	u32 rx;		/* receive register */
 	u8 res1[0xFC8];	/* fill up to 0x1000 */
 } spi8xxx_t;
+static_assert(sizeof(spi8xxx_t) == 0x1000);
 
 #endif
 

---
base-commit: 2522af42b19cced6f5fb487e7eec41a31006d277
change-id: 20250217-immap-size-cf9f6f06139e

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

