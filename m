From: Cristian Cozzolino <cristian_ci@protonmail.com>
Date: Sat, 20 Sep 2025 20:23:29 +0200
Subject: [PATCH 04/10] ARM: dts: mediatek: mt6582: sort nodes and
 properties
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250920-mt6582-v1-4-b887720f577d@protonmail.com>
References: <20250920-mt6582-v1-0-b887720f577d@protonmail.com>
In-Reply-To: <20250920-mt6582-v1-0-b887720f577d@protonmail.com>
To: Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Russell King <linux@armlinux.org.uk>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sean Wang <sean.wang@mediatek.com>
Cc: linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, devicetree@vger.kernel.org, 
 phone-devel@vger.kernel.org, 
 Cristian Cozzolino <cristian_ci@protonmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758392693; l=3996;
 i=cristian_ci@protonmail.com; s=20250620; h=from:subject:message-id;
 bh=Z1S2PzSFTRUHdm6e5KvQH8f0VJGVi1iLBc3KX94/HbU=;
 b=FQWueJz6fpe77OaZh5ItLntT/nNPCZOu63nJSRYJV7jq1NjhxWRXdvUnJxw9UR4CUIP3IznxY
 UHp1qlhmqfVCmY0/5UixAQOQI4bbNxzXkG2hfTt/7J2KCsgnT8JYP8a
X-Developer-Key: i=cristian_ci@protonmail.com; a=ed25519;
 pk=xH5IvIPUNHV1Q8R0/pq2CfuVFR/wTiAyuyi6IwedjZY=
X-Endpoint-Received: by B4 Relay for cristian_ci@protonmail.com/20250620 with auth_id=438
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Sort fixed clocks nodes by clock frequency and memory mapped device
nodes by reg address. Also, sort properties as shown in dt-bindings
examples.

Signed-off-by: Cristian Cozzolino <cristian_ci@protonmail.com>
---
 arch/arm/boot/dts/mediatek/mt6582.dtsi | 46 +++++++++++++++-------------------
 1 file changed, 20 insertions(+), 26 deletions(-)

diff --git a/arch/arm/boot/dts/mediatek/mt6582.dtsi b/arch/arm/boot/dts/mediatek/mt6582.dtsi
index 37d2b8786188aecb65c0a6e0d31aabc3b66e2bd7..8ada8c6518661509ebee647367064187f4376ab9 100644
--- a/arch/arm/boot/dts/mediatek/mt6582.dtsi
+++ b/arch/arm/boot/dts/mediatek/mt6582.dtsi
@@ -13,8 +13,8 @@ / {
 	interrupt-parent = <&sysirq>;
 
 	cpus {
-		#address-cells = <1>;
 		#size-cells = <0>;
+		#address-cells = <1>;
 
 		cpu@0 {
 			device_type = "cpu";
@@ -38,22 +38,22 @@ cpu@3 {
 		};
 	};
 
-	system_clk: dummy13m {
+	uart_clk: dummy26m {
 		compatible = "fixed-clock";
-		clock-frequency = <13000000>;
 		#clock-cells = <0>;
+		clock-frequency = <26000000>;
 	};
 
-	rtc_clk: dummy32k {
+	system_clk: dummy13m {
 		compatible = "fixed-clock";
-		clock-frequency = <32000>;
 		#clock-cells = <0>;
+		clock-frequency = <13000000>;
 	};
 
-	uart_clk: dummy26m {
+	rtc_clk: dummy32k {
 		compatible = "fixed-clock";
-		clock-frequency = <26000000>;
 		#clock-cells = <0>;
+		clock-frequency = <32000>;
 	};
 
 	soc {
@@ -62,6 +62,11 @@ soc {
 		compatible = "simple-bus";
 		ranges;
 
+		watchdog: watchdog@10007000 {
+			compatible = "mediatek,mt6582-wdt", "mediatek,mt6589-wdt";
+			reg = <0x10007000 0x100>;
+		};
+
 		timer: timer@11008000 {
 			compatible = "mediatek,mt6577-timer";
 			reg = <0x10008000 0x80>;
@@ -71,18 +76,17 @@ timer: timer@11008000 {
 		};
 
 		sysirq: interrupt-controller@10200100 {
-			compatible = "mediatek,mt6582-sysirq",
-				     "mediatek,mt6577-sysirq";
+			compatible = "mediatek,mt6582-sysirq", "mediatek,mt6577-sysirq";
+			reg = <0x10200100 0x1c>;
+			interrupt-parent = <&gic>;
 			interrupt-controller;
 			#interrupt-cells = <3>;
-			interrupt-parent = <&gic>;
-			reg = <0x10200100 0x1c>;
 		};
 
 		gic: interrupt-controller@10211000 {
 			compatible = "arm,cortex-a7-gic";
-			interrupt-controller;
 			#interrupt-cells = <3>;
+			interrupt-controller;
 			interrupt-parent = <&gic>;
 			reg = <0x10211000 0x1000>,
 			      <0x10212000 0x2000>,
@@ -91,8 +95,7 @@ gic: interrupt-controller@10211000 {
 		};
 
 		uart0: serial@11002000 {
-			compatible = "mediatek,mt6582-uart",
-				     "mediatek,mt6577-uart";
+			compatible = "mediatek,mt6582-uart", "mediatek,mt6577-uart";
 			reg = <0x11002000 0x400>;
 			interrupts = <GIC_SPI 51 IRQ_TYPE_LEVEL_LOW>;
 			clocks = <&uart_clk>;
@@ -100,8 +103,7 @@ uart0: serial@11002000 {
 		};
 
 		uart1: serial@11003000 {
-			compatible = "mediatek,mt6582-uart",
-				     "mediatek,mt6577-uart";
+			compatible = "mediatek,mt6582-uart", "mediatek,mt6577-uart";
 			reg = <0x11003000 0x400>;
 			interrupts = <GIC_SPI 52 IRQ_TYPE_LEVEL_LOW>;
 			clocks = <&uart_clk>;
@@ -109,8 +111,7 @@ uart1: serial@11003000 {
 		};
 
 		uart2: serial@11004000 {
-			compatible = "mediatek,mt6582-uart",
-				     "mediatek,mt6577-uart";
+			compatible = "mediatek,mt6582-uart", "mediatek,mt6577-uart";
 			reg = <0x11004000 0x400>;
 			interrupts = <GIC_SPI 53 IRQ_TYPE_LEVEL_LOW>;
 			clocks = <&uart_clk>;
@@ -118,18 +119,11 @@ uart2: serial@11004000 {
 		};
 
 		uart3: serial@11005000 {
-			compatible = "mediatek,mt6582-uart",
-				     "mediatek,mt6577-uart";
+			compatible = "mediatek,mt6582-uart", "mediatek,mt6577-uart";
 			reg = <0x11005000 0x400>;
 			interrupts = <GIC_SPI 54 IRQ_TYPE_LEVEL_LOW>;
 			clocks = <&uart_clk>;
 			status = "disabled";
 		};
-
-		watchdog: watchdog@10007000 {
-			compatible = "mediatek,mt6582-wdt",
-				     "mediatek,mt6589-wdt";
-			reg = <0x10007000 0x100>;
-		};
 	};
 };

-- 
2.49.0

