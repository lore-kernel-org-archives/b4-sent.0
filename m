From: Rudraksha Gupta <guptarud@gmail.com>
Date: Tue, 31 Mar 2026 11:00:04 -0700
Subject: [PATCH] ARM: dts: qcom: msm8960: expressatt: Add MAX17048 fuel
 gauge
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260331-expressatt_fuel_guage-v1-1-23d1d8526b69@gmail.com>
X-B4-Tracking: v=1; b=H4sIAKMLzGkC/22NQQqDMBREryJZN2JM1Cql9B5F5Ks/GjDaJlEE8
 e6Nuu3yDTNvNmLRKLSkCDZicFFWTaMHdgtI08PYIVWtZxJHcRpxziiuH4PWgnOVnHGouhl8SaR
 JK2su7xnUxG99R6r19L7Liw1+Z693V0j0ITn1RfD4Z29Ao4FKDmB7uggaUckwz6XIRML4q9Ogh
 rCZ9PP4q8Ei9aCVK4IlDVlOyn3/AS2HDwLeAAAA
X-Change-ID: 20260331-expressatt_fuel_guage-465dfb3f87ab
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774980004; l=4175;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=iH66uI8R5ZUxHjxlzdM/gKMh3t/2Y/PmeUvx5ls7J1w=;
 b=aW9/7UbiUkxapuj8jBpP+RO8fzXEJxOEKMpiLavoWLdMVuvb2GtG2BboCiu5in4gAeWp8OapI
 r/peXiVm+n5Djj1MI3IMhYIziva1pgXec1X46AMc4IXRo7oNY7ZFKPL
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add MAX17048 fuel gauge support.

Tested by comparing battery capacity readings between upstream (mainline
max17040 driver) and downstream (Samsung max17048_fuelgauge driver)
across a full discharge cycle. Upstream reads ~3% lower throughout. Both
track the discharge curve correctly:

  Upstream:   95 92 88 87 86 87 83 82 80 68 60 55 50 45 40 35 30 20 16 10 10 5 5 1
  Downstream: 95 94 92 91 91 89 87 86 84 73 64 59 51 48 43 38 33 23 17 14 12 8 6 3

Each pair of readings was collected by checking the upstream capacity
first, then moving the battery to a second expressatt running downstream
Android to check its capacity. The battery was then moved back to the
upstream device for the next reading. This swap occasionally caused the
upstream capacity to read slightly higher than the previous value
(e.g. 86 -> 87). When this happened, the reading was retaken after the
value settled.

Link: https://github.com/LineageOS/android_kernel_samsung_d2/blob/stable/cm-11.0-XNG3C/arch/arm/mach-msm/board-apexq-battery.c
Link: https://github.com/LineageOS/android_kernel_samsung_d2/blob/stable/cm-11.0-XNG3C/drivers/battery/Makefile#L5
Link: https://github.com/LineageOS/android_kernel_samsung_d2/blob/stable/cm-11.0-XNG3C/arch/arm/mach-msm/Makefile#L308

Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
Tested by doing `cat /sys/class/power_supply/battery/capacity` in
upstream Linux and comparing the value with downstream Linux. Booted
on upstream Linux first, as the upstream Linux seems to use a lot
more battery than downstream, and then put the battery into another
Expressatt running downstream Android to compare values. There are
some slight differences, but overall seems to line up pretty well with
downstream.
---
 .../dts/qcom/qcom-msm8960-samsung-expressatt.dts   | 40 ++++++++++++++++++++++
 1 file changed, 40 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts b/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
index 82f8a4e10c6f..638124fb3922 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
+++ b/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
@@ -143,6 +143,32 @@ vdd_haptics: vdd-haptics-regulator {
 		pinctrl-names = "default";
 		pinctrl-0 = <&haptics_pwr_en>;
 	};
+
+	/* Fuel gauge (MAX17048) on i2c-gpio 24/25. Alert on GPIO 67. */
+	i2c-fuelgauge {
+		compatible = "i2c-gpio";
+		#address-cells = <1>;
+		#size-cells = <0>;
+		sda-gpios = <&tlmm 24 (GPIO_ACTIVE_HIGH | GPIO_OPEN_DRAIN)>;
+		scl-gpios = <&tlmm 25 (GPIO_ACTIVE_HIGH | GPIO_OPEN_DRAIN)>;
+		pinctrl-0 = <&fuelgauge_i2c_pins>;
+		pinctrl-names = "default";
+		status = "okay";
+		i2c-gpio,delay-us = <2>;
+
+		fuel-gauge@36 {
+			compatible = "maxim,max17048";
+			reg = <0x36>;
+			maxim,double-soc;
+			maxim,rcomp = /bits/ 8 <0x62>;
+			maxim,alert-low-soc-level = <2>;
+			interrupt-parent = <&tlmm>;
+			interrupts = <67 IRQ_TYPE_EDGE_FALLING>;
+			pinctrl-0 = <&fuelgauge_alert_pin>;
+			pinctrl-names = "default";
+			wakeup-source;
+		};
+	};
 };
 
 &gsbi2 {
@@ -281,6 +307,13 @@ touchscreen: touchscreen-int-state {
 		drive-strength = <2>;
 	};
 
+	fuelgauge_i2c_pins: fuelgauge-i2c-state {
+		pins = "gpio24", "gpio25";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+	};
+
 	nfc_default: nfc-default-state {
 		irq-pins {
 			pins = "gpio106";
@@ -325,6 +358,13 @@ touchkey_irq_pin: touchkey-irq-state {
 		drive-strength = <2>;
 		bias-disable;
 	};
+
+	fuelgauge_alert_pin: fuelgauge-alert-state {
+		pins = "gpio67";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+	};
 };
 
 &pm8921 {

---
base-commit: e9ec05addd1a067fc7cb218f20ecdc1b1b0898c0
change-id: 20260331-expressatt_fuel_guage-465dfb3f87ab
prerequisite-message-id: <20260331-expressatt_camera_flash-v4-0-f1e99f474513@gmail.com>
prerequisite-patch-id: ab8b8d87fd2d518c4c5b5dace3f22238d1abbe49
prerequisite-patch-id: 47e32e653e520a27770bb05d99135694b0128ba0
prerequisite-patch-id: 7ef7df61e7ef6476a35811d765f522f793d9ecc7

Best regards,
-- 
Rudraksha Gupta <guptarud@gmail.com>

