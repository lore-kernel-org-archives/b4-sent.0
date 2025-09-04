From: Gregory Fuchedgi <gfuchedgi@gmail.com>
Date: Thu, 04 Sep 2025 10:33:44 -0700
Subject: [PATCH v3 1/2] dt-bindings: hwmon: update TI TPS23861 with
 per-port schema
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250904-hwmon-tps23861-add-class-restrictions-v3-1-b4e33e6d066c@gmail.com>
References: <20250904-hwmon-tps23861-add-class-restrictions-v3-0-b4e33e6d066c@gmail.com>
In-Reply-To: <20250904-hwmon-tps23861-add-class-restrictions-v3-0-b4e33e6d066c@gmail.com>
To: Robert Marko <robert.marko@sartura.hr>, 
 Luka Perkov <luka.perkov@sartura.hr>, Jean Delvare <jdelvare@suse.com>, 
 Guenter Roeck <linux@roeck-us.net>, Jonathan Corbet <corbet@lwn.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-hwmon@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Gregory Fuchedgi <gfuchedgi@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757007242; l=3648;
 i=gfuchedgi@gmail.com; s=20250811; h=from:subject:message-id;
 bh=SKYcjxqEAKKTKyENkgiukshEk5CgSMUj+twbpURzbYg=;
 b=/ilmcY7LFjTKx+CUoGtzhjHpcAqskiBdnOZplChgwKAHiOuiN9z7Bylnp5qTlApxT4UQcWjff
 z6Xjk1QaQy7CeX9mgY5YmCfml+L/B9CvsDySr9xdpyq7o5WNoyC50oR
X-Developer-Key: i=gfuchedgi@gmail.com; a=ed25519;
 pk=J3o48+1a2mUIebH8K4S3SPuR5bmamUvjlsf8onoIccA=
X-Endpoint-Received: by B4 Relay for gfuchedgi@gmail.com/20250811 with auth_id=484
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update schema after per-port poe class restrictions and a few other options
were implemented.

Signed-off-by: Gregory Fuchedgi <gfuchedgi@gmail.com>
---
 .../devicetree/bindings/hwmon/ti,tps23861.yaml     | 93 +++++++++++++++++++++-
 1 file changed, 92 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/hwmon/ti,tps23861.yaml b/Documentation/devicetree/bindings/hwmon/ti,tps23861.yaml
index ee7de53e19184d4c3df7564624532306d885f6e4..7538d1a9c19905ec90c48d34f84a92c1972f566b 100644
--- a/Documentation/devicetree/bindings/hwmon/ti,tps23861.yaml
+++ b/Documentation/devicetree/bindings/hwmon/ti,tps23861.yaml
@@ -24,12 +24,60 @@ properties:
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
+    description: GPIO for the reset pin.
+    maxItems: 1
+
+  ti,ports-shutdown-gpios:
+    description:
+      GPIO for the shutdown pin. Used to prevent PoE activity before the driver
+      had a chance to configure the chip.
+    maxItems: 1
+
+  interrupts:
+    description:
+      Only required if PoE class is restricted to less than class 4 in the
+      device tree.
+    maxItems: 1
+
+patternProperties:
+  "^poe-port@[0-3]$":
+    type: object
+    description: Port specific nodes.
+    unevaluatedProperties: false
+    properties:
+      reg:
+        description: Port index.
+        items:
+          maximum: 3
+
+      ti,class:
+        description: The maximum power class a port should accept.
+        $ref: /schemas/types.yaml#/definitions/uint32
+        maximum: 4
+
+      ti,off-by-default:
+        description: Indicates the port is off by default.
+        type: boolean
+
+      label:
+        description: Port label.
+
+    required:
+      - reg
+
 required:
   - compatible
   - reg
@@ -45,9 +93,52 @@ examples:
         #address-cells = <1>;
         #size-cells = <0>;
 
-        tps23861@30 {
+        poe_controller@30 {
             compatible = "ti,tps23861";
             reg = <0x30>;
             shunt-resistor-micro-ohms = <255000>;
         };
     };
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+    #include <dt-bindings/interrupt-controller/irq.h>
+
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        poe_controller@28 {
+            compatible = "ti,tps23861";
+            reg = <0x28>;
+            #address-cells = <1>;
+            #size-cells = <0>;
+            shunt-resistor-micro-ohms = <255000>;
+            interrupt-parent = <&gpio1>;
+            interrupts = <14 IRQ_TYPE_EDGE_FALLING>;
+            label = "cabinet_poe_controller";
+            reset-gpios = <&gpio1 13 GPIO_ACTIVE_LOW>;
+            ti,ports-shutdown-gpios = <&gpio1 12 GPIO_ACTIVE_LOW>;
+
+            poe-port@0 {
+                    reg = <0>;
+                    ti,class = <2>; // Max PoE class allowed.
+                    ti,off-by-default;
+                    label = "cabinet_port_a";
+            };
+
+            poe-port@1 {
+                    reg = <1>;
+                    status = "disabled";
+            };
+
+            poe-port@2 {
+                    reg = <2>;
+                    status = "disabled";
+            };
+
+            poe-port@3 {
+                    reg = <3>;
+                    status = "disabled";
+            };
+        };
+    };

-- 
2.43.0

