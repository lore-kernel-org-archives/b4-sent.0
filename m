From: Maud Spierings <maud_spierings@hotmail.com>
Date: Sun, 19 Jan 2025 15:50:51 +0100
Subject: [PATCH 1/2] arm64: dts: qcom: x1e80100-vivobook-s15: Enable USB-A
 ports
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250119-usb_a_micro_sd-v1-1-01eb7502ae05@hotmail.com>
References: <20250119-usb_a_micro_sd-v1-0-01eb7502ae05@hotmail.com>
In-Reply-To: <20250119-usb_a_micro_sd-v1-0-01eb7502ae05@hotmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Maud Spierings <maud_spierings@hotmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1737298255; l=3649;
 i=maud_spierings@hotmail.com; s=20241110; h=from:subject:message-id;
 bh=idUvFTYnjlWc1hne6a9f/k2cF8fXFoNt7OjqqPI7Elg=;
 b=rWhKRfL8YkTdmOrujhoQlvGsFleap4guv118Cjw48KX4aQtMFVnlHGM6lM1p6LQgDdGcLq857
 6xM003uNvPxA6FZ9kAr+JJj60G1tSoz3tqYKBtFMa5v1RcqBnlq3gMo
X-Developer-Key: i=maud_spierings@hotmail.com; a=ed25519;
 pk=CeFKVnZvRfX2QjB1DpdiAe2N+MEjwLEB9Yhx/OAcxRc=
X-Endpoint-Received: by B4 Relay for maud_spierings@hotmail.com/20241110 with auth_id=273
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The asus vivobook has 2 USB type A ports on the right side, enable them

Signed-off-by: Maud Spierings <maud_spierings@hotmail.com>
---
 .../boot/dts/qcom/x1e80100-asus-vivobook-s15.dts   | 103 ++++++++++++++++++++-
 1 file changed, 102 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/x1e80100-asus-vivobook-s15.dts b/arch/arm64/boot/dts/qcom/x1e80100-asus-vivobook-s15.dts
index 53781f9b13af3e8491dcf63c57868eaf7025d0a8..b66d03ee3ff30561e8665be6ad34919f89a79572 100644
--- a/arch/arm64/boot/dts/qcom/x1e80100-asus-vivobook-s15.dts
+++ b/arch/arm64/boot/dts/qcom/x1e80100-asus-vivobook-s15.dts
@@ -192,6 +192,20 @@ vreg_l2b_3p0: ldo2 {
 			regulator-initial-mode = <RPMH_REGULATOR_MODE_HPM>;
 		};
 
+		vreg_l4b_1p8: ldo4 {
+			regulator-name = "vreg_l4b_1p8";
+			regulator-min-microvolt = <1800000>;
+			regulator-max-microvolt = <1800000>;
+			regulator-initial-mode = <RPMH_REGULATOR_MODE_HPM>;
+		};
+
+		vreg_l13b_3p0: ldo13 {
+			regulator-name = "vreg_l13b_3p0";
+			regulator-min-microvolt = <3072000>;
+			regulator-max-microvolt = <3072000>;
+			regulator-initial-mode = <RPMH_REGULATOR_MODE_HPM>;
+		};
+
 		vreg_l14b_3p0: ldo14 {
 			regulator-name = "vreg_l14b_3p0";
 			regulator-min-microvolt = <3072000>;
@@ -209,6 +223,13 @@ regulators-1 {
 		vdd-l3-supply = <&vreg_s1f_0p7>;
 		vdd-s4-supply = <&vph_pwr>;
 
+		vreg_l3c_0p8: ldo3 {
+			regulator-name = "vreg_l3c_0p8";
+			regulator-min-microvolt = <912000>;
+			regulator-max-microvolt = <912000>;
+			regulator-initial-mode = <RPMH_REGULATOR_MODE_HPM>;
+		};
+
 		vreg_s4c_1p8: smps4 {
 			regulator-name = "vreg_s4c_1p8";
 			regulator-min-microvolt = <1856000>;
@@ -401,7 +422,35 @@ keyboard@3a {
 		wakeup-source;
 	};
 
-	/* EC? @ 0x5b, 0x76 */
+	eusb3_repeater: redriver@47 {
+		compatible = "nxp,ptn3222";
+		reg = <0x47>;
+		#phy-cells = <0>;
+
+		vdd3v3-supply = <&vreg_l13b_3p0>;
+		vdd1v8-supply = <&vreg_l4b_1p8>;
+
+		reset-gpios = <&tlmm 6 GPIO_ACTIVE_LOW>;
+
+		pinctrl-0 = <&eusb3_reset_n>;
+		pinctrl-names = "default";
+	};
+
+	eusb6_repeater: redriver@4f {
+		compatible = "nxp,ptn3222";
+		reg = <0x4f>;
+		#phy-cells = <0>;
+
+		vdd3v3-supply = <&vreg_l13b_3p0>;
+		vdd1v8-supply = <&vreg_l4b_1p8>;
+
+		reset-gpios = <&tlmm 184 GPIO_ACTIVE_LOW>;
+
+		pinctrl-0 = <&eusb6_reset_n>;
+		pinctrl-names = "default";
+	};
+
+	/* EC @ 0x76 */
 };
 
 &i2c7 {
@@ -563,6 +612,22 @@ edp_reg_en: edp-reg-en-state {
 		bias-disable;
 	};
 
+	eusb3_reset_n: eusb3-reset-n-state {
+		pins = "gpio6";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-pull-up;
+		output-low;
+	};
+
+	eusb6_reset_n: eusb6-reset-n-state {
+		pins = "gpio184";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-pull-up;
+		output-low;
+	};
+
 	hall_int_n_default: hall-int-n-state {
 		pins = "gpio92";
 		function = "gpio";
@@ -698,3 +763,39 @@ &usb_1_ss1_dwc3_hs {
 &usb_1_ss1_qmpphy_out {
 	remote-endpoint = <&pmic_glink_ss1_ss_in>;
 };
+
+&usb_mp {
+	status = "okay";
+};
+
+&usb_mp_hsphy0 {
+	vdd-supply = <&vreg_l2e_0p8>;
+	vdda12-supply = <&vreg_l3e_1p2>;
+
+	phys = <&eusb6_repeater>;
+
+	status = "okay";
+};
+
+&usb_mp_hsphy1 {
+	vdd-supply = <&vreg_l2e_0p8>;
+	vdda12-supply = <&vreg_l3e_1p2>;
+
+	phys = <&eusb3_repeater>;
+
+	status = "okay";
+};
+
+&usb_mp_qmpphy0 {
+	vdda-phy-supply = <&vreg_l3e_1p2>;
+	vdda-pll-supply = <&vreg_l3c_0p8>;
+
+	status = "okay";
+};
+
+&usb_mp_qmpphy1 {
+	vdda-phy-supply = <&vreg_l3e_1p2>;
+	vdda-pll-supply = <&vreg_l3c_0p8>;
+
+	status = "okay";
+};

-- 
2.47.1

