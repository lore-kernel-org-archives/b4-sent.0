From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 28 Nov 2026 08:30:07 +0000
Subject: [PATCH v6 1/4] media: dt-bindings: Add Rockchip IEP2 deinterlacer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-iep2-v6-1-5f4f10a0dbeb@gmail.com>
References: <20261128-iep2-v6-0-5f4f10a0dbeb@gmail.com>
In-Reply-To: <20261128-iep2-v6-0-5f4f10a0dbeb@gmail.com>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-rockchip@lists.infradead.org, linux-media@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, iommu@lists.linux.dev, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Alex Bee <knaerzche@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795854607; l=3925;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=Qe6wQ4E2xaAvete4oI5amRHE0suyCMaOjV61Q0hB68c=;
 b=R8Jlkn+pG6lnsUuFgrxt72FQ8NNeHUoGdnvC7byeX6Zpl2SHd7gpbvgjWypyQuJ+Oq4y376sG
 Ga1vybXpWVMBt8WdCz31mXiHhq07/0IDUCbiw+pJapQ2gBFjHojBYk6
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a binding for the IEP2 deinterlacer of the RK3568 and RK3588 SoCs.
It is a different block from the IEP of RK3228/RK3288/RK3328/RK3399,
hence "iep2". The RK3588 block falls back to the RK3568 compatible.

Clock and reset names follow the RGA binding. The resets are optional:
the block has its own soft reset.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 .../bindings/media/rockchip,rk3568-iep2.yaml       | 95 ++++++++++++++++++++++
 MAINTAINERS                                        |  6 ++
 2 files changed, 101 insertions(+)

diff --git a/Documentation/devicetree/bindings/media/rockchip,rk3568-iep2.yaml b/Documentation/devicetree/bindings/media/rockchip,rk3568-iep2.yaml
new file mode 100644
index 000000000000..834282ef99a0
--- /dev/null
+++ b/Documentation/devicetree/bindings/media/rockchip,rk3568-iep2.yaml
@@ -0,0 +1,95 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/media/rockchip,rk3568-iep2.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Rockchip IEP2 image enhancement processor
+
+maintainers:
+  - Arun Iyengar <aiyengar1990@gmail.com>
+
+description:
+  Memory to memory video deinterlacer of the Rockchip RK3568 and RK3588
+  SoCs. It has its own IOMMU, with which it shares its interrupt line.
+
+properties:
+  compatible:
+    oneOf:
+      - const: rockchip,rk3568-iep2
+      - items:
+          - const: rockchip,rk3588-iep2
+          - const: rockchip,rk3568-iep2
+
+  reg:
+    maxItems: 1
+
+  clocks:
+    items:
+      - description: AXI bus clock
+      - description: AHB bus clock
+      - description: Core clock
+
+  clock-names:
+    items:
+      - const: aclk
+      - const: hclk
+      - const: sclk
+
+  interrupts:
+    maxItems: 1
+
+  resets:
+    items:
+      - description: AXI reset
+      - description: AHB reset
+      - description: Core reset
+
+  reset-names:
+    items:
+      - const: axi
+      - const: ahb
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
+  - clocks
+  - clock-names
+  - interrupts
+  - power-domains
+  - iommus
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
+      #address-cells = <2>;
+      #size-cells = <2>;
+
+      deinterlace@fdbb0000 {
+        compatible = "rockchip,rk3588-iep2", "rockchip,rk3568-iep2";
+        reg = <0x0 0xfdbb0000 0x0 0x500>;
+        clocks = <&cru ACLK_IEP2P0>, <&cru HCLK_IEP2P0>,
+                 <&cru CLK_IEP2P0_CORE>;
+        clock-names = "aclk", "hclk", "sclk";
+        interrupts = <GIC_SPI 117 IRQ_TYPE_LEVEL_HIGH>;
+        resets = <&cru SRST_A_IEP2P0>, <&cru SRST_H_IEP2P0>,
+                 <&cru SRST_IEP2P0_CORE>;
+        reset-names = "axi", "ahb", "core";
+        power-domains = <&power RK3588_PD_VDPU>;
+        iommus = <&iep_mmu>;
+      };
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index f72ce07a4e38..90ec701edce6 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -24285,6 +24285,12 @@ S:	Maintained
 F:	Documentation/devicetree/bindings/sound/rockchip,i2s-tdm.yaml
 F:	sound/soc/rockchip/rockchip_i2s_tdm.*
 
+ROCKCHIP IEP2 DEINTERLACER DRIVER
+M:	Arun Iyengar <aiyengar1990@gmail.com>
+L:	linux-rockchip@lists.infradead.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/media/rockchip,rk3568-iep2.yaml
+
 ROCKCHIP ISP V1 DRIVER
 M:	Dafna Hirschfeld <dafna@fastmail.com>
 M:	Laurent Pinchart <laurent.pinchart@ideasonboard.com>

-- 
2.55.0

