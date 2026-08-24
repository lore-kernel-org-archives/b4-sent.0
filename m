From: Jia Wang <wangjia@ultrarisc.com>
Date: Mon, 24 Aug 2026 13:54:14 +0800
Subject: [PATCH 01/12] dt-bindings: riscv: cpus: Fix yamllint style issues
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260824-ultrarisc-dts-v1-1-61ab7aebe9e5@ultrarisc.com>
References: <20260824-ultrarisc-dts-v1-0-61ab7aebe9e5@ultrarisc.com>
In-Reply-To: <20260824-ultrarisc-dts-v1-0-61ab7aebe9e5@ultrarisc.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Thomas Gleixner <tglx@kernel.org>, 
 Samuel Holland <samuel.holland@sifive.com>, 
 Anup Patel <anup@brainfault.org>, Mark Brown <broonie@kernel.org>, 
 Andi Shyti <andi.shyti@kernel.org>, 
 Mika Westerberg <mika.westerberg@linux.intel.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Giuseppe Cavallaro <peppe.cavallaro@st.com>, 
 Jose Abreu <joabreu@synopsys.com>, 
 Eugeniy Paltsev <Eugeniy.Paltsev@synopsys.com>, 
 Vinod Koul <vkoul@kernel.org>, Frank Li <Frank.Li@kernel.org>
Cc: Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@sifive.com>, Conor Dooley <conor@kernel.org>, 
 devicetree@vger.kernel.org, linux-riscv@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-spi@vger.kernel.org, 
 linux-i2c@vger.kernel.org, netdev@vger.kernel.org, 
 dmaengine@vger.kernel.org, Jia Wang <wangjia@ultrarisc.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787552108; l=1425;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=Q697DFC7ysJh9zCppPk9O+0gvj0yAIUmzUczo/IHMyc=;
 b=or1xxNfTcnovPzCMzApsOwWbacOhxI/q+gccq7qhyvzRWq2X2lx0MS3b8g6Wxi5KIU0117ZLQ
 IUn00ulNlwjCPLJm5EosC9d3iWABnhGYcGZ3B6wMnXld66Os6azzRvh
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=wGVm18siRScehKOkOz0WKxgxDy7IezHEszhnN4/TUCY=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260515 with auth_id=779
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Wrap an overlong description line and normalize the inline dependency
lists to satisfy yamllint.

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
 Documentation/devicetree/bindings/riscv/cpus.yaml | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/Documentation/devicetree/bindings/riscv/cpus.yaml b/Documentation/devicetree/bindings/riscv/cpus.yaml
index 5feeb2203050..0da219ae6769 100644
--- a/Documentation/devicetree/bindings/riscv/cpus.yaml
+++ b/Documentation/devicetree/bindings/riscv/cpus.yaml
@@ -117,8 +117,8 @@ properties:
     $ref: /schemas/types.yaml#/definitions/uint32
     description:
       VLEN/8, the vector register length in bytes. This property is required on
-      thead systems where the vector register length is not identical on all harts, or
-      the vlenb CSR is not available.
+      thead systems where the vector register length is not identical on all
+      harts, or the vlenb CSR is not available.
 
   # RISC-V has multiple properties for cache op block sizes as the sizes
   # differ between individual CBO extensions
@@ -151,8 +151,8 @@ anyOf:
       - riscv,isa-base
 
 dependencies:
-  riscv,isa-base: [ "riscv,isa-extensions" ]
-  riscv,isa-extensions: [ "riscv,isa-base" ]
+  riscv,isa-base: ["riscv,isa-extensions"]
+  riscv,isa-extensions: ["riscv,isa-base"]
 
 required:
   - interrupt-controller

-- 
2.34.1

