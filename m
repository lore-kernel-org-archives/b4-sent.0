From: Mizuno Miotsuki <founder@crepuse.com>
Date: Wed, 14 Oct 2026 06:45:10 +0800
Subject: [PATCH v5 2/3] dt-bindings: input: touchscreen: add Nsiway NS2009
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261014-review-self-ns2009-v4-20261013-v5-2-0851740cd939@crepuse.com>
References: <20261014-review-self-ns2009-v4-20261013-v5-0-0851740cd939@crepuse.com>
In-Reply-To: <20261014-review-self-ns2009-v4-20261013-v5-0-0851740cd939@crepuse.com>
To: dmitry.torokhov@gmail.com
Cc: krzk+dt@kernel.org, linux-input@vger.kernel.org, 
 linux-kernel@vger.kernel.org, icenowy@aosc.io, conor+dt@kernel.org, 
 robh@kernel.org, devicetree@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3748; i=founder@crepuse.com;
 s=20261012; h=from:subject:message-id;
 bh=J5Vu4eaGlLH4g1cPvBTxdXuhSAI05sIXWGBXtk2x+To=;
 b=owGbwMvMwCUmds2G2fVJ/hLG02pJDFnntpTVLuk8/L/QVn/JLH7GBTsmpK/TOHODP35/xtZZS
 38UCmwr65jIwiDGxWAppsgyW5S9/FDzimtzJzTZwcxhZQIZIi3SwAAELAx8uYl5pUY6Rnqm2oZ6
 hkY6BjrGDFycAjDVW80YGf4Xrcj29ts0lb3iBNfjV5OOr4vb5V9+5u3miIdyXYKfJBoZ/sppH2l
 t5I7yFPiiumZBgN9E9oqQKy77ClgrNinz3P2SyAkA
X-Developer-Key: i=founder@crepuse.com; a=openpgp;
 fpr=9B150777C283A8D69D90823E16D63C0345E46FA4
X-Endpoint-Received: by B4 Relay for founder@crepuse.com/20261012 with auth_id=1166
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the Nsiway NS2009 four-wire resistive touchscreen controller,
including its pen interrupt, main supply and external reference supply.
Keep vref-supply optional:
differential touch measurements reference the driven panel terminals, and
the 10-pin package does not expose a separate VREF pin.

Allow the common coordinate and touch resistance properties, and describe
the raw Z1 contact threshold separately from calibrated pressure.

Reviewed-by: Conor Dooley <conor.dooley@microchip.com>
Signed-off-by: Mizuno Miotsuki <founder@crepuse.com>
---
 .../bindings/input/touchscreen/nsiway,ns2009.yaml  | 79 ++++++++++++++++++++++
 MAINTAINERS                                        |  6 ++
 2 files changed, 85 insertions(+)

diff --git a/Documentation/devicetree/bindings/input/touchscreen/nsiway,ns2009.yaml b/Documentation/devicetree/bindings/input/touchscreen/nsiway,ns2009.yaml
new file mode 100644
index 000000000000..8ee7ff7156ca
--- /dev/null
+++ b/Documentation/devicetree/bindings/input/touchscreen/nsiway,ns2009.yaml
@@ -0,0 +1,79 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/input/touchscreen/nsiway,ns2009.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Nsiway NS2009 resistive touchscreen controller
+
+maintainers:
+  - Mizuno Miotsuki <founder@crepuse.com>
+
+description:
+  Nsiway NS2009 is an I2C four-wire resistive touchscreen controller with
+  a 12-bit ADC, an active-low pen interrupt and touch resistance measurement.
+
+allOf:
+  - $ref: touchscreen.yaml#
+
+properties:
+  compatible:
+    const: nsiway,ns2009
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    maxItems: 1
+    description:
+      Active-low pen interrupt output. Optional when the signal is not
+      connected.
+
+  wakeup-source:
+    type: boolean
+
+  vdd-supply:
+    description: Main power supply.
+
+  vref-supply:
+    description: External ADC reference voltage supply.
+
+  touchscreen-min-pressure:
+    minimum: 1
+    maximum: 4095
+    default: 80
+    description:
+      Minimum raw Z1 reading considered a touch. This is a contact detection
+      threshold, not a calibrated pressure value. Boards may require a higher
+      empirically determined threshold than the historical driver default.
+
+required:
+  - compatible
+  - reg
+  - vdd-supply
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/irq.h>
+
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        touchscreen@48 {
+            compatible = "nsiway,ns2009";
+            reg = <0x48>;
+            interrupt-parent = <&gpio1>;
+            interrupts = <7 IRQ_TYPE_LEVEL_LOW>;
+            wakeup-source;
+            vdd-supply = <&vdd>;
+            vref-supply = <&vref>;
+            touchscreen-x-plate-ohms = <400>;
+            touchscreen-min-pressure = <150>;
+            touchscreen-max-pressure = <4095>;
+            touchscreen-fuzz-pressure = <16>;
+            touchscreen-inverted-y;
+        };
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index f53047aa8d3c..696f2badc49c 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -19467,6 +19467,12 @@ S:	Maintained
 F:	Documentation/core-api/symbol-namespaces.rst
 F:	scripts/nsdeps
 
+NSIWAY NS2009 TOUCHSCREEN CONTROLLER
+M:	Mizuno Miotsuki <founder@crepuse.com>
+L:	linux-input@vger.kernel.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/input/touchscreen/nsiway,ns2009.yaml
+
 NTB AMD DRIVER
 M:	Basavaraj Natikar <Basavaraj.Natikar@amd.com>
 M:	Shyam Sundar S K <Shyam-sundar.S-k@amd.com>

-- 
2.56.0

