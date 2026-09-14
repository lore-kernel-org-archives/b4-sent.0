From: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Date: Mon, 14 Sep 2026 15:55:54 +0200
Subject: [PATCH 6/9] dt-bindings: timer: Add MIPS P8700 ACLINT MTIMER
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260914-p8700-dts-v1-6-3267f14ebce1@htecgroup.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789394164; l=2438;
 i=aleksa.paunovic@htecgroup.com; s=20250806; h=from:subject:message-id;
 bh=M5IyHBybwxEJk8ac4GspHzVPEulbhlRzm20t9LNaGmM=;
 b=9Aj12FjNDRPLsiFijbdUWSzeynhgFvKygTdmlPOuxb81BeHEw3ZUUNOXAlM1adSx55m0YRq7V
 TSBpv33dDYvD1Q+vq/Md9Se5o8TYo+6qcTfV6wdJEUXvYRe9MDz2m7k
X-Developer-Key: i=aleksa.paunovic@htecgroup.com; a=ed25519;
 pk=Dn4KMnDdgyhlXJNspQQrlHJ04i7/irG29p2H27Avd+8=
X-Endpoint-Received: by B4 Relay for aleksa.paunovic@htecgroup.com/20250806 with auth_id=476
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the MIPS P8700 ACLINT MTIMER.
Extend support for both mtimecmp and mtime registers
within the ACLINT MTIMER, identified via reg-names.

Signed-off-by: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
---
 .../bindings/timer/thead,c900-aclint-mtimer.yaml   | 43 ++++++++++++++++++++--
 1 file changed, 39 insertions(+), 4 deletions(-)

diff --git a/Documentation/devicetree/bindings/timer/thead,c900-aclint-mtimer.yaml b/Documentation/devicetree/bindings/timer/thead,c900-aclint-mtimer.yaml
index cf7c82e980f674afcf59fc726742dc4f49c1a820..35e02da675becb3c8bb187b8e1e623994d52df8c 100644
--- a/Documentation/devicetree/bindings/timer/thead,c900-aclint-mtimer.yaml
+++ b/Documentation/devicetree/bindings/timer/thead,c900-aclint-mtimer.yaml
@@ -17,18 +17,20 @@ properties:
               - sophgo,sg2042-aclint-mtimer
               - sophgo,sg2044-aclint-mtimer
           - const: thead,c900-aclint-mtimer
+      - items:
+          - const: gf,mips-p8700-aclint-mtimer
       - items:
           - enum:
               - anlogic,dr1v90-aclint-mtimer
           - const: nuclei,ux900-aclint-mtimer
 
   reg:
-    items:
-      - description: MTIMECMP Registers
+    minItems: 1
+    maxItems: 2
 
   reg-names:
-    items:
-      - const: mtimecmp
+    minItems: 1
+    maxItems: 2
 
   interrupts-extended:
     minItems: 1
@@ -42,6 +44,28 @@ required:
   - reg-names
   - interrupts-extended
 
+allOf:
+  - if:
+      properties:
+        compatible:
+          contains:
+            const: gf,mips-p8700-aclint-mtimer
+    then:
+      properties:
+        reg:
+          minItems: 2
+        reg-names:
+          items:
+            - const: mtime
+            - const: mtimecmp
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
@@ -53,4 +77,15 @@ examples:
       reg = <0xac000000 0x00010000>;
       reg-names = "mtimecmp";
     };
+
+  - |
+    timer@16108050 {
+      compatible = "gf,mips-p8700-aclint-mtimer";
+      reg = <0x16108050 0x8>, <0x16154000 0x7ff8>;
+      reg-names = "mtime", "mtimecmp";
+      interrupts-extended = <&cpu1intc 7>,
+                            <&cpu2intc 7>,
+                            <&cpu3intc 7>,
+                            <&cpu4intc 7>;
+    };
 ...

-- 
2.43.0

