From: Thomas Antoine <t.antoine@uclouvain.be>
Date: Mon, 15 Sep 2025 12:14:11 +0200
Subject: [PATCH v6 2/2] dt-bindings: power: supply: add support for
 MAX77759 fuel gauge
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250915-b4-gs101_max77759_fg-v6-2-31d08581500f@uclouvain.be>
References: <20250915-b4-gs101_max77759_fg-v6-0-31d08581500f@uclouvain.be>
In-Reply-To: <20250915-b4-gs101_max77759_fg-v6-0-31d08581500f@uclouvain.be>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sebastian Reichel <sre@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 =?utf-8?q?Andr=C3=A9_Draszik?= <andre.draszik@linaro.org>
Cc: linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 devicetree@vger.kernel.org, Thomas Antoine <t.antoine@uclouvain.be>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757931256; l=3462;
 i=t.antoine@uclouvain.be; s=20241202; h=from:subject:message-id;
 bh=RmrJkFcdKdGw/nW9mrN2NqAI0SHNuIVBB+BVTG5fu5w=;
 b=hlTQFthVMw1e+fIMoGX7ZzBZTtDfMDVZ4HJOwUPGLh7Pdjnr032ocqXmFWxuIkKD+btGyotPc
 uINIS045cq4BE2MWbKh7rBGhv620OIMxlAtpKAveKZiNv17bMPfc/yV
X-Developer-Key: i=t.antoine@uclouvain.be; a=ed25519;
 pk=sw7UYl31W1LTpgWRiX4xIF5x6ok7YWZ6XZnHqy/d3dY=
X-Endpoint-Received: by B4 Relay for t.antoine@uclouvain.be/20241202 with auth_id=289
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Maxim MAX77759 is a companion PMIC for USB Type-C. It contains
Battery Charger, Fuel Gauge, temperature sensors, USB Type-C Port
Controller (TCPC), NVMEM, and additional GPIO interfaces

Use max77759-fg compatible to avoid conflict with drivers for other
functions.

The battery node is used to pass the REPCAP and ICHGTERM values
needed for the initialization of the fuel gauge.

The nvmem cells are used to get initialization values and to backup
the learning and the number of cycles. It should work out of the box
with gs101-oriole and gs101-raven which were previously running
Android.

Signed-off-by: Thomas Antoine <t.antoine@uclouvain.be>
---
 .../bindings/power/supply/maxim,max77759.yaml      | 78 ++++++++++++++++++++++
 1 file changed, 78 insertions(+)

diff --git a/Documentation/devicetree/bindings/power/supply/maxim,max77759.yaml b/Documentation/devicetree/bindings/power/supply/maxim,max77759.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..4d45739fcaf26273ec57b60049d6d0421df38efb
--- /dev/null
+++ b/Documentation/devicetree/bindings/power/supply/maxim,max77759.yaml
@@ -0,0 +1,78 @@
+# SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/power/supply/maxim,max77759.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Maxim Integrated MAX77759 fuel gauge
+
+maintainers:
+  - Thomas Antoine <t.antoine@uclouvain.be>
+
+allOf:
+  - $ref: power-supply.yaml#
+
+properties:
+  compatible:
+    const: maxim,max77759-fg
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    maxItems: 1
+
+  shunt-resistor-micro-ohms:
+    description: The value of the current sense resistor in microohms.
+
+  monitored-battery:
+    description: |
+      The fuel gauge needs the following battery properties:
+      - charge-full-design-microamp-hours
+      - charge-term-current-microamp
+
+  nvmem-cells:
+    maxItems: 1
+    description: |
+      Saved fuel gauge state. This state will be used during the initialization
+      and saved on exit. It must be initialized beforehand.
+      Its layout must be composed of
+        - RCOMP0 (characterization of the open-circuit voltage)
+        - TCOMPO (temperature compensation information)
+        - FULLCAPREP (reported full capacity)
+        - QRTABLE00, QRTABLE10, QRTABLE20, QRTABLE30 (cell capacity information)
+        - cv_mixcap (remaining capacity of the cell without empty compensation)
+        - cv_halftime (time-to-full characterization time constant)
+      They must all be aligned on 2 bytes. A valid CRC8 checksum must
+      also be found at the end (polynomial x^8 + x^2 + x + 1).
+
+  nvmem-cell-names:
+    const: fg_state
+
+required:
+  - compatible
+  - reg
+  - shunt-resistor-micro-ohms
+  - monitored-battery
+  - nvmem-cells
+  - nvmem-cell-names
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/irq.h>
+    i2c {
+      #address-cells = <1>;
+      #size-cells = <0>;
+
+      fuel-gauge@36 {
+        compatible = "maxim,max77759-fg";
+        reg = <0x36>;
+        interrupts-extended = <&gpa9 3 IRQ_TYPE_LEVEL_LOW>;
+        shunt-resistor-micro-ohms = <5000>;
+        monitored-battery = <&battery>;
+        nvmem-cells = <&fg_state>;
+        nvmem-cell-names = "fg_state";
+      };
+    };

-- 
2.51.0

