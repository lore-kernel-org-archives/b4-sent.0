From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Fri, 07 Feb 2025 22:30:23 +0100
Subject: [PATCH v2 06/12] dt-bindings: pci: Convert fsl,mpc83xx-pcie to
 YAML
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250207-ppcyaml-v2-6-8137b0c42526@posteo.net>
References: <20250207-ppcyaml-v2-0-8137b0c42526@posteo.net>
In-Reply-To: <20250207-ppcyaml-v2-0-8137b0c42526@posteo.net>
To: devicetree@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 Krzysztof Kozlowski <krzk@kernel.org>
Cc: imx@lists.linux.dev, Scott Wood <oss@buserror.net>, 
 Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 Naveen N Rao <naveen@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Damien Le Moal <dlemoal@kernel.org>, 
 Niklas Cassel <cassel@kernel.org>, Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>, Lee Jones <lee@kernel.org>, 
 Vinod Koul <vkoul@kernel.org>, Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kw@linux.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.neuschaefer@gmx.net>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Mark Brown <broonie@kernel.org>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>, 
 linux-kernel@vger.kernel.org, linux-ide@vger.kernel.org, 
 linux-crypto@vger.kernel.org, dmaengine@vger.kernel.org, 
 linux-pci@vger.kernel.org, linux-watchdog@vger.kernel.org, 
 linux-spi@vger.kernel.org, linux-mtd@lists.infradead.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1738963832; l=5802;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=jBiH9+MQmhRrwEmLTkNNDzkIkSq8VyyQ3zetJ06KX9U=;
 b=sEBW0totelYgL1en7cVmNkknyNI5Sj/Sspm1mJTetH6lj+iSulPd72CfWDp7mXxTwMSsXTvC8
 CcPFFfl4jGrD9Ji4ICjmccGslMxPc79Ljlsx1zaFK/lzwD1MvefNj68
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Formalise the binding for the PCI controllers in the Freescale MPC8xxx
chip family. Information about PCI-X-specific properties was taken from
fsl,pci.txt. The examples were taken from mpc8315erdb.dts and
xpedite5200_xmon.dts.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---

V2:
- merge fsl,pci.txt into fsl,mpc8xxx-pci.yaml
- regroup compatible strings, list single-item values in one enum
- trim subject line (remove "binding")
- fix property order to comply with dts coding style
---
 .../devicetree/bindings/pci/fsl,mpc8xxx-pci.yaml   | 115 +++++++++++++++++++++
 Documentation/devicetree/bindings/pci/fsl,pci.txt  |  27 -----
 2 files changed, 115 insertions(+), 27 deletions(-)

