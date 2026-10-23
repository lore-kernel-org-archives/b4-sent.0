From: Cunhao Lu <1579567540@qq.com>
Date: Fri, 23 Oct 2026 18:33:47 +0800
Subject: [PATCH v2 1/3] dt-bindings: clock: rockchip: Add RK3572 CRU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261023-add-board-ok3572-c-clk-v2-1-90b98836be6e@qq.com>
References: <20261023-add-board-ok3572-c-clk-v2-0-90b98836be6e@qq.com>
In-Reply-To: <20261023-add-board-ok3572-c-clk-v2-0-90b98836be6e@qq.com>
To: Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Elaine Zhang <zhangqing@rock-chips.com>, 
 Richard Cochran <richardcochran@gmail.com>
Cc: Cunhao Lu <1579567540@qq.com>, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 netdev@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792751694; l=52889;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=oUdsLE2MxdDKWQMq0FH6ke4dTnVfV/5AWK60V1WIqAs=;
 b=dqm9wNNFIOjngMzY+KL1FebFRudmI+UUvmhJ0WB0Zu1vhZaSHFpb6or/uDqgSwIgcYOuezSbJ
 h2b7q3jIqeTCJtStcy7ezFuK8LmUoxScw9ThKxhdMrZaTq9k2jtN3FY
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Elaine Zhang <zhangqing@rock-chips.com>

The RK3572 CRU uses the PMU0 GRF for the AUPLL reference mux.
Describe the controller and define its clock and reset IDs.

Signed-off-by: Elaine Zhang <zhangqing@rock-chips.com>

- Documented the xin24m input.
- Made the PMU0 GRF phandle required.
- Updated the example.

Signed-off-by: Cunhao Lu <1579567540@qq.com>
---
 .../bindings/clock/rockchip,rk3572-cru.yaml        |  57 ++
 include/dt-bindings/clock/rockchip,rk3572-cru.h    | 560 ++++++++++++++++
 include/dt-bindings/reset/rockchip,rk3572-cru.h    | 713 +++++++++++++++++++++
 3 files changed, 1330 insertions(+)

