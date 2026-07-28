From: Aaron Kling <webgeek1234@gmail.com>
Date: Mon, 27 Jul 2026 19:20:14 -0500
Subject: [PATCH v9 6/6] arm64: dts: qcom: Add AYN Thor
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260727-ayn-qcs8550-v9-6-e3db456e10e5@gmail.com>
References: <20260727-ayn-qcs8550-v9-0-e3db456e10e5@gmail.com>
In-Reply-To: <20260727-ayn-qcs8550-v9-0-e3db456e10e5@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>, 
 Teguh Sobirin <teguh@sobir.in>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785198012; l=7059;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=fy7O2f4hARL19dvp0RORykEjV1fC0UR3ZItnFH8IsXQ=;
 b=ZjwN2d0ECdDqp5PsozImAq0gYEWAh1yxq+DxI21Ev74o+Yoxl9EmKXcXmrMMioN0E2uyvyeft
 CHfAugbOuNKBZLoqiJcJg+oZobxrP50VuC8Lol8rvqnb8TL0pYiT3T5
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Teguh Sobirin <teguh@sobir.in>

The AYN Thor is a high-performance Android-based handheld gaming console
powered by the Qualcomm Snapdragon 8 Gen 2 processor featuring dual
AMOLED touchscreens.

Signed-off-by: Teguh Sobirin <teguh@sobir.in>
Co-developed-by: Aaron Kling <webgeek1234@gmail.com>
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 arch/arm64/boot/dts/qcom/Makefile                |   1 +
 arch/arm64/boot/dts/qcom/qcs8550-ayntec-thor.dts | 250 +++++++++++++++++++++++
 2 files changed, 251 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/Makefile b/arch/arm64/boot/dts/qcom/Makefile
