From: Bruce Tsao <bruce.tsao@analog.com>
Date: Sat, 17 Oct 2026 03:23:53 +0800
Subject: [PATCH 1/2] dt-bindings: iio: dac: Document Analog Devices AD5413
 single-channel DAC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261017-ad5413-upstream-v1-1-61f40c8fef25@analog.com>
References: <20261017-ad5413-upstream-v1-0-61f40c8fef25@analog.com>
In-Reply-To: <20261017-ad5413-upstream-v1-0-61f40c8fef25@analog.com>
To: Jonathan Cameron <jic23@kernel.org>
Cc: linux-iio@vger.kernel.org, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Bruce Tsao <bruce.tsao@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792178669; l=3103;
 i=bruce.tsao@analog.com; s=20261017; h=from:subject:message-id;
 bh=MLPV8sK6YxrCDJ3rbi7e0JiFTKRnM1tj3rvbSW15OFA=;
 b=quDm8XU1PO9wKKXa4zW6z2ltCpe32WYd7d5NnP8xnp5kYdHA50dl+wSh78dMWOEqcXsHF6tRE
 qlI1ickDsuWCO8iKl4oi67jqSOa+ujzj4mQsroX1+8nIJmgvs1gA0gI
X-Developer-Key: i=bruce.tsao@analog.com; a=ed25519;
 pk=dT7qI1i91oYvnYmY2ljmdZ0ZQoCZIzrQ8hnsyjuBedg=
X-Endpoint-Received: by B4 Relay for bruce.tsao@analog.com/20261017 with auth_id=1215
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the devicetree bindings for the Analog Devices AD5413, a
single-channel precision DAC controlled via SPI. The device supports
voltage or current output modes and programmable slew-rate control.

Signed-off-by: Bruce Tsao <bruce.tsao@analog.com>
---
 .../devicetree/bindings/iio/dac/adi,ad5413.yaml    | 101 +++++++++++++++++++++
 1 file changed, 101 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/dac/adi,ad5413.yaml b/Documentation/devicetree/bindings/iio/dac/adi,ad5413.yaml
new file mode 100644
index 000000000000..74e869304aab
--- /dev/null
+++ b/Documentation/devicetree/bindings/iio/dac/adi,ad5413.yaml
@@ -0,0 +1,101 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/iio/dac/adi,ad5413.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Analog Devices AD5413 DAC
+
+description:
+  Analog Devices AD5413 is a single-channel precision DAC supporting voltage
+  or current output modes with programmable slew-rate control.
+  The output mode is selected via the adi,chan-current-mode property.
+  Optional reset GPIO may be provided.
+
+maintainers:
+  - bruce.tsao@analog.com
+
+properties:
+  compatible:
+    const: adi,ad5413
+
+  spi-max-frequency:
+    maximum: 50000000
+
+  spi-cpha: true
+
+  spi-cpol: false
+
+  reset-gpios:
+    maxItems: 1
+    description: Optional reset GPIO (active low).
+
+  avdd-supply:
+    description: Analog positive supply (AVDD)
+
+  dvdd-supply:
+    description: Digital positive supply (DVDD)
+
+  avss-supply:
+    description: Analog negative supply (AVSS)
+
+  adi,chan-current-mode:
+    type: boolean
+    description: Select current output mode. If absent, voltage mode is used.
+
+  adi,slew-time-us:
+    description: Output digital slew control time in microseconds
+    minimum: 0
+    maximum: 1000000
+    default: 0
+
+required:
+  - compatible
+  - spi-cpha
+  - avdd-supply
+  - dvdd-supply
+  - avss-supply
+
+allOf:
+  - $ref: /schemas/spi/spi-peripheral-props.yaml#
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+
+    spi {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        dac@0 {
+            compatible = "adi,ad5413";
+            reg = <0>;
+            spi-max-frequency = <1000000>;
+            spi-cpha;
+            reset-gpios = <&gpio 0 GPIO_ACTIVE_LOW>;
+            avdd-supply = <&avdd>;
+            dvdd-supply = <&dvdd>;
+            avss-supply = <&avss>;
+            adi,slew-time-us = <125>;
+        };
+    };
+
+  - |
+    spi {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        dac@0 {
+            compatible = "adi,ad5413";
+            reg = <0>;
+            spi-max-frequency = <1000000>;
+            spi-cpha;
+            avdd-supply = <&avdd>;
+            dvdd-supply = <&dvdd>;
+            avss-supply = <&avss>;
+
+            adi,chan-current-mode;
+        };
+    };

-- 
2.53.0

