From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Tue, 25 Aug 2026 16:07:45 +0200
Subject: [PATCH v2 1/2] arm64: dts: qcom: sc8280xp-microsoft-blackrock:
 Replace old sound nodes, enable DisplayPort audio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260825-blackrock-audio-v2-1-659cc4724d57@oldschoolsolutions.biz>
References: <20260825-blackrock-audio-v2-0-659cc4724d57@oldschoolsolutions.biz>
In-Reply-To: <20260825-blackrock-audio-v2-0-659cc4724d57@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 =?utf-8?q?J=C3=A9r=C3=B4me_de_Bretagne?= <jerome.debretagne@gmail.com>, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787666870; l=6514;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=CdOmTI4YQ6rgBx9azLec66Nt1DW9VSVJREkoJZpOnqQ=;
 b=QnS04Kt39AUKI80WKUWoqxxKos/2GV4REumEMhPPPuUlylqmeSmhD6kWnTbG2bwp8qHBwgDI6
 jSXkJXXy6mTA0/YfJYomMDuwZ5QNh5CV77I9dGzb+hWhxCByeZBHA2p
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Windows Dev Kit 2023 has no built-in speakers, microphones or
headphone jack. Likewise the device with the same mainboard, Surface
Pro 9 5G [1]. The previous WCD938x / WSA / VA sound card definition
was therefore non-functional.

Replace the unused codec nodes, SoundWire controllers, LPASS macros
and related pinctrl with DisplayPort DAI links (DP0/DP1/DP2) so that
audio is available over the DP connectors. Add the required
sound-name-prefix properties and update the card model name to the
conventional SC8280XP-MICROSOFT-BLACKROCK form.

[1]: https://support.microsoft.com/en-us/surface/models/surface-pro-9-features-and-specs

Fixes: 16a7fed11714 ("arm64: dts: qcom: sc8280xp-blackrock: dt definition for WDK2023")
Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 .../boot/dts/qcom/sc8280xp-microsoft-blackrock.dts | 135 +++------------------
 arch/arm64/boot/dts/qcom/sc8280xp.dtsi             |   4 +
 2 files changed, 21 insertions(+), 118 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-blackrock.dts b/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-blackrock.dts
index 4f4b5f4285ec2..ac22f44020a64 100644
--- a/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-blackrock.dts
+++ b/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-blackrock.dts
@@ -28,32 +28,6 @@ aliases {
 		serial1 = &uart2;
 	};
 
