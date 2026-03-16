From: Jia Wang <wangjia@ultrarisc.com>
Date: Mon, 16 Mar 2026 15:06:59 +0800
Subject: [PATCH 3/4] dt-bindings: PCI: Add UltraRISC DP1000 PCIe controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260316-ultrarisc-pcie-v1-3-ef2946ede698@ultrarisc.com>
References: <20260316-ultrarisc-pcie-v1-0-ef2946ede698@ultrarisc.com>
In-Reply-To: <20260316-ultrarisc-pcie-v1-0-ef2946ede698@ultrarisc.com>
To: Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Albert Ou <aou@eecs.berkeley.edu>, Alexandre Ghiti <alex@ghiti.fr>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>, Jingoo Han <jingoohan1@gmail.com>, 
 Xincheng Zhang <zhangxincheng@ultrarisc.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-riscv@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-pci@vger.kernel.org, devicetree@vger.kernel.org, 
 Jia Wang <wangjia@ultrarisc.com>
X-Mailer: b4 0.15-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773644922; l=3662;
 i=wangjia@ultrarisc.com; s=20260309; h=from:subject:message-id;
 bh=nD9gA9EKG6xe+XUDTqlleMYCHKvkqt4+oCKLxokSvt4=;
 b=MGeeWLEgIvcIfEisStVOuydBYqRjk3U61LnS/xnp67AAPQXB8zlZOT01Mp14YJQDYLPmwhljI
 3nR3K1SADJ2DRpuLDddU8DxUN/+EdsqsXLX+Mwx0D7x6UL173T1JcBF
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=XvYkrelqJIIzobY7j+nIg8rsfv5kzaOzuc1UPhd087U=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260309 with auth_id=682
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add UltraRISC DP1000 SoC PCIe controller devicetree bindings.

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
 .../bindings/pci/ultrarisc,dp1000-pcie.yaml        | 108 +++++++++++++++++++++
 1 file changed, 108 insertions(+)

diff --git a/Documentation/devicetree/bindings/pci/ultrarisc,dp1000-pcie.yaml b/Documentation/devicetree/bindings/pci/ultrarisc,dp1000-pcie.yaml
new file mode 100644
index 000000000000..b50ff98dd878
--- /dev/null
+++ b/Documentation/devicetree/bindings/pci/ultrarisc,dp1000-pcie.yaml
@@ -0,0 +1,108 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/pci/ultrarisc,dp1000-pcie.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: UltraRISC DP1000 PCIe Host Controller
+
+description: |
+  UltraRISC DP1000 SoC PCIe host controller is based on the DesignWare PCIe IP.
+  This binding describes the UltraRISC specific extensions to the base DesignWare
+  PCIe binding.
+
+maintainers:
+  - Xincheng Zhang <zhangxincheng@ultrarisc.com>
+  - Jia Wang <wangjia@ultrarisc.com>
+
+allOf:
+  - $ref: /schemas/pci/pci-bus.yaml#
+
+properties:
+  compatible:
+    const: ultrarisc,dp1000-pcie
+
+  reg:
+      - description: Data Bus Interface (DBI) registers.
+      - description: PCIe configuration space region.
+
+  reg-names:
+    items:
+      - const: dbi
+      - const: config
+
+  num-lanes:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    description:
+      Number of lanes to use.
+      Valid values: 4, 16.
+
+  max-link-speed:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    const: 4
+    description:
+      Maximum PCIe link speed supported. 4 for Gen4.
+
+  interrupt-names:
+    items:
+      - const: msi
+      - const: inta
+      - const: intb
+      - const: intc
+      - const: intd
+
+  device_type:
+    const: pci
+
+  dma-coherent:
+    type: boolean
+
+  bus-range:
+    description:
+      PCI bus range associated with this controller.
+
+  interrupt-map-mask:
+    description:
+      PCI interrupt map mask for this controller.
+
+  interrupt-map:
+    description:
+      PCI interrupt map for this controller.
+
+  required:
+  - compatible
+  - reg
+  - reg-names
+  - interrupts
+  - interrupt-names
+  - device_type
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    pcie_x16: pcie@21000000 {
+        compatible = "ultrarisc,dp1000-pcie";
+        #address-cells = <3>;
+        #size-cells = <2>;
+        #interrupt-cells = <1>;
+        reg = <0x0 0x21000000 0x0 0x01000000>, /* IP registers */
+              <0x0 0x4fff0000 0x0 0x00010000>; /* Configuration space */
+        reg-names = "dbi", "config";
+        device_type = "pci";
+        dma-coherent;
+        bus-range = <0x0 0xff>;
+        num-lanes = <16>;
+        ranges = <0x81000000  0x0 0x4fbf0000  0x0 0x4fbf0000  0x0 0x00400000>, /* io */
+                 <0x82000000  0x0 0x40000000  0x0 0x40000000  0x0 0x0fbf0000>, /* mem32 */
+                 <0xc3000000 0x40 0x00000000 0x40 0x00000000  0xd 0x00000000>; /* mem64 prefetchable */
+        max-link-speed = <4>;
+        interrupt-parent = <&plic>;
+        interrupts = <43>, <44>, <45>, <46>, <47>;
+        interrupt-names = "msi", "inta", "intb", "intc", "intd";
+        interrupt-map-mask = <0x0 0x0 0x0 0x7>;
+        interrupt-map = <0x0 0x0 0x0 0x1 &plic 44>,
+                        <0x0 0x0 0x0 0x2 &plic 45>,
+                        <0x0 0x0 0x0 0x3 &plic 46>,
+                        <0x0 0x0 0x0 0x4 &plic 47>;
+    };

-- 
2.34.1

