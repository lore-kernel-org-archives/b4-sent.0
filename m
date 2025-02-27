From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Thu, 27 Feb 2025 19:10:51 +0530
Subject: [PATCH 09/23] dt-bindings: PCI: qcom,pcie-sc7280: Add 'global'
 interrupt
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250227-pcie-global-irq-v1-9-2b70a7819d1e@linaro.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1743;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=Ypfuedp5Iva71ub+3I/TErUi7/T1H5RxWeczTJusiAc=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnwGtft6BtrM1tZFvua316Ng6Gc9IK8GbDisgWv
 z7AYhsGqx+JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZ8BrXwAKCRBVnxHm/pHO
 9VbzB/9Ig+5sg5vOcKeWP1vv+i09AEn/enAbcsxRlnSer+8tiPwmmybKoQlitBsnYR23DRrgp5a
 SCCbxeHq/4Ygci1rw3vd2/AzKrAQX2BVCavFwjafDpy5ltQjEiY+NAbkgTwtK9Q7JobPj1Q3x/h
 vkofVspBS8MudSfqBkvQigmmPupQb+s38Ts5UDkpfJk4PF2kreTDaFpsI6LRaRg3+KHQsSHX/zd
 EV7JDhipM3ZKsyY/46p2j2uRq3Hehd1O1gsVW6536RNelaGrJLGbpcCnjkoVGR9xWlB4XAR996P
 BkgpbIxTqTENDBp2izD2gppD0ni2F4z5/VYwbGpLoCJwBH+k
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

'global' interrupt is used to receive PCIe controller and link specific
events.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 Documentation/devicetree/bindings/pci/qcom,pcie-sc7280.yaml | 9 ++++++---
 1 file changed, 6 insertions(+), 3 deletions(-)

diff --git a/Documentation/devicetree/bindings/pci/qcom,pcie-sc7280.yaml b/Documentation/devicetree/bindings/pci/qcom,pcie-sc7280.yaml
index 76cb9fbfd476..ff508f592a1a 100644
--- a/Documentation/devicetree/bindings/pci/qcom,pcie-sc7280.yaml
+++ b/Documentation/devicetree/bindings/pci/qcom,pcie-sc7280.yaml
@@ -54,9 +54,10 @@ properties:
 
   interrupts:
     minItems: 8
-    maxItems: 8
+    maxItems: 9
 
   interrupt-names:
+    minItems: 8
     items:
       - const: msi0
       - const: msi1
@@ -66,6 +67,7 @@ properties:
       - const: msi5
       - const: msi6
       - const: msi7
+      - const: global
 
   resets:
     maxItems: 1
@@ -149,9 +151,10 @@ examples:
                          <GIC_SPI 313 IRQ_TYPE_LEVEL_HIGH>,
                          <GIC_SPI 314 IRQ_TYPE_LEVEL_HIGH>,
                          <GIC_SPI 374 IRQ_TYPE_LEVEL_HIGH>,
-                         <GIC_SPI 375 IRQ_TYPE_LEVEL_HIGH>;
+                         <GIC_SPI 375 IRQ_TYPE_LEVEL_HIGH>,
+                         <GIC_SPI 306 IRQ_TYPE_LEVEL_HIGH>;
             interrupt-names = "msi0", "msi1", "msi2", "msi3",
-                              "msi4", "msi5", "msi6", "msi7";
+                              "msi4", "msi5", "msi6", "msi7", "global";
             #interrupt-cells = <1>;
             interrupt-map-mask = <0 0 0 0x7>;
             interrupt-map = <0 0 0 1 &intc 0 0 0 434 IRQ_TYPE_LEVEL_HIGH>,

-- 
2.25.1

