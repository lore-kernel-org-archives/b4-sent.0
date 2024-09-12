From: Oliver Gaskell <Oliver.Gaskell@analog.com>
Date: Thu, 12 Sep 2024 16:50:54 +0100
Subject: [PATCH v2 13/20] arm: SC598-SOM-EZKIT initial support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240912-sc5xx-upstreaming-patches-v2-13-1185a80df79e@analog.com>
References: <20240912-sc5xx-upstreaming-patches-v2-0-1185a80df79e@analog.com>
In-Reply-To: <20240912-sc5xx-upstreaming-patches-v2-0-1185a80df79e@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726156261; l=14521;
 i=Oliver.Gaskell@analog.com; s=20240821; h=from:subject:message-id;
 bh=vfLWc1dQ3bLkL7Tc4zQLzkYW5uVJCs8csEhXdxVPEaM=;
 b=yIvYdHe3FssAHrKH/5BWbnEv3c+EZgz/aR9IMowtaMTQu3I8BIqdyNmc3OQcNqLiOTKyangp1
 qh5cSSgs0JhA6pulSX94E0o7iJ8aksjiv8yVlrBcd5B1akp+2vNu1ts
X-Developer-Key: i=Oliver.Gaskell@analog.com; a=ed25519;
 pk=Icq9TxwFJ6FePHS28YbBWMvtZpFWxpPQLhLA9cNvZ/Y=
X-Endpoint-Received: by B4 Relay for Oliver.Gaskell@analog.com/20240821 with auth_id=197
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds support for Analog Devices' SC598-SOM-EZKIT board. Includes:
- CONFIG options common to all SC5xx SoCs
- SoC specific configs in mach-sc5xx/Kconfig
- SPL config options in common/spl/Kconfig
- Memory Map for SPL
- Necessary board-specific init functions
- Board-specific Kconfig and environment in board/adi/
- Memory configuration

Co-developed-by: Greg Malysa <greg.malysa@timesys.com>
Signed-off-by: Greg Malysa <greg.malysa@timesys.com>
Co-developed-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
Signed-off-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
Co-developed-by: Trevor Woerner <twoerner@gmail.com>
Signed-off-by: Trevor Woerner <twoerner@gmail.com>
Signed-off-by: Oliver Gaskell <Oliver.Gaskell@analog.com>
---
 Kconfig                                       |   4 +-
 MAINTAINERS                                   |   2 +
 arch/arm/Kconfig                              |   6 ++
 arch/arm/mach-sc5xx/Kconfig                   |  43 ++++++++++-
 arch/arm/mach-sc5xx/Makefile                  |   1 +
 arch/arm/mach-sc5xx/sc59x_64-spl.c            |  26 +++++++
 arch/arm/mach-sc5xx/sc59x_64.c                |  25 +++++++
 arch/arm/mach-sc5xx/soc.c                     |  36 ++++++++++
 board/adi/sc598-som-ezkit/Kconfig             | 100 ++++++++++++++++++++++++++
 board/adi/sc598-som-ezkit/sc598-som-ezkit.env |  13 ++++
 common/spl/Kconfig                            |  10 ++-
 include/configs/sc598-som.h                   |  23 ++++++
 12 files changed, 285 insertions(+), 4 deletions(-)

diff --git a/Kconfig b/Kconfig
index 82df59f176..1596139160 100644
--- a/Kconfig
+++ b/Kconfig
@@ -208,7 +208,7 @@ config ENV_VARS_UBOOT_CONFIG
 
 config NR_DRAM_BANKS
 	int "Number of DRAM banks"
-	default 1 if ARCH_SUNXI || ARCH_OWL
+	default 1 if ARCH_SC5XX || ARCH_SUNXI || ARCH_OWL
 	default 4
 	help
 	  This defines the number of DRAM banks.
@@ -545,6 +545,7 @@ config SYS_LOAD_ADDR
 	default 0x12000000 if ARCH_MX6 && !(MX6SL || MX6SLL  || MX6SX || MX6UL || MX6ULL)
 	default 0x80800000 if ARCH_MX7
 	default 0x90000000 if FSL_LSCH2 || FSL_LSCH3
+	default 0x0 if ARCH_SC5XX
 	help
 	  Address in memory to use as the default safe load address.
 
