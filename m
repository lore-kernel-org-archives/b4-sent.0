From: Ricardo Pardini <ricardo@pardini.net>
Date: Wed, 14 Jan 2026 23:48:37 +0100
Subject: [PATCH 2/2] arm64: dts: amlogic: add the type-c controller on
 Radxa Zero 2
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260114-arm64-dts-amlogic-radxa-zero2-additions-v1-2-8b5cdf328fde@pardini.net>
References: <20260114-arm64-dts-amlogic-radxa-zero2-additions-v1-0-8b5cdf328fde@pardini.net>
In-Reply-To: <20260114-arm64-dts-amlogic-radxa-zero2-additions-v1-0-8b5cdf328fde@pardini.net>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Ricardo Pardini <ricardo@pardini.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1485; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=zb/OKKB6zV/hhBZYiZyJobFT3XGfSbU/eSwN+6koa1Y=;
 b=owEBbQGS/pANAwAIATteP+Oex+3pAcsmYgBpaB1KlEhHDQdS0hwR9gCrhbZI2IMpaGlg0cHJM
 GAsqkn+BQuJATMEAAEIAB0WIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCaWgdSgAKCRA7Xj/jnsft
 6VpIB/48OQIO8h534tAeCE4rHGBpxfc6elGR0Nw/+vh6ua9H1f+NS6RtkgR/249vXrgzaPpq3DN
 O+POmf+VLSS+slNDVUmwVY1ev/2W4IqGR4jsKV6IzXycKBFm72uE8/93PRbfo/Bxavpl7SZAEQX
 2dtba8pz5t7nmyldBFZ5hFXxP39+O9yUnNDGLdbMGfrL3rV7nhZzhlCj4SollYHCFPD9TBCwXwX
 1QSTbbZWo7bh9+qLJRy03C9M8V4huPEMoun8KudEzPd3SKsxy3gSGBv2RPlPDcShaBzzGdVYD5a
 3+y+BmQkwNnpgJIwCWoPrg1ytk3BRSvc8o2SCBo3KhPZ+5o3
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Radxa Zero2 has an FUSB302 controller on i2c3 at address 0x22 and
INT# wired to GPIOA-13.

Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
 .../boot/dts/amlogic/meson-g12b-radxa-zero2.dts    | 32 ++++++++++++++++++++++
 1 file changed, 32 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/meson-g12b-radxa-zero2.dts b/arch/arm64/boot/dts/amlogic/meson-g12b-radxa-zero2.dts
index a37776d22b09e..125b064a15c1e 100644
--- a/arch/arm64/boot/dts/amlogic/meson-g12b-radxa-zero2.dts
+++ b/arch/arm64/boot/dts/amlogic/meson-g12b-radxa-zero2.dts
@@ -364,12 +364,44 @@ hdmi_tx_tmds_out: endpoint {
 	};
 };
 
+/* Also exposed on the 40-pin header: SDA pin 3, SCL pin 5 */
+&i2c3 {
+	pinctrl-0 = <&i2c3_sda_a_pins>, <&i2c3_sck_a_pins>;
+	pinctrl-names = "default";
+	status = "okay";
+
+	fusb302@22 {
+		compatible = "fcs,fusb302";
+		reg = <0x22>;
+
+		pinctrl-0 = <&fusb302_irq_pins>;
+		pinctrl-names = "default";
+		interrupt-parent = <&gpio_intc>;
+		interrupts = <13 IRQ_TYPE_LEVEL_LOW>;
+
+		vbus-supply = <&ao_5v>;
+
+		status = "okay";
+	};
+};
+
 &ir {
 	status = "disabled";
 	pinctrl-0 = <&remote_input_ao_pins>;
 	pinctrl-names = "default";
 };
 
+&periphs_pinctrl {
+	fusb302_irq_pins: fusb302-irq {
+		mux {
+			groups = "GPIOA_13";
+			function = "gpio_periphs";
+			bias-pull-up;
+			output-disable;
+		};
+	};
+};
+
 &pwm_ab {
 	pinctrl-0 = <&pwm_a_e_pins>;
 	pinctrl-names = "default";

-- 
2.52.0

