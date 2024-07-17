From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Wed, 17 Jul 2024 22:33:14 +0530
Subject: [PATCH v2 09/13] arm64: dts: qcom: sa8775p: Add 'linux,pci-domain'
 to PCIe EP controller nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240717-pci-qcom-hotplug-v2-9-71d304b817f8@linaro.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1289;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=YKSy5vPklQvLJA99UbdPy4mFyoiPQChYvArhByAGkpA=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBml/lO0Dmif7USBFz5hYoCiza5W/fd8O+FngHr/
 24+q3osoLiJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZpf5TgAKCRBVnxHm/pHO
 9awtB/4kSxxPulCuNa6RgrOTzuAeI/hkw6WQQ97HhrEZToQEkUZvp8WMGZ2aQIHLxS2xYUQxE5R
 EdJWwjl83+26qlrhNwwR60/fltegr6Wyb4g3dhiRBrYGav0cCt7hSwbEatBc5axOyxNNwf80eg3
 y4xM9rVaSJICwe8FTw+d4oYXWwcS6HdAR9W8PJpcVI/iFGOr7Dtia2yH1XKywUNyVAdS/JynHxV
 nQfS2SIHXiCs3b2v6xYBx1NBgGVcKZoh7CM1u0bWJkaY4s+QlWL1QMJEK1JkLAzstaWYk/W2lth
 pQLivgbf7hZuXjpGbCnm8+FbHBu0Gd3uSXy1T4cSCTa33tsV
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

'linux,pci-domain' property provides the PCI domain number for the PCI
endpoint controllers in a SoC. If this property is not present, then an
unstable (across boots) unique number will be assigned.

Use this property to specify the domain number based on the actual hardware
instance of the PCI endpoint controllers in SA8775P SoC.

Reviewed-by: Konrad Dybcio <konrad.dybcio@linaro.org>
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

