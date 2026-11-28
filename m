From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Sat, 28 Nov 2026 21:40:47 +0100
Subject: [PATCH v4 1/2] dt-bindings: iio: light: add ams OSRAM TCS3430
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-iio-tcs3430-v4-1-14d03e411f8e@gmail.com>
References: <20261128-iio-tcs3430-v4-0-14d03e411f8e@gmail.com>
In-Reply-To: <20261128-iio-tcs3430-v4-0-14d03e411f8e@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Matti Vaittinen <mazziesaccount@gmail.com>, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Robert Ijtsma <robertijtsma@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795898449; l=2459;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=awrvMCU4drzUcSZ7P0NEK2PfH25/y/k0YDI5G+gqa0g=;
 b=EEvS8yPe36bDrxb8+2ZcwOh4mY/RyLpXbzpjNfNN5ukYB+xnTT3OLLsB6n9NffZkbAP9tA1Wk
 7mK5uZgPcqzBflhrY6HGRKhejtj/B89/NhA8R5WgD9lu1c3Du3X/J5R
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Devicetree binding schema for the ams OSRAM TCS3430 ambient light
and CIE 1931 XYZ tristimulus color sensor.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
 .../devicetree/bindings/iio/light/ams,tcs3430.yaml | 52 ++++++++++++++++++++++
 MAINTAINERS                                        |  5 +++
 2 files changed, 57 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/light/ams,tcs3430.yaml b/Documentation/devicetree/bindings/iio/light/ams,tcs3430.yaml
new file mode 100644
index 000000000000..085a70e5557b
--- /dev/null
+++ b/Documentation/devicetree/bindings/iio/light/ams,tcs3430.yaml
@@ -0,0 +1,52 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/iio/light/ams,tcs3430.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: ams OSRAM TCS3430 XYZ Tristimulus Color and Ambient Light Sensor
+
+maintainers:
+  - Robert Ijtsma <robertijtsma@gmail.com>
+
+description: |
+  The ams OSRAM TCS3430 is an I2C ambient light and CIE 1931 XYZ tristimulus
+  color sensor with photopic Y, Z, X, and IR channels.
+
+  Datasheet: https://look.ams-osram.com/m/43d518b4cd81e3f2/original/TCS3430-DS000539.pdf
+
+properties:
+  compatible:
+    const: ams,tcs3430
+
+  reg:
+    maxItems: 1
+
+  vdd-supply: true
+
+  interrupts:
+    maxItems: 1
+
+required:
+  - compatible
+  - reg
+  - vdd-supply
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/irq.h>
+
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        light-sensor@39 {
+            compatible = "ams,tcs3430";
+            reg = <0x39>;
+            vdd-supply = <&vdd_reg>;
+            interrupts = <24 IRQ_TYPE_LEVEL_LOW>;
+        };
+    };
+...
diff --git a/MAINTAINERS b/MAINTAINERS
index 44540a1eb2b8..ea8ebd8ccd84 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1489,6 +1489,11 @@ S:	Maintained
 F:	Documentation/devicetree/bindings/iio/light/ams,as73211.yaml
 F:	drivers/iio/light/as73211.c
 
+AMS TCS3430 DRIVER
+M:	Robert Ijtsma <robertijtsma@gmail.com>
+S:	Maintained
+F:	Documentation/devicetree/bindings/iio/light/ams,tcs3430.yaml
+
 AMT (Automatic Multicast Tunneling)
 M:	Taehee Yoo <ap420073@gmail.com>
 L:	netdev@vger.kernel.org

-- 
2.56.0