-	wcd938x: audio-codec {
-		compatible = "qcom,wcd9380-codec";
-
-		pinctrl-0 = <&wcd_default>;
-		pinctrl-names = "default";
-
-		reset-gpios = <&tlmm 106 GPIO_ACTIVE_LOW>;
-
-		vdd-buck-supply = <&vreg_s10b>;
-		vdd-rxtx-supply = <&vreg_s10b>;
-		vdd-io-supply = <&vreg_s10b>;
-		vdd-mic-bias-supply = <&vreg_bob>;
-
-		qcom,micbias1-microvolt = <1800000>;
-		qcom,micbias2-microvolt = <1800000>;
-		qcom,micbias3-microvolt = <1800000>;
-		qcom,micbias4-microvolt = <1800000>;
-		qcom,mbhc-buttons-vthreshold-microvolt = <75000 150000 237000 500000 500000 500000 500000 500000>;
-		qcom,mbhc-headset-vthreshold-microvolt = <1700000>;
-		qcom,mbhc-headphone-vthreshold-microvolt = <50000>;
-		qcom,rx-device = <&wcd_rx>;
-		qcom,tx-device = <&wcd_tx>;
-
-		#sound-dai-cells = <1>;
-	};
-
 	dp3_connector: connector {
 		compatible = "dp-connector";
 		label = "DP-3";
@@ -852,23 +826,19 @@ &remoteproc_nsp0 {
 	status = "okay";
 };
 
-&rxmacro {
-	status = "okay";
-};
-
 &sound {
 	compatible = "qcom,sc8280xp-sndcard";
-	model = "microsoft/blackrock";
+	model = "SC8280XP-MICROSOFT-BLACKROCK";
 
-	wcd-playback-dai-link {
-		link-name = "WCD Playback";
+	dp0-dai-link {
+		link-name = "DP0 Playback";
 
-		cpu {
-			sound-dai = <&q6apmbedai RX_CODEC_DMA_RX_0>;
+		codec {
+			sound-dai = <&mdss0_dp0>;
 		};
 
-		codec {
-			sound-dai = <&wcd938x 0>, <&swr1 0>, <&rxmacro 0>;
+		cpu {
+			sound-dai = <&q6apmbedai DISPLAY_PORT_RX_0>;
 		};
 
 		platform {
@@ -876,15 +846,15 @@ platform {
 		};
 	};
 
-	wcd-capture-dai-link {
-		link-name = "WCD Capture";
+	dp1-dai-link {
+		link-name = "DP1 Playback";
 
-		cpu {
-			sound-dai = <&q6apmbedai TX_CODEC_DMA_TX_3>;
+		codec {
+			sound-dai = <&mdss0_dp1>;
 		};
 
-		codec {
-			sound-dai = <&wcd938x 1>, <&swr2 0>, <&txmacro 0>;
+		cpu {
+			sound-dai = <&q6apmbedai DISPLAY_PORT_RX_1>;
 		};
 
 		platform {
@@ -892,67 +862,23 @@ platform {
 		};
 	};
 
-	wsa-dai-link {
-		link-name = "WSA Playback";
-
-		cpu {
-			sound-dai = <&q6apmbedai WSA_CODEC_DMA_RX_0>;
-		};
+	dp2-dai-link {
+		link-name = "DP2 Playback";
 
 		codec {
-			sound-dai = <&swr0 0>, <&wsamacro 0>;
-		};
-
-		platform {
-			sound-dai = <&q6apm>;
+			sound-dai = <&mdss0_dp2>;
 		};
-	};
-
-	va-dai-link {
-		link-name = "VA Capture";
 
 		cpu {
-			sound-dai = <&q6apmbedai VA_CODEC_DMA_TX_0>;
+			sound-dai = <&q6apmbedai DISPLAY_PORT_RX_2>;
 		};
 
 		platform {
 			sound-dai = <&q6apm>;
 		};
-
-		codec {
-			sound-dai = <&vamacro 0>;
-		};
 	};
 };
 
-&swr0 {
-	status = "okay";
-};
-
-&swr1 {
-	status = "okay";
-
-	wcd_rx: wcd9380-rx@0,4 {
-		compatible = "sdw20217010d00";
-		reg = <0 4>;
-		qcom,rx-port-mapping = <1 2 3 4 5>;
-	};
-};
-
-&swr2 {
-	status = "okay";
-
-	wcd_tx: wcd9380-tx@0,3 {
-		compatible = "sdw20217010d00";
-		reg = <0 3>;
-		qcom,tx-port-mapping = <1 1 2 3>;
-	};
-};
-
-&txmacro {
-	status = "okay";
-};
-
 &uart2 {
 	pinctrl-0 = <&uart2_default>;
 	pinctrl-names = "default";
@@ -1076,31 +1002,12 @@ &usb_2_qmpphy0 {
 	status = "okay";
 };
 
-&vamacro {
-	pinctrl-0 = <&dmic01_default>, <&dmic23_default>;
-	pinctrl-names = "default";
-
-	vdd-micb-supply = <&vreg_s10b>;
-
-	qcom,dmic-sample-rate = <4800000>;
-
-	status = "okay";
-};
-
-&wsamacro {
-	status = "okay";
-};
-
 &xo_board_clk {
 	clock-frequency = <38400000>;
 };
 
 /* PINCTRL */
 
-&lpass_tlmm {
-	status = "okay";
-};
-
 &pmc8280_1_gpios {
 	misc_3p3_reg_en: misc-3p3-reg-en-state {
 		pins = "gpio1";
@@ -1302,14 +1209,6 @@ usb2_en_state: usb2-en-state {
 		output-low;
 	};
 
-	wcd_default: wcd-default-state {
-		reset-pins {
-			pins = "gpio106";
-			function = "gpio";
-			bias-disable;
-		};
-	};
-
 	wlan_en: wlan-en-state {
 		pins = "gpio134";
 		function = "gpio";
diff --git a/arch/arm64/boot/dts/qcom/sc8280xp.dtsi b/arch/arm64/boot/dts/qcom/sc8280xp.dtsi
index fbcfd3883bbb4..baca36b151853 100644
--- a/arch/arm64/boot/dts/qcom/sc8280xp.dtsi
+++ b/arch/arm64/boot/dts/qcom/sc8280xp.dtsi
@@ -4903,6 +4903,7 @@ mdss0_dp0: displayport-controller@ae90000 {
 				phy-names = "dp";
 
 				#sound-dai-cells = <0>;
+				sound-name-prefix = "DisplayPort0";
 
 				operating-points-v2 = <&mdss0_dp0_opp_table>;
 				power-domains = <&rpmhpd SC8280XP_MMCX>;
@@ -5168,6 +5169,7 @@ mdss0_dp1: displayport-controller@ae98000 {
 				phy-names = "dp";
 
 				#sound-dai-cells = <0>;
+				sound-name-prefix = "DisplayPort1";
 
 				operating-points-v2 = <&mdss0_dp1_opp_table>;
 				power-domains = <&rpmhpd SC8280XP_MMCX>;
@@ -5252,6 +5254,7 @@ mdss0_dp2: displayport-controller@ae9a000 {
 				operating-points-v2 = <&mdss0_dp2_opp_table>;
 
 				#sound-dai-cells = <0>;
+				sound-name-prefix = "DisplayPort2";
 
 				status = "disabled";
 
@@ -5327,6 +5330,7 @@ mdss0_dp3: displayport-controller@aea0000 {
 				operating-points-v2 = <&mdss0_dp3_opp_table>;
 
 				#sound-dai-cells = <0>;
+				sound-name-prefix = "DisplayPort3";
 
 				status = "disabled";
 

-- 
2.53.0

