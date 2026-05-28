From: Rudraksha Gupta <guptarud@gmail.com>
Date: Wed, 27 May 2026 19:13:41 -0700
Subject: [PATCH v2] ARM: dts: qcom: msm8960: expressatt: Add
 coreriver,tc360-touchkey
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260527-expressatt-touchkey-v2-1-049dca41fc3a@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32OQQ6DIBBFr2JmXQwgxuiq92hcIB110lpaQKIx3
 r1U982s3uTNn7+BR0foock2cBjJk30lkJcMzKhfAzK6JwbJZSkkLxkub4fe6xBYsLMZH7gyUan
 KlLzQsi8gXSajp+VIvbUnO/zMKTycS+i0R2bsNFFosljlHH7eSD5Ytx5lojjEv3+jYGmUUl0tK
 1P3xXWYND3zFAztvu9fZL55KN4AAAA=
X-Change-ID: 20251205-expressatt-touchkey-1747c503a2f3
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Rudraksha Gupta <guptarud@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779934422; l=5127;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=QKeXmWv32UYGOnYCe6uOdzYUC+QSTTFeTGr6mUqA+oU=;
 b=KtaXdbdrs6N2DxKOXa8+rKWRxO8BoT+09CU2hHO8sm5itm2N3tRFNhPx45NgTaHcP4MirEGtT
 kwu4Iw9uH07ACUrK9BCpSDo6UHQTRp5yFjxY7vBcd7ptj/10wq2T8W8
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the tc360 touchkey. It's unknown if this is the actual model of the
touchkey, as downstream doesn't mention a variant, but this works.

Link:
https://github.com/LineageOS/android_kernel_samsung_d2/blob/stable/cm-12.0-YNG4N/drivers/input/keyboard/cypress_touchkey_236/Makefile#L5

Assisted-by: Claude:claude-opus-4.6
Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
Add the tc360 touchkey. It's unknown if this is the actual model of the
touchkey, as downstream doesn't mention a variant, but this works.

Link:
https://github.com/LineageOS/android_kernel_samsung_d2/blob/stable/cm-12.0-YNG4N/drivers/input/keyboard/cypress_touchkey_236/Makefile#L5

Test:
=============
- LEDs:
samsung-expressatt:/sys/class/leds/tm2-touchkey$ echo heartbeat > trigger
// Flashes LEDs :)

- Touching buttons:
samsung-expressatt:/sys/class/leds/tm2-touchkey$ evtest
No device specified, trying to scan all of /dev/input/event*
Not running as root, no devices may be available.
Available devices:
/dev/input/event0:      pmic8xxx_pwrkey
/dev/input/event1:      gpio-keys
/dev/input/event2:      tm2-touchkey
/dev/input/event3:      Atmel maXTouch Touchscreen
Select the device event number [0-3]: 2
Input driver version is 1.0.1
Input device ID: bus 0x18 vendor 0x0 product 0x0 version 0x0
Input device name: "tm2-touchkey"
Supported events:
  Event type 0 (EV_SYN)
  Event type 1 (EV_KEY)
    Event code 139 (KEY_MENU)
    Event code 158 (KEY_BACK)
  Event type 4 (EV_MSC)
    Event code 4 (MSC_SCAN)
Properties:
Testing ... (interrupt to exit)
Event: time 1761059686.899755, type 4 (EV_MSC), code 4 (MSC_SCAN), value 00
Event: time 1761059686.899755, type 1 (EV_KEY), code 139 (KEY_MENU), value 1
Event: time 1761059686.899755, -------------- SYN_REPORT ------------
Event: time 1761059687.113489, type 4 (EV_MSC), code 4 (MSC_SCAN), value 00
Event: time 1761059687.113489, type 1 (EV_KEY), code 139 (KEY_MENU), value 0
Event: time 1761059687.113489, -------------- SYN_REPORT ------------
Event: time 1761059688.764757, type 4 (EV_MSC), code 4 (MSC_SCAN), value 01
Event: time 1761059688.764757, type 1 (EV_KEY), code 158 (KEY_BACK), value 1
Event: time 1761059688.764757, -------------- SYN_REPORT ------------
Event: time 1761059688.817516, type 4 (EV_MSC), code 4 (MSC_SCAN), value 01
Event: time 1761059688.817516, type 1 (EV_KEY), code 158 (KEY_BACK), value 0
Event: time 1761059688.817516, -------------- SYN_REPORT ------------
---
Changes in v2:
- drop status = okay
- reorder pinctrl-{n,names}
- Resend of v1: https://lore.kernel.org/all/20260503-expressatt-touchkey-v1-1-f7dd5db64e0d@gmail.com/
- Link to v1: https://lore.kernel.org/r/20251205-expressatt-touchkey-v1-1-1444b927c9f3@gmail.com
---
 .../dts/qcom/qcom-msm8960-samsung-expressatt.dts   | 54 ++++++++++++++++++++++
 1 file changed, 54 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts b/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
index 5a39abd6f3ce..5a3d88e31cf5 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
+++ b/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
@@ -52,6 +52,40 @@ key-volume-down {
 			linux,code = <KEY_VOLUMEDOWN>;
 		};
 	};
+
+	touchkey_enable: touchkey-enable {
+		compatible = "regulator-fixed";
+		regulator-name = "touchkey_enable";
+		gpio = <&tlmm 51 GPIO_ACTIVE_HIGH>;
+		enable-active-high;
+		regulator-boot-on;
+	};
+
+	i2c-gpio-touchkey {
+		compatible = "i2c-gpio";
+		#address-cells = <1>;
+		#size-cells = <0>;
+		sda-gpios = <&tlmm 71 (GPIO_ACTIVE_HIGH | GPIO_OPEN_DRAIN)>;
+		scl-gpios = <&tlmm 72 (GPIO_ACTIVE_HIGH | GPIO_OPEN_DRAIN)>;
+		pinctrl-0 = <&touchkey_i2c_pins>;
+		pinctrl-names = "default";
+		i2c-gpio,delay-us = <2>;
+
+		touchkey@20 {
+			compatible = "coreriver,tc360-touchkey";
+			reg = <0x20>;
+
+			interrupts-extended = <&tlmm 52 IRQ_TYPE_EDGE_FALLING>;
+			pinctrl-0 = <&touchkey_irq_pin>;
+			pinctrl-names = "default";
+
+			vddio-supply = <&touchkey_enable>;
+			vdd-supply = <&pm8921_l29>;
+			vcc-supply = <&pm8921_l29>;
+
+			linux,keycodes = <KEY_MENU KEY_BACK>;
+		};
+	};
 };
 
 &gsbi2 {
@@ -198,6 +232,20 @@ firmware-pins {
 			bias-disable;
 		};
 	};
+
+	touchkey_i2c_pins: touchkey-i2c-state {
+		pins = "gpio71", "gpio72";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+	};
+
+	touchkey_irq_pin: touchkey-irq-state {
+		pins = "gpio52";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+	};
 };
 
 &pm8921 {
@@ -420,6 +468,12 @@ pm8921_l25: l25 {
 			bias-pull-down;
 		};
 
+		pm8921_l29: l29 {
+			regulator-min-microvolt = <1800000>;
+			regulator-max-microvolt = <3300000>;
+			bias-pull-down;
+		};
+
 		/* Low Voltage Switch */
 		pm8921_lvs1: lvs1 {
 			bias-pull-down;

---
base-commit: 3131ff5a117498bb4b9db3a238bb311cbf8383ce
change-id: 20251205-expressatt-touchkey-1747c503a2f3

Best regards,
-- 
Rudraksha Gupta <guptarud@gmail.com>

