From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Thu, 27 Feb 2025 19:10:57 +0530
Subject: [PATCH 15/23] arm64: dts: qcom: msm8998: Add missing MSI and
 'global' IRQs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250227-pcie-global-irq-v1-15-2b70a7819d1e@linaro.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1465;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=tuxfQ/qLaeL1Z/VoxRrRg/3WlsnVe+b+pyGU9A4SJKY=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnwGtgfSwFhnoCqGtydye9BXdEW7ClIAs2n9osj
 +JDhLFLnfmJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZ8BrYAAKCRBVnxHm/pHO
 9fyNB/9mxvdmorLy+FACaOQiboLBiU2AvuB5ihy0znAUcVOCdfzbUeRRji7b4AWl9uesF0sAvxQ
 9xd9hN5AmW97pYc4m+EE+rh1M7r2dvsfOfTZsaCUGi5s21EwHL0KMmPjPOYT71TTXqhxSVNpRs9
 jUndY41lVHZfNv5RlhxEwsPyYSn+NyIyj4gYPbyO+gt4xJWaSvn9/DNmA5BLUpQX5Z0K5nBiYd6
 2leklQP+68EeV/f181zZiRYnfz0T1SXSG1W+X3j20r6Cc3Jza4S6m7mYTgoxlIUBdEfoql7GhPr
 Ba2limYezoRxUsgSCxlwgj+j2yHH3OVLKVhNAV0U0nl6TeBf
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

MSM8998 has 8 MSI SPI interrupts and one 'global' interrupt.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 arch/arm64/boot/dts/qcom/msm8998.dtsi | 20 ++++++++++++++++++--
 1 file changed, 18 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/msm8998.dtsi b/arch/arm64/boot/dts/qcom/msm8998.dtsi
index c2caad85c668..65bb03406a59 100644
--- a/arch/arm64/boot/dts/qcom/msm8998.dtsi
+++ b/arch/arm64/boot/dts/qcom/msm8998.dtsi
@@ -935,8 +935,24 @@ pcie0: pcie@1c00000 {
 				 <0x02000000 0x0 0x1b300000 0x1b300000 0x0 0xd00000>;
 
 			#interrupt-cells = <1>;
-			interrupts = <GIC_SPI 405 IRQ_TYPE_LEVEL_HIGH>;
-			interrupt-names = "msi";
+			interrupts = <GIC_SPI 405 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 406 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 407 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 408 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 409 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 410 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 411 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 412 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 278 IRQ_TYPE_LEVEL_HIGH>;
+			interrupt-names = "msi0",
+					  "msi1",
+					  "msi2",
+					  "msi3",
+					  "msi4",
+					  "msi5",
+					  "msi6",
+					  "msi7",
+					  "global";
 			interrupt-map-mask = <0 0 0 0x7>;
 			interrupt-map = <0 0 0 1 &intc 0 0 135 IRQ_TYPE_LEVEL_HIGH>,
 					<0 0 0 2 &intc 0 0 136 IRQ_TYPE_LEVEL_HIGH>,

-- 
2.25.1

