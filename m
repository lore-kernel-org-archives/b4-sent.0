From: Demeter Barna <me@fromdisposition.org>
Date: Thu, 05 Nov 2026 13:30:04 +0000
Subject: [PATCH 5/5] arm64: dts: qcom: sm8350: Add the GPU speed bins
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-b4-sm8350-gpu-v1-5-a7175cdd6512@fromdisposition.org>
References: <20261105-b4-sm8350-gpu-v1-0-a7175cdd6512@fromdisposition.org>
In-Reply-To: <20261105-b4-sm8350-gpu-v1-0-a7175cdd6512@fromdisposition.org>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Srinivas Kandagatla <srini@kernel.org>, 
 Rob Clark <robin.clark@oss.qualcomm.com>, Sean Paul <sean@poorly.run>, 
 Akhil P Oommen <akhilpo@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, Demeter Barna <me@fromdisposition.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793885419; l=4165;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=Go4TFFoOKKLlrDXSMdwVz23UmppnG+cEaIIyTAUOMts=;
 b=gvMWWyHdYqIcfg4Bi9gJX8QdzZV6k9PsAiPTXeSbClueRJU9sTngpnC2INWztvFHcEOht2Urt
 woh7pBiCoX1DPEBa0KUdekh9/Nd9aBtGj640nasUrxAvuZKLV6YwK+I
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Today every SM8350 runs its GPU up to 840 MHz, including the parts that
are validated only up to 738 MHz, and no part gets the 900 MHz level the
best bin supports.

Describe the QFPROM with the GPU speed bin cell, as sm8250.dtsi does,
let the GPU read it and mark each OPP with the bins that support it:

  900 MHz            bin 1 (new OPP, same bandwidth as 840 MHz)
  840, 778 MHz       bins 0 and 1
  738 MHz and below  all bins

Drop the note about downstream binning above the OPP table, which this
replaces.

Reading the whole nvmem file needs the SM8350 keepout regions in the
qfprom driver; without them it resets the SoC.

Signed-off-by: Demeter Barna <me@fromdisposition.org>
---
 arch/arm64/boot/dts/qcom/sm8350.dtsi | 33 ++++++++++++++++++++++++++++++++-
 1 file changed, 32 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sm8350.dtsi b/arch/arm64/boot/dts/qcom/sm8350.dtsi
index 903b2968c..d488c9d64 100644
--- a/arch/arm64/boot/dts/qcom/sm8350.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8350.dtsi
@@ -710,6 +710,18 @@ ipcc: mailbox@408000 {
 			#mbox-cells = <2>;
 		};
 
+		qfprom: efuse@784000 {
+			compatible = "qcom,sm8350-qfprom", "qcom,qfprom";
+			reg = <0 0x00784000 0 0x3000>;
+			#address-cells = <1>;
+			#size-cells = <1>;
+
+			gpu_speed_bin: gpu-speed-bin@17b {
+				reg = <0x17b 0x1>;
+				bits = <5 3>;
+			};
+		};
+
 		gpi_dma2: dma-controller@800000 {
 			compatible = "qcom,sm8350-gpi-dma", "qcom,sm6350-gpi-dma";
 			reg = <0 0x00800000 0 0x60000>;
@@ -2057,6 +2069,9 @@ gpu: gpu@3d00000 {
 			operating-points-v2 = <&gpu_opp_table>;
 
 			qcom,gmu = <&gmu>;
+
+			nvmem-cells = <&gpu_speed_bin>;
+			nvmem-cell-names = "speed_bin";
 			#cooling-cells = <2>;
 
 			status = "disabled";
@@ -2065,68 +2080,84 @@ gpu_zap_shader: zap-shader {
 				memory-region = <&pil_gpu_mem>;
 			};
 
-			/* note: downstream checks gpu binning for 670 Mhz */
 			gpu_opp_table: opp-table {
 				compatible = "operating-points-v2";
 
+				opp-900000000 {
+					opp-hz = /bits/ 64 <900000000>;
+					opp-level = <RPMH_REGULATOR_LEVEL_TURBO_L2>;
+					opp-peak-kBps = <12484375>;
+					opp-supported-hw = <0x2>;
+				};
+
 				opp-840000000 {
 					opp-hz = /bits/ 64 <840000000>;
 					opp-level = <RPMH_REGULATOR_LEVEL_TURBO_L1>;
 					opp-peak-kBps = <12484375>;
+					opp-supported-hw = <0x3>;
 				};
 
 				opp-778000000 {
 					opp-hz = /bits/ 64 <778000000>;
 					opp-level = <RPMH_REGULATOR_LEVEL_TURBO>;
 					opp-peak-kBps = <12484375>;
+					opp-supported-hw = <0x3>;
 				};
 
 				opp-738000000 {
 					opp-hz = /bits/ 64 <738000000>;
 					opp-level = <RPMH_REGULATOR_LEVEL_NOM_L1>;
 					opp-peak-kBps = <12484375>;
+					opp-supported-hw = <0x7>;
 				};
 
 				opp-676000000 {
 					opp-hz = /bits/ 64 <676000000>;
 					opp-level = <RPMH_REGULATOR_LEVEL_NOM>;
 					opp-peak-kBps = <10687500>;
+					opp-supported-hw = <0x7>;
 				};
 
 				opp-608000000 {
 					opp-hz = /bits/ 64 <608000000>;
 					opp-level = <RPMH_REGULATOR_LEVEL_SVS_L2>;
 					opp-peak-kBps = <6074218>;
+					opp-supported-hw = <0x7>;
 				};
 
 				opp-540000000 {
 					opp-hz = /bits/ 64 <540000000>;
 					opp-level = <RPMH_REGULATOR_LEVEL_SVS_L1>;
 					opp-peak-kBps = <6074218>;
+					opp-supported-hw = <0x7>;
 				};
 
 				opp-491000000 {
 					opp-hz = /bits/ 64 <491000000>;
 					opp-level = <RPMH_REGULATOR_LEVEL_SVS_L0>;
 					opp-peak-kBps = <6074218>;
+					opp-supported-hw = <0x7>;
 				};
 
 				opp-443000000 {
 					opp-hz = /bits/ 64 <443000000>;
 					opp-level = <RPMH_REGULATOR_LEVEL_SVS>;
 					opp-peak-kBps = <6074218>;
+					opp-supported-hw = <0x7>;
 				};
 
 				opp-379000000 {
 					opp-hz = /bits/ 64 <379000000>;
 					opp-level = <80 /* RPMH_REGULATOR_LEVEL_LOW_SVS_L1 */>;
 					opp-peak-kBps = <3972656>;
+					opp-supported-hw = <0x7>;
 				};
 
 				opp-315000000 {
 					opp-hz = /bits/ 64 <315000000>;
 					opp-level = <RPMH_REGULATOR_LEVEL_LOW_SVS>;
 					opp-peak-kBps = <1761718>;
+					opp-supported-hw = <0x7>;
 				};
 			};
 		};

-- 
2.53.0

