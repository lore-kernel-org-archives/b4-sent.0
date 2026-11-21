From: Yuugo Yoneda <yogo.0917.sabu@gmail.com>
Date: Sat, 21 Nov 2026 21:43:15 +0900
Subject: [PATCH RFC v2 05/13] dt-bindings: timer: add SiRF AT550 system
 timer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-at550-rfc-v1-v2-5-b0309d0789b2@gmail.com>
References: <20261121-at550-rfc-v1-v2-0-b0309d0789b2@gmail.com>
In-Reply-To: <20261121-at550-rfc-v1-v2-0-b0309d0789b2@gmail.com>
To: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Ulf Hansson <ulfh@kernel.org>, 
 Adrian Hunter <adrian.hunter@intel.com>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Russell King <linux@armlinux.org.uk>, 
 Arnd Bergmann <arnd@arndb.de>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Linus Walleij <linusw@kernel.org>, Drew Fustini <fustini@kernel.org>, 
 linux-kernel@vger.kernel.org, linux-input@vger.kernel.org, 
 linux-mmc@vger.kernel.org, linux-doc@vger.kernel.org, soc@lists.linux.dev
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795264991; l=2417;
 i=yogo.0917.sabu@gmail.com; s=ypl514-20261117; h=from:subject:message-id;
 bh=dZNkcUac5AL1S7vwdLxO5MlCIcwUgq168srvwmaOOms=;
 b=YYOsBBNfiai4cC/74NLzqDIYLvpCtFDebjs55YUBRPvprZdIKDB1yBS8hmLeGGt6mKHH/7rrA
 UdtqKRqHzheDQcTYgT+L1agdexjl3JaJkaoyrGyl9JA+HJXAK+M/BbJ
X-Developer-Key: i=yogo.0917.sabu@gmail.com; a=ed25519;
 pk=TIQ8Tk4xQrxyn8rmk3GI2f5qg/kO6g2KZm7YOOyBHeg=
X-Endpoint-Received: by B4 Relay for yogo.0917.sabu@gmail.com/ypl514-20261117 with auth_id=1550
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the Devicetree binding for the SiRF AT550 64-bit free-running
system counter and six match channels.

Signed-off-by: Yuugo Yoneda <yogo.0917.sabu@gmail.com>
---
 .../bindings/timer/sirf,at550-timer.yaml           | 51 ++++++++++++++++++++++
 MAINTAINERS                                        |  1 +
 2 files changed, 52 insertions(+)

diff --git a/Documentation/devicetree/bindings/timer/sirf,at550-timer.yaml b/Documentation/devicetree/bindings/timer/sirf,at550-timer.yaml
new file mode 100644
index 000000000..6611dabe7
--- /dev/null
+++ b/Documentation/devicetree/bindings/timer/sirf,at550-timer.yaml
@@ -0,0 +1,51 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/timer/sirf,at550-timer.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: SiRF AT550 system timer
+
+maintainers:
+  - Yuugo Yoneda <yogo.0917.sabu@gmail.com>
+
+description:
+  A 64-bit free-running system counter with six 32-bit match channels and an
+  internal clock divider. Match channel 5 can also operate as a watchdog timer.
+
+properties:
+  compatible:
+    const: sirf,at550-timer
+  reg:
+    maxItems: 1
+  interrupts:
+    minItems: 1
+    items:
+      - description: Match channel 0 interrupt
+      - description: Match channel 1 interrupt
+      - description: Match channel 2 interrupt
+      - description: Match channel 3 interrupt
+      - description: Match channel 4 interrupt
+      - description: Match channel 5 interrupt
+  clocks:
+    maxItems: 1
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
diff --git a/MAINTAINERS b/MAINTAINERS
index 354466e29..3c5a814f2 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -25852,6 +25852,7 @@ M:	Yuugo Yoneda <yogo.0917.sabu@gmail.com>
 S:	Odd Fixes
 F:	Documentation/devicetree/bindings/arm/sirf,at550.yaml
 F:	Documentation/devicetree/bindings/interrupt-controller/sirf,at550-intc.yaml
+F:	Documentation/devicetree/bindings/timer/sirf,at550-timer.yaml
 F:	drivers/irqchip/irq-at550.c
 
 SIS 190 ETHERNET DRIVER

-- 
2.56.0

