From: Cody Kang <codykang.hk@gmail.com>
Date: Sun, 09 Aug 2026 21:14:10 +0800
Subject: [PATCH v2 01/17] dt-bindings: display: spacemit: add K3 Saturn DPU
 controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260809-k3-display-v2-1-327d7910bf71@gmail.com>
References: <20260809-k3-display-v2-0-327d7910bf71@gmail.com>
In-Reply-To: <20260809-k3-display-v2-0-327d7910bf71@gmail.com>
To: David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Yixun Lan <dlan@kernel.org>, 
 Vinod Koul <vkoul@kernel.org>, Neil Armstrong <neil.armstrong@linaro.org>, 
 Haylen Chu <heylenay@4d2.org>, Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney@redhat.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Yao Zi <me@ziyao.cc>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@baylibre.com>, 
 Guodong Xu <docular.xu@gmail.com>
Cc: dri-devel@lists.freedesktop.org, linux-riscv@lists.infradead.org, 
 devicetree@vger.kernel.org, spacemit@lists.linux.dev, 
 linux-kernel@vger.kernel.org, linux-phy@lists.infradead.org, 
 linux-clk@vger.kernel.org, Cody Kang <codykang.hk@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786281298; l=4691;
 i=codykang.hk@gmail.com; s=codykang; h=from:subject:message-id;
 bh=BmFVX9AQPaf/054idrgE6KVKK1IoNznGkA+GRXEpG9M=;
 b=/yT1v9ef3dtpOxKhsnKQ6uDojXxRxTguGnrCGEHMzwSEdtLmy/6hQaxRTrGavkrSIIhV91ENi
 Keu/o38CU+fDXhx68dbKaDqN0e5YjIYpM1GaAE80y4Kp71TuxHmZXYS
X-Developer-Key: i=codykang.hk@gmail.com; a=ed25519;
 pk=Osn6/cs9Su/mHHw4P19cmVc3v2FMQfiWahjsN0vEkuk=
X-Endpoint-Received: by B4 Relay for codykang.hk@gmail.com/codykang with auth_id=895
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the Saturn display processing unit found on the SpacemiT K3 SoC.
The K3 instantiates two of them, one per display path. They share a
compatible: an instance differs only in which register window, interrupt,
clock and reset lines it takes.

Reviewed-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: Cody Kang <codykang.hk@gmail.com>

---
v2:
- add Reviewed-by: Rob Herring (Arm)
---
 .../display/spacemit/spacemit,k3-saturn-dpu.yaml   | 132 +++++++++++++++++++++
 1 file changed, 132 insertions(+)

diff --git a/Documentation/devicetree/bindings/display/spacemit/spacemit,k3-saturn-dpu.yaml b/Documentation/devicetree/bindings/display/spacemit/spacemit,k3-saturn-dpu.yaml
new file mode 100644
index 0000000000000..97ea9da4b68e4
--- /dev/null
+++ b/Documentation/devicetree/bindings/display/spacemit/spacemit,k3-saturn-dpu.yaml
@@ -0,0 +1,132 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/display/spacemit/spacemit,k3-saturn-dpu.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: SpacemiT K3 Saturn Display Processing Unit
+
+maintainers:
+  - Cody Kang <codykang.hk@gmail.com>
+
+description:
+  The Saturn DPU is the display processing unit of the SpacemiT K3 SoC. It
+  composes the display planes and drives the timing for one display path. Its
+  output goes to a DisplayPort or embedded DisplayPort controller. The K3 has
+  two instances.
+
+properties:
+  compatible:
+    const: spacemit,k3-saturn-dpu
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    items:
+      - description: Online (live display) compose path.
+      - description: Offline (writeback) compose path.
+
+  interrupt-names:
+    items:
+      - const: online
+      - const: offline
+
+  clocks:
+    items:
+      - description: Pixel clock.
+      - description: Memory clock for the compose pipeline.
+      - description: AXI bus clock.
+      - description: DSI escape clock.
+      - description: DSC clock.
+
+  clock-names:
+    items:
+      - const: pxclk
+      - const: mclk
+      - const: aclk
+      - const: escclk
+      - const: dscclk
+
+  resets:
+    items:
+      - description: Memory clock domain.
+      - description: LCD domain, shared with the downstream controller.
+      - description: DSI escape clock domain.
+      - description: AXI clock domain.
+      - description: DSC domain.
+
+  reset-names:
+    items:
+      - const: mclk
+      - const: lcd
+      - const: esc
+      - const: aclk
+      - const: dsc
+
+  ports:
+    $ref: /schemas/graph.yaml#/properties/ports
+
+    properties:
+      port@0:
+        $ref: /schemas/graph.yaml#/properties/port
+        description: Video output to the DisplayPort or eDP controller.
+
+    required:
+      - port@0
+
+required:
+  - compatible
+  - reg
+  - interrupts
+  - interrupt-names
+  - clocks
+  - clock-names
+  - resets
+  - reset-names
+  - ports
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/clock/spacemit,k3-clocks.h>
+    #include <dt-bindings/reset/spacemit,k3-resets.h>
+    #include <dt-bindings/interrupt-controller/irq.h>
+
+    soc {
+        #address-cells = <2>;
+        #size-cells = <2>;
+
+        dpu@c0340000 {
+            compatible = "spacemit,k3-saturn-dpu";
+            reg = <0x0 0xc0340000 0x0 0x54000>;
+            interrupts = <90 IRQ_TYPE_LEVEL_HIGH>,
+                         <89 IRQ_TYPE_LEVEL_HIGH>;
+            interrupt-names = "online", "offline";
+            clocks = <&syscon_apmu CLK_APMU_LCD_PXCLK>,
+                     <&syscon_apmu CLK_APMU_LCD_MCLK>,
+                     <&syscon_apmu CLK_APMU_DPU_ACLK>,
+                     <&syscon_apmu CLK_APMU_DSI_ESC>,
+                     <&syscon_apmu CLK_APMU_LCD_DSC>;
+            clock-names = "pxclk", "mclk", "aclk", "escclk", "dscclk";
+            resets = <&syscon_apmu RESET_APMU_LCD_MCLK>,
+                     <&syscon_apmu RESET_APMU_LCD>,
+                     <&syscon_apmu RESET_APMU_DSI_ESC>,
+                     <&syscon_apmu RESET_APMU_DPU_ACLK>,
+                     <&syscon_apmu RESET_APMU_LCD_DSCCLK>;
+            reset-names = "mclk", "lcd", "esc", "aclk", "dsc";
+
+            ports {
+                #address-cells = <1>;
+                #size-cells = <0>;
+
+                port@0 {
+                    reg = <0>;
+                    endpoint {
+                        remote-endpoint = <&edp0_in>;
+                    };
+                };
+            };
+        };
+    };

-- 
2.43.0

