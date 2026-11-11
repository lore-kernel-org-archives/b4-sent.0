From: Andrew Gigena <mail@andrewgigena.dev>
Date: Wed, 11 Nov 2026 04:17:51 +0000
Subject: [PATCH v3 3/3] arm64: dts: qcom: sm8150: use standalone ICE for
 UFS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-sm8150-ice-rfc-v3-3-f9d5a806fc95@andrewgigena.dev>
References: <20261111-sm8150-ice-rfc-v3-0-f9d5a806fc95@andrewgigena.dev>
In-Reply-To: <20261111-sm8150-ice-rfc-v3-0-f9d5a806fc95@andrewgigena.dev>
To: Abel Vesa <abelvesa@kernel.org>, 
 Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Manivannan Sadhasivam <mani@kernel.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>, Bart Van Assche <bvanassche@acm.org>, 
 Bean Huo <beanhuo@micron.com>, Stanley Jhu <stanleyjhu@google.com>, 
 Bjorn Andersson <andersson@kernel.org>, Andy Gross <agross@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-crypto@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-scsi@vger.kernel.org, Andrew Gigena <mail@andrewgigena.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794370671; l=2347;
 i=mail@andrewgigena.dev; s=20261104; h=from:subject:message-id;
 bh=5ojOLo8hWLDK0hV2yglUJhrUv/sb3CLr9di70RGzFCA=;
 b=fYh/wnOjTAhn9em3DNVhlUH56Virjz5sZPm4HyxwD2C0/aw3IssZBPyFgRnsaQITow4T7Ovq8
 3+M+kZvHIPjCyalquq6BFaIzxHn8MJ6Hzp0XNvakSNUYBWfy2DrPmIG
X-Developer-Key: i=mail@andrewgigena.dev; a=ed25519;
 pk=OMhlYIBaOEC8g4mJ4JCKy7kbg+lrwRxuujieZF8Ne6U=
X-Endpoint-Received: by B4 Relay for mail@andrewgigena.dev/20261104 with auth_id=1402
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Align SM8150 with the standalone ICE representation used on newer
platforms instead of embedding ICE registers in the UFS node.

Signed-off-by: Andrew Gigena <mail@andrewgigena.dev>
---
 arch/arm64/boot/dts/qcom/sm8150.dtsi | 25 ++++++++++++++++---------
 1 file changed, 16 insertions(+), 9 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sm8150.dtsi b/arch/arm64/boot/dts/qcom/sm8150.dtsi
index 293fcbacff34..b3d6f3d92395 100644
--- a/arch/arm64/boot/dts/qcom/sm8150.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8150.dtsi
@@ -2071,9 +2071,7 @@ pcie1_phy: phy@1c0e000 {
 		ufs_mem_hc: ufshc@1d84000 {
 			compatible = "qcom,sm8150-ufshc", "qcom,ufshc",
 				     "jedec,ufs-2.0";
-			reg = <0 0x01d84000 0 0x2500>,
-			      <0 0x01d90000 0 0x8000>;
-			reg-names = "std", "ice";
+			reg = <0 0x01d84000 0 0x2500>;
 			interrupts = <GIC_SPI 265 IRQ_TYPE_LEVEL_HIGH>;
 			phys = <&ufs_mem_phy>;
 			phy-names = "ufsphy";
@@ -2092,8 +2090,7 @@ ufs_mem_hc: ufshc@1d84000 {
 				"ref_clk",
 				"tx_lane0_sync_clk",
 				"rx_lane0_sync_clk",
-				"rx_lane1_sync_clk",
-				"ice_core_clk";
+				"rx_lane1_sync_clk";
 			clocks =
 				<&gcc GCC_UFS_PHY_AXI_CLK>,
 				<&gcc GCC_AGGRE_UFS_PHY_AXI_CLK>,
@@ -2102,8 +2099,7 @@ ufs_mem_hc: ufshc@1d84000 {
 				<&rpmhcc RPMH_CXO_CLK>,
 				<&gcc GCC_UFS_PHY_TX_SYMBOL_0_CLK>,
 				<&gcc GCC_UFS_PHY_RX_SYMBOL_0_CLK>,
-				<&gcc GCC_UFS_PHY_RX_SYMBOL_1_CLK>,
-				<&gcc GCC_UFS_PHY_ICE_CORE_CLK>;
+				<&gcc GCC_UFS_PHY_RX_SYMBOL_1_CLK>;
 			freq-table-hz =
 				<37500000 300000000>,
 				<0 0>,
@@ -2112,8 +2108,8 @@ ufs_mem_hc: ufshc@1d84000 {
 				<0 0>,
 				<0 0>,
 				<0 0>,
-				<0 0>,
-				<0 300000000>;
+				<0 0>;
+			qcom,ice = <&ice>;
 
 			status = "disabled";
 		};
@@ -2139,6 +2135,17 @@ ufs_mem_phy: phy@1d87000 {
 			status = "disabled";
 		};
 
+		ice: crypto@1d90000 {
+			compatible = "qcom,sm8150-inline-crypto-engine",
+				     "qcom,inline-crypto-engine";
+			reg = <0 0x01d90000 0 0x8000>;
+			clocks = <&gcc GCC_UFS_PHY_ICE_CORE_CLK>,
+				 <&gcc GCC_UFS_PHY_AHB_CLK>;
+			clock-names = "core",
+				      "iface";
+			power-domains = <&gcc UFS_PHY_GDSC>;
+		};
+
 		cryptobam: dma-controller@1dc4000 {
 			compatible = "qcom,bam-v1.7.4", "qcom,bam-v1.7.0";
 			reg = <0 0x01dc4000 0 0x24000>;

-- 
2.56.0

