From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Wed, 17 Jul 2024 22:33:12 +0530
Subject: [PATCH v2 07/13] ARM: dts: qcom: sdx55: Add 'linux,pci-domain' to
 PCIe EP controller node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240717-pci-qcom-hotplug-v2-7-71d304b817f8@linaro.org>
References: <20240717-pci-qcom-hotplug-v2-0-71d304b817f8@linaro.org>
In-Reply-To: <20240717-pci-qcom-hotplug-v2-0-71d304b817f8@linaro.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=986;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=+Lb2vcF7RPFdOyct+N0+V3AMTmLDYS+SRQY7Fw3HIuE=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBml/lO5lBDAIgog7/DCQS8jI0fHtovZQlYwqd5B
 WyOgUwNCS+JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZpf5TgAKCRBVnxHm/pHO
 9drCCACjiN6bdLASGYBDuhq74Vb33fBJv4q/jyLQI7eY1YopkvdioFtdULJXkMXon5Zuk0IaPku
 kTBOiAX6Fn8kn/Xlj5sScthaADAb3cWT0JlJyEMgcpT52ASfJAroHamUTcqSigY5q4qh+j9yIC9
 7BkhTsQjOnd7TLxKYFC4A59LbfM8Rd7loU2mV0Et8D8agByUjG9JrtsxXjxvYhaI+JbV4OBvXrJ
 qjDsuvabamJDN3ijnuhEeC6DsCu1povehl1QaFsAzAtPJdQ62Kjn6HUiYSBQB3y1PNw7YmwLIkR
 B3++UcnUscWAB4kR2N2KnO4ZQ5P1Es90cNCEk8EtGiAME9pD
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

