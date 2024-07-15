From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Mon, 15 Jul 2024 23:03:52 +0530
Subject: [PATCH 10/14] arm64: dts: qcom: sa8775p: Add 'linux,pci-domain' to
 PCIe EP controller nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240715-pci-qcom-hotplug-v1-10-5f3765cc873a@linaro.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1234;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=yEgvSXmb27DZa3gudFLW4zQMizODQlbDCoGJB1twpkY=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmlV16mrEo9NAV0hiS5F8uIuEUCRNSQ3KaNpcjJ
 xlqNZmego+JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZpVdegAKCRBVnxHm/pHO
 9a0UB/9rL1u5DYb4E5GiDOZUSXZC+9jk0Sxesl5D3WH2U2toRZncQIw6kUqORTEnnyoTGA/gYsr
 DpZJ3HVigPzTH4uJIwNDKBX+9/9CaaPfkfXbxMBhix1cI0dbX1NJ4QXSAkQhAsbk+qt+pZNBSMa
 7oTrmIgYW0Ptw/LQ0pdXv5dYsg2JX20BMyYhl500pLJj8CPzihAb+7qgFgR5IgjuYdSW4H3OYkV
 yUt4wSE9GhhGCT3D9Clor1IvW0sPTeaVv8udq5s0QeX6zsREGU57pF1ozrWsXqVBgD9MpNsY0WZ
 OF2AcDFy4RofVwZ6G2h3zxK4W90JPVcMpqBOEC6vqbB5H2k4
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

'linux,pci-domain' property provides the PCI domain number for the PCI
endpoint controllers in a SoC. If this property is not present, then an
unstable (across boots) unique number will be assigned.

Use this property to specify the domain number based on the actual hardware
instance of the PCI endpoint controllers in SA8775P SoC.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 arch/arm64/boot/dts/qcom/sa8775p.dtsi | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sa8775p.dtsi b/arch/arm64/boot/dts/qcom/sa8775p.dtsi
index 23f1b2e5e624..198b39abde97 100644
--- a/arch/arm64/boot/dts/qcom/sa8775p.dtsi
+++ b/arch/arm64/boot/dts/qcom/sa8775p.dtsi
@@ -4618,6 +4618,7 @@ pcie0_ep: pcie-ep@1c00000 {
 		phy-names = "pciephy";
 		max-link-speed = <3>; /* FIXME: Limiting the Gen speed due to stability issues */
 		num-lanes = <2>;
+		linux,pci-domain = <0>;
 
 		status = "disabled";
 	};
@@ -4775,6 +4776,7 @@ pcie1_ep: pcie-ep@1c10000 {
 		phy-names = "pciephy";
 		max-link-speed = <3>; /* FIXME: Limiting the Gen speed due to stability issues */
 		num-lanes = <4>;
+		linux,pci-domain = <1>;
 
 		status = "disabled";
 	};

-- 
2.25.1

