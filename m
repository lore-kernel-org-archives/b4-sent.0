From: Nizat Mikayilli <nacht@dxdmail.cc>
Date: Sun, 08 Nov 2026 12:22:25 +0100
Subject: [PATCH 1/2] dt-bindings: power: supply: Add Silicon Mitus SM5714
 fuel gauge
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-b4-sm5714-fuel-gauge-v1-1-c659b6c0884a@dxdmail.cc>
References: <20261108-b4-sm5714-fuel-gauge-v1-0-c659b6c0884a@dxdmail.cc>
In-Reply-To: <20261108-b4-sm5714-fuel-gauge-v1-0-c659b6c0884a@dxdmail.cc>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Nizat Mikayilli <nacht@dxdmail.cc>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794136945; l=2545;
 i=nacht@dxdmail.cc; s=20261004; h=from:subject:message-id;
 bh=Cmh7YjU6/OabK3s0Tan26kUaXZen4FX7P/sskBlVdP0=;
 b=i4iCortCNP29TqalR0jK9yohaOIfM5L3HjlJHL47n1R9XTWJmh+DN7gyPc1B7YgVeMMcLSnIJ
 x7vjEp53nlmCuXaUVO2DQIacLXFXyVBzMC/cbuQqQwsAkJcO1F7Mdfp
X-Developer-Key: i=nacht@dxdmail.cc; a=ed25519;
 pk=Kay3P3pOJq5klUD+0/I8QX8JGOh0CeQXEwRVv7CMm4k=
X-Endpoint-Received: by B4 Relay for nacht@dxdmail.cc/20261004 with auth_id=1111
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Silicon Mitus SM5714 includes a MUIC, a charger and a fuel gauge,
each at its own I2C address. Add a binding for the fuel gauge as a
separate device, like the MAX77705 fuel gauge.

Signed-off-by: Nizat Mikayilli <nacht@dxdmail.cc>
---
 .../supply/siliconmitus,sm5714-fuel-gauge.yaml     | 47 ++++++++++++++++++++++
 MAINTAINERS                                        |  6 +++
 2 files changed, 53 insertions(+)

diff --git a/Documentation/devicetree/bindings/power/supply/siliconmitus,sm5714-fuel-gauge.yaml b/Documentation/devicetree/bindings/power/supply/siliconmitus,sm5714-fuel-gauge.yaml
new file mode 100644
index 000000000000..777b64bade5d
--- /dev/null
+++ b/Documentation/devicetree/bindings/power/supply/siliconmitus,sm5714-fuel-gauge.yaml
@@ -0,0 +1,47 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/power/supply/siliconmitus,sm5714-fuel-gauge.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Silicon Mitus SM5714 fuel gauge
+
+maintainers:
+  - Nizat Mikayilli <nacht@dxdmail.cc>
+
+description:
+  The Silicon Mitus SM5714 includes a MUIC, a battery charger with a flash LED
+  driver and a fuel gauge, each on its own I2C address. The fuel gauge measures
+  the battery voltage and current and estimates the state of charge.
+
+allOf:
+  - $ref: power-supply.yaml#
+
+properties:
+  compatible:
+    const: siliconmitus,sm5714-fuel-gauge
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    maxItems: 1
+
+required:
+  - compatible
+  - reg
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        fuel-gauge@71 {
+            compatible = "siliconmitus,sm5714-fuel-gauge";
+            reg = <0x71>;
+            monitored-battery = <&battery>;
+        };
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index 93abbb315065..2875017d21c2 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -25713,6 +25713,12 @@ S:	Supported
 F:	Documentation/devicetree/bindings/net/wireless/silabs,wfx.yaml
 F:	drivers/net/wireless/silabs/
 
+SILICON MITUS SM5714 FUEL GAUGE DRIVER
+M:	Nizat Mikayilli <nacht@dxdmail.cc>
+L:	linux-pm@vger.kernel.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/power/supply/siliconmitus,sm5714-fuel-gauge.yaml
+
 SILICON MOTION SM712 FRAME BUFFER DRIVER
 M:	Sudip Mukherjee <sudipm.mukherjee@gmail.com>
 M:	Teddy Wang <teddy.wang@siliconmotion.com>

-- 
2.56.0

