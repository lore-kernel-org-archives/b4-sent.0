From: Janne Grunau <j@jannau.net>
Date: Tue, 03 Dec 2024 08:57:58 +0100
Subject: [PATCH v2 2/5] arm64: dts: apple: t8103: Add spi controller nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241203-asahi-spi-dt-v2-2-cd68bfaf0c84@jannau.net>
References: <20241203-asahi-spi-dt-v2-0-cd68bfaf0c84@jannau.net>
In-Reply-To: <20241203-asahi-spi-dt-v2-0-cd68bfaf0c84@jannau.net>
To: Hector Martin <marcan@marcan.st>, Sven Peter <sven@svenpeter.dev>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3632; i=j@jannau.net;
 s=yk2024; h=from:subject:message-id;
 bh=9MFJ0ZiYLZ8Qk0zHZWVIFqmiPpB2dmJwF7SezS0P754=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhnS/XVyOh+tNdlx0U+S8GPvusdbXNZwXHgglMFxhD3q+/
 NTt2w/EO0pZGMS4GGTFFFmStF92MKyuUYypfRAGM4eVCWQIAxenAExEPJfhf3nC44ld7R5hb698
 O5WTHdFteWlJLN8E85Ubr9k0f1fwvcTwi0lL3nRCJH+t4LNleYb/VI+pMat1qQvXrlkXdYOXXyq
 LHQA=
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/yk2024 with auth_id=264
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Apple silicon devices have one or more SPI devices. Add device tree
nodes for all known controllers. The missing ones could be guessed and
tested with a little effort but since the devices expose no pins and
no new devices are expected there is no point in spending the effort.
SPI is used for spi-nor and input devices like keyboard, trackpad,
touchscreen and fingerprint reader. Only the spi-nor flash has upstream
drivers. Support for it will be added in a following commit.

Reviewed-by: Neal Gompa <neal@gompa.dev>
Signed-off-by: Janne Grunau <j@jannau.net>
---
 arch/arm64/boot/dts/apple/t8103.dtsi | 76 ++++++++++++++++++++++++++++++++++++
 1 file changed, 76 insertions(+)

diff --git a/arch/arm64/boot/dts/apple/t8103.dtsi b/arch/arm64/boot/dts/apple/t8103.dtsi
index 9b0dad6b618444ac6b1c9735c50cccfc3965f947..c9b789a2ff7e1757930b3fc3682e734c1e4dbef9 100644
--- a/arch/arm64/boot/dts/apple/t8103.dtsi
+++ b/arch/arm64/boot/dts/apple/t8103.dtsi
@@ -326,6 +326,20 @@ clkref: clock-ref {
 		clock-output-names = "clkref";
 	};
 
+	clk_120m: clock-120m {
+		compatible = "fixed-clock";
+		#clock-cells = <0>;
+		clock-frequency = <120000000>;
+		clock-output-names = "clk_120m";
+	};
+
+	clk_200m: clock-200m {
+		compatible = "fixed-clock";
+		#clock-cells = <0>;
+		clock-frequency = <200000000>;
+		clock-output-names = "clk_200m";
+	};
+
 	/*
 	 * This is a fabulated representation of the input clock
 	 * to NCO since we don't know the true clock tree.
@@ -441,6 +455,48 @@ fpwm1: pwm@235044000 {
 			status = "disabled";
 		};
 
+		spi0: spi@235100000 {
+			compatible = "apple,t8103-spi", "apple,spi";
+			reg = <0x2 0x35100000 0x0 0x4000>;
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ 614 IRQ_TYPE_LEVEL_HIGH>;
+			clocks = <&clk_200m>;
+			pinctrl-0 = <&spi0_pins>;
+			pinctrl-names = "default";
+			power-domains = <&ps_spi0>;
+			#address-cells = <1>;
+			#size-cells = <0>;
+			status = "disabled";
+		};
+
+		spi1: spi@235104000 {
+			compatible = "apple,t8103-spi", "apple,spi";
+			reg = <0x2 0x35104000 0x0 0x4000>;
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ 615 IRQ_TYPE_LEVEL_HIGH>;
+			clocks = <&clk_200m>;
+			pinctrl-0 = <&spi1_pins>;
+			pinctrl-names = "default";
+			power-domains = <&ps_spi1>;
+			#address-cells = <1>;
+			#size-cells = <0>;
+			status = "disabled";
+		};
+
+		spi3: spi@23510c000 {
+			compatible = "apple,t8103-spi", "apple,spi";
+			reg = <0x2 0x3510c000 0x0 0x4000>;
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ 617 IRQ_TYPE_LEVEL_HIGH>;
+			clocks = <&clk_120m>;
+			pinctrl-0 = <&spi3_pins>;
+			pinctrl-names = "default";
+			power-domains = <&ps_spi3>;
+			#address-cells = <1>;
+			#size-cells = <0>;
+			status = "disabled";
+		};
+
 		serial0: serial@235200000 {
 			compatible = "apple,s5l-uart";
 			reg = <0x2 0x35200000 0x0 0x1000>;
@@ -597,6 +653,26 @@ i2c4_pins: i2c4-pins {
 					 <APPLE_PINMUX(134, 1)>;
 			};
 
+			spi0_pins: spi0-pins {
+				pinmux = <APPLE_PINMUX(67, 1)>, /* CLK */
+					<APPLE_PINMUX(68, 1)>,  /* MOSI */
+					<APPLE_PINMUX(69, 1)>;  /* MISO */
+			};
+
+			spi1_pins: spi1-pins {
+				pinmux = <APPLE_PINMUX(42, 1)>,
+					<APPLE_PINMUX(43, 1)>,
+					<APPLE_PINMUX(44, 1)>,
+					<APPLE_PINMUX(45, 1)>;
+			};
+
+			spi3_pins: spi3-pins {
+				pinmux = <APPLE_PINMUX(46, 1)>,
+					<APPLE_PINMUX(47, 1)>,
+					<APPLE_PINMUX(48, 1)>,
+					<APPLE_PINMUX(49, 1)>;
+			};
+
 			pcie_pins: pcie-pins {
 				pinmux = <APPLE_PINMUX(150, 1)>,
 					 <APPLE_PINMUX(151, 1)>,

-- 
2.47.0