@@ -644,6 +645,7 @@ config TEXT_BASE
 	default 0x2a000000 if MACH_SUN9I
 	default 0x4a000000 if SUNXI_MINIMUM_DRAM_MB >= 256
 	default 0x42e00000 if SUNXI_MINIMUM_DRAM_MB >= 64
+	default 0x96000000 if ARCH_SC5XX && SC59X_64
 	hex "Text Base"
 	help
 	  The address in memory that U-Boot will be copied and executed from
diff --git a/MAINTAINERS b/MAINTAINERS
index 0bc7f2f22d..0f4eee367d 100644
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
index 72960126ee..348f48b2ce 100644
--- a/arch/arm/Kconfig
+++ b/arch/arm/Kconfig
@@ -1871,9 +1871,15 @@ config ARCH_SC5XX
 	select ADI_SC5XX_TIMER
 	select DM
 	select DM_SERIAL
+	select HAS_CUSTOM_SYS_INIT_SP_ADDR
 	select PANIC_HANG
 	select SPL
+	select SPL_BOOTROM_SUPPORT
 	select SPL_DM
+	select SPL_DM_SEQ_ALIAS
+	select SPL_LIBGENERIC_SUPPORT
+	select SPL_LIBCOMMON_SUPPORT
+	select SPL_SKIP_LOWLEVEL_INIT
 	select SUPPORT_SPL
 	select TIMER
 
diff --git a/arch/arm/mach-sc5xx/Kconfig b/arch/arm/mach-sc5xx/Kconfig
index 2ec09dbf3e..4e587eb0b3 100644
--- a/arch/arm/mach-sc5xx/Kconfig
+++ b/arch/arm/mach-sc5xx/Kconfig
@@ -13,6 +13,9 @@
 
 if ARCH_SC5XX
 
+config SYS_VENDOR
+	default "adi"
+
 choice
 	prompt "SC5xx SoC Select"
 	help
@@ -39,12 +42,33 @@ config SC59X_64
 	select ARM64
 	select COMMON_CLK_ADI_SC598
 	select GICV3
+	select GICV3_SUPPORT_GIC600
 	select GIC_600_CLEAR_RDPD
 	select MMC_SDHCI_ADMA_FORCE_32BIT
-	select NOP_PHY
+	select NOP_PHY if PHY
 
 endchoice
 
+if SC59X_64
+
+choice
+	prompt "SC59x 64-bit board select"
+
+config TARGET_SC598_SOM_EZKIT
+	bool
+	prompt "SC598-SOM with SOMCRR-EZKIT"
+	select ADI_CARRIER_SOMCRR_EZKIT
+
+endchoice
+
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
@@ -84,10 +108,25 @@ config SC_BOOT_OSPI_SSEL
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
@@ -463,4 +502,6 @@ config PINCTRL_ADI
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
index 0000000000..3992538133
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
+	[1] = {0x60040000, 0x00040000, 0x20620247},
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
index 8f13127a66..f3619206e9 100644
--- a/arch/arm/mach-sc5xx/soc.c
+++ b/arch/arm/mach-sc5xx/soc.c
@@ -172,6 +172,42 @@ void fixup_dp83867_phy(struct phy_device *phydev)
 		phy_write(phydev, MDIO_DEVAD_NONE, 0, 0x3100);
 }
 
