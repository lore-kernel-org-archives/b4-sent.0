From: Rudraksha Gupta <guptarud@gmail.com>
Date: Wed, 31 Jan 2024 01:04:47 -0800
Subject: [PATCH v2 2/2] ARM: dts: qcom: msm8960: expressatt: Add mXT224S
 touchscreen
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240131-expressatt_mxt224s_touchscreen-v2-2-4463ae0414b5@gmail.com>
References: <20240131-expressatt_mxt224s_touchscreen-v2-0-4463ae0414b5@gmail.com>
In-Reply-To: <20240131-expressatt_mxt224s_touchscreen-v2-0-4463ae0414b5@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706691886; l=1620;
 i=guptarud@gmail.com; s=20240120; h=from:subject:message-id;
 bh=4Gi3ILnitkF34hh7B1r4k2VP7IMCG7Hjj/6AwpaU750=;
 b=aToJeq7bdKkloeO+pbha6Cimk77XwMqWEyri7P45ecOMZaHTkdN4Cy1Gcpli+x+loyRp/LVf6
 SNTmxUSdiqZDmTcl8lGZNOvhSgthxCwy1F5lkuFNrb/xQprQc/fsi0B
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=RGmug3GRHS4XYTXDcT2VrlTGXlEF2gY4L9/swGIU1ko=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240120 with auth_id=114
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add mXT224S touchscreen

Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
 .../dts/qcom/qcom-msm8960-samsung-expressatt.dts   | 31 +++++++++++++++++++++-
 1 file changed, 30 insertions(+), 1 deletion(-)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts b/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
index 47e0e26ad9f0..af6cc6393d74 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
+++ b/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
@@ -85,6 +85,27 @@ &gsbi1_spi {
 	status = "okay";
 };
 
+&gsbi3 {
+	qcom,mode = <GSBI_PROT_I2C>;
+	status = "okay";
+};
+
+&gsbi3_i2c {
+	status = "okay";
+
+	// Atmel mXT224S touchscreen
+	touchscreen@4a {
+		compatible = "atmel,maxtouch";
+		reg = <0x4a>;
+		interrupt-parent = <&msmgpio>;
+		interrupts = <11 IRQ_TYPE_EDGE_FALLING>;
+		vdda-supply = <&pm8921_lvs6>;
+		vdd-supply = <&pm8921_l17>;
+		pinctrl-names = "default";
+		pinctrl-0 = <&touchscreen>;
+	};
+};
+
 &msmgpio {
 	spi1_default: spi1-default-state {
 		mosi-pins {
@@ -123,6 +144,14 @@ gpio_keys_pin_a: gpio-keys-active-state {
 		drive-strength = <8>;
 		bias-disable;
 	};
+
+	touchscreen: touchscreen-int-state {
+		pins = "gpio11";
+		function = "gpio";
+		output-enable;
+		bias-disable;
+		drive-strength = <2>;
+	};
 };
 
 &pm8921 {
@@ -285,7 +314,7 @@ pm8921_l16: l16 {
 		};
 
 		pm8921_l17: l17 {
-			regulator-min-microvolt = <1800000>;
+			regulator-min-microvolt = <3300000>;
 			regulator-max-microvolt = <3300000>;
 			bias-pull-down;
 		};

-- 
2.43.0

