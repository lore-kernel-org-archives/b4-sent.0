From: Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
Date: Thu, 15 Oct 2026 14:22:50 +0000
Subject: [PATCH v9 1/2] dt-bindings: gpio-enabled-clock: Add a new binding
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261015-feature-clock-guard-v9-1-c1c05a498d9a@bruker.com>
References: <20261015-feature-clock-guard-v9-0-c1c05a498d9a@bruker.com>
In-Reply-To: <20261015-feature-clock-guard-v9-0-c1c05a498d9a@bruker.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Brian Masney <bmasney@redhat.com>, 
 Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Jyri Sarha <jsarha@ti.com>
Cc: linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, Vyacheslav Yurkov <uvv.mail@gmail.com>, 
 Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792074172; l=2086;
 i=V.Yurkov.EXT@bruker.com; s=20260318; h=from:subject:message-id;
 bh=JV9mIk6OeqqUThZQfhKYkJ3FLsH8eD9NrGO7uQLENC8=;
 b=hq4mdmxzZwgxMwj32VUzUTi2llVgYBwcDh123k0HtBDzDj5u+Xx4wf44ZR5U29z0qvWyAlts7
 iIyFsri/ECTAHQ19G9KgU0ESeeNn3pK7p39qVoAHbzdi7K7ubihQhOv
X-Developer-Key: i=V.Yurkov.EXT@bruker.com; a=ed25519;
 pk=snJmgYVOKlp7aQtK9tWnEI7QTYxpPpJJvxdVsnxA7Fk=
X-Endpoint-Received: by B4 Relay for V.Yurkov.EXT@bruker.com/20260318 with auth_id=686
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the binding for gpio-enabled-clock. A GPIO-enabled clock provider
exposes a clock (can be any type of clock) whose availability depends on
a GPIO status signal.

Some hardware designs provide fixed-frequency clocks generated outside
software control, such as by FPGA-resident PLLs. While the clock rate is
fixed, a separate GPIO signal indicates whether the clock source is enabled
and producing a valid output.

Signed-off-by: Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
---
 .../bindings/clock/gpio-enabled-clock.yaml         | 53 ++++++++++++++++++++++
 1 file changed, 53 insertions(+)

diff --git a/Documentation/devicetree/bindings/clock/gpio-enabled-clock.yaml b/Documentation/devicetree/bindings/clock/gpio-enabled-clock.yaml
new file mode 100644
index 000000000000..3ab6fa9dd412
--- /dev/null
+++ b/Documentation/devicetree/bindings/clock/gpio-enabled-clock.yaml
@@ -0,0 +1,53 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/clock/gpio-enabled-clock.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: GPIO Enabled Clock
+
+maintainers:
+  - Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
+
+properties:
+  compatible:
+    const: gpio-enabled-clock
+
+  clocks:
+    maxItems: 1
+
+  "#clock-cells":
+    const: 0
+
+  clock-output-names:
+    maxItems: 1
+
+  enabled-gpios:
+    description: GPIO that indicates whether the clock is enabled or disabled.
+    maxItems: 1
+
+  poll-timeout-us:
+    description: Timeout in microseconds for waiting for a GPIO signal.
+    default: 10
+    minimum: 10
+    maximum: 1000
+
+required:
+  - compatible
+  - clocks
+  - "#clock-cells"
+  - enabled-gpios
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+
+    clock {
+        compatible = "gpio-enabled-clock";
+        #clock-cells = <0>;
+        clocks = <&pll>;
+        enabled-gpios = <&gpio0 4 GPIO_ACTIVE_HIGH>;
+        poll-timeout-us = <20>;
+    };

-- 
2.34.1

