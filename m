From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Tue, 24 Nov 2026 00:50:58 +0300
Subject: [PATCH 1/3] dt-bindings: soc: Describe CS7542 global gates and
 reset domains
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-b4-cs7542-global-controls-v1-1-12548785df2c@gmail.com>
References: <20261124-b4-cs7542-global-controls-v1-0-12548785df2c@gmail.com>
In-Reply-To: <20261124-b4-cs7542-global-controls-v1-0-12548785df2c@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Stephen Boyd <sboyd@kernel.org>, 
 Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795470657; l=3633;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=n/z0ljwGjp/3VFKQErO4wbHMgKIiXYh7j3B5tNIJnUo=;
 b=Q9HYthlORc5L0xu0ndiFe+2NOZiLVjcykhEDFU4Zs1cGK0rkrmFEHwoNu1R5doyVM+WP85Kds
 O7nCXMCEafLB93uxR26YcbG5YA+XcXKNWTIAeMsYL6uIbm1R73pFnYK
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Expose PCIe gates and resets and the exclusive network engine composite
reset on the existing global syscon node. Preserve clock indices 0..2,
add PCIe clock indices 3..5 and reset indices 0..2, and give the NE domain
index 3. No virtual control child is required. The optional reset-cells
property preserves compatibility with clock-only users.

AI assistance: Codex prepared this draft from the posted CS7542 series.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 .../bindings/soc/cortina/cortina,cs7542-syscon.yaml        | 14 ++++++++++++--
 include/dt-bindings/clock/cortina,cs7542-clock.h           |  4 ++++
 include/dt-bindings/reset/cortina,cs7542-reset.h           | 12 ++++++++++++
 3 files changed, 28 insertions(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/soc/cortina/cortina,cs7542-syscon.yaml b/Documentation/devicetree/bindings/soc/cortina/cortina,cs7542-syscon.yaml
index fb074de87..12f750dab 100644
--- a/Documentation/devicetree/bindings/soc/cortina/cortina,cs7542-syscon.yaml
+++ b/Documentation/devicetree/bindings/soc/cortina/cortina,cs7542-syscon.yaml
@@ -12,8 +12,14 @@ maintainers:
 description:
   The global control block contains the boot strap status, GPIO/peripheral
   mux registers, reset controls and the secondary CPU release register.
-  It provides the APB, CPU and AXI clock rates selected by the boot straps.
-  The clock specifiers are defined in dt-bindings/clock/cortina,cs7542-clock.h.
+  It provides the APB, CPU and AXI clock rates selected by the boot straps,
+  and the three PCIe clock gates and controller reset lines. The network
+  engine reset domain covers NI, FE, TM, scheduler, QM, NI XRAM and the
+  entire DMA block (LSO and SSP). It excludes SDRAM. The network engine
+  consumer must own this complete domain exclusively; it cannot run
+  concurrently with a separate SSP DMA user.
+  Clock specifiers are defined in dt-bindings/clock/cortina,cs7542-clock.h;
+  reset specifiers are defined in dt-bindings/reset/cortina,cs7542-reset.h.
   The pin controller uses the same register map through its parent syscon.
 
 properties:
@@ -29,6 +35,9 @@ properties:
   "#clock-cells":
     const: 1
 
+  "#reset-cells":
+    const: 1
+
   pinctrl:
     type: object
     $ref: /schemas/pinctrl/cortina,cs7542-pinctrl.yaml#
@@ -46,4 +55,5 @@ examples:
         compatible = "cortina,cs7542-syscon", "syscon", "simple-mfd";
         reg = <0xf0000000 0x100>;
         #clock-cells = <1>;
+        #reset-cells = <1>;
     };
diff --git a/include/dt-bindings/clock/cortina,cs7542-clock.h b/include/dt-bindings/clock/cortina,cs7542-clock.h
index 34d544238..c68c6ba20 100644
--- a/include/dt-bindings/clock/cortina,cs7542-clock.h
+++ b/include/dt-bindings/clock/cortina,cs7542-clock.h
@@ -6,4 +6,8 @@
 #define CS7542_CLK_CPU	1
 #define CS7542_CLK_AXI	2
 
+#define CS7542_CLK_PCIE0	3
+#define CS7542_CLK_PCIE1	4
+#define CS7542_CLK_PCIE2	5
+
 #endif
diff --git a/include/dt-bindings/reset/cortina,cs7542-reset.h b/include/dt-bindings/reset/cortina,cs7542-reset.h
new file mode 100644
index 000000000..546e643a3
--- /dev/null
+++ b/include/dt-bindings/reset/cortina,cs7542-reset.h
@@ -0,0 +1,12 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause) */
+#ifndef _DT_BINDINGS_RESET_CORTINA_CS7542_H
+#define _DT_BINDINGS_RESET_CORTINA_CS7542_H
+
+#define CS7542_RESET_PCIE0	0
+#define CS7542_RESET_PCIE1	1
+#define CS7542_RESET_PCIE2	2
+
+/* NI, FE, TM, scheduler, QM, NI XRAM and DMA-LSO/SSP, excluding SDRAM. */
+#define CS7542_RESET_NE		3
+
+#endif

-- 
2.53.0

