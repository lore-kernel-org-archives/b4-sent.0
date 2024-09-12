From: Oliver Gaskell <Oliver.Gaskell@analog.com>
Date: Thu, 12 Sep 2024 16:51:01 +0100
Subject: [PATCH v2 20/20] arm: SC573-EZKIT initial support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240912-sc5xx-upstreaming-patches-v2-20-1185a80df79e@analog.com>
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
 Oliver Gaskell <Oliver.Gaskell@analog.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726156261; l=7536;
 i=Oliver.Gaskell@analog.com; s=20240821; h=from:subject:message-id;
 bh=qjQtLVVlQxUcOA2JnCboJVfD1xmRp3AG5KCmDv6yQCY=;
 b=S1p9uNYVa875U8gGmquSyWGq4Ws2ZjFGKPEfnVO7QJJmkoEbPvh6qBT22Tdd8cgCsSt/X1GD8
 SSzhntshOf7DM4NSFEaWDcSIeTnfXD9D1AY2oHwLmwT/Z90tq+cRYKB
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
Signed-off-by: Greg Malysa <greg.malysa@timesys.com>
Co-developed-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
Signed-off-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
Signed-off-by: Oliver Gaskell <Oliver.Gaskell@analog.com>
---
 Kconfig                               |   1 +
 arch/arm/mach-sc5xx/Kconfig           |   9 +++
 arch/arm/mach-sc5xx/Makefile          |   1 +
 arch/arm/mach-sc5xx/sc57x-spl.c       |  26 ++++++++
 board/adi/sc573-ezkit/Kconfig         | 116 ++++++++++++++++++++++++++++++++++
 board/adi/sc573-ezkit/sc573-ezkit.env |  13 ++++
 common/spl/Kconfig                    |   4 +-
 include/configs/sc573-ezkit.h         |  18 ++++++
 8 files changed, 187 insertions(+), 1 deletion(-)

diff --git a/Kconfig b/Kconfig
index 6853219dd5..709271ef0b 100644
--- a/Kconfig
+++ b/Kconfig
@@ -649,6 +649,7 @@ config TEXT_BASE
 	default 0xB2200000 if ARCH_SC5XX && SC59X
 	default 0x89200000 if ARCH_SC5XX && TARGET_SC584_EZKIT
 	default 0xC2200000 if ARCH_SC5XX && (TARGET_SC589_EZKIT || TARGET_SC589_MINI)
+	default 0x82200000 if ARCH_SC5XX && SC57X
 	hex "Text Base"
 	help
 	  The address in memory that U-Boot will be copied and executed from
diff --git a/arch/arm/mach-sc5xx/Kconfig b/arch/arm/mach-sc5xx/Kconfig
index 6f8ea453b0..30444f04fc 100644
--- a/arch/arm/mach-sc5xx/Kconfig
+++ b/arch/arm/mach-sc5xx/Kconfig
@@ -25,6 +25,7 @@ config SC57X
 	bool "SC57x series"
 	select COMMON_CLK_ADI_SC57X
 	select CPU_V7A
+	select TARGET_SC573_EZKIT
 
 config SC58X
 	bool "SC58x series"
@@ -49,6 +50,13 @@ config SC59X_64
 
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
@@ -555,5 +563,6 @@ source "board/adi/sc594-som-ezlite/Kconfig"
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
diff --git a/board/adi/sc573-ezkit/Kconfig b/board/adi/sc573-ezkit/Kconfig
new file mode 100644
index 0000000000..328563c129
--- /dev/null
+++ b/board/adi/sc573-ezkit/Kconfig
@@ -0,0 +1,116 @@
+# SPDX-License-Identifier: GPL-2.0-or-later
+#
+# (C) Copyright 2024 - Analog Devices, Inc.
+
+if TARGET_SC573_EZKIT
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
+config ADI_IMAGE
+	default "tiny"
+
+config CUSTOM_SYS_INIT_SP_ADDR
+	default 0x8203f000
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
diff --git a/common/spl/Kconfig b/common/spl/Kconfig
index a7378bea8f..6dc0b6444c 100644
--- a/common/spl/Kconfig
+++ b/common/spl/Kconfig
@@ -87,7 +87,7 @@ config SPL_MAX_SIZE
 	default 0x10000 if ASPEED_AST2600
 	default 0x27000 if IMX8MM && SPL_TEXT_BASE = 0x7E1000
 	default 0x30000 if ARCH_SC5XX && (SC59X_64 || SC59X)
-	default 0x20000 if ARCH_SC5XX && SC58X
+	default 0x20000 if ARCH_SC5XX && (SC58X || SC57X)
 	default 0x0
 	help
 	  Maximum size of the SPL image (text, data, rodata, and linker lists
@@ -126,6 +126,7 @@ config SPL_BSS_START_ADDR
 	default 0x1000 if ARCH_ZYNQMP
 	default 0x200B0000 if ARCH_SC5XX && (SC59X_64 || SC59X)
 	default 0x20080000 if ARCH_SC5XX && SC58X
+	default 0x200A0000 if ARCH_SC5XX && SC57X
 
 choice
 	prompt "Enforce SPL BSS limit"
@@ -398,6 +399,7 @@ config SPL_STACK
 	default 0x8000 if ARCH_SUNXI
 	default 0x200E4000 if ARCH_SC5XX && (SC59X_64 || SC59X)
 	default 0x200B0000 if ARCH_SC5XX && SC58X
+	default 0x200D0000 if ARCH_SC5XX && SC57X
 	help
 	  Address of the start of the stack SPL will use before SDRAM is
 	  initialized.
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

