From: Alexandre Hamamdjian <azkali.limited@gmail.com>
Date: Mon, 11 May 2026 01:09:49 +0700
Subject: [PATCH 1/2] dt-bindings: iio: light: Add ROHM BH1730FVC binding
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260511-bh1730-v1-1-e0df1f499135@gmail.com>
References: <20260511-bh1730-v1-0-e0df1f499135@gmail.com>
In-Reply-To: <20260511-bh1730-v1-0-e0df1f499135@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, CTCaer <ctcaer@gmail.com>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Alexandre Hamamdjian <azkali.limited@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778436589; l=3793;
 i=azkali.limited@gmail.com; s=20260510; h=from:subject:message-id;
 bh=jQHKR47Y8URKhOfFc/PxeUwRtzxZuqi9u6qUMfwgT9g=;
 b=ObpFPEaz1gMJZrJKNnAZL+40c304k1+WO2lqMgrq91nU3A5nKTrMr0nYckD7+iHo7qyNij7ZN
 Y5dEaGJwKdxDczrGylqUt+yNwxh5kvsPLKgpW7qXwFETXJPQ9AlRB3T
X-Developer-Key: i=azkali.limited@gmail.com; a=ed25519;
 pk=I0Z0IdCdQJqNGX+FQUnXhrHg950u3cM6Xzz3YT6JOyQ=
X-Endpoint-Received: by B4 Relay for azkali.limited@gmail.com/20260510 with auth_id=774
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: CTCaer <ctcaer@gmail.com>

Add a YAML binding for the ROHM BH1730FVC ambient light sensor.
Documents the required compatible string, the als-vdd/als-vid
regulators, and the rohm,integration-cycle, rohm,lux-multiplier,
rohm,opt-win-coeff and rohm,gain-coeff calibration properties
consumed by the driver.

Signed-off-by: CTCaer <ctcaer@gmail.com>
Signed-off-by: Alexandre Hamamdjian <azkali.limited@gmail.com>
---
 .../bindings/iio/light/rohm,bh1730fvc.yaml         | 95 ++++++++++++++++++++++
 1 file changed, 95 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/light/rohm,bh1730fvc.yaml b/Documentation/devicetree/bindings/iio/light/rohm,bh1730fvc.yaml
new file mode 100644
index 000000000000..6273b69e82ab
--- /dev/null
+++ b/Documentation/devicetree/bindings/iio/light/rohm,bh1730fvc.yaml
@@ -0,0 +1,95 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/iio/light/rohm,bh1730fvc.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: ROHM BH1730FVC ambient light sensor
+
+maintainers:
+  - CTCaer <ctcaer@gmail.com>
+
+description:
+  Digital 16-bit ambient light sensor with an I2C interface. The device has
+  two photodiodes (visible and infrared) and supports four gain settings and
+  programmable integration time.
+
+properties:
+  compatible:
+    const: rohm,bh1730fvc
+
+  reg:
+    maxItems: 1
+
+  als-vdd-supply:
+    description: Regulator for the analog/digital supply (VDD).
+
+  als-vid-supply:
+    description: Regulator for the LED indicator supply (VID).
+
+  rohm,integration-cycle:
+    description:
+      Number of internal clock cycles used for the ADC integration time.
+      Used together with rohm,lux-multiplier to calibrate the lux output.
+    $ref: /schemas/types.yaml#/definitions/uint32
+
+  rohm,lux-multiplier:
+    description:
+      Lux scaling multiplier applied after integration. Used together with
+      rohm,integration-cycle to calibrate the lux output.
+    $ref: /schemas/types.yaml#/definitions/uint32
+
+  rohm,opt-win-coeff:
+    description:
+      Optical-window calibration coefficients. Specified as a flat list of
+      triplets <rc cv ci>, one triplet per window region, where rc is the
+      visible/IR ratio cutoff and cv/ci are the visible and IR weighting
+      factors used in that region.
+    $ref: /schemas/types.yaml#/definitions/uint32-matrix
+    items:
+      minItems: 3
+      maxItems: 3
+
+  rohm,gain-coeff:
+    description:
+      Per-gain sensitivity coefficients. Eight u32 values arranged as four
+      <cl fl> pairs, one pair for each supported gain (1x, 2x, 64x, 128x).
+    $ref: /schemas/types.yaml#/definitions/uint32-array
+    minItems: 8
+    maxItems: 8
+
+required:
+  - compatible
+  - reg
+
+dependencies:
+  rohm,integration-cycle: ['rohm,lux-multiplier']
+  rohm,lux-multiplier: ['rohm,integration-cycle']
+
+additionalProperties: false
+
+examples:
+  - |
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        light-sensor@29 {
+            compatible = "rohm,bh1730fvc";
+            reg = <0x29>;
+            als-vdd-supply = <&vdd_als>;
+            als-vid-supply = <&vid_als>;
+            rohm,integration-cycle = <38>;
+            rohm,lux-multiplier = <1000>;
+            rohm,opt-win-coeff = <260 1290 2733>,
+                                 <550 795 859>,
+                                 <1090 510 345>,
+                                 <2130 276 130>;
+            rohm,gain-coeff = <3000 0xffffffff
+                               2000 9800
+                               15 60000
+                               0 1300>;
+        };
+    };
+
+...

-- 
2.54.0

