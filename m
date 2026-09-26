From: David Heidelberg <david@ixit.cz>
Date: Sat, 26 Sep 2026 14:40:26 +0200
Subject: [PATCH RFC 07/12] arm64: dts: qcom: pm660: Add USB Type-C port
 controller node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260926-typec-v1-7-31adc19f32c6@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2238; i=david@ixit.cz;
 h=from:subject:message-id; bh=nfUfneQHFyPXoTLQ2iDCROlyx0D+c7Q2EAHBttmHuPo=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqt70+kPL94BUUjOGf4dU2jnzEuweWBFTQyYS1b
 HYZ1UvtVlyJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCare9PgAKCRBgAj/E00kg
 cqVREACz+DbVUSwKhcqkKE4OxwCx4JSHA1cEOJA49V4LAZx/la2dL4AiUV3IlxIFYTbqLfKPpRR
 eIaXAYKkUUnmXwNsEPZdpqPuruUdkhWm0phR28T7BRg4V+xf6d5euRn4MKo0OyErAAmsQbyxNPA
 Xgxy0vCVrIybsEQwoNvK6UiSXbRlDyj1FZcc+fGmw+br9xRysgXO2ucMfeYlfWROW8d1Jg+zkqr
 SU5/sVC0l60Oof+kgzSki+rrdc4FL+FPaeIfz1gUydnS2FCRZOPMVRB9vZ64E4bdENd6YvoLb6Y
 S0G0MV7BJZRsdGFqt9joe/i8M2ZUrH0GJ7dFsk9zyKSqn7nwZS+5RQnWrjPWqddxV1uSSmWmqZp
 Z1S1DPPVg0fQXxUCctvsN1+lNzkXNmVqsfDxjIIZkl3KYil4EdpwD5+xhOTmv6BuqVH4tJXjApx
 s6V/BJkSUwmfocC09nYr2bdS9wGqQQ4N3Hmb4E++/jw8C6DPb45WBrv7lsC7ofo7axuPHG3ZR4i
 8jgGB2fwINzKdsN1GGWrqMw5BJnVScWmmE4kqDFoaBlBcPAUV0jpRmW76LwRIPFHOuoCRk/qPa9
 aSBijLscrdMObCOLrHYFMS1ockbiHDiUqWzyZmDugImCaodL56lrSlY9/GlsMn5c0zarR3DxeHM
 5LMkgFXkKssTOyA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Alexey Minnekhanov <alexeymin@minlexx.ru>

Add the PM660 Type-C port controller and PD PHY device node.

As on PMI8998, the Type-C CC logic is part of the charger's USBIN
peripheral at 0x1300, the PD PHY is at 0x1700. The node uses the
'type-c-change' interrupt from the USBIN peripheral for CC state
notifications, plus the 8 PD PHY interrupts, including fr-swap.

The node is disabled by default; individual boards enable it and provide
the USB-C connector description with PD capabilities and port graph.

Assisted-by: LLM
Signed-off-by: Alexey Minnekhanov <alexeymin@minlexx.ru>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/pm660.dtsi | 27 +++++++++++++++++++++++++++
 1 file changed, 27 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/pm660.dtsi b/arch/arm64/boot/dts/qcom/pm660.dtsi
index 156b2ddff0dcb..37965a3607417 100644
--- a/arch/arm64/boot/dts/qcom/pm660.dtsi
+++ b/arch/arm64/boot/dts/qcom/pm660.dtsi
@@ -85,16 +85,43 @@ pm660_charger: charger@1000 {
 
 			io-channels = <&pm660_rradc 3>,
 				      <&pm660_rradc 4>;
 			io-channel-names = "usbin_i", "usbin_v";
 
 			status = "disabled";
 		};
 
+		pm660_typec: typec@1300 {
+			compatible = "qcom,pm660-typec";
+			reg = <0x1300>,
+			      <0x1700>;
+
+			interrupts = <0x0 0x13 0x7 IRQ_TYPE_EDGE_RISING>,
+				     <0x0 0x17 0x0 IRQ_TYPE_EDGE_RISING>,
+				     <0x0 0x17 0x1 IRQ_TYPE_EDGE_RISING>,
+				     <0x0 0x17 0x2 IRQ_TYPE_EDGE_RISING>,
+				     <0x0 0x17 0x3 IRQ_TYPE_EDGE_RISING>,
+				     <0x0 0x17 0x4 IRQ_TYPE_EDGE_RISING>,
+				     <0x0 0x17 0x5 IRQ_TYPE_EDGE_RISING>,
+				     <0x0 0x17 0x6 IRQ_TYPE_EDGE_RISING>,
+				     <0x0 0x17 0x7 IRQ_TYPE_EDGE_RISING>;
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
 		pm660_temp: temp-alarm@2400 {
 			compatible = "qcom,spmi-temp-alarm";
 			reg = <0x2400>;
 			interrupts = <0x0 0x24 0x0 IRQ_TYPE_EDGE_RISING>;
 			io-channels = <&pm660_adc ADC5_DIE_TEMP>;
 			io-channel-names = "thermal";
 			#thermal-sensor-cells = <0>;
 		};

-- 
2.55.0

