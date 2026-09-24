From: David Heidelberg <david@ixit.cz>
Date: Thu, 24 Sep 2026 16:01:38 +0200
Subject: [PATCH v2 10/11] arm64: dts: qcom: sdm845-google: Move panel pins
 into common
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260924-crosshatch-panel-v2-10-08d5c7bf72fc@ixit.cz>
References: <20260924-crosshatch-panel-v2-0-08d5c7bf72fc@ixit.cz>
In-Reply-To: <20260924-crosshatch-panel-v2-0-08d5c7bf72fc@ixit.cz>
To: Dzmitry Sankouski <dsankouski@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: Petr Vorel <petr.vorel@gmail.com>, dri-devel@lists.freedesktop.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2126; i=david@ixit.cz;
 h=from:subject:message-id; bh=tmWWZMnJdIiah2Ra+OBrkILlOUVZlqnIlNSnhIb5uBA=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqtS09f2wlNMXFy/rZ1CQYqSibfi/pXLBtMVeu6
 1wnc12nzs2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCarUtPQAKCRBgAj/E00kg
 ct0AEACyeppnguTHriwBUu+k8lbdUGxD74whGrWZu8DAEYfw1G06WQYsn5KpfTWmNkAkLo/vewT
 mBgQJexOmb34ahjlHFOfgNlMs/ocRMHkzxEUCJaeWLYGnZr+ibyXj1+EyEupXSEmsrh1ygyXW6I
 MLtYVuoB3kjTlGOMagMPCFKjLI+AS8ZeCHpWg/hmNH/MTmUX0sx/Hh+5aXgX/mjl2WVLeXouaFR
 A8XhBYI/ySZZKVIH0r06QiVj7OVwhEdbe91JxOuqBeMDaNM4pgl1clv9ZIJIt7EYyMNzxQFZyd7
 FjSixpSOt2ol6xFTKCr0lUOj48Rb15v7st6H99cklzd0KOyFbSM+YOgjxH21H5/3ZTbK7kr3FlN
 DQOjvgV+9n5V68DvoyhdJDqtETDxXoN9DANks5UHEzRCeUeN/nXK1RXqxX3+PaC5WI45F6UeUmt
 fySCAFFdJUG4fp07YWdw3M3Wo0wT2zmfyjxIl1/eXmXkQ+PmGZEfVX3kvbN3PUEKCvDJYFyGccI
 66jrb5pQsElKZEhjYaO7eLhXg/8SDSiiiTggCGt73Zb7mYbpH9GhOJZpxQ1mgxMWrPAdTcvGnKa
 jzqonpUah+XR9NSSiAFuavk9Nd2ELcQbb5QtuLMp8Ohg6Vh0rLY8SWVQpM676fIHCmasq+p04rs
 jzBkIthjorSBAlA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Both devices share the pinctrl configuration.

Reviewed-by: Petr Vorel <petr.vorel@gmail.com>
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

