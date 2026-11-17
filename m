From: Rui Cao <i@udp0.com>
Date: Tue, 17 Nov 2026 17:11:35 +0800
Subject: [PATCH v2 5/5] arm64: dts: mediatek: Add MT6833 and the Xiaomi
 Redmi Note 13 5G
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-mt6833-base-v2-5-058a0685c40c@udp0.com>
References: <20261117-mt6833-base-v2-0-058a0685c40c@udp0.com>
In-Reply-To: <20261117-mt6833-base-v2-0-058a0685c40c@udp0.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Sean Wang <sean.wang@mediatek.com>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 linux-watchdog@vger.kernel.org, linux-serial@vger.kernel.org, 
 phone-devel@vger.kernel.org, Roman Vivchar <rva333@protonmail.com>, 
 Rui Cao <i@udp0.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794906695; l=11318;
 i=i@udp0.com; s=20261107; h=from:subject:message-id;
 bh=O0MLfKFZkjuBoo2kmJGBComme0o8liP1XxIG55mQug4=;
 b=+i1lGpPfzoGptcpDKAI/OrSyo4xSKEVL99ZKfssSl++26nEzgg+2k1Aj5NnvgsfbG2/RCgdTl
 i3H97PgkgsHCBswfnFXGCBM3g2tTQQ/WEmUmM02T9CFRE7TIDWg9r/7
X-Developer-Key: i=i@udp0.com; a=ed25519;
 pk=XZJKcKgnUUjjyw8KuKy7u2QeIX0JLY/L1Fxzwwje41w=
X-Endpoint-Received: by B4 Relay for i@udp0.com/20261107 with auth_id=1443
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a device tree for MediaTek's MT6833 (Dimensity 700): its eight
cores, six Cortex-A55 and two Cortex-A76 in one DynamIQ cluster, with
their caches and PMUs, PSCI, the architected timer, the GICv3, the
watchdog and the first UART.

Add the Xiaomi Redmi Note 13 5G (gold) on it, with the framebuffer the
bootloader leaves the panel scanning out and a ramoops region. The
memory size and the regions reserved for the firmware the bootloader
starts depend on the RAM variant, so they are left to the bootloader:
the memory node has no size, and reserved-memory holds only the regions
the kernel uses itself.

The cache sizes are the ones the cores report in CCSIDR_EL1. The
bootloader programs CNTFRQ_EL0 (13 MHz), so the timer has no
clock-frequency.

Signed-off-by: Rui Cao <i@udp0.com>
---
 arch/arm64/boot/dts/mediatek/Makefile              |   1 +
 .../arm64/boot/dts/mediatek/mt6833-xiaomi-gold.dts |  57 ++++
 arch/arm64/boot/dts/mediatek/mt6833.dtsi           | 341 +++++++++++++++++++++
 3 files changed, 399 insertions(+)

diff --git a/arch/arm64/boot/dts/mediatek/Makefile b/arch/arm64/boot/dts/mediatek/Makefile
index a86fb313b1a..b8466d4a3d6 100644
--- a/arch/arm64/boot/dts/mediatek/Makefile
+++ b/arch/arm64/boot/dts/mediatek/Makefile
@@ -6,6 +6,7 @@ dtb-$(CONFIG_ARCH_MEDIATEK) += mt6795-evb.dtb
 dtb-$(CONFIG_ARCH_MEDIATEK) += mt6795-sony-xperia-m5.dtb
 dtb-$(CONFIG_ARCH_MEDIATEK) += mt6797-evb.dtb
 dtb-$(CONFIG_ARCH_MEDIATEK) += mt6797-x20-dev.dtb
+dtb-$(CONFIG_ARCH_MEDIATEK) += mt6833-xiaomi-gold.dtb
 dtb-$(CONFIG_ARCH_MEDIATEK) += mt7622-rfb1.dtb
 dtb-$(CONFIG_ARCH_MEDIATEK) += mt7622-bananapi-bpi-r64.dtb
 dtb-$(CONFIG_ARCH_MEDIATEK) += mt7981b-cudy-wr3000-v1.dtb
