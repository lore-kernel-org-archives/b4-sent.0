From: David Heidelberg <david@ixit.cz>
Date: Sun, 08 Nov 2026 12:32:31 +0000
Subject: [PATCH v3 10/10] arm64: dts: qcom: sdm845-google-crosshatch: Add
 display panel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-crosshatch-panel-v3-10-87dd4ec4f7cc@ixit.cz>
References: <20261108-crosshatch-panel-v3-0-87dd4ec4f7cc@ixit.cz>
In-Reply-To: <20261108-crosshatch-panel-v3-0-87dd4ec4f7cc@ixit.cz>
To: Dzmitry Sankouski <dsankouski@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Petr Vorel <petr.vorel@gmail.com>, dri-devel@lists.freedesktop.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2243; i=david@ixit.cz;
 h=from:subject:message-id; bh=QFnr4Iy2wJCXJX07eMOq9LU+21ab3o9NMfZAs83u37o=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq8GvfzCKzQDlWDUrFr9huD1SqWucMmluVS6GAz
 a2Dsr/3ew+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCavBr3wAKCRBgAj/E00kg
 ch4eD/4ytefeCYqNZf8oeoLbcDiX7Zgzf6Y1sezaokg1spJHnY1ZPj2xnCFHYvqnWzMgYbOhYeP
 z5AItIq8dZUYOy/OoGjwtQoAchWCkslWuzob91KOCEHJMd+yhDVDuS4iq4nUxikZ/J1r6R9Pqhb
 lYDmaKvmuofYstmkNeqjPvMUze507RgNTxXhll+RZM7UO/KNlIq2yfVYOD+oMXqX5fiNnP31q/m
 Ay59dOqVLmv8jGjLsj5ZaEhKD4URmdf4+6/mMU7+PtxJyttjs+XXx0h9NcPxciUAgLDlD0DiER6
 Yktm/bVlbCiFMozz76HorYBHNqsCK6E+VoRZhsZYgpGAsiaAZOJKFMymfbaFREXuKpKcMfMwtSc
 dWZgKWX6DU+EPI8Momk6cSShd5pOMnCEjy2u4xFM+IEHGvbGExQC/Fg76UTPkVqJXszYX8TTt5N
 4A5JgYv6t5PiU8YCuN5L8tQBGHKW298eEumEbVXd0yCGc3s/rZ++D8W5apm+B9/R/9+0Xhm1p3b
 mIkLkGLyepA5Zbv+XvTD9B5AlxCZwrlKv/3GCv0+3UbsDREkhrCr/mHakly6Qu4ytP8S16L2opX
 XgoPkINdRbS7P1sZ/7YpopjtptO/wGLZlaCgN3Zk34PfpvXoL0vWHcjUup607G2Km6MoYFPFWJ+
 AAzjnsjRj3QO7wg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Wire up the Samsung AMB630QY01 AMOLED panel on the Pixel 3 XL and drop
the MDSS/DISPCC disables that kept simple-framebuffer alive.

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

