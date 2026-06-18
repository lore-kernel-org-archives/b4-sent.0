From: Jian Hu <jian.hu@amlogic.com>
Date: Thu, 18 Jun 2026 17:51:36 +0800
Subject: [PATCH v4 1/2] dt-bindings: clock: Add Amlogic A9 peripherals
 clock controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260618-a9_peripherals-v4-1-fe120de44e77@amlogic.com>
References: <20260618-a9_peripherals-v4-0-fe120de44e77@amlogic.com>
In-Reply-To: <20260618-a9_peripherals-v4-0-fe120de44e77@amlogic.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, Jian Hu <jian.hu@amlogic.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781776301; l=17630;
 i=jian.hu@amlogic.com; s=20260415; h=from:subject:message-id;
 bh=/+ZOVqqD2sou5w1R2zkf3DRePt/2B3S604rzu0FsjlU=;
 b=uOlSXjcIkkVfOHwqScL3kKe7YLBPy1g/gp0iTFBgpjiQl/lfQ/MAFHU18vu7KKa76Tv6HpJGT
 qAfUUjtFeT+AKWQ4PG5u9WHI46osj8SYjTE5uveDqqR4SlA/AwlMU+T
X-Developer-Key: i=jian.hu@amlogic.com; a=ed25519;
 pk=zHUE+rNtH9z+Sb8au1/elWknjFQmy5QDVkBoxleuOIA=
X-Endpoint-Received: by B4 Relay for jian.hu@amlogic.com/20260415 with auth_id=735
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the peripherals clock controller dt-bindings for the Amlogic A9
SoC family.

Acked-by: Conor Dooley <conor.dooley@microchip.com>
Signed-off-by: Jian Hu <jian.hu@amlogic.com>
---
 .../clock/amlogic,a9-peripherals-clkc.yaml         | 164 ++++++++++
 .../clock/amlogic,a9-peripherals-clkc.h            | 352 +++++++++++++++++++++
 2 files changed, 516 insertions(+)

