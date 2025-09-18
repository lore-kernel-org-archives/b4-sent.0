From: Dang Huynh <dang.huynh@mainlining.org>
Date: Fri, 19 Sep 2025 01:48:50 +0700
Subject: [PATCH 10/10] ARM: dts: unisoc: rda8810pl: Add SDMMC controllers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250919-rda8810pl-mmc-v1-10-d4f08a05ba4d@mainlining.org>
References: <20250919-rda8810pl-mmc-v1-0-d4f08a05ba4d@mainlining.org>
In-Reply-To: <20250919-rda8810pl-mmc-v1-0-d4f08a05ba4d@mainlining.org>
To: Manivannan Sadhasivam <mani@kernel.org>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Vinod Koul <vkoul@kernel.org>, 
 Ulf Hansson <ulf.hansson@linaro.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Kees Cook <kees@kernel.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-unisoc@lists.infradead.org, 
 linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 dmaengine@vger.kernel.org, linux-mmc@vger.kernel.org, 
 linux-hardening@vger.kernel.org, Dang Huynh <dang.huynh@mainlining.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758221395; l=5720;
 i=dang.huynh@mainlining.org; s=20250917; h=from:subject:message-id;
 bh=zi1lBIjsLiJ+MvStlhu52N5g0U+YipGaIL9gPvgvEPE=;
 b=l77vToHDcYswIc8WztAJWYO/+3IYOVrmTQlZnFRvjc0lKarYC0h4XR0hoxgA2q3ZB98uFJham
 quoNd+aQB2RCTuhZ8oSMEutdqzVeCxtTOtcZpguuNT9Z4JHuV24Oxly
X-Developer-Key: i=dang.huynh@mainlining.org; a=ed25519;
 pk=RyzH4CL4YU/ItXYUurA51EVBidfx4lIy8/E4EKRJCUk=
X-Endpoint-Received: by B4 Relay for dang.huynh@mainlining.org/20250917 with auth_id=526
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add SDMMC1 and 2 controllers for the RDA8810PL platform and enable it
on the Orange Pi i96 and 2G-IOT.

Signed-off-by: Dang Huynh <dang.huynh@mainlining.org>
---
 .../boot/dts/unisoc/rda8810pl-orangepi-2g-iot.dts  | 20 +++++++++
 .../arm/boot/dts/unisoc/rda8810pl-orangepi-i96.dts | 20 +++++++++
 arch/arm/boot/dts/unisoc/rda8810pl.dtsi            | 47 ++++++++++++++++++++--
 3 files changed, 83 insertions(+), 4 deletions(-)

diff --git a/arch/arm/boot/dts/unisoc/rda8810pl-orangepi-2g-iot.dts b/arch/arm/boot/dts/unisoc/rda8810pl-orangepi-2g-iot.dts
index 98e34248ae80b1fcd673ff01fe045db412d5bcc9..b462057ec0d1eb1877eb770afa6aced99efd84b7 100644
--- a/arch/arm/boot/dts/unisoc/rda8810pl-orangepi-2g-iot.dts
+++ b/arch/arm/boot/dts/unisoc/rda8810pl-orangepi-2g-iot.dts
@@ -6,6 +6,7 @@
 
 /dts-v1/;
 
