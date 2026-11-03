From: Rajan Yadav <rajanyadav0307@gmail.com>
Date: Tue, 03 Nov 2026 03:09:04 -0600
Subject: [PATCH] arm64: dts: allwinner: a100: Add CPU thermal trips and
 cooling maps
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-a100-thermal-trips-v1-1-73bce7ff0767@gmail.com>
X-B4-Tracking: v=1; b=H4sIAK+k6WoC/yXMQQrCQAxG4auUrA0ktah4FXExU39tRGtJRhFK7
 +6oy2/x3kwBNwTtm5kcLwt7jBW6aqgf0ngB26maWmk3qrLmpCJcBvg93bi4TcEZ2mEn3TZLohp
 OjrO9f9PD8e945iv68j3RsnwAeuWDOnYAAAA=
X-Change-ID: 20261103-a100-thermal-trips-be14e8047b0a
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Rajan Yadav <rajanyadav0307@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793696943; l=3851;
 i=rajanyadav0307@gmail.com; s=20261103; h=from:subject:message-id;
 bh=TK5v1GFylrgHUT61Byg8vJfxL26nBlC6KGx7Vp13nuU=;
 b=/0kW6ihxKb1jQSR5o8EODnSv+/ohl7t86rMTSddqI7rmvqiEcu/p299NMpE/Ho5Fz1M0xWnl5
 TIh1RNopqd7Bwqbl5AidD39HpB0upbRkKxbFiRQ6ANcSnaXnG3akcoK
X-Developer-Key: i=rajanyadav0307@gmail.com; a=ed25519;
 pk=4ZPeiP5qrv2b44q/Obxi2koUS70Q6npbttJnpUoTlgg=
X-Endpoint-Received: by B4 Relay for rajanyadav0307@gmail.com/20261103 with auth_id=1391
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The CPU thermal zone in sun50i-a100.dtsi has a sensor but no trip
points, so nothing throttles the CPU as it heats up and nothing shuts
the system down before it overheats. On a KickPi K5C (A133) without a
heatsink, the CPU reaches 90 C within minutes of full load.

Add a passive trip at 90 C that throttles all four cores through
cpufreq, and a critical trip at 110 C, using the same layout as
sun50i-h6.dtsi.

The temperatures come from the Allwinner BSP (sun50iw10p1.dtsi). The
BSP drives this zone with the power allocator governor: control starts
at 70 C, the target is 90 C, and 110 C is critical. The power
allocator needs a power model of the CPUs (dynamic-power-coefficient),
which the A100 does not have in mainline, so here the 90 C target
becomes a step_wise passive trip, and the 110 C critical trip is kept.
110 C is also the highest working junction temperature in the
recommended operating conditions of the A133 datasheet (rev 1.5,
table 5-2). The absolute maximum is 125 C.

The GPU and DDR zones are left without trips, as in the BSP.

Polling stays disabled: the sensor raises an interrupt every 250 ms
and the driver updates the zone from it, as on the H6.

Tested on a KickPi K5C (A133, no heatsink):
- one hour of full load on all cores held the CPU at about 90 C, with
  short throttling to 1.32 GHz
- with thermal emulation, a rising temperature lowers the limit one
  OPP at a time down to 408 MHz, the limit is released below 88 C, and
  111 C triggers the hardware protection shutdown

Signed-off-by: Rajan Yadav <rajanyadav0307@gmail.com>
---
arm64: dts: allwinner: a100: Add CPU thermal trips and cooling maps
---
 arch/arm64/boot/dts/allwinner/sun50i-a100.dtsi | 29 ++++++++++++++++++++++++++
 1 file changed, 29 insertions(+)

diff --git a/arch/arm64/boot/dts/allwinner/sun50i-a100.dtsi b/arch/arm64/boot/dts/allwinner/sun50i-a100.dtsi
index ba6020989..fce91dc2c 100644
--- a/arch/arm64/boot/dts/allwinner/sun50i-a100.dtsi
+++ b/arch/arm64/boot/dts/allwinner/sun50i-a100.dtsi
@@ -8,6 +8,7 @@
 #include <dt-bindings/clock/sun50i-a100-r-ccu.h>
 #include <dt-bindings/reset/sun50i-a100-ccu.h>
 #include <dt-bindings/reset/sun50i-a100-r-ccu.h>
+#include <dt-bindings/thermal/thermal.h>
 
 / {
 	interrupt-parent = <&gic>;
@@ -24,6 +25,7 @@ cpu0: cpu@0 {
 			reg = <0x0>;
 			enable-method = "psci";
 			clocks = <&ccu CLK_CPUX>;
+			#cooling-cells = <2>;
 		};
 
 		cpu1: cpu@1 {
@@ -32,6 +34,7 @@ cpu1: cpu@1 {
 			reg = <0x1>;
 			enable-method = "psci";
 			clocks = <&ccu CLK_CPUX>;
+			#cooling-cells = <2>;
 		};
 
 		cpu2: cpu@2 {
@@ -40,6 +43,7 @@ cpu2: cpu@2 {
 			reg = <0x2>;
 			enable-method = "psci";
 			clocks = <&ccu CLK_CPUX>;
+			#cooling-cells = <2>;
 		};
 
 		cpu3: cpu@3 {
@@ -48,6 +52,7 @@ cpu3: cpu@3 {
 			reg = <0x3>;
 			enable-method = "psci";
 			clocks = <&ccu CLK_CPUX>;
+			#cooling-cells = <2>;
 		};
 	};
 
@@ -659,6 +664,30 @@ cpu-thermal {
 			polling-delay-passive = <0>;
 			polling-delay = <0>;
 			thermal-sensors = <&ths 0>;
+
+			trips {
+				cpu_alert: cpu-alert {
+					temperature = <90000>;
+					hysteresis = <2000>;
+					type = "passive";
+				};
+
+				cpu-crit {
+					temperature = <110000>;
+					hysteresis = <0>;
+					type = "critical";
+				};
+			};
+
+			cooling-maps {
+				map0 {
+					trip = <&cpu_alert>;
+					cooling-device = <&cpu0 THERMAL_NO_LIMIT THERMAL_NO_LIMIT>,
+							 <&cpu1 THERMAL_NO_LIMIT THERMAL_NO_LIMIT>,
+							 <&cpu2 THERMAL_NO_LIMIT THERMAL_NO_LIMIT>,
+							 <&cpu3 THERMAL_NO_LIMIT THERMAL_NO_LIMIT>;
+				};
+			};
 		};
 
 		ddr-thermal {

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261103-a100-thermal-trips-be14e8047b0a

Best regards,
--  
Rajan Yadav <rajanyadav0307@gmail.com>

