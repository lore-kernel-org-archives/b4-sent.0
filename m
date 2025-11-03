From: David Heidelberg <david@ixit.cz>
Date: Mon, 03 Nov 2025 12:45:52 +0100
Subject: [PATCH v6 3/4] arm64: dts: qcom: sdm845-oneplus: Implement panel
 sleep pinctrl
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251103-s6e3fc2x01-v6-3-d4eb4abaefa4@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1523; i=david@ixit.cz;
 h=from:subject:message-id; bh=WQYIgl3txe070LJxSGYEwJAp2NAlPO9ze25JpKPvsUg=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpCJXu3codYCCYJZRipGc1sfbU+nQD0hiJX7MWL
 Op+SBtM62yJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaQiV7gAKCRBgAj/E00kg
 cq/YD/4onliWEg7VvnsY6w+mNK/S6hoSnVahc3ZXt3Ummnspr9ru8MPzmij2H08Bz8L3fW4GsO/
 +oNNlsskD02zjWzOjjxAIY0Qw4tpVpKBUd38qJ/GPsqHkK6kFRZMnSetxIV0mjc3hxgE4JhwQrA
 tO/2ZihiESEPMceoiqVOEbGkNpnJORgl6QfMgXCwdchTH94EyXSQCSHhE7aAb5bJ8o33WJEI4rG
 ilVyE67HSil9nJLz8KAEft0JFl/h38k7w7vol2bWBhyYUEFhKAt1LHNEgQGag7MPxCWGHj7wQGJ
 tsii+MSVC/ZZo/Ogw/zKneng3sw/jhZ7aY3vgYypwCOEJSreEB2xgmCToz5aW1cUMPmXRHgQ46A
 Hil4q0m7xwCqdMT3sadgsaYJr34GN3Sf6eI7GUxiTv/BeJGtiH6gr2fo0RGGNbMvsfgISb62DMt
 wTPvdvVyDUDENWgecMVISkzFHFkUO3QSLH5FTLRA8ngwc7pt9/IXwUyGs/kMAMrt8h+1PUBW/bc
 /Ediq10+hu+AJFhXvJ5iPGTw0qwl3Y+ijkzjU5jj40gSK+3OZQImfmsEAL9UAy49soTx8XboGPG
 s5EbmnDeSRcu1qEv6GWpm4SGzuZTVpd9Yd/PVUq4aQmvLUkn6P2CboMmM3mF6MWho1r5O6JIUMX
 +yFNSKQ5sZWpE8w==
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
index d59a5e8cdeb2c..f00dbc0fff3d4 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -449,8 +449,9 @@ display_panel: panel@0 {
 
 		reset-gpios = <&tlmm 6 GPIO_ACTIVE_LOW>;
 
-		pinctrl-names = "default";
 		pinctrl-0 = <&panel_default>;
+		pinctrl-1 = <&panel_sleep>;
+		pinctrl-names = "default", "sleep";
 
 		port {
 			panel_in: endpoint {
@@ -864,6 +865,29 @@ te-pins {
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
 	ts_default_pins: ts-int-state {
 		pins = "gpio99", "gpio125";
 		function = "gpio";

-- 
2.51.0

