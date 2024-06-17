From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Mon, 17 Jun 2024 23:22:27 +0200
Subject: [PATCH v2 1/3] ARM: dts: qcom: msm8926-motorola-peregrine: Add
 accelerometer, magnetometer, regulator
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240617-peregrine-v2-1-c8835d2da7af@apitzsch.eu>
References: <20240617-peregrine-v2-0-c8835d2da7af@apitzsch.eu>
In-Reply-To: <20240617-peregrine-v2-0-c8835d2da7af@apitzsch.eu>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 ~postmarketos/upstreaming@lists.sr.ht, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718659400; l=2907;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=mj4yxzOm2d+J3umJgLBBLCdJ6UtTa0NpoUWMAtyqNkY=;
 b=cEbuwgEsPA7k5I25OSNgvvgBVtnZm+tO83xlkrVBYyxVG/Gv9kA2EPiXYOHyrbMJXVidIeZ3l
 poCdd9l/2EHBF7/WHqFeBM04bT9Obc/KjI3kpQSzL6XQGDLCXG5eBFp
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the accelerometer, magnetometer and regulator that are present on
the Motorola Moto G 4G (2013) device.

Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 .../dts/qcom/qcom-msm8926-motorola-peregrine.dts   | 85 ++++++++++++++++++++++
 1 file changed, 85 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8926-motorola-peregrine.dts b/arch/arm/boot/dts/qcom/qcom-msm8926-motorola-peregrine.dts
index 0cbe2d2fbbb1..50ae3cfc95bb 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8926-motorola-peregrine.dts
+++ b/arch/arm/boot/dts/qcom/qcom-msm8926-motorola-peregrine.dts
@@ -68,9 +68,60 @@ smem_region: smem@fa00000 {
 	};
 };
 
+&blsp1_i2c2 {
+	clock-frequency = <100000>;
+	status = "okay";
+
+	magnetometer@c {
+		compatible = "asahi-kasei,ak8963";
+		reg = <0xc>;
+		interrupts-extended = <&tlmm 38 IRQ_TYPE_EDGE_FALLING>;
+		reset-gpios = <&tlmm 62 GPIO_ACTIVE_LOW>;
+		vdd-supply = <&pm8226_l19>;
+		pinctrl-0 = <&mag_int_default &mag_reset_default>;
+		pinctrl-names = "default";
+	};
+
+	accelerometer@18 {
+		compatible = "st,lis3dh-accel";
+		reg = <0x18>;
+		interrupts-extended = <&tlmm 1 IRQ_TYPE_EDGE_FALLING>;
+		vdd-supply = <&pm8226_l19>;
+		pinctrl-0 = <&accel_int_default>;
+		pinctrl-names = "default";
+		st,drdy-int-pin = <1>;
+	};
+};
+
 &blsp1_i2c3 {
+	clock-frequency = <400000>;
 	status = "okay";
 
+	regulator@3e {
+		compatible = "ti,tps65132";
+		reg = <0x3e>;
+		pinctrl-0 = <&reg_lcd_default>;
+		pinctrl-names = "default";
+
+		reg_lcd_pos: outp {
+			regulator-name = "outp";
+			regulator-min-microvolt = <4000000>;
+			regulator-max-microvolt = <6000000>;
+			regulator-active-discharge = <1>;
+			regulator-boot-on;
+			enable-gpios = <&tlmm 31 GPIO_ACTIVE_HIGH>;
+		};
+
+		reg_lcd_neg: outn {
+			regulator-name = "outn";
+			regulator-min-microvolt = <4000000>;
+			regulator-max-microvolt = <6000000>;
+			regulator-active-discharge = <1>;
+			regulator-boot-on;
+			enable-gpios = <&tlmm 33 GPIO_ACTIVE_HIGH>;
+		};
+	};
+
 	sensor@48 {
 		compatible = "ti,tmp108";
 		reg = <0x48>;
@@ -278,6 +329,40 @@ &smbb {
 	status = "okay";
 };
 
+&tlmm {
+	accel_int_default: accel-int-default-state {
+		pins = "gpio1";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+		output-disable;
+	};
+
+	mag_int_default: mag-int-default-state {
+		pins = "gpio38";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+		output-disable;
+	};
+
+	mag_reset_default: mag-reset-default-state {
+		pins = "gpio62";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+		output-high;
+	};
+
+	reg_lcd_default: reg-lcd-default-state {
+		pins = "gpio31", "gpio33";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+		output-high;
+	};
+};
+
 &usb {
 	extcon = <&smbb>;
 	dr_mode = "peripheral";

-- 
2.45.2

