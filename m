From: Aaron Kling <webgeek1234@gmail.com>
Date: Sun, 22 Nov 2026 15:46:16 -0600
Subject: [PATCH 1/4] arm64: dts: qcom: qcs8550-retroidpocket-nova: Remove
 pwm backlight
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-rp-qcs8550-display-v1-1-d513d9819a34@gmail.com>
References: <20261122-rp-qcs8550-display-v1-0-d513d9819a34@gmail.com>
In-Reply-To: <20261122-rp-qcs8550-display-v1-0-d513d9819a34@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795383979; l=1203;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=179YKHLvNNa1LrCEnmKzvwXZC97Kf2YubmEHcIb0YwI=;
 b=Eykh6KwoB5x0+roEJgHA/HVZqvPkoh7FKyFA0w2Q9xMGUY9XgzzWlwKkc8+36pUzeg0mJ6HKc
 Ych0OYERGOzDAwingIzt1Z18qZaoHDmlxts84VEb6xEYhUd3CFA4raz
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This device does not use a pwm backlight, it has a backlight controlled
by dcs commands via the panel.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 arch/arm64/boot/dts/qcom/qcs8550-retroidpocket-nova.dts | 12 ------------
 1 file changed, 12 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/qcs8550-retroidpocket-nova.dts b/arch/arm64/boot/dts/qcom/qcs8550-retroidpocket-nova.dts
index 0a0546977a026..ef1356f4c34ce 100644
--- a/arch/arm64/boot/dts/qcom/qcs8550-retroidpocket-nova.dts
+++ b/arch/arm64/boot/dts/qcom/qcs8550-retroidpocket-nova.dts
@@ -10,18 +10,6 @@
 	model = "Retroid Pocket Nova";
 	compatible = "retroidpocket,nova", "qcom,qcs8550", "qcom,sm8550";
 
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

