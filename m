From: Xiangxu Yin <xiangxu.yin@oss.qualcomm.com>
Date: Tue, 14 Oct 2025 17:42:11 +0800
Subject: [PATCH v2 2/3] arm64: dts: qcom: Add DisplayPort and QMP USB3DP
 PHY for SM6150
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251014-add-displayport-support-to-qcs615-devicetree-v2-2-1209df74d410@oss.qualcomm.com>
References: <20251014-add-displayport-support-to-qcs615-devicetree-v2-0-1209df74d410@oss.qualcomm.com>
In-Reply-To: <20251014-add-displayport-support-to-qcs615-devicetree-v2-0-1209df74d410@oss.qualcomm.com>
To: Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jessica.zhang@oss.qualcomm.com>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, fange.zhang@oss.qualcomm.com, 
 yongxing.mou@oss.qualcomm.com, li.liu@oss.qualcomm.com, 
 Xiangxu Yin <xiangxu.yin@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1760434946; l=4500;
 i=xiangxu.yin@oss.qualcomm.com; s=20241125; h=from:subject:message-id;
 bh=jrRR9YL4HK6SbTmfepwLOlAbKElAZs5deEPV5yxtLa8=;
 b=Zhq0a6dozr1oeX/VMgGTSJwUvAp5Wi3ayuBKW4shLLbHXiBNfLTq0h5RqN3Zoeu39bI8Sn4H9
 DMjEKuvZ+KXBUWG71ROPVttxZbYBjPv0UFEtIXYKVCOJfuT/lDPx80u
X-Developer-Key: i=xiangxu.yin@oss.qualcomm.com; a=ed25519;
 pk=F1TwipJzpywfbt3n/RPi4l/A4AVF+QC89XzCHgZYaOc=
X-Endpoint-Received: by B4 Relay for xiangxu.yin@oss.qualcomm.com/20241125 with auth_id=542
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce DisplayPort controller node and associated QMP USB3-DP PHY
for SM6150 SoC. Update clock and endpoint connections to enable DP
integration.

Signed-off-by: Xiangxu Yin <xiangxu.yin@oss.qualcomm.com>
---
 arch/arm64/boot/dts/qcom/sm6150.dtsi | 110 ++++++++++++++++++++++++++++++++++-
 1 file changed, 108 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sm6150.dtsi b/arch/arm64/boot/dts/qcom/sm6150.dtsi
index 6128d8c48f9c0807ac488ddac3b2377678e8f8c3..cdf53d74c778c652080b0288278353e20c317379 100644
--- a/arch/arm64/boot/dts/qcom/sm6150.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm6150.dtsi
@@ -17,6 +17,7 @@
 #include <dt-bindings/power/qcom-rpmpd.h>
 #include <dt-bindings/power/qcom,rpmhpd.h>
 #include <dt-bindings/soc/qcom,rpmh-rsc.h>
+#include <dt-bindings/phy/phy-qcom-qmp.h>
 
 / {
 	interrupt-parent = <&intc>;
@@ -3717,6 +3718,7 @@ port@0 {
 						reg = <0>;
 
 						dpu_intf0_out: endpoint {
+							remote-endpoint = <&mdss_dp0_in>;
 						};
 					};
 
@@ -3749,6 +3751,84 @@ opp-307200000 {
 				};
 			};
 
