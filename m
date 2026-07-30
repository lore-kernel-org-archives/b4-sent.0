From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Thu, 30 Jul 2026 13:55:59 +0200
Subject: [PATCH 18/22] arm64: dts: qcom: lemans-evk-ifp-mezzanine: Fix the
 PCIe iommu-map entries
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260730-iommu-map-fix-v1-18-83405d37ba41@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1808;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=6/fejk3AUzlk1STcYkZQ4EwteAhTMlV5L1LTi7u62zo=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqazvbxsNv6wZ428gGrnwtbVCX7aa9MTOu8MEka
 l9wqZTxVymJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCams72wAKCRBVnxHm/pHO
 9RZECACOa9itTFox0FsxKXOkZ92rTwi8LjeqqnwdnFCVbypRUyjI/bCZcP1yEULa/rFL0Pkf/75
 SA2GOWHY2cZGgWBFGwPJcQJAv3fZJ6Y713yX+vllbu1j/fpl+qp9LJwlqbjBSi23sBl/I5mPqQ8
 OZofoL+vn2h6MKSBSljTgEhysPWNUSAicR2VAj8RMlkUfWWVV+QmKYEyT4a8370Lsx2zB83qEJw
 y6sRfh0GAuLqOrBxLEjnrbD+27bAptsMojH+okaUi/WVWXu5v4UvUFq8ftuZSygZZGSEeN3plRE
 K8SFe8mdbWG1CflNI9zbOETM2IRrB4jAAmDRDyKbwHARxhQZ
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

Fixes: b64abb26a291 ("arm64: dts: qcom: lemans-evk: Add IFP Mezzanine")
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 arch/arm64/boot/dts/qcom/lemans-evk-ifp-mezzanine.dtso | 18 +++++++++---------
 1 file changed, 9 insertions(+), 9 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/lemans-evk-ifp-mezzanine.dtso b/arch/arm64/boot/dts/qcom/lemans-evk-ifp-mezzanine.dtso
index 44bd9b1a1765..22c975628ed7 100644
--- a/arch/arm64/boot/dts/qcom/lemans-evk-ifp-mezzanine.dtso
+++ b/arch/arm64/boot/dts/qcom/lemans-evk-ifp-mezzanine.dtso
@@ -204,15 +204,15 @@ &mdss1_dp1_phy {
 };
 
 &pcie0 {
-	iommu-map = <0x0 &pcie_smmu 0x0 0x1>,
-		    <0x100 &pcie_smmu 0x1 0x1>,
-		    <0x208 &pcie_smmu 0x2 0x1>,
-		    <0x210 &pcie_smmu 0x3 0x1>,
-		    <0x218 &pcie_smmu 0x4 0x1>,
-		    <0x300 &pcie_smmu 0x5 0x1>,
-		    <0x400 &pcie_smmu 0x6 0x1>,
-		    <0x500 &pcie_smmu 0x7 0x1>,
-		    <0x501 &pcie_smmu 0x8 0x1>;
+	iommu-map = <0x0 &pcie_smmu 0x0 0x0 0x1>,
+		    <0x100 &pcie_smmu 0x1 0x0 0x1>,
+		    <0x208 &pcie_smmu 0x2 0x0 0x1>,
+		    <0x210 &pcie_smmu 0x3 0x0 0x1>,
+		    <0x218 &pcie_smmu 0x4 0x0 0x1>,
+		    <0x300 &pcie_smmu 0x5 0x0 0x1>,
+		    <0x400 &pcie_smmu 0x6 0x0 0x1>,
+		    <0x500 &pcie_smmu 0x7 0x0 0x1>,
+		    <0x501 &pcie_smmu 0x8 0x0 0x1>;
 };
 
 &pcieport0 {

-- 
2.43.0

