From: David Heidelberg <david@ixit.cz>
Date: Sun, 20 Sep 2026 13:05:54 +0200
Subject: [PATCH 11/11] arm64: dts: qcom: sdm845-google-crosshatch: Add
 display panel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260920-crosshatch-panel-v1-11-de6e9512da96@ixit.cz>
References: <20260920-crosshatch-panel-v1-0-de6e9512da96@ixit.cz>
In-Reply-To: <20260920-crosshatch-panel-v1-0-de6e9512da96@ixit.cz>
To: Dzmitry Sankouski <dsankouski@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2261; i=david@ixit.cz;
 h=from:subject:message-id; bh=YKxaEQ83IRvBzliLWTENjXhw/HISL/i0Wy+mkQdH9Sw=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqr74JMGGtOVCy+5FmoktcbR/n4ppXAal2NLO7R
 q10RdQV1ueJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaq++CQAKCRBgAj/E00kg
 ctW1D/0TCMNB42Yv7b+MJDGzmZ0Oxcssb79dlYpAQ+BCITQeP6KXWWqM++CKKDcxuzimZQntcot
 hElxWayU7FXW5IgSzTUyWcOEU5mA9RTa3Xh7Wc9hwbvJqzN0Ar7zGwhqee5B0FG2gjDfYRDKspe
 Dbg4OyeBs7YrzLXIdry4nNrOqOCyERtswgI0BvFXRhygqdWLL1jgjPWJHAHStscXCMDVgBecgZG
 SWkOuzD1bMYlP60TJQb+pmC5T7XjLLKBTo5R8/u0Pg01jmPVyr1RQR0uPST43iYnM8Rpr3sOYUh
 HHSAXTw/jYKrMBtLFpE8ojO4QhVCNsHacx/Dy+GZe7DDmrSBmIM9yht6A5uI2//4qehI/+egl2+
 2pCzlZygnYGm1CWnyNP4woTypaIXqwCPY3lJZqfDX8Ocw8tra8nHGotNOT7b048aOt3X10p6d3b
 +X+qyPOMh9CKtmR3qGckBTBFnIJIt/umOQ4FPtAhf4uxxoOOhuCuXVatVEraSLBeKYENyY4gKpF
 7SOpJKzmmEF8pD2EMw+c4oEf9Yrm8TmlN/y14L9ESwX6oVtDaePTMGJkttvJ5Os8KA3fumfQVzY
 yttTbP1S4ZgXzgST9o8b1Q3M01OqhWNmAHzR2xNS2pnYad9ghqWcohcshrVqcjURLarORXtALiv
 GTbDSZxYnvvN/Cw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Wire up the Samsung AMB630QY01 AMOLED panel on the Pixel 3 XL and drop
the MDSS/DISPCC disables that kept simple-framebuffer alive.

Assisted-by: LLM
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

