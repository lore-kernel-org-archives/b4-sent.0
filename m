From: Esteban Urrutia <esteuwu@proton.me>
Date: Mon, 22 Jun 2026 21:44:17 -0400
Subject: [PATCH 1/3] arm64: dts: qcom: sm8450: Add IPA support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260622-sm8450-ipa-v1-1-532f0299f96e@proton.me>
References: <20260622-sm8450-ipa-v1-0-532f0299f96e@proton.me>
In-Reply-To: <20260622-sm8450-ipa-v1-0-532f0299f96e@proton.me>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Alex Elder <elder@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782179059; l=2576;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=REPoX2GD1ofl2IYq/QGL3Tdyi2FLXycfusk5NUq3JGA=;
 b=QoxedY3RmE6Ji5eZvOO4tDSdZlVmZEjjpbnrD0VwbIKAeDooafDiOUzrCg+47OP1nv71YOg6y
 +IktDTKMBbSCEsWTcPMjIXPKhN5U8MV8oGgdCHb1O13JsFKZ/97TEmV
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for IPA in DT while expanding the IMEM region just enough to
accommodate the modem tables used by IPA.
As reference, SM8450 uses IPA v5.1.

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
 arch/arm64/boot/dts/qcom/sm8450.dtsi | 55 ++++++++++++++++++++++++++++++++----
 1 file changed, 50 insertions(+), 5 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sm8450.dtsi b/arch/arm64/boot/dts/qcom/sm8450.dtsi
index 56cb6e959e4e..c904720008fa 100644
--- a/arch/arm64/boot/dts/qcom/sm8450.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8450.dtsi
@@ -2639,6 +2639,47 @@ adreno_smmu: iommu@3da0000 {
 			dma-coherent;
 		};
 
+		ipa: ipa@3f40000 {
+			compatible = "qcom,sm8450-ipa";
+
+			iommus = <&apps_smmu 0x5c0 0x0>,
+				 <&apps_smmu 0x5c2 0x0>;
+			reg = <0 0x3f40000 0 0x10000>,
+			      <0 0x3f50000 0 0x5000>,
+			      <0 0x3e04000 0 0xfc000>;
+			reg-names = "ipa-reg",
+				    "ipa-shared",
+				    "gsi";
+
+			interrupts-extended = <&intc GIC_SPI 654 IRQ_TYPE_EDGE_RISING>,
+					      <&intc GIC_SPI 432 IRQ_TYPE_LEVEL_HIGH>,
+					      <&ipa_smp2p_in 0 IRQ_TYPE_EDGE_RISING>,
+					      <&ipa_smp2p_in 1 IRQ_TYPE_EDGE_RISING>;
+			interrupt-names = "ipa",
+					  "gsi",
+					  "ipa-clock-query",
+					  "ipa-setup-ready";
+
+			clocks = <&rpmhcc RPMH_IPA_CLK>;
+			clock-names = "core";
+
+			interconnects = <&aggre2_noc MASTER_IPA 0 &mc_virt SLAVE_EBI1 0>,
+					<&gem_noc MASTER_APPSS_PROC 0 &config_noc SLAVE_IPA_CFG 0>;
+			interconnect-names = "memory",
+					     "config";
+
+			qcom,qmp = <&aoss_qmp>;
+
+			qcom,smem-states = <&ipa_smp2p_out 0>,
+					   <&ipa_smp2p_out 1>;
+			qcom,smem-state-names = "ipa-clock-enabled-valid",
+						"ipa-clock-enabled";
+
+			sram = <&ipa_modem_tables>;
+
+			status = "disabled";
+		};
+
 		usb_1_hsphy: phy@88e3000 {
 			compatible = "qcom,sm8450-usb-hs-phy",
 				     "qcom,usb-snps-hs-7nm-phy";
@@ -4970,17 +5011,21 @@ cti@13900000 {
 			clock-names = "apb_pclk";
 		};
 
-		sram@146aa000 {
+		sram@146a8000 {
 			compatible = "qcom,sm8450-imem", "syscon", "simple-mfd";
-			reg = <0 0x146aa000 0 0x1000>;
-			ranges = <0 0 0x146aa000 0x1000>;
+			reg = <0 0x146a8000 0 0x3000>;
+			ranges = <0 0 0x146a8000 0x3000>;
 
 			#address-cells = <1>;
 			#size-cells = <1>;
 
-			pil-reloc@94c {
+			ipa_modem_tables: modem-tables@0 {
+				reg = <0 0x2000>;
+			};
+
+			pil-reloc@294c {
 				compatible = "qcom,pil-reloc-info";
-				reg = <0x94c 0xc8>;
+				reg = <0x294c 0xc8>;
 			};
 		};
 

-- 
2.54.0

