From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Mon, 12 Oct 2026 20:32:58 +0300
Subject: [PATCH 03/11] dt-bindings: gpio: Add Cortina Systems CS7542 GPIO
 controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261012-b4-cs75xx-s2-v1-3-8a7641b7b79c@gmail.com>
References: <20261012-b4-cs75xx-s2-v1-0-8a7641b7b79c@gmail.com>
In-Reply-To: <20261012-b4-cs75xx-s2-v1-0-8a7641b7b79c@gmail.com>
To: Thomas Gleixner <tglx@kernel.org>, Radu Rendec <radu@rendec.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, Andi Shyti <andi.shyti@kernel.org>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Russell King <linux@armlinux.org.uk>, 
 Arnd Bergmann <arnd@arndb.de>, Krzysztof Kozlowski <krzk@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-gpio@vger.kernel.org, 
 linux-i2c@vger.kernel.org, linux-watchdog@vger.kernel.org, 
 Fil Dunsky <filipp.dunsky@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791826375; l=2368;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=uz2ou1IT1ghc6GBy1z+YYFHHajTQ9VyMONdxfzPSdIk=;
 b=8+fbyqjLofqG9WBhmK3gaslEb9wRm4Pc5xw3UL1wayW/7eXxOp9epY3IB4OdC3VgYa5cymASk
 Oxp0F5tSARSCXp2/j+1xmBxbShTVxqPqFd0+4f2NQ2MHlJX6TOvnV+q
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Cortina Systems CS75xx SoCs have five banks of 32 GPIO lines. Each
pin is shared between a GPIO line and a peripheral function, selected by
the bank's GPIO_MUX register in the global control block, which is
described as the second register region of the bank.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 .../bindings/gpio/cortina,cs7542-gpio.yaml         | 68 ++++++++++++++++++++++
 1 file changed, 68 insertions(+)

diff --git a/Documentation/devicetree/bindings/gpio/cortina,cs7542-gpio.yaml b/Documentation/devicetree/bindings/gpio/cortina,cs7542-gpio.yaml
new file mode 100644
index 000000000..b54421d65
--- /dev/null
+++ b/Documentation/devicetree/bindings/gpio/cortina,cs7542-gpio.yaml
@@ -0,0 +1,68 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/gpio/cortina,cs7542-gpio.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Cortina Systems CS7542 GPIO controller
+
+maintainers:
+  - Fil Dunsky <filipp.dunsky@gmail.com>
+
+description:
+  The Cortina Systems CS75xx (Goldengate G2) SoCs have five banks of 32
+  GPIO lines, each with its own interrupt. Every pin is shared between a
+  GPIO line and a peripheral function; the choice is made per pin in the
+  GPIO_MUX register of the bank, which is part of the global control
+  block.
+
+properties:
+  compatible:
+    const: cortina,cs7542-gpio
+
+  reg:
+    items:
+      - description: GPIO bank registers
+      - description: GPIO_MUX register of the bank
+
+  interrupts:
+    maxItems: 1
+
+  gpio-controller: true
+
+  "#gpio-cells":
+    const: 2
+
+  gpio-line-names:
+    maxItems: 32
+
+  gpio-reserved-ranges: true
+
+  interrupt-controller: true
+
+  "#interrupt-cells":
+    const: 2
+
+required:
+  - compatible
+  - reg
+  - interrupts
+  - gpio-controller
+  - "#gpio-cells"
+  - interrupt-controller
+  - "#interrupt-cells"
+
+additionalProperties: false
+
+examples:
+  - |
+    gpio@f00701f0 {
+        compatible = "cortina,cs7542-gpio";
+        reg = <0xf00701f0 0x20>, <0xf0000020 0x4>;
+        interrupt-parent = <&intc>;
+        interrupts = <7>;
+        gpio-controller;
+        #gpio-cells = <2>;
+        interrupt-controller;
+        #interrupt-cells = <2>;
+    };

-- 
2.53.0

