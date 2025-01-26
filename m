From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Sun, 26 Jan 2025 19:59:03 +0100
Subject: [PATCH 8/9] dt-bindings: spi: Convert Freescale SPI bindings to
 YAML
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250126-ppcyaml-v1-8-50649f51c3dd@posteo.net>
References: <20250126-ppcyaml-v1-0-50649f51c3dd@posteo.net>
In-Reply-To: <20250126-ppcyaml-v1-0-50649f51c3dd@posteo.net>
To: devicetree@vger.kernel.org, linuxppc-dev@lists.ozlabs.org
Cc: Scott Wood <oss@buserror.net>, 
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1737917943; l=6825;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=xDa2X5ix7Yz+uUKr7B2an+BkT3tqXXsRwdduIK9iWgc=;
 b=4QCYXX3kpPGMdIqbCZvKPP/cQo3jUJcs6wRQLhb2Owtx6YTpaYDSWzkNBanZH6Dsamu4kpkge
 fyBklNraCwfDQXDyg9Fcfu6YmzGiRTaSu2oLelsxED9beNbs3wG63u6
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

fsl-spi.txt contains the bindings for the fsl,spi and fsl,espi
contollers. Convert them to YAML.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 .../devicetree/bindings/spi/fsl,espi.yaml          | 56 +++++++++++++++++
 Documentation/devicetree/bindings/spi/fsl,spi.yaml | 71 ++++++++++++++++++++++
 Documentation/devicetree/bindings/spi/fsl-spi.txt  | 62 -------------------
 3 files changed, 127 insertions(+), 62 deletions(-)

