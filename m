From: Chuan Liu <chuan.liu@amlogic.com>
Date: Tue, 30 Sep 2025 17:37:32 +0800
Subject: [PATCH 19/19] arm64: dts: amlogic: A5: Add peripheral clock
 controller node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250930-a4_a5_add_clock_driver-v1-19-a9acf7951589@amlogic.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759225047; l=2041;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=819hwcypvLPkK6zGwB1cqKbMQOi/dUvVkIknKgOKBPA=;
 b=Yxou6e6o7eYaQX7ea8PxyQS46pJ+jtcK7m1onlU0UwXsX3ttMyz3/Ts2jBPl6HRVxH7dcdASr
 d+p/EnVQbr/DBmqr7SkjrupsjApzN85QilFbyXdufDKtY5IGcEaCJDv
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add peripheral clock controller node for A5 SoC family.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi | 43 +++++++++++++++++++++++++++++
 1 file changed, 43 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi b/arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi
index 89f7b5ff4ea3..406cd52a6474 100644
--- a/arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi
+++ b/arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi
@@ -8,6 +8,7 @@
 #include <dt-bindings/power/amlogic,a5-pwrc.h>
 #include <dt-bindings/clock/amlogic,a5-scmi-clkc.h>
 #include <dt-bindings/clock/amlogic,a5-pll-clkc.h>
+#include <dt-bindings/clock/amlogic,a5-peripherals-clkc.h>
 
 / {
 	cpus {
@@ -83,6 +84,48 @@ scmi_clk: protocol@14 {
 };
 
 &apb {
+	clkc_periphs: clock-controller@0 {
+		compatible = "amlogic,a5-peripherals-clkc";
+		reg = <0x0 0x0 0x0 0x224>;
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
+			 <&clkc_pll CLKID_MPLL2>,
+			 <&clkc_pll CLKID_MPLL3>,
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
+			      "mpll2",
+			      "mpll3",
+			      "gp0",
+			      "gp1",
+			      "hifi",
+			      "sysclk",
+			      "axiclk",
+			      "sysplldiv16",
+			      "cpudiv16";
+	};
+
 	reset: reset-controller@2000 {
 		compatible = "amlogic,a5-reset",
 			     "amlogic,meson-s4-reset";

-- 
2.42.0

