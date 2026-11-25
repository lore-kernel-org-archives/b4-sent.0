From: David Heidelberg <david@ixit.cz>
Date: Wed, 25 Nov 2026 19:12:53 +0100
Subject: [PATCH v4 9/9] arm64: dts: qcom: sdm845-google-crosshatch: Add
 display panel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-crosshatch-panel-v4-9-120adc58e737@ixit.cz>
References: <20261125-crosshatch-panel-v4-0-120adc58e737@ixit.cz>
In-Reply-To: <20261125-crosshatch-panel-v4-0-120adc58e737@ixit.cz>
To: Dzmitry Sankouski <dsankouski@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: Marco Mattiolo <marco.mattiolo@hotmail.it>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Petr Vorel <petr.vorel@gmail.com>, dri-devel@lists.freedesktop.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>, Abel Vesa <abel.vesa@oss.qualcomm.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2357; i=david@ixit.cz;
 h=from:subject:message-id; bh=A+2cpgTKZsuyPaY65ARPRtY967sq4BpFSqvnoaIMPGw=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrByUe51AB0/xnlO5MuDoBhNQVQ6rTFJH08qj84
 xflJayGh7yJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawclHgAKCRBgAj/E00kg
 crNHD/sFUXcq1AMMwnsUYItZGc7eUg+E1Qu47rIXPgA4HXXxY4PgxEvZvvq+jywnV8WTCxsGVt1
 JUkeo1HRf5nOiU0A2aAr0vtsvm4lvrS0a0xfWOw3TSJeGkoicz1z5+ZGRrba+u0wamzr6alQ2lO
 1nz3AYZbzrJuqC8obgXo8r8Bb3w3ylg9xJs//RhqHBkqiMnTH72z79S6bObZY4N4UBmWlpEuMbc
 lQoFWjd0vGs06jdqAM3LHbGTd2eA7bge+5rRwRQXc1XygeSTkfCdx7+LH+J58c0nM8HkJVaTxSc
 yVfB3N8JPwkao/+jrW+Q+VexMZlcQrqy87k0dgo+zFWx735IqC0tY1JuE8RQSmntdd99Tuv3KyK
 w1cypzsmdm0bzxkSc+gs58+9fqKEdYt/RtvqXfSw4TSfKVuJl/WPm2QEKl+dOM4MzRLH+h+sScE
 QgXs6Kx+E76KfrAhd+nILkEFD0jqODC5IQ0M2E+juKDjLPzaBLfVVvxtamyA5qHpeboC/pIrM/7
 pKj//CGYokosPlAdswNIJThs8M3cumXuF1+KtJQxfQlhwdQz9l25yenmjPA3AItAMtw52KiNagQ
 jn9zTy+QNe/w3s4gB8R0C9iZ0ZBrfzLbuT9+sByXvsMA29MBpRxaX+KzGGD0epaczvNZiOSN2ve
 FPSSa48rbITYYAg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Wire up the Samsung AMB630QY01 AMOLED panel on the Pixel 3 XL and drop
the MDSS/DISPCC disables that kept simple-framebuffer alive.

Reviewed-by: Abel Vesa <abel.vesa@oss.qualcomm.com>
Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../boot/dts/qcom/sdm845-google-crosshatch.dts     | 60 +++++++++++++++++++---
 1 file changed, 52 insertions(+), 8 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-crosshatch.dts b/arch/arm64/boot/dts/qcom/sdm845-google-crosshatch.dts
index 2a81ca1d00b1b..3b788757b7303 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-crosshatch.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-crosshatch.dts
@@ -10,27 +10,71 @@ / {
 };
 
 &battery {
 	charge-full-design-microamp-hours = <3480000>;
 	voltage-min-design-microvolt = <3600000>;
 	voltage-max-design-microvolt = <4400000>;
 };
 
-&dispcc {
-	/* Disable for now so simple-framebuffer continues working */
-	status = "disabled";
-};
-
 &framebuffer0 {
 	width = <1440>;
 	height = <2960>;
 	stride = <(1440 * 4)>;
 };
 
-&mdss {
-	/* Disable for now so simple-framebuffer continues working */
-	status = "disabled";
+&ibb {
+	regulator-min-microvolt = <4600000>;
+	regulator-max-microvolt = <6000000>;
+	regulator-over-current-protection;
+	regulator-pull-down;
+	regulator-soft-start;
+};
+
+&lab {
+	regulator-min-microvolt = <4600000>;
+	regulator-max-microvolt = <6000000>;
+	regulator-soft-start;
+	regulator-pull-down;
+};
+
+&mdss_dsi0 {
+	vdda-supply = <&vdda_mipi_dsi0_1p2>;
+
+	status = "okay";
+
+	panel@0 {
+		compatible = "samsung,s6e3ha8-amb630qy01";
+		reg = <0>;
+
+		vdd3-supply = <&vreg_l14a_1p8>;
+		vci-supply = <&vreg_l28a_3p0>;
+		vddpos-supply = <&lab>;
+		vddneg-supply = <&ibb>;
+
+		reset-gpios = <&tlmm 6 GPIO_ACTIVE_LOW>;
+
+		pinctrl-0 = <&panel_default>;
+		pinctrl-names = "default";
+
+		port {
+			panel_in: endpoint {
+				remote-endpoint = <&mdss_dsi0_out>;
+			};
+		};
+	};
+};
+
+&mdss_dsi0_out {
+	data-lanes = <0 1 2 3>;
+	remote-endpoint = <&panel_in>;
+	qcom,te-source = "mdp_vsync_e";
+};
+
+&mdss_dsi0_phy {
+	vdds-supply = <&vdda_mipi_dsi0_pll>;
+
+	status = "okay";
 };
 
 &wifi {
 	qcom,calibration-variant = "Google_crosshatch";
 };

-- 
2.55.0

