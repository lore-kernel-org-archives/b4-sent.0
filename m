From: Robert Eckelmann <longnoserob@gmail.com>
Date: Wed, 26 Nov 2025 21:08:35 +0900
Subject: [PATCH 1/2] arm64: dts: qcom: sdm845-xiaomi-beryllium: Enable SLPI
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251126-slpi-v1-1-c101d08beaf2@gmail.com>
References: <20251126-slpi-v1-0-c101d08beaf2@gmail.com>
In-Reply-To: <20251126-slpi-v1-0-c101d08beaf2@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 phone-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Robert Eckelmann <longnoserob@gmail.com>, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1037; i=longnoserob@gmail.com;
 h=from:subject:message-id; bh=oQ7sBf0C1pN7qOlstYDWiU3zk1wxIDDBTQIIlEu5j4w=;
 b=owGbwMvMwCVmcOAq9/vk/SGMp9WSGDLV3p7vc5jxXbRvaY/goZql2s5bRH71MoWkXfiwoqe77
 aXG5ajwjlIWBjEuBlkxRZYdbsd0Ml2XRmzcvb8MZg4rE8gQBi5OAZhI/BRGhubIV1vur27R39La
 5hXDMeHbcblIB8aW/hNp6Vwf7p3VyWf47/j2uZ+o15auquKku9Y+Pgt8lTSktSR++5UUTwgKPyn
 MAwA=
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
index 785006a15e97..0fb1d7e724c4 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
@@ -425,6 +425,12 @@ &sdhc_2 {
 	cd-gpios = <&tlmm 126 GPIO_ACTIVE_HIGH>;
 };
 
+&slpi_pas {
+	firmware-name = "qcom/sdm845/beryllium/slpi.mbn";
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