diff --git a/Documentation/devicetree/bindings/spi/fsl,espi.yaml b/Documentation/devicetree/bindings/spi/fsl,espi.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..350275760210c5763af0c7b1e1522ccbfb97eec7
--- /dev/null
+++ b/Documentation/devicetree/bindings/spi/fsl,espi.yaml
@@ -0,0 +1,56 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/spi/fsl,espi.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Freescale eSPI (Enhanced Serial Peripheral Interface) controller
+
+maintainers:
+  - J. Neuschäfer <j.ne@posteo.net>
+
+properties:
+  compatible:
+    const: fsl,mpc8536-espi
+
+  reg:
+    maxItems: 1
+
+  interrupts: true
+
+  fsl,espi-num-chipselects:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    description: The number of the chipselect signals.
+
+  fsl,csbef:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    description: Chip select assertion time in bits before frame starts
+
+  fsl,csaft:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    description: Chip select negation time in bits after frame ends
+
+required:
+  - compatible
+  - reg
+  - interrupts
+  - fsl,espi-num-chipselects
+
+allOf:
+  - $ref: spi-controller.yaml#
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    spi@110000 {
+        #address-cells = <1>;
+        #size-cells = <0>;
+        compatible = "fsl,mpc8536-espi";
+        reg = <0x110000 0x1000>;
+        interrupts = <53 0x2>;
+        interrupt-parent = <&mpic>;
+        fsl,espi-num-chipselects = <4>;
+        fsl,csbef = <1>;
+        fsl,csaft = <1>;
+    };
diff --git a/Documentation/devicetree/bindings/spi/fsl,spi.yaml b/Documentation/devicetree/bindings/spi/fsl,spi.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..8efa971b5954a93665cb624345774f2966bb5648
--- /dev/null
+++ b/Documentation/devicetree/bindings/spi/fsl,spi.yaml
@@ -0,0 +1,71 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/spi/fsl,spi.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Freescale SPI (Serial Peripheral Interface) controller
+
+maintainers:
+  - J. Neuschäfer <j.ne@posteo.net>
+
+properties:
+  compatible:
+    enum:
+      - fsl,spi
+      - aeroflexgaisler,spictrl
+
+  reg:
+    maxItems: 1
+
+  cell-index:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    description: |
+      QE SPI subblock index.
+      0: QE subblock SPI1
+      1: QE subblock SPI2
+
+  mode:
+    description: SPI operation mode
+    enum:
+      - cpu
+      - cpu-qe
+
+  interrupts: true
+
+  clock-frequency:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    description: input clock frequency to non FSL_SOC cores
+
+  cs-gpios: true
+
+  fsl,spisel_boot:
+    $ref: /schemas/types.yaml#/definitions/flag
+    description:
+      For the MPC8306 and MPC8309, specifies that the SPISEL_BOOT signal is used
+      as chip select for a slave device. Use reg = <number of gpios> in the
+      corresponding child node, i.e. 0 if the cs-gpios property is not present.
+
+required:
+  - compatible
+  - reg
+  - mode
+  - interrupts
+
+allOf:
+  - $ref: spi-controller.yaml#
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    spi@4c0 {
+        cell-index = <0>;
+        compatible = "fsl,spi";
+        reg = <0x4c0 0x40>;
+        interrupts = <82 0>;
+        interrupt-parent = <&intc>;
+        mode = "cpu";
+        cs-gpios = <&gpio 18 1          // device reg=<0>
+                    &gpio 19 1>;        // device reg=<1>
+    };
diff --git a/Documentation/devicetree/bindings/spi/fsl-spi.txt b/Documentation/devicetree/bindings/spi/fsl-spi.txt
deleted file mode 100644
index 0654380eb7515d8bda80eea1486e77b939ac38d8..0000000000000000000000000000000000000000
--- a/Documentation/devicetree/bindings/spi/fsl-spi.txt
+++ /dev/null
@@ -1,62 +0,0 @@
-* SPI (Serial Peripheral Interface)
-
-Required properties:
-- cell-index : QE SPI subblock index.
-		0: QE subblock SPI1
-		1: QE subblock SPI2
-- compatible : should be "fsl,spi" or "aeroflexgaisler,spictrl".
-- mode : the SPI operation mode, it can be "cpu" or "cpu-qe".
-- reg : Offset and length of the register set for the device
-- interrupts : <a b> where a is the interrupt number and b is a
-  field that represents an encoding of the sense and level
-  information for the interrupt.  This should be encoded based on
-  the information in section 2) depending on the type of interrupt
-  controller you have.
-- clock-frequency : input clock frequency to non FSL_SOC cores
-
-Optional properties:
-- cs-gpios : specifies the gpio pins to be used for chipselects.
-  The gpios will be referred to as reg = <index> in the SPI child nodes.
-  If unspecified, a single SPI device without a chip select can be used.
-- fsl,spisel_boot : for the MPC8306 and MPC8309, specifies that the
-  SPISEL_BOOT signal is used as chip select for a slave device. Use
-  reg = <number of gpios> in the corresponding child node, i.e. 0 if
-  the cs-gpios property is not present.
-
-Example:
-	spi@4c0 {
-		cell-index = <0>;
-		compatible = "fsl,spi";
-		reg = <4c0 40>;
-		interrupts = <82 0>;
-		interrupt-parent = <700>;
-		mode = "cpu";
-		cs-gpios = <&gpio 18 1		// device reg=<0>
-			    &gpio 19 1>;	// device reg=<1>
-	};
-
-
-* eSPI (Enhanced Serial Peripheral Interface)
-
-Required properties:
-- compatible : should be "fsl,mpc8536-espi".
-- reg : Offset and length of the register set for the device.
-- interrupts : should contain eSPI interrupt, the device has one interrupt.
-- fsl,espi-num-chipselects : the number of the chipselect signals.
-
-Optional properties:
-- fsl,csbef: chip select assertion time in bits before frame starts
-- fsl,csaft: chip select negation time in bits after frame ends
-
-Example:
-	spi@110000 {
-		#address-cells = <1>;
-		#size-cells = <0>;
-		compatible = "fsl,mpc8536-espi";
-		reg = <0x110000 0x1000>;
-		interrupts = <53 0x2>;
-		interrupt-parent = <&mpic>;
-		fsl,espi-num-chipselects = <4>;
-		fsl,csbef = <1>;
-		fsl,csaft = <1>;
-	};

-- 
2.48.0.rc1.219.gb6b6757d772

