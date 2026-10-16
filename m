From: David Heidelberg <david@ixit.cz>
Date: Fri, 16 Oct 2026 23:52:20 +0200
Subject: [PATCH v6 1/2] arm64: dts: qcom: sdm845-google: Add basic audio
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261016-pixel3-audio-v6-1-11c88448b3be@ixit.cz>
References: <20261016-pixel3-audio-v6-0-11c88448b3be@ixit.cz>
In-Reply-To: <20261016-pixel3-audio-v6-0-11c88448b3be@ixit.cz>
To: Srinivas Kandagatla <srini@kernel.org>, 
 Srinivas Kandagatla <srinivas.kandagatla@oss.qualcomm.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 David Rhodes <david.rhodes@cirrus.com>, 
 Richard Fitzgerald <rf@opensource.cirrus.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 David Rhodes <drhodes@opensource.cirrus.com>, 
 Conor Dooley <conor+dt@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: Viken Dadhaniya <viken.dadhaniya@oss.qualcomm.com>, 
 linux-sound@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, patches@opensource.cirrus.com, 
 devicetree@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=5501; i=david@ixit.cz;
 h=from:subject:message-id; bh=OPuhAiGiwh1F0hU4jXrVkMpTLkDrYHqdITX3pk25rWU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq0pyZjle75JsbIv7W+OlzUEq6KqljH5zwKfmeU
 hQf4j85LpSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCatKcmQAKCRBgAj/E00kg
 cgQ7EACxntnWeyRNPzt4VFujSLCUZ6LdUoEy5wtxj/E98hAdwsvGMTIEDt3wvVMVXoXZ6w89dEp
 VHoiokQrq5BM6IaaFtRPTBIsJFcQJ4b6JZteyjc/zLBpJTuCmc+IJW3V58XJM4UCJHuvlkUwH5Q
 lpjoatPrKNlG16KEuVaH8yfczPJg1Idpm0dk4NkzDpISicb7z0Dh1pz58UFZ6EoXivXQpJt1tk2
 pPzHFK0kA2AyCLHuldG/rsq3/SE3XGE+7XRM0DdtxxT3nZnH7dU43ofLShWY7hT9J9No0WrMxGf
 HgP+Q/9cC6aOBzRwYTb9On9kvdEXS8gElf7O9m6/cdZv/ASaxHTYej6GRN8hfz6PxQQ8xRF8225
 qr6PKFlHTHQQXgYGNTRZSXZ/G0O4bik8/JTvE8yxmYRHELfeyP7MXwAZScSwbMAIRunIYSZVCjT
 7npkTjKSsYPuv6Fhlo+9tKyOmqFT4omSgfSIkoM20+zWlGSTIiI4glpMUlkPKtZn2P7zU8hVPGE
 3G3wpYgs/5o5GKPS+aBafELR8oNE3JWfujbuWlrfkmmk0z9oKaYAauctisANioaA0vKqzT9ywod
 BQ2/Ti9aReebh6anUo+MFaNG9bp97NXzsXMYwXryBkht8iUVub6jksHwQnx8y91tgE89WhpYsi8
 l4o4TwePRqvjkHQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce support for sound card and wire two CS35L36 audio codecs for
top and bottom speakers.

Inspired by commit from Joel Selvaraj.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi | 132 ++++++++++++++++++++-
 1 file changed, 130 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
index f1379857e2742..68d26c1a06d0c 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
@@ -2,16 +2,18 @@
 
 /dts-v1/;
 
 #include <dt-bindings/arm/qcom,ids.h>
 #include <dt-bindings/dma/qcom-gpi.h>
 #include <dt-bindings/input/linux-event-codes.h>
 #include <dt-bindings/interrupt-controller/irq.h>
 #include <dt-bindings/regulator/qcom,rpmh-regulator.h>
+#include <dt-bindings/sound/qcom,q6afe.h>
+#include <dt-bindings/sound/qcom,q6asm.h>
 
 #include "sdm845.dtsi"
 #include "pm8998.dtsi"
 #include "pmi8998.dtsi"
 
 /delete-node/ &mpss_region;
 /delete-node/ &venus_mem;
 /delete-node/ &cdsp_mem;
