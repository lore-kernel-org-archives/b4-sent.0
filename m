From: Oliver Gaskell <Oliver.Gaskell@analog.com>
Date: Thu, 12 Sep 2024 16:50:59 +0100
Subject: [PATCH v2 18/20] arm: SC589-EZKIT initial support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240912-sc5xx-upstreaming-patches-v2-18-1185a80df79e@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726156261; l=4560;
 i=Oliver.Gaskell@analog.com; s=20240821; h=from:subject:message-id;
 bh=rd9JAxKkEO18wZbWqHA0JfnebuP17MfuWHqOTowwyu0=;
 b=5I8rrQNcxpTvZzwFJ5T7p1Y/y0rROdmUe9jtWRCqbaKXSgAoru/RqwABEEIPmx5mi8H/iEDfz
 IlQkmovXD8bAa8THULlUlBfii4RXVF/IPUffQC3ttRm1obpVfKWdXN1
X-Developer-Key: i=Oliver.Gaskell@analog.com; a=ed25519;
 pk=Icq9TxwFJ6FePHS28YbBWMvtZpFWxpPQLhLA9cNvZ/Y=
X-Endpoint-Received: by B4 Relay for Oliver.Gaskell@analog.com/20240821 with auth_id=197
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds support for Analog Devices' SC589-EZKIT board. Includes:
- Board specific configs in mach-sc5xx/Kconfig
- Board-specific Kconfig and environment in board/adi/
- Memory configuration

Signed-off-by: Oliver Gaskell <Oliver.Gaskell@analog.com>
---
 Kconfig                               |   1 +
 arch/arm/mach-sc5xx/Kconfig           |   5 ++
 board/adi/sc589-ezkit/Kconfig         | 116 ++++++++++++++++++++++++++++++++++
 board/adi/sc589-ezkit/sc589-ezkit.env |  13 ++++
 include/configs/sc589.h               |  19 ++++++
 5 files changed, 154 insertions(+)

diff --git a/Kconfig b/Kconfig
index 2422b94e6d..bdae1b01d3 100644
--- a/Kconfig
+++ b/Kconfig
@@ -648,6 +648,7 @@ config TEXT_BASE
 	default 0x96000000 if ARCH_SC5XX && SC59X_64
 	default 0xB2200000 if ARCH_SC5XX && SC59X
 	default 0x89200000 if ARCH_SC5XX && TARGET_SC584_EZKIT
+	default 0xC2200000 if ARCH_SC5XX && TARGET_SC589_EZKIT
 	hex "Text Base"
 	help
 	  The address in memory that U-Boot will be copied and executed from
diff --git a/arch/arm/mach-sc5xx/Kconfig b/arch/arm/mach-sc5xx/Kconfig
index ac2b669940..408b943fd6 100644
--- a/arch/arm/mach-sc5xx/Kconfig
+++ b/arch/arm/mach-sc5xx/Kconfig
@@ -59,6 +59,10 @@ config TARGET_SC584_EZKIT
 	prompt "SC584-EZKIT"
 	select ADI_USE_DDR2
 
+config TARGET_SC589_EZKIT
+	bool
+	prompt "SC589-EZKIT"
+
 endchoice
 
 endif
@@ -544,6 +548,7 @@ source "board/adi/sc598-som-ezkit/Kconfig"
 source "board/adi/sc598-som-ezlite/Kconfig"
 source "board/adi/sc594-som-ezkit/Kconfig"
 source "board/adi/sc594-som-ezlite/Kconfig"
+source "board/adi/sc589-ezkit/Kconfig"
 source "board/adi/sc584-ezkit/Kconfig"
 
 endif
diff --git a/board/adi/sc589-ezkit/Kconfig b/board/adi/sc589-ezkit/Kconfig
new file mode 100644
index 0000000000..b5f555f3a2
--- /dev/null
+++ b/board/adi/sc589-ezkit/Kconfig
@@ -0,0 +1,116 @@
+# SPDX-License-Identifier: GPL-2.0-or-later
+#
+# (C) Copyright 2024 - Analog Devices, Inc.
+
+if TARGET_SC589_EZKIT
+
+config LDR_CPU
+	default	"ADSP-SC589-0.1"
+
+config SYS_BOARD
+	default "sc589-ezkit"
+
+config SYS_CONFIG_NAME
+	default "sc589"
+
+config DEFAULT_DEVICE_TREE
+	default "sc589-ezkit"
+
+config ADI_IMAGE
+	default "tiny"
+
+config CUSTOM_SYS_INIT_SP_ADDR
+	default 0xC203f000
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
+	default 1
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
diff --git a/board/adi/sc589-ezkit/sc589-ezkit.env b/board/adi/sc589-ezkit/sc589-ezkit.env
new file mode 100644
index 0000000000..34b924992a
--- /dev/null
+++ b/board/adi/sc589-ezkit/sc589-ezkit.env
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
+loadaddr=0xC3000000
+jffs2file=adsp-sc5xx-__stringify(CONFIG_ADI_IMAGE)-adsp-sc589-ezkit.jffs2
diff --git a/include/configs/sc589.h b/include/configs/sc589.h
new file mode 100644
index 0000000000..137c80be8e
--- /dev/null
+++ b/include/configs/sc589.h
@@ -0,0 +1,19 @@
+/* SPDX-License-Identifier: GPL-2.0-or-later */
+/*
+ * (C) Copyright 2024 - Analog Devices, Inc.
+ */
+
+#ifndef __CONFIG_SC589_H
+#define __CONFIG_SC589_H
+
+/*
+ * Memory Settings
+ */
+#define MEM_MT41K128M16JT
+#define MEM_DMC0
+#define MEM_DMC1
+
+#define CFG_SYS_SDRAM_BASE	0xC2000000
+#define CFG_SYS_SDRAM_SIZE	0xe000000
+
+#endif

-- 
2.34.1

