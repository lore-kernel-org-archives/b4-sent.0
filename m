From: Sam Day <me@samcday.com>
Date: Sat, 26 Sep 2026 18:41:32 +1000
Subject: [PATCH v5 1/3] arm64: dts: qcom: sdm670: add default uart pinctrl
 nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260926-pabloyoyoista-debug-uart-on-rdacayan-next-v5-1-db74ff64a7e7@samcday.com>
References: <20260926-pabloyoyoista-debug-uart-on-rdacayan-next-v5-0-db74ff64a7e7@samcday.com>
In-Reply-To: <20260926-pabloyoyoista-debug-uart-on-rdacayan-next-v5-0-db74ff64a7e7@samcday.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Richard Acayan <mailingradian@gmail.com>, 
 =?utf-8?q?Pablo_Correa_G=C3=B3mez?= <pabloyoyoista@postmarketos.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790412092; l=5952;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=hUNBmM8bvKT0yQH74K4n83NfYx+CXMZCZPR8Oii1LAM=;
 b=+XOS3tpF0pNO7nb/Hy8axf5ILTuwICauA8ye8Qh8t+2gOqac60evnXsR6OXvS8SlZ6lbLLVSd
 Dt4rUDomL9IAEIbKVOnkklj5xEAOXhlGgKC3oDEieCNNMsZHlHK5yVE
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Pablo Correa Gómez <pabloyoyoista@postmarketos.org>

This is a pre-requisite to enable UART in sargo and bonito. Values for
the pins have been taken from sdm845, and cross-checking dowstream,
where available.

Signed-off-by: Pablo Correa Gómez <pabloyoyoista@postmarketos.org>
[sam: drop the tx/rx subnode labels, add drive-strength/bias-disable]
Assisted-by: LLM
Signed-off-by: Sam Day <me@samcday.com>
---
 arch/arm64/boot/dts/qcom/sdm670.dtsi | 256 +++++++++++++++++++++++++++++++++++
 1 file changed, 256 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm670.dtsi b/arch/arm64/boot/dts/qcom/sdm670.dtsi
index 5c60ea36f04a1..09e9d5afa6f65 100644
--- a/arch/arm64/boot/dts/qcom/sdm670.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm670.dtsi
@@ -1343,6 +1343,262 @@ qup_i2c15_default: qup-i2c15-default-state {
 				function = "qup15";
 			};
 
