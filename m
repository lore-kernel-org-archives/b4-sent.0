From: Oliver Gaskell <Oliver.Gaskell@analog.com>
Date: Wed, 28 Aug 2024 11:02:21 +0100
Subject: [PATCH 13/20] arm: SC598-SOM-EZKIT initial support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240828-sc5xx-upstreaming-patches-v1-13-44d9adfdf327@analog.com>
References: <20240828-sc5xx-upstreaming-patches-v1-0-44d9adfdf327@analog.com>
In-Reply-To: <20240828-sc5xx-upstreaming-patches-v1-0-44d9adfdf327@analog.com>
To: Tom Rini <trini@konsulko.com>, 
 Nathan Barrett-Morrison <nathan.morrison@timesys.com>, 
 Greg Malysa <greg.malysa@timesys.com>, 
 Ian Roberts <ian.roberts@timesys.com>, 
 Vasileios Bimpikas <vasileios.bimpikas@analog.com>, 
 Utsav Agarwal <utsav.agarwal@analog.com>, 
 Arturs Artamonovs <arturs.artamonovs@analog.com>, 
 Rayagonda Kokatanur <rayagonda.kokatanur@broadcom.com>
Cc: u-boot@lists.denx.de, adsp-linux@analog.com, 
 Oliver Gaskell <Oliver.Gaskell@analog.com>, 
 Trevor Woerner <twoerner@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724839434; l=10533;
 i=Oliver.Gaskell@analog.com; s=20240821; h=from:subject:message-id;
 bh=9F+zvQJMMot/CLh1Ec54WEbVXJ2GcVVeBNvDllK0m04=;
 b=bLYUoUZc5iJv/zvgQws0Fyl5r4z9VapNH45mr+zLmyF6MCm9SZNcLtkf5LET3rnzLhnZr//0m
 2dVduKza8w/BHzunnfr3sXuxdPnQYjS413n+G0no84wY5TxEEUBxYzk
X-Developer-Key: i=Oliver.Gaskell@analog.com; a=ed25519;
 pk=Icq9TxwFJ6FePHS28YbBWMvtZpFWxpPQLhLA9cNvZ/Y=
X-Endpoint-Received: by B4 Relay for Oliver.Gaskell@analog.com/20240821 with auth_id=197
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds support for Analog Devices' SC598-SOM-EZKIT board. Includes:
- CONFIG options common to all SC5xx SoCs
- SoC specific configs in mach-sc5xx/Kconfig
- Memory Map for SPL
- Necessary board-specific init functions
- Board-specific Kconfig and environment in board/adi/
- Memory configuration

Co-developed-by: Greg Malysa <greg.malysa@timesys.com>
Co-developed-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
Co-developed-by: Trevor Woerner <twoerner@gmail.com>
Signed-off-by: Oliver Gaskell <Oliver.Gaskell@analog.com>
---
 MAINTAINERS                                   |   2 +
 arch/arm/Kconfig                              |   6 ++
 arch/arm/mach-sc5xx/Kconfig                   |  40 ++++++-
 arch/arm/mach-sc5xx/Makefile                  |   1 +
 arch/arm/mach-sc5xx/sc59x_64-spl.c            |  26 +++++
 arch/arm/mach-sc5xx/sc59x_64.c                |  25 +++++
 arch/arm/mach-sc5xx/soc.c                     |  25 +++++
 board/adi/sc598-som-ezkit/Kconfig             | 150 ++++++++++++++++++++++++++
 board/adi/sc598-som-ezkit/sc598-som-ezkit.env |  13 +++
 include/configs/sc598-som.h                   |  23 ++++
 10 files changed, 310 insertions(+), 1 deletion(-)

diff --git a/MAINTAINERS b/MAINTAINERS
index 823bb5ad92..5f945ec335 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -607,12 +607,14 @@ T:	git https://github.com/analogdevicesinc/lnxdsp-u-boot
 F:	arch/arm/dts/sc5*
 F:	arch/arm/include/asm/arch-adi/
 F:	arch/arm/mach-sc5xx/
+F:	board/adi/
 F:	doc/device-tree-bindings/arm/adi/adi,sc5xx.yaml
 F:	doc/device-tree-bindings/clock/adi,sc5xx-clocks.yaml
 F:	doc/device-tree-bindings/timer/adi,sc5xx-gptimer.yaml
 F:	drivers/clk/adi/
 F:	drivers/serial/serial_adi_uart4.c
 F:	drivers/timer/adi_sc5xx_timer.c
