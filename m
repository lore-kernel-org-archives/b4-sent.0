From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Mon, 15 Jul 2024 23:03:45 +0530
Subject: [PATCH 03/14] dt-bindings: PCI: pci-ep: Update Maintainers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240715-pci-qcom-hotplug-v1-3-5f3765cc873a@linaro.org>
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
 bh=hjExGhGjQYtIRypMJXzdJurZJRAD466HOf0lMqV3fm8=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmlV14KYPtRgTg3g5EoPeN8522vVrQhN1qaY7/c
 kIik6AD35uJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZpVdeAAKCRBVnxHm/pHO
 9eSuB/9x6dRA5UTZGB8p96YqCmsRpqrOTNu+uvJvQVEwqOSETlWw4EnwEpB2LfPMRFLfmvUWBYt
 wdyMR3qpMNxZgBlhnpz2eD7u0f6c4Mo1xkYKUBMzR4i7+rsGeV2ytOX28WYDiPdXtdF7nt156KJ
 ExX80HAXszwxIUdGz3aovIr9cZV+xsmPvsLT9rBaXy6ax/2elU8LtYdJTB/fj430YEji5KeBvzc
 TeBFn9SyiQ4VPaUr88aQht8PvKDy3hupt52CtnHcIWVWi1r+V4M+ZQPqb5WnpRQ5pM33nt32Qfn
 GJjVn5Kr8wTiI5v920O+QkgudZkDT2he8eJ3xokaafDC7KpE
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Kishon's TI email ID is not active anymore, so use his korg ID. Also, since
I've been maintaining the PCI endpoint framework, I'm willing to maintain
the DT binding as well. So add myself as the Co-maintainer.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 Documentation/devicetree/bindings/pci/pci-ep.yaml | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/pci/pci-ep.yaml b/Documentation/devicetree/bindings/pci/pci-ep.yaml
index d1eef4825207..0b5456ee21eb 100644
--- a/Documentation/devicetree/bindings/pci/pci-ep.yaml
+++ b/Documentation/devicetree/bindings/pci/pci-ep.yaml
@@ -10,7 +10,8 @@ description: |
   Common properties for PCI Endpoint Controller Nodes.
 
 maintainers:
-  - Kishon Vijay Abraham I <kishon@ti.com>
+  - Kishon Vijay Abraham I <kishon@kernel.org>
+  - Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
 
 properties:
   $nodename:

-- 
2.25.1

