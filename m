From: David Heidelberg <david@ixit.cz>
Date: Tue, 21 Oct 2025 13:53:04 +0200
Subject: [PATCH v4 4/7] arm64: dts: qcom: sdm845-oneplus: Group panel
 pinctrl
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251021-s6e3fc2x01-v4-4-5e3ee21c688a@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2066; i=david@ixit.cz;
 h=from:subject:message-id; bh=KTrLESxmqDJURSGJs44NIqxmLK4hwbD8ph2DGEQH+CE=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBo93QhYI72W+xL1iYR88xJCffoEAu642WnVDrao
 s6SRRtq/dOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaPd0IQAKCRBgAj/E00kg
 clv6EACVHWSXf8INehHmARalnfS2d8uET3mOQRebSwlbgVKmeQntR6cmrg9LGNOck6cod4zRIzC
 ZSB0DUjS1eKC+Dy6HM6gxpNI9F1NWIlv8cC6X6tj4isG+wUXeu6fGvTXrJk9m67fh0ZxFjSRSbd
 o7BBbzrWtgqpGbjtLpxLu0tRnhaULOF/5lHWcCvTMUHcSjcx99arDFSVd8/+4QPUtdjBhVCcLwP
 Naqj3RIad4j5qHt1t9uiowVqpvxQ0K1hYjn64AAajW9+5mAEPkOD7ZbspRc6njSAQpb0yktcpbL
 LNUTS6cXL6IV7R0GlSMFkTEYMy6s1TS/fBz18y+/iMcm0ZEuL0n72OOK3Palr34WOjf3M+UsQ7j
 HkTfK1mWg5HbSPCrVx+JlpboizW8Z6zexy/3xPkIgaMSZ2iSJH7s0UhAQhlGie5JYWdqwXM4oNK
 9KOn/Jl1kz0VYLneK4yuSO0W4F6CKEbOpstc9T5iMwwX8THJ0sZ+o/Kn9ty1Gk1sFTou6VHleYo
 aIJ7NrWw0lLtlsUw1zSTyLzBWrjXOYOzHiriR5iFIZNhMjIrdw5DalOo2Px9hQKVu/ZBATfSkyM
 lAvI518j9mmulDWEEzi0cpU7ek08GELVHfoK+H5xdejDqPcZwFEhdItAjCoZF90n3mFeH2808qg
 WCAHQYlKOUi/xFg==
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
index 1cf03047dd7ae..9b571fab9c80c 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -463,7 +463,7 @@ display_panel: panel@0 {
 		reset-gpios = <&tlmm 6 GPIO_ACTIVE_LOW>;
 
 		pinctrl-names = "default";
-		pinctrl-0 = <&panel_reset_pins &panel_te_pin &panel_esd_pin>;
+		pinctrl-0 = <&panel_default>;
 
 		port {
 			panel_in: endpoint {
@@ -847,6 +847,29 @@ panel_poc_default: poc-state {
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
@@ -861,27 +884,6 @@ ts_default_pins: ts-int-state {
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

