From: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Date: Tue, 03 Nov 2026 16:11:28 +0100
Subject: [PATCH v2 4/8] dt-bindings: interrupt-controller: Add MIPS P8700
 APLIC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-p8700-dts-v2-4-3ac5d49f2c37@htecgroup.com>
References: <20261103-p8700-dts-v2-0-3ac5d49f2c37@htecgroup.com>
In-Reply-To: <20261103-p8700-dts-v2-0-3ac5d49f2c37@htecgroup.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, 
 Djordje Todorovic <djordje.todorovic@htecgroup.com>, 
 Anup Patel <anup@brainfault.org>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Inochi Amaoto <inochiama@outlook.com>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Conor Dooley <conor@kernel.org>, linux-riscv@lists.infradead.org, 
 Vladimir Kondratiev <vladimir.kondratiev@mobileye.com>, 
 Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@sifive.com>, 
 Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793718695; l=863;
 i=aleksa.paunovic@htecgroup.com; s=20250806; h=from:subject:message-id;
 bh=2lms0SOqaM4I4/vPB5czylxQz+VKnxBbKrzIdfMCocU=;
 b=kKWd8oBLvuphCeyGao17aOm0k1IHXVSc98UPtxe8GOpg5lvESDYnzC9TDjZCer1pYVuBzLQ7Y
 15A+fqIXnCgAyNjFLYN5oRyDBhjjp900w241SoPz6asxkXeAocqYKwC
X-Developer-Key: i=aleksa.paunovic@htecgroup.com; a=ed25519;
 pk=Dn4KMnDdgyhlXJNspQQrlHJ04i7/irG29p2H27Avd+8=
X-Endpoint-Received: by B4 Relay for aleksa.paunovic@htecgroup.com/20250806 with auth_id=476
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the aplic compatible for the MIPS P8700.

Signed-off-by: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
---
 Documentation/devicetree/bindings/interrupt-controller/riscv,aplic.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/interrupt-controller/riscv,aplic.yaml b/Documentation/devicetree/bindings/interrupt-controller/riscv,aplic.yaml
index 0718071444d29fbfa36283fc9666e8cecd6f77e7..9b986aa1a1c62316a1fd08fe535075111601b80e 100644
--- a/Documentation/devicetree/bindings/interrupt-controller/riscv,aplic.yaml
+++ b/Documentation/devicetree/bindings/interrupt-controller/riscv,aplic.yaml
@@ -27,6 +27,7 @@ properties:
   compatible:
     items:
       - enum:
+          - gf,mips-p8700-aplic
           - qemu,aplic
           - spacemit,k3-aplic
       - const: riscv,aplic

-- 
2.43.0

