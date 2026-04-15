From: David Heidelberg <david@ixit.cz>
Date: Wed, 15 Apr 2026 13:56:08 +0200
Subject: [PATCH] arm64: dts: qcom: sdm845-shift-axolotl: describe WiFi/BT
 properly
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260415-axolotl-wifi-v1-1-07df39cfc0a4@ixit.cz>
X-B4-Tracking: v=1; b=H4sIANd832kC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDE0NT3cSK/Jz8khzd8sy0TF1LIwuD1DQLCzNDi0QloJaCotS0zAqwcdG
 xtbUAHx2u0V4AAAA=
X-Change-ID: 20260415-axolotl-wifi-9280ef88618a
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2911; i=david@ixit.cz;
 h=from:subject:message-id; bh=m+1gBdPtLHFUl/FZSDkO1ZCLirKtvrPu1z4kfRZxdtU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp33zaBHJJ7tdDyjIkv2tD9QKaMuEipuGeY8xy6
 /VyaEIVhxSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCad982gAKCRBgAj/E00kg
 crFEEADExORWdeDstIT/UDZrBsjq/ilsoTTMrKPkU/l2bL7gKl2cTONbMXHyCq6fF60tZiNQWrM
 /yXAXIx2hQ3PvP1N1++pz7vSH/tgbDRu76BtTIeFf6HVtFw088DJPIO2AwXseCNfz625/RsqaGJ
 rRZ1K55lg1BJfiqbs7BETgPjUgWkAVPH08Yes8SqpTCIOfFQqmVgZAaEjbBb/XOUbD4kVQIDCbW
 pxu1F+6aYc5pB2io4Dle868N0mUTyd0GFoLyPhKD2oU9ex/C5mvF2eWh02nOF5ewOjJPb9I+Ii4
 AL62NOJh9qu+mkqSJdT3Isogz0mwFI1pG02KOt7H4aCgoFAbJWJQl6ir/TnGZV3KObz013Bsmex
 88uSDnPzUvdE/Fu2UhFGdXy6FBLvv3gqXnFxY1QQwmnT2i/d4qDfO524PFofUO4OtcG1PYaZ1mp
 2N9zFOb+YfUdQ63r8RKbgsQhdTE0m6Gy/i+dt5G+8Myw6BxF2Uxeiy/4D0sAD2gCw+hOk/nvnuk
 OIUT6MKopQuVku7U75qHQGODACHgxwtnGQEePUWnwpq+BgCrqpaN1XScIdNUr2JN+qrxmIUnsdE
 Sp+wj/+V05so8nmK+6NkmzZ6GDRv0MHaf8Z6h8CuA/lbBael6ytojl2m3mg+vGW2UXa/peYu/++
 JpBdg/TMdFzCzMw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The onboard WiFi / BT device, WCN3990, has a simple on-chip PMU, which
further spreads generated voltage. Describe the PMU in the device tree.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts | 65 +++++++++++++++++++----
 1 file changed, 55 insertions(+), 10 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
index 7d81198bc499c..c14a798035d1b 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
@@ -105,6 +105,43 @@ vreg_s4a_1p8: pm8998-smps4 {
 
 		vin-supply = <&vph_pwr>;
 	};
+
+	wcn3990-pmu {
+		compatible = "qcom,wcn3990-pmu";
+
+		pinctrl-0 = <&sw_ctrl_default>;
+		pinctrl-names = "default";
+
+		vddio-supply = <&vreg_s4a_1p8>;
+		vddxo-supply = <&vreg_l7a_1p8>;
+		vddrf-supply = <&vreg_l17a_1p3>;
+		vddch0-supply = <&vreg_l25a_3p3>;
+		vddch1-supply = <&vreg_l23a_3p3>;
+
+		swctrl-gpios = <&pm8998_gpios 3 GPIO_ACTIVE_HIGH>;
+
+		regulators {
+			vreg_pmu_io: ldo0 {
+				regulator-name = "vreg_pmu_io";
+			};
+
+			vreg_pmu_xo: ldo1 {
+				regulator-name = "vreg_pmu_xo";
+			};
+
+			vreg_pmu_rf: ldo2 {
+				regulator-name = "vreg_pmu_rf";
+			};
+
+			vreg_pmu_ch0: ldo3 {
+				regulator-name = "vreg_pmu_ch0";
+			};
+
+			vreg_pmu_ch1: ldo4 {
+				regulator-name = "vreg_pmu_ch1";
+			};
+		};
+	};
 };
 
 &adsp_pas {
@@ -526,6 +563,13 @@ &mss_pil {
 };
 
 &pm8998_gpios {
+	sw_ctrl_default: sw-ctrl-default-state {
+		pins = "gpio3";
+		function = "normal";
+		input-enable;
+		bias-pull-down;
+	};
+
 	volume_up_gpio: pm8998-gpio6-state {
 		pinconf {
 			pins = "gpio6";
@@ -732,10 +776,11 @@ bluetooth {
 		 */
 		firmware-name = "SHIFT/axolotl/crnv21.bin";
 
-		vddio-supply = <&vreg_s4a_1p8>;
-		vddxo-supply = <&vreg_l7a_1p8>;
-		vddrf-supply = <&vreg_l17a_1p3>;
-		vddch0-supply = <&vreg_l25a_3p3>;
+		vddio-supply = <&vreg_pmu_io>;
+		vddxo-supply = <&vreg_pmu_xo>;
+		vddrf-supply = <&vreg_pmu_rf>;
+		vddch0-supply = <&vreg_pmu_ch0>;
+
 		max-speed = <3200000>;
 	};
 };
@@ -790,14 +835,14 @@ &venus {
 };
 
 &wifi {
-	status = "okay";
-
 	vdd-0.8-cx-mx-supply = <&vreg_l5a_0p8>;
-	vdd-1.3-rfa-supply = <&vreg_l17a_1p3>;
-	vdd-1.8-xo-supply = <&vreg_l7a_1p8>;
-	vdd-3.3-ch0-supply = <&vreg_l25a_3p3>;
-	vdd-3.3-ch1-supply = <&vreg_l23a_3p3>;
+	vdd-1.8-xo-supply = <&vreg_pmu_xo>;
+	vdd-1.3-rfa-supply = <&vreg_pmu_rf>;
+	vdd-3.3-ch0-supply = <&vreg_pmu_ch0>;
+	vdd-3.3-ch1-supply = <&vreg_pmu_ch1>;
 
 	qcom,calibration-variant = "shift_axolotl";
 	qcom,snoc-host-cap-8bit-quirk;
+
+	status = "okay";
 };

---
base-commit: e6efabc0afca02efa263aba533f35d90117ab283
change-id: 20260415-axolotl-wifi-9280ef88618a

Best regards,
-- 
David Heidelberg <david@ixit.cz>

