From: Jia Wang <wangjia@ultrarisc.com>
Date: Mon, 07 Sep 2026 17:54:46 +0800
Subject: [PATCH v2 07/10] dt-bindings: dma: snps,dw-axi-dmac: Add UltraRISC
 DP1000 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260907-ultrarisc-dts-v2-7-5eb4c97477c5@ultrarisc.com>
References: <20260907-ultrarisc-dts-v2-0-5eb4c97477c5@ultrarisc.com>
In-Reply-To: <20260907-ultrarisc-dts-v2-0-5eb4c97477c5@ultrarisc.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Jia Wang <wangjia@ultrarisc.com>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Thomas Gleixner <tglx@kernel.org>, 
 Samuel Holland <samuel.holland@sifive.com>, 
 Anup Patel <anup@brainfault.org>, Mark Brown <broonie@kernel.org>, 
 Andi Shyti <andi.shyti@kernel.org>, 
 Mika Westerberg <mika.westerberg@linux.intel.com>, 
 Eugeniy Paltsev <Eugeniy.Paltsev@synopsys.com>, 
 Vinod Koul <vkoul@kernel.org>, Frank Li <Frank.Li@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@sifive.com>, Conor Dooley <conor@kernel.org>, 
 linux-riscv@lists.infradead.org, linux-spi@vger.kernel.org, 
 linux-i2c@vger.kernel.org, dmaengine@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788775103; l=1419;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=ENFwCaDg2Es24T1JPD8nJSb6K6VohaYxMboKPZolvgI=;
 b=MyRA9jGZrwxWJ4/f/ssvZI6lzGtLrFdRbrj04uuCN0+jhnwxhnZs36ZCQyo03NHkrgeKwTgY7
 meq5UYXIU1ZARPkIWze/XzKIuDOOQniuZ47xHauQ0/IYsaJTuP473O7
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=wGVm18siRScehKOkOz0WKxgxDy7IezHEszhnN4/TUCY=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260515 with auth_id=779
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The DP1000 integrates a DMA controller.

Add its SoC-specific compatible with the generic fallback.

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
 .../devicetree/bindings/dma/snps,dw-axi-dmac.yaml  | 22 ++++++++++++++++++++++
 1 file changed, 22 insertions(+)

diff --git a/Documentation/devicetree/bindings/dma/snps,dw-axi-dmac.yaml b/Documentation/devicetree/bindings/dma/snps,dw-axi-dmac.yaml
index 0a30a455b0ee..bfd6d67a98e6 100644
--- a/Documentation/devicetree/bindings/dma/snps,dw-axi-dmac.yaml
+++ b/Documentation/devicetree/bindings/dma/snps,dw-axi-dmac.yaml
@@ -14,6 +14,27 @@ description:
 
 allOf:
   - $ref: dma-controller.yaml#
+  - if:
+      properties:
+        compatible:
+          contains:
+            const: ultrarisc,dp1000-axi-dma
+    then:
+      properties:
+        reg:
+          maxItems: 1
+        interrupts:
+          minItems: 8
+        dma-channels:
+          const: 8
+        snps,dma-masters:
+          const: 1
+        snps,data-width:
+          const: 4
+        snps,priority:
+          minItems: 8
+        snps,block-size:
+          minItems: 8
 
 properties:
   compatible:
@@ -27,6 +48,7 @@ properties:
           - enum:
               - altr,agilex5-axi-dma
               - sophgo,cv1800b-axi-dma
+              - ultrarisc,dp1000-axi-dma
           - const: snps,axi-dma-1.01a
 
   reg:

-- 
2.34.1

