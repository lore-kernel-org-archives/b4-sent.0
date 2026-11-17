From: yy-Local-LLM <yogo.0917.sabu@gmail.com>
Date: Tue, 17 Nov 2026 22:06:56 +0900
Subject: [PATCH RFC 6/6] ARM: add the SiRF AT550 platform and YPL514si
 board
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-at550-rfc-v1-v1-6-5879573cb825@gmail.com>
References: <20261117-at550-rfc-v1-v1-0-5879573cb825@gmail.com>
In-Reply-To: <20261117-at550-rfc-v1-v1-0-5879573cb825@gmail.com>
To: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Thomas Gleixner <tglx@kernel.org>, Radu Rendec <radu@rendec.net>, 
 Ulf Hansson <ulfh@kernel.org>, Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Adrian Hunter <adrian.hunter@intel.com>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Russell King <linux@armlinux.org.uk>, 
 Arnd Bergmann <arnd@arndb.de>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Linus Walleij <linusw@kernel.org>, Drew Fustini <fustini@kernel.org>, 
 linux-kernel@vger.kernel.org, linux-input@vger.kernel.org, 
 linux-mmc@vger.kernel.org, linux-doc@vger.kernel.org, soc@lists.linux.dev
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794920817; l=12332;
 i=yogo.0917.sabu@gmail.com; s=ypl514-20261117; h=from:subject:message-id;
 bh=fkERuernoI+JItcwimoOR1zmbwQwQilTSUah3wY/Zo4=;
 b=eXqihrP6VYmO4pZ4Eu2ludgvyRZfv0EfU6bocwmks3nUU5dZgek1LSs5gUvgJCifx9H2F/qTj
 gtONxnWHFOmCyVyztEhKFWTpWAS2zV8p/wFNQNvqyCG5Fk8cA9rdu6S
X-Developer-Key: i=yogo.0917.sabu@gmail.com; a=ed25519;
 pk=TIQ8Tk4xQrxyn8rmk3GI2f5qg/kO6g2KZm7YOOyBHeg=
X-Endpoint-Received: by B4 Relay for yogo.0917.sabu@gmail.com/ypl514-20261117 with auth_id=1550
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a minimal DT machine using standard IRQ, timer and simplefb paths.
Describe the SoC and the firmware-configured YPL514si display. Leave
usable memory and the divided counter rate for the bootloader to
populate. Keep optional peripheral nodes disabled until firmware hands
them over. Disable unvalidated board suspend; limit this board to SD PIO
at 25 MHz. Document the RAM-boot contract and the missing
cold-boot/clock-tree support.

Signed-off-by: yy-Local-LLM <yogo.0917.sabu@gmail.com>
---
 Documentation/arch/arm/at550.rst          | 55 ++++++++++++++++++++++++++
 Documentation/arch/arm/index.rst          |  1 +
 MAINTAINERS                               |  4 ++
 arch/arm/Kconfig                          |  1 +
 arch/arm/Makefile                         |  1 +
 arch/arm/boot/dts/Makefile                |  2 +
 arch/arm/boot/dts/sirf/Makefile           |  2 +
 arch/arm/boot/dts/sirf/at550-ypl514si.dts | 52 ++++++++++++++++++++++++
 arch/arm/boot/dts/sirf/at550.dtsi         | 66 +++++++++++++++++++++++++++++++
 arch/arm/configs/at550_defconfig          | 34 ++++++++++++++++
 arch/arm/mach-at550/Kconfig               | 13 ++++++
 arch/arm/mach-at550/Makefile              |  2 +
 arch/arm/mach-at550/at550.c               | 11 ++++++
 13 files changed, 244 insertions(+)

