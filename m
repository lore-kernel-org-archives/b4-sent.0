From: David Heidelberg <david@ixit.cz>
Date: Mon, 03 Nov 2025 12:45:51 +0100
Subject: [PATCH v6 2/4] arm64: dts: qcom: sdm845-oneplus: Group panel
 pinctrl
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251103-s6e3fc2x01-v6-2-d4eb4abaefa4@ixit.cz>
References: <20251103-s6e3fc2x01-v6-0-d4eb4abaefa4@ixit.cz>
In-Reply-To: <20251103-s6e3fc2x01-v6-0-d4eb4abaefa4@ixit.cz>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, Sam Ravnborg <sam@ravnborg.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2083; i=david@ixit.cz;
 h=from:subject:message-id; bh=lb+GbJGxJgK2d3fIap7gSBx+1yLKhKOT53wmKqsWzJ0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpCJXuX6DPV5P6vzVpZk9sr742nGjlNUVFjnSMP
 7CU2G3IQ3aJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaQiV7gAKCRBgAj/E00kg
 cu3LEAC4YNe6NXKR36r9BEgn0wcY439gaL5NFBykgcsKfbkPo0ZqQk0stJEqFTctgj/oPSYcBmx
 DNhpeWgyrfqKwpWFUOvNiNO7xIdF/iAKd75Qalloa2bUkil9OpBNq3CMSCa/kSGPpOQ9DdGSwt4
 3fr4QJ+Hdn3WjQMPpyNbdWkHWTubj4+io++e14+lSLdcx8x4ICzF4/cWRY0dGjinZRRJWrDgfqV
 bcay7/QcBtp40Q+0e7YjERk14vJFPnMGnby/dAPy8F5fnX5721dDyEMolu2VsWuxdmPL7qMi4kF
 lnzSS2tQvI5TywkWBxC8MA/OvobCpwtL2IAoGnOQVi4vkN2D+6WvijewsQBOKu5eByWXCfJ9nSN
 MPkEyP4qCrakEzkMkSTx9IJro5Yzl/bIu2ZhcCa3R2rUPTbuXlYG4j9dXDOC32j7TYKyTMZ/e/u
 v+dounzXqu1/nYtQXicqAC6+Gah1SpAC/o48ce7G+wQOkWuIbYH24Ahm3OGC/uFtHxxqBUMzwU7
 qIVn2kpGIX+sEqiJOMjTYcRBV7HnVwuJdO1/c0IjuDw6712WWufuzrnKX32F6FTKGBAfF9aCdr4
 WyrPubX7XW/o/OQ1Dk5NMcBDTb209id3RmFfddLRjlypZr78Mx5NoA0FJM8bKRrHFyAZ8dcB6LY
 i8EaDgadXjlhNTg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As these pins won't be used outside the group, let's group them.

Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 46 +++++++++++-----------
 1 file changed, 24 insertions(+), 22 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index d619b710c63fe..d59a5e8cdeb2c 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -450,7 +450,7 @@ display_panel: panel@0 {
 		reset-gpios = <&tlmm 6 GPIO_ACTIVE_LOW>;
 
 		pinctrl-names = "default";
-		pinctrl-0 = <&panel_reset_pins &panel_te_pin &panel_esd_pin>;
+		pinctrl-0 = <&panel_default>;
 
 		port {
 			panel_in: endpoint {
@@ -841,32 +841,34 @@ alert_slider_default: alert-slider-default-state {
 		bias-disable;
 	};
 
-	ts_default_pins: ts-int-state {
-		pins = "gpio99", "gpio125";
-		function = "gpio";
-		drive-strength = <16>;
-		bias-pull-up;
-	};
+	panel_default: panel-default-state {
+		esd-pins {
+			pins = "gpio30";
+			function = "gpio";
+			drive-strength = <2>;
+			bias-pull-down;
+		};
 
-	panel_reset_pins: panel-reset-state {
-		pins = "gpio6";
-		function = "gpio";
-		drive-strength = <8>;
-		bias-disable;
-	};
+		reset-pins {
+			pins = "gpio6";
+			function = "gpio";
+			drive-strength = <8>;
+			bias-disable;
+		};
 
-	panel_te_pin: panel-te-state {
-		pins = "gpio10";
-		function = "mdp_vsync";
-		drive-strength = <2>;
-		bias-disable;
+		te-pins {
+			pins = "gpio10";
+			function = "mdp_vsync";
+			drive-strength = <2>;
+			bias-disable;
+		};
 	};
 
-	panel_esd_pin: panel-esd-state {
-		pins = "gpio30";
+	ts_default_pins: ts-int-state {
+		pins = "gpio99", "gpio125";
 		function = "gpio";
-		drive-strength = <2>;
-		bias-pull-down;
+		drive-strength = <16>;
+		bias-pull-up;
 	};
 
 	speaker_default: speaker-default-state {

-- 
2.51.0

