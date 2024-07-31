From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Wed, 31 Jul 2024 16:20:14 +0530
Subject: [PATCH v3 11/13] dt-bindings: PCI: qcom,pcie-sm8450: Add 'global'
 interrupt
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240731-pci-qcom-hotplug-v3-11-a1426afdee3b@linaro.org>
References: <20240731-pci-qcom-hotplug-v3-0-a1426afdee3b@linaro.org>
In-Reply-To: <20240731-pci-qcom-hotplug-v3-0-a1426afdee3b@linaro.org>
To: Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kw@linux.com>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-pci@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=openpgp-sha256; l=2096;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=w4cY5FEuD1vubOFd7Zhbt7y5H9yLj0yvZBQOIyWPebc=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmqhbkakmaRXQMThiXty5wzJtqGzDoKQJJtmLBw
 VRycaPEeJeJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZqoW5AAKCRBVnxHm/pHO
 9dngB/kBPbwnipqgE9LYCyvM7tsqZnqrzPBVSl+ShZO4DBdntLhupwJWwoBGIOLNCS4UPNmNkI5
 aEu/3uV3MI7G6IiUxXbDsnbH9bTKYNrmM9hLySVzr+rvvTbZJV2YeHCya65WOQCpWIfDwt9cVaC
 RZgwv3x9vnXEc2lF+YIRgzogwadwbn+iYCYh4Ykrze5gut+mjGsxdNiJa2euaF+d7r4g22h8HJG
 lA2aPMhzwKrDj5zjG8dMTpiyGlAWVnq9gBRRVvFQaHLjj+oKAK53jWHuPaM/NzlmkQveKEYVxY0
 hD4RHBZxKOQjKG2lASxkAkCTX9Ec8SPNSiw9H7LApYxU9gM1
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Qcom PCIe RC controllers are capable of generating 'global' SPI interrupt
to the host CPU. This interrupt can be used by the device driver to
identify events such as PCIe link specific events, safety events, etc...

Hence, document it in the binding along with the existing MSI interrupts.
Though adding a new interrupt will break the ABI, it is required to
accurately describe the hardware.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 Documentation/devicetree/bindings/pci/qcom,pcie-sm8450.yaml | 10 ++++++----
 1 file changed, 6 insertions(+), 4 deletions(-)

diff --git a/Documentation/devicetree/bindings/pci/qcom,pcie-sm8450.yaml b/Documentation/devicetree/bindings/pci/qcom,pcie-sm8450.yaml
index d8c0afaa4b19..46bd59eefadb 100644
--- a/Documentation/devicetree/bindings/pci/qcom,pcie-sm8450.yaml
+++ b/Documentation/devicetree/bindings/pci/qcom,pcie-sm8450.yaml
@@ -55,8 +55,8 @@ properties:
       - const: aggre1 # Aggre NoC PCIe1 AXI clock
 
   interrupts:
-    minItems: 8
-    maxItems: 8
+    minItems: 9
+    maxItems: 9
 
   interrupt-names:
     items:
@@ -68,6 +68,7 @@ properties:
       - const: msi5
       - const: msi6
       - const: msi7
+      - const: global
 
   operating-points-v2: true
   opp-table:
@@ -149,9 +150,10 @@ examples:
                          <GIC_SPI 145 IRQ_TYPE_LEVEL_HIGH>,
                          <GIC_SPI 146 IRQ_TYPE_LEVEL_HIGH>,
                          <GIC_SPI 147 IRQ_TYPE_LEVEL_HIGH>,
-                         <GIC_SPI 148 IRQ_TYPE_LEVEL_HIGH>;
+                         <GIC_SPI 148 IRQ_TYPE_LEVEL_HIGH>,
+                         <GIC_SPI 140 IRQ_TYPE_LEVEL_HIGH>;
             interrupt-names = "msi0", "msi1", "msi2", "msi3",
-                              "msi4", "msi5", "msi6", "msi7";
+                              "msi4", "msi5", "msi6", "msi7", "global";
             #interrupt-cells = <1>;
             interrupt-map-mask = <0 0 0 0x7>;
             interrupt-map = <0 0 0 1 &intc 0 0 0 149 IRQ_TYPE_LEVEL_HIGH>, /* int_a */

-- 
2.25.1

