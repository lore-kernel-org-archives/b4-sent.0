From: Zhentao Guo <zhentao.guo@amlogic.com>
Date: Mon, 31 Aug 2026 16:32:04 +0800
Subject: [PATCH v8 3/6] media: dt-bindings: Add Amlogic V4L2 video decoder
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260831-b4-s4-vdec-upstream-v8-3-830195b9bd91@amlogic.com>
References: <20260831-b4-s4-vdec-upstream-v8-0-830195b9bd91@amlogic.com>
In-Reply-To: <20260831-b4-s4-vdec-upstream-v8-0-830195b9bd91@amlogic.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-media@vger.kernel.org, 
 devicetree@vger.kernel.org, Zhentao Guo <zhentao.guo@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788165132; l=3483;
 i=zhentao.guo@amlogic.com; s=20251024; h=from:subject:message-id;
 bh=ulRIFePdp9aejiMT2s8F2+Ow8Q3VDBAIg+orPFx2ohY=;
 b=mDdgapk1uYA1ln/mZ7NZk5bP9DNpZBgRlWlW2w7up1Fy+dqMTCOC8tw/3L0tLWDmcr8hmo3wS
 qRKisrRIJcwCY2EjxHEOQG7NGXotDOfaFgCekV6JPy+kcjLFHj2ziGl
X-Developer-Key: i=zhentao.guo@amlogic.com; a=ed25519;
 pk=5yfDKrjreXwcAoEUsdtWafy6YN500upXp/CgtnXjLVU=
X-Endpoint-Received: by B4 Relay for zhentao.guo@amlogic.com/20251024 with auth_id=555
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the initial support for the V4L2 stateless video decoder
driver used with the Amlogic S4 (S805X2) platform.

Signed-off-by: Zhentao Guo <zhentao.guo@amlogic.com>
---
 .../devicetree/bindings/media/amlogic,s4-vdec.yaml | 106 +++++++++++++++++++++
 1 file changed, 106 insertions(+)

diff --git a/Documentation/devicetree/bindings/media/amlogic,s4-vdec.yaml b/Documentation/devicetree/bindings/media/amlogic,s4-vdec.yaml
new file mode 100644
index 000000000000..a93a2140801b
--- /dev/null
+++ b/Documentation/devicetree/bindings/media/amlogic,s4-vdec.yaml
@@ -0,0 +1,106 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+# Copyright (C) 2025 Amlogic, Inc. All rights reserved
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/media/amlogic,s4-vdec.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Amlogic Video Decode Accelerator
+
+maintainers:
+  - Zhentao Guo <zhentao.guo@amlogic.com>
+
+description:
+  The Video Decoder Accelerator present on Amlogic SOCs.
+  It supports stateless h264 decoding.
+
+properties:
+  compatible:
+    const: amlogic,s4-vdec
+
+  reg:
+    maxItems: 2
+
+  reg-names:
+    items:
+      - const: dos
+      - const: dmc
+
+  interrupts:
+    maxItems: 2
+
+  clocks:
+    maxItems: 3
+
+  clock-names:
+    items:
+      - const: dos
+      - const: core_vdec
+      - const: core_hvdec
+
+  power-domains:
+    maxItems: 2
+
+  power-domain-names:
+    items:
+      - const: dos_vdec
+      - const: dos_hvdec
+
+  resets:
+    maxItems: 1
+
+  amlogic,canvas:
+    description: Canvas maintains an index-to-physical-address
+     mapping table that allows the 16-bit AMRISC decoder core
+     to access 32-bit or 64-bit physical address.
+    $ref: /schemas/types.yaml#/definitions/phandle
+
+  amlogic,secure-monitor:
+    description: Used to decrypt and load the signed decoder
+     firmware through ARM SMC (Secure Monitor Call).
+    $ref: /schemas/types.yaml#/definitions/phandle
+
+required:
+  - compatible
+  - reg
+  - reg-names
+  - interrupts
+  - clocks
+  - clock-names
+  - power-domains
+  - power-domain-names
+  - resets
+  - amlogic,canvas
+  - amlogic,secure-monitor
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/arm-gic.h>
+    #include <dt-bindings/clock/amlogic,s4-pll-clkc.h>
+    #include <dt-bindings/clock/amlogic,s4-peripherals-clkc.h>
+    #include <dt-bindings/power/meson-s4-power.h>
+    #include <dt-bindings/reset/amlogic,meson-s4-reset.h>
+    video-codec@fe320000 {
+      compatible = "amlogic,s4-vdec";
+      reg = <0xfe320000 0x10000>,
+            <0xfe036000 0x20>;
+      reg-names = "dos",
+                  "dmc";
+      interrupts = <GIC_SPI 91 IRQ_TYPE_EDGE_RISING>,
+                   <GIC_SPI 92 IRQ_TYPE_EDGE_RISING>;
+      clocks = <&clkc_periphs CLKID_DOS>,
+               <&clkc_periphs CLKID_VDEC_SEL>,
+               <&clkc_periphs CLKID_HEVCF_SEL>;
+      clock-names = "dos",
+                    "core_vdec",
+                    "core_hvdec";
+      power-domains = <&pwrc PWRC_S4_DOS_VDEC_ID>,
+                      <&pwrc PWRC_S4_DOS_HEVC_ID>;
+      power-domain-names = "dos_vdec",
+                           "dos_hvdec";
+      resets = <&reset RESET_DOS>;
+      amlogic,canvas = <&canvas>;
+      amlogic,secure-monitor = <&sm>;
+    };

-- 
2.42.0