+			qup_uart0_default: qup-uart0-default-state {
+				tx-pins {
+					pins = "gpio2";
+					function = "qup0";
+					drive-strength = <2>;
+					bias-disable;
+				};
+
+				rx-pins {
+					pins = "gpio3";
+					function = "qup0";
+					drive-strength = <2>;
+					bias-disable;
+				};
+			};
+
+			qup_uart1_default: qup-uart1-default-state {
+				tx-pins {
+					pins = "gpio19";
+					function = "qup1";
+					drive-strength = <2>;
+					bias-disable;
+				};
+
+				rx-pins {
+					pins = "gpio20";
+					function = "qup1";
+					drive-strength = <2>;
+					bias-disable;
+				};
+			};
+
+			qup_uart2_default: qup-uart2-default-state {
+				tx-pins {
+					pins = "gpio29";
+					function = "qup2";
+					drive-strength = <2>;
+					bias-disable;
+				};
+
+				rx-pins {
+					pins = "gpio30";
+					function = "qup2";
+					drive-strength = <2>;
+					bias-disable;
+				};
+			};
+
+			qup_uart3_default: qup-uart3-default-state {
+				tx-pins {
+					pins = "gpio43";
+					function = "qup3";
+					drive-strength = <2>;
+					bias-disable;
+				};
+
+				rx-pins {
+					pins = "gpio44";
+					function = "qup3";
+					drive-strength = <2>;
+					bias-disable;
+				};
+			};
+
+			qup_uart4_default: qup-uart4-default-state {
+				tx-pins {
+					pins = "gpio91";
+					function = "qup4";
+					drive-strength = <2>;
+					bias-disable;
+				};
+
+				rx-pins {
+					pins = "gpio92";
+					function = "qup4";
+					drive-strength = <2>;
+					bias-disable;
+				};
+			};
+
+			qup_uart5_default: qup-uart5-default-state {
+				tx-pins {
+					pins = "gpio87";
+					function = "qup5";
+					drive-strength = <2>;
+					bias-disable;
+				};
+
+				rx-pins {
+					pins = "gpio88";
+					function = "qup5";
+					drive-strength = <2>;
+					bias-disable;
+				};
+			};
+
+			qup_uart6_default: qup-uart6-default-state {
+				tx-pins {
+					pins = "gpio47";
+					function = "qup6";
+					drive-strength = <2>;
+					bias-disable;
+				};
+
+				rx-pins {
+					pins = "gpio48";
+					function = "qup6";
+					drive-strength = <2>;
+					bias-disable;
+				};
+			};
+
+			qup_uart7_default: qup-uart7-default-state {
+				tx-pins {
+					pins = "gpio95";
+					function = "qup7";
+					drive-strength = <2>;
+					bias-disable;
+				};
+
+				rx-pins {
+					pins = "gpio96";
+					function = "qup7";
+					drive-strength = <2>;
+					bias-disable;
+				};
+			};
+
+			qup_uart8_default: qup-uart8-default-state {
+				tx-pins {
+					pins = "gpio67";
+					function = "qup8";
+					drive-strength = <2>;
+					bias-disable;
+				};
+
+				rx-pins {
+					pins = "gpio68";
+					function = "qup8";
+					drive-strength = <2>;
+					bias-disable;
+				};
+			};
+
+			qup_uart9_default: qup-uart9-default-state {
+				tx-pins {
+					pins = "gpio4";
+					function = "qup9";
+					drive-strength = <2>;
+					bias-disable;
+				};
+
+				rx-pins {
+					pins = "gpio5";
+					function = "qup9";
+					drive-strength = <2>;
+					bias-disable;
+				};
+			};
+
+			qup_uart10_default: qup-uart10-default-state {
+				tx-pins {
+					pins = "gpio53";
+					function = "qup10";
+					drive-strength = <2>;
+					bias-disable;
+				};
+
+				rx-pins {
+					pins = "gpio54";
+					function = "qup10";
+					drive-strength = <2>;
+					bias-disable;
+				};
+			};
+
+			qup_uart11_default: qup-uart11-default-state {
+				tx-pins {
+					pins = "gpio33";
+					function = "qup11";
+					drive-strength = <2>;
+					bias-disable;
+				};
+
+				rx-pins {
+					pins = "gpio34";
+					function = "qup11";
+					drive-strength = <2>;
+					bias-disable;
+				};
+			};
+
+			qup_uart12_default: qup-uart12-default-state {
+				tx-pins {
+					pins = "gpio51";
+					function = "qup12";
+					drive-strength = <2>;
+					bias-disable;
+				};
+
+				rx-pins {
+					pins = "gpio52";
+					function = "qup12";
+					drive-strength = <2>;
+					bias-disable;
+				};
+			};
+
+			qup_uart13_default: qup-uart13-default-state {
+				tx-pins {
+					pins = "gpio107";
+					function = "qup13";
+					drive-strength = <2>;
+					bias-disable;
+				};
+
+				rx-pins {
+					pins = "gpio108";
+					function = "qup13";
+					drive-strength = <2>;
+					bias-disable;
+				};
+			};
+
+			qup_uart14_default: qup-uart14-default-state {
+				tx-pins {
+					pins = "gpio31";
+					function = "qup14";
+					drive-strength = <2>;
+					bias-disable;
+				};
+
+				rx-pins {
+					pins = "gpio32";
+					function = "qup14";
+					drive-strength = <2>;
+					bias-disable;
+				};
+			};
+
+			qup_uart15_default: qup-uart15-default-state {
+				tx-pins {
+					pins = "gpio83";
+					function = "qup15";
+					drive-strength = <2>;
+					bias-disable;
+				};
+
+				rx-pins {
+					pins = "gpio84";
+					function = "qup15";
+					drive-strength = <2>;
+					bias-disable;
+				};
+			};
+
 			sdc1_state_on: sdc1-on-state {
 				clk-pins {
 					pins = "sdc1_clk";

-- 
2.55.0

