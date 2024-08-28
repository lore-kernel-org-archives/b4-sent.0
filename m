From: Oliver Gaskell <Oliver.Gaskell@analog.com>
Date: Wed, 28 Aug 2024 11:02:25 +0100
Subject: [PATCH 17/20] arm: SC584-EZKIT initial support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240828-sc5xx-upstreaming-patches-v1-17-44d9adfdf327@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724839434; l=7326;
 i=Oliver.Gaskell@analog.com; s=20240821; h=from:subject:message-id;
 bh=23UQSWjZWvGXRYzaoNdE6djFFH32B17hFZgUrs7mDgk=;
 b=sFD+h5Mweam4lWDkE10O8mObkDm9WlHpm5WPLuw281z70oahx/bHExAjbOU7tId5Oo5+Ztx/J
 kZDzYM3OUoBDgU0vTxMtl4yJWpE97bFD/2KxcCaAiOzVc+bU010alfv
X-Developer-Key: i=Oliver.Gaskell@analog.com; a=ed25519;
 pk=Icq9TxwFJ6FePHS28YbBWMvtZpFWxpPQLhLA9cNvZ/Y=
X-Endpoint-Received: by B4 Relay for Oliver.Gaskell@analog.com/20240821 with auth_id=197
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds support for Analog Devices' SC584-EZKIT board. Includes:
- SoC specific configs in mach-sc5xx/Kconfig
- Memory Map for SPL
- Necessary board-specific init functions
- Board-specific Kconfig and environment in board/adi/
- Memory configuration

Co-developed-by: Greg Malysa <greg.malysa@timesys.com>
Co-developed-by: Trevor Woerner <twoerner@gmail.com>
Co-developed-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
Signed-off-by: Oliver Gaskell <Oliver.Gaskell@analog.com>
---
 arch/arm/mach-sc5xx/Kconfig           |  15 ++++
 arch/arm/mach-sc5xx/Makefile          |   1 +
 arch/arm/mach-sc5xx/sc58x-spl.c       |  26 ++++++
 arch/arm/mach-sc5xx/soc.c             |  19 ++++
 board/adi/sc584-ezkit/Kconfig         | 160 ++++++++++++++++++++++++++++++++++
 board/adi/sc584-ezkit/sc584-ezkit.env |  13 +++
 include/configs/sc584-ezkit.h         |  18 ++++
 7 files changed, 252 insertions(+)

diff --git a/arch/arm/mach-sc5xx/Kconfig b/arch/arm/mach-sc5xx/Kconfig
index 89bc60d6a5..c75262bee4 100644
--- a/arch/arm/mach-sc5xx/Kconfig
+++ b/arch/arm/mach-sc5xx/Kconfig
@@ -46,6 +46,20 @@ config SC59X_64
 
 endchoice
 
+if SC58X
+
+choice
+	prompt "SC58x board select"
+
+config TARGET_SC584_EZKIT
+	bool
+	prompt "SC584-EZKIT"
+	select ADI_USE_DDR2
+
+endchoice
+
+endif
+
 if SC59X
 
 choice
@@ -527,5 +541,6 @@ source "board/adi/sc598-som-ezkit/Kconfig"
 source "board/adi/sc598-som-ezlite/Kconfig"
 source "board/adi/sc594-som-ezkit/Kconfig"
 source "board/adi/sc594-som-ezlite/Kconfig"
+source "board/adi/sc584-ezkit/Kconfig"
 
 endif
diff --git a/arch/arm/mach-sc5xx/Makefile b/arch/arm/mach-sc5xx/Makefile
index a8079b6120..9a00a430b4 100644
--- a/arch/arm/mach-sc5xx/Makefile
+++ b/arch/arm/mach-sc5xx/Makefile
@@ -12,6 +12,7 @@ obj-y += soc.o init/
 
 obj-$(CONFIG_SC57X) += sc57x.o
 obj-$(CONFIG_SC58X) += sc58x.o
