From: David Heidelberg <david@ixit.cz>
Date: Wed, 18 Nov 2026 18:25:38 +0100
Subject: [PATCH v2 05/12] arm64: dts: qcom: pmi8998: Add node for PMIC VBUS
 booster
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-pmi8998-vbus-v2-5-3c77a72b280a@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1153; i=david@ixit.cz;
 h=from:subject:message-id; bh=Vml5iGmLl1DRnRJN3EG4LOdQ6VYHu9Isno8WfrbJtu0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq/d+XemSzEY+u+p5xduVbCY5qO/O3Aygrw5bOq
 QQpsVQYqa6JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCav3flwAKCRBgAj/E00kg
 ciI4D/4wKee+VYKUNi3UFoP1r1oc2tDloP/9f0eHvYdr9US6whWYCtZO12lCJZt7H0kjfzTaMAT
 MZ6CImazYP7oAkvqTC7U/mHGQHlbq7BhA4ECOmrGf4O3nrf6d6g1Yb1GTc7JouReujrPDSvbAHW
 JyiVliU4K+kmXCpsNGxd5W22FdKECk0aDtBmQdc2XEdY40WUNLhHVpdzmeANyuKdxJpEZuKaA/9
 sBKsxxs9vX3lIwSvuiLLXkB7mEnx0vGiX+W7GtLKy/3v7U3rHTgRMxT7HoKx5lAcrQVRwJSOje7
 HRX6j4XCw7DJNwmXAElrSEDNToJ+HXnyHSp/yIF6XBKPYXcoCEBTi4w8DNkRWcQI6D6lrYySIrk
 Kaq8+t2in19t/0bkBJBBrOtDb0yvb/ONQxQVE/rnSp20n3WgYaMjDhSuxr4M/4VLPhYMiPn5S3Q
 qQL4SmSsrLTmHV3n00RQ9czrWY0xaHPQ53nEUock6gJ6cd4QCsKzjK8BpymR/WqEDwCbzmFJRCy
 n3EqMcuSB5EqClSb8FZubS/tuXAEdyGuGpB0KDvMPBjypgGhW87k2zqMeGJ4ERR67ffuPh3uSBa
 IMmQQhMIczBkuE7fWvK+O8W3iMKazfyPSFTtsoesA2fsP9Gqb4Pja6OOACqYyb5GJws1v1forux
 XgwC2A8he5BtrCw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the required DTS node for the USB VBUS output regulator, which is
available on PMI8998. This will provide the VBUS source to connected
peripherals.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/pmi8998.dtsi | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/pmi8998.dtsi b/arch/arm64/boot/dts/qcom/pmi8998.dtsi
index cd3f0790fd420..9d65dd4abcdbb 100644
--- a/arch/arm64/boot/dts/qcom/pmi8998.dtsi
+++ b/arch/arm64/boot/dts/qcom/pmi8998.dtsi
@@ -24,16 +24,23 @@ pmi8998_charger: charger@1000 {
 
 			io-channels = <&pmi8998_rradc 3>,
 				      <&pmi8998_rradc 4>;
 			io-channel-names = "usbin_i", "usbin_v";
 
 			status = "disabled";
 		};
 
+		pmi8998_vbus: usb-vbus-regulator@1100 {
+			compatible = "qcom,pmi8998-vbus-reg";
+			reg = <0x1100>;
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

