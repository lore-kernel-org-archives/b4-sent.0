From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Mon, 15 Jul 2024 23:03:47 +0530
Subject: [PATCH 05/14] dt-bindings: PCI: qcom-ep: Document
 "linux,pci-domain" property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240715-pci-qcom-hotplug-v1-5-5f3765cc873a@linaro.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=988;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=4/Y3NDpzD8Z8CE/W/YJnbzDjm+Dvqo0pEX0LWeYt20k=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmlV14OxNu2Wouvfh0sC2iqACXk4KaF46EPflGP
 K5SvUq1GKOJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZpVdeAAKCRBVnxHm/pHO
 9ZRqB/9aiqXGr2qOBpgTi78f/kJz/f1LUHV2LmgvzXET9Xqx2UNmEVcAilBQQBSZK52d6X4PBxv
 aWJ1oX8Zue/z2xEAHNwZIjg/wR/hFMku4gJNvheAE3UrigmeKAgd2aiIHEI7FVZ8SbJwCe/5QHT
 ADzYloawz3PUkbN6zWNY0S1mag5KAW1nWGsjbYfKCx5sNqfTMMFOT1ZdJBpdDXgmLnNuAbEGCnl
 l0yTmZ0jDL1tYtYO+5AgKlVF7I/3q5GlfL6Ps3EqFVbCT/epaLH0FK2OO1VseRjmrpocaZf89YA
 YWyMEcgnFosgHbVde+NZnLhEzA36wQHjoVhcHEgvw1CHn9Ci
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

'linux,pci-domain' property provides the PCI domain number for the PCI
endpoint controllers in a SoC. If this property is not present, then an
unstable (across boots) unique number will be assigned.

Use this property to specify the domain number based on the actual hardware
instance of the PCI endpoint controllers in a SoC.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 Documentation/devicetree/bindings/pci/qcom,pcie-ep.yaml | 1 +
 1 file changed, 1 insertion(+)

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

