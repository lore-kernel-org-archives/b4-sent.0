From: Aaron Kling <webgeek1234@gmail.com>
Date: Thu, 01 May 2025 17:32:23 -0500
Subject: [PATCH v2] arm64: tegra: Enable PWM fan on the Jetson TX1 Devkit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250501-tx1-therm-v2-1-abdb1922c001@gmail.com>
X-B4-Tracking: v=1; b=H4sIAHb2E2gC/23MSw7CIBSF4a00dyyGp1pH7sN0gAjlJlIMEFLTs
 HexY4f/ycm3QbYJbYbrsEGyFTPGpQc/DGC8XmZL8NkbOOWKSk5JWRkp3qZARvcQRlCnpXDQ/+9
 kHa67dZ96e8wlps9OV/Zb/ymVEUbURbGTOTsj+Xibg8bX0cQAU2vtC4GbZxyiAAAA
X-Change-ID: 20250420-tx1-therm-9fb3c30fa43f
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: devicetree@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746138746; l=3058;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=5WwXIILW7h6PVNyGMb5HuC90et+tCHw6bRcXa5HcJ8g=;
 b=cdAMKSijdEpZU1K5DfekxqFfLwNz+5PfWhWRkyosUCSkP4J0nShnN5pYqwPAIkGJrkI9IzSow
 eaTFIF278T1DXzlUlLLu5TobhfV55hLm6MHCLIVBWI5fQG7ESqdFqEl
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is based on 6f78a94, which enabled added the fan and thermal zones
for the Jetson Nano Devkit. The fan and thermal characteristics of the
two devkits are similar, so using the same configuration.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Changes in v2:
- Add fan regulator
- Add interrupt for tachometer
- Reverse cooling map to account for inverse polarity
- Rename cooling map nodes to map# as tht is all the schema allows
- Link to v1: https://lore.kernel.org/r/20250420-tx1-therm-v1-1-58516c7fc429@gmail.com
---
 arch/arm64/boot/dts/nvidia/tegra210-p2597.dtsi | 75 ++++++++++++++++++++++++++
 1 file changed, 75 insertions(+)

diff --git a/arch/arm64/boot/dts/nvidia/tegra210-p2597.dtsi b/arch/arm64/boot/dts/nvidia/tegra210-p2597.dtsi
index 83ed6ac2a8d8f403fb588edce83dc401065c162f..584461f3a6196c4327e958b424dfd2139cd43965 100644
--- a/arch/arm64/boot/dts/nvidia/tegra210-p2597.dtsi
+++ b/arch/arm64/boot/dts/nvidia/tegra210-p2597.dtsi
@@ -1623,6 +1623,18 @@ key-volume-up {
 		};
 	};
 
+	fan: pwm-fan {
+		compatible = "pwm-fan";
+		pwms = <&pwm 3 45334>;
+		fan-supply = <&vdd_fan>;
+		interrupt-parent = <&gpio>;
+		interrupts = <TEGRA_GPIO(K, 7) IRQ_TYPE_EDGE_RISING>;
+
+		/* cooling level (0, 1, 2, 3) - pwm inverted */
+		cooling-levels = <255 128 64 0>;
+		#cooling-cells = <2>;
+	};
+
 	vdd_sys_mux: regulator-vdd-sys-mux {
 		compatible = "regulator-fixed";
 		regulator-name = "VDD_SYS_MUX";
@@ -1778,4 +1790,67 @@ vdd_usb_vbus_otg: regulator-vdd-usb-vbus-otg {
 		enable-active-high;
 		vin-supply = <&vdd_5v0_sys>;
 	};
+
+	vdd_fan: regulator-vdd-fan {
+		compatible = "regulator-fixed";
+		regulator-name = "VDD_FAN";
+		regulator-min-microvolt = <5000000>;
+		regulator-max-microvolt = <5000000>;
+		gpio = <&exp1 4 GPIO_ACTIVE_LOW>;
+		vin-supply = <&vdd_5v0_sys>;
+
+		regulator-enable-ramp-delay = <284>;
+	};
+
+	thermal-zones {
+		cpu-thermal {
+			trips {
+				cpu_trip_critical: critical {
+					temperature = <96500>;
+					hysteresis = <0>;
+					type = "critical";
+				};
+
+				cpu_trip_hot: hot {
+					temperature = <70000>;
+					hysteresis = <2000>;
+					type = "hot";
+				};
+
+				cpu_trip_active: active {
+					temperature = <50000>;
+					hysteresis = <2000>;
+					type = "active";
+				};
+
+				cpu_trip_passive: passive {
+					temperature = <30000>;
+					hysteresis = <2000>;
+					type = "passive";
+				};
+			};
+
+			cooling-maps {
+				map0 {
+					cooling-device = <&fan 3 3>;
+					trip = <&cpu_trip_critical>;
+				};
+
+				map1 {
+					cooling-device = <&fan 2 2>;
+					trip = <&cpu_trip_hot>;
+				};
+
+				map2 {
+					cooling-device = <&fan 1 1>;
+					trip = <&cpu_trip_active>;
+				};
+
+				map3 {
+					cooling-device = <&fan 0 0>;
+					trip = <&cpu_trip_passive>;
+				};
+			};
+		};
+	};
 };

---
base-commit: 9c32cda43eb78f78c73aee4aa344b777714e259b
change-id: 20250420-tx1-therm-9fb3c30fa43f

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

