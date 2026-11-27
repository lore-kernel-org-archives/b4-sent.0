From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Fri, 27 Nov 2026 03:21:55 +0000
Subject: [PATCH v4 2/2] arm64: dts: amlogic: a9: Add IR controller support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-a9-ir-v4-2-820209515755@amlogic.com>
References: <20261127-a9-ir-v4-0-820209515755@amlogic.com>
In-Reply-To: <20261127-a9-ir-v4-0-820209515755@amlogic.com>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795749801; l=2083;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=uVqKmngtre8D85X97L1agM7jjiKqs/7e0xWwzs/gfjw=;
 b=+K2T/dxU12IDjRPhCyp4FqTfeEDcnFtAUxerdexWmDb4MIDSeHGdG2izoVSN4EDXDT5OIQRmP
 vFABSKbAIfNCQvN6hqw7jZUo02idScACEfSeXklb/qrz4tZsbMBBEpj
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the IR controller node for the Amlogic A9 SoC and describe the
corresponding remote input pin configuration.

Enable the IR controller on the Amlogic A9 A311Y3 BY401 board with the
proper pinctrl setting.

Reviewed-by: Neil Armstrong <neil.armstrong@linaro.org>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 arch/arm64/boot/dts/amlogic/amlogic-a9-a311y3-by401.dts |  6 ++++++
 arch/arm64/boot/dts/amlogic/amlogic-a9.dtsi             | 14 ++++++++++++++
 2 files changed, 20 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/amlogic-a9-a311y3-by401.dts b/arch/arm64/boot/dts/amlogic/amlogic-a9-a311y3-by401.dts
index a6b380ca47a5..389c9de3dc3c 100644
--- a/arch/arm64/boot/dts/amlogic/amlogic-a9-a311y3-by401.dts
+++ b/arch/arm64/boot/dts/amlogic/amlogic-a9-a311y3-by401.dts
@@ -38,3 +38,9 @@ secmon_reserved: secmon@5000000 {
 &uart_b {
 	status = "okay";
 };
+
+&ir {
+	status = "okay";
+	pinctrl-0 = <&remote_input_ao_pins>;
+	pinctrl-names = "default";
+};
diff --git a/arch/arm64/boot/dts/amlogic/amlogic-a9.dtsi b/arch/arm64/boot/dts/amlogic/amlogic-a9.dtsi
index 91f4cf319b0d..b1766ea57c2a 100644
--- a/arch/arm64/boot/dts/amlogic/amlogic-a9.dtsi
+++ b/arch/arm64/boot/dts/amlogic/amlogic-a9.dtsi
@@ -246,6 +246,13 @@ test_n: gpio@c0 {
 					#gpio-cells = <2>;
 					gpio-ranges = <&aobus_pinctrl 0 (AMLOGIC_GPIO_TEST_N<<8) 1>;
 				};
+
+				func-ir-in {
+					remote_input_ao_pins: group-remote-input-ao-pins {
+						pinmux = <AML_PINMUX(AMLOGIC_GPIO_D, 5, 1)>;
+						bias-disable;
+					};
+				};
 			};
 
 			gpio_ao_intc: interrupt-controller@4080 {
@@ -259,6 +266,13 @@ gpio_ao_intc: interrupt-controller@4080 {
 					394 395 396 397 398 399 400 401 402 403>;
 			};
 
+			ir: ir@14080 {
+				compatible = "amlogic,a9-ir", "amlogic,meson-s4-ir";
+				reg = <0x0 0x14080 0x0 0x30>;
+				interrupts = <GIC_SPI 413 IRQ_TYPE_EDGE_RISING>;
+				status = "disabled";
+			};
+
 			uart_b: serial@1e000 {
 				compatible = "amlogic,a9-uart",
 					     "amlogic,meson-s4-uart";

-- 
2.52.0

