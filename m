From: Yuugo Yoneda <yogo.0917.sabu@gmail.com>
Date: Sat, 21 Nov 2026 21:43:22 +0900
Subject: [PATCH RFC v2 12/13] ARM: dts: sirf: add SiRF AT550 SoC and
 Yupiteru YPL514si board
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-at550-rfc-v1-v2-12-b0309d0789b2@gmail.com>
References: <20261121-at550-rfc-v1-v2-0-b0309d0789b2@gmail.com>
In-Reply-To: <20261121-at550-rfc-v1-v2-0-b0309d0789b2@gmail.com>
To: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Ulf Hansson <ulfh@kernel.org>, 
 Adrian Hunter <adrian.hunter@intel.com>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Russell King <linux@armlinux.org.uk>, 
 Arnd Bergmann <arnd@arndb.de>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Linus Walleij <linusw@kernel.org>, Drew Fustini <fustini@kernel.org>, 
 linux-kernel@vger.kernel.org, linux-input@vger.kernel.org, 
 linux-mmc@vger.kernel.org, linux-doc@vger.kernel.org, soc@lists.linux.dev
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795264991; l=5087;
 i=yogo.0917.sabu@gmail.com; s=ypl514-20261117; h=from:subject:message-id;
 bh=YYX61pnZdoYnIBPRaBdIkg3vvaVgdoCDdTNEbzGmLXk=;
 b=bKDtzQGtlYOFfzHob6IE5SlxNrps9zcBIoMbJNwdCddsMSw4hw+qBG+NXH4OQE+Xh3rBgxlwL
 5AD3vB/SGBKAQZy68sNzRleyWHBxLl8ghXGdmlzXRbA0lbfuEdhnM02
X-Developer-Key: i=yogo.0917.sabu@gmail.com; a=ed25519;
 pk=TIQ8Tk4xQrxyn8rmk3GI2f5qg/kO6g2KZm7YOOyBHeg=
X-Endpoint-Received: by B4 Relay for yogo.0917.sabu@gmail.com/ypl514-20261117 with auth_id=1550
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the SiRF AT550 SoC device tree include and the Yupiteru YPL514si
board device tree.

The bootloader fills in the Linux-owned RAM range and post-divider
counter clock frequency at boot, enables only handed-over peripherals,
and enables simple-framebuffer once display geometry is verified. The
framebuffer range is reserved via a no-map reserved-memory node so
simplefb ioremap_wc() does not alias the ARM linear mapping.

Signed-off-by: Yuugo Yoneda <yogo.0917.sabu@gmail.com>
---
 MAINTAINERS                               |  1 +
 arch/arm/boot/dts/Makefile                |  1 +
 arch/arm/boot/dts/sirf/Makefile           |  2 +
 arch/arm/boot/dts/sirf/at550-ypl514si.dts | 63 ++++++++++++++++++++++++++++
 arch/arm/boot/dts/sirf/at550.dtsi         | 69 +++++++++++++++++++++++++++++++
 5 files changed, 136 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 1f9c8c08b..c6f0f3fb6 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -25856,6 +25856,7 @@ F:	Documentation/devicetree/bindings/input/touchscreen/sirf,at550-ts.yaml
 F:	Documentation/devicetree/bindings/interrupt-controller/sirf,at550-intc.yaml
 F:	Documentation/devicetree/bindings/mmc/sirf,at550-sdhci.yaml
 F:	Documentation/devicetree/bindings/timer/sirf,at550-timer.yaml
+F:	arch/arm/boot/dts/sirf/at550*
 F:	arch/arm/mach-at550/
 F:	drivers/clocksource/timer-at550.c
 F:	drivers/input/touchscreen/at550-ts.c
diff --git a/arch/arm/boot/dts/Makefile b/arch/arm/boot/dts/Makefile
index 28fba538d..d28c8eb01 100644
--- a/arch/arm/boot/dts/Makefile
+++ b/arch/arm/boot/dts/Makefile
@@ -30,6 +30,7 @@ subdir-y += renesas
 subdir-y += rockchip
 subdir-y += samsung
 subdir-y += sigmastar
+subdir-y += sirf
 subdir-y += socionext
 subdir-y += st
 subdir-y += sunplus
