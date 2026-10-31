From: David Heidelberg <david@ixit.cz>
Date: Sat, 31 Oct 2026 16:05:05 +0100
Subject: [PATCH 08/11] arm64: dts: qcom: sdm845-shift-axolotl: Enable vbus
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261031-pmi8998-vbus-v1-8-4d805e5a0f27@ixit.cz>
References: <20261031-pmi8998-vbus-v1-0-4d805e5a0f27@ixit.cz>
In-Reply-To: <20261031-pmi8998-vbus-v1-0-4d805e5a0f27@ixit.cz>
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
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq5gOw+Qmkgmz0PHHPS9JPGISet/lf4b1azhgkm
 QrX0PCfidqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCauYDsAAKCRBgAj/E00kg
 cpwED/9nRiTgNmILcJASqhq+aaUj6Vfii4ZSQ0MJlW1/fTweMIee6vNAV51NrpYcrfHRkmpK46B
 smg0rtNPpOb86pkthZ+A3MPCXQAdlr6j3HhhKtQe7BxMzInp53qDpWBhwHPqpaZMo0jQM1zUtuI
 PYWjfU8KOI+/UKTef+Yq7A8cmNqBdWEDWfqoTxHDYu594rt69n6XRF+Ls+qVCW8GNvHOIDE19eI
 0dQRDsM5eUbs+F2UbKOLpPUi1dLb/h46fip7SID/2JmurfbO9woKrT8LMyour+W8k1/neup6qDm
 HmiNa+pKnM9dw3N+OrZekID7WjCW7Yi/kQyEXwywccCwx9Ow1m0FtXKrwrUIZjA6X8Aiw4z6/f+
 KxqM6s06RtAu9WgxV59C/mcFloiKJJYz/DwsGRm8Fj9naGA4ndazsM0dT9mEBEaW2u9+6lrxDIU
 k1agmTFJMhftbj1JCTvKSRrTvBFtdOcgXrt0rdt+ypDWhJ+9XdSpjuY34G437M/Q2DChp1PGx64
 gmdlPslCtA13tgmK/Os5l7on2MWt6bos61p7OiT1YwFomsdZL6aWTZfse2LGaVi7icoutK8vhQB
 J+CuvJ/QiKkPu6IR/kCOqcdWHtaMLgeSazaRXyl0x6OspQ9uKBNj4zNoYeqeQLoqfhCs+xyVHAY
 EdQuJxWBBabhKxg==
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

