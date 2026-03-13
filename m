From: Radu Sabau <radu.sabau@analog.com>
Date: Fri, 13 Mar 2026 12:07:25 +0200
Subject: [PATCH v3 1/4] dt-bindings: iio: adc: add bindings for AD4691
 family
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260313-ad4692-multichannel-sar-adc-driver-v3-1-b4d14d81a181@analog.com>
References: <20260313-ad4692-multichannel-sar-adc-driver-v3-0-b4d14d81a181@analog.com>
In-Reply-To: <20260313-ad4692-multichannel-sar-adc-driver-v3-0-b4d14d81a181@analog.com>
To: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pwm@vger.kernel.org, 
 linux-gpio@vger.kernel.org, Radu Sabau <radu.sabau@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773396456; l=7296;
 i=radu.sabau@analog.com; s=20260220; h=from:subject:message-id;
 bh=oJ+skzTO+ldVyCAp6LzsSaIW3BVvqyXV5zmKWF0Z/GQ=;
 b=U9uUEwwFsZs5v0+at5LAoz4KhSbzNVWFTLPt5bpOeFmpVRerc9avumDdrNlGW13zGWDzir0a4
 xTzVsTGq4AMDvYrBGE2c6f4X9f0JURjRmOo5Ql0sIEBlT9/ILAGnMDx
X-Developer-Key: i=radu.sabau@analog.com; a=ed25519;
 pk=lDPQHgn9jTdt0vo58Na9lLxLaE2mb330if71Cn+EvFU=
X-Endpoint-Received: by B4 Relay for radu.sabau@analog.com/20260220 with auth_id=642
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add DT bindings for the Analog Devices AD4691 family of multichannel
SAR ADCs (AD4691, AD4692, AD4693, AD4694).

The binding describes the hardware connections: an optional PWM on
the CNV pin selects CNV Clock Mode; when absent, Manual Mode is used
with CNV tied to SPI CS. GPIO pins, voltage supplies, and the
trigger-source interface for SPI Engine offload operation are also
described.

Signed-off-by: Radu Sabau <radu.sabau@analog.com>
---
 .../devicetree/bindings/iio/adc/adi,ad4691.yaml    | 180 +++++++++++++++++++++
 MAINTAINERS                                        |   8 +
 include/dt-bindings/iio/adc/adi,ad4691.h           |  13 ++
 3 files changed, 201 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/adc/adi,ad4691.yaml b/Documentation/devicetree/bindings/iio/adc/adi,ad4691.yaml
new file mode 100644
index 000000000000..a9301e0ca851
--- /dev/null
+++ b/Documentation/devicetree/bindings/iio/adc/adi,ad4691.yaml
@@ -0,0 +1,180 @@
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
+  an SPI-compatible serial interface. The ADC supports CNV Clock Mode,
+  where an external PWM drives the CNV pin, and Manual Mode, where CNV
+  is directly tied to the SPI chip-select.
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
+  vio-supply:
+    description: I/O voltage supply (1.71V to 1.89V or VDD).
+
+  vref-supply:
+    description: External reference voltage supply (2.4V to 5.25V).
+
+  vrefin-supply:
+    description: Internal reference buffer input supply.
+
+  reset-gpios:
+    description: GPIO connected to the RESET pin (active high).
+    maxItems: 1
+
+  clocks:
+    description: Reference clock for PWM timing in CNV Clock Mode.
+    maxItems: 1
+
+  pwms:
+    description:
+      PWM connected to the CNV pin. When present, selects CNV Clock Mode where
+      the PWM drives the conversion rate. When absent, Manual Mode is used
+      (CNV tied to SPI CS).
+    maxItems: 1
+
+  pwm-names:
+    items:
+      - const: cnv
+
+  interrupts:
+    description:
+      Interrupt line connected to the ADC GP0 pin. GP0 must be physically
+      wired to an interrupt-capable input on the SoC. The ADC asserts GP0 as
+      DATA_READY at end of conversion, used both for non-offload CNV Clock Mode
+      operation and for SPI Engine offload triggering via '#trigger-source-cells'.
+      Not used in Manual Mode, where CNV is tied to SPI CS and no DATA_READY
+      signal is generated.
+    maxItems: 1
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
+  # CNV Clock Mode requires a reference clock.
+  - if:
+      required:
+        - pwms
+    then:
+      required:
+        - clocks
+
+  # CNV Clock Mode (pwms present) without SPI offload requires a DRDY interrupt.
+  # Offload configurations expose '#trigger-source-cells' instead.
+  - if:
+      required:
+        - pwms
+      not:
+        required:
+          - '#trigger-source-cells'
+    then:
+      required:
+        - interrupts
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+
+    /* Example: AD4692 in CNV Clock Mode (pwms present) with standard SPI */
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
+            vio-supply = <&vio_supply>;
+            vref-supply = <&vref_5v>;
+
+            reset-gpios = <&gpio 10 GPIO_ACTIVE_HIGH>;
+
+            clocks = <&ref_clk>;
+
+            pwms = <&pwm_gen 0 0>;
+            pwm-names = "cnv";
+
+            interrupts = <12 4>;
+        };
+    };
+
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+
+    /* Example: AD4692 in Manual Mode (no pwms) with SPI Engine offload */
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
+            vio-supply = <&vio_supply>;
+            vrefin-supply = <&vrefin_supply>;
+
+            reset-gpios = <&gpio 10 GPIO_ACTIVE_HIGH>;
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

