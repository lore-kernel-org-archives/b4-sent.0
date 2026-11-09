From: Demeter Barna <me@fromdisposition.org>
Date: Mon, 09 Nov 2026 13:55:30 +0000
Subject: [PATCH v2 2/2] arm64: dts: qcom: sm8350: Add the inline crypto
 engine
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-b4-sm8350-ice-v2-2-fd5e84985e90@fromdisposition.org>
References: <20261109-b4-sm8350-ice-v2-0-fd5e84985e90@fromdisposition.org>
In-Reply-To: <20261109-b4-sm8350-ice-v2-0-fd5e84985e90@fromdisposition.org>
To: Abel Vesa <abelvesa@kernel.org>, 
 Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-crypto@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Demeter Barna <me@fromdisposition.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794232535; l=1535;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=D6BUds9SxEA685Rzubo4gGj7fm7khF99ZYP/XeTNyDQ=;
 b=0W8t+eSCuo4ppfZiiZgklYWeFq6LPpLSbbeACf7KjIDwos87XAaUwYG8+6kDZngXeKl1IkG9S
 1NGoCazcVvGAN2EKY+rOTn92d126IuXWK56/oxVkFT2H+E+nJhiOs47
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the UFS inline crypto engine at 0x1d88000 and hand it to the
UFS host controller with qcom,ice. The region covers the engine and its
hardware key manager (0x8000 + 0x9000), as in Qualcomm's SM8350 device
tree; it is clocked by the UFS ICE core and AHB clocks and powered by
the UFS PHY GDSC, as on SM8450. Without it the UFS driver logs
"Disabling inline encryption support" and fscrypt has no hardware path.

Signed-off-by: Demeter Barna <me@fromdisposition.org>
---
 arch/arm64/boot/dts/qcom/sm8350.dtsi | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sm8350.dtsi b/arch/arm64/boot/dts/qcom/sm8350.dtsi
index 55b32050c..2b258c4b4 100644
--- a/arch/arm64/boot/dts/qcom/sm8350.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8350.dtsi
@@ -1782,6 +1782,8 @@ &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ALWAYS>,
 				<0 0>,
 				<0 0>,
 				<0 0>;
+			qcom,ice = <&ice>;
+
 			status = "disabled";
 		};
 
@@ -1807,6 +1809,17 @@ ufs_mem_phy: phy@1d87000 {
 			status = "disabled";
 		};
 
+		ice: crypto@1d88000 {
+			compatible = "qcom,sm8350-inline-crypto-engine",
+				     "qcom,inline-crypto-engine";
+			reg = <0 0x01d88000 0 0x11000>;
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
2.53.0