+F:	include/configs/sc5*
 F:	include/env/adi/
 
 ARM SNAPDRAGON
diff --git a/arch/arm/Kconfig b/arch/arm/Kconfig
index 69decaa591..a3e8ebe0b1 100644
--- a/arch/arm/Kconfig
+++ b/arch/arm/Kconfig
@@ -1870,7 +1870,13 @@ config ARCH_SC5XX
 	bool "Analog Devices SC5XX-processor family"
 	select SPL
 	select SUPPORT_SPL
+	select SPL_SKIP_LOWLEVEL_INIT
+	select SPL_LIBGENERIC_SUPPORT
+	select SPL_LIBCOMMON_SUPPORT
+	select SPL_BOOTROM_SUPPORT
+	select SPL_DM_SEQ_ALIAS
 	select PANIC_HANG
+	select HAS_CUSTOM_SYS_INIT_SP_ADDR
 	select DM
 	select SPL_DM
 	select DM_SERIAL
diff --git a/arch/arm/mach-sc5xx/Kconfig b/arch/arm/mach-sc5xx/Kconfig
index d99b02b574..cd3c7011f4 100644
--- a/arch/arm/mach-sc5xx/Kconfig
+++ b/arch/arm/mach-sc5xx/Kconfig
@@ -41,10 +41,31 @@ config SC59X_64
 	select COMMON_CLK_ADI_SC598
 	select GICV3
 	select GIC_600_CLEAR_RDPD
-	select NOP_PHY
+	select GICV3_SUPPORT_GIC600
+	select NOP_PHY if PHY
+
+endchoice
+
+if SC59X_64
+
+choice
+	prompt "SC59x 64-bit board select"
+
+config TARGET_SC598_SOM_EZKIT
+	bool
+	prompt "SC598-SOM with SOMCRR-EZKIT"
+	select ADI_CARRIER_SOMCRR_EZKIT
 
 endchoice
 
+endif
+
+config ADI_IMAGE
+	string "ADI fitImage type"
+	help
+	  The image built by the ADI ADSP Linux build system.
+	  Is one of tiny, minimal, full.
+
 config SC_BOOT_MODE
 	int "SC5XX boot mode select"
 	default 1
@@ -84,10 +105,25 @@ config SC_BOOT_OSPI_SSEL
 	  This is the OSPI chip select number to use for booting, Y in the
 	  expression `sf probe X:Y`
 
+config SYS_BOOTM_LEN
+	hex
+	default 0x1800000
+
 config SYS_FLASH_BASE
 	hex
 	default 0x60000000
 
+config SYS_MALLOC_F_LEN
+	default 0x14000
+
+config SYS_LOAD_ADDR
+	hex
+	default 0x0
+
+config SYS_MALLOC_LEN
+	hex
+	default 1048576
+
 config UART_CONSOLE
 	int
 	default 0
@@ -463,4 +499,6 @@ config PINCTRL_ADI
 	bool
 	default y
 
+source "board/adi/sc598-som-ezkit/Kconfig"
+
 endif
diff --git a/arch/arm/mach-sc5xx/Makefile b/arch/arm/mach-sc5xx/Makefile
index eeb56c078b..0955c509a5 100644
--- a/arch/arm/mach-sc5xx/Makefile
+++ b/arch/arm/mach-sc5xx/Makefile
@@ -14,6 +14,7 @@ obj-$(CONFIG_SC57X) += sc57x.o
 obj-$(CONFIG_SC58X) += sc58x.o
 obj-$(CONFIG_SC59X) += sc59x.o
 obj-$(CONFIG_SC59X_64) += sc59x_64.o
+obj-$(CONFIG_SC59X_64) += sc59x_64-spl.o
 
 obj-$(CONFIG_SPL_BUILD) += spl.o
 obj-$(CONFIG_SYSCON) += rcu.o
