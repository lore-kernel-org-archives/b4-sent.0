From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Wed, 31 Jul 2024 16:20:11 +0530
Subject: [PATCH v3 08/13] ARM: dts: qcom: sdx65: Add 'linux,pci-domain' to
 PCIe EP controller node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240731-pci-qcom-hotplug-v3-8-a1426afdee3b@linaro.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=961;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=4ksb8gQi6XxtqZHvRIfOuO8m7D/GXep6HzglfrtwSCA=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmqhbj6AuR19gVgM6SXGBTiRSNQwqVP0FlXbfOh
 dH/EI7xJimJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZqoW4wAKCRBVnxHm/pHO
 9VW8B/9MUtYiNGVpuIfJAqYCVOzwF+YamFjxtReGIZzZB/h1zfMILBFtGv/iiAQf0SsENP/AmQK
 7lQtHhyCTi+jSGUT8HlUMLN8k7Oreavy/lwt6D1/qZ0BVzRpdI0G+vYAuCn/X3R6K7N5NPkequ9
 cbIT30CZawkFf+Y8LqSQNhvS441+zuQQlEzXg3MLqf9kuBtyQhmWKHHTmEyhH683xm0I5nTTXMS
 cGfl+gtCrRqjAfmyIE+lw3eOgGUY5kYoVm50maTvndVm4gC8ofnbApX9Prw15Euh4b4dxT8gdEE
 /JcYse9jgoAz2xBLPT8t6UEtXmmpB8OuWg7t2PfesumKpaMr
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

'linux,pci-domain' property provides the PCI domain number for the PCI
endpoint controllers in a SoC. If this property is not present, then an
unstable (across boots) unique number will be assigned.

Use this property to specify the domain number based on the actual hardware
instance of the PCI endpoint controllers in SDX65 SoC.

Reviewed-by: Konrad Dybcio <konrad.dybcio@linaro.org>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 arch/arm/boot/dts/qcom/qcom-sdx65.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-sdx65.dtsi b/arch/arm/boot/dts/qcom/qcom-sdx65.dtsi
index a949454212e9..fcfec4228670 100644
--- a/arch/arm/boot/dts/qcom/qcom-sdx65.dtsi
+++ b/arch/arm/boot/dts/qcom/qcom-sdx65.dtsi
@@ -345,6 +345,7 @@ pcie_ep: pcie-ep@1c00000 {
 
 			max-link-speed = <3>;
 			num-lanes = <2>;
+			linux,pci-domain = <0>;
 
 			status = "disabled";
 		};

-- 
2.25.1

