From: Roman Vivchar <rva333@protonmail.com>
Date: Mon, 04 May 2026 21:25:04 +0300
Subject: [PATCH 12/13] ARM: dts: mediatek: mt6323: add support for thermal
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260504-mt6323-v1-12-799b58b355ff@protonmail.com>
References: <20260504-mt6323-v1-0-799b58b355ff@protonmail.com>
In-Reply-To: <20260504-mt6323-v1-0-799b58b355ff@protonmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Srinivas Kandagatla <srini@kernel.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Lee Jones <lee@kernel.org>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, linux-pm@vger.kernel.org, 
 Ben Grisdale <bengris32@protonmail.ch>, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777919095; l=1739;
 i=rva333@protonmail.com; s=20260325; h=from:subject:message-id;
 bh=RnX15Bbq0POSOMld8rImsDthXoY2gvxd4clxXzA+bLs=;
 b=jW2y5q+4ec0II0RivLcNCB19jAdPdayHabag4j3LyuTqfh8CcsUQSchx+QYvx94osw2zOF/wY
 JeaBhZfg5ODAnnCm2PTOt7Ne47BabO61K4FNAWW8mMO1afuvQNniTBz
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=euuVBZGtA2Cqb8Dju84qpQPhvwxyUirJlXpqEPQWKBM=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260325 with auth_id=695
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the devicetree node for the mt6323 thermal.

Tested-by: Ben Grisdale <bengris32@protonmail.ch> # Amazon Echo Dot (2nd Generation)
Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 arch/arm/boot/dts/mediatek/mt6323.dtsi | 35 ++++++++++++++++++++++++++++++++--
 1 file changed, 33 insertions(+), 2 deletions(-)

diff --git a/arch/arm/boot/dts/mediatek/mt6323.dtsi b/arch/arm/boot/dts/mediatek/mt6323.dtsi
index 3fe6a5e35e70..bdfa177aa1e3 100644
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
@@ -21,8 +23,16 @@ mt6323_adc: adc {
 
 		mt6323_efuse: efuse {
 			compatible = "mediatek,mt6323-efuse";
-			#address-cells = <1>;
-			#size-cells = <1>;
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
@@ -276,5 +286,26 @@ power-controller {
 		rtc {
 			compatible = "mediatek,mt6323-rtc";
 		};
+
+		mt6323_thermal: thermal {
+			compatible = "mediatek,mt6323-thermal";
+			nvmem-cells = <&mt6323_thermal_calibration_data>;
+			nvmem-cell-names = "calibration-data";
+
+			io-channels = <&mt6323_adc MT6323_AUXADC_CHIP_TEMP>;
+			io-channel-names = "vts";
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
2.53.0

