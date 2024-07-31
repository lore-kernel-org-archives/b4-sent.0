From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Wed, 31 Jul 2024 16:20:07 +0530
Subject: [PATCH v3 04/13] dt-bindings: PCI: pci-ep: Document
 'linux,pci-domain' property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240731-pci-qcom-hotplug-v3-4-a1426afdee3b@linaro.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2076;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=gFM57NfjI22HI5zO2G4ZyvVdTIrBmxWoCkDYpg/zh4Q=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmqhbiAb7YQ78WmQL+3pg/asHYaUv2cb/2l//Pm
 jyYj96EdqiJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZqoW4gAKCRBVnxHm/pHO
 9WmQB/9si9S+OmgvS+y51lNqf3cu9EerZUXmpMp9BQPH2G/MbNfuM5P1TnLhFhuNHIDsykyo6kf
 TSKZDjpNjKUtwUKI8/6fVP4laVkYCwd11+WzWiAigELfLKB+3whUNPxIcqxeRXWNFIkGvAHhuW5
 oNTVEpq1kZdGX3LVsVX5QLw+c19f8RLzW3/vOnHzernLgouZFW/RT/Pt+ZAm3APCnE34rMIP4a5
 2qErJkVovUD40tPkIjPs8tm/Xmj0mVhF4rzufUqkbgiVqSedMqVddEeo+Ro3TCNBK3uO+jD7qsp
 YbvEvOq0n3LUQ1jVGxkBdTrrxEwOG5Qy1pC3128GwI+Bk4Td
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

