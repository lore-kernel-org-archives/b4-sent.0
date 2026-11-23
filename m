From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Mon, 23 Nov 2026 23:32:20 +0300
Subject: [PATCH v2 6/8] dt-bindings: PCI: Describe the CS7542 host
 controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-b4-cs7542-pcie-v2-6-f589a9cd0bef@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795465935; l=3988;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=Vmod6N4o3vqaSh1IK8EbHrW7VX/NgdSVfaTIztFcUoM=;
 b=Xivi4LcanyE1E17n8Vs4I3xi+sg0eaz6nTCzeXOlirKlXuA52hN7XWQrVsbCl3vq/6z28ZXkD
 ZYtHAFzN4mWCk2smkJYmOrUSKWJ8qKLTVsCQO9YD6ePkNrMDAf7CBTf
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the DesignWare host wrapper, clock/reset/PHY consumers, combined
interrupt and INTx domain. Document the root configuration access limit.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 .../bindings/pci/cortina,cs7542-pcie.yaml          | 129 +++++++++++++++++++++
 1 file changed, 129 insertions(+)

diff --git a/Documentation/devicetree/bindings/pci/cortina,cs7542-pcie.yaml b/Documentation/devicetree/bindings/pci/cortina,cs7542-pcie.yaml
new file mode 100644
index 000000000..c8ef5176d
--- /dev/null
+++ b/Documentation/devicetree/bindings/pci/cortina,cs7542-pcie.yaml
@@ -0,0 +1,129 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/pci/cortina,cs7542-pcie.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Cortina Systems CS7542 PCIe host controller
+
+maintainers:
+  - Fil Dunsky <filipp.dunsky@gmail.com>
+
+description: |
+  DesignWare host with a Cortina application wrapper. A single interrupt
+  multiplexes four INTx lines, the internal MSI receiver and link errors.
+  Root-port configuration is accessible only below offset 0x200; the
+  DesignWare private register bank starts at offset 0x700.
+
+allOf:
+  - $ref: /schemas/pci/snps,dw-pcie.yaml#
+
+properties:
+  compatible:
+    const: cortina,cs7542-pcie
+
+  reg:
+    items:
+      - description: DBI registers including the viewport iATU
+      - description: Downstream configuration window
+      - description: Application wrapper registers
+
+  reg-names:
+    items:
+      - const: dbi
+      - const: config
+      - const: app
+
+  clocks:
+    maxItems: 1
+
+  interrupts:
+    maxItems: 1
+
+  interrupt-names:
+    const: msi
+
+  resets:
+    maxItems: 1
+
+  phys:
+    maxItems: 1
+
+  phy-names:
+    const: pcie
+
+  num-lanes:
+    const: 1
+
+  reset-gpios:
+    maxItems: 1
+    description: Optional active-low endpoint PERST#
+
+  interrupt-controller:
+    type: object
+    additionalProperties: false
+    properties:
+      "#address-cells":
+        const: 0
+      "#interrupt-cells":
+        const: 1
+      interrupt-controller: true
+    required:
+      - "#address-cells"
+      - "#interrupt-cells"
+      - interrupt-controller
+
+required:
+  - compatible
+  - reg
+  - reg-names
+  - clocks
+  - interrupts
+  - interrupt-names
+  - resets
+  - phys
+  - phy-names
+  - num-lanes
+  - interrupt-controller
+  - interrupt-map
+  - interrupt-map-mask
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/clock/cortina,cs7542-clock.h>
+    #include <dt-bindings/interrupt-controller/arm-gic.h>
+    #include <dt-bindings/reset/cortina,cs7542-reset.h>
+
+    pcie@80000000 {
+        compatible = "cortina,cs7542-pcie";
+        reg = <0x80000000 0x1000>, <0x80001000 0x1000>,
+              <0xf00a0000 0x100>;
+        reg-names = "dbi", "config", "app";
+        #address-cells = <3>;
+        #size-cells = <2>;
+        device_type = "pci";
+        bus-range = <0 0xff>;
+        num-lanes = <1>;
+        ranges = <0x82000000 0 0x80200000 0x80200000 0 0x1fe00000>;
+        clocks = <&global CS7542_CLK_PCIE0>;
+        interrupt-parent = <&gic>;
+        interrupts = <GIC_SPI 33 IRQ_TYPE_LEVEL_HIGH>;
+        interrupt-names = "msi";
+        resets = <&global CS7542_RESET_PCIE0>;
+        phys = <&serdes 0>;
+        phy-names = "pcie";
+        #interrupt-cells = <1>;
+        interrupt-map-mask = <0 0 0 7>;
+        interrupt-map = <0 0 0 1 &pcie_intc 1>,
+                        <0 0 0 2 &pcie_intc 2>,
+                        <0 0 0 3 &pcie_intc 3>,
+                        <0 0 0 4 &pcie_intc 4>;
+
+        pcie_intc: interrupt-controller {
+            #address-cells = <0>;
+            #interrupt-cells = <1>;
+            interrupt-controller;
+        };
+    };

-- 
2.53.0

