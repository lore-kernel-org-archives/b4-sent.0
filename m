From: Yuugo Yoneda <yogo.0917.sabu@gmail.com>
Date: Sat, 21 Nov 2026 21:43:19 +0900
Subject: [PATCH RFC v2 09/13] dt-bindings: mmc: add SiRF AT550 SDHCI host
 controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-at550-rfc-v1-v2-9-b0309d0789b2@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795264991; l=2242;
 i=yogo.0917.sabu@gmail.com; s=ypl514-20261117; h=from:subject:message-id;
 bh=Cw4PW1ium2XRqrgyq5Y/w+tMdamgHyjj6FEWVO1PTf0=;
 b=a5zpJI5EjZIlhB/FD+UmNuiUUXzSTRIjkg4sO7w1rcWzckKK7gDVBjOIO3C0eFjJNY8WwdmVc
 UhNpbbAXLIQAkJNLHm9G7C7Wsjlcl3mCu9pYSehXwFqMXqfogeooB8J
X-Developer-Key: i=yogo.0917.sabu@gmail.com; a=ed25519;
 pk=TIQ8Tk4xQrxyn8rmk3GI2f5qg/kO6g2KZm7YOOyBHeg=
X-Endpoint-Received: by B4 Relay for yogo.0917.sabu@gmail.com/ypl514-20261117 with auth_id=1550
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the Devicetree binding for the SiRF AT550 SDHCI host
controller.

Signed-off-by: Yuugo Yoneda <yogo.0917.sabu@gmail.com>
---
 .../devicetree/bindings/mmc/sirf,at550-sdhci.yaml  | 50 ++++++++++++++++++++++
 MAINTAINERS                                        |  1 +
 2 files changed, 51 insertions(+)

diff --git a/Documentation/devicetree/bindings/mmc/sirf,at550-sdhci.yaml b/Documentation/devicetree/bindings/mmc/sirf,at550-sdhci.yaml
new file mode 100644
index 000000000..ca0c7c414
--- /dev/null
+++ b/Documentation/devicetree/bindings/mmc/sirf,at550-sdhci.yaml
@@ -0,0 +1,50 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/mmc/sirf,at550-sdhci.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: SiRF AT550 SDHCI host controller
+
+maintainers:
+  - Yuugo Yoneda <yogo.0917.sabu@gmail.com>
+
+description:
+  SiRF AT550 SD/MMC host controller compliant with the SDHCI specification.
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
+  clocks:
+    maxItems: 1
+  bus-width:
+    enum: [1, 4]
+  no-1-8-v: true
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
diff --git a/MAINTAINERS b/MAINTAINERS
index df3d38c6b..1164152dc 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -25853,6 +25853,7 @@ S:	Odd Fixes
 F:	Documentation/devicetree/bindings/arm/sirf,at550.yaml
 F:	Documentation/devicetree/bindings/input/touchscreen/sirf,at550-ts.yaml
 F:	Documentation/devicetree/bindings/interrupt-controller/sirf,at550-intc.yaml
+F:	Documentation/devicetree/bindings/mmc/sirf,at550-sdhci.yaml
 F:	Documentation/devicetree/bindings/timer/sirf,at550-timer.yaml
 F:	drivers/clocksource/timer-at550.c
 F:	drivers/input/touchscreen/at550-ts.c

-- 
2.56.0

