From: Yassine Ouaissa <yassine.ouaissa@allegrodvt.com>
Date: Thu, 05 Jun 2025 12:26:57 +0000
Subject: [PATCH v2 2/4] dt-bindings: media: allegro-dvt: add decoder
 dt-bindings for Gen3 IP
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250605-allegro_dvt_al300_dec_driver-v2-2-1ef4839f5f06@allegrodvt.com>
References: <20250605-allegro_dvt_al300_dec_driver-v2-0-1ef4839f5f06@allegrodvt.com>
In-Reply-To: <20250605-allegro_dvt_al300_dec_driver-v2-0-1ef4839f5f06@allegrodvt.com>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Michael Tretter <m.tretter@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Michal Simek <michal.simek@amd.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Yassine OUAISSA <yassine.ouaissa@allegrodvt.com>, 
 Nicolas Dufresne <nicolas@ndufresne.ca>
Cc: linux-kernel@vger.kernel.org, linux-media@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4465;
 i=yassine.ouaissa@allegrodvt.com; h=from:subject:message-id;
 bh=gyDJpDMIBTqzfypvbD80Y9BICAPF5u6vCQosYsoMsbw=;
 b=owGbwMvMwCV2oHftXqU9jLMZT6slMWQ49oobrHHl/iGfJWFz6vXtrfNPnnny9khEPovGGpXCI
 I/emfOOdZSyMIhxMciKKbJ8MFj67Atbjc+MFrb5MHNYmUCGMHBxCsBEnA8w/NO7wS323m3ryVxl
 ta74V3E6Ukds/lpusLLeJ1HTPL1/83pGhrNGViHn9/61/iLDXl8X7st05vejAzrvL9d8yBM90CP
 tzQsA
X-Developer-Key: i=yassine.ouaissa@allegrodvt.com; a=openpgp;
 fpr=B0CE218FC8E89064DAED6179042F935CFB3AD0CC
X-Endpoint-Received: by B4 Relay for yassine.ouaissa@allegrodvt.com/default with auth_id=423
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add compatible for video decoder on allegrodvt Gen 3 IP.

v2:
- Change the YAML file name, use the existing vendor-prefix.
- Improuve the dt-bindings description.
- Change the device compatible identifier, from "allegrodvt, al300-vdec",
  to "allegro, al300-vdec"
- Simplify the register property specification,
  by using the simple min/max items constraint (Krzysztof Kozlowski)
- Remove the clock-names property. And remove it from the required
  properties list (Krzysztof Kozlowski) (Conor Dooley)
- Use the simple maxItems constraint for the memory-region property.
  Also for the firmware-name (Krzysztof Kozlowski)
- Example changes:
  - Use header provides definitions for the interrupts (Conor Dooley)
  - Improuve Interrupt specification using GIC constants (Conor Dooley)
  - Use generic node name "video-decoder" (Krzysztof Kozlowski) (Conor Dooley)
  - Remove unused label (Krzysztof Kozlowski)
  - Change clock reference from <&mcu_clock_dec> to <&mcu_core_clk>
  - Use hex format for reg property (Krzysztof Kozlowski) (Conor Dooley)
  - Reduce memory region size (Krzysztof Kozlowski) (Conor Dooley)

  - Link v1: https://patchwork.linuxtv.org/project/linux-media/patch/20250511144752.504162-4-yassine.ouaissa@allegrodvt.com/

Signed-off-by: Yassine Ouaissa <yassine.ouaissa@allegrodvt.com>
---
 .../bindings/media/allegro,al300-vdec.yaml         | 75 ++++++++++++++++++++++
 MAINTAINERS                                        |  2 +
 2 files changed, 77 insertions(+)

diff --git a/Documentation/devicetree/bindings/media/allegro,al300-vdec.yaml b/Documentation/devicetree/bindings/media/allegro,al300-vdec.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..26f9ac39682431b1d4828aed5d1ed43ef099e204
--- /dev/null
+++ b/Documentation/devicetree/bindings/media/allegro,al300-vdec.yaml
@@ -0,0 +1,75 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/media/allegro,al300-vdec.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Allegro DVT Video IP Decoder Gen 3
+
+maintainers:
+  - Yassine OUAISSA <yassine.ouaissa@allegrodvt.com>
+
+description: The al300-vdec represents the gen 3 of Allegro DVT IP video
+  decoding technology, offering significant advancements over its
+  predecessors. This new decoder features enhanced processing capabilities
+  with improved throughput and reduced latency.
+
+  Communication between the host driver software and the MCU is implemented
+  through a specialized mailbox interface mechanism. This mailbox system
+  provides a structured channel for exchanging commands, parameters, and
+  status information between the host CPU and the MCU controlling the codec
+  engines.
+
+properties:
+  compatible:
+    const: allegro,al300-vdec
+
+  reg:
+    maxItems: 2
+    minItems: 2
+
+  reg-names:
+    items:
+      - const: regs
+      - const: apb
+
+  interrupts:
+    maxItems: 1
+
+  clocks:
+    items:
+      - description: MCU core clock
+
+  memory-region:
+    maxItems: 1
+
+  firmware-name:
+    maxItems: 1
+
+required:
+  - compatible
+  - reg
+  - reg-names
+  - interrupts
+  - clocks
+
+additionalProperties: False
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/arm-gic.h>
+
+    axi {
+        #address-cells = <2>;
+        #size-cells = <2>;
+
+        video-decoder@a0120000 {
+            compatible = "allegro,al300-vdec";
+            reg = <0x00 0xa0120000 0x00 0x10000>,
+                  <0x01 0x80000000 0x00 0x8000>;
+            reg-names = "regs", "apb";
+            interrupts = <GIC_SPI 96 IRQ_TYPE_LEVEL_HIGH>;
+            clocks = <&mcu_core_clk>;
+            firmware-name = "al300_vdec.fw";
+        };
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index abc6ba61048771303bc219102f2db602266b7c30..1ff78b9a76cb8cdf32263fcd9b4579b4a2bb6b2a 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -816,7 +816,9 @@ M:	Michael Tretter <m.tretter@pengutronix.de>
 R:	Pengutronix Kernel Team <kernel@pengutronix.de>
 L:	linux-media@vger.kernel.org
 S:	Maintained
+F:	Documentation/devicetree/bindings/media/allegro,al300-vdec.yaml
 F:	Documentation/devicetree/bindings/media/allegro,al5e.yaml
+F:	drivers/media/platform/allegro-dvt/al300
 F:	drivers/media/platform/allegro-dvt/zynqmp
 
 ALLIED VISION ALVIUM CAMERA DRIVER

-- 
2.30.2

