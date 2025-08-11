From: Gregory Fuchedgi <gfuchedgi@gmail.com>
Date: Mon, 11 Aug 2025 09:13:16 -0700
Subject: [PATCH v2 2/2] dt-bindings: hwmon: update TI TPS23861 bindings
 with per-port schema
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250811-hwmon-tps23861-add-class-restrictions-v2-2-ebd122ec5e3b@gmail.com>
References: <20250811-hwmon-tps23861-add-class-restrictions-v2-0-ebd122ec5e3b@gmail.com>
In-Reply-To: <20250811-hwmon-tps23861-add-class-restrictions-v2-0-ebd122ec5e3b@gmail.com>
To: Robert Marko <robert.marko@sartura.hr>, 
 Luka Perkov <luka.perkov@sartura.hr>, Jean Delvare <jdelvare@suse.com>, 
 Guenter Roeck <linux@roeck-us.net>, Jonathan Corbet <corbet@lwn.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-hwmon@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Gregory Fuchedgi <gfuchedgi@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754928795; l=3382;
 i=gfuchedgi@gmail.com; s=20250811; h=from:subject:message-id;
 bh=xpxZZVQduuI8ZuEwYXxZY5dWL1ZqA8Vhj1NRk9pc398=;
 b=m5Lxo8KQLpI997ER/UiJ0xI+2VYJHDsJ2jPXs0/xlemcSbFSNwbzrZoWx4dDYFdjq1q4uE6ve
 l3OImKrhu0KA1/5bHCH47MTf4EbQlfBUO1UkgJQg5uzrlwDRuvQmCqp
X-Developer-Key: i=gfuchedgi@gmail.com; a=ed25519;
 pk=J3o48+1a2mUIebH8K4S3SPuR5bmamUvjlsf8onoIccA=
X-Endpoint-Received: by B4 Relay for gfuchedgi@gmail.com/20250811 with auth_id=484
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update schema after per-port poe class restrictions and a few other options
were implemented.

Signed-off-by: Gregory Fuchedgi <gfuchedgi@gmail.com>
---
 .../devicetree/bindings/hwmon/ti,tps23861.yaml     | 86 ++++++++++++++++++++++
 1 file changed, 86 insertions(+)

diff --git a/Documentation/devicetree/bindings/hwmon/ti,tps23861.yaml b/Documentation/devicetree/bindings/hwmon/ti,tps23861.yaml
index ee7de53e19184d4c3df7564624532306d885f6e4..578f4dad7eab630b218e9e30b23fc611a760d332 100644
--- a/Documentation/devicetree/bindings/hwmon/ti,tps23861.yaml
+++ b/Documentation/devicetree/bindings/hwmon/ti,tps23861.yaml
@@ -24,12 +24,62 @@ properties:
   reg:
     maxItems: 1
 
+  '#address-cells':
+    const: 1
+
+  '#size-cells':
+    const: 0
+
   shunt-resistor-micro-ohms:
     description: The value of current sense resistor in microohms.
     default: 255000
     minimum: 250000
     maximum: 255000
 
+  reset-gpios:
+    description: Optional GPIO for the reset pin.
+    maxItems: 1
+
+  shutdown-gpios:
+    description: |
+      Optional GPIO for the shutdown pin. Used to prevent PoE activity before
+      the driver had a chance to configure the chip.
+    maxItems: 1
+
+  interrupts:
+    description: |
+      The interrupt specifier. Only required if PoE class is restricted to less
+      than class 4 in the device tree.
+    maxItems: 1
+
+patternProperties:
+  "^port@[0-3]$":
+    type: object
+    description: Port specific nodes.
+    unevaluatedProperties: false
+    required:
+      - reg
+
+    properties:
+      reg:
+        description: Port index.
+        items:
+          minimum: 0
+          maximum: 3
+
+      class:
+        description: The maximum power class a port should accept.
+        $ref: /schemas/types.yaml#/definitions/uint32
+        minimum: 0
+        maximum: 4
+
+      off-by-default:
+        description: Indicates the port is off by default.
+        type: boolean
+
+      label:
+        description: Optional port label
+
 required:
   - compatible
   - reg
@@ -51,3 +101,39 @@ examples:
             shunt-resistor-micro-ohms = <255000>;
         };
     };
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+        tps23861@28 {
+            #address-cells = <1>;
+            #size-cells = <0>;
+            compatible = "ti,tps23861";
+            reg = <0x28>;
+            shunt-resistor-micro-ohms = <255000>;
+            reset-gpios = <&gpio1 13 GPIO_ACTIVE_LOW>;
+            shutdown-gpios = <&gpio1 12 GPIO_ACTIVE_LOW>;
+            interrupt-parent = <&gpio1>;
+            interrupts = <14 0>;
+            label = "my_poe_controller";
+            port@0 {
+                    reg = <0>;
+                    class = <2>; // Max PoE class allowed.
+                    off-by-default;
+                    label = "myport";
+            };
+            port@1 {
+                    reg = <1>;
+                    status = "disabled";
+            };
+            port@2 {
+                    reg = <2>;
+                    status = "disabled";
+            };
+            port@3 {
+                    reg = <3>;
+                    status = "disabled";
+            };
+        };
+    };

-- 
2.43.0

