From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Tue, 24 Nov 2026 11:20:19 +0300
Subject: [PATCH v2 1/3] dt-bindings: rng: Add Cortina Systems CS7542 TRNG
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-b4-cs7542-trng-v2-1-0192937b44be@gmail.com>
References: <20261124-b4-cs7542-trng-v2-0-0192937b44be@gmail.com>
In-Reply-To: <20261124-b4-cs7542-trng-v2-0-0192937b44be@gmail.com>
To: Olivia Mackall <olivia@selenic.com>, 
 Herbert Xu <herbert@gondor.apana.org.au>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@baylibre.com>, 
 linux-crypto@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795508418; l=1739;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=l1fROYGvUCU9bKrkug2vK1Rka6sqX2RjZb2LewzoVUM=;
 b=KLrAWWXkmpFw430BX6JJHZ2JmgYjVP9RW3wKNQj2b9SDOaf+FmseKvatXmzjfdl0MRUiQdzXQ
 5dkdxpSSjRdA0IB4U4Vfw7jq2aEYzV7SNV1ywSouWEbmCFbODJV8GzI
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the Elliptic TRNG register block and its reference to the
shared global control syscon.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 .../bindings/rng/cortina,cs7542-trng.yaml          | 43 ++++++++++++++++++++++
 1 file changed, 43 insertions(+)

diff --git a/Documentation/devicetree/bindings/rng/cortina,cs7542-trng.yaml b/Documentation/devicetree/bindings/rng/cortina,cs7542-trng.yaml
new file mode 100644
index 000000000..2a3890650
--- /dev/null
+++ b/Documentation/devicetree/bindings/rng/cortina,cs7542-trng.yaml
@@ -0,0 +1,43 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/rng/cortina,cs7542-trng.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Cortina Systems CS7542 true random number generator
+
+description: |
+  The CS7542 A0 revision is affected by reseeding erratum 28891.
+  Hardware entropy reseeding requires the CS7542 A1 revision.
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
+      Global control syscon containing the SoC identification register at
+      offset 0x00 and the scratch register at offset 0xc0.
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

