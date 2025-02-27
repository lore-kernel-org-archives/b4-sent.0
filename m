From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Thu, 27 Feb 2025 19:11:00 +0530
Subject: [PATCH 18/23] dt-bindings: PCI: qcom: Allow IPQ6018 to use 8 MSI
 and one 'global' interrupt
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250227-pcie-global-irq-v1-18-2b70a7819d1e@linaro.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1064;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=3oilXH/eh6Uh87q83kHcwoMClQ62eXD3O03uzw0uOB4=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnwGthW5ENmwQn9oN1voJHayqM6bExe8JP4bYOJ
 /Jbguw5L4OJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZ8BrYQAKCRBVnxHm/pHO
 9ae9B/0Z4L4/4T9YG3AJGc4k+NVtnkrqDcVGaMxKtoxgz+oXM+SwXbiO/dEPkyO7SWAhavAhmhH
 hF3aUFR6rVaYHXL5kiqVc3ctqiuUyQEEtj8dXh3YWgsffSARTDuSDZ4Qr8HjfWT610g11+aPvMw
 hsuabzpYOlyuK28m6kaUlKJitlcQVdWtTvvPhFe+ZVgnsQfcQ5muAO8oUw+G3173/fardQoPQrM
 jrSCdgRTPbVewyYuRAHuBPPjm43608eA0GzCvGlY20VkEDowcgyadfgQi+dMEFCVj+CfDqiGI4H
 rwm6kEEmOmFj9UaiUBZAdoXwwZiJ1bRsBDU1L9HTIBiajZDR
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

IPQ6018 has 8 MSI SPI and one 'global' interrupt.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 Documentation/devicetree/bindings/pci/qcom,pcie.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/pci/qcom,pcie.yaml b/Documentation/devicetree/bindings/pci/qcom,pcie.yaml
index 433a4fc4d883..8969254c3c7d 100644
--- a/Documentation/devicetree/bindings/pci/qcom,pcie.yaml
+++ b/Documentation/devicetree/bindings/pci/qcom,pcie.yaml
@@ -586,6 +586,7 @@ allOf:
         compatible:
           contains:
             enum:
+              - qcom,pcie-ipq6018
               - qcom,pcie-ipq8074
               - qcom,pcie-ipq8074-gen3
               - qcom,pcie-msm8996
@@ -624,7 +625,6 @@ allOf:
               - qcom,pcie-apq8064
               - qcom,pcie-apq8084
               - qcom,pcie-ipq4019
-              - qcom,pcie-ipq6018
               - qcom,pcie-ipq8064
               - qcom,pcie-ipq8064-v2
               - qcom,pcie-qcs404

-- 
2.25.1

