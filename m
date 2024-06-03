From: Alexandre Messier <alex@me.ssier.org>
Date: Mon, 03 Jun 2024 02:28:57 -0400
Subject: [PATCH 2/2] ARM: dts: qcom: Add initial support for HTC One (M8)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240603-m8-support-v1-2-c7b6a1941ed2@me.ssier.org>
References: <20240603-m8-support-v1-0-c7b6a1941ed2@me.ssier.org>
In-Reply-To: <20240603-m8-support-v1-0-c7b6a1941ed2@me.ssier.org>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Luca Weiss <luca@z3ntu.xyz>, linux-arm-kernel@lists.infradead.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 ~postmarketos/upstreaming@lists.sr.ht, 
 Alexandre Messier <alex@me.ssier.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717396145; l=8929;
 i=alex@me.ssier.org; s=20240603; h=from:subject:message-id;
 bh=UpJvjtnEQ3Nh2o5lWTWj9v8Sn4StqngLLSysn4fnBUs=;
 b=w0sgFT/6Ucs0SAAprK31SqHJsjoGUbil2KtJ3WcM/LiUAjqgh+D9RWWPFw7fBYPvCixmx/rct
 CBHjNlJqLCgCF7CJ5Ri81XRi/7d0E0dr6wA+tGfEnXj+M0/nClACpO1
X-Developer-Key: i=alex@me.ssier.org; a=ed25519;
 pk=JjRqVfLd2XLHX2QTylKoROw346/1LOyZJX0q6cfnrKw=
X-Endpoint-Received: by B4 Relay for alex@me.ssier.org/20240603 with auth_id=168
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add initial device tree for the HTC One (M8) smartphone.

Initial support includes:
 - eMMC
 - Power button
 - USB
 - Vibrator
 - Volume buttons (GPIO)
 - Wi-Fi

Signed-off-by: Alexandre Messier <alex@me.ssier.org>
---
 arch/arm/boot/dts/qcom/Makefile                   |   1 +
 arch/arm/boot/dts/qcom/qcom-msm8974pro-htc-m8.dts | 353 ++++++++++++++++++++++
 2 files changed, 354 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/Makefile b/arch/arm/boot/dts/qcom/Makefile
index e2e922bdc9e9..759b0e7f0043 100644
--- a/arch/arm/boot/dts/qcom/Makefile
+++ b/arch/arm/boot/dts/qcom/Makefile
@@ -44,6 +44,7 @@ dtb-$(CONFIG_ARCH_QCOM) += \
 	qcom-msm8974-sony-xperia-rhine-amami.dtb \
 	qcom-msm8974-sony-xperia-rhine-honami.dtb \
 	qcom-msm8974pro-fairphone-fp2.dtb \
+	qcom-msm8974pro-htc-m8.dtb \
 	qcom-msm8974pro-oneplus-bacon.dtb \
 	qcom-msm8974pro-samsung-klte.dtb \
 	qcom-msm8974pro-samsung-kltechn.dtb \
