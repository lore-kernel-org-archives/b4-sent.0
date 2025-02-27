From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Thu, 27 Feb 2025 19:11:05 +0530
Subject: [PATCH 23/23] arm64: dts: qcom: x1e80100: Add missing 'global'
 PCIe interrupt
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250227-pcie-global-irq-v1-23-2b70a7819d1e@linaro.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2331;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=D+b9sJdvKhFSUCftBjhpfmmmILsMj4McEC3OdoOVoxc=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnwGtiqVZNe1xC6tTLX7QsrP7cApoKwQC3cixH9
 89ms7ZhdnKJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZ8BrYgAKCRBVnxHm/pHO
 9eyVB/4pXp/Y8V0U4S2uZSPb8oYmVLDF+X1mBwCW9GwMn7YMBk8trEwDd+2zGUyf9g3akusCuEj
 TmdT0RTW59JmJKVhQSjIJFSldBp8DY7EfcADKkaOq+eQfgrMhtTLmIkQQSY78mG2/fxB1fEVtOd
 IptrKO0e/vfyHv6Y6JyIBl+fRi6v9yjAp6bRpwtPJOPRwFu1Z7sAkvaqu98rka/0YyMltPjMPRA
 8ursC+cogA+rQFN76isBjAALM/l1AOllPsjPISkzacUvkJjrDWMsjIXYVJNOGKGt3ZE0uGfM8JG
 MQj2Is64LObltY86F+obue5kMZfTRyKtM8CJQDVRmM9QUwAG
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

'global' interrupt is used to receive PCIe controller and link specific
events.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 arch/arm64/boot/dts/qcom/x1e80100.dtsi | 18 ++++++++++++------
 1 file changed, 12 insertions(+), 6 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/x1e80100.dtsi b/arch/arm64/boot/dts/qcom/x1e80100.dtsi
index 4936fa5b98ff..cea199966d82 100644
--- a/arch/arm64/boot/dts/qcom/x1e80100.dtsi
+++ b/arch/arm64/boot/dts/qcom/x1e80100.dtsi
@@ -3358,7 +3358,8 @@ pcie6a: pci@1bf8000 {
 				     <GIC_SPI 839 IRQ_TYPE_LEVEL_HIGH>,
 				     <GIC_SPI 840 IRQ_TYPE_LEVEL_HIGH>,
 				     <GIC_SPI 841 IRQ_TYPE_LEVEL_HIGH>,
-				     <GIC_SPI 842 IRQ_TYPE_LEVEL_HIGH>;
+				     <GIC_SPI 842 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 672 IRQ_TYPE_LEVEL_HIGH>;
 			interrupt-names = "msi0",
 					  "msi1",
 					  "msi2",
@@ -3366,7 +3367,8 @@ pcie6a: pci@1bf8000 {
 					  "msi4",
 					  "msi5",
 					  "msi6",
-					  "msi7";
+					  "msi7",
+					  "global";
 
 			#interrupt-cells = <1>;
 			interrupt-map-mask = <0 0 0 0x7>;
@@ -3485,7 +3487,8 @@ pcie5: pci@1c00000 {
 				     <GIC_SPI 86 IRQ_TYPE_LEVEL_HIGH>,
 				     <GIC_SPI 82 IRQ_TYPE_LEVEL_HIGH>,
 				     <GIC_SPI 77 IRQ_TYPE_LEVEL_HIGH>,
-				     <GIC_SPI 78 IRQ_TYPE_LEVEL_HIGH>;
+				     <GIC_SPI 78 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 157 IRQ_TYPE_LEVEL_HIGH>;
 			interrupt-names = "msi0",
 					  "msi1",
 					  "msi2",
@@ -3493,7 +3496,8 @@ pcie5: pci@1c00000 {
 					  "msi4",
 					  "msi5",
 					  "msi6",
-					  "msi7";
+					  "msi7",
+					  "global";
 
 			#interrupt-cells = <1>;
 			interrupt-map-mask = <0 0 0 0x7>;
@@ -3609,7 +3613,8 @@ pcie4: pci@1c08000 {
 				     <GIC_SPI 145 IRQ_TYPE_LEVEL_HIGH>,
 				     <GIC_SPI 146 IRQ_TYPE_LEVEL_HIGH>,
 				     <GIC_SPI 147 IRQ_TYPE_LEVEL_HIGH>,
-				     <GIC_SPI 148 IRQ_TYPE_LEVEL_HIGH>;
+				     <GIC_SPI 148 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 156 IRQ_TYPE_LEVEL_HIGH>;
 			interrupt-names = "msi0",
 					  "msi1",
 					  "msi2",
@@ -3617,7 +3622,8 @@ pcie4: pci@1c08000 {
 					  "msi4",
 					  "msi5",
 					  "msi6",
-					  "msi7";
+					  "msi7",
+					  "global";
 
 			#interrupt-cells = <1>;
 			interrupt-map-mask = <0 0 0 0x7>;

-- 
2.25.1

