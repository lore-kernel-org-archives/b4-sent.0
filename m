From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Date: Sun, 12 Jan 2025 19:41:34 +0100
Subject: [PATCH v3 3/4] arm64: dts: apple: Add touchbar digitizer nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250112-z2-v3-3-5c0e555d3df1@gmail.com>
References: <20250112-z2-v3-0-5c0e555d3df1@gmail.com>
In-Reply-To: <20250112-z2-v3-0-5c0e555d3df1@gmail.com>
To: Hector Martin <marcan@marcan.st>, Sven Peter <sven@svenpeter.dev>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Henrik Rydberg <rydberg@bitmath.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sasha Finkelstein <fnkl.kernel@gmail.com>, 
 Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1736707300; l=5193;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=1gxPgxCLDO2GbcY7Z6AYrb9Le2GWgwKoXaZMJOLVIKw=;
 b=HUGMH7aP21h8qDh+FBLQ61xTW/QMB1FW9YnFvswbKXAxhZ7UTz5rHL+qUKNlu9kSQW8EdUlbK
 mnT3jBbXPXnDpIr3ySNp5D7nABOa31UPp2naVmEjiQArGMx+nBBK9P3
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=aSkp1PdZ+eF4jpMO6oLvz/YfT5XkBUneWwyhQrOgmsU=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20241124 with auth_id=283
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds device tree entries for the touchbar digitizer

Co-developed-by: Janne Grunau <j@jannau.net>
Signed-off-by: Janne Grunau <j@jannau.net>
Reviewed-by: Neal Gompa <neal@gompa.dev>
Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
 arch/arm64/boot/dts/apple/t8103-j293.dts | 27 +++++++++++++++++++++++++++
 arch/arm64/boot/dts/apple/t8103.dtsi     | 19 +++++++++++++++++++
 arch/arm64/boot/dts/apple/t8112-j493.dts | 23 +++++++++++++++++++++++
 arch/arm64/boot/dts/apple/t8112.dtsi     | 14 ++++++++++++++
 4 files changed, 83 insertions(+)

