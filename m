From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Wed, 22 Jul 2026 17:04:53 +0800
Subject: [PATCH v5 1/2] dt-bindings: media: add ITE IT6625/IT6626 HDMI
 bridge binding
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260722-upstream-it6625-it6626-v5-1-387e7584f2c9@ite.com.tw>
References: <20260722-upstream-it6625-it6626-v5-0-387e7584f2c9@ite.com.tw>
In-Reply-To: <20260722-upstream-it6625-it6626-v5-0-387e7584f2c9@ite.com.tw>
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784711094; l=6978;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=kvmWSJ1bCMezEyl+3kGjHtMHI6toPCQNPCBbtrclasU=;
 b=EMXNbKXFU//AANVF5XYBdiQZaMhSkIIvFdYC10MD8t0iRPIHwKJ/LDf9uDG0QloByzobY1N9f
 VzEbstBUpzSC7PtdoBnhDXGFoe+v5zc23tQAGJQyrwVe2QFKG+s81oU
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the devicetree binding for the ITE IT6625/IT6626 HDMI to
MIPI CSI-2 bridge. The device exposes two graph ports: port@0
(MIPI0) and port@1 (MIPI1), the two selectable CSI-2 D-PHY/C-PHY
outputs. Only port@0 is required, since a board only needs to wire up
as many of the bridge's outputs as it actually uses.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
Changes in v4:
- Drop port@2 (the HDMI connector input graph port) entirely: it
  added no constraints beyond graph.yaml's generic endpoint-base, and
  the driver doesn't use this graph port for anything schema-relevant,
  so there was nothing for a consumer devicetree to usefully validate
  against it. Found by the automated review of v3, which suggested
  adding it to `required` instead -- dropping it entirely was judged
  the better fix since the port carried no real constraints to begin
  with.
- Require bus-type on port@0/port@1 endpoints when compatible contains
  "ite,it6626": the driver defaults to D-PHY when bus-type is omitted,
  which is always correct for it6625 (D-PHY only) but would silently
  misconfigure an it6626 board actually wired for C-PHY. Also found by
  the automated review of v3.

One other v3 review finding was checked and is not being acted on:
- The plain `properties: { endpoint: {...} }` override used for each
  port technically doesn't reach graph.yaml's separate
  `patternProperties` matcher, so an `endpoint@0`-style node could in
  principle bypass the local data-lanes/bus-type constraints. This is
  the same convention already used by other single-endpoint-per-port
  bindings in-tree (e.g. thine,thp7312.yaml), not a defect unique to
  this binding.

Changes in v2:
- Restrict port@0/port@1 endpoint bus-type to D-PHY (4) only when
  compatible is "ite,it6625", via an allOf/if/then constraint. IT6625
  only supports MIPI CSI-2 D-PHY output; the schema previously allowed
  both C-PHY (1) and D-PHY (4) unconditionally, so a devicetree
  claiming "ite,it6625" with bus-type = C-PHY passed schema validation
  despite being invalid on that hardware. IT6626, which supports both
  PHY types, is unaffected. Found by the sashiko.dev automated review
  of v1.
---
 .../devicetree/bindings/media/i2c/ite,it6625.yaml  | 169 +++++++++++++++++++++
 1 file changed, 169 insertions(+)

diff --git a/Documentation/devicetree/bindings/media/i2c/ite,it6625.yaml b/Documentation/devicetree/bindings/media/i2c/ite,it6625.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..fed732e4428ba0098b0a5580cfaf4b704af21a8e
--- /dev/null
+++ b/Documentation/devicetree/bindings/media/i2c/ite,it6625.yaml
@@ -0,0 +1,169 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/media/i2c/ite,it6625.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: ITE IT6625/IT6626 HDMI to dual MIPI CSI-2 bridge
+
+maintainers:
+  - Hermes Wu <Hermes.wu@ite.com.tw>
+
+description: |-
+  The ITE IT6625 and IT6626 are HDMI to MIPI CSI-2 bridge devices.
+  IT6625 supports an HDMI 2.0 input and converts it to one or two D-PHY CSI
+  outputs, while IT6626 supports an HDMI 2.1 input and converts it to one or
+  two C/D-PHY CSI outputs. The bridges are programmable through I2C and
+  expose two selectable CSI-2 output ports. The bridge can operate in
+  split mode or clone mode.
+
+properties:
+  compatible:
+    enum:
+      - ite,it6625
+      - ite,it6626
+
+  reg:
+    maxItems: 1
+
+  reset-gpios:
+    description:
+      GPIO connected to the active-low reset line.
+    maxItems: 1
+
+  ports:
+    $ref: /schemas/graph.yaml#/properties/ports
+    properties:
+      port@0:
+        $ref: /schemas/graph.yaml#/$defs/port-base
+        unevaluatedProperties: false
+        description: CSI-2 output port MIPI0
+
+        properties:
+          endpoint:
+            $ref: /schemas/media/video-interfaces.yaml#
+            unevaluatedProperties: false
+
+            properties:
+              data-lanes:
+                minItems: 1
+                maxItems: 4
+
+              bus-type:
+                enum:
+                  - 1 # MEDIA_BUS_TYPE_CSI2_CPHY
+                  - 4 # MEDIA_BUS_TYPE_CSI2_DPHY
+
+              clock-noncontinuous: true
+              link-frequencies: true
+
+            required:
+              - data-lanes
+
+      port@1:
+        $ref: /schemas/graph.yaml#/$defs/port-base
+        unevaluatedProperties: false
+        description: CSI-2 output port MIPI1
+
+        properties:
+          endpoint:
+            $ref: /schemas/media/video-interfaces.yaml#
+            unevaluatedProperties: false
+
+            properties:
+              data-lanes:
+                minItems: 1
+                maxItems: 4
+
+              bus-type:
+                enum:
+                  - 1 # MEDIA_BUS_TYPE_CSI2_CPHY
+                  - 4 # MEDIA_BUS_TYPE_CSI2_DPHY
+
+              clock-noncontinuous: true
+              link-frequencies: true
+
+            required:
+              - data-lanes
+
+    required:
+      - port@0
+required:
+  - compatible
+  - reg
+  - ports
+
+allOf:
+  - if:
+      properties:
+        compatible:
+          contains:
+            const: ite,it6625
+    then:
+      properties:
+        ports:
+          properties:
+            port@0:
+              properties:
+                endpoint:
+                  properties:
+                    bus-type:
+                      const: 4
+            port@1:
+              properties:
+                endpoint:
+                  properties:
+                    bus-type:
+                      const: 4
+
+  - if:
+      properties:
+        compatible:
+          contains:
+            const: ite,it6626
+    then:
+      properties:
+        ports:
+          properties:
+            port@0:
+              properties:
+                endpoint:
+                  required:
+                    - bus-type
+            port@1:
+              properties:
+                endpoint:
+                  required:
+                    - bus-type
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+
+    i2c {
+      #address-cells = <1>;
+      #size-cells = <0>;
+
+      hdmi-bridge@4c {
+        compatible = "ite,it6625";
+        reg = <0x4c>;
+
+        reset-gpios = <&gpio 2 GPIO_ACTIVE_LOW>;
+
+        ports {
+          #address-cells = <1>;
+          #size-cells = <0>;
+
+          port@0 {
+            reg = <0>;
+            csi_out0: endpoint {
+              remote-endpoint = <&csi2_rx0>;
+              bus-type = <4>; /* MEDIA_BUS_TYPE_CSI2_DPHY */
+              data-lanes = <1 2 3 4>;
+            };
+          };
+        };
+      };
+    };

-- 
2.34.1

