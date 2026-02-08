From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Sun, 08 Feb 2026 22:25:40 +0100
Subject: [PATCH 3/4] arm64: dts: qcom: x1-vivobook-s15: create a common
 dtsi for Hamoa and Purwa variants
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260208-b4-vivobook-v1-3-3a9b5e153909@oldschoolsolutions.biz>
References: <20260208-b4-vivobook-v1-0-3a9b5e153909@oldschoolsolutions.biz>
In-Reply-To: <20260208-b4-vivobook-v1-0-3a9b5e153909@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Maud Spierings <maud_spierings@hotmail.com>, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770585945; l=2235;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=Y2qI1/Z1yfQDT1AVJoKJZZpFnOZ4lrVs42vPBsxZ9/I=;
 b=apTc6Gg3RSrTxFsFUqVHgpwtchAffdCNlUGQ8tDMPm1K8/J4XhXlZRXlTVCJ08bL9iudkZ4GH
 L4mim6Yp2GYCHcRL1qtSIuRvm4R2jJy1hiLsAUclbwVLZOmm28Og5xc
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Asus VivoBook S15 S5507QA is sold with x1e-78-100 and x1p-42-100 SKUs.
Put the common part into one dtsi file to be included for model-specific dts.

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 ...-vivobook-s15.dts => x1-asus-vivobook-s15.dtsi} | 28 ----------------------
 1 file changed, 28 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/x1e80100-asus-vivobook-s15.dts b/arch/arm64/boot/dts/qcom/x1-asus-vivobook-s15.dtsi
similarity index 97%
copy from arch/arm64/boot/dts/qcom/x1e80100-asus-vivobook-s15.dts
copy to arch/arm64/boot/dts/qcom/x1-asus-vivobook-s15.dtsi
index 17269eb0638acb81cef7112285372b5d306ed8c3..1ac64d64e675b557d86042c3c361239170cf3f97 100644
--- a/arch/arm64/boot/dts/qcom/x1e80100-asus-vivobook-s15.dts
+++ b/arch/arm64/boot/dts/qcom/x1-asus-vivobook-s15.dtsi
@@ -4,19 +4,14 @@
  * Copyright (c) 2024, Xilin Wu <wuxilin123@gmail.com>
  */
 
-/dts-v1/;
-
 #include <dt-bindings/gpio/gpio.h>
 #include <dt-bindings/input/gpio-keys.h>
 #include <dt-bindings/regulator/qcom,rpmh-regulator.h>
 #include <dt-bindings/pinctrl/qcom,pmic-gpio.h>
 
-#include "hamoa.dtsi"
 #include "hamoa-pmics.dtsi"
 
 / {
-	model = "ASUS Vivobook S 15";
-	compatible = "asus,vivobook-s15", "qcom,x1e80100";
 	chassis-type = "laptop";
 
 	aliases {
@@ -632,10 +627,6 @@ &gpu {
 	status = "okay";
 };
 
-&gpu_zap_shader {
-	firmware-name = "qcom/x1e80100/ASUSTeK/vivobook-s15/qcdxkmsuc8380.mbn";
-};
-
 &i2c0 {
 	clock-frequency = <400000>;
 	status = "okay";
@@ -833,11 +824,6 @@ retimer_ss1_con_sbu_out: endpoint {
 	};
 };
 
-&iris {
-	firmware-name = "qcom/x1e80100/ASUSTeK/vivobook-s15/qcvss8380.mbn";
-	status = "okay";
-};
-
 &mdss {
 	status = "okay";
 };
@@ -1027,20 +1013,6 @@ &qupv3_2 {
 	status = "okay";
 };
 
-&remoteproc_adsp {
-	firmware-name = "qcom/x1e80100/ASUSTeK/vivobook-s15/qcadsp8380.mbn",
-			"qcom/x1e80100/ASUSTeK/vivobook-s15/adsp_dtbs.elf";
-
-	status = "okay";
-};
-
-&remoteproc_cdsp {
-	firmware-name = "qcom/x1e80100/ASUSTeK/vivobook-s15/qccdsp8380.mbn",
-			"qcom/x1e80100/ASUSTeK/vivobook-s15/cdsp_dtbs.elf";
-
-	status = "okay";
-};
-
 &smb2360_0 {
 	status = "okay";
 };

-- 
2.51.0

