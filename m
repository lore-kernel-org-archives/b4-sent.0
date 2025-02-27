From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Thu, 27 Feb 2025 19:11:02 +0530
Subject: [PATCH 20/23] dt-bindings: PCI: qcom,pcie-sc8180x: Add 'global'
 interrupt
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250227-pcie-global-irq-v1-20-2b70a7819d1e@linaro.org>
References: <20250227-pcie-global-irq-v1-0-2b70a7819d1e@linaro.org>
In-Reply-To: <20250227-pcie-global-irq-v1-0-2b70a7819d1e@linaro.org>
To: Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kw@linux.com>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, cros-qcom-dts-watchers@chromium.org
Cc: linux-arm-msm@vger.kernel.org, linux-pci@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1916;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=Na12fmGJbdooTFijRdHfDd5PBT36knP9iLScIFZtl68=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnwGtiZFdkTxnv7NuCHp2GN9Rm/aTBWYJZQn+e9
 PwYElIAjVGJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZ8BrYgAKCRBVnxHm/pHO
 9ZWrB/wPz8+bq4a82ucw3T/2CPxOQRWrnjrMU+l1T2nEBfqqz2FKqT8nGL82LGPMYA09hmxSQZ4
 dQ43eZrJgM+l5cK+GMt9iXjEq2/iVhuisdaeqRPJXnbFcjqb3LgY3oNenU+1TYovSoS7LuwmhzS
 YljJhwXsNA7Af4e+AVxlqn9h4XwwUX9Gy2h2v0fkxtjG+0h3aliUZKk5BU2ESVg/sRtW6tlPKVv
 a5e7AIozRvYZhHxnhqOgjdm1G7712zF8KLg6u9aa8xJh1tlgZJShv6eMpGaGtwP0AHAqYE6IHUx
 ZoFX4FEO/DmJVlH62U98LO9KzKFiUjMMDJq+6iHh5Kq1SvD6
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

'global' interrupt is used to receive PCIe controller and link specific
events.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 Documentation/devicetree/bindings/pci/qcom,pcie-sc8180x.yaml | 10 +++++++---
 1 file changed, 7 insertions(+), 3 deletions(-)

diff --git a/Documentation/devicetree/bindings/pci/qcom,pcie-sc8180x.yaml b/Documentation/devicetree/bindings/pci/qcom,pcie-sc8180x.yaml
index baf1813ec0ac..331fc25d7a17 100644
--- a/Documentation/devicetree/bindings/pci/qcom,pcie-sc8180x.yaml
+++ b/Documentation/devicetree/bindings/pci/qcom,pcie-sc8180x.yaml
@@ -49,9 +49,10 @@ properties:
 
   interrupts:
     minItems: 8
-    maxItems: 8
+    maxItems: 9
 
   interrupt-names:
+    minItems: 8
     items:
       - const: msi0
       - const: msi1
@@ -61,6 +62,7 @@ properties:
       - const: msi5
       - const: msi6
       - const: msi7
+      - const: global
 
   resets:
     maxItems: 1
@@ -136,7 +138,8 @@ examples:
                          <GIC_SPI 145 IRQ_TYPE_LEVEL_HIGH>,
                          <GIC_SPI 146 IRQ_TYPE_LEVEL_HIGH>,
                          <GIC_SPI 147 IRQ_TYPE_LEVEL_HIGH>,
-                         <GIC_SPI 148 IRQ_TYPE_LEVEL_HIGH>;
+                         <GIC_SPI 148 IRQ_TYPE_LEVEL_HIGH>,
+                         <GIC_SPI 140 IRQ_TYPE_LEVEL_HIGH>;
             interrupt-names = "msi0",
                           "msi1",
                           "msi2",
@@ -144,7 +147,8 @@ examples:
                           "msi4",
                           "msi5",
                           "msi6",
-                          "msi7";
+                          "msi7",
+                          "global";
             #interrupt-cells = <1>;
             interrupt-map-mask = <0 0 0 0x7>;
             interrupt-map = <0 0 0 1 &intc 0 149 IRQ_TYPE_LEVEL_HIGH>, /* int_a */

-- 
2.25.1

