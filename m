From: Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
Date: Sun, 10 May 2026 18:06:23 +0000
Subject: [PATCH v2 2/2] dt-bindings: Add GPIO locked fixed clock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260510-feature-clock-guard-v2-2-6c25458d5340@bruker.com>
References: <20260510-feature-clock-guard-v2-0-6c25458d5340@bruker.com>
In-Reply-To: <20260510-feature-clock-guard-v2-0-6c25458d5340@bruker.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, Vyacheslav Yurkov <uvv.mail@gmail.com>, 
 Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778436398; l=2531;
 i=V.Yurkov.EXT@bruker.com; s=20260318; h=from:subject:message-id;
 bh=FupGvIs6kugUEugv1WXQH65Y6JAfr5er0m/C8QC4esM=;
 b=ksqNRA/HW0QmBLYaPK3be16Y9VuSE3MSJtE+1BnLiBPhIkNjDiEExNWvXsyYomfKct+XNQkCB
 W/UUtGHf1XwChI3rwrBJDnZDwxlZPeuvdPQ05mpR1TR4BCM9S16P/Ay
X-Developer-Key: i=V.Yurkov.EXT@bruker.com; a=ed25519;
 pk=snJmgYVOKlp7aQtK9tWnEI7QTYxpPpJJvxdVsnxA7Fk=
X-Endpoint-Received: by B4 Relay for V.Yurkov.EXT@bruker.com/20260318 with auth_id=686
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe device tree binding for a fixed clock, which state can only be
determined by the external GPIO. It's similar to gated-fixed-clock, but
the GPIO direction is inverted.

Signed-off-by: Vyacheslav Yurkov <uvv.mail@gmail.com>
Signed-off-by: Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
---
 .../bindings/clock/gpio-locked-fixed-clock.yaml    | 77 ++++++++++++++++++++++
 1 file changed, 77 insertions(+)

diff --git a/Documentation/devicetree/bindings/clock/gpio-locked-fixed-clock.yaml b/Documentation/devicetree/bindings/clock/gpio-locked-fixed-clock.yaml
new file mode 100644
index 000000000000..e0256bbd441d
--- /dev/null
+++ b/Documentation/devicetree/bindings/clock/gpio-locked-fixed-clock.yaml
@@ -0,0 +1,77 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/clock/gpio-locked-fixed-clock.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: GPIO Locked Fixed Clock
+
+maintainers:
+  - Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
+
+description: |
+  Clock controller that aggregates input clocks and/or GPIO
+  signals and exposes them as a single clock output.
+
+properties:
+  compatible:
+    const: gpio-locked-fixed-clock
+
+  "#clock-cells":
+    const: 0
+
+  clocks:
+    description: Input clocks that externally locked.
+
+  clock-names:
+    description: Input clock names.
+
+  clock-output-names:
+    description: Names of the clock provided by this controller.
+    maxItems: 1
+
+  locked-gpios:
+    description: |
+      GPIOs to check the lock state.
+    minItems: 1
+    maxItems: 32
+
+  gpio-names:
+    description: Names corresponding to each GPIO.
+    minItems: 1
+    maxItems: 32
+
+required:
+  - compatible
+  - "#clock-cells"
+anyOf:
+  - required:
+      - clocks
+  - required:
+      - locked-gpios
+dependentRequired:
+  gpio-names:
+    - locked-gpios
+  clock-names:
+    - clocks
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+
+    clk_gpio_locked: gpio-locked-fixed-clock {
+        compatible = "gpio-locked-fixed-clock";
+        #clock-cells = <0>;
+
+        clocks = <&clk0 0>, <&pll 0>;
+
+        locked-gpios = <&gpio0 4 GPIO_ACTIVE_HIGH>,
+                <&gpio0 5 GPIO_ACTIVE_HIGH>,
+                <&gpio1 2 GPIO_ACTIVE_LOW>;
+
+        gpio-names = "gpio0", "gpio1", "gpio2";
+
+        clock-output-names = "clkout0";
+    };

-- 
2.34.1

