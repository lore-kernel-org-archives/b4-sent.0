From: George Chan <gchan9527@gmail.com>
Date: Tue, 15 Oct 2024 20:53:29 +0800
Subject: [PATCH RFC/RFT 1/3] dt-bindings: touchscreen: Add binding for
 Novatek NT36xxx series driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241015-nt36xxx-v1-1-3919d0bffee6@gmail.com>
References: <20241015-nt36xxx-v1-0-3919d0bffee6@gmail.com>
In-Reply-To: <20241015-nt36xxx-v1-0-3919d0bffee6@gmail.com>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Del Regno <kholk11@gmail.com>, 
 Henrik Rydberg <rydberg@bitmath.org>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, George Chan <gchan9527@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1728996810; l=2336;
 i=gchan9527@gmail.com; s=20241015; h=from:subject:message-id;
 bh=6oXy8utpLvYCjX6FpS5vMO4JWOmudlGhgWpN7w1GKpA=;
 b=CWp38R0kg4uaRnXXylbmhUTfN0jCdb9ZlwmWTWEB23Q+QeTeiwx1ni+IxplTJCJ1KKwRp0uKk
 X7ejSsE16zZA5e6/vpxusNPxamsZPsFqVl7osdTto0WB7CYSF86tKyR
X-Developer-Key: i=gchan9527@gmail.com; a=ed25519;
 pk=dscYWhT+BiQOBMpPE19NFQAjBBmcpipc6zdf2MTze/U=
X-Endpoint-Received: by B4 Relay for gchan9527@gmail.com/20241015 with auth_id=248
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add binding for the Novatek NT36xxx series touchscreen driver.

Signed-off-by: AngeloGioacchino Del Regno <kholk11@gmail.com>
Signed-off-by: George Chan <gchan9527@gmail.com>
---
 .../bindings/input/touchscreen/nt36xxx.yaml        | 70 ++++++++++++++++++++++
 1 file changed, 70 insertions(+)

diff --git a/Documentation/devicetree/bindings/input/touchscreen/nt36xxx.yaml b/Documentation/devicetree/bindings/input/touchscreen/nt36xxx.yaml
new file mode 100644
index 0000000000..3919f0d026
--- /dev/null
+++ b/Documentation/devicetree/bindings/input/touchscreen/nt36xxx.yaml
@@ -0,0 +1,70 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/input/touchscreen/nt36xxx.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Novatek NT36xxx series touchscreen controller Bindings
+
+maintainers:
+  - AngeloGioacchino Del Regno <kholk11@gmail.com>
+  - George Chan <gchan9527@gmail.com>
+
+allOf:
+  - $ref: touchscreen.yaml#
+
+properties:
+  compatible:
+    enum:
+        - novatek,nt36525-spi
+        - novatek,nt36672a-spi
+        - novatek,nt36675-spi
+        - novatek,nt36676f-spi
+        - novatek,nt36772-spi
+
+  reg:
+    maxItems: 1
+
+  irq-gpio:
+    maxItems: 1
+
+  vdd-supply:
+    description: Power supply regulator for VDD pin
+
+  vio-supply:
+    description: Power supply regulator on VDD-IO pin
+
+  firmware-name:
+    description: Firmware for device initialization, if unspecify, all
+                  other IC treat as no firmware needed. For nt36675, default
+                  to "novatek_ts_tianma_fw.bin".
+
+  spi-max-frequency:
+    description: Set max frequency to spi bus communication. This is optional.
+
+unevaluatedProperties: false
+
+required:
+  - compatible
+  - reg
+  - irq-gpio
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/irq.h>
+    #include <dt-bindings/gpio/gpio.h>
+
+    spi {
+      #address-cells = <1>;
+      #size-cells = <0>;
+
+      touchscreen@0 {
+        compatible = "novatek,nt36675-spi";
+        reg = <0>;
+        spi-max-frequency = <4000000>;
+        irq-gpio = <&tlmm 9 0x2001>;
+        firmware-name = "novatek_ts_tianma_fw.bin";
+      };
+    };
+
+...

-- 
2.43.0

