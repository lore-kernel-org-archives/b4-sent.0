From: David Heidelberg <david@ixit.cz>
Date: Thu, 16 Oct 2025 18:16:57 +0200
Subject: [PATCH v3 2/8] arm64: dts: qcom: sdm845-oneplus: Describe panel
 vci and poc supplies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251016-s6e3fc2x01-v3-2-ce0f3566b903@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2735; i=david@ixit.cz;
 h=from:subject:message-id; bh=wyoU9d3slp1a80oxXbHjL+liib53t7o67lGGsu4UofI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBo8Rp5dgtTSdWd75kUXSvsl9NH1ddgakNs5b3Hm
 GVrQwSW+V2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaPEaeQAKCRBgAj/E00kg
 cvS6D/9PVWcLp6Bfew4uYW7Eg4WK5udIZEyZEede5wK6aU9K07ZKULQw37rxybNuz+l+VFzgBFQ
 1Yr2KW7tYYTctWiFqYO9V63N5HQdXYylB0ghCZiuApKmeiS7xIpVZLXuySZOTqR/FOz4Eo0/rhm
 VNlFUEHFUGMH4MXIiYej9gzL8KqmlFv78MU3ysbOkoPlBA5XiKgHJRtfj+oEOpe0Adqv+hoY7Xr
 Nj90X6fxFJoEymE7jw9WxuisFMi5armKEzmHwrJi0dHCb4+mqQJJ+yCvRH2dzV98fvvdk3knavX
 Omux62Z+pp0kFZi3lMqggnQ3RBOWvcLKXC4jSk+jxtC16OCx/xWNcJntslnwSXD8nEybUivQh8O
 fgw+0dWeKF0nZVtCJYjj6uQYgn8bn7gj51PzbwpYj4S8xQySLstcI6lflhgikTmo9LmbAiCf3Vu
 SWP9yoal62SMaOUnrM4VALHisfFgI7qziLGJKHlLnHAjJ9lz/LqiKDj9Jyr1srKe6LDeB5u8I7p
 xcRfI8QzfFrAgqYl2m2+gZhqWubB+cTZV7fdSiqi29lc+FSwaNzzuo1purULdwGpdi3s6wJQPtc
 mYPAsVSbCeN4DVnKhu1L22h8aLqytso//PdFNLap+wAQPnnPy2LTStT1aiBPzwjT+UaqsrsnIqo
 NllzFcReDRwI6Cg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Casey Connolly <casey.connolly@linaro.org>

There are two additional supplies used by the panel, both are GPIO
controlled and are left enabled by the bootloader for continuous splash.

Previously these were (incorrectly) modelled as pinctrl. Describe them
properly so that the panel can control them.

Fixes: 288ef8a42612 ("arm64: dts: sdm845: add oneplus6/6t devices")
Signed-off-by: Casey Connolly <casey.connolly@linaro.org>
Co-developed-by: David Heidelberg <david@ixit.cz>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 46 +++++++++++++++++++++-
 1 file changed, 45 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index dcfffb271fcf3..1cf03047dd7ae 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -162,6 +162,34 @@ ts_1p8_supply: ts-1p8-regulator {
 		enable-active-high;
 		regulator-boot-on;
 	};
+
+	panel_vci_3v3: panel-vci-3v3-regulator {
+		compatible = "regulator-fixed";
+		regulator-name = "LCD_VCI_3V";
+
+		regulator-min-microvolt = <3300000>;
+		regulator-max-microvolt = <3300000>;
+
+		gpio = <&tlmm 26 GPIO_ACTIVE_HIGH>;
+		enable-active-high;
+		pinctrl-0 = <&panel_vci_default>;
+		pinctrl-names = "default";
+		regulator-boot-on;
+	};
+
+	panel_vddi_poc_1p8: panel-vddi-poc-regulator {
+		compatible = "regulator-fixed";
+		regulator-name = "VDDI_POC";
+
+		regulator-min-microvolt = <1800000>;
+		regulator-max-microvolt = <1800000>;
+
+		gpio = <&tlmm 25 GPIO_ACTIVE_HIGH>;
+		enable-active-high;
+		pinctrl-0 = <&panel_poc_default>;
+		pinctrl-names = "default";
+		regulator-boot-on;
+	};
 };
 
 &adsp_pas {
@@ -429,6 +457,8 @@ display_panel: panel@0 {
 		reg = <0>;
 
 		vddio-supply = <&vreg_l14a_1p88>;
+		vci-supply = <&panel_vci_3v3>;
+		poc-supply = <&panel_vddi_poc_1p8>;
 
 		reset-gpios = <&tlmm 6 GPIO_ACTIVE_LOW>;
 
@@ -803,6 +833,20 @@ hall_sensor_default: hall-sensor-default-state {
 		bias-disable;
 	};
 
+	panel_vci_default: vci-state {
+		pins = "gpio26";
+		function = "gpio";
+		drive-strength = <8>;
+		bias-disable;
+	};
+
+	panel_poc_default: poc-state {
+		pins = "gpio25";
+		function = "gpio";
+		drive-strength = <8>;
+		bias-disable;
+	};
+
 	tri_state_key_default: tri-state-key-default-state {
 		pins = "gpio40", "gpio42", "gpio26";
 		function = "gpio";
@@ -818,7 +862,7 @@ ts_default_pins: ts-int-state {
 	};
 
 	panel_reset_pins: panel-reset-state {
-		pins = "gpio6", "gpio25", "gpio26";
+		pins = "gpio6";
 		function = "gpio";
 		drive-strength = <8>;
 		bias-disable;

-- 
2.51.0