diff --git a/Documentation/arch/arm/at550.rst b/Documentation/arch/arm/at550.rst
new file mode 100644
index 000000000..8925a9ffb
--- /dev/null
+++ b/Documentation/arch/arm/at550.rst
@@ -0,0 +1,55 @@
+.. SPDX-License-Identifier: GPL-2.0-only
+
+SiRF AT550 and Yupiteru YPL514si
+================================
+
+The initial AT550 port supports the ARM1136 CPU, the 64-source interrupt
+controller, the low 32 bits of the system counter and match channel zero,
+polled resistive touch input, and SDHCI programmed I/O. The YPL514si board
+can use a firmware-configured 480 by 272 RGB565 simple framebuffer.
+
+Firmware handoff
+----------------
+
+Use the standard ARM boot protocol and a flattened device tree. Firmware must
+initialize SDRAM, peripheral clocks, and pin multiplexing before entering the
+kernel. No firmware-specific virtual mappings or page-table inspection are
+used by the Linux drivers.
+
+The bootloader must update the following parts of the board device tree:
+
+* Supply the actual Linux-owned region in the memory node. The zero size in
+  the source DTS is a placeholder, not a description of all installed memory.
+  RAM still owned by another operating system must not be advertised to Linux.
+* Set the fixed counter clock frequency to the rate after the programmed
+  hardware divider. The driver deliberately does not reset the counter or
+  change the divider. A zero rate is rejected.
+* Disable the timer watchdog before handing the timer block to Linux.
+* Enable the simple framebuffer only when its physical address, dimensions,
+  stride, and format have been verified. Reserve its memory from other uses.
+* Enable the touch and SD nodes only for peripherals actually handed to Linux.
+  The touchscreen driver rejects an active streaming/AUX configuration.
+
+A Windows CE RAM loader is one possible bootloader. Its allocation checks,
+volatile driver registration, MMU transition, and DT fixups are outside the
+kernel port. The Linux Image and all its runtime memory must fit inside the
+region returned to the kernel; a static firmware RAM mapping is insufficient
+proof that memory is available.
+
+Initial limits
+--------------
+
+The port depends on firmware clock and pin setup; cold reset initialization
+and clock-tree programming are not implemented. Board suspend is disabled in
+the defconfig because firmware state restoration has not been established.
+
+DMA address translation has not been validated, so the SDHCI driver uses PIO.
+The YPL514si DT disables MMC and SDIO discovery and limits SD to 25 MHz and
+3.3 V. Filesystem write support, card removal, and suspend/resume require
+separate hardware validation. No flash or bootloader update is required to
+use the RAM boot path.
+
+The touchscreen exports raw coordinates. Initial five-point affine calibration
+is performed in userspace, rather than placing a board-specific transform in
+the input driver. GPS/baseband, USB, UART, and native LCD modesetting are not
+part of the initial support.
diff --git a/Documentation/arch/arm/index.rst b/Documentation/arch/arm/index.rst
index b15621093..9cf1fb834 100644
--- a/Documentation/arch/arm/index.rst
+++ b/Documentation/arch/arm/index.rst
@@ -62,6 +62,7 @@ SoC-specific documents
    stm32/stm32mp157-overview
    stm32/stm32-dma-mdma-chaining
 
+   at550
    sunxi
 
    samsung/index
diff --git a/MAINTAINERS b/MAINTAINERS
index 347d46a20..75f5a827e 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -25850,11 +25850,15 @@ F:	include/trace/events/siox.h
 SIRF AT550 PLATFORM
 M:	yy-Local-LLM <yogo.0917.sabu@gmail.com>
 S:	Odd Fixes
+F:	Documentation/arch/arm/at550.rst
 F:	Documentation/devicetree/bindings/arm/sirf,at550.yaml
 F:	Documentation/devicetree/bindings/input/touchscreen/sirf,at550-ts.yaml
 F:	Documentation/devicetree/bindings/interrupt-controller/sirf,at550-intc.yaml
 F:	Documentation/devicetree/bindings/mmc/sirf,at550-sdhci.yaml
 F:	Documentation/devicetree/bindings/timer/sirf,at550-timer.yaml
+F:	arch/arm/boot/dts/sirf/at550*
+F:	arch/arm/configs/at550_defconfig
+F:	arch/arm/mach-at550/
 F:	drivers/clocksource/timer-at550.c
 F:	drivers/input/touchscreen/at550-ts.c
 F:	drivers/irqchip/irq-at550.c
