From: David Heidelberg <david@ixit.cz>
Date: Sun, 19 Jul 2026 20:03:53 +0200
Subject: [PATCH v5 2/2] arm64: dts: qcom: sdm845-google: Enable PMI8998
 camera flash LEDs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260719-pixel3-camera-v5-2-99593f1bd8ec@ixit.cz>
References: <20260719-pixel3-camera-v5-0-99593f1bd8ec@ixit.cz>
In-Reply-To: <20260719-pixel3-camera-v5-0-99593f1bd8ec@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Petr Hodina <petr.hodina@protonmail.com>, 
 Richard Acayan <mailingradian@gmail.com>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2101; i=david@ixit.cz;
 h=from:subject:message-id; bh=hIR5m+3hEHUVKN/E0aT2UW1X7Xn618H06WFsR908Ic4=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqXRGK7fZUfReynnvMDObSQkkctlha7/os8YBGm
 RlcFUwAAcOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCal0RigAKCRBgAj/E00kg
 cgvBD/4pAwzpRdfkFh2N6wnEeCd4vx00X0QDwjj60nLPB2172S7m8CMN7ijl74u04+GvIYcHJsg
 hcLwUjlwZgoSf3V6Hzce+qMJlE7mvm15/zuzZAcysLIF3jgKPUyUd2m/qWnZbNoq6HbJSu3AVj1
 kf2n5gVIruFdUh55mZ2a0hIpb5irfFpJbwkvPvh85vkwlIRjBno9BdoA2XJfaqOdiHFAun1b3Xo
 FRqANSoRqnqgGOuGLOLYAQuyVRypBM80BubwFJb1EHwcFXXOZchPNYsHotZgh/E1fpewDbI57ka
 Bw9LVNQ1FxhQwOJLPvG6tmWe7BMMHhWleZ8fmYEKYgDEqPQ836TwvepIDLdjsKFgD+YUZIJ8KV+
 vddMN4OpWfUZOiUeJZcxAAuUaeyMyLVXAa/AqD59qCrsWzV+ZLLZjHQPOB5nTF2+PjxDCPmW6wN
 zo4kwC/+fIxxlFPG0I+AKB2ylMpm0QuqIdlbNSbnyOBW73w5wDOXZ+3I1Arbpu/L19zvJA3jIRe
 MR/uZ1cskR1AOxgZ+2djSMFicM5JFUqvRRyYfGNklcldPJnnRWkqqBAGrz51U4UbfWPxT8Geh2A
 XilZNoc8rbOkhg1kk0bHt4vnQ5cUaNQrdzJ5dAMNWT2hT+sVEMdwmfS9xH6pXpO03QrJGDXPhbt
 +3kVQ4j/ep6QVBw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the PMI8998 flash LED block and describe two white flash LEDs
used for the rear camera.

Configure the LED in flash mode with hardware limits matching the
original device configuration, including maximum current and timeout.

In contrary to downstream, we can control both LEDs separately.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi | 27 ++++++++++++++++++++++
 1 file changed, 27 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
index cb5c261802bc9..f3c7333a4076e 100644
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
@@ -589,16 +590,42 @@ &pm8998_resin {
 };
 
 &pmi8998_charger {
 	monitored-battery = <&battery>;
 
 	status = "okay";
 };
 
+&pmi8998_flash {
+	status = "okay";
+
+	/* upper part */
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
+	/* bottom part */
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

