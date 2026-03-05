From: Radu Sabau <radu.sabau@analog.com>
Date: Thu, 05 Mar 2026 14:23:27 +0200
Subject: [PATCH 1/4] dt-bindings: iio: adc: add bindings for AD4691 family
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260305-ad4692-multichannel-sar-adc-driver-v1-1-336229a8dcc7@analog.com>
References: <20260305-ad4692-multichannel-sar-adc-driver-v1-0-336229a8dcc7@analog.com>
In-Reply-To: <20260305-ad4692-multichannel-sar-adc-driver-v1-0-336229a8dcc7@analog.com>
To: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pwm@vger.kernel.org, 
 linux-gpio@vger.kernel.org, Radu Sabau <radu.sabau@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772713413; l=10122;
 i=radu.sabau@analog.com; s=20260220; h=from:subject:message-id;
 bh=lsINb5qT8O5iLIY36KaeYf7LKPIGXET2nXgZufTpeWU=;
 b=AX6kACPh4Wvnmru2wcsCLTF6WOCvYBofqGrkbFkq7sq110JY0cEdluBcLZ8ecbDNgBQO5Fp40
 f5SRk0xp+VjCk3/6ncUahK1V/DW/u+pp26YpMZL7vytcaDrbDsoaCfu
X-Developer-Key: i=radu.sabau@analog.com; a=ed25519;
 pk=lDPQHgn9jTdt0vo58Na9lLxLaE2mb330if71Cn+EvFU=
X-Endpoint-Received: by B4 Relay for radu.sabau@analog.com/20260220 with auth_id=642
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add YAML bindings and dt-bindings header for the Analog Devices AD4691
family of multichannel SAR ADCs (AD4691, AD4692, AD4693, AD4694).

The binding describes five operating modes selectable via the
adi,spi-mode property, optional PWM/clock for CNV Clock and CNV Burst
modes, GPIO pins, voltage supplies and the trigger-source interface for
SPI Engine offload operation.

Signed-off-by: Radu Sabau <radu.sabau@analog.com>
---
 .../devicetree/bindings/iio/adc/adi,ad4691.yaml    | 278 +++++++++++++++++++++
 MAINTAINERS                                        |   8 +
 include/dt-bindings/iio/adc/adi,ad4691.h           |  13 +
 3 files changed, 299 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/adc/adi,ad4691.yaml b/Documentation/devicetree/bindings/iio/adc/adi,ad4691.yaml
