From: Alexandre Messier <alex@me.ssier.org>
Date: Mon, 06 Apr 2026 01:16:57 -0400
Subject: [PATCH v2 1/4] ARM: dts: qcom: msm8974pro-htc-m8: add status LEDs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260406-m8-dts-additions-v2-1-c4c4bd50af48@me.ssier.org>
References: <20260406-m8-dts-additions-v2-0-c4c4bd50af48@me.ssier.org>
In-Reply-To: <20260406-m8-dts-additions-v2-0-c4c4bd50af48@me.ssier.org>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Luca Weiss <luca@lucaweiss.eu>, linux-arm-kernel@lists.infradead.org, 
 linux-arm-msm@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 phone-devel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Alexandre Messier <alex@me.ssier.org>, 
 Lee Jones <lee@kernel.org>, Pavel Machek <pavel@kernel.org>, 
 linux-leds@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775452618; l=1446;
 i=alex@me.ssier.org; s=20240603; h=from:subject:message-id;
 bh=3h5eC7Cp5T5BYkF0l8ntqlN3+V3NGs9ZIeqd8JvOxHw=;
 b=sT3B97jdTe8Yb/ZHQ+q1ZRpJQ68qZtgaFiRNDGqvLlpowcS/qjCejlAw3utpaVFmInN/ye8fg
 /cs7prl6aO1BxL2M2iwoqLHHdr4rAoW2JMSczMMPwKnaDx0p4WybynC
X-Developer-Key: i=alex@me.ssier.org; a=ed25519;
 pk=JjRqVfLd2XLHX2QTylKoROw346/1LOyZJX0q6cfnrKw=
X-Endpoint-Received: by B4 Relay for alex@me.ssier.org/20240603 with auth_id=168
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the notification LEDs on the HTC One M8.

Two LEDs are available, one orange and one green. Together,
they both form a single notification source, so use a
multicolor LED node to describe this arrangement.

Cc: Lee Jones <lee@kernel.org>
Cc: Pavel Machek <pavel@kernel.org>
Cc: linux-leds@vger.kernel.org
Signed-off-by: Alexandre Messier <alex@me.ssier.org>
---
 arch/arm/boot/dts/qcom/qcom-msm8974pro-htc-m8.dts | 25 +++++++++++++++++++++++
 1 file changed, 25 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8974pro-htc-m8.dts b/arch/arm/boot/dts/qcom/qcom-msm8974pro-htc-m8.dts
index 402372834c53..37df271dbdeb 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8974pro-htc-m8.dts
+++ b/arch/arm/boot/dts/qcom/qcom-msm8974pro-htc-m8.dts
@@ -3,6 +3,7 @@
 #include "pm8841.dtsi"
 #include "pm8941.dtsi"
 #include <dt-bindings/input/input.h>
+#include <dt-bindings/leds/common.h>
 
 / {
 	model = "HTC One (M8)";
@@ -64,6 +65,30 @@ vreg_vph_pwr: vreg-vph-pwr {
 	};
 };
 
+&pm8941_lpg {
+	qcom,power-source = <1>;
+
+	status = "okay";
+
+	multi-led {
+		color = <LED_COLOR_ID_MULTI>;
+		function = LED_FUNCTION_STATUS;
+
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		led@6 {
+			reg = <6>;
+			color = <LED_COLOR_ID_GREEN>;
+		};
+
+		led@7 {
+			reg = <7>;
+			color = <LED_COLOR_ID_ORANGE>;
+		};
+	};
+};
+
 &pm8941_vib {
 	status = "okay";
 };

-- 
2.53.0

