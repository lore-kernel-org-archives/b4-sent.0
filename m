From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Mon, 09 Jun 2025 22:53:56 +0200
Subject: [PATCH] dt: arm64: qcom: sc8280xp-blackrock: amend usb0-sbu-mux
 enable gpio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250609-blackrock-usb0-mux-v1-1-7903c3b071e4@oldschoolsolutions.biz>
X-B4-Tracking: v=1; b=H4sIAONJR2gC/x3MSQqAMAxA0atI1gZicUCvIi5sjBocaakI4t0tL
 t/i/we8OBUPTfKAk0u9HntElibAc79PgjpEgyFTUEk12rXnxR28YPCWcAs3mqEiZku1zXKI4el
 k1Puftt37fj0IVTVkAAAA
X-Change-ID: 20250609-blackrock-usb0-mux-2d70ccb09b14
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Aleksandrs Vinarskis <alex.vinarskis@gmail.com>, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749502444; l=2173;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=0U1VNm6UEDUZ5+luOdhF4fqviPgQfWkNGEy/dPW1eC4=;
 b=e9Byf0rEru5w6V5DwJCO6BifuGo/PjwSHJviqRtqjj9xTZOSR/IGL6aRyqrFXKqTdZgHCDBps
 6T/ZEP8N0TyBVghdGNSqevtKq0CuNJykE7Y9SecA+ZBTchfkzNvFIQd
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The usb0 port didn't switch to dp altmode, investigation into DSDT
UCS0 device resulted into GPIO 100.

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
This patch amends the enable gpio for the usb0-sbu-mux to the one
found in the DSDT file for this box. It shows a list of GPIOs in 
a certain order, and it has 2 buffers with conflicting values. 
The one deviating is in the second buffer, at the place where one 
would expect the GPIO for the select pin of USB0 (by pattern 
application from USB1). The GPIO previously used is also there, but 
at the end of the UCS0 buffer structure). Changing it resulted in 
a working dp altmode functionality on usb0.

This debug effort is a result of work / testing of the 4-lanes patch
[1] on all available devices. Independent of it, it enables dp 
altmode on usb0, and with it, also 4 lanes, making it even more useful.

[1]: https://lore.kernel.org/all/20250527-topic-4ln_dp_respin-v3-0-f9a0763ec289@oss.qualcomm.com/
---
 arch/arm64/boot/dts/qcom/sc8280xp-microsoft-blackrock.dts | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-blackrock.dts b/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-blackrock.dts
index 812251324002b50f3b48845b6c244f692d42b9b2..b8cbef0ebce76acf9d1e841e613646119dc400ff 100644
--- a/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-blackrock.dts
+++ b/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-blackrock.dts
@@ -243,7 +243,7 @@ linux,cma {
 	usb0-sbu-mux {
 		compatible = "pericom,pi3usb102", "gpio-sbu-mux";
 
-		enable-gpios = <&tlmm 101 GPIO_ACTIVE_LOW>;
+		enable-gpios = <&tlmm 100 GPIO_ACTIVE_LOW>;
 		select-gpios = <&tlmm 164 GPIO_ACTIVE_HIGH>;
 
 		pinctrl-0 = <&usb0_sbu_default>;
@@ -1267,7 +1267,7 @@ tx-pins {
 
 	usb0_sbu_default: usb0-sbu-state {
 		oe-n-pins {
-			pins = "gpio101";
+			pins = "gpio100";
 			function = "gpio";
 			bias-disable;
 			drive-strength = <16>;

---
base-commit: 475c850a7fdd0915b856173186d5922899d65686
change-id: 20250609-blackrock-usb0-mux-2d70ccb09b14

Best regards,
-- 
Jens Glathe <jens.glathe@oldschoolsolutions.biz>

