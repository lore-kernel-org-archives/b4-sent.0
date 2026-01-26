From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Mon, 26 Jan 2026 13:51:03 +0000
Subject: [PATCH v2 2/6] dt-bindings: iio: amplifiers: Add AD8366 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260126-iio-ad8366-update-v2-2-c9a4d31aeb01@analog.com>
References: <20260126-iio-ad8366-update-v2-0-c9a4d31aeb01@analog.com>
In-Reply-To: <20260126-iio-ad8366-update-v2-0-c9a4d31aeb01@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Lars-Peter Clausen <lars@metafoo.de>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769436111; l=2610;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=PH30WSr8qpiolFuH2hsqx+jrXGR0KzrfQM8KgsHyz8Q=;
 b=JcPFr/Gu8SY4SPvzzEjP7VQraWwBjQXjUTHeQehJT5ayaH+75nBdTyKdmUcgcYikDu49lFqK/
 Ha0SwqEVu0UBH4qG56bEQ0jPtL5ob+ECvm9UZcAsg7QsW7BhD90kVFT
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add device tree binding documentation for amplifiers and digital
attenuators. This covers different device variants with similar
SPI control.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 .../bindings/iio/amplifiers/adi,ad8366.yaml        | 68 ++++++++++++++++++++++
 MAINTAINERS                                        |  1 +
 2 files changed, 69 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/amplifiers/adi,ad8366.yaml b/Documentation/devicetree/bindings/iio/amplifiers/adi,ad8366.yaml
new file mode 100644
index 000000000000..02f790fd73d7
--- /dev/null
+++ b/Documentation/devicetree/bindings/iio/amplifiers/adi,ad8366.yaml
@@ -0,0 +1,68 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/iio/amplifiers/adi,ad8366.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: AD8366 and similar Gain Amplifiers and Digital Attenuators
+
+maintainers:
+  - Michael Hennerich <michael.hennerich@analog.com>
+  - Rodrigo Alencar <rodrigo.alencar@analog.com>
+
+description:
+  Digital Variable Gain Amplifiers (VGAs) and Digital Attenuators with
+  SPI interface.
+
+properties:
+  compatible:
+    enum:
+      - adi,ad8366
+      - adi,ada4961
+      - adi,adl5240
+      - adi,adrf5720
+      - adi,adrf5730
+      - adi,adrf5731
+      - adi,hmc271a
+      - adi,hmc792a
+      - adi,hmc1018a
+      - adi,hmc1019a
+      - adi,hmc1119
+
+  reg:
+    maxItems: 1
+
+  vcc-supply:
+    description: Regulator that provides power to the device.
+
+  reset-gpios:
+    maxItems: 1
+
+  enable-gpios:
+    maxItems: 1
+
+required:
+  - compatible
+  - reg
+  - vcc-supply
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
+      #address-cells = <1>;
+      #size-cells = <0>;
+
+      amplifier@0 {
+        compatible = "adi,ad8366";
+        reg = <0>;
+        spi-max-frequency = <1000000>;
+        vcc-supply = <&vcc_3v3>;
+      };
+    };
+...
diff --git a/MAINTAINERS b/MAINTAINERS
index 8b5bb7030fa6..c3403ae478b7 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1589,6 +1589,7 @@ M:	Rodrigo Alencar <rodrigo.alencar@analog.com>
 L:	linux-iio@vger.kernel.org
 S:	Supported
 W:	https://ez.analog.com/linux-software-drivers
+F:	Documentation/devicetree/bindings/iio/amplifiers/adi,ad8366.yaml
 F:	drivers/iio/amplifiers/ad8366.c
 
 ANALOG DEVICES INC AD9467 DRIVER

-- 
2.43.0

