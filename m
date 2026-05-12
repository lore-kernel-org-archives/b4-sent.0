From: Roman Vivchar <rva333@protonmail.com>
Date: Tue, 12 May 2026 08:18:18 +0300
Subject: [PATCH v2 04/16] dt-bindings: mfd: mediatek: mt6397: add mt6323
 PMIC thermal
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260512-mt6323-v2-4-3efcba579e88@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778563297; l=2547;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=ZpxlgI78YGvqL6f2ifb/QUYUxotfv5VA81LyEjs6Ymg=;
 b=5BpWueZ6TOkGclDn87Sy1sIhi9IvwPL+bOAayzD9G/vf7l+pNOHAza/evuYJiGk/kmkMyaTE6
 fLx7vC0yprjDBloMp/NHwxiCGAjDohboW+0tPC3yFrcGLM/t0thkt9k
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MediaTek mt6323 PMIC temperature can be read using AUXADC channel.

Add the devicetree binding documentation for the MediaTek mt6323 thermal.

While mt6323 exposes only a single thermal sensor, newer PMICs like
mt6358 provide more than one sensor. Therefore define #thermal-sensor-cells
as 1 to avoid breaking devicetree ABI in the future.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 .../devicetree/bindings/mfd/mediatek,mt6397.yaml   | 44 ++++++++++++++++++++++
 1 file changed, 44 insertions(+)

diff --git a/Documentation/devicetree/bindings/mfd/mediatek,mt6397.yaml b/Documentation/devicetree/bindings/mfd/mediatek,mt6397.yaml
index beaa67bf0df2..2c826737189e 100644
--- a/Documentation/devicetree/bindings/mfd/mediatek,mt6397.yaml
+++ b/Documentation/devicetree/bindings/mfd/mediatek,mt6397.yaml
@@ -242,6 +242,31 @@ properties:
     description:
       Pin controller
 
+  thermal:
+    type: object
+    unevaluatedProperties: false
+    description:
+      PMIC thermal monitoring
+
+    properties:
+      compatible:
+        const: mediatek,mt6323-thermal
+
+      io-channels:
+        description:
+          IIO channel for the AUXADC to read raw data from.
+        maxItems: 1
+
+      nvmem-cells:
+        maxItems: 1
+
+      "#thermal-sensor-cells":
+        const: 1
+    required:
+      - compatible
+      - io-channels
+      - "#thermal-sensor-cells"
+
 required:
   - compatible
   - regulators
@@ -250,6 +275,7 @@ additionalProperties: false
 
 examples:
   - |
+    #include <dt-bindings/iio/adc/mediatek,mt6323-auxadc.h>
     #include <dt-bindings/interrupt-controller/arm-gic.h>
     #include <dt-bindings/leds/common.h>
 
@@ -262,6 +288,16 @@ examples:
 
         efuse {
           compatible = "mediatek,mt6323-efuse";
+
+          nvmem-layout {
+            compatible = "fixed-layout";
+            #address-cells = <1>;
+            #size-cells = <1>;
+
+            mt6323_thermal_calibration_data: thermal-data@14 {
+              reg = <0x14 0x4>;
+            };
+          };
         };
 
         leds {
@@ -511,6 +547,14 @@ examples:
         rtc {
             compatible = "mediatek,mt6323-rtc";
         };
+
+        thermal {
+          compatible = "mediatek,mt6323-thermal";
+          nvmem-cells = <&mt6323_thermal_calibration_data>;
+
+          io-channels = <&mt6323_adc MT6323_AUXADC_CHIP_TEMP>;
+          #thermal-sensor-cells = <1>;
+        };
     };
 
   - |

-- 
2.54.0

