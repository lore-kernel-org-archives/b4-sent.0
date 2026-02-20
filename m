From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Fri, 20 Feb 2026 16:46:05 +0000
Subject: [PATCH RFC 1/8] dt-bindings: iio: frequency: add ad9910
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260220-ad9910-iio-driver-v1-1-3b264aa48a10@analog.com>
References: <20260220-ad9910-iio-driver-v1-0-3b264aa48a10@analog.com>
In-Reply-To: <20260220-ad9910-iio-driver-v1-0-3b264aa48a10@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771605986; l=8500;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=z//Z0l3LpZmXPafUE4JJ++VbXBpuP6Jb0ARDmbbi/9Y=;
 b=tMM1fBTnwN259oS02qmc1e9qaBf5eMxapoOfk4WKZ53XsXIq+5YpsFYSjJnoeOBwK9Ns1h9KH
 h6bGCA/6dJBAdyzA2s5KuTs3ndqq9rhkMZbhymgpDmZj14pknWgsxYq
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

DT-bindings for AD9910, a 1 GSPS DDS with 14-bit DAC. It includes
configurations for the reference clock path, DAC current, reset and basic
GPIO control.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 .../bindings/iio/frequency/adi,ad9910.yaml         | 236 +++++++++++++++++++++
 MAINTAINERS                                        |   7 +
 2 files changed, 243 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/frequency/adi,ad9910.yaml b/Documentation/devicetree/bindings/iio/frequency/adi,ad9910.yaml
