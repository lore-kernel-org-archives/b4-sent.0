From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Tue, 10 Jun 2025 06:57:27 +0200
Subject: [PATCH] t: arm64: qcom: sc8280xp-x13s: amend usb0-sbu-mux enable
 gpio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250610-x13s-usb0-mux-v1-1-683213580ff1@oldschoolsolutions.biz>
X-B4-Tracking: v=1; b=H4sIADe7R2gC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDM0MD3QpD42Ld0uIkA93c0gpdC6NEy1QDI0tLi2QLJaCegqLUtMwKsHn
 RsbW1AOYMTIFfAAAA
X-Change-ID: 20250610-x13s-usb0-mux-82a9e02998c8
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Johan Hovold <johan+linaro@kernel.org>, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749531449; l=2326;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=RNPTb2CXyFgoc1osarAq8drSEBAlFXeDnXM/Y1PKLRk=;
 b=gknX1VlOlFvkMWg89JLOgVMiR9vFSMfZibp4Iavjh2JljKRABcLJz2V3xuhFSwuOBWq9CBxqy
 TETqA7ieXb0ClC+emCFuLrT7eRV+TVbftN+bulmalAJzAm9pOj2u5iK
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The usb0 port didn't switch to dp altmode, investigation into DSDT
UCS0 device resulted in GPIO 165.

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
This patch amends the enable gpio for the usb0-sbu-mux to the one
found in the DSDT file for this laptop. UCS0 shows a list of GPIOs in 
a certain order, and it has 2 buffers with slightly different length. 
At the place where one would expect the GPIO for the select pin of USB0 
(by pattern application from USB1) is a deviating value (165 instead of 
101). This value is the same in both buffers. The GPIO previously used
is also there, but at the end of the UCS0 buffer structure. Changing it
resulted in a working dp altmode functionality on usb0.

Since the X13s dt looks derived from the SC8280XP CRD, it is likely that
the change also needs to be done there. 

This debug effort is a result of work / testing of the 4-lanes patch
[1] on all available devices. Independent of it, it enables dp 
altmode on usb0, and with it, also 4 lanes, making it even more useful.

[1]: https://lore.kernel.org/all/20250527-topic-4ln_dp_respin-v3-0-f9a0763ec289@oss.qualcomm.com/
---
 arch/arm64/boot/dts/qcom/sc8280xp-lenovo-thinkpad-x13s.dts | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sc8280xp-lenovo-thinkpad-x13s.dts b/arch/arm64/boot/dts/qcom/sc8280xp-lenovo-thinkpad-x13s.dts
index ae7a275fd2236a2c71808b003fbcb66687e6e45e..abb742337359e88b7db62a3ea2d7cf3f8ab71c53 100644
--- a/arch/arm64/boot/dts/qcom/sc8280xp-lenovo-thinkpad-x13s.dts
+++ b/arch/arm64/boot/dts/qcom/sc8280xp-lenovo-thinkpad-x13s.dts
@@ -366,7 +366,7 @@ map1 {
 	usb0-sbu-mux {
 		compatible = "pericom,pi3usb102", "gpio-sbu-mux";
 
-		enable-gpios = <&tlmm 101 GPIO_ACTIVE_LOW>;
+		enable-gpios = <&tlmm 165 GPIO_ACTIVE_LOW>;
 		select-gpios = <&tlmm 164 GPIO_ACTIVE_HIGH>;
 
 		pinctrl-names = "default";
@@ -1781,7 +1781,7 @@ tx-pins {
 
 	usb0_sbu_default: usb0-sbu-state {
 		oe-n-pins {
-			pins = "gpio101";
+			pins = "gpio165";
 			function = "gpio";
 			bias-disable;
 			drive-strength = <16>;

---
base-commit: 475c850a7fdd0915b856173186d5922899d65686
change-id: 20250610-x13s-usb0-mux-82a9e02998c8

Best regards,
-- 
Jens Glathe <jens.glathe@oldschoolsolutions.biz>

