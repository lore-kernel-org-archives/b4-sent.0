From: Sai Sree Kartheek Adivi <s-adivi@ti.com>
Date: Tue, 24 Nov 2026 19:30:48 +0530
Subject: [PATCH] arm64: dts: ti: k3-am625-sk-common: Add TPIC2810 LED
 expander support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-am62x-tpic2810-v1-1-2b9fcb76a3c3@ti.com>
X-B4-Tracking: v=1; b=H4sIAI+YBWsC/x3MQQqAIBBA0avErBNyKJGuEi1Gm2oWWWiEIN09a
 fkW/xdIHIUTjE2ByI8kOUOFbhvwO4WNlSzVgB0arbFXdBjM6r7Eo9WdGsg6dotxZA3U6Iq8Sv6
 H0/y+HwQaJ2BgAAAA
X-Change-ID: 20261124-am62x-tpic2810-5a8bebd6ba86
To: Nishanth Menon <nm@ti.com>, Vignesh Raghavendra <vigneshr@ti.com>, 
 Tero Kristo <kristo@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sebin Francis <sebin.francis@ti.com>, 
 Sai Sree Kartheek Adivi <s-adivi@ti.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795528855; l=3619;
 i=s-adivi@ti.com; s=20261124; h=from:subject:message-id;
 bh=/kJ/e4Uy/UPyHeMJ7jIEfjC0cSg4x5LGcObEFevGZNY=;
 b=x5aVq+vkKXct/6HmiNcrxjs/5fzPvK2EOk+DZo8nFvXPs7JJ/RuAYk/0Iwy/C5sEYPgxl4Zgs
 6CFUCTX+ilgAyO5ophtdXnr7bJF+E4SVU7I0B3PVNpTRNYoku0M5nfE
X-Developer-Key: i=s-adivi@ti.com; a=ed25519;
 pk=EtOwVxmXDuYMgw3DqFtPDBpf8ZvbO89w1fJm4w5yPI8=
X-Endpoint-Received: by B4 Relay for s-adivi@ti.com/20261124 with auth_id=1627
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The AM625 SK and AM62x SIP SK EVMs both have a TPIC2810 I2C GPIO
expander at address 0x60 on WKUP_I2C0, driving 8 user LEDs. Describe it
in the shared k3-am625-sk-common.dtsi, mirroring the AM642 SK support:

- add the WKUP_I2C0 pinmux
- enable wkup_i2c0 with the TPIC2810 node
- add a gpio-leds node for the 8 outputs

CONFIG_GPIO_TPIC2810 is already enabled in the arm64 defconfig.

Signed-off-by: Sai Sree Kartheek Adivi <s-adivi@ti.com>
---
 arch/arm64/boot/dts/ti/k3-am625-sk-common.dtsi | 93 ++++++++++++++++++++++++++
 1 file changed, 93 insertions(+)

diff --git a/arch/arm64/boot/dts/ti/k3-am625-sk-common.dtsi b/arch/arm64/boot/dts/ti/k3-am625-sk-common.dtsi
index 8e07d2c2e62fd..7d5b16568aa9c 100644
--- a/arch/arm64/boot/dts/ti/k3-am625-sk-common.dtsi
+++ b/arch/arm64/boot/dts/ti/k3-am625-sk-common.dtsi
@@ -91,6 +91,74 @@ vcc_1v8: regulator-5 {
 		regulator-always-on;
 		regulator-boot-on;
 	};
+
+	led-controller {
+		compatible = "gpio-leds";
+
+		led-0 {
+			color = <LED_COLOR_ID_GREEN>;
+			function = LED_FUNCTION_INDICATOR;
+			function-enumerator = <1>;
+			gpios = <&exp2 0 GPIO_ACTIVE_HIGH>;
+			default-state = "off";
+		};
+
+		led-1 {
+			color = <LED_COLOR_ID_RED>;
+			function = LED_FUNCTION_INDICATOR;
+			function-enumerator = <2>;
+			gpios = <&exp2 1 GPIO_ACTIVE_HIGH>;
+			default-state = "off";
+		};
+
+		led-2 {
+			color = <LED_COLOR_ID_GREEN>;
+			function = LED_FUNCTION_INDICATOR;
+			function-enumerator = <3>;
+			gpios = <&exp2 2 GPIO_ACTIVE_HIGH>;
+			default-state = "off";
+		};
+
+		led-3 {
+			color = <LED_COLOR_ID_AMBER>;
+			function = LED_FUNCTION_INDICATOR;
+			function-enumerator = <4>;
+			gpios = <&exp2 3 GPIO_ACTIVE_HIGH>;
+			default-state = "off";
+		};
+
+		led-4 {
+			color = <LED_COLOR_ID_GREEN>;
+			function = LED_FUNCTION_INDICATOR;
+			function-enumerator = <5>;
+			gpios = <&exp2 4 GPIO_ACTIVE_HIGH>;
+			default-state = "off";
+		};
+
+		led-5 {
+			color = <LED_COLOR_ID_RED>;
+			function = LED_FUNCTION_INDICATOR;
+			function-enumerator = <6>;
+			gpios = <&exp2 5 GPIO_ACTIVE_HIGH>;
+			default-state = "off";
+		};
+
+		led-6 {
+			color = <LED_COLOR_ID_GREEN>;
+			function = LED_FUNCTION_INDICATOR;
+			function-enumerator = <7>;
+			gpios = <&exp2 6 GPIO_ACTIVE_HIGH>;
+			default-state = "off";
+		};
+
+		led-7 {
+			color = <LED_COLOR_ID_AMBER>;
+			function = LED_FUNCTION_HEARTBEAT;
+			function-enumerator = <8>;
+			linux,default-trigger = "heartbeat";
+			gpios = <&exp2 7 GPIO_ACTIVE_HIGH>;
+		};
+	};
 };
 
 &main_pmx0 {
@@ -160,6 +228,15 @@ AM62X_IOPAD(0x01d4, PIN_INPUT, 7) /* (B15) UART0_RTSn.GPIO1_23 */
 	};
 };
 
+&mcu_pmx0 {
+	tpic_pins_default: tpic-default-pins {
+		pinctrl-single,pins = <
+			AM62X_MCU_IOPAD(0x004c, PIN_INPUT, 0) /* (B9) WKUP_I2C0_SCL */
+			AM62X_MCU_IOPAD(0x0050, PIN_INPUT, 0) /* (A9) WKUP_I2C0_SDA */
+		>;
+	};
+};
+
 &main_gpio0 {
 	bootph-all;
 };
@@ -196,6 +273,22 @@ exp1: gpio@22 {
 	};
 };
 
+&wkup_i2c0 {
+	status = "okay";
+	pinctrl-names = "default";
+	pinctrl-0 = <&tpic_pins_default>;
+	clock-frequency = <400000>;
+
+	exp2: gpio@60 {
+		compatible = "ti,tpic2810";
+		reg = <0x60>;
+		gpio-controller;
+		#gpio-cells = <2>;
+		gpio-line-names = "LED0", "LED1", "LED2", "LED3",
+				   "LED4", "LED5", "LED6", "LED7";
+	};
+};
+
 &sdhci0 {
 	bootph-all;
 	non-removable;

---
base-commit: 566085204d669ed4bd0d8d230b10f94f963e2481
change-id: 20261124-am62x-tpic2810-5a8bebd6ba86

Best regards,
--  
Sai Sree Kartheek Adivi <s-adivi@ti.com>

