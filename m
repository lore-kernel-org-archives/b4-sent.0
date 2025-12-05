From: Robert Eckelmann <longnoserob@gmail.com>
Date: Fri, 05 Dec 2025 22:00:04 +0900
Subject: [PATCH v2 1/3] arm64: dts: qcom: sdm845-xiaomi-beryllium: Enable
 SLPI
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251205-slpi-v2-1-dfe0b106cf1a@gmail.com>
References: <20251205-slpi-v2-0-dfe0b106cf1a@gmail.com>
In-Reply-To: <20251205-slpi-v2-0-dfe0b106cf1a@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 phone-devel@vger.kernel.org, linux-kernel@vger.kernel.org, david@ixit.cz, 
 Robert Eckelmann <longnoserob@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1044; i=longnoserob@gmail.com;
 h=from:subject:message-id; bh=AE9KxQiMpmdD1lHdyzsIYuYg+WK329GmEsuY+M4AANc=;
 b=owGbwMvMwCVmcOAq9/vk/SGMp9WSGDKNrrftfxA4x9okg18sc6ngKu71fDPPRGYmsSSlzL4z6
 fazRn7mjlIWBjEuBlkxRZYdbsd0Ml2XRmzcvb8MZg4rE8gQBi5OAZhIZRMjw4fzz5d8E7scbTlh
 17fldw6s+d30o2/93ZeuAQuUpHwmHnJmZHiha8W773moz/WMIzMz7vxJV9TcyhEdXcL9Kmdd/mq
 mDH4A
X-Developer-Key: i=longnoserob@gmail.com; a=openpgp;
 fpr=B846C62C6945A558B1BBBF7630C0D50BEF63BF54
X-Endpoint-Received: by B4 Relay for longnoserob@gmail.com/default with auth_id=569
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the SLPI dsp on the Xiaomi Pocophone F1 with Qualcom SDM845 SoC.

Signed-off-by: Robert Eckelmann <longnoserob@gmail.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
index 785006a15e97..cadddcf63ef6 100644
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
@@ -637,3 +643,4 @@ &wifi {
 	vdd-3.3-ch0-supply = <&vreg_l25a_3p3>;
 	vdd-3.3-ch1-supply = <&vreg_l23a_3p3>;
 };
+

-- 
2.52.0