@@ -406,19 +408,61 @@ nfc@28 {
 		firmware-gpios = <&tlmm 79 GPIO_ACTIVE_HIGH>;
 
 		pinctrl-0 = <&nfc_default>;
 		pinctrl-names = "default";
 	};
 };
 
 &i2c12 {
-	/* Bottom spkr (right) CS35L36 @ 40 */
+	status = "okay";
+
+	cs35l36_bottom: audio-codec@40 {
+		compatible = "cirrus,cs35l36";
+		reg = <0x40>;
+		reset-gpios = <&tlmm 112 GPIO_ACTIVE_HIGH>;
+		#sound-dai-cells = <0>;
+		sound-name-prefix = "Right"; /* Bottom */
+		VA-supply = <&vreg_s4a_1p8>;
+		interrupts-extended = <&tlmm 115 IRQ_TYPE_LEVEL_LOW>;
+
+		pinctrl-0 = <&cs35l36_bottom_default_state>;
+		pinctrl-names = "default";
+
+		cirrus,boost-ind-nanohenry = <1000>;
+		cirrus,boost-ctl-select = <1>;
+		cirrus,boost-ctl-millivolt = <10000>;
+		cirrus,boost-peak-milliamp = <3700>;
+		cirrus,temp-warn-threshold = <1>;
+		cirrus,multi-amp-mode;
+		cirrus,irq-drive-select = <0>;
+		cirrus,irq-gpio-select = <0>;
+	};
+
+	cs35l36_top: audio-codec@41 {
+		compatible = "cirrus,cs35l36";
+		reg = <0x41>;
+		reset-gpios = <&tlmm 75 GPIO_ACTIVE_HIGH>;
+		#sound-dai-cells = <0>;
+		sound-name-prefix = "Left"; /* Top */
+		VA-supply = <&vreg_s4a_1p8>;
+		interrupts-extended = <&tlmm 40 IRQ_TYPE_LEVEL_LOW>;
 
-	/* Top spkr (left) CS35L36 @ 41 */
+		pinctrl-0 = <&cs35l36_top_default_state>;
+		pinctrl-names = "default";
+
+		cirrus,boost-ind-nanohenry = <1000>;
+		cirrus,boost-ctl-select = <0x01>;
+		cirrus,boost-ctl-millivolt = <10000>;
+		cirrus,boost-peak-milliamp = <3700>;
+		cirrus,temp-warn-threshold = <1>;
+		cirrus,multi-amp-mode;
+		cirrus,irq-drive-select = <0>;
+		cirrus,irq-gpio-select = <0>;
+	};
 };
 
 &ipa {
 	firmware-name = "qcom/sdm845/Google/blueline/ipa_fws.mbn";
 	memory-region = <&ipa_fw_mem>;
 
 	status = "okay";
 };
@@ -451,16 +495,35 @@ &pm8998_resin {
 };
 
 &pmi8998_charger {
 	monitored-battery = <&battery>;
 
 	status = "okay";
 };
 
+&q6afedai {
+	dai@72 {
+		reg = <QUATERNARY_TDM_RX_0>;
+
+		qcom,tdm-sync-mode = <0>;
+		qcom,tdm-sync-src = <1>;
+		qcom,tdm-data-out = <0>;
+		qcom,tdm-invert-sync = <0>;
+		qcom,tdm-data-delay = <1>;
+		qcom,tdm-data-align = <0>;
+	};
+};
+
+&q6asmdai {
+	dai@0 {
+		reg = <MSM_FRONTEND_DAI_MULTIMEDIA1>;
+	};
+};
+
 &qupv3_id_0 {
 	status = "okay";
 };
 
 &qupv3_id_1 {
 	status = "okay";
 };
 
@@ -469,16 +532,49 @@ &qup_uart9_rx {
 	bias-pull-up;
 };
 
 &qup_uart9_tx {
 	drive-strength = <2>;
 	bias-disable;
 };
 
+&sound {
+	compatible = "qcom,sdm845-sndcard";
+	model = "Pixel 3";
+	pinctrl-0 = <&quat_mi2s_active>, <&quat_mi2s_sd0_active>,
+		    <&quat_mi2s_sd1_active>;
+	pinctrl-names = "default";
+
+	/* mm[0-9]-dai-link nodes must be positioned first regardless of sorting */
+	mm1-dai-link {
+		link-name = "MultiMedia1";
+
+		cpu {
+			sound-dai = <&q6asmdai MSM_FRONTEND_DAI_MULTIMEDIA1>;
+		};
+	};
+
+	cs35l36-dai-link {
+		link-name = "Speaker Playback";
+
+		codec {
+			sound-dai = <&cs35l36_bottom>, <&cs35l36_top>;
+		};
+
+		cpu {
+			sound-dai = <&q6afedai QUATERNARY_TDM_RX_0>;
+		};
+
+		platform {
+			sound-dai = <&q6routing>;
+		};
+	};
+};
+
 &tlmm {
 	gpio-reserved-ranges = < 0 4>, /* SPI (Intel MNH Pixel Visual Core) */
 			       <81 4>; /* SPI (most likely Fingerprint Cards FPC1075) */
 
 	nfc_default: nfc-default-state {
 		enable-pins {
 			pins = "gpio25";
 			function = "gpio";
@@ -517,16 +613,48 @@ touchscreen_pins: ts-pins-gpio-state {
 	};
 
 	touchscreen_i2c_pins: qup-i2c2-gpio-state {
 		pins = "gpio27", "gpio28";
 		function = "gpio";
 		drive-strength = <2>;
 		bias-disable;
 	};
+
+	cs35l36_bottom_default_state: cs35l36-bottom-default-state {
+		reset-pins {
+			pins = "gpio112";
+			function = "gpio";
+			drive-strength = <2>;
+			bias-disable;
+		};
+
+		irq-pins {
+			pins = "gpio115";
+			function = "gpio";
+			drive-strength = <2>;
+			bias-pull-up;
+		};
+	};
+
+	cs35l36_top_default_state: cs35l36-top-default-state {
+		irq-pins {
+			pins = "gpio40";
+			function = "gpio";
+			drive-strength = <2>;
+			bias-pull-up;
+		};
+
+		reset-pins {
+			pins = "gpio75";
+			function = "gpio";
+			drive-strength = <2>;
+			bias-disable;
+		};
+	};
 };
 
 &uart6 {
 	pinctrl-0 = <&qup_uart6_4pin>;
 
 	status = "okay";
 
 	bluetooth {

-- 
2.55.0

