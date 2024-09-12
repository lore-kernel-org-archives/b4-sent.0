From: Oliver Gaskell <Oliver.Gaskell@analog.com>
Date: Thu, 12 Sep 2024 16:51:00 +0100
Subject: [PATCH v2 19/20] arm: SC589-MINI initial support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240912-sc5xx-upstreaming-patches-v2-19-1185a80df79e@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726156261; l=4052;
 i=Oliver.Gaskell@analog.com; s=20240821; h=from:subject:message-id;
 bh=ihM3ZQ8lKDj6GL8LYz5QBzkMM74PpGGSwXAMXfrRJu4=;
 b=nv6oxlnrXjISZwjOinD/5685LPiaREF3phWLlTW/uYzYjYGCmQInWrSLd66LHcEW4XIG/OTNV
 07M9xP9aMPJD1PuDjxrNjipE2IY7qzIIvzNudTmKOC5SCv7ZeGj6SVK
X-Developer-Key: i=Oliver.Gaskell@analog.com; a=ed25519;
 pk=Icq9TxwFJ6FePHS28YbBWMvtZpFWxpPQLhLA9cNvZ/Y=
X-Endpoint-Received: by B4 Relay for Oliver.Gaskell@analog.com/20240821 with auth_id=197
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds support for Analog Devices' SC589-MINI board. Includes:
- Board specific configs in mach-sc5xx/Kconfig
- Board-specific Kconfig and environment in board/adi/

Signed-off-by: Oliver Gaskell <Oliver.Gaskell@analog.com>
---
 Kconfig                             |   2 +-
 arch/arm/mach-sc5xx/Kconfig         |   5 ++
 board/adi/sc589-mini/Kconfig        | 116 ++++++++++++++++++++++++++++++++++++
 board/adi/sc589-mini/sc589-mini.env |  13 ++++
 4 files changed, 135 insertions(+), 1 deletion(-)

diff --git a/Kconfig b/Kconfig
index bdae1b01d3..6853219dd5 100644
--- a/Kconfig
+++ b/Kconfig
@@ -648,7 +648,7 @@ config TEXT_BASE
 	default 0x96000000 if ARCH_SC5XX && SC59X_64
 	default 0xB2200000 if ARCH_SC5XX && SC59X
 	default 0x89200000 if ARCH_SC5XX && TARGET_SC584_EZKIT
-	default 0xC2200000 if ARCH_SC5XX && TARGET_SC589_EZKIT
+	default 0xC2200000 if ARCH_SC5XX && (TARGET_SC589_EZKIT || TARGET_SC589_MINI)
 	hex "Text Base"
 	help
 	  The address in memory that U-Boot will be copied and executed from
diff --git a/arch/arm/mach-sc5xx/Kconfig b/arch/arm/mach-sc5xx/Kconfig
index 408b943fd6..6f8ea453b0 100644
--- a/arch/arm/mach-sc5xx/Kconfig
+++ b/arch/arm/mach-sc5xx/Kconfig
@@ -59,6 +59,10 @@ config TARGET_SC584_EZKIT
 	prompt "SC584-EZKIT"
 	select ADI_USE_DDR2
 
+config TARGET_SC589_MINI
+	bool
+	prompt "SC589-MINI"
+
 config TARGET_SC589_EZKIT
 	bool
 	prompt "SC589-EZKIT"
@@ -549,6 +553,7 @@ source "board/adi/sc598-som-ezlite/Kconfig"
 source "board/adi/sc594-som-ezkit/Kconfig"
 source "board/adi/sc594-som-ezlite/Kconfig"
 source "board/adi/sc589-ezkit/Kconfig"
+source "board/adi/sc589-mini/Kconfig"
 source "board/adi/sc584-ezkit/Kconfig"
 
 endif
diff --git a/board/adi/sc589-mini/Kconfig b/board/adi/sc589-mini/Kconfig
new file mode 100644
index 0000000000..8f723f30dd
--- /dev/null
+++ b/board/adi/sc589-mini/Kconfig
@@ -0,0 +1,116 @@
+# SPDX-License-Identifier: GPL-2.0-or-later
+#
+# (C) Copyright 2024 - Analog Devices, Inc.
+
+if TARGET_SC589_MINI
+
+config LDR_CPU
+	default	"ADSP-SC589-0.1"
+
+config SYS_BOARD
+	default "sc589-mini"
+
+config SYS_CONFIG_NAME
+	default "sc589"
+
+config DEFAULT_DEVICE_TREE
+	default "sc589-mini"
+
+config ADI_IMAGE
+	default "minimal"
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
diff --git a/board/adi/sc589-mini/sc589-mini.env b/board/adi/sc589-mini/sc589-mini.env
new file mode 100644
index 0000000000..0f3f0bd28e
--- /dev/null
+++ b/board/adi/sc589-mini/sc589-mini.env
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
+adi_rfs_offset=0x8E0000
+loadaddr=0xC3000000
+jffs2file=adsp-sc5xx-__stringify(CONFIG_ADI_IMAGE)-adsp-sc589-mini.jffs2

-- 
2.34.1

