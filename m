From: Oliver Gaskell <Oliver.Gaskell@analog.com>
Date: Wed, 28 Aug 2024 11:02:23 +0100
Subject: [PATCH 15/20] arm: SC594-SOM-EZKIT initial support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240828-sc5xx-upstreaming-patches-v1-15-44d9adfdf327@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724839434; l=7033;
 i=Oliver.Gaskell@analog.com; s=20240821; h=from:subject:message-id;
 bh=sYuy/YkBdmEAedGkRekKyMOYGSQ3QF2AUcu8G7VvB6k=;
 b=IG1LFM92EasbFch4POp3LHiEdskHTvZWFH0IgW9NSqR3bk8YxfNIU40eBFvF2erpYvYvBHFz8
 Q22NU25zU7ZADKxwsolzDz2fuHIjfo2lHe4nGA26vfYQviAvAzKH2Ih
X-Developer-Key: i=Oliver.Gaskell@analog.com; a=ed25519;
 pk=Icq9TxwFJ6FePHS28YbBWMvtZpFWxpPQLhLA9cNvZ/Y=
X-Endpoint-Received: by B4 Relay for Oliver.Gaskell@analog.com/20240821 with auth_id=197
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds support for Analog Devices' SC594-SOM-EZKIT board. Includes:
- SoC specific configs in mach-sc5xx/Kconfig
- Memory Map for SPL
- Necessary board-specific init functions
- Board-specific Kconfig and environment in board/adi/
- Memory configuration

Co-developed-by: Greg Malysa <greg.malysa@timesys.com>
Co-developed-by: Trevor Woerner <twoerner@gmail.com>
Co-developed-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
Co-developed-by: Ian Roberts <ian.roberts@timesys.com>
Signed-off-by: Oliver Gaskell <Oliver.Gaskell@analog.com>
---
 arch/arm/mach-sc5xx/Kconfig                   |  17 ++-
 arch/arm/mach-sc5xx/Makefile                  |   1 +
 arch/arm/mach-sc5xx/sc59x-spl.c               |  26 ++++
 board/adi/sc594-som-ezkit/Kconfig             | 181 ++++++++++++++++++++++++++
 board/adi/sc594-som-ezkit/sc594-som-ezkit.env |  13 ++
 include/configs/sc594-som.h                   |  19 +++
 6 files changed, 256 insertions(+), 1 deletion(-)

diff --git a/arch/arm/mach-sc5xx/Kconfig b/arch/arm/mach-sc5xx/Kconfig
index b3a17036e7..fd7029974b 100644
--- a/arch/arm/mach-sc5xx/Kconfig
+++ b/arch/arm/mach-sc5xx/Kconfig
@@ -32,7 +32,7 @@ config SC59X
 	bool "SC59x 32-bit series"
 	select CPU_V7A
 	select COMMON_CLK_ADI_SC594
-	select NOP_PHY
+	select NOP_PHY if PHY
 
 config SC59X_64
 	bool "SC59x 64-bit series"
@@ -46,6 +46,20 @@ config SC59X_64
 
 endchoice
 
+if SC59X
+
+choice
+	prompt "SC59x 32-bit board select"
+
+config TARGET_SC594_SOM_EZKIT
+	bool
+	prompt "SC594-SOM with SOMCRR-EZKIT"
+	select ADI_CARRIER_SOMCRR_EZKIT
+
+endchoice
+
+endif
+
 if SC59X_64
 
 choice
@@ -506,5 +520,6 @@ config PINCTRL_ADI
 
 source "board/adi/sc598-som-ezkit/Kconfig"
 source "board/adi/sc598-som-ezlite/Kconfig"
+source "board/adi/sc594-som-ezkit/Kconfig"
 
 endif
diff --git a/arch/arm/mach-sc5xx/Makefile b/arch/arm/mach-sc5xx/Makefile
index 0955c509a5..a8079b6120 100644
--- a/arch/arm/mach-sc5xx/Makefile
+++ b/arch/arm/mach-sc5xx/Makefile
@@ -13,6 +13,7 @@ obj-y += soc.o init/
 obj-$(CONFIG_SC57X) += sc57x.o
 obj-$(CONFIG_SC58X) += sc58x.o
 obj-$(CONFIG_SC59X) += sc59x.o
+obj-$(CONFIG_SC59X) += sc59x-spl.o
 obj-$(CONFIG_SC59X_64) += sc59x_64.o
 obj-$(CONFIG_SC59X_64) += sc59x_64-spl.o
 