+extern char __bss_start, __bss_end;
+extern char __rel_dyn_end;
+
+void bss_clear(void)
+{
+	char *bss_start = &__bss_start;
+	char *bss_end = &__bss_end;
+	char *rel_dyn_end = &__rel_dyn_end;
+
+	char *start;
+
+	if (rel_dyn_end >= bss_start && rel_dyn_end <= bss_end)
+		start = rel_dyn_end;
+	else
+		start = bss_start;
+
+	u32 *pt;
+	size_t sz = bss_end - start;
+
+	for (int i = 0; i < sz; i += 4) {
+		pt = (u32 *)(start + i);
+		*pt = 0;
+	}
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
index 0000000000..9abecbe1dd
--- /dev/null
+++ b/board/adi/sc598-som-ezkit/Kconfig
@@ -0,0 +1,100 @@
+# SPDX-License-Identifier: GPL-2.0-or-later
+#
+# (C) Copyright 2024 - Analog Devices, Inc.
+
+if TARGET_SC598_SOM_EZKIT
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
+config ADI_IMAGE
+	default "minimal"
+
+config CUSTOM_SYS_INIT_SP_ADDR
+	default 0x96000000
+
+# SPL
+
+config SPL_OF_LIBFDT_ASSUME_MASK
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
diff --git a/common/spl/Kconfig b/common/spl/Kconfig
index c08ff06449..48775b04bb 100644
--- a/common/spl/Kconfig
+++ b/common/spl/Kconfig
@@ -86,6 +86,7 @@ config SPL_MAX_SIZE
 	default 0x5fa0 if SUNXI_SRAM_ADDRESS = 0x0
 	default 0x10000 if ASPEED_AST2600
 	default 0x27000 if IMX8MM && SPL_TEXT_BASE = 0x7E1000
+	default 0x30000 if ARCH_SC5XX && SC59X_64
 	default 0x0
 	help
 	  Maximum size of the SPL image (text, data, rodata, and linker lists
@@ -110,7 +111,7 @@ config SPL_PAD_TO
 config SPL_HAS_BSS_LINKER_SECTION
 	depends on SPL_FRAMEWORK
 	bool "Use a specific address for the BSS via the linker script"
-	default y if ARCH_SUNXI || ARCH_MX6 || ARCH_OMAP2PLUS || MIPS || RISCV || ARCH_ZYNQMP
+	default y if ARCH_SUNXI || ARCH_MX6 || ARCH_OMAP2PLUS || MIPS || RISCV || ARCH_ZYNQMP || ARCH_SC5XX
 
 config SPL_BSS_START_ADDR
 	hex "Link address for the BSS within the SPL binary"
@@ -122,6 +123,7 @@ config SPL_BSS_START_ADDR
 	default 0x4ff80000 if ARCH_SUNXI && !(MACH_SUN9I || MACH_SUNIV)
 	default 0x2ff80000 if ARCH_SUNXI && MACH_SUN9I
 	default 0x1000 if ARCH_ZYNQMP
+	default 0x200B0000 if ARCH_SC5XX && SC59X_64
 
 choice
 	prompt "Enforce SPL BSS limit"
@@ -150,6 +152,7 @@ config SPL_BSS_MAX_SIZE
 	depends on SPL_BSS_LIMIT
 	default 0x100000 if ARCH_MX6 || RISCV
 	default 0x80000 if ARCH_OMAP2PLUS || ARCH_SUNXI
+	default 0x10000 if ARCH_SC5XX
 	help
 	  When non-zero, the linker checks that the actual memory used by SPL
 	  from __bss_start to __bss_end does not exceed it.
@@ -268,6 +271,7 @@ config SPL_TEXT_BASE
 	default 0x20060 if SUN50I_GEN_H6 || SUNXI_GEN_NCAT2
 	default 0x00060 if ARCH_SUNXI
 	default 0xfffc0000 if ARCH_ZYNQMP
+	default 0x20080000 if ARCH_SC5XX
 	default 0x0
 	help
 	  The address in memory that SPL will be running from.
@@ -369,7 +373,7 @@ config SPL_SYS_MALLOC_SIMPLE
 config SPL_SHARES_INIT_SP_ADDR
 	bool "SPL and U-Boot use the same initial stack pointer location"
 	depends on (ARM || ARCH_JZ47XX || MICROBLAZE || RISCV) && SPL_FRAMEWORK
-	default n if ARCH_SUNXI || ARCH_MX6 || ARCH_MX7
+	default n if ARCH_SUNXI || ARCH_MX6 || ARCH_MX7 || ARCH_SC5XX
 	default y
 	help
 	  In many cases, we can use the same initial stack pointer address for
@@ -390,6 +394,7 @@ config SPL_STACK
 	default 0x54000 if MACH_SUN50I || MACH_SUN50I_H5
 	default 0x18000 if MACH_SUN9I
 	default 0x8000 if ARCH_SUNXI
+	default 0x200E4000 if ARCH_SC5XX && SC59X_64
 	help
 	  Address of the start of the stack SPL will use before SDRAM is
 	  initialized.
@@ -1124,6 +1129,7 @@ config SPL_PAYLOAD_ARGS_ADDR
 	hex "Address in memory to load 'args' file for Falcon Mode to"
 	depends on SPL_OS_BOOT || SPL_LOAD_FIT_OPENSBI_OS_BOOT
 	default 0x88000000 if ARCH_OMAP2PLUS
+	default 0x99000000 if ARCH_SC5XX && SC59X_64
 	help
 	  Address in memory where the 'args' file, typically a device tree
 	  will be loaded in to memory.
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

