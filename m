From: Roman Vivchar <rva333@protonmail.com>
Date: Tue, 12 May 2026 08:18:27 +0300
Subject: [PATCH v2 13/16] ARM: dts: mediatek: mt6323: add thermal support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260512-mt6323-v2-13-3efcba579e88@protonmail.com>
References: <20260512-mt6323-v2-0-3efcba579e88@protonmail.com>
In-Reply-To: <20260512-mt6323-v2-0-3efcba579e88@protonmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Sen Chu <sen.chu@mediatek.com>, Sean Wang <sean.wang@mediatek.com>, 
 Macpaul Lin <macpaul.lin@mediatek.com>, Lee Jones <lee@kernel.org>, 
 Roman Vivchar <rva333@protonmail.com>, 
 Srinivas Kandagatla <srini@kernel.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, linux-pm@vger.kernel.org, 
 Ben Grisdale <bengris32@protonmail.ch>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778563297; l=1594;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=hUyvSa8MYTwV73cQfjfUS4VTPsNzQkrB0KKei9sFl3w=;
 b=iBXBJZ/5flzM6Pf+lOnm4NFJqNw9k+B/NfwaNSs7a/M4ot2GF0rt3PvAo32sJiacjN+R/WvmW
 V4hKYbt4vbzC0WPWyWnRHKeOSQ6rnmouUXor3C4RWhJmez7RgdpMcpv
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the devicetree node for the mt6323 thermal.

Tested-by: Ben Grisdale <bengris32@protonmail.ch> # Amazon Echo Dot (2nd Generation)
Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 arch/arm/boot/dts/mediatek/mt6323.dtsi | 31 +++++++++++++++++++++++++++++++
 1 file changed, 31 insertions(+)

diff --git a/arch/arm/boot/dts/mediatek/mt6323.dtsi b/arch/arm/boot/dts/mediatek/mt6323.dtsi
index 435936b477fa..9825e15ab4e4 100644
--- a/arch/arm/boot/dts/mediatek/mt6323.dtsi
+++ b/arch/arm/boot/dts/mediatek/mt6323.dtsi
@@ -6,6 +6,8 @@
  *
  */
 
+#include <dt-bindings/iio/adc/mediatek,mt6323-auxadc.h>
+
 &pwrap {
 	pmic: mt6323 {
 		compatible = "mediatek,mt6323";
@@ -21,6 +23,16 @@ mt6323_adc: adc {
 
 		mt6323_efuse: efuse {
 			compatible = "mediatek,mt6323-efuse";
+
+			nvmem-layout {
+				compatible = "fixed-layout";
+				#address-cells = <1>;
+				#size-cells = <1>;
+
+				mt6323_thermal_calibration_data: thermal-data@14 {
+					reg = <0x14 0x4>;
+				};
+			};
 		};
 
 		mt6323_leds: leds {
@@ -274,5 +286,24 @@ power-controller {
 		rtc {
 			compatible = "mediatek,mt6323-rtc";
 		};
+
+		mt6323_thermal: thermal {
+			compatible = "mediatek,mt6323-thermal";
+			nvmem-cells = <&mt6323_thermal_calibration_data>;
+
+			io-channels = <&mt6323_adc MT6323_AUXADC_CHIP_TEMP>;
+			#thermal-sensor-cells = <1>;
+		};
+	};
+};
+
+/ {
+	thermal-zones {
+		pmic_vts_thermal {
+			polling-delay-passive = <1000>;
+			polling-delay = <1000>;
+
+			thermal-sensors = <&mt6323_thermal 0>;
+		};
 	};
 };

-- 
2.54.0

