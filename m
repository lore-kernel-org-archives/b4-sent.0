From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Mon, 22 Jul 2024 22:05:01 +0200
Subject: [PATCH] arm64: dts: qcom: msm8916-longcheer-l8910: Add rear flash
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240722-x5_sy7802-v1-1-b2ffeeaf8d2d@apitzsch.eu>
X-B4-Tracking: v=1; b=H4sIAGy7nmYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDcyND3QrT+OJKcwsDI12DJHOTxERzc6NUg2QloPqCotS0zAqwWdGxtbU
 Aad18LVsAAAA=
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?St=C3=A9phane_Martins?= <stemartins@proton.me>, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721678722; l=1600;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=3z8QU4g8ZpdKw7PLxFkOzP4TidQn21XO47XtCji7QEQ=;
 b=llK5B0kB3/LuUytgjFAglkv3f/qqys73Jtv2UyMzwpsZ+LHSuBFqEZp0SOZSHDZSzH9y2jaAu
 gPoGY5YgEfODDo83LQ2VPCGhRqCGgszkjMoiEfpRhXmCGG4AtlSIrEq
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The phone has a Silergy SY7802 flash LED controller.

Tested-by: Stéphane Martins <stemartins@proton.me>
Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 .../boot/dts/qcom/msm8916-longcheer-l8910.dts      | 27 ++++++++++++++++++++++
 1 file changed, 27 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/msm8916-longcheer-l8910.dts b/arch/arm64/boot/dts/qcom/msm8916-longcheer-l8910.dts
index 3b7fdb6797a9..2cc54eaf7202 100644
--- a/arch/arm64/boot/dts/qcom/msm8916-longcheer-l8910.dts
+++ b/arch/arm64/boot/dts/qcom/msm8916-longcheer-l8910.dts
@@ -125,6 +125,26 @@ led@2 {
 			};
 		};
 	};
+
+	flash-led-controller@53 {
+		compatible = "silergy,sy7802";
+		reg = <0x53>;
+
+		enable-gpios = <&tlmm 16 GPIO_ACTIVE_HIGH>;
+
+		pinctrl-0 = <&camera_rear_flash_default>;
+		pinctrl-names = "default";
+
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		led@0 {
+			reg = <0>;
+			function = LED_FUNCTION_FLASH;
+			color = <LED_COLOR_ID_WHITE>;
+			led-sources = <0>, <1>;
+		};
+	};
 };
 
 &blsp_i2c3 {
@@ -278,6 +298,13 @@ camera_front_flash_default: camera-front-flash-default-state {
 		bias-disable;
 	};
 
+	camera_rear_flash_default: camera-rear-flash-default-state {
+		pins = "gpio9", "gpio16", "gpio117";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+	};
+
 	gpio_keys_default: gpio-keys-default-state {
 		pins = "gpio107";
 		function = "gpio";

---
base-commit: 933069701c1b507825b514317d4edd5d3fd9d417
change-id: 20240721-x5_sy7802-0b74aa772e0c

Best regards,
-- 
André Apitzsch <git@apitzsch.eu>

