From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Sat, 12 Apr 2025 14:56:20 +0200
Subject: [PATCH v2] dt-bindings: timer: Convert fsl,gtm to YAML
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250412-gtm-yaml-v2-1-e4d2292ffefc@posteo.net>
X-B4-Tracking: v=1; b=H4sIAPNi+mcC/0XMQQrDIBCF4auEWXeKGiXYVe8RsjB1mghNDCrSE
 Lx7bSh0+T8e3wGRgqMIt+aAQNlF59ca4tLAYzbrROhsbRBMKCY4wyktuJvlhaPkRstOWTa2UO9
 boKd7n1Q/1J5dTD7sp5z5d/0hQv2RzJGjJWVNJ7SWLbtvPiby15USDKWUD0ThHumhAAAA
X-Change-ID: 20250210-gtm-yaml-b41a9475d0b3
To: Daniel Lezcano <daniel.lezcano@linaro.org>, 
 Thomas Gleixner <tglx@linutronix.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744462587; l=4462;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=9whPopX6S651IhYCNC5/C4r5vNx8pM5oAbuAUI21Hkk=;
 b=RekIsWZBByF0qTa57/6Jump/9caAL+Qr6JFsGCnxao65Vijt3l3H+yW7HThnUe8W0rWzlQ3Ub
 mYZxuxI9qp8DGEiGZMz8XcbJlIFzAocgFhcZFsjDZFM1Qa19pNASMBM
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Convert fsl,gtm.txt to YAML so that device trees using a Freescale
General-purpose Timers Module can be properly validated.

Reviewed-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
Changes in v2:
- Add Rob Herring's review tag
- Rebase on v6.15-rc1
- Link to v1: https://lore.kernel.org/r/20250225-gtm-yaml-v1-1-de5da7299430@posteo.net
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
base-commit: 0af2f6be1b4281385b618cb86ad946eded089ac8
change-id: 20250210-gtm-yaml-b41a9475d0b3

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

