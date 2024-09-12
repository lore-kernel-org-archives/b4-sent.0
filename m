From: Oliver Gaskell <Oliver.Gaskell@analog.com>
Date: Thu, 12 Sep 2024 16:50:47 +0100
Subject: [PATCH v2 06/20] arm: dts: Support SC594-SOM-EZLITE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240912-sc5xx-upstreaming-patches-v2-6-1185a80df79e@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726156261; l=1676;
 i=Oliver.Gaskell@analog.com; s=20240821; h=from:subject:message-id;
 bh=EOGKrLN34VGPZVPLtrZGatsYePkJhtF2kzJugCc4/4M=;
 b=E/fQGsu4xXYE6ehF+3gr2eY7+b48fJDxQCSWA3qUQbM/BbFU7FNVamfQlHU7bzYuM/YHOhTGH
 D0IkldF3ayCDiLfPGrCaOPo4OCH9mr6p4Bvikp6vDWUQV+HgTnmtWAb
X-Developer-Key: i=Oliver.Gaskell@analog.com; a=ed25519;
 pk=Icq9TxwFJ6FePHS28YbBWMvtZpFWxpPQLhLA9cNvZ/Y=
X-Endpoint-Received: by B4 Relay for Oliver.Gaskell@analog.com/20240821 with auth_id=197
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add minimal device tree for Analog Devices' SC594-SOM-EZLITE board.

This patch depends on Patches 01 and 05, for sc5xx.dtsi and
sc594-som.dtsi respectively.

Co-developed-by: Greg Malysa <greg.malysa@timesys.com>
Signed-off-by: Greg Malysa <greg.malysa@timesys.com>
Co-developed-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
Signed-off-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
Signed-off-by: Oliver Gaskell <Oliver.Gaskell@analog.com>
---
 arch/arm/dts/Makefile             |  1 +
 arch/arm/dts/sc594-som-ezlite.dts | 13 +++++++++++++
 2 files changed, 14 insertions(+)

diff --git a/arch/arm/dts/Makefile b/arch/arm/dts/Makefile
index a56867b3de..7a1dd24838 100644
--- a/arch/arm/dts/Makefile
+++ b/arch/arm/dts/Makefile
@@ -1263,6 +1263,7 @@ dtb-$(CONFIG_TARGET_SC584_EZKIT) += sc584-ezkit.dtb
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

