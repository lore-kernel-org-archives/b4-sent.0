From: Muzaffer Kadir <muzafferkadir@mainlining.org>
Date: Sat, 12 Sep 2026 11:39:29 +0300
Subject: [PATCH RFC 20/20] arm64: dts: qcom: generalmobile-shamrock: new
 device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260912-msm8952-initial-support-v1-20-0e742578b524@mainlining.org>
References: <20260912-msm8952-initial-support-v1-0-0e742578b524@mainlining.org>
In-Reply-To: <20260912-msm8952-initial-support-v1-0-0e742578b524@mainlining.org>
To: Bjorn Andersson <andersson@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Srinivas Kandagatla <srini@kernel.org>, 
 Ulf Hansson <ulfh@kernel.org>, Konrad Dybcio <konradybcio@kernel.org>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, Lee Jones <lee@kernel.org>, 
 Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Robert Marko <robimarko@gmail.com>, Guru Das Srinagesh <linux@gurudas.dev>, 
 Amit Kucheria <amitk@kernel.org>, Thara Gopinath <thara.gopinath@gmail.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Kees Cook <kees@kernel.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: David Heidelberg <david@ixit.cz>, Dang Huynh <danct12@riseup.net>, 
 phone-devel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-clk@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-mmc@vger.kernel.org, 
 iommu@lists.linux.dev, mfd@lists.linux.dev, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, Krzysztof Kozlowski <krzk@kernel.org>, 
 linux-pm@vger.kernel.org, linux-input@vger.kernel.org, 
 Muzaffer Kadir <muzafferkadir@mainlining.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789202354; l=11139;
 i=muzafferkadir@mainlining.org; s=20260816; h=from:subject:message-id;
 bh=LCzevTgTqTbZMUx77r9xIrvOtg8agw+pOgdFFe2F8OI=;
 b=Zt9U45CXeRUso7gHItINI29ZBZOM5SeFnBW3fRl0fEdvMHnCzOsLAFiDs/Z9UjEJN+i3gnO7N
 59fC6iGHvgLDg0IJ5VExg/sBHEA0CYPCjzIh29kQVHT7ldOlVDmeTqM
X-Developer-Key: i=muzafferkadir@mainlining.org; a=ed25519;
 pk=4zkv4suQ3cYcO4Z7CrV8JSSjEGLBGepUtvQCFjgnYIU=
X-Endpoint-Received: by B4 Relay for muzafferkadir@mainlining.org/20260816 with auth_id=954
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add General Mobile Shamrock (GM 5 Plus).
Shamrock is designed similar to L9300.
Downstream reference is [1].

[1] https://github.com/Asderdd/android_kernel_generalmobile_shamrock/blob/cm-14.1/arch/arm/boot/dts/qcom/msm8952-l9300.dtsi

Signed-off-by: Muzaffer Kadir <muzafferkadir@mainlining.org>
---
 arch/arm64/boot/dts/qcom/Makefile                  |   1 +
 .../dts/qcom/msm8952-generalmobile-shamrock.dts    | 426 +++++++++++++++++++++
 2 files changed, 427 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/Makefile b/arch/arm64/boot/dts/qcom/Makefile
