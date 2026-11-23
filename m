From: Joseph Telaak <joseph@telaak.dev>
Date: Sun, 22 Nov 2026 20:37:18 -0500
Subject: [PATCH v3 1/2] dt-bindings: gpio: Add Siflower SF19A2890 GPIO
 controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-sf19a2890-gpio-v3-1-3a4857ebc84a@telaak.dev>
References: <20261122-sf19a2890-gpio-v3-0-3a4857ebc84a@telaak.dev>
In-Reply-To: <20261122-sf19a2890-gpio-v3-0-3a4857ebc84a@telaak.dev>
To: Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: Chuanhong Guo <gch981213@gmail.com>, Qingfang Deng <dqfext@gmail.com>, 
 Michael Walle <mwalle@kernel.org>, linux-mips@vger.kernel.org, 
 linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795397847; l=3455;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=pVI8ZFvssbvuyI5yjpcZjMZpO8VtPQcany4H5g/wKlU=;
 b=sNLLVJz+S6fJypz872MCOZ5yHe66GCSDKIRy5JGgFI6eeiSfeh/F1BY69BP1qmb6Gb7zjH6Yv
 LthL2j7saW8D6naax9t1wU5lM0v3E/UUhT+7pBgSZeTzzKv0cIK9qR4
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Chuanhong Guo <gch981213@gmail.com>

Document the GPIO controller of the Siflower SF19A2890. Siflower's SF21
RISC-V SoCs have the same controller, and will get compatibles of their
own with their device trees.

[Joseph Telaak:
  - take it from Chuanhong's siflower-7.1 branch
  - list myself as the binding's maintainer
  - use GPL-2.0-only instead of the deprecated GPL-2.0 SPDX
    identifier
  - indent the example by four spaces
  - drop the ngpios property, which the compatible implies, take
    exactly four interrupts, and order the properties as in required
  - commit message and subject]

Signed-off-by: Chuanhong Guo <gch981213@gmail.com>
Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
 .../bindings/gpio/siflower,sf19a2890-gpio.yaml     | 76 ++++++++++++++++++++++
 MAINTAINERS                                        |  6 ++
 2 files changed, 82 insertions(+)

diff --git a/Documentation/devicetree/bindings/gpio/siflower,sf19a2890-gpio.yaml b/Documentation/devicetree/bindings/gpio/siflower,sf19a2890-gpio.yaml
new file mode 100644
index 000000000000..830a049ae4f5
--- /dev/null
+++ b/Documentation/devicetree/bindings/gpio/siflower,sf19a2890-gpio.yaml
@@ -0,0 +1,76 @@
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
+  reg:
+    maxItems: 1
+
+  interrupts:
+    description: One interrupt per group of 16 GPIOs.
+    maxItems: 4
+
+  clocks:
+    maxItems: 1
+
+  resets:
+    maxItems: 1
+
+  gpio-controller: true
+
+  "#gpio-cells":
+    const: 2
+
+  gpio-ranges: true
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
+  - clocks
+  - resets
+  - gpio-controller
+  - "#gpio-cells"
+  - gpio-ranges
+  - interrupt-controller
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
+        gpio-ranges = <&pinctrl 0 0 49>;
+
+        interrupt-controller;
+        #interrupt-cells = <2>;
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index b5a6dc379c09..4193b433c915 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -25706,6 +25706,12 @@ N:	sifive
 K:	fu[57]40
 K:	[^@]sifive
 
+SIFLOWER GPIO DRIVER
+M:	Joseph Telaak <joseph@telaak.dev>
+L:	linux-gpio@vger.kernel.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/gpio/siflower,sf19a2890-gpio.yaml
+
 SILEAD TOUCHSCREEN DRIVER
 M:	Hans de Goede <hansg@kernel.org>
 L:	linux-input@vger.kernel.org

-- 
Git-155)

