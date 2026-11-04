From: Joseph Telaak <joseph@telaak.dev>
Date: Wed, 04 Nov 2026 02:21:37 -0500
Subject: [PATCH 1/2] dt-bindings: gpio: Add Siflower SF19A2890 GPIO
 controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-sf19a2890-gpio-v1-1-45e463c48728@telaak.dev>
References: <20261104-sf19a2890-gpio-v1-0-45e463c48728@telaak.dev>
In-Reply-To: <20261104-sf19a2890-gpio-v1-0-45e463c48728@telaak.dev>
To: Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: Chuanhong Guo <gch981213@gmail.com>, Qingfang Deng <dqfext@gmail.com>, 
 linux-mips@vger.kernel.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793776902; l=2771;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=uSoSG67SFdVKXQExecXvufj+C6sUxYM+E633nWAqYG0=;
 b=bfAu5bt6JFuxnloUdHZ/vmb8chiKz/fFuEkW8z09xji/E5Zu8jEAqw/eKZpTlFaYpQg/cVesb
 EZgRN0aPLNqABkxUoOUXdCbwMCiALHSl3gjHLnKMFlUS+TPWDxsIZo5
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Chuanhong Guo <gch981213@gmail.com>

Document the GPIO controller found on the Siflower SF19A2890 and other
Siflower MIPS and RISC-V SoCs.

Signed-off-by: Chuanhong Guo <gch981213@gmail.com>
[jt: from Chuanhong's siflower-7.1 branch; Joseph Telaak as the binding's
 maintainer, GPL-2.0-only for the deprecated GPL-2.0 SPDX identifier,
 example indented by four spaces, commit message, subject]
Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
 .../bindings/gpio/siflower,sf19a2890-gpio.yaml     | 84 ++++++++++++++++++++++
 1 file changed, 84 insertions(+)

diff --git a/Documentation/devicetree/bindings/gpio/siflower,sf19a2890-gpio.yaml b/Documentation/devicetree/bindings/gpio/siflower,sf19a2890-gpio.yaml
new file mode 100644
index 000000000..6708d92fe
--- /dev/null
+++ b/Documentation/devicetree/bindings/gpio/siflower,sf19a2890-gpio.yaml
@@ -0,0 +1,84 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/gpio/siflower,sf19a2890-gpio.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Siflower SF19A2890 GPIO controller
+
+maintainers:
+  - Joseph Telaak <joseph@telaak.dev>
+
+properties:
+  compatible:
+    const: siflower,sf19a2890-gpio
+
+  gpio-controller: true
+  "#gpio-cells":
+    const: 2
+
+  gpio-ranges: true
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    description:
+      Interrupt mapping, one interrupt per 16 GPIOs.
+    minItems: 1
+    maxItems: 10
+
+  clocks:
+    maxItems: 1
+
+  resets:
+    maxItems: 1
+
+  interrupt-controller: true
+
+  "#interrupt-cells":
+    const: 2
+
+  ngpios:
+    description:
+      The number of GPIOs available on the controller implementation.
+    minimum: 1
+
+required:
+  - compatible
+  - clocks
+  - gpio-controller
+  - gpio-ranges
+  - interrupt-controller
+  - interrupts
+  - ngpios
+  - reg
+  - resets
+  - "#gpio-cells"
+  - "#interrupt-cells"
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/irq.h>
+    #include <dt-bindings/interrupt-controller/mips-gic.h>
+
+    gpio@19d00000 {
+        compatible = "siflower,sf19a2890-gpio";
+        reg = <0x19d00000 0x100000>;
+        interrupts = <GIC_SHARED 246 IRQ_TYPE_LEVEL_HIGH>,
+                     <GIC_SHARED 247 IRQ_TYPE_LEVEL_HIGH>,
+                     <GIC_SHARED 248 IRQ_TYPE_LEVEL_HIGH>,
+                     <GIC_SHARED 249 IRQ_TYPE_LEVEL_HIGH>;
+        clocks = <&gpioclk 0>;
+        resets = <&gpiorst 0>;
+
+        gpio-controller;
+        #gpio-cells = <2>;
+        ngpios = <49>;
+        gpio-ranges = <&pinctrl 0 0 49>;
+
+        interrupt-controller;
+        #interrupt-cells = <2>;
+    };

-- 
Git-155)

