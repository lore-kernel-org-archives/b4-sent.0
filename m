From: Rui Cao <i@udp0.com>
Date: Sat, 07 Nov 2026 20:22:01 +0800
Subject: [PATCH 4/4] arm64: dts: mediatek: Add MT6833 and the Xiaomi Redmi
 Note 13 5G
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-mt6833-base-v1-4-bda21083e9f3@udp0.com>
References: <20261107-mt6833-base-v1-0-bda21083e9f3@udp0.com>
In-Reply-To: <20261107-mt6833-base-v1-0-bda21083e9f3@udp0.com>
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
 Rui Cao <i@udp0.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794054121; l=13819;
 i=i@udp0.com; s=20261107; h=from:subject:message-id;
 bh=uIxIEzzU1mADLPxOnxknw3D8VLYCkXpkopxWcfOUpto=;
 b=gK6glUzBS/rKm+NGBRwfuGIyl93RHBHKQmdY9pVK0HuVYjQgpqJD4Zs+liBHzWMxTIpUdJGHM
 NdCBRhPSL6sDkwH08WDsGJs5LLXpvjLIp5xZ8l/shcB28FF/DiYiHwZ
X-Developer-Key: i=i@udp0.com; a=ed25519;
 pk=XZJKcKgnUUjjyw8KuKy7u2QeIX0JLY/L1Fxzwwje41w=
X-Endpoint-Received: by B4 Relay for i@udp0.com/20261107 with auth_id=1443
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a device tree for MediaTek's MT6833 (Dimensity 700): its eight
cores, six Cortex-A55 and two Cortex-A76 in one DynamIQ cluster, with
their caches and PMUs, PSCI, the architected timer, the GICv3, the
watchdog and the first UART.

Add the Xiaomi Redmi Note 13 5G (gold) on it, with its memory, the
regions its bootloader reserves for the firmware it starts, and the
framebuffer the bootloader leaves the panel scanning out.

The cache sizes are the ones the cores report in CCSIDR_EL1. The
bootloader programs CNTFRQ_EL0 (13 MHz), so the timer has no
clock-frequency.

