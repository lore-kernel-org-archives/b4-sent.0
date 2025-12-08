From: Yassine Ouaissa <yassine.ouaissa@allegrodvt.com>
Date: Mon, 08 Dec 2025 14:41:22 +0100
Subject: [PATCH v6 2/4] dt-bindings: media: allegro: Add al300 decoder IPs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251208-allegro_dvt_al300_dec_driver-v6-2-2e51ab2e4ce9@allegrodvt.com>
References: <20251208-allegro_dvt_al300_dec_driver-v6-0-2e51ab2e4ce9@allegrodvt.com>
In-Reply-To: <20251208-allegro_dvt_al300_dec_driver-v6-0-2e51ab2e4ce9@allegrodvt.com>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Michael Tretter <m.tretter@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Michal Simek <michal.simek@amd.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Yassine OUAISSA <yassine.ouaissa@allegrodvt.com>, 
 Nicolas Dufresne <nicolas@ndufresne.ca>
Cc: linux-kernel@vger.kernel.org, linux-media@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3244;
 i=yassine.ouaissa@allegrodvt.com; h=from:subject:message-id;
 bh=jzj1ta0KXPH3flJwQD/CD3oKP8EK5pemrsqeprwRzpQ=;
 b=owGbwMvMwCV2oHftXqU9jLMZT6slMWSaXZ1n+emSlGtTsW2OYsfSO2+u7n67qH5WDN+9vxkdK
 uuuKFdN7ShlYRDjYpAVU2T5YLD02Re2Gp8ZLWzzYeawMoEMYeDiFICJ3GZi+GdtqnoqYLen4FaN
 jswi3k0b3uiUfu90XXZs8tsawVNlaeWMDCdljzR1G+yPFPCdm3Ln5adZ7qn3Nh+N1xXgYAk9+Pv
 ASUYA
X-Developer-Key: i=yassine.ouaissa@allegrodvt.com; a=openpgp;
 fpr=B0CE218FC8E89064DAED6179042F935CFB3AD0CC
X-Endpoint-Received: by B4 Relay for yassine.ouaissa@allegrodvt.com/default with auth_id=423
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a schema for the allegro gen3 video decoder.

Acked-by: Conor Dooley <conor.dooley@microchip.com>
Signed-off-by: Yassine Ouaissa <yassine.ouaissa@allegrodvt.com>
---
 .../bindings/media/allegro,al300-vdec.yaml         | 76 ++++++++++++++++++++++
 MAINTAINERS                                        |  2 +
 2 files changed, 78 insertions(+)

diff --git a/Documentation/devicetree/bindings/media/allegro,al300-vdec.yaml b/Documentation/devicetree/bindings/media/allegro,al300-vdec.yaml
new file mode 100644
index 000000000000..12e86c306d55
--- /dev/null
+++ b/Documentation/devicetree/bindings/media/allegro,al300-vdec.yaml
@@ -0,0 +1,76 @@
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
+description:
+  The al300-vdec represents the gen 3 of Allegro DVT IP video
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
+
+  reg-names:
+    items:
+      - const: top
+      - const: apb
+
+  interrupts:
+    maxItems: 1
+
+  clocks:
+    description: MCU core clock
+    maxItems: 1
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
+            reg = <0x00 0xa0120000 0x00 0x10000>, /*VDEC_TOP*/
+                  <0x01 0x80000000 0x00 0x8000>;  /*MCU_APB*/
+            reg-names = "top", "apb";
+            interrupts = <GIC_SPI 96 IRQ_TYPE_LEVEL_HIGH>;
+            clocks = <&mcu_core_clk>;
+            memory-region = <&vdec_mem>;
+            firmware-name = "al300_vdec.fw";
+        };
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index dc56841fa5e5..67dfc2ee1725 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -837,7 +837,9 @@ M:	Michael Tretter <m.tretter@pengutronix.de>
 R:	Pengutronix Kernel Team <kernel@pengutronix.de>
 L:	linux-media@vger.kernel.org
 S:	Maintained
+F:	Documentation/devicetree/bindings/media/allegro,al300-vdec.yaml
 F:	Documentation/devicetree/bindings/media/allegro,al5e.yaml
+F:	drivers/media/platform/allegro-dvt/al300
 F:	drivers/media/platform/allegro-dvt/zynqmp
 
 ALLIED VISION ALVIUM CAMERA DRIVER

-- 
2.50.1

