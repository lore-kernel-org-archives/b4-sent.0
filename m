From: George Moussalem <george.moussalem@outlook.com>
Date: Fri, 21 Mar 2025 13:09:52 +0400
Subject: [PATCH v5 3/6] dt-bindings: PCI: qcom: Add IPQ5018 SoC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250321-ipq5018-pcie-v5-3-aae2caa1f418@outlook.com>
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
 Sricharan Ramabadhran <quic_srichara@quicinc.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742548192; l=3072;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=n1pq98OF6nCyGBtv37e9qjebYlzLP26UOUQF23Nah7k=;
 b=HxPtt29b2Xz941ykzosjFdDL8NuX+ZEK2YcOobB5XMVeU6a5/fRbB1/AoDv3IkRPTvw/kIeFR
 jELXAyxOONsD0mbl6CnC8bWsvuO26Rv2d3HZXzGL3fTI/s43hIxU45F
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Nitheesh Sekar <quic_nsekar@quicinc.com>

Add support for the PCIe controller on the Qualcomm
IPQ5108 SoC to the bindings.

Signed-off-by: Nitheesh Sekar <quic_nsekar@quicinc.com>
Signed-off-by: Sricharan Ramabadhran <quic_srichara@quicinc.com>
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 .../devicetree/bindings/pci/qcom,pcie.yaml         | 50 ++++++++++++++++++++++
 1 file changed, 50 insertions(+)

diff --git a/Documentation/devicetree/bindings/pci/qcom,pcie.yaml b/Documentation/devicetree/bindings/pci/qcom,pcie.yaml
index 469b99fa0f0e..668ff03f2561 100644
--- a/Documentation/devicetree/bindings/pci/qcom,pcie.yaml
+++ b/Documentation/devicetree/bindings/pci/qcom,pcie.yaml
@@ -21,6 +21,7 @@ properties:
           - qcom,pcie-apq8064
           - qcom,pcie-apq8084
           - qcom,pcie-ipq4019
+          - qcom,pcie-ipq5018
           - qcom,pcie-ipq6018
           - qcom,pcie-ipq8064
           - qcom,pcie-ipq8064-v2
@@ -168,6 +169,7 @@ allOf:
         compatible:
           contains:
             enum:
+              - qcom,pcie-ipq5018
               - qcom,pcie-ipq6018
               - qcom,pcie-ipq8074-gen3
               - qcom,pcie-ipq9574
@@ -324,6 +326,53 @@ allOf:
             - const: ahb # AHB reset
             - const: phy_ahb # PHY AHB reset
 
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - qcom,pcie-ipq5018
+    then:
+      properties:
+        clocks:
+          minItems: 6
+          maxItems: 6
+        clock-names:
+          items:
+            - const: iface # PCIe to SysNOC BIU clock
+            - const: axi_m # AXI Master clock
+            - const: axi_s # AXI Slave clock
+            - const: ahb # AHB clock
+            - const: aux # Auxiliary clock
+            - const: axi_bridge # AXI bridge clock
+        resets:
+          minItems: 8
+          maxItems: 8
+        reset-names:
+          items:
+            - const: pipe # PIPE reset
+            - const: sleep # Sleep reset
+            - const: sticky # Core sticky reset
+            - const: axi_m # AXI master reset
+            - const: axi_s # AXI slave reset
+            - const: ahb # AHB reset
+            - const: axi_m_sticky # AXI master sticky reset
+            - const: axi_s_sticky # AXI slave sticky reset
+        interrupts:
+          minItems: 9
+          maxItems: 9
+        interrupt-names:
+          items:
+            - const: msi0
+            - const: msi1
+            - const: msi2
+            - const: msi3
+            - const: msi4
+            - const: msi5
+            - const: msi6
+            - const: msi7
+            - const: global
+
   - if:
       properties:
         compatible:
@@ -564,6 +613,7 @@ allOf:
               enum:
                 - qcom,pcie-apq8064
                 - qcom,pcie-ipq4019
+                - qcom,pcie-ipq5018
                 - qcom,pcie-ipq8064
                 - qcom,pcie-ipq8064v2
                 - qcom,pcie-ipq8074

-- 
2.48.1