Signed-off-by: Rui Cao <i@udp0.com>
---
 arch/arm64/boot/dts/mediatek/Makefile              |   1 +
 .../arm64/boot/dts/mediatek/mt6833-xiaomi-gold.dts | 205 +++++++++++++
 arch/arm64/boot/dts/mediatek/mt6833.dtsi           | 341 +++++++++++++++++++++
 3 files changed, 547 insertions(+)

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
index 00000000000..6bdcf407fb6
--- /dev/null
+++ b/arch/arm64/boot/dts/mediatek/mt6833-xiaomi-gold.dts
@@ -0,0 +1,205 @@
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
+		reg = <0 0x40000000 1 0x80000000>;
+	};
+
+	/*
+	 * The regions the bootloader reserves for the firmware it starts (ATF,
+	 * TEE, GenieZone, the SSPM, MCUPM and SCP coprocessors, the modem) and
+	 * for itself, as it reports them.
+	 */
+	reserved-memory {
+		#address-cells = <2>;
+		#size-cells = <2>;
+		ranges;
+
+		aee-debug-kinfo@48080000 {
+			reg = <0 0x48080000 0 0x10000>;
+			no-map;
+		};
+
+		ramoops@48090000 {
+			compatible = "ramoops";
+			reg = <0 0x48090000 0 0xe0000>;
+			console-size = <0x40000>;
+			pmsg-size = <0x80000>;
+			no-map;
+		};
+
+		minirdump@48170000 {
+			reg = <0 0x48170000 0 0x10000>;
+			no-map;
+		};
+
+		atf-reserved@48c00000 {
+			reg = <0 0x48c00000 0 0x200000>;
+			no-map;
+		};
+
+		spm-reserved@72c00000 {
+			reg = <0 0x72c00000 0 0x10000>;
+			no-map;
+		};
+
+		framebuffer@73c10000 {
+			reg = <0 0x73c10000 0 0x1df0000>;
+			no-map;
+		};
+
+		tee-shm@75a00000 {
+			reg = <0 0x75a00000 0 0x400000>;
+			no-map;
+		};
+
+		tee-reserved@75e00000 {
+			reg = <0 0x75e00000 0 0x8a00000>;
+			no-map;
+		};
+
+		tee-secmem@7e800000 {
+			reg = <0 0x7e800000 0 0x400000>;
+			no-map;
+		};
+
+		gz-log@7ec00000 {
+			reg = <0 0x7ec00000 0 0x41000>;
+			no-map;
+		};
+
+		mcupm-reserved@7ed00000 {
+			reg = <0 0x7ed00000 0 0x100000>;
+			no-map;
+		};
+
+		gz@7ee00000 {
+			reg = <0 0x7ee00000 0 0x1000000>;
+			no-map;
+		};
+
+		sspm-reserved@7feb0000 {
+			reg = <0 0x7feb0000 0 0x100000>;
+			no-map;
+		};
+
+		log-store@7ffb0000 {
+			reg = <0 0x7ffb0000 0 0x40000>;
+			no-map;
+		};
+
+		emi-mbist-buf@7ffff000 {
+			reg = <0 0x7ffff000 0 0x1000>;
+			no-map;
+		};
+
+		ap-md-c-smem@86000000 {
+			reg = <0 0x86000000 0 0x2960000>;
+			no-map;
+		};
+
+		ap-md-nc-smem@8a000000 {
+			reg = <0 0x8a000000 0 0x1b0000>;
+			no-map;
+		};
+
+		md-mem-usage@8c000000 {
+			reg = <0 0x8c000000 0 0x20c0000>;
+			no-map;
+		};
+
+		drdi-memory@8e0c0000 {
+			reg = <0 0x8e0c0000 0 0x270000>;
+			no-map;
+		};
+
+		md-mem-usage@8e330000 {
+			reg = <0 0x8e330000 0 0x10000>;
+			no-map;
+		};
+
+		md-mem-usage@8f000000 {
+			reg = <0 0x8f000000 0 0xf0000>;
+			no-map;
+		};
+
+		md-mem-usage@90000000 {
+			reg = <0 0x90000000 0 0x7210000>;
+			no-map;
+		};
+
+		md-mem-usage@a7bd0000 {
+			reg = <0 0xa7bd0000 0 0x1730000>;
+			no-map;
+		};
+
+		scp-reserved@b9500000 {
+			reg = <0 0xb9500000 0 0x400000>;
+			no-map;
+		};
+
+		picachu@bfd00000 {
+			reg = <0 0xbfd00000 0 0x80000>;
+			no-map;
+		};
+
+		atf-log-reserved@bfe00000 {
+			reg = <0 0xbfe00000 0 0x40000>;
+			no-map;
+		};
+
+		ccci-tag-mem@bff60000 {
+			reg = <0 0xbff60000 0 0x10000>;
+			no-map;
+		};
+
+		atf-ramdump-reserved@bff70000 {
+			reg = <0 0xbff70000 0 0x80000>;
+			no-map;
+		};
+
+		dramc-rk0@bffff000 {
+			reg = <0 0xbffff000 0 0x1000>;
+			no-map;
+		};
+
+		dpm-reserved@ffe60000 {
+			reg = <0 0xffe60000 0 0x190000>;
+			no-map;
+		};
+
+		dramc-rk1@1bffff000 {
+			reg = <1 0xbffff000 0 0x1000>;
+			no-map;
+		};
+	};
+};
diff --git a/arch/arm64/boot/dts/mediatek/mt6833.dtsi b/arch/arm64/boot/dts/mediatek/mt6833.dtsi
new file mode 100644
index 00000000000..4c5f1381ca6
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
+			compatible = "mediatek,mt6833-wdt", "mediatek,mt6589-wdt";
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

