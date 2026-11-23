From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Mon, 23 Nov 2026 21:41:34 +0300
Subject: [PATCH 1/3] dt-bindings: rng: Add Cortina Systems CS7542 TRNG
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-b4-cs7542-trng-v1-1-92d9ffcee531@gmail.com>
References: <20261123-b4-cs7542-trng-v1-0-92d9ffcee531@gmail.com>
In-Reply-To: <20261123-b4-cs7542-trng-v1-0-92d9ffcee531@gmail.com>
To: Olivia Mackall <olivia@selenic.com>, 
 Herbert Xu <herbert@gondor.apana.org.au>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-crypto@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795459294; l=1529;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=h3Rkf84iDXCJIMnadYFK8kaa2zOPjoZm3reYLlt/sOc=;
 b=CAksPJdPCf1i8DCqnPWzq8mAGuYAdij5H6veRCIsvGhokheBm/cE6ThpGZw1x7g7G1ryAJPRx
 dxNjxnxvRTJBj4dxlUPfE6mikU3wyRqzBhwyXBH3UqEXft5mdB5SPxq
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the Elliptic TRNG register block and its reference to the
shared global control syscon.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 .../bindings/rng/cortina,cs7542-trng.yaml          | 38 ++++++++++++++++++++++
 1 file changed, 38 insertions(+)

diff --git a/Documentation/devicetree/bindings/rng/cortina,cs7542-trng.yaml b/Documentation/devicetree/bindings/rng/cortina,cs7542-trng.yaml
new file mode 100644
index 000000000..9118397d6
--- /dev/null
+++ b/Documentation/devicetree/bindings/rng/cortina,cs7542-trng.yaml
@@ -0,0 +1,38 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/rng/cortina,cs7542-trng.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Cortina Systems CS7542 true random number generator
+
+maintainers:
+  - Fil Dunsky <filipp.dunsky@gmail.com>
+
+properties:
+  compatible:
+    const: cortina,cs7542-trng
+
+  reg:
+    maxItems: 1
+
+  cortina,syscon:
+    $ref: /schemas/types.yaml#/definitions/phandle
+    description:
+      Global control syscon containing the scratch register at offset 0xc0.
+      Bit 5 is set before initializing the random number generator.
+
+required:
+  - compatible
+  - reg
+  - cortina,syscon
+
+additionalProperties: false
+
+examples:
+  - |
+    rng@f0600000 {
+        compatible = "cortina,cs7542-trng";
+        reg = <0xf0600000 0x20>;
+        cortina,syscon = <&global_control>;
+    };

-- 
2.53.0

