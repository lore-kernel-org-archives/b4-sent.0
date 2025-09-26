From: Frank Li <Frank.Li@nxp.com>
Date: Fri, 26 Sep 2025 14:19:40 -0400
Subject: [PATCH v4 1/4] dt-bindings: usb: add missed compatible string for
 arm64 layerscape
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250926-ls_dma_coherence-v4-1-21e9c6bdb5cb@nxp.com>
References: <20250926-ls_dma_coherence-v4-0-21e9c6bdb5cb@nxp.com>
In-Reply-To: <20250926-ls_dma_coherence-v4-0-21e9c6bdb5cb@nxp.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>, Shawn Guo <shawnguo@kernel.org>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 bjorn.andersson@oss.qualcomm.com, imx@lists.linux.dev, 
 Frank Li <Frank.Li@nxp.com>, Ze Huang <huang.ze@linux.dev>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758910787; l=2369;
 i=Frank.Li@nxp.com; s=20240130; h=from:subject:message-id;
 bh=xECP3rJgzFVmUgwO2Q0SoMn/hJcv7uPuVA3P1+7dxKA=;
 b=ihVrKU/QKLhhdbQULjuiZ91XkMApIntlRtjBuERXvfxnVIj5c3BFkIqber7bGljsF1GxkQ6KR
 Bfgt7U3yFMCAj6hKQNU9RXgqfXcXe4SEEVE92LcG8Lk7VFexIRsEZA+
X-Developer-Key: i=Frank.Li@nxp.com; a=ed25519;
 pk=I0L1sDUfPxpAkRvPKy7MdauTuSENRq+DnA+G4qcS94Q=
X-Endpoint-Received: by B4 Relay for Frank.Li@nxp.com/20240130 with auth_id=121
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add missed compatible string for arm64 layerscape platform. Allow these
fallback to fsl,ls1028a-dwc3.

Remove fallback snps,dwc3 because layerscape dwc3 is not full compatible
with common snps,dwc3 device, a special value gsburstcfg0 need be set when
dma coherence enabled.

Allow iommus property.

Change ref to snps,dwc3-common.yaml to use dwc3 flatten library.

Reviewed-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: Frank Li <Frank.Li@nxp.com>
---
change in v2-v4
- none
---
 .../devicetree/bindings/usb/fsl,ls1028a.yaml       | 33 ++++++++++++----------
 1 file changed, 18 insertions(+), 15 deletions(-)

diff --git a/Documentation/devicetree/bindings/usb/fsl,ls1028a.yaml b/Documentation/devicetree/bindings/usb/fsl,ls1028a.yaml
index a44bdf391887f9c7d565c01d2c3aede99c4a9fc3..4784f057264ac7b18cbc8b41a405f9c9268605bb 100644
--- a/Documentation/devicetree/bindings/usb/fsl,ls1028a.yaml
+++ b/Documentation/devicetree/bindings/usb/fsl,ls1028a.yaml
@@ -9,21 +9,19 @@ title: Freescale layerscape SuperSpeed DWC3 USB SoC controller
 maintainers:
   - Frank Li <Frank.Li@nxp.com>
 
-select:
-  properties:
-    compatible:
-      contains:
-        enum:
-          - fsl,ls1028a-dwc3
-  required:
-    - compatible
-
 properties:
   compatible:
-    items:
-      - enum:
-          - fsl,ls1028a-dwc3
-      - const: snps,dwc3
+    oneOf:
+      - items:
+          - enum:
+              - fsl,ls1012a-dwc3
+              - fsl,ls1043a-dwc3
+              - fsl,ls1046a-dwc3
+              - fsl,ls1088a-dwc3
+              - fsl,ls208xa-dwc3
+              - fsl,lx2160a-dwc3
+          - const: fsl,ls1028a-dwc3
+      - const: fsl,ls1028a-dwc3
 
   reg:
     maxItems: 1
@@ -31,6 +29,11 @@ properties:
   interrupts:
     maxItems: 1
 
+  iommus:
+    maxItems: 1
+
+  dma-coherent: true
+
 unevaluatedProperties: false
 
 required:
@@ -39,14 +42,14 @@ required:
   - interrupts
 
 allOf:
-  - $ref: snps,dwc3.yaml#
+  - $ref: snps,dwc3-common.yaml#
 
 examples:
   - |
     #include <dt-bindings/interrupt-controller/arm-gic.h>
 
     usb@fe800000 {
-        compatible = "fsl,ls1028a-dwc3", "snps,dwc3";
+        compatible = "fsl,ls1028a-dwc3";
         reg = <0xfe800000 0x100000>;
         interrupts = <GIC_SPI 105 IRQ_TYPE_LEVEL_HIGH>;
     };

-- 
2.34.1

