From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Mon, 15 Jul 2024 23:03:50 +0530
Subject: [PATCH 08/14] ARM: dts: qcom: sdx55: Add 'linux,pci-domain' to
 PCIe EP controller node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240715-pci-qcom-hotplug-v1-8-5f3765cc873a@linaro.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=931;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=kwx7QGYogFgH9r43zYyha4gga2vYwsd4o33qhsGds+k=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmlV15CSE+uo3sq2/IU8wwhr3HPQhoooREAXiTf
 2moyV4AIy6JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZpVdeQAKCRBVnxHm/pHO
 9euhB/9SeAVltwvnAJZ+YRfNlsDMbN7Uj/QBB1xmDKKYJ1sL5L26gF9CoVkGnA6K8E0SXy9Gc+A
 NTb8XstE7UvbNDOMutorOlKNUIXv+K1/lxQkbT1xZIxKhqO7R5TGH9+IkEmHMDkr7P7hHoIuXdm
 JPWPepg3a0a78frM+9WUf6zIvSzTh/VL3fTomMstjc/k4BH+mLwhJ/9i6dJLyXCf72NPjX5r+iP
 UuS+5RRveledStbcaGGWSg6crWKVO4ewA8oWBNiR/tlFNBv2BY7Hlo7hx89SafZT70tCDpRczmB
 ze8I8CbxVJS84qqvpCnThxQj8Pd09GoBt8yxELZyQfO0qUzQ
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

'linux,pci-domain' property provides the PCI domain number for the PCI
endpoint controllers in a SoC. If this property is not present, then an
unstable (across boots) unique number will be assigned.

Use this property to specify the domain number based on the actual hardware
instance of the PCI endpoint controllers in SDX55 SoC.

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

