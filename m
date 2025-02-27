From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Thu, 27 Feb 2025 19:10:55 +0530
Subject: [PATCH 13/23] arm64: dts: qcom: msm8996: Add missing MSI SPI
 interrupts
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250227-pcie-global-irq-v1-13-2b70a7819d1e@linaro.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3064;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=FpIpzsPiznSX9qJ/hFF/18H43JcNjeBgD8xcW752Tcg=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnwGtgUobujnlZrKuDYllEeCj1oe2ExBz3nb8Tg
 ryssQ1b4uyJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZ8BrYAAKCRBVnxHm/pHO
 9SZxCACDsKolqSytylF4Xn5Tvhbvf+R9EbGmyUjho7XRci/roNmKKJpcTImP0HIiG2n3uRJp3mt
 14VymAVYruvDycVI575VrhTsI3VfUdMqSP52czjfbfaYOgAtvqoBNUVwUGWRs3Nxbh/6L2tTMAH
 U65sle2x9xBdCyoWw6RzKV3H0abum/FbYNbY+PfR+BgCL3FFfq9FOj/Hp6baXmBcUa4r835eLdb
 FT1b7r8za6WGFVnQgHFOYCO9FU7BoDL5ApcS1VOE69XvY082kUZ8OV6Zt4JCucOFe2B4Kbf1M/e
 yRTI7168LnmY4dyNifnSlURh6FhTQ6zzcAqmcvfnSLCEsPll
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

MSM8996 has 8 MSI SPI interrupts per controller instance.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 arch/arm64/boot/dts/qcom/msm8996.dtsi | 54 +++++++++++++++++++++++++++++++----
 1 file changed, 48 insertions(+), 6 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/msm8996.dtsi b/arch/arm64/boot/dts/qcom/msm8996.dtsi
index 4719e1fc70d2..38df095e9336 100644
--- a/arch/arm64/boot/dts/qcom/msm8996.dtsi
+++ b/arch/arm64/boot/dts/qcom/msm8996.dtsi
@@ -1905,8 +1905,22 @@ pcie0: pcie@600000 {
 
 				device_type = "pci";
 
-				interrupts = <GIC_SPI 405 IRQ_TYPE_LEVEL_HIGH>;
-				interrupt-names = "msi";
+				interrupts = <GIC_SPI 405 IRQ_TYPE_LEVEL_HIGH>,
+					     <GIC_SPI 406 IRQ_TYPE_LEVEL_HIGH>,
+					     <GIC_SPI 407 IRQ_TYPE_LEVEL_HIGH>,
+					     <GIC_SPI 408 IRQ_TYPE_LEVEL_HIGH>,
+					     <GIC_SPI 409 IRQ_TYPE_LEVEL_HIGH>,
+					     <GIC_SPI 410 IRQ_TYPE_LEVEL_HIGH>,
+					     <GIC_SPI 411 IRQ_TYPE_LEVEL_HIGH>,
+					     <GIC_SPI 412 IRQ_TYPE_LEVEL_HIGH>;
+				interrupt-names = "msi0",
+						  "msi1",
+						  "msi2",
+						  "msi3",
+						  "msi4",
+						  "msi5",
+						  "msi6",
+						  "msi7";
 				#interrupt-cells = <1>;
 				interrupt-map-mask = <0 0 0 0x7>;
 				interrupt-map = <0 0 0 1 &intc 0 244 IRQ_TYPE_LEVEL_HIGH>, /* int_a */
@@ -1968,8 +1982,22 @@ pcie1: pcie@608000 {
 
 				device_type = "pci";
 
-				interrupts = <GIC_SPI 413 IRQ_TYPE_LEVEL_HIGH>;
-				interrupt-names = "msi";
+				interrupts = <GIC_SPI 413 IRQ_TYPE_LEVEL_HIGH>,
+					     <GIC_SPI 414 IRQ_TYPE_LEVEL_HIGH>,
+					     <GIC_SPI 415 IRQ_TYPE_LEVEL_HIGH>,
+					     <GIC_SPI 416 IRQ_TYPE_LEVEL_HIGH>,
+					     <GIC_SPI 417 IRQ_TYPE_LEVEL_HIGH>,
+					     <GIC_SPI 418 IRQ_TYPE_LEVEL_HIGH>,
+					     <GIC_SPI 419 IRQ_TYPE_LEVEL_HIGH>,
+					     <GIC_SPI 420 IRQ_TYPE_LEVEL_HIGH>;
+				interrupt-names = "msi0",
+						  "msi1",
+						  "msi2",
+						  "msi3",
+						  "msi4",
+						  "msi5",
+						  "msi6",
+						  "msi7";
 				#interrupt-cells = <1>;
 				interrupt-map-mask = <0 0 0 0x7>;
 				interrupt-map = <0 0 0 1 &intc 0 272 IRQ_TYPE_LEVEL_HIGH>, /* int_a */
@@ -2029,8 +2057,22 @@ pcie2: pcie@610000 {
 
 				device_type = "pci";
 
-				interrupts = <GIC_SPI 421 IRQ_TYPE_LEVEL_HIGH>;
-				interrupt-names = "msi";
+				interrupts = <GIC_SPI 421 IRQ_TYPE_LEVEL_HIGH>,
+					     <GIC_SPI 422 IRQ_TYPE_LEVEL_HIGH>,
+					     <GIC_SPI 423 IRQ_TYPE_LEVEL_HIGH>,
+					     <GIC_SPI 424 IRQ_TYPE_LEVEL_HIGH>,
+					     <GIC_SPI 425 IRQ_TYPE_LEVEL_HIGH>,
+					     <GIC_SPI 426 IRQ_TYPE_LEVEL_HIGH>,
+					     <GIC_SPI 427 IRQ_TYPE_LEVEL_HIGH>,
+					     <GIC_SPI 428 IRQ_TYPE_LEVEL_HIGH>;
+				interrupt-names = "msi0",
+						  "msi1",
+						  "msi2",
+						  "msi3",
+						  "msi4",
+						  "msi5",
+						  "msi6",
+						  "msi7";
 				#interrupt-cells = <1>;
 				interrupt-map-mask = <0 0 0 0x7>;
 				interrupt-map = <0 0 0 1 &intc 0 142 IRQ_TYPE_LEVEL_HIGH>, /* int_a */

-- 
2.25.1

