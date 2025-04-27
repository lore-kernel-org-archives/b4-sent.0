From: Aaron Kling <webgeek1234@gmail.com>
Date: Sun, 27 Apr 2025 15:05:32 -0500
Subject: [PATCH] arm64: tegra: Enable PWM fan on the Jetson TX2 Devkit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250427-tx2-therm-v1-1-65ddb4314723@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAyODmgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDEyMz3ZIKI92SjNSiXN3k5FRDS0vLRINUkxQloPqCotS0zAqwWdGxtbU
 AxtftiFsAAAA=
X-Change-ID: 20250426-tx2-therm-cce1999a0e4d
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: devicetree@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745784337; l=3494;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=TW0EJ+Fija24t/QHZjDcvnNH954zMaFPLdXKDD11nCU=;
 b=jOK3dOpFlZ4UPEDkwmQSri5PRFgH9aFNSld0lj7Wc3DDO9EMsCjlO2Z+rzCOuxVtZOUllpCNP
 J1QPgsqZNcfA9jzWUkPg4lXJYFx8QZQvR42bJ9UQI/G8QiYnNjSDGhg
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is based on the existing configuration of the Jetson TX2 NX devkit.
The fan and thermal characteristics of the two devkits are similar, so
using the same configuration.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 arch/arm64/boot/dts/nvidia/tegra186-p2771-0000.dts | 109 +++++++++++++++++++++
 1 file changed, 109 insertions(+)

diff --git a/arch/arm64/boot/dts/nvidia/tegra186-p2771-0000.dts b/arch/arm64/boot/dts/nvidia/tegra186-p2771-0000.dts
index 15aa49fc450399c7bd525adcdb6e92a27a185805..a50fd205daa868d58baa6af085d6409560c5c740 100644
--- a/arch/arm64/boot/dts/nvidia/tegra186-p2771-0000.dts
+++ b/arch/arm64/boot/dts/nvidia/tegra186-p2771-0000.dts
@@ -2409,6 +2409,10 @@ eeprom@57 {
 		};
 	};
 
+	pwm@c340000 {
+		status = "okay";
+	};
+
 	pcie@10003000 {
 		status = "okay";
 
@@ -2508,6 +2512,16 @@ key-volume-up {
 		};
 	};
 
+	fan: pwm-fan {
+		compatible = "pwm-fan";
+		pwms = <&pwm4 0 45334>;
+		fan-supply = <&vdd_fan>;
+
+		/* cooling level (0, 1, 2, 3) - pwm inverted */
+		cooling-levels = <255 128 64 0>;
+		#cooling-cells = <2>;
+	};
+
 	vdd_sd: regulator-vdd-sd {
 		compatible = "regulator-fixed";
 		regulator-name = "SD_CARD_SW_PWR";
@@ -2556,6 +2570,17 @@ vdd_usb1: regulator-vdd-usb1 {
 		vin-supply = <&vdd_5v0_sys>;
 	};
 
+	vdd_fan: regulator-vdd-fan {
+		compatible = "regulator-fixed";
+		regulator-name = "VDD_FAN";
+		regulator-min-microvolt = <5000000>;
+		regulator-max-microvolt = <5000000>;
+
+		gpio = <&exp1 4 GPIO_ACTIVE_LOW>;
+
+		vin-supply = <&vdd_5v0_sys>;
+	};
+
 	sound {
 		compatible = "nvidia,tegra186-audio-graph-card";
 		status = "okay";
@@ -2621,4 +2646,88 @@ sound {
 
 		label = "NVIDIA Jetson TX2 APE";
 	};
+
+	thermal-zones {
+		cpu-thermal {
+			polling-delay = <0>;
+			polling-delay-passive = <500>;
+			status = "okay";
+
+			trips {
+				cpu_trip_critical: critical {
+					temperature = <96500>;
+					hysteresis = <0>;
+					type = "critical";
+				};
+
+				cpu_trip_hot: hot {
+					temperature = <79000>;
+					hysteresis = <2000>;
+					type = "hot";
+				};
+
+				cpu_trip_active: active {
+					temperature = <62000>;
+					hysteresis = <2000>;
+					type = "active";
+				};
+
+				cpu_trip_passive: passive {
+					temperature = <45000>;
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
+
+		aux-thermal {
+			polling-delay = <0>;
+			polling-delay-passive = <500>;
+			status = "okay";
+
+			trips {
+				aux_alert0: critical {
+					temperature = <90000>;
+					hysteresis = <0>;
+					type = "critical";
+				};
+			};
+		};
+
+		gpu-thermal {
+			polling-delay = <0>;
+			polling-delay-passive = <500>;
+			status = "okay";
+
+			trips {
+				gpu_alert0: critical {
+					temperature = <99000>;
+					hysteresis = <0>;
+					type = "critical";
+				};
+			};
+		};
+	};
 };

---
base-commit: 5bc1018675ec28a8a60d83b378d8c3991faa5a27
change-id: 20250426-tx2-therm-cce1999a0e4d

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

