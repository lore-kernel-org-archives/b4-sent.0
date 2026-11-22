From: David Heidelberg <david@ixit.cz>
Date: Sun, 22 Nov 2026 01:01:14 +0100
Subject: [PATCH] arm64: dts: qcom: sdm845-shift-axolotl: Enable sound
 subsystem
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-axolotl-misc-v1-1-27211eded948@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDI0Nz3cSK/Jz8khzd3MziZF3DFGNjA3PjJONkI2MloJaCotS0zAqwcdG
 xtbUAYdgdL14AAAA=
X-Change-ID: 20251217-axolotl-misc-1d33073b3c23
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, Abel Vesa <abelvesa@kernel.org>
Cc: Alexander Martinz <amartinz@shiftphones.com>, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Dylan Van Assche <me@dylanvanassche.be>, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=7055; i=david@ixit.cz;
 h=from:subject:message-id; bh=YTj0uYzd+DRdhyLqXRtWaLi9sUqjVAzyoVLYvS8B748=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrAjDOWX+eQFGOoHfDcXBQG04Gx3dw4ZlrP4W6q
 dhJmTXx7n2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawIwzgAKCRBgAj/E00kg
 ckObD/oDrzVErBTGKzbhkfZHeuo4ZFtGqjQ/qVLGkMr6kOPJ0+Psci1+fOtoDvm5o78TrcA71YQ
 C3wTFQrT2GrmqFuTHckczHV0s/hbtRCUbfE2QSac6TzV9NgAAiwh2djNdhiJWU3NBAIJs7k/L3F
 kRhUta4EVmmpsEFcyvi/tHgJFSQaLkaiRje4tAoMkntSEzDgdZTwi3f1XW5enoNgpZu1PKjU7jv
 6I8Cm4Cx9tmFLvAra8yGoDA7h1EZKcGphBWpY/3QyV0Qp21QJaMcq+B4NZKN2RIkqoNPh7c2vuC
 TXXaj7cz+cUvkN5OFhCBjYgtIAsQvifOAE2VHDPxGIUY+gSC+RT9rdZAynApHoUkuKph8hiUIFq
 05zpi3G+vUCiEW5S3EDtu3TrtY/uJg9pLG7MxkPwNZ4DZpJJyHSmx6hzl7sWplrhNqjJY40JB32
 rtSYannshNMfJePdH8MssUjZcyrlL79xaL5GFfdKtRmcAxXONtSf/75rioGWexR7o6gwywH/YJr
 UYe54RS6vOI8LPLIIZyqXL5bHUXl/79LuNHak2cEtXI5dlNN1wGDlllIv1vaUw1p0M8nMozK6Ms
 tat9YPZg3p9MPTaLvG84yzGR/Y8YHvmdB4o6fyo8uPneDzFti2OzbAbxRVTSrBioHZuGXlUdIMC
 fe4EYu2Ewcd7+ZQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce support for audio speakers and microphones on the SHIFT6mq.

The SHIFT6mq uses the WCD9340 codec over SLIMbus for the earpiece,
headset jack, and three microphones (internal bottom, internal back, and
headset), together with an NXP TFA9890 amplifier over Quaternary MI2S
for the main speaker. Enable MultiMedia1-6 frontend DAIs and wire up the
corresponding SLIMbus and speaker backend DAI links.

Co-developed-by: Alexander Martinz <amartinz@shiftphones.com>
Signed-off-by: Alexander Martinz <amartinz@shiftphones.com>
Co-developed-by: Dylan Van Assche <me@dylanvanassche.be>
Signed-off-by: Dylan Van Assche <me@dylanvanassche.be>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
Front speaker and earpiece works.
All three microphones receiving signal.
---
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts | 199 +++++++++++++++++++++-
 1 file changed, 198 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
index 1b0eaeafbd517..e02e5ca868c8f 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
@@ -6,17 +6,21 @@
  */
 
 /dts-v1/;
 
 #include <dt-bindings/arm/qcom,ids.h>
 #include <dt-bindings/gpio/gpio.h>
 #include <dt-bindings/leds/common.h>
 #include <dt-bindings/regulator/qcom,rpmh-regulator.h>
+#include <dt-bindings/sound/qcom,q6afe.h>
+#include <dt-bindings/sound/qcom,q6asm.h>
+#include <dt-bindings/sound/qcom,wcd934x.h>
 #include "sdm845.dtsi"
