From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Thu, 27 Feb 2025 19:10:50 +0530
Subject: [PATCH 08/23] arm64: dts: qcom: sa8775p: Add 'global' PCIe
 interrupt
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250227-pcie-global-irq-v1-8-2b70a7819d1e@linaro.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1937;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=Os2oTXz3lM7O8tEiJo6RhT8WTo7QJJeaiTGq7TdERl4=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnwGtf3mFRsxhFB5i2bT0PnqnD5DqV6CyNoa0dY
 gRb4So9q/eJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZ8BrXwAKCRBVnxHm/pHO
 9Y5yB/9SjMKRBDc281gpmD7dg7RV/rSvsHE3S6duGtZdwzaujXh5DfIOrVaI6/NMjvmTmw3uo+G
 7TpU5hJs4SeIq3jJ4o2iupox5rEq+xKpE37hFfJFfjEozYNifxFrfgGhW2Uhx3iGWi8Sh2QwogD
 YZq+MFEmcJR5J2YAO/PsAWq9/W94JHFaM2k6GvI5RJKhwC6swAX7TamagXST6j4jC5RJfLrd6qO
 IXZzv8fj92VsWpUkqITfxonMximOezz/bz3mXF6cRNsSrh18vJoUcfo9VCbCEASmJMcYCNxUbDR
 OP7zUa+Lsw2pnBS+fD1hI+5iXLGtioFEWTDUad5224hOengC
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

'global' interrupt is used to receive PCIe controller and link specific
events.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 arch/arm64/boot/dts/qcom/sa8775p.dtsi | 28 ++++++++++++++++++++++------
 1 file changed, 22 insertions(+), 6 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sa8775p.dtsi b/arch/arm64/boot/dts/qcom/sa8775p.dtsi
index 3394ae2d1300..05a3eb06d182 100644
--- a/arch/arm64/boot/dts/qcom/sa8775p.dtsi
+++ b/arch/arm64/boot/dts/qcom/sa8775p.dtsi
@@ -6421,9 +6421,17 @@ pcie0: pcie@1c00000 {
 			     <GIC_SPI 313 IRQ_TYPE_LEVEL_HIGH>,
 			     <GIC_SPI 314 IRQ_TYPE_LEVEL_HIGH>,
 			     <GIC_SPI 374 IRQ_TYPE_LEVEL_HIGH>,
-			     <GIC_SPI 375 IRQ_TYPE_LEVEL_HIGH>;
-		interrupt-names = "msi0", "msi1", "msi2", "msi3",
-				  "msi4", "msi5", "msi6", "msi7";
+			     <GIC_SPI 375 IRQ_TYPE_LEVEL_HIGH>,
+			     <GIC_SPI 306 IRQ_TYPE_LEVEL_HIGH>;
+		interrupt-names = "msi0",
+				  "msi1",
+				  "msi2",
+				  "msi3",
+				  "msi4",
+				  "msi5",
+				  "msi6",
+				  "msi7",
+				  "global";
 		#interrupt-cells = <1>;
 		interrupt-map-mask = <0 0 0 0x7>;
 		interrupt-map = <0 0 0 1 &intc GIC_SPI 434 IRQ_TYPE_LEVEL_HIGH>,
@@ -6579,9 +6587,17 @@ pcie1: pcie@1c10000 {
 			     <GIC_SPI 143 IRQ_TYPE_LEVEL_HIGH>,
 			     <GIC_SPI 144 IRQ_TYPE_LEVEL_HIGH>,
 			     <GIC_SPI 145 IRQ_TYPE_LEVEL_HIGH>,
-			     <GIC_SPI 146 IRQ_TYPE_LEVEL_HIGH>;
-		interrupt-names = "msi0", "msi1", "msi2", "msi3",
-				  "msi4", "msi5", "msi6", "msi7";
+			     <GIC_SPI 146 IRQ_TYPE_LEVEL_HIGH>,
+			     <GIC_SPI 518 IRQ_TYPE_LEVEL_HIGH>;
+		interrupt-names = "msi0",
+				  "msi1",
+				  "msi2",
+				  "msi3",
+				  "msi4",
+				  "msi5",
+				  "msi6",
+				  "msi7",
+				  "global";
 		#interrupt-cells = <1>;
 		interrupt-map-mask = <0 0 0 0x7>;
 		interrupt-map = <0 0 0 1 &intc GIC_SPI 148 IRQ_TYPE_LEVEL_HIGH>,

-- 
2.25.1

