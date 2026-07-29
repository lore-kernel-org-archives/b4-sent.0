From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Wed, 29 Jul 2026 09:25:36 +0100
Subject: [PATCH v10 09/17] dt-bindings: iio: frequency: add ad9910
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260729-ad9910-iio-driver-v10-9-aa1f6167729e@analog.com>
References: <20260729-ad9910-iio-driver-v10-0-aa1f6167729e@analog.com>
In-Reply-To: <20260729-ad9910-iio-driver-v10-0-aa1f6167729e@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-hardening@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785313627; l=7035;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=+LDivY4JV3+M3Ao0MTotVHXbBlEWqLbL+pu0WGm5Rmg=;
 b=5DdW+61frgGeL9pwh2vPlbJ0pk27j2DcuW8ZQ5sCnY1quh5D/LYxWiOwCeQ5S7xXphu1uX+R3
 azGy2Pt1dLSD7FXkombgIisDQ2G8goUCvYwXP2vScCgx/JieaIKji7L
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

DT-bindings for AD9910, a 1 GSPS DDS with 14-bit DAC. It includes
configurations for clocks, PLL configs, reset and basic GPIO control.

Reviewed-by: Conor Dooley <conor.dooley@microchip.com>
Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 .../bindings/iio/frequency/adi,ad9910.yaml         | 209 +++++++++++++++++++++
 MAINTAINERS                                        |   7 +
 2 files changed, 216 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/frequency/adi,ad9910.yaml b/Documentation/devicetree/bindings/iio/frequency/adi,ad9910.yaml
new file mode 100644
index 000000000000..4eebbd388b27
--- /dev/null
+++ b/Documentation/devicetree/bindings/iio/frequency/adi,ad9910.yaml
@@ -0,0 +1,209 @@
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
+description: >
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
+    minItems: 1
+    items:
+      - description: Reference clock (REF_CLK).
+      - description: Optional synchronization clock (SYNC_IN).
+
+  clock-names:
+    minItems: 1
+    items:
+      - const: ref_clk
+      - const: sync_in
+
+  '#clock-cells':
+    const: 1
+
+  clock-output-names:
+    items:
+      - const: sync_clk
+      - const: pdclk
+      - const: sync_out
+
+  interrupts:
+    minItems: 1
+    maxItems: 2
+    description:
+      Requires interrupt-names property with the same number of items. The
+      supported interrupts are 'drover' (digital ramp generator limit) and
+      'ram_swp_ovr' (end of RAM sweep).
+
+  interrupt-names:
+    minItems: 1
+    maxItems: 2
+    items:
+      enum: [ drover, ram_swp_ovr ]
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
+  reset-gpios:
+    maxItems: 1
+    description:
+      GPIOs controlling the Main Device reset.
+
+  io-reset-gpios:
+    maxItems: 1
+    description:
+      GPIO controlling the I/O_RESET pin.
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
+  sync-err-gpios:
+    maxItems: 1
+    description:
+      GPIO used to read SYNC_SMP_ERR pin status.
+
+  lock-detect-gpios:
+    maxItems: 1
+    description:
+      GPIO used to read PLL_LOCK pin status.
+
+  pwms:
+    maxItems: 1
+    description:
+      PWM used to drive the DRCTL pin, which controls the digital ramp
+      generator slope direction.
+
+  pwm-names:
+    items:
+      - const: drctl
+
+  adi,pll-enable:
+    type: boolean
+    description:
+      Enables the internal PLL. Applicable when external loop filter components
+      are connected to the PLL_LOOP_FILTER pin and low reference clock
+      frequencies are used, often provided by a crystal or by a single-ended
+      on-board oscillator.
+
+  adi,charge-pump-current-microamp:
+    minimum: 212
+    maximum: 387
+    default: 212
+    description:
+      PLL charge pump current in microamps. Only applicable when the internal
+      PLL is enabled. The value is rounded to the nearest supported step. This
+      value depends mostly on the loop filter design.
+
+  adi,refclk-out-drive-strength:
+    $ref: /schemas/types.yaml#/definitions/string
+    enum: [ disabled, low, medium, high ]
+    default: disabled
+    description:
+      Reference clock output (DRV0) drive strength. Only applicable when
+      the internal PLL is enabled.
+
+dependencies:
+  adi,charge-pump-current-microamp: [ 'adi,pll-enable' ]
+  adi,refclk-out-drive-strength: [ 'adi,pll-enable' ]
+  lock-detect-gpios: [ 'adi,pll-enable' ]
+  interrupts: [ interrupt-names ]
+  pwms: [ pwm-names ]
+
+required:
+  - compatible
+  - reg
+  - clocks
+  - clock-names
+  - '#clock-cells'
+  - dvdd-io33-supply
+  - avdd33-supply
+  - dvdd18-supply
+  - avdd18-supply
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
+
+            #clock-cells = <1>;
+            clock-output-names = "sync_clk", "pdclk", "sync_out";
+
+            clocks = <&ad9910_refclk>;
+            clock-names = "ref_clk";
+
+            dvdd-io33-supply = <&vdd_io33>;
+            avdd33-supply = <&vdd_a33>;
+            dvdd18-supply = <&vdd_d18>;
+            avdd18-supply = <&vdd_a18>;
+
+            reset-gpios = <&gpio 0 GPIO_ACTIVE_HIGH>;
+            io-reset-gpios = <&gpio 1 GPIO_ACTIVE_HIGH>;
+            powerdown-gpios = <&gpio 2 GPIO_ACTIVE_HIGH>;
+            update-gpios = <&gpio 3 GPIO_ACTIVE_HIGH>;
+            profile-gpios = <&gpio 4 GPIO_ACTIVE_HIGH>,
+                            <&gpio 5 GPIO_ACTIVE_HIGH>,
+                            <&gpio 6 GPIO_ACTIVE_HIGH>;
+
+            pwms = <&pwm 0 1000000 0>;
+            pwm-names = "drctl";
+
+            adi,pll-enable;
+            adi,charge-pump-current-microamp = <387>;
+            adi,refclk-out-drive-strength = "disabled";
+        };
+    };
+...
diff --git a/MAINTAINERS b/MAINTAINERS
index 101303d28a17..103f95307af1 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1678,6 +1678,13 @@ W:	https://ez.analog.com/linux-software-drivers
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

