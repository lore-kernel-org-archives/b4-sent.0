From: Oliver Gaskell <Oliver.Gaskell@analog.com>
Date: Thu, 12 Sep 2024 16:50:42 +0100
Subject: [PATCH v2 01/20] arm: dts: Support SC573-EZKIT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240912-sc5xx-upstreaming-patches-v2-1-1185a80df79e@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726156261; l=4317;
 i=Oliver.Gaskell@analog.com; s=20240821; h=from:subject:message-id;
 bh=r4aHTZBVZsVIuHKj//cUZ8TbZSM5wgSHOGA8oAUbiMs=;
 b=vvApAYSjBxmM5VPOES236JkuWOC6tsf0i75zgYlOWdwOVaDyfQcvHxkg4UJ29Kpiw/NWTvp5T
 sQG9885y4rZB0cSSIemXvIscLe1wn6jBewBMnca0C0TT5WB24tSqNSf
X-Developer-Key: i=Oliver.Gaskell@analog.com; a=ed25519;
 pk=Icq9TxwFJ6FePHS28YbBWMvtZpFWxpPQLhLA9cNvZ/Y=
X-Endpoint-Received: by B4 Relay for Oliver.Gaskell@analog.com/20240821 with auth_id=197
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds minimal device tree for Analog Devices' SC573-EZKIT board and
common files for the SC57x/SC5xx family.

This also adds all sc5* devicetrees to ARM SC5XX in MAINTAINERS, and
adds the ADSP Linux mailing list as the list for ARM SC5XX.

Co-developed-by: Greg Malysa <greg.malysa@timesys.com>
Signed-off-by: Greg Malysa <greg.malysa@timesys.com>
Co-developed-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
Signed-off-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
Signed-off-by: Oliver Gaskell <Oliver.Gaskell@analog.com>
---
 MAINTAINERS                  |  2 ++
 arch/arm/dts/Makefile        |  2 ++
 arch/arm/dts/sc573-ezkit.dts | 13 +++++++++++
 arch/arm/dts/sc57x.dtsi      | 21 +++++++++++++++++
 arch/arm/dts/sc5xx.dtsi      | 54 ++++++++++++++++++++++++++++++++++++++++++++
 5 files changed, 92 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 2050ae24df..b172e1ea95 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -601,8 +601,10 @@ M:	Ian Roberts <ian.roberts@timesys.com>
 M:	Vasileios Bimpikas <vasileios.bimpikas@analog.com>
 M:	Utsav Agarwal <utsav.agarwal@analog.com>
 M:	Arturs Artamonovs <arturs.artamonovs@analog.com>
+L:	adsp-linux@analog.com
 S:	Supported
 T:	git https://github.com/analogdevicesinc/lnxdsp-u-boot
+F:	arch/arm/dts/sc5*
 F:	arch/arm/include/asm/arch-adi/
 F:	arch/arm/mach-sc5xx/
 F:	drivers/clk/adi/
diff --git a/arch/arm/dts/Makefile b/arch/arm/dts/Makefile
index 2d931c23fc..d2194908d9 100644
--- a/arch/arm/dts/Makefile
+++ b/arch/arm/dts/Makefile
@@ -1258,6 +1258,8 @@ dtb-$(CONFIG_TARGET_IMX8MM_CL_IOT_GATE_OPTEE) += imx8mm-cl-iot-gate-optee.dtb \
 					imx8mm-cl-iot-gate-ied-tpm0.dtbo \
 					imx8mm-cl-iot-gate-ied-tpm1.dtbo
 
+dtb-$(CONFIG_TARGET_SC573_EZKIT) += sc573-ezkit.dtb
+
 ifneq ($(CONFIG_TARGET_IMX8MP_RSB3720A1_4G)$(CONFIG_TARGET_IMX8MP_RSB3720A1_6G),)
 dtb-y += imx8mp-rsb3720-a1.dtb
 endif
diff --git a/arch/arm/dts/sc573-ezkit.dts b/arch/arm/dts/sc573-ezkit.dts
new file mode 100644
index 0000000000..0dc2962618
--- /dev/null
+++ b/arch/arm/dts/sc573-ezkit.dts
@@ -0,0 +1,13 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * (C) Copyright 2024 - Analog Devices, Inc.
+ */
+
+/dts-v1/;
+
+#include "sc57x.dtsi"
+
+/ {
+	model = "ADI SC573-EZKIT";
+	compatible = "adi,sc573-ezkit", "adi,sc57x";
+};
diff --git a/arch/arm/dts/sc57x.dtsi b/arch/arm/dts/sc57x.dtsi
new file mode 100644
index 0000000000..ddfcae8d19
--- /dev/null
+++ b/arch/arm/dts/sc57x.dtsi
@@ -0,0 +1,21 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * (C) Copyright 2024 - Analog Devices, Inc.
+ */
+
+#include "sc5xx.dtsi"
+
+/ {
+	gic: interrupt-controller@310b2000 {
+		compatible = "arm,cortex-a5-gic";
+		#interrupt-cells = <3>;
+		#address-cells = <0>;
+		interrupt-controller;
+		reg = <0x310B2000 0x1000>,
+		      <0x310B4000 0x100>;
+	};
+};
+
+&timer0 {
+	clocks = <&clk ADSP_SC57X_CLK_CGU0_SCLK0>;
+};
diff --git a/arch/arm/dts/sc5xx.dtsi b/arch/arm/dts/sc5xx.dtsi
new file mode 100644
index 0000000000..3f440dac29
--- /dev/null
+++ b/arch/arm/dts/sc5xx.dtsi
@@ -0,0 +1,54 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * (C) Copyright 2024 - Analog Devices, Inc.
+ */
+
+#include <dt-bindings/interrupt-controller/arm-gic.h>
+#include <dt-bindings/clock/adi-sc5xx-clock.h>
+
+/ {
+	#address-cells = <1>;
+	#size-cells = <1>;
+
+	clocks {
+		sys_clkin0: sys_clkin0 {
+			compatible = "fixed-clock";
+			#clock-cells = <0>;
+			clock-frequency = <25000000>;
+			bootph-all;
+		};
+
+		sys_clkin1: sys_clkin1 {
+			compatible = "fixed-clock";
+			#clock-cells = <0>;
+			clock-frequency = <25000000>;
+			bootph-all;
+		};
+	};
+
+	soc {
+		#address-cells = <1>;
+		#size-cells = <1>;
+		compatible = "simple-bus";
+		device_type = "soc";
+		ranges;
+		bootph-all;
+
+		timer0: timer@31018000 {
+			compatible = "adi,sc5xx-gptimer";
+			reg = <0x31018004 0x100>,
+			      <0x31018060 0x100>;
+			status = "okay";
+			bootph-all;
+		};
+
+		clk: clocks@3108d000 {
+			reg = <0x3108d000 0x1000>;
+			#clock-cells = <1>;
+			clocks = <&sys_clkin0>, <&sys_clkin1>;
+			clock-names = "sys_clkin0", "sys_clkin1";
+			status = "okay";
+			bootph-all;
+		};
+	};
+};

-- 
2.34.1

