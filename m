From: Nikita Shubin <nikita.shubin@maquefel.me>
Date: Thu, 20 Jul 2023 14:29:21 +0300
Subject: [PATCH v3 21/42] dt-bindings: dma: Add Cirrus EP93xx
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230605-ep93xx-v3-21-3d63a5f1103e@maquefel.me>
References: <20230605-ep93xx-v3-0-3d63a5f1103e@maquefel.me>
In-Reply-To: <20230605-ep93xx-v3-0-3d63a5f1103e@maquefel.me>
To: Hartley Sweeten <hsweeten@visionengravers.com>, 
 Lennert Buytenhek <kernel@wantstofly.org>, 
 Alexander Sverdlin <alexander.sverdlin@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, Lukasz Majewski <lukma@denx.de>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Nikita Shubin <nikita.shubin@maquefel.me>, 
 Daniel Lezcano <daniel.lezcano@linaro.org>, 
 Thomas Gleixner <tglx@linutronix.de>, 
 Alessandro Zummo <a.zummo@towertech.it>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Sebastian Reichel <sre@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@pengutronix.de>, 
 Mark Brown <broonie@kernel.org>, "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Vinod Koul <vkoul@kernel.org>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>, 
 Damien Le Moal <dlemoal@kernel.org>, Sergey Shtylyov <s.shtylyov@omp.ru>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Arnd Bergmann <arnd@arndb.de>, 
 Olof Johansson <olof@lixom.net>, soc@kernel.org, 
 Liam Girdwood <lgirdwood@gmail.com>, Jaroslav Kysela <perex@perex.cz>, 
 Takashi Iwai <tiwai@suse.com>, Andy Shevchenko <andy@kernel.org>, 
 Michael Peters <mpeters@embeddedTS.com>, Kris Bahnsen <kris@embeddedTS.com>
Cc: linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-clk@vger.kernel.org, linux-rtc@vger.kernel.org, 
 linux-watchdog@vger.kernel.org, linux-pm@vger.kernel.org, 
 linux-pwm@vger.kernel.org, linux-spi@vger.kernel.org, 
 netdev@vger.kernel.org, dmaengine@vger.kernel.org, 
 linux-mtd@lists.infradead.org, linux-ide@vger.kernel.org, 
 linux-input@vger.kernel.org, alsa-devel@alsa-project.org
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1689852591; l=8666;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=aXXlGe/xBEf3HwMFX6kd2KXsEwj1QIDN8Sh3QWPPNM4=;
 b=FwF4B/KCZXfqwZFDxkkWmSraU+dmJgUdgDd8nn3CbUw7j1djwRkZa0Dv+Wi+uDY1QZiKi7J7rxox
 SU8SSoNYB+CaqbJtBh5fxrY0bEbsryMeUMNIYFFHjtJqOVcJzWbe
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add YAML bindings for ep93xx SoC DMA.

Signed-off-by: Nikita Shubin <nikita.shubin@maquefel.me>
---
 .../bindings/dma/cirrus,ep9301-dma-m2m.yaml        |  72 ++++++++++++
 .../bindings/dma/cirrus,ep9301-dma-m2p.yaml        | 124 +++++++++++++++++++++
 include/dt-bindings/dma/cirrus,ep93xx-dma.h        |  26 +++++
 include/linux/platform_data/dma-ep93xx.h           |  21 +---
 4 files changed, 223 insertions(+), 20 deletions(-)

