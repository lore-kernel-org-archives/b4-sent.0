From: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Date: Mon, 14 Sep 2026 15:55:53 +0200
Subject: [PATCH 5/9] dt-bindings: interrupt-controller: Add MIPS P8700
 ACLINT MSWI
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260914-p8700-dts-v1-5-3267f14ebce1@htecgroup.com>
References: <20260914-p8700-dts-v1-0-3267f14ebce1@htecgroup.com>
In-Reply-To: <20260914-p8700-dts-v1-0-3267f14ebce1@htecgroup.com>
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
 Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789394164; l=2394;
 i=aleksa.paunovic@htecgroup.com; s=20250806; h=from:subject:message-id;
 bh=d6dCUSpFr/wHwlyABy937JZmuMEa5B5i8Du3V+WGvRU=;
 b=/CK+7BpY2QEZwNjyCeVxDPxAdvJb8B+L1XLb3ovHEhU/AAcNGfbaoNr5qYc7dKzjrvvqjF5gS
 9i9e+eTcC1HCfeO68b+1EqPs+F600EQRxdEx2cyEs8zcUkYaL6wuIze
X-Developer-Key: i=aleksa.paunovic@htecgroup.com; a=ed25519;
 pk=Dn4KMnDdgyhlXJNspQQrlHJ04i7/irG29p2H27Avd+8=
X-Endpoint-Received: by B4 Relay for aleksa.paunovic@htecgroup.com/20250806 with auth_id=476
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the aclint mswi compatible for the MIPS P8700 and
introduce the 'riscv,hart-indexes' property,
used to address the sparse MIPS P8700 harts.

Signed-off-by: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
---
 .../thead,c900-aclint-mswi.yaml                    | 34 ++++++++++++++++++++++
 1 file changed, 34 insertions(+)

diff --git a/Documentation/devicetree/bindings/interrupt-controller/thead,c900-aclint-mswi.yaml b/Documentation/devicetree/bindings/interrupt-controller/thead,c900-aclint-mswi.yaml
index 62fd220e126e650e3800d8eee2a749fdbbde6108..47c04943eb0c793467aaa5570776605cae0eadfd 100644
--- a/Documentation/devicetree/bindings/interrupt-controller/thead,c900-aclint-mswi.yaml
+++ b/Documentation/devicetree/bindings/interrupt-controller/thead,c900-aclint-mswi.yaml
@@ -17,6 +17,8 @@ properties:
               - sophgo,sg2042-aclint-mswi
               - sophgo,sg2044-aclint-mswi
           - const: thead,c900-aclint-mswi
+      - items:
+          - const: gf,mips-p8700-aclint-mswi
       - items:
           - enum:
               - anlogic,dr1v90-aclint-mswi
@@ -29,6 +31,14 @@ properties:
     minItems: 1
     maxItems: 4095
 
+  riscv,hart-indexes:
+    $ref: /schemas/types.yaml#/definitions/uint32-array
+    minItems: 1
+    maxItems: 4095
+    description:
+      A list of hart indexes that the MSWI device uses to address each hart
+      that is mentioned in the "interrupts-extended"
+
 additionalProperties: false
 
 required:
@@ -36,6 +46,19 @@ required:
   - reg
   - interrupts-extended
 
+allOf:
+  - if:
+      properties:
+        compatible:
+          contains:
+            const: gf,mips-p8700-aclint-mswi
+    then:
+      required:
+        - riscv,hart-indexes
+    else:
+      properties:
+        riscv,hart-indexes: false
+
 examples:
   - |
     interrupt-controller@94000000 {
@@ -46,4 +69,15 @@ examples:
                             <&cpu4intc 3>;
       reg = <0x94000000 0x00010000>;
     };
+
+  - |
+    mswi@16150000 {
+      compatible = "gf,mips-p8700-aclint-mswi";
+      reg = <0x16150000 0x4000>;
+      interrupts-extended = <&cpu1intc 3>,
+                            <&cpu2intc 3>,
+                            <&cpu3intc 3>,
+                            <&cpu4intc 3>;
+      riscv,hart-indexes = <0x0 0x1 0x10 0x11>;
+    };
 ...

-- 
2.43.0

