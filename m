From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Thu, 09 Jul 2026 08:26:50 +0000
Subject: [PATCH 3/3] arm64: dts: amlogic: a9: Add reset controller support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260709-a9-reset-v1-3-fd7cf039b853@amlogic.com>
References: <20260709-a9-reset-v1-0-fd7cf039b853@amlogic.com>
In-Reply-To: <20260709-a9-reset-v1-0-fd7cf039b853@amlogic.com>
To: Philipp Zabel <p.zabel@pengutronix.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783585609; l=9268;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=oODyjrjEWR0VVNYxuXsuxzIRBRji+50KsZ/k5IisG0Q=;
 b=CehsLOVEvre4Q6qOZtCLa7rTarT8SIYiHPOqG4BKqjpchcaxqt8b5s6/CiC+74cJ1Z/+yaWYj
 lrXCKy4dt+1AhV7vQm5Uvwi9NBlhMjdYhY0z37UnGdGtiT9EC+8yC3/
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add reset controller descriptions for the Amlogic A9 SoC and include the
corresponding reset IDs header.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 arch/arm64/boot/dts/amlogic/amlogic-a9-reset.h | 247 +++++++++++++++++++++++++
 arch/arm64/boot/dts/amlogic/amlogic-a9.dtsi    |  14 ++
 2 files changed, 261 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/amlogic-a9-reset.h b/arch/arm64/boot/dts/amlogic/amlogic-a9-reset.h
