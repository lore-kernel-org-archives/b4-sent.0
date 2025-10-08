From: David Heidelberg <david@ixit.cz>
Date: Wed, 08 Oct 2025 16:05:33 +0200
Subject: [PATCH v2 6/7] arm64: dts: qcom: sdm845-oneplus: Group panel
 pinctrl
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251008-s6e3fc2x01-v2-6-21eca1d5c289@ixit.cz>
References: <20251008-s6e3fc2x01-v2-0-21eca1d5c289@ixit.cz>
In-Reply-To: <20251008-s6e3fc2x01-v2-0-21eca1d5c289@ixit.cz>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jessica.zhang@oss.qualcomm.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, Sam Ravnborg <sam@ravnborg.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1999; i=david@ixit.cz;
 h=from:subject:message-id; bh=5GvFr+5VUexi+/uUvkg17qDYTvfgOqthqFHsVHOQK9s=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBo5m+pSpDF0SJRbsFIkbOPU53ElSfE6bo5AUBbn
 l3JVHR30AiJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaOZvqQAKCRBgAj/E00kg
 coq/EACxm8V+s0Y/GDc4+gVDvkY1g+g4y3f0RhQEwClSHssMxMNmbCxY7f9eueSAqwxXBfrWr4z
 4aFp7r9k9rlwakNfvhT3ipco+ytuYDQqttfn5Ss/HXY77th0irTQqReLr/d3kGWR4OkGM+KAz61
 5EcmdBz51zP8WI7VAS1dDnMVJhve6iF5ZFf0hDKmQD0wczm1TC7r0sfaSIvC+wyeJ1V5Q4P49ly
 IPBQuOaCw6Sw5x4jlb/0Z4g6VaaSAkcj3Chjb9qOEgvVCKunKWPNTFjXOKtCCSbj6gOeIzyHz02
 thIkj0TS/br95Z9InQZsug2jkT5OEMBoZ3de7K8scYn/22869iTEoT0tlWn/D8cu1PVYy2zd7AJ
 KTwcQS8/FasiJzL7JH508Q3EFuOfAwSGQ+IS5j/4P2Cjk/7pxhtj4Imlbgvp8KeNLHS9UUavvfU
 qURiaqUyGbokyCe7HYITHjVvgpgd3PinlpQ84Xa3UitAl+9wMYbVq7NpxqP2F+8WilgUFR5jqsS
 7XDDEsKKrYdoGZSgly4Xthg4Zo+c/J6yo/Ow3zqbYAwsHvPKLiHDAYcfWHjyqStub7JINVR6w7h
 FaFKkEJRehg5RLyqYr+6PR2GKK7eiEucsqaY4ttAgLsaM05yANZ56h5PoXhuZhuG33SCxmiatqY
 nGSVzyYqbupIkXA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As these pins won't be used outside the group, let's group them.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 46 +++++++++++-----------
 1 file changed, 24 insertions(+), 22 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index 75989b377f8bc..c216369fae237 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -464,7 +464,7 @@ display_panel: panel@0 {
 		reset-gpios = <&tlmm 6 GPIO_ACTIVE_LOW>;
 
 		pinctrl-names = "default";
-		pinctrl-0 = <&panel_reset_pins &panel_te_pin &panel_esd_pin>;
+		pinctrl-0 = <&panel_default>;
 
 		port {
 			panel_in: endpoint {
@@ -848,6 +848,29 @@ panel_poc_default: poc-state {
 		bias-disable;
 	};
 
+	panel_default: panel-default-state {
+		esd-pins {
+			pins = "gpio30";
+			function = "gpio";
+			drive-strength = <2>;
+			bias-pull-down;
+		};
+
+		reset-pins {
+			pins = "gpio6";
+			function = "gpio";
+			drive-strength = <8>;
+			bias-disable;
+		};
+
+		te-pins {
+			pins = "gpio10";
+			function = "mdp_vsync";
+			drive-strength = <2>;
+			bias-disable;
+		};
+	};
+
 	tri_state_key_default: tri-state-key-default-state {
 		pins = "gpio40", "gpio42", "gpio26";
 		function = "gpio";
@@ -862,27 +885,6 @@ ts_default_pins: ts-int-state {
 		bias-pull-up;
 	};
 
-	panel_reset_pins: panel-reset-state {
-		pins = "gpio6";
-		function = "gpio";
-		drive-strength = <8>;
-		bias-disable;
-	};
-
-	panel_te_pin: panel-te-state {
-		pins = "gpio10";
-		function = "mdp_vsync";
-		drive-strength = <2>;
-		bias-disable;
-	};
-
-	panel_esd_pin: panel-esd-state {
-		pins = "gpio30";
-		function = "gpio";
-		drive-strength = <2>;
-		bias-pull-down;
-	};
-
 	speaker_default: speaker-default-state {
 		pins = "gpio69";
 		function = "gpio";

-- 
2.51.0

