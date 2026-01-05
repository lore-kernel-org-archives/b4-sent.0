From: Robert Eckelmann <longnoserob@gmail.com>
Date: Mon, 05 Jan 2026 22:31:51 +0900
Subject: [PATCH v4 1/3] arm64: dts: qcom: sdm845-xiaomi-beryllium: Enable
 SLPI
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260105-slpi-v4-1-e6e0abfad3a4@gmail.com>
References: <20260105-slpi-v4-0-e6e0abfad3a4@gmail.com>
In-Reply-To: <20260105-slpi-v4-0-e6e0abfad3a4@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 phone-devel@vger.kernel.org, linux-kernel@vger.kernel.org, david@ixit.cz, 
 Robert Eckelmann <longnoserob@gmail.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=989; i=longnoserob@gmail.com;
 h=from:subject:message-id; bh=43kKQJ2mrMLWelYKXy1f8QwGrRrSkq/JoF9T1aflu3c=;
 b=owGbwMvMwCVmcOAq9/vk/SGMp9WSGDKj91Y5ndp0SXKNZJ/MmmOLeCXOlTEZVhl58+xdu4Dr4
 nrNnEuRHaUsDGJcDLJiiiw73I7pZLoujdi4e38ZzBxWJpAhDFycAjCR/7MYGfY9i3LR6lB6pJHZ
 9m9Bqfm7mzH+Wnny4ktZIs48u7NM6xwjwy3pxPSNMjHTN0WnGO9b2tFr+ibw6seJm7V9BG8EMs5
 uZwcA
X-Developer-Key: i=longnoserob@gmail.com; a=openpgp;
 fpr=B846C62C6945A558B1BBBF7630C0D50BEF63BF54
X-Endpoint-Received: by B4 Relay for longnoserob@gmail.com/default with auth_id=569
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the SLPI dsp on the Xiaomi Pocophone F1 with Qualcom SDM845 SoC.

Signed-off-by: David Heidelberg <david@ixit.cz>
Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Signed-off-by: Robert Eckelmann <longnoserob@gmail.com>
---
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
index 785006a15e97..57af560e35ce 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
@@ -425,6 +425,12 @@ &sdhc_2 {
 	cd-gpios = <&tlmm 126 GPIO_ACTIVE_HIGH>;
 };
 
+&slpi_pas {
+	firmware-name = "qcom/sdm845/Xiaomi/beryllium/slpi.mbn";
+
+	status = "okay";
+};
+
 &sound {
 	compatible = "qcom,db845c-sndcard", "qcom,sdm845-sndcard";
 	pinctrl-0 = <&quat_mi2s_active

-- 
2.52.0

