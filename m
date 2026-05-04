From: Roman Vivchar <rva333@protonmail.com>
Date: Mon, 04 May 2026 21:24:55 +0300
Subject: [PATCH 03/13] dt-bindings: thermal: add mt6323 PMIC thermal
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260504-mt6323-v1-3-799b58b355ff@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777919095; l=2523;
 i=rva333@protonmail.com; s=20260325; h=from:subject:message-id;
 bh=Y0jGUqql3soeCei8ikkZ/UAUGnGbcX1Kt0zfmNLXZe4=;
 b=lQx9pnqPRHZhANCq6Fot6muIYsncfpNjwFildJFkPJyUUmvivT5WyxPskKeUZyyj05VzSA3s8
 QsmJn2RmGknDE3xVFJJ7MX3q+cv0iIOMyuptPHzDdSNh8XjAkhcp4/S
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=euuVBZGtA2Cqb8Dju84qpQPhvwxyUirJlXpqEPQWKBM=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260325 with auth_id=695
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MediaTek mt6323 PMIC temperature can be read using AUXADC channel.

Add the devicetree binding documentation for the MediaTek mt6323 thermal.
Due similarities with newer PMICs like mt6358, which include more than
one thermal sensor, the #thermal-sensor-cells should be set to 1, to
avoid breaking devicetree ABI in future.

Tested-by: Ben Grisdale <bengris32@protonmail.ch> # Amazon Echo Dot (2nd Generation)
Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 .../bindings/thermal/mediatek,mt6323-thermal.yaml  | 63 ++++++++++++++++++++++
 1 file changed, 63 insertions(+)

diff --git a/Documentation/devicetree/bindings/thermal/mediatek,mt6323-thermal.yaml b/Documentation/devicetree/bindings/thermal/mediatek,mt6323-thermal.yaml
new file mode 100644
index 000000000000..1882816ba274
--- /dev/null
+++ b/Documentation/devicetree/bindings/thermal/mediatek,mt6323-thermal.yaml
@@ -0,0 +1,63 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/thermal/mediatek,mt6323-thermal.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: MediaTek PMIC thermal
+
+maintainers:
+  - Roman Vivchar <rva333@protonmail.com>
+
+description:
+  The MediaTek PMIC thermal sensor uses an AUXADC channel to read raw
+  temperature data and applies calibration data from NVMEM.
+
+allOf:
+  - $ref: thermal-sensor.yaml#
+
+properties:
+  compatible:
+    const: mediatek,mt6323-thermal
+
+  io-channels:
+    description: >
+      IIO channel for the AUXADC to read raw data from.
+    maxItems: 1
+
+  io-channel-names:
+    const: vts
+
+  nvmem-cells:
+    description: >
+      NVMEM cell with phandle to the calibration data provided by the
+      NVMEM device. If unspecified default values will be used.
+    maxItems: 1
+
+  nvmem-cell-names:
+    const: calibration-data
+
+  "#thermal-sensor-cells":
+    const: 1
+
+required:
+  - compatible
+  - io-channels
+  - io-channel-names
+  - "#thermal-sensor-cells"
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/iio/adc/mediatek,mt6323-auxadc.h>
+
+    mt6323_thermal: thermal {
+      compatible = "mediatek,mt6323-thermal";
+      nvmem-cells = <&mt6323_thermal_calibration_data>;
+      nvmem-cell-names = "calibration-data";
+
+      io-channels = <&mt6323_adc MT6323_AUXADC_CHIP_TEMP>;
+      io-channel-names = "vts";
+      #thermal-sensor-cells = <1>;
+    };

-- 
2.53.0

