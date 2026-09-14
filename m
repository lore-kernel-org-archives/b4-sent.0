From: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Date: Mon, 14 Sep 2026 15:55:56 +0200
Subject: [PATCH 8/9] riscv: dts: gf: Initial support for the P8700 Boston
 board
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260914-p8700-dts-v1-8-3267f14ebce1@htecgroup.com>
References: <20260914-p8700-dts-v1-0-3267f14ebce1@htecgroup.com>
In-Reply-To: <20260914-p8700-dts-v1-0-3267f14ebce1@htecgroup.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, 
 Djordje Todorovic <djordje.todorovic@htecgroup.com>, 
 Anup Patel <anup@brainfault.org>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Inochi Amaoto <inochiama@outlook.com>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Conor Dooley <conor@kernel.org>, linux-riscv@lists.infradead.org, 
 Vladimir Kondratiev <vladimir.kondratiev@mobileye.com>, 
 Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789394164; l=12458;
 i=aleksa.paunovic@htecgroup.com; s=20250806; h=from:subject:message-id;
 bh=sdKgjEvUZZC8ghjKq0mA+IWSifHHew1uS0qIbTFq0Zo=;
 b=eCS9CDGlBSaLwX04m02bgLCpgxbKPkhAzCqPlL4F9bEU4rjHqrmqDCPXU8Bzg/o1qNezlm5SL
 VR3Ux3RFmBkABkCRYg0z7KKzkVIet9TltRC2Fmf0Ql4feDSBqTm52KW
X-Developer-Key: i=aleksa.paunovic@htecgroup.com; a=ed25519;
 pk=Dn4KMnDdgyhlXJNspQQrlHJ04i7/irG29p2H27Avd+8=
X-Endpoint-Received: by B4 Relay for aleksa.paunovic@htecgroup.com/20250806 with auth_id=476
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add initial device tree for the MIPS P8700 and the device tree
for the Boston FPGA development board with a MIPS P8700 bitfile.

Add related Makefile and KCONFIG changes.

Co-developed-by: Djordje Todorovic <djordje.todorovic@htecgroup.com>
Signed-off-by: Djordje Todorovic <djordje.todorovic@htecgroup.com>
Signed-off-by: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
---
 arch/riscv/Kconfig.socs                 |   6 +
 arch/riscv/boot/dts/Makefile            |   1 +
 arch/riscv/boot/dts/gf/Makefile         |   2 +
 arch/riscv/boot/dts/gf/p8700-boston.dts | 135 ++++++++++++++++++
 arch/riscv/boot/dts/gf/p8700.dtsi       | 241 ++++++++++++++++++++++++++++++++
 5 files changed, 385 insertions(+)

diff --git a/arch/riscv/Kconfig.socs b/arch/riscv/Kconfig.socs
index 429e0758930687c742c4dd09603e71e90dc096a2..78b0a0076feb14ebdafc4b7f0fa1be3aa416d415 100644
--- a/arch/riscv/Kconfig.socs
+++ b/arch/riscv/Kconfig.socs
@@ -18,6 +18,12 @@ config ARCH_ESWIN
 	  This enables support for ESWIN SoC platform hardware,
 	  including the ESWIN EIC7700 SoC.
 
+config ARCH_GF
+	bool "GlobalFoundries SoCs"
+	help
+	  This enables support for GlobalFoundries SoC platform hardware,
+	  including the MIPS P8700.
+
 config ARCH_MICROCHIP_POLARFIRE
 	def_bool ARCH_MICROCHIP
 
diff --git a/arch/riscv/boot/dts/Makefile b/arch/riscv/boot/dts/Makefile
index 69d8751fb17c803f0efb8003e111ee24144c222b..5d8d55c4cf9d0b17f2a8744aa17526819e6c277a 100644
--- a/arch/riscv/boot/dts/Makefile
+++ b/arch/riscv/boot/dts/Makefile
@@ -4,6 +4,7 @@ subdir-y += andes
 subdir-y += anlogic
 subdir-y += canaan
 subdir-y += eswin
+subdir-y += gf
 subdir-y += microchip
 subdir-y += renesas
 subdir-y += sifive
