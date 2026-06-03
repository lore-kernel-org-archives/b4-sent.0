From: Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
Date: Wed, 03 Jun 2026 11:16:42 +0000
Subject: [PATCH v3 1/2] dt-bindings: Add GPIO-locked fixed clock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260603-feature-clock-guard-v3-1-01cca0aa04a5@bruker.com>
References: <20260603-feature-clock-guard-v3-0-01cca0aa04a5@bruker.com>
In-Reply-To: <20260603-feature-clock-guard-v3-0-01cca0aa04a5@bruker.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Brian Masney <bmasney@redhat.com>
Cc: linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, Vyacheslav Yurkov <uvv.mail@gmail.com>, 
 Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780485407; l=2817;
 i=V.Yurkov.EXT@bruker.com; s=20260318; h=from:subject:message-id;
 bh=iHRb7fBmSmETe2+oHkt2rJtsp8K/mu9bMS++HcMLWAg=;
 b=QAyCwjFnk+SBMikLZQpp4n32gxXiduFG9py82nppOle736/Uj92YJIgBQRfBaBjJBc30x7nhN
 Ncc45wc2udUCbx6jx75NmVFbGdvH0HgRoPW2gjGjX0C0YvFikkfoiA2
X-Developer-Key: i=V.Yurkov.EXT@bruker.com; a=ed25519;
 pk=snJmgYVOKlp7aQtK9tWnEI7QTYxpPpJJvxdVsnxA7Fk=
X-Endpoint-Received: by B4 Relay for V.Yurkov.EXT@bruker.com/20260318 with auth_id=686
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some hardware designs provide fixed-frequency clocks generated outside
software control, such as by FPGA-resident PLLs. While the clock rate is
fixed, a separate GPIO signal indicates whether the clock source is
locked and producing a valid output.

Describe a GPIO-locked fixed clock provider that exposes a fixed-rate
clock whose availability depends on one or more GPIO lock-status
signals.

Signed-off-by: Vyacheslav Yurkov <uvv.mail@gmail.com>
Signed-off-by: Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
---
 .../bindings/clock/gpio-locked-fixed-clock.yaml    | 70 ++++++++++++++++++++++
 1 file changed, 70 insertions(+)

diff --git a/Documentation/devicetree/bindings/clock/gpio-locked-fixed-clock.yaml b/Documentation/devicetree/bindings/clock/gpio-locked-fixed-clock.yaml
new file mode 100644
index 000000000000..9106b800b673
--- /dev/null
+++ b/Documentation/devicetree/bindings/clock/gpio-locked-fixed-clock.yaml
@@ -0,0 +1,70 @@
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
+  Provides a clock output whose availability depends on a set of
+  prerequisite conditions. These conditions include the presence of
+  one or more parent clocks and the asserted state of one or more
+  GPIO lock indicators. An example of such clocks is FPGA clock that
+  are outside CPU control, with the lock status exposed through GPIO
+  signal.
+
+  The output clock is considered available only when all configured
+  prerequisites are satisfied.
+
+properties:
+  compatible:
+    const: gpio-locked-fixed-clock
+
+  "#clock-cells":
+    const: 0
+
+  clocks:
+    description: Input clocks whose validity is monitored by this provider.
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
+required:
+  - compatible
+  - "#clock-cells"
+
+anyOf:
+  - required:
+      - clocks
+  - required:
+      - locked-gpios
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
+        clock-output-names = "clkout0";
+    };

-- 
2.34.1

