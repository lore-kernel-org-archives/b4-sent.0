From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Thu, 27 Feb 2025 19:10:58 +0530
Subject: [PATCH 16/23] dt-bindings: PCI: qcom: Allow IPQ8074 to use 8 MSI
 and one 'global' interrupt
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250227-pcie-global-irq-v1-16-2b70a7819d1e@linaro.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1104;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=OfBhoTpPsH3HUYKaANPdFRRwP7sOZT/NsW34mrUnbUc=;
 b=owGbwMvMwMUYOl/w2b+J574ynlZLYkg/kJ14W6h68R0jFaO11nve3PK56a64sTHGROHHr/KGs
 JeKT9hLOhmNWRgYuRhkxRRZ0pc6azV6nL6xJEJ9OswgViaQKQxcnAIwkcX72P+H/XF1LSn3vFm0
 o+2/R7fz/+POq961mYZwP3CU8mX5tU5U837mfVWFUteonHlsBya4XeCcLfLrrPpvNhvftkXM6tH
 TLySzCr2PyFPK3uDs4f5sbniEuVTnm/YHbUd+hc6LusesJWDX+l4rtaAl5vqbhX2cbQotRy/m7H
 USs9sSfPblfFV2xq8Le/8EVqyJFFlYeP75nw8KX9c+ZFqSEJBk9uyGmaVdi7jPjsSLurmc944H3
 +F9PMVPebGU7lHz8xOba+OMLv5QS1q9LUGOd1o8M3tYSVi40Gq9hhidVdUPv8x+WWch1CRrZNj4
 tGaKcq8vz2mmr5kzw2/kdzX82LnrWdAvtmor/hRWAa9TAA==
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

IPA8074 has 8 MSI SPI and one 'global' interrupt.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 Documentation/devicetree/bindings/pci/qcom,pcie.yaml | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/pci/qcom,pcie.yaml b/Documentation/devicetree/bindings/pci/qcom,pcie.yaml
index 44b1a6e74c9b..433a4fc4d883 100644
--- a/Documentation/devicetree/bindings/pci/qcom,pcie.yaml
+++ b/Documentation/devicetree/bindings/pci/qcom,pcie.yaml
@@ -586,6 +586,8 @@ allOf:
         compatible:
           contains:
             enum:
+              - qcom,pcie-ipq8074
+              - qcom,pcie-ipq8074-gen3
               - qcom,pcie-msm8996
               - qcom,pcie-msm8998
               - qcom,pcie-sdm845
@@ -625,8 +627,6 @@ allOf:
               - qcom,pcie-ipq6018
               - qcom,pcie-ipq8064
               - qcom,pcie-ipq8064-v2
-              - qcom,pcie-ipq8074
-              - qcom,pcie-ipq8074-gen3
               - qcom,pcie-qcs404
     then:
       properties:

-- 
2.25.1

