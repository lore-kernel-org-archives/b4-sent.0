From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Sat, 25 Jul 2026 10:59:13 +0200
Subject: [PATCH 1/6] dt-bindings: PCI: toshiba,tc9563: Restrict Tx
 Amplitude, DFE and N_FTS to USP, DSP1 and DSP2
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260725-tc9563-fix-v1-1-ec4286e31331@oss.qualcomm.com>
References: <20260725-tc9563-fix-v1-0-ec4286e31331@oss.qualcomm.com>
In-Reply-To: <20260725-tc9563-fix-v1-0-ec4286e31331@oss.qualcomm.com>
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>, 
 Bartosz Golaszewski <brgl@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>
Cc: linux-pci@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Alex Elder <elder@riscstar.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2392;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=2krJ+Gl92wRTcPKqXItla8eODcjbHgeoYFXahBYG2pU=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqZHr6GfqZP1O6wg6ZdYOJhuB6Pnrk+LD1NamFs
 f1d4sqK8ceJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCamR6+gAKCRBVnxHm/pHO
 9SzmB/wJLR15r38GlMgy4fVT3L3qnm69jIjilA1lEsYNbcXJXZi0y6UugCxATLL45NED5KoAbUX
 cZjbRGF8+gmlyodDl9NvBGIZpK+8rj85noRq13V7Ej5tF5pNDHSu6vo3AjL7czZ4eG439H8WFP8
 tN5njts3qpL11EHUIVG1vZDImqFA6j/NeuGGCWfbkKQmujW+dAN42TVv7wbpPW/3gpq4QWFCcrY
 PBzfptiA538Q/f/dmo9JG6wfrbn3d64WcH4owl4Vcl6/eD16gRmBE/9iS1ryJYNAq8XiKzHZt1w
 gErpIyWrv5Q2rREHbK1bZdd0rrKJpYSWYc5nRmgnvt4ynmws
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

TC9563 switch allows configuring Tx Amplitude, DFE and N_FTS settings only
to USP, DSP1 and DSP2 ports. These settings don't apply to DSP3 and also
the integrated Ethernet MAC Endpoint.

So restrict these properties and also move the
'toshiba,tx-amplitude-microvolt' property to DSP2 in the example to conform
to the binding.

Fixes: 26f3ac884835 ("dt-bindings: PCI: Add binding for Toshiba TC9563 PCIe switch")
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 .../devicetree/bindings/pci/toshiba,tc9563.yaml     | 21 ++++++++++++++++++---
 1 file changed, 18 insertions(+), 3 deletions(-)

diff --git a/Documentation/devicetree/bindings/pci/toshiba,tc9563.yaml b/Documentation/devicetree/bindings/pci/toshiba,tc9563.yaml
index b3ad05d90201..f084830c6d0c 100644
--- a/Documentation/devicetree/bindings/pci/toshiba,tc9563.yaml
+++ b/Documentation/devicetree/bindings/pci/toshiba,tc9563.yaml
@@ -54,7 +54,7 @@ properties:
           - description: I2C slave address
 
 patternProperties:
-  "^pcie@[1-3],0$":
+  "^pcie@[1-2],0$":
     description:
       child nodes describing the internal downstream ports of
       the tc9563 switch.
@@ -64,6 +64,21 @@ patternProperties:
       - $ref: /schemas/pci/pci-pci-bridge.yaml#
     unevaluatedProperties: false
 
+  "^pcie@[3],0$":
+    description:
+      child node describing the internal downstream port connected to the
+      integrated Ethernet MAC endpoint of the tc9563 switch.
+    type: object
+    $ref: /schemas/pci/pci-pci-bridge.yaml#
+    properties:
+      n-fts: false
+    patternProperties:
+      "^ethernet@0,[0-1]$":
+        type: object
+        properties:
+          n-fts: false
+    unevaluatedProperties: false
+
 $defs:
   tc9563-node:
     type: object
@@ -154,6 +169,8 @@ examples:
                     device_type = "pci";
                     ranges;
                     bus-range = <0x04 0xff>;
+
+                    toshiba,tx-amplitude-microvolt = <10>;
                 };
 
                 pcie@3,0 {
@@ -165,8 +182,6 @@ examples:
                     ranges;
                     bus-range = <0x05 0xff>;
 
-                    toshiba,tx-amplitude-microvolt = <10>;
-
                     ethernet@0,0 {
                         reg = <0x50000 0x0 0x0 0x0 0x0>;
                     };

-- 
2.43.0

