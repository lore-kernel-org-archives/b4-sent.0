From: David Heidelberg <david@ixit.cz>
Date: Sun, 08 Nov 2026 12:32:30 +0000
Subject: [PATCH v3 09/10] arm64: dts: qcom: sdm845-google: Move panel pins
 into common
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-crosshatch-panel-v3-9-87dd4ec4f7cc@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2187; i=david@ixit.cz;
 h=from:subject:message-id; bh=0xoSE8g8hQhjUJDUkLj1oNslYQIjrBTjTW8DNBjsTIM=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq8GvfT+vBvIhZSx7g4ypyveRa4g157FIz9bUyO
 H2SIQMe3UOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCavBr3wAKCRBgAj/E00kg
 cq/gD/0YpTLcxsgciJ4LlTG4ERBQqJQsYwC2qyT7ubIjkK2iS5d8tOHXMqkaKkibUEHAoMhjZte
 Kb2cUIrDZbauMSSpeg1Ca61DT5WwSAhDyRn9Z7LqiGKRZciSiezkJPOZgBZNAlpfUUhXq+a2+13
 nomOP+GXwZy24+hz2itzxpMiwHrQO6PjTOAT93oAOY4jlPlTCJF+vhms0JKHJJA2giNh/+oIma+
 ryjHRtTbbsZP45WLGaAKYFH5gddSEjS+psnTvG1auVqwoNi68kdgQKsc1/nyJVo3G49eh+0BlFR
 HjjvceC/uMY6OS2TPu88bP43omcsYVSW2m7+vXhwYyOfXlEBIi/jJ5HbHy4HgfFhvKPsOvL5NiN
 bQQa1qADQUmmeHtotvd8RDkJi+P2CNrxRZmTcE+JcOv3aULZI4MiIpV38CCo8hOJUkngDSlew08
 DlYHBfp0+KMocEVWRwOKhbADKTJOOYE7zgiVRcfxHqG98Zdp1WHGTHI1vt6cUBjlx2e3ilqJVOT
 6BL7QlDre/pMo+/A98PgreHOWicfbq8M8FPue0ZuR1NxRfg2FfYVN9TdJ6f7nEnhpaMtXFAejCj
 lY0JfSjwVik/s1Z3PZnjt7k6NLorHd1b/Og7bJ4NZzwJhUKyAOSsnUjPHdh0vW0qtx0y/twLn71
 2pGskKNNEMBrKsg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Both devices share the pinctrl configuration.

Reviewed-by: Petr Vorel <petr.vorel@gmail.com>
Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts | 18 ------------------
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi  | 16 ++++++++++++++++
 2 files changed, 16 insertions(+), 18 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts b/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts
index fa89be500fb85..a000c75494f1c 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-blueline.dts
@@ -61,29 +61,11 @@ &mdss_dsi0_out {
 };
 
 &mdss_dsi0_phy {
 	vdds-supply = <&vdda_mipi_dsi0_pll>;
 
 	status = "okay";
 };
 
-&tlmm {
-	panel_default: panel-default-state {
-		reset-pins {
-			pins = "gpio6";
-			function = "gpio";
-			drive-strength = <8>;
-			bias-disable;
-		};
-
-		te-pins {
-			pins = "gpio12";
-			function = "mdp_vsync";
-			drive-strength = <2>;
-			bias-pull-down;
-		};
-	};
-};
-
 &wifi {
 	qcom,calibration-variant = "Google_blueline";
 };
diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
index f1379857e2742..d54cb47cdf95b 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
@@ -473,16 +473,32 @@ &qup_uart9_tx {
 	drive-strength = <2>;
 	bias-disable;
 };
 
 &tlmm {
 	gpio-reserved-ranges = < 0 4>, /* SPI (Intel MNH Pixel Visual Core) */
 			       <81 4>; /* SPI (most likely Fingerprint Cards FPC1075) */
 
+	panel_default: panel-default-state {
+		reset-pins {
+			pins = "gpio6";
+			function = "gpio";
+			drive-strength = <8>;
+			bias-disable;
+		};
+
+		te-pins {
+			pins = "gpio12";
+			function = "mdp_vsync";
+			drive-strength = <2>;
+			bias-pull-down;
+		};
+	};
+
 	nfc_default: nfc-default-state {
 		enable-pins {
 			pins = "gpio25";
 			function = "gpio";
 			drive-strength = <2>;
 			bias-pull-down;
 		};
 

-- 
2.55.0

