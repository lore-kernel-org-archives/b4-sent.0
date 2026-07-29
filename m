From: David Heidelberg <david@ixit.cz>
Date: Wed, 29 Jul 2026 23:53:10 +0200
Subject: [PATCH 2/2] arm64: dts: qcom: sdm845-shift-axolotl: Add actuator
 for main rear camera
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260729-dw9714v-v1-2-3c479b3cf8c0@ixit.cz>
References: <20260729-dw9714v-v1-0-3c479b3cf8c0@ixit.cz>
In-Reply-To: <20260729-dw9714v-v1-0-3c479b3cf8c0@ixit.cz>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, linux-media@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3122; i=david@ixit.cz;
 h=from:subject:message-id; bh=Bgwnm+VwbiXpfgDQHiNPw5ngK4aeyuOwfsjo/oyygrc=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqanZHrJ+vocGc/y0vRclULT6KsvQavi7HS2mTS
 rWoPC4C6SSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCamp2RwAKCRBgAj/E00kg
 crdHEACgPPy9ygbcQTRbZ7bmT7DS4p8Ffku4EPuzhy+eL50cmhNkynU+wX9A/jBbHICJ72EcGF+
 7lPu5nDadgq3eu+4qAIcBQOmscGBy/GdZ4BQARFHqTnimrzxy6BvZm/4VHVtJMGl+Z3NHTB40oO
 Q7ogqs9vEgXJg/XZ0X8YyWQw16uu0KrhnkJ1EWgmaxWYLFzrvOwH5EWFHfvFjIzu8XVcl3DL027
 XMCElXDmdjJhT90/GJu+qIFOBoFhwLn8eUCoEEBJsz09pn7stDyZliS9KmwQrNW1M75pntTpZB7
 G5zg8Fj2jZEPXJGMS6soBIe7zNX1wNugyjwHzD4aeXV/gbq1+XqTofp+Wqe26jcAm130KPUGMCW
 jO4wkrFAIzS29wE7CWW50qeclFBeMwMg4QZX9aBawA8IL/BUCQ4brniB/mqCYTm6LVoqiytNgDc
 mANWDU3DZr9760PIbcPkyn+zw4v3m7M9cEm/gepi2eqNPdjfn9Aj1rg2UtvW0Df5oNbZg+WgMv2
 Z11qdGLci0Yh79PngTb7oIvZh5bAMTWN1zy+/8vOOBcIlozX7gE6xSB1h52vSgsU2jvw0LBJUiY
 ya9djwJ4/fCYdsm+O9PMxmMXl8qWg8Gi0q7HQDtpZaeLF1LX55+Gmw5Lh/JJM2+b9CNLHKDnXFG
 RQEd3Rn00X2BLFQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Main rear camera uses Dongwoon DW9714V actuator. Add regulator and
actuator node.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts | 61 +++++++++++++++++++++++
 1 file changed, 61 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
index e31c784eff3de..6d0254e205850 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
@@ -81,16 +81,42 @@ ramoops: ramoops@b0000000 {
 	battery: battery {
 		compatible = "simple-battery";
 
 		charge-full-design-microamp-hours = <3850000>;
 		voltage-min-design-microvolt = <3600000>;
 		voltage-max-design-microvolt = <4400000>;
 	};
 
+	/* SGM2036-2.8YUDH4G/TR */
+	cam_bus_2p8: cam-bus-2p8-regulator {
+		compatible = "regulator-fixed";
+
+		regulator-name = "cam_bus_2p8";
+		regulator-min-microvolt = <2800000>;
+		regulator-max-microvolt = <2800000>;
+		regulator-enable-ramp-delay = <100>;
+
+		gpio = <&tlmm 8 GPIO_ACTIVE_HIGH>;
+		enable-active-high;
+
+		pinctrl-0 = <&cam_bus_avdd_default_state>;
+		pinctrl-1 = <&cam_bus_avdd_sleep_state>;
+		pinctrl-names = "default", "sleep";
+
+		vin-supply = <&vreg_bob>;
+
+		/*
+		 * TODO: This node represent bus supply to the cam i2c module.
+		 * Others DT do in similar fashion, but should be addressed
+		 * by the bus-supply in the future
+		 */
+		regulator-always-on;
+	};
+
 	vph_pwr: vph-pwr-regulator {
 		compatible = "regulator-fixed";
 		regulator-name = "vph_pwr";
 		regulator-min-microvolt = <3700000>;
 		regulator-max-microvolt = <3700000>;
 	};
 
 	vreg_s4a_1p8: pm8998-smps4 {
@@ -447,16 +473,36 @@ vreg_s3c_0p6: smps3 {
 };
 
 &cdsp_pas {
 	firmware-name = "qcom/sdm845/SHIFT/axolotl/cdsp.mbn";
 
 	status = "okay";
 };
 
+&camss {
+	vdda-phy-supply = <&vreg_l1a_0p875>;
+	vdda-pll-supply = <&vdda_mipi_csi_1p25>;
+
+	status = "okay";
+};
+
+&cci {
+	status = "okay";
+};
+
+&cci_i2c0 {
+	rear_camera_actuator: actuator@c {
+		compatible = "dongwoon,dw9714v", "dongwoon,dw9714a", "dongwoon,dw9714";
+		reg = <0x0c>;
+
+		vcc-supply = <&vreg_lvs1a_1p8>;
+	};
+};
+
 &gcc {
 	protected-clocks = <GCC_QSPI_CORE_CLK>,
 			   <GCC_QSPI_CORE_CLK_SRC>,
 			   <GCC_QSPI_CNOC_PERIPH_AHB_CLK>,
 			   <GCC_LPASS_Q6_AXI_CLK>,
 			   <GCC_LPASS_SWAY_CLK>;
 };
 
@@ -699,16 +745,31 @@ &slpi_pas {
 	firmware-name = "qcom/sdm845/SHIFT/axolotl/slpi.mbn";
 
 	status = "okay";
 };
 
 &tlmm {
 	gpio-reserved-ranges = <0 4>, <81 4>;
 
+	cam_bus_avdd_default_state: cam-bus-avdd-default-state {
+		pins = "gpio8";
+		function = "gpio";
+		bias-disable;
+		drive-strength = <2>;
+	};
+
+	cam_bus_avdd_sleep_state: cam-bus-avdd-sleep-state {
+		pins = "gpio8";
+		function = "gpio";
+		bias-disable;
+		drive-strength = <2>;
+		output-low;
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
2.53.0

