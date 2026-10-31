From: David Heidelberg <david@ixit.cz>
Date: Sat, 31 Oct 2026 16:05:08 +0100
Subject: [PATCH 11/11] arm64: dts: qcom: sdm670-google: Enable vbus support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261031-pmi8998-vbus-v1-11-4d805e5a0f27@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=985; i=david@ixit.cz;
 h=from:subject:message-id; bh=pBRLO5rZ3Rm5tJrcNsGBLN6OjgyMlOuDvEjF7+il+L0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq5gOwhLDb/48orJirTu7/94yDF3J9cj4MK58qB
 gzwA9lAJPaJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCauYDsAAKCRBgAj/E00kg
 cjElEADLWvkkUZnThiqp7xjD5OiyhyBOHmbh4/dUJl97peX0+9x3PZ+tdgXmxqRz2t/1SsOj577
 2KsQdL9+OfMrXvnjZN618mRGROr6yM3k6pGxunLNACnlMiob7pWRjL+uHdS8I+Au8Yq+KJkD4c4
 RvmnaJ39XXDj2NTUfH4fiZnIbfO3vYORGIH8Dd6eTxZr8nr2A99V7RhfZGz0e5lUcnHhhKuEyA9
 yajcezPXRZMYzlDQo3xZ8A30TzJQ6UZAJiY2puGPr7jE9p0BQJwsHgwloI38gRSm8xCmi4WWSLz
 RynkeFrypRgD5c/ssJ5o+ZqlVE1uFkJoFaQF+y/Ou2iatbB6pTJ94je36x7gXs803yN6Gh4r/yk
 aiBoUjNkcYdn+CNN60kKzntlTrs0knq4Dd2djgoEulANMBMSz85n1EkOT+IhMcD9JfmDhacg+/E
 Mo96L42wOCPEMGjg/GsKNEY+COBzTJ1z67mR51jgVawqTqWJ2B8QqhC0OhcKgspuUV3OxkRzTFj
 jRix8tJT5RHtmugWGCQT/5Mx2AUGmQ40+bbBfFy+Z8Sb4l92X5O8P+yGMD2fc5185gAkEaqlKAD
 +HYvX2c9Xxcob3nWMPKFQb4tk9J3fAMyN+LfnRmZKDF422igi6jD72zcL3BFWXBg4RRcpIfHfM4
 I4Gk/3hVrj2jkdg==
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
index 4ce9b62abe53f..94590cccc590f 100644
--- a/arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi
@@ -602,16 +602,23 @@ cam_vio_pin: cam-vio-state {
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

