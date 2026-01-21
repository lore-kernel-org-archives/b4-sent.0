From: Zhentao Guo <zhentao.guo@amlogic.com>
Date: Wed, 21 Jan 2026 18:30:39 +0800
Subject: [PATCH RFC v3 1/4] media: dt-bindings: Add Amlogic V4L2 video
 decoder
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260121-b4-s4-vdec-upstream-v3-1-4496aec3d79e@amlogic.com>
References: <20260121-b4-s4-vdec-upstream-v3-0-4496aec3d79e@amlogic.com>
In-Reply-To: <20260121-b4-s4-vdec-upstream-v3-0-4496aec3d79e@amlogic.com>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, Zhentao Guo <zhentao.guo@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768991475; l=3141;
 i=zhentao.guo@amlogic.com; s=20251024; h=from:subject:message-id;
 bh=+ALt9bgLT6yjuZPZxCh4y6nzKx5uZews8JNjwnFmwig=;
 b=eWVMe/Lg1HvciLUweUC9ZzVRriH1aor5JXrry2U3NCFMCjoAd97FgcXUj0fejSMt/NL5lf7io
 /lao5ud3NHKA7y+W1krJe7djQUlcxM5c7JuN/jn4/jYc7HDrgp3fey0
X-Developer-Key: i=zhentao.guo@amlogic.com; a=ed25519;
 pk=5yfDKrjreXwcAoEUsdtWafy6YN500upXp/CgtnXjLVU=
X-Endpoint-Received: by B4 Relay for zhentao.guo@amlogic.com/20251024 with auth_id=555
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the initial support for the V4L2 stateless video decoder
driver used with the Amlogic S4 (S805X2) platform.

Signed-off-by: Zhentao Guo <zhentao.guo@amlogic.com>
---
 .../bindings/media/amlogic,s4-vcodec-dec.yaml      | 96 ++++++++++++++++++++++
 1 file changed, 96 insertions(+)

diff --git a/Documentation/devicetree/bindings/media/amlogic,s4-vcodec-dec.yaml b/Documentation/devicetree/bindings/media/amlogic,s4-vcodec-dec.yaml
new file mode 100644
index 000000000000..88780514d06c
--- /dev/null
+++ b/Documentation/devicetree/bindings/media/amlogic,s4-vcodec-dec.yaml
@@ -0,0 +1,96 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+# Copyright (C) 2025 Amlogic, Inc. All rights reserved
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/media/amlogic,s4-vcodec-dec.yaml#
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
+    const: amlogic,s4-vcodec-dec
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
+    maxItems: 3
+
+  clocks:
+    maxItems: 3
+
+  clock-names:
+    items:
+      - const: vdec
+      - const: clk_vdec_mux
+      - const: clk_hevcf_mux
+
+  power-domains:
+    maxItems: 2
+
+  power-domain-names:
+    items:
+      - const: vdec
+      - const: hevc
+
+  resets:
+    maxItems: 1
+
+  amlogic,canvas:
+    description: should point to a canvas provider node
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
+      compatible = "amlogic,s4-vcodec-dec";
+      reg = <0xfe320000 0x10000>,
+            <0xfe036000 0x20>;
+      amlogic,canvas = <&canvas>;
+      reg-names = "dos",
+                  "dmc";
+      interrupts = <GIC_SPI 91 IRQ_TYPE_EDGE_RISING>,
+                   <GIC_SPI 92 IRQ_TYPE_EDGE_RISING>,
+                   <GIC_SPI 93 IRQ_TYPE_EDGE_RISING>;
+      clocks = <&clkc_periphs CLKID_DOS>,
+               <&clkc_periphs CLKID_VDEC_SEL>,
+               <&clkc_periphs CLKID_HEVCF_SEL>;
+      clock-names = "vdec",
+                    "clk_vdec_mux",
+                    "clk_hevcf_mux";
+      power-domains = <&pwrc PWRC_S4_DOS_VDEC_ID>,
+                      <&pwrc PWRC_S4_DOS_HEVC_ID>;
+      power-domain-names = "vdec",
+                           "hevc";
+      resets = <&reset RESET_DOS>;
+    };

-- 
2.42.0