diff --git a/arch/arm/mach-sc5xx/sc59x_64-spl.c b/arch/arm/mach-sc5xx/sc59x_64-spl.c
new file mode 100644
index 0000000000..ae8c860cfe
--- /dev/null
+++ b/arch/arm/mach-sc5xx/sc59x_64-spl.c
@@ -0,0 +1,26 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * (C) Copyright 2024 - Analog Devices, Inc.
+ */
+
+#include <asm/arch-adi/sc5xx/spl.h>
+
+// Table 47-14 in SC598 hardware reference manual
+const struct adi_boot_args adi_rom_boot_args[] = {
+	// JTAG/no boot
+	[0] = {0, 0, 0},
+	// SPI master, used for qspi as well
+	[1] = {0x60040000, 0x00040000, 0x00000207},
+	// SPI slave
+	[2] = {0, 0, 0x00000212},
+	// UART slave
+	[3] = {0, 0, 0x00000013},
+	// Linkport slave
+	[4] = {0, 0, 0x00000014},
+	// OSPI master
+	[5] = {0x60040000, 0, 0x00000008},
+	// eMMC
+	[6] = {0x201, 0, 0x86009},
+	// reserved, also no boot
+	[7] = {0, 0, 0}
+};
diff --git a/arch/arm/mach-sc5xx/sc59x_64.c b/arch/arm/mach-sc5xx/sc59x_64.c
index 82537bf196..001747f223 100644
--- a/arch/arm/mach-sc5xx/sc59x_64.c
+++ b/arch/arm/mach-sc5xx/sc59x_64.c
@@ -9,6 +9,7 @@
  */
 
 #include <asm/io.h>
+#include <asm/armv8/mmu.h>
 #include <asm/arch-adi/sc5xx/sc5xx.h>
 #include <asm/arch-adi/sc5xx/spl.h>
 
@@ -24,6 +25,30 @@
 #define BITM_SCB5_SPI2_OSPI_REMAP_REMAP 0x00000003
 #define ENUM_SCB5_SPI2_OSPI_REMAP_OSPI0 0x00000001
 
+static struct mm_region sc598_mem_map[] = {
+	{
+		/* Peripherals */
+		.virt = 0x0UL,
+		.phys = 0x0UL,
+		.size = 0x80000000UL,
+		.attrs = PTE_BLOCK_MEMTYPE(MT_DEVICE_NGNRNE) |
+			 PTE_BLOCK_NON_SHARE |
+			 PTE_BLOCK_PXN | PTE_BLOCK_UXN
+	}, {
+		/* DDR */
+		.virt = 0x80000000UL,
+		.phys = 0x80000000UL,
+		.size = 0x40000000UL,
+		.attrs = PTE_BLOCK_MEMTYPE(MT_NORMAL) |
+			 PTE_BLOCK_INNER_SHARE
+	}, {
+		/* List terminator */
+		0,
+	}
+};
+
+struct mm_region *mem_map = sc598_mem_map;
+
 adi_rom_boot_fn adi_rom_boot = (adi_rom_boot_fn)0x000000e4;
 
 void sc5xx_enable_rgmii(void)
diff --git a/arch/arm/mach-sc5xx/soc.c b/arch/arm/mach-sc5xx/soc.c
index 8f13127a66..714b214bf6 100644
--- a/arch/arm/mach-sc5xx/soc.c
+++ b/arch/arm/mach-sc5xx/soc.c
@@ -172,6 +172,31 @@ void fixup_dp83867_phy(struct phy_device *phydev)
 		phy_write(phydev, MDIO_DEVAD_NONE, 0, 0x3100);
 }
 
