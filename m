From: David Heidelberg <david@ixit.cz>
Date: Wed, 08 Oct 2025 16:05:34 +0200
Subject: [PATCH v2 7/7] arm64: dts: qcom: sdm845-oneplus: Implement panel
 sleep pinctrl
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251008-s6e3fc2x01-v2-7-21eca1d5c289@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1489; i=david@ixit.cz;
 h=from:subject:message-id; bh=mp3HRjBZ7F75KJMOIKY0ujssyiub4Jy/WN4kGAY5j8g=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBo5m+piiWLIGs1xMLHjYcw1Kxi+dVr02ZH7Mmqu
 OeABLuKSjSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaOZvqQAKCRBgAj/E00kg
 ctV3D/9lubFbmrou5+gTBa2JMEdcOKJUmBFaw+Vy/vJFor0U3Uxr5rhDtLdAK9/eQ3o2dfZ9LUM
 MJRT5qoA3SorlFBSrV5nVa5HdxdW5b+3hqIupb45Dhr0dm2DfAzT8UFHE1fj60Z57LgEEkVhFVq
 xVY9s9zGXToPHmA1QCvS5RDXCIMyQY76fKWEkKfB5e59hMJHTk0OsE2bbsyRwlMt1u9IWPArgrn
 hzRdI5DQerHDgdav/UHwrw83n/nS2t5R69n3BRGX0inbVaBiTtJZ7AzcDx6dN2sK00TyqYcRRiY
 FN680Vy6dXpP3Hbm6d07dFJbJ3Fm852k4Wc05+8bb0C693tE2JN5XjzFxDxCCggx+yGmhkrMuxo
 v6DqgVAlC1Xt33L0TXhFkslf5ULO1g/dMX3m4Dj7FGdT372tyY4n1J07zXihjgmsjMtZ0SkQTfF
 j1sfS2Q9TVq/f7gHXHhNvUysJitJXJeY7uneJ2ZxJvisOGJHWPh3ljoeOQdlD6350h3WAcgzSAZ
 86felmyHVVn3k08JiNEwuvnD+pb0kJSyzuYhc9235+xO35LPjEXTWmNKgnh3EF1ziQm9m27xrbm
 HtL7grNbnYgi29vGxCd8+pZUUCDMhhzsaDgYLIEMrxxUkV6MBpcuOCKXuehVmMkSwQdDcq/L4qT
 6H3nus+UNFuUMBA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We can DSI pin from 8mA to 2mA while suspend, do it.

In theory, should give us extra 2 hours of idle battery life.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 26 +++++++++++++++++++++-
 1 file changed, 25 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index c216369fae237..fa538b37ef25b 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -463,8 +463,9 @@ display_panel: panel@0 {
 		te-gpios = <&tlmm 30 GPIO_ACTIVE_HIGH>;
 		reset-gpios = <&tlmm 6 GPIO_ACTIVE_LOW>;
 
-		pinctrl-names = "default";
+		pinctrl-names = "default", "sleep";
 		pinctrl-0 = <&panel_default>;
+		pinctrl-1 = <&panel_sleep>;
 
 		port {
 			panel_in: endpoint {
@@ -871,6 +872,29 @@ te-pins {
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

