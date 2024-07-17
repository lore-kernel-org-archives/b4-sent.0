From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Wed, 17 Jul 2024 22:33:16 +0530
Subject: [PATCH v2 11/13] dt-bindings: PCI: qcom,pcie-sm8450: Add 'global'
 interrupt
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240717-pci-qcom-hotplug-v2-11-71d304b817f8@linaro.org>
References: <20240717-pci-qcom-hotplug-v2-0-71d304b817f8@linaro.org>
In-Reply-To: <20240717-pci-qcom-hotplug-v2-0-71d304b817f8@linaro.org>
To: Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kw@linux.com>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>
Cc: linux-pci@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=openpgp-sha256; l=2121;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=WTYqEiAQrNsXkDUR6nKibzqYEnKaNCwK2nnJZ4g+zho=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBml/lP9ULqIWFizsPL1F7exFT3gCiltHrrGeD+r
 VHyeE2BUfKJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZpf5TwAKCRBVnxHm/pHO
 9TrlB/9x3P5MCFvYHOJZ0ypEcPgHw43VN7IF/KoZBvA1IoFKnKPUoZzLGrdWSPEdc6UWFL0tQhl
 mmbcdHHyJqAi+jX7WepExANqKvvb3i0SUIIYF9WqvfWSqgorAmOMzpXg1LKSp+Qk2qJwxrXEooC
 rDEUuiw20CW6fCdrPFEhEkHfh2vMmHtRqaKU2FRQC7suZDvyFgGJ48h69B1INLSVSboUuroaTC8
 Lu1L92pHpTGcYY6wNctfRnrymsWoeBrbftVbgXohF+Nou0cRaS2ZVM7OkyARysWj8gPfa8z9zkc
 txNu6TZ2UhQb1Ne0aJRLxkF7053SBtAu5oVp5eFcnICg9XX0
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Qcom PCIe RC controllers are capable of generating 'global' SPI interrupt
to the host CPU. This interrupt can be used by the device driver to
identify events such as PCIe link specific events, safety events, etc...

Hence, document it in the binding along with the existing MSI interrupts.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 Documentation/devicetree/bindings/pci/qcom,pcie-sm8450.yaml | 10 ++++++----
 1 file changed, 6 insertions(+), 4 deletions(-)

diff --git a/Documentation/devicetree/bindings/pci/qcom,pcie-sm8450.yaml b/Documentation/devicetree/bindings/pci/qcom,pcie-sm8450.yaml
index d8c0afaa4b19..0d68ce073383 100644
--- a/Documentation/devicetree/bindings/pci/qcom,pcie-sm8450.yaml
+++ b/Documentation/devicetree/bindings/pci/qcom,pcie-sm8450.yaml
@@ -55,11 +55,12 @@ properties:
       - const: aggre1 # Aggre NoC PCIe1 AXI clock
 
   interrupts:
-    minItems: 8
-    maxItems: 8
+    minItems: 9
+    maxItems: 9
 
   interrupt-names:
     items:
+      - const: global
       - const: msi0
       - const: msi1
       - const: msi2
@@ -142,7 +143,8 @@ examples:
                           "aggre0",
                           "aggre1";
 
-            interrupts = <GIC_SPI 141 IRQ_TYPE_LEVEL_HIGH>,
+            interrupts = <GIC_SPI 140 IRQ_TYPE_LEVEL_HIGH>,
+                         <GIC_SPI 141 IRQ_TYPE_LEVEL_HIGH>,
                          <GIC_SPI 142 IRQ_TYPE_LEVEL_HIGH>,
                          <GIC_SPI 143 IRQ_TYPE_LEVEL_HIGH>,
                          <GIC_SPI 144 IRQ_TYPE_LEVEL_HIGH>,
@@ -150,7 +152,7 @@ examples:
                          <GIC_SPI 146 IRQ_TYPE_LEVEL_HIGH>,
                          <GIC_SPI 147 IRQ_TYPE_LEVEL_HIGH>,
                          <GIC_SPI 148 IRQ_TYPE_LEVEL_HIGH>;
-            interrupt-names = "msi0", "msi1", "msi2", "msi3",
+            interrupt-names = "global", "msi0", "msi1", "msi2", "msi3",
                               "msi4", "msi5", "msi6", "msi7";
             #interrupt-cells = <1>;
             interrupt-map-mask = <0 0 0 0x7>;

-- 
2.25.1

