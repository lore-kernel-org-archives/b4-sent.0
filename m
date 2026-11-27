From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Fri, 27 Nov 2026 23:50:26 +0300
Subject: [PATCH v5 1/6] dt-bindings: soc: Add Cortina Systems CS7542 global
 controls
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-cs7542-syscon-v5-1-d5a373c72b05@gmail.com>
References: <20261127-cs7542-syscon-v5-0-d5a373c72b05@gmail.com>
In-Reply-To: <20261127-cs7542-syscon-v5-0-d5a373c72b05@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-gpio@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795812625; l=4089;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=LqNLTAcu72EDE3AcsaBdidyY70NNKo0WkG3SoF8q1Nw=;
 b=djRcgSWO+zkDwMw7wDWzAQirZzaOzurj7yO9pZ01NSw+4gGR/mx7A6DzYkhFRjnTVU7SpfsyR
 ZRk27Py5e30DdRR3hyBPOsg5F62R96zbA8lUlGKD9TEhRdpegoiyA1/
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the shared syscon, its strap-selected clocks, three PCIe
gates and level resets. Reserve the former group reset ID and assign
individual IDs to the seven network reset signals.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 .../soc/cortina/cortina,cs7542-syscon.yaml         | 56 ++++++++++++++++++++++
 include/dt-bindings/clock/cortina,cs7542-clock.h   | 13 +++++
 include/dt-bindings/reset/cortina,cs7542-reset.h   | 20 ++++++++
 3 files changed, 89 insertions(+)

diff --git a/Documentation/devicetree/bindings/soc/cortina/cortina,cs7542-syscon.yaml b/Documentation/devicetree/bindings/soc/cortina/cortina,cs7542-syscon.yaml
new file mode 100644
index 000000000..59bd1cfe3
--- /dev/null
+++ b/Documentation/devicetree/bindings/soc/cortina/cortina,cs7542-syscon.yaml
@@ -0,0 +1,56 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/soc/cortina/cortina,cs7542-syscon.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Cortina Systems CS7542 global control block
+
+maintainers:
+  - Fil Dunsky <filipp.dunsky@gmail.com>
+
+description:
+  The global control block contains the boot strap status, GPIO/peripheral
+  mux registers, reset controls and the secondary CPU release register.
+  It provides the APB, CPU and AXI clock rates selected by the boot straps,
+  and the three PCIe clock gates and controller reset lines. Individual
+  reset lines control NI, FE, TM, scheduler, QM, NI XRAM and the entire DMA
+  block (LSO and SSP). The network engine consumer must acquire all seven
+  lines exclusively; it cannot run concurrently with a separate SSP DMA
+  user. The flash controller has a separate reset. SDRAM is excluded.
+  Reset identifier 3 is reserved.
+  Clock specifiers are defined in dt-bindings/clock/cortina,cs7542-clock.h;
+  reset specifiers are defined in dt-bindings/reset/cortina,cs7542-reset.h.
+  The pin controller uses the same register map through its parent syscon.
+
+properties:
+  compatible:
+    items:
+      - const: cortina,cs7542-syscon
+      - const: syscon
+      - const: simple-mfd
+
+  reg:
+    maxItems: 1
+
+  "#clock-cells":
+    const: 1
+
+  "#reset-cells":
+    const: 1
+
+required:
+  - compatible
+  - reg
+  - "#clock-cells"
+
+additionalProperties: false
+
+examples:
+  - |
+    syscon@f0000000 {
+        compatible = "cortina,cs7542-syscon", "syscon", "simple-mfd";
+        reg = <0xf0000000 0x100>;
+        #clock-cells = <1>;
+        #reset-cells = <1>;
+    };
diff --git a/include/dt-bindings/clock/cortina,cs7542-clock.h b/include/dt-bindings/clock/cortina,cs7542-clock.h
new file mode 100644
index 000000000..c68c6ba20
--- /dev/null
+++ b/include/dt-bindings/clock/cortina,cs7542-clock.h
@@ -0,0 +1,13 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause) */
+#ifndef _DT_BINDINGS_CLOCK_CORTINA_CS7542_H
+#define _DT_BINDINGS_CLOCK_CORTINA_CS7542_H
+
+#define CS7542_CLK_APB	0
+#define CS7542_CLK_CPU	1
+#define CS7542_CLK_AXI	2
+
+#define CS7542_CLK_PCIE0	3
+#define CS7542_CLK_PCIE1	4
+#define CS7542_CLK_PCIE2	5
+
+#endif
diff --git a/include/dt-bindings/reset/cortina,cs7542-reset.h b/include/dt-bindings/reset/cortina,cs7542-reset.h
new file mode 100644
index 000000000..136d21432
--- /dev/null
+++ b/include/dt-bindings/reset/cortina,cs7542-reset.h
@@ -0,0 +1,20 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause) */
+#ifndef _DT_BINDINGS_RESET_CORTINA_CS7542_H
+#define _DT_BINDINGS_RESET_CORTINA_CS7542_H
+
+#define CS7542_RESET_PCIE0	0
+#define CS7542_RESET_PCIE1	1
+#define CS7542_RESET_PCIE2	2
+
+/* Reserved legacy composite ID; never reinterpret it as an individual line. */
+#define CS7542_RESET_NE		3
+#define CS7542_RESET_NI		4
+#define CS7542_RESET_FE		5
+#define CS7542_RESET_TM		6
+#define CS7542_RESET_SCH		7
+#define CS7542_RESET_QM		8
+#define CS7542_RESET_DMA		9
+#define CS7542_RESET_NI_XRAM	10
+#define CS7542_RESET_FLASH	11
+
+#endif

-- 
2.53.0