diff --git a/Documentation/devicetree/bindings/dma/cirrus,ep9301-dma-m2m.yaml b/Documentation/devicetree/bindings/dma/cirrus,ep9301-dma-m2m.yaml
new file mode 100644
index 000000000000..c8f57e000865
--- /dev/null
+++ b/Documentation/devicetree/bindings/dma/cirrus,ep9301-dma-m2m.yaml
@@ -0,0 +1,72 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/dma/cirrus,ep9301-dma-m2m.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Cirrus Logick ep93xx SoC DMA controller
+
+maintainers:
+  - Alexander Sverdlin <alexander.sverdlin@gmail.com>
+  - Nikita Shubin <nikita.shubin@maquefel.me>
+
+properties:
+  compatible:
+    oneOf:
+      - const: cirrus,ep9301-dma-m2m
+      - items:
+          - enum:
+              - cirrus,ep9302-dma-m2m
+              - cirrus,ep9307-dma-m2m
+              - cirrus,ep9312-dma-m2m
+              - cirrus,ep9315-dma-m2m
+          - const: cirrus,ep9301-dma-m2m
+
+  reg:
+    items:
+      - description: m2m0 channel registers
+      - description: m2m1 channel registers
+
+  clocks:
+    items:
+      - description: m2m0 channel gate clock
+      - description: m2m1 channel gate clock
+
+  clock-names:
+    items:
+      - const: m2m0
+      - const: m2m1
+
+  interrupts:
+    items:
+      - description: m2m0 channel interrupt
+      - description: m2m1 channel interrupt
+
+  '#dma-cells': true
+
+required:
+  - compatible
+  - reg
+  - clocks
+  - clock-names
+  - interrupts
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/clock/cirrus,ep93xx-clock.h>
+    dma-controller@80000100 {
+      compatible = "cirrus,ep9301-dma-m2m";
+      reg = <0x80000100 0x0040>,
+            <0x80000140 0x0040>;
+      clocks = <&eclk EP93XX_CLK_M2M0>,
+              <&eclk EP93XX_CLK_M2M1>;
+      clock-names = "m2m0", "m2m1";
+      interrupt-parent = <&vic0>;
+      interrupts = <17>, <18>;
+      #dma-cells = <1>;
+    };
+
+...
+
diff --git a/Documentation/devicetree/bindings/dma/cirrus,ep9301-dma-m2p.yaml b/Documentation/devicetree/bindings/dma/cirrus,ep9301-dma-m2p.yaml
new file mode 100644
index 000000000000..e3090421c328
--- /dev/null
+++ b/Documentation/devicetree/bindings/dma/cirrus,ep9301-dma-m2p.yaml
@@ -0,0 +1,124 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/dma/cirrus,ep9301-dma-m2p.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Cirrus Logick ep93xx SoC M2P DMA controller
+
+maintainers:
+  - Alexander Sverdlin <alexander.sverdlin@gmail.com>
+  - Nikita Shubin <nikita.shubin@maquefel.me>
+
+properties:
+  compatible:
+    oneOf:
+      - const: cirrus,ep9301-dma-m2p
+      - items:
+          - enum:
+              - cirrus,ep9302-dma-m2p
+              - cirrus,ep9307-dma-m2p
+              - cirrus,ep9312-dma-m2p
+              - cirrus,ep9315-dma-m2p
+          - const: cirrus,ep9301-dma-m2p
+
+  reg:
+    items:
+      - description: m2p0 channel registers
+      - description: m2p1 channel registers
+      - description: m2p2 channel registers
+      - description: m2p3 channel registers
+      - description: m2p4 channel registers
+      - description: m2p5 channel registers
+      - description: m2p6 channel registers
+      - description: m2p7 channel registers
+      - description: m2p8 channel registers
+      - description: m2p9 channel registers
+
+  clocks:
+    items:
+      - description: m2p0 channel gate clock
+      - description: m2p1 channel gate clock
+      - description: m2p2 channel gate clock
+      - description: m2p3 channel gate clock
+      - description: m2p4 channel gate clock
+      - description: m2p5 channel gate clock
+      - description: m2p6 channel gate clock
+      - description: m2p7 channel gate clock
+      - description: m2p8 channel gate clock
+      - description: m2p9 channel gate clock
+
+  clock-names:
+    items:
+      - const: m2p0
+      - const: m2p1
+      - const: m2p2
+      - const: m2p3
+      - const: m2p4
+      - const: m2p5
+      - const: m2p6
+      - const: m2p7
+      - const: m2p8
+      - const: m2p9
+
+  interrupts:
+    items:
+      - description: m2p0 channel interrupt
+      - description: m2p1 channel interrupt
+      - description: m2p2 channel interrupt
+      - description: m2p3 channel interrupt
+      - description: m2p4 channel interrupt
+      - description: m2p5 channel interrupt
+      - description: m2p6 channel interrupt
+      - description: m2p7 channel interrupt
+      - description: m2p8 channel interrupt
+      - description: m2p9 channel interrupt
+
+  '#dma-cells': true
+
+required:
+  - compatible
+  - reg
+  - clocks
+  - clock-names
+  - interrupts
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/clock/cirrus,ep93xx-clock.h>
+    dma-controller@80000000 {
+      compatible = "cirrus,ep9301-dma-m2p";
+      reg =   <0x80000000 0x0040>,
+              <0x80000040 0x0040>,
+              <0x80000080 0x0040>,
+              <0x800000c0 0x0040>,
+              <0x80000240 0x0040>,
+              <0x80000200 0x0040>,
+              <0x800002c0 0x0040>,
+              <0x80000280 0x0040>,
+              <0x80000340 0x0040>,
+              <0x80000300 0x0040>;
+      clocks = <&eclk EP93XX_CLK_M2P0>,
+              <&eclk EP93XX_CLK_M2P1>,
+              <&eclk EP93XX_CLK_M2P2>,
+              <&eclk EP93XX_CLK_M2P3>,
+              <&eclk EP93XX_CLK_M2P4>,
+              <&eclk EP93XX_CLK_M2P5>,
+              <&eclk EP93XX_CLK_M2P6>,
+              <&eclk EP93XX_CLK_M2P7>,
+              <&eclk EP93XX_CLK_M2P8>,
+              <&eclk EP93XX_CLK_M2P9>;
+      clock-names = "m2p0", "m2p1",
+              "m2p2", "m2p3",
+              "m2p4", "m2p5",
+              "m2p6", "m2p7",
+              "m2p8", "m2p9";
+      interrupt-parent = <&vic0>;
+      interrupts = <7>, <8>, <9>, <10>, <11>, <12>, <13>, <14>, <15>, <16>;
+      #dma-cells = <1>;
+    };
+
+...
+
diff --git a/include/dt-bindings/dma/cirrus,ep93xx-dma.h b/include/dt-bindings/dma/cirrus,ep93xx-dma.h
new file mode 100644
index 000000000000..21c7324eb27e
--- /dev/null
+++ b/include/dt-bindings/dma/cirrus,ep93xx-dma.h
@@ -0,0 +1,26 @@
+/* SPDX-License-Identifier: (GPL-2.0 OR MIT) */
+#ifndef DT_BINDINGS_CIRRUS_EP93XX_DMA_H
+#define DT_BINDINGS_CIRRUS_EP93XX_DMA_H
+
+/*
+ * M2P channels.
+ *
+ * Note that these values are also directly used for setting the PPALLOC
+ * register.
+ */
+#define EP93XX_DMA_I2S1         0
+#define EP93XX_DMA_I2S2         1
+#define EP93XX_DMA_AAC1         2
+#define EP93XX_DMA_AAC2         3
+#define EP93XX_DMA_AAC3         4
+#define EP93XX_DMA_I2S3         5
+#define EP93XX_DMA_UART1        6
+#define EP93XX_DMA_UART2        7
+#define EP93XX_DMA_UART3        8
+#define EP93XX_DMA_IRDA         9
+/* M2M channels */
+#define EP93XX_DMA_SSP          10
+#define EP93XX_DMA_IDE          11
+
+#endif /* DT_BINDINGS_CIRRUS_EP93XX_DMA_H */
+
diff --git a/include/linux/platform_data/dma-ep93xx.h b/include/linux/platform_data/dma-ep93xx.h
index eb9805bb3fe8..54b41d1468ef 100644
--- a/include/linux/platform_data/dma-ep93xx.h
+++ b/include/linux/platform_data/dma-ep93xx.h
@@ -5,26 +5,7 @@
 #include <linux/types.h>
 #include <linux/dmaengine.h>
 #include <linux/dma-mapping.h>
-
-/*
- * M2P channels.
- *
- * Note that these values are also directly used for setting the PPALLOC
- * register.
- */
-#define EP93XX_DMA_I2S1		0
-#define EP93XX_DMA_I2S2		1
-#define EP93XX_DMA_AAC1		2
-#define EP93XX_DMA_AAC2		3
-#define EP93XX_DMA_AAC3		4
-#define EP93XX_DMA_I2S3		5
-#define EP93XX_DMA_UART1	6
-#define EP93XX_DMA_UART2	7
-#define EP93XX_DMA_UART3	8
-#define EP93XX_DMA_IRDA		9
-/* M2M channels */
-#define EP93XX_DMA_SSP		10
-#define EP93XX_DMA_IDE		11
+#include <dt-bindings/dma/cirrus,ep93xx-dma.h>
 
 /**
  * struct ep93xx_dma_data - configuration data for the EP93xx dmaengine

-- 
2.39.2

