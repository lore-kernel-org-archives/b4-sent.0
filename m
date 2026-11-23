From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Tue, 24 Nov 2026 01:50:01 +0300
Subject: [PATCH v4 1/3] dt-bindings: rtc: Add Cortina Systems CS7542 RTC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-b4-cs7542-rtc-v4-1-bceefd844074@gmail.com>
References: <20261124-b4-cs7542-rtc-v4-0-bceefd844074@gmail.com>
In-Reply-To: <20261124-b4-cs7542-rtc-v4-0-bceefd844074@gmail.com>
To: Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-rtc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795474200; l=1725;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=zpMLao1XyuPRjMljD/Vh3jkbZiWoCb7Hr28HjaR1ywM=;
 b=oR9esJeUokeEbZbQ02JskhlGOH4puiHttYHl17UuOIWe6aXpRWccZ2ZqaICQjdZb/s5vaU3mA
 14QGt6UnM/TDu5W93R1uxBzV6ZVsC19Y3sygKEm/Vya7Miqgi4SJZgB
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the RTC register block and its optional alarm and periodic
interrupt lines. The initial driver supports the calendar without
requiring those interrupts.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 .../bindings/rtc/cortina,cs7542-rtc.yaml           | 48 ++++++++++++++++++++++
 1 file changed, 48 insertions(+)

diff --git a/Documentation/devicetree/bindings/rtc/cortina,cs7542-rtc.yaml b/Documentation/devicetree/bindings/rtc/cortina,cs7542-rtc.yaml
new file mode 100644
index 000000000..8c2cc7ec9
--- /dev/null
+++ b/Documentation/devicetree/bindings/rtc/cortina,cs7542-rtc.yaml
@@ -0,0 +1,48 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/rtc/cortina,cs7542-rtc.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Cortina Systems CS7542 real-time clock
+
+maintainers:
+  - Fil Dunsky <filipp.dunsky@gmail.com>
+
+allOf:
+  - $ref: rtc.yaml#
+
+properties:
+  compatible:
+    const: cortina,cs7542-rtc
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    items:
+      - description: Alarm interrupt
+      - description: Periodic interrupt
+
+  interrupt-names:
+    items:
+      - const: alarm
+      - const: periodic
+
+required:
+  - compatible
+  - reg
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/arm-gic.h>
+
+    rtc@f4920000 {
+        compatible = "cortina,cs7542-rtc";
+        reg = <0xf4920000 0x50>;
+        interrupts = <GIC_SPI 10 IRQ_TYPE_LEVEL_HIGH>,
+                     <GIC_SPI 11 IRQ_TYPE_LEVEL_HIGH>;
+        interrupt-names = "alarm", "periodic";
+    };

-- 
2.53.0