index d6547fb18edf..3cc2dfb09116 100644
--- a/arch/arm64/boot/dts/qcom/Makefile
+++ b/arch/arm64/boot/dts/qcom/Makefile
@@ -125,6 +125,7 @@ dtb-$(CONFIG_ARCH_QCOM)	+= msm8939-samsung-a7.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= msm8939-sony-xperia-kanuti-tulip.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= msm8939-wingtech-wt82918.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= msm8939-wingtech-wt82918hd.dtb
+dtb-$(CONFIG_ARCH_QCOM)	+= msm8952-generalmobile-shamrock.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= msm8953-flipkart-rimob.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= msm8953-motorola-potter.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= msm8953-xiaomi-daisy.dtb
diff --git a/arch/arm64/boot/dts/qcom/msm8952-generalmobile-shamrock.dts b/arch/arm64/boot/dts/qcom/msm8952-generalmobile-shamrock.dts
new file mode 100644
index 000000000000..22723b62d3d6
--- /dev/null
+++ b/arch/arm64/boot/dts/qcom/msm8952-generalmobile-shamrock.dts
@@ -0,0 +1,426 @@
+// SPDX-License-Identifier: GPL-2.0-only
+
+/dts-v1/;
+
+#include "msm8952.dtsi"
+#include "pm8950.dtsi"
+#include "pmi8950.dtsi"
+#include <dt-bindings/gpio/gpio.h>
+#include <dt-bindings/leds/common.h>
+
+/ {
+	model = "General Mobile GM 5 Plus (shamrock)";
+	compatible = "generalmobile,shamrock", "qcom,msm8952";
+	qcom,msm-id = <QCOM_ID_MSM8952 0x0>;
+	qcom,board-id = <QCOM_BOARD_ID_QRD 1>;
+	chassis-type = "handset";
+
+	aliases {
+		mmc0 = &sdhc_1; /* SDC1 eMMC slot */
+		mmc1 = &sdhc_2; /* SDC2 SD card slot */
+		serial0 = &blsp1_uart2;
+	};
+
+	chosen {
+		stdout-path = "serial0:115200n8";
+
+		framebuffer {
+			compatible = "simple-framebuffer";
+			memory-region = <&cont_splash_mem>;
+
+			width = <1080>;
+			height = <1920>;
+			stride = <(1080 * 3)>;
+			format = "r8g8b8";
+
+			power-domains = <&gcc MDSS_GDSC>;
+
+			clocks = <&gcc GCC_MDSS_AHB_CLK>,
+					 <&gcc GCC_MDSS_AXI_CLK>,
+					 <&gcc GCC_MDSS_VSYNC_CLK>,
+					 <&gcc GCC_MDSS_MDP_CLK>,
+					 <&gcc GCC_MDSS_BYTE0_CLK>,
+					 <&gcc GCC_MDSS_PCLK0_CLK>,
+					 <&gcc GCC_MDSS_ESC0_CLK>;
+		};
+	};
+
+	reserved-memory {
+		cont_splash_mem: cont-splash@83200000 {
+			reg = <0x0 0x83200000 0x0 (1080 * 1920 * 3)>;
+			no-map;
+		};
+	};
+
+	gpio-keys {
+		compatible = "gpio-keys";
+
+		pinctrl-0 = <&gpio_hall_sensor_default>, <&gpio_keys_default>;
+		pinctrl-names = "default";
+
+		event-hall-sensor {
+			label = "Hall Effect Sensor";
+			gpios = <&tlmm 46 GPIO_ACTIVE_LOW>;
+			linux,input-type = <EV_SW>;
+			linux,code = <SW_LID>;
+			linux,can-disable;
+			wakeup-source;
+		};
+
+		button-volume-up {
+			label = "Volume Up";
+			gpios = <&tlmm 85 GPIO_ACTIVE_LOW>;
+			linux,code = <KEY_VOLUMEUP>;
+			debounce-interval = <15>;
+			wakeup-source;
+		};
+	};
+
+	/* Front Flash */
+	flash-led-controller {
+		compatible = "sgmicro,sgm3140";
+
+		enable-gpios = <&tlmm 33 GPIO_ACTIVE_HIGH>;
+		flash-gpios = <&tlmm 128 GPIO_ACTIVE_HIGH>;
+
+		pinctrl-0 = <&front_flash_default>;
+		pinctrl-names = "default";
+
+		front_flash_led: led {
+			function = LED_FUNCTION_FLASH;
+			color = <LED_COLOR_ID_WHITE>;
+			flash-max-microamp = <1000000>;
+			led-max-microamp = <625000>;
+			flash-max-timeout-us = <1280000>;
+		};
+	};
+
+	battery: battery {
+		compatible = "simple-battery";
+
+		charge-term-current-microamp = <100000>;
+		charge-full-design-microamp-hours = <3100000>;
+		constant-charge-current-max-microamp = <3000000>;
+		constant-charge-voltage-max-microvolt = <4400000>;
+		voltage-min-design-microvolt = <3400000>;
+		voltage-max-design-microvolt = <4400000>;
+	};
+
+	vph_pwr: regulator-vph-pwr {
+		compatible = "regulator-fixed";
+		regulator-name = "vph-pwr";
+		regulator-always-on;
+		regulator-boot-on;
+	};
+
+	multi-led {
+		compatible = "leds-group-multicolor";
+		color = <LED_COLOR_ID_RGB>;
+		function = LED_FUNCTION_INDICATOR;
+		leds = <&red_status>, <&green_status>, <&blue_status>;
+	};
+
+};
+
+&blsp2_i2c1 {
+	status = "okay";
+
+	/* FUSB301 @25 USB-C Controller */
+
+	tpa6130a2: tpa6130a2@60 {
+		compatible = "ti,tpa6130a2";
+		pinctrl-0 = <&tpa6130a2_default>;
+		pinctrl-names = "default";
+		reg = <0x60>;
+		power-gpios = <&tlmm 61 GPIO_ACTIVE_HIGH>;
+		Vdd-supply = <&pm8950_l22>;
+	};
+
+	tusb320: tusb320@67 {
+		compatible = "ti,tusb320";
+		reg = <0x67>;
+		interrupts-extended = <&tlmm 45 IRQ_TYPE_EDGE_RISING>;
+	};
+
+	led-controller@68 {
+		compatible = "si-en,sn3193";
+		reg = <0x68>;
+
+		shutdown-gpios = <&tlmm 68 GPIO_ACTIVE_HIGH>;
+
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		red_status: led@1 {
+			reg = <1>;
+			label = "red:status";
+			led-max-microamp = <17500>;
+		};
+
+		green_status: led@2 {
+			reg = <2>;
+			label = "green:status";
+			led-max-microamp = <17500>;
+		};
+
+		blue_status: led@3 {
+			reg = <3>;
+			label = "blue:status";
+			led-max-microamp = <17500>;
+		};
+	};
+};
+
+&blsp1_i2c2 {
+	status = "okay";
+	/* SMB1351 @1d charger */
+	/* wsa881x-i2c @e @44 @f @45 audio amplifier */
+};
+
+&blsp1_i2c3 {
+	status = "okay";
+
+	/* himax,852x@48 Touchscreen */
+
+	touchscreen@5d {
+		compatible = "goodix,gt970", "goodix,gt911";
+		reg = <0x5d>;
+		interrupts-extended = <&tlmm 65 IRQ_TYPE_EDGE_FALLING>;
+		irq-gpios = <&tlmm 65 GPIO_ACTIVE_HIGH>;
+		reset-gpios = <&tlmm 64 GPIO_ACTIVE_HIGH>;
+		AVDD28-supply = <&pm8950_l10>;
+		VDDIO-supply = <&pm8950_l6>;
+
+		pinctrl-0 = <&touchscreen_default>;
+		pinctrl-names = "default";
+
+		touchscreen-size-x = <1080>;
+		touchscreen-size-y = <1920>;
+	};
+};
+
+&pm8950_resin {
+	linux,code = <KEY_VOLUMEDOWN>;
+
+	status = "okay";
+};
+
+&sdhc_1 {
+	vmmc-supply = <&pm8950_l8>;
+	vqmmc-supply = <&pm8950_l5>;
+
+	status = "okay";
+};
+
+&sdhc_2 {
+	cd-gpios = <&tlmm 67 GPIO_ACTIVE_HIGH>;
+	vmmc-supply = <&pm8950_l11>;
+	vqmmc-supply = <&pm8950_l12>;
+
+	status = "okay";
+};
+
+&sdc2_cd_on {
+	/delete-property/ bias-pull-up;
+	bias-disable;
+};
+
+&pmi8950_wled {
+	qcom,enabled-strings = <0 1>;
+	qcom,current-limit-microamp = <30000>;
+	qcom,ovp-millivolt = <29500>;
+	qcom,external-pfet;
+
+	status = "okay";
+};
+
+&ramoops_mem {
+	status = "okay";
+};
+
+&adsp {
+	status = "okay";
+};
+
+&lpass_mem {
+	status = "okay";
+};
+
+&pm8950_spmi_regulators {
+	// PM8950 S5 + S6 = VDD_APC supply
+	pm8950_s5: s5 {
+		regulator-min-microvolt = <1050000>;
+		regulator-max-microvolt = <1350000>;
+		regulator-always-on;
+		regulator-boot-on;
+	};
+};
+
+&rpm_requests {
+	pm8950_rpm_regulators: regulators {
+		compatible = "qcom,rpm-pm8950-regulators";
+		vdd_s1-supply = <&vph_pwr>;
+		vdd_s2-supply = <&vph_pwr>;
+		vdd_s3-supply = <&vph_pwr>;
+		vdd_s4-supply = <&vph_pwr>;
+		vdd_s6-supply = <&vph_pwr>;
+		vdd_l1_l19-supply = <&pm8950_s3>;
+		vdd_l2_l23-supply = <&pm8950_s3>;
+		vdd_l3-supply = <&pm8950_s3>;
+		vdd_l5_l6_l7_l16-supply = <&pm8950_s4>;
+		vdd_l8_l11_l12_l17_l22-supply = <&vph_pwr>;
+		vdd_l9_l10_l13_l14_l15_l18-supply = <&vph_pwr>;
+
+		pm8950_s1: s1 {
+			regulator-min-microvolt = <1000000>;
+			regulator-max-microvolt = <1225000>;
+		};
+
+		pm8950_s3: s3 {
+			regulator-min-microvolt = <1300000>;
+			regulator-max-microvolt = <1300000>;
+		};
+		pm8950_s4: s4 {
+			regulator-min-microvolt = <2050000>;
+			regulator-max-microvolt = <2050000>;
+		};
+
+		pm8950_l2: l2 {
+			regulator-min-microvolt = <1200000>;
+			regulator-max-microvolt = <1200000>;
+			regulator-always-on;
+			regulator-boot-on;
+		};
+
+		/* pm8950_l3 is managed by rpmpd (RPMPD_VDDMX) */
+
+		pm8950_l5: l5 {
+			regulator-min-microvolt = <1800000>;
+			regulator-max-microvolt = <1800000>;
+		};
+
+		pm8950_l6: l6 {
+			regulator-min-microvolt = <1800000>;
+			regulator-max-microvolt = <1800000>;
+		};
+
+		pm8950_l7: l7 {
+			regulator-min-microvolt = <1800000>;
+			regulator-max-microvolt = <1800000>;
+		};
+
+		pm8950_l8: l8 {
+			regulator-min-microvolt = <2850000>;
+			regulator-max-microvolt = <2900000>;
+		};
+
+		pm8950_l9: l9 {
+			regulator-min-microvolt = <3000000>;
+			regulator-max-microvolt = <3300000>;
+		};
+
+		pm8950_l10: l10 {
+			regulator-min-microvolt = <2800000>;
+			regulator-max-microvolt = <2800000>;
+		};
+
+		pm8950_l11: l11 {
+			regulator-min-microvolt = <2950000>;
+			regulator-max-microvolt = <2950000>;
+			regulator-allow-set-load;
+			regulator-system-load = <200000>;
+		};
+
+		pm8950_l12: l12 {
+			regulator-min-microvolt = <1800000>;
+			regulator-max-microvolt = <2950000>;
+		};
+
+		pm8950_l13: l13 {
+			regulator-min-microvolt = <3075000>;
+			regulator-max-microvolt = <3075000>;
+		};
+
+		pm8950_l14: l14 {
+			regulator-min-microvolt = <1800000>;
+			regulator-max-microvolt = <3300000>;
+		};
+
+		pm8950_l15: l15 {
+			regulator-min-microvolt = <1800000>;
+			regulator-max-microvolt = <3300000>;
+		};
+
+		pm8950_l16: l16 {
+			regulator-min-microvolt = <1800000>;
+			regulator-max-microvolt = <1800000>;
+		};
+
+		pm8950_l17: l17 {
+			regulator-min-microvolt = <2850000>;
+			regulator-max-microvolt = <2850000>;
+		};
+
+		pm8950_l19: l19 {
+			regulator-min-microvolt = <1225000>;
+			regulator-max-microvolt = <1350000>;
+		};
+
+		pm8950_l22: l22 {
+			regulator-min-microvolt = <2800000>;
+			regulator-max-microvolt = <2800000>;
+		};
+
+		pm8950_l23: l23 {
+			regulator-min-microvolt = <1200000>;
+			regulator-max-microvolt = <1200000>;
+		};
+	};
+};
+
+&tlmm {
+	gpio-reserved-ranges = <20 4>; // Downstream doesn't use 21,22,23. 24 is mdss_te
+	gpio_hall_sensor_default: gpio-hall-sensor-default-state {
+		pins = "gpio46";
+		function = "gpio";
+		drive-strength = <6>;
+		bias-pull-up;
+	};
+
+	front_flash_default: front-flash-default-state {
+		pins = "gpio33", "gpio128";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-pull-down;
+	};
+
+	gpio_keys_default: gpio-keys-default-state {
+		pins = "gpio85";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-pull-up;
+	};
+
+	touchscreen_default: touchscreen-default-state {
+		pins = "gpio65", "gpio64";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+	};
+
+	tpa6130a2_default: tpa6130a2-default-state {
+		pins = "gpio61";
+		function = "gpio";
+		drive-strength = <8>;
+		bias-pull-down;
+		output-low;
+	};
+};
+
+&sleep_clk {
+	clock-frequency = <32768>;
+};
+
+&xo_board {
+	clock-frequency = <19200000>;
+};

-- 
2.54.0

