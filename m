From: Ben Zong-You Xie <ben717@andestech.com>
Date: Thu, 22 Jan 2026 11:53:18 +0800
Subject: [PATCH v2 1/4] dt-bindings: i2c: add support for AE350 I2C
 controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260122-atciic100-v2-1-7559136d07cf@andestech.com>
References: <20260122-atciic100-v2-0-7559136d07cf@andestech.com>
In-Reply-To: <20260122-atciic100-v2-0-7559136d07cf@andestech.com>
To: Andi Shyti <andi.shyti@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>
Cc: linux-i2c@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-riscv@lists.infradead.org, 
 Ben Zong-You Xie <ben717@andestech.com>
X-Mailer: b4 0.15-dev-47773
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769054012; l=1551;
 i=ben717@andestech.com; s=20260120; h=from:subject:message-id;
 bh=bzYjfsqz3N3OJ2j9q6l3BfHCzA65mq7d2npy3Ry0CC0=;
 b=cae9XqVaBijHpGFgb5ZB/sdG9gKCTINR921/4Qy5OD1h21DNmNwnafowJvlmWthFpi9or8KCX
 C+KJXDzvmThANQo0SX0may8Eanire4JSRp0jXdgjucOtcPuKWi2gVZ+
X-Developer-Key: i=ben717@andestech.com; a=ed25519;
 pk=nb8L7zQKGJpYk0yvrYKjViOZ34A36g1ZIsCmCsP518s=
X-Endpoint-Received: by B4 Relay for ben717@andestech.com/20260120 with auth_id=610
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document device tree bindings for the I2C controller on Andes AE350
platform.

Signed-off-by: Ben Zong-You Xie <ben717@andestech.com>
---
 .../bindings/i2c/andestech,ae350-i2c.yaml          | 45 ++++++++++++++++++++++
 1 file changed, 45 insertions(+)

diff --git a/Documentation/devicetree/bindings/i2c/andestech,ae350-i2c.yaml b/Documentation/devicetree/bindings/i2c/andestech,ae350-i2c.yaml
new file mode 100644
index 000000000000..59a521fb249b
--- /dev/null
+++ b/Documentation/devicetree/bindings/i2c/andestech,ae350-i2c.yaml
@@ -0,0 +1,45 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/i2c/andestech,ae350-i2c.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Andes I2C controller on AE350 platform
+
+maintainers:
+  - Ben Zong-You Xie <ben717@andestech.com>
+
+allOf:
+  - $ref: /schemas/i2c/i2c-controller.yaml#
+
+properties:
+  compatible:
+    oneOf:
+      - items:
+          - enum:
+              - andestech,qilai-i2c
+          - const: andestech,ae350-i2c
+      - const: andestech,ae350-i2c
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    maxItems: 1
+
+required:
+  - compatible
+  - reg
+  - interrupts
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/irq.h>
+
+    i2c@f0a00000 {
+        compatible = "andestech,ae350-i2c";
+        reg = <0xf0a00000 0x100000>;
+        interrupts = <6 IRQ_TYPE_LEVEL_HIGH>;
+    };

-- 
2.34.1

