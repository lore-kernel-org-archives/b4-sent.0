From: David Wales <daviewales@disroot.org>
Date: Thu, 23 Apr 2026 23:24:51 +1000
Subject: [PATCH 2/2] ARM: dts: qcom: Support Motorola Moto G2 (2014)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260423-device-motorola-titan-mainline-v1-2-e1813a028cc8@disroot.org>
References: <20260423-device-motorola-titan-mainline-v1-0-e1813a028cc8@disroot.org>
In-Reply-To: <20260423-device-motorola-titan-mainline-v1-0-e1813a028cc8@disroot.org>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Wales <daviewales@disroot.org>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=9111;
 i=daviewales@disroot.org; h=from:subject:message-id;
 bh=Pso6mnHMePzlz73ajKH9CQ4GAdeq67YB7T/4eugpYsU=;
 b=owEBbQGS/pANAwAKAW1jV4FG9KFmAcsmYgBp6h21DTVu2ydkLkljItoAOUkFjIPvncbYhynNR
 84MChmUg1aJATMEAAEKAB0WIQTXikd3yUPmOPWSLPJtY1eBRvShZgUCaeodtQAKCRBtY1eBRvSh
 Zvs3B/9CIWC4fkDFZL92lUp0b584FPfEZL+N64Bmml6obk4dflvNKsG6Urk0A4OyaPD1N/4Jm0g
 0USbcdpeCf9crglQeg6icpziwSqh2HJuA3ko49vHCpvDsdB9xZ91h9OUUVc0iH6u/0WHxc+DX7b
 Yb/baIncvwu2qvxOhqsDXxtS6Oa6aQ49YZ9T/0+DISurG49uo/SMwtbLpjD+b+rRcp/OdZQQwQC
 xQX5WN/UZriyQmJa2keXsTrSdAyYltANF+59jfTCPrQlBI7C3T4nYcgdMzQ7OFcJhW9uX12I92A
 INQ74zN47KidKJ3Ommuuz20ydKpUHa+nVVPveCTW4wntxQgs
X-Developer-Key: i=daviewales@disroot.org; a=openpgp;
 fpr=8F5BAFB15444A769DC3B61684022B817D275D037
X-Endpoint-Received: by B4 Relay for daviewales@disroot.org/default with auth_id=737
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add device tree for Motorola Moto G2 (2014) (motorola-titan) smartphone
based on the Qualcomm MSM8226 SoC.

Initially supported features:
  - Buttons (Volume Down/Up, Power)
  - eMMC
  - Hall Effect Sensor
  - Simple framebuffer display
  - Vibrator

Based on device tree for similar device msm8226-motorola-falcon.
Initial commit for falcon notes that dhob and shob reserved-memory
regions seem to be related to a Motorola specific mechanism. [1]

[1] https://github.com/LineageOS/android_kernel_motorola_msm8226/blob/cm-14.1/Documentation/devicetree/bindings/misc/hob_ram.txt

Signed-off-by: David Wales <daviewales@disroot.org>
---
 arch/arm/boot/dts/qcom/Makefile                   |   1 +
 arch/arm/boot/dts/qcom/msm8226-motorola-titan.dts | 351 ++++++++++++++++++++++
 2 files changed, 352 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/Makefile b/arch/arm/boot/dts/qcom/Makefile
index c7873dcef154..de311293ce16 100644
--- a/arch/arm/boot/dts/qcom/Makefile
+++ b/arch/arm/boot/dts/qcom/Makefile
@@ -1,6 +1,7 @@
 # SPDX-License-Identifier: GPL-2.0
 dtb-$(CONFIG_ARCH_QCOM) += \
 	msm8226-motorola-falcon.dtb \
+	msm8226-motorola-titan.dtb \
 	qcom-apq8016-sbc.dtb \
 	qcom-apq8026-asus-sparrow.dtb \
 	qcom-apq8026-huawei-sturgeon.dtb \