new file mode 100644
index 000000000000..55fcaa54cd56
--- /dev/null
+++ b/arch/arm64/boot/dts/amlogic/amlogic-a9-reset.h
@@ -0,0 +1,247 @@
+/* SPDX-License-Identifier: (GPL-2.0+ OR MIT) */
+/*
+ * Copyright (c) 2026 Amlogic, Inc. All rights reserved.
+ * Author: Zelong Dong <zelong.dong@amlogic.com>
+ *
+ */
+
+#ifndef _DT_BINDINGS_AMLOGIC_MESON_A9_RESET_H
+#define _DT_BINDINGS_AMLOGIC_MESON_A9_RESET_H
+
+/* AO RESET0 */
+#define AO_RESET_APB				0
+#define AO_RESET_RTC				1
+#define AO_RESET_BRG_NIC_RTC			2
+#define AO_RESET_AO2EE				3
+#define AO_RESET_BRG_NIC_EE			4
+#define AO_RESET_WATCHDOG			5
+#define AO_RESET_I3C				6
+#define AO_RESET_PWR				7
+#define AO_RESET_PWM_A				8
+#define AO_RESET_PWM_B				9
+#define AO_RESET_PWM_C				10
+#define AO_RESET_PWM_D				11
+#define AO_RESET_PWM_E				12
+#define AO_RESET_PWM_F				13
+#define AO_RESET_PWM_G				14
+#define AO_RESET_I2C_M_A			15
+#define AO_RESET_I2C_M_B			16
+#define AO_RESET_I2C_M_C			17
+#define AO_RESET_I2C_M_D			18
+#define AO_RESET_IR				19
+#define AO_RESET_UART_B				20
+#define AO_RESET_UART_C				21
+#define AO_RESET_UART_D				22
+#define AO_RESET_SPISG				23
+#define AO_RESET_SED				24
+#define AO_RESET_CEC				25
+#define AO_RESET_AOCPU				26
+#define AO_RESET_AOCPU_POR			27
+#define AO_RESET_AOCPU_CORE			28
+#define AO_RESET_SRAM				29
+#define AO_RESET_CAPU				30
+#define AO_RESET_UART_E				31
+
+/* RESET0 */
+#define RESET_ETH_1G				0
+#define RESET_ISP				1
+#define RESET_U3DRD_USB3PHY_APB			2
+#define RESET_U3DRD_USB3PHY			3
+#define RESET_U3DRD_USB2PHY			4
+#define RESET_U3DRD				5
+#define RESET_U3DRD_COMB			6
+#define RESET_U3DRD_USB2PHY_APB			7
+#define RESET_DP_PHY_APB			8
+#define RESET_DP_PHY				9
+#define RESET_DPTX_1P4				10
+#define RESET_DPTX_1P4_APB			11
+#define RESET_EDPTX_1P4				12
+#define RESET_USB2DRD_PHY_APB			13
+#define RESET_U2DRD_COMB			14
+#define RESET_U2DRD				15
+#define RESET_HDMI20_AES			16
+#define RESET_HDMITX_CBUS_APB			17
+#define RESET_BRG_VCBUS_DEC			18
+#define RESET_VCBUS				19
+#define RESET_VID_PLL_DIV			20
+#define RESET_VDI6				21
+#define RESET_HDMITXPHY				22
+#define RESET_VID_LOCK				23
+#define RESET_VENC_2				24
+#define RESET_VDAC				25
+#define RESET_VENC_1				26
+#define RESET_VENC_0				27
+#define RESET_RDMA				28
+#define RESET_HDMITX				29
+#define RESET_VIU				30
+#define RESET_VENC				31
+
+/* RESET1 */
+#define RESET_AUDIO				32
+#define RESET_MALI_CBUS_APB			33
+#define RESET_MALI				34
+#define RESET_PCIE_B_PHY			35
+#define RESET_PCIE_B_POR			36
+#define RESET_DOS_CBUS_APB			37
+#define RESET_DOS				38
+#define RESET_MALI_SYS				39
+#define RESET_CC				40
+#define RESET_DSP_A_DEBUG			41
+#define RESET_PCIE_A_PHY_APB			42
+#define RESET_PCIE_A_PIPE			43
+#define RESET_PCIE_A_POR			44
+#define RESET_PCIE_A_PHY			45
+#define RESET_PCIE_A_MAC_APB			46
+#define RESET_AMFC_APB				47
+#define RESET_ETH				48
+/*						49 */
+#define RESET_MALI_MBIST			50
+#define RESET_ETH_1G_AXI			51
+#define RESET_VICP				52
+#define RESET_DEWARP				53
+#define RESET_GE2D				54
+#define RESET_VGE				55
+#define RESET_PCIE_A_0				56
+#define RESET_PCIE_A_1				57
+#define RESET_PCIE_A_2				58
+#define RESET_PCIE_A_3				59
+#define RESET_PCIE_A_4				60
+#define RESET_PCIE_A_5				61
+#define RESET_PCIE_A_6				62
+#define RESET_PCIE_A_7				63
+
+/* RESET2 */
+#define RESET_AM2AXI				64
+#define RESET_DSP_A				65
+#define RESET_MIPI_DSI_PHY			66
+#define RESET_TS_PLL				67
+#define RESET_TS_A55				68
+#define RESET_ETH_AXI				69
+#define RESET_TS_CORE				70
+#define RESET_MIPI_DSI1_PHY			71
+#define RESET_SMART_CARD			72
+#define RESET_SPISG				73
+#define RESET_TS_DOS				74
+#define RESET_U2DRD_USB2PHY			75
+#define RESET_PIO				76
+#define RESET_U2H_COMB				77
+#define RESET_U2H				78
+#define RESET_USB2H_PHY_APB			79
+#define RESET_MSR_CLK				80
+/*						81 */
+#define RESET_AUX_DIG				82
+/*						83 */
+#define RESET_U2H_USB2PHY			84
+#define RESET_U3HSG_PCIE_PIPE			85
+#define RESET_AMFC				86
+#define RESET_U3HSG_PCIE_PHY_APB		87
+#define RESET_U3HSG_PCIE_PHY			88
+#define RESET_PP_DMA				89
+#define RESET_I3C				90
+#define RESET_WATCHDOG				91
+#define RESET_PP_WRAPPER			92
+#define RESET_MIPI_DSI_HOST			93
+#define RESET_DSI_PLL_DIV			94
+#define RESET_MIPI_DSI_B_HOST			95
+
+/* RESET3 */
+/*						96 */
+#define RESET_HDMIRX_WRAP_APB			97
+#define RESET_HDMIRX				98
+#define RESET_PCIE_B_0				99
+#define RESET_PCIE_B_1				100
+#define RESET_PCIE_B_2				101
+#define RESET_PCIE_B_3				102
+#define RESET_PCIE_B_4				103
+#define RESET_PCIE_B_5				104
+#define RESET_PCIE_B_6				105
+#define RESET_PCIE_B_7				106
+#define RESET_PCIE_B_PIPE			107
+#define RESET_PCIE_B_MAC_APB			108
+#define RESET_NNA_TO_VGA_PIPE			109
+#define RESET_CVE				110
+#define RESET_GLOBAL_TIMER			111
+#define RESET_COMBO_DPHY_PCLK			112
+#define RESET_COMBO_DPHY			113
+/*						114 - 118 */
+#define RESET_U3PHY30_APB			119
+#define RESET_U3PHY30				120
+#define RESET_HSG				121
+#define RESET_U3HSG_HSG				122
+#define RESET_U3DRDB				123
+#define RESET_U3DRDB_APB			124
+#define RESET_U3PHY20_APB			125
+#define RESET_U3PHY20				126
+#define RESET_A55_ACE				127
+
+/* RESET4 */
+#define RESET_CAN_0				128
+#define RESET_CAN_1				129
+#define RESET_TAHOE_CORE			130
+#define RESET_TAHOE				131
+#define RESET_TAHOE_APB				132
+#define RESET_TAHOE_SYS				133
+/*						134 - 135 */
+#define RESET_PWM_I				136
+#define RESET_PWM_J				137
+#define RESET_UART_A				138
+/*						139 - 143 */
+#define RESET_MALI_AVBCD			144
+#define RESET_MALI_AVBCD_APB			145
+#define RESET_MALI_MCR_TOP			146
+#define RESET_I2C_M_E				147
+#define RESET_I2C_M_F				148
+#define RESET_I2C_M_G				149
+#define RESET_I2C_M_H				150
+#define RESET_I2C_M_I				151
+#define RESET_SD_EMMC_A				152
+#define RESET_SD_EMMC_B				153
+#define RESET_SD_EMMC_C				154
+#define RESET_UART_F				155
+#define RESET_PWM_N				156
+#define RESET_PWM_M				157
+#define RESET_PWM_L				158
+#define RESET_PWM_K				159
+
+/* RESET5 */
+#define RESET_BRG_ISP_PIPE			160
+#define RESET_BRG_HEVCF_DMC_PIPE		161
+#define RESET_BRG_HEVCB_PIPE			162
+#define RESET_BRG_EMMC_PIPE			163
+#define RESET_BRG_VGE_PIPE			164
+#define RESET_BRG_DMC_VPU1_PIPE			165
+#define RESET_BRG_DMC_VPU0_PIPE			166
+#define RESET_BRG_NNA_PIPE			167
+#define RESET_BRG_NNA_SRAM_PIPE			168
+#define RESET_BRG_U2DRDA_PIPE			169
+#define RESET_BRG_U3DRDA_PIPE			170
+/*						171 - 173 */
+#define RESET_BRG_NIC_AOSYS			174
+#define RESET_BRG_NIC_AMFC			175
+#define RESET_BRG_NIC_GIC			176
+#define RESET_BRG_SRAM_NIC_NNA			177
+#define RESET_BRG_SRAM_NIC_MAIN			178
+#define RESET_BRG_SRAM_NIC_ALL			179
+#define RESET_BRG_NIC_SOC_BRG			180
+#define RESET_BRG_NIC_GPV			181
+#define RESET_BRG_NIC_AO			182
+#define RESET_BRG_NIC_EMMC			183
+#define RESET_BRG_NIC_DSP_A			184
+#define RESET_BRG_NIC_SDIO_B			185
+#define RESET_BRG_NIC_SDIO_A			186
+#define RESET_BRG_NIC_VAP_B			187
+#define RESET_BRG_NIC_DSU			188
+#define RESET_BRG_NIC_CLK81			189
+#define RESET_BRG_NIC_MAIN			190
+#define RESET_BRG_NIC_ALL			191
+
+/* RESET6 */
+/*						192 - 216 */
+#define RESET_BRG_PP_CLK			217
+#define RESET_BRG_PP_NIC_CLK81			218
+/*						219 - 220 */
+#define RESET_BRG_PERIPH_APB_SYNC		221
+#define RESET_BRG_VPU_APB_SYNC			222
+#define RESET_BRG_DSP_A_PIPE			223
+
+#endif
diff --git a/arch/arm64/boot/dts/amlogic/amlogic-a9.dtsi b/arch/arm64/boot/dts/amlogic/amlogic-a9.dtsi
index b0e0fadeed82..546820b4598b 100644
--- a/arch/arm64/boot/dts/amlogic/amlogic-a9.dtsi
+++ b/arch/arm64/boot/dts/amlogic/amlogic-a9.dtsi
@@ -7,6 +7,7 @@
 #include <dt-bindings/interrupt-controller/arm-gic.h>
 #include <dt-bindings/gpio/gpio.h>
 #include <dt-bindings/pinctrl/amlogic,pinctrl.h>
