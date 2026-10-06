From: Igor Velkov <iav@iav.lv>
Date: Tue, 06 Oct 2026 19:36:17 +0300
Subject: [PATCH v2] arm64: dts: amlogic: meson-sm1-odroid-hc4: add the fan
 tachometer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261006-hc4-fan-tach-v2-1-e27ad96e92a2@iav.lv>
X-B4-Tracking: v=1; b=H4sIAIAjxWoC/3XMQQrCMBCF4auUWTuShLEVV95DukjixAxIKkkJS
 sndjd27/B+8b4PCWbjAZdggc5UiS+phDgP4aNODUe69wSgzaqVGjJ4w2ISr9RGJlNfuPJFVBP3
 yyhzkvXO3uXeUsi75s+tV/9Y/UNWokXjy7INydHJXsfX4rDC31r7ydyCepQAAAA==
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Christian Hewitt <christianshewitt@gmail.com>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1903; i=iav@iav.lv;
 h=from:subject:message-id; bh=oCCjURBullL5W0mILbeZieiLJNm1TbubemMG4u+TG88=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFlHlRstbGxiiph3/Kw9cOHIVRn/f54PGueqNV7/VGX0o
 ujmBvHjHaUsDGJcDLJiiiwTDmncylhy9a+/h/kDmDmsTCBDGLg4BWAiGvGMDHt0Tl09MkWVr2l9
 VML6MxfLNk7eVLPNWqb0y6d36hor/EoYGWapOG2dFPZ41g6Tq7tfbTsaNbsgXWrrqVl/Dot84/r
 Nkc4CAA==
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The fan connector routes the fan's tachometer output to GPIOX_7, but
the fan node does not describe it. pwm-fan therefore registers no
fan1_input, and the fan speed cannot be read.

Describe the line as the fan's interrupt, and mux the pin as a GPIO
input without bias: R109 on the board pulls the line up to VDDAO_3V3
(schematic rev1.0, sheet 31).

Tested on ODROID-HC4: fan1_input reads 0 with the fan stopped and
rises with the duty cycle, to about 4200 rpm at full speed.

Assisted-by: LLM
Signed-off-by: Igor Velkov <iav@iav.lv>
---
Changes in v2:
- Mux GPIOX_7 as a GPIO input without bias (Neil).
- Link to v1: https://lore.kernel.org/r/20261006-hc4-fan-tach-v1-1-4e7cecf0b45b@iav.lv
---
 arch/arm64/boot/dts/amlogic/meson-sm1-odroid-hc4.dts | 15 +++++++++++++++
 1 file changed, 15 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/meson-sm1-odroid-hc4.dts b/arch/arm64/boot/dts/amlogic/meson-sm1-odroid-hc4.dts
index 5f15c2299509..64602aff1d81 100644
--- a/arch/arm64/boot/dts/amlogic/meson-sm1-odroid-hc4.dts
+++ b/arch/arm64/boot/dts/amlogic/meson-sm1-odroid-hc4.dts
@@ -21,6 +21,10 @@ fan0: pwm-fan {
 		#cooling-cells = <2>;
 		cooling-levels = <0 120 170 220>;
 		pwms = <&pwm_cd 1 40000 0>;
+		interrupt-parent = <&gpio_intc>;
+		interrupts = <IRQID_GPIOX_7 IRQ_TYPE_EDGE_FALLING>;
+		pinctrl-0 = <&fan_tach_pins>;
+		pinctrl-names = "default";
 	};
 
 	leds {
@@ -114,6 +118,17 @@ &pcie {
 	reset-gpios = <&gpio GPIOH_4 GPIO_ACTIVE_LOW>;
 };
 
+&periphs_pinctrl {
+	fan_tach_pins: fan-tach {
+		mux {
+			groups = "GPIOX_7";
+			function = "gpio_periphs";
+			bias-disable;
+			output-disable;
+		};
+	};
+};
+
 &pwm_cd {
 	status = "okay";
 	pinctrl-names = "default";

---
base-commit: b44e2be772f866985cafdf90355285069ea68495
change-id: 20261006-hc4-fan-tach-440c1b874a04

Best regards,
-- 
Igor Velkov <iav@iav.lv>

