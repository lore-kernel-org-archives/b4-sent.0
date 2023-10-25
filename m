From: Richard Leitner <richard.leitner@linux.dev>
Date: Wed, 25 Oct 2023 10:34:12 +0000
Subject: [PATCH 2/4] dt-bindings: hwmon: add ti,ina238
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231025-ina237-v1-2-a0196119720c@linux.dev>
References: <20231025-ina237-v1-0-a0196119720c@linux.dev>
In-Reply-To: <20231025-ina237-v1-0-a0196119720c@linux.dev>
To: Guenter Roeck <linux@roeck-us.net>, Jean Delvare <jdelvare@suse.com>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 devicetree@vger.kernel.org, Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1698230088; l=2124;
 i=richard.leitner@linux.dev; s=20231025; h=from:subject:message-id;
 bh=i2xaXqOVgU88Uvg3QDgHjQjoR8ujrvuCPuyxLV6Xtz4=;
 b=yuv9v7Sy8wlR5MraQ2EgcTULWV5JPbnedvH4packoK616Xqds4Mm9TEg6QErN/mLJKfPfxhhqp4c
 CD7JxoP4Bq3qpgWMbMbjwAsk960HEgsqRRKpjySvzmZZnznGL4HR
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=ZYa5+0m9RFYtnNU6DLet7sHyPehnVHa0ucJlYiAu2NU=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20231025 with auth_id=90
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ina238 driver is available since 2021 but lacks a dt-bindings file.
Therefore add the missing file now.

Mention Jean Delvare and Guenter Roeck as maintainers as reported by the
get_maintainer.pl script.

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 .../devicetree/bindings/hwmon/ti,ina238.yaml       | 46 ++++++++++++++++++++++
 MAINTAINERS                                        |  1 +
 2 files changed, 47 insertions(+)

diff --git a/Documentation/devicetree/bindings/hwmon/ti,ina238.yaml b/Documentation/devicetree/bindings/hwmon/ti,ina238.yaml
new file mode 100644
index 000000000000..aba89e5f34b3
--- /dev/null
+++ b/Documentation/devicetree/bindings/hwmon/ti,ina238.yaml
@@ -0,0 +1,46 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+
+$id: http://devicetree.org/schemas/hwmon/ti,ina238.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Texas Instruments INA238 power/voltage monitors
+
+maintainers:
+  - Jean Delvare <jdelvare@suse.com>
+  - Guenter Roeck <linux@roeck-us.net>
+
+description: |
+  The INA238 is an ultra-precise digital power monitor with a
+  16-bit delta-sigma ADC specifically designed for current-sensing
+  applications.
+
+  Datasheets:
+    https://www.ti.com/lit/ds/symlink/ina238.pdf
+
+properties:
+  compatible:
+    enum:
+      - ti,ina238
+
+  reg:
+    maxItems: 1
+
+required:
+  - compatible
+  - reg
+
+additionalProperties: false
+
+examples:
+  - |
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        power-sensor@40 {
+            compatible = "ti,ina238";
+            reg = <0x40>;
+        };
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index 28f91c8a2e1c..13858bd6a3d4 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -10271,6 +10271,7 @@ INA238 HARDWARE MONITOR DRIVER
 M:	Guenter Roeck <linux@roeck-us.net>
 L:	linux-hwmon@vger.kernel.org
 S:	Maintained
+F:	Documentation/devicetree/bindings/hwmon/ti,ina238.yaml
 F:	drivers/hwmon/ina238.c
 
 INDEX OF FURTHER KERNEL DOCUMENTATION

-- 
2.40.1

