From: Luna Hart <lhart.opensource@witekio.com>
Date: Tue, 17 Nov 2026 15:45:35 -0800
Subject: [PATCH v2 1/2] dt-bindings: hwmon: Add TI TPS389006/TPS389008
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-lhart-dev-tps38900x-v2-1-e5730523d3ee@witekio.com>
References: <20261117-lhart-dev-tps38900x-v2-0-e5730523d3ee@witekio.com>
In-Reply-To: <20261117-lhart-dev-tps38900x-v2-0-e5730523d3ee@witekio.com>
To: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>
Cc: linux-hwmon@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Flaviu Nistor <flaviu.nistor@gmail.com>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@baylibre.com>, 
 Luna Hart <lhart.opensource@witekio.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794959140; l=3741;
 i=lhart.opensource@witekio.com; s=20260928; h=from:subject:message-id;
 bh=sMKtGRvbgftwE3ETBtOaj3gXiqiiDQvh1BO5KE2HTrQ=;
 b=/ZoAO2+zv0H+i6I5EVP5w1sDUmwHKvEExL3O4lqQw7gNlFqTfRSfhaIJrOHsrewabQkOSefp6
 yqIGP8lRHPFDiw9Fu3n13Lb0K5a1tmtiwmNrCCZ0yO2PJk2DOpPHyip
X-Developer-Key: i=lhart.opensource@witekio.com; a=ed25519;
 pk=Dm1WPzsg+HuKn11WChbCWrNOk7GD980BnpCdnUwyDuU=
X-Endpoint-Received: by B4 Relay for lhart.opensource@witekio.com/20260928 with auth_id=1079
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a binding for the TI TPS389006 and TPS389008 I2C voltage
supervisors and monitors, which provide 6 and 8 voltage inputs
respectively. Each input may be described by an optional child node,
containing additional properties including the label and voltage
monitoring range. Inputs that are not connected can be marked with
status set to "disabled".

Based on an earlier binding by Flaviu Nistor.

Signed-off-by: Luna Hart <lhart.opensource@witekio.com>
---
 .../devicetree/bindings/hwmon/ti,tps389006.yaml    | 114 +++++++++++++++++++++
 1 file changed, 114 insertions(+)

diff --git a/Documentation/devicetree/bindings/hwmon/ti,tps389006.yaml b/Documentation/devicetree/bindings/hwmon/ti,tps389006.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..2a26f6623adf06d1df38d5bc3683b5d2e06f3c0f
--- /dev/null
+++ b/Documentation/devicetree/bindings/hwmon/ti,tps389006.yaml
@@ -0,0 +1,114 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/hwmon/ti,tps389006.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: TI TPS389006/TPS389008 voltage supervisor and monitor
+
+maintainers:
+  - Luna Hart <lhart.opensource@witekio.com>
+
+description: |
+  Voltage supervisor and monitor from TI (TPS389006, TPS389008) on I2C bus.
+
+  Datasheets:
+    https://www.ti.com/lit/ds/symlink/tps389006.pdf
+    https://www.ti.com/lit/ds/symlink/tps389006-q1.pdf
+
+properties:
+  compatible:
+    enum:
+      - ti,tps389006
+      - ti,tps389008
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    maxItems: 1
+    description: NIRQ fault interrupt output (active low).
+
+  "#address-cells":
+    const: 1
+
+  "#size-cells":
+    const: 0
+
+patternProperties:
+  "^channel@[0-7]$":
+    description:
+      A monitored input. Inputs that are not connected can be marked with
+      status set to "disabled".
+    type: object
+    additionalProperties: false
+
+    properties:
+      reg:
+        description: Input index, 0 for MON1 up to 7 for MON8.
+        enum: [ 0, 1, 2, 3, 4, 5, 6, 7 ]
+
+      label:
+        description: Name of the input source.
+
+      ti,vrange-multiplier:
+        description:
+          Voltage monitoring range of the input. 1 selects 0.2V to 1.475V in
+          5mV steps, 4 selects 0.8V to 5.5V in 20mV steps. If absent, the
+          range programmed in the device is used.
+        $ref: /schemas/types.yaml#/definitions/uint32
+        enum: [ 1, 4 ]
+
+    required:
+      - reg
+
+required:
+  - compatible
+  - reg
+
+allOf:
+  - if:
+      properties:
+        compatible:
+          const: ti,tps389006
+    then:
+      patternProperties:
+        "^channel@[67]$": false
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/irq.h>
+
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        voltage-monitor@30 {
+            compatible = "ti,tps389008";
+            reg = <0x30>;
+            interrupt-parent = <&gpio1>;
+            interrupts = <12 IRQ_TYPE_LEVEL_LOW>;
+            #address-cells = <1>;
+            #size-cells = <0>;
+
+            channel@0 {
+                reg = <0x0>;
+                label = "input0";
+                ti,vrange-multiplier = <4>;
+            };
+
+            channel@1 {
+                reg = <0x1>;
+                label = "input1";
+                ti,vrange-multiplier = <1>;
+            };
+
+            channel@7 {
+                reg = <0x7>;
+
+                status = "disabled";
+            };
+        };
+    };

-- 
2.47.3

