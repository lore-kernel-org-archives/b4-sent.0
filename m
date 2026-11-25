From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Wed, 25 Nov 2026 11:17:42 +0100
Subject: [PATCH 2/4] dt-bindings: PCI: qcom,pcie-x1e80100: Add
 qcom,pcie-recalibration-thermal-zones
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-glymur-thermal-fix-v1-2-b93a9feae156@oss.qualcomm.com>
References: <20261125-glymur-thermal-fix-v1-0-b93a9feae156@oss.qualcomm.com>
In-Reply-To: <20261125-glymur-thermal-fix-v1-0-b93a9feae156@oss.qualcomm.com>
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-pci@vger.kernel.org, 
 devicetree@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2757;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=aidfoMBoiQFj9PzexN43ZSatE2G0PFF5W2U8Fq+yNOs=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBrBrXNmeIZ+xo9d+6cYA3A3WnzI93dWegmdWvDl
 v2SLtNsk8iJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCawa1zQAKCRBVnxHm/pHO
 9SOtB/4hE4AsbhtT5MCVl/8n4v+pw50876z4vtxVRxyPWqMWh1b5LvHYQnYW0H9eq+3+iE4XKZy
 QmWq2Qwi9Tx6/KkzQovRPhDEsjG201TTzCj/TFYw2LtYXWxpzwwrwomQdgzkVeMbxWFitDQ38+Q
 8aDib88CyVoLJWsAyQBej4MfyUSQW2EuzAkji+MECYd14s3C0FNz5or24aqFegXob8txy7AKhoO
 krDPtRD6txfWJJFxT5uyYsSBxCTO4jXX3PrkecShDVsPGYzUUC4Ob05mxnp+ba9saBcN2ivXhDG
 tHDVXOJMbn8pXDcNJxPeOouDXFrGIeTaDdJkt1mq9GMQ0qz3
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some PCIe PHY instances on SoCs like Glymur benefit from periodic
recalibration to compensate for temperature-related drift and maintain
stable link operation. Otherwise there is a potential for a link drop. The
recalibration is performed by the hardware during a PCIe link speed
switch, which the driver initiates once the temperature change on a
polled sensor exceeds the defined threshold. For this purpose, the driver
needs to know which sensors track the PHY temperature and the drift
temperature.

So introduce a new property 'qcom,pcie-recalibration-thermal-zones' to
specify the tuples of thermal zone phandle and the drift temperature in
millidegree Celsius to be monitored by the driver, and allow it only for
Glymur, which is the only SoC needing it so far.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 .../bindings/pci/qcom,pcie-x1e80100.yaml           | 31 ++++++++++++++++++++++
 1 file changed, 31 insertions(+)

diff --git a/Documentation/devicetree/bindings/pci/qcom,pcie-x1e80100.yaml b/Documentation/devicetree/bindings/pci/qcom,pcie-x1e80100.yaml
index 3d3b9f309a73..389a6bbacaa9 100644
--- a/Documentation/devicetree/bindings/pci/qcom,pcie-x1e80100.yaml
+++ b/Documentation/devicetree/bindings/pci/qcom,pcie-x1e80100.yaml
@@ -78,6 +78,26 @@ properties:
       - const: pci # PCIe core reset
       - const: link_down # PCIe link down reset
 
+  qcom,pcie-recalibration-thermal-zones:
+    $ref: /schemas/types.yaml#/definitions/phandle-array
+    minItems: 1
+    maxItems: 16
+    items:
+      items:
+        - description:
+            Phandle to a thermal zone corresponding to the sensor used to
+            monitor the PHY temperature drift.
+        - description:
+            Temperature drift this zone is allowed to accumulate before the
+            PHY needs a fresh calibration, in millidegree Celsius.
+          minimum: 1000
+          maximum: 100000
+    description:
+      Thermal zones whose sensors track the PCIe PHY temperature, along with
+      the temperature drift each zone is allowed to accumulate before the PHY
+      needs a fresh calibration. Applies to PCIe instances that rely on
+      periodic PHY recalibration to maintain stable link operation.
+
 required:
   - power-domains
   - resets
@@ -85,6 +105,17 @@ required:
 
 allOf:
   - $ref: qcom,pcie-common.yaml#
+  - if:
+      properties:
+        compatible:
+          contains:
+            const: qcom,glymur-pcie
+    then:
+      properties:
+        qcom,pcie-recalibration-thermal-zones: true
+    else:
+      properties:
+        qcom,pcie-recalibration-thermal-zones: false
 
 unevaluatedProperties: false
 

-- 
2.43.0