+#include "sdm845-wcd9340.dtsi"
 #include "pm8998.dtsi"
 #include "pmi8998.dtsi"
 
 / {
 	model = "SHIFT SHIFT6mq";
 	compatible = "shift,axolotl", "qcom,sdm845";
 	chassis-type = "handset";
 	qcom,msm-id = <QCOM_ID_SDM845 0x20001>;
@@ -516,20 +520,21 @@ &i2c10 {
 	/* SMB1355@0x0C */
 };
 
 &i2c11 {
 	clock-frequency = <400000>;
 
 	status = "okay";
 
-	audio-codec@34 {
+	tfa9890_codec: audio-codec@34 {
 		compatible = "nxp,tfa9890";
 		reg = <0x34>;
 		vddd-supply = <&vreg_s4a_1p8>;
+		sound-name-prefix = "Speaker";
 		#sound-dai-cells = <0>;
 	};
 };
 
 &ipa {
 	firmware-name = "qcom/sdm845/SHIFT/axolotl/ipa_fws.mbn";
 
 	status = "okay";
@@ -654,16 +659,49 @@ led-1 {
 		color = <LED_COLOR_ID_YELLOW>;
 		led-sources = <2>;
 		led-max-microamp = <100000>;
 		flash-max-microamp = <1100000>;
 		flash-max-timeout-us = <1280000>;
 	};
 };
 
+&q6afedai {
+	dai@22 {
+		reg = <QUATERNARY_MI2S_RX>;
+		qcom,sd-lines = <0>;
+	};
+};
+
+&q6asmdai {
+	dai@0 {
+		reg = <MSM_FRONTEND_DAI_MULTIMEDIA1>;
+	};
+
+	dai@1 {
+		reg = <MSM_FRONTEND_DAI_MULTIMEDIA2>;
+	};
+
+	dai@2 {
+		reg = <MSM_FRONTEND_DAI_MULTIMEDIA3>;
+	};
+
+	dai@3 {
+		reg = <MSM_FRONTEND_DAI_MULTIMEDIA4>;
+	};
+
+	dai@4 {
+		reg = <MSM_FRONTEND_DAI_MULTIMEDIA5>;
+	};
+
+	dai@5 {
+		reg = <MSM_FRONTEND_DAI_MULTIMEDIA6>;
+	};
+};
+
 &qup_uart9_rx {
 	drive-strength = <2>;
 	bias-pull-up;
 };
 
 &qup_uart9_tx {
 	drive-strength = <2>;
 	bias-disable;
@@ -696,16 +734,161 @@ &sdhc_2 {
 };
 
 &slpi_pas {
 	firmware-name = "qcom/sdm845/SHIFT/axolotl/slpi.mbn";
 
 	status = "okay";
 };
 
+&sound {
+	model = "SHIFT6mq";
+	compatible = "qcom,sdm845-sndcard";
+	pinctrl-0 = <&quat_mi2s_active &quat_mi2s_sd0_active>;
+	pinctrl-names = "default";
+
+	audio-routing = "RX_BIAS", "MCLK",
+			"AMIC1", "MIC BIAS1",
+			"AMIC2", "MIC BIAS2",
+			"AMIC3", "MIC BIAS3";
+
+	/* mm[0-9]-dai-link nodes must be positioned first regardless of sorting */
+	mm1-dai-link {
+		link-name = "MultiMedia1";
+		cpu {
+			sound-dai = <&q6asmdai MSM_FRONTEND_DAI_MULTIMEDIA1>;
+		};
+	};
+
+	mm2-dai-link {
+		link-name = "MultiMedia2";
+		cpu {
+			sound-dai = <&q6asmdai MSM_FRONTEND_DAI_MULTIMEDIA2>;
+		};
+	};
+
+	mm3-dai-link {
+		link-name = "MultiMedia3";
+		cpu {
+			sound-dai = <&q6asmdai MSM_FRONTEND_DAI_MULTIMEDIA3>;
+		};
+	};
+
+	mm4-dai-link {
+		link-name = "MultiMedia4";
+		cpu {
+			sound-dai = <&q6asmdai MSM_FRONTEND_DAI_MULTIMEDIA4>;
+		};
+	};
+
+	mm5-dai-link {
+		link-name = "MultiMedia5";
+		cpu {
+			sound-dai = <&q6asmdai MSM_FRONTEND_DAI_MULTIMEDIA5>;
+		};
+	};
+
+	mm6-dai-link {
+		link-name = "MultiMedia6";
+		cpu {
+			sound-dai = <&q6asmdai MSM_FRONTEND_DAI_MULTIMEDIA6>;
+		};
+	};
+
+	speaker-dai-link {
+		link-name = "Speaker Playback";
+		codec {
+			sound-dai = <&tfa9890_codec>;
+		};
+
+		cpu {
+			sound-dai = <&q6afedai QUATERNARY_MI2S_RX>;
+		};
+
+		platform {
+			sound-dai = <&q6routing>;
+		};
+	};
+
+	slimcap-wcd-dai-link {
+		link-name = "SLIM WCD Capture 1";
+		codec {
+			sound-dai = <&wcd9340 AIF1_CAP>;
+		};
+
+		cpu {
+			sound-dai = <&q6afedai SLIMBUS_1_TX>;
+		};
+
+		platform {
+			sound-dai = <&q6routing>;
+		};
+	};
+
+	slim-dai-link {
+		link-name = "SLIM WCD Playback 1";
+		codec {
+			sound-dai = <&wcd9340 AIF1_PB>;
+		};
+
+		cpu {
+			sound-dai = <&q6afedai SLIMBUS_0_RX>;
+		};
+
+		platform {
+			sound-dai = <&q6routing>;
+		};
+	};
+
+	slimcap-dai-link {
+		link-name = "SLIM WCD Capture 2";
+		codec {
+			sound-dai = <&wcd9340 AIF2_CAP>;
+		};
+
+		cpu {
+			sound-dai = <&q6afedai SLIMBUS_0_TX>;
+		};
+
+		platform {
+			sound-dai = <&q6routing>;
+		};
+	};
+
+	slim-wcd-dai-link {
+		link-name = "SLIM WCD Playback 2";
+		codec {
+			sound-dai = <&wcd9340 AIF2_PB>;
+		};
+
+		cpu {
+			sound-dai = <&q6afedai SLIMBUS_1_RX>;
+		};
+
+		platform {
+			sound-dai = <&q6routing>;
+		};
+	};
+
+	slimcap2-wcd-dai-link {
+		link-name = "SLIM WCD Capture 3";
+		codec {
+			sound-dai = <&wcd9340 AIF3_CAP>;
+		};
+
+		cpu {
+			sound-dai = <&q6afedai SLIMBUS_2_TX>;
+		};
+
+		platform {
+			sound-dai = <&q6routing>;
+		};
+	};
+};
+
 &tlmm {
 	gpio-reserved-ranges = <0 4>, <81 4>;
 
 	sdc2_default_state: sdc2-default-state {
 		clk-pins {
 			pins = "sdc2_clk";
 			drive-strength = <16>;
 			bias-disable;
@@ -879,16 +1062,30 @@ &usb_1_qmpphy {
 };
 
 &venus {
 	firmware-name = "qcom/sdm845/SHIFT/axolotl/venus.mbn";
 
 	status = "okay";
 };
 
+&wcd9340 {
+	reset-gpios = <&tlmm 64 GPIO_ACTIVE_HIGH>;
+	vdd-buck-supply = <&vreg_s4a_1p8>;
+	vdd-buck-sido-supply = <&vreg_s4a_1p8>;
+	vdd-tx-supply = <&vreg_s4a_1p8>;
+	vdd-rx-supply = <&vreg_s4a_1p8>;
+	vdd-io-supply = <&vreg_s4a_1p8>;
+
+	qcom,micbias1-microvolt = <2700000>;
+	qcom,micbias2-microvolt = <2700000>;
+	qcom,micbias3-microvolt = <2700000>;
+	qcom,micbias4-microvolt = <2700000>;
+};
+
 &wifi {
 	vdd-0.8-cx-mx-supply = <&vreg_l5a_0p8>;
 	vdd-1.8-xo-supply = <&vreg_pmu_xo>;
 	vdd-1.3-rfa-supply = <&vreg_pmu_rf>;
 	vdd-3.3-ch0-supply = <&vreg_pmu_ch0>;
 	vdd-3.3-ch1-supply = <&vreg_pmu_ch1>;
 
 	qcom,calibration-variant = "shift_axolotl";

---
base-commit: 909ef7a9a30fa139e69e555e3606680f5cca7726
change-id: 20251217-axolotl-misc-1d33073b3c23

Best regards,
--  
David Heidelberg <david@ixit.cz>

