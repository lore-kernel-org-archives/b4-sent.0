From: Petr Hodina <petr.hodina@protonmail.com>
Date: Mon, 19 Jan 2026 18:19:08 +0100
Subject: [PATCH 3/3] sdm845: tama: Add AMS TCS3400 ambient light sensor
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260119-tsc3400-v1-3-82a65c5417aa@protonmail.com>
References: <20260119-tsc3400-v1-0-82a65c5417aa@protonmail.com>
In-Reply-To: <20260119-tsc3400-v1-0-82a65c5417aa@protonmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, David Heidelberg <david@ixit.cz>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768843157; l=1617;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=Q9E7GuxhgZ08JdbgPbICgzjn1Hy4d+2NDwK0eFbzpK4=;
 b=IPlvfSzMaVogNzIyBJOL3YLmXBH9HaRoJaSrYSVDZl1JUNZ1qdR+DMyeh2pkmnMzL6g6XE2I+
 f3+Rw8osNwoBtlto0Ayw/blcLYEr3Cmn59eFeMOVU0lSKayRCyUfKK8
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add device tree node for TCS3400 ambient light sensor with
power supplies, interrupt on GPIO11, and pinctrl states.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 .../boot/dts/qcom/sdm845-sony-xperia-tama.dtsi     | 36 +++++++++++++++++++++-
 1 file changed, 35 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-sony-xperia-tama.dtsi b/arch/arm64/boot/dts/qcom/sdm845-sony-xperia-tama.dtsi
index 7dc9349eedfd..15d56d6831c5 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-sony-xperia-tama.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-sony-xperia-tama.dtsi
@@ -485,7 +485,23 @@ &i2c14 {
 	clock-frequency = <400000>;
 
 	/* SONY ToF sensor @ 52 */
-	/* AMS TCS3490 RGB+IR color sensor @ 72 */
+
+	tcs3400_sensor: tcs3400_sensor@39 {
+		compatible = "ams,tcs3400";
+		reg = <0x39>;
+
+		interrupts-extended = <&tlmm 11 IRQ_TYPE_EDGE_FALLING>;
+
+		vdd-supply = <&vreg_l22a_2p8>;
+		vio-supply = <&cam_vio_vreg>;
+
+		pinctrl-0 = <&ams_sensor_default>;
+		pinctrl-1 = <&ams_sensor_sleep>;
+
+		ams,rgbcir-vdd-supply = <1>;
+		ams,rgbcir-gpio-vdd = <0>;
+		ams,rgbcir-vio-supply = <1>;
+	};
 };
 
 &ibb {
@@ -751,6 +767,24 @@ int-pins {
 			bias-pull-down;
 		};
 	};
+
+	ams_sensor_default: ams-sensor-default-state {
+		int-pins {
+			pins = "gpio11";
+			function = "gpio";
+			drive-strength = <2>;
+			bias-pull-up;
+		};
+	};
+
+	ams_sensor_sleep: ams_sensor-sleep-state {
+		int-pins {
+			pins = "gpio11";
+			function = "gpio";
+			drive-strength = <2>;
+			bias-pull-down;
+		};
+	};
 };
 
 &uart6 {

-- 
2.52.0

