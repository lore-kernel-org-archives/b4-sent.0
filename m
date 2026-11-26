From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Thu, 26 Nov 2026 09:11:47 +0100
Subject: [PATCH v2 1/2] dt-bindings: iio: light: add ams OSRAM TCS3430
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-iio-tcs3430-v2-1-6c5329d20919@gmail.com>
References: <20261126-iio-tcs3430-v2-0-6c5329d20919@gmail.com>
In-Reply-To: <20261126-iio-tcs3430-v2-0-6c5329d20919@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Robert Ijtsma <robertijtsma@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795680706; l=2571;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=oT2YcBwRHJlAGiUMywD1VuA9hLwSIhrT+EC9d5oP2Lw=;
 b=PFA3h61Ctb/pGXgYJNcTfov11ejFZoLGU7QDLD8L596VnE+/BD5+tES4c0Rhdiu1c+FqRTIOU
 GKrAK5M7GsSBTe4sDHL+eWZO/F5WEPaIW9rxpdvCxgdXbUwbVjv8IbH
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
index 0000000000000000000000000000000000000000..085a70e5557b1b5201bdd11e00736af065e002de
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
index 44540a1eb2b8088f9da95a9b6f83b4bf05188ee1..ea8ebd8ccd849702e82bf6aaeb4d8d60c2255628 100644
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
2.47.3