new file mode 100644
index 000000000000..b0d8036184b0
--- /dev/null
+++ b/Documentation/devicetree/bindings/iio/adc/adi,ad4691.yaml
@@ -0,0 +1,278 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/iio/adc/adi,ad4691.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Analog Devices AD4691 Family Multichannel SAR ADCs
+
+maintainers:
+  - Radu Sabau <radu.sabau@analog.com>
+
+description: |
+  The AD4691 family are high-speed, low-power, multichannel successive
+  approximation register (SAR) analog-to-digital converters (ADCs) with
+  an SPI-compatible serial interface. The family supports multiple operating
+  modes including CNV Clock Mode, CNV Burst Mode, Autonomous Mode, SPI Burst
+  Mode, and Manual Mode.
+
+  The driver supports both standard SPI and SPI Engine (offload) operation.
+
+  Datasheets:
+    * https://www.analog.com/en/products/ad4692.html
+    * https://www.analog.com/en/products/ad4691.html
+    * https://www.analog.com/en/products/ad4694.html
+    * https://www.analog.com/en/products/ad4693.html
+
+$ref: /schemas/spi/spi-peripheral-props.yaml#
+
+properties:
+  compatible:
+    enum:
+      - adi,ad4691
+      - adi,ad4692
+      - adi,ad4693
+      - adi,ad4694
+
+  reg:
+    maxItems: 1
+
+  spi-max-frequency:
+    maximum: 40000000
+
+  spi-cpol: true
+  spi-cpha: true
+
+  adi,spi-mode:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    enum: [0, 1, 2, 3, 4]
+    description: |
+      Selects the ADC operating mode:
+        0 - CNV Clock Mode: External PWM drives CNV pin, samples at PWM rate.
+        1 - CNV Burst Mode: PWM triggers burst cycles, internal oscillator
+            drives conversions within each burst.
+        2 - Autonomous Mode: Internal oscillator drives conversions, software
+            starts/stops via register write.
+        3 - SPI Burst Mode: Similar to Autonomous Mode but optimized for
+            SPI burst reads.
+        4 - Manual Mode: CNV is directly tied to SPI CS. Each SPI transfer
+            triggers a conversion and returns previous result (pipelined).
+
+  vio-supply:
+    description: I/O voltage supply (1.71V to 1.89V or VDD).
+
+  vref-supply:
+    description:
+      External reference voltage supply (2.4V to 5.25V). Mutually exclusive
+      with vrefin-supply.
+
+  vrefin-supply:
+    description:
+      Internal reference buffer input supply. Mutually exclusive with
+      vref-supply.
+
+  reset-gpios:
+    description: GPIO connected to the RESET pin (active high).
+    maxItems: 1
+
+  gp0-gpios:
+    description:
+      GPIO connected to the GP0 pin. Required for non-offload operation to
+      receive DATA_READY or BUSY interrupts. For SPI Engine offload, this
+      is optional as the trigger is provided by the SPI offload subsystem.
+    maxItems: 1
+
+  gp1-gpios:
+    description: GPIO connected to the GP1 pin.
+    maxItems: 1
+
+  gp2-gpios:
+    description: GPIO connected to the GP2 pin.
+    maxItems: 1
+
+  gp3-gpios:
+    description: GPIO connected to the GP3 pin.
+    maxItems: 1
+
+  clocks:
+    description: Reference clock for PWM timing in CNV Clock and CNV Burst modes.
+    maxItems: 1
+
+  clock-names:
+    items:
+      - const: ref_clk
+
+  pwms:
+    description:
+      PWM connected to the CNV pin. Required for CNV Clock Mode and CNV Burst
+      Mode to control conversion timing.
+    maxItems: 1
+
+  pwm-names:
+    items:
+      - const: cnv
+
+  interrupts:
+    description:
+      Interrupt from the GP0 pin configured as DATA_READY or BUSY. Required
+      for non-offload operation in all modes except Manual Mode (mode 4),
+      where CNV is tied to CS and no DATA_READY signal is generated.
+    maxItems: 1
+
+  interrupt-names:
+    items:
+      - const: DRDY
+
+  '#trigger-source-cells':
+    description: |
+      For SPI Engine offload operation, this node acts as a trigger source.
+      Two cells are required:
+        - First cell: Trigger event type (0 = BUSY, 1 = DATA_READY)
+        - Second cell: GPIO pin number (only 0 = GP0 is supported)
+
+      Macros are available in dt-bindings/iio/adc/adi,ad4691.h:
+        AD4691_TRIGGER_EVENT_BUSY, AD4691_TRIGGER_EVENT_DATA_READY
+        AD4691_TRIGGER_PIN_GP0
+    const: 2
+
+required:
+  - compatible
+  - reg
+  - adi,spi-mode
+  - vio-supply
+  - reset-gpios
+
+allOf:
+  # vref-supply and vrefin-supply are mutually exclusive, one is required
+  - oneOf:
+      - required:
+          - vref-supply
+      - required:
+          - vrefin-supply
+
+  # AD4694 (20-bit) does not support Manual Mode
+  - if:
+      properties:
+        compatible:
+          const: adi,ad4694
+    then:
+      properties:
+        adi,spi-mode:
+          enum: [0, 1, 2, 3]
+
+  # CNV Clock Mode and CNV Burst Mode require PWM and clock
+  - if:
+      properties:
+        adi,spi-mode:
+          enum: [0, 1]
+    then:
+      required:
+        - clocks
+        - clock-names
+        - pwms
+        - pwm-names
+
+  # Non-Manual modes (0-3) without SPI offload require a DRDY interrupt.
+  # Offload configurations expose '#trigger-source-cells' instead.
+  - if:
+      properties:
+        adi,spi-mode:
+          enum: [0, 1, 2, 3]
+      not:
+        required:
+          - '#trigger-source-cells'
+    then:
+      required:
+        - interrupts
+        - interrupt-names
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+    #include <dt-bindings/iio/adc/adi,ad4691.h>
+
+    /* Example: AD4692 in CNV Clock Mode with standard SPI */
+    spi {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        adc@0 {
+            compatible = "adi,ad4692";
+            reg = <0>;
+            spi-cpol;
+            spi-cpha;
+            spi-max-frequency = <40000000>;
+
+            adi,spi-mode = <0>; /* CNV Clock Mode */
+
+            vio-supply = <&vio_supply>;
+            vref-supply = <&vref_5v>;
+
+            reset-gpios = <&gpio 10 GPIO_ACTIVE_HIGH>;
+            gp0-gpios = <&gpio 11 GPIO_ACTIVE_HIGH>;
+
+            clocks = <&ref_clk>;
+            clock-names = "ref_clk";
+
+            pwms = <&pwm_gen 0 0>;
+            pwm-names = "cnv";
+
+            interrupts = <12 4>;
+            interrupt-names = "DRDY";
+        };
+    };
+
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+    #include <dt-bindings/iio/adc/adi,ad4691.h>
+
+    /* Example: AD4692 in Manual Mode with SPI Engine offload */
+    spi {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        adc@0 {
+            compatible = "adi,ad4692";
+            reg = <0>;
+            spi-cpol;
+            spi-cpha;
+            spi-max-frequency = <31250000>;
+
+            adi,spi-mode = <4>; /* Manual Mode */
+
+            vio-supply = <&vio_supply>;
+            vrefin-supply = <&vrefin_supply>;
+
+            reset-gpios = <&gpio 10 GPIO_ACTIVE_HIGH>;
+        };
+    };
+
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+    #include <dt-bindings/iio/adc/adi,ad4691.h>
+
+    /* Example: AD4691 in Autonomous Mode with SPI Engine offload trigger */
+    spi {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        adc@0 {
+            compatible = "adi,ad4691";
+            reg = <0>;
+            spi-cpol;
+            spi-cpha;
+            spi-max-frequency = <40000000>;
+
+            adi,spi-mode = <2>; /* Autonomous Mode */
+
+            vio-supply = <&vio_supply>;
+            vref-supply = <&vref_5v>;
+
+            reset-gpios = <&gpio 10 GPIO_ACTIVE_HIGH>;
+            gp0-gpios = <&gpio 11 GPIO_ACTIVE_HIGH>;
+
+            #trigger-source-cells = <2>;
+        };
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index 61bf550fd37c..9994d107d88d 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1484,6 +1484,14 @@ W:	https://ez.analog.com/linux-software-drivers
 F:	Documentation/devicetree/bindings/iio/adc/adi,ad4170-4.yaml
 F:	drivers/iio/adc/ad4170-4.c
 
+ANALOG DEVICES INC AD4691 DRIVER
+M:	Radu Sabau <radu.sabau@analog.com>
+L:	linux-iio@vger.kernel.org
+S:	Supported
+W:	https://ez.analog.com/linux-software-drivers
+F:	Documentation/devicetree/bindings/iio/adc/adi,ad4691.yaml
+F:	include/dt-bindings/iio/adc/adi,ad4691.h
+
 ANALOG DEVICES INC AD4695 DRIVER
 M:	Michael Hennerich <michael.hennerich@analog.com>
 M:	Nuno Sá <nuno.sa@analog.com>
diff --git a/include/dt-bindings/iio/adc/adi,ad4691.h b/include/dt-bindings/iio/adc/adi,ad4691.h
new file mode 100644
index 000000000000..294b03974f48
--- /dev/null
+++ b/include/dt-bindings/iio/adc/adi,ad4691.h
@@ -0,0 +1,13 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause) */
+
+#ifndef _DT_BINDINGS_ADI_AD4691_H
+#define _DT_BINDINGS_ADI_AD4691_H
+
+/* Trigger event types */
+#define AD4691_TRIGGER_EVENT_BUSY	0
+#define AD4691_TRIGGER_EVENT_DATA_READY	1
+
+/* Trigger GPIO pin selection */
+#define AD4691_TRIGGER_PIN_GP0		0
+
+#endif /* _DT_BINDINGS_ADI_AD4691_H */

-- 
2.43.0

