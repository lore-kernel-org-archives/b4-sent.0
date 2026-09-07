From: Jia Wang <wangjia@ultrarisc.com>
Date: Mon, 07 Sep 2026 17:54:45 +0800
Subject: [PATCH v2 06/10] dt-bindings: i2c: dw: Add compatible for
 UltraRISC DP1000 SoC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260907-ultrarisc-dts-v2-6-5eb4c97477c5@ultrarisc.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788775103; l=1475;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=qmmOpiZIekiFaSTyRs9mX7I+f5uExLbikMi5zvQgBR0=;
 b=MwErmEoUN1yX+JIVBc+ba5Q2dXErRpQto0sss5j0hElQVOqMJXvvTtPalWZh+m4BTBf8Jq3Wl
 ENt8lFxCQsdB9c679906QjzeLeprXsiAtbyMOtMiuyYTnY914Vc6KyM
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=wGVm18siRScehKOkOz0WKxgxDy7IezHEszhnN4/TUCY=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260515 with auth_id=779
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The DP1000 integrates four DesignWare APB I2C controllers. I2C1 supports
SMBus, while I2C0, I2C2, and I2C3 support standard I2C transfers. Each
controller has one register range and uses separate reference and APB
interface clocks.

Add the DP1000-specific compatible string with the generic one as a
fallback.

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
 .../devicetree/bindings/i2c/snps,designware-i2c.yaml      | 15 +++++++++++++++
 1 file changed, 15 insertions(+)

diff --git a/Documentation/devicetree/bindings/i2c/snps,designware-i2c.yaml b/Documentation/devicetree/bindings/i2c/snps,designware-i2c.yaml
index 467bdcbb8538..8a7c0a44601b 100644
--- a/Documentation/devicetree/bindings/i2c/snps,designware-i2c.yaml
+++ b/Documentation/devicetree/bindings/i2c/snps,designware-i2c.yaml
@@ -21,6 +21,20 @@ allOf:
       properties:
         reg:
           maxItems: 1
+  - if:
+      properties:
+        compatible:
+          contains:
+            const: ultrarisc,dp1000-i2c
+    then:
+      properties:
+        clocks:
+          minItems: 2
+        clock-names:
+          minItems: 2
+      required:
+        - clocks
+        - clock-names
 
 properties:
   compatible:
@@ -44,6 +58,7 @@ properties:
               - mscc,ocelot-i2c
               - sophgo,sg2044-i2c
               - thead,th1520-i2c
+              - ultrarisc,dp1000-i2c
           - const: snps,designware-i2c
 
   reg:

-- 
2.34.1

