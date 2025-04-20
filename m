From: Aaron Kling <webgeek1234@gmail.com>
Date: Sun, 20 Apr 2025 17:42:53 -0500
Subject: [PATCH] arm64: tegra: Enable PWM fan on the Jetson TX1 Devkit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250420-tx1-therm-v1-1-58516c7fc429@gmail.com>
X-B4-Tracking: v=1; b=H4sIAGx4BWgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDEyMD3ZIKQ92SjNSiXF3LtCTjZGODtEQT4zQloPqCotS0zAqwWdGxtbU
 AXn/S9lsAAAA=
X-Change-ID: 20250420-tx1-therm-9fb3c30fa43f
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: devicetree@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745188973; l=2319;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=iN570KuLt7vPq0m05cENwdl1eH7zSuxYdheu8eBhrUE=;
 b=RGDaoSbKWpMTMzRv5hDhqR7bntY29cZbLtxuaOlXWQSiB/eyneLy+rveGmn2vQEpTtYa9VNVz
 EEOOt0lNvNwDx0QPeIxgGIu07wLLjbwXg/VxQPvPOyEpdEJt7A+Vp6H
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is based on 6f78a94, which enabled added the fan and thermal zones
for the Jetson Nano Devkit. The fan and thermal characteristics of the
two devkits are similar, so usng the same configuration.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 arch/arm64/boot/dts/nvidia/tegra210-p2597.dtsi | 60 ++++++++++++++++++++++++++
 1 file changed, 60 insertions(+)

diff --git a/arch/arm64/boot/dts/nvidia/tegra210-p2597.dtsi b/arch/arm64/boot/dts/nvidia/tegra210-p2597.dtsi
index 83ed6ac2a8d8f403fb588edce83dc401065c162f..bc02f2eb14bcbd99627c58b398bbf43061c8110b 100644
--- a/arch/arm64/boot/dts/nvidia/tegra210-p2597.dtsi
+++ b/arch/arm64/boot/dts/nvidia/tegra210-p2597.dtsi
@@ -1623,6 +1623,14 @@ key-volume-up {
 		};
 	};
 
+	fan: pwm-fan {
+		compatible = "pwm-fan";
+		pwms = <&pwm 3 45334>;
+
+		cooling-levels = <0 64 128 255>;
+		#cooling-cells = <2>;
+	};
+
 	vdd_sys_mux: regulator-vdd-sys-mux {
 		compatible = "regulator-fixed";
 		regulator-name = "VDD_SYS_MUX";
@@ -1778,4 +1786,56 @@ vdd_usb_vbus_otg: regulator-vdd-usb-vbus-otg {
 		enable-active-high;
 		vin-supply = <&vdd_5v0_sys>;
 	};
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
+				cpu-critical {
+					cooling-device = <&fan 3 3>;
+					trip = <&cpu_trip_critical>;
+				};
+
+				cpu-hot {
+					cooling-device = <&fan 2 2>;
+					trip = <&cpu_trip_hot>;
+				};
+
+				cpu-active {
+					cooling-device = <&fan 1 1>;
+					trip = <&cpu_trip_active>;
+				};
+
+				cpu-passive {
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

