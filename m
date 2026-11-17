From: yy-Local-LLM <yogo.0917.sabu@gmail.com>
Date: Tue, 17 Nov 2026 22:06:51 +0900
Subject: [PATCH RFC 1/6] dt-bindings: add SiRF AT550 and Yupiteru YPL514si
 descriptions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-at550-rfc-v1-v1-1-5879573cb825@gmail.com>
References: <20261117-at550-rfc-v1-v1-0-5879573cb825@gmail.com>
In-Reply-To: <20261117-at550-rfc-v1-v1-0-5879573cb825@gmail.com>
To: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Thomas Gleixner <tglx@kernel.org>, Radu Rendec <radu@rendec.net>, 
 Ulf Hansson <ulfh@kernel.org>, Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Adrian Hunter <adrian.hunter@intel.com>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Russell King <linux@armlinux.org.uk>, 
 Arnd Bergmann <arnd@arndb.de>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Linus Walleij <linusw@kernel.org>, Drew Fustini <fustini@kernel.org>, 
 linux-kernel@vger.kernel.org, linux-input@vger.kernel.org, 
 linux-mmc@vger.kernel.org, linux-doc@vger.kernel.org, soc@lists.linux.dev
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794920817; l=8505;
 i=yogo.0917.sabu@gmail.com; s=ypl514-20261117; h=from:subject:message-id;
 bh=PPMFmty+X1fB4x1sTCUWuwl5IruxK1aahzVZzgQU0DI=;
 b=/M56w7i6wjjKb7hkQhlFL4AB7O0JGYb32FY8M87pw5hDp1BHmErXvZVs4yqdXAIaIoI0HuWL3
 x7h42a21k0HBJ0HskfUmHsNgeVwKeAgdVZzsePenB1Nq51EwaHtImmM
X-Developer-Key: i=yogo.0917.sabu@gmail.com; a=ed25519;
 pk=TIQ8Tk4xQrxyn8rmk3GI2f5qg/kO6g2KZm7YOOyBHeg=
X-Endpoint-Received: by B4 Relay for yogo.0917.sabu@gmail.com/ypl514-20261117 with auth_id=1550
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the 64-source interrupt controller, counter/match timer,
resistive touch input and PIO SD host, together with the YPL514si board
compatible. The counter clock is supplied by boot firmware after its
configured divider. The initial platform inherits firmware clock and pin
setup.

Signed-off-by: yy-Local-LLM <yogo.0917.sabu@gmail.com>
---
 .../devicetree/bindings/arm/sirf,at550.yaml        | 22 ++++++++++
 .../bindings/input/touchscreen/sirf,at550-ts.yaml  | 36 +++++++++++++++
 .../interrupt-controller/sirf,at550-intc.yaml      | 46 +++++++++++++++++++
 .../devicetree/bindings/mmc/sirf,at550-sdhci.yaml  | 51 ++++++++++++++++++++++
 .../bindings/timer/sirf,at550-timer.yaml           | 47 ++++++++++++++++++++
 .../devicetree/bindings/vendor-prefixes.yaml       |  2 +
 MAINTAINERS                                        |  9 ++++
 7 files changed, 213 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/sirf,at550.yaml b/Documentation/devicetree/bindings/arm/sirf,at550.yaml
