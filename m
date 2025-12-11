From: Rudraksha Gupta <guptarud@gmail.com>
Date: Thu, 11 Dec 2025 02:23:09 -0800
Subject: [PATCH] ARM: dts: qcom: msm8960: expressatt Add PWM vibrator
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251211-expressatt-vibrator-v1-1-41bdc47217b2@gmail.com>
X-B4-Tracking: v=1; b=H4sIAIybOmkC/03MwQ6CMAyA4VchPTvD5haEGON7GA5jFGgUptsgG
 MK7O+Fievqb9lvAoyP0UCQLOJzIkx1i8EMCptNDi4zq2CBSobjgnOH8cui9DoFNVDkdrGM1KpV
 pfW6yWkL8jBcNzZt6L/d2+B4jHvYl9D9iw4vkstup+reDHU33wA+bOIsjpaxykZm8Od3aXtPza
 Gx/hXJdv7sq1nPCAAAA
X-Change-ID: 20251211-expressatt-vibrator-de557aa8f7d4
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1765448590; l=3861;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=ISLw8u+aVcL38Og1i02YfdmWTkxiTbCmji9uWmWdQeM=;
 b=1QAwfks1/c7/sv6EAAOantjAr/R5zmQv5mVuyOkbZeiOta7c4NjZmqEjILi5sYph1miZeX7AF
 JTWU0Tj3cFKDsHiz+Ue2OA2pShytIdyQHb5QxSQxqCFmcIXR9LtFILZ
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a pwm-vibrator to expressatt. Currently this vibrates only at 100%

Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
Add a pwm-vibrator to expressatt. Currently this vibrates only at 100%

Link:
- https://github.com/LineageOS/android_kernel_samsung_d2/blob/stable/cm-12.0-YNG4N/arch/arm/mach-msm/board-express.c#L1767
- https://github.com/LineageOS/android_kernel_samsung_d2/blob/stable/cm-12.0-YNG4N/drivers/motor/Makefile#L5

Test:
=====================
samsung-expressatt:~$ dmesg | grep vibra
[   79.892226] input: pwm-vibrator as /devices/platform/vibrator/input/input4
samsung-expressatt:~$ fftest /dev/input/event4 
Force feedback test program.
HOLD FIRMLY YOUR WHEEL OR JOYSTICK TO PREVENT DAMAGES

Device /dev/input/event4 opened
Features:
  * Absolute axes: 
    [00 00 00 00 00 00 00 00 ]
  * Relative axes: 
    [00 00 ]
  * Force feedback effects types: Periodic, Rumble, Gain, 
    Force feedback periodic effects: Square, Triangle, Sine, 
    [00 00 00 00 00 00 00 00 00 00 03 07 01 00 00 00 ]
  * Number of simultaneous effects: 16

Setting master gain to 75% ... OK
Uploading effect #0 (Periodic sinusoidal) ... OK (id 0)
Uploading effect #1 (Constant) ... Error: Invalid argument
Uploading effect #2 (Spring) ... Error: Invalid argument
Uploading effect #3 (Damper) ... Error: Invalid argument
Uploading effect #4 (Strong rumble, with heavy motor) ... OK (id 1)
Uploading effect #5 (Weak rumble, with light motor) ... OK (id 2)
Enter effect number, -1 to exit
0
Now Playing: Sine vibration
Enter effect number, -1 to exit
[  157.967092] pwm-vibrator vibrator: failed to apply pwm state: -16
[  158.017952] pwm-vibrator vibrator: failed to apply pwm state: -16

Note: This patch was assisted with Claude and cleaned up by me.
---
 .../dts/qcom/qcom-msm8960-samsung-expressatt.dts   | 44 ++++++++++++++++++++++
 1 file changed, 44 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts b/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
index c4b98af6955d..09443df0fdce 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
+++ b/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
@@ -87,6 +87,35 @@ touchkey@20 {
 			linux,keycodes = <KEY_MENU KEY_BACK>;
 		};
 	};
+
+	gp1_pwm: pwm {
+		compatible = "clk-pwm";
+		#pwm-cells = <2>;
+		clocks = <&gcc GP1_CLK>;
+	};
+
+	/* TODO: Vary the frequency besides being 0% or 100% */
+	vibrator {
+		compatible = "pwm-vibrator";
+		pwms = <&gp1_pwm 0 54347 0>;  /* ~18.4 kHz */
+		pwm-names = "enable";
+		enable-gpios = <&pm8921_gpio 4 GPIO_ACTIVE_HIGH>;
+		vcc-supply = <&vdd_haptics>;
+
+		pinctrl-names = "default";
+		pinctrl-0 = <&vib_pwm_gpio>;
+	};
+
+	vdd_haptics: vdd-haptics-regulator {
+		compatible = "regulator-fixed";
+		regulator-name = "vdd_haptics";
+		gpio = <&tlmm 47 GPIO_ACTIVE_HIGH>;
+		enable-active-high;
+		regulator-boot-on;
+
+		pinctrl-names = "default";
+		pinctrl-0 = <&haptics_pwr_en>;
+	};
 };
 
 &gsbi2 {
@@ -241,6 +270,21 @@ touchkey_i2c_pins: touchkey-i2c-state {
 		bias-disable;
 	};
 
+	haptics_pwr_en: haptics-pwr-en-state {
+		pins = "gpio47";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+		output-low;
+	};
+
+	vib_pwm_gpio: vib-pwm-gpio-state {
+		pins = "gpio70";
+		function = "gp_clk_1b";
+		drive-strength = <2>;
+		bias-disable;
+	};
+
 	touchkey_irq_pin: touchkey-irq-state {
 		pins = "gpio52";
 		function = "gpio";

---
base-commit: b066d7751f99fabaa07939006233781536ab16e5
change-id: 20251211-expressatt-vibrator-de557aa8f7d4
prerequisite-message-id: <20251205-expressatt-touchkey-v1-1-1444b927c9f3@gmail.com>
prerequisite-patch-id: 8de4de7909722ccaf385c4224f25a623eaa72c28

Best regards,
-- 
Rudraksha Gupta <guptarud@gmail.com>

