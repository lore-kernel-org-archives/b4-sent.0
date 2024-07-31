From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Wed, 31 Jul 2024 16:20:13 +0530
Subject: [PATCH v3 10/13] dt-bindings: PCI: qcom: Add 'global' interrupt
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240731-pci-qcom-hotplug-v3-10-a1426afdee3b@linaro.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1044;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=UnqChimHBG0jtzlN6KxFR0yebxEqg1erfRRq9qEP0p0=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmqhbkB/cWBxZAuW9kvnCZmyNplxRrctsF4Cguu
 0gi2zs5h9mJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZqoW5AAKCRBVnxHm/pHO
 9V6YCACMPaLpig/X0T0VKYUbdat2nq1pdJKlbyHurTfL4nDpP54WIHkmka0L/wiJ52wjEtze+2q
 pcRhyrMPNtZbc8D6/fW7rF12kfYbPwD4oosxWbXYEfO3h/ffv7FYf1wHY7JAG2PRYXXWpkDWzlI
 DoKRA+xjS9KOfUEis3kCTQ7Kt2L/yq9n4rhSq9njHL+FvcYOiOvZEPWwXVCfwgo9/tOSFGp88Db
 GuI5usUM3Eh1R9RQ/AdZ8ssCEwjLXrp0YzsYLhBA6rPWwxjcPmeUubKnKDf7YyLhWtS+6HilwIH
 ptrgYF4ULjjhUHpJs52fUqawGxmJUecGq4pW5xGsPgiJem68
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
 Documentation/devicetree/bindings/pci/qcom,pcie-common.yaml | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/pci/qcom,pcie-common.yaml b/Documentation/devicetree/bindings/pci/qcom,pcie-common.yaml
index 0a39bbfcb28b..704c0f58eea5 100644
--- a/Documentation/devicetree/bindings/pci/qcom,pcie-common.yaml
+++ b/Documentation/devicetree/bindings/pci/qcom,pcie-common.yaml
@@ -21,11 +21,11 @@ properties:
 
   interrupts:
     minItems: 1
-    maxItems: 8
+    maxItems: 9
 
   interrupt-names:
     minItems: 1
-    maxItems: 8
+    maxItems: 9
 
   iommu-map:
     minItems: 1

-- 
2.25.1

