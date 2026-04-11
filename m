From: David Heidelberg <david@ixit.cz>
Date: Sat, 11 Apr 2026 12:12:03 +0200
Subject: [PATCH v2 2/2] arm64: dts: qcom: sdm845-google: Enable PMI8998
 camera flash LED
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260411-pixel3-camera-v2-2-41b889abb14c@ixit.cz>
References: <20260411-pixel3-camera-v2-0-41b889abb14c@ixit.cz>
In-Reply-To: <20260411-pixel3-camera-v2-0-41b889abb14c@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Petr Hodina <petr.hodina@protonmail.com>, 
 Richard Acayan <mailingradian@gmail.com>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1378; i=david@ixit.cz;
 h=from:subject:message-id; bh=44B67eoSxTZ4WyYriw0YqGPLUibyC/y8pYBqVebOa4c=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp2h5yVvDHV6k5Xumh1+kFN7pxD1UZOBOqzydjx
 3FrS9aCAxmJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCadoecgAKCRBgAj/E00kg
 ci7vD/95LqSUFUncSITjMTfnlRGGmKSZeYvIlA9JO+X8RnkULCj4mnFRxyJzrh3qS2k8FysVytT
 N1eX0VsTMYhxtF6nWR90mYczbjtZJwjpLZsptGlcCUakYUFh/0jmoObs4OelXu/Qv+MKKFoDMrt
 IoGxxN14aKyJsq0x7uC69DBmzRTtmAcyXr0nx6GlStuiWrPXqeD21A29ntf1Huq+27ysWZmk0va
 zaAb/T1kImVZzBnlqVJ+KjZeoW1SEpI5bH4dH8Juruyf25OiTfndfVoNxnOF9SUMu0QoreZiw3c
 yusAyc9CX5e4/gAjUMkWqP6E7YMtYbVkQAJsDxUw19/GBCR6K5Zn6SPk1R/Hz0D+Fad1tVPyM5t
 UdohnQ86RsY6FgPR/zSzuB/LtpZz2J6usosU4BXFIDd3bpGB/lN/rvSG9rPaGGqgbGX180GbzKl
 JfiJXk5OBJWKC+stbV4hLKKCuE6WPRNskQBQQLkmk5Q0sOgCBhOysxMXhkHrvGGqXKhUNAausDt
 6BqMkwKucnkKll50//vMKwuPQK19kUBSF47DvD0ktfxymeV9+Su4y69YJVpQSEazHEwMuDh2sJl
 tiHxwAuAraiDrf898SgbOwglV6lBkd4Haoi271YoDLK2jJeaes10Lb4XOQBUhPWX/4dW7HUZic4
 N1wWpxp4CJOQYqg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the PMI8998 flash LED block and describe the white flash LED
used for the rear camera.

Configure the LED in flash mode with hardware limits matching the
original device configuration, including maximum current and timeout.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
index 084058a597c10..44b6d61697caf 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
@@ -6,6 +6,7 @@
 #include <dt-bindings/dma/qcom-gpi.h>
 #include <dt-bindings/input/linux-event-codes.h>
 #include <dt-bindings/interrupt-controller/irq.h>
+#include <dt-bindings/leds/common.h>
 #include <dt-bindings/media/video-interfaces.h>
 #include <dt-bindings/regulator/qcom,rpmh-regulator.h>
 
@@ -590,6 +591,19 @@ &pmi8998_charger {
 	status = "okay";
 };
 
+&pmi8998_flash {
+	status = "okay";
+
+	led-1 {
+		function = LED_FUNCTION_FLASH;
+		color = <LED_COLOR_ID_WHITE>;
+		led-sources = <2>;
+		led-max-microamp = <500000>;
+		flash-max-microamp = <750000>;
+		flash-max-timeout-us = <1280000>;
+	};
+};
+
 &qupv3_id_0 {
 	status = "okay";
 };

-- 
2.53.0