diff --git a/arch/riscv/boot/dts/gf/Makefile b/arch/riscv/boot/dts/gf/Makefile
new file mode 100644
index 0000000000000000000000000000000000000000..180d7cc7f5cf87e48e2219f9ac9882828ca62016
--- /dev/null
+++ b/arch/riscv/boot/dts/gf/Makefile
@@ -0,0 +1,2 @@
+# SPDX-License-Identifier: GPL-2.0
+dtb-$(CONFIG_ARCH_GF) += p8700-boston.dtb
diff --git a/arch/riscv/boot/dts/gf/p8700-boston.dts b/arch/riscv/boot/dts/gf/p8700-boston.dts
new file mode 100644
index 0000000000000000000000000000000000000000..b829899592aeed5f1cfe3323e755410de07dbdb8
--- /dev/null
+++ b/arch/riscv/boot/dts/gf/p8700-boston.dts
@@ -0,0 +1,135 @@
+// SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+/*
+ * Copyright (C) 2025 MIPS
+ *
+ * Boston FPGA development board with a MIPS P8700 bitfile.
+ */
+
+/dts-v1/;
+
+#include "p8700.dtsi"
+
+#include <dt-bindings/interrupt-controller/irq.h>
+
+/* Clock frequency (in Hz) of the FPGA bitfile */
+#define BITFILE_FREQ	25000000
+
+/ {
+	model = "MIPS P8700 Boston";
+	compatible = "gf,mips-p8700-boston";
+
+	aliases {
+		serial0 = &uart0;
+	};
+
+	chosen {
+		stdout-path = "serial0:115200n8";
+	};
+
+	cpus {
+		timebase-frequency = <BITFILE_FREQ>;
+	};
+
+	memory@80000000 {
+		device_type = "memory";
+		reg = <0x80000000 0x80000000>;
+	};
+
+	pci2: pci@14000000 {
+		compatible = "xlnx,axi-pcie-host-1.00.a";
+		device_type = "pci";
+		reg = <0x14000000 0x2000000>;
+
+		#address-cells = <3>;
+		#size-cells = <2>;
+		#interrupt-cells = <1>;
+
+		interrupt-parent = <&aplic_s0>;
+		interrupts = <7 IRQ_TYPE_LEVEL_HIGH>;
+
+		ranges = <0x02000000 0 0x16000000
+			  0x16000000 0 0x100000>;
+
+		bus-range = <0x00 0xff>;
+
+		interrupt-map-mask = <0 0 0 7>;
+		interrupt-map = <0 0 0 1 &pci2_intc 1>,
+				<0 0 0 2 &pci2_intc 2>,
+				<0 0 0 3 &pci2_intc 3>,
+				<0 0 0 4 &pci2_intc 4>;
+
+		pci2_intc: interrupt-controller {
+			interrupt-controller;
+			#address-cells = <0>;
+			#interrupt-cells = <1>;
+		};
+
+		pci2_root@0,0 {
+			compatible = "pci10ee,7021", "pci-bridge";
+			reg = <0x00000000 0 0 0 0>;
+
+			#address-cells = <3>;
+			#size-cells = <2>;
+
+			eg20t_bridge@1,0,0 {
+				compatible = "pci8086,8800", "pci-bridge";
+				reg = <0x00010000 0 0 0 0>;
+
+				#address-cells = <3>;
+				#size-cells = <2>;
+
+				eg20t_mac@2,0,1 {
+					compatible = "pci8086,8802",
+						     "intel,pch-gbe";
+					reg = <0x00020100 0 0 0 0>;
+					phy-reset-gpios = <&eg20t_gpio 6 1>;
+				};
+
+				eg20t_gpio: eg20t_gpio@2,0,2 {
+					compatible = "pci8086,8803",
+						     "intel,eg20t-gpio";
+					reg = <0x00020200 0 0 0 0>;
+
+					gpio-controller;
+					#gpio-cells = <2>;
+				};
+
+				eg20t_i2c@2,12,2 {
+					compatible = "pci8086,8817";
+					reg = <0x00026200 0 0 0 0>;
+
+					#address-cells = <1>;
+					#size-cells = <0>;
+
+					rtc@68 {
+						compatible = "st,m41t81s";
+						reg = <0x68>;
+					};
+				};
+			};
+		};
+	};
+
+	uart0: serial@17ffe000 {
+		compatible = "ns16550a";
+		reg = <0x17ffe000 0x1000>;
+		reg-shift = <2>;
+		reg-io-width = <4>;
+
+		interrupt-parent = <&aplic_s0>;
+		interrupts = <4 IRQ_TYPE_LEVEL_HIGH>;
+
+		clock-frequency = <BITFILE_FREQ>;
+	};
+
+	lcd: lcd@17fff000 {
+		compatible = "img,boston-lcd";
+		reg = <0x17fff000 0x8>;
+	};
+
+	flash@18000000 {
+		compatible = "cfi-flash";
+		reg = <0x18000000 0x8000000>;
+		bank-width = <2>;
+	};
+};
diff --git a/arch/riscv/boot/dts/gf/p8700.dtsi b/arch/riscv/boot/dts/gf/p8700.dtsi
new file mode 100644
index 0000000000000000000000000000000000000000..ba1854df5201bc4a6ca26868811834a7847dc624
--- /dev/null
+++ b/arch/riscv/boot/dts/gf/p8700.dtsi
@@ -0,0 +1,241 @@
+// SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+/*
+ * Copyright (C) 2025 MIPS
+ */
+
+/dts-v1/;
+
+/ {
+	#address-cells = <1>;
+	#size-cells = <1>;
+
+	cpus {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		cpu0: cpu@0 {
+			device_type = "cpu";
+			compatible = "gf,mips-p8700", "riscv";
+			reg = <0x0>;
+			mmu-type = "riscv,sv39";
+			riscv,cbom-block-size = <64>;
+			riscv,isa-base = "rv64i";
+			riscv,isa-extensions = "i", "m", "a", "f", "d", "c",
+					       "zicntr", "zicsr", "zifencei",
+					       "zihpm", "zba", "zbb",
+					       "xmipsexectl";
+
+			cpu0_intc: interrupt-controller {
+				compatible = "riscv,cpu-intc";
+				interrupt-controller;
+				#interrupt-cells = <1>;
+			};
+		};
+
+		cpu1: cpu@1 {
+			device_type = "cpu";
+			compatible = "gf,mips-p8700", "riscv";
+			reg = <0x1>;
+			mmu-type = "riscv,sv39";
+			riscv,cbom-block-size = <64>;
+			riscv,isa-base = "rv64i";
+			riscv,isa-extensions = "i", "m", "a", "f", "d", "c",
+					       "zicntr", "zicsr", "zifencei",
+					       "zihpm", "zba", "zbb",
+					       "xmipsexectl";
+
+			cpu1_intc: interrupt-controller {
+				compatible = "riscv,cpu-intc";
+				interrupt-controller;
+				#interrupt-cells = <1>;
+			};
+		};
+
+		cpu2: cpu@10 {
+			device_type = "cpu";
+			compatible = "gf,mips-p8700", "riscv";
+			reg = <0x10>;
+			mmu-type = "riscv,sv39";
+			riscv,cbom-block-size = <64>;
+			riscv,isa-base = "rv64i";
+			riscv,isa-extensions = "i", "m", "a", "f", "d", "c",
+					       "zicntr", "zicsr", "zifencei",
+					       "zihpm", "zba", "zbb",
+					       "xmipsexectl";
+
+			cpu2_intc: interrupt-controller {
+				compatible = "riscv,cpu-intc";
+				interrupt-controller;
+				#interrupt-cells = <1>;
+			};
+		};
+
+		cpu3: cpu@11 {
+			device_type = "cpu";
+			compatible = "gf,mips-p8700", "riscv";
+			reg = <0x11>;
+			mmu-type = "riscv,sv39";
+			riscv,cbom-block-size = <64>;
+			riscv,isa-base = "rv64i";
+			riscv,isa-extensions = "i", "m", "a", "f", "d", "c",
+					       "zicntr", "zicsr", "zifencei",
+					       "zihpm", "zba", "zbb",
+					       "xmipsexectl";
+
+			cpu3_intc: interrupt-controller {
+				compatible = "riscv,cpu-intc";
+				interrupt-controller;
+				#interrupt-cells = <1>;
+			};
+		};
+
+		cpu4: cpu@20 {
+			device_type = "cpu";
+			compatible = "gf,mips-p8700", "riscv";
+			reg = <0x20>;
+			mmu-type = "riscv,sv39";
+			riscv,cbom-block-size = <64>;
+			riscv,isa-base = "rv64i";
+			riscv,isa-extensions = "i", "m", "a", "f", "d", "c",
+					       "zicntr", "zicsr", "zifencei",
+					       "zihpm", "zba", "zbb",
+					       "xmipsexectl";
+
+			cpu4_intc: interrupt-controller {
+				compatible = "riscv,cpu-intc";
+				interrupt-controller;
+				#interrupt-cells = <1>;
+			};
+		};
+
+		cpu5: cpu@21 {
+			device_type = "cpu";
+			compatible = "gf,mips-p8700", "riscv";
+			reg = <0x21>;
+			mmu-type = "riscv,sv39";
+			riscv,cbom-block-size = <64>;
+			riscv,isa-base = "rv64i";
+			riscv,isa-extensions = "i", "m", "a", "f", "d", "c",
+					       "zicntr", "zicsr", "zifencei",
+					       "zihpm", "zba", "zbb",
+					       "xmipsexectl";
+
+			cpu5_intc: interrupt-controller {
+				compatible = "riscv,cpu-intc";
+				interrupt-controller;
+				#interrupt-cells = <1>;
+			};
+		};
+
+		cpu6: cpu@30 {
+			device_type = "cpu";
+			compatible = "gf,mips-p8700", "riscv";
+			reg = <0x30>;
+			mmu-type = "riscv,sv39";
+			riscv,cbom-block-size = <64>;
+			riscv,isa-base = "rv64i";
+			riscv,isa-extensions = "i", "m", "a", "f", "d", "c",
+					       "zicntr", "zicsr", "zifencei",
+					       "zihpm", "zba", "zbb",
+					       "xmipsexectl";
+
+			cpu6_intc: interrupt-controller {
+				compatible = "riscv,cpu-intc";
+				interrupt-controller;
+				#interrupt-cells = <1>;
+			};
+		};
+
+		cpu7: cpu@31 {
+			device_type = "cpu";
+			compatible = "gf,mips-p8700", "riscv";
+			reg = <0x31>;
+			mmu-type = "riscv,sv39";
+			riscv,cbom-block-size = <64>;
+			riscv,isa-base = "rv64i";
+			riscv,isa-extensions = "i", "m", "a", "f", "d", "c",
+					       "zicntr", "zicsr", "zifencei",
+					       "zihpm", "zba", "zbb",
+					       "xmipsexectl";
+
+			cpu7_intc: interrupt-controller {
+				compatible = "riscv,cpu-intc";
+				interrupt-controller;
+				#interrupt-cells = <1>;
+			};
+		};
+	};
+
+	soc: soc {
+		compatible = "simple-bus";
+		#address-cells = <1>;
+		#size-cells = <1>;
+		ranges;
+
+		mtimer0: timer@16108050 {
+			compatible = "gf,mips-p8700-aclint-mtimer";
+			reg = <0x16108050 0x8>,
+			      <0x16154000 0x7ff8>;
+			reg-names = "mtime", "mtimecmp";
+			interrupts-extended = <&cpu0_intc 7>, <&cpu1_intc 7>,
+					      <&cpu2_intc 7>, <&cpu3_intc 7>,
+					      <&cpu4_intc 7>, <&cpu5_intc 7>,
+					      <&cpu6_intc 7>, <&cpu7_intc 7>;
+		};
+
+		aplic_m0: interrupt-controller@16140000 {
+			compatible = "gf,mips-p8700-aplic", "riscv,aplic";
+			reg = <0x16140000 0x8000>;
+			interrupt-controller;
+			#interrupt-cells = <2>;
+			interrupts-extended = <&cpu0_intc 11>, <&cpu1_intc 11>,
+					      <&cpu2_intc 11>, <&cpu3_intc 11>,
+					      <&cpu4_intc 11>, <&cpu5_intc 11>,
+					      <&cpu6_intc 11>, <&cpu7_intc 11>;
+			riscv,num-sources = <53>;
+			riscv,hart-indexes = <0x00 0x01 0x10 0x11
+					      0x20 0x21 0x30 0x31>;
+			riscv,children = <&aplic_s0>;
+			riscv,delegation = <&aplic_s0 1 53>;
+		};
+
+		mswi0: mswi@16150000 {
+			compatible = "gf,mips-p8700-aclint-mswi";
+			reg = <0x16150000 0x4000>;
+			interrupts-extended = <&cpu0_intc 3>, <&cpu1_intc 3>,
+					      <&cpu2_intc 3>, <&cpu3_intc 3>,
+					      <&cpu4_intc 3>, <&cpu5_intc 3>,
+					      <&cpu6_intc 3>, <&cpu7_intc 3>;
+			riscv,hart-indexes = <0x00 0x01 0x10 0x11
+					      0x20 0x21 0x30 0x31>;
+		};
+
+		aplic_s0: interrupt-controller@16160000 {
+			compatible = "gf,mips-p8700-aplic", "riscv,aplic";
+			reg = <0x16160000 0x8000>;
+			interrupt-controller;
+			#interrupt-cells = <2>;
+			interrupts-extended = <&cpu0_intc 9>, <&cpu1_intc 9>,
+					      <&cpu2_intc 9>, <&cpu3_intc 9>,
+					      <&cpu4_intc 9>, <&cpu5_intc 9>,
+					      <&cpu6_intc 9>, <&cpu7_intc 9>;
+			riscv,num-sources = <53>;
+			riscv,hart-indexes = <0x00 0x01 0x10 0x11
+					      0x20 0x21 0x30 0x31>;
+		};
+
+		sswi0: interrupt-controller@1616c000 {
+			compatible = "gf,mips-p8700-aclint-sswi",
+				     "mips,p8700-aclint-sswi";
+			reg = <0x1616c000 0x4000>;
+			interrupt-controller;
+			#interrupt-cells = <0>;
+			interrupts-extended = <&cpu0_intc 1>, <&cpu1_intc 1>,
+					      <&cpu2_intc 1>, <&cpu3_intc 1>,
+					      <&cpu4_intc 1>, <&cpu5_intc 1>,
+					      <&cpu6_intc 1>, <&cpu7_intc 1>;
+			riscv,hart-indexes = <0x00 0x01 0x10 0x11
+					      0x20 0x21 0x30 0x31>;
+		};
+	};
+};

-- 
2.43.0