+obj-$(CONFIG_SC58X) += sc58x-spl.o
 obj-$(CONFIG_SC59X) += sc59x.o
 obj-$(CONFIG_SC59X) += sc59x-spl.o
 obj-$(CONFIG_SC59X_64) += sc59x_64.o
diff --git a/arch/arm/mach-sc5xx/sc58x-spl.c b/arch/arm/mach-sc5xx/sc58x-spl.c
new file mode 100644
index 0000000000..ae809f09e5
--- /dev/null
+++ b/arch/arm/mach-sc5xx/sc58x-spl.c
@@ -0,0 +1,26 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * (C) Copyright 2024 - Analog Devices, Inc.
+ */
+
+#include <asm/arch-adi/sc5xx/spl.h>
+
+// Table 53-13 in SC58x HRM
+const struct adi_boot_args adi_rom_boot_args[] = {
+	// JTAG/no boot
+	[0] = {0, 0, 0},
+	// SPI master, used for qspi as well
+	[1] = {0x60020000, 0x00040000, 0x00010207},
+	// SPI slave
+	[2] = {0, 0, 0x00000212},
+	// reserved, no boot
+	[3] = {0, 0, 0},
+	// reserved, no boot
+	[4] = {0, 0, 0},
+	// reserved, also no boot
+	[5] = {0, 0, 0},
+	// Linkport slave
+	[6] = {0, 0, 0x00000014},
+	// UART slave
+	[7] = {0, 0, 0x00000013},
+};
diff --git a/arch/arm/mach-sc5xx/soc.c b/arch/arm/mach-sc5xx/soc.c
index 714b214bf6..9f2e66d729 100644
--- a/arch/arm/mach-sc5xx/soc.c
+++ b/arch/arm/mach-sc5xx/soc.c
@@ -173,6 +173,9 @@ void fixup_dp83867_phy(struct phy_device *phydev)
 }
 
 extern char __bss_start, __bss_end;
