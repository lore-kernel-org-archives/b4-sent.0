From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Mon, 15 Jul 2024 23:03:46 +0530
Subject: [PATCH 04/14] dt-bindings: PCI: pci-ep: Document
 'linux,pci-domain' property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240715-pci-qcom-hotplug-v1-4-5f3765cc873a@linaro.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1493;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=AdGl5m97uW0nytJxHIv1uC0b7XTjC/3siXK0QubHe3A=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmlV14F9MHhAndakYHmQubDUeQEqYLKrlW9Kq/s
 a1PHQeg2yCJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZpVdeAAKCRBVnxHm/pHO
 9RR/B/9xARyrbyS7qtcfVGThO0D22TMAVIFcHJjlb98oUOxms57Sz7OYbCh6MVwSk/ZfHGLEEwk
 uOfxUX/ficqQlv9euJIo2MNUoS/Z9X+/LmQctpOTyRa/DQOb1TQlBQc5mPSQI9JWvAyOuUkc+YM
 Gscnc/N8+05NATJ+7HOOImp8lvpoyMsQuFnl8Uf/LjNGMLNIBP1qN27ItK03xnozskJeYxPdFnE
 ftz6QmvjCLR5Fwx1KIsctuIb7Alb2dQhqz4eFZbAyni2Wn0El58ZG9w7wYmzGl6K/eAtsL5sh6z
 bxX5HVZzv0o0cKb0H5uEwNEYfyF4snrcXdWd9BuPZYwiubI6
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

'linux,pci-domain' property provides the PCI domain number for the PCI
endpoint controllers in a SoC. If this property is not present, then an
unstable (across boots) unique number will be assigned.

Devicetrees can specify the domain number based on the actual hardware
instance of the PCI endpoint controllers in the SoC.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 Documentation/devicetree/bindings/pci/pci-ep.yaml | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/Documentation/devicetree/bindings/pci/pci-ep.yaml b/Documentation/devicetree/bindings/pci/pci-ep.yaml
index 0b5456ee21eb..f75000e3093d 100644
--- a/Documentation/devicetree/bindings/pci/pci-ep.yaml
+++ b/Documentation/devicetree/bindings/pci/pci-ep.yaml
@@ -42,6 +42,17 @@ properties:
     default: 1
     maximum: 16
 
+  linux,pci-domain:
+    description:
+      If present this property assigns a fixed PCI domain number to a PCI
+      Endpoint Controller, otherwise an unstable (across boots) unique number
+      will be assigned. It is required to either not set this property at all
+      or set it for all PCI endpoint controllers in the system, otherwise
+      potentially conflicting domain numbers may be assigned to endpoint
+      controllers. The domain number for each endpoint controller in the system
+      must be unique.
+    $ref: /schemas/types.yaml#/definitions/uint32
+
 required:
   - compatible
 

-- 
2.25.1

