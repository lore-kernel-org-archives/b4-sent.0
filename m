From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Mon, 07 Apr 2025 13:21:51 +0200
Subject: [PATCH v9 1/2] dt-bindings: pwm: add support for MC33XS2410
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250407-mc33xs2410-v9-1-57adcb56a6e4@liebherr.com>
References: <20250407-mc33xs2410-v9-0-57adcb56a6e4@liebherr.com>
In-Reply-To: <20250407-mc33xs2410-v9-0-57adcb56a6e4@liebherr.com>
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Dimitri Fedrau <dima.fedrau@gmail.com>
Cc: linux-pwm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 Dimitri Fedrau <dimitri.fedrau@liebherr.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744024920; l=3391;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=atZyh4aIY1QkrES663/EKCnuh1zQ/qQWrrz7fi0x2TM=;
 b=g5qpSEba1yYt+7zNqXRdVtdsPInXoGwJE79EZ+EHNrJOe5IHOnoVBYFxQPi9YBa82zJwItEzp
 uvH5hLdHzumBlCSITaEIMI/NpEtKDWv4gWoEFOIkePZMHzuFg4XX1nr
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adding documentation for NXPs MC33XS2410 high side switch.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 .../devicetree/bindings/pwm/nxp,mc33xs2410.yaml    | 118 +++++++++++++++++++++
 1 file changed, 118 insertions(+)

diff --git a/Documentation/devicetree/bindings/pwm/nxp,mc33xs2410.yaml b/Documentation/devicetree/bindings/pwm/nxp,mc33xs2410.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..1729fe5c3dfb0dae0006913899a3b901986f43ff
--- /dev/null
+++ b/Documentation/devicetree/bindings/pwm/nxp,mc33xs2410.yaml
@@ -0,0 +1,118 @@
+# SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/pwm/nxp,mc33xs2410.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: High-side switch MC33XS2410
+
+maintainers:
+  - Dimitri Fedrau <dima.fedrau@gmail.com>
+
+allOf:
+  - $ref: pwm.yaml#
+  - $ref: /schemas/spi/spi-peripheral-props.yaml#
+
+properties:
+  compatible:
+    const: nxp,mc33xs2410
+
+  reg:
+    maxItems: 1
+
+  spi-max-frequency:
+    maximum: 10000000
+
+  spi-cpha: true
+
+  spi-cs-setup-delay-ns:
+    minimum: 100
+    default: 100
+
+  spi-cs-hold-delay-ns:
+    minimum: 10
+    default: 10
+
+  spi-cs-inactive-delay-ns:
+    minimum: 300
+    default: 300
+
+  reset-gpios:
+    description:
+      GPIO connected to the active low reset pin.
+    maxItems: 1
+
+  "#pwm-cells":
+    const: 3
+
+  pwm-names:
+    items:
+      - const: di0
+      - const: di1
+      - const: di2
+      - const: di3
+
+  pwms:
+    description:
+      Direct inputs(di0-3) are used to directly turn-on or turn-off the
+      outputs.
+    maxItems: 4
+
+  interrupts:
+    maxItems: 1
+
+  clocks:
+    description:
+      The external clock can be used if the internal clock doesn't meet
+      timing requirements over temperature and voltage operating range.
+    maxItems: 1
+
+  vdd-supply:
+    description:
+      Logic supply voltage
+
+  vspi-supply:
+    description:
+      Supply voltage for SPI
+
+  vpwr-supply:
+    description:
+      Power switch supply
+
+required:
+  - compatible
+  - reg
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+    #include <dt-bindings/interrupt-controller/irq.h>
+    spi {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+       pwm@0 {
+           compatible = "nxp,mc33xs2410";
+           reg = <0x0>;
+           spi-max-frequency = <4000000>;
+           spi-cpha;
+           spi-cs-setup-delay-ns = <100>;
+           spi-cs-hold-delay-ns = <10>;
+           spi-cs-inactive-delay-ns = <300>;
+           reset-gpios = <&gpio3 22 GPIO_ACTIVE_LOW>;
+           #pwm-cells = <3>;
+           pwm-names = "di0", "di1", "di2", "di3";
+           pwms = <&pwm0 0 1000000>,
+                  <&pwm1 0 1000000>,
+                  <&pwm2 0 1000000>,
+                  <&pwm3 0 1000000>;
+           interrupt-parent = <&gpio0>;
+           interrupts = <31 IRQ_TYPE_LEVEL_LOW>;
+           clocks = <&clk_ext_fixed>;
+           vdd-supply = <&reg_3v3>;
+           vspi-supply = <&reg_3v3>;
+           vpwr-supply = <&reg_24v0>;
+       };
+    };

-- 
2.39.5

