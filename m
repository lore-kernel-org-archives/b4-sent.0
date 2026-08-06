From: Long Zhao <longzhao@ambarella.com>
Date: Thu, 06 Aug 2026 17:34:10 +0800
Subject: [PATCH v2 02/10] dt-bindings: soc: add Ambarella secure scratchpad
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260806-longzhao-upstream-cv75-v2-v2-2-6b09707c5fe9@ambarella.com>
References: <20260806-longzhao-upstream-cv75-v2-v2-0-6b09707c5fe9@ambarella.com>
In-Reply-To: <20260806-longzhao-upstream-cv75-v2-v2-0-6b09707c5fe9@ambarella.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Arnd Bergmann <arnd@arndb.de>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-gpio@vger.kernel.org, linux-serial@vger.kernel.org, 
 soc@lists.linux.dev, Long Zhao <longzhao@ambarella.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786008863; l=1545;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=1vmye3CK0HpbkUmTNeoU7Oscgo8VwkmeZd901TWonnk=;
 b=f3oS0meErI2j00TKtSZ8nQ8sMS+wTYXOy+doYgvXLIsQdTWSBNPan7rytIrwLIoZznhElBAee
 KuyY6KX+IeZBHkpzWLPBo4zGKFpEpuqUX2LsFzPBeafjNNlDGKeEVi7
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the Ambarella secure scratchpad syscon used by CV75.

Signed-off-by: Long Zhao <longzhao@ambarella.com>
---
 .../ambarella/ambarella,cv75-sec-scratchpad.yaml   | 39 ++++++++++++++++++++++
 1 file changed, 39 insertions(+)

diff --git a/Documentation/devicetree/bindings/soc/ambarella/ambarella,cv75-sec-scratchpad.yaml b/Documentation/devicetree/bindings/soc/ambarella/ambarella,cv75-sec-scratchpad.yaml
new file mode 100644
index 000000000000..4bfeca0ac3da
--- /dev/null
+++ b/Documentation/devicetree/bindings/soc/ambarella/ambarella,cv75-sec-scratchpad.yaml
@@ -0,0 +1,39 @@
+# SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/soc/ambarella/ambarella,cv75-sec-scratchpad.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Ambarella CV75 Secure Scratchpad Registers
+
+maintainers:
+  - Long Zhao <longzhao@ambarella.com>
+
+description:
+  The secure scratchpad block contains shared system registers used by
+  other Ambarella SoC blocks through syscon regmap lookups.
+
+allOf:
+  - $ref: /schemas/mfd/syscon-common.yaml#
+
+properties:
+  compatible:
+    items:
+      - const: ambarella,cv75-sec-scratchpad
+      - const: syscon
+
+  reg:
+    maxItems: 1
+
+required:
+  - compatible
+  - reg
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    scratchpad@e002e000 {
+        compatible = "ambarella,cv75-sec-scratchpad", "syscon";
+        reg = <0xe002e000 0x1000>;
+    };

-- 
2.34.1