+#include "amlogic-a9-reset.h"
 
 / {
 	interrupt-parent = <&gic>;
@@ -105,6 +106,13 @@ apb: bus@fe000000 {
 			#size-cells = <2>;
 			ranges = <0x0 0x0 0x0 0xfe000000 0x0 0x480000>;
 
+			reset: reset-controller@2000 {
+				compatible = "amlogic,a9-reset",
+					     "amlogic,t7-reset";
+				reg = <0x0 0x2000 0x0 0x98>;
+				#reset-cells = <1>;
+			};
+
 			periphs_pinctrl: pinctrl@4000 {
 				compatible = "amlogic,pinctrl-a9";
 				#address-cells = <2>;
@@ -204,6 +212,12 @@ aobus: bus@ffa00000 {
 			#size-cells = <2>;
 			ranges = <0x0 0x0 0x0 0xffa00000 0x0 0x100000>;
 
+			ao_reset: ao-reset-controller@2000 {
+				compatible = "amlogic,a9-ao-reset";
+				reg = <0x0 0x2000 0x0 0xc>;
+				#reset-cells = <1>;
+			};
+
 			aobus_pinctrl: pinctrl@4000 {
 				compatible = "amlogic,pinctrl-a9";
 				#address-cells = <2>;

-- 
2.52.0

