From: Alexandre Messier <alex@me.ssier.org>
Date: Tue, 07 Oct 2025 01:55:42 -0400
Subject: [PATCH 1/4] ARM: dts: qcom: msm8974pro-htc-m8: add status LEDs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251007-m8-dts-additions-v1-1-53d7ab3594e7@me.ssier.org>
References: <20251007-m8-dts-additions-v1-0-53d7ab3594e7@me.ssier.org>
In-Reply-To: <20251007-m8-dts-additions-v1-0-53d7ab3594e7@me.ssier.org>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Luca Weiss <luca@lucaweiss.eu>, linux-arm-kernel@lists.infradead.org, 
 linux-arm-msm@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 phone-devel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Alexandre Messier <alex@me.ssier.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759816548; l=1141;
 i=alex@me.ssier.org; s=20240603; h=from:subject:message-id;
 bh=SD/8uvnSr2d+2HzDqbM9fG8xyKZ/sbIt2qlYS8ZUIlw=;
 b=ayzUpHLzZDtFDSLQFCgmQwsof3hOVov+Hc3pyvAr5CeWtT7F7NPP3fm36Bi76I5/DawD96nHd
 /0DyfTMD93KByNS4LQbX1th9EaO9m9MX76vy3QjObJkqeM86uUEFa+h
X-Developer-Key: i=alex@me.ssier.org; a=ed25519;
 pk=JjRqVfLd2XLHX2QTylKoROw346/1LOyZJX0q6cfnrKw=
X-Endpoint-Received: by B4 Relay for alex@me.ssier.org/20240603 with auth_id=168
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the notification LEDs on the HTC One M8.

Two LEDs are available, one amber and one green.

Signed-off-by: Alexandre Messier <alex@me.ssier.org>
---
 arch/arm/boot/dts/qcom/qcom-msm8974pro-htc-m8.dts | 19 +++++++++++++++++++
 1 file changed, 19 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8974pro-htc-m8.dts b/arch/arm/boot/dts/qcom/qcom-msm8974pro-htc-m8.dts
index b896cc1ad6f7..9c3859069aba 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8974pro-htc-m8.dts
+++ b/arch/arm/boot/dts/qcom/qcom-msm8974pro-htc-m8.dts
@@ -3,6 +3,7 @@
 #include "pm8841.dtsi"
 #include "pm8941.dtsi"
 #include <dt-bindings/input/input.h>
+#include <dt-bindings/leds/common.h>
 
 / {
 	model = "HTC One (M8)";
@@ -64,6 +65,24 @@ vreg_vph_pwr: vreg-vph-pwr {
 	};
 };
 
+&pm8941_lpg {
+	qcom,power-source = <1>;
+
+	status = "okay";
+
+	led@6 {
+		reg = <6>;
+		color = <LED_COLOR_ID_GREEN>;
+		function = LED_FUNCTION_STATUS;
+	};
+
+	led@7 {
+		reg = <7>;
+		color = <LED_COLOR_ID_AMBER>;
+		function = LED_FUNCTION_STATUS;
+	};
+};
+
 &pm8941_vib {
 	status = "okay";
 };

-- 
2.51.0

