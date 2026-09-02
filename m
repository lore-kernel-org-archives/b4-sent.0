From: David Heidelberg <david@ixit.cz>
Date: Wed, 02 Sep 2026 22:59:14 +0200
Subject: [PATCH 3/3] arm64: dts: qcom: sdm670-google: Add NFC support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260902-sdm670-sargo-nfc-v1-3-bed1cbbffc46@ixit.cz>
References: <20260902-sdm670-sargo-nfc-v1-0-bed1cbbffc46@ixit.cz>
In-Reply-To: <20260902-sdm670-sargo-nfc-v1-0-bed1cbbffc46@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Richard Acayan <mailingradian@gmail.com>
Cc: Marco Mattiolo <marco.mattiolo@hotmail.it>, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2123; i=david@ixit.cz;
 h=from:subject:message-id; bh=nLoRLzWSD9I8QjZocCX1KJtlPxdBkqwCM/C1ynX9oYU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqmI4lAGgep8wCBGzhi2XmUy1eTpd8/Zc4BltUq
 VVVEFJB3t2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCapiOJQAKCRBgAj/E00kg
 cmINEACG77+AleMKMB6rN/hKly9BtOeMUj9oRTl0d2+0na6z7eZHh/ihzDX9SpiA6pAFYS2dEqy
 fbAvi8Wd5/0ILeH3UBAT60VfQPkkcKF2AI8GPXuM/eiWb2ERpiEwp01ztoxbWWlV8XGGIA0Q8d9
 z728nkurL7iRPObbQ709ae18JWQJrhMwPks48Pz0YS7uaD09F6hyAj/ggmFPC6hDegIc/K5sst8
 r81ssdbscKNdwmkY6LWMOGCNez4yfuh0DDMBER+7v7WZjoZSkX1gkFtNCFzvBavqEo7YblRZ3WO
 h/MI3jitl909G45vDKSDSiULcIHdnDvdbDH8vI0ElnJY27F34In8BNA8l6efldyztYvT8DWdzRv
 Fwda6uRjnOnlUpr692y0Xkx5slvTXYT7Tq8DjZcBM5+/pXHiZGNiRt/V+zu4AY3QwPzdk9zFom9
 pYIlNqEBJRLNZ/dPkNTnsS972JwGVueHBBUo8BFJkEObHSboXIMFzET59ALPqDSsYiptI3mBgsI
 cYdIiz9oQqExslxtu2KgtNTC2vB+hject/SvVQmGmIMVUv236/7kHwHZf7GU7a3vFjZYAf+49iN
 W6fekChjwbJEV1XBPF9m7v+8dlq7FMj1iA7b1KjaTelq6uzcQsl35Rts9JeorzDgwjsS7NRu/ip
 E7ZnTx7keLk/PSA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Richard Acayan <mailingradian@gmail.com>

The NFC driver can detect and read an NFC tag.

Signed-off-by: Richard Acayan <mailingradian@gmail.com>
Co-developed-by: David Heidelberg <david@ixit.cz>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi | 42 ++++++++++++++++++++++
 1 file changed, 42 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi b/arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi
index b4854801a5f5e..5c2613e53679c 100644
--- a/arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi
@@ -485,16 +485,35 @@ &gpi_dma1 {
 &gpu {
 	status = "okay";
 };
 
 &gpu_zap_shader {
 	firmware-name = "qcom/sdm670/sargo/a615_zap.mbn";
 };
 
+&i2c3 {
+	clock-frequency = <400000>;
+
+	status = "okay";
+
+	nfc@28 {
+		compatible = "nxp,pn557", "nxp,nxp-nci-i2c";
+		reg = <0x28>;
+
+		interrupts-extended = <&tlmm 44 IRQ_TYPE_EDGE_RISING>;
+
+		enable-gpios = <&tlmm 12 GPIO_ACTIVE_HIGH>;
+		firmware-gpios = <&tlmm 43 GPIO_ACTIVE_HIGH>;
+
+		pinctrl-0 = <&nfc_default>;
+		pinctrl-names = "default";
+	};
+};
+
 &i2c9 {
 	clock-frequency = <100000>;
 	status = "okay";
 
 	synaptics-rmi4-i2c@20 {
 		compatible = "syna,rmi4-i2c";
 		reg = <0x20>;
 		interrupts-extended = <&tlmm 125 IRQ_TYPE_EDGE_FALLING>;
@@ -686,16 +705,39 @@ ts-irq-pins {
 		ts-switch-pins {
 			pins = "gpio135";
 			function = "gpio";
 			drive-strength = <2>;
 			bias-disable;
 			output-low;
 		};
 	};
+
+	nfc_default: nfc-default-state {
+		enable-pins {
+			pins = "gpio12";
+			function = "gpio";
+			drive-strength = <2>;
+			bias-pull-down;
+		};
+
+		firmware-pins {
+			pins = "gpio43";
+			function = "gpio";
+			drive-strength = <2>;
+			bias-pull-down;
+		};
+
+		irq-pins {
+			pins = "gpio44";
+			function = "gpio";
+			drive-strength = <2>;
+			bias-pull-down;
+		};
+	};
 };
 
 &usb_1_hsphy {
 	vdd-supply = <&vreg_l1b_0p925>;
 	vdda-pll-supply = <&vreg_l10a_1p8>;
 	vdda-phy-dpdm-supply = <&vreg_l7b_3p125>;
 
 	status = "okay";

-- 
2.55.0

