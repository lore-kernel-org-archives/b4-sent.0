From: David Heidelberg <david@ixit.cz>
Date: Tue, 21 Oct 2025 13:53:05 +0200
Subject: [PATCH v4 5/7] arm64: dts: qcom: sdm845-oneplus: Implement panel
 sleep pinctrl
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251021-s6e3fc2x01-v4-5-5e3ee21c688a@ixit.cz>
References: <20251021-s6e3fc2x01-v4-0-5e3ee21c688a@ixit.cz>
In-Reply-To: <20251021-s6e3fc2x01-v4-0-5e3ee21c688a@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1553; i=david@ixit.cz;
 h=from:subject:message-id; bh=ojFoQ3nmgXFa6brSu0i4y7xk0ivDDVrkpAAIpMNxPBQ=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBo93QhGUWPwsDLQX/S4Ji9ihyCdz32C3uI7IHz7
 Ec7HIEqTquJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaPd0IQAKCRBgAj/E00kg
 cgMgD/9TkrWg/mJUQaXp3FmThwVY5VV227lcdjmNTnPhmymZAA30WGukQfNt2vZCk+rCrR+RExp
 j4W1AZ+kIObqR4zqfEvP6Hsi7IeWM8a7RLbRxE6Zhm0XzdvGyZHTh/gss3oTv52aqOMFcugFrAm
 kJGTb3nxQrvq0oxlvtomkDyctnjStgdWsAg7wN+LSZibq1X7Wb3z0Cu9WoF0+k/2ZUbHmxDCOgC
 eTrSCHq9/XgnCPn89jfEKWWolfIGU1JS/MYF16zhyCjvq7RzgyJSeqWkDkHngJUqlYO9Zo6lA1m
 f0l+RPesMKt3LOjwrUvTxtZDcaa1FFCAfRpGDyhMXvEPBFIQscpiwko15+UeJopcujKVS7GEwWc
 Q2NEwhm1Yk4eW6Fniev1JRkVn5fmtT+luk3TCzyfkzw3R5zr4kul3lFbUnVx70OrRGB49B+xsuL
 P1IdimovTumVt9TFy6OsakUsrTEeWxAVLhEuO/tj9F2YpgwtM40sp+cO/97mQC+lJXoaEkTBeM4
 s+lEA3peBRifYBjHvd4P5cdA3Kaj+4Ib6LQNHUcB+3FTxhUmNJVXORR1f5tUQgkIVx5JOY7bYRY
 YIR2gsPVl1bkXpfof4P7uldLMl67znsw1KVnnw0dwHSaU0yKd1swuPZ3yXzU4I9gLbAGM3KfJxc
 hjhoaoShycK0cQA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We can DSI pin from 8mA to 2mA while suspend, do it.

In theory, should give us extra 2 hours of idle battery life.

cosmetic: sort pinctrl properties.

Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 26 +++++++++++++++++++++-
 1 file changed, 25 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index 9b571fab9c80c..a8e87507d667b 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -462,8 +462,9 @@ display_panel: panel@0 {
 
 		reset-gpios = <&tlmm 6 GPIO_ACTIVE_LOW>;
 
-		pinctrl-names = "default";
 		pinctrl-0 = <&panel_default>;
+		pinctrl-1 = <&panel_sleep>;
+		pinctrl-names = "default", "sleep";
 
 		port {
 			panel_in: endpoint {
@@ -870,6 +871,29 @@ te-pins {
 		};
 	};
 
+	panel_sleep: panel-sleep-state {
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
+			drive-strength = <2>;
+			bias-pull-down;
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

-- 
2.51.0

