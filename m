From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Mon, 15 Jul 2024 23:03:51 +0530
Subject: [PATCH 09/14] ARM: dts: qcom: sdx65: Add 'linux,pci-domain' to
 PCIe EP controller node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240715-pci-qcom-hotplug-v1-9-5f3765cc873a@linaro.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=906;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=csDoZP2OLES7tPZyHjq00PkbEc3m+4OOmtcZKbO5fqQ=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmlV15ILF+SBcNiGMrBAY25nZOAZu7j9Kv2LBvw
 ZMFFcRVTL6JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZpVdeQAKCRBVnxHm/pHO
 9Sv8B/4yrtadvSEQqOUXqW6F0dvNf6+Zln9x+SGI/lNhwGwZqkjc55QHUCEyTPwRmWWUB89jP78
 q0a/m4kXRCkrAYxsPcLRwJmyUY2zqh2/k5Cih1iFqcNbqALrMSRxQ9rXxNbQ7uKkbOZsRCS6lsB
 YkfrQbRNZouw7BU7+FRVa1y1NQdCMVbKIdoJVD9XeD2xVFg0v9RrpIssIZ6WTmoAgyOFq6EEr3D
 rzbwgTcqBSwcFaW5M+oKVS8BLg73fwMqX6+ZofQH5DNK2mhRVUHfwiGyjV2M56z/3hlzvbTqe3a
 9wZ5g8IytbMFVCnWUEEFo+0xViAHeDhrpmr8nN6BOeWNSu7f
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

'linux,pci-domain' property provides the PCI domain number for the PCI
endpoint controllers in a SoC. If this property is not present, then an
unstable (across boots) unique number will be assigned.

Use this property to specify the domain number based on the actual hardware
instance of the PCI endpoint controllers in SDX65 SoC.

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

