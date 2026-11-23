From: David Heidelberg <david@ixit.cz>
Date: Mon, 23 Nov 2026 14:28:11 +0100
Subject: [PATCH v11 2/2] arm64: dts: qcom: sdm845-google: Enable PMI8998
 camera flash LEDs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-pixel3-camera-v11-2-d00195d180dc@ixit.cz>
References: <20261123-pixel3-camera-v11-0-d00195d180dc@ixit.cz>
In-Reply-To: <20261123-pixel3-camera-v11-0-d00195d180dc@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Abel Vesa <abel.vesa@oss.qualcomm.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Petr Hodina <petr.hodina@protonmail.com>, 
 Richard Acayan <mailingradian@gmail.com>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2281; i=david@ixit.cz;
 h=from:subject:message-id; bh=F5sq/PnEtjGmqazwQ+898n43o6XCMRwhDRliedBHnYI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrBD9sIxiiUQti76uzxmxCbXSPPNPXP+MIf3Pl7
 jsrnnTPRkyJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawQ/bAAKCRBgAj/E00kg
 cuUND/95Laajx/9lats4rCo4YRkRAu1tJ281PJ7xa3EJeqvwmLWZAcJGLskOKOUO/2VUGTQHTab
 CFExrRuJG9dezrM8k7AFf+EmVjmFqrvv+mnsqefj6hTbwGmQSTlz7wUqZvpRStWTVMwDUIrML/6
 bPET9mQiPY1D2Sd41zyQdV5dRUslqRGVsIlErou/HUiiKF18sEJ7uISWqGtS4lr/n6sl7HcODr/
 69iu6h2hQmA8JY8XxiXh29LzA0/F/HxRAmMwiGawum3uW55XVyfoNI1og/wDPTxLzpYr36XMdcP
 Shsg/mqBiPI1LmlaWJx6s9tq/Ass0dwBtLMB0Zw0ZR6Bo5x70QtKCVVYh1VeiPWkZqyGCA2N9ib
 V3lW2gSKnu794A7uusdvtt8AupPwbzxsAXm7TnAeMDGg4NUyrc+2jYS9zx/Jdku5kqDc9Ofp/+d
 aKhJsunLM261MO4qH17Xv4d/6fzFTEd5csr85rbgBXJKQHx4e54QkGaicqv/h30QT+cGtkxTy+V
 SSyXNDMMHZBHeaSILWNPPaVgJiwnWcIXIBRQ7jlCQIqGS3vrNgLkLOr27kQSxMqxrKS3q6JQr8l
 bdhoSniG/JTrR4Iu/ZMiqQofqaHg/S4zil8w6dUmriXLXfmZYsF6qYJRzlI3PMEmSht9TPAyZgi
 IP/0OyaL0iKMEQA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the PMI8998 flash LED block and describe two white flash LEDs
used for the rear camera.

Configure the LED in flash mode with hardware limits matching the
original device configuration, including maximum current and timeout.

In contrary to downstream, we can control both LEDs separately.

Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Reviewed-by: Abel Vesa <abel.vesa@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi | 27 ++++++++++++++++++++++
 1 file changed, 27 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
index 1c1cc036dcfe8..4084b6215f8be 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
@@ -1,16 +1,17 @@
 // SPDX-License-Identifier: GPL-2.0-only
 
 /dts-v1/;
 
 #include <dt-bindings/arm/qcom,ids.h>
 #include <dt-bindings/dma/qcom-gpi.h>
 #include <dt-bindings/input/linux-event-codes.h>
 #include <dt-bindings/interrupt-controller/irq.h>
+#include <dt-bindings/leds/common.h>
 #include <dt-bindings/media/video-interface-devices.h>
 #include <dt-bindings/media/video-interfaces.h>
 #include <dt-bindings/regulator/qcom,rpmh-regulator.h>
 
 #include "sdm845.dtsi"
 #include "pm8998.dtsi"
 #include "pmi8998.dtsi"
 
@@ -593,16 +594,42 @@ &pm8998_resin {
 };
 
 &pmi8998_charger {
 	monitored-battery = <&battery>;
 
 	status = "okay";
 };
 
+&pmi8998_flash {
+	status = "okay";
+
+	/* upper part of the flash module */
+	led-0 {
+		function = LED_FUNCTION_FLASH;
+		color = <LED_COLOR_ID_WHITE>;
+		led-sources = <1>;
+		led-max-microamp = <500000>;
+		flash-max-microamp = <1500000>;
+		flash-max-timeout-us = <1280000>;
+		function-enumerator = <0>;
+	};
+
+	/* lower part of the flash module */
+	led-1 {
+		function = LED_FUNCTION_FLASH;
+		color = <LED_COLOR_ID_WHITE>;
+		led-sources = <2>;
+		led-max-microamp = <500000>;
+		flash-max-microamp = <1500000>;
+		flash-max-timeout-us = <1280000>;
+		function-enumerator = <1>;
+	};
+};
+
 &qupv3_id_0 {
 	status = "okay";
 };
 
 &qupv3_id_1 {
 	status = "okay";
 };
 

-- 
2.55.0

