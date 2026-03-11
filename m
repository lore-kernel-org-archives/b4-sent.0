From: Aaron Kling <webgeek1234@gmail.com>
Date: Wed, 11 Mar 2026 12:44:39 -0500
Subject: [PATCH v2 3/5] arm64: dts: qcom: Add AYN Odin 2 Mini
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260311-ayn-qcs8550-v2-3-e66986e0f0cb@gmail.com>
References: <20260311-ayn-qcs8550-v2-0-e66986e0f0cb@gmail.com>
In-Reply-To: <20260311-ayn-qcs8550-v2-0-e66986e0f0cb@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>, 
 Teguh Sobirin <teguh@sobir.in>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773251087; l=4783;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=xcEVqKMPSvcHvwAORvrNa8rHTg1+vl1NPzo/rpqSz8g=;
 b=umcND7W24lwLA+Z3PCRmZp7Yj2X2lBqEJmlVlYCD9cY44BS/zFpcni6OXtGpFU7195n8MEWAk
 MoFrhupKFJZCvmkwn9DRZ5JUfm0xxmPyuWaSPJ4yx+Vxh3Im06pYybO
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Teguh Sobirin <teguh@sobir.in>

The AYN Odin 2 Mini is a high-performance Android-based handheld gaming
console powered by the Qualcomm Snapdragon 8 Gen 2 processor featuring a
5-inch mini-led touchscreen.

Signed-off-by: Teguh Sobirin <teguh@sobir.in>
Co-developed-by: Aaron Kling <webgeek1234@gmail.com>
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 arch/arm64/boot/dts/qcom/Makefile                  |   2 +
 .../boot/dts/qcom/qcs8550-ayntec-odin2mini.dtso    | 147 +++++++++++++++++++++
 2 files changed, 149 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/Makefile b/arch/arm64/boot/dts/qcom/Makefile
index 5bb88dd7a31bbd8ee7078a880056cc1f35be494e..3dd5db42713b1d468d029518178a9df33af991c9 100644
--- a/arch/arm64/boot/dts/qcom/Makefile
+++ b/arch/arm64/boot/dts/qcom/Makefile
@@ -164,6 +164,8 @@ qcs8300-ride-el2-dtbs := qcs8300-ride.dtb monaco-el2.dtbo
 dtb-$(CONFIG_ARCH_QCOM)	+= qcs8300-ride-el2.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= qcs8550-aim300-aiot.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= qcs8550-ayntec-common.dtb
+qcs8550-ayntec-odin2mini-dtbs := qcs8550-ayntec-common.dtb qcs8550-ayntec-odin2mini.dtbo
+dtb-$(CONFIG_ARCH_QCOM)	+= qcs8550-ayntec-odin2mini.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= qcs9100-ride.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= qcs9100-ride-r3.dtb
 
