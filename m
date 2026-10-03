From: =?utf-8?q?S=C3=A9rgio_Ferreira?= <ferreira@se-rg.io>
Date: Sat, 03 Oct 2026 14:00:56 +0200
Subject: [PATCH] arm64: dts: qcom: x1e80100-medion-sprchrgd-14-s1: Add PWM
 backlight
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261003-medion-sprchrgd-14-backlight-v1-1-e47da56acfa2@se-rg.io>
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/x3MUQrCMAwA0KuEfC/Q1iKjVxE/uia2Qe1GOkQYu
 7vgO8A7cIipDExwoMlHh64dE/gJsLTcq5AyJsDgwtU7d6G3sK6dxmalWWXykZZcni+tbac4+5y
 XECPPjBPgZvLQ77+/3c/zBydriOZuAAAA
X-Change-ID: 20261003-medion-sprchrgd-14-backlight-481aab244d8d
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Georg Gottleuber <ggo@tuxedocomputers.com>, 
 Ettore Chimenti <ek5.chimenti@gmail.com>, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>, 
 Srinivas Kandagatla <srini@kernel.org>, 
 =?utf-8?q?S=C3=A9rgio_Ferreira?= <ferreira@se-rg.io>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791028866; l=2946;
 i=ferreira@se-rg.io; s=20261003; h=from:subject:message-id;
 bh=/JSVI7YyXas5fHFXo/Esfhx2hK6PyOATrgU8Kx4S8VY=;
 b=OKJTmcBXhB8Jw67ys8qE6awZKvnBxcXFNMdVsA9jwESVQQdOG0Zcjo515aKH3rN3Vd1ceaMSb
 1oE9X9USwd/D/Y/7sbpQoO7u0PHNCL3gXfKllbNMez5PqLK6z1u+59A
X-Developer-Key: i=ferreira@se-rg.io; a=ed25519;
 pk=Jsl0SyJyW91ZKPhUIURdD/k1q+0LKkiRvua+L5lAI4M=
X-Endpoint-Received: by B4 Relay for ferreira@se-rg.io/20261003 with auth_id=1104
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The eDP panel (CSOT MNE007ZA3-2, IPS LCD) cannot have its brightness
set over eDP AUX. With no backlight phandle on the panel, panel-edp
falls back to the DP AUX backlight, which registers dp_aux_backlight
with a maximum brightness of 0, so brightness control has no effect.

Brightness is driven by PWM instead. UEFI leaves PM8550 LPG channel 3
running and the PWM output configured on PM8550 GPIO 8:

	gpio8 : out low func1 vin-0 no pull push-pull medium

while PMC8380_3 GPIO 4 is driven high as the backlight enable. The
panel configuration in the Windows ACPI tables agrees (PMIC-controlled
PWM, PMIC 1, bank 3, 9-bit, 2 kHz).

Describe this with a pwm-backlight node: enable pm8550_pwm, add the
pinctrl state for gpio8 func1 and attach the backlight to the panel.

Tested on a Medion SPRCHRGD 14 S1 (X1E78100): brightness control over
the full range, brightness keys, suspend/resume and restore after
reboot.

Assisted-by: LLM
Signed-off-by: Sérgio Ferreira <ferreira@se-rg.io>
---
The PWM output pin was identified from the firmware-configured PMIC
state (both PM8550 GPIO 7 and 8 run func1; GPIO 8 matches a
non-inverted, full-duty backlight PWM) and verified by booting with
this pinctrl state. It was not taken from schematics, so a
confirmation from someone with board documentation would be welcome.
---
 .../boot/dts/qcom/x1e80100-medion-sprchrgd-14-s1.dts  | 19 +++++++++++++++++++
 1 file changed, 19 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/x1e80100-medion-sprchrgd-14-s1.dts b/arch/arm64/boot/dts/qcom/x1e80100-medion-sprchrgd-14-s1.dts
index 9b599917c..962531ad3 100644
--- a/arch/arm64/boot/dts/qcom/x1e80100-medion-sprchrgd-14-s1.dts
+++ b/arch/arm64/boot/dts/qcom/x1e80100-medion-sprchrgd-14-s1.dts
@@ -52,6 +52,15 @@ wcd938x: audio-codec {
 		#sound-dai-cells = <1>;
 	};
 
+	backlight: backlight {
+		compatible = "pwm-backlight";
+		pwms = <&pm8550_pwm 3 500000>;
+		enable-gpios = <&pmc8380_3_gpios 4 GPIO_ACTIVE_HIGH>;
+
+		pinctrl-0 = <&edp_bl_pwm>;
+		pinctrl-names = "default";
+	};
+
 	chosen {
 		stdout-path = "serial0:115200n8";
 	};
@@ -997,6 +1006,7 @@ &mdss_dp3 {
 	aux-bus {
 		panel {
 			compatible = "edp-panel";
+			backlight = <&backlight>;
 			power-supply = <&vreg_edp_3p3>;
 
 			port {
@@ -1084,6 +1094,11 @@ &pcie6a_port0 {
 };
 
 &pm8550_gpios {
+	edp_bl_pwm: edp-bl-pwm-state {
+		pins = "gpio8";
+		function = "func1";
+	};
+
 	rtmr0_default: rtmr0-reset-n-active-state {
 		pins = "gpio10";
 		function = "normal";
@@ -1103,6 +1118,10 @@ usb0_3p3_reg_en: usb0-3p3-reg-en-state {
 	};
 };
 
+&pm8550_pwm {
+	status = "okay";
+};
+
 &pm8550ve_9_gpios {
 	usb0_1p8_reg_en: usb0-1p8-reg-en-state {
 		pins = "gpio8";

---
base-commit: f0406245cb9855e6318335a8a223551354291a46
change-id: 20261003-medion-sprchrgd-14-backlight-481aab244d8d

Best regards,
-- 
Sérgio Ferreira <ferreira@se-rg.io>

