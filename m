From: Oliver Gaskell <Oliver.Gaskell@analog.com>
Date: Wed, 28 Aug 2024 11:02:11 +0100
Subject: [PATCH 03/20] arm: dts: Support SC589-MINI
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240828-sc5xx-upstreaming-patches-v1-3-44d9adfdf327@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724839434; l=1495;
 i=Oliver.Gaskell@analog.com; s=20240821; h=from:subject:message-id;
 bh=qW/obTP3BVfcXPpV8uB1duEZKgXXecwX6E47LEhmVA4=;
 b=io4AkNZ71q8mPtOjvm6E9nuEZgwBhhimXWgG4qzRZwI/2zb2oP4luxloWgnJjdtmkIQYA9ApM
 biz1Vm3LyalAOAOGVgM4qFsMb1vVskI4asgcAwCRHb31F3iOghfcgBj
X-Developer-Key: i=Oliver.Gaskell@analog.com; a=ed25519;
 pk=Icq9TxwFJ6FePHS28YbBWMvtZpFWxpPQLhLA9cNvZ/Y=
X-Endpoint-Received: by B4 Relay for Oliver.Gaskell@analog.com/20240821 with auth_id=197
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add minimal device tree for Analog Devices' SC589-MINI board.

This patch depends on Patches 01 and 02, for sc5xx.dtsi and sc58x.dtsi.

Co-developed-by: Greg Malysa <greg.malysa@timesys.com>
Co-developed-by: Trevor Woerner <twoerner@gmail.com>
Co-developed-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
Signed-off-by: Oliver Gaskell <Oliver.Gaskell@analog.com>
---
 arch/arm/dts/Makefile       |  1 +
 arch/arm/dts/sc589-mini.dts | 13 +++++++++++++
 2 files changed, 14 insertions(+)

diff --git a/arch/arm/dts/Makefile b/arch/arm/dts/Makefile
index 5b87c8972f..34c7ede8cb 100644
--- a/arch/arm/dts/Makefile
+++ b/arch/arm/dts/Makefile
@@ -1277,6 +1277,7 @@ dtb-$(CONFIG_TARGET_IMX8MM_CL_IOT_GATE_OPTEE) += imx8mm-cl-iot-gate-optee.dtb \
 
 dtb-$(CONFIG_TARGET_SC573_EZKIT) += sc573-ezkit.dtb
 dtb-$(CONFIG_TARGET_SC584_EZKIT) += sc584-ezkit.dtb
+dtb-$(CONFIG_TARGET_SC589_MINI) += sc589-mini.dtb
 
 ifneq ($(CONFIG_TARGET_IMX8MP_RSB3720A1_4G)$(CONFIG_TARGET_IMX8MP_RSB3720A1_6G),)
 dtb-y += imx8mp-rsb3720-a1.dtb
diff --git a/arch/arm/dts/sc589-mini.dts b/arch/arm/dts/sc589-mini.dts
new file mode 100644
index 0000000000..605f7a17bf
--- /dev/null
+++ b/arch/arm/dts/sc589-mini.dts
@@ -0,0 +1,13 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * (C) Copyright 2024 - Analog Devices, Inc.
+ */
+
+/dts-v1/;
+
+#include "sc58x.dtsi"
+
+/ {
+	model = "ADI SC598-MINI";
+	compatible = "adi,sc589-mini", "adi,sc58x";
+};

-- 
2.34.1

