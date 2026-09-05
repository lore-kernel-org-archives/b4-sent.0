From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Sat, 05 Sep 2026 11:29:00 +0200
Subject: [PATCH 5/7] arm64: dts: qcom: ideacentre-mini: Fix the second M.2
 3V3 rail
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260905-x1-ideacentre-mini-prettify-v1-5-9a87882973bb@oldschoolsolutions.biz>
References: <20260905-x1-ideacentre-mini-prettify-v1-0-9a87882973bb@oldschoolsolutions.biz>
In-Reply-To: <20260905-x1-ideacentre-mini-prettify-v1-0-9a87882973bb@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788600555; l=2236;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=Mbc9hxbkPkS0pdjVkRDoJOizEKE/npezL/nBqRXTsNU=;
 b=+BL58zAwMzRiORd2z1LMluqU0QVNK0eSQQJ2sTt8ZyMBllVj1jm5Uios4gLhDLfVoWhbTAjde
 +DrIZIA6PvTA912pSPmYeZxl8pBJ8hoyL6GaQh3NelGBIw9KwJAAb8w
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

TLMM18 only enables M.2-1 on pcie6a. The second slot (pcie3) is gated
by PMC8380_3 GPIO5; both regulators previously pointed at the same
TLMM pin, so the DT had no effect on that rail.

Switch vreg_nvme2_3p3 to the PMIC GPIO, add its pinctrl state, and
keep a 2 s startup delay plus always-on. Without the delay the pcie3
slot fails to probe; always-on is a stand-in until an M.2 power
sequencer exists. Both slots work on Purwa with NVMe SSDs.

Tested-on: IdeaCentre Mini 01Q8X10, Purwa (X1-26-100)

Assisted-by: Grok 4.5 (xAI)
Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 .../dts/qcom/x1-lenovo-ideacentre-mini-01q8x10.dtsi | 21 +++++++++++++++++++--
 1 file changed, 19 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/x1-lenovo-ideacentre-mini-01q8x10.dtsi b/arch/arm64/boot/dts/qcom/x1-lenovo-ideacentre-mini-01q8x10.dtsi
index 1af97c5f86fd3..76a9f745b279d 100644
--- a/arch/arm64/boot/dts/qcom/x1-lenovo-ideacentre-mini-01q8x10.dtsi
+++ b/arch/arm64/boot/dts/qcom/x1-lenovo-ideacentre-mini-01q8x10.dtsi
@@ -4,6 +4,7 @@
  */
 
 #include <dt-bindings/gpio/gpio.h>
+#include <dt-bindings/pinctrl/qcom,pmic-gpio.h>
 #include <dt-bindings/regulator/qcom,rpmh-regulator.h>
 
 #include "hamoa-pmics.dtsi"
@@ -173,13 +174,16 @@ vreg_nvme2_3p3: regulator-nvme2-3p3 {
 		regulator-min-microvolt = <3300000>;
 		regulator-max-microvolt = <3300000>;
 
-		gpio = <&tlmm 18 GPIO_ACTIVE_HIGH>;
+		gpio = <&pmc8380_3_gpios 5 GPIO_ACTIVE_HIGH>;
 		enable-active-high;
 
-		pinctrl-0 = <&nvme_reg_en>;
+		pinctrl-0 = <&nvme2_reg_en>;
 		pinctrl-names = "default";
 
+		startup-delay-us = <2000000>;
+
 		regulator-boot-on;
+		regulator-always-on;
 	};
 
 	vreg_v0p9: regulator-v0p9 {
@@ -788,6 +792,19 @@ &pcie6a_port0 {
 	wake-gpios = <&tlmm 154 GPIO_ACTIVE_LOW>;
 };
 
+&pmc8380_3_gpios {
+	nvme2_reg_en: nvme2-reg-en-state {
+		pins = "gpio5";
+		function = "normal";
+		power-source = <0>;
+		input-disable;
+		output-enable;
+		drive-push-pull;
+		bias-disable;
+		qcom,drive-strength = <PMIC_GPIO_STRENGTH_LOW>;
+	};
+};
+
 &pmc8380_5_gpios {
 	usb0_pwr_1p15_reg_en: usb0-pwr-1p15-reg-en-state {
 		pins = "gpio8";

-- 
2.53.0

