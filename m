From: Nayab Sayed <nayabbasha.sayed@microchip.com>
Date: Mon, 17 Mar 2025 16:44:24 +0530
Subject: [PATCH] dt-bindings: mtd: atmel,dataflash: convert txt to yaml
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250317-atmel-dataflash-v1-1-b5f13083f67c@microchip.com>
X-B4-Tracking: v=1; b=H4sIAA8E2GcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDY0Nz3cSS3NQc3ZTEksS0nMTiDF0TA9NUS5PUFIs0szQloK6CotS0zAq
 widGxtbUA0kpqS2EAAAA=
X-Change-ID: 20250317-atmel-dataflash-405e94ed8f6f
To: Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Nicolas Ferre <nicolas.ferre@microchip.com>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Claudiu Beznea <claudiu.beznea@tuxon.dev>
Cc: Nayab Sayed <nayabbasha.sayed@microchip.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3000;
 i=nayabbasha.sayed@microchip.com; h=from:subject:message-id;
 bh=P9+lMKW5fDbyoDq7LnkeOIvwDBv4IZcbCICN8qf70EI=;
 b=owGbwMvMwCEmfMj/xNz7ei8ZT6slMaTfYBH1qjtR2b9IxNI98yPrJpvoeZX+Dy4nGk55U5sur
 KZ27FRlRykLgxgHg6yYIkv35vmzDYv+dGb+5FwBM4eVCWQIAxenAExELZ2RYbmZnO62j+k7Cycz
 PTdpfKaiPF9xR1dIjbGGlLHHYj9jeYb/AZUnLwicsF/8946MSf/VC5knaqenn+x/feRT6K+/zCf
 s2QE=
X-Developer-Key: i=nayabbasha.sayed@microchip.com; a=openpgp;
 fpr=E108A58C09FB2280B0AB41DAE24318EF3B3861A3
X-Endpoint-Received: by B4 Relay for nayabbasha.sayed@microchip.com/default with auth_id=304
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Convert atmel-dataflash.txt into atmel,dataflash.yaml

Signed-off-by: Nayab Sayed <nayabbasha.sayed@microchip.com>
---
 .../devicetree/bindings/mtd/atmel,dataflash.yaml   | 55 ++++++++++++++++++++++
 .../devicetree/bindings/mtd/atmel-dataflash.txt    | 17 -------
 2 files changed, 55 insertions(+), 17 deletions(-)

diff --git a/Documentation/devicetree/bindings/mtd/atmel,dataflash.yaml b/Documentation/devicetree/bindings/mtd/atmel,dataflash.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..8c72fa346e3631284d222837a621fed47103c889
--- /dev/null
+++ b/Documentation/devicetree/bindings/mtd/atmel,dataflash.yaml
@@ -0,0 +1,55 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/mtd/atmel,dataflash.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Atmel DataFlash
+
+maintainers:
+  - Nayab Sayed <nayabbasha.sayed@microchip.com>
+
+description:
+  The Atmel DataFlash is a low pin-count serial interface sequential access
+  Flash memory, compatible with SPI standard. The device tree may optionally
+  contain sub-nodes describing partitions of the address space.
+
+properties:
+  compatible:
+    oneOf:
+      - items:
+          - enum:
+              - atmel,at45db321d
+              - atmel,at45db041e
+              - atmel,at45db642d
+              - atmel,at45db021d
+          - const: atmel,at45
+          - const: atmel,dataflash
+      - items:
+          - const: atmel,at45
+          - const: atmel,dataflash
+
+  reg:
+    maxItems: 1
+
+required:
+  - compatible
+  - reg
+
+allOf:
+  - $ref: mtd.yaml#
+  - $ref: /schemas/spi/spi-peripheral-props.yaml#
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    spi {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        flash@1 {
+            compatible = "atmel,at45db321d", "atmel,at45", "atmel,dataflash";
+            reg = <1>;
+        };
+    };
diff --git a/Documentation/devicetree/bindings/mtd/atmel-dataflash.txt b/Documentation/devicetree/bindings/mtd/atmel-dataflash.txt
deleted file mode 100644
index 1889a4db5b7c47ed1f4908dc785a2c87abff9c57..0000000000000000000000000000000000000000
--- a/Documentation/devicetree/bindings/mtd/atmel-dataflash.txt
+++ /dev/null
@@ -1,17 +0,0 @@
-* Atmel Data Flash
-
-Required properties:
-- compatible : "atmel,<model>", "atmel,<series>", "atmel,dataflash".
-
-The device tree may optionally contain sub-nodes describing partitions of the
-address space. See partition.txt for more detail.
-
-Example:
-
-flash@1 {
-	#address-cells = <1>;
-	#size-cells = <1>;
-	compatible = "atmel,at45db321d", "atmel,at45", "atmel,dataflash";
-	spi-max-frequency = <25000000>;
-	reg = <1>;
-};

---
base-commit: 4701f33a10702d5fc577c32434eb62adde0a1ae1
change-id: 20250317-atmel-dataflash-405e94ed8f6f

Best regards,
-- 
Nayab Sayed <nayabbasha.sayed@microchip.com>

