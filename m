From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Thu, 27 Feb 2025 19:11:01 +0530
Subject: [PATCH 19/23] arm64: dts: qcom: ipq6018: Add missing MSI and
 'global' IRQs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250227-pcie-global-irq-v1-19-2b70a7819d1e@linaro.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1416;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=RowCCsa7UmB5mPOEsSXdyNQWv59aOMUHKBxIbtgXr/U=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnwGtho03MSKCOi1OZSeZzOcyA6tRYzXGdRBo8t
 BThJZlrT2GJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZ8BrYQAKCRBVnxHm/pHO
 9W5JB/4qgyIIi+x3cyWS0XyxVtV8zWuzaPhuu7NYJTxAIbABr3v/9Xe38jPeT+mALauJ53rFTzW
 xSG5FDITYkf4psiMCnwioco+rldyJr6PcvF57/wCeaCE1+wQsbOjq2DYyGbnDPvKuWYAQJXg5Do
 +RoyM9UkLuGiAqnvuTG0+PWHfRYhfV/VgKU8MDfjSNiJa9iajzA7AXZ2Owc08uY5+46fP7Ocp9x
 2O0Ez1hYxSOpPrN6RpKNHeCBWzIsSUV2AHWjc92G6rCY+nMTNZag5baLV4JdcipMj+C4g4JaAvf
 7MGPe5Ims/2MmLK+RG8YBSSSXiISILLX9uUWLL57Q2hksEEJ
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

IPQ6018 has 8 MSI SPI interrupts and one 'global' interrupt.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 arch/arm64/boot/dts/qcom/ipq6018.dtsi | 20 ++++++++++++++++++--
 1 file changed, 18 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/ipq6018.dtsi b/arch/arm64/boot/dts/qcom/ipq6018.dtsi
index dbf6716bcb59..d1b1dc048262 100644
--- a/arch/arm64/boot/dts/qcom/ipq6018.dtsi
+++ b/arch/arm64/boot/dts/qcom/ipq6018.dtsi
@@ -888,8 +888,24 @@ pcie0: pcie@20000000 {
 			ranges = <0x81000000 0x0 0x00000000 0x0 0x20200000 0x0 0x10000>,
 				 <0x82000000 0x0 0x20220000 0x0 0x20220000 0x0 0xfde0000>;
 
-			interrupts = <GIC_SPI 52 IRQ_TYPE_LEVEL_HIGH>;
-			interrupt-names = "msi";
+			interrupts = <GIC_SPI 52 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 55 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 56 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 57 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 59 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 63 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 68 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 72 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 51 IRQ_TYPE_LEVEL_HIGH>;
+			interrupt-names = "msi0",
+					  "msi1",
+					  "msi2",
+					  "msi3",
+					  "msi4",
+					  "msi5",
+					  "msi6",
+					  "msi7",
+					  "global";
 
 			#interrupt-cells = <1>;
 			interrupt-map-mask = <0 0 0 0x7>;

-- 
2.25.1