+			mdss_dp0: displayport-controller@ae90000 {
+				compatible = "qcom,sm6150-dp", "qcom,sm8150-dp", "qcom,sm8350-dp";
+
+				reg = <0x0 0x0ae90000 0x0 0x200>,
+				      <0x0 0x0ae90200 0x0 0x200>,
+				      <0x0 0x0ae90400 0x0 0x600>,
+				      <0x0 0x0ae90a00 0x0 0x600>,
+				      <0x0 0x0ae91000 0x0 0x600>;
+
+				interrupt-parent = <&mdss>;
+				interrupts = <12>;
+
+				clocks = <&dispcc DISP_CC_MDSS_AHB_CLK>,
+					 <&dispcc DISP_CC_MDSS_DP_AUX_CLK>,
+					 <&dispcc DISP_CC_MDSS_DP_LINK_CLK>,
+					 <&dispcc DISP_CC_MDSS_DP_LINK_INTF_CLK>,
+					 <&dispcc DISP_CC_MDSS_DP_PIXEL_CLK>,
+					 <&dispcc DISP_CC_MDSS_DP_PIXEL1_CLK>;
+				clock-names = "core_iface",
+					      "core_aux",
+					      "ctrl_link",
+					      "ctrl_link_iface",
+					      "stream_pixel",
+					      "stream_1_pixel";
+
+				assigned-clocks = <&dispcc DISP_CC_MDSS_DP_LINK_CLK_SRC>,
+						  <&dispcc DISP_CC_MDSS_DP_PIXEL_CLK_SRC>;
+				assigned-clock-parents = <&usb_qmpphy_2 QMP_USB43DP_DP_LINK_CLK>,
+							 <&usb_qmpphy_2 QMP_USB43DP_DP_VCO_DIV_CLK>;
+
+				phys = <&usb_qmpphy_2 QMP_USB43DP_DP_PHY>;
+				phy-names = "dp";
+
+				operating-points-v2 = <&dp_opp_table>;
+				power-domains = <&rpmhpd RPMHPD_CX>;
+
+				#sound-dai-cells = <0>;
+
+				status = "disabled";
+
+				ports {
+					#address-cells = <1>;
+					#size-cells = <0>;
+
+					port@0 {
+						reg = <0>;
+						mdss_dp0_in: endpoint {
+							remote-endpoint = <&dpu_intf0_out>;
+						};
+					};
+
+					port@1 {
+						reg = <1>;
+						mdss_dp0_out: endpoint {
+						};
+					};
+				};
+
+				dp_opp_table: opp-table {
+					compatible = "operating-points-v2";
+
+					opp-160000000 {
+						opp-hz = /bits/ 64 <160000000>;
+						required-opps = <&rpmhpd_opp_low_svs>;
+					};
+
+					opp-270000000 {
+						opp-hz = /bits/ 64 <270000000>;
+						required-opps = <&rpmhpd_opp_svs>;
+					};
+
+					opp-540000000 {
+						opp-hz = /bits/ 64 <540000000>;
+						required-opps = <&rpmhpd_opp_svs_l1>;
+					};
+				};
+			};
+
 			mdss_dsi0: dsi@ae94000 {
 				compatible = "qcom,sm6150-dsi-ctrl", "qcom,mdss-dsi-ctrl";
 				reg = <0x0 0x0ae94000 0x0 0x400>;
@@ -3844,8 +3924,8 @@ dispcc: clock-controller@af00000 {
 				 <&mdss_dsi0_phy DSI_BYTE_PLL_CLK>,
 				 <&mdss_dsi0_phy DSI_PIXEL_PLL_CLK>,
 				 <0>,
-				 <0>,
-				 <0>;
+				 <&usb_qmpphy_2 QMP_USB43DP_DP_LINK_CLK>,
+				 <&usb_qmpphy_2 QMP_USB43DP_DP_VCO_DIV_CLK>;
 
 			#clock-cells = <1>;
 			#reset-cells = <1>;
@@ -4214,6 +4294,32 @@ usb_qmpphy: phy@88e6000 {
 			status = "disabled";
 		};
 
+		usb_qmpphy_2: phy@88e8000 {
+			compatible = "qcom,qcs615-qmp-usb3-dp-phy";
+			reg = <0x0 0x088e8000 0x0 0x2000>;
+
+			clocks = <&gcc GCC_USB2_SEC_PHY_AUX_CLK>,
+				 <&gcc GCC_USB3_SEC_CLKREF_CLK>,
+				 <&gcc GCC_AHB2PHY_WEST_CLK>,
+				 <&gcc GCC_USB2_SEC_PHY_PIPE_CLK>;
+			clock-names = "aux",
+				      "ref",
+				      "cfg_ahb",
+				      "pipe";
+
+			resets = <&gcc GCC_USB3PHY_PHY_SEC_BCR >,
+				 <&gcc GCC_USB3_DP_PHY_SEC_BCR>;
+			reset-names = "phy_phy",
+				      "dp_phy";
+
+			#clock-cells = <1>;
+			#phy-cells = <1>;
+
+			qcom,tcsr-reg = <&tcsr 0xbff0 0xb24c>;
+
+			status = "disabled";
+		};
+
 		usb_1: usb@a6f8800 {
 			compatible = "qcom,qcs615-dwc3", "qcom,dwc3";
 			reg = <0x0 0x0a6f8800 0x0 0x400>;

-- 
2.34.1