index 0f71d5bd3efaa..6d8205b82032a 100644
--- a/arch/arm64/boot/dts/qcom/Makefile
+++ b/arch/arm64/boot/dts/qcom/Makefile
@@ -194,6 +194,7 @@ dtb-$(CONFIG_ARCH_QCOM)	+= qcs8300-ride-el2.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= qcs8550-aim300-aiot.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= qcs8550-ayntec-odin2mini.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= qcs8550-ayntec-odin2portal.dtb
+dtb-$(CONFIG_ARCH_QCOM)	+= qcs8550-ayntec-thor.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= qcs8550-rb5gen2.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= qcs9100-ride.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= qcs9100-ride-r3.dtb
diff --git a/arch/arm64/boot/dts/qcom/qcs8550-ayntec-thor.dts b/arch/arm64/boot/dts/qcom/qcs8550-ayntec-thor.dts
new file mode 100644
index 0000000000000..7683911914be3
--- /dev/null
+++ b/arch/arm64/boot/dts/qcom/qcs8550-ayntec-thor.dts
@@ -0,0 +1,250 @@
+// SPDX-License-Identifier: BSD-3-Clause
+/*
+ * Copyright (c) 2025, Teguh Sobirin.
+ */
+
+/dts-v1/;
+
+#include <dt-bindings/gpio/gpio.h>
+#include <dt-bindings/input/input.h>
+#include <dt-bindings/interrupt-controller/irq.h>
+#include "qcs8550-ayntec-common.dtsi"
+
+&{/} {
+	model = "AYN Thor";
+	compatible = "ayntec,thor", "qcom,qcs8550", "qcom,sm8550";
+
+	vdd_bl_5v0: vdd-bl-5v0-regulator {
+		compatible = "regulator-fixed";
+		regulator-name = "vdd_bl_5v0";
+
+		regulator-min-microvolt = <5000000>;
+		regulator-max-microvolt = <5000000>;
+
+		gpio = <&tlmm 52 GPIO_ACTIVE_HIGH>;
+		enable-active-high;
+	};
+
+	vdd_disp_1v8: vdd-disp-1v8-regulator {
+		compatible = "regulator-fixed";
+		regulator-name = "vdd_disp_1v8";
+
+		regulator-min-microvolt = <1800000>;
+		regulator-max-microvolt = <1800000>;
+
+		gpio = <&tlmm 70 GPIO_ACTIVE_HIGH>;
+		enable-active-high;
+	};
+
+	vdd_disp1_2v8: vdd-disp1-2v8-regulator {
+		compatible = "regulator-fixed";
+		regulator-name = "vdd_disp1_2v8";
+
+		regulator-min-microvolt = <2800000>;
+		regulator-max-microvolt = <2800000>;
+
+		gpio = <&tlmm 142 GPIO_ACTIVE_HIGH>;
+		enable-active-high;
+	};
+
+	vdd_disp2_2v8: vdd-disp2-2v8-regulator {
+		compatible = "regulator-fixed";
+		regulator-name = "vdd_disp2_2v8";
+
+		regulator-min-microvolt = <2800000>;
+		regulator-max-microvolt = <2800000>;
+
+		gpio = <&tlmm 143 GPIO_ACTIVE_HIGH>;
+		enable-active-high;
+	};
+
+	vdd_ts_3v0: vdd-ts-3v0-regulator {
+		compatible = "regulator-fixed";
+		regulator-name = "vdd_ts_3v0";
+
+		regulator-min-microvolt = <3000000>;
+		regulator-max-microvolt = <3000000>;
+
+		gpio = <&tlmm 144 GPIO_ACTIVE_HIGH>;
+		enable-active-high;
+	};
+
+	vdd_ts_1v8: vdd-ts-1v8-regulator {
+		compatible = "regulator-fixed";
+		regulator-name = "vdd_ts_1v8";
+
+		regulator-min-microvolt = <1800000>;
+		regulator-max-microvolt = <1800000>;
+
+		gpio = <&tlmm 102 GPIO_ACTIVE_HIGH>;
+		enable-active-high;
+	};
+};
+
+&display_panel {
+	compatible = "ayntec,thor-panel-top", "chipone,icna3520";
+
+	pinctrl-0 = <&dsi_s_rst_active>, <&dsi_s_te_active>;
+	pinctrl-1 = <&dsi_s_rst_suspend>, <&dsi_s_te_suspend>;
+	pinctrl-names = "default", "sleep";
+
+	vdd-supply = <&vreg_l11b_1p2>;
+	vddio-supply = <&vreg_l12b_1p8>;
+	vci-supply = <&vreg_l14b_3p2>;
+	disp-supply = <&vdd_disp1_2v8>;
+	blvdd-supply = <&vdd_bl_5v0>;
+
+	reset-gpios = <&tlmm 137 GPIO_ACTIVE_LOW>;
+
+	rotation = <90>;
+};
+
+&gpio_keys {
+	pinctrl-0 = <&volume_up_n &key_ayn_n>;
+
+	key-ayn {
+		label = "AYN Key";
+		debounce-interval = <15>;
+		gpios = <&tlmm 41 GPIO_ACTIVE_LOW>;
+		linux,code = <KEY_F24>;
+		linux,can-disable;
+	};
+
+	switch-lid {
+		label = "Hall Lid Sensor";
+		gpios = <&tlmm 17 GPIO_ACTIVE_LOW>;
+		linux,input-type = <EV_SW>;
+		linux,code = <SW_LID>;
+		linux,can-disable;
+		wakeup-source;
+	};
+};
+
+&i2c4 {
+	clock-frequency = <400000>;
+
+	status = "okay";
+
+	touchscreen@38 {
+		compatible = "focaltech,ft5426";
+		reg = <0x38>;
+
+		interrupt-parent = <&tlmm>;
+		interrupts = <25 IRQ_TYPE_EDGE_FALLING>;
+
+		reset-gpios = <&tlmm 24 GPIO_ACTIVE_LOW>;
+
+		vcc-supply = <&vreg_l14b_3p2>;
+		iovcc-supply = <&vreg_l12b_1p8>;
+
+		pinctrl-0 = <&ts_p_rst_default &ts_p_int_default>;
+		pinctrl-1 = <&ts_p_rst_sleep &ts_p_int_sleep>;
+		pinctrl-names = "default", "sleep";
+
+		touchscreen-size-x = <1080>;
+		touchscreen-size-y = <1920>;
+		touchscreen-swapped-x-y;
+		touchscreen-inverted-x;
+	};
+};
+
+&i2c_hub_3 {
+	clock-frequency = <100000>;
+
+	status = "okay";
+
+	touchscreen@38 {
+		compatible = "focaltech,ft5452";
+		reg = <0x38>;
+
+		interrupt-parent = <&tlmm>;
+		interrupts = <15 IRQ_TYPE_EDGE_FALLING>;
+
+		reset-gpios = <&tlmm 14 GPIO_ACTIVE_LOW>;
+
+		vcc-supply = <&vdd_ts_3v0>;
+		iovcc-supply = <&vdd_ts_1v8>;
+
+		pinctrl-0 = <&ts_s_rst_default &ts_s_int_default>;
+		pinctrl-1 = <&ts_s_rst_sleep &ts_s_int_sleep>;
+		pinctrl-names = "default", "sleep";
+
+		touchscreen-size-x = <1080>;
+		touchscreen-size-y = <1240>;
+		touchscreen-swapped-x-y;
+		touchscreen-inverted-x;
+	};
+};
+
+&mdss_dsi0 {
+	vdda-supply = <&vreg_l3e_1p2>;
+
+	status = "okay";
+
+	panel@0 {
+		reg = <0>;
+		compatible = "ayntec,thor-panel-bottom", "chipwealth,ch13726a";
+
+		pinctrl-0 = <&dsi_p_rst_active>, <&dsi_p_te_active>;
+		pinctrl-1 = <&dsi_p_rst_suspend>, <&dsi_p_te_suspend>;
+		pinctrl-names = "default", "sleep";
+
+		vdd1v2-supply = <&vreg_l11b_1p2>;
+		vddio-supply = <&vdd_disp_1v8>;
+		vdd-supply = <&vreg_l13b_3p0>;
+		avdd-supply = <&vdd_disp2_2v8>;
+
+		reset-gpios = <&tlmm 133 GPIO_ACTIVE_LOW>;
+
+		rotation = <90>;
+
+		port {
+			panel0_in: endpoint {
+				remote-endpoint = <&mdss_dsi0_out>;
+			};
+		};
+	};
+};
+
+&mdss_dsi0_out {
+	remote-endpoint = <&panel0_in>;
+	data-lanes = <0 1 2 3>;
+};
+
+&mdss_dsi0_phy {
+	vdds-supply = <&vreg_l1e_0p88>;
+
+	status = "okay";
+};
+
+&mdss_dsi1_out {
+	qcom,te-source = "mdp_vsync_s";
+};
+
+&pm8550_multi_led {
+	status = "disabled";
+};
+
+&remoteproc_adsp {
+	firmware-name = "qcom/sm8550/ayntec/thor/adsp.mbn",
+			"qcom/sm8550/ayntec/thor/adsp_dtb.mbn";
+
+	status = "okay";
+};
+
+&spk_amp_l {
+	firmware-name = "qcom/sm8550/ayntec/thor/aw883xx_acf.bin";
+};
+
+&spk_amp_r {
+	firmware-name = "qcom/sm8550/ayntec/thor/aw883xx_acf.bin";
+};
+
+&tlmm {
+	key_ayn_n: key-ayn-n-state {
+		pins = "gpio41";
+		function = "gpio";
+		bias-pull-up;
+		output-disable;
+	};
+};

-- 
2.54.0

