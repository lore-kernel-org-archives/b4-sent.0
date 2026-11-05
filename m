From: Demeter Barna <me@fromdisposition.org>
Date: Thu, 05 Nov 2026 13:30:00 +0000
Subject: [PATCH 1/5] arm64: dts: qcom: sm8350: Vote the GPU memory
 bandwidth
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-b4-sm8350-gpu-v1-1-a7175cdd6512@fromdisposition.org>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793885419; l=2824;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=Qj0SetyPXcoz/xqqaiV7q7+hqlgKFBJNuFzemnv6s4o=;
 b=5k1FzaWwPTWmD/1NkUbNJdAoQuLjitJ1m3kP377Dc4pqlngCKZdo6rf+qrYK5ez549PL8xZqB
 j7hWNqGEiH/CGMv0k47fj2wK//sUKL4PsdtlPd0qxAMIu6Uj+Uz7WZw
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SM8350 GPU never asks for DDR bandwidth. On A660 the GMU gets a DDR
table with only an "off" entry, so the driver leaves the vote to the OPP
core, and the OPP core votes only when the GPU has an interconnect path
and its OPPs carry a bandwidth. sm8350.dtsi has neither.

Add the GPU's path to DDR and give each OPP the peak bandwidth that
Qualcomm's GPU tables for this SoC vote at that frequency on LPDDR5, as
kodiak.dtsi does for its A635.

Signed-off-by: Demeter Barna <me@fromdisposition.org>
---
 arch/arm64/boot/dts/qcom/sm8350.dtsi | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sm8350.dtsi b/arch/arm64/boot/dts/qcom/sm8350.dtsi
index 55b32050c..903b2968c 100644
--- a/arch/arm64/boot/dts/qcom/sm8350.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8350.dtsi
@@ -2050,6 +2050,10 @@ gpu: gpu@3d00000 {
 
 			iommus = <&adreno_smmu 0 0x400>, <&adreno_smmu 1 0x400>;
 
+			interconnects = <&gem_noc MASTER_GFX3D QCOM_ICC_TAG_ALWAYS
+					 &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ALWAYS>;
+			interconnect-names = "gfx-mem";
+
 			operating-points-v2 = <&gpu_opp_table>;
 
 			qcom,gmu = <&gmu>;
@@ -2068,51 +2072,61 @@ gpu_opp_table: opp-table {
 				opp-840000000 {
 					opp-hz = /bits/ 64 <840000000>;
 					opp-level = <RPMH_REGULATOR_LEVEL_TURBO_L1>;
+					opp-peak-kBps = <12484375>;
 				};
 
 				opp-778000000 {
 					opp-hz = /bits/ 64 <778000000>;
 					opp-level = <RPMH_REGULATOR_LEVEL_TURBO>;
+					opp-peak-kBps = <12484375>;
 				};
 
 				opp-738000000 {
 					opp-hz = /bits/ 64 <738000000>;
 					opp-level = <RPMH_REGULATOR_LEVEL_NOM_L1>;
+					opp-peak-kBps = <12484375>;
 				};
 
 				opp-676000000 {
 					opp-hz = /bits/ 64 <676000000>;
 					opp-level = <RPMH_REGULATOR_LEVEL_NOM>;
+					opp-peak-kBps = <10687500>;
 				};
 
 				opp-608000000 {
 					opp-hz = /bits/ 64 <608000000>;
 					opp-level = <RPMH_REGULATOR_LEVEL_SVS_L2>;
+					opp-peak-kBps = <6074218>;
 				};
 
 				opp-540000000 {
 					opp-hz = /bits/ 64 <540000000>;
 					opp-level = <RPMH_REGULATOR_LEVEL_SVS_L1>;
+					opp-peak-kBps = <6074218>;
 				};
 
 				opp-491000000 {
 					opp-hz = /bits/ 64 <491000000>;
 					opp-level = <RPMH_REGULATOR_LEVEL_SVS_L0>;
+					opp-peak-kBps = <6074218>;
 				};
 
 				opp-443000000 {
 					opp-hz = /bits/ 64 <443000000>;
 					opp-level = <RPMH_REGULATOR_LEVEL_SVS>;
+					opp-peak-kBps = <6074218>;
 				};
 
 				opp-379000000 {
 					opp-hz = /bits/ 64 <379000000>;
 					opp-level = <80 /* RPMH_REGULATOR_LEVEL_LOW_SVS_L1 */>;
+					opp-peak-kBps = <3972656>;
 				};
 
 				opp-315000000 {
 					opp-hz = /bits/ 64 <315000000>;
 					opp-level = <RPMH_REGULATOR_LEVEL_LOW_SVS>;
+					opp-peak-kBps = <1761718>;
 				};
 			};
 		};

-- 
2.53.0

