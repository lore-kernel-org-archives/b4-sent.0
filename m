From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Fri, 17 Apr 2026 09:17:30 +0100
Subject: [PATCH RFC v3 1/9] dt-bindings: iio: frequency: add ad9910
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260417-ad9910-iio-driver-v3-1-29b93712a228@analog.com>
References: <20260417-ad9910-iio-driver-v3-0-29b93712a228@analog.com>
In-Reply-To: <20260417-ad9910-iio-driver-v3-0-29b93712a228@analog.com>
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
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776413867; l=6418;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=jpnU+PdYYLxqGgaOYBAedYfqrN5HXtXF5AnH1zRbRnQ=;
 b=l5b6JqTuRYOxKceYQOj29K3elwjyjbCFPx9/OmgZ2cYsqlQTbDuQdXoD/Hbdo/jvJvWogcm7S
 6IEdBIGrXVDB0J8w8nq4JdnxVW5XGYue7Ta2rkhGRgXO3SmlUJ7zMWV
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

DT-bindings for AD9910, a 1 GSPS DDS with 14-bit DAC. It includes
configurations for clocks, DAC current, reset and basic GPIO control.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 .../bindings/iio/frequency/adi,ad9910.yaml         | 189 +++++++++++++++++++++
 MAINTAINERS                                        |   7 +
 2 files changed, 196 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/frequency/adi,ad9910.yaml b/Documentation/devicetree/bindings/iio/frequency/adi,ad9910.yaml
new file mode 100644
index 000000000000..61e879bca5c2
--- /dev/null
+++ b/Documentation/devicetree/bindings/iio/frequency/adi,ad9910.yaml
@@ -0,0 +1,189 @@
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
+    minItems: 1
+    maxItems: 2
+    description:
+      First clock is always the reference clock (REF_CLK), while the second
+      clock is an optional synchronization clock (SYNC_IN).
+
+  clock-names:
+    oneOf:
+      - items:
+          - const: ref_clk
+      - items:
+          - const: ref_clk
+          - const: sync_in
+
+  '#clock-cells':
+    const: 1
+
+  clock-output-names:
+    minItems: 1
+    maxItems: 3
+    items:
+      enum: [ sync_clk, pdclk, sync_out ]
+
+  interrupts:
+    minItems: 1
+    maxItems: 2
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
+  adi,pll-enable:
+    type: boolean
+    description:
+      Indicates that a loop filter is connected and the internal PLL is enabled.
+      Often used when the reference clock is provided by a crystal or by a
+      single-ended on-board oscillator.
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
+  adi,dac-output-current-microamp:
+    minimum: 8640
+    maximum: 31590
+    default: 20070
+    description:
+      DAC full-scale output current in microamps.
+
+dependencies:
+  adi,charge-pump-current-microamp: [ 'adi,pll-enable' ]
+  adi,refclk-out-drive-strength: [ 'adi,pll-enable' ]
+  interrupts: [ interrupt-names ]
+  clocks: [ clock-names ]
+  '#clock-cells': [ clock-output-names ]
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
+            adi,pll-enable;
+            adi,charge-pump-current-microamp = <387>;
+            adi,refclk-out-drive-strength = "disabled";
+        };
+    };
+...
diff --git a/MAINTAINERS b/MAINTAINERS
index 08d8ddf4ef68..2ca8b68e5daa 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1630,6 +1630,13 @@ W:	https://ez.analog.com/linux-software-drivers
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

