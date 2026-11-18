From: David Heidelberg <david@ixit.cz>
Date: Wed, 18 Nov 2026 18:25:39 +0100
Subject: [PATCH v2 06/12] arm64: dts: qcom: pm660: Add node for PMIC VBUS
 booster
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-pmi8998-vbus-v2-6-3c77a72b280a@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1176; i=david@ixit.cz;
 h=from:subject:message-id; bh=YJAh5JKxsMmwh1tjGfME9pip1rZ2KokfphW0+tMoGZ0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq/d+X4XIJq3Uh7rLMwNZ4NJPm4II+Kh63DpMFb
 /ZVfEWzL/6JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCav3flwAKCRBgAj/E00kg
 cox3D/9cMH6PB7kzKPaSjXBTcH/sfzCqzCHlPHzc7cAPhaMZ7htgH5TjkkbaIcP6iaBd8MoTfgE
 lH6fEDloPOUvbyJQoPbskRvfoQaao3kWeJ8vH0XNnwanu5hykDUUaS3CSzwNZVm8122PqTXYnt8
 d+5FfCfM8qC+BUTLsiHov+92qkfbTFoYiG1hmFyFOy5+/62Q2OW8h1PXz+Q12O4UISLYcvI0tvW
 /TTASCkTiiXAYoXeolQ952X89N9OtE12Ap4BFcxlLQXwhd9PDH3oRKS37Ax6y8W8L6uyrBXNrSq
 Yf992tOOyESMgJGfNem/Wm1g5WdxKe39gQH0w0Gir6PHLyxI72PCKRB3a70fy9Kf6YZfcF9RbZ4
 x6nHFOsD0/G+zDtHCZQ9+l7qSfqXO+5wH2WlTFY+OMaalqcLNhGTYJaBxx3iNy/Ysv9moidC71c
 i4PkMlb9c1OIO17BWzYjDtCtsNesTeqnme2y3IiZC5uEtU8ISIj6WY63qEYQvTiCz5P4n/+Sftw
 5ctFCOw9yWHHSZcB7MN7vhm8FbxhZv1gBysxX/NNZYWjdTdL4KW4cjM8OBoh4DJD/1j8XZVNW4r
 2fXybMu0IlLWiQSZCpMauKy+4W08t7oIZKyGB1iHBJzn6vpN8dIGK3KICn8p+P3xX5WU7Q4atOS
 la1msPiFU5SdInQ==
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
index 156b2ddff0dcb..fe9ef304d64e7 100644
--- a/arch/arm64/boot/dts/qcom/pm660.dtsi
+++ b/arch/arm64/boot/dts/qcom/pm660.dtsi
@@ -85,16 +85,23 @@ pm660_charger: charger@1000 {
 
 			io-channels = <&pm660_rradc 3>,
 				      <&pm660_rradc 4>;
 			io-channel-names = "usbin_i", "usbin_v";
 
 			status = "disabled";
 		};
 
+		pm660_vbus: usb-vbus-regulator@1100 {
+			compatible = "qcom,pm660-vbus-reg", "qcom,pmi8998-vbus-reg";
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

