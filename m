From: Aaron Kling <webgeek1234@gmail.com>
Date: Wed, 11 Mar 2026 01:46:08 -0500
Subject: [PATCH 5/5] arm64: dts: qcom: Add AYN Thor
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260311-ayn-qcs8550-v1-5-fe8b2faad1ea@gmail.com>
References: <20260311-ayn-qcs8550-v1-0-fe8b2faad1ea@gmail.com>
In-Reply-To: <20260311-ayn-qcs8550-v1-0-fe8b2faad1ea@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>, 
 Teguh Sobirin <teguh@sobir.in>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773211585; l=6459;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=oOK/8C/MTUxbcbYjWVAtSByUswN9MzoGI131ulGzL/Y=;
 b=v+6+RHNqAoShiIM7HVwOhqIy2+TAQQlhjH/kxmoGeReTl7WW7E5C6by30lcGNR7Zz5f1yyrd9
 BuVkY49YsG0ANxcu1JIrbW8TP+bn9EbqvlsGRnBKjCDXsOOIag5RbzX
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Teguh Sobirin <teguh@sobir.in>

The AYN Thor is a high-performance Android-based handheld gaming console
powered by the Qualcomm Snapdragon 8 Gen 2 processor featuring dual
AMOLED touchscreens.

Signed-off-by: Teguh Sobirin <teguh@sobir.in>
Co-authored-by: Aaron Kling <webgeek1234@gmail.com>
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 arch/arm64/boot/dts/qcom/Makefile                 |   2 +
 arch/arm64/boot/dts/qcom/qcs8550-ayntec-thor.dtso | 223 ++++++++++++++++++++++
 2 files changed, 225 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/Makefile b/arch/arm64/boot/dts/qcom/Makefile
index 4e4f870ad68e02c620a8c490665285a07a632ecf..427d8449b332caefa93780cb0235e94d24eb5ac5 100644
--- a/arch/arm64/boot/dts/qcom/Makefile
+++ b/arch/arm64/boot/dts/qcom/Makefile
@@ -153,6 +153,8 @@ qcs8550-ayntec-odin2mini-dtbs := qcs8550-ayntec-common.dtb qcs8550-ayntec-odin2m
 dtb-$(CONFIG_ARCH_QCOM)	+= qcs8550-ayntec-odin2mini.dtb
 qcs8550-ayntec-odin2portal-dtbs := qcs8550-ayntec-common.dtb qcs8550-ayntec-odin2portal.dtbo
 dtb-$(CONFIG_ARCH_QCOM)	+= qcs8550-ayntec-odin2portal.dtb
+qcs8550-ayntec-thor-dtbs := qcs8550-ayntec-common.dtb qcs8550-ayntec-thor.dtbo
+dtb-$(CONFIG_ARCH_QCOM)	+= qcs8550-ayntec-thor.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= qcs9100-ride.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= qcs9100-ride-r3.dtb
 
diff --git a/arch/arm64/boot/dts/qcom/qcs8550-ayntec-thor.dtso b/arch/arm64/boot/dts/qcom/qcs8550-ayntec-thor.dtso
new file mode 100644
index 0000000000000000000000000000000000000000..65f2a820d08268671ac5beb959c1d79cde43015d
--- /dev/null
+++ b/arch/arm64/boot/dts/qcom/qcs8550-ayntec-thor.dtso
@@ -0,0 +1,223 @@
+// SPDX-License-Identifier: BSD-3-Clause
+/*
+ * Copyright (c) 2025, Teguh Sobirin.
+ */
+
+#include <dt-bindings/gpio/gpio.h>
+#include <dt-bindings/input/input.h>
+#include <dt-bindings/interrupt-controller/irq.h>
+
+/dts-v1/;
+/plugin/;
+
+&{/} {
+	model = "AYN Thor";
+	compatible = "ayntec,thor", "qcom,qcs8550", "qcom,sm8550";
+
+	gpio-keys {
+		compatible = "gpio-keys";
+
+		pinctrl-0 = <&volume_up_n &key_ayn_n>;
+
+		key-ayn {
+			label = "AYN Key";
+			debounce-interval = <15>;
+			gpios = <&tlmm 41 GPIO_ACTIVE_LOW>;
+			linux,code = <KEY_F24>;
+			linux,can-disable;
+		};
+
+		switch-lid {
+			label = "Hall Lid Sensor";
+			gpios = <&tlmm 17 GPIO_ACTIVE_LOW>;
+			linux,input-type = <EV_SW>;
+			linux,code = <SW_LID>;
+			linux,can-disable;
+			wakeup-source;
+		};
+	};
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
+&i2c4 {
+	#address-cells = <1>;
+	#size-cells = <0>;
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
+	status = "okay";
+
+	#address-cells = <1>;
+	#size-cells = <0>;
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
+	status = "okay";
+
+	#address-cells = <1>;
+	#size-cells = <0>;
+
+	panel@0 {
+		reg = <0>;
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
+	status = "okay";
+};
+
+&mdss_dsi1_out {
+	qcom,te-source = "mdp_vsync_s";
+};
+
+&pm8550_pwm {
+	multi-led {
+		status = "disabled";
+	};
+};
+
+&remoteproc_adsp {
+	firmware-name = "qcom/sm8550/ayntec/thor/adsp.mbn",
+			"qcom/sm8550/ayntec/thor/adsp_dtb.mbn";
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
2.53.0

