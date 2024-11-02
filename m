From: Janne Grunau <j@jannau.net>
Date: Sat, 02 Nov 2024 12:34:23 +0100
Subject: [PATCH 4/5] arm64: dts: apple: t600x: Add spi controller nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241102-asahi-spi-dt-v1-4-7ac44c0a88f9@jannau.net>
References: <20241102-asahi-spi-dt-v1-0-7ac44c0a88f9@jannau.net>
In-Reply-To: <20241102-asahi-spi-dt-v1-0-7ac44c0a88f9@jannau.net>
To: Hector Martin <marcan@marcan.st>, Sven Peter <sven@svenpeter.dev>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Janne Grunau <j@jannau.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3545; i=j@jannau.net;
 s=yk2024; h=from:subject:message-id;
 bh=+9ZFqpJ8nwSbJAAJz7hiOfMfbrOzc9lBaAhTOBlh010=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhnQ1PttSvgvvgpYZsPw5X/f7gOnUebLcFxf13zjr7LNmq
 bu23JSojlIWBjEuBlkxRZYk7ZcdDKtrFGNqH4TBzGFlAhnCwMUpABM5kM7IsPfT483WK2r9/HLa
 Tri9dF3GqWYSUiifkuXQvc7r6tnAFYwMNyJ8XKIuXVm8Iy3x/SulnX6TtEofCkQ+b3xapaO2JTG
 IBwA=
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

Signed-off-by: Janne Grunau <j@jannau.net>
---
 arch/arm64/boot/dts/apple/t600x-common.dtsi    |  7 +++++++
 arch/arm64/boot/dts/apple/t600x-die0.dtsi      | 28 ++++++++++++++++++++++++++
 arch/arm64/boot/dts/apple/t600x-gpio-pins.dtsi | 14 +++++++++++++
 3 files changed, 49 insertions(+)

diff --git a/arch/arm64/boot/dts/apple/t600x-common.dtsi b/arch/arm64/boot/dts/apple/t600x-common.dtsi
index fa8ead69936366999786cdd4910266ee08b5ca7a..87dfc13d74171f62bf3087401918d9d41eaac560 100644
--- a/arch/arm64/boot/dts/apple/t600x-common.dtsi
+++ b/arch/arm64/boot/dts/apple/t600x-common.dtsi
@@ -362,6 +362,13 @@ clkref: clock-ref {
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
diff --git a/arch/arm64/boot/dts/apple/t600x-die0.dtsi b/arch/arm64/boot/dts/apple/t600x-die0.dtsi
index b1c875e692c8fb9c0af46a23568a7b0cd720141b..e9b3140ba1a996eeb91b3f60470833060b632bd2 100644
--- a/arch/arm64/boot/dts/apple/t600x-die0.dtsi
+++ b/arch/arm64/boot/dts/apple/t600x-die0.dtsi
@@ -163,6 +163,34 @@ i2c5: i2c@39b054000 {
 		status = "disabled";
 	};
 
+	spi1: spi@39b104000 {
+		compatible = "apple,t6000-spi", "apple,spi";
+		reg = <0x3 0x9b104000 0x0 0x4000>;
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_IRQ 0 1107 IRQ_TYPE_LEVEL_HIGH>;
+		#address-cells = <1>;
+		#size-cells = <0>;
+		clocks = <&clk_200m>;
+		pinctrl-0 = <&spi1_pins>;
+		pinctrl-names = "default";
+		power-domains = <&ps_spi1>;
+		status = "disabled";
+	};
+
+	spi3: spi@39b10c000 {
+		compatible = "apple,t6000-spi", "apple,spi";
+		reg = <0x3 0x9b10c000 0x0 0x4000>;
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_IRQ 0 1109 IRQ_TYPE_LEVEL_HIGH>;
+		#address-cells = <1>;
+		#size-cells = <0>;
+		clocks = <&clkref>;
+		pinctrl-0 = <&spi3_pins>;
+		pinctrl-names = "default";
+		power-domains = <&ps_spi3>;
+		status = "disabled";
+	};
+
 	serial0: serial@39b200000 {
 		compatible = "apple,s5l-uart";
 		reg = <0x3 0x9b200000 0x0 0x1000>;
diff --git a/arch/arm64/boot/dts/apple/t600x-gpio-pins.dtsi b/arch/arm64/boot/dts/apple/t600x-gpio-pins.dtsi
index b31f1a7a2b3fc36e7dfa480d27012d6d0fd56f97..1a994c3c1b79f088d685e13d1dc16e7d1e6546f4 100644
--- a/arch/arm64/boot/dts/apple/t600x-gpio-pins.dtsi
+++ b/arch/arm64/boot/dts/apple/t600x-gpio-pins.dtsi
@@ -36,6 +36,20 @@ i2c5_pins: i2c5-pins {
 			<APPLE_PINMUX(101, 1)>;
 	};
 
+	spi1_pins: spi1-pins {
+		pinmux = <APPLE_PINMUX(10, 1)>,
+			<APPLE_PINMUX(11, 1)>,
+			<APPLE_PINMUX(32, 1)>,
+			<APPLE_PINMUX(33, 1)>;
+	};
+
+	spi3_pins: spi3-pins {
+		pinmux = <APPLE_PINMUX(52, 1)>,
+			<APPLE_PINMUX(53, 1)>,
+			<APPLE_PINMUX(54, 1)>,
+			<APPLE_PINMUX(55, 1)>;
+	};
+
 	pcie_pins: pcie-pins {
 		pinmux = <APPLE_PINMUX(0, 1)>,
 				<APPLE_PINMUX(1, 1)>,

-- 
2.47.0

