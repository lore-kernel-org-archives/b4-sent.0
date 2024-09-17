From: Rudraksha Gupta <guptarud@gmail.com>
Date: Mon, 16 Sep 2024 21:48:35 -0700
Subject: [PATCH] arm: expressatt: fix pm8921_l6 regulator
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240916-sd-card-regulator-v1-1-669533c393d7@gmail.com>
X-B4-Tracking: v=1; b=H4sIACIK6WYC/x3MMQqAMAxA0atIZgO2iFavIg6hjTUgKqmKIN7d4
 viG/x9IrMIJ+uIB5UuSbGuGKQvwM62RUUI22MrWVWcaTAE9aUDleC50bIrUGts4T3XLDnK3K09
 y/89hfN8PdF7ctmMAAAA=
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726548515; l=930;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=0szhZ8yMa3ObS2XdUtiow/IhLUveGGFKEJjNsTf2maw=;
 b=zNZLIIpIV6we+iuTTRtSItw7FtLYgumjoSgbLi6eTwkq4WKZbzffar16BnHfZ4QK7tk/HS01Q
 QuBuG4fSa8ZDOE4oAY+BHc1JYdUFaFw+/e3ulBI1fONbL1rE8DFREcP
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SD card refuses to work because the regulator is turned off. Enable
it by default.

Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
 arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts b/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
index af6cc6393d74..13c102a562ab 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
+++ b/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
@@ -253,6 +253,7 @@ pm8921_l5: l5 {
 		};
 
 		pm8921_l6: l6 {
+			regulator-always-on;
 			regulator-min-microvolt = <2950000>;
 			regulator-max-microvolt = <2950000>;
 			bias-pull-down;

---
base-commit: 98f7e32f20d28ec452afb208f9cffc08448a2652
change-id: 20240916-sd-card-regulator-a71268ca47e8

Best regards,
-- 
Rudraksha Gupta <guptarud@gmail.com>

