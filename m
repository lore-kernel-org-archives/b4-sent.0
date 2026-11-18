From: David Heidelberg <david@ixit.cz>
Date: Wed, 18 Nov 2026 18:25:42 +0100
Subject: [PATCH v2 09/12] arm64: dts: qcom: sdm845-shift-axolotl: Enable
 vbus support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-pmi8998-vbus-v2-9-3c77a72b280a@ixit.cz>
References: <20261118-pmi8998-vbus-v2-0-3c77a72b280a@ixit.cz>
In-Reply-To: <20261118-pmi8998-vbus-v2-0-3c77a72b280a@ixit.cz>
To: Alexey Minnekhanov <alexeymin@minlexx.ru>, 
 Robin Snyders <robin@snyders.xyz>, Liam Girdwood <lgirdwood@gmail.com>, 
 Mark Brown <broonie@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Wesley Cheng <quic_wcheng@quicinc.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Sebastian Reichel <sre@kernel.org>
Cc: Richard Acayan <mailingradian@gmail.com>, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 linux-pm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1003; i=david@ixit.cz;
 h=from:subject:message-id; bh=VGlvhzohfkCXo1xrxHnzPQfZCT11uvlRraEHS3HXGX8=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq/d+XwLxl+WCziFjoZ0PJmkLg9vtrKNVnyVPw0
 64Tmv/q94+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCav3flwAKCRBgAj/E00kg
 cqLhD/95gZDo8ePIqSIOKZqyj3JHXXnZP/N7/30MxPUqZL8ewdmdsIwQp361cKZl66xHSVr0ORr
 8zAFkEllhvZiWCOL23y0CSiX92gDE8bXajZHqDWr3scdSgikSUrRfIOWM6jwkE/3Nh0RwvRRBs5
 OQUqxyz6F7ChzpNX8QlWuOTYyeKJ/jYGAcdt5RWj+Qgvq/Dh09wTNJyvjtk+8qUS7UltzD8yVKk
 2bLqCPWh97niYRZimUJcthalKOFhLInbJwJPZKHPTwIJyBJ8tdXocZSe3jpW+IP4Fk00ZJMIgWB
 XPc1MKDY9CrYlzxQFjSJP1H54GarCclyW9qWwFDcnfg9PNDawrCmv9/CpoxHPyFJIRhOQijqiqD
 DAGPQE+ozTBCIvbNot/7xY33peECkoXl//BTg9snmTSBoNiiUcg+ckpTqFn/ntw3c2t7ybyAauE
 WkhcWCCaRCB4QZ/Alh/WUAbYwiyGmMsZd9PSI4fHGCNLtK0WcftPQJIf6+uh7BtBEtTfSvBBZz0
 c894fYF4Q2lAw6uE8jDuUhgnPsGICmj3UkqYAUYoFs/NVw/SbWIhznI4CRKX4vAl3jX73A21tOd
 xZpBNu3vBMQEOM+uMSOvkgNCS3Y7upmy49u727Mykg4aut07zO2mCP+xBSAgsP0CWjsdHCjZGKt
 Os3JvI2DkfaTQqg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On this device, vbus was setup and switched off by the charger driver.
Enable proper driver.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
index 1b0eaeafbd517..124717214edd6 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
@@ -654,16 +654,23 @@ led-1 {
 		color = <LED_COLOR_ID_YELLOW>;
 		led-sources = <2>;
 		led-max-microamp = <100000>;
 		flash-max-microamp = <1100000>;
 		flash-max-timeout-us = <1280000>;
 	};
 };
 
+&pmi8998_vbus {
+	regulator-min-microamp = <500000>;
+	regulator-max-microamp = <1500000>;
+
+	status = "okay";
+};
+
 &qup_uart9_rx {
 	drive-strength = <2>;
 	bias-pull-up;
 };
 
 &qup_uart9_tx {
 	drive-strength = <2>;
 	bias-disable;

-- 
2.55.0

