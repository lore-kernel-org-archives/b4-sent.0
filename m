From: David Heidelberg <david@ixit.cz>
Date: Mon, 20 Jul 2026 12:53:08 +0200
Subject: [PATCH v6 2/2] arm64: dts: qcom: sdm845-google: Enable PMI8998
 camera flash LEDs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260720-pixel3-camera-v6-2-afe419bef476@ixit.cz>
References: <20260720-pixel3-camera-v6-0-afe419bef476@ixit.cz>
In-Reply-To: <20260720-pixel3-camera-v6-0-afe419bef476@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Petr Hodina <petr.hodina@protonmail.com>, 
 Richard Acayan <mailingradian@gmail.com>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2187; i=david@ixit.cz;
 h=from:subject:message-id; bh=+JTTruT1wyhpjPxfzBWwZfGwRsmkaQCpAUzY/f6Aiic=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqXf4Uj2pZ6Kubd5/ik8gO7F84rxctxStDvnZuu
 cddClBOCPSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCal3+FAAKCRBgAj/E00kg
 cqWOEACOMGp12pxBKnY8ya7rfeUKSwR0bg76cNT/SiI5hbMADwsdnYhWI+w6+wh0LHxTGWcst+K
 1JFjkdSOB0WxUp/TlkQT61l+cmiMsAK453mIij95ss3xJ8FeehZ0uEVdOt4wXLD1iQi7TortnDp
 zyz21+yh7yFEEXnquciny3gqMh9rvle90x0++JJdAnW/eICqBwDZ4nzLKmQoQI5szK9RTBFfvsn
 WbVeVVgbq16RoJOmO24Lm0PyiKw9gtgt2MpAzCsKpTAMv0K4+Yf6KsL68H+hCM7rrogrzsZehUW
 5fZPwOKZs7XHeMiuWDnhPh0TvgLOKXO8THefd3Af3lFTcFrZvF+zJstVzVVsiujssdbGxIkad2O
 GifMI+Yf8OS7NxE+FSA/H+k52lIbVale/yAoPRN5bU72BAr96sloxzv8nNhTnXohUnv8E2Wo/tb
 9s/CaLMO2QJsb65tz5t5h23XRMs7vDWaVVg6Gxfq12YenOikYKVg3OdDgnxtfcfs8wP/Dd8HYDP
 Sbldr7bmqXn9zcSfplNEcGSKeRmkuB7EkRCX+olEs2Ke4pXzpXYHsP9kKic6HP5eBazyV22fcf6
 vG6gj/ovewD8+/LlvnlRbllFV0dRixx9zVho6xmnCrChiUr+YwV0ItMOmITJhAQojzUm1pFRXNF
 D8ihg1dNRFZNA3g==
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
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi | 27 ++++++++++++++++++++++
 1 file changed, 27 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
index 267dcd6eddaee..c8699f72cfecf 100644
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
 #include <dt-bindings/media/video-interfaces.h>
 #include <dt-bindings/regulator/qcom,rpmh-regulator.h>
 
 #include "sdm845.dtsi"
 #include "pm8998.dtsi"
 #include "pmi8998.dtsi"
 
 /delete-node/ &mpss_region;
@@ -590,16 +591,42 @@ &pm8998_resin {
 };
 
 &pmi8998_charger {
 	monitored-battery = <&battery>;
 
 	status = "okay";
 };
 
+&pmi8998_flash {
+	status = "okay";
+
+	/* upper flash module part */
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
+	/* lower flash module part */
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
2.53.0

