From: George Moussalem <george.moussalem@outlook.com>
Date: Tue, 25 Aug 2026 16:37:19 +0400
Subject: [PATCH v3 02/12] dt-bindings: phy: qcom,ipq5332-uniphy-pcie-usb3:
 Document the IPQ5018 USB3 PHY
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260825-ipq5018-usb3-v3-2-39be0955a6aa@outlook.com>
References: <20260825-ipq5018-usb3-v3-0-39be0955a6aa@outlook.com>
In-Reply-To: <20260825-ipq5018-usb3-v3-0-39be0955a6aa@outlook.com>
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
 Manivannan Sadhasivam <mani@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787661450; l=1847;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=X92ejnhwDPtga79pHvMyqYjnXONSziO0EJioVCS0ABA=;
 b=m2T5qx7FPQMNTLk6lhedEpBLyrSqTSMrw5CpPDaxTCtZaJUi54zkvLB+c4zokXIz766afBBvE
 7EenPiSHMiUCWe/aRlPY1IDzvQQ59R5jdMNVESIXmlesBZs0nsu2Y2F
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the USB3 PHY found in the IPQ5018 SoC so add the compatible
string for it as well as the required resources (clocks and resets).

The PCIe and USB physical pads are muxed and selection is done via a
control register in TCSR. By default, PCIe mode is selected, hence make
the property for USB mux selection required.

In addition, the PHY requires a 5V supply for USB3 mode operation.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 .../phy/qcom,ipq5332-uniphy-pcie-usb3-phy.yaml     | 24 ++++++++++++++++++++++
 1 file changed, 24 insertions(+)

diff --git a/Documentation/devicetree/bindings/phy/qcom,ipq5332-uniphy-pcie-usb3-phy.yaml b/Documentation/devicetree/bindings/phy/qcom,ipq5332-uniphy-pcie-usb3-phy.yaml
index 0d9d0fb405b6..1cd5392a1a0f 100644
--- a/Documentation/devicetree/bindings/phy/qcom,ipq5332-uniphy-pcie-usb3-phy.yaml
+++ b/Documentation/devicetree/bindings/phy/qcom,ipq5332-uniphy-pcie-usb3-phy.yaml
@@ -18,6 +18,7 @@ properties:
   compatible:
     enum:
       - qcom,ipq5018-uniphy-pcie-phy
+      - qcom,ipq5018-uniphy-usb3-phy
       - qcom,ipq5332-uniphy-pcie-phy
 
   reg:
@@ -93,6 +94,29 @@ allOf:
       required:
         - num-lanes
 
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
+        "#clock-cells":
+          const: 0
+        "#phy-cells":
+          const: 0
+      required:
+        - vdd-supply
+        - qcom,phy-usb-mux-sel
+
   - if:
       properties:
         compatible:

-- 
2.53.0

