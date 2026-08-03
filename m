From: David Heidelberg <david@ixit.cz>
Date: Mon, 03 Aug 2026 11:50:26 +0200
Subject: [PATCH v3 2/2] arm64: dts: qcom: sdm845-shift-axolotl: Add
 actuator for main rear camera
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260803-dw9714v-v3-2-8e10278dcd0d@ixit.cz>
References: <20260803-dw9714v-v3-0-8e10278dcd0d@ixit.cz>
In-Reply-To: <20260803-dw9714v-v3-0-8e10278dcd0d@ixit.cz>
To: Alexander Martinz <amartinz@shiftphones.com>, 
 Bjorn Andersson <andersson@kernel.org>, Conor Dooley <conor+dt@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-media@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3383; i=david@ixit.cz;
 h=from:subject:message-id; bh=GdbUfwJ10fR0lW+Kb3dZndvP8ed4Y2Pebi8vBrKB8vI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqcGRi+byvi1KOnXzLHdi6nBj57QwdrGOGk38TI
 O9opNaHpaSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCanBkYgAKCRBgAj/E00kg
 cqX8D/9Z3QqZcZZeysix/ECfwWDAXO6gliMGZ5we15gYTZiodb/WYqG3ychau/5VWMnwzbB8DsX
 iW25iaenEST9kDQD3jqLsRlzxmLtaIhq04wfzGERxGgJYkkW1QKDXmT4mygqqcneWXbhMxixNtn
 SuO/LfeuaUfi9EFvC6vsTa7N/jqzh/IdDWNxU0KphZTQ+Fv6IUQdyvsin/yXcMS0r4xQGRBpQfI
 89SSdmOGqhm07Uqv2qNEj91cCvTlfMG8I3TNogxT950DnMYT6AP/j05c3d5u5SmOSyd/SD6QVfE
 urMu4pgX2I6cOu3onE7bPsSBJ0dEpzbbqiJlByVL1HV+859FP4Yfah49kvUCIzZ88ameiy8/vmn
 3lGLZinpeXsWyT+A+KgdfOqayGR8lpRqOf30gh7bC6Y2fc6ho0Wb/gKyesF1rcHnF55ABVzTWxH
 RY5UmrW9jcY1yXbnntsRpeUWqvhpIjfUbykTQC56FDMNi82AEFCLGyn3L6I2bpjaEyTFfJjcKJs
 nUT1Gg8LVJ86ZB5eGi/sMjzFnbtVmiSvqUdVUGG1IiO6JbjLA+mUdyeW7WRkKJlIDBR7Y8aZEPS
 Hdglb50g0nqZgXUNCSkkxtk6Izj5+O1rGJxbxviBfK3w5Fds+2mXlwQBrf/TEeAY7y8hmyAgj/3
 Y3xIWHTHcJ1a7tw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Main rear camera uses Dongwoon DW9714V actuator. Add regulator and
actuator node.

Since the actuator sits on the CCI I2C bus, whose 1.8V side is fed by
vreg_lvs1a_1p8 and there is no place to describe that, keep it always-on
for now, until bus-supply exists.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts | 48 +++++++++++++++++++++++
 1 file changed, 48 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
index e31c784eff3de..358ce1930d4e1 100644
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
 
@@ -441,16 +466,32 @@ regulators-2 {
 
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
+	/* main camera actuator */
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
@@ -699,16 +740,23 @@ &slpi_pas {
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