diff --git a/arch/arm/boot/dts/sirf/Makefile b/arch/arm/boot/dts/sirf/Makefile
new file mode 100644
index 000000000..d1d3d5bfe
--- /dev/null
+++ b/arch/arm/boot/dts/sirf/Makefile
@@ -0,0 +1,2 @@
+# SPDX-License-Identifier: GPL-2.0-only
+dtb-$(CONFIG_ARCH_AT550) += at550-ypl514si.dtb
diff --git a/arch/arm/boot/dts/sirf/at550-ypl514si.dts b/arch/arm/boot/dts/sirf/at550-ypl514si.dts
new file mode 100644
index 000000000..d34019858
--- /dev/null
+++ b/arch/arm/boot/dts/sirf/at550-ypl514si.dts
@@ -0,0 +1,63 @@
+// SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+/dts-v1/;
+#include "at550.dtsi"
+
+/ {
+	model = "Yupiteru YPL514si";
+	compatible = "yupiteru,ypl514si", "sirf,at550";
+
+	chosen {
+		ranges;
+		#address-cells = <1>;
+		#size-cells = <1>;
+
+		framebuffer@c0100000 {
+			compatible = "simple-framebuffer";
+			reg = <0xc0100000 0x3fc00>;
+			width = <480>;
+			height = <272>;
+			stride = <960>;
+			format = "r5g6b5";
+
+			status = "disabled";
+		};
+	};
+
+	memory@c0000000 {
+		device_type = "memory";
+		/* The bootloader supplies the region allocated for Linux. */
+		reg = <0xc0000000 0>;
+	};
+
+	reserved-memory {
+		ranges;
+		#address-cells = <1>;
+		#size-cells = <1>;
+
+		framebuffer@c0100000 {
+			reg = <0xc0100000 0x40000>;
+			no-map;
+		};
+	};
+};
+
+&sd0 {
+	bus-width = <4>;
+	max-frequency = <25000000>;
+	no-1-8-v;
+	no-mmc;
+	no-sdio;
+};
+
+&sd2 {
+	bus-width = <4>;
+	max-frequency = <25000000>;
+	no-1-8-v;
+	no-mmc;
+	no-sdio;
+};
+
+&touchscreen {
+	touchscreen-size-x = <4096>;
+	touchscreen-size-y = <4096>;
+};
diff --git a/arch/arm/boot/dts/sirf/at550.dtsi b/arch/arm/boot/dts/sirf/at550.dtsi
new file mode 100644
index 000000000..0daf05eca
--- /dev/null
+++ b/arch/arm/boot/dts/sirf/at550.dtsi
@@ -0,0 +1,69 @@
+// SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+/ {
+	#address-cells = <1>;
+	#size-cells = <1>;
+	interrupt-parent = <&intc>;
+
+	counter_clk: clock-counter {
+		compatible = "fixed-clock";
+		#clock-cells = <0>;
+		/* Boot firmware supplies the rate after the hardware divider. */
+		clock-frequency = <0>;
+	};
+
+	cpus {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		cpu@0 {
+			device_type = "cpu";
+			compatible = "arm,arm1136jf-s";
+			reg = <0>;
+		};
+	};
+
+	soc {
+		compatible = "simple-bus";
+		ranges;
+		#address-cells = <1>;
+		#size-cells = <1>;
+
+		sd0: mmc@56000000 {
+			compatible = "sirf,at550-sdhci";
+			reg = <0x56000000 0x1000>;
+			interrupts = <36>;
+
+			status = "disabled";
+		};
+
+		sd2: mmc@56200000 {
+			compatible = "sirf,at550-sdhci";
+			reg = <0x56200000 0x1000>;
+			interrupts = <20>;
+
+			status = "disabled";
+		};
+
+		touchscreen: touchscreen@80120000 {
+			compatible = "sirf,at550-ts";
+			reg = <0x80120000 0x1000>;
+
+			status = "disabled";
+		};
+
+		intc: interrupt-controller@90020000 {
+			compatible = "sirf,at550-intc";
+			reg = <0x90020000 0x1000>;
+			interrupt-controller;
+			#interrupt-cells = <1>;
+			#address-cells = <0>;
+		};
+
+		timer@90050000 {
+			compatible = "sirf,at550-timer";
+			reg = <0x90050000 0x1000>;
+			interrupts = <0>;
+			clocks = <&counter_clk>;
+		};
+	};
+};

-- 
2.56.0

