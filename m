From: George Moussalem <george.moussalem@outlook.com>
Date: Tue, 08 Sep 2026 13:40:54 +0400
Subject: [PATCH v4 01/13] dt-bindings: phy: qcom,ipq5332-uniphy-pcie:
 Document the IPQ5018 USB3 PHY
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260908-ipq5018-usb3-v4-1-b789702f0695@outlook.com>
References: <20260908-ipq5018-usb3-v4-0-b789702f0695@outlook.com>
In-Reply-To: <20260908-ipq5018-usb3-v4-0-b789702f0695@outlook.com>
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Praveenkumar I <praveenkumar.i@oss.qualcomm.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 Nitheesh Sekar <quic_nsekar@quicinc.com>, 
 Wesley Cheng <quic_wcheng@quicinc.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Varadarajan Narayanan <quic_varada@quicinc.com>
Cc: linux-arm-msm@vger.kernel.org, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788860512; l=3216;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=TqWnP3AC9DE1HL7njHHwCLpEe8r5+8+QRZEW4l8Wl84=;
 b=rVIhYL1zY84VxVREmCywegI2WeRUzTopjZCJlTxsroMvOs/QiM7ybKgi02klpu6I9dmxxhrkm
 sJvHvCB9GPHCunW0NOfPvtmz50S4yY0W4OI3sHypLF32IGItMLwUdGX
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the USB3 PHY found in the IPQ5018 SoC, so add the compatible
string for it as well as the required resources (clocks and resets).

The PCIe and USB physical pads are muxed and selection is done via a
control register in TCSR. By default, PCIe mode is selected, hence make
the property for USB mux selection required.

In addition, the PHY requires a 5V supply for USB3 mode operation.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 .../bindings/phy/qcom,ipq5332-uniphy-pcie-phy.yaml | 44 ++++++++++++++++++++--
 1 file changed, 41 insertions(+), 3 deletions(-)

diff --git a/Documentation/devicetree/bindings/phy/qcom,ipq5332-uniphy-pcie-phy.yaml b/Documentation/devicetree/bindings/phy/qcom,ipq5332-uniphy-pcie-phy.yaml
index 6e9df81441e9..f59fa4e88866 100644
--- a/Documentation/devicetree/bindings/phy/qcom,ipq5332-uniphy-pcie-phy.yaml
+++ b/Documentation/devicetree/bindings/phy/qcom,ipq5332-uniphy-pcie-phy.yaml
@@ -4,7 +4,7 @@
 $id: http://devicetree.org/schemas/phy/qcom,ipq5332-uniphy-pcie-phy.yaml#
 $schema: http://devicetree.org/meta-schemas/core.yaml#
 
-title: Qualcomm UNIPHY PCIe 28LP PHY
+title: Qualcomm UNIPHY PCIe and USB3 28LP PHY
 
 maintainers:
   - Nitheesh Sekar <quic_nsekar@quicinc.com>
@@ -17,6 +17,7 @@ properties:
   compatible:
     enum:
       - qcom,ipq5018-uniphy-pcie-phy
+      - qcom,ipq5018-uniphy-usb3-phy
       - qcom,ipq5332-uniphy-pcie-phy
 
   reg:
@@ -27,9 +28,24 @@ properties:
     maxItems: 2
 
   resets:
-    minItems: 2
+    minItems: 1
     maxItems: 3
 
+  vdd-supply:
+    description:
+      Phandle to 5V regulator supply to PHY digital circuit.
+
+  qcom,phy-usb-mux-sel:
+    description:
+      TCSR register address for mux selection control for PCIe / USB3 mode.
+      If the property is set, the driver will configure USB3 mux selection.
+      If not set, the setting defaults to PCIe mux selection (BIT(0) = 0).
+    $ref: /schemas/types.yaml#/definitions/phandle-array
+    items:
+      - items:
+          - description: phandle to TCSR syscon
+          - description: offset of PHY mux selection register
+
   "#phy-cells":
     const: 0
 
@@ -47,7 +63,6 @@ required:
   - resets
   - "#phy-cells"
   - "#clock-cells"
-  - num-lanes
 
 additionalProperties: false
 
@@ -67,6 +82,27 @@ allOf:
           items:
             - description: phy reset
             - description: cfg reset
+      required:
+        - num-lanes
+
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - qcom,ipq5018-uniphy-usb3-phy
+    then:
+      properties:
+        clocks:
+          items:
+            - description: usb3 pipe clock
+            - description: usb3 cfg ahb clock
+        resets:
+          items:
+            - description: usb3 phy reset
+      required:
+        - vdd-supply
+        - qcom,phy-usb-mux-sel
 
   - if:
       properties:
@@ -85,6 +121,8 @@ allOf:
             - description: phy reset
             - description: ahb reset
             - description: cfg reset
+      required:
+        - num-lanes
 
 examples:
   - |

-- 
2.53.0

