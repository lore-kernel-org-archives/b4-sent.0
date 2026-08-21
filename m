From: Sven Peter <sven@kernel.org>
Date: Fri, 21 Aug 2026 17:44:54 +0200
Subject: [PATCH v2 1/3] dt-bindings: reset: Add Apple SoC CIO reset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260821-b4-cio-reset-v2-1-2d045f80a424@kernel.org>
References: <20260821-b4-cio-reset-v2-0-2d045f80a424@kernel.org>
In-Reply-To: <20260821-b4-cio-reset-v2-0-2d045f80a424@kernel.org>
To: Sven Peter <sven@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: Joshua Peisach <jpeisach@ubuntu.com>, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4541; i=sven@kernel.org;
 h=from:subject:message-id; bh=+ixko2Bt0RcawsuOfq9EeeMloylw3ayN6yWX9GXtlRI=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ1ZH0bKdNpa/NnYFXzwkcf7KcrnH86OqN98KO9jP7P532
 9PXkbd3d5SyMIhxMciKKbJs329v+uThG8Glmy69h5nDygQyhIGLUwAmwsfIyDDLZrNhekGTYeF1
 DvPtq/3v+PMrpRqcE+Tqznsb1XJPM4OR4drV/qsXw3ma/a49PBD0+6kSz0uVqaYZE0pmXLqXzyy
 exgMA
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

Reviewed-by: Conor Dooley <conor.dooley@microchip.com>
Signed-off-by: Sven Peter <sven@kernel.org>
---
 .../devicetree/bindings/arm/apple/apple,pmgr.yaml  | 12 +++++
 .../bindings/reset/apple,t8103-cio-reset.yaml      | 61 ++++++++++++++++++++++
 MAINTAINERS                                        |  1 +
 3 files changed, 74 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/apple/apple,pmgr.yaml b/Documentation/devicetree/bindings/arm/apple/apple,pmgr.yaml
index c67b67ba065a..49b4bec36461 100644
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
@@ -103,6 +109,12 @@ examples:
                 label = "uart0";
                 power-domains = <&ps_uart_p>;
             };
+
+            reset-controller@13034 {
+                compatible = "apple,t6000-cio-reset";
+                reg = <0x13034 0x4>;
+                #reset-cells = <1>;
+            };
         };
 
         power-management@23d280000 {
diff --git a/Documentation/devicetree/bindings/reset/apple,t8103-cio-reset.yaml b/Documentation/devicetree/bindings/reset/apple,t8103-cio-reset.yaml
new file mode 100644
index 000000000000..6f602669d242
--- /dev/null
+++ b/Documentation/devicetree/bindings/reset/apple,t8103-cio-reset.yaml
@@ -0,0 +1,61 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
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
diff --git a/MAINTAINERS b/MAINTAINERS
index 8014b9f8253e..e1ec54f4d80e 100644
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

