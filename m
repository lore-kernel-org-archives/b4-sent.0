From: Han Gao <gaohan@iscas.ac.cn>
Date: Sat, 14 Nov 2026 06:33:31 +0800
Subject: [PATCH 05/19] dt-bindings: clock: sunxi-ng: document the Allwinner
 V861 CCUs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-v861-v1-5-eb71ec3ee523@iscas.ac.cn>
References: <20261114-v861-v1-0-eb71ec3ee523@iscas.ac.cn>
In-Reply-To: <20261114-v861-v1-0-eb71ec3ee523@iscas.ac.cn>
To: Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Albert Ou <aou@eecs.berkeley.edu>, Alexandre Ghiti <alex@ghiti.fr>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Guo Ren <guoren@kernel.org>, 
 Thomas Gleixner <tglx@kernel.org>, Radu Rendec <radu@rendec.net>, 
 Samuel Holland <samuel.holland@sifive.com>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Anup Patel <anup@brainfault.org>, Han Gao <gaohan@iscas.ac.cn>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Maxime Ripard <mripard@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Andre Przywara <andre.przywara@arm.com>
Cc: Han Gao <rabenda.cn@gmail.com>, linux-riscv@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@sifive.com>, Conor Dooley <conor@kernel.org>, 
 devicetree@vger.kernel.org, linux-csky@vger.kernel.org, 
 linux-sunxi@lists.linux.dev, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rtc@vger.kernel.org, 
 linux-gpio@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794609209; l=9862;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=X6amVifX6wTJABP+6L3zVQlUeUCCFovpXLSux1h5A9k=;
 b=LmCm9nqfiu9N0qGbfs5+yqm7KNaE4hFFBfHVT4pJugGV8Tb151nx/LUh7lGpNUtcFLazVJaUp
 cD2aVCDe+XeBYGOj6NKiIBvccDWYy9a/NnL1UWTJKCx5OQ19DB9CtWR
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The V861 has a main CCU and a PRCM CCU. Add the binding and the clock
and reset indices for both.

Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 .../bindings/clock/allwinner,sun252i-v861-ccu.yaml |  99 ++++++++++++++++
 include/dt-bindings/clock/sun252i-v861-ccu.h       | 127 +++++++++++++++++++++
 include/dt-bindings/clock/sun252i-v861-r-ccu.h     |  14 +++
 include/dt-bindings/reset/sun252i-v861-ccu.h       |  55 +++++++++
 include/dt-bindings/reset/sun252i-v861-r-ccu.h     |  12 ++
 5 files changed, 307 insertions(+)

