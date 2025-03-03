From: Joel Selvaraj <foss@joelselvaraj.com>
Date: Mon, 03 Mar 2025 16:36:56 -0600
Subject: [PATCH v4 2/4] arm64: dts: qcom: sdm845-xiaomi-beryllium-common:
 add touchscreen related nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250303-pocof1-touchscreen-support-v4-2-cdc3bebc3942@joelselvaraj.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741041422; l=2097;
 i=foss@joelselvaraj.com; s=20241007; h=from:subject:message-id;
 bh=EpPcR4Wun9zUS0l7gI/2ehR5PCkceW/n4h3upa10e/U=;
 b=5HqTN23bgnrRLSnkhvdPiYHCUZEiJcBwHMndr/sU+wScCWIoPdf+OLkKjg3rPa1GoajeSFEUp
 92O0pwh2d8+CnxYbuNwUNqsHCDoH6xosFwt2yCV8HdgadfGlWzeCsbZ
X-Developer-Key: i=foss@joelselvaraj.com; a=ed25519;
 pk=pqYvzJftxCPloaoUbVsfQE7Gwv8bynZPy8mjYohwMCc=
X-Endpoint-Received: by B4 Relay for foss@joelselvaraj.com/20241007 with auth_id=238
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable qupv3_id_1 and gpi_dma1 as they are required for configuring
touchscreen. Also add pinctrl configurations needed for touchscreen.
These are common for both the tianma and ebbg touchscreen variant.
In the subsequent patches, we will enable support for the Novatek NT36672a
touchscreen and FocalTech FT8719 touchscreen that are used in the Poco F1
Tianma and EBBG panel variant respectively. This is done in preparation
for that.

Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Signed-off-by: Joel Selvaraj <foss@joelselvaraj.com>
---
 .../dts/qcom/sdm845-xiaomi-beryllium-common.dtsi   | 39 ++++++++++++++++++++++
 1 file changed, 39 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
index 617b17b2d7d9..e93ed6effdd7 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
@@ -243,6 +243,10 @@ &gmu {
 	status = "okay";
 };
 
+&gpi_dma1 {
+	status = "okay";
+};
+
 &gpu {
 	status = "okay";
 
@@ -408,6 +412,10 @@ &qupv3_id_0 {
 	status = "okay";
 };
 
+&qupv3_id_1 {
+	status = "okay";
+};
+
 &sdhc_2 {
 	status = "okay";
 
@@ -513,6 +521,37 @@ sdc2_card_det_n: sd-card-det-n-state {
 		function = "gpio";
 		bias-pull-up;
 	};
+
+	ts_int_default: ts-int-default-state {
+		pins = "gpio31";
+		function = "gpio";
+		drive-strength = <16>;
+		bias-pull-down;
+		output-disable;
+	};
+
+	ts_reset_default: ts-reset-default-state {
+		pins = "gpio32";
+		function = "gpio";
+		drive-strength = <16>;
+		output-high;
+	};
+
+	ts_int_sleep: ts-int-sleep-state {
+		pins = "gpio31";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-pull-down;
+		output-disable;
+	};
+
+	ts_reset_sleep: ts-reset-sleep-state {
+		pins = "gpio32";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+		output-low;
+	};
 };
 
 &uart6 {

-- 
2.48.1

