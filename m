From: David Heidelberg <david@ixit.cz>
Date: Thu, 23 Oct 2025 22:24:29 +0200
Subject: [PATCH v5 5/6] arm64: dts: qcom: sdm845-oneplus: Implement panel
 sleep pinctrl
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251023-s6e3fc2x01-v5-5-8f8852e67417@ixit.cz>
References: <20251023-s6e3fc2x01-v5-0-8f8852e67417@ixit.cz>
In-Reply-To: <20251023-s6e3fc2x01-v5-0-8f8852e67417@ixit.cz>
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
 b=kA0DAAgBYAI/xNNJIHIByyZiAGj6jvuhdaObq7PRbz6REhvlARUPOBsk3a8lzcAfCE3kAQ1eQ
 okCMwQAAQgAHRYhBNd6Cc/u3Cu9U6cEdGACP8TTSSByBQJo+o77AAoJEGACP8TTSSBy88YP/3Gm
 XfoA4EZd63lFay2zcCR7647GB3tHS4bLu/VXW2dvPstWbrgHCMIqLK0G8X7WVdtoPPwQZoJhHjn
 3a+fHeIR/r/TZN6F2L1qoJ5e85XahXf9KlmDiPogPC77eFDi1eBC+IsBDh855OxFE9SkENGnpFx
 kGtkVHsejmfpQey/D5CmxK0XLNR80iyxYGU55JyA9uU0gPQNZ9v8MRLPkPEEOWeOtYfLod9b3af
 nApOrtczzTYfNHYr9UA/g6f9QYLV5v87JfCQNBo8D5r576taBKM4vk/hB/ZoLN22cdgdsEJHLA/
 IErb1Vffegt7an9wrRF5F7huEx/29SS8n0JIUaTL/fZfazmCIYPc5nUoTSk8qDAmD1ArtzxXKLA
 9SK2yyLRVQdEefBAOJPanhUIHk+ksasurNdSzhxdAVaRe4hk/VasG12P/w5qPK/ATLH8P8sorgQ
 mVRWydEfij7eQnejurFTJux8TexA3ounkOrfrnMcYrlPqiJUPC44PF23iqjQVbvLLlYHWDMAWrd
 HHApzz5nRKIfUs/MtUCpGuNiGzWn3DAa50Zm6FFyrrT7pk92FUryRCZJp01DJcwWdVJ1WT8lSpi
 5dnPVppzNPHy1PzbposBTriJRHoouW2kGDkR4qmkQETClWcC1BRBLidSQxFhAFiQeIoId9jnhnP
 MEtwc
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