diff --git a/Documentation/devicetree/bindings/pci/fsl,mpc8xxx-pci.yaml b/Documentation/devicetree/bindings/pci/fsl,mpc8xxx-pci.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..57c5503cec47e6e90ed2b09835bfad10309db927
--- /dev/null
+++ b/Documentation/devicetree/bindings/pci/fsl,mpc8xxx-pci.yaml
@@ -0,0 +1,115 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+
+$id: http://devicetree.org/schemas/pci/fsl,mpc8xxx-pci.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Freescale MPC83xx PCI/PCI-X/PCIe controllers
+
+description: |
+  Binding for the PCI/PCI-X/PCIe host bridges on MPC8xxx SoCs.
+  See also: Documentation/devicetree/bindings/pci/fsl,pci.txt
+
+maintainers:
+  - J. Neuschäfer <j.neuschaefer@gmx.net>
+
+allOf:
+  - $ref: /schemas/pci/pci-host-bridge.yaml#
+
+properties:
+  compatible:
+    oneOf:
+      - enum:
+          - fsl,mpc8314-pcie
+          - fsl,mpc8349-pci
+          - fsl,mpc8540-pci
+          - fsl,mpc8548-pcie
+          - fsl,mpc8641-pcie
+      - items:
+          - enum:
+              - fsl,mpc8308-pcie
+              - fsl,mpc8315-pcie
+              - fsl,mpc8377-pcie
+              - fsl,mpc8378-pcie
+          - const: fsl,mpc8314-pcie
+      - items:
+          - const: fsl,mpc8360-pci
+          - const: fsl,mpc8349-pci
+      - items:
+          - const: fsl,mpc8540-pcix
+          - const: fsl,mpc8540-pci
+
+  reg:
+    minItems: 1
+    items:
+      - description: internal registers
+      - description: config space access registers
+
+  clock-frequency: true
+
+  interrupts:
+    items:
+      - description: Consolidated PCI interrupt
+
+  fsl,pci-agent-force-enum:
+    type: boolean
+    description:
+      Typically any Freescale PCI-X bridge hardware strapped into Agent mode is
+      prevented from enumerating the bus. The PrPMC form-factor requires all
+      mezzanines to be PCI-X Agents, but one per system may still enumerate the
+      bus.
+
+      This property allows a PCI-X bridge to be used for bus enumeration
+      despite being strapped into Agent mode.
+
+required:
+  - reg
+  - compatible
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/irq.h>
+
+    pcie@e0009000 {
+        compatible = "fsl,mpc8315-pcie", "fsl,mpc8314-pcie";
+        reg = <0xe0009000 0x00001000>;
+        ranges = <0x02000000 0 0xa0000000 0xa0000000 0 0x10000000
+                  0x01000000 0 0x00000000 0xb1000000 0 0x00800000>;
+        #address-cells = <3>;
+        #size-cells = <2>;
+        #interrupt-cells = <1>;
+        device_type = "pci";
+        bus-range = <0 255>;
+        interrupt-map-mask = <0xf800 0 0 7>;
+        interrupt-map = <0 0 0 1 &ipic 1 IRQ_TYPE_LEVEL_LOW
+                         0 0 0 2 &ipic 1 IRQ_TYPE_LEVEL_LOW
+                         0 0 0 3 &ipic 1 IRQ_TYPE_LEVEL_LOW
+                         0 0 0 4 &ipic 1 IRQ_TYPE_LEVEL_LOW>;
+        clock-frequency = <0>;
+    };
+
+  - |
+    pci@ef008000 {
+        compatible = "fsl,mpc8540-pcix", "fsl,mpc8540-pci";
+        reg = <0xef008000 0x1000>;
+        ranges = <0x02000000 0 0x80000000 0x80000000 0 0x20000000
+                  0x01000000 0 0x00000000 0xd0000000 0 0x01000000>;
+        #interrupt-cells = <1>;
+        #size-cells = <2>;
+        #address-cells = <3>;
+        device_type = "pci";
+        clock-frequency = <33333333>;
+        interrupt-map-mask = <0xf800 0x0 0x0 0x7>;
+        interrupt-map = </* IDSEL */
+                         0xe000 0 0 1 &mpic 2 1
+                         0xe000 0 0 2 &mpic 3 1>;
+        interrupts-extended = <&mpic 24 2>;
+        bus-range = <0 0>;
+        fsl,pci-agent-force-enum;
+    };
+
+
+...
diff --git a/Documentation/devicetree/bindings/pci/fsl,pci.txt b/Documentation/devicetree/bindings/pci/fsl,pci.txt
deleted file mode 100644
index d8ac4a768e7e65b465f83308cc918ec471309dcf..0000000000000000000000000000000000000000
--- a/Documentation/devicetree/bindings/pci/fsl,pci.txt
+++ /dev/null
@@ -1,27 +0,0 @@
-* Bus Enumeration by Freescale PCI-X Agent
-
-Typically any Freescale PCI-X bridge hardware strapped into Agent mode
-is prevented from enumerating the bus. The PrPMC form-factor requires
-all mezzanines to be PCI-X Agents, but one per system may still
-enumerate the bus.
-
-The property defined below will allow a PCI-X bridge to be used for bus
-enumeration despite being strapped into Agent mode.
-
-Required properties:
-- fsl,pci-agent-force-enum : There is no value associated with this
-  property. The property itself is treated as a boolean.
-
-Example:
-
-	/* PCI-X bridge known to be PrPMC Monarch */
-	pci0: pci@ef008000 {
-		fsl,pci-agent-force-enum;
-		#interrupt-cells = <1>;
-		#size-cells = <2>;
-		#address-cells = <3>;
-		compatible = "fsl,mpc8540-pcix", "fsl,mpc8540-pci";
-		device_type = "pci";
-		...
-		...
-	};

-- 
2.48.0.rc1.219.gb6b6757d772

