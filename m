From: Keguang Zhang <keguang.zhang@gmail.com>
Date: Wed, 09 Jul 2025 19:05:52 +0800
Subject: [PATCH v2 1/9] dt-bindings: mips: loongson: Add LS1B demo board
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250709-loongson1-arch-v2-1-bcff6e518c09@gmail.com>
References: <20250709-loongson1-arch-v2-0-bcff6e518c09@gmail.com>
In-Reply-To: <20250709-loongson1-arch-v2-0-bcff6e518c09@gmail.com>
To: Thomas Bogendoerfer <tsbogend@alpha.franken.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jiaxun Yang <jiaxun.yang@flygoat.com>, 
 Keguang Zhang <keguang.zhang@gmail.com>
Cc: linux-mips@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752059245; l=780;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=a0j9vy3+NQEGotdsDECWGxL/pwdxlHQjjCW2egT2QVw=;
 b=Htc3m2YzyEGebXWNYyqRvTq034ikKfHNn+tSyoJTWaTKJbHjs7MsWIWPtbi2Lo29oisdIuMkt
 tpigow9am1nAMj6OkXPOzybf20e2+Lca5MoVEafVtnTjJ92hOWGKotQ
X-Developer-Key: i=keguang.zhang@gmail.com; a=ed25519;
 pk=FMKGj/JgKll/MgClpNZ3frIIogsh5e5r8CeW2mr+WLs=
X-Endpoint-Received: by B4 Relay for keguang.zhang@gmail.com/20231129 with auth_id=102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document loongson,ls1b-demo, a board based on Loongson-1B.

Signed-off-by: Keguang Zhang <keguang.zhang@gmail.com>
---
 Documentation/devicetree/bindings/mips/loongson/devices.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/mips/loongson/devices.yaml b/Documentation/devicetree/bindings/mips/loongson/devices.yaml
index 099e40e1482d..8736eb9fe224 100644
--- a/Documentation/devicetree/bindings/mips/loongson/devices.yaml
+++ b/Documentation/devicetree/bindings/mips/loongson/devices.yaml
@@ -40,6 +40,7 @@ properties:
       - description: LS1B based boards
         items:
           - enum:
+              - loongson,ls1b-demo
               - loongson,lsgz-1b-dev
           - const: loongson,ls1b
 

-- 
2.43.0

