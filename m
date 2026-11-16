From: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Date: Mon, 16 Nov 2026 12:55:12 +0100
Subject: [PATCH v3 5/8] dt-bindings: timer: Add MIPS P8700 ACLINT MTIMER
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-p8700-dts-v3-5-ec5d4b7de39f@htecgroup.com>
References: <20261116-p8700-dts-v3-0-ec5d4b7de39f@htecgroup.com>
In-Reply-To: <20261116-p8700-dts-v3-0-ec5d4b7de39f@htecgroup.com>
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
 Palmer Dabbelt <palmer@sifive.com>, Joel Stanley <joel@jms.id.au>, 
 Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794830124; l=2281;
 i=aleksa.paunovic@htecgroup.com; s=20250806; h=from:subject:message-id;
 bh=NJe+9FUIucxCmNXZnGjS07SXJ64Ib/0GQbLsdG2nvOM=;
 b=YxdDK4koG2rM6wnlapd4vaY+E2+hhCtPnx271NUbwJPio1A3ajKWu3wHmKxS1rDXbn6EAC/sQ
 CYTOKULvqitCHqXVF4KGAl5GOIaKEKu0HJ27gV/ZiWACf6AWCFNzjXq
X-Developer-Key: i=aleksa.paunovic@htecgroup.com; a=ed25519;
 pk=Dn4KMnDdgyhlXJNspQQrlHJ04i7/irG29p2H27Avd+8=
X-Endpoint-Received: by B4 Relay for aleksa.paunovic@htecgroup.com/20250806 with auth_id=476
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the MIPS P8700 ACLINT MTIMER.
Extend support for both mtimecmp and mtime registers
within the ACLINT MTIMER, identified via reg-names.

Signed-off-by: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
---
 .../bindings/timer/thead,c900-aclint-mtimer.yaml   | 37 ++++++++++++++++++++++
 1 file changed, 37 insertions(+)

diff --git a/Documentation/devicetree/bindings/timer/thead,c900-aclint-mtimer.yaml b/Documentation/devicetree/bindings/timer/thead,c900-aclint-mtimer.yaml
index cf7c82e980f674afcf59fc726742dc4f49c1a820..a5ebe04ade9ed61c8beac5017aab94ab12afa9ea 100644
--- a/Documentation/devicetree/bindings/timer/thead,c900-aclint-mtimer.yaml
+++ b/Documentation/devicetree/bindings/timer/thead,c900-aclint-mtimer.yaml
@@ -21,13 +21,19 @@ properties:
           - enum:
               - anlogic,dr1v90-aclint-mtimer
           - const: nuclei,ux900-aclint-mtimer
+      - const: mips,p8700-aclint-mtimer
 
   reg:
+    minItems: 1
     items:
+      - description: MTIME Registers, or MTIMECMP Registers if only one
+          region is present
       - description: MTIMECMP Registers
 
   reg-names:
+    minItems: 1
     items:
+      - enum: [ mtime, mtimecmp ]
       - const: mtimecmp
 
   interrupts-extended:
@@ -42,6 +48,26 @@ required:
   - reg-names
   - interrupts-extended
 
+allOf:
+  - if:
+      properties:
+        compatible:
+          contains:
+            const: mips,p8700-aclint-mtimer
+    then:
+      properties:
+        reg:
+          minItems: 2
+        reg-names:
+          minItems: 2
+    else:
+      properties:
+        reg:
+          maxItems: 1
+        reg-names:
+          items:
+            - const: mtimecmp
+
 examples:
   - |
     timer@ac000000 {
@@ -53,4 +79,15 @@ examples:
       reg = <0xac000000 0x00010000>;
       reg-names = "mtimecmp";
     };
+
+  - |
+    timer@16108050 {
+        compatible = "mips,p8700-aclint-mtimer";
+        reg = <0x16108050 0x8>, <0x16154000 0x7ff8>;
+        reg-names = "mtime", "mtimecmp";
+        interrupts-extended = <&cpu1intc 7>,
+                              <&cpu2intc 7>,
+                              <&cpu3intc 7>,
+                              <&cpu4intc 7>;
+    };
 ...

-- 
2.43.0

