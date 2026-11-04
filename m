From: Joseph Telaak <joseph@telaak.dev>
Date: Wed, 04 Nov 2026 02:20:58 -0500
Subject: [PATCH 1/4] dt-bindings: clock: Add Siflower SF19A2890 clock
 manager
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-sf19a2890-sysm-v1-1-a4fac07df823@telaak.dev>
References: <20261104-sf19a2890-sysm-v1-0-a4fac07df823@telaak.dev>
In-Reply-To: <20261104-sf19a2890-sysm-v1-0-a4fac07df823@telaak.dev>
To: Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: Chuanhong Guo <gch981213@gmail.com>, Yao Zi <me@ziyao.cc>, 
 linux-mips@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793776865; l=3448;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=UOCQCNAQ/b0HDJGf7xgsq9U+ntDdWggj7SVJU/wSbdg=;
 b=a4M53z8NCt5Fp3VmSoBvIu32pNpnavi3PoxnbOiGH6esw56KeHSPxuOLFGLq9VGYAArtk2Mdd
 48BkaYnbXN6BHsAPUOIvV0hxRF75avMLJem9JDycYO2e34tewEumuej
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The clock manager of the Siflower SF19A2890 holds the SoC's PLLs and
the muxes and dividers that derive the bus, CPU and peripheral clocks
from them. The peripherals' own gates and resets are in separate
blocks.

The header is Chuanhong Guo's, from his SF19A2890 branch, without the
count at its end.

Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
 .../bindings/clock/siflower,sf19a2890-clk.yaml     | 57 ++++++++++++++++++++++
 include/dt-bindings/clock/siflower,sf19a2890-clk.h | 27 ++++++++++
 2 files changed, 84 insertions(+)

diff --git a/Documentation/devicetree/bindings/clock/siflower,sf19a2890-clk.yaml b/Documentation/devicetree/bindings/clock/siflower,sf19a2890-clk.yaml
new file mode 100644
index 000000000..9b72f14c2
--- /dev/null
+++ b/Documentation/devicetree/bindings/clock/siflower,sf19a2890-clk.yaml
@@ -0,0 +1,57 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/clock/siflower,sf19a2890-clk.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Siflower SF19A2890 clock manager
+
+maintainers:
+  - Joseph Telaak <joseph@telaak.dev>
+
+description: |
+  The clock manager of the Siflower SF19A2890 holds the SoC's three PLLs
+  (CPU, DDR and common) and the clock muxes with dividers that derive the
+  bus, CPU and peripheral clocks from them. The peripherals' own clock
+  gates and resets are in separate peripheral clock and reset managers.
+
+  The clocks are defined in include/dt-bindings/clock/siflower,sf19a2890-clk.h.
+
+properties:
+  compatible:
+    const: siflower,sf19a2890-clk
+
+  reg:
+    maxItems: 1
+
+  clocks:
+    items:
+      - description: 12 MHz oscillator
+      - description: 40 MHz oscillator
+
+  clock-names:
+    items:
+      - const: osc12m
+      - const: osc40m
+
+  "#clock-cells":
+    const: 1
+
+required:
+  - compatible
+  - reg
+  - clocks
+  - clock-names
+  - "#clock-cells"
+
+additionalProperties: false
+
+examples:
+  - |
+    clock-controller@19e01000 {
+        compatible = "siflower,sf19a2890-clk";
+        reg = <0x19e01000 0x800>;
+        clocks = <&osc12m>, <&osc40m>;
+        clock-names = "osc12m", "osc40m";
+        #clock-cells = <1>;
+    };
diff --git a/include/dt-bindings/clock/siflower,sf19a2890-clk.h b/include/dt-bindings/clock/siflower,sf19a2890-clk.h
new file mode 100644
index 000000000..74b9d67ea
--- /dev/null
+++ b/include/dt-bindings/clock/siflower,sf19a2890-clk.h
@@ -0,0 +1,27 @@
+/* SPDX-License-Identifier: (GPL-2.0 OR MIT) */
+#ifndef __DT_BINDINGS_CLOCK_SIFLOWER_SF19A2890_CLK_H
+#define __DT_BINDINGS_CLOCK_SIFLOWER_SF19A2890_CLK_H
+
+#define CLK_PLL_CPU		0
+#define CLK_PLL_DDR		1
+#define CLK_PLL_CMN		2
+#define CLK_MUXDIV_BUS1		3
+#define CLK_MUXDIV_BUS2		4
+#define CLK_MUXDIV_BUS3		5
+#define CLK_MUXDIV_CPU		6
+#define CLK_MUXDIV_PBUS		7
+#define CLK_MUXDIV_MEM_PHY	8
+#define CLK_MUXDIV_UART		9
+#define CLK_MUXDIV_ETH_REF	10
+#define CLK_MUXDIV_ETH_BYP_REF	11
+#define CLK_MUXDIV_ETH_TSU	12
+#define CLK_MUXDIV_GMAC_BYP_REF	13
+#define CLK_MUXDIV_M6250_0	14
+#define CLK_MUXDIV_M6250_1	15
+#define CLK_MUXDIV_WLAN24_PLF	16
+#define CLK_MUXDIV_WLAN5_PLF	17
+#define CLK_MUXDIV_USBPHY_REF	18
+#define CLK_MUXDIV_TCLK		19
+#define CLK_MUXDIV_NPU_PE_CLK	20
+
+#endif /* __DT_BINDINGS_CLOCK_SIFLOWER_SF19A2890_CLK_H */

-- 
Git-155)

