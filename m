From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Tue, 24 Nov 2026 23:46:57 +0100
Subject: [PATCH 1/2] dt-bindings: iio: light: add ams OSRAM TCS3430
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-iio-tcs3430-v1-1-0f2a38a6a4c1@gmail.com>
References: <20261124-iio-tcs3430-v1-0-0f2a38a6a4c1@gmail.com>
In-Reply-To: <20261124-iio-tcs3430-v1-0-0f2a38a6a4c1@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795560419; l=2397;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=6g3jbEADq4dZ3mSEGwYLMwabsTUEtLyGK4g51b8S51k=;
 b=8Nwd+wcxYr8+gQfY89SoZNiJ/L0j2Xe4BohEDYG4fTvdYpPs8l4HEaf068d6gyPQjVYWOcXQg
 0Kv0bXEEHNFA7LhdXUb7SakqBVaiDtsarKOLqdzdMEP5VyyZtD7I53n
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Devicetree binding schema for the ams OSRAM TCS3430 ambient light
and CIE 1931 XYZ tristimulus color sensor.

Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
 .../devicetree/bindings/iio/light/ams,tcs3430.yaml | 52 ++++++++++++++++++++++
 MAINTAINERS                                        |  6 +++
 2 files changed, 58 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/light/ams,tcs3430.yaml b/Documentation/devicetree/bindings/iio/light/ams,tcs3430.yaml
new file mode 100644
index 0000000..085a70e
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
index 44540a1..b1cebc2 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1489,6 +1489,12 @@ S:	Maintained
 F:	Documentation/devicetree/bindings/iio/light/ams,as73211.yaml
 F:	drivers/iio/light/as73211.c
 
+AMS TCS3430 DRIVER
+M:	Robert Ijtsma <robertijtsma@gmail.com>
+L:	linux-iio@vger.kernel.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/iio/light/ams,tcs3430.yaml
+
 AMT (Automatic Multicast Tunneling)
 M:	Taehee Yoo <ap420073@gmail.com>
 L:	netdev@vger.kernel.org

-- 
2.56.0

