From: Vincent Jardin <vjardin@free.fr>
Date: Thu, 23 Jul 2026 15:02:43 +0200
Subject: [PATCH 2/3] dt-bindings: hwmon: pmbus: add MPS MPQ8646 binding
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260723-mpq8646_v0-v1-2-14363c75916f@free.fr>
References: <20260723-mpq8646_v0-v1-0-14363c75916f@free.fr>
In-Reply-To: <20260723-mpq8646_v0-v1-0-14363c75916f@free.fr>
To: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org, 
 Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784811776; l=1982;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=Tvf4fzvHxa9KKqFmGBANHE66PMlQlAr4hrKgSTUyCc4=;
 b=U08MA3fO8zvi76wSTIPiAJ8aUZLwkoPKs9FvZXg6VsyfAmQ77Q6McjT2qLrFeIenIAchmp4T/
 Hw9h0NFEd9nCvIaKwluwz/DGo8pbMAbc6vggpSbAHthUMAmRszdwGZL
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a device-tree binding for the Monolithic Power Systems
MPQ8646 step-down converter as a PMBus devince.

The schema is inspired from the mpq8785e:
same mps,vout-fb-divider-ratio-permille property (maximum: 2047),
and const: mps,mpq8646.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 .../bindings/hwmon/pmbus/mps,mpq8646.yaml          | 50 ++++++++++++++++++++++
 1 file changed, 50 insertions(+)

diff --git a/Documentation/devicetree/bindings/hwmon/pmbus/mps,mpq8646.yaml b/Documentation/devicetree/bindings/hwmon/pmbus/mps,mpq8646.yaml
new file mode 100644
index 000000000000..401a80325b4b
--- /dev/null
+++ b/Documentation/devicetree/bindings/hwmon/pmbus/mps,mpq8646.yaml
@@ -0,0 +1,50 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+# Copyright (c) 2026 Free Mobile - Vincent Jardin <vjardin@free.fr>
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/hwmon/pmbus/mps,mpq8646.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Monolithic Power Systems MPQ8646 PMBus Step-Down Converter (extended)
+
+maintainers:
+  - Vincent Jardin <vjardin@free.fr>
+
+description: |
+  PMBus driver for the MPS MPQ8646 step-down converter.
+
+properties:
+  compatible:
+    const: mps,mpq8646
+
+  reg:
+    maxItems: 1
+
+  mps,vout-fb-divider-ratio-permille:
+    description:
+      The feedback resistor divider ratio, expressed in permille
+      (Vfb / Vout * 1000). This value is written to the
+      PMBUS_VOUT_SCALE_LOOP register and is required for correct output
+      voltage presentation.
+    $ref: /schemas/types.yaml#/definitions/uint32
+    minimum: 1
+    maximum: 2047
+    default: 706
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
+      #address-cells = <1>;
+      #size-cells = <0>;
+
+      regulator@10 {
+        compatible = "mps,mpq8646";
+        reg = <0x10>;
+      };
+    };

-- 
2.43.0