diff --git a/arch/arm/mach-sc5xx/sc59x-spl.c b/arch/arm/mach-sc5xx/sc59x-spl.c
new file mode 100644
index 0000000000..c8fc25fe7c
--- /dev/null
+++ b/arch/arm/mach-sc5xx/sc59x-spl.c
@@ -0,0 +1,26 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * (C) Copyright 2024 - Analog Devices, Inc.
+ */
+
+#include <asm/arch-adi/sc5xx/spl.h>
+
+// Table 45-14 in sc594 HRM
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
+	// reserved, no boot
+	[6] = {0, 0, 0},
+	// reserved, also no boot
+	[7] = {0, 0, 0}
+};
diff --git a/board/adi/sc594-som-ezkit/Kconfig b/board/adi/sc594-som-ezkit/Kconfig
new file mode 100644
index 0000000000..09e22141d4
--- /dev/null
+++ b/board/adi/sc594-som-ezkit/Kconfig
@@ -0,0 +1,181 @@
+# SPDX-License-Identifier: GPL-2.0-or-later
+#
+# (C) Copyright 2024 - Analog Devices, Inc.
+
+if TARGET_SC594_SOM_EZKIT
+
+config SYS_VENDOR
+	default "adi"
+
+config LDR_CPU
+	default "ADSP-SC594-0.0"
+
+config SYS_BOARD
+	default "sc594-som-ezkit"
+
+config SYS_CONFIG_NAME
+	default "sc594-som"
+
+config DEFAULT_DEVICE_TREE
+	default "sc594-som-ezkit"
+
+config SPL_MAX_SIZE
+	default 0x30000 # 256KB
+
+config ADI_IMAGE
+	default "minimal"
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
+	default 0xB2200000
+
+config CUSTOM_SYS_INIT_SP_ADDR
+	hex
+	default 0xA003f000
+
+config SYS_LOAD_ADDR
+	hex
+	default 0x0
+
+# SPL
+
+config SPL_TEXT_BASE
+	hex
+	default 0x20080000
+
+config SPL_PAYLOAD_ARGS_ADDR
+	hex
+	default 0xA0000000
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
+# Clocks
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
+	default 2
+
+config CGU0_OCLK_DIV
+	default 16
+
+config CGU0_DIV_S1SELEX
+	default 6
+
+config CGU1_VCO_MULT
+	default 64
+
+config CGU1_DF_DIV
+	default 0
+
+config CGU1_CCLK_DIV
+	default 2
+
+config CGU1_SCLK_DIV
+	default 4
+
+config CGU1_SCLK0_DIV
+	default 4
+
+config CGU1_SCLK1_DIV
+	default 2
+
+config CGU1_DCLK_DIV
+	default 2
+
+config CGU1_OCLK_DIV
+	default 16
+
+config CGU1_DIV_S1SELEX
+	default 6
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
+	default 3
+
+config CDU0_CLKO4
+	default 3
+
+config CDU0_CLKO5
+	default 1
+
+config CDU0_CLKO6
+	default 1
+
+config CDU0_CLKO7
+	default 1
+
+config CDU0_CLKO8
+	default 3
+
+config CDU0_CLKO9
+	default 1
+
+config CDU0_CLKO10
+	default 1
+
+config CDU0_CLKO12
+	default 1
+
+endif
diff --git a/board/adi/sc594-som-ezkit/sc594-som-ezkit.env b/board/adi/sc594-som-ezkit/sc594-som-ezkit.env
new file mode 100644
index 0000000000..83d6b457a0
--- /dev/null
+++ b/board/adi/sc594-som-ezkit/sc594-som-ezkit.env
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
+adi_image_offset=0x0120000
+adi_rfs_offset=0x1020000
+loadaddr=0xA2000000
+jffs2file=adsp-sc5xx-__stringify(CONFIG_ADI_IMAGE)-adsp-sc594-som-ezkit.jffs2
diff --git a/include/configs/sc594-som.h b/include/configs/sc594-som.h
new file mode 100644
index 0000000000..ba9b0cdb0c
--- /dev/null
+++ b/include/configs/sc594-som.h
@@ -0,0 +1,19 @@
+/* SPDX-License-Identifier: GPL-2.0-or-later */
+/*
+ * (C) Copyright 2024 - Analog Devices, Inc.
+ */
+
+#ifndef __CONFIG_SC594_SOM_H
+#define __CONFIG_SC594_SOM_H
+
+/*
+ * Memory Settings
+ */
+#define MEM_IS43TR16512BL
+#define MEM_ISSI_8Gb_DDR3_800MHZ
+#define MEM_DMC0
+
+#define CFG_SYS_SDRAM_BASE	0xA0000000
+#define CFG_SYS_SDRAM_SIZE	0x20000000
+
+#endif

-- 
2.34.1

