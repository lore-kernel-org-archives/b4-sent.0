From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Wed, 31 Jul 2024 16:20:10 +0530
Subject: [PATCH v3 07/13] ARM: dts: qcom: sdx55: Add 'linux,pci-domain' to
 PCIe EP controller node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240731-pci-qcom-hotplug-v3-7-a1426afdee3b@linaro.org>
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
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=openpgp-sha256; l=986;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=+Lb2vcF7RPFdOyct+N0+V3AMTmLDYS+SRQY7Fw3HIuE=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmqhbjkTiApJTNTSUBKI9q0eAZ0la4yNkAKIvRj
 ljKbglV8RWJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZqoW4wAKCRBVnxHm/pHO
 9QfVCACjGPb3cSXofPXXA+xQOK5VyTm0JsWjYGlVhpBRR3i9m8pYPFc1wJeOTKGJCfgCkj1oRc1
 Xadvp5Uc3OD6RDssrwDZ8B1rbpqb0Zqr4ok5k/1/BEtqKVl9UgtRlQ7yqlMV33Z6E/EhAbE34NJ
 EPL8Y/A6JerH7OLUlAPOrqlk34iLQkyFGH2g3iE+0qp70ZH693eUFTLdR4DM+LYADeyxJSjfolu
 VqcFT6b8IoSRFoemRQMBZfkoC1UZCo6NkHpBI71o10uV3ibDH5skWSykTBrru9jvbQ0DOf1P1mc
 d0f6RohT1YZdLtjKWAmZEWPzEQNGQ08Mg/EZQaGugxxFdbwP
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

'linux,pci-domain' property provides the PCI domain number for the PCI
endpoint controllers in a SoC. If this property is not present, then an
unstable (across boots) unique number will be assigned.

Use this property to specify the domain number based on the actual hardware
instance of the PCI endpoint controllers in SDX55 SoC.

Reviewed-by: Konrad Dybcio <konrad.dybcio@linaro.org>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 arch/arm/boot/dts/qcom/qcom-sdx55.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-sdx55.dtsi b/arch/arm/boot/dts/qcom/qcom-sdx55.dtsi
index 68fa5859d263..d0f6120b665d 100644
--- a/arch/arm/boot/dts/qcom/qcom-sdx55.dtsi
+++ b/arch/arm/boot/dts/qcom/qcom-sdx55.dtsi
@@ -437,6 +437,7 @@ pcie_ep: pcie-ep@1c00000 {
 			phy-names = "pciephy";
 			max-link-speed = <3>;
 			num-lanes = <2>;
+			linux,pci-domain = <0>;
 
 			status = "disabled";
 		};

-- 
2.25.1

