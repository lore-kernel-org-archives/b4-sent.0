From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Fri, 30 Aug 2024 22:49:50 +0200
Subject: [PATCH] Revert "arm64: dts: qcom: msm8939-longcheer-l9100: Add
 rear flash"
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240830-revert_flash-v1-1-ad7057ea7e6e@apitzsch.eu>
X-B4-Tracking: v=1; b=H4sIAG0w0mYC/x2MQQqAIBAAvxJ7TlBTsL4SEZJrLoSFRgTi35OOA
 zNTIGMizDB1BRI+lOmMDUTfwRZs3JGRawySS8XNwFmTMN2rP2wOTKEwSo/CWaGhJVdCT++/m5d
 aP60G5wFeAAAA
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1725051108; l=1873;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=e8OmqrXh0tbGdO++XiKLMFxfWpEu2DvMhtbt6MUV/A8=;
 b=O92PbyqG9ghtpTVHIrrk4BWY3mb570s0wC+LCtYQgraW1WTvErXUQeUUY4HkEXbOS6+roClHo
 g+t/fpRE8VODfR1hFpZdFkMzkY/5hvmkmQ2j+HXDl50hZD8x03TIlZW
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Patch "arm64: dts: qcom: msm8939-longcheer-l9100: Add rear flash" has
been applied twice. This reverts the older version of the patch.

Revert the commit f98bdb21cfc9 ("arm64: dts: qcom:
msm8939-longcheer-l9100: Add rear flash")

Fixes: f98bdb21cfc9 ("arm64: dts: qcom: msm8939-longcheer-l9100: Add rear flash")
Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 .../boot/dts/qcom/msm8939-longcheer-l9100.dts      | 26 ----------------------
 1 file changed, 26 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/msm8939-longcheer-l9100.dts b/arch/arm64/boot/dts/qcom/msm8939-longcheer-l9100.dts
index adc992ebc29d..b845da4fa23e 100644
--- a/arch/arm64/boot/dts/qcom/msm8939-longcheer-l9100.dts
+++ b/arch/arm64/boot/dts/qcom/msm8939-longcheer-l9100.dts
@@ -160,25 +160,6 @@ led@2 {
 		};
 	};
 
-	flash-led-controller@53 {
-		compatible = "silergy,sy7802";
-		reg = <0x53>;
-		#address-cells = <1>;
-		#size-cells = <0>;
-
-		enable-gpios = <&tlmm 16 GPIO_ACTIVE_HIGH>;
-
-		pinctrl-0 = <&camera_rear_flash_default>;
-		pinctrl-names = "default";
-
-		led@0 {
-			reg = <0>;
-			function = LED_FUNCTION_FLASH;
-			color = <LED_COLOR_ID_WHITE>;
-			led-sources = <0>, <1>;
-		};
-	};
-
 	flash-led-controller@53 {
 		compatible = "silergy,sy7802";
 		reg = <0x53>;
@@ -364,13 +345,6 @@ camera_rear_flash_default: camera-rear-flash-default-state {
 		bias-disable;
 	};
 
-	camera_rear_flash_default: camera-rear-flash-default-state {
-		pins = "gpio9", "gpio16", "gpio51";
-		function = "gpio";
-		drive-strength = <2>;
-		bias-disable;
-	};
-
 	gpio_hall_sensor_default: gpio-hall-sensor-default-state {
 		pins = "gpio20";
 		function = "gpio";

---
base-commit: d7b69f6e9e1c8b6acdcce3b385779eb046835dd5
change-id: 20240830-revert_flash-4e184591da15

Best regards,
-- 
André Apitzsch <git@apitzsch.eu>

