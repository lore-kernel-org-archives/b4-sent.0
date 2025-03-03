From: Joel Selvaraj <foss@joelselvaraj.com>
Date: Mon, 03 Mar 2025 16:36:57 -0600
Subject: [PATCH v4 3/4] arm64: dts: qcom: sdm845-xiaomi-beryllium-tianma:
 introduce touchscreen support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250303-pocof1-touchscreen-support-v4-3-cdc3bebc3942@joelselvaraj.com>
References: <20250303-pocof1-touchscreen-support-v4-0-cdc3bebc3942@joelselvaraj.com>
In-Reply-To: <20250303-pocof1-touchscreen-support-v4-0-cdc3bebc3942@joelselvaraj.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-input@vger.kernel.org, 
 Joel Selvaraj <foss@joelselvaraj.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741041422; l=1390;
 i=foss@joelselvaraj.com; s=20241007; h=from:subject:message-id;
 bh=yhsKIm7ZLnIXHoyaZNN55eP6DISAW8rg+iMWaf1tr+I=;
 b=MLrnq3P9DpRvQ1b6hK0zSPSpHsWRZb90fRG3foKuAqcctkeChJKR7SWj5C2NekU1bARE+zDJl
 jhL6Cn4u6JSBSTFlJJaDg3adcpEAXMrZTxV4Z6+VNLr79EXAB6YExp+
X-Developer-Key: i=foss@joelselvaraj.com; a=ed25519;
 pk=pqYvzJftxCPloaoUbVsfQE7Gwv8bynZPy8mjYohwMCc=
X-Endpoint-Received: by B4 Relay for foss@joelselvaraj.com/20241007 with auth_id=238
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the Novatek NT36672A touchscreen controller used in the Poco F1
(Tianma) panel variant.

Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Signed-off-by: Joel Selvaraj <foss@joelselvaraj.com>
---
 .../dts/qcom/sdm845-xiaomi-beryllium-tianma.dts    | 23 ++++++++++++++++++++++
 1 file changed, 23 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-tianma.dts b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-tianma.dts
index e9427851ebaa..b58964cde834 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-tianma.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-tianma.dts
@@ -13,3 +13,26 @@ &display_panel {
 	compatible = "tianma,fhd-video", "novatek,nt36672a";
 	status = "okay";
 };
+
+&i2c14 {
+	status = "okay";
+
+	touchscreen@1 {
+		compatible = "novatek,nt36672a-ts";
+		reg = <0x01>;
+
+		interrupts-extended = <&tlmm 31 IRQ_TYPE_EDGE_RISING>;
+		reset-gpios = <&tlmm 32 GPIO_ACTIVE_LOW>;
+		panel = <&display_panel>;
+
+		iovcc-supply = <&vreg_l14a_1p8>;
+		vcc-supply = <&lab>;
+
+		pinctrl-0 = <&ts_int_default &ts_reset_default>;
+		pinctrl-1 = <&ts_int_sleep &ts_reset_sleep>;
+		pinctrl-names = "default", "sleep";
+
+		touchscreen-size-x = <1080>;
+		touchscreen-size-y = <2246>;
+	};
+};

-- 
2.48.1

