From: Robert Eckelmann <longnoserob@gmail.com>
Date: Fri, 05 Dec 2025 22:58:59 +0900
Subject: [PATCH v3 1/3] arm64: dts: qcom: sdm845-xiaomi-beryllium: Enable
 SLPI
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251205-slpi-v3-1-a1320a074345@gmail.com>
References: <20251205-slpi-v3-0-a1320a074345@gmail.com>
In-Reply-To: <20251205-slpi-v3-0-a1320a074345@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 phone-devel@vger.kernel.org, linux-kernel@vger.kernel.org, david@ixit.cz, 
 Robert Eckelmann <longnoserob@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=922; i=longnoserob@gmail.com;
 h=from:subject:message-id; bh=X2jyhLpnhQw17+D9jmrIWEkCOS7CfZrrsf0u+JBIKOM=;
 b=owGbwMvMwCVmcOAq9/vk/SGMp9WSGDKNnurKxPFd3n/4vyCj4HmpyoKCDQ4HrQUOB/bNerp+s
 mpDfp1oRykLgxgXg6yYIssOt2M6ma5LIzbu3l8GM4eVCWQIAxenAEzk8nmG/zFPhLdJfNO/vXK2
 rfqdlNAo9vKNd2NcORQyetpbCkN9oxj+2V+/t9Sw75oOl+q5ebO1vkauK1+1YVuQzXEDo2Keotn
 cPAA=
X-Developer-Key: i=longnoserob@gmail.com; a=openpgp;
 fpr=B846C62C6945A558B1BBBF7630C0D50BEF63BF54
X-Endpoint-Received: by B4 Relay for longnoserob@gmail.com/default with auth_id=569
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the SLPI dsp on the Xiaomi Pocophone F1 with Qualcom SDM845 SoC.

Signed-off-by: Robert Eckelmann <longnoserob@gmail.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
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

