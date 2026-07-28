From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 28 Jul 2026 17:03:51 +0100
Subject: [PATCH 4/5] dt-bindings: hwmon/pmbus: Document MAX20826 and
 similar devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260728-hwmon-max20826-support-v1-4-224766e0acd1@analog.com>
References: <20260728-hwmon-max20826-support-v1-0-224766e0acd1@analog.com>
In-Reply-To: <20260728-hwmon-max20826-support-v1-0-224766e0acd1@analog.com>
To: linux-hwmon@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-doc@vger.kernel.org
Cc: Mark Brown <broonie@kernel.org>, 
 Alan Tull <atull@opensource.altera.com>, Guenter Roeck <linux@roeck-us.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Alexis Czezar Torreno <alexisczezar.torreno@analog.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785254629; l=3112;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=kkxkPuAr8r9C2BFfsr9GKXUusi7kxUwS7LZSffvIXhU=;
 b=zqGK7puAKOZaV6S/5MGhCAOD5knjNz+BCV2WduhmPN8fHxpqS0es+dzQu9lBnHElPpS7rScdo
 leIc9eCnwznB84Yw/oHFhyxrlUXqj+y6g0K0bknQmd+WSJPZ2/YBdwt
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MAX20826 IC and similar provide a high-density, flexible and scalable
dual-loop solution for high current cores for AI applications. These are
dual loop solutions multiphase voltage regulators. Between Rails A and B,
MAX20855B and MAX20908 supports up to 8 phases total configurable from
8+0 to 4+4 phases, MAX20912 supports up to 12 phases from 12+0 to 6+6,
and MAX20826 and MAX20916 supports up to 16 phases from 16+0 to 8+8.

Co-developed-by: Alexis Czezar Torreno <alexisczezar.torreno@analog.com>
Signed-off-by: Alexis Czezar Torreno <alexisczezar.torreno@analog.com>
Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 .../bindings/hwmon/pmbus/adi,max20826.yaml         | 56 ++++++++++++++++++++++
 MAINTAINERS                                        |  7 +++
 2 files changed, 63 insertions(+)

diff --git a/Documentation/devicetree/bindings/hwmon/pmbus/adi,max20826.yaml b/Documentation/devicetree/bindings/hwmon/pmbus/adi,max20826.yaml
new file mode 100644
index 000000000000..6d280f8bf56b
--- /dev/null
+++ b/Documentation/devicetree/bindings/hwmon/pmbus/adi,max20826.yaml
@@ -0,0 +1,56 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/hwmon/pmbus/adi,max20826.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Analog Devices MAX20826 PMBus Voltage Regulator
+
+maintainers:
+  - Nuno Sá <nuno.sa@analog.com>
+
+description:
+  Analog Devices MAX20826 and similar devices are Dual-Output Multiphase
+  High-Current Controller.
+
+properties:
+  compatible:
+    enum:
+      - adi,max20826
+      - adi,max20855b
+      - adi,max20908
+      - adi,max20912
+      - adi,max20916
+
+  reg:
+    maxItems: 1
+
+  avren-gpios:
+    description: GPIO pin to enable/disable the output voltage on Rail A.
+    maxItems: 1
+
+  bvren-gpios:
+    description: GPIO pin to enable/disable the output voltage on Rail B.
+    maxItems: 1
+
+required:
+  - compatible
+  - reg
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        regulator@64 {
+            compatible = "adi,max20826";
+            reg = <0x64>;
+
+            avren-gpios = <&gpio 0 GPIO_ACTIVE_HIGH>;
+            bvren-gpios = <&gpio 1 GPIO_ACTIVE_HIGH>;
+        };
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index 716acfc3d7c1..fe8808f3ee4c 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -15837,6 +15837,13 @@ F:	Documentation/devicetree/bindings/hwmon/pmbus/adi,max17616.yaml
 F:	Documentation/hwmon/max17616.rst
 F:	drivers/hwmon/pmbus/max17616.c
 
+MAX20826 HARDWARE MONITOR CONTROLLER DRIVER
+M:	Nuno Sá <nuno.sa@analog.com>
+L:	linux-hwmon@vger.kernel.org
+S:	Supported
+W:	https://ez.analog.com/linux-software-drivers
+F:	Documentation/devicetree/bindings/hwmon/pmbus/adi,max20826.yaml
+
 MAX20830 HARDWARE MONITOR DRIVER
 M:	Alexis Czezar Torreno <alexisczezar.torreno@analog.com>
 L:	linux-hwmon@vger.kernel.org

-- 
2.55.0