new file mode 100644
index 000000000..f538f7ccc
--- /dev/null
+++ b/Documentation/devicetree/bindings/arm/sirf,at550.yaml
@@ -0,0 +1,22 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/arm/sirf,at550.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: SiRF AT550 platforms
+
+maintainers:
+  - yy-Local-LLM <yogo.0917.sabu@gmail.com>
+
+properties:
+  $nodename:
+    const: '/'
+  compatible:
+    items:
+      - const: yupiteru,ypl514si
+      - const: sirf,at550
+
+additionalProperties: true
+
+...
diff --git a/Documentation/devicetree/bindings/input/touchscreen/sirf,at550-ts.yaml b/Documentation/devicetree/bindings/input/touchscreen/sirf,at550-ts.yaml
new file mode 100644
index 000000000..0458db241
--- /dev/null
+++ b/Documentation/devicetree/bindings/input/touchscreen/sirf,at550-ts.yaml
@@ -0,0 +1,36 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/input/touchscreen/sirf,at550-ts.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: SiRF AT550 resistive touchscreen
+
+maintainers:
+  - yy-Local-LLM <yogo.0917.sabu@gmail.com>
+
+allOf:
+  - $ref: touchscreen.yaml#
+
+properties:
+  compatible:
+    const: sirf,at550-ts
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
+    touchscreen@80120000 {
+        compatible = "sirf,at550-ts";
+        reg = <0x80120000 0x1000>;
+        touchscreen-size-x = <4096>;
+        touchscreen-size-y = <4096>;
+    };
+
+...
diff --git a/Documentation/devicetree/bindings/interrupt-controller/sirf,at550-intc.yaml b/Documentation/devicetree/bindings/interrupt-controller/sirf,at550-intc.yaml
new file mode 100644
index 000000000..ec68afa80
--- /dev/null
+++ b/Documentation/devicetree/bindings/interrupt-controller/sirf,at550-intc.yaml
@@ -0,0 +1,46 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/interrupt-controller/sirf,at550-intc.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: SiRF AT550 interrupt controller
+
+maintainers:
+  - yy-Local-LLM <yogo.0917.sabu@gmail.com>
+
+description:
+  The AT550 controller routes 64 level-sensitive interrupt sources to the
+  ARM1136 IRQ input. Each source has a fixed active level; the single interrupt
+  cell is the source number. Firmware FIQ routes are not exposed by this driver.
+
+properties:
+  compatible:
+    const: sirf,at550-intc
+  reg:
+    maxItems: 1
+  interrupt-controller: true
+  '#interrupt-cells':
+    const: 1
+  '#address-cells':
+    const: 0
+
+required:
+  - compatible
+  - reg
+  - interrupt-controller
+  - '#interrupt-cells'
+
+additionalProperties: false
+
+examples:
+  - |
+    interrupt-controller@90020000 {
+        compatible = "sirf,at550-intc";
+        reg = <0x90020000 0x1000>;
+        interrupt-controller;
+        #interrupt-cells = <1>;
+        #address-cells = <0>;
+    };
+
+...
diff --git a/Documentation/devicetree/bindings/mmc/sirf,at550-sdhci.yaml b/Documentation/devicetree/bindings/mmc/sirf,at550-sdhci.yaml
new file mode 100644
index 000000000..7129aaeec
--- /dev/null
+++ b/Documentation/devicetree/bindings/mmc/sirf,at550-sdhci.yaml
@@ -0,0 +1,51 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/mmc/sirf,at550-sdhci.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: SiRF AT550 SDHCI host controller
+
+maintainers:
+  - yy-Local-LLM <yogo.0917.sabu@gmail.com>
+
+description:
+  AT550 removable SD controller. Initial support uses programmed I/O and
+  firmware-configured clocks and pin multiplexing. DMA address translation
+  and 1.8 V operation are not described by this binding.
+
+allOf:
+  - $ref: mmc-controller.yaml#
+
+properties:
+  compatible:
+    const: sirf,at550-sdhci
+  reg:
+    maxItems: 1
+  interrupts:
+    maxItems: 1
+  bus-width:
+    enum: [1, 4]
+  no-1-8-v: true
+
+required:
+  - compatible
+  - reg
+  - interrupts
+  - no-1-8-v
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    mmc@56000000 {
+        compatible = "sirf,at550-sdhci";
+        reg = <0x56000000 0x1000>;
+        interrupt-parent = <&intc>;
+        interrupts = <36>;
+        bus-width = <4>;
+        max-frequency = <25000000>;
+        no-1-8-v;
+    };
+
+...
diff --git a/Documentation/devicetree/bindings/timer/sirf,at550-timer.yaml b/Documentation/devicetree/bindings/timer/sirf,at550-timer.yaml
new file mode 100644
index 000000000..d1465d438
--- /dev/null
+++ b/Documentation/devicetree/bindings/timer/sirf,at550-timer.yaml
@@ -0,0 +1,47 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/timer/sirf,at550-timer.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: SiRF AT550 system timer
+
+maintainers:
+  - yy-Local-LLM <yogo.0917.sabu@gmail.com>
+
+description:
+  A free-running counter with six match channels. The Linux driver uses the
+  low 32 counter bits and match channel zero. Firmware configures the divider
+  before boot and supplies the resulting counter clock. A running watchdog
+  must be disabled by firmware before this block is handed to Linux.
+
+properties:
+  compatible:
+    const: sirf,at550-timer
+  reg:
+    maxItems: 1
+  interrupts:
+    maxItems: 1
+  clocks:
+    items:
+      - description: Counter clock after the firmware-configured divider
+
+required:
+  - compatible
+  - reg
+  - interrupts
+  - clocks
+
+additionalProperties: false
+
+examples:
+  - |
+    timer@90050000 {
+        compatible = "sirf,at550-timer";
+        reg = <0x90050000 0x1000>;
+        interrupt-parent = <&intc>;
+        interrupts = <0>;
+        clocks = <&counter_clk>;
+    };
+
+...
diff --git a/Documentation/devicetree/bindings/vendor-prefixes.yaml b/Documentation/devicetree/bindings/vendor-prefixes.yaml
index 5471a06f9..a8927fea3 100644
--- a/Documentation/devicetree/bindings/vendor-prefixes.yaml
+++ b/Documentation/devicetree/bindings/vendor-prefixes.yaml
@@ -1985,6 +1985,8 @@ patternProperties:
     description: Shenzhen Yashi Changhua Intelligent Technology Co., Ltd.
   "^ysoft,.*":
     description: Y Soft Corporation a.s.
+  "^yupiteru,.*":
+    description: Yupiteru
   "^yuridenki,.*":
     description: Yuridenki-Shokai Co. Ltd.
   "^yuzukihd,.*":
diff --git a/MAINTAINERS b/MAINTAINERS
index d73899016..6c3702cd8 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -25847,6 +25847,15 @@ F:	drivers/gpio/gpio-siox.c
 F:	drivers/siox/*
 F:	include/trace/events/siox.h
 
+SIRF AT550 PLATFORM
+M:	yy-Local-LLM <yogo.0917.sabu@gmail.com>
+S:	Odd Fixes
+F:	Documentation/devicetree/bindings/arm/sirf,at550.yaml
+F:	Documentation/devicetree/bindings/input/touchscreen/sirf,at550-ts.yaml
+F:	Documentation/devicetree/bindings/interrupt-controller/sirf,at550-intc.yaml
+F:	Documentation/devicetree/bindings/mmc/sirf,at550-sdhci.yaml
+F:	Documentation/devicetree/bindings/timer/sirf,at550-timer.yaml
+
 SIS 190 ETHERNET DRIVER
 M:	Francois Romieu <romieu@fr.zoreil.com>
 L:	netdev@vger.kernel.org

-- 
2.56.0

