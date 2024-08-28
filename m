From: Oliver Gaskell <Oliver.Gaskell@analog.com>
Date: Wed, 28 Aug 2024 11:02:22 +0100
Subject: [PATCH 14/20] arm: SC598-SOM-EZLITE initial support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240828-sc5xx-upstreaming-patches-v1-14-44d9adfdf327@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724839434; l=4067;
 i=Oliver.Gaskell@analog.com; s=20240821; h=from:subject:message-id;
 bh=YLyEL6ITWehoiQARPsFI7ZAnETeirU+Gf3uKxS/f2PA=;
 b=T148U5KLlv2uOQ956SowDhkfSffcO+k3oJljB61Zip6qc4t/95AHfjuZeV1tQAfEICf0SSztd
 Y/JpgHjcCBaDi0iVF3pK8mp3vKbYveFhKXi21BOWBgINRIFsf4OLDsC
X-Developer-Key: i=Oliver.Gaskell@analog.com; a=ed25519;
 pk=Icq9TxwFJ6FePHS28YbBWMvtZpFWxpPQLhLA9cNvZ/Y=
X-Endpoint-Received: by B4 Relay for Oliver.Gaskell@analog.com/20240821 with auth_id=197
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds support for Analog Devices' SC598-SOM-EZLITE board. Includes:
- Board specific configs in mach-sc5xx/Kconfig
- Board-specific Kconfig and environment in board/adi/

Signed-off-by: Oliver Gaskell <Oliver.Gaskell@analog.com>
---
 arch/arm/mach-sc5xx/Kconfig                     |   6 +
 board/adi/sc598-som-ezlite/Kconfig              | 150 ++++++++++++++++++++++++
 board/adi/sc598-som-ezlite/sc598-som-ezlite.env |  13 ++
 3 files changed, 169 insertions(+)

diff --git a/arch/arm/mach-sc5xx/Kconfig b/arch/arm/mach-sc5xx/Kconfig
index cd3c7011f4..b3a17036e7 100644
--- a/arch/arm/mach-sc5xx/Kconfig
+++ b/arch/arm/mach-sc5xx/Kconfig
@@ -51,6 +51,11 @@ if SC59X_64
 choice
 	prompt "SC59x 64-bit board select"
 
+config TARGET_SC598_SOM_EZLITE
+	bool
+	prompt "SC598-SOM with SOMCRR-EZLITE"
+	select ADI_CARRIER_SOMCRR_EZLITE
+
 config TARGET_SC598_SOM_EZKIT
 	bool
 	prompt "SC598-SOM with SOMCRR-EZKIT"
@@ -500,5 +505,6 @@ config PINCTRL_ADI
 	default y
 
 source "board/adi/sc598-som-ezkit/Kconfig"
+source "board/adi/sc598-som-ezlite/Kconfig"
 
 endif
diff --git a/board/adi/sc598-som-ezlite/Kconfig b/board/adi/sc598-som-ezlite/Kconfig
new file mode 100644
index 0000000000..0dbb89cde5
--- /dev/null
+++ b/board/adi/sc598-som-ezlite/Kconfig
@@ -0,0 +1,150 @@
+# SPDX-License-Identifier: GPL-2.0-or-later
+#
+# (C) Copyright 2024 - Analog Devices, Inc.
+
+if TARGET_SC598_SOM_EZLITE
+
+config SYS_VENDOR
+	default "adi"
+
+config LDR_CPU
+	default "ADSP-SC598-0.0"
+
+config SYS_BOARD
+	default "sc598-som-ezlite"
+
+config SYS_CONFIG_NAME
+	default "sc598-som"
+
+config DEFAULT_DEVICE_TREE
+	default "sc598-som-ezlite"
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
diff --git a/board/adi/sc598-som-ezlite/sc598-som-ezlite.env b/board/adi/sc598-som-ezlite/sc598-som-ezlite.env
new file mode 100644
index 0000000000..036c9ae759
--- /dev/null
+++ b/board/adi/sc598-som-ezlite/sc598-som-ezlite.env
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
+jffs2file=adsp-sc5xx-__stringify(CONFIG_ADI_IMAGE)-adsp-sc598-som-ezlite.jffs2

-- 
2.34.1

