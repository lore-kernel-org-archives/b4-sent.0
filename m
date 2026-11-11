From: Asdlerto Korry <korryasdlerto@gmail.com>
Date: Wed, 11 Nov 2026 17:34:59 +0200
Subject: [PATCH 1/2] dt-bindings: power: supply: Add Silicon Mitus SM5714
 fuel gauge
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-sm5714-fuel-gauge-v1-1-b9d163fff6ff@gmail.com>
References: <20261111-sm5714-fuel-gauge-v1-0-b9d163fff6ff@gmail.com>
In-Reply-To: <20261111-sm5714-fuel-gauge-v1-0-b9d163fff6ff@gmail.com>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Asdlerto Korry <korryasdlerto@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794411298; l=2367;
 i=korryasdlerto@gmail.com; s=20261104; h=from:subject:message-id;
 bh=l9dRAjJonPbniX5sdrRnnL5yQqFuAZe21X2uph8Yb7s=;
 b=oBEF4DLZSmYt5qhnuCWRprl7mJpMOgHC+cZY1+lCyQmqM2f2vWsfHYW1skKFWv3IpKTgwsCg/
 ThQzAUvqTk2A52gsXON6Thy64SeI+6Ts8BpCm01d0GwDdnd5HXFEkw5
X-Developer-Key: i=korryasdlerto@gmail.com; a=ed25519;
 pk=RqttIGkm2XZ8NhLQBzPgpXXawOdVa1uODGsk+sagbxs=
X-Endpoint-Received: by B4 Relay for korryasdlerto@gmail.com/20261104 with auth_id=1411
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SM5714 is a power management chip for mobile phones that combines a
charger, a USB Type-C port controller, a MUIC and a fuel gauge, each on
its own I2C address. It is used in the Samsung Galaxy M52 5G.

Add a binding for the fuel gauge. The temperature measured by the gauge
itself rises with the charge current, so an optional ADC channel can
point at the battery thermistor.

Signed-off-by: Asdlerto Korry <korryasdlerto@gmail.com>
---
 .../supply/siliconmitus,sm5714-fuelgauge.yaml      | 53 ++++++++++++++++++++++
 1 file changed, 53 insertions(+)

diff --git a/Documentation/devicetree/bindings/power/supply/siliconmitus,sm5714-fuelgauge.yaml b/Documentation/devicetree/bindings/power/supply/siliconmitus,sm5714-fuelgauge.yaml
new file mode 100644
index 000000000000..af51db8cf13d
--- /dev/null
+++ b/Documentation/devicetree/bindings/power/supply/siliconmitus,sm5714-fuelgauge.yaml
@@ -0,0 +1,53 @@
+# SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/power/supply/siliconmitus,sm5714-fuelgauge.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Silicon Mitus SM5714 fuel gauge
+
+maintainers:
+  - Asdlerto Korry <korryasdlerto@gmail.com>
+
+description:
+  The SM5714 is a power management chip for mobile phones with a charger,
+  a USB Type-C port controller, a MUIC and a fuel gauge, each on its own
+  I2C address. This binding describes the fuel gauge, which reports the
+  battery state of charge, voltage and current.
+
+allOf:
+  - $ref: power-supply.yaml#
+
+properties:
+  compatible:
+    const: siliconmitus,sm5714-fuelgauge
+
+  reg:
+    maxItems: 1
+
+  io-channels:
+    maxItems: 1
+    description:
+      ADC channel that reports the temperature of the battery thermistor.
+      The temperature measured by the fuel gauge itself rises with the
+      charge current, so the battery temperature is taken from this
+      channel when it is present.
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
+      #address-cells = <1>;
+      #size-cells = <0>;
+
+      fuel-gauge@71 {
+        compatible = "siliconmitus,sm5714-fuelgauge";
+        reg = <0x71>;
+        io-channels = <&pmk8350_vadc 0x14b>;
+      };
+    };

-- 
2.25.1

