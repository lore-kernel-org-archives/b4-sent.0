From: Chuan Liu <chuan.liu@amlogic.com>
Date: Tue, 30 Sep 2025 17:37:24 +0800
Subject: [PATCH 11/19] arm64: dts: amlogic: A4: Add peripherals clock
 controller node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250930-a4_a5_add_clock_driver-v1-11-a9acf7951589@amlogic.com>
References: <20250930-a4_a5_add_clock_driver-v1-0-a9acf7951589@amlogic.com>
In-Reply-To: <20250930-a4_a5_add_clock_driver-v1-0-a9acf7951589@amlogic.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>, Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759225047; l=1947;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=WkZjCGYH9SRZ1p+CbboLb8KN0Yvea30tPFS+Yn032E8=;
 b=24BHjpOH4gCCvBgh+DjCK5+2l9sJd9v4b8UIh947+UdrksdwZhUuw12uWaJw/27TRTxRo5Ddb
 KHdpac5OKj9DyJkBJV814kMWQ5dG6ngI/Z2tXLhRKgltH8WEvNX+vCD
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the peripherals clock controller node for A4 SoC family.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi | 39 +++++++++++++++++++++++++++++
 1 file changed, 39 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi b/arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi
index aca81e658654..3404358aff58 100644
--- a/arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi
+++ b/arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi
@@ -9,6 +9,7 @@
 #include <dt-bindings/pinctrl/amlogic,pinctrl.h>
 #include <dt-bindings/clock/amlogic,a4-pll-clkc.h>
 #include <dt-bindings/clock/amlogic,a4-scmi-clkc.h>
+#include <dt-bindings/clock/amlogic,a4-peripherals-clkc.h>
 
 / {
 	cpus {
@@ -83,6 +84,44 @@ scmi_clk: protocol@14 {
 };
 
 &apb {
+	clkc_periphs: clock-controller@0 {
+		compatible = "amlogic,a4-peripherals-clkc";
+		reg = <0x0 0x0 0x0 0x20c>;
+		#clock-cells = <1>;
+		clocks = <&xtal>,
+			 <&scmi_clk CLKID_OSC>,
+			 <&scmi_clk CLKID_FIXED_PLL>,
+			 <&scmi_clk CLKID_FCLK_DIV2>,
+			 <&scmi_clk CLKID_FCLK_DIV2P5>,
+			 <&scmi_clk CLKID_FCLK_DIV3>,
+			 <&scmi_clk CLKID_FCLK_DIV4>,
+			 <&scmi_clk CLKID_FCLK_DIV5>,
+			 <&scmi_clk CLKID_FCLK_DIV7>,
+			 <&clkc_pll CLKID_GP0_PLL>,
+			 <&scmi_clk CLKID_GP1_PLL>,
+			 <&clkc_pll CLKID_HIFI_PLL>,
+			 <&scmi_clk CLKID_SYS_CLK>,
+			 <&scmi_clk CLKID_AXI_CLK>,
+			 <&scmi_clk CLKID_SYS_PLL_DIV16>,
+			 <&scmi_clk CLKID_CPU_CLK_DIV16>;
+		clock-names = "xtal",
+			      "oscin",
+			      "fix",
+			      "fdiv2",
+			      "fdiv2p5",
+			      "fdiv3",
+			      "fdiv4",
+			      "fdiv5",
+			      "fdiv7",
+			      "gp0",
+			      "gp1",
+			      "hifi",
+			      "sysclk",s
+			      "axiclk",
+			      "sysplldiv16",
+			      "cpudiv16";
+	};
+
 	reset: reset-controller@2000 {
 		compatible = "amlogic,a4-reset",
 			     "amlogic,meson-s4-reset";

-- 
2.42.0

