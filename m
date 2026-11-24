From: Sai Sree Kartheek Adivi <s-adivi@ti.com>
Date: Tue, 24 Nov 2026 22:52:40 +0530
Subject: [PATCH v2] arm64: dts: ti: k3-am625-sk-common: Add TPIC2810 LED
 expander support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-am62x-tpic2810-v2-1-91115ba8e2dd@ti.com>
X-B4-Tracking: v=1; b=H4sIAN/HBWsC/3XMQQ7CIBCF4as0s3ZMmSqiK+9hugBK7SxaGiCkp
 uHuYvcu/5e8b4foArsIj2aH4DJH9ksNOjVgJ728HfJQG6glKQRdUM+SNkwrW1KixatWxplBGq0
 k1NMa3MjbAb762hPH5MPn8LP4rX+pLFAgmftozU3qznbPxGfrZ+hLKV8nbhlFqQAAAA==
X-Change-ID: 20261124-am62x-tpic2810-5a8bebd6ba86
To: Nishanth Menon <nm@ti.com>, Vignesh Raghavendra <vigneshr@ti.com>, 
 Tero Kristo <kristo@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sebin Francis <sebin.francis@ti.com>, 
 Sai Sree Kartheek Adivi <s-adivi@ti.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795540969; l=4368;
 i=s-adivi@ti.com; s=20261124; h=from:subject:message-id;
 bh=ehVtq9ntD1a3UcuBE08CQeJf9PzsTkL2oMpSs6MAAtc=;
 b=tBbLfdDuHaobWR9sYvDmPJd8Y0sruMmEsKnGSRj8AH65Ihz+nauwVaoUUMNTGZFUQQ9JIYtpa
 tpTkypliMtoBqF47rJgMoM2WVdVm6nxrVC1vaP7NCsByHSaOXW5a29G
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
Changes in v2:
- Fix dt-check-style warnings: move led-controller before opp-table,
  reorder properties, fix alignment
- Pinmux alignment/line-length warning left as is, to match the existing
  style of the file
- Link to v1: https://serenity.dal.design.ti.com/lore/linux-patch-review/20261124-am62x-tpic2810-v1-1-2b9fcb76a3c3@ti.com

Cc: linux-arm-kernel@lists.infradead.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
To: Nishanth Menon <nm@ti.com>
To: Vignesh Raghavendra <vigneshr@ti.com>
To: Tero Kristo <kristo@kernel.org>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
---
 arch/arm64/boot/dts/ti/k3-am625-sk-common.dtsi | 94 ++++++++++++++++++++++++++
 1 file changed, 94 insertions(+)

diff --git a/arch/arm64/boot/dts/ti/k3-am625-sk-common.dtsi b/arch/arm64/boot/dts/ti/k3-am625-sk-common.dtsi
index 8e07d2c2e62fd..2d2b82b0de8ad 100644
--- a/arch/arm64/boot/dts/ti/k3-am625-sk-common.dtsi
+++ b/arch/arm64/boot/dts/ti/k3-am625-sk-common.dtsi
@@ -8,6 +8,74 @@
 #include "k3-am62x-sk-common.dtsi"
 
 / {
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
+			gpios = <&exp2 7 GPIO_ACTIVE_HIGH>;
+			linux,default-trigger = "heartbeat";
+		};
+	};
+
 	opp-table {
 		/* Add 1.4GHz OPP for am625-sk board. Requires VDD_CORE to be at 0.85V */
 		opp-1400000000 {
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
@@ -196,6 +273,23 @@ exp1: gpio@22 {
 	};
 };
 
+&wkup_i2c0 {
+	clock-frequency = <400000>;
+	pinctrl-0 = <&tpic_pins_default>;
+	pinctrl-names = "default";
+
+	status = "okay";
+
+	exp2: gpio@60 {
+		compatible = "ti,tpic2810";
+		reg = <0x60>;
+		gpio-controller;
+		#gpio-cells = <2>;
+		gpio-line-names = "LED0", "LED1", "LED2", "LED3",
+				  "LED4", "LED5", "LED6", "LED7";
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

