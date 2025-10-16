From: David Heidelberg <david@ixit.cz>
Date: Thu, 16 Oct 2025 18:17:01 +0200
Subject: [PATCH v3 6/8] arm64: dts: qcom: sdm845-oneplus: Implement panel
 sleep pinctrl
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251016-s6e3fc2x01-v3-6-ce0f3566b903@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1486; i=david@ixit.cz;
 h=from:subject:message-id; bh=IdGkA2BKwmHx0VWG6UhlzI4rKDrzt5SVgWCdxZMctQg=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBo8Rp5vN8HQcZ54pdipCWfyIN70cVAsyHq2daOQ
 59LWvnxPvCJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaPEaeQAKCRBgAj/E00kg
 cpSKEACUZgZD3YpZbH/UXmE7NJ+MyBRKPn0g/VuLazxFylvuV1y4an2YgZX3mChsVlfkimxaUiR
 RMwSSNyGFm+JFaHYGSMtSkCnnERaLN1iJpiAjLJ7rSom8kNnng+Ld6tb8BdWgpuFKvtmQxsbnK+
 NCFidN1kjIiRc8cL8FN1PT6GW4xMqInCIU5HFlvYjsQsPTHrAxJe1QJFp7te9LT6KcSrLtlGtgw
 Bg6pwROadutE9XK9L1Y87wSZlGMXM6B725B+ku5gaqNRNdhJZABJf9gfphRzeVKDxyCUavfRD4t
 dRp26jwtS67lutsf8MiYutI0Al1yjc2pt9JGT47Q4MigGbQocPLpcouqQK/uBlXo+2LEEdah+UB
 3jYdPofturtqmzoifL8PkHyjwsIS19t9Kmr8/GFvyq5YHFUUsD84MROXXYqA7pMWZuocZhFUOdi
 hS9QB/cSd7vtknj+Fl6q3sVIN25N7m1qIrPZKv/I2TrksgNLy1rUmrl2Gw0ZMp6FiPCqw8ZUfzQ
 aVvtEj9gpdQZSg4ODqkLJTbP71SOY9l11v7f0U8b4wITpcNxy13TXku8JuRYdTW04GKUfOHU1uI
 XOLtLFfCVgptECqMQ9SocP2boATCJ/EgWwHWQHGVLoGe1rWnm7nqonaJ0pisBB4O0BOGEFJJqrc
 fVEErpNohgoEptw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We can DSI pin from 8mA to 2mA while suspend, do it.

In theory, should give us extra 2 hours of idle battery life.

cosmetic: sort pinctrl properties.

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

