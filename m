From: David Heidelberg <david@ixit.cz>
Date: Wed, 18 Nov 2026 18:25:45 +0100
Subject: [PATCH v2 12/12] arm64: dts: qcom: sdm670-google: Enable vbus
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-pmi8998-vbus-v2-12-3c77a72b280a@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=985; i=david@ixit.cz;
 h=from:subject:message-id; bh=opQSg7fZ2yNDm8dbUq57ONjOIZ7j+aCXyQPY1Da3ae0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq/d+X8tGUm9NqcawCeiNNQn3yPCHrsJApxfjza
 /qcssjy6P6JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCav3flwAKCRBgAj/E00kg
 cuOpD/9Mlt3mX5CO1pP7WQX65+rTeQsLM5MkbJ7evmfniT6rHsLOhp71uqBd1GUskQtHJKzxUeU
 0xzKXgB6mfU0pZxyX7A3o3ukHz0LGlBvpLJplRTxru7BL/3f5tkcI+81kTmHBABSXlxdU/D0EoK
 xeO+HpfOfSV75ZzWypwhrmK8vVusYRi4OKMj8jP5p1mlJEXchi3OLXgp3YAuOgj+WqDFmRDdr/D
 YhK9pYMeN0pFs4GgSbaG32ytluKhtIH0p+Re5XZjF4NbxGo9A+SsKWcN5FTqyFGeh4LR4FNRRz7
 d+Qr+lU0HGL0fad1FeZ0dSbWEAaSjwcPjIKwpC/5zgWBAAiOW3itJh3aOBI5XSnqf+9YLycrVfk
 xW3p1cT7PB6W7I4hV8Abk+yrRPDAra0ALUVbAnZnV8y3k1jTp8Z7ZTrolTn4ydrcjSqYFgcDAuR
 acZZEw40VqXMeprrOYbCfS9ubj3OGFXzcToVqAOe+414UW1leMeKg1klnXXTt/OG9EDCALu6u2T
 QTGZw9p+3k/g/hMj1K6uzQsIB61PX50Puvaj1qzAU6LfO5e8jo99pY62Ulp1//OmEjtILyn39MN
 EBgix4WWMXgCRfIjX67T5XjXH3UwDvWdvKrcuCMD6I//Bww47MPrmeb38g6XVvmx9QfsnmhOw1h
 KnLowI+KdNeqNyA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On this device, vbus was setup and switched off by the charger driver.
Enable proper driver.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi b/arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi
index 8f91faf8a9cc5..9c95855b56e7b 100644
--- a/arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi
@@ -604,16 +604,23 @@ cam_vio_pin: cam-vio-state {
 		power-source = <0>;
 	};
 };
 
 &pm660_rradc {
 	status = "okay";
 };
 
+&pm660_vbus {
+	regulator-min-microamp = <500000>;
+	regulator-max-microamp = <1500000>;
+
+	status = "okay";
+};
+
 &pm660l_flash {
 	status = "okay";
 
 	led-0 {
 		function = LED_FUNCTION_FLASH;
 		color = <LED_COLOR_ID_WHITE>;
 		led-sources = <1>, <2>;
 		led-max-microamp = <500000>;

-- 
2.55.0

