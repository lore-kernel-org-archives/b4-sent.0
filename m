From: Esteban Urrutia <esteuwu@proton.me>
Date: Wed, 29 Jul 2026 02:03:14 -0400
Subject: [PATCH v2 1/2] dt-bindings: usb: Add Parade PS5169 redriver
 bindings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260729-ps5169-bup-v2-1-203b0a49881a@proton.me>
References: <20260729-ps5169-bup-v2-0-203b0a49881a@proton.me>
In-Reply-To: <20260729-ps5169-bup-v2-0-203b0a49881a@proton.me>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785304993; l=5883;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=0S6UXUorUMbLlKLnEsHGa9utbX+f+ELHzb5JHwii9qs=;
 b=tVEWCcPh1m28amUH5krTe0yTg3MnS7Rndp5hFs4WVNuS2TfqE2lcykehSOVO3THllpOMpC29t
 Rgn2o5E4niwCRJw28Yl0CFSoHrsL7wxvtAZazIqWQWbRtOz31tiyj2E
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add bindings for the Parade PS5169 and PS5170 USB Type-C linear redrivers.
The difference between PS5169 and PS5170 is that PS5170 features an
embedded AUX switch, while PS5169 does not.
Future-proof the binding by adding PS5170 as well.

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
 .../devicetree/bindings/usb/parade,ps5169.yaml     | 191 +++++++++++++++++++++
 1 file changed, 191 insertions(+)

diff --git a/Documentation/devicetree/bindings/usb/parade,ps5169.yaml b/Documentation/devicetree/bindings/usb/parade,ps5169.yaml
new file mode 100644
index 000000000000..86ea2351ee1e
--- /dev/null
+++ b/Documentation/devicetree/bindings/usb/parade,ps5169.yaml
@@ -0,0 +1,191 @@
+# SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/usb/parade,ps5169.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Parade PS5169 USB Type-C linear redriver
+
+maintainers:
+  - Esteban Urrutia <esteuwu@proton.me>
+
+properties:
+  compatible:
+    oneOf:
+      - items:
+          - const: parade,ps5170
+          - const: parade,ps5169
+      - const: parade,ps5169
+
+  reg:
+    maxItems: 1
+
+  vcc-supply:
+    description: 1.8V power supply
+
+  reset-gpios:
+    maxItems: 1
+
+  orientation-switch: true
+  retimer-switch: true
+
+  parade,dp-eq-level:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    description:
+      Equalization level for DisplayPort channels which is mapped to decibels.
+    # 0: 2    dB
+    # 1: 5.5  dB
+    # 2: 6.5  dB
+    # 3: 7.5  dB
+    # 4: 8    dB
+    # 5: 8.5  dB
+    # 6: 9.5  dB
+    # 7: 10   dB
+    enum: [ 0, 1, 2, 3, 4, 5, 6, 7 ]
+
+  parade,usb-rx-eq-level:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    description:
+      Equalization level for USB receive channels which is mapped to decibels.
+    # 0: 5.2  dB
+    # 1: 6    dB
+    # 2: 7    dB
+    # 3: 8    dB
+    # 4: 8.8  dB
+    # 5: 9.6  dB
+    # 6: 10.4 dB
+    # 7: 11.2 dB
+    enum: [ 0, 1, 2, 3, 4, 5, 6, 7 ]
+
+  parade,usb-tx-eq-level:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    description:
+      Equalization level for USB transmit channels which is mapped to decibels.
+    # 0: 2    dB
+    # 1: 5.5  dB
+    # 2: 6.5  dB
+    # 3: 7.5  dB
+    # 4: 8    dB
+    # 5: 8.5  dB
+    # 6: 9.5  dB
+    # 7: 10   dB
+    enum: [ 0, 1, 2, 3, 4, 5, 6, 7 ]
+
+  parade,aux-rx-data-reverse:
+    type: boolean
+    description:
+      Please check the driver before specifying this property.
+      Usage of this property is design-specific.
+
+  parade,fine-tune-lfps-swing:
+    type: boolean
+    description:
+      If this property is specified a 50 ohm termination will be set on the USB receive channels.
+      Usage of this property is design-specific.
+
+  parade,dp-set-gain:
+    type: boolean
+    description:
+      If this property is specified a gain of -0.9 dB will be applied on the DisplayPort channels.
+
+  parade,usb-rx-set-gain:
+    type: boolean
+    description:
+      If this property is specified a gain of -0.9 dB will be applied on the USB receive channels.
+
+  parade,usb-tx-set-gain:
+    type: boolean
+    description:
+      If this property is specified a gain of -0.9 dB will be applied on the USB transmit channels.
+
+  ports:
+    $ref: /schemas/graph.yaml#/properties/ports
+    properties:
+      port@0:
+        $ref: /schemas/graph.yaml#/properties/port
+        description: Super Speed (SS) Output endpoint to the Type-C connector
+
+      port@1:
+        $ref: /schemas/graph.yaml#/$defs/port-base
+        description: Super Speed (SS) Input endpoint from the Super-Speed PHY
+        unevaluatedProperties: false
+
+required:
+  - compatible
+  - reg
+  - vcc-supply
+  - reset-gpios
+  - orientation-switch
+  - retimer-switch
+
+allOf:
+  - $ref: usb-switch.yaml#
+  - $ref: usb-switch-ports.yaml#
+  - if:
+      properties:
+        compatible:
+          contains:
+            const: parade,ps5170
+    then:
+      properties:
+        ports:
+          properties:
+            port@2:
+              $ref: /schemas/graph.yaml#/properties/port
+              description:
+                Sideband Use (SBU) AUX lines endpoint to the Type-C connector for the purpose of
+                handling altmode muxing and orientation switching.
+    else:
+      properties:
+        ports:
+          properties:
+            port@2: false
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        typec-retimer@30 {
+            compatible = "parade,ps5169";
+            reg = <0x30>;
+
+            vcc-supply = <&vreg_s10b_1p8>;
+            reset-gpios = <&tlmm 54 GPIO_ACTIVE_LOW>;
+
+            orientation-switch;
+            retimer-switch;
+
+            parade,dp-eq-level = <0>;     /* 2   dB */
+            parade,usb-rx-eq-level = <0>; /* 5.2 dB */
+            parade,usb-tx-eq-level = <0>; /* 2   dB */
+
+            parade,aux-rx-data-reverse;
+            parade,fine-tune-lfps-swing;
+
+            ports {
+                #address-cells = <1>;
+                #size-cells = <0>;
+
+                port@0 {
+                    reg = <0>;
+                    usb_con_ss: endpoint {
+                        remote-endpoint = <&typec_con_ss>;
+                    };
+                };
+
+                port@1 {
+                    reg = <1>;
+                    phy_con_ss: endpoint {
+                        remote-endpoint = <&usb_phy_ss>;
+                    };
+                };
+            };
+        };
+    };
+...

-- 
2.55.0

