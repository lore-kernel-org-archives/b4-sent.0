From: Radu Sabau <radu.sabau@analog.com>
Date: Fri, 27 Mar 2026 13:07:57 +0200
Subject: [PATCH v5 1/4] dt-bindings: iio: adc: add AD4691 family
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260327-ad4692-multichannel-sar-adc-driver-v5-1-11f789de47b8@analog.com>
References: <20260327-ad4692-multichannel-sar-adc-driver-v5-0-11f789de47b8@analog.com>
In-Reply-To: <20260327-ad4692-multichannel-sar-adc-driver-v5-0-11f789de47b8@analog.com>
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
 Philipp Zabel <p.zabel@pengutronix.de>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pwm@vger.kernel.org, 
 linux-gpio@vger.kernel.org, linux-doc@vger.kernel.org, 
 Radu Sabau <radu.sabau@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774609685; l=6575;
 i=radu.sabau@analog.com; s=20260220; h=from:subject:message-id;
 bh=8WQtXGwAJMX9LKjokE7g+NNdM3YBj5DyijsdwhSVWu8=;
 b=nTrNVkiKWzBmMuz762oQjw3q2GER0wboRbdVWSbk02gKG4NkI4GGG0zS+pxBRRVfHPvQZKMZ1
 l3WP3h4d31TAhjdU1BhVWurEHYyF8lrlyUNsJvGemEsYWwjLZ8VySag
X-Developer-Key: i=radu.sabau@analog.com; a=ed25519;
 pk=lDPQHgn9jTdt0vo58Na9lLxLaE2mb330if71Cn+EvFU=
X-Endpoint-Received: by B4 Relay for radu.sabau@analog.com/20260220 with auth_id=642
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add DT bindings for the Analog Devices AD4691 family of multichannel
SAR ADCs (AD4691, AD4692, AD4693, AD4694).

The binding describes the hardware connections:

- Power domains: avdd-supply (required), vio-supply, ref-supply or
  refin-supply (external reference; the REFIN path enables the
  internal reference buffer), and an optional ldo-in-supply, that if
  absent, means the on-chip internal LDO will be used.

- Optional PWM on the CNV pin selects CNV Burst Mode; when absent,
  Manual Mode is assumed with CNV tied to SPI CS.

- An optional reset GPIO (reset-gpios) for hardware reset.

- Up to four GP pins (gp0..gp3) usable as interrupt sources,
  identified in firmware via interrupt-names "gp0".."gp3".

- gpio-controller with #gpio-cells = <2> for GP pin GPIO usage.

- #trigger-source-cells = <1>: one cell selecting the GP pin number
  (0-3) used as the SPI offload trigger source.

Two binding examples are provided: CNV Burst Mode with SPI offload
(DMA data acquisition driven by DATA_READY on a GP pin), and Manual
Mode for CPU-driven triggered-buffer or single-shot capture.

Signed-off-by: Radu Sabau <radu.sabau@analog.com>
---
 .../devicetree/bindings/iio/adc/adi,ad4691.yaml    | 162 +++++++++++++++++++++
 MAINTAINERS                                        |   7 +
 2 files changed, 169 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/adc/adi,ad4691.yaml b/Documentation/devicetree/bindings/iio/adc/adi,ad4691.yaml
new file mode 100644
index 000000000000..81d2ca4e0e22
--- /dev/null
+++ b/Documentation/devicetree/bindings/iio/adc/adi,ad4691.yaml
@@ -0,0 +1,162 @@
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
+  an SPI-compatible serial interface. The ADC supports CNV Burst Mode,
+  where an external PWM drives the CNV pin, and Manual Mode, where CNV
+  is directly tied to the SPI chip-select.
+
+  Datasheets:
+    * https://www.analog.com/en/products/ad4691.html
+    * https://www.analog.com/en/products/ad4692.html
+    * https://www.analog.com/en/products/ad4693.html
+    * https://www.analog.com/en/products/ad4694.html
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
+  avdd-supply:
+    description: Analog power supply (4.5V to 5.5V).
+
+  ldo-in-supply:
+    description: LDO input supply. When absent, the internal LDO is used.
+
+  vio-supply:
+    description: I/O voltage supply (1.71V to 1.89V or VDD).
+
+  ref-supply:
+    description: External reference voltage supply (2.4V to 5.25V).
+
+  refin-supply:
+    description: Internal reference buffer input supply.
+
+  reset-gpios:
+    description:
+      GPIO line controlling the hardware reset pin (active-low).
+    maxItems: 1
+
+  pwms:
+    description:
+      PWM connected to the CNV pin. When present, selects CNV Burst Mode where
+      the PWM drives the conversion rate. When absent, Manual Mode is used
+      (CNV tied to SPI CS).
+    maxItems: 1
+
+  interrupts:
+    description:
+      Interrupt lines connected to the ADC GP pins. Each GP pin can be
+      physically wired to an interrupt-capable input on the SoC.
+    maxItems: 4
+
+  interrupt-names:
+    description: Names of the interrupt lines, matching the GP pin names.
+    minItems: 1
+    maxItems: 4
+    items:
+      enum:
+        - gp0
+        - gp1
+        - gp2
+        - gp3
+
+  gpio-controller: true
+
+  '#gpio-cells':
+    const: 2
+
+  '#trigger-source-cells':
+    description:
+      This node can act as a trigger source. The single cell in a consumer
+      reference specifies the GP pin number (0-3) used as the trigger output.
+    const: 1
+
+required:
+  - compatible
+  - reg
+  - avdd-supply
+  - vio-supply
+
+allOf:
+  # ref-supply and refin-supply are mutually exclusive, one is required
+  - oneOf:
+      - required:
+          - ref-supply
+      - required:
+          - refin-supply
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+    /* AD4692 in CNV Burst Mode with SPI offload */
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
+            avdd-supply = <&avdd_supply>;
+            vio-supply = <&vio_supply>;
+            ref-supply = <&ref_5v>;
+
+            reset-gpios = <&gpio0 15 GPIO_ACTIVE_LOW>;
+
+            pwms = <&pwm_gen 0 0>;
+
+            #trigger-source-cells = <1>;
+        };
+    };
+
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+    /* AD4692 in Manual Mode (CNV tied to SPI CS) */
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
+            avdd-supply = <&avdd_supply>;
+            vio-supply = <&vio_supply>;
+            refin-supply = <&refin_supply>;
+
+            reset-gpios = <&gpio0 15 GPIO_ACTIVE_LOW>;
+        };
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index 61bf550fd37c..438ca850fa1c 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1484,6 +1484,13 @@ W:	https://ez.analog.com/linux-software-drivers
 F:	Documentation/devicetree/bindings/iio/adc/adi,ad4170-4.yaml
 F:	drivers/iio/adc/ad4170-4.c
 
+ANALOG DEVICES INC AD4691 DRIVER
+M:	Radu Sabau <radu.sabau@analog.com>
+L:	linux-iio@vger.kernel.org
+S:	Supported
+W:	https://ez.analog.com/linux-software-drivers
+F:	Documentation/devicetree/bindings/iio/adc/adi,ad4691.yaml
+
 ANALOG DEVICES INC AD4695 DRIVER
 M:	Michael Hennerich <michael.hennerich@analog.com>
 M:	Nuno Sá <nuno.sa@analog.com>

-- 
2.43.0

