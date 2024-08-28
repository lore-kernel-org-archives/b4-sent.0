From: Oliver Gaskell <Oliver.Gaskell@analog.com>
Date: Wed, 28 Aug 2024 11:02:14 +0100
Subject: [PATCH 06/20] arm: dts: Support SC594-SOM-EZLITE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240828-sc5xx-upstreaming-patches-v1-6-44d9adfdf327@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724839434; l=1552;
 i=Oliver.Gaskell@analog.com; s=20240821; h=from:subject:message-id;
 bh=sJ3AA+4nNO2X/f+kxcLmNn3Q/1Jkk6MkZMvzHfkwRqY=;
 b=4nXyiA3VmXauVGXJevpjlE3I5mNRK/MphNbIM5z7QCb1KPK9IoV4fup7zmmmnMGnuAewPtNr4
 MXsCOUpX78bAHqZAcZFrsCDPkuBgmz8vB2BS8p4yR4YTXbVO16SkKq1
X-Developer-Key: i=Oliver.Gaskell@analog.com; a=ed25519;
 pk=Icq9TxwFJ6FePHS28YbBWMvtZpFWxpPQLhLA9cNvZ/Y=
X-Endpoint-Received: by B4 Relay for Oliver.Gaskell@analog.com/20240821 with auth_id=197
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add minimal device tree for Analog Devices' SC594-SOM-EZLITE board.

This patch depends on Patches 01 and 05, for sc5xx.dtsi and
sc594-som.dtsi respectively.

Co-developed-by: Greg Malysa <greg.malysa@timesys.com>
Co-developed-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
Signed-off-by: Oliver Gaskell <Oliver.Gaskell@analog.com>
---
 arch/arm/dts/Makefile             |  1 +
 arch/arm/dts/sc594-som-ezlite.dts | 13 +++++++++++++
 2 files changed, 14 insertions(+)

diff --git a/arch/arm/dts/Makefile b/arch/arm/dts/Makefile
index 25c236039b..0c9984232b 100644
--- a/arch/arm/dts/Makefile
+++ b/arch/arm/dts/Makefile
@@ -1280,6 +1280,7 @@ dtb-$(CONFIG_TARGET_SC584_EZKIT) += sc584-ezkit.dtb
 dtb-$(CONFIG_TARGET_SC589_MINI) += sc589-mini.dtb
 dtb-$(CONFIG_TARGET_SC589_EZKIT) += sc589-ezkit.dtb
 dtb-$(CONFIG_TARGET_SC594_SOM_EZKIT) += sc594-som-ezkit.dtb
+dtb-$(CONFIG_TARGET_SC594_SOM_EZLITE) += sc594-som-ezlite.dtb
 
 ifneq ($(CONFIG_TARGET_IMX8MP_RSB3720A1_4G)$(CONFIG_TARGET_IMX8MP_RSB3720A1_6G),)
 dtb-y += imx8mp-rsb3720-a1.dtb
diff --git a/arch/arm/dts/sc594-som-ezlite.dts b/arch/arm/dts/sc594-som-ezlite.dts
new file mode 100644
index 0000000000..7d81b40fe8
--- /dev/null
+++ b/arch/arm/dts/sc594-som-ezlite.dts
@@ -0,0 +1,13 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * (C) Copyright 2024 - Analog Devices, Inc.
+ */
+
+/dts-v1/;
+
+#include "sc594-som.dtsi"
+
+/ {
+	model = "ADI SC594-SOM-EZLITE";
+	compatible = "adi,sc594-som-ezlite", "adi,sc59x";
+};

-- 
2.34.1