diff --git a/arch/arm/Kconfig b/arch/arm/Kconfig
index 0cc289a71..7fcf2a28f 100644
--- a/arch/arm/Kconfig
+++ b/arch/arm/Kconfig
@@ -367,6 +367,7 @@ source "arch/arm/mach-artpec/Kconfig"
 
 source "arch/arm/mach-aspeed/Kconfig"
 
+source "arch/arm/mach-at550/Kconfig"
 source "arch/arm/mach-at91/Kconfig"
 
 source "arch/arm/mach-axxia/Kconfig"
diff --git a/arch/arm/Makefile b/arch/arm/Makefile
index 573813ef5..508cbad8b 100644
--- a/arch/arm/Makefile
+++ b/arch/arm/Makefile
@@ -176,6 +176,7 @@ machine-$(CONFIG_ARCH_ACTIONS)		+= actions
 machine-$(CONFIG_ARCH_ALPINE)		+= alpine
 machine-$(CONFIG_ARCH_ARTPEC)		+= artpec
 machine-$(CONFIG_ARCH_ASPEED)           += aspeed
+machine-$(CONFIG_ARCH_AT550)		+= at550
 machine-$(CONFIG_ARCH_AT91)		+= at91
 machine-$(CONFIG_ARCH_AXXIA)		+= axxia
 machine-$(CONFIG_ARCH_BCM)		+= bcm
diff --git a/arch/arm/boot/dts/Makefile b/arch/arm/boot/dts/Makefile
index 28fba538d..a4844a80b 100644
--- a/arch/arm/boot/dts/Makefile
+++ b/arch/arm/boot/dts/Makefile
@@ -40,3 +40,5 @@ subdir-y += vt8500
 subdir-y += xen
 subdir-y += xilinx
 subdir-y += zte