diff --git a/Documentation/devicetree/bindings/clock/allwinner,sun252i-v861-ccu.yaml b/Documentation/devicetree/bindings/clock/allwinner,sun252i-v861-ccu.yaml
new file mode 100644
index 000000000000..29fc23ab2401
--- /dev/null
+++ b/Documentation/devicetree/bindings/clock/allwinner,sun252i-v861-ccu.yaml
@@ -0,0 +1,99 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/clock/allwinner,sun252i-v861-ccu.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Allwinner V861 Clock Control Unit
+
+maintainers:
+  - Han Gao <gaohan@iscas.ac.cn>
+
+properties:
+  "#clock-cells":
+    const: 1
+
+  "#reset-cells":
+    const: 1
+
+  compatible:
+    enum:
+      - allwinner,sun252i-v861-ccu
+      - allwinner,sun252i-v861-r-ccu
+
+  reg:
+    maxItems: 1
+
+  clocks:
+    minItems: 3
+    maxItems: 4
+
+  clock-names:
+    minItems: 3
+    maxItems: 4
+
+required:
+  - "#clock-cells"
+  - "#reset-cells"
+  - compatible
+  - reg
+  - clocks
+  - clock-names
+
+allOf:
+  - if:
+      properties:
+        compatible:
+          enum:
+            - allwinner,sun252i-v861-ccu
+
+    then:
+      properties:
+        clocks:
+          items:
+            - description: High Frequency Oscillator (usually at 24MHz)
+            - description: Low Frequency Oscillator (usually at 32kHz)
+            - description: Internal Oscillator
+
+        clock-names:
+          items:
+            - const: hosc
+            - const: losc
+            - const: iosc
+
+  - if:
+      properties:
+        compatible:
+          enum:
+            - allwinner,sun252i-v861-r-ccu
+
+    then:
+      properties:
+        clocks:
+          items:
+            - description: High Frequency Oscillator (usually at 24MHz)
+            - description: Low Frequency Oscillator (usually at 32kHz)
+            - description: Internal Oscillator
+            - description: Peripherals PLL (200 MHz output)
+
+        clock-names:
+          items:
+            - const: hosc
+            - const: losc
+            - const: iosc
+            - const: pll-periph
+
+additionalProperties: false
+
+examples:
+  - |
+    clock-controller@2001000 {
+        compatible = "allwinner,sun252i-v861-ccu";
+        reg = <0x02001000 0x1000>;
+        clocks = <&osc24M>, <&rtc 0>, <&rtc 2>;
+        clock-names = "hosc", "losc", "iosc";
+        #clock-cells = <1>;
+        #reset-cells = <1>;
+    };
+
+...
diff --git a/include/dt-bindings/clock/sun252i-v861-ccu.h b/include/dt-bindings/clock/sun252i-v861-ccu.h
new file mode 100644
index 000000000000..1123b894a493
--- /dev/null
+++ b/include/dt-bindings/clock/sun252i-v861-ccu.h
@@ -0,0 +1,127 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR MIT) */
+/*
+ * Copyright (c) 2026 Han Gao <gaohan@iscas.ac.cn>
+ */
+
+#ifndef _DT_BINDINGS_CLK_SUN252I_V861_CCU_H_
+#define _DT_BINDINGS_CLK_SUN252I_V861_CCU_H_
+
+#define CLK_PLL_DDR		0
+#define CLK_PLL_PERIPH0_4X	1
+#define CLK_PLL_PERIPH0_2X	2
+#define CLK_PLL_PERIPH0_800M	3
+#define CLK_PLL_PERIPH0_480M	4
+#define CLK_PLL_PERIPH0_600M	5
+#define CLK_PLL_PERIPH0_400M	6
+#define CLK_PLL_PERIPH0_300M	7
+#define CLK_PLL_PERIPH0_200M	8
+#define CLK_PLL_PERIPH0_160M	9
+#define CLK_PLL_PERIPH0_150M	10
+#define CLK_PLL_VIDEO_8X	11
+#define CLK_PLL_VIDEO_4X	12
+#define CLK_PLL_VIDEO_2X	13
+#define CLK_PLL_VIDEO_1X	14
+#define CLK_PLL_CSI_8X		15
+#define CLK_PLL_CSI_4X		16
+#define CLK_PLL_CSI_2X		17
+#define CLK_PLL_CSI_1X		18
+#define CLK_PLL_AUDIO		19
+#define CLK_PLL_AUDIO_DIV2	20
+#define CLK_PLL_AUDIO_DIV3	21
+#define CLK_PLL_AUDIO_DIV5	22
+#define CLK_PLL_AUDIO_4X	23
+#define CLK_PLL_AUDIO_1X	24
+#define CLK_PLL_NPU_8X		25
+#define CLK_PLL_NPU_4X		26
+#define CLK_PLL_NPU_2X		27
+#define CLK_PLL_NPU_1X		28
+#define CLK_AHB			29
+#define CLK_APB0		30
+#define CLK_APB1		31
+#define CLK_APB_UART		32
+#define CLK_DE			33
+#define CLK_BUS_DE		34
+#define CLK_G2D			35
+#define CLK_BUS_G2D		36
+#define CLK_CE			37
+#define CLK_BUS_CE		38
+#define CLK_BUS_CE_SYS		39
+#define CLK_VE			40
+#define CLK_BUS_VE		41
+#define CLK_NPU			42
+#define CLK_BUS_NPU		43
+#define CLK_BUS_SGDMA		44
+#define CLK_BUS_NDMA		45
+#define CLK_BUS_MSGBOX0		46
+#define CLK_BUS_MSGBOX1		47
+#define CLK_BUS_SPINLOCK	48
+#define CLK_BUS_HSTIMER		49
+#define CLK_AVS			50
+#define CLK_BUS_TIMER		51
+#define CLK_BUS_DBG		52
+#define CLK_BUS_PWM		53
+#define CLK_DRAM		54
+#define CLK_MBUS		55
+#define CLK_MBUS_DMA		56
+#define CLK_MBUS_VE		57
+#define CLK_MBUS_CE		58
+#define CLK_MBUS_CSI		59
+#define CLK_MBUS_ISP		60
+#define CLK_MBUS_G2D		61
+#define CLK_BUS_DRAM		62
+#define CLK_MMC0		63
+#define CLK_MMC1		64
+#define CLK_MMC2		65
+#define CLK_BUS_MMC0		66
+#define CLK_BUS_MMC1		67
+#define CLK_BUS_MMC2		68
+#define CLK_PSRAM		69
+#define CLK_BUS_PSRAM		70
+#define CLK_BUS_UART0		71
+#define CLK_BUS_UART1		72
+#define CLK_BUS_UART2		73
+#define CLK_BUS_UART3		74
+#define CLK_BUS_I2C0		75
+#define CLK_BUS_I2C1		76
+#define CLK_BUS_I2C2		77
+#define CLK_BUS_I2C3		78
+#define CLK_SPI0		79
+#define CLK_SPI1		80
+#define CLK_SPI2		81
+#define CLK_SPIF		82
+#define CLK_BUS_SPI0		83
+#define CLK_BUS_SPI1		84
+#define CLK_BUS_SPI2		85
+#define CLK_BUS_SPIF		86
+#define CLK_GMAC_25M		87
+#define CLK_BUS_GMAC		88
+#define CLK_BUS_GPADC		89
+#define CLK_BUS_THS		90
+#define CLK_I2S0		91
+#define CLK_BUS_I2S0		92
+#define CLK_AUDIO_CODEC_DAC	93
+#define CLK_AUDIO_CODEC_ADC	94
+#define CLK_BUS_AUDIO_CODEC	95
+#define CLK_USB_OHCI0		96
+#define CLK_BUS_OHCI0		97
+#define CLK_BUS_EHCI0		98
+#define CLK_BUS_OTG		99
+#define CLK_BUS_DPSS_TOP	100
+#define CLK_TCON_LCD		101
+#define CLK_BUS_TCON_LCD	102
+#define CLK_CSI			103
+#define CLK_CSI_MCLK0		104
+#define CLK_CSI_MCLK1		105
+#define CLK_CSI_MCLK2		106
+#define CLK_BUS_CSI		107
+#define CLK_FANOUT_24M		108
+#define CLK_FANOUT_12M		109
+#define CLK_FANOUT_16M		110
+#define CLK_FANOUT_25M		111
+#define CLK_FANOUT_27M		112
+#define CLK_FANOUT_PCLK		113
+#define CLK_FANOUT0		114
+#define CLK_FANOUT1		115
+#define CLK_FANOUT2		116
+
+#endif /* _DT_BINDINGS_CLK_SUN252I_V861_CCU_H_ */
diff --git a/include/dt-bindings/clock/sun252i-v861-r-ccu.h b/include/dt-bindings/clock/sun252i-v861-r-ccu.h
new file mode 100644
index 000000000000..41eaf8aab2c0
--- /dev/null
+++ b/include/dt-bindings/clock/sun252i-v861-r-ccu.h
@@ -0,0 +1,14 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR MIT) */
+/*
+ * Copyright (c) 2026 Han Gao <gaohan@iscas.ac.cn>
+ */
+
+#ifndef _DT_BINDINGS_CLK_SUN252I_V861_R_CCU_H_
+#define _DT_BINDINGS_CLK_SUN252I_V861_R_CCU_H_
+
+#define CLK_R_AHB		0
+#define CLK_R_APB0		1
+#define CLK_BUS_R_PPU		2
+#define CLK_BUS_R_RTC		3
+
+#endif /* _DT_BINDINGS_CLK_SUN252I_V861_R_CCU_H_ */
diff --git a/include/dt-bindings/reset/sun252i-v861-ccu.h b/include/dt-bindings/reset/sun252i-v861-ccu.h
new file mode 100644
index 000000000000..4e0245c6c99a
--- /dev/null
+++ b/include/dt-bindings/reset/sun252i-v861-ccu.h
@@ -0,0 +1,55 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR MIT) */
+/*
+ * Copyright (c) 2026 Han Gao <gaohan@iscas.ac.cn>
+ */
+
+#ifndef _DT_BINDINGS_RST_SUN252I_V861_CCU_H_
+#define _DT_BINDINGS_RST_SUN252I_V861_CCU_H_
+
+#define RST_MBUS		0
+#define RST_BUS_DE		1
+#define RST_BUS_G2D		2
+#define RST_BUS_CE		3
+#define RST_BUS_CE_SYS		4
+#define RST_BUS_VE		5
+#define RST_BUS_NPU		6
+#define RST_BUS_SGDMA		7
+#define RST_BUS_NDMA		8
+#define RST_BUS_MSGBOX0		9
+#define RST_BUS_MSGBOX1		10
+#define RST_BUS_SPINLOCK	11
+#define RST_BUS_HSTIMER		12
+#define RST_BUS_TIMER		13
+#define RST_BUS_DBG		14
+#define RST_BUS_PWM		15
+#define RST_BUS_DRAM		16
+#define RST_BUS_MMC0		17
+#define RST_BUS_MMC1		18
+#define RST_BUS_MMC2		19
+#define RST_BUS_PSRAM		20
+#define RST_BUS_UART0		21
+#define RST_BUS_UART1		22
+#define RST_BUS_UART2		23
+#define RST_BUS_UART3		24
+#define RST_BUS_I2C0		25
+#define RST_BUS_I2C1		26
+#define RST_BUS_I2C2		27
+#define RST_BUS_I2C3		28
+#define RST_BUS_SPI0		29
+#define RST_BUS_SPI1		30
+#define RST_BUS_SPI2		31
+#define RST_BUS_SPIF		32
+#define RST_BUS_GMAC		33
+#define RST_BUS_GPADC		34
+#define RST_BUS_THS		35
+#define RST_BUS_I2S0		36
+#define RST_BUS_AUDIO_CODEC	37
+#define RST_USB_PHY0		38
+#define RST_BUS_OHCI0		39
+#define RST_BUS_EHCI0		40
+#define RST_BUS_OTG		41
+#define RST_BUS_DPSS_TOP	42
+#define RST_BUS_TCON_LCD	43
+#define RST_BUS_CSI		44
+
+#endif /* _DT_BINDINGS_RST_SUN252I_V861_CCU_H_ */
diff --git a/include/dt-bindings/reset/sun252i-v861-r-ccu.h b/include/dt-bindings/reset/sun252i-v861-r-ccu.h
new file mode 100644
index 000000000000..ed0f3063df49
--- /dev/null
+++ b/include/dt-bindings/reset/sun252i-v861-r-ccu.h
@@ -0,0 +1,12 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR MIT) */
+/*
+ * Copyright (c) 2026 Han Gao <gaohan@iscas.ac.cn>
+ */
+
+#ifndef _DT_BINDINGS_RST_SUN252I_V861_R_CCU_H_
+#define _DT_BINDINGS_RST_SUN252I_V861_R_CCU_H_
+
+#define RST_BUS_R_PPU		0
+#define RST_BUS_R_RTC		1
+
+#endif /* _DT_BINDINGS_RST_SUN252I_V861_R_CCU_H_ */

-- 
2.55.0

