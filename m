From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Thu, 27 Feb 2025 19:10:56 +0530
Subject: [PATCH 14/23] dt-bindings: PCI: qcom: Allow MSM8998 to use 8 MSI
 and one 'global' interrupt
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250227-pcie-global-irq-v1-14-2b70a7819d1e@linaro.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=729;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=A3ZjegB9ymOJbKrwFnz4F34ZFvQLAhzn+iJNxtH6+DY=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnwGtgBWAF0xKBJhApgk9zItN9GnKDjS4xgEbv+
 ZNkuR4YM72JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZ8BrYAAKCRBVnxHm/pHO
 9d6eB/9CdWyEAxsIM8eMjfdKBkUBzEeNntDzkk6MeHURlbBAtSfdTb4yi6SUTs+40eH9jMPVmHX
 IwUA270qzXi6tJ6uC9IpRrJ5sPboH5NZioSQLvF/sfdtbKkbw1f0s9Vp/FefF4bqAJld4eANZ0j
 RyWrZORIm4hjpKQBIuZG5CZwx6loxfmNRXFWgZ117TERZ/cj4jdKAbql0OGgvjmbVbIi8AtHM0R
 BUSrs2qmOW5SYPPpTDNxjZ/AwFnmg0UpbgbXft00upo4WUol7Mm9Cz8uzL8wF+AuecNIem35xT1
 ngF7sm8zsY93s1T8Nl7ZX9bXYEDf98oo4Gcgw/o9ByajQEx/
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

MSM8998 has 8 MSI SPI and one 'global' interrupt.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 Documentation/devicetree/bindings/pci/qcom,pcie.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/pci/qcom,pcie.yaml b/Documentation/devicetree/bindings/pci/qcom,pcie.yaml
index 3776dfcd2dca..44b1a6e74c9b 100644
--- a/Documentation/devicetree/bindings/pci/qcom,pcie.yaml
+++ b/Documentation/devicetree/bindings/pci/qcom,pcie.yaml
@@ -587,6 +587,7 @@ allOf:
           contains:
             enum:
               - qcom,pcie-msm8996
+              - qcom,pcie-msm8998
               - qcom,pcie-sdm845
     then:
       oneOf:

-- 
2.25.1