diff --git a/arch/arm/boot/dts/qcom/qcom-msm8974pro-htc-m8.dts b/arch/arm/boot/dts/qcom/qcom-msm8974pro-htc-m8.dts
new file mode 100644
index 000000000000..b896cc1ad6f7
--- /dev/null
+++ b/arch/arm/boot/dts/qcom/qcom-msm8974pro-htc-m8.dts
@@ -0,0 +1,353 @@
+// SPDX-License-Identifier: GPL-2.0-only
+#include "qcom-msm8974pro.dtsi"
+#include "pm8841.dtsi"
+#include "pm8941.dtsi"
+#include <dt-bindings/input/input.h>
+
+/ {
+	model = "HTC One (M8)";
+	compatible = "htc,m8", "qcom,msm8974pro", "qcom,msm8974";
+	chassis-type = "handset";
+
+	aliases {
+		mmc0 = &sdhc_1;
+	};
+
+	gpio-keys {
+		compatible = "gpio-keys";
+
+		pinctrl-0 = <&gpio_keys_default>;
+		pinctrl-names = "default";
+
+		key-volume-down {
+			label = "volume_down";
+			gpios = <&tlmm 27 GPIO_ACTIVE_LOW>;
+			linux,code = <KEY_VOLUMEDOWN>;
+			debounce-interval = <20>;
+			wakeup-source;
+		};
+
+		key-volume-up {
+			label = "volume_up";
+			gpios = <&tlmm 28 GPIO_ACTIVE_LOW>;
+			linux,code = <KEY_VOLUMEUP>;
+			debounce-interval = <20>;
+			wakeup-source;
+		};
+	};
+
+	vreg_boost: vreg-boost {
+		compatible = "regulator-fixed";
+
+		regulator-name = "vreg-boost";
+		regulator-min-microvolt = <3150000>;
+		regulator-max-microvolt = <3150000>;
+
+		regulator-always-on;
+		regulator-boot-on;
+
+		gpio = <&pm8941_gpios 21 GPIO_ACTIVE_HIGH>;
+		enable-active-high;
+
+		pinctrl-0 = <&boost_bypass_n_pin>;
+		pinctrl-names = "default";
+	};
+
+	vreg_vph_pwr: vreg-vph-pwr {
+		compatible = "regulator-fixed";
+		regulator-name = "vph-pwr";
+
+		regulator-min-microvolt = <3600000>;
+		regulator-max-microvolt = <3600000>;
+
+		regulator-always-on;
+	};
+};
+
+&pm8941_vib {
+	status = "okay";
+};
+
+&pronto {
+	vddmx-supply = <&pm8841_s1>;
+	vddcx-supply = <&pm8841_s2>;
+	vddpx-supply = <&pm8941_s3>;
+
+	pinctrl-0 = <&wcnss_pin_a>;
+	pinctrl-names = "default";
+
+	status = "okay";
+
+	iris {
+		vddxo-supply = <&pm8941_l6>;
+		vddrfa-supply = <&pm8941_l11>;
+		vddpa-supply = <&pm8941_l19>;
+		vdddig-supply = <&pm8941_s3>;
+	};
+
+	smd-edge {
+		qcom,remote-pid = <4>;
+		label = "pronto";
+
+		wcnss {
+			status = "okay";
+		};
+	};
+};
+
+&rpm_requests {
+	regulators-0 {
+		compatible = "qcom,rpm-pm8841-regulators";
+
+		pm8841_s1: s1 {
+			regulator-min-microvolt = <675000>;
+			regulator-max-microvolt = <1050000>;
+		};
+
+		pm8841_s2: s2 {
+			regulator-min-microvolt = <500000>;
+			regulator-max-microvolt = <1050000>;
+		};
+
+		pm8841_s3: s3 {
+			regulator-min-microvolt = <1050000>;
+			regulator-max-microvolt = <1050000>;
+		};
+
+		pm8841_s4: s4 {
+			regulator-min-microvolt = <815000>;
+			regulator-max-microvolt = <900000>;
+		};
+	};
+
+	regulators-1 {
+		compatible = "qcom,rpm-pm8941-regulators";
+
+		vdd_l1_l3-supply = <&pm8941_s1>;
+		vdd_l2_lvs1_2_3-supply = <&pm8941_s3>;
+		vdd_l4_l11-supply = <&pm8941_s1>;
+		vdd_l5_l7-supply = <&pm8941_s2>;
+		vdd_l6_l12_l14_l15-supply = <&pm8941_s2>;
+		vdd_l8_l16_l18_l19-supply = <&vreg_vph_pwr>;
+		vdd_l9_l10_l17_l22-supply = <&vreg_boost>;
+		vdd_l13_l20_l23_l24-supply = <&vreg_boost>;
+		vdd_l21-supply = <&vreg_boost>;
+
+		pm8941_s1: s1 {
+			regulator-min-microvolt = <1300000>;
+			regulator-max-microvolt = <1300000>;
+			regulator-always-on;
+			regulator-boot-on;
+		};
+
+		pm8941_s2: s2 {
+			regulator-min-microvolt = <2150000>;
+			regulator-max-microvolt = <2150000>;
+			regulator-boot-on;
+		};
+
+		pm8941_s3: s3 {
+			regulator-min-microvolt = <1800000>;
+			regulator-max-microvolt = <1800000>;
+			regulator-always-on;
+			regulator-boot-on;
+		};
+
+		pm8941_l1: l1 {
+			regulator-min-microvolt = <1225000>;
+			regulator-max-microvolt = <1225000>;
+			regulator-always-on;
+			regulator-boot-on;
+		};
+
+		pm8941_l2: l2 {
+			regulator-min-microvolt = <1200000>;
+			regulator-max-microvolt = <1200000>;
+		};
+
+		pm8941_l3: l3 {
+			regulator-min-microvolt = <1200000>;
+			regulator-max-microvolt = <1200000>;
+		};
+
+		pm8941_l4: l4 {
+			regulator-min-microvolt = <1225000>;
+			regulator-max-microvolt = <1225000>;
+		};
+
+		pm8941_l5: l5 {
+			regulator-min-microvolt = <1800000>;
+			regulator-max-microvolt = <1800000>;
+		};
+
+		pm8941_l6: l6 {
+			regulator-min-microvolt = <1800000>;
+			regulator-max-microvolt = <1800000>;
+			regulator-boot-on;
+		};
+
+		pm8941_l7: l7 {
+			regulator-min-microvolt = <1800000>;
+			regulator-max-microvolt = <1800000>;
+			regulator-boot-on;
+		};
+
+		pm8941_l8: l8 {
+			regulator-min-microvolt = <1800000>;
+			regulator-max-microvolt = <1800000>;
+		};
+
+		pm8941_l9: l9 {
+			regulator-min-microvolt = <1800000>;
+			regulator-max-microvolt = <2950000>;
+		};
+
+		pm8941_l10: l10 {
+			regulator-min-microvolt = <1800000>;
+			regulator-max-microvolt = <2950000>;
+		};
+
+		pm8941_l11: l11 {
+			regulator-min-microvolt = <1225000>;
+			regulator-max-microvolt = <1350000>;
+		};
+
+		pm8941_l12: l12 {
+			regulator-min-microvolt = <1800000>;
+			regulator-max-microvolt = <1800000>;
+			regulator-always-on;
+			regulator-boot-on;
+		};
+
+		pm8941_l13: l13 {
+			regulator-min-microvolt = <1800000>;
+			regulator-max-microvolt = <2950000>;
+			regulator-boot-on;
+		};
+
+		pm8941_l14: l14 {
+			regulator-min-microvolt = <1800000>;
+			regulator-max-microvolt = <1800000>;
+		};
+
+		pm8941_l15: l15 {
+			regulator-min-microvolt = <2050000>;
+			regulator-max-microvolt = <2050000>;
+		};
+
+		pm8941_l16: l16 {
+			regulator-min-microvolt = <2700000>;
+			regulator-max-microvolt = <2700000>;
+		};
+
+		pm8941_l17: l17 {
+			regulator-min-microvolt = <2850000>;
+			regulator-max-microvolt = <2850000>;
+		};
+
+		pm8941_l18: l18 {
+			regulator-min-microvolt = <2850000>;
+			regulator-max-microvolt = <2850000>;
+		};
+
+		pm8941_l19: l19 {
+			regulator-min-microvolt = <2900000>;
+			regulator-max-microvolt = <3350000>;
+		};
+
+		pm8941_l20: l20 {
+			regulator-min-microvolt = <2950000>;
+			regulator-max-microvolt = <2950000>;
+			regulator-system-load = <200000>;
+			regulator-allow-set-load;
+			regulator-boot-on;
+		};
+
+		pm8941_l21: l21 {
+			regulator-min-microvolt = <2950000>;
+			regulator-max-microvolt = <2950000>;
+			regulator-boot-on;
+		};
+
+		pm8941_l22: l22 {
+			regulator-min-microvolt = <3300000>;
+			regulator-max-microvolt = <3300000>;
+		};
+
+		pm8941_l23: l23 {
+			regulator-min-microvolt = <3000000>;
+			regulator-max-microvolt = <3000000>;
+		};
+
+		pm8941_l24: l24 {
+			regulator-min-microvolt = <3075000>;
+			regulator-max-microvolt = <3075000>;
+			regulator-boot-on;
+		};
+	};
+};
+
+&sdhc_1 {
+	vmmc-supply = <&pm8941_l20>;
+	vqmmc-supply = <&pm8941_s3>;
+
+	pinctrl-0 = <&sdc1_on>;
+	pinctrl-1 = <&sdc1_off>;
+	pinctrl-names = "default", "sleep";
+
+	status = "okay";
+};
+
+&smbb {
+	status = "okay";
+};
+
+&tlmm {
+	gpio_keys_default: gpio-keys-default-state {
+		pins = "gpio27", "gpio28";
+		function = "gpio";
+		bias-pull-up;
+	};
+
+	sdc1_on: sdc1-on-state {
+		clk-pins {
+			pins = "sdc1_clk";
+			drive-strength = <10>;
+			bias-disable;
+		};
+
+		cmd-data-pins {
+			pins = "sdc1_cmd", "sdc1_data";
+			drive-strength = <10>;
+			bias-pull-up;
+		};
+	};
+
+	wcnss_pin_a: wcnss-pin-active-state {
+		pins = "gpio36", "gpio37", "gpio38", "gpio39", "gpio40";
+		function = "wlan";
+		drive-strength = <6>;
+		bias-pull-down;
+	};
+};
+
+&usb {
+	phys = <&usb_hs1_phy>;
+	phy-select = <&tcsr 0xb000 0>;
+	extcon = <&smbb>, <&usb_id>;
+	vbus-supply = <&chg_otg>;
+
+	hnp-disable;
+	srp-disable;
+	adp-disable;
+
+	status = "okay";
+};
+
+&usb_hs1_phy {
+	v1p8-supply = <&pm8941_l6>;
+	v3p3-supply = <&pm8941_l24>;
+	extcon = <&smbb>;
+	qcom,init-seq = /bits/ 8 <0x1 0x63>;
+	status = "okay";
+};

-- 
2.45.1

