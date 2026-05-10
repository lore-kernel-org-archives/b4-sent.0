From: Alexandre Hamamdjian <azkali.limited@gmail.com>
Date: Sun, 10 May 2026 23:45:26 +0700
Subject: [PATCH 1/2] dt-bindings: regulator: add SGMicro SGM3804
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260510-sgm3804-v1-1-e5e8799e0aa0@gmail.com>
References: <20260510-sgm3804-v1-0-e5e8799e0aa0@gmail.com>
In-Reply-To: <20260510-sgm3804-v1-0-e5e8799e0aa0@gmail.com>
To: Philippe Simons <simons.philippe@gmail.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Alexandre Hamamdjian <azkali.limited@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778431530; l=3403;
 i=azkali.limited@gmail.com; s=20260510; h=from:subject:message-id;
 bh=XWCit0ZA8mWCGZuR1y+fa+IVWSjOU74cPNIGW9a/Ktg=;
 b=q+S2dD3+5X5wiS4eT8yx5WrFzrWAMjwfyP7tLlbhkN/NMfC15a/0lX3B7erDP9wzJsLsBfzJG
 Ozp7cAjPws9A7AaLohjX6+5Wqx02KVdZCtwcR2VTSzhH2YuQfljTisV
X-Developer-Key: i=azkali.limited@gmail.com; a=ed25519;
 pk=I0Z0IdCdQJqNGX+FQUnXhrHg950u3cM6Xzz3YT6JOyQ=
X-Endpoint-Received: by B4 Relay for azkali.limited@gmail.com/20260510 with auth_id=774
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SGMicro SGM3804 is an I2C-controlled positive and negative output
charge-pump regulator. It is commonly used to provide the AVDD and AVEE
supplies for display panels, and exposes two reset GPIOs to sequence the
positive and negative output rails independently.

Document the binding for the new compatible "sgmicro,sgm3804" so it can
be referenced by board device trees and the matching driver, and add a
MAINTAINERS entry covering both the binding and the upcoming driver.

Co-developed-by: Philippe Simons <simons.philippe@gmail.com>
Signed-off-by: Philippe Simons <simons.philippe@gmail.com>
Signed-off-by: Alexandre Hamamdjian <azkali.limited@gmail.com>
---
 .../bindings/regulator/sgmicro,sgm3804.yaml        | 60 ++++++++++++++++++++++
 MAINTAINERS                                        |  7 +++
 2 files changed, 67 insertions(+)

diff --git a/Documentation/devicetree/bindings/regulator/sgmicro,sgm3804.yaml b/Documentation/devicetree/bindings/regulator/sgmicro,sgm3804.yaml
new file mode 100644
index 000000000000..f1de17bd5395
--- /dev/null
+++ b/Documentation/devicetree/bindings/regulator/sgmicro,sgm3804.yaml
@@ -0,0 +1,60 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/regulator/sgmicro,sgm3804.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: SGMicro SGM3804 I2C charge-pump regulator
+
+maintainers:
+  - Alexandre Hamamdjian <azkali.limited@gmail.com>
+  - Philippe Simons <simons.philippe@gmail.com>
+
+description:
+  The SGM3804 is an I2C-controlled positive and negative output charge-pump
+  regulator typically used to provide the AVDD and AVEE supplies for display
+  panels. Two reset GPIOs are used to sequence the positive and negative
+  outputs independently.
+
+allOf:
+  - $ref: regulator.yaml#
+
+properties:
+  compatible:
+    const: sgmicro,sgm3804
+
+  reg:
+    maxItems: 1
+
+  reset-gpios:
+    minItems: 1
+    maxItems: 2
+    description:
+      Reset/enable GPIOs for the positive (index 0) and, optionally, the
+      negative (index 1) output rails.
+
+required:
+  - compatible
+  - reg
+  - reset-gpios
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        regulator@3e {
+            compatible = "sgmicro,sgm3804";
+            reg = <0x3e>;
+            reset-gpios = <&tlmm 10 GPIO_ACTIVE_HIGH>,
+                          <&tlmm 11 GPIO_ACTIVE_HIGH>;
+            regulator-name = "panel-avdd";
+            regulator-min-microvolt = <5000000>;
+            regulator-max-microvolt = <5000000>;
+        };
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index f877e5aaf2c7..394216175d2e 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -24391,6 +24391,13 @@ M:	Steve Wahl <steve.wahl@hpe.com>
 S:	Maintained
 F:	drivers/misc/sgi-xp/
 
+SGMICRO SGM3804 REGULATOR DRIVER
+M:	Alexandre Hamamdjian <azkali.limited@gmail.com>
+M:	Philippe Simons <simons.philippe@gmail.com>
+S:	Maintained
+F:	Documentation/devicetree/bindings/regulator/sgmicro,sgm3804.yaml
+F:	drivers/regulator/sgm3804-regulator.c
+
 SHARED MEMORY COMMUNICATIONS (SMC) SOCKETS
 M:	D. Wythe <alibuda@linux.alibaba.com>
 M:	Dust Li <dust.li@linux.alibaba.com>

-- 
2.54.0

