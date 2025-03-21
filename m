From: George Moussalem <george.moussalem@outlook.com>
Date: Fri, 21 Mar 2025 13:09:50 +0400
Subject: [PATCH v5 1/6] dt-bindings: phy: qcom: uniphy-pcie: Add ipq5018
 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250321-ipq5018-pcie-v5-1-aae2caa1f418@outlook.com>
References: <20250321-ipq5018-pcie-v5-0-aae2caa1f418@outlook.com>
In-Reply-To: <20250321-ipq5018-pcie-v5-0-aae2caa1f418@outlook.com>
To: Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Nitheesh Sekar <quic_nsekar@quicinc.com>, 
 Varadarajan Narayanan <quic_varada@quicinc.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kw@linux.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 Bjorn Helgaas <bhelgaas@google.com>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-pci@vger.kernel.org, George Moussalem <george.moussalem@outlook.com>, 
 20250317100029.881286-2-quic_varada@quicinc.com, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 Sricharan Ramabadhran <quic_srichara@quicinc.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742548192; l=2799;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=YO1GatpnBlBF8JPXKfKBWyGdUDfdpI2iVibaLGfHwaM=;
 b=G3ZMTZMovwOmJ7mZJScYzhYZC9yCXFTseqlRVRwFCeheCUNU6QbHC2PW4Cvjf9KPhT96gDouX
 7VWIvwdHuOmCZvZ/YBiZAoP7g+ZwzunvqDtklP/lgmyKKqHmmTo8Noz
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Nitheesh Sekar <quic_nsekar@quicinc.com>

The IPQ5018 SoC contains a Gen2 1 and 2-lane PCIe UNIPHY which is the
same as the one found in IPQ5332. As such, add IPQ5018 compatible.

Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Signed-off-by: Nitheesh Sekar <quic_nsekar@quicinc.com>
Signed-off-by: Sricharan Ramabadhran <quic_srichara@quicinc.com>
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 .../bindings/phy/qcom,ipq5332-uniphy-pcie-phy.yaml | 57 +++++++++++++++++++---
 1 file changed, 49 insertions(+), 8 deletions(-)

diff --git a/Documentation/devicetree/bindings/phy/qcom,ipq5332-uniphy-pcie-phy.yaml b/Documentation/devicetree/bindings/phy/qcom,ipq5332-uniphy-pcie-phy.yaml
index e39168d55d23..580651eba864 100644
--- a/Documentation/devicetree/bindings/phy/qcom,ipq5332-uniphy-pcie-phy.yaml
+++ b/Documentation/devicetree/bindings/phy/qcom,ipq5332-uniphy-pcie-phy.yaml
@@ -11,26 +11,24 @@ maintainers:
   - Varadarajan Narayanan <quic_varada@quicinc.com>
 
 description:
-  PCIe and USB combo PHY found in Qualcomm IPQ5332 SoC
+  PCIe and USB combo PHY found in Qualcomm IPQ5018 & IPQ5332 SoCs
 
 properties:
   compatible:
     enum:
+      - qcom,ipq5018-uniphy-pcie-phy
       - qcom,ipq5332-uniphy-pcie-phy
 
   reg:
     maxItems: 1
 
   clocks:
-    items:
-      - description: pcie pipe clock
-      - description: pcie ahb clock
+    minItems: 1
+    maxItems: 2
 
   resets:
-    items:
-      - description: phy reset
-      - description: ahb reset
-      - description: cfg reset
+    minItems: 2
+    maxItems: 3
 
   "#phy-cells":
     const: 0
@@ -53,6 +51,49 @@ required:
 
 additionalProperties: false
 
+allOf:
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - qcom,ipq5018-uniphy-pcie-phy
+    then:
+      properties:
+        clocks:
+          minItems: 1
+          maxItems: 1
+          items:
+            - description: pcie pipe clock
+        resets:
+          minItems: 2
+          maxItems: 2
+          items:
+            - description: phy reset
+            - description: cfg reset
+
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - qcom,ipq5332-uniphy-pcie-phy
+    then:
+      properties:
+        clocks:
+          minItems: 2
+          maxItems: 2
+          items:
+            - description: pcie pipe clock
+            - description: pcie ahb clock
+        resets:
+          minItems: 3
+          maxItems: 3
+          items:
+            - description: phy reset
+            - description: ahb reset
+            - description: cfg reset
+
 examples:
   - |
     #include <dt-bindings/clock/qcom,ipq5332-gcc.h>

-- 
2.48.1

