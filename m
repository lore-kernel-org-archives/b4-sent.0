From: Oliver Gaskell <Oliver.Gaskell@analog.com>
Date: Wed, 28 Aug 2024 11:02:28 +0100
Subject: [PATCH 20/20] arm: SC573-EZKIT initial support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240828-sc5xx-upstreaming-patches-v1-20-44d9adfdf327@analog.com>
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
 Oliver Gaskell <Oliver.Gaskell@analog.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724839434; l=7147;
 i=Oliver.Gaskell@analog.com; s=20240821; h=from:subject:message-id;
 bh=ucsappLohmmrXaoGkSKqXtBgWNA6Qpjw7OxSagzx+co=;
 b=LtdDznKF4P/iNX3+G8MHzxb0c68QpkDrh0JwUcslt89qO3x2a0kiIXpgu5HZLKVqFIocmykYu
 gXi4PJiACpxD6Ho3+ggI+/oM1cBJnqNHcDF24yF8qpXglDabkG8jrMq
X-Developer-Key: i=Oliver.Gaskell@analog.com; a=ed25519;
 pk=Icq9TxwFJ6FePHS28YbBWMvtZpFWxpPQLhLA9cNvZ/Y=
X-Endpoint-Received: by B4 Relay for Oliver.Gaskell@analog.com/20240821 with auth_id=197
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds support for Analog Devices' SC573-EZKIT board. Includes:
- SoC specific configs in mach-sc5xx/Kconfig
- Memory Map for SPL
- Necessary board-specific init functions
- Board-specific Kconfig and environment in board/adi/
- Memory configuration

Co-developed-by: Greg Malysa <greg.malysa@timesys.com>
Co-developed-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
Signed-off-by: Oliver Gaskell <Oliver.Gaskell@analog.com>
---
 arch/arm/mach-sc5xx/Kconfig           |   9 ++
 arch/arm/mach-sc5xx/Makefile          |   1 +
 arch/arm/mach-sc5xx/sc57x-spl.c       |  26 ++++++
 arch/arm/mach-sc5xx/soc.c             |   4 +-
 board/adi/sc573-ezkit/Kconfig         | 160 ++++++++++++++++++++++++++++++++++
 board/adi/sc573-ezkit/sc573-ezkit.env |  13 +++
 include/configs/sc573-ezkit.h         |  18 ++++
 7 files changed, 229 insertions(+), 2 deletions(-)

diff --git a/arch/arm/mach-sc5xx/Kconfig b/arch/arm/mach-sc5xx/Kconfig
index d9cf38a3b5..9b26342bc3 100644
--- a/arch/arm/mach-sc5xx/Kconfig
+++ b/arch/arm/mach-sc5xx/Kconfig
@@ -22,6 +22,7 @@ config SC57X
 	bool "SC57x series"
 	select CPU_V7A
 	select COMMON_CLK_ADI_SC57X
+	select TARGET_SC573_EZKIT
 
 config SC58X
 	bool "SC58x series"
@@ -46,6 +47,13 @@ config SC59X_64
 
 endchoice
 
+if SC57X
+
+config TARGET_SC573_EZKIT
+	bool "Support SC573-EZKIT"
+
+endif
+
 if SC58X
 
 choice
@@ -552,5 +560,6 @@ source "board/adi/sc594-som-ezlite/Kconfig"
 source "board/adi/sc589-ezkit/Kconfig"
 source "board/adi/sc589-mini/Kconfig"
 source "board/adi/sc584-ezkit/Kconfig"
+source "board/adi/sc573-ezkit/Kconfig"
 
 endif
diff --git a/arch/arm/mach-sc5xx/Makefile b/arch/arm/mach-sc5xx/Makefile
index 9a00a430b4..cac768ba56 100644
--- a/arch/arm/mach-sc5xx/Makefile
+++ b/arch/arm/mach-sc5xx/Makefile
@@ -11,6 +11,7 @@
 obj-y += soc.o init/
 
 obj-$(CONFIG_SC57X) += sc57x.o
+obj-$(CONFIG_SC57X) += sc57x-spl.o
 obj-$(CONFIG_SC58X) += sc58x.o
 obj-$(CONFIG_SC58X) += sc58x-spl.o
 obj-$(CONFIG_SC59X) += sc59x.o
