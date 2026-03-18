From: Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
Date: Wed, 18 Mar 2026 17:43:40 +0000
Subject: [PATCH 2/2] dt-bindings: Add clock guard DT description
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260318-feature-clock-guard-v1-2-6137cb4084b7@bruker.com>
References: <20260318-feature-clock-guard-v1-0-6137cb4084b7@bruker.com>
In-Reply-To: <20260318-feature-clock-guard-v1-0-6137cb4084b7@bruker.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, Vyacheslav Yurkov <uvv.mail@gmail.com>, 
 Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773855836; l=2408;
 i=V.Yurkov.EXT@bruker.com; s=20260318; h=from:subject:message-id;
 bh=nftM24g/uBu7svtXQ2MG9cVaqhavKUW1WxRDBq2fT/8=;
 b=X2/vy2XIiAWf10c3i4jfNnsT3rbtNRB5XzDMQ6dTUyDDEVRFiKnKtPk2VM1XG5imdC/j6VpsM
 ZWx52GXBR50C/jUU9qkf7h6U6EbGe+uhJ6GJ+vgvqvQTIzlOIf9Gnf+
X-Developer-Key: i=V.Yurkov.EXT@bruker.com; a=ed25519;
 pk=snJmgYVOKlp7aQtK9tWnEI7QTYxpPpJJvxdVsnxA7Fk=
X-Endpoint-Received: by B4 Relay for V.Yurkov.EXT@bruker.com/20260318 with auth_id=686
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe device tree binding for virtual clock controller guard.

Signed-off-by: Vyacheslav Yurkov <uvv.mail@gmail.com>
Signed-off-by: Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
---
 .../bindings/clock/clock-controller-guard.yaml     | 79 ++++++++++++++++++++++
 1 file changed, 79 insertions(+)

diff --git a/Documentation/devicetree/bindings/clock/clock-controller-guard.yaml b/Documentation/devicetree/bindings/clock/clock-controller-guard.yaml
new file mode 100644
index 000000000000..71c2d80de1f0
--- /dev/null
+++ b/Documentation/devicetree/bindings/clock/clock-controller-guard.yaml
@@ -0,0 +1,79 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: "http://devicetree.org/schemas/clock/clock-controller-guard.yaml#"
+$schema: "http://devicetree.org/meta-schemas/core.yaml#"
+
+title: Clock Controller Guard
+
+maintainers:
+  - Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
+
+description: |
+  Clock controller that guards upstream clocks and/or GPIO
+  signals and exposes them as a single clock output.
+
+properties:
+  compatible:
+    const: clock-controller-guard
+
+  "#clock-cells":
+    const: 1
+
+  clocks:
+    description: Input clocks that will be guarded.
+    minItems: 0
+
+  clock-names: Input clock names.
+    minItems: 0
+
+  clock-output-names:
+    description: Names of the clock provided by this controller.
+    minItems: 1
+    items:
+      type: string
+
+  gpios:
+    description: |
+      GPIOs used to control or guard the clocks.
+    minItems: 0
+    maxItems: 32
+
+  gpio-names:
+    description: Names corresponding to each GPIO.
+    minItems: 0
+    maxItems: 32
+
+    items:
+      type: string
+
+required:
+  - compatible
+  - "#clock-cells"
+anyOf:
+  - required:
+      - clocks
+  - required:
+      - gpios
+dependencies:
+  gpio-names: [gpios]
+  clock-names: [clocks]
+
+additionalProperties: false
+
+examples:
+  - |
+    clkctrl: clock-controller {
+        compatible = "clock-controller-guard";
+        #clock-cells = <1>;
+
+        clocks = <&clk0 0>, <&pll 0>;
+
+        gpios = <&gpio0 4 GPIO_ACTIVE_HIGH>,
+                <&gpio0 5 GPIO_ACTIVE_HIGH>,
+                <&gpio1 2 GPIO_ACTIVE_LOW>;
+
+        gpio-names = "gpio0", "gpio1", "gpio2";
+
+        clock-output-names = "clkout0";
+    };

-- 
2.34.1