new file mode 100644
index 000000000000..43b21d1428ba
--- /dev/null
+++ b/Documentation/devicetree/bindings/iio/frequency/adi,ad9910.yaml
@@ -0,0 +1,236 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/iio/frequency/adi,ad9910.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Analog Devices AD9910 Direct Digital Synthesizer
+
+maintainers:
+  - Rodrigo Alencar <rodrigo.alencar@analog.com>
+
+description:
+  The AD9910 is a 1 GSPS direct digital synthesizer (DDS) with an integrated
+  14-bit DAC. It features single tone mode with 8 configurable profiles,
+  a digital ramp generator, RAM control, OSK, and a parallel data port for
+  high-speed streaming.
+
+  https://www.analog.com/en/products/ad9910.html
+
+properties:
+  compatible:
+    const: adi,ad9910
+
+  reg:
+    maxItems: 1
+
+  spi-max-frequency:
+    maximum: 70000000
+
+  clocks:
+    maxItems: 1
+    description:
+      Reference clock input (REFCLK). When the PLL is enabled, this is
+      multiplied by adi,pll-multiplier to produce the system clock.
+      When the PLL is bypassed, the reference clock is used directly or divided
+      by 2 based on adi,reference-div2-enable to produce the system clock.
+
+  dvdd-io33-supply:
+    description: 3.3V Digital I/O supply.
+
+  avdd33-supply:
+    description: 3.3V Analog DAC supply.
+
+  dvdd18-supply:
+    description: 1.8V Digital Core supply.
+
+  avdd18-supply:
+    description: 1.8V Analog Core supply.
+
+  resets:
+    minItems: 1
+    maxItems: 2
+
+  reset-names:
+    oneOf:
+      - items:
+          - const: dev
+      - items:
+          - const: dev
+          - const: io
+
+  reset-gpios:
+    maxItems: 2
+    description:
+      GPIOs controlling the device reset and the I/O_RESET pins. This is only
+      used if resets property is not defined.
+
+  powerdown-gpios:
+    maxItems: 1
+    description:
+      GPIO controlling the EXT_PWR_DWN pin.
+
+  update-gpios:
+    maxItems: 1
+    description:
+      GPIO controlling the I/O_UPDATE pin.
+
+  profile-gpios:
+    minItems: 3
+    maxItems: 3
+    description:
+      GPIOs controlling the PROFILE[2:0] pins for profile selection.
+
+  adi,pll-multiplier:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    minimum: 12
+    maximum: 127
+    description:
+      PLL feedback divider value (N). The system clock frequency is
+      REFCLK * N. When not specified, the PLL is bypassed.
+
+  adi,pll-vco-select:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    minimum: 0
+    maximum: 5
+    description: |
+      VCO frequency range selection (0-5). When not specified and the PLL
+      is enabled, the VCO range is automatically selected based on the
+      computed system clock frequency. Typical VCO frequency ranges are:
+      - Range 0: 370 MHz to 510 MHz (Auto-selected when <= 465 MHz)
+      - Range 1: 420 MHz to 590 MHz (Auto-selected when > 465 MHz and <= 545 MHz)
+      - Range 2: 500 MHz to 700 MHz (Auto-selected when > 545 MHz and <= 650 MHz)
+      - Range 3: 600 MHz to 880 MHz (Auto-selected when > 650 MHz and <= 790 MHz)
+      - Range 4: 700 MHz to 950 MHz (Auto-selected when > 790 MHz and <= 885 MHz)
+      - Range 5: 820 MHz to 1050 MHz (Auto-selected when > 885 MHz)
+
+  adi,charge-pump-current-microamp:
+    minimum: 212
+    maximum: 387
+    default: 387
+    description:
+      PLL charge pump current in microamps. Only applicable when the PLL
+      is enabled. The value is rounded to the nearest supported step.
+
+  adi,refclk-out-drive-strength:
+    $ref: /schemas/types.yaml#/definitions/string
+    enum: [ disabled, low, medium, high ]
+    default: disabled
+    description:
+      Reference clock output (DRV0) drive strength. Only applicable when
+      the PLL is enabled.
+
+  adi,reference-div2-enable:
+    type: boolean
+    description:
+      Enable the reference clock input divider. When enabled, the input
+      reference frequency is halved before deriving the system clock.
+      This is only applicable when the PLL is bypassed.
+
+  adi,inverse-sinc-enable:
+    type: boolean
+    description:
+      Enable the inverse sinc filter that compensates for the sinc roll-off
+      of the DAC output. When it is enabled, the filter introduces up to 3 dB
+      of insertion loss.
+
+  adi,sine-output-enable:
+    type: boolean
+    description:
+      Select sine wave output from the DDS core. When not set, the
+      output is a cosine wave.
+
+  adi,sync-clk-disable:
+    type: boolean
+    description:
+      Disable the SYNC_CLK output pin. SYNC_CLK runs at one quarter
+      of the system clock frequency.
+
+  adi,pdclk-disable:
+    type: boolean
+    description:
+      Disable the parallel data clock (PDCLK) output. PDCLK runs at
+      one quarter of the system clock frequency.
+
+  adi,pdclk-invert:
+    type: boolean
+    description:
+      Invert the polarity of the PDCLK output.
+
+  adi,tx-enable-invert:
+    type: boolean
+    description:
+      Invert the polarity of the TX_ENABLE input pin.
+
+  adi,dac-output-current-microamp:
+    minimum: 8640
+    maximum: 31590
+    default: 20070
+    description:
+      DAC full-scale output current in microamps.
+
+dependencies:
+  adi,pll-vco-select: [ 'adi,pll-multiplier' ]
+  adi,charge-pump-current-microamp: [ 'adi,pll-multiplier' ]
+  adi,refclk-out-drive-strength: [ 'adi,pll-multiplier' ]
+
+required:
+  - compatible
+  - reg
+  - clocks
+  - dvdd-io33-supply
+  - avdd33-supply
+  - dvdd18-supply
+  - avdd18-supply
+
+dependentSchemas:
+  resets:
+    properties:
+      reset-gpios: false
+  reset-gpios:
+    properties:
+      resets: false
+  adi,reference-div2-enable:
+    properties:
+      adi,pll-multiplier: false
+  adi,pll-multiplier:
+    properties:
+      adi,reference-div2-enable: false
+
+allOf:
+  - $ref: /schemas/spi/spi-peripheral-props.yaml#
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+    spi {
+        #address-cells = <1>;
+        #size-cells = <0>;
+        dds@0 {
+            compatible = "adi,ad9910";
+            reg = <0>;
+            spi-max-frequency = <1000000>;
+            clocks = <&ad9910_refclk>;
+
+            dvdd-io33-supply = <&vdd_io33>;
+            avdd33-supply = <&vdd_a33>;
+            dvdd18-supply = <&vdd_d18>;
+            avdd18-supply = <&vdd_a18>;
+
+            reset-gpios = <&gpio 0 GPIO_ACTIVE_HIGH>,
+                          <&gpio 1 GPIO_ACTIVE_HIGH>;
+            powerdown-gpios = <&gpio 2 GPIO_ACTIVE_HIGH>;
+            update-gpios = <&gpio 3 GPIO_ACTIVE_HIGH>;
+            profile-gpios = <&gpio 4 GPIO_ACTIVE_HIGH>,
+                            <&gpio 5 GPIO_ACTIVE_HIGH>,
+                            <&gpio 6 GPIO_ACTIVE_HIGH>;
+
+            adi,pll-multiplier = <40>;
+            adi,charge-pump-current-microamp = <387>;
+            adi,refclk-out-drive-strength = "disabled";
+            adi,inverse-sinc-enable;
+        };
+    };
+...
diff --git a/MAINTAINERS b/MAINTAINERS
index 1251965d70bd..79b4180e2334 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1610,6 +1610,13 @@ W:	https://ez.analog.com/linux-software-drivers
 F:	Documentation/devicetree/bindings/iio/dac/adi,ad9739a.yaml
 F:	drivers/iio/dac/ad9739a.c
 
+ANALOG DEVICES INC AD9910 DRIVER
+M:	Rodrigo Alencar <rodrigo.alencar@analog.com>
+L:	linux-iio@vger.kernel.org
+S:	Supported
+W:	https://ez.analog.com/linux-software-drivers
+F:	Documentation/devicetree/bindings/iio/frequency/adi,ad9910.yaml
+
 ANALOG DEVICES INC MAX22007 DRIVER
 M:	Janani Sunil <janani.sunil@analog.com>
 L:	linux-iio@vger.kernel.org

-- 
2.43.0