+#if defined(CONFIG_SC58X)
+extern char __rel_dyn_start, __rel_dyn_end;
+#endif
 
 void bss_clear(void)
 {
@@ -181,6 +184,22 @@ void bss_clear(void)
 	int i, sz;
 
 	sz = &__bss_end - &__bss_start;
+	for (i = 0; i < sz; i += 4)
+		*to++ = 0;
+	#elif defined(CONFIG_SC58X)
+	u32 bss_start = (u32)&__bss_start;
+	u32 bss_end = (u32)&__bss_end;
+	u32 rel_dyn_end = (u32)&__rel_dyn_end;
+	u32 *to;
+
+	if (rel_dyn_end >= bss_start && rel_dyn_end <= bss_end)
+		to = (u32 *)rel_dyn_end;
+	else
+		to = (u32 *)bss_start;
+
+	int i, sz;
+
+	sz = bss_end - (u32)to;
 	for (i = 0; i < sz; i += 4)
 		*to++ = 0;
 	#endif
diff --git a/board/adi/sc584-ezkit/Kconfig b/board/adi/sc584-ezkit/Kconfig
new file mode 100644
index 0000000000..f0c6bad663
--- /dev/null
+++ b/board/adi/sc584-ezkit/Kconfig
@@ -0,0 +1,160 @@
+# SPDX-License-Identifier: GPL-2.0-or-later
+#
+# (C) Copyright 2024 - Analog Devices, Inc.
+
+if TARGET_SC584_EZKIT
+
+config SYS_VENDOR
+	default "adi"
+
+config LDR_CPU
+	default	"ADSP-SC584-0.1"
+
+config SYS_BOARD
+	default "sc584-ezkit"
+
+config SYS_CONFIG_NAME
+	default "sc584-ezkit"
+
+config DEFAULT_DEVICE_TREE
+	default "sc584-ezkit"
+
+config SPL_MAX_SIZE
+	default 0x20000 # 128KB
+
+config ADI_IMAGE
+	default "tiny"
+
+config SPL_BSS_START_ADDR
+	hex
+	default 0x20080000
+
+config SPL_BSS_MAX_SIZE
+	hex
+	default 0x10000 # 64K
+
+config SYS_SPL_MALLOC_START
+	hex
+	default 0x20090000
+
+config SYS_SPL_MALLOC_SIZE
+	hex
+	default 0x10000 # 64K
+
+config SPL_STACK
+	hex
+	default 0x200B0000
+
+config SPL_STACK_SIZE
+	hex
+	default 0x10000 # 64K
+
+config TEXT_BASE
+	hex
+	default 0x89200000
+
+config CUSTOM_SYS_INIT_SP_ADDR
+	hex
+	default 0x8903f000
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
+# SPI Flash
+
+config SF_DEFAULT_BUS
+	default 2
+
+config SF_DEFAULT_CS
+	default 1
+
+config SF_DEFAULT_SPEED
+	default 5000000
+
+# Clocks
+
+config CGU0_DF_DIV
+	default 0
+
+config CGU0_VCO_MULT
+	default 18
+
+config CGU0_CCLK_DIV
+	default 1
+
+config CGU0_SCLK_DIV
+	default 2
+
+config CGU0_SCLK0_DIV
+	default 2
+
+config CGU0_SCLK1_DIV
+	default 2
+
+config CGU0_DCLK_DIV
+	default 2
+
+config CGU0_OCLK_DIV
+	default 3
+
+config CGU1_VCO_MULT
+	default 5
+
+config CGU1_DF_DIV
+	default 0
+
+config CGU1_CCLK_DIV
+	default 1
+
+config CGU1_SCLK_DIV
+	default 2
+
+config CGU1_SCLK0_DIV
+	default 2
+
+config CGU1_SCLK1_DIV
+	default 2
+
+config CGU1_DCLK_DIV
+	default 2
+
+config CGU1_OCLK_DIV
+	default 3
+
+config CDU0_CLKO0
+	default 1
+
+config CDU0_CLKO1
+	default 1
+
+config CDU0_CLKO2
+	default 1
+
+config CDU0_CLKO3
+	default 1
+
+config CDU0_CLKO4
+	default 1
+
+config CDU0_CLKO5
+	default 1
+
+config CDU0_CLKO6
+	default 1
+
+config CDU0_CLKO7
+	default 5
+
+config CDU0_CLKO8
+	default 1
+
+config CDU0_CLKO9
+	default 1
+
+endif
diff --git a/board/adi/sc584-ezkit/sc584-ezkit.env b/board/adi/sc584-ezkit/sc584-ezkit.env
new file mode 100644
index 0000000000..af9a9e01bc
--- /dev/null
+++ b/board/adi/sc584-ezkit/sc584-ezkit.env
@@ -0,0 +1,13 @@
+/* SPDX-License-Identifier: GPL-2.0-or-later+ */
+
+/*
+ * (C) Copyright 2024 - Analog Devices, Inc.
+ */
+
+#include <env/adi/adi_boot.env>
+
+adi_stage2_offset=0x20000
+adi_image_offset=0xE0000
+adi_rfs_offset=0x6E0000
+loadaddr=0x89300000
+jffs2file=adsp-sc5xx-__stringify(CONFIG_ADI_IMAGE)-adsp-sc584-ezkit.jffs2
diff --git a/include/configs/sc584-ezkit.h b/include/configs/sc584-ezkit.h
new file mode 100644
index 0000000000..905836cc2c
--- /dev/null
+++ b/include/configs/sc584-ezkit.h
@@ -0,0 +1,18 @@
+/* SPDX-License-Identifier: GPL-2.0-or-later */
+/*
+ * (C) Copyright 2024 - Analog Devices, Inc.
+ */
+
+#ifndef __CONFIG_SC584_EZKIT_H
+#define __CONFIG_SC584_EZKIT_H
+
+/*
+ * Memory Settings
+ */
+#define MEM_MT47H128M16RT
+#define MEM_DMC0
+
+#define CFG_SYS_SDRAM_BASE	0x89000000
+#define CFG_SYS_SDRAM_SIZE	0x7000000
+
+#endif

-- 
2.34.1

