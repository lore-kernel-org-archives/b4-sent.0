From: Oliver Gaskell <Oliver.Gaskell@analog.com>
Date: Thu, 12 Sep 2024 16:50:57 +0100
Subject: [PATCH v2 16/20] arm: SC594-SOM-EZLITE initial support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240912-sc5xx-upstreaming-patches-v2-16-1185a80df79e@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726156261; l=4389;
 i=Oliver.Gaskell@analog.com; s=20240821; h=from:subject:message-id;
 bh=/L8NMZm1pKklI8KZfDNeJIrU+vnx/Z5MLH1H53Arh/U=;
 b=S7EC4mG1vfzbH3/ozLxBuKDV5VsLUSN1JGgxyREbWq+NH79NBS6dmORWHnKnD+wv+aTVXQMwM
 UD6FtpUWkJEAb1BRDkMCNt5C86Un//ZibhSGzoq2g7mXJ9BkpNaK+1c
X-Developer-Key: i=Oliver.Gaskell@analog.com; a=ed25519;
 pk=Icq9TxwFJ6FePHS28YbBWMvtZpFWxpPQLhLA9cNvZ/Y=
X-Endpoint-Received: by B4 Relay for Oliver.Gaskell@analog.com/20240821 with auth_id=197
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds support for Analog Devices' SC594-SOM-EZLITE board. Includes:
- Board specific configs in mach-sc5xx/Kconfig
- Board-specific Kconfig and environment in board/adi/

Signed-off-by: Oliver Gaskell <Oliver.Gaskell@analog.com>
---
 arch/arm/mach-sc5xx/Kconfig                     |   6 ++
 board/adi/sc594-som-ezlite/Kconfig              | 133 ++++++++++++++++++++++++
 board/adi/sc594-som-ezlite/sc594-som-ezlite.env |  13 +++
 common/spl/Kconfig                              |   1 +
 4 files changed, 153 insertions(+)

diff --git a/arch/arm/mach-sc5xx/Kconfig b/arch/arm/mach-sc5xx/Kconfig
index e93f214441..b57c21cf16 100644
--- a/arch/arm/mach-sc5xx/Kconfig
+++ b/arch/arm/mach-sc5xx/Kconfig
@@ -54,6 +54,11 @@ if SC59X
 choice
 	prompt "SC59x 32-bit board select"
 
+config TARGET_SC594_SOM_EZLITE
+	bool
+	prompt "SC594-SOM with SOMCRR-EZLITE"
+	select ADI_CARRIER_SOMCRR_EZLITE
+
 config TARGET_SC594_SOM_EZKIT
 	bool
 	prompt "SC594-SOM with SOMCRR-EZKIT"
@@ -524,5 +529,6 @@ config PINCTRL_ADI
 source "board/adi/sc598-som-ezkit/Kconfig"
 source "board/adi/sc598-som-ezlite/Kconfig"
 source "board/adi/sc594-som-ezkit/Kconfig"
+source "board/adi/sc594-som-ezlite/Kconfig"
 
 endif
diff --git a/board/adi/sc594-som-ezlite/Kconfig b/board/adi/sc594-som-ezlite/Kconfig
new file mode 100644
index 0000000000..70436955b6
--- /dev/null
+++ b/board/adi/sc594-som-ezlite/Kconfig
@@ -0,0 +1,133 @@
+# SPDX-License-Identifier: GPL-2.0-or-later
+#
+# (C) Copyright 2024 - Analog Devices, Inc.
+
+if TARGET_SC594_SOM_EZLITE
+
+config LDR_CPU
+	default "ADSP-SC594-0.0"
+
+config SYS_BOARD
+	default "sc594-som-ezlite"
+
+config SYS_CONFIG_NAME
+	default "sc594-som"
+
+config DEFAULT_DEVICE_TREE
+	default "sc594-som-ezlite"
+
+config ADI_IMAGE
+	default "minimal"
+
+config CUSTOM_SYS_INIT_SP_ADDR
+	default 0x8203f000
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
diff --git a/board/adi/sc594-som-ezlite/sc594-som-ezlite.env b/board/adi/sc594-som-ezlite/sc594-som-ezlite.env
new file mode 100644
index 0000000000..152e1f14fd
--- /dev/null
+++ b/board/adi/sc594-som-ezlite/sc594-som-ezlite.env
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
+jffs2file=adsp-sc5xx-__stringify(CONFIG_ADI_IMAGE)-adsp-sc594-som-ezlite.jffs2
diff --git a/common/spl/Kconfig b/common/spl/Kconfig
index d46984b3ea..e723ff1996 100644
--- a/common/spl/Kconfig
+++ b/common/spl/Kconfig
@@ -1131,6 +1131,7 @@ config SPL_PAYLOAD_ARGS_ADDR
 	default 0x88000000 if ARCH_OMAP2PLUS
 	default 0x99000000 if ARCH_SC5XX && SC59X_64
 	default 0xA0000000 if ARCH_SC5XX && TARGET_SC594_SOM_EZKIT
+	default 0x80000000 if ARCH_SC5XX && TARGET_SC594_SOM_EZLITE
 	help
 	  Address in memory where the 'args' file, typically a device tree
 	  will be loaded in to memory.

-- 
2.34.1

