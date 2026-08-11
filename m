From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Tue, 11 Aug 2026 18:31:25 +0800
Subject: [PATCH v10 1/2] dt-bindings: media: add ITE IT6625/IT6626 HDMI
 bridge
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260811-upstream-it6625-it6626-v10-1-9b6bb75262c9@ite.com.tw>
References: <20260811-upstream-it6625-it6626-v10-0-9b6bb75262c9@ite.com.tw>
In-Reply-To: <20260811-upstream-it6625-it6626-v10-0-9b6bb75262c9@ite.com.tw>
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Hermes Wu <Hermes.wu@ite.com.tw>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786444285; l=10595;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=UsmF0hNIAkN5CtGWO2Fk8KHbUh9mjSVIuHJPgrTgjSk=;
 b=cjvUOPKrdo7jbQu2se8nEai1j6TEuD2prizIrjqUMTywGAoD9zb2ChrNOU2rpbv+ieJq49u84
 hSvIZxOjsIMDeLIPBknqpJ3llxT+pKjcMrfAJ+A8i4xI8BAgoaSPtnr
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
Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
---
Changes in v10:
- No code change. The sashiko.dev automated review of v9 re-raised the
  same it6625 bus-type concern yet again -- allowing bus-type = <1>
  (C-PHY) for the "ite,it6625" compatible. Re-dismissed for the same
  reason as v8/v9: Krzysztof Kozlowski explicitly requested dropping
  this constraint since it6625 hardware already implies D-PHY via
  compatible, and nothing has changed since that dismissal.

Changes in v9:
- No code change. The sashiko.dev automated review of v8 re-raised
  restricting port@0/port@1 endpoint bus-type to D-PHY (4) only for
  "ite,it6625" -- the exact constraint dropped in the v7->v8 fold at
  Krzysztof Kozlowski's explicit on-list request ("If the bus-type is
  fixed, why is it in the DT in the first place? Compatible defines it
  already."). Re-adding it would directly contradict that real
  maintainer feedback from the same series, so it's dismissed again,
  not fixed.

Changes in v8:
- Drop the redundant trailing "binding" from the subject -- the
  "dt-bindings:" prefix already says so.
- Use a bare "description:" (no block-scalar indicator) instead of
  "description: |-", matching the dominant in-tree style and
  adi,adv748x.yaml's own multi-line description.
- Drop the bare "clock-noncontinuous: true" / "link-frequencies: true"
  entries under port@0/port@1 endpoints: they add no constraint beyond
  what video-interfaces.yaml already allows via $ref.
- Add the missing blank line between the ports.required block and the
  top-level required list.
- Drop the allOf branch forcing port@0/port@1 endpoint
  bus-type = const 4 for "ite,it6625": that value is already implied
  by compatible, so asserting it again in the schema added nothing.
  The "ite,it6626" branch requiring bus-type is unaffected.
- Document interrupts (optional) and the vcc10-supply/vdd33-supply/
  ovdd-supply power rails (required), and extend the example with
  all three plus the previously-missing port@2 node.
All found by Krzysztof Kozlowski's on-list review of v7.

Changes in v7:
- Add back port@2 for the HDMI input port, reversing the v4 decision
  to drop it. The v6 automated review re-raised the same concern with
  stronger footing than v3's: devicetree describes the physical
  hardware independent of what a given driver consumes, and the chip
  has a physical HDMI input regardless of whether it6625.c wires
  anything to it. Checked against adi,adv7604.yaml, an
  actively-maintained upstream binding for a comparable HDMI-receiver
  chip, which documents its input port(s) the same way via
  graph.yaml's generic port pattern -- concrete precedent that an
  input port unused by the driver still belongs in the schema.
  Verified port@2 stays optional and the schema still validates with
  dt-doc-validate/dt-validate both with and without it present.

Changes in v6:
- Unchanged. The v5 automated review flagged that the it6626
  conditional's `required: [bus-type]` constraint, expressed under
  `properties: { endpoint: {...} }`, doesn't match an `endpoint@N`
  unit-addressed node and could in principle be bypassed. Checked
  against mipi-ccs.yaml, an actively-maintained upstream binding that
  requires bus-type (among other properties) via the exact same
  `properties.endpoint.required` idiom with no patternProperties --
  direct evidence this is accepted convention, not a defect, so no
  fix was made.

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
 .../devicetree/bindings/media/i2c/ite,it6625.yaml  | 175 +++++++++++++++++++++
 1 file changed, 175 insertions(+)

diff --git a/Documentation/devicetree/bindings/media/i2c/ite,it6625.yaml b/Documentation/devicetree/bindings/media/i2c/ite,it6625.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..756fe655f534f85b23b7741d06710c956f9694d8
--- /dev/null
+++ b/Documentation/devicetree/bindings/media/i2c/ite,it6625.yaml
@@ -0,0 +1,175 @@
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
+description:
+  The ITE IT6625 and IT6626 are HDMI to MIPI CSI-2 bridge devices.
+  IT6625 supports an HDMI 2.0 input and converts it to one or two D-PHY CSI
+  outputs, while IT6626 supports an HDMI 2.1 input and converts it to one or
+  two C/D-PHY CSI outputs. The bridges are programmable through I2C and
+  expose two selectable CSI-2 output ports and an HDMI input port. The
+  bridge can operate in split mode or clone mode.
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
+  interrupts:
+    maxItems: 1
+
+  reset-gpios:
+    description:
+      GPIO connected to the active-low reset line.
+    maxItems: 1
+
+  vcc10-supply:
+    description: 1.0V core supply
+
+  vdd33-supply:
+    description: 3.3V supply
+
+  ovdd-supply:
+    description: I/O supply voltage
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
+            required:
+              - data-lanes
+
+      port@2:
+        $ref: /schemas/graph.yaml#/$defs/port-base
+        unevaluatedProperties: false
+        description: HDMI input port
+
+    required:
+      - port@0
+
+required:
+  - compatible
+  - reg
+  - ports
+  - vcc10-supply
+  - vdd33-supply
+  - ovdd-supply
+
+allOf:
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
+    #include <dt-bindings/interrupt-controller/irq.h>
+
+    i2c {
+      #address-cells = <1>;
+      #size-cells = <0>;
+
+      hdmi-bridge@4c {
+        compatible = "ite,it6625";
+        reg = <0x4c>;
+        interrupts = <3 IRQ_TYPE_LEVEL_LOW>;
+
+        reset-gpios = <&gpio 2 GPIO_ACTIVE_LOW>;
+
+        vcc10-supply = <&vcc10_reg>;
+        vdd33-supply = <&vdd33_reg>;
+        ovdd-supply = <&ovdd_reg>;
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
+
+          port@2 {
+            reg = <2>;
+            endpoint {
+              remote-endpoint = <&hdmi_con>;
+            };
+          };
+        };
+      };
+    };

-- 
2.34.1

