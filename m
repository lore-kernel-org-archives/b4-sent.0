From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Tue, 25 Feb 2025 12:50:43 +0100
Subject: [PATCH] dt-bindings: timer: Convert fsl,gtm to YAML
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250225-gtm-yaml-v1-1-de5da7299430@posteo.net>
X-B4-Tracking: v=1; b=H4sIAJOuvWcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDI0MD3fSSXN3KxNwc3SQTw0RLE3PTFIMkYyWg8oKi1LTMCrBR0bG1tQC
 3qRAMWgAAAA==
X-Change-ID: 20250210-gtm-yaml-b41a9475d0b3
To: Daniel Lezcano <daniel.lezcano@linaro.org>, 
 Thomas Gleixner <tglx@linutronix.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740484262; l=4248;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=IJ2Pa/73xPD+G6Z1wxNgj8rNjWlTYDU/+mVzEQ1et/Q=;
 b=yeu7WB5KhuLu0yJuJmFG0VtBoDF5CMhRLBSJuFsg0b4GNU5rG2b0VN4XgOSIR/ccG4ZpMflSF
 /erfPHQ/nGAC4ijVrHlaEthKqFxgmPA/NPBMpA0x6jWAXvZTuZe7pOV
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Convert fsl,gtm.txt to YAML so that device trees using a Freescale
General-purpose Timers Module can be properly validated.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 .../devicetree/bindings/timer/fsl,gtm.txt          | 30 --------
 .../devicetree/bindings/timer/fsl,gtm.yaml         | 83 ++++++++++++++++++++++
 2 files changed, 83 insertions(+), 30 deletions(-)

diff --git a/Documentation/devicetree/bindings/timer/fsl,gtm.txt b/Documentation/devicetree/bindings/timer/fsl,gtm.txt
deleted file mode 100644
index fc1c571f74123d2293bf5c3af3197000d46a07ee..0000000000000000000000000000000000000000
--- a/Documentation/devicetree/bindings/timer/fsl,gtm.txt
+++ /dev/null
@@ -1,30 +0,0 @@
-* Freescale General-purpose Timers Module
-
-Required properties:
-  - compatible : should be
-    "fsl,<chip>-gtm", "fsl,gtm" for SOC GTMs
-    "fsl,<chip>-qe-gtm", "fsl,qe-gtm", "fsl,gtm" for QE GTMs
-    "fsl,<chip>-cpm2-gtm", "fsl,cpm2-gtm", "fsl,gtm" for CPM2 GTMs
-  - reg : should contain gtm registers location and length (0x40).
-  - interrupts : should contain four interrupts.
-  - clock-frequency : specifies the frequency driving the timer.
-
-Example:
-
-timer@500 {
-	compatible = "fsl,mpc8360-gtm", "fsl,gtm";
-	reg = <0x500 0x40>;
-	interrupts = <90 8 78 8 84 8 72 8>;
-	interrupt-parent = <&ipic>;
-	/* filled by u-boot */
-	clock-frequency = <0>;
-};
-
-timer@440 {
-	compatible = "fsl,mpc8360-qe-gtm", "fsl,qe-gtm", "fsl,gtm";
-	reg = <0x440 0x40>;
-	interrupts = <12 13 14 15>;
-	interrupt-parent = <&qeic>;
-	/* filled by u-boot */
-	clock-frequency = <0>;
-};
diff --git a/Documentation/devicetree/bindings/timer/fsl,gtm.yaml b/Documentation/devicetree/bindings/timer/fsl,gtm.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..1f35f1ee0be2a947ad241f4ba0be391e7e0d0882
--- /dev/null
+++ b/Documentation/devicetree/bindings/timer/fsl,gtm.yaml
@@ -0,0 +1,83 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/timer/fsl,gtm.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Freescale General-purpose Timers Module
+
+maintainers:
+  - J. Neuschäfer <j.ne@posteo.net>
+
+properties:
+  compatible:
+    oneOf:
+      # for SoC GTMs
+      - items:
+          - enum:
+              - fsl,mpc8308-gtm
+              - fsl,mpc8313-gtm
+              - fsl,mpc8315-gtm
+              - fsl,mpc8360-gtm
+          - const: fsl,gtm
+
+      # for QE GTMs
+      - items:
+          - enum:
+              - fsl,mpc8360-qe-gtm
+              - fsl,mpc8569-qe-gtm
+          - const: fsl,qe-gtm
+          - const: fsl,gtm
+
+      # for CPM2 GTMs (no known examples)
+      - items:
+          # - enum:
+          #     - fsl,<chip>-cpm2-gtm
+          - const: fsl,cpm2-gtm
+          - const: fsl,gtm
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    items:
+      - description: Interrupt for timer 1 (e.g. GTM1 or GTM5)
+      - description: Interrupt for timer 2 (e.g. GTM2 or GTM6)
+      - description: Interrupt for timer 3 (e.g. GTM3 or GTM7)
+      - description: Interrupt for timer 4 (e.g. GTM4 or GTM8)
+
+  clock-frequency: true
+
+required:
+  - compatible
+  - reg
+  - interrupts
+  - clock-frequency
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/irq.h>
+
+    timer@500 {
+        compatible = "fsl,mpc8360-gtm", "fsl,gtm";
+        reg = <0x500 0x40>;
+        interrupts = <90 IRQ_TYPE_LEVEL_LOW>,
+                     <78 IRQ_TYPE_LEVEL_LOW>,
+                     <84 IRQ_TYPE_LEVEL_LOW>,
+                     <72 IRQ_TYPE_LEVEL_LOW>;
+        /* filled by u-boot */
+        clock-frequency = <0>;
+    };
+
+  - |
+    timer@440 {
+        compatible = "fsl,mpc8360-qe-gtm", "fsl,qe-gtm", "fsl,gtm";
+        reg = <0x440 0x40>;
+        interrupts = <12>, <13>, <14>, <15>;
+        /* filled by u-boot */
+        clock-frequency = <0>;
+    };
+
+...

---
base-commit: 2014c95afecee3e76ca4a56956a936e23283f05b
change-id: 20250210-gtm-yaml-b41a9475d0b3

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

