From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Mon, 17 Jun 2024 23:22:28 +0200
Subject: [PATCH v2 2/3] ARM: dts: qcom: msm8926-motorola-peregrine: Update
 temperature sensor
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240617-peregrine-v2-2-c8835d2da7af@apitzsch.eu>
References: <20240617-peregrine-v2-0-c8835d2da7af@apitzsch.eu>
In-Reply-To: <20240617-peregrine-v2-0-c8835d2da7af@apitzsch.eu>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 ~postmarketos/upstreaming@lists.sr.ht, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718659400; l=1178;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=lioNlZR631NtRJ2JVy/65vxGGztyn3Q8Af+bbiSagJY=;
 b=ALfmy8RuBtkDBwdTpaCgtWG2bVt1y7mcXue/wSoGL8Th7XZNKTmqfjus459j0baMme4wdvZio
 X+ixkKI5DD+DUHF2suJRSwKU9b6QLD0cMmRpF9Mepl9wU034ioI0l/y
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add alert interrupt for the temperature sensor of Motorola Moto G 4G
(2013), although not used by the driver yet.

Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 arch/arm/boot/dts/qcom/qcom-msm8926-motorola-peregrine.dts | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8926-motorola-peregrine.dts b/arch/arm/boot/dts/qcom/qcom-msm8926-motorola-peregrine.dts
index 50ae3cfc95bb..cff9415baa46 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8926-motorola-peregrine.dts
+++ b/arch/arm/boot/dts/qcom/qcom-msm8926-motorola-peregrine.dts
@@ -125,6 +125,10 @@ reg_lcd_neg: outn {
 	sensor@48 {
 		compatible = "ti,tmp108";
 		reg = <0x48>;
+		interrupts-extended = <&tlmm 13 IRQ_TYPE_LEVEL_LOW>;
+		pinctrl-0 = <&temp_alert_default>;
+		pinctrl-names = "default";
+		#thermal-sensor-cells = <0>;
 	};
 };
 
@@ -361,6 +365,14 @@ reg_lcd_default: reg-lcd-default-state {
 		bias-disable;
 		output-high;
 	};
+
+	temp_alert_default: temp-alert-default-state {
+		pins = "gpio13";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+		output-disable;
+	};
 };
 
 &usb {

-- 
2.45.2