diff --git a/arch/arm64/boot/dts/mediatek/mt6833-xiaomi-gold.dts b/arch/arm64/boot/dts/mediatek/mt6833-xiaomi-gold.dts
new file mode 100644
index 00000000000..bf5340617e6
--- /dev/null
+++ b/arch/arm64/boot/dts/mediatek/mt6833-xiaomi-gold.dts
@@ -0,0 +1,57 @@
+// SPDX-License-Identifier: (GPL-2.0-only OR MIT)
+/*
+ * Xiaomi Redmi Note 13 5G (gold)
+ *
+ * Copyright (C) 2026 Rui Cao <i@udp0.com>
+ */
+
+/dts-v1/;
+#include "mt6833.dtsi"
+
+/ {
+	model = "Xiaomi Redmi Note 13 5G";
+	compatible = "xiaomi,gold", "mediatek,mt6833";
+	chassis-type = "handset";
+
+	chosen {
+		#address-cells = <2>;
+		#size-cells = <2>;
+		ranges;
+
+		/* The bootloader leaves the panel lit, scanning out this buffer */
+		framebuffer@73c10000 {
+			compatible = "simple-framebuffer";
+			reg = <0 0x73c10000 0 (4352 * 2400)>;
+			width = <1080>;
+			height = <2400>;
+			stride = <4352>;
+			format = "a8r8g8b8";
+		};
+	};
+
+	memory@40000000 {
+		device_type = "memory";
+		/* The bootloader fills in the size */
+		reg = <0 0x40000000 0 0>;
+	};
+
+	/* The bootloader adds the regions it reserves for firmware */
+	reserved-memory {
+		#address-cells = <2>;
+		#size-cells = <2>;
+		ranges;
+
+		ramoops@48090000 {
+			compatible = "ramoops";
+			reg = <0 0x48090000 0 0xe0000>;
+			console-size = <0x40000>;
+			pmsg-size = <0x80000>;
+			no-map;
+		};
+
+		framebuffer@73c10000 {
+			reg = <0 0x73c10000 0 0x1df0000>;
+			no-map;
+		};
+	};
+};
diff --git a/arch/arm64/boot/dts/mediatek/mt6833.dtsi b/arch/arm64/boot/dts/mediatek/mt6833.dtsi
new file mode 100644
index 00000000000..51bcdad846e
--- /dev/null
+++ b/arch/arm64/boot/dts/mediatek/mt6833.dtsi
@@ -0,0 +1,341 @@
+// SPDX-License-Identifier: (GPL-2.0-only OR MIT)
+/*
+ * MediaTek MT6833 (Dimensity 700)
+ *
+ * Copyright (C) 2026 Rui Cao <i@udp0.com>
+ */
+
+#include <dt-bindings/interrupt-controller/arm-gic.h>
+#include <dt-bindings/interrupt-controller/irq.h>
+
+/ {
+	compatible = "mediatek,mt6833";
+	interrupt-parent = <&gic>;
+	#address-cells = <2>;
+	#size-cells = <2>;
+
+	clk26m: oscillator-26m {
+		compatible = "fixed-clock";
+		#clock-cells = <0>;
+		clock-frequency = <26000000>;
+		clock-output-names = "clk26m";
+	};
+
+	cpus {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		cpu0: cpu@0 {
+			device_type = "cpu";
+			compatible = "arm,cortex-a55";
+			reg = <0x000>;
+			enable-method = "psci";
+			capacity-dmips-mhz = <405>;
+			i-cache-size = <32768>;
+			i-cache-line-size = <64>;
+			i-cache-sets = <128>;
+			d-cache-size = <32768>;
+			d-cache-line-size = <64>;
+			d-cache-sets = <128>;
+			next-level-cache = <&l2_0>;
+
+			l2_0: l2-cache {
+				compatible = "cache";
+				cache-level = <2>;
+				cache-unified;
+				cache-size = <131072>;
+				cache-line-size = <64>;
+				cache-sets = <512>;
+				next-level-cache = <&l3_0>;
+			};
+		};
+
+		cpu1: cpu@100 {
+			device_type = "cpu";
+			compatible = "arm,cortex-a55";
+			reg = <0x100>;
+			enable-method = "psci";
+			capacity-dmips-mhz = <405>;
+			i-cache-size = <32768>;
+			i-cache-line-size = <64>;
+			i-cache-sets = <128>;
+			d-cache-size = <32768>;
+			d-cache-line-size = <64>;
+			d-cache-sets = <128>;
+			next-level-cache = <&l2_1>;
+
+			l2_1: l2-cache {
+				compatible = "cache";
+				cache-level = <2>;
+				cache-unified;
+				cache-size = <131072>;
+				cache-line-size = <64>;
+				cache-sets = <512>;
+				next-level-cache = <&l3_0>;
+			};
+		};
+
+		cpu2: cpu@200 {
+			device_type = "cpu";
+			compatible = "arm,cortex-a55";
+			reg = <0x200>;
+			enable-method = "psci";
+			capacity-dmips-mhz = <405>;
+			i-cache-size = <32768>;
+			i-cache-line-size = <64>;
+			i-cache-sets = <128>;
+			d-cache-size = <32768>;
+			d-cache-line-size = <64>;
+			d-cache-sets = <128>;
+			next-level-cache = <&l2_2>;
+
+			l2_2: l2-cache {
+				compatible = "cache";
+				cache-level = <2>;
+				cache-unified;
+				cache-size = <131072>;
+				cache-line-size = <64>;
+				cache-sets = <512>;
+				next-level-cache = <&l3_0>;
+			};
+		};
+
+		cpu3: cpu@300 {
+			device_type = "cpu";
+			compatible = "arm,cortex-a55";
+			reg = <0x300>;
+			enable-method = "psci";
+			capacity-dmips-mhz = <405>;
+			i-cache-size = <32768>;
+			i-cache-line-size = <64>;
+			i-cache-sets = <128>;
+			d-cache-size = <32768>;
+			d-cache-line-size = <64>;
+			d-cache-sets = <128>;
+			next-level-cache = <&l2_3>;
+
+			l2_3: l2-cache {
+				compatible = "cache";
+				cache-level = <2>;
+				cache-unified;
+				cache-size = <131072>;
+				cache-line-size = <64>;
+				cache-sets = <512>;
+				next-level-cache = <&l3_0>;
+			};
+		};
+
+		cpu4: cpu@400 {
+			device_type = "cpu";
+			compatible = "arm,cortex-a55";
+			reg = <0x400>;
+			enable-method = "psci";
+			capacity-dmips-mhz = <405>;
+			i-cache-size = <32768>;
+			i-cache-line-size = <64>;
+			i-cache-sets = <128>;
+			d-cache-size = <32768>;
+			d-cache-line-size = <64>;
+			d-cache-sets = <128>;
+			next-level-cache = <&l2_4>;
+
+			l2_4: l2-cache {
+				compatible = "cache";
+				cache-level = <2>;
+				cache-unified;
+				cache-size = <131072>;
+				cache-line-size = <64>;
+				cache-sets = <512>;
+				next-level-cache = <&l3_0>;
+			};
+		};
+
+		cpu5: cpu@500 {
+			device_type = "cpu";
+			compatible = "arm,cortex-a55";
+			reg = <0x500>;
+			enable-method = "psci";
+			capacity-dmips-mhz = <405>;
+			i-cache-size = <32768>;
+			i-cache-line-size = <64>;
+			i-cache-sets = <128>;
+			d-cache-size = <32768>;
+			d-cache-line-size = <64>;
+			d-cache-sets = <128>;
+			next-level-cache = <&l2_5>;
+
+			l2_5: l2-cache {
+				compatible = "cache";
+				cache-level = <2>;
+				cache-unified;
+				cache-size = <131072>;
+				cache-line-size = <64>;
+				cache-sets = <512>;
+				next-level-cache = <&l3_0>;
+			};
+		};
+
+		cpu6: cpu@600 {
+			device_type = "cpu";
+			compatible = "arm,cortex-a76";
+			reg = <0x600>;
+			enable-method = "psci";
+			capacity-dmips-mhz = <1024>;
+			i-cache-size = <65536>;
+			i-cache-line-size = <64>;
+			i-cache-sets = <256>;
+			d-cache-size = <65536>;
+			d-cache-line-size = <64>;
+			d-cache-sets = <256>;
+			next-level-cache = <&l2_6>;
+
+			l2_6: l2-cache {
+				compatible = "cache";
+				cache-level = <2>;
+				cache-unified;
+				cache-size = <262144>;
+				cache-line-size = <64>;
+				cache-sets = <512>;
+				next-level-cache = <&l3_0>;
+			};
+		};
+
+		cpu7: cpu@700 {
+			device_type = "cpu";
+			compatible = "arm,cortex-a76";
+			reg = <0x700>;
+			enable-method = "psci";
+			capacity-dmips-mhz = <1024>;
+			i-cache-size = <65536>;
+			i-cache-line-size = <64>;
+			i-cache-sets = <256>;
+			d-cache-size = <65536>;
+			d-cache-line-size = <64>;
+			d-cache-sets = <256>;
+			next-level-cache = <&l2_7>;
+
+			l2_7: l2-cache {
+				compatible = "cache";
+				cache-level = <2>;
+				cache-unified;
+				cache-size = <262144>;
+				cache-line-size = <64>;
+				cache-sets = <512>;
+				next-level-cache = <&l3_0>;
+			};
+		};
+
+		cpu-map {
+			cluster0 {
+				core0 {
+					cpu = <&cpu0>;
+				};
+
+				core1 {
+					cpu = <&cpu1>;
+				};
+
+				core2 {
+					cpu = <&cpu2>;
+				};
+
+				core3 {
+					cpu = <&cpu3>;
+				};
+
+				core4 {
+					cpu = <&cpu4>;
+				};
+
+				core5 {
+					cpu = <&cpu5>;
+				};
+
+				core6 {
+					cpu = <&cpu6>;
+				};
+
+				core7 {
+					cpu = <&cpu7>;
+				};
+			};
+		};
+
+		l3_0: l3-cache {
+			compatible = "cache";
+			cache-level = <3>;
+			cache-unified;
+			cache-size = <1048576>;
+			cache-line-size = <64>;
+			cache-sets = <1024>;
+		};
+	};
+
+	pmu-a55 {
+		compatible = "arm,cortex-a55-pmu";
+		interrupt-parent = <&gic>;
+		interrupts = <GIC_PPI 7 IRQ_TYPE_LEVEL_HIGH &ppi_cluster0>;
+	};
+
+	pmu-a76 {
+		compatible = "arm,cortex-a76-pmu";
+		interrupt-parent = <&gic>;
+		interrupts = <GIC_PPI 7 IRQ_TYPE_LEVEL_HIGH &ppi_cluster1>;
+	};
+
+	psci {
+		compatible = "arm,psci-1.0";
+		method = "smc";
+	};
+
+	timer: timer {
+		compatible = "arm,armv8-timer";
+		interrupt-parent = <&gic>;
+		interrupts = <GIC_PPI 13 IRQ_TYPE_LEVEL_HIGH 0>,
+			     <GIC_PPI 14 IRQ_TYPE_LEVEL_HIGH 0>,
+			     <GIC_PPI 11 IRQ_TYPE_LEVEL_HIGH 0>,
+			     <GIC_PPI 10 IRQ_TYPE_LEVEL_HIGH 0>;
+	};
+
+	soc {
+		compatible = "simple-bus";
+		#address-cells = <2>;
+		#size-cells = <2>;
+		ranges;
+
+		gic: interrupt-controller@c000000 {
+			compatible = "arm,gic-v3";
+			reg = <0 0x0c000000 0 0x40000>,
+			      <0 0x0c040000 0 0x200000>;
+			interrupts = <GIC_PPI 9 IRQ_TYPE_LEVEL_HIGH 0>;
+			interrupt-parent = <&gic>;
+			interrupt-controller;
+			#interrupt-cells = <4>;
+			#redistributor-regions = <1>;
+
+			ppi-partitions {
+				ppi_cluster0: interrupt-partition-0 {
+					affinity = <&cpu0 &cpu1 &cpu2 &cpu3 &cpu4 &cpu5>;
+				};
+
+				ppi_cluster1: interrupt-partition-1 {
+					affinity = <&cpu6 &cpu7>;
+				};
+			};
+		};
+
+		watchdog: watchdog@10007000 {
+			compatible = "mediatek,mt6833-wdt";
+			reg = <0 0x10007000 0 0x100>;
+		};
+
+		uart0: serial@11002000 {
+			compatible = "mediatek,mt6833-uart", "mediatek,mt6577-uart";
+			reg = <0 0x11002000 0 0x1000>;
+			interrupts = <GIC_SPI 109 IRQ_TYPE_LEVEL_HIGH 0>;
+			clocks = <&clk26m>, <&clk26m>;
+			clock-names = "baud", "bus";
+			status = "disabled";
+		};
+	};
+};

-- 
Git-157)