diff --git a/arch/arm64/boot/dts/qcom/qcs8550-ayntec-odin2mini.dtso b/arch/arm64/boot/dts/qcom/qcs8550-ayntec-odin2mini.dtso
new file mode 100644
index 0000000000000000000000000000000000000000..60b402a6b98857f56b04c44b053d5a46faf8c0a6
--- /dev/null
+++ b/arch/arm64/boot/dts/qcom/qcs8550-ayntec-odin2mini.dtso
@@ -0,0 +1,147 @@
+// SPDX-License-Identifier: BSD-3-Clause
+/*
+ * Copyright (c) 2025, Teguh Sobirin.
+ */
+
+#include <dt-bindings/gpio/gpio.h>
+#include <dt-bindings/interrupt-controller/irq.h>
+
+/dts-v1/;
+/plugin/;
+
+&{/} {
+	model = "AYN Odin 2 Mini";
+	compatible = "ayntec,odin2mini", "qcom,qcs8550", "qcom,sm8550";
+
+	hdmi-out {
+		compatible = "hdmi-connector";
+		type = "d";
+		hpd-gpios = <&tlmm 9 GPIO_ACTIVE_HIGH>;
+		hdmi-pwr-supply = <&vdd_hdmi_1v8>;
+
+		port {
+			hdmi_con: endpoint {
+				remote-endpoint = <&lt8912_out>;
+			};
+		};
+	};
+
+	vcc_hdmi_1v8: vcc-hdmi-1v8-regulator {
+		compatible = "regulator-fixed";
+		regulator-name = "vcc_hdmi_1v8";
+
+		regulator-min-microvolt = <1800000>;
+		regulator-max-microvolt = <1800000>;
+
+		gpio = <&tlmm 10 GPIO_ACTIVE_HIGH>;
+		enable-active-high;
+	};
+
+	vdd_bl_5v0: vdd-bl-5v0-regulator {
+		compatible = "regulator-fixed";
+		regulator-name = "vdd_bl_5v0";
+
+		regulator-min-microvolt = <5000000>;
+		regulator-max-microvolt = <5000000>;
+
+		gpio = <&tlmm 55 GPIO_ACTIVE_HIGH>;
+		enable-active-high;
+	};
+
+	vdd_disp_2v8: vdd-disp-2v8-regulator {
+		compatible = "regulator-fixed";
+		regulator-name = "vdd_disp_2v8";
+
+		regulator-min-microvolt = <2800000>;
+		regulator-max-microvolt = <2800000>;
+
+		gpio = <&tlmm 142 GPIO_ACTIVE_HIGH>;
+		enable-active-high;
+	};
+
+	vdd_hdmi_1v8: vdd-hdmi-1v8-regulator {
+		compatible = "regulator-fixed";
+		regulator-name = "vdd_hdmi_1v8";
+
+		regulator-min-microvolt = <1800000>;
+		regulator-max-microvolt = <1800000>;
+
+		gpio = <&tlmm 6 GPIO_ACTIVE_HIGH>;
+		enable-active-high;
+	};
+};
+
+&i2c_hub_0 {
+	clock-frequency = <100000>;
+	status = "okay";
+
+	#address-cells = <1>;
+	#size-cells = <0>;
+
+	lt8912_codec: hdmi-bridge@48 {
+		compatible = "lontium,lt8912b";
+		reg = <0x48> ;
+
+		reset-gpios = <&tlmm 7 GPIO_ACTIVE_LOW>;
+
+		vdd-supply = <&vdd_hdmi_1v8>;
+		vccmipirx-supply = <&vcc_hdmi_1v8>;
+		vccsysclk-supply = <&vcc_hdmi_1v8>;
+		vcclvdstx-supply = <&vcc_hdmi_1v8>;
+		vcchdmitx-supply = <&vcc_hdmi_1v8>;
+		vcclvdspll-supply = <&vcc_hdmi_1v8>;
+		vcchdmipll-supply = <&vcc_hdmi_1v8>;
+
+		ports {
+			#address-cells = <1>;
+			#size-cells = <0>;
+
+			port@0 {
+				reg = <0>;
+
+				hdmi_out_in: endpoint {
+					data-lanes = <1 2 3 4>;
+					remote-endpoint = <&mdss_dsi0_out>;
+				};
+			};
+
+			port@1 {
+				reg = <1>;
+
+				lt8912_out: endpoint {
+					remote-endpoint = <&hdmi_con>;
+				};
+			};
+		};
+	};
+};
+
+&mdss_dsi0 {
+	vdda-supply = <&vreg_l3e_1p2>;
+	status = "okay";
+};
+
+&mdss_dsi0_out {
+	remote-endpoint = <&hdmi_out_in>;
+	data-lanes = <0 1 2 3>;
+};
+
+&mdss_dsi0_phy {
+	vdds-supply = <&vreg_l1e_0p88>;
+	status = "okay";
+};
+
+&remoteproc_adsp {
+	firmware-name = "qcom/sm8550/ayntec/odin2mini/adsp.mbn",
+			"qcom/sm8550/ayntec/odin2mini/adsp_dtb.mbn";
+	status = "okay";
+};
+
+&spk_amp_l {
+	firmware-name = "qcom/sm8550/ayntec/odin2mini/aw883xx_acf.bin";
+};
+
+&spk_amp_r {
+	firmware-name = "qcom/sm8550/ayntec/odin2mini/aw883xx_acf.bin";
+};
+

-- 
2.53.0