diff --git a/arch/arm/boot/dts/qcom/msm8226-motorola-titan.dts b/arch/arm/boot/dts/qcom/msm8226-motorola-titan.dts
new file mode 100644
index 000000000000..9abb4738749d
--- /dev/null
+++ b/arch/arm/boot/dts/qcom/msm8226-motorola-titan.dts
@@ -0,0 +1,351 @@
+// SPDX-License-Identifier: BSD-3-Clause
+/*
+ * Copyright (c) 2026, David Wales <daviewales@disroot.org>
+ */
+
+/dts-v1/;
+
+#include "qcom-msm8226.dtsi"
+#include "pm8226.dtsi"
+
+/delete-node/ &smem_region;
+
+/ {
+	model = "Motorola Moto G2 (2014)";
+	compatible = "motorola,titan", "qcom,msm8226";
+	chassis-type = "handset";
+
+	aliases {
+		mmc0 = &sdhc_1; /* eMMC */
+	};
+
+	chosen {
+		#address-cells = <1>;
+		#size-cells = <1>;
+		ranges;
+
+		framebuffer@3200000 {
+			compatible = "simple-framebuffer";
+			reg = <0x03200000 0x800000>;
+			width = <720>;
+			height = <1280>;
+			stride = <(720 * 3)>;
+			format = "r8g8b8";
+			vsp-supply = <&reg_lcd_pos>;
+			vsn-supply = <&reg_lcd_neg>;
+			vddio-supply = <&vddio_disp_vreg>;
+
+			clocks = <&mmcc MDSS_AHB_CLK>,
+				 <&mmcc MDSS_AXI_CLK>,
+				 <&mmcc MDSS_BYTE0_CLK>,
+				 <&mmcc MDSS_ESC0_CLK>,
+				 <&mmcc MDSS_MDP_CLK>,
+				 <&mmcc MMSS_MISC_AHB_CLK>,
+				 <&mmcc MDSS_PCLK0_CLK>,
+				 <&mmcc MDSS_VSYNC_CLK>;
+			power-domains = <&mmcc MDSS_GDSC>;
+		};
+	};
+
+	gpio-keys {
+		compatible = "gpio-keys";
+
+		event-hall-sensor {
+			label = "Hall Effect Sensor";
+			gpios = <&tlmm 109 GPIO_ACTIVE_LOW>;
+			linux,input-type = <EV_SW>;
+			linux,code = <SW_LID>;
+			linux,can-disable;
+		};
+
+		key-volume-down {
+			label = "Volume Down";
+			gpios = <&tlmm 107 GPIO_ACTIVE_LOW>;
+			linux,code = <KEY_VOLUMEDOWN>;
+			debounce-interval = <15>;
+		};
+
+		key-volume-up {
+			label = "Volume Up";
+			gpios = <&tlmm 106 GPIO_ACTIVE_LOW>;
+			linux,code = <KEY_VOLUMEUP>;
+			debounce-interval = <15>;
+		};
+	};
+
+	vddio_disp_vreg: regulator-vddio-disp {
+		compatible = "regulator-fixed";
+		regulator-name = "vddio_disp";
+
+		gpio = <&tlmm 10 GPIO_ACTIVE_HIGH>;
+		startup-delay-us = <300>;
+		enable-active-high;
+		regulator-boot-on;
+	};
+
+	reserved-memory {
+		#address-cells = <1>;
+		#size-cells = <1>;
+		ranges;
+
+		framebuffer@3200000 {
+			reg = <0x03200000 0xfa0000>;
+			no-map;
+		};
+
+		dhob@f500000 {
+			reg = <0x0f500000 0x40000>;
+			no-map;
+		};
+
+		shob@f540000 {
+			reg = <0x0f540000 0x2000>;
+			no-map;
+		};
+
+		smem_region: smem@fa00000 {
+			reg = <0x0fa00000 0x100000>;
+			no-map;
+		};
+
+		reserved@fb00000 {
+			reg = <0x0fb00000 0x400000>;
+			no-map;
+		};
+	};
+};
+
+&blsp1_i2c4 {
+	status = "okay";
+
+	regulator@3e {
+		compatible = "ti,tps65132";
+		reg = <0x3e>;
+
+		pinctrl-0 = <&reg_lcd_default>;
+		pinctrl-names = "default";
+
+		reg_lcd_pos: outp {
+			regulator-name = "outp";
+			regulator-min-microvolt = <5400000>;
+			regulator-max-microvolt = <5600000>;
+			regulator-active-discharge = <1>;
+			regulator-boot-on;
+			enable-gpios = <&tlmm 12 GPIO_ACTIVE_HIGH>;
+		};
+
+		reg_lcd_neg: outn {
+			regulator-name = "outn";
+			regulator-min-microvolt = <5400000>;
+			regulator-max-microvolt = <5600000>;
+			regulator-active-discharge = <1>;
+			regulator-boot-on;
+			enable-gpios = <&tlmm 13 GPIO_ACTIVE_HIGH>;
+		};
+	};
+};
+
+&pm8226_vib {
+	status = "okay";
+};
+
+&rpm_requests {
+	regulators {
+		compatible = "qcom,rpm-pm8226-regulators";
+
+		pm8226_s3: s3 {
+			regulator-min-microvolt = <1200000>;
+			regulator-max-microvolt = <1300000>;
+		};
+
+		pm8226_s4: s4 {
+			regulator-min-microvolt = <1800000>;
+			regulator-max-microvolt = <2200000>;
+		};
+
+		pm8226_s5: s5 {
+			regulator-min-microvolt = <1150000>;
+			regulator-max-microvolt = <1150000>;
+		};
+
+		pm8226_l1: l1 {
+			regulator-min-microvolt = <1225000>;
+			regulator-max-microvolt = <1225000>;
+		};
+
+		pm8226_l2: l2 {
+			regulator-min-microvolt = <1200000>;
+			regulator-max-microvolt = <1200000>;
+		};
+
+		pm8226_l3: l3 {
+			regulator-min-microvolt = <750000>;
+			regulator-max-microvolt = <1337500>;
+		};
+
+		pm8226_l4: l4 {
+			regulator-min-microvolt = <1200000>;
+			regulator-max-microvolt = <1200000>;
+		};
+
+		pm8226_l5: l5 {
+			regulator-min-microvolt = <1200000>;
+			regulator-max-microvolt = <1200000>;
+		};
+
+		pm8226_l6: l6 {
+			/* Hall effect sensor */
+			regulator-min-microvolt = <1800000>;
+			regulator-max-microvolt = <1800000>;
+			regulator-always-on;
+		};
+
+		pm8226_l7: l7 {
+			regulator-min-microvolt = <1850000>;
+			regulator-max-microvolt = <1850000>;
+		};
+
+		pm8226_l8: l8 {
+			regulator-min-microvolt = <1800000>;
+			regulator-max-microvolt = <1800000>;
+		};
+
+		pm8226_l9: l9 {
+			regulator-min-microvolt = <2050000>;
+			regulator-max-microvolt = <2050000>;
+		};
+
+		pm8226_l10: l10 {
+			regulator-min-microvolt = <1800000>;
+			regulator-max-microvolt = <1800000>;
+		};
+
+		pm8226_l12: l12 {
+			regulator-min-microvolt = <1800000>;
+			regulator-max-microvolt = <1800000>;
+		};
+
+		pm8226_l14: l14 {
+			regulator-min-microvolt = <2750000>;
+			regulator-max-microvolt = <2750000>;
+		};
+
+		pm8226_l15: l15 {
+			regulator-min-microvolt = <2800000>;
+			regulator-max-microvolt = <2800000>;
+		};
+
+		pm8226_l16: l16 {
+			regulator-min-microvolt = <3000000>;
+			regulator-max-microvolt = <3350000>;
+		};
+
+		pm8226_l17: l17 {
+			regulator-min-microvolt = <2950000>;
+			regulator-max-microvolt = <2950000>;
+		};
+
+		pm8226_l18: l18 {
+			regulator-min-microvolt = <2950000>;
+			regulator-max-microvolt = <2950000>;
+		};
+
+		pm8226_l19: l19 {
+			regulator-min-microvolt = <2850000>;
+			regulator-max-microvolt = <2850000>;
+		};
+
+		pm8226_l20: l20 {
+			regulator-min-microvolt = <3075000>;
+			regulator-max-microvolt = <3075000>;
+		};
+
+		pm8226_l21: l21 {
+			regulator-min-microvolt = <1800000>;
+			regulator-max-microvolt = <2950000>;
+			regulator-allow-set-load;
+		};
+
+		pm8226_l22: l22 {
+			regulator-min-microvolt = <1800000>;
+			regulator-max-microvolt = <2950000>;
+		};
+
+		pm8226_l23: l23 {
+			regulator-min-microvolt = <1800000>;
+			regulator-max-microvolt = <2950000>;
+		};
+
+		pm8226_l24: l24 {
+			regulator-min-microvolt = <1300000>;
+			regulator-max-microvolt = <1350000>;
+		};
+
+		pm8226_l25: l25 {
+			regulator-min-microvolt = <1775000>;
+			regulator-max-microvolt = <2125000>;
+		};
+
+		pm8226_l26: l26 {
+			regulator-min-microvolt = <1225000>;
+			regulator-max-microvolt = <1225000>;
+		};
+
+		pm8226_l27: l27 {
+			regulator-min-microvolt = <2050000>;
+			regulator-max-microvolt = <2050000>;
+		};
+
+		pm8226_l28: l28 {
+			regulator-min-microvolt = <1800000>;
+			regulator-max-microvolt = <3400000>;
+			regulator-boot-on;
+		};
+
+		pm8226_lvs1: lvs1 {
+			/* Pull-up for I2C lines */
+			regulator-always-on;
+		};
+	};
+};
+
+&sdhc_1 {
+	vmmc-supply = <&pm8226_l17>;
+	vqmmc-supply = <&pm8226_l6>;
+	bus-width = <8>;
+	non-removable;
+
+	status = "okay";
+};
+
+&smbb {
+	qcom,fast-charge-safe-current = <2000000>;
+	qcom,fast-charge-current-limit = <1900000>;
+	qcom,fast-charge-safe-voltage = <4400000>;
+	qcom,minimum-input-voltage = <4300000>;
+
+	status = "okay";
+};
+
+&usb {
+	extcon = <&smbb>;
+	dr_mode = "peripheral";
+
+	status = "okay";
+};
+
+&usb_hs_phy {
+	extcon = <&smbb>;
+	v1p8-supply = <&pm8226_l10>;
+	v3p3-supply = <&pm8226_l20>;
+};
+
+&tlmm {
+	reg_lcd_default: reg-lcd-default-state {
+		pins = "gpio12", "gpio13";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+		output-high;
+	};
+};

-- 
2.53.0

