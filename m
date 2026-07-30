From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Thu, 30 Jul 2026 13:55:57 +0200
Subject: [PATCH 16/22] arm64: dts: qcom: monaco-monza-som: Fix the PCIe
 iommu-map entries
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260730-iommu-map-fix-v1-16-83405d37ba41@oss.qualcomm.com>
References: <20260730-iommu-map-fix-v1-0-83405d37ba41@oss.qualcomm.com>
In-Reply-To: <20260730-iommu-map-fix-v1-0-83405d37ba41@oss.qualcomm.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Manivannan Sadhasivam <mani@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Bjorn Andersson <bjorn.andersson@oss.qualcomm.com>, 
 Krzysztof Kozlowski <krzk@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1742;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=4Y7qxUSzkNOLqJefhft4hjG0ihS1PeYGE/kul77ZLc8=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqazvaGxkhrqu3i8XxNGgCFTYBu3GorvpGcvJmq
 gioFKqPS0eJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCams72gAKCRBVnxHm/pHO
 9WyzCACpLfE1ZURwJzT4z+FC4eSpEDSO9S8mt9eSC702kk/CNfak7uc43XTJtpHgPqSxf3Q/KwV
 +X0mSPydiLS/a+pDe5qw1N+a1BV8KuvWUyQXyBd4CjIxxvbdAT3hXeHQUIUPSjutiftRpAr8AYW
 AXRQjU4pkcRrOSOWio6oAzpbi2QQ7XbMB7edHl/uktN7/gUlQ6QYc+G6D/f4l2NQxA3xb5okPfP
 Ieoyk/OsXXORglP8zqQ0LZFJEmSNStjf8wpExvWOJG10FZU6COTjgA6BDLBnBxBz2ZcG6qmJ5ye
 WHxemB6HQFhwSGKQRIySqbyN1CDFfrKm/4MJTqGpQPD4ky9p
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The IOMMU provider pcie_smmu uses '#iommu-cells = <2>', but the PCIe
iommu-map entries specify only one cell for the SID, omitting the SID
mask. This went unnoticed until the OF core started warning with commit
ccb2fd725d41 ("of: Respect #{iommu,msi}-cells in maps"):

  iommu-map has 1-cell entries targeting 2-cell #iommu-cells, treating as 1-cell output

So fix the entries to match the provider's '#iommu-cells' property.

Fixes: 5238f4e7169f ("arm64: dts: qcom: Add Monaco Monza SoM")
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 arch/arm64/boot/dts/qcom/monaco-monza-som.dtsi | 16 ++++++++--------
 1 file changed, 8 insertions(+), 8 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/monaco-monza-som.dtsi b/arch/arm64/boot/dts/qcom/monaco-monza-som.dtsi
index 9b5ed55939b8..36af1ad2105d 100644
--- a/arch/arm64/boot/dts/qcom/monaco-monza-som.dtsi
+++ b/arch/arm64/boot/dts/qcom/monaco-monza-som.dtsi
@@ -196,14 +196,14 @@ &iris {
 
 /* PCIe0 Gen4 x2 */
 &pcie0 {
-	iommu-map = <0x0 &pcie_smmu 0x0000 0x1>,
-		    <0x100 &pcie_smmu 0x0001 0x1>,
-		    <0x200 &pcie_smmu 0x0007 0x1>,
-		    <0x208 &pcie_smmu 0x0002 0x1>,
-		    <0x210 &pcie_smmu 0x0003 0x1>,
-		    <0x218 &pcie_smmu 0x0004 0x1>,
-		    <0x300 &pcie_smmu 0x0005 0x1>,
-		    <0x400 &pcie_smmu 0x0006 0x1>;
+	iommu-map = <0x0 &pcie_smmu 0x0000 0x0 0x1>,
+		    <0x100 &pcie_smmu 0x0001 0x0 0x1>,
+		    <0x200 &pcie_smmu 0x0007 0x0 0x1>,
+		    <0x208 &pcie_smmu 0x0002 0x0 0x1>,
+		    <0x210 &pcie_smmu 0x0003 0x0 0x1>,
+		    <0x218 &pcie_smmu 0x0004 0x0 0x1>,
+		    <0x300 &pcie_smmu 0x0005 0x0 0x1>,
+		    <0x400 &pcie_smmu 0x0006 0x0 0x1>;
 
 	status = "okay";
 };

-- 
2.43.0

