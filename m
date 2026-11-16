From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Mon, 16 Nov 2026 05:08:16 +0300
Subject: [PATCH v4 1/2] dt-bindings: gpio: Add Cortina Systems CS7542 GPIO
 controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-cs75xx-gpio-v4-1-ad80a944e966@gmail.com>
References: <20261116-cs75xx-gpio-v4-0-ad80a944e966@gmail.com>
In-Reply-To: <20261116-cs75xx-gpio-v4-0-ad80a944e966@gmail.com>
To: Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 Fil Dunsky <filipp.dunsky@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794794896; l=2174;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=uZPKiOwpZpFDwjo7k4WMPvOXgvIRpR4xQHtLI92EFkI=;
 b=Q2FTiw9zpF8SGfKF2lTP80YbnclDCPZkZRCKB3rmTGzRbij8W9e/V/JrwT7708WtnRVJvQSje
 dsvNKHu+8YUCdweOUiim7wq38QnAaxfwubEoW93GC5rabre/VFMrL9A
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Cortina Systems CS75xx SoCs have five banks of 32 GPIO lines. Each
pin is shared between a GPIO line and a peripheral function; the pin
mux lives in the global control block and is not described here.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 .../bindings/gpio/cortina,cs7542-gpio.yaml         | 65 ++++++++++++++++++++++
 1 file changed, 65 insertions(+)

diff --git a/Documentation/devicetree/bindings/gpio/cortina,cs7542-gpio.yaml b/Documentation/devicetree/bindings/gpio/cortina,cs7542-gpio.yaml
new file mode 100644
index 000000000..faa302180
--- /dev/null
+++ b/Documentation/devicetree/bindings/gpio/cortina,cs7542-gpio.yaml
@@ -0,0 +1,65 @@
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
+  GPIO line and a peripheral function; the choice is made in the global
+  control block and is not part of the GPIO controller.
+
+properties:
+  compatible:
+    const: cortina,cs7542-gpio
+
+  reg:
+    maxItems: 1
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
+        reg = <0xf00701f0 0x20>;
+        interrupt-parent = <&intc>;
+        interrupts = <7>;
+        gpio-controller;
+        #gpio-cells = <2>;
+        interrupt-controller;
+        #interrupt-cells = <2>;
+    };

-- 
2.53.0

