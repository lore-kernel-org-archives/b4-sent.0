From: Kelvin Zhang <kelvin.zhang@amlogic.com>
Date: Thu, 13 Mar 2025 17:05:36 +0800
Subject: [PATCH v4 3/3] arm64: dts: amlogic: Add A5 Reset Controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250313-a4-a5-reset-v4-3-8076f684d6cf@amlogic.com>
References: <20250313-a4-a5-reset-v4-0-8076f684d6cf@amlogic.com>
In-Reply-To: <20250313-a4-a5-reset-v4-0-8076f684d6cf@amlogic.com>
To: Philipp Zabel <p.zabel@pengutronix.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Zelong Dong <zelong.dong@amlogic.com>, 
 Kelvin Zhang <kelvin.zhang@amlogic.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741856786; l=3877;
 i=kelvin.zhang@amlogic.com; s=20240329; h=from:subject:message-id;
 bh=ZFu/iq6Br16B1GmXZXg+n7u5XDIS+7iiJRB1TMYOhs4=;
 b=8WsA+Mm77eVUAT3YgjZQzAi9J3yuCVLHAYgwmSKS8l6fcCTikKBtv+PoxXMtrweg0qyrUt9n4
 19h7CXmFbd3DXsUYHDxicwR7642QUCitxBuP0WfbwV/EQKeIIjb976U
X-Developer-Key: i=kelvin.zhang@amlogic.com; a=ed25519;
 pk=pgnle7HTNvnNTcOoGejvtTC7BJT30HUNXfMHRRXSylI=
X-Endpoint-Received: by B4 Relay for kelvin.zhang@amlogic.com/20240329 with auth_id=148
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Zelong Dong <zelong.dong@amlogic.com>

Add the device node and related header file for Amlogic
A5 reset controller.

Signed-off-by: Zelong Dong <zelong.dong@amlogic.com>
Link: https://lore.kernel.org/r/20240918074211.8067-4-zelong.dong@amlogic.com
Signed-off-by: Kelvin Zhang <kelvin.zhang@amlogic.com>
---
 arch/arm64/boot/dts/amlogic/amlogic-a5-reset.h | 95 ++++++++++++++++++++++++++
 arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi    | 10 +++
 2 files changed, 105 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/amlogic-a5-reset.h b/arch/arm64/boot/dts/amlogic/amlogic-a5-reset.h
new file mode 100644
index 0000000000000000000000000000000000000000..cdf0f515962097c606e4c53badb19df7d21606ec
--- /dev/null
+++ b/arch/arm64/boot/dts/amlogic/amlogic-a5-reset.h
@@ -0,0 +1,95 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR MIT) */
+/*
+ * Copyright (c) 2024 Amlogic, Inc. All rights reserved.
+ */
+
+#ifndef __DTS_AMLOGIC_A5_RESET_H
+#define __DTS_AMLOGIC_A5_RESET_H
+
+/* RESET0 */
+/*						0-3 */
+#define RESET_USB				4
+/*						5-7 */
+#define RESET_USBPHY20				8
+/*						9 */
+#define RESET_USB2DRD				10
+/*						11-31 */
+
+/* RESET1 */
+#define RESET_AUDIO				32
+#define RESET_AUDIO_VAD				33
+/*                                              34 */
+#define RESET_DDR_APB				35
+#define RESET_DDR				36
+/*						37-40 */
+#define RESET_DSPA_DEBUG			41
+/*                                              42 */
+#define RESET_DSPA				43
+/*						44-46 */
+#define RESET_NNA				47
+#define RESET_ETHERNET				48
+/*						49-63 */
+
+/* RESET2 */
+#define RESET_ABUS_ARB				64
+#define RESET_IRCTRL				65
+/*						66 */
+#define RESET_TS_PLL				67
+/*						68-72 */
+#define RESET_SPICC_0				73
+#define RESET_SPICC_1				74
+#define RESET_RSA				75
+
+/*						76-79 */
+#define RESET_MSR_CLK				80
+#define RESET_SPIFC				81
+#define RESET_SAR_ADC				82
+/*						83-90 */
+#define RESET_WATCHDOG				91
+/*						92-95 */
+
+/* RESET3 */
+/*						96-127 */
+
+/* RESET4 */
+#define RESET_RTC				128
+/*						129-131 */
+#define RESET_PWM_AB				132
+#define RESET_PWM_CD				133
+#define RESET_PWM_EF				134
+#define RESET_PWM_GH				135
+/*						104-105 */
+#define RESET_UART_A				138
+#define RESET_UART_B				139
+#define RESET_UART_C				140
+#define RESET_UART_D				141
+#define RESET_UART_E				142
+/*						143*/
+#define RESET_I2C_S_A				144
+#define RESET_I2C_M_A				145
+#define RESET_I2C_M_B				146
+#define RESET_I2C_M_C				147
+#define RESET_I2C_M_D				148
+/*						149-151 */
+#define RESET_SDEMMC_A				152
+/*						153 */
+#define RESET_SDEMMC_C				154
+/*						155-159*/
+
+/* RESET5 */
+/*						160-175 */
+#define RESET_BRG_AO_NIC_SYS			176
+#define RESET_BRG_AO_NIC_DSPA			177
+#define RESET_BRG_AO_NIC_MAIN			178
+#define RESET_BRG_AO_NIC_AUDIO			179
+/*						180-183 */
+#define RESET_BRG_AO_NIC_ALL			184
+#define RESET_BRG_NIC_NNA			185
+#define RESET_BRG_NIC_SDIO			186
+#define RESET_BRG_NIC_EMMC			187
+#define RESET_BRG_NIC_DSU			188
+#define RESET_BRG_NIC_SYSCLK			189
+#define RESET_BRG_NIC_MAIN			190
+#define RESET_BRG_NIC_ALL			191
+
+#endif
diff --git a/arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi b/arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi
index 17a6316de8918f31f3f7625f2eda06a60664139a..b97e2f3091bf62f4bdaaebeaf5d1dfe695cfc6d5 100644
--- a/arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi
+++ b/arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi
@@ -4,6 +4,7 @@
  */
 
 #include "amlogic-a4-common.dtsi"
+#include "amlogic-a5-reset.h"
 #include <dt-bindings/power/amlogic,a5-pwrc.h>
 / {
 	cpus {
@@ -48,3 +49,12 @@ pwrc: power-controller {
 		};
 	};
 };
+
+&apb {
+	reset: reset-controller@2000 {
+		compatible = "amlogic,a5-reset",
+			     "amlogic,meson-s4-reset";
+		reg = <0x0 0x2000 0x0 0x98>;
+		#reset-cells = <1>;
+	};
+};

-- 
2.37.1