diff --git a/arch/arm/mach-sc5xx/sc57x-spl.c b/arch/arm/mach-sc5xx/sc57x-spl.c
new file mode 100644
index 0000000000..28380b89b4
--- /dev/null
+++ b/arch/arm/mach-sc5xx/sc57x-spl.c
@@ -0,0 +1,26 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * (C) Copyright 2024 - Analog Devices, Inc.
+ */
+
+#include <asm/arch-adi/sc5xx/spl.h>
+
+// Table 45-16 in SC573 HRM
+const struct adi_boot_args adi_rom_boot_args[] = {
+	// JTAG/no boot
+	[0] = {0, 0, 0},
+	// SPI master, used for qspi as well
+	[1] = {0x60020000, 0x00040000, 0x00010207},
+	// SPI slave
+	[2] = {0, 0, 0x00000212},
+	// UART slave
+	[3] = {0, 0, 0x00000013},
+	// Linkport slave
+	[4] = {0, 0, 0x00000014},
+	// reserved, no boot
+	[5] = {0, 0, 0},
+	// reserved, no boot
+	[6] = {0, 0, 0},
+	// reserved, also no boot
+	[7] = {0, 0, 0}
+};
diff --git a/arch/arm/mach-sc5xx/soc.c b/arch/arm/mach-sc5xx/soc.c
index 9f2e66d729..4976243fb9 100644
--- a/arch/arm/mach-sc5xx/soc.c
+++ b/arch/arm/mach-sc5xx/soc.c
@@ -173,7 +173,7 @@ void fixup_dp83867_phy(struct phy_device *phydev)
 }
 
 extern char __bss_start, __bss_end;
-#if defined(CONFIG_SC58X)
+#if defined(CONFIG_SC57X) || defined(CONFIG_SC58X)
 extern char __rel_dyn_start, __rel_dyn_end;
 #endif
 
@@ -186,7 +186,7 @@ void bss_clear(void)
 	sz = &__bss_end - &__bss_start;
 	for (i = 0; i < sz; i += 4)
 		*to++ = 0;
-	#elif defined(CONFIG_SC58X)
+	#elif defined(CONFIG_SC57X) || defined(CONFIG_SC58X)
 	u32 bss_start = (u32)&__bss_start;
 	u32 bss_end = (u32)&__bss_end;
 	u32 rel_dyn_end = (u32)&__rel_dyn_end;
diff --git a/board/adi/sc573-ezkit/Kconfig b/board/adi/sc573-ezkit/Kconfig
new file mode 100644
index 0000000000..91da4f1e05
--- /dev/null
+++ b/board/adi/sc573-ezkit/Kconfig
@@ -0,0 +1,160 @@
+# SPDX-License-Identifier: GPL-2.0-or-later
+#
+# (C) Copyright 2024 - Analog Devices, Inc.
+
+if TARGET_SC573_EZKIT
+
+config SYS_VENDOR
+	default "adi"
+
+config SYS_BOARD
+	default "sc573-ezkit"
+
+config SYS_CONFIG_NAME
+	default "sc573-ezkit"
+
+config LDR_CPU
+	default "ADSP-SC573-0.0"
+
+config DEFAULT_DEVICE_TREE
+	default "sc573-ezkit"
+
+config SPL_MAX_SIZE
+	default 0x20000 # 128KB
+
+config ADI_IMAGE
+	default "tiny"
+
+config SPL_BSS_START_ADDR
+	hex
+	default 0x200A0000
+
+config SPL_BSS_MAX_SIZE
+	hex
+	default 0x10000 # 64K
+
+config SYS_SPL_MALLOC_START
+	hex
+	default 0x200B0000
+
+config SYS_SPL_MALLOC_SIZE
+	hex
+	default 0x10000 # 64K
+
+config SPL_STACK
+	hex
+	default 0x200D0000
+
+config SPL_STACK_SIZE
+	hex
+	default 0x10000 # 64K
+
+config TEXT_BASE
+	hex
+	default 0x82200000
+
+config CUSTOM_SYS_INIT_SP_ADDR
+	hex
+	default 0x8203f000
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
+	default 10000000
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
diff --git a/board/adi/sc573-ezkit/sc573-ezkit.env b/board/adi/sc573-ezkit/sc573-ezkit.env
new file mode 100644
index 0000000000..26f7b6cb79
--- /dev/null
+++ b/board/adi/sc573-ezkit/sc573-ezkit.env
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
+loadaddr=0x83000000
+jffs2file=adsp-sc5xx-__stringify(CONFIG_ADI_IMAGE)-adsp-sc573-ezkit.jffs2
diff --git a/include/configs/sc573-ezkit.h b/include/configs/sc573-ezkit.h
new file mode 100644
index 0000000000..42e42f8150
--- /dev/null
+++ b/include/configs/sc573-ezkit.h
@@ -0,0 +1,18 @@
+/* SPDX-License-Identifier: GPL-2.0-or-later */
+/*
+ * (C) Copyright 2024 - Analog Devices, Inc.
+ */
+
+#ifndef __CONFIG_SC573_EZKIT_H
+#define __CONFIG_SC573_EZKIT_H
+
+/*
+ * Memory Settings
+ */
+#define MEM_MT41K128M16JT
+#define MEM_DMC0
+
+#define CFG_SYS_SDRAM_BASE	0x82000000
+#define CFG_SYS_SDRAM_SIZE	0xe000000
+
+#endif

-- 
2.34.1