diff --git a/Documentation/devicetree/bindings/clock/amlogic,a9-peripherals-clkc.yaml b/Documentation/devicetree/bindings/clock/amlogic,a9-peripherals-clkc.yaml
new file mode 100644
index 000000000000..f0aef005ecf3
--- /dev/null
+++ b/Documentation/devicetree/bindings/clock/amlogic,a9-peripherals-clkc.yaml
@@ -0,0 +1,164 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+# Copyright (C) 2026 Amlogic, Inc. All rights reserved
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/clock/amlogic,a9-peripherals-clkc.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Amlogic A9 Series Peripherals Clock Controller
+
+maintainers:
+  - Neil Armstrong <neil.armstrong@linaro.org>
+  - Jerome Brunet <jbrunet@baylibre.com>
+  - Jian Hu <jian.hu@amlogic.com>
+  - Xianwei Zhao <xianwei.zhao@amlogic.com>
+
+properties:
+  compatible:
+    const: amlogic,a9-peripherals-clkc
+
+  reg:
+    maxItems: 1
+
+  '#clock-cells':
+    const: 1
+
+  clocks:
+    minItems: 27
+    items:
+      - description: input oscillator
+      - description: input fclk div 2
+      - description: input fclk div 3
+      - description: input fclk div 4
+      - description: input fclk div 5
+      - description: input fclk div 7
+      - description: input fclk div 2p5
+      - description: input sys clk
+      - description: input gp1 pll
+      - description: input gp2 pll
+      - description: input sys pll div 16
+      - description: input cpu clk div 16
+      - description: input a78 clk div 16
+      - description: input dsu clk div 16
+      - description: input rtc clk
+      - description: input gp0 pll
+      - description: input hifi0 pll
+      - description: input hifi1 pll
+      - description: input mclk0 pll
+      - description: input mclk1 pll
+      - description: input video1 pll
+      - description: input video2 pll
+      - description: input hdmi out2 clk
+      - description: input hdmi pixel clk
+      - description: input pixel0 pll
+      - description: input pixel1 pll
+      - description: input ddr pll test clk
+      - description: external input rmii oscillator (optional)
+
+  clock-names:
+    minItems: 27
+    items:
+      - const: xtal
+      - const: fdiv2
+      - const: fdiv3
+      - const: fdiv4
+      - const: fdiv5
+      - const: fdiv7
+      - const: fdiv2p5
+      - const: sys
+      - const: gp1
+      - const: gp2
+      - const: sysplldiv16
+      - const: cpudiv16
+      - const: a78div16
+      - const: dsudiv16
+      - const: rtc
+      - const: gp0
+      - const: hifi0
+      - const: hifi1
+      - const: mclk0
+      - const: mclk1
+      - const: vid1
+      - const: vid2
+      - const: hdmiout2
+      - const: hdmipix
+      - const: pix0
+      - const: pix1
+      - const: ddr_test
+      - const: ext_rmii
+
+required:
+  - compatible
+  - reg
+  - '#clock-cells'
+  - clocks
+  - clock-names
+
+additionalProperties: false
+
+examples:
+  - |
+    soc {
+        #address-cells = <2>;
+        #size-cells = <2>;
+
+        clock-controller@200 {
+            compatible = "amlogic,a9-peripherals-clkc";
+            reg = <0x0 0x200 0x0 0x2f8>;
+            #clock-cells = <1>;
+            clocks = <&xtal>,
+                     <&scmi_clk 10>,
+                     <&scmi_clk 12>,
+                     <&scmi_clk 14>,
+                     <&scmi_clk 16>,
+                     <&scmi_clk 18>,
+                     <&scmi_clk 20>,
+                     <&scmi_clk 21>,
+                     <&scmi_clk 33>,
+                     <&scmi_clk 34>,
+                     <&scmi_clk 35>,
+                     <&scmi_clk 36>,
+                     <&scmi_clk 37>,
+                     <&scmi_clk 38>,
+                     <&scmi_clk 40>,
+                     <&gp0 3>,
+                     <&hifi0 3>,
+                     <&hifi1 3>,
+                     <&mclk0 3>,
+                     <&mclk1 3>,
+                     <&vid1>,
+                     <&vid2>,
+                     <&hdmitx 10>,
+                     <&hdmitx 11>,
+                     <&pix0>,
+                     <&pix1>,
+                     <&ddr 3>;
+            clock-names = "xtal",
+                          "fdiv2",
+                          "fdiv3",
+                          "fdiv4",
+                          "fdiv5",
+                          "fdiv7",
+                          "fdiv2p5",
+                          "sys",
+                          "gp1",
+                          "gp2",
+                          "sysplldiv16",
+                          "cpudiv16",
+                          "a78div16",
+                          "dsudiv16",
+                          "rtc",
+                          "gp0",
+                          "hifi0",
+                          "hifi1",
+                          "mclk0",
+                          "mclk1",
+                          "vid1",
+                          "vid2",
+                          "hdmiout2",
+                          "hdmipix",
+                          "pix0",
+                          "pix1",
+                          "ddr_test";
+        };
+    };
diff --git a/include/dt-bindings/clock/amlogic,a9-peripherals-clkc.h b/include/dt-bindings/clock/amlogic,a9-peripherals-clkc.h
new file mode 100644
index 000000000000..50b8f96b435e
--- /dev/null
+++ b/include/dt-bindings/clock/amlogic,a9-peripherals-clkc.h
@@ -0,0 +1,352 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause) */
+/*
+ * Copyright (C) 2026 Amlogic, Inc. All rights reserved.
+ */
+
+#ifndef __AMLOGIC_A9_PERIPHERALS_CLKC_H
+#define __AMLOGIC_A9_PERIPHERALS_CLKC_H
+
+#define CLKID_SYS_AM_AXI			0
+#define CLKID_SYS_DOS				1
+#define CLKID_SYS_MIPI_DSI			2
+#define CLKID_SYS_ETH_PHY			3
+#define CLKID_SYS_AMFC				4
+#define CLKID_SYS_MALI				5
+#define CLKID_SYS_NNA				6
+#define CLKID_SYS_ETH_AXI			7
+#define CLKID_SYS_DP_APB			8
+#define CLKID_SYS_EDPTX_APB			9
+#define CLKID_SYS_U3HSG				10
+#define CLKID_SYS_AUCPU				11
+#define CLKID_SYS_GLB				12
+#define CLKID_SYS_COMBO_DPHY_APB		13
+#define CLKID_SYS_HDMIRX_APB			14
+#define CLKID_SYS_HDMIRX_PCLK			15
+#define CLKID_SYS_MIPI_DSI_PHY			16
+#define CLKID_SYS_CAN0				17
+#define CLKID_SYS_CAN1				18
+#define CLKID_SYS_SD_EMMC_A			19
+#define CLKID_SYS_SD_EMMC_B			20
+#define CLKID_SYS_SD_EMMC_C			21
+#define CLKID_SYS_SC				22
+#define CLKID_SYS_ACODEC			23
+#define CLKID_SYS_MIPI_ISP			24
+#define CLKID_SYS_MSR				25
+#define CLKID_SYS_AUDIO				26
+#define CLKID_SYS_MIPI_DSI_B			27
+#define CLKID_SYS_MIPI_DSI1_PHY			28
+#define CLKID_SYS_ETH				29
+#define CLKID_SYS_ETH_1G_MAC			30
+#define CLKID_SYS_UART_A			31
+#define CLKID_SYS_UART_F			32
+#define CLKID_SYS_TS_A55			33
+#define CLKID_SYS_ETH_1G_AXI			34
+#define CLKID_SYS_TS_DOS			35
+#define CLKID_SYS_U3DRD_B			36
+#define CLKID_SYS_TS_CORE			37
+#define CLKID_SYS_TS_PLL			38
+#define CLKID_SYS_CSI_DIG_CLKIN			39
+#define CLKID_SYS_CVE				40
+#define CLKID_SYS_GE2D				41
+#define CLKID_SYS_SPISG				42
+#define CLKID_SYS_U3DRD_1			43
+#define CLKID_SYS_U2H				44
+#define CLKID_SYS_PCIE_MAC_A			45
+#define CLKID_SYS_U3DRD_A			46
+#define CLKID_SYS_U2DRD				47
+#define CLKID_SYS_PCIE_PHY			48
+#define CLKID_SYS_PCIE_MAC_B			49
+#define CLKID_SYS_PERIPH			50
+#define CLKID_SYS_PIO				51
+#define CLKID_SYS_I3C				52
+#define CLKID_SYS_I2C_M_E			53
+#define CLKID_SYS_I2C_M_F			54
+#define CLKID_SYS_HDMITX_APB			55
+#define CLKID_SYS_I2C_M_I			56
+#define CLKID_SYS_I2C_M_G			57
+#define CLKID_SYS_I2C_M_H			58
+#define CLKID_SYS_HDMI20_AES			59
+#define CLKID_SYS_CSI2_HOST			60
+#define CLKID_SYS_CSI2_ADAPT			61
+#define CLKID_SYS_DSPA				62
+#define CLKID_SYS_PP_DMA			63
+#define CLKID_SYS_PP_WRAPPER			64
+#define CLKID_SYS_VPU_INTR			65
+#define CLKID_SYS_CSI2_PHY			66
+#define CLKID_SYS_SARADC			67
+#define CLKID_SYS_PWM_J				68
+#define CLKID_SYS_PWM_I				69
+#define CLKID_SYS_PWM_H				70
+#define CLKID_SYS_PWM_N				71
+#define CLKID_SYS_PWM_M				72
+#define CLKID_SYS_PWM_L				73
+#define CLKID_SYS_PWM_K				74
+#define CLKID_SD_EMMC_A_SEL			75
+#define CLKID_SD_EMMC_A_DIV			76
+#define CLKID_SD_EMMC_A				77
+#define CLKID_SD_EMMC_B_SEL			78
+#define CLKID_SD_EMMC_B_DIV			79
+#define CLKID_SD_EMMC_B				80
+#define CLKID_SD_EMMC_C_SEL			81
+#define CLKID_SD_EMMC_C_DIV			82
+#define CLKID_SD_EMMC_C				83
+#define CLKID_PWM_H_SEL				84
+#define CLKID_PWM_H_DIV				85
+#define CLKID_PWM_H				86
+#define CLKID_PWM_I_SEL				87
+#define CLKID_PWM_I_DIV				88
+#define CLKID_PWM_I				89
+#define CLKID_PWM_J_SEL				90
+#define CLKID_PWM_J_DIV				91
+#define CLKID_PWM_J				92
+#define CLKID_PWM_K_SEL				93
+#define CLKID_PWM_K_DIV				94
+#define CLKID_PWM_K				95
+#define CLKID_PWM_L_SEL				96
+#define CLKID_PWM_L_DIV				97
+#define CLKID_PWM_L				98
+#define CLKID_PWM_M_SEL				99
+#define CLKID_PWM_M_DIV				100
+#define CLKID_PWM_M				101
+#define CLKID_PWM_N_SEL				102
+#define CLKID_PWM_N_DIV				103
+#define CLKID_PWM_N				104
+#define CLKID_SPISG0_SEL			105
+#define CLKID_SPISG0_DIV			106
+#define CLKID_SPISG0				107
+#define CLKID_SPISG1_SEL			108
+#define CLKID_SPISG1_DIV			109
+#define CLKID_SPISG1				110
+#define CLKID_SPISG2_SEL			111
+#define CLKID_SPISG2_DIV			112
+#define CLKID_SPISG2				113
+#define CLKID_SARADC_SEL			114
+#define CLKID_SARADC_DIV			115
+#define CLKID_SARADC				116
+#define CLKID_AMFC_SEL				117
+#define CLKID_AMFC_DIV				118
+#define CLKID_AMFC				119
+#define CLKID_NNA_SEL				120
+#define CLKID_NNA_DIV				121
+#define CLKID_NNA				122
+#define CLKID_USB_250M_SEL			123
+#define CLKID_USB_250M_DIV			124
+#define CLKID_USB_250M				125
+#define CLKID_USB_48M_PRE_SEL			126
+#define CLKID_USB_48M_PRE_DIV			127
+#define CLKID_USB_48M_PRE			128
+#define CLKID_PCIE0_TL_SEL			129
+#define CLKID_PCIE0_TL_DIV			130
+#define CLKID_PCIE0_TL				131
+#define CLKID_PCIE1_TL_SEL			132
+#define CLKID_PCIE1_TL_DIV			133
+#define CLKID_PCIE1_TL				134
+#define CLKID_CMPR_SEL				135
+#define CLKID_CMPR_DIV				136
+#define CLKID_CMPR				137
+#define CLKID_DEWARPA_SEL			138
+#define CLKID_DEWARPA_DIV			139
+#define CLKID_DEWARPA				140
+#define CLKID_SC_PRE_SEL			141
+#define CLKID_SC_PRE_DIV			142
+#define CLKID_SC_PRE				143
+#define CLKID_SC				144
+#define CLKID_DPTX_APB2_SEL			145
+#define CLKID_DPTX_APB2_DIV			146
+#define CLKID_DPTX_APB2				147
+#define CLKID_DPTX_AUD_SEL			148
+#define CLKID_DPTX_AUD_DIV			149
+#define CLKID_DPTX_AUD				150
+#define CLKID_ISP_SEL				151
+#define CLKID_ISP_DIV				152
+#define CLKID_ISP				153
+#define CLKID_CVE_SEL				154
+#define CLKID_CVE_DIV				155
+#define CLKID_CVE				156
+#define CLKID_VGE_SEL				157
+#define CLKID_VGE_DIV				158
+#define CLKID_VGE				159
+#define CLKID_PP_SEL				160
+#define CLKID_PP_DIV				161
+#define CLKID_PP				162
+#define CLKID_GLB_SEL				163
+#define CLKID_GLB_DIV				164
+#define CLKID_GLB				165
+#define CLKID_USB_48M_DUALDIV_IN		166
+#define CLKID_USB_48M_DUALDIV_DIV		167
+#define CLKID_USB_48M_DUALDIV_SEL		168
+#define CLKID_USB_48M_DUALDIV			169
+#define CLKID_USB_48M				170
+#define CLKID_CAN0_PE_SEL			171
+#define CLKID_CAN0_PE_DIV			172
+#define CLKID_CAN0_PE				173
+#define CLKID_CAN1_PE_SEL			174
+#define CLKID_CAN1_PE_DIV			175
+#define CLKID_CAN1_PE				176
+#define CLKID_CAN0_FILTER_SEL			177
+#define CLKID_CAN0_FILTER_DIV			178
+#define CLKID_CAN0_FILTER			179
+#define CLKID_CAN1_FILTER_SEL			180
+#define CLKID_CAN1_FILTER_DIV			181
+#define CLKID_CAN1_FILTER			182
+#define CLKID_I3C_SEL				183
+#define CLKID_I3C_DIV				184
+#define CLKID_I3C				185
+#define CLKID_TS_DIV				186
+#define CLKID_TS				187
+#define CLKID_ETH_125M_DIV			188
+#define CLKID_ETH_125M				189
+#define CLKID_ETH_RMII_SEL			190
+#define CLKID_ETH_RMII_DIV			191
+#define CLKID_ETH_RMII				192
+#define CLKID_GEN_SEL				193
+#define CLKID_GEN_DIV				194
+#define CLKID_GEN				195
+#define CLKID_CLK24M_IN				196
+#define CLKID_CLK12_24M				197
+#define CLKID_MALI_0_SEL			198
+#define CLKID_MALI_0_DIV			199
+#define CLKID_MALI_0				200
+#define CLKID_MALI_1_SEL			201
+#define CLKID_MALI_1_DIV			202
+#define CLKID_MALI_1				203
+#define CLKID_MALI				204
+#define CLKID_MALI_STACK_0_SEL			205
+#define CLKID_MALI_STACK_0_DIV			206
+#define CLKID_MALI_STACK_0			207
+#define CLKID_MALI_STACK_1_SEL			208
+#define CLKID_MALI_STACK_1_DIV			209
+#define CLKID_MALI_STACK_1			210
+#define CLKID_MALI_STACK			211
+#define CLKID_DSPA_0_SEL			212
+#define CLKID_DSPA_0_DIV			213
+#define CLKID_DSPA_0				214
+#define CLKID_DSPA_1_SEL			215
+#define CLKID_DSPA_1_DIV			216
+#define CLKID_DSPA_1				217
+#define CLKID_DSPA				218
+#define CLKID_HEVCF_0_SEL			219
+#define CLKID_HEVCF_0_DIV			220
+#define CLKID_HEVCF_0				221
+#define CLKID_HEVCF_1_SEL			222
+#define CLKID_HEVCF_1_DIV			223
+#define CLKID_HEVCF_1				224
+#define CLKID_HEVCF				225
+#define CLKID_HCODEC_0_SEL			226
+#define CLKID_HCODEC_0_DIV			227
+#define CLKID_HCODEC_0				228
+#define CLKID_HCODEC_1_SEL			229
+#define CLKID_HCODEC_1_DIV			230
+#define CLKID_HCODEC_1				231
+#define CLKID_HCODEC				232
+#define CLKID_VPU_0_SEL				233
+#define CLKID_VPU_0_DIV				234
+#define CLKID_VPU_0				235
+#define CLKID_VPU_1_SEL				236
+#define CLKID_VPU_1_DIV				237
+#define CLKID_VPU_1				238
+#define CLKID_VPU				239
+#define CLKID_VAPB_0_SEL			240
+#define CLKID_VAPB_0_DIV			241
+#define CLKID_VAPB_0				242
+#define CLKID_VAPB_1_SEL			243
+#define CLKID_VAPB_1_DIV			244
+#define CLKID_VAPB_1				245
+#define CLKID_VAPB				246
+#define CLKID_GE2D				247
+#define CLKID_VPU_CLKB_TMP_SEL			248
+#define CLKID_VPU_CLKB_TMP_DIV			249
+#define CLKID_VPU_CLKB_TMP			250
+#define CLKID_VPU_CLKB_DIV			251
+#define CLKID_VPU_CLKB				252
+#define CLKID_HDMITX_SYS_SEL			253
+#define CLKID_HDMITX_SYS_DIV			254
+#define CLKID_HDMITX_SYS			255
+#define CLKID_HDMITX_PRIF_SEL			256
+#define CLKID_HDMITX_PRIF_DIV			257
+#define CLKID_HDMITX_PRIF			258
+#define CLKID_HDMITX_200M_SEL			259
+#define CLKID_HDMITX_200M_DIV			260
+#define CLKID_HDMITX_200M			261
+#define CLKID_HDMITX_AUD_SEL			262
+#define CLKID_HDMITX_AUD_DIV			263
+#define CLKID_HDMITX_AUD			264
+#define CLKID_HDMIRX_5M_SEL			265
+#define CLKID_HDMIRX_5M_DIV			266
+#define CLKID_HDMIRX_5M				267
+#define CLKID_HDMIRX_2M_SEL			268
+#define CLKID_HDMIRX_2M_DIV			269
+#define CLKID_HDMIRX_2M				270
+#define CLKID_HDMIRX_CFG_SEL			271
+#define CLKID_HDMIRX_CFG_DIV			272
+#define CLKID_HDMIRX_CFG			273
+#define CLKID_HDMIRX_HDCP2X_SEL			274
+#define CLKID_HDMIRX_HDCP2X_DIV			275
+#define CLKID_HDMIRX_HDCP2X			276
+#define CLKID_HDMIRX_ACR_REF_SEL		277
+#define CLKID_HDMIRX_ACR_REF_DIV		278
+#define CLKID_HDMIRX_ACR_REF			279
+#define CLKID_HDMIRX_METER_SEL			280
+#define CLKID_HDMIRX_METER_DIV			281
+#define CLKID_HDMIRX_METER			282
+#define CLKID_VID_LOCK_SEL			283
+#define CLKID_VID_LOCK_DIV			284
+#define CLKID_VID_LOCK				285
+#define CLKID_VDIN_MEAS_SEL			286
+#define CLKID_VDIN_MEAS_DIV			287
+#define CLKID_VDIN_MEAS				288
+#define CLKID_VID_PLL_DIV			289
+#define CLKID_VID_PLL_SEL			290
+#define CLKID_VID_PLL				291
+#define CLKID_VID_PLL_VCLK			292
+#define CLKID_VCLK0_SEL				293
+#define CLKID_VCLK0_IN				294
+#define CLKID_VCLK0_DIV				295
+#define CLKID_VCLK0				296
+#define CLKID_VCLK0_DIV1_EN			297
+#define CLKID_VCLK0_DIV2_EN			298
+#define CLKID_VCLK0_DIV2			299
+#define CLKID_VCLK0_DIV4_EN			300
+#define CLKID_VCLK0_DIV4			301
+#define CLKID_VCLK0_DIV6_EN			302
+#define CLKID_VCLK0_DIV6			303
+#define CLKID_VCLK0_DIV12_EN			304
+#define CLKID_VCLK0_DIV12			305
+#define CLKID_VCLK1_SEL				306
+#define CLKID_VCLK1_IN				307
+#define CLKID_VCLK1_DIV				308
+#define CLKID_VCLK1				309
+#define CLKID_VCLK1_DIV1_EN			310
+#define CLKID_VCLK1_DIV2_EN			311
+#define CLKID_VCLK1_DIV2			312
+#define CLKID_VCLK1_DIV4_EN			313
+#define CLKID_VCLK1_DIV4			314
+#define CLKID_VCLK1_DIV6_EN			315
+#define CLKID_VCLK1_DIV6			316
+#define CLKID_VCLK1_DIV12_EN			317
+#define CLKID_VCLK1_DIV12			318
+#define CLKID_VDAC_SEL				319
+#define CLKID_VDAC				320
+#define CLKID_ENCODER0_SEL			321
+#define CLKID_ENCODER0				322
+#define CLKID_ENCODER1_SEL			323
+#define CLKID_ENCODER1				324
+#define CLKID_HDMITX_PIXEL_SEL			325
+#define CLKID_HDMITX_PIXEL			326
+#define CLKID_HDMITX_FE_SEL			327
+#define CLKID_HDMITX_FE				328
+#define CLKID_HDMITX1_PIXEL_SEL			329
+#define CLKID_HDMITX1_PIXEL			330
+#define CLKID_HDMITX1_FE_SEL			331
+#define CLKID_HDMITX1_FE			332
+#define CLKID_CSI_PHY_SEL			333
+#define CLKID_CSI_PHY_DIV			334
+#define CLKID_CSI_PHY				335
+#define CLKID_DSI_MEAS_SEL			336
+#define CLKID_DSI_MEAS_DIV			337
+#define CLKID_DSI_MEAS				338
+#define CLKID_DSI_B_MEAS_SEL			339
+#define CLKID_DSI_B_MEAS_DIV			340
+#define CLKID_DSI_B_MEAS			341
+
+#endif  /* __AMLOGIC_A9_PERIPHERALS_CLKC_H */

-- 
2.47.1