diff --git a/Documentation/devicetree/bindings/clock/rockchip,rk3572-cru.yaml b/Documentation/devicetree/bindings/clock/rockchip,rk3572-cru.yaml
new file mode 100644
index 000000000000..89e360ccb884
--- /dev/null
+++ b/Documentation/devicetree/bindings/clock/rockchip,rk3572-cru.yaml
@@ -0,0 +1,57 @@
+# SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/clock/rockchip,rk3572-cru.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Rockchip RK3572 Family Clock and Reset Control Module
+
+maintainers:
+  - Elaine Zhang <zhangqing@rock-chips.com>
+  - Heiko Stuebner <heiko@sntech.de>
+
+description:
+  The RK3572 CRU supplies peripheral clocks and resets.
+
+properties:
+  compatible:
+    const: rockchip,rk3572-cru
+
+  reg:
+    maxItems: 1
+
+  "#clock-cells":
+    const: 1
+
+  "#reset-cells":
+    const: 1
+
+  clocks:
+    maxItems: 1
+
+  clock-names:
+    items:
+      - const: xin24m
+
+  rockchip,grf:
+    $ref: /schemas/types.yaml#/definitions/phandle
+    description: PMU0 GRF register block.
+
+required:
+  - compatible
+  - reg
+  - "#clock-cells"
+  - "#reset-cells"
+  - rockchip,grf
+
+additionalProperties: false
+
+examples:
+  - |
+    clock-controller@26090000 {
+      compatible = "rockchip,rk3572-cru";
+      reg = <0x26090000 0x60000>;
+      #clock-cells = <1>;
+      #reset-cells = <1>;
+      rockchip,grf = <&pmu0_grf>;
+    };
diff --git a/include/dt-bindings/clock/rockchip,rk3572-cru.h b/include/dt-bindings/clock/rockchip,rk3572-cru.h
new file mode 100644
index 000000000000..9c586d9e9ae9
--- /dev/null
+++ b/include/dt-bindings/clock/rockchip,rk3572-cru.h
@@ -0,0 +1,560 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR MIT) */
+/*
+ * Copyright (c) 2025 Rockchip Electronics Co., Ltd.
+ * Author: Elaine Zhang <zhangqing@rock-chips.com>
+ */
+#ifndef _DT_BINDINGS_CLK_ROCKCHIP_RK3572_H
+#define _DT_BINDINGS_CLK_ROCKCHIP_RK3572_H
+
+/* PLLs */
+#define PLL_PPLL				0
+#define PLL_BPLL				1
+#define PLL_LPLL				2
+#define PLL_AUPLL				3
+#define PLL_CPLL				4
+#define PLL_GPLL				5
+#define PLL_VPLL				6
+#define ARMCLK_L0				7
+#define ARMCLK_L1				8
+#define ARMCLK_B				9
+
+#define CLK_CPLL_DIV20				10
+#define CLK_CPLL_DIV10				11
+#define CLK_GPLL_DIV8				12
+#define CLK_GPLL_DIV6				13
+#define CLK_CPLL_DIV4				14
+#define CLK_GPLL_DIV4				15
+#define CLK_GPLL_DIV3				16
+#define CLK_CPLL_DIV2				17
+#define CLK_GPLL_DIV2				18
+#define CLK_DDRPHY_TOP_SRC			19
+#define PCLK_TOP_ROOT				20
+#define ACLK_TOP				21
+#define ACLK_TOP_MID				22
+#define ACLK_SECURE_HIGH			23
+#define CLK_BPLL_DIV				24
+#define CLK_AUDIO_FRAC_0			25
+#define CLK_AUDIO_FRAC_1			26
+#define CLK_AUDIO_FRAC_2			27
+#define CLK_AUDIO_FRAC_3			28
+#define CLK_AUDIO_FRAC_0_SRC			29
+#define CLK_AUDIO_FRAC_1_SRC			30
+#define CLK_AUDIO_FRAC_2_SRC			31
+#define CLK_AUDIO_FRAC_3_SRC			32
+#define HCLK_TOP				33
+#define CLK_UART_FRAC_0				34
+#define CLK_UART_FRAC_1				35
+#define CLK_UART_FRAC_2				36
+#define CLK_UART_FRAC_0_SRC			37
+#define CLK_UART_FRAC_1_SRC			38
+#define CLK_UART_FRAC_2_SRC			39
+
+#define CLK_UART1_SRC_TOP			40
+#define CLK_AUDIO_INT_0				41
+#define CLK_AUDIO_INT_1				42
+#define CLK_AUDIO_INT_2				43
+#define CLK_PDM0_SRC_TOP			44
+#define CLK_GMAC0_125M_SRC			45
+#define CLK_GMAC1_125M_SRC			46
+#define MCLK_ASRC0_SRC_0			47
+#define MCLK_ASRC1_SRC_1			48
+#define REF_CLK0_OUT_PLL			49
+#define REF_CLK1_OUT_PLL			50
+#define REF_CLK2_OUT_PLL			51
+#define REF_PULSE_CLK_AUDIO_FRAC_0		52
+#define REF_PULSE_CLK_AUDIO_FRAC_1		53
+#define REF_PULSE_CLK_AUDIO_FRAC_2		54
+#define REF_PULSE_FRACDIV_3			55
+#define REF_PULSE_AUPLL				56
+#define CLK_SAI1_MCLKOUT			57
+#define CLK_SAI2_MCLKOUT			58
+#define CLK_SAI3_MCLKOUT			59
+#define CLK_SAI0_MCLKOUT			60
+#define REFCLKO25M_GMAC0_OUT			61
+#define REFCLKO25M_GMAC1_OUT			62
+#define CLK_CIFOUT_OUT				63
+#define CLK_GMAC0_RMII_CRU			64
+#define CLK_GMAC1_RMII_CRU			65
+#define CLK_OTPC_AUTO_RD_G			66
+#define CAM_CLK0_OUT_IOUT			67
+#define CAM_CLK1_OUT_IOUT			68
+#define CAM_CLK2_OUT_IOUT			69
+#define MCLK_PDM0_SRC_TOP			70
+#define HCLK_AUDIO_ROOT				71
+#define HCLK_ASRC_2CH_0				72
+#define HCLK_ASRC_2CH_1				73
+#define CLK_ASRC_2CH_0				74
+#define CLK_ASRC_2CH_1				75
+#define MCLK_SAI0				76
+#define HCLK_SAI0				77
+#define HCLK_SPDIF_RX0				78
+#define MCLK_SPDIF_RX0				79
+#define MCLK_SAI1				80
+#define HCLK_SAI1				81
+#define MCLK_SAI2				82
+#define HCLK_SAI2				83
+#define MCLK_SAI3				84
+#define HCLK_SAI3				85
+#define LRCK_ASRC_2CH0_SRC			86
+#define LRCK_ASRC_2CH0_DST			87
+#define LRCK_ASRC_2CH1_SRC			88
+#define LRCK_ASRC_2CH1_DST			89
+#define HCLK_ACDCDIG_DSM			90
+#define MCLK_ACDCDIG_DSM			91
+#define PCLK_AUDIO_ROOT				92
+#define HCLK_SPDIF_TX0				93
+#define MCLK_SPDIF_TX0				94
+#define HCLK_SPDIF_TX1				95
+#define MCLK_SPDIF_TX1				96
+#define ASRC_REF_PULSE				97
+#define HCLK_BUS_ROOT				98
+#define PCLK_BUS_ROOT				99
+#define ACLK_BUS_ROOT				100
+#define HCLK_CAN0				101
+#define CLK_CAN0				102
+#define HCLK_CAN1				103
+#define CLK_CAN1				104
+#define HCLK_CAN2				105
+#define CLK_CAN2				106
+#define HCLK_CAN3				107
+#define CLK_CAN3				108
+#define ACLK_DECOM_ROOT				109
+#define AUPLL_REF				110
+#define PCLK_I2C1				111
+#define PCLK_I2C2				112
+#define PCLK_I2C3				113
+#define PCLK_I2C4				114
+#define PCLK_I2C5				115
+#define PCLK_I2C6				116
+#define PCLK_I2C7				117
+#define PCLK_I2C8				118
+#define PCLK_I2C9				119
+#define PCLK_WDT_BUSMCU				120
+#define TCLK_WDT_BUSMCU				121
+#define ACLK_GIC				122
+#define CLK_I2C1				123
+#define CLK_I2C2				124
+#define CLK_I2C3				125
+#define CLK_I2C4				126
+#define CLK_I2C5				127
+#define CLK_I2C6				128
+#define CLK_I2C7				129
+#define CLK_I2C8				130
+#define CLK_I2C9				131
+#define PCLK_SARADC				132
+#define CLK_SARADC				133
+#define PCLK_TSADC				134
+#define CLK_TSADC				135
+#define PCLK_UART0				136
+#define PCLK_UART2				137
+#define PCLK_UART3				138
+#define PCLK_UART4				139
+#define PCLK_UART5				140
+#define PCLK_UART6				141
+#define PCLK_UART7				142
+#define PCLK_UART8				143
+#define PCLK_UART9				144
+#define PCLK_UART10				145
+#define PCLK_UART11				146
+#define SCLK_UART0				147
+#define SCLK_UART2				148
+#define SCLK_UART3				149
+#define SCLK_UART4				150
+#define SCLK_UART5				151
+#define SCLK_UART6				152
+#define SCLK_UART7				153
+#define SCLK_UART8				154
+#define SCLK_UART9				155
+#define SCLK_UART10				156
+#define SCLK_UART11				157
+#define PCLK_SPI0				158
+#define PCLK_SPI1				159
+#define PCLK_SPI2				160
+#define PCLK_SPI3				161
+#define PCLK_SPI4				162
+#define CLK_SPI0				163
+#define CLK_SPI1				164
+#define CLK_SPI2				165
+#define CLK_SPI3				166
+#define CLK_SPI4				167
+#define PCLK_WDT0				168
+#define TCLK_WDT0				169
+#define PCLK_PWM1				170
+#define CLK_PWM1				171
+#define CLK_OSC_PWM1				172
+#define CLK_RC_PWM1				173
+#define CLK_FREQ_PWM1				174
+#define CLK_COUNTER_PWM1			175
+#define PCLK_PWM2				176
+#define CLK_PWM2				177
+#define CLK_RC_PWM2				178
+#define CLK_OSC_PWM2				179
+#define SAI_SCLKIN_FREQ				180
+#define SAI_SCLKIN_COUNTER			181
+#define PCLK_BUSTIMER0				182
+#define PCLK_BUSTIMER1				183
+#define CLK_TIMER0_ROOT				184
+#define CLK_TIMER0				185
+#define CLK_TIMER1				186
+#define CLK_TIMER2				187
+#define CLK_TIMER3				188
+#define CLK_TIMER4				189
+#define CLK_TIMER5				190
+#define PCLK_MAILBOX0				191
+#define PCLK_GPIO1				192
+#define DBCLK_GPIO1				193
+#define PCLK_GPIO2				194
+#define DBCLK_GPIO2				195
+#define PCLK_GPIO3				196
+#define DBCLK_GPIO3				197
+#define PCLK_GPIO4				198
+#define DBCLK_GPIO4				199
+#define ACLK_DECOM				200
+#define PCLK_DECOM				201
+#define DCLK_DECOM				202
+#define CLK_TIMER1_ROOT				203
+#define CLK_TIMER6				204
+#define CLK_TIMER7				205
+#define CLK_TIMER8				206
+#define CLK_TIMER9				207
+#define CLK_TIMER10				208
+#define CLK_TIMER11				209
+#define ACLK_RKDMA0				210
+#define PCLK_RKDMA0				211
+#define ACLK_RKDMA1				212
+#define PCLK_RKDMA1				213
+#define ACLK_RKDMA2				214
+#define PCLK_RKDMA2				215
+#define ACLK_RKDMA3				216
+#define PCLK_RKDMA3				217
+#define PCLK_SPINLOCK				218
+#define CLK_I3C					219
+#define HCLK_I3C				220
+#define CLK_BUSMCU_ROOT				221
+#define CLK_BUSMCU_CORE_AON			222
+#define CLK_MTIME_TOGGLE_A			223
+#define CLK_DBG_TOGGLE_A			224
+#define CLK_MCU_AXI_INTEGRITY			225
+#define PCLK_PMU2				226
+#define CLK_HDMITXHPD				227
+#define PCLK_APB2ASB_HDMITX			228
+#define SCLK_APB2ASB_HDMITX			229
+#define PCLK_APB2ASB_MIPICSI			230
+#define SCLK_APB2ASB_MIPICSI			231
+#define PCLK_APB2ASB_VCCIO0_3			232
+#define SCLK_APB2ASB_VCCIO0_3			233
+#define PCLK_APB2ASB_VCCIO1_2_4			234
+#define SCLK_APB2ASB_VCCIO1_2_4			235
+#define PCLK_APB2ASB_VCCIO5_6			236
+#define SCLK_APB2ASB_VCCIO5_6			237
+#define PCLK_DDR_ROOT				238
+#define ACLK_DDR_ROOT				239
+#define LCLK_DDRSCH_BIU				240
+#define CLK_DDR_TIMER_ROOT			241
+#define CLK_DDR_TIMER0				242
+#define CLK_DDR_TIMER1				243
+#define TCLK_DDR_WDT				244
+#define PCLK_WDT				245
+#define PCLK_TIMER				246
+#define CLK_DDRMCU_ROOT				247
+#define CLK_DDRMCU_CORE_AON			248
+#define CLK_MTIME_TOGGLE_A_DDR			249
+#define CLK_DBG_TOGGLE_A_DDR			250
+#define ACLK_RKNN_ROOT				251
+#define ACLK_RKNN_ROOT_SRC			252
+#define ACLK_RKNN				253
+#define PCLK_RKNN_ROOT				254
+#define CLK_24M_RKNN				255
+#define CLK_NPUTIMER_ROOT			256
+#define CLK_NPUTIMER0				257
+#define CLK_NPUTIMER1				258
+#define PCLK_NPU_TIMER				259
+#define PCLK_NPU_WDT				260
+#define TCLK_NPU_WDT				261
+#define PCLK_PHP0_ROOT				262
+#define ACLK_PHP0_ROOT				263
+#define PCLK_PCIE1				264
+#define CLK_PCIE1_AUX				265
+#define ACLK_PCIE1_MSTR				266
+#define ACLK_PCIE1_SLV				267
+#define ACLK_PCIE1_DBI				268
+#define PCLK_PCIE0				269
+#define CLK_PCIE0_AUX				270
+#define ACLK_PCIE0_MSTR				271
+#define ACLK_PCIE0_SLV				272
+#define ACLK_PCIE0_DBI				273
+#define ACLK_USB3OTG1				274
+#define CLK_REF_USB3OTG1			275
+#define CLK_SUSPEND_USB3OTG1			276
+#define ACLK_GMAC0				277
+#define PCLK_GMAC0				278
+#define ACLK_UFS_ROOT				279
+#define ACLK_USB3OTG0				280
+#define CLK_REF_USB3OTG0			281
+#define CLK_SUSPEND_USB3OTG0			282
+#define ACLK_UFS_SYS				283
+#define CLK_GMAC0_PTP_REF_PRE			284
+#define CLK_GMAC0_PTP_REF_SRC			285
+#define CLK_RXOOB0				286
+#define CLK_PMALIVE0				287
+#define ACLK_SATA0				288
+#define CLK_RXOOB1				289
+#define CLK_PMALIVE1				290
+#define ACLK_SATA1				291
+#define CLK_EEE_XPCS				292
+#define PCLK_XPCS				293
+#define CLK_USB3OTG1_PIPE_PCLK			294
+#define CLK_USB3OTG1_UTMI			295
+#define CLK_USB3OTG0_PIPE_PCLK			296
+#define CLK_USB3OTG0_UTMI			297
+#define HCLK_NVM0_ROOT				298
+#define ACLK_NVM0_ROOT				299
+#define PCLK_NVM0_ROOT				300
+#define CCLK_SRC_EMMC				301
+#define HCLK_EMMC				302
+#define ACLK_EMMC				303
+#define BCLK_EMMC				304
+#define TCLK_EMMC				305
+#define CLK_GMAC1_PTP_REF_SRC			306
+#define CLK_GMAC1_PTP_REF			307
+#define ACLK_GMAC1				308
+#define PCLK_GMAC1				309
+#define SCLK_FSPI0_X2				310
+#define HCLK_FSPI0				311
+#define CCLK_SRC_SDMMC1				312
+#define HCLK_SDMMC1				313
+#define ACLK_DSMC_ROOT				314
+#define ACLK_DSMC				315
+#define HCLK_DSMC_ROOT				316
+#define HCLK_DSMC				317
+#define PCLK_DSMC_ROOT				318
+#define PCLK_DSMC				319
+#define CLK_DSMC_SYS				320
+#define HCLK_NVM1_ROOT				321
+#define PCLK_NVM1_ROOT				322
+#define CCLK_SRC_SDMMC0				323
+#define HCLK_SDMMC0				324
+#define SCLK_FSPI1_X2				325
+#define HCLK_FSPI1				326
+#define PCLK_PHPSUBSYS_ROOT			327
+#define PCLK_PCIE2_COMBOPHY0			328
+#define PCLK_PCIE2_COMBOPHY1			329
+#define PCLK_MPHY				330
+#define CLK_32K_USB2DEBUG			331
+#define PCLK_PCIEPHY2				332
+#define SCLK_APB2ASB_USBMPHY_PHPPHY		333
+#define PCLK_APB2ASB_USBMPHY_PHPPHY		334
+#define CLK_CPLL_DIV10_PHPPHY			335
+#define CLK_PHPPHY_REF				336
+#define CLK_PCIE_100M_SRC			337
+#define CLK_PCIE_100M_NDUTY_SRC			338
+#define CLK_REF_PCIEPHY2			339
+#define CLK_REF_PCIE0_INNER_PHY			340
+#define CLK_REF_PCIE1_INNER_PHY			341
+#define CLK_REF_MPHY_26M			342
+#define REF_CLK_FROM_PPLL			343
+#define HCLK_RKVDEC_ROOT			344
+#define HCLK_RKVDEC				345
+#define ACLK_RKVDEC_ROOT			346
+#define CLK_RKVDEC_HEVC_CA			347
+#define CLK_RKVDEC_CORE				348
+#define PCLK_VDEC_ROOT				349
+#define PCLK_VOSUBSYS_ROOT			350
+#define PCLK_APB2ASB_MIPI_HDMI_SUBVO		351
+#define SCLK_APB2ASB_MIPI_HDMI_SUBVO		352
+#define PCLK_APB2ASB_VCCIO0_3_SUBVO		353
+#define SCLK_APB2ASB_VCCIO0_3_SUBVO		354
+#define PCLK_HDPTXPHY				355
+#define PCLK_MIPI_DPHY0				356
+#define CLK_VOSUBSYS_REF			357
+#define PCLK_IOC_SUBVO				358
+#define PCLK_VISUBSYS_ROOT			359
+#define PCLK_APB2ASB_VCCIO1_2_4_SUBVI		360
+#define SCLK_APB2ASB_VCCIO1_2_4_SUBVI		361
+#define PCLK_APB2ASB_CSIPHY_SUBVI		362
+#define SCLK_APB2ASB_CSIPHY_SUBVI		363
+#define PCLK_CSIPHY0				364
+#define PCLK_CSIPHY1				365
+#define PCLK_IOC_SUBVI				366
+#define CLK_SDMMC_SWITCH_24M			367
+#define PCLK_DSMCSUBSYS_ROOT			368
+#define PCLK_APB2ASB_VCCIO5_6_SUBDSMC		369
+#define SCLK_APB2ASB_VCCIO5_6_SUBDSMC		370
+#define ACLK_IMG_ROOT				371
+#define ACLK_IMG_MID_ROOT			372
+#define HCLK_IMG_ROOT				373
+#define ACLK_JPEG_ROOT				374
+#define ACLK_IMG_LOW_ROOT			375
+#define PCLK_IMG_ROOT				376
+#define HCLK_RGA2E_0				377
+#define ACLK_RGA2E_0				378
+#define CLK_CORE_RGA2E_0			379
+#define ACLK_JPEG				380
+#define HCLK_JPEG				381
+#define HCLK_VDPP				382
+#define ACLK_VDPP				383
+#define CLK_CORE_VDPP				384
+#define DCLK_EBC_SRC_TOP			385
+#define DCLK_EBC_INT_SRC			386
+#define DCLK_EBC_FRAC_SRC			387
+#define HCLK_EBC				388
+#define ACLK_EBC				389
+#define DCLK_EBC				390
+#define HCLK_RKVENC_ROOT			391
+#define ACLK_RKVENC_ROOT			392
+#define HCLK_RKVENC				393
+#define ACLK_RKVENC				394
+#define CLK_RKVENC_CORE				395
+#define ACLK_VI_ROOT				396
+#define HCLK_VI_ROOT				397
+#define PCLK_VI_ROOT				398
+#define DCLK_VICAP				399
+#define ACLK_VICAP				400
+#define HCLK_VICAP				401
+#define CLK_ISP_CORE				402
+#define CLK_ISP_CORE_MARVIN			403
+#define CLK_ISP_CORE_VICAP			404
+#define ACLK_ISP				405
+#define HCLK_ISP				406
+#define ACLK_VPSS				407
+#define HCLK_VPSS				408
+#define CLK_CORE_VPSS				409
+#define PCLK_VI_GRF				410
+#define PCLK_CSI_HOST_0				411
+#define PCLK_CSI_HOST_1				412
+#define PCLK_CSI_HOST_2				413
+#define PCLK_CSI_HOST_3				414
+#define DCLK_VICAP_CSIHOST0			415
+#define DCLK_VICAP_CSIHOST1			416
+#define DCLK_VICAP_CSIHOST2			417
+#define DCLK_VICAP_CSIHOST3			418
+#define ACLK_VI_ROOT_INTER			419
+#define ACLK_VOP_ROOT				420
+#define HCLK_VOP_ROOT				421
+#define PCLK_VOP_ROOT				422
+#define HCLK_VOP				423
+#define ACLK_VOP				424
+#define DCLK_VP0_SRC				425
+#define DCLK_VP1_SRC				426
+#define DCLK_VP0				427
+#define DCLK_VP1				428
+#define CLK_EBC_VOP_DCLK2DSIHOST_0		429
+#define PCLK_DSIHOST0				430
+#define ACLK_VO_ROOT				431
+#define HCLK_VO_ROOT				432
+#define PCLK_VO_ROOT				433
+#define PCLK_HDCP0_TRNG_NS			434
+#define ACLK_HDCP0				435
+#define HCLK_HDCP0				436
+#define PCLK_HDCP0				437
+#define CLK_TRNG0_SKP				438
+#define PCLK_HDMITX0				439
+#define CLK_HDMITX0_EARC			440
+#define CLK_HDMITX0_REF				441
+#define CLK_EXTREF_TIMEOUT_VO			442
+#define PCLK_EDP0				443
+#define CLK_EDP0_24M				444
+#define CLK_EDP0_200M				445
+#define MCLK_SAI4_SRC				446
+#define MCLK_SAI4				447
+#define HCLK_SAI4				448
+#define MCLK_SAI5_SRC				449
+#define MCLK_SAI5				450
+#define HCLK_SAI5				451
+#define HCLK_SPDIF_TX2				452
+#define MCLK_SPDIF_TX2_SRC			453
+#define MCLK_SPDIF_TX2				454
+#define HCLK_SPDIF_RX1				455
+#define MCLK_SPDIF_RX1				456
+#define CLK_EBC_VOP_DCLK2HDMITX			457
+#define CLK_EBC_VOP_DCLK2EDP			458
+#define CLK_EBC_VOP_DCLK_INTER			459
+#define CLK_SAI4_MCLKOUT			460
+#define CLK_GPU_SRC				461
+#define CLK_GPU					462
+#define CLK_GPU_COREGROUP			463
+#define CLK_GPU_STACKS				464
+#define PCLK_GPU_ROOT				465
+#define ACLK_CENTER_ROOT			466
+#define ACLK_CENTER_LOW_ROOT			467
+#define HCLK_CENTER_ROOT			468
+#define PCLK_CENTER_ROOT			469
+#define ACLK_DMA2DDR				470
+#define ACLK_DDR_SHAREMEM			471
+#define PCLK_DMA2DDR				472
+#define CLK_LINK_EDP0				473
+#define CLK_CHTXD_EDP0				474
+#define CLK_DIV2_EDP0				475
+#define CLK_VOP2HDCP0_PIX_CLK			476
+#define CLK_LINKSYM_HDMITXPHY0			477
+#define CLK_XGXS_TXDIV20			478
+#define CLK_XGXS_TX				479
+#define CLK_XGXS_RXDIV20			480
+#define CLK_XGXS_RX				481
+#define HCLK_SECURE_NS_ROOT			482
+#define PCLK_SECURE_NS_ROOT			483
+#define HCLK_CRYPTO_NS				484
+#define HCLK_TRNG_NS				485
+#define PCLK_OTPC_NS				486
+#define CLK_OTPC_NS				487
+#define CLK_REF_OSC_MPHY			488
+#define CLK_REF_UFS_CLKOUT			489
+#define HCLK_PMU1_ROOT				490
+#define HCLK_PMU_CM0_ROOT			491
+#define PCLK_APB2ASB_PMU1			492
+#define SCLK_APB2ASB_PMU1			493
+#define CLK_PMUMCU_CORE_AON			494
+#define CLK_MTIME_TOGGLE_A_PMU			495
+#define PCLK_PMU1_ROOT				496
+#define PCLK_PMU1				497
+#define CLK_PMU1				498
+#define PCLK_PMU1WDT				499
+#define TCLK_PMU1WDT				500
+#define PCLK_PMUTIMER				501
+#define CLK_PMUTIMER_ROOT			502
+#define CLK_PMUTIMER0				503
+#define CLK_PMUTIMER1				504
+#define PCLK_PWM0				505
+#define CLK_PWM0				506
+#define CLK_PWM0_OSC				507
+#define PCLK_PMUPHY_ROOT			508
+#define PCLK_I2C0				509
+#define CLK_I2C0				510
+#define SCLK_UART1				511
+#define PCLK_UART1				512
+#define CLK_PWM0_RC				513
+#define CLK_PDM0				514
+#define HCLK_PDM0				515
+#define MCLK_PDM0				516
+#define HCLK_VAD				517
+#define CLK_PDM0_OUT				518
+#define PCLK_PMU0_ROOT				519
+#define PCLK_PMU0				520
+#define PCLK_GPIO0				521
+#define DBCLK_GPIO0				522
+#define SCLK_APB2ASB_SRC			523
+#define CLK_32K					524
+#define ACLK_CRYPTO_NS				525
+#define CLK_PKA_CRYPTO_NS			526
+#define PCLK_DDR_MON				527
+
+/* Secure clocks */
+#define ACLK_CCI				600
+#define SCLK_DDR				601
+#define CLK_STIMER0_ROOT			602
+#define PCLK_SECURE_S				603
+#define HCLK_SECURE_S				604
+#define ACLK_SECURE_S				605
+#define CLK_PKA_CRYPTO_S			606
+#define PCLK_KLAD				607
+#define HCLK_CRYPTO_S				608
+#define HCLK_KLAD				609
+#define ACLK_CRYPTO_S				610
+#define PCLK_OTPC_S				611
+#define CLK_OTPC_S				612
+#define PCLK_WDT_S				613
+#define TCLK_WDT_S				614
+#define HCLK_TRNG_S				615
+
+#define CLK_NR_CLKS				(HCLK_TRNG_S + 1)
+#endif
diff --git a/include/dt-bindings/reset/rockchip,rk3572-cru.h b/include/dt-bindings/reset/rockchip,rk3572-cru.h
new file mode 100644
index 000000000000..a78947532681
--- /dev/null
+++ b/include/dt-bindings/reset/rockchip,rk3572-cru.h
@@ -0,0 +1,713 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR MIT) */
+/*
+ * Copyright (c) 2025 Rockchip Electronics Co., Ltd.
+ * Author: Elaine Zhang <zhangqing@rock-chips.com>
+ */
+
+#ifndef _DT_BINDINGS_RESET_ROCKCHIP_RK3572_H
+#define _DT_BINDINGS_RESET_ROCKCHIP_RK3572_H
+
+/* CRU-->SOFTRST_CON01 */
+#define SRST_ARESETN_TOP_BIU                     0
+#define SRST_PRESETN_TOP_BIU                     1
+#define SRST_ARESETN_TOP_MID_BIU                 2
+#define SRST_HRESETN_TOP_BIU                     3
+
+/* CRU-->SOFTRST_CON02 */
+#define SRST_HRESETN_TOP_FW                      4
+
+/* CRU-->SOFTRST_CON06 */
+#define SRST_RESETN_TEST_JUDGE_24M_TOP           5
+#define SRST_RESETN_TEST_JUDGE_TOP               6
+
+/* CRU-->SOFTRST_CON07 */
+#define SRST_HRESETN_AUDIO_BIU                   7
+#define SRST_HRESETN_ASRC_2CH_0                  8
+#define SRST_HRESETN_ASRC_2CH_1                  9
+#define SRST_RESETN_ASRC_2CH_0                   10
+#define SRST_RESETN_ASRC_2CH_1                   11
+#define SRST_MRESETN_SAI0                        12
+#define SRST_HRESETN_SAI0                        13
+#define SRST_HRESETN_SPDIF_RX0                   14
+#define SRST_MRESETN_SPDIF_RX0                   15
+
+/* CRU-->SOFTRST_CON08 */
+#define SRST_MRESETN_SAI1                        16
+#define SRST_HRESETN_SAI1                        17
+#define SRST_MRESETN_SAI2                        18
+#define SRST_HRESETN_SAI2                        19
+#define SRST_MRESETN_SAI3                        20
+#define SRST_HRESETN_SAI3                        21
+#define SRST_HRESETN_ACDCDIG_DSM                 22
+
+/* CRU-->SOFTRST_CON09 */
+#define SRST_MRESETN_ACDCDIG_DSM                 23
+#define SRST_PRESETN_AUDIO_BIU                   24
+#define SRST_PRESETN_AUDIO_GRF                   25
+#define SRST_HRESETN_SPDIF_TX0                   26
+#define SRST_MRESETN_SPDIF_TX0                   27
+#define SRST_HRESETN_SPDIF_TX1                   28
+#define SRST_MRESETN_SPDIF_TX1                   29
+#define SRST_RESETN_TEST_JUDGE_24M_AUDIO         30
+#define SRST_RESETN_TEST_JUDGE_AUDIO             31
+
+/* CRU-->SOFTRST_CON11 */
+#define SRST_ARESETN_BUS_BIU                     32
+#define SRST_ARESETN_BUS_FW                      33
+#define SRST_PRESETN_BUS_BIU                     34
+#define SRST_PRESETN_CRU                         35
+#define SRST_HRESETN_CAN0                        36
+#define SRST_RESETN_CAN0                         37
+#define SRST_HRESETN_CAN1                        38
+#define SRST_RESETN_CAN1                         39
+#define SRST_HRESETN_CAN2                        40
+#define SRST_RESETN_CAN2                         41
+#define SRST_HRESETN_CAN3                        42
+#define SRST_RESETN_CAN3                         43
+
+/* CRU-->SOFTRST_CON12 */
+#define SRST_ARESETN_DECOM_BIU                   44
+#define SRST_HRESETN_BUS_BIU                     45
+#define SRST_RESETN_KEY_SHIFT                    46
+#define SRST_PRESETN_I2C1                        47
+#define SRST_PRESETN_I2C2                        48
+#define SRST_PRESETN_I2C3                        49
+#define SRST_PRESETN_I2C4                        50
+#define SRST_PRESETN_I2C5                        51
+#define SRST_PRESETN_I2C6                        52
+#define SRST_PRESETN_I2C7                        53
+#define SRST_PRESETN_I2C8                        54
+#define SRST_PRESETN_I2C9                        55
+#define SRST_PRESETN_WDT_BUSMCU                  56
+#define SRST_TRESETN_WDT_BUSMCU                  57
+
+/* CRU-->SOFTRST_CON13 */
+#define SRST_ARESETN_GIC                         58
+#define SRST_RESETN_I2C1                         59
+#define SRST_RESETN_I2C2                         60
+#define SRST_RESETN_I2C3                         61
+#define SRST_RESETN_I2C4                         62
+#define SRST_RESETN_I2C5                         63
+#define SRST_RESETN_I2C6                         64
+#define SRST_RESETN_I2C7                         65
+#define SRST_RESETN_I2C8                         66
+#define SRST_RESETN_I2C9                         67
+#define SRST_PRESETN_SARADC                      68
+
+/* CRU-->SOFTRST_CON14 */
+#define SRST_RESETN_SARADC                       69
+#define SRST_RESETN_SARADC_32K                   70
+#define SRST_PRESETN_TSADC                       71
+#define SRST_RESETN_TSADC                        72
+#define SRST_PRESETN_UART0                       73
+#define SRST_PRESETN_UART2                       74
+#define SRST_PRESETN_UART3                       75
+#define SRST_PRESETN_UART4                       76
+#define SRST_PRESETN_UART5                       77
+#define SRST_PRESETN_UART6                       78
+#define SRST_PRESETN_UART7                       79
+#define SRST_PRESETN_UART8                       80
+#define SRST_PRESETN_UART9                       81
+#define SRST_PRESETN_UART10                      82
+#define SRST_PRESETN_UART11                      83
+#define SRST_SRESETN_UART0                       84
+
+/* CRU-->SOFTRST_CON15 */
+#define SRST_SRESETN_UART2                       85
+#define SRST_SRESETN_UART3                       86
+#define SRST_SRESETN_UART4                       87
+#define SRST_SRESETN_UART5                       88
+#define SRST_SRESETN_UART6                       89
+#define SRST_SRESETN_UART7                       90
+
+/* CRU-->SOFTRST_CON16 */
+#define SRST_SRESETN_UART8                       91
+#define SRST_SRESETN_UART9                       92
+#define SRST_SRESETN_UART10                      93
+#define SRST_SRESETN_UART11                      94
+#define SRST_PRESETN_SPI0                        95
+#define SRST_PRESETN_SPI1                        96
+#define SRST_PRESETN_SPI2                        97
+#define SRST_PRESETN_SPI3                        98
+#define SRST_PRESETN_SPI4                        99
+#define SRST_RESETN_SPI0                         100
+#define SRST_RESETN_SPI1                         101
+#define SRST_RESETN_SPI2                         102
+#define SRST_RESETN_SPI3                         103
+
+/* CRU-->SOFTRST_CON17 */
+#define SRST_RESETN_SPI4                         104
+#define SRST_PRESETN_WDT0                        105
+#define SRST_TRESETN_WDT0                        106
+#define SRST_PRESETN_SYS_GRF                     107
+#define SRST_PRESETN_PWM1                        108
+#define SRST_RESETN_PWM1                         109
+#define SRST_PRESETN_PWM2                        110
+#define SRST_RESETN_PWM2                         111
+
+/* CRU-->SOFTRST_CON18 */
+#define SRST_PRESETN_BUSTIMER0                   112
+#define SRST_PRESETN_BUSTIMER1                   113
+#define SRST_RESETN_TIMER0                       114
+#define SRST_RESETN_TIMER1                       115
+#define SRST_RESETN_TIMER2                       116
+#define SRST_RESETN_TIMER3                       117
+#define SRST_RESETN_TIMER4                       118
+#define SRST_RESETN_TIMER5                       119
+#define SRST_PRESETN_MAILBOX0                    120
+
+/* CRU-->SOFTRST_CON19 */
+#define SRST_PRESETN_GPIO1                       121
+#define SRST_DBRESETN_GPIO1                      122
+#define SRST_PRESETN_GPIO2                       123
+#define SRST_DBRESETN_GPIO2                      124
+#define SRST_PRESETN_GPIO3                       125
+#define SRST_DBRESETN_GPIO3                      126
+#define SRST_PRESETN_GPIO4                       127
+#define SRST_DBRESETN_GPIO4                      128
+#define SRST_ARESETN_DECOM                       129
+#define SRST_PRESETN_DECOM                       130
+#define SRST_DRESETN_DECOM                       131
+#define SRST_RESETN_TIMER6                       132
+#define SRST_RESETN_TIMER7                       133
+#define SRST_RESETN_TIMER8                       134
+#define SRST_RESETN_TIMER9                       135
+
+/* CRU-->SOFTRST_CON20 */
+#define SRST_RESETN_TIMER10                      136
+#define SRST_RESETN_TIMER11                      137
+#define SRST_ARESETN_RKDMA0                      138
+#define SRST_PRESETN_RKDMA0                      139
+#define SRST_ARESETN_RKDMA1                      140
+#define SRST_PRESETN_RKDMA1                      141
+#define SRST_ARESETN_RKDMA2                      142
+#define SRST_PRESETN_RKDMA2                      143
+#define SRST_ARESETN_RKDMA3                      144
+#define SRST_PRESETN_RKDMA3                      145
+#define SRST_PRESETN_SPINLOCK                    146
+#define SRST_RESETN_REF_PVTPLL_BUS               147
+#define SRST_RESETN_I3C                          148
+#define SRST_HRESETN_I3C                         149
+
+/* CRU-->SOFTRST_CON21 */
+#define SRST_RESETN_BUSMCU_BIU                   150
+#define SRST_CORERESETN_N320                     151
+#define SRST_PORESETN_N320                       152
+#define SRST_RESETN_MCU_AXI_INTEGRITY            153
+#define SRST_PRESETN_INTMUX2PMU                  154
+#define SRST_PRESETN_INTMUX2DDR                  155
+#define SRST_PRESETN_PVTPLL_BUS                  156
+#define SRST_RESETN_HDMITXHPD                    157
+
+/* CRU-->SOFTRST_CON22 */
+#define SRST_PRESETN_APB2ASB_HDMITX              158
+#define SRST_SRESETN_APB2ASB_HDMITX              159
+#define SRST_PRESETN_APB2ASB_MIPICSI             160
+#define SRST_SRESETN_APB2ASB_MIPICSI             161
+#define SRST_PRESETN_APB2ASB_VCCIO0_3            162
+#define SRST_SRESETN_APB2ASB_VCCIO0_3            163
+#define SRST_PRESETN_APB2ASB_VCCIO1_2_4          164
+#define SRST_SRESETN_APB2ASB_VCCIO1_2_4          165
+#define SRST_PRESETN_APB2ASB_VCCIO5_6            166
+#define SRST_SRESETN_APB2ASB_VCCIO5_6            167
+#define SRST_RESETN_TEST_JUDGE_24M_BUS           168
+#define SRST_RESETN_TEST_JUDGE_BUS               169
+
+/* CRU-->SOFTRST_CON23 */
+#define SRST_PRESETN_DDR_MON                     170
+#define SRST_PRESETN_DDR_BIU                     171
+#define SRST_PRESETN_DDR_UPCTL                   172
+#define SRST_TMRESETN_DDR_MON                    173
+#define SRST_ARESETN_DDR_BIU                     174
+#define SRST_PRESETN_DDR_BIU_FW                  175
+#define SRST_RESETN_DDR_MON                      176
+#define SRST_PRESETN_DDR_HWLP                    177
+
+/* CRU-->SOFTRST_CON24 */
+#define SRST_ARESETN_DDR_MSCH_BIU                178
+#define SRST_ARESETN_DDR_MSCH_FW                 179
+#define SRST_RESETN_DDR_SCRAMBLE                 180
+#define SRST_LRESETN_DDRSCH_BIU                  181
+
+/* CRU-->SOFTRST_CON25 */
+#define SRST_RESETN_DDR_TIMER0                   182
+#define SRST_RESETN_DDR_TIMER1                   183
+#define SRST_TRESETN_DDR_WDT                     184
+#define SRST_PRESETN_WDT                         185
+#define SRST_PRESETN_TIMER                       186
+#define SRST_PRESETN_DDR_GRF                     187
+
+/* CRU-->SOFTRST_CON26 */
+#define SRST_RESETN_DDR_UPCTL                    188
+#define SRST_ARESETN_DDR_UPCTL_0                 189
+#define SRST_ARESETN_DDR_UPCTL_1                 190
+#define SRST_ARESETN_DDR_UPCTL_2                 191
+#define SRST_ARESETN_DDR_UPCTL_3                 192
+#define SRST_ARESETN_DDR_UPCTL_4                 193
+#define SRST_ARESETN_DDR_UPCTL_5                 194
+
+/* CRU-->SOFTRST_CON27 */
+#define SRST_RESETN_DDRMCU_BIU                   195
+#define SRST_CORERESETN_N320_DDR                 196
+#define SRST_PORESETN_N320_DDR                   197
+#define SRST_RESETN_TEST_JUDGE_24M_DDR           198
+#define SRST_RESETN_TEST_JUDGE_DDR               199
+
+/* CRU-->SOFTRST_CON31 */
+#define SRST_ARESETN_RKNN                        200
+#define SRST_ARESETN_RKNN_RV                     201
+#define SRST_ARESETN_RKNN_BIU                    202
+#define SRST_ARESETN_RKNN_FW                     203
+#define SRST_PRESETN_RKNN_BIU                    204
+#define SRST_PRESETN_PVTPLL_NPU                  205
+#define SRST_RESETN_NPU_PVTPLL                   206
+#define SRST_RESETN_24M_RKNN                     207
+#define SRST_RESETN_NPUTIMER0                    208
+#define SRST_RESETN_NPUTIMER1                    209
+#define SRST_PRESETN_NPU_TIMER                   210
+
+/* CRU-->SOFTRST_CON32 */
+#define SRST_PRESETN_NPU_WDT                     211
+#define SRST_TRESETN_NPU_WDT                     212
+#define SRST_PRESETN_RKNN_GRF                    213
+#define SRST_RESETN_TEST_JUDGE_24M_NPU           214
+#define SRST_RESETN_TEST_JUDGE_NPU               215
+
+/* CRU-->SOFTRST_CON33 */
+#define SRST_PRESETN_PHP0_GRF                    216
+#define SRST_PRESETN_PHP0_BIU                    217
+#define SRST_ARESETN_PHP0_BIU                    218
+#define SRST_ARESETN_PHP0_FW                     219
+#define SRST_PRESETN_PCIE1                       220
+#define SRST_RESETN_PCIE1_POWER_UP               221
+#define SRST_RESETN_TEST_JUDGE_24M_PHP0          222
+#define SRST_RESETN_TEST_JUDGE_PHP0              223
+
+/* CRU-->SOFTRST_CON34 */
+#define SRST_PRESETN_PCIE0                       224
+#define SRST_RESETN_PCIE0_POWER_UP               225
+#define SRST_ARESETN_USB3OTG1                    226
+#define SRST_ARESETN_GMAC0                       227
+#define SRST_ARESETN_USB3OTG0                    228
+
+/* CRU-->SOFTRST_CON35 */
+#define SRST_ARESETN_UFS_BIU                     229
+#define SRST_ARESETN_UFS_SYS                     230
+#define SRST_ARESETN_UFS                         231
+#define SRST_PRESETN_UFS_GRF                     232
+
+/* CRU-->SOFTRST_CON37 */
+#define SRST_RESETN_RXOOB0                       233
+#define SRST_RESETN_PMALIVE0                     234
+#define SRST_ARESETN_SATA0                       235
+#define SRST_RESETN_RXOOB1                       236
+#define SRST_RESETN_PMALIVE1                     237
+#define SRST_ARESETN_SATA1                       238
+#define SRST_RESETN_XPCS_PWR_ON                  239
+#define SRST_RESETN_ASIC0                        240
+#define SRST_RESETN_ASIC1                        241
+
+/* CRU-->SOFTRST_CON42 */
+#define SRST_PRESETN_NVM0_GRF                    242
+#define SRST_PRESETN_NVM0_BIU                    243
+#define SRST_ARESETN_NVM0_BIU                    244
+#define SRST_HRESETN_NVM0_BIU                    245
+#define SRST_CRESETN_EMMC                        246
+#define SRST_HRESETN_EMMC                        247
+#define SRST_ARESETN_EMMC                        248
+#define SRST_BRESETN_EMMC                        249
+#define SRST_TRESETN_EMMC                        250
+#define SRST_ARESETN_GMAC1                       251
+
+/* CRU-->SOFTRST_CON43 */
+#define SRST_SRESETN_FSPI0                       252
+#define SRST_HRESETN_FSPI0                       253
+#define SRST_HRESETN_SDMMC1                      254
+#define SRST_RESETN_TEST_JUDGE_24M_NVM0          255
+#define SRST_RESETN_TEST_JUDGE_NVM0              256
+
+/* CRU-->SOFTRST_CON44 */
+#define SRST_ARESETN_DSMC_BIU                    257
+#define SRST_ARESETN_DSMC                        258
+#define SRST_HRESETN_DSMC_BIU                    259
+#define SRST_HRESETN_DSMC                        260
+#define SRST_PRESETN_DSMC_BIU                    261
+#define SRST_PRESETN_DSMC                        262
+#define SRST_RESETN_TEST_JUDGE_24M_DSMC          263
+#define SRST_RESETN_TEST_JUDGE_DSMC              264
+#define SRST_PRESETN_DSMC_GRF                    265
+
+/* CRU-->SOFTRST_CON45 */
+#define SRST_PRESETN_NVM1_GRF                    266
+#define SRST_PRESETN_NVM1_BIU                    267
+#define SRST_HRESETN_NVM1_BIU                    268
+#define SRST_HRESETN_SDMMC0                      269
+#define SRST_SRESETN_FSPI1                       270
+#define SRST_HRESETN_FSPI1                       271
+
+/* CRU-->SOFTRST_CON46 */
+#define SRST_RESETN_TEST_JUDGE_24M_NVM1          272
+#define SRST_RESETN_TEST_JUDGE_NVM1              273
+
+/* CRU-->SOFTRST_CON50 */
+#define SRST_HRESETN_RKVDEC                      274
+#define SRST_HRESETN_RKVDEC_BIU                  275
+#define SRST_ARESETN_RKVDEC_BIU                  276
+#define SRST_RESETN_RKVDEC_HEVC_CA               277
+#define SRST_RESETN_RKVDEC_CORE                  278
+#define SRST_RESETN_TEST_JUDGE_24M_VDEC          279
+#define SRST_RESETN_TEST_JUDGE_VDEC              280
+#define SRST_PRESETN_VDEC_BIU                    281
+#define SRST_PRESETN_VDEC_GRF                    282
+
+/* CRU-->SOFTRST_CON52 */
+#define SRST_PRESETN_APB2ASB_MIPI_HDMI_SUBVO     283
+#define SRST_SRESETN_APB2ASB_MIPI_HDMI_SUBVO     284
+#define SRST_PRESETN_APB2ASB_VCCIO0_3_SUBVO      285
+#define SRST_SRESETN_APB2ASB_VCCIO0_3_SUBVO      286
+#define SRST_PRESETN_HDPTXPHY                    287
+#define SRST_PRESETN_HDPTXPHY_GRF                288
+#define SRST_PRESETN_MIPI_DPHY0                  289
+
+/* CRU-->SOFTRST_CON53 */
+#define SRST_RESETN_HDPTX_INIT                   290
+#define SRST_RESETN_HDPTX_CMN                    291
+#define SRST_RESETN_HDPTX_LANE                   292
+#define SRST_PRESETN_IOC_SUBVO                   293
+#define SRST_RESETN_GMAC1_SUBVO_ASYNC            294
+#define SRST_RESETN_TEST_JUDGE_24M_SUBSYSVO      295
+#define SRST_RESETN_TEST_JUDGE_SUBSYSVO          296
+
+/* CRU-->SOFTRST_CON54 */
+#define SRST_PRESETN_APB2ASB_VCCIO1_2_4_SUBVI    297
+#define SRST_SRESETN_APB2ASB_VCCIO1_2_4_SUBVI    298
+#define SRST_PRESETN_APB2ASB_CSIPHY_SUBVI        299
+#define SRST_SRESETN_APB2ASB_CSIPHY_SUBVI        300
+#define SRST_PRESETN_CSIPHY0                     301
+#define SRST_PRESETN_CSIPHY0_GRF                 302
+#define SRST_PRESETN_CSIPHY1                     303
+#define SRST_PRESETN_CSIPHY1_GRF                 304
+#define SRST_PRESETN_IOC_SUBVI                   305
+#define SRST_RESETN_GMAC0_SUBVI_ASYNC            306
+#define SRST_SCAN_RESETN_CSIPHY0                 307
+#define SRST_SCAN_RESETN_CSIPHY1                 308
+#define SRST_RESETN_TEST_JUDGE_24M_SUBSYSVI      309
+#define SRST_RESETN_TEST_JUDGE_SUBSYSVI          310
+
+/* CRU-->SOFTRST_CON56 */
+#define SRST_PRESETN_APB2ASB_VCCIO5_6_SUBDSMC    311
+#define SRST_SRESETN_APB2ASB_VCCIO5_6_SUBDSMC    312
+#define SRST_PRESETN_VCCIO5_6                    313
+#define SRST_RESETN_GMAC1_ASYNC                  314
+
+/* CRU-->SOFTRST_CON57 */
+#define SRST_PRESETN_IMG_BIU                     315
+#define SRST_PRESETN_IMG_GRF                     316
+#define SRST_HRESETN_IMG_BIU                     317
+#define SRST_ARESETN_JPEG_BIU                    318
+#define SRST_RESETN_TEST_JUDGE_24M_IMG           319
+#define SRST_RESETN_TEST_JUDGE_IMG               320
+#define SRST_ARESETN_RGA_BIU                     321
+#define SRST_ARESETN_VDPP_BIU                    322
+#define SRST_ARESETN_EBC_BIU                     323
+
+/* CRU-->SOFTRST_CON58 */
+#define SRST_HRESETN_RGA2E_0                     324
+#define SRST_ARESETN_RGA2E_0                     325
+#define SRST_RESETN_CORE_RGA2E_0                 326
+#define SRST_ARESETN_JPEG                        327
+#define SRST_HRESETN_JPEG                        328
+#define SRST_HRESETN_VDPP                        329
+#define SRST_ARESETN_VDPP                        330
+#define SRST_RESETN_CORE_VDPP                    331
+#define SRST_HRESETN_EBC                         332
+#define SRST_ARESETN_EBC                         333
+#define SRST_DRESETN_EBC                         334
+
+/* CRU-->SOFTRST_CON60 */
+#define SRST_HRESETN_RKVENC_BIU                  335
+#define SRST_ARESETN_RKVENC_BIU                  336
+#define SRST_HRESETN_RKVENC                      337
+#define SRST_ARESETN_RKVENC                      338
+#define SRST_RESETN_RKVENC_CORE                  339
+#define SRST_RESETN_TEST_JUDGE_24M_VENC          340
+#define SRST_RESETN_TEST_JUDGE_VENC              341
+
+/* CRU-->SOFTRST_CON63 */
+#define SRST_ARESETN_VI_BIU                      342
+#define SRST_HRESETN_VI_BIU                      343
+#define SRST_PRESETN_VI_BIU                      344
+#define SRST_DRESETN_VICAP                       345
+#define SRST_ARESETN_VICAP                       346
+#define SRST_HRESETN_VICAP                       347
+#define SRST_RESETN_ISP                          348
+#define SRST_RESETN_ISP_VICAP                    349
+
+/* CRU-->SOFTRST_CON64 */
+#define SRST_RESETN_CORE_VPSS                    350
+#define SRST_PRESETN_VI_GRF                      351
+#define SRST_PRESETN_CSI_HOST_0                  352
+#define SRST_PRESETN_CSI_HOST_1                  353
+#define SRST_PRESETN_CSI_HOST_2                  354
+#define SRST_PRESETN_CSI_HOST_3                  355
+#define SRST_RESETN_TEST_JUDGE_24M_VI            356
+#define SRST_RESETN_TEST_JUDGE_VI                357
+
+/* CRU-->SOFTRST_CON72 */
+#define SRST_RESETN_CIFIN                        358
+
+/* CRU-->SOFTRST_CON74 */
+#define SRST_ARESETN_VOP_BIU                     359
+#define SRST_ARESETN_VOP_FW                      360
+#define SRST_HRESETN_VOP_BIU                     361
+#define SRST_PRESETN_VOP_BIU                     362
+#define SRST_HRESETN_VOP                         363
+#define SRST_ARESETN_VOP                         364
+#define SRST_DRESETN_VP0                         365
+
+/* CRU-->SOFTRST_CON75 */
+#define SRST_DRESETN_VP1                         366
+#define SRST_PRESETN_VOPGRF                      367
+#define SRST_RESETN_TEST_JUDGE_24M_VOP           368
+#define SRST_RESETN_TEST_JUDGE_VOP               369
+
+/* CRU-->SOFTRST_CON78 */
+#define SRST_PRESETN_DSIHOST0                    370
+#define SRST_HRESETN_VO_BIU                      371
+#define SRST_PRESETN_VO_BIU                      372
+#define SRST_ARESETN_HDCP0_BIU                   373
+#define SRST_PRESETN_VO_GRF                      374
+
+/* CRU-->SOFTRST_CON79 */
+#define SRST_PRESETN_HDCP0_TRNG_NS               375
+#define SRST_ARESETN_HDCP0                       376
+#define SRST_HRESETN_HDCP0                       377
+#define SRST_RESETN_HDCP0                        378
+#define SRST_PRESETN_HDMITX0                     379
+#define SRST_RESETN_HDMITX0_EARC                 380
+
+/* CRU-->SOFTRST_CON80 */
+#define SRST_RESETN_HDMITX0_REF                  381
+#define SRST_PRESETN_EDP0                        382
+#define SRST_RESETN_EDP0_24M                     383
+#define SRST_MRESETN_SAI4                        384
+#define SRST_HRESETN_SAI4                        385
+#define SRST_MRESETN_SAI5                        386
+#define SRST_HRESETN_SAI5                        387
+#define SRST_HRESETN_SPDIF_TX2                   388
+#define SRST_MRESETN_SPDIF_TX2                   389
+#define SRST_HRESETN_SPDIF_RX1                   390
+#define SRST_MRESETN_SPDIF_RX1                   391
+
+/* CRU-->SOFTRST_CON81 */
+#define SRST_RESETN_EBC_VOP_DCLK_VO              392
+
+/* CRU-->SOFTRST_CON82 */
+#define SRST_RESETN_TEST_JUDGE_24M_VO            393
+#define SRST_RESETN_TEST_JUDGE_VO                394
+
+/* CRU-->SOFTRST_CON84 */
+#define SRST_RESETN_GPU                          395
+#define SRST_SYSRESETN_GPU                       396
+#define SRST_PRESETN_GPU_BIU                     397
+#define SRST_PORESETN_GPU_JTAG                   398
+#define SRST_PRESETN_GPU_GRF                     399
+#define SRST_RESETN_GPU_PVTPLL                   400
+#define SRST_PRESETN_PVTPLL_GPU                  401
+#define SRST_ARESETN_SLV_GPU_BIU                 402
+
+/* CRU-->SOFTRST_CON85 */
+#define SRST_ARESETN_GPU_BIU                     403
+#define SRST_RESETN_TEST_JUDGE_24M_GPU           404
+#define SRST_RESETN_TEST_JUDGE_GPU               405
+
+/* CRU-->SOFTRST_CON86 */
+#define SRST_ARESETN_CENTER_BIU                  406
+#define SRST_ARESETN_CENTER_FW_DDR               407
+#define SRST_ARESETN_CENTER_FW_GPU               408
+#define SRST_ARESETN_DMA2DDR                     409
+#define SRST_ARESETN_DDR_SHAREMEM                410
+#define SRST_ARESETN_DDR_SHAREMEM_BIU            411
+#define SRST_ARESETN_DDR_SHAREMEM_FW             412
+#define SRST_HRESETN_CENTER_BIU                  413
+#define SRST_HRESETN_CENTER_FW                   414
+#define SRST_PRESETN_CENTER_GRF                  415
+#define SRST_PRESETN_DMA2DDR                     416
+
+/* CRU-->SOFTRST_CON87 */
+#define SRST_PRESETN_CENTER_BIU                  417
+#define SRST_RESETN_TEST_JUDGE_24M_CENTER        418
+#define SRST_RESETN_TEST_JUDGE_CENTER            419
+#define SRST_RESETN_LINKSYM_HDMITXPHY0           420
+
+/* PHPPHY_CRU-->SOFTRST_CON00 */
+#define SRST_PRESETN_PHPPHY_CRU                  422
+#define SRST_PRESETN_PCIE2_COMBOPHY0             423
+#define SRST_PRESETN_PCIE2_COMBOPHY0_GRF         424
+#define SRST_PRESETN_PCIE2_COMBOPHY1             425
+#define SRST_PRESETN_PCIE2_COMBOPHY1_GRF         426
+#define SRST_PRESETN_USBPHY_GRF_0                427
+#define SRST_PRESETN_USBPHY_GRF_1                428
+#define SRST_RESETN_MPHY_INIT                    429
+#define SRST_PRESETN_MPHY_GRF                    430
+#define SRST_PRESETN_VCCIO7_IOC                  431
+#define SRST_RESETN_USB2DEBUG                    432
+#define SRST_PRESETN_PCIEPHY2                    433
+#define SRST_PRESETN_PCIEPHY2_GRF                434
+
+/* PHPPHY_CRU-->SOFTRST_CON01 */
+#define SRST_SRESETN_APB2ASB_USBMPHY_PHPPHY      435
+#define SRST_PRESETN_APB2ASB_USBMPHY_PHPPHY      436
+#define SRST_RESETN_OTGPHY_0                     437
+#define SRST_RESETN_OTGPHY_1                     438
+#define SRST_RESETN_TEST_JUDGE_24M_PHPPHY        439
+#define SRST_RESETN_TEST_JUDGE_PHPPHY            440
+
+/* PHPPHY_CRU-->SOFTRST_CON02 */
+#define SRST_RESETN_PCIEPHY2                     441
+#define SRST_RESETN_PCIE0_PIPE_PHY               442
+#define SRST_RESETN_PCIE1_PIPE_PHY               443
+
+/* SECURE_CRU-->SOFTRST_CON00 */
+#define SRST_HRESETN_CRYPTO_NS                   444
+#define SRST_HRESETN_TRNG_NS                     445
+#define SRST_PRESETN_SECURE_NS_BIU               446
+#define SRST_ARESETN_SECURE_HIGH_BIU             447
+#define SRST_HRESETN_SECURE_NS_BIU               448
+#define SRST_PRESETN_OTPC_NS                     449
+#define SRST_RESETN_OTPC_NS                      450
+
+/* PMU1_CRU-->SOFTRST_CON03 */
+#define SRST_PRESETN_APB2ASB_PMU1                451
+#define SRST_SRESETN_APB2ASB_PMU1                452
+#define SRST_HRESETN_PMU1_BIU                    453
+#define SRST_HRESETN_PMU1_FW                     454
+#define SRST_PRESETN_PMU1_BIU                    455
+#define SRST_HRESETN_PMU_CM0_BIU                 456
+#define SRST_CORERESETN_N100                     457
+#define SRST_PORESETN_N100                       458
+
+/* PMU1_CRU-->SOFTRST_CON04 */
+#define SRST_PRESETN_CRU_PMU1                    459
+#define SRST_PRESETN_PMU1_GRF                    460
+#define SRST_PRESETN_PMU1_IOC                    461
+#define SRST_PRESETN_PMU1WDT                     462
+#define SRST_TRESETN_PMU1WDT                     463
+#define SRST_PRESETN_PMUTIMER                    464
+#define SRST_RESETN_PMUTIMER0                    465
+#define SRST_RESETN_PMUTIMER1                    466
+#define SRST_PRESETN_PWM0                        467
+#define SRST_RESETN_PWM0                         468
+
+/* PMU1_CRU-->SOFTRST_CON05 */
+#define SRST_PRESETN_I2C0                        469
+#define SRST_RESETN_I2C0                         470
+#define SRST_SRESETN_UART1                       471
+#define SRST_PRESETN_UART1                       472
+#define SRST_RESETN_TEST_JUDGE_24M_PMU1          473
+#define SRST_RESETN_TEST_JUDGE_PMU1              474
+#define SRST_RESETN_PDM0                         475
+
+/* PMU1_CRU-->SOFTRST_CON06 */
+#define SRST_HRESETN_PDM0                        476
+#define SRST_MRESETN_PDM0                        477
+#define SRST_HRESETN_VAD                         478
+#define SRST_PRESETN_RCOSC                       479
+#define SRST_RESETN_RCOSC                        480
+
+/* PMU1_CRU-->SOFTRST_CON07 */
+#define SRST_PRESETN_PMU0GRF                     481
+#define SRST_PRESETN_PMU0IOC                     482
+#define SRST_PRESETN_GPIO0                       483
+#define SRST_DBRESETN_GPIO0                      484
+
+/* DDR0_CRU-->SOFTRST_CON00 */
+#define SRST_RESETN_DDRPHY1X                     485
+
+/* DDR0_CRU-->SOFTRST_CON01 */
+#define SRST_PRESETN_DDRPHY_CRU                  486
+#define SRST_PRESETN_DDRPHY                      487
+
+/* BIGCORE_CRU-->SOFTRST_CON00 */
+#define SRST_RESETN_REF_PVTPLL_BIGCORE           488
+#define SRST_PRESETN_BIGCORE_BIU                 489
+#define SRST_PRESETN_BIGCORE_GRF                 490
+#define SRST_PRESETN_BIGCORE_CRU                 491
+#define SRST_PRESETN_PVTPLL_BIGCORE              492
+#define SRST_NBIGCOREPORESET0                    493
+#define SRST_NBIGCOREPORESET1                    494
+#define SRST_NBIGCORESET0                        495
+#define SRST_NBIGCORESET1                        496
+
+/* BIGCORE_CRU-->SOFTRST_CON01 */
+#define SRST_NL2RESET_BIGCORE                    497
+#define SRST_ARESETN_ADB400_A73_ACE              498
+#define SRST_RESETN_TEST_JUDGE_24M_BIGCORE       499
+#define SRST_RESETN_TEST_JUDGE_BIGCORE           500
+#define SRST_PRESETN_DBG_BIGCORE                 501
+
+/* LITCORE0_CRU-->SOFTRST_CON00 */
+#define SRST_RESETN_REF_LITCORE0_PVTPLL          502
+#define SRST_NLITCOREPORESET0                    503
+#define SRST_NLITCOREPORESET1                    504
+#define SRST_NLITCOREPORESET2                    505
+#define SRST_NLITCOREPORESET3                    506
+#define SRST_NLITCORESET0                        507
+#define SRST_NLITCORESET1                        508
+#define SRST_NLITCORESET2                        509
+#define SRST_NLITCORESET3                        510
+#define SRST_NL2RESET_LITCORE0                   511
+#define SRST_PRESETN_DBG_LITCORE0                512
+#define SRST_ARESETN_ADB400_A53_ACE_LITCORE0     513
+
+/* LITCORE0_CRU-->SOFTRST_CON01 */
+#define SRST_PRESETN_LITCORE0_GRF                514
+#define SRST_PRESETN_LITCORE0_BIU                515
+#define SRST_PRESETN_PVTPLL_LITCORE0             516
+#define SRST_PRESETN_LITCORE0_CRU                517
+#define SRST_RESETN_TEST_JUDGE_24M_LITCORE0      518
+#define SRST_RESETN_TEST_JUDGE_LITCORE0          519
+
+/* LITCORE1_CRU-->SOFTRST_CON00 */
+#define SRST_RESETN_REF_LITCORE1_PVTPLL          520
+#define SRST_NLITCOREPORESET4                    521
+#define SRST_NLITCOREPORESET5                    522
+#define SRST_NLITCORESET4                        523
+#define SRST_NLITCORESET5                        524
+#define SRST_NL2RESET_LITCORE1                   525
+#define SRST_PRESETN_DBG_LITCORE1                526
+#define SRST_ARESETN_ADB400_A53_ACE_LITCORE1     527
+#define SRST_PRESETN_LITCORE1_GRF                528
+#define SRST_PRESETN_LITCORE1_BIU                529
+
+/* LITCORE1_CRU-->SOFTRST_CON01 */
+#define SRST_PRESETN_PVTPLL_LITCORE1             530
+#define SRST_PRESETN_LITCORE1_CRU                531
+#define SRST_RESETN_TEST_JUDGE_24M_LITCORE1      532
+#define SRST_RESETN_TEST_JUDGE_LITCORE1          533
+
+/* CCI_CRU-->SOFTRST_CON01 */
+#define SRST_RESETN_TEST_JUDGE_24M_CCI           534
+#define SRST_RESETN_TEST_JUDGE_CCI               535
+#define SRST_ARESETN_CPE                         536
+#define SRST_PRESETN_CCI_BIU                     537
+#define SRST_PRESETN_CCI_FW                      538
+#define SRST_ARESETN_CCI_BIU                     539
+#define SRST_ARESETN_CCI_FW                      540
+
+/* CCI_CRU-->SOFTRST_CON02 */
+#define SRST_PRESETN_DBG_SYS                     541
+#define SRST_PRESETN_CCI_GRF                     542
+#define SRST_PRESETN_CCI_CRU                     543
+#define SRST_ARESETN_CCI                         544
+#define SRST_PORESETN_JTAG                       545
+#define SRST_PRESETN_DBG_M                       546
+#define SRST_ARESETN_ADB400_CCI_A73              547
+#define SRST_ARESETN_ADB400_CCI_A53_0            548
+#define SRST_ARESETN_ADB400_CCI_A53_1            549
+#define SRST_PRESETN_PVTPLL_CCI                  550
+#define SRST_PRESETN_CCI_SPINLOCK                551
+#define SRST_PRESETN_DBG_M_BIU                   552
+#define SRST_RESETN_REF_CCI_PVTPLL               553
+
+#endif

-- 
2.34.1

