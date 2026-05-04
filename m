From: Roman Vivchar <rva333@protonmail.com>
Date: Mon, 04 May 2026 21:24:54 +0300
Subject: [PATCH 02/13] dt-bindings: nvmem: add mt6323 PMIC EFUSE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260504-mt6323-v1-2-799b58b355ff@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777919095; l=1691;
 i=rva333@protonmail.com; s=20260325; h=from:subject:message-id;
 bh=TDwKTKu2cZc7u9klkOVCAaJXpSXuuDnK80oaDp3s4XA=;
 b=QyRCwIcC2yywc1uTzzTmOq3WgWRG+kGrwQhuXwmDoOFKdugyeRblC9dKhWN8q8RWrceuFq49w
 Grz9bOIPSeKDqHtlQqd4XA5nA/MyjxaIfEQNl7XerI3ta4FAhYIr4P3
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=euuVBZGtA2Cqb8Dju84qpQPhvwxyUirJlXpqEPQWKBM=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260325 with auth_id=695
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MediaTek mt6323 PMIC includes an EFUSE used for storing calibration
data.

Add the device tree binding documentation for the MediaTek mt6323 EFUSE.

Tested-by: Ben Grisdale <bengris32@protonmail.ch> # Amazon Echo Dot (2nd Generation)
Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 .../bindings/nvmem/mediatek,mt6323-efuse.yaml      | 42 ++++++++++++++++++++++
 1 file changed, 42 insertions(+)

diff --git a/Documentation/devicetree/bindings/nvmem/mediatek,mt6323-efuse.yaml b/Documentation/devicetree/bindings/nvmem/mediatek,mt6323-efuse.yaml
new file mode 100644
index 000000000000..eb2437b0c1f0
--- /dev/null
+++ b/Documentation/devicetree/bindings/nvmem/mediatek,mt6323-efuse.yaml
@@ -0,0 +1,42 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/nvmem/mediatek,mt6323-efuse.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: MediaTek MT6323 PMIC EFUSE
+
+description: |
+  MT6323 efuse is used for storing calibration data, such as thermal sensor
+  calibration.
+
+maintainers:
+  - Roman Vivchar <rva333@protonmail.com>
+
+allOf:
+  - $ref: nvmem.yaml#
+
+properties:
+  compatible:
+    const: mediatek,mt6323-efuse
+
+required:
+  - compatible
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    mt6323_efuse: efuse {
+      compatible = "mediatek,mt6323-efuse";
+
+      nvmem-layout {
+        compatible = "fixed-layout";
+        #address-cells = <1>;
+        #size-cells = <1>;
+
+        mt6323_thermal_calibration_data: thermal-data@14 {
+          reg = <0x14 0x4>;
+        };
+      };
+    };

-- 
2.53.0

