From: David Heidelberg <david@ixit.cz>
Date: Sat, 26 Sep 2026 14:40:27 +0200
Subject: [PATCH RFC 08/12] arm64: dts: qcom: pmi8998: Add USB Type-C port
 controller node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260926-typec-v1-8-31adc19f32c6@ixit.cz>
References: <20260926-typec-v1-0-31adc19f32c6@ixit.cz>
In-Reply-To: <20260926-typec-v1-0-31adc19f32c6@ixit.cz>
To: Alexey Minnekhanov <alexeymin@minlexx.ru>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Lee Jones <lee@kernel.org>, Stephen Boyd <sboyd@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 phone-devel@vger.kernel.org, mfd@lists.linux.dev, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2142; i=david@ixit.cz;
 h=from:subject:message-id; bh=RieyzNgTb75VGeJsjq62hPOrIsikmavlqM7+JXkr+qg=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqt70+hRgy8KUAH4mpYNQGJAeTLLsf1WXpUNnqL
 U2lph0zExGJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCare9PgAKCRBgAj/E00kg
 csT5EACstGo4EK8/PM5YY9feak3r3qMK+hB2xbrMeNEW8ItM8IQd3sen0VXPFVcGzL7XzKbQ/EN
 tDREYBfiN4pfXeZWfXTCr9z3rbv3xT3/jCo/0KYT1dOcOMo6U9M002lq0ZlltL4MMi/bi4N5ykf
 Q/sVh1H82IITWcqriljTQl+4JSzISseeIiIeP/m4kiv3NJ3Fb5wZ/ql1nkqk8MXwJENZAc0aGbM
 /s0gOShQxNEkGUqKSl5owXD60auXbNLnqvWTMmY4krRp0HV9aD8eiQXv+N4F39wCJPPcerJXcJW
 EoLhT9P89LPO1oiWerKUjeNhM0AuigruCZJUJE97xD2JAWimVAvfN24erXzlQuRIN1fEGIEnfMI
 JK1dkMVfDlmuV3m96qe4X1AZ+6xOyCa+8FDFKOHtcrOsLK31PqjMXDRuPuVL+IiwFdFlVNOg1SU
 3tNY3MhhzlcgyU3TuP8og9vnKfWXLyE02r9UeGjtH+Ght36QUW3Dgnp2leEuZM4xJ+evi7vw4ED
 V//UYxzhmJhbGkSDi4FnUG8G9/vdVwzm9ykX1Sl0jFIn4V0Qh0gZ0ohJcVjQ+g1aJCFQrmDbah/
 UmXHkdhVcoFtSmRsEnQXItwZ1rMzvYChAJklsDEPAJioAqWH/ViXc4W3kai+LuO3QRJ2Uf00ynA
 KZ/ZPZYQd+5lE6A==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the pmi8998 Type-C port controller and PD PHY device node.

The Type-C CC logic is at USBIN base 0x1300 and the PD PHY is at 0x1700.
The node uses the 'type-c-change' interrupt from the USBIN peripheral
for CC state notifications, plus the 8 PD PHY interrupts, including
fr-swap.

The node is disabled by default; individual boards enable it and provide
the USB-C connector description with PD capabilities and port graph.

Assisted-by: LLM
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/pmi8998.dtsi | 27 +++++++++++++++++++++++++++
 1 file changed, 27 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/pmi8998.dtsi b/arch/arm64/boot/dts/qcom/pmi8998.dtsi
index cd3f0790fd420..878e577c667d0 100644
--- a/arch/arm64/boot/dts/qcom/pmi8998.dtsi
+++ b/arch/arm64/boot/dts/qcom/pmi8998.dtsi
@@ -24,16 +24,43 @@ pmi8998_charger: charger@1000 {
 
 			io-channels = <&pmi8998_rradc 3>,
 				      <&pmi8998_rradc 4>;
 			io-channel-names = "usbin_i", "usbin_v";
 
 			status = "disabled";
 		};
 
+		pmi8998_typec: typec@1300 {
+			compatible = "qcom,pmi8998-typec";
+			reg = <0x1300>,
+			      <0x1700>;
+
+			interrupts = <0x2 0x13 0x7 IRQ_TYPE_EDGE_RISING>,
+				     <0x2 0x17 0x0 IRQ_TYPE_EDGE_RISING>,
+				     <0x2 0x17 0x1 IRQ_TYPE_EDGE_RISING>,
+				     <0x2 0x17 0x2 IRQ_TYPE_EDGE_RISING>,
+				     <0x2 0x17 0x3 IRQ_TYPE_EDGE_RISING>,
+				     <0x2 0x17 0x4 IRQ_TYPE_EDGE_RISING>,
+				     <0x2 0x17 0x5 IRQ_TYPE_EDGE_RISING>,
+				     <0x2 0x17 0x6 IRQ_TYPE_EDGE_RISING>,
+				     <0x2 0x17 0x7 IRQ_TYPE_EDGE_RISING>;
+			interrupt-names = "type-c-change",
+					  "sig-tx",
+					  "sig-rx",
+					  "msg-tx",
+					  "msg-rx",
+					  "msg-tx-failed",
+					  "msg-tx-discarded",
+					  "msg-rx-discarded",
+					  "fr-swap";
+
+			status = "disabled";
+		};
+
 		pmi8998_gpios: gpio@c000 {
 			compatible = "qcom,pmi8998-gpio", "qcom,spmi-gpio";
 			reg = <0xc000>;
 			gpio-controller;
 			gpio-ranges = <&pmi8998_gpios 0 0 14>;
 			#gpio-cells = <2>;
 			interrupt-controller;
 			#interrupt-cells = <2>;

-- 
2.55.0