+extern char __bss_start, __bss_end;
+
+void bss_clear(void)
+{
+	#ifdef CONFIG_SC59X_64
+	u32 *to = (void *)&__bss_start;
+	int i, sz;
+
+	sz = &__bss_end - &__bss_start;
+	for (i = 0; i < sz; i += 4)
+		*to++ = 0;
+	#endif
+}
+
+int board_early_init_f(void)
+{
+	bss_clear();
+	return 0;
+}
+
+int board_init(void)
+{
+	return 0;
+}
+
 int dram_init(void)
 {
 	gd->ram_size = CFG_SYS_SDRAM_SIZE;
diff --git a/board/adi/sc598-som-ezkit/Kconfig b/board/adi/sc598-som-ezkit/Kconfig
new file mode 100644
index 0000000000..3d9b378d37
--- /dev/null
+++ b/board/adi/sc598-som-ezkit/Kconfig
@@ -0,0 +1,150 @@
+# SPDX-License-Identifier: GPL-2.0-or-later
+#
+# (C) Copyright 2024 - Analog Devices, Inc.
+
+if TARGET_SC598_SOM_EZKIT
+
+config SYS_VENDOR
+	default "adi"
+
+config LDR_CPU
+	default "ADSP-SC598-0.0"
+
+config SYS_BOARD
+	default "sc598-som-ezkit"
+
+config SYS_CONFIG_NAME
+	default "sc598-som"
+
+config DEFAULT_DEVICE_TREE
+	default "sc598-som-ezkit"
+
+config SPL_MAX_SIZE
+	default 0x30000 # 256KB
+
+config ADI_IMAGE
+	default "minimal"
+
+config NR_DRAM_BANKS
+	default 1
+
+config SPL_BSS_START_ADDR
+	hex
+	default 0x200B0000
+
+config SPL_BSS_MAX_SIZE
+	hex
+	default 0x10000 # 64K
+
+config SYS_SPL_MALLOC_START
+	hex
+	default 0x200C0000
+
+config SYS_SPL_MALLOC_SIZE
+	hex
+	default 0x10000 # 64K
+
+config SPL_STACK
+	hex
+	default 0x200E4000
+
+config SPL_STACK_SIZE
+	hex
+	default 0x14000 # 64K
+
+config TEXT_BASE
+	hex
+	default 0x96000000
+
+config CUSTOM_SYS_INIT_SP_ADDR
+	hex
+	default 0x96000000
+
+config SYS_LOAD_ADDR
+	hex
+	default 0x0
+
+# SPL
+
+config SPL_TEXT_BASE
+	default 0x20080000
+
+config SPL_PAYLOAD_ARGS_ADDR
+	hex
+	default 0x99000000
+
+config SPL_OF_LIBFDT_ASSUME_MASK
+	hex
+	default 0x0
+
+# SPI Flash
+
+config SF_DEFAULT_BUS
+	default 2
+
+config SF_DEFAULT_CS
+	default 1
+
+config SF_DEFAULT_SPEED
+	default 10000000
+
+# Clock Configs
+
+config CGU0_DF_DIV
+	default 0
+
+config CGU0_VCO_MULT
+	default 80
+
+config CGU0_CCLK_DIV
+	default 2
+
+config CGU0_SCLK_DIV
+	default 4
+
+config CGU0_SCLK0_DIV
+	default 4
+
+config CGU0_SCLK1_DIV
+	default 2
+
+config CGU0_DCLK_DIV
+	default 3
+
+config CGU0_OCLK_DIV
+	default 8
+
+config CGU0_DIV_S1SELEX
+	default 6
+
+config CGU1_VCO_MULT
+	default 72
+
+config CGU1_DF_DIV
+	default 0
+
+config CGU1_CCLK_DIV
+	default 16
+
+config CGU1_SCLK_DIV
+	default 8
+
+config CGU1_SCLK0_DIV
+	default 4
+
+config CGU1_SCLK1_DIV
+	default 2
+
+config CGU1_DCLK_DIV
+	default 18
+
+config CGU1_OCLK_DIV
+	default 16
+
+config CGU1_DIV_S0SELEX
+	default 36
+
+config CGU1_DIV_S1SELEX
+	default 90
+
+endif
diff --git a/board/adi/sc598-som-ezkit/sc598-som-ezkit.env b/board/adi/sc598-som-ezkit/sc598-som-ezkit.env
new file mode 100644
index 0000000000..242436c160
--- /dev/null
+++ b/board/adi/sc598-som-ezkit/sc598-som-ezkit.env
@@ -0,0 +1,13 @@
+/* SPDX-License-Identifier: GPL-2.0-or-later+ */
+
+/*
+ * (C) Copyright 2024 - Analog Devices, Inc.
+ */
+
+#include <env/adi/adi_boot.env>
+
+adi_stage2_offset=0x40000
+adi_image_offset=0x01a0000
+adi_rfs_offset=0x1020000
+loadaddr=0x90000000
+jffs2file=adsp-sc5xx-__stringify(CONFIG_ADI_IMAGE)-adsp-sc598-som-ezkit.jffs2
diff --git a/include/configs/sc598-som.h b/include/configs/sc598-som.h
new file mode 100644
index 0000000000..964c694bbe
--- /dev/null
+++ b/include/configs/sc598-som.h
@@ -0,0 +1,23 @@
+/* SPDX-License-Identifier: GPL-2.0-or-later */
+/*
+ * (C) Copyright 2024 - Analog Devices, Inc.
+ */
+
+#ifndef __CONFIG_SC598_SOM_H
+#define __CONFIG_SC598_SOM_H
+
+/*
+ * Memory Settings
+ */
+#define MEM_IS43TR16512BL
+#define MEM_ISSI_4Gb_DDR3_800MHZ
+#define MEM_DMC0
+
+#define CFG_SYS_SDRAM_BASE	0x90000000
+#define CFG_SYS_SDRAM_SIZE	0x0e000000
+
+/* GIC */
+#define GICD_BASE 0x31200000
+#define GICR_BASE 0x31240000
+
+#endif

-- 
2.34.1

