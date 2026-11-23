From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Mon, 23 Nov 2026 23:32:16 +0300
Subject: [PATCH v2 2/8] dt-bindings: soc: Describe CS7542 PCIe clocks and
 resets
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-b4-cs7542-pcie-v2-2-f589a9cd0bef@gmail.com>
References: <20261123-b4-cs7542-pcie-v2-0-f589a9cd0bef@gmail.com>
In-Reply-To: <20261123-b4-cs7542-pcie-v2-0-f589a9cd0bef@gmail.com>
To: Manivannan Sadhasivam <mani@kernel.org>, 
 Stephen Boyd <sboyd@kernel.org>, Vinod Koul <vkoul@kernel.org>
Cc: Jingoo Han <jingoohan1@gmail.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 Krzysztof Wilczynski <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 linux-pci@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-clk@vger.kernel.org, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795465935; l=3193;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=f8i2MUsoVg+zzyGMskQHqPaf9wJgR56JnWGThlimNzg=;
 b=DMG0WPKRoRxeDezktvzlUVonyL/6hwSDG2kJFWn3seAiKvsgWodsaxp7f0DPc7Rymn84o8WIF
 Pg28KF8cPe7D2TkrATMT7wBqddl/i2RrOVv/6qddpnMuBCUlh0VzPeR
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The global register block already supplies the strap clocks. Extend that
same provider with the three PCIe gate clocks and controller reset lines,
rather than inventing a resource-less child to instantiate a driver.

Keep the existing APB/CPU/AXI indices and add named PCIe clock and reset
specifiers. The reset property is optional for clock-only descriptions.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 .../devicetree/bindings/soc/cortina/cortina,cs7542-syscon.yaml | 10 ++++++++--
 include/dt-bindings/clock/cortina,cs7542-clock.h               |  4 ++++
 include/dt-bindings/reset/cortina,cs7542-reset.h               |  9 +++++++++
 3 files changed, 21 insertions(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/soc/cortina/cortina,cs7542-syscon.yaml b/Documentation/devicetree/bindings/soc/cortina/cortina,cs7542-syscon.yaml
index fb074de87..dc7306868 100644
--- a/Documentation/devicetree/bindings/soc/cortina/cortina,cs7542-syscon.yaml
+++ b/Documentation/devicetree/bindings/soc/cortina/cortina,cs7542-syscon.yaml
@@ -12,8 +12,10 @@ maintainers:
 description:
   The global control block contains the boot strap status, GPIO/peripheral
   mux registers, reset controls and the secondary CPU release register.
-  It provides the APB, CPU and AXI clock rates selected by the boot straps.
-  The clock specifiers are defined in dt-bindings/clock/cortina,cs7542-clock.h.
+  It provides the APB, CPU and AXI clock rates selected by the boot straps,
+  and the three PCIe clock gates and controller reset lines.
+  Clock specifiers are defined in dt-bindings/clock/cortina,cs7542-clock.h;
+  reset specifiers are defined in dt-bindings/reset/cortina,cs7542-reset.h.
   The pin controller uses the same register map through its parent syscon.
 
 properties:
@@ -29,6 +31,9 @@ properties:
   "#clock-cells":
     const: 1
 
+  "#reset-cells":
+    const: 1
+
   pinctrl:
     type: object
     $ref: /schemas/pinctrl/cortina,cs7542-pinctrl.yaml#
@@ -46,4 +51,5 @@ examples:
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
index 000000000..bfd5799b2
--- /dev/null
+++ b/include/dt-bindings/reset/cortina,cs7542-reset.h
@@ -0,0 +1,9 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause) */
+#ifndef _DT_BINDINGS_RESET_CORTINA_CS7542_H
+#define _DT_BINDINGS_RESET_CORTINA_CS7542_H
+
+#define CS7542_RESET_PCIE0	0
+#define CS7542_RESET_PCIE1	1
+#define CS7542_RESET_PCIE2	2
+
+#endif

-- 
2.53.0

