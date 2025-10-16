From: David Heidelberg <david@ixit.cz>
Date: Thu, 16 Oct 2025 18:17:00 +0200
Subject: [PATCH v3 5/8] arm64: dts: qcom: sdm845-oneplus: Group panel
 pinctrl
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251016-s6e3fc2x01-v3-5-ce0f3566b903@ixit.cz>
References: <20251016-s6e3fc2x01-v3-0-ce0f3566b903@ixit.cz>
In-Reply-To: <20251016-s6e3fc2x01-v3-0-ce0f3566b903@ixit.cz>
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
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1999; i=david@ixit.cz;
 h=from:subject:message-id; bh=cOk70bxJ/JKLB2gGDnhwyKrowfthFtlbdZEpsLGu6fg=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBo8Rp5dXzixReqnxBQn91MskJ7JKTVBcxXgU+2z
 UsHwYtKoPWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaPEaeQAKCRBgAj/E00kg
 coTVEADCb7p7y1kQI4tNrkFppwtLp2UaK73uTbhZGA8nMoyHkqdtc0h2/nZQa/9VGZEXruifOvv
 h5P2cmxgKOIT3xCCXPi6cZUrlQM20/vJLkfiLugNc+bvoc2MTrI90gh/TiGp3zdXOHPlWHJJZjv
 1FWBCqqbCHByNvkhFKJXKZ+bL/SI9dR90gsCG7FQ/jUBPUQiyR/VJ9zZ1RPlMW3BfhGTYxEvBYb
 cHEXcGxEaAZe9fPGhCM7xJAWPSVmtxLjYCc14NZa67L0phGamvjEGHDG5Fjq5/c7srBSvSK1d+X
 Q6oSmMbwQWcgmS7p0m3Ll7K954kqz3BawHt4Pjd83bwZa647Cui0U29fUSDGp/2ABx6Cijt59Aa
 YVZXuZbbzV8fStCRb5dADDlluRVNDOx5hL9UOTqUYSNyWo9AdgQrDGyev8sWQ36yY8pf/3ZgKeB
 fmc6doFjFqnee/FHhUXqTi0YoA11H7pRjY9+pn5w+uN4EBFAyW+wekhr5ep5oMk06zV2wflCrTC
 qSeAv9tm+mmWRM7/Ix4fdxE9e8RbW/I3F7btLvsITU9WFvnAR/FoJfc0OgmobUBgczhm7Q08N82
 vGfbq9U2LJaiCGi8vQI+lsqGtm8Uc0tODxchK8Af3qB0/cVF1UuDm+Y8K+8/E40JqVM9L9CAHD0
 Y8X79JuUS+AJr1A==
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

