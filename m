From: Yedaya Katsman <yedaya.ka@gmail.com>
Date: Sun, 18 Jan 2026 22:29:42 +0200
Subject: [PATCH v3 3/3] arm64: dts: qcom: sm6125-xiaomi-laurel-sprout: Add
 Focaltech FT3518 touchscreen
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260118-touchscreen-patches-v3-3-1c6a729c5eb4@gmail.com>
References: <20260118-touchscreen-patches-v3-0-1c6a729c5eb4@gmail.com>
In-Reply-To: <20260118-touchscreen-patches-v3-0-1c6a729c5eb4@gmail.com>
To: =?utf-8?q?Kamil_Go=C5=82da?= <kamil.golda@protonmail.com>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Yedaya Katsman <yedaya.ka@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768768201; l=3979;
 i=yedaya.ka@gmail.com; s=20260113; h=from:subject:message-id;
 bh=gc0uiHv+Kr2394WFOHhQSa//UoZdP1/ciZ1jZkUwa0E=;
 b=cSROccKeZFVWmSgQUYE5KsGt/3EsRqvOweoKWRwOueObEAs7gZRtAmM9lS6Of5R7naU2o8QE3
 k4JLpMG7w8cCGO3ZC1H3yHkXI+VW4LyfOz6VfJD2zieZB3meiAsHFYs
X-Developer-Key: i=yedaya.ka@gmail.com; a=ed25519;
 pk=CgNmxD3tYSws5dZfpmJfc6re/bV/f47veVijddHLytk=
X-Endpoint-Received: by B4 Relay for yedaya.ka@gmail.com/20260113 with auth_id=601
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add device tree node for the Focaltech FT3518 touchscreen on
Xiaomi Mi A3 (laurel-sprout).

Add pmx_ts_* gpio configurations and reference them in the touchscreen
node.
Note that gpio pin 83 for the regulator isn't documented downstream
except in the touchscreen node so it's not defined in the tlmm.

Enable qupv3_id_0 and i2c2 bus that the touchscreen is on.

Downstream references:
Link: https://github.com/MiCode/Xiaomi_Kernel_OpenSource/blob/laurel-r-oss/arch/arm64/boot/dts/qcom/trinket-pinctrl.dtsi
Link: https://github.com/MiCode/Xiaomi_Kernel_OpenSource/blob/laurel-r-oss/arch/arm64/boot/dts/qcom/laurel_sprout-qrd.dtsi

Co-developed-by: Kamil Gołda <kamil.golda@protonmail.com>
Signed-off-by: Kamil Gołda <kamil.golda@protonmail.com>
Signed-off-by: Yedaya Katsman <yedaya.ka@gmail.com>
---
 .../boot/dts/qcom/sm6125-xiaomi-laurel-sprout.dts  | 113 +++++++++++++++++++++
 1 file changed, 113 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sm6125-xiaomi-laurel-sprout.dts b/arch/arm64/boot/dts/qcom/sm6125-xiaomi-laurel-sprout.dts
index 994fb0412fcbdf5466f87a325c48b697a37b514b..5e55acacee9585f34eead20661268103f0b7889c 100644
--- a/arch/arm64/boot/dts/qcom/sm6125-xiaomi-laurel-sprout.dts
+++ b/arch/arm64/boot/dts/qcom/sm6125-xiaomi-laurel-sprout.dts
@@ -82,6 +82,18 @@ key-volume-up {
 		};
 	};
 
+	ts_vdd_supply: regulator-ts-vdd {
+		compatible = "regulator-fixed";
+		regulator-name = "ts_vdd_supply";
+		regulator-min-microvolt = <3300000>;
+		regulator-max-microvolt = <3300000>;
+
+		gpio = <&tlmm 83 GPIO_ACTIVE_HIGH>;
+		enable-active-high;
+
+		startup-delay-us = <70000>;
+	};
+
 	thermal-zones {
 		rf-pa0-thermal {
 			thermal-sensors = <&pm6125_adc_tm 0>;
@@ -128,6 +140,28 @@ &hsusb_phy1 {
 	status = "okay";
 };
 
+&i2c2 {
+	status = "okay";
+
+	touchscreen@38 {
+		compatible = "focaltech,ft3518";
+		reg = <0x38>;
+		interrupts-extended = <&tlmm 88 IRQ_TYPE_EDGE_FALLING>;
+
+		vcc-supply = <&ts_vdd_supply>;
+
+		pinctrl-names = "pmx_ts_active","pmx_ts_suspend","pmx_ts_release";
+		pinctrl-0 = <&ts_int_active &ts_reset_active>;
+		pinctrl-1 = <&ts_int_suspend &ts_reset_suspend>;
+		pinctrl-2 = <&ts_release>;
+
+		reset-gpios = <&tlmm 87 GPIO_ACTIVE_LOW>;
+
+		touchscreen-size-x = <720>;
+		touchscreen-size-y = <1560>;
+	};
+};
+
 &pm6125_adc {
 	pinctrl-names = "default";
 	pinctrl-0 = <&camera_flash_therm &emmc_ufs_therm>;
@@ -220,6 +254,10 @@ &pon_resin {
 	status = "okay";
 };
 
+&qupv3_id_0 {
+	status = "okay";
+};
+
 &rpm_requests {
 	regulators-0 {
 		compatible = "qcom,rpm-pm6125-regulators";
@@ -387,6 +425,81 @@ &sdhc_2 {
 
 &tlmm {
 	gpio-reserved-ranges = <22 2>, <28 6>;
+
+	pmx_ts_reset_active {
+		ts_reset_active: ts_reset_active {
+			mux {
+				pins = "gpio87";
+				function = "gpio";
+			};
+
+			config {
+				pins = "gpio87";
+				drive-strength = <8>;
+				bias-pull-up;
+			};
+		};
+	};
+
+	pmx_ts_reset_suspend {
+		ts_reset_suspend: ts_reset_suspend {
+			mux {
+				pins = "gpio87";
+				function = "gpio";
+			};
+
+			config {
+				pins = "gpio87";
+				drive-strength = <2>;
+				bias-pull-down;
+			};
+		};
+	};
+
+	pmx_ts_int_active {
+		ts_int_active: ts_int_active {
+			mux {
+				pins = "gpio88";
+				function = "gpio";
+			};
+
+			config {
+				pins = "gpio88";
+				drive-strength = <8>;
+				bias-pull-up;
+			};
+		};
+	};
+
+	pmx_ts_int_suspend {
+		ts_int_suspend: ts_int_suspend {
+			mux {
+				pins = "gpio88";
+				function = "gpio";
+			};
+
+			config {
+				pins = "gpio88";
+				drive-strength = <2>;
+				bias-pull-down;
+			};
+		};
+	};
+
+	pmx_ts_release {
+		ts_release: ts_release {
+			mux {
+				pins = "gpio87", "gpio88";
+				function = "gpio";
+			};
+
+			config {
+				pins = "gpio87", "gpio88";
+				drive-strength = <2>;
+				bias-pull-down;
+			};
+		};
+	};
 };
 
 &ufs_mem_hc {

-- 
2.52.0

