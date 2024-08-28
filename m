From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Wed, 28 Aug 2024 21:16:14 +0530
Subject: [PATCH v4 04/12] dt-bindings: PCI: pci-ep: Document
 'linux,pci-domain' property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240828-pci-qcom-hotplug-v4-4-263a385fbbcb@linaro.org>
References: <20240828-pci-qcom-hotplug-v4-0-263a385fbbcb@linaro.org>
In-Reply-To: <20240828-pci-qcom-hotplug-v4-0-263a385fbbcb@linaro.org>
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
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=2076;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=gFM57NfjI22HI5zO2G4ZyvVdTIrBmxWoCkDYpg/zh4Q=;
 b=owGbwMvMwMUYOl/w2b+J574ynlZLYkg77+b9qPD0zoTmjt55705zP/3VGWERKqNUMP9ExrVHd
 Z3c/vNOdzIaszAwcjHIiimypC911mr0OH1jSYT6dJhBrEwgUxi4OAVgIimZHAzdekYzIpiikz8X
 1a5cw84yuXSRRtFuo1gOe/6+g1/OqoXs9f9b9rHRWT0skqXteknqmp/KSg2dDzPCeGt5wtl+FCw
 Ij27vi9kns9r2jopQk/ySEPmZHrs/2n/745YR2quQ8+924sx9u6+4fv/0qHB+MfPPFX8tctrNrl
 Wl+/R2T+H7W6OX98Bs9nzj1lOvbhk35IqX9B4or3XurmLfnbH+75VQV69Gsa1aqRbOm9JPbf6z/
 ajTD86pW2vly2xKpvHIH+MPPXbTPuB3sm+g0cO/8Uovp+0M7tI5K13IzFv4y931IKu993S/D8dt
 7739za4aKdAwrWLjglJeeWYVZt3HScs+hkie1pRbft0FAA==
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

'linux,pci-domain' property provides the PCI domain number for the PCI
endpoint controllers in a SoC. If this property is not present, then an
unstable (across boots) unique number will be assigned.

Devicetrees can specify the domain number based on the actual hardware
instance of the PCI endpoint controllers in the SoC.

Reviewed-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 Documentation/devicetree/bindings/pci/pci-ep.yaml       | 11 +++++++++++
 Documentation/devicetree/bindings/pci/qcom,pcie-ep.yaml |  1 +
 2 files changed, 12 insertions(+)

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
 
diff --git a/Documentation/devicetree/bindings/pci/qcom,pcie-ep.yaml b/Documentation/devicetree/bindings/pci/qcom,pcie-ep.yaml
index 46802f7d9482..1226ee5d08d1 100644
--- a/Documentation/devicetree/bindings/pci/qcom,pcie-ep.yaml
+++ b/Documentation/devicetree/bindings/pci/qcom,pcie-ep.yaml
@@ -280,4 +280,5 @@ examples:
         phy-names = "pciephy";
         max-link-speed = <3>;
         num-lanes = <2>;
+        linux,pci-domain = <0>;
     };

-- 
2.25.1