+#include <dt-bindings/gpio/gpio.h>
 #include "rda8810pl.dtsi"
 
 / {
@@ -27,6 +28,13 @@ memory@80000000 {
 		reg = <0x80000000 0x10000000>;
 	};
 
+	vdd_sdmmc: regulator-fixed {
+		compatible = "regulator-fixed";
+		regulator-name = "vdd_sdmmc";
+		regulator-min-microvolt = <2800000>;
+		regulator-max-microvolt = <2800000>;
+	};
+
 	uart_clk: uart-clk {
 		compatible = "fixed-clock";
 		clock-frequency = <921600>;
@@ -34,6 +42,18 @@ uart_clk: uart-clk {
 	};
 };
 
+&mmc1 {
+	status = "okay";
+	no-sdio;
+	no-mmc;
+	bus-width = <4>;
+	max-frequency = <30000000>;
+	cd-gpios = <&gpiob 4 GPIO_ACTIVE_LOW>;
+	vmmc-supply = <&vdd_sdmmc>;
+	rda,mclk-adj = /bits/ 8 <1>;
+	rda,mclk-inv;
+};
+
 &uart1 {
 	status = "okay";
 	clocks = <&uart_clk>;
diff --git a/arch/arm/boot/dts/unisoc/rda8810pl-orangepi-i96.dts b/arch/arm/boot/dts/unisoc/rda8810pl-orangepi-i96.dts
index 728f76931b995fdfc036b586f899b15a7f07528b..cf4b75f114b33b27fad0ead4951b15abb1f5cabd 100644
--- a/arch/arm/boot/dts/unisoc/rda8810pl-orangepi-i96.dts
+++ b/arch/arm/boot/dts/unisoc/rda8810pl-orangepi-i96.dts
@@ -6,6 +6,7 @@
 
 /dts-v1/;
 
+#include <dt-bindings/gpio/gpio.h>
 #include "rda8810pl.dtsi"
 
 / {
@@ -27,6 +28,13 @@ memory@80000000 {
 		reg = <0x80000000 0x10000000>;
 	};
 
+	vdd_sdmmc: regulator-fixed {
+		compatible = "regulator-fixed";
+		regulator-name = "vdd_sdmmc";
+		regulator-min-microvolt = <2800000>;
+		regulator-max-microvolt = <2800000>;
+	};
+
 	uart_clk: uart-clk {
 		compatible = "fixed-clock";
 		clock-frequency = <921600>;
@@ -34,6 +42,18 @@ uart_clk: uart-clk {
 	};
 };
 
+&mmc1 {
+	status = "okay";
+	no-sdio;
+	no-mmc;
+	bus-width = <4>;
+	max-frequency = <30000000>;
+	cd-gpios = <&gpiob 4 GPIO_ACTIVE_LOW>;
+	vmmc-supply = <&vdd_sdmmc>;
+	rda,mclk-adj = /bits/ 8 <1>;
+	rda,mclk-inv;
+};
+
 &uart1 {
 	status = "okay";
 	clocks = <&uart_clk>;
diff --git a/arch/arm/boot/dts/unisoc/rda8810pl.dtsi b/arch/arm/boot/dts/unisoc/rda8810pl.dtsi
index f30d6ece49fb33d9c5c3ad9522c83bb8e4f8b488..438be79a89060655e4a12edc6d3c42574748108b 100644
--- a/arch/arm/boot/dts/unisoc/rda8810pl.dtsi
+++ b/arch/arm/boot/dts/unisoc/rda8810pl.dtsi
@@ -7,6 +7,8 @@
  */
 
 #include <dt-bindings/interrupt-controller/irq.h>
+#include <dt-bindings/clock/rda,8810pl-apclk.h>
+#include <dt-bindings/dma/rda-ifc.h>
 
 / {
 	compatible = "rda,8810pl";
@@ -39,7 +41,7 @@ modem@10000000 {
 		#size-cells = <1>;
 		ranges = <0x0 0x10000000 0xfffffff>;
 
-		gpioc@1a08000 {
+		gpioc: gpioc@1a08000 {
 			compatible = "rda,8810pl-gpio";
 			reg = <0x1a08000 0x1000>;
 			gpio-controller;
@@ -68,6 +70,13 @@ apb@20900000 {
 		#size-cells = <1>;
 		ranges = <0x0 0x20900000 0x100000>;
 
+		ap_syscon: syscon@0 {
+			compatible = "rda,8810pl-apsyscon", "syscon";
+			reg = <0x0 0x1000>;
+			#clock-cells = <1>;
+			#reset-cells = <1>;
+		};
+
 		timer@10000 {
 			compatible = "rda,8810pl-timer";
 			reg = <0x10000 0x1000>;
@@ -76,7 +85,7 @@ timer@10000 {
 			interrupt-names = "hwtimer", "ostimer";
 		};
 
-		gpioa@30000 {
+		gpioa: gpioa@30000 {
 			compatible = "rda,8810pl-gpio";
 			reg = <0x30000 0x1000>;
 			gpio-controller;
@@ -87,7 +96,7 @@ gpioa@30000 {
 			interrupts = <12 IRQ_TYPE_LEVEL_HIGH>;
 		};
 
-		gpiob@31000 {
+		gpiob: gpiob@31000 {
 			compatible = "rda,8810pl-gpio";
 			reg = <0x31000 0x1000>;
 			gpio-controller;
@@ -98,7 +107,7 @@ gpiob@31000 {
 			interrupts = <13 IRQ_TYPE_LEVEL_HIGH>;
 		};
 
-		gpiod@32000 {
+		gpiod: gpiod@32000 {
 			compatible = "rda,8810pl-gpio";
 			reg = <0x32000 0x1000>;
 			gpio-controller;
@@ -123,6 +132,30 @@ uart1: serial@0 {
 			status = "disabled";
 		};
 
+		mmc1: mmc@50000 {
+			compatible = "rda,8810pl-mmc", "rda,mmc";
+			reg = <0x50000 0x1000>;
+			interrupts = <3 IRQ_TYPE_LEVEL_HIGH>;
+			clocks = <&ap_syscon CLK_APB2>;
+			clock-names = "mclk";
+			resets = <&ap_syscon RST_APB2_SDMMC1>;
+			dmas = <&ifc IFC_SDMMC1_TX>, <&ifc IFC_SDMMC1_RX>;
+			dma-names = "tx", "rx";
+			status = "disabled";
+		};
+
+		mmc2: mmc@60000 {
+			compatible = "rda,8810pl-mmc", "rda,mmc";
+			reg = <0x60000 0x1000>;
+			interrupts = <4 IRQ_TYPE_LEVEL_HIGH>;
+			clocks = <&ap_syscon CLK_APB2>;
+			clock-names = "mclk";
+			resets = <&ap_syscon RST_APB2_SDMMC2>;
+			dmas = <&ifc IFC_SDMMC2_TX>, <&ifc IFC_SDMMC2_RX>;
+			dma-names = "tx", "rx";
+			status = "disabled";
+		};
+
 		uart2: serial@10000 {
 			compatible = "rda,8810pl-uart";
 			reg = <0x10000 0x1000>;
@@ -136,6 +169,12 @@ uart3: serial@90000 {
 			interrupts = <11 IRQ_TYPE_LEVEL_HIGH>;
 			status = "disabled";
 		};
+
+		ifc: dma-controller@f0000 {
+			compatible = "rda,8810pl-ifc", "rda,ifc";
+			reg = <0xf0000 0x1000>;
+			#dma-cells = <1>;
+		};
 	};
 
 	l2: cache-controller@21100000 {

-- 
2.51.0

