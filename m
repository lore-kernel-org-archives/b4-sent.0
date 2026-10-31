From: David Heidelberg <david@ixit.cz>
Date: Sat, 31 Oct 2026 16:05:02 +0100
Subject: [PATCH 05/11] arm64: dts: qcom: pm660: Add node for PMIC VBUS
 booster
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261031-pmi8998-vbus-v1-5-4d805e5a0f27@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1176; i=david@ixit.cz;
 h=from:subject:message-id; bh=p63Dg9i1oE6P2ODBJ4VzZiAmk+f8FnNEbY1449D7Tf4=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq5gOveGztyizkzMKlhhMHa6tPLFDLf6x7vnkdn
 IKLLQdF3R2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCauYDrwAKCRBgAj/E00kg
 ck2pEACiYMmrBoBCQJrpMIg53wd8Q3hcKdPXITGKL9loBR8pjG79vwHd2ofjQCiCMi188so6Uhz
 YLe9KjgC0NOipwW0ip1eR1J4okOE7lo4QQh5wkk6Rv5MYp0vDnaqcSlxWQkhSaiB0xxOcLqRx/S
 TLiofbrNuaInNv6r6uKg05U9moaSi23jrkjFZ0EJru15WMNp+JsuyM5y5Lo0QDn5jNnm7TbqI2H
 olwLupTVZXqwmfOKGSoy2xEt8ecZAH5RsUAdacLm41fYpGWuh5MZKxj8QCfXzS9juM+m6hYFrN9
 BDfCasROXhdMOpcq1W+LwZEb+QGX0mYLGaelr5VWaBPkBTBX8Z/7QoEBXN4eK8NEMDfCde8Dx/i
 IRzVK7gV5RoV8fCdz/S/OwHVE+nzHDtLsIUNEr0FCOv98htYCW63y2uFfBLCmNrxR/xet22rZHw
 BxEsluh1hjm70wDdxbYiodbMje+oBCJXXLMAzK8fdnYPRdOBeHha9R6QtIy/5bak4FlHiN9TLNw
 1UTVQSHpNWQehjTjC0s77C7AWn7jH0PUmguHnEE+gcZtWg+O2V5HB83kJ20vMzpLqZ3xCMo6DsJ
 jYgkX0G+bxP5efObUzBsoWVpupJWJbKN8iuJ8ihSzEbxvN6fTWteKc0w4EDtu99svhTEPq6eyMj
 Pdjz4JoMgmDhRfA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the required DTS node for the USB VBUS output regulator, which is
available on PM660. This will provide the VBUS source to connected
peripherals.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/pm660.dtsi | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/pm660.dtsi b/arch/arm64/boot/dts/qcom/pm660.dtsi
index 156b2ddff0dcb..86e9223ed88f4 100644
--- a/arch/arm64/boot/dts/qcom/pm660.dtsi
+++ b/arch/arm64/boot/dts/qcom/pm660.dtsi
@@ -85,16 +85,23 @@ pm660_charger: charger@1000 {
 
 			io-channels = <&pm660_rradc 3>,
 				      <&pm660_rradc 4>;
 			io-channel-names = "usbin_i", "usbin_v";
 
 			status = "disabled";
 		};
 
+		pm660_vbus: usb-vbus-regulator@1100 {
+			compatible = "qcom,pm660-vbus-reg", "qcom,pm8150b-vbus-reg";
+			reg = <0x1100>;
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

