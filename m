From: Petr Hodina <petr.hodina@protonmail.com>
Date: Mon, 19 Jan 2026 18:19:06 +0100
Subject: [PATCH 1/3] doc: add Device Tree binding for AMS TCS3400 light
 sensor
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260119-tsc3400-v1-1-82a65c5417aa@protonmail.com>
References: <20260119-tsc3400-v1-0-82a65c5417aa@protonmail.com>
In-Reply-To: <20260119-tsc3400-v1-0-82a65c5417aa@protonmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, David Heidelberg <david@ixit.cz>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768843157; l=2537;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=1LDwA54n0tkYAGyvdpUdaNISfncR1cK5nESUpKkwwc8=;
 b=xKuI+yo90AJJ5IlxvKntYTEmP+ZcSeI/7Px4HhOzYrqfHogJT4MvIE2kGre8uJcqnP0tc2evl
 0Rwcq3WXQmgALu+8yy7Jf0RVMqEoLMdrCGWQsEhne6kaSw+BwLxWCbV
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds a new YAML binding describing the AMS TCS3400 I2C light sensor,
including compatible string, registers, interrupts, power supply, and an
example node.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 .../devicetree/bindings/iio/light/ams,tcs3400.yaml | 54 ++++++++++++++++++++++
 MAINTAINERS                                        |  6 +++
 2 files changed, 60 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/light/ams,tcs3400.yaml b/Documentation/devicetree/bindings/iio/light/ams,tcs3400.yaml
new file mode 100644
index 000000000000..2c5a9295af1a
--- /dev/null
+++ b/Documentation/devicetree/bindings/iio/light/ams,tcs3400.yaml
@@ -0,0 +1,54 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: "http://devicetree.org/schemas/iio/light/ams,tcs3400.yaml#"
+$schema: "http://devicetree.org/meta-schemas/core.yaml#"
+
+title: AMS TCS3400 Color Light-to-Digital Converter
+
+maintainers:
+  - name: Petr Hodina
+    email: petr.hodina@protonmail.com
+
+description: |
+  The AMS TCS3400 is an I2C-connected color light sensor providing
+  RGBC or RGB-IR measurements with a programmable integration time
+  and gain.
+
+properties:
+  compatible:
+    const: ams,tcs3400
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    maxItems: 1
+    description:
+      Interrupt line signaling ALS data ready or threshold events.
+
+  vdd-supply:
+    description:
+      Regulator supplying the main sensor power.
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
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        light-sensor@39 {
+            compatible = "ams,tcs3400";
+            reg = <0x39>;
+            interrupt-parent = <&gpio1>;
+            interrupts = <5 IRQ_TYPE_EDGE_FALLING>;
+            vdd-supply = <&vdd_3v3>;
+        };
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index 14a06f856b81..ab5307a34180 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -22866,6 +22866,12 @@ S:	Supported
 F:	drivers/iio/adc/rohm-bd79112.c
 F:	drivers/iio/adc/rohm-bd79124.c
 
+AMS TCS3400 AMBIENT LIGHT SENSOR DRIVER
+M:	Petr Hodina
+L:	Petr Hodina <petr.hodina@protonmail.com>
+S:	Petr Hodina <petr.hodina@protonmail.com>
+F:	Documentation/devicetree/bindings/iio/light/ams,tcs3400.yaml
+
 ROHM BH1745 COLOUR SENSOR
 M:	Mudit Sharma <muditsharma.info@gmail.com>
 L:	linux-iio@vger.kernel.org

-- 
2.52.0

