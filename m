From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Wed, 31 Jul 2024 16:20:16 +0530
Subject: [PATCH v3 13/13] arm64: dts: qcom: sm8450: Add 'global' interrupt
 to the PCIe RC node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240731-pci-qcom-hotplug-v3-13-a1426afdee3b@linaro.org>
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
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=openpgp-sha256; l=2085;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=VT44obotCPUBbxvMUSiK7oaxSibx2Iio+dz6SHI7KhE=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmqhblNzaaeYw8B23DDeqkEmh17nbj4nLf1+plB
 bbD5W/MaxCJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZqoW5QAKCRBVnxHm/pHO
 9edLB/wJfinRqT1ZaIEqmwdeCglsOvXrZYFwynjzpwkrwDnq/VJXpKxc1EYNUYndw2kJsnQnkjz
 MJy1k9utlvQI1HfHcGl3AjAL+iS0uVExZabdGUpQaKEFJCf1hr/UiiHh486UCOfE0wCJhni1TvP
 EuXNGESFIBsIcAf4XzYP3OfIIafC6g5fLA5r/6A322EVxMdCy+/kLv2gczMfVf/5ZyZQOGBiW9F
 nir8hA84oZdJsCf8xy50ulrMxrgwXDT3phbIQ2cbduZ1s3ltdLNosD2JIUuU4H/xwRcLh5ZxG3/
 WrTAx9Z1hH/oQQ2lIK73Bi73atywSQtqCQvEs0hvAS+0TUtk
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Qcom PCIe RC controllers are capable of generating 'global' SPI interrupt
to the host CPUs. This interrupt can be used by the device driver to
identify events such as PCIe link specific events, safety events, etc...

Hence, add it to the PCIe RC node along with the existing MSI interrupts.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 arch/arm64/boot/dts/qcom/sm8450.dtsi | 12 ++++++++----
 1 file changed, 8 insertions(+), 4 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sm8450.dtsi b/arch/arm64/boot/dts/qcom/sm8450.dtsi
index 9bafb3b350ff..564b071eb77c 100644
--- a/arch/arm64/boot/dts/qcom/sm8450.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8450.dtsi
@@ -1787,7 +1787,8 @@ pcie0: pcie@1c00000 {
 				     <GIC_SPI 145 IRQ_TYPE_LEVEL_HIGH>,
 				     <GIC_SPI 146 IRQ_TYPE_LEVEL_HIGH>,
 				     <GIC_SPI 147 IRQ_TYPE_LEVEL_HIGH>,
-				     <GIC_SPI 148 IRQ_TYPE_LEVEL_HIGH>;
+				     <GIC_SPI 148 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 140 IRQ_TYPE_LEVEL_HIGH>;
 			interrupt-names = "msi0",
 					  "msi1",
 					  "msi2",
@@ -1795,7 +1796,8 @@ pcie0: pcie@1c00000 {
 					  "msi4",
 					  "msi5",
 					  "msi6",
-					  "msi7";
+					  "msi7",
+					  "global";
 			#interrupt-cells = <1>;
 			interrupt-map-mask = <0 0 0 0x7>;
 			interrupt-map = <0 0 0 1 &intc 0 0 0 149 IRQ_TYPE_LEVEL_HIGH>, /* int_a */
@@ -1949,7 +1951,8 @@ pcie1: pcie@1c08000 {
 				     <GIC_SPI 313 IRQ_TYPE_LEVEL_HIGH>,
 				     <GIC_SPI 314 IRQ_TYPE_LEVEL_HIGH>,
 				     <GIC_SPI 374 IRQ_TYPE_LEVEL_HIGH>,
-				     <GIC_SPI 375 IRQ_TYPE_LEVEL_HIGH>;
+				     <GIC_SPI 375 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 306 IRQ_TYPE_LEVEL_HIGH>;
 			interrupt-names = "msi0",
 					  "msi1",
 					  "msi2",
@@ -1957,7 +1960,8 @@ pcie1: pcie@1c08000 {
 					  "msi4",
 					  "msi5",
 					  "msi6",
-					  "msi7";
+					  "msi7",
+					  "global";
 			#interrupt-cells = <1>;
 			interrupt-map-mask = <0 0 0 0x7>;
 			interrupt-map = <0 0 0 1 &intc 0 0 0 434 IRQ_TYPE_LEVEL_HIGH>, /* int_a */

-- 
2.25.1

