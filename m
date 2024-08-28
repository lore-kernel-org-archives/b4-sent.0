From: Oliver Gaskell <Oliver.Gaskell@analog.com>
Date: Wed, 28 Aug 2024 11:02:15 +0100
Subject: [PATCH 07/20] arm: dts: Support SC598-SOM-EZKIT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240828-sc5xx-upstreaming-patches-v1-7-44d9adfdf327@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724839434; l=2464;
 i=Oliver.Gaskell@analog.com; s=20240821; h=from:subject:message-id;
 bh=XwhlBkJTZ9l9CK3/LMBUYJ30up8T7c9WzOtGrRACVpM=;
 b=vM3GFZeBNpPf/Eur9pzvHCRBNLPhAbbSsU3/NdzwvGkREoxvmyykwpMf+SNx/KEZnkZ8TGwnX
 bP7keP6nQiCBB7RbXUaoJi2wyepa7yU8Wy948NgooUpsBVpqBBfJthe
X-Developer-Key: i=Oliver.Gaskell@analog.com; a=ed25519;
 pk=Icq9TxwFJ6FePHS28YbBWMvtZpFWxpPQLhLA9cNvZ/Y=
X-Endpoint-Received: by B4 Relay for Oliver.Gaskell@analog.com/20240821 with auth_id=197
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add minimal device tree for Analog Devices' SC598-SOM-EZKIT board, and
the SC598 SoM.

This patch depends on patch 01, for sc5xx.dtsi.

Co-developed-by: Greg Malysa <greg.malysa@timesys.com>
Co-developed-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
Signed-off-by: Oliver Gaskell <Oliver.Gaskell@analog.com>
---
 arch/arm/dts/Makefile            |  1 +
 arch/arm/dts/sc598-som-ezkit.dts | 13 +++++++++++++
 arch/arm/dts/sc598-som.dtsi      | 31 +++++++++++++++++++++++++++++++
 3 files changed, 45 insertions(+)

diff --git a/arch/arm/dts/Makefile b/arch/arm/dts/Makefile
index 0c9984232b..6b0a762bce 100644
--- a/arch/arm/dts/Makefile
+++ b/arch/arm/dts/Makefile
@@ -1281,6 +1281,7 @@ dtb-$(CONFIG_TARGET_SC589_MINI) += sc589-mini.dtb
 dtb-$(CONFIG_TARGET_SC589_EZKIT) += sc589-ezkit.dtb
 dtb-$(CONFIG_TARGET_SC594_SOM_EZKIT) += sc594-som-ezkit.dtb
 dtb-$(CONFIG_TARGET_SC594_SOM_EZLITE) += sc594-som-ezlite.dtb
+dtb-$(CONFIG_TARGET_SC598_SOM_EZKIT) += sc598-som-ezkit.dtb
 
 ifneq ($(CONFIG_TARGET_IMX8MP_RSB3720A1_4G)$(CONFIG_TARGET_IMX8MP_RSB3720A1_6G),)
 dtb-y += imx8mp-rsb3720-a1.dtb
diff --git a/arch/arm/dts/sc598-som-ezkit.dts b/arch/arm/dts/sc598-som-ezkit.dts
new file mode 100644
index 0000000000..7289e4d1d5
--- /dev/null
+++ b/arch/arm/dts/sc598-som-ezkit.dts
@@ -0,0 +1,13 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * (C) Copyright 2024 - Analog Devices, Inc.
+ */
+
+/dts-v1/;
+
+#include "sc598-som.dtsi"
+
+/ {
+	model = "ADI SC598-SOM-EZKIT";
+	compatible = "adi,sc598-som-ezkit", "adi,sc59x-64";
+};
diff --git a/arch/arm/dts/sc598-som.dtsi b/arch/arm/dts/sc598-som.dtsi
new file mode 100644
index 0000000000..8bcc8bb8f1
--- /dev/null
+++ b/arch/arm/dts/sc598-som.dtsi
@@ -0,0 +1,31 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * (C) Copyright 2024 - Analog Devices, Inc.
+ */
+
+/dts-v1/;
+
+#include "sc5xx.dtsi"
+
+/ {
+	gic: interrupt-controller@31200000 {
+		compatible = "arm,gic-v3";
+		#interrupt-cells = <3>;
+		interrupt-controller;
+		reg = <0x31200000 0x40000>, /* GIC Dist */
+		      <0x31240000 0x40000>; /* GICR */
+	};
+};
+
+&clk {
+	compatible = "adi,sc598-clocks";
+	reg = <0x3108d000 0x1000>,
+	      <0x3108e000 0x1000>,
+	      <0x3108f000 0x1000>,
+	      <0x310a9000 0x1000>;
+	reg-names = "cgu0", "cgu1", "cdu", "pll3";
+};
+
+&timer0 {
+	clocks = <&clk ADSP_SC598_CLK_CGU0_SCLK0>;
+};

-- 
2.34.1

