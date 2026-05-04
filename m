From: Roman Vivchar <rva333@protonmail.com>
Date: Mon, 04 May 2026 21:24:53 +0300
Subject: [PATCH 01/13] dt-bindings: iio: adc: add mt6323 PMIC AUXADC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260504-mt6323-v1-1-799b58b355ff@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777919095; l=2722;
 i=rva333@protonmail.com; s=20260325; h=from:subject:message-id;
 bh=XPIXRDZjIr1oHvzoo9sh4iZKYAKxVcZZDRCPHSoj0Zs=;
 b=6PgEHIy0LQy0rccGbN1mtBbpxZNOpoWD7AzrYh5pCwjNaWk8d5CeZXcYp9p+hWzjpttEQC1a4
 n82lAnVqs97A8v9uCRo+z553P0v6pmYYduZNXxmLK1JJ5X3SUlPMaEW
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=euuVBZGtA2Cqb8Dju84qpQPhvwxyUirJlXpqEPQWKBM=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260325 with auth_id=695
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MediaTek mt6323 PMIC includes an AUXADC used for battery voltage,
temperature, and other internal measurements.

Add the devicetree binding documentation and the associated header file
defining the ADC channel constants.

Tested-by: Ben Grisdale <bengris32@protonmail.ch> # Amazon Echo Dot (2nd Generation)
Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 .../bindings/iio/adc/mediatek,mt6323-auxadc.yaml   | 39 ++++++++++++++++++++++
 .../dt-bindings/iio/adc/mediatek,mt6323-auxadc.h   | 16 +++++++++
 2 files changed, 55 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/adc/mediatek,mt6323-auxadc.yaml b/Documentation/devicetree/bindings/iio/adc/mediatek,mt6323-auxadc.yaml
new file mode 100644
index 000000000000..7dc1ac8bf253
--- /dev/null
+++ b/Documentation/devicetree/bindings/iio/adc/mediatek,mt6323-auxadc.yaml
@@ -0,0 +1,39 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/iio/adc/mediatek,mt6323-auxadc.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: MediaTek MT6323 PMIC AUXADC
+
+maintainers:
+  - Roman Vivchar <rva333@protonmail.com>
+
+description: >
+  The Auxiliary Analog/Digital Converter (AUXADC) is an ADC found
+  in the MediaTek MT6323 PMIC, performing various PMIC related measurements
+  such as battery and PMIC internal voltage regulators temperatures,
+  accessory detection resistance (usually, for a 3.5mm audio jack)
+  other than voltages for various PMIC internal components.
+
+properties:
+  compatible:
+    const: mediatek,mt6323-auxadc
+
+  "#io-channel-cells":
+    const: 1
+
+required:
+  - compatible
+  - "#io-channel-cells"
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/iio/adc/mediatek,mt6323-auxadc.h>
+
+    adc {
+        compatible = "mediatek,mt6323-auxadc";
+        #io-channel-cells = <1>;
+    };
diff --git a/include/dt-bindings/iio/adc/mediatek,mt6323-auxadc.h b/include/dt-bindings/iio/adc/mediatek,mt6323-auxadc.h
new file mode 100644
index 000000000000..c12a21e7ddea
--- /dev/null
+++ b/include/dt-bindings/iio/adc/mediatek,mt6323-auxadc.h
@@ -0,0 +1,16 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause) */
+
+#ifndef _DT_BINDINGS_MEDIATEK_MT6323_AUXADC_H
+#define _DT_BINDINGS_MEDIATEK_MT6323_AUXADC_H
+
+#define MT6323_AUXADC_BATON2 0
+#define MT6323_AUXADC_CH6 1
+#define MT6323_AUXADC_BAT_TEMP 2
+#define MT6323_AUXADC_CHIP_TEMP 3
+#define MT6323_AUXADC_VCDT 4
+#define MT6323_AUXADC_BATON1 5
+#define MT6323_AUXADC_ISENSE 6
+#define MT6323_AUXADC_BATSNS 7
+#define MT6323_AUXADC_ACCDET 8
+
+#endif

-- 
2.53.0

