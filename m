From: Sven Peter <sven@kernel.org>
Date: Sun, 09 Aug 2026 14:16:02 +0200
Subject: [PATCH 1/3] dt-bindings: reset: Add Apple SoC CIO reset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260809-b4-cio-reset-v1-1-4f33777d9b4b@kernel.org>
References: <20260809-b4-cio-reset-v1-0-4f33777d9b4b@kernel.org>
In-Reply-To: <20260809-b4-cio-reset-v1-0-4f33777d9b4b@kernel.org>
To: Sven Peter <sven@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4500; i=sven@kernel.org;
 h=from:subject:message-id; bh=GS0706aWd/X1ewhqfLjE66a5N9etk1CxR3PFk3+EnSU=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ1ZFfnvIvV2XKu9/dQityzjywVMjbFLbU1t2sTz2zcu/C
 vu3PDvbUcrCIMbFICumyLJ9v73pk4dvBJduuvQeZg4rE8gQBi5OAZhI+zKGf2bbsph/HAnbsvRP
 dYCOQNzN/F2x9Wx91cbr5L6pGP5/rMDwV2Ry7KQTYomhSU9zG2PiGVsCi99bMp98+DZf0PzbZpU
 nnAA=
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The CIO (USB4/Thunderbolt) blocks on Apple Silicon SoCs have a reset
inside the power manager that has to be deasserted before their
co-processor can be booted. On t8103 each port comes with a dedicated
register page, represented as a standalone node. On t600x a single
register shared by all ports of a die is located in the middle of the
PMGR MMIO region instead, represented as a sub-node of the PMGR syscon.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 .../devicetree/bindings/arm/apple/apple,pmgr.yaml  |  6 ++
 .../bindings/reset/apple,t8103-cio-reset.yaml      | 74 ++++++++++++++++++++++
 MAINTAINERS                                        |  1 +
 3 files changed, 81 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/apple/apple,pmgr.yaml b/Documentation/devicetree/bindings/arm/apple/apple,pmgr.yaml
index c67b67ba065a..2cdecc2c2cea 100644
--- a/Documentation/devicetree/bindings/arm/apple/apple,pmgr.yaml
+++ b/Documentation/devicetree/bindings/arm/apple/apple,pmgr.yaml
@@ -59,6 +59,12 @@ patternProperties:
     type: object
     $ref: /schemas/power/apple,pmgr-pwrstate.yaml#
 
+  "reset-controller@[0-9a-f]+$":
+    description:
+      Reset controller for the CIO (USB4/Thunderbolt) blocks
+    type: object
+    $ref: /schemas/reset/apple,t8103-cio-reset.yaml#
+
 required:
   - compatible
   - reg
diff --git a/Documentation/devicetree/bindings/reset/apple,t8103-cio-reset.yaml b/Documentation/devicetree/bindings/reset/apple,t8103-cio-reset.yaml
new file mode 100644
index 000000000000..5f5be0636b36
--- /dev/null
+++ b/Documentation/devicetree/bindings/reset/apple,t8103-cio-reset.yaml
@@ -0,0 +1,74 @@
+# SPDX-License-Identifier: GPL-2.0 OR BSD-2-Clause
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/reset/apple,t8103-cio-reset.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Apple SoC CIO (USB4/Thunderbolt) block reset controller
+
+maintainers:
+  - Sven Peter <sven@kernel.org>
+
+description: |
+  The CIO (Converged I/O) blocks on Apple Silicon SoCs have a reset
+  inside the power manager (PMGR) that has to be deasserted before
+  their co-processor can be booted. On t8103 each port comes with a
+  dedicated register page, represented as a standalone node. On t600x a
+  single register shared by all ports of a die with one request bit per
+  port is used instead. Since this register is located in the middle of
+  the PMGR MMIO region it is represented as a sub-node of the PMGR
+  syscon with reg used as an offset into it.
+
+  In both cases the reset id is the CIO port index on the die.
+
+properties:
+  compatible:
+    oneOf:
+      - enum:
+          - apple,t8103-cio-reset
+          - apple,t6000-cio-reset
+      - items:
+          - const: apple,t8112-cio-reset
+          - const: apple,t8103-cio-reset
+      - items:
+          - const: apple,t6020-cio-reset
+          - const: apple,t6000-cio-reset
+
+  reg:
+    maxItems: 1
+
+  '#reset-cells':
+    const: 1
+
+required:
+  - compatible
+  - reg
+  - '#reset-cells'
+
+additionalProperties: false
+
+examples:
+  - |
+    soc {
+        #address-cells = <2>;
+        #size-cells = <2>;
+
+        reset-controller@23b784000 {
+            compatible = "apple,t8103-cio-reset";
+            reg = <0x2 0x3b784000 0x0 0x8000>;
+            #reset-cells = <1>;
+        };
+    };
+  - |
+    power-management@28e080000 {
+        compatible = "apple,t6000-pmgr", "apple,pmgr", "syscon", "simple-mfd";
+        reg = <0x8e080000 0x1c000>;
+        #address-cells = <1>;
+        #size-cells = <1>;
+
+        reset-controller@1a034 {
+            compatible = "apple,t6000-cio-reset";
+            reg = <0x1a034 0x4>;
+            #reset-cells = <1>;
+        };
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index 15011f5752a9..4b78528324c8 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2606,6 +2606,7 @@ F:	Documentation/devicetree/bindings/pinctrl/apple,pinctrl.yaml
 F:	Documentation/devicetree/bindings/power/apple*
 F:	Documentation/devicetree/bindings/power/reset/apple,smc-reboot.yaml
 F:	Documentation/devicetree/bindings/pwm/apple,s5l-fpwm.yaml
+F:	Documentation/devicetree/bindings/reset/apple,t8103-cio-reset.yaml
 F:	Documentation/devicetree/bindings/rtc/apple,smc-rtc.yaml
 F:	Documentation/devicetree/bindings/spi/apple,spi.yaml
 F:	Documentation/devicetree/bindings/spmi/apple,spmi.yaml

-- 
2.55.0

