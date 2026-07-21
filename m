From: David Heidelberg <david@ixit.cz>
Date: Tue, 21 Jul 2026 14:33:30 +0200
Subject: [PATCH v7 2/2] arm64: dts: qcom: sdm845-google: Enable PMI8998
 camera flash LEDs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260721-pixel3-camera-v7-2-82d323c6c5d2@ixit.cz>
References: <20260721-pixel3-camera-v7-0-82d323c6c5d2@ixit.cz>
In-Reply-To: <20260721-pixel3-camera-v7-0-82d323c6c5d2@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2228; i=david@ixit.cz;
 h=from:subject:message-id; bh=GKWXzv/TxU8dE0wKdWqwHqCHilW6WCLiUExNVd3EEOY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqX2cdsBDfQDws8pt12X/+MAzVNHbG5gl5b9gVF
 +67k6vKJ9iJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCal9nHQAKCRBgAj/E00kg
 crAWEACiSuiELlkV8+B+zSPjf1LQTGORMpJnPldKqvwbUhQ/3doyxpUXEDqP9LvMEFuYxOiSxl9
 5jtggpJhm3nJzFo28c/Wy8sXjLHZ+3rKNHJUVY8Hfflbx1DErW7mDYXfS17E0FUGnjFqj0DfJ24
 /7+bmtLLaxa3VBt3dGhBkns7nXBBhg0ju0vciiz/SM6/yR1sl7OzWTn34BXrxW7L92b5gfQZStw
 7pDo4rJDlWcbGnofCeAwGfoucWARll/ttEfRkBxbJtHyXflZakmhP0I1+IXTXVzjrtPKs5ab+/L
 yU9saNsQz0lZHkWdIeY7mLBZm6SB4mA2XSPJO5gpqt9AvpgEqxcdSRp8flNb1FqVAqkNJkyqP9G
 Uv+navPDGf2znsx6VSZ6tZhBGaIeDX+ZkMMXC9wPp+xXKMUSnQzdqWMT2w9hbO2GpXjnPytKz/4
 ylqjR+xreqZZwQv7/zSj8Xusplj1Hbhq2b0pOO1qU9Mx67I1hWhqTkBnpGxuJfEMGtZrqT0uUIL
 g3k9F8qe+gWM+lzhNycFihy1pP3hJYRGbLBTiiZGMkQ4I7oca84o/ZjtdkogMNJL/pPBQo7XKlV
 FnUPdvfWOCcZrIWnH3V8GZV2h3usKpdwmeU/MuwPBAR3YzKEpLLBThqru6zajvz6zpEKtaHMZvI
 NQgaF+YqBx2GShw==
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
index c8a28133fb38d..8d35e33ef7aaf 100644
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
 #include <dt-bindings/media/video-interface-devices.h>
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
2.53.0