+
+subdir-y += sirf
\ No newline at end of file
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
index 000000000..d45328fa0
--- /dev/null
+++ b/arch/arm/boot/dts/sirf/at550-ypl514si.dts
@@ -0,0 +1,52 @@
+// SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+/dts-v1/;
+/memreserve/ 0xc0100000 0x40000;
+#include "at550.dtsi"
+
+/ {
+	model = "Yupiteru YPL514si";
+	compatible = "yupiteru,ypl514si", "sirf,at550";
+
+	memory@c0000000 {
+		device_type = "memory";
+		/* The bootloader supplies the region allocated for Linux. */
+		reg = <0xc0000000 0>;
+	};
+
+	chosen {
+		#address-cells = <1>;
+		#size-cells = <1>;
+		ranges;
+
+		framebuffer@c0100000 {
+			compatible = "simple-framebuffer";
+			reg = <0xc0100000 0x3fc00>;
+			width = <480>;
+			height = <272>;
+			stride = <960>;
+			format = "r5g6b5";
+			status = "disabled";
+		};
+	};
+};
+
+&touchscreen {
+	touchscreen-size-x = <4096>;
+	touchscreen-size-y = <4096>;
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
diff --git a/arch/arm/boot/dts/sirf/at550.dtsi b/arch/arm/boot/dts/sirf/at550.dtsi
new file mode 100644
index 000000000..62d9842cb
--- /dev/null
+++ b/arch/arm/boot/dts/sirf/at550.dtsi
@@ -0,0 +1,66 @@
+// SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+/ {
+	#address-cells = <1>;
+	#size-cells = <1>;
+	interrupt-parent = <&intc>;
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
+	counter_clk: clock-counter {
+		compatible = "fixed-clock";
+		#clock-cells = <0>;
+		/* Boot firmware supplies the rate after the hardware divider. */
+		clock-frequency = <0>;
+	};
+
+	soc {
+		compatible = "simple-bus";
+		#address-cells = <1>;
+		#size-cells = <1>;
+		ranges;
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
+
+		touchscreen: touchscreen@80120000 {
+			compatible = "sirf,at550-ts";
+			reg = <0x80120000 0x1000>;
+			status = "disabled";
+		};
+
+		sd0: mmc@56000000 {
+			compatible = "sirf,at550-sdhci";
+			reg = <0x56000000 0x1000>;
+			interrupts = <36>;
+			status = "disabled";
+		};
+
+		sd2: mmc@56200000 {
+			compatible = "sirf,at550-sdhci";
+			reg = <0x56200000 0x1000>;
+			interrupts = <20>;
+			status = "disabled";
+		};
+	};
+};
diff --git a/arch/arm/configs/at550_defconfig b/arch/arm/configs/at550_defconfig
new file mode 100644
index 000000000..698b2f675
--- /dev/null
+++ b/arch/arm/configs/at550_defconfig
@@ -0,0 +1,34 @@
+# CONFIG_LOCALVERSION_AUTO is not set
+CONFIG_SYSVIPC=y
+CONFIG_NO_HZ_IDLE=y
+CONFIG_HIGH_RES_TIMERS=y
+CONFIG_BLK_DEV_INITRD=y
+CONFIG_ARCH_MULTI_V6=y
+CONFIG_ARCH_AT550=y
+# CONFIG_SUSPEND is not set
+CONFIG_MODULES=y
+CONFIG_MODULE_UNLOAD=y
+CONFIG_PARTITION_ADVANCED=y
+CONFIG_NET=y
+CONFIG_UNIX=y
+CONFIG_DEVTMPFS=y
+CONFIG_DEVTMPFS_MOUNT=y
+CONFIG_INPUT_EVDEV=y
+# CONFIG_INPUT_KEYBOARD is not set
+# CONFIG_INPUT_MOUSE is not set
+CONFIG_INPUT_TOUCHSCREEN=y
+CONFIG_TOUCHSCREEN_AT550=y
+CONFIG_FB=y
+CONFIG_FB_SIMPLE=y
+CONFIG_FRAMEBUFFER_CONSOLE=y
+CONFIG_MMC=y
+CONFIG_MMC_SDHCI=y
+CONFIG_MMC_SDHCI_PLTFM=y
+CONFIG_MMC_SDHCI_AT550=y
+CONFIG_VFAT_FS=y
+CONFIG_TMPFS=y
+CONFIG_NLS_CODEPAGE_437=y
+CONFIG_NLS_ISO8859_1=y
+CONFIG_NLS_UTF8=y
+CONFIG_FONTS=y
+CONFIG_FONT_8x8=y
diff --git a/arch/arm/mach-at550/Kconfig b/arch/arm/mach-at550/Kconfig
new file mode 100644
index 000000000..c6380e529
--- /dev/null
+++ b/arch/arm/mach-at550/Kconfig
@@ -0,0 +1,13 @@
+# SPDX-License-Identifier: GPL-2.0-only
+config ARCH_AT550
+	bool "SiRF AT550 platforms"
+	depends on ARCH_MULTI_V6
+	select ARM_ERRATA_411920
+	select AT550_IRQ
+	select CLKSRC_AT550
+	select CPU_V6
+	help
+	  Support SiRF AT550 systems, including the Yupiteru YPL514si.
+	  The initial support uses firmware-configured peripheral clocks,
+	  pin multiplexing and SDRAM. A bootloader-supplied device tree must
+	  describe the usable RAM region and the divided counter clock rate.
diff --git a/arch/arm/mach-at550/Makefile b/arch/arm/mach-at550/Makefile
new file mode 100644
index 000000000..98a51d234
--- /dev/null
+++ b/arch/arm/mach-at550/Makefile
@@ -0,0 +1,2 @@
+# SPDX-License-Identifier: GPL-2.0-only
+obj-y += at550.o
diff --git a/arch/arm/mach-at550/at550.c b/arch/arm/mach-at550/at550.c
new file mode 100644
index 000000000..affcc9eb3
--- /dev/null
+++ b/arch/arm/mach-at550/at550.c
@@ -0,0 +1,11 @@
+// SPDX-License-Identifier: GPL-2.0-only
+#include <asm/mach/arch.h>
+
+static const char *const at550_dt_compat[] __initconst = {
+	"sirf,at550",
+	NULL,
+};
+
+DT_MACHINE_START(AT550_DT, "SiRF AT550")
+	.dt_compat = at550_dt_compat,
+MACHINE_END

-- 
2.56.0

