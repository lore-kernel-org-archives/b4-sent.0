From: David Heidelberg <david@ixit.cz>
Date: Tue, 01 Sep 2026 11:46:46 +0200
Subject: [PATCH v8 2/2] arm64: dts: qcom: sdm845-google: Enable PMI8998
 camera flash LEDs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260901-pixel3-camera-v8-2-99f159883348@ixit.cz>
References: <20260901-pixel3-camera-v8-0-99f159883348@ixit.cz>
In-Reply-To: <20260901-pixel3-camera-v8-0-99f159883348@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Petr Hodina <petr.hodina@protonmail.com>, 
 Richard Acayan <mailingradian@gmail.com>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2228; i=david@ixit.cz;
 h=from:subject:message-id; bh=prTj+YvVw1o8d4g7Tl+HH1FctxXrbb97DHabaxSpRN4=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqlp8H0JS9hyifhRSwlIuOsIYEeGMwFiabxbPvS
 uqVf8Ieh9aJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCapafBwAKCRBgAj/E00kg
 cuKcEADQT8OYqJANMbHWK5Z9NGf1W9K3Z2ahdoyDK4UsPMaupYFh12K9xbtfcOkUEZ0JZoUXGap
 XlnHOEKlsleiTHNSc1//UgSm0NCaXs1yapw8hgh/K8+RcM4yMOQo0K6p2sbGpalhgFxQxYpdy+p
 BmVpJ5BVC2P9ZlgJr9HXTVGxhlUAs61g4o7JCuSWcAaPrbQ67fPVGq1+HzeoANw1CWiDEBQ3O+j
 raaA75TZfZ+ELqk195Gq6hIAs/sDunnjdcMceD+oxRDtRPsQqVso9pqn8M6Z+VeIxm15NKHat9x
 vhUZDHRH16Yoru4NXCBnZfWP2JURtaK4QXj8uVxzMcJ27m/RI/ADCr+1RSmdFgrjwKLmltI+854
 DsxQGz4PbgInyuj8RvZuwzfKulWDsQOlwakk58ARtY/IeMu24kwuZdRi6PQ9/ikeBU42xrrD3Aq
 GSnXoYuUEd78NyND7H1/76sk0b/sdQrrOxLN6I9HmYo3ulSNu3yL/E3U9yF2CEULZnJydOj48Cf
 DQQWGEIJuEJHsTnEav80JUUEYHv9y+Lr6fnhlxFSUNY8zXOjQy2cVqITuCAKf9c0kI8/8sSvpOs
 qpDFPtkoWam2AznYdnzRKk2Gb/ASqCbchB3yzRFG/aNvy+2BhbaYEeeRifyfN19Y6rW7i2zDQRv
 4kh0yZzXNyH9ZTw==
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
index 913e2032e6472..365fd6d9287e1 100644
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
 
@@ -591,16 +592,42 @@ &pm8998_resin {
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

