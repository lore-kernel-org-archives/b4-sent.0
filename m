From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Mon, 15 Jul 2024 23:03:54 +0530
Subject: [PATCH 12/14] dt-bindings: PCI: qcom,pcie-sm8450: Add 'global'
 interrupt
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240715-pci-qcom-hotplug-v1-12-5f3765cc873a@linaro.org>
References: <20240715-pci-qcom-hotplug-v1-0-5f3765cc873a@linaro.org>
In-Reply-To: <20240715-pci-qcom-hotplug-v1-0-5f3765cc873a@linaro.org>
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
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmlV16ZB3NnaJtATae6mwMyrKVJ5xmd5atLfNLa
 xNlnVYMLfiJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZpVdegAKCRBVnxHm/pHO
 9XSNB/sESbYziAXHCBhk6c0y4dDnKo4/6fjFGjaoiyuL3YY+yC6HGf4SU6vfy5rgOSfWQ99qy6+
 y691vXTGGQQx+ZsWpidtNxMp1HrknnTgg4BjRYwAC8UJzvxX1ABF96iHbWDQP0a3AlhsOt0u8sw
 qQoFSu/eleHhcdSoPcIsD0BUoHnT488bVpYbwRPBIUQEGtNDPf2BadLKJiiIT/y3LjrMsMQU4Cb
 RUX+VeDDj0CHEGfgc5zuTDidsls19BPtYjo1NsmEeiNXFfmxYOQJwBJO1NueUznfO8kJO1ctX2S
 jEvWemfxy0WBlS8FybekwrE7jS9uNMo/+WiVQNGGCpvoO5Pc
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

