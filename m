From: Aaron Kling <webgeek1234@gmail.com>
Date: Sun, 22 Nov 2026 15:46:18 -0600
Subject: [PATCH 3/4] arm64: dts: qcom: qcs8550-retroidpocket-rp6: Remove
 pwm backlight
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-rp-qcs8550-display-v1-3-d513d9819a34@gmail.com>
References: <20261122-rp-qcs8550-display-v1-0-d513d9819a34@gmail.com>
In-Reply-To: <20261122-rp-qcs8550-display-v1-0-d513d9819a34@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795383979; l=1194;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=XJhe98HFyVSwJqUvStUrAk0mwelhqDfoIAU2HEa6TOw=;
 b=Pqr+YO1s/WqKaWfJ92j1Fo/ql2Bss1xvYIHXyexKvxKIUW0B4CvnfsZYrtof17aBRbZRXH87M
 Qi/EW/QxwPBAc/R7FZhgF2MuiV+S+DkKgx0ogrdNOOBZ/L8Ue54BHVT
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This device does not use a pwm backlight, it has a backlight controlled
by dcs commands via the panel.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 arch/arm64/boot/dts/qcom/qcs8550-retroidpocket-rp6.dts | 12 ------------
 1 file changed, 12 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/qcs8550-retroidpocket-rp6.dts b/arch/arm64/boot/dts/qcom/qcs8550-retroidpocket-rp6.dts
index a93fe74b83383..91fed8795d611 100644
--- a/arch/arm64/boot/dts/qcom/qcs8550-retroidpocket-rp6.dts
+++ b/arch/arm64/boot/dts/qcom/qcs8550-retroidpocket-rp6.dts
@@ -13,18 +13,6 @@
 	model = "Retroid Pocket 6";
 	compatible = "retroidpocket,rp6", "qcom,qcs8550", "qcom,sm8550";
 
-	backlight: backlight {
-		compatible = "pwm-backlight";
-		pwms = <&pmk8550_pwm 0 860000>;
-		brightness-levels = <1023 0>;
-		num-interpolated-steps = <1023>;
-		default-brightness-level = <600>;
-		power-supply = <&vph_pwr>;
-		enable-gpios = <&pmk8550_gpios 5 GPIO_ACTIVE_HIGH>;
-		pinctrl-0 = <&pwm_backlight_default>;
-		pinctrl-names = "default";
-	};
-
 	vdd_disp_1v8: regulator-vdd-disp-1v8 {
 		compatible = "regulator-fixed";
 		regulator-name = "vdd_disp_1v8";

-- 
2.56.0

