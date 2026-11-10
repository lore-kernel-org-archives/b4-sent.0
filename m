From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 10:08:03 +0000
Subject: [PATCH RFC 01/12] dt-bindings: media: Add the Rockchip VEPU580
 video encoder
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-rkvenc-v1-1-ea8b47122d8c@gmail.com>
References: <20261110-rkvenc-v1-0-ea8b47122d8c@gmail.com>
In-Reply-To: <20261110-rkvenc-v1-0-ea8b47122d8c@gmail.com>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Paul Kocialkowski <paulk@sys-base.io>, 
 =?utf-8?q?Sven_P=C3=BCschel?= <s.pueschel@pengutronix.de>, 
 Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Detlev Casanova <detlev.casanova@collabora.com>, 
 Hans Verkuil <hverkuil@kernel.org>, Jiaxing Hu <gahing@gahingwoo.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794305283; l=4162;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=Ts7pMXWf/I5T8ZMd/4JVnE7tMKOGl43GA03EZ8jGtCE=;
 b=slS1xDOmb7x2dV8Ky2vEl4BO6JnpFvJGs8WnFNXv8Ue3qqE3ADlkIEU//HEdSPQ4V/S8GfyUI
 cOlq1p3EPn7DzHGsqpNh9qy+2prvMs8j7jgP9nUz5sTvEKpa6asd/HH
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The VEPU580 (RKVENC) is the H.264/HEVC video encoder of the RK3588. The SoC
has two identical cores at 0xfdbd0000 and 0xfdbe0000, each with its own
clocks, resets, power domain, interrupt and IOMMU.

Describe each core as an independent node. Unlike the vendor kernel, which
groups the cores under software-only "mpp-service" and "ccu" nodes, nothing
in the hardware ties the cores together, so how they are used (one job per
core, or both cores on one stream) is left to the operating system.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 .../bindings/media/rockchip,rk3588-vepu580.yaml    | 93 ++++++++++++++++++++++
 MAINTAINERS                                        |  7 ++
 2 files changed, 100 insertions(+)

diff --git a/Documentation/devicetree/bindings/media/rockchip,rk3588-vepu580.yaml b/Documentation/devicetree/bindings/media/rockchip,rk3588-vepu580.yaml
new file mode 100644
index 000000000000..2b52b17de93d
--- /dev/null
+++ b/Documentation/devicetree/bindings/media/rockchip,rk3588-vepu580.yaml
@@ -0,0 +1,93 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/media/rockchip,rk3588-vepu580.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Rockchip VEPU580 video encoder
+
+maintainers:
+  - Heiko Stuebner <heiko@sntech.de>
+
+description:
+  The VEPU580 (also called RKVENC) is the H.264 and HEVC video encoder of the
+  Rockchip RK3588. The SoC has two identical encoder cores, each with its own
+  clocks, resets, power domain, interrupt and IOMMU. Every core is described
+  by its own node; the operating system may use the cores independently or
+  together.
+
+properties:
+  compatible:
+    const: rockchip,rk3588-vepu580
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    maxItems: 1
+
+  clocks:
+    items:
+      - description: AXI bus clock
+      - description: AHB bus clock
+      - description: Encoder core clock
+
+  clock-names:
+    items:
+      - const: aclk
+      - const: hclk
+      - const: core
+
+  resets:
+    items:
+      - description: AXI bus reset
+      - description: AHB bus reset
+      - description: Encoder core reset
+
+  reset-names:
+    items:
+      - const: aclk
+      - const: hclk
+      - const: core
+
+  power-domains:
+    maxItems: 1
+
+  iommus:
+    maxItems: 1
+
+required:
+  - compatible
+  - reg
+  - interrupts
+  - clocks
+  - clock-names
+  - power-domains
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/clock/rockchip,rk3588-cru.h>
+    #include <dt-bindings/interrupt-controller/arm-gic.h>
+    #include <dt-bindings/power/rk3588-power.h>
+    #include <dt-bindings/reset/rockchip,rk3588-cru.h>
+
+    bus {
+        #address-cells = <2>;
+        #size-cells = <2>;
+
+        video-codec@fdbd0000 {
+            compatible = "rockchip,rk3588-vepu580";
+            reg = <0x0 0xfdbd0000 0x0 0x6000>;
+            interrupts = <GIC_SPI 101 IRQ_TYPE_LEVEL_HIGH 0>;
+            clocks = <&cru ACLK_RKVENC0>, <&cru HCLK_RKVENC0>,
+                     <&cru CLK_RKVENC0_CORE>;
+            clock-names = "aclk", "hclk", "core";
+            resets = <&cru SRST_A_RKVENC0>, <&cru SRST_H_RKVENC0>,
+                     <&cru SRST_RKVENC0_CORE>;
+            reset-names = "aclk", "hclk", "core";
+            power-domains = <&power RK3588_PD_VENC0>;
+            iommus = <&vepu580_0_mmu>;
+        };
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index 93abbb315065..57d899b1229f 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -24322,6 +24322,13 @@ S:	Maintained
 F:	Documentation/devicetree/bindings/sound/rockchip,rk3576-sai.yaml
 F:	sound/soc/rockchip/rockchip_sai.*
 
+ROCKCHIP VEPU580 VIDEO ENCODER DRIVER
+M:	Arun Iyengar <aiyengar1990@gmail.com>
+L:	linux-media@vger.kernel.org
+L:	linux-rockchip@lists.infradead.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/media/rockchip,rk3588-vepu580.yaml
+
 ROCKCHIP XPCS DRIVER
 M:	Coia Prant <coiaprant@gmail.com>
 L:	netdev@vger.kernel.org

-- 
2.55.0

