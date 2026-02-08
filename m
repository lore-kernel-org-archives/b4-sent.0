From: Aaron Kling <webgeek1234@gmail.com>
Date: Sat, 07 Feb 2026 20:12:11 -0600
Subject: [PATCH] arm64: dts: qcom: pmk8550: Add PWM controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260207-pmk8550-pwm-v1-1-f2b26ab98d8b@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDIwNz3YLcbAtTUwPdgvJcXWPzVPNUIwPj1OS0FCWgjoKi1LTMCrBp0bG
 1tQBRMpMhXQAAAA==
X-Change-ID: 20260207-pmk8550-pwm-37e7e203ecfd
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Xilin Wu <wuxilin123@gmail.com>, 
 Aaron Kling <webgeek1234@gmail.com>, Konrad Dybcio <konradybcio@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770516744; l=1352;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=nkSib1r0tiqP/QFHvtzkaBG2I3y6pZ5YlqojPgxhYug=;
 b=WwacdgPXd9I95XFOewoNrVUHY3wYGX1kyiu++95/qjcS5hp213dk57+rlewaOY3TDIljTZSsu
 J8NjhJQMZQVBTHMOEs3dGQsQEWuQgpHNFxApLn87gr95PhiLNailWG3
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Xilin Wu <wuxilin123@gmail.com>

Add the PWM function to the pmk8550 dtsi, which is usually used
to control PWM backlight on platforms using this PMIC.

Signed-off-by: Xilin Wu <wuxilin123@gmail.com>
Reviewed-by: Konrad Dybcio <konrad.dybcio@linaro.org>
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
This patch was originally submitted as part of a series to support the
AYN Odin 2 [0]. That series stalled, so submitting separately.

[0] https://lore.kernel.org/all/20240424-ayn-odin2-initial-v1-0-e0aa05c991fd@gmail.com/
---
 arch/arm64/boot/dts/qcom/pmk8550.dtsi | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/pmk8550.dtsi b/arch/arm64/boot/dts/qcom/pmk8550.dtsi
index 583f61fc16ad570972ac166aef12183382ebb4c5..3049eb6b46d7af77e5ea39e41ced0de24ee9f3e0 100644
--- a/arch/arm64/boot/dts/qcom/pmk8550.dtsi
+++ b/arch/arm64/boot/dts/qcom/pmk8550.dtsi
@@ -73,5 +73,15 @@ pmk8550_gpios: gpio@b800 {
 			interrupt-controller;
 			#interrupt-cells = <2>;
 		};
+
+		pmk8550_pwm: pwm {
+			compatible = "qcom,pmk8550-pwm";
+
+			#address-cells = <1>;
+			#size-cells = <0>;
+			#pwm-cells = <2>;
+
+			status = "disabled";
+		};
 	};
 };

---
base-commit: 9845cf73f7db6094c0d8419d6adb848028f4a921
change-id: 20260207-pmk8550-pwm-37e7e203ecfd

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