diff --git a/arch/arm64/boot/dts/apple/t8103-j293.dts b/arch/arm64/boot/dts/apple/t8103-j293.dts
index 56b0c67bfcda321b60c621de092643017693ff91..0a93d3891c23da8b8c77dce64001caacb69ee140 100644
--- a/arch/arm64/boot/dts/apple/t8103-j293.dts
+++ b/arch/arm64/boot/dts/apple/t8103-j293.dts
@@ -17,6 +17,14 @@ / {
 	compatible = "apple,j293", "apple,t8103", "apple,arm-platform";
 	model = "Apple MacBook Pro (13-inch, M1, 2020)";
 
+	/*
+	 * All of those are used by the bootloader to pass calibration
+	 * blobs and other device-specific properties
+	 */
+	aliases {
+		touchbar0 = &touchbar0;
+	};
+
 	led-controller {
 		compatible = "pwm-leds";
 		led-0 {
@@ -49,3 +57,22 @@ &i2c4 {
 &fpwm1 {
 	status = "okay";
 };
+
+&spi0 {
+	cs-gpios = <&pinctrl_ap 109 GPIO_ACTIVE_LOW>;
+	status = "okay";
+
+	touchbar0: touchbar@0 {
+		compatible = "apple,j293-touchbar";
+		reg = <0>;
+		spi-max-frequency = <11500000>;
+		spi-cs-setup-delay-ns = <2000>;
+		spi-cs-hold-delay-ns = <2000>;
+		reset-gpios = <&pinctrl_ap 139 GPIO_ACTIVE_LOW>;
+		interrupts-extended = <&pinctrl_ap 194 IRQ_TYPE_EDGE_FALLING>;
+		firmware-name = "apple/dfrmtfw-j293.bin";
+		touchscreen-size-x = <23045>;
+		touchscreen-size-y = <640>;
+		touchscreen-inverted-y;
+	};
+};
diff --git a/arch/arm64/boot/dts/apple/t8103.dtsi b/arch/arm64/boot/dts/apple/t8103.dtsi
index 9b0dad6b618444ac6b1c9735c50cccfc3965f947..dc72aae3844bf33579f623f0b01abc7de4033af4 100644
--- a/arch/arm64/boot/dts/apple/t8103.dtsi
+++ b/arch/arm64/boot/dts/apple/t8103.dtsi
@@ -326,6 +326,13 @@ clkref: clock-ref {
 		clock-output-names = "clkref";
 	};
 
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
@@ -441,6 +448,18 @@ fpwm1: pwm@235044000 {
 			status = "disabled";
 		};
 
+		spi0: spi@235100000 {
+			compatible = "apple,t8103-spi", "apple,spi";
+			reg = <0x2 0x35100000 0x0 0x4000>;
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ 614 IRQ_TYPE_LEVEL_HIGH>;
+			clocks = <&clk_200m>;
+			power-domains = <&ps_spi0>;
+			#address-cells = <1>;
+			#size-cells = <0>;
+			status = "disabled"; /* only used in J293 */
+		};
+
 		serial0: serial@235200000 {
 			compatible = "apple,s5l-uart";
 			reg = <0x2 0x35200000 0x0 0x1000>;
diff --git a/arch/arm64/boot/dts/apple/t8112-j493.dts b/arch/arm64/boot/dts/apple/t8112-j493.dts
index 0ad908349f55406783942735a2e9dad54cda00ec..045bd0716cb7d20c1379ebc1e3ff7f4d0dddc179 100644
--- a/arch/arm64/boot/dts/apple/t8112-j493.dts
+++ b/arch/arm64/boot/dts/apple/t8112-j493.dts
@@ -17,8 +17,13 @@ / {
 	compatible = "apple,j493", "apple,t8112", "apple,arm-platform";
 	model = "Apple MacBook Pro (13-inch, M2, 2022)";
 
+	/*
+	 * All of those are used by the bootloader to pass calibration
+	 * blobs and other device-specific properties
+	 */
 	aliases {
 		bluetooth0 = &bluetooth0;
+		touchbar0 = &touchbar0;
 		wifi0 = &wifi0;
 	};
 
@@ -67,3 +72,21 @@ &i2c4 {
 &fpwm1 {
 	status = "okay";
 };
+
+&spi3 {
+	status = "okay";
+
+	touchbar0: touchbar@0 {
+		compatible = "apple,j493-touchbar";
+		reg = <0>;
+		spi-max-frequency = <8000000>;
+		spi-cs-setup-delay-ns = <2000>;
+		spi-cs-hold-delay-ns = <2000>;
+		reset-gpios = <&pinctrl_ap 170 GPIO_ACTIVE_LOW>;
+		interrupts-extended = <&pinctrl_ap 174 IRQ_TYPE_EDGE_FALLING>;
+		firmware-name = "apple/dfrmtfw-j493.bin";
+		touchscreen-size-x = <23045>;
+		touchscreen-size-y = <640>;
+		touchscreen-inverted-y;
+	};
+};
diff --git a/arch/arm64/boot/dts/apple/t8112.dtsi b/arch/arm64/boot/dts/apple/t8112.dtsi
index 1666e6ab250bc0be9b8318e3c8fc903ccd3f3760..bb6c9e769c65330a32a3c7aa2f074c1f63e195fd 100644
--- a/arch/arm64/boot/dts/apple/t8112.dtsi
+++ b/arch/arm64/boot/dts/apple/t8112.dtsi
@@ -467,6 +467,20 @@ fpwm1: pwm@235044000 {
 			status = "disabled";
 		};
 
+		spi3: spi@23510c000 {
+			compatible = "apple,t8112-spi", "apple,spi";
+			reg = <0x2 0x3510c000 0x0 0x4000>;
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ 751 IRQ_TYPE_LEVEL_HIGH>;
+			clocks = <&clkref>;
+			pinctrl-0 = <&spi3_pins>;
+			pinctrl-names = "default";
+			power-domains = <&ps_spi3>;
+			#address-cells = <1>;
+			#size-cells = <0>;
+			status = "disabled"; /* only used in J493 */
+		};
+
 		serial0: serial@235200000 {
 			compatible = "apple,s5l-uart";
 			reg = <0x2 0x35200000 0x0 0x1000>;

-- 
2.48.0

