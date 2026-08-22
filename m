From: David Heidelberg <david@ixit.cz>
Date: Sat, 22 Aug 2026 07:15:17 +0200
Subject: [PATCH v5 2/3] arm64: dts: qcom: sdm845-shift-axolotl: Add
 actuator for main rear camera
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260822-dw9714v-v5-2-502bc7f43b8f@ixit.cz>
References: <20260822-dw9714v-v5-0-502bc7f43b8f@ixit.cz>
In-Reply-To: <20260822-dw9714v-v5-0-502bc7f43b8f@ixit.cz>
To: Alexander Martinz <amartinz@shiftphones.com>, 
 Bjorn Andersson <andersson@kernel.org>, Conor Dooley <conor+dt@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-media@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3473; i=david@ixit.cz;
 h=from:subject:message-id; bh=gHZ8gqtaNh8wddZIfEMQhnQ9mvQzrc6d6pxFqY4z7/w=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqiTB9hll6ibiYv14aVu5EOY1pp3fu12HOwb31S
 q5V5mB0B8uJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaokwfQAKCRBgAj/E00kg
 cjYnD/96erJ4ScJ/wTXlsolNt5ty2tt5RRHg3h4vpkZOPy32zHfbPyugBtSzmPLqT+eSAa9hKwS
 mRpW7KeFIor6hgZbTz1R0evfxVOhf212TeUHnt/8ejOkXnQOYt6gsYATpcv49ReUGewdIEBXQG0
 dni0cplP5d+c9QDyoB8mlKBvfEmd77Zmiyg4MtDEQCfPrso+Fc8vuQ2ykjXzmUfIYI/NWd42u3/
 WahNdwHGFvCagz+JQ0f38Vppsz76/1xPd5zUJhjP935AWm5ydfo9NnMY9bFRGLIva+q6JBAW/XP
 b7hKkZmLL+oyUliGvJydJbd+rxBA7bbSSjO20Ce9Gv1eH3gWJrLiqpCAXIDRDWRemgecBGAdffB
 pGn4Vzn0IcLTEUz1rnyxi9+ku8bDyQD8rEfnLFteiuJTBOOhaEBmz+mufPiH3mtS9jyjxSzsr6k
 xa5p3p1hB2DVbD+BP9mMx5yvdVAcOOb1GEpDJ/GHmDO7rMgKuQA1Bvihf3D0yrNL4oRN7oeDp6n
 5xhgEeZcc/QUXj53w+CcW9Cg2AXHwTCTwlAatx3EPoyjVx9PVsUX5wDoNAfQE9V87YfL9M7USTh
 u8Y9Xz820W7Xb8iasiomIFNNDV/DREYO8m6oTxVNvROhbWQitumICbzNUZrMrZ4G1zGByY7Hq69
 jS+mGE0XFyquP2A==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Main rear camera uses Dongwoon DW9714V actuator. Add regulator and
actuator node.

Since the actuator sits on the CCI I2C bus, whose 1.8V side is fed by
vreg_lvs1a_1p8 and there is no place to describe that, keep it always-on
for now, until bus-supply exists.

Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts | 50 +++++++++++++++++++++++
 1 file changed, 50 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
index 1b0eaeafbd517..f14fe8e175e96 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
@@ -81,16 +81,34 @@ ramoops: ramoops@b0000000 {
 	battery: battery {
 		compatible = "simple-battery";
 
 		charge-full-design-microamp-hours = <3850000>;
 		voltage-min-design-microvolt = <3600000>;
 		voltage-max-design-microvolt = <4400000>;
 	};
 
+	/* SGM2036-2.8YUDH4G/TR */
+	cam_main_af_2p8: regulator-cam-main-af-2p8 {
+		compatible = "regulator-fixed";
+
+		regulator-name = "cam_main_af_2p8";
+		regulator-min-microvolt = <2800000>;
+		regulator-max-microvolt = <2800000>;
+		regulator-enable-ramp-delay = <100>;
+
+		gpio = <&tlmm 8 GPIO_ACTIVE_HIGH>;
+		enable-active-high;
+
+		pinctrl-0 = <&cam_main_af_default_state>;
+		pinctrl-names = "default";
+
+		vin-supply = <&vreg_bob>;
+	};
+
 	vph_pwr: vph-pwr-regulator {
 		compatible = "regulator-fixed";
 		regulator-name = "vph_pwr";
 		regulator-min-microvolt = <3700000>;
 		regulator-max-microvolt = <3700000>;
 	};
 
 	vreg_s4a_1p8: pm8998-smps4 {
@@ -403,16 +421,23 @@ vreg_l28a_3p0: ldo28 {
 			regulator-min-microvolt = <2856000>;
 			regulator-max-microvolt = <3008000>;
 			regulator-initial-mode = <RPMH_REGULATOR_MODE_HPM>;
 		};
 
 		vreg_lvs1a_1p8: lvs1 {
 			regulator-min-microvolt = <1800000>;
 			regulator-max-microvolt = <1800000>;
+
+			/*
+			 * Supplies the 1.8V side of the CCI I2C level
+			 * shifter; keep enabled until a generic
+			 * bus-supply property exists.
+			 */
+			regulator-always-on;
 		};
 
 		vreg_lvs2a_1p8: lvs2 {
 			regulator-min-microvolt = <1800000>;
 			regulator-max-microvolt = <1800000>;
 		};
 	};
 
@@ -441,16 +466,34 @@ regulators-2 {
 
 		vreg_s3c_0p6: smps3 {
 			regulator-min-microvolt = <600000>;
 			regulator-max-microvolt = <600000>;
 		};
 	};
 };
 
+&cci {
+	status = "okay";
+};
+
+&cci_i2c0 {
+	/* sony,imx519 @ 1a */
+
+	/* rear camera actuator */
+	camera-lens@c {
+		compatible = "dongwoon,dw9714v",
+			     "dongwoon,dw9714a",
+			     "dongwoon,dw9714";
+		reg = <0x0c>;
+
+		vcc-supply = <&cam_main_af_2p8>;
+	};
+};
+
 &cdsp_pas {
 	firmware-name = "qcom/sdm845/SHIFT/axolotl/cdsp.mbn";
 
 	status = "okay";
 };
 
 &gcc {
 	protected-clocks = <GCC_QSPI_CORE_CLK>,
@@ -699,16 +742,23 @@ &slpi_pas {
 	firmware-name = "qcom/sdm845/SHIFT/axolotl/slpi.mbn";
 
 	status = "okay";
 };
 
 &tlmm {
 	gpio-reserved-ranges = <0 4>, <81 4>;
 
+	cam_main_af_default_state: cam-main-af-default-state {
+		pins = "gpio8";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+	};
+
 	sdc2_default_state: sdc2-default-state {
 		clk-pins {
 			pins = "sdc2_clk";
 			drive-strength = <16>;
 			bias-disable;
 		};
 
 		cmd-pins {

-- 
2.55.0

